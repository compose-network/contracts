// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.30;

import { IMailbox } from "@ssv/src/core/interfaces/IMailbox.sol";
import { ICETFactory } from "@ssv/src/bridge/interfaces/ICetFactory.sol";
import { IUniversalBridge } from "@ssv/src/bridge/interfaces/IUniversalBridge.sol";
import { IComposableERC20 } from "@ssv/src/bridge/interfaces/IComposableERC20.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniversalBridge is IUniversalBridge {
    using SafeERC20 for IERC20;

    IMailbox public immutable mailbox;
    ICETFactory public immutable cetFactory;

    constructor(address _mailbox, address _cetFactory) {
        mailbox = IMailbox(_mailbox);
        cetFactory = ICETFactory(_cetFactory);
    }

    function computeCETAddress(
        address remoteAsset,
        uint256 remoteChainID,
        uint8 decimals,
        string memory name,
        string memory symbol
    ) internal view returns (address) {
        return cetFactory.predictAddress(
            remoteAsset,
            remoteChainID,
            decimals,
            name,
            symbol,
            address(this)
        );
    }

    function ensureCETAndMint(
        address remoteAsset,
        uint256 remoteChainID,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        address to,
        uint256 amount
    ) internal returns (address cet) {
        address predicted = computeCETAddress(remoteAsset, remoteChainID, decimals, name, symbol);

        cet = cetFactory.deployIfAbsent(
            remoteAsset,
            remoteChainID,
            decimals,
            name,
            symbol,
            address(this)
        );

        if (cet != predicted) revert InvalidCetAddress();

        IComposableERC20(cet).crosschainMint(to, amount);
        return cet;
    }

    function bridgeERC20To(
        uint256 chainDest,
        address tokenSrc,
        uint256 amount,
        address receiver,
        uint256 sessionId
    ) external {
        address sender = msg.sender;

        IERC20(tokenSrc).safeTransferFrom(sender, address(this), amount);
        emit TokensLocked(tokenSrc, sender, amount);

        bytes memory payload = abi.encode(block.chainid, tokenSrc, amount);
        mailbox.write(chainDest, receiver, sessionId, "SEND", payload);
        checkAck(chainDest, receiver, sessionId);
        emit MailboxWrite(chainDest, receiver, sessionId, "SEND");

        bytes32 messageId = keccak256(
            abi.encodePacked(chainDest, receiver, sessionId, "SEND")
        );
        emit TokensSendQueued(chainDest, sender, receiver, tokenSrc, amount, sessionId, messageId);
    }

    function bridgeCETTo(
        uint256 chainDest,
        address cetTokenSrc,
        uint256 amount,
        address receiver,
        uint256 sessionId
    ) external {
        address sender = msg.sender;
        address remoteAsset = IComposableERC20(cetTokenSrc).remoteAsset();
        uint256 remoteChainID = IComposableERC20(cetTokenSrc).remoteChainID();

        IComposableERC20(cetTokenSrc).crosschainBurn(sender, amount);
        emit CETBurned(cetTokenSrc, sender, amount);

        bytes memory payload = abi.encode(remoteChainID, remoteAsset, amount);
        mailbox.write(chainDest, receiver, sessionId, "SEND", payload);
        checkAck(chainDest, receiver, sessionId);
        emit MailboxWrite(chainDest, receiver, sessionId, "SEND");

        bytes32 messageId = keccak256(
            abi.encodePacked(chainDest, receiver, sessionId, "SEND")
        );
        emit TokensSendQueued(chainDest, sender, receiver, remoteAsset, amount, sessionId, messageId);
    }

    function receiveTokens(
        IMailbox.MessageHeader calldata msgHeader,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external returns (address token, uint256 amount) {
        if (msg.sender != msgHeader.receiver) revert NotReceiver();
        if (msgHeader.chainDest != block.chainid) revert WrongDestinationChain();
        if (keccak256(msgHeader.label) != keccak256(bytes("SEND"))) revert InvalidMessage();

        bytes memory m = mailbox.read(
            msgHeader.chainSrc,
            msgHeader.sender,
            msgHeader.sessionId,
            msgHeader.label
        );
        if (m.length == 0) revert NoSendMessage();

        uint256 remoteChainID;
        address remoteAsset;
        (remoteChainID, remoteAsset, amount) = abi.decode(m, (uint256, address, uint256));

        if (
            remoteChainID == block.chainid &&
            IERC20(remoteAsset).balanceOf(address(this)) >= amount
        ) {
            IERC20(remoteAsset).safeTransfer(msgHeader.receiver, amount);
            token = remoteAsset;
        } else {
            token = ensureCETAndMint(
                remoteAsset,
                remoteChainID,
                name,
                symbol,
                decimals,
                msgHeader.receiver,
                amount
            );
        }

        mailbox.write(msgHeader.chainSrc, msgHeader.sender, msgHeader.sessionId, "ACK", abi.encode());
        emit MailboxAckWrite(msgHeader.chainSrc, msgHeader.sender, msgHeader.sessionId, "ACK");
        emit TokensReceived(token, amount);
    }

    function checkAck(uint256, address, uint256 sessionId) internal {
        bytes memory ack = mailbox.read(block.chainid, address(this), sessionId, "ACK");
        if (ack.length == 0) revert NoAckMessage();
    }
}