// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.30;

import { IBridgeableToken } from "@ssv/src/core/interfaces/IBridgeableToken.sol";
import { IMailbox } from "@ssv/src/core/interfaces/IMailbox.sol";
import { IBridge } from "@ssv/src/core/interfaces/IBridge.sol";

/**
 * @title Bridge
 * @notice This contract handles token bridging between blockchain networks using a mailbox for cross-chain messages.
 *
 * @author
 * SSV Labs
 */
contract Bridge is IBridge {

    /// @notice The mailbox contract used for sending and receiving cross-chain messages.
    /// @dev This is set in the constructor and cannot be changed later.
    IMailbox public immutable mailbox;

    /// @notice Initializes the bridge with a mailbox address.
    /// @dev Sets the mailbox interface for all cross-chain operations.
    /// @param _mailbox The address of the mailbox contract.
    constructor(address _mailbox) {
        mailbox = IMailbox(_mailbox);
    }

    struct MsgHeader {
        uint256 sourceChain;
        address senderContract;
        uint256 destChain;
        address destContract;
        bytes32 sessionId;
        string label;
    }

    struct FullMsg {
        MsgHeader header;
        bytes data;
    }

    // Sent / Received messages cache storage
    // Key: A unique ID (or index) | Value: The full message
    mapping(bytes32 => FullMsg) public messageCache;

    /// @notice Prepares the sending of tokens from the current chain to another chain by burning them and sending a message.
    /// @dev The caller must be the tokens sender. Tokens are burned, and a message is emitted for the destination bridge to process.
    /// @param otherChainId The ID of the destination blockchain.
    /// @param token The address of the token being transferred.
    /// @param sender The address sending the tokens (must be the caller).
    /// @param receiver The address that will receive the tokens on the destination chain.
    /// @param amount The number of tokens to transfer.
    /// @param sessionId A unique ID for this transaction session.
    /// @param destBridge The address of the Bridge contract on the destination chain.
    function send(
        uint256 otherChainId,
        address token,
        address sender,
        address receiver,
        uint256 amount,
        uint256 sessionId,
        address destBridge
    ) external {
        if (msg.sender != sender) {
            revert Unauthorized();
        }

        IBridgeableToken(token).burn(sender, amount);

        MsgHeader memory header = MsgHeader({
            sourceChain:block.chainid,
            senderContract:address(this),
            destChain:otherChainId,
            destContract:destBridge,
            sessionId:sessionId,
            label:"SEND"
        });

        bytes memory data = abi.encode(sender, receiver, token, amount);

        FullMsg memory fullMsg = FullMsg({
            header: header,
            data: data
        });

        bytes32 key = keccak256(
            abi.encode(header)
        );

        messageCache[key] = data;

        emit MessageCreated(abi.encode(fullMsg));
    }

    /// @notice Confirms the sending of tokens from the current chain to another chain by saving the message to the mailbox.
    /// @dev The message must have been save previously.
    /// @param otherChainId The ID of the destination blockchain.
    /// @param token The address of the token being transferred.
    /// @param sender The address sending the tokens (must be the caller).
    /// @param receiver The address that will receive the tokens on the destination chain.
    /// @param amount The number of tokens to transfer.
    /// @param sessionId A unique ID for this transaction session.
    /// @param destBridge The address of the Bridge contract on the destination chain.
    function sendConfirm(
        uint256 otherChainId,
        address token,
        address sender,
        address receiver,
        uint256 amount,
        uint256 sessionId,
        address destBridge
    ) external {
        MsgHeader memory header = MsgHeader({
            sourceChain:block.chainid,
            senderContract:address(this),
            destChain:otherChainId,
            destContract:destBridge,
            sessionId:sessionId,
            label:"SEND"
        });

        bytes memory data = abi.encode(sender, receiver, token, amount);

        FullMsg memory fullMsg = FullMsg({
            header: header,
            data: data
        });

        bytes32 key = keccak256(
            abi.encode(header)
        );

        if(messageCache[key] != bytes(0)){
            mailbox.write(otherChainId, destBridge, sessionId, "SEND", data); // TODO: replace depending on mailbox changes
            delete messageCache[key];
        } else revert Unauthorized();
    }

    /// @notice Aborts the sending of tokens from the current chain to another chain by returning amount tokens to the owner.
    /// @dev The message must have been save previously.
    /// @param otherChainId The ID of the destination blockchain.
    /// @param token The address of the token being transferred.
    /// @param sender The address sending the tokens (must be the caller).
    /// @param receiver The address that will receive the tokens on the destination chain.
    /// @param amount The number of tokens to transfer.
    /// @param sessionId A unique ID for this transaction session.
    /// @param destBridge The address of the Bridge contract on the destination chain.
    function SendAbort(
        uint256 otherChainId,
        address token,
        address sender,
        address receiver,
        uint256 amount,
        uint256 sessionId,
        address destBridge
    ) external {
        MsgHeader memory header = MsgHeader({
            sourceChain:block.chainid,
            senderContract:address(this),
            destChain:otherChainId,
            destContract:destBridge,
            sessionId:sessionId,
            label:"SEND"
        });

        bytes memory data = abi.encode(sender, receiver, token, amount);

        FullMsg memory fullMsg = FullMsg({
            header: header,
            data: data
        });

        bytes32 key = keccak256(
            abi.encode(header)
        );

        if(messageCache[key] != bytes(0)){
            IBridgeableToken(token).mint(sender, amount);
            delete messageCache[key];
        } else revert Unauthorized();
    }

    /// @notice Receives and processes tokens on the destination chain by minting them after reading the source message and saving them to be delivered afterwards.
    /// @dev The caller must be the receiver. It checks the message, verifies sender and receiver, mints tokens, and sends an acknowledgment back.
    /// @param otherChainId The ID of the source blockchain.
    /// @param sender The address that sent the tokens from the source chain.
    /// @param receiver The address receiving the tokens (must be the caller).
    /// @param sessionId The unique ID for this transaction session.
    /// @param srcBridge The address of the Bridge contract on the source chain.
    /// @param receivedMessage The message sent by the source chain informing of the intent of sending tokens
    function recv(
        uint256 otherChainId,
        address sender,
        address receiver,
        uint256 sessionId,
        address srcBridge,
        bytes receivedMessage
    ) external {
        if (msg.sender != receiver) {
            revert Unauthorized();
        }

        if (receivedMessage.length == 0) {
            revert EmptySourceChainMessage();
        }

        FullMsg memory fullMsg = abi.decode(receivedMessage);

        address readSender;
        address readReceiver;
        address token;
        uint256 amount;

        (readSender, readReceiver, token, amount) = abi.decode(
            fullMsg.data,
            (address, address, address, uint256)
        );

        if (readSender != sender) {
            revert SenderMismatch();
        }
        if (readReceiver != receiver) {
            revert ReceiverMismatch();
        }

        IBridgeableToken(token).mint(address(this), amount);

        MsgHeader memory h = MsgHeader({
            sourceChain:block.chainid,
            senderContract:address(this),
            destChain:otherChainId,
            destContract:srcBridge,
            sessionId:sessionId,
            label:"ACK SEND"
        });

        bytes memory m = abi.encode("OK", token, amount);

        FullMsg memory confirmMsg = FullMsg({
            header: h,
            data: m
        });

        bytes32 key = keccak256(
            abi.encode(h)
        );

        messageCache[h] = m;

        emit MessageReceived(abi.encode(confirmMsg));
    }

    /// @notice Confirms the receiving of tokens by transferring the reserved tokens to the receiver address and saving changes to the mailbox
    /// @dev The message must have been previously save.
    /// @param otherChainId The ID of the source blockchain.
    /// @param sender The address that sent the tokens from the source chain.
    /// @param receiver The address receiving the tokens (must be the caller).
    /// @param sessionId The unique ID for this transaction session.
    /// @param srcBridge The address of the Bridge contract on the source chain.
    /// @return token The address of the token that was transferred.
    /// @return amount The number of tokens transferred.
    function recvConfirm(
        uint256 otherChainId,
        address sender,
        address receiver,
        uint256 sessionId,
        address srcBridge
    ) external returns (address token, uint256 amount) {
        MsgHeader memory h = MsgHeader({
            sourceChain:block.chainid,
            senderContract:address(this),
            destChain:otherChainId,
            destContract:srcBridge,
            sessionId:sessionId,
            label:"ACK SEND"
        });

        bytes32 key = keccak256(
            abi.encode(h)
        );

        bytes memory m = messageCache[key];

        if(m != bytes(0)){
            (,,token, amount) = abi.decode(
                m,
                (address, address, address, uint256)
            );
            IBridgeableToken(token).transfer(receiver, amount);
            mailbox.write(otherChainId, srcBridge, sessionId, "ACK SEND", m);
            delete messageCache[key];
            return (token, amount);
        } else revert Unauthorized();
    }

    /// @notice Aborts the receiving of tokens by burning the reserved tokens
    /// @dev The message must have been previously save.
    /// @param otherChainId The ID of the source blockchain.
    /// @param sender The address that sent the tokens from the source chain.
    /// @param receiver The address receiving the tokens (must be the caller).
    /// @param sessionId The unique ID for this transaction session.
    /// @param srcBridge The address of the Bridge contract on the source chain.
    /// @return token The address of the token that was transferred.
    /// @return amount The number of tokens transferred.
    function recvAbort(
        uint256 otherChainId,
        address sender,
        address receiver,
        uint256 sessionId,
        address srcBridge
    ) external {
        MsgHeader memory h = MsgHeader({
            sourceChain:block.chainid,
            senderContract:address(this),
            destChain:otherChainId,
            destContract:srcBridge,
            sessionId:sessionId,
            label:"ACK SEND"
        });

        bytes32 key = keccak256(
            abi.encode(h)
        );

        bytes memory m = messageCache[key];

        if(m != bytes(0)){
            address memory token;
            uint256 memory amount;
            (,,token, amount) = abi.decode(
                m,
                (address, address, address, uint256)
            );
            IBridgeableToken(token).burn(receiver, amount);
            delete messageCache[key];
        } else revert Unauthorized();
    }

    /// @notice Checks for an acknowledgment message from the destination chain.
    /// @dev This is a view function to read the ACK.
    /// @param chainDest The ID of the destination blockchain.
    /// @param destBridge The address of the Bridge contract on the destination chain.
    /// @param sessionId The unique ID for the transaction session.
    /// @return The acknowledgment message as bytes, or empty if none exists.
    function checkAck(
        uint256 chainDest,
        address destBridge,
        uint256 sessionId
    ) external view returns (bytes memory) {
        MsgHeader memory h = MsgHeader({
            sourceChain:chainDest,
            senderContract:destBridge,
            destChain:block.chainid,
            destContract:address(this),
            sessionId:sessionId,
            label:"ACK SEND"
        });

        bytes32 key = keccak256(
            abi.encode(h)
        );

        return messageCache[key];
    }
}
