// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.30;

import { ICETFactory } from "@ssv/src/bridge/interfaces/ICetFactory.sol";
import { IComposableERC20 } from "@ssv/src/bridge/interfaces/IComposableERC20.sol";
import { IComposeMailbox } from "@ssv/src/bridge/interfaces/IComposeMailbox.sol";
import { IEthLiquidity } from "@ssv/src/bridge/interfaces/IEthLiquidity.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IMailbox } from "@ssv/src/core/interfaces/IMailbox.sol";
import { IComposeBridge } from "@ssv/src/bridge/interfaces/IComposeBridge.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ComposeBridge is IComposeBridge {
    using SafeERC20 for IERC20;

    IComposeMailbox public immutable mailbox;
    ICETFactory public immutable cetFactory;
    IEthLiquidity public immutable ETHLiquidity;

    constructor(address _mailbox, address _cetFactory, address _ethLiquidity) {
        mailbox = IComposeMailbox(_mailbox);
        cetFactory = ICETFactory(_cetFactory);
        ETHLiquidity = IEthLiquidity(_ethLiquidity);
    }

    function bridgeERC20To(
        uint256 chainDest,
        address tokenSrc,
        uint256 amount,
        address receiver,
        uint256 sessionId
    ) external {
        address sender = msg.sender;
        string memory name = IERC20Metadata(tokenSrc).name();
        string memory symbol = IERC20Metadata(tokenSrc).symbol();
        uint8 decimals = IERC20Metadata(tokenSrc).decimals();
        bytes memory payload = abi.encode(block.chainid, tokenSrc, amount, name, symbol, decimals);

        IComposeMailbox.MessageHeader memory bridgeHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: block.chainid,
            chainDest: chainDest,
            sender: msg.sender,
            receiver: receiver,
            label: "SEND_TOKEN"
        });


        IComposeMailbox.Message memory message = IComposeMailbox.Message({
            header: bridgeHeader,
            payload: payload
        });

        mailbox.write(message);

        checkAck(sessionId, chainDest, receiver, sender, tokenSrc, amount);
        emit MailboxWrite(chainDest, receiver, sessionId, "SEND_TOKEN");

        IERC20(tokenSrc).safeTransferFrom(sender, address(this), amount);
        emit TokensLocked(tokenSrc, sender, amount);

        bytes32 messageId = keccak256(abi.encodePacked(chainDest, receiver, sessionId, "SEND_TOKEN"));
        emit TokensBridged(chainDest, sender, receiver, tokenSrc, amount, sessionId, messageId);
    }

    function bridgeCETTo(
        uint256 chainDest,
        address cetTokenSrc,
        uint256 amount,
        address receiver,
        uint256 sessionId
    ) external {
        address sender = msg.sender;

        IComposableERC20.BridgedComposeTokenERC20Metadata memory data =
                                IComposableERC20(cetTokenSrc).metadata();

        IComposeMailbox.MessageHeader memory bridgeHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: block.chainid,
            chainDest: chainDest,
            sender: msg.sender,
            receiver: receiver,
            label: "SEND_TOKEN"
        });

        bytes memory payload = abi.encode(
            data.remoteChainID,
            data.remoteAsset,
            amount,
            data.name,
            data.symbol,
            data.decimals
        );

        IComposeMailbox.Message memory message = IComposeMailbox.Message({
            header: bridgeHeader,
            payload: payload
        });

        mailbox.write(message);
        checkAck(sessionId, chainDest, receiver, sender, cetTokenSrc, amount);
        emit MailboxWrite(chainDest, receiver, sessionId, "SEND_TOKEN");

        IComposableERC20(cetTokenSrc).crosschainBurn(sender, amount);
        emit CETBurned(sender, amount);

        bytes32 messageId = keccak256(abi.encodePacked(chainDest, receiver, sessionId, "SEND_TOKEN"));
        emit TokensBridged(chainDest, sender, receiver, cetTokenSrc, amount, sessionId, messageId);
    }

    function receiveTokens(
        IComposeMailbox.MessageHeader memory msgHeader
    ) external returns (address token, uint256 amount) {
        if (msg.sender != msgHeader.receiver) {
            revert NotReceiver();
        }
        if (msgHeader.chainDest != block.chainid) {
            revert WrongDestinationChain();
        }
        if (keccak256(abi.encodePacked(msgHeader.label)) != keccak256(abi.encodePacked("SEND_TOKEN"))) {
            revert InvalidMessage();
        }

        bytes memory m = mailbox.read(msgHeader);

        if (m.length == 0) {
            revert NoSendMessage();
        }

        uint256 remoteChainID;
        address remoteAsset;
        string memory name;
        string memory symbol;
        uint8 decimals;

        (remoteChainID, remoteAsset, amount, name, symbol, decimals) =
        abi.decode(m, (uint256, address, uint256, string, string, uint8));

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

        IComposeMailbox.MessageHeader memory ackHeader = IComposeMailbox.MessageHeader({
            sessionId: msgHeader.sessionId,
            chainSrc: msgHeader.chainDest,
            chainDest: msgHeader.chainSrc,
            sender: msgHeader.receiver,
            receiver: msgHeader.sender,
            label: "ACK"
        });

        IComposeMailbox.Message memory ack = IComposeMailbox.Message({
            header: ackHeader,
            payload: abi.encode(address(token), amount)
        });

        mailbox.write(ack);

        emit TokensReceived(token, amount);
        return (token, amount);
    }

    function bridgeEthTo(
        uint256 chainDest,
        address receiver,
        uint256 sessionId
    ) external payable { // todo nonReentrant ?
        if (msg.value == 0) {
            revert ZeroEthSent();
        }

        IComposeMailbox.MessageHeader memory bridgeHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: block.chainid,
            chainDest: chainDest,
            sender: msg.sender,
            receiver: receiver,
            label: "SEND_ETH"
        });

        IComposeMailbox.Message memory message = IComposeMailbox.Message({
            header: bridgeHeader,
            payload: abi.encode(block.chainid, msg.value)
        });

        mailbox.write(message);
        checkAck(sessionId, chainDest, receiver, msg.sender, address(0), msg.value);

        ETHLiquidity.burn{value: msg.value}();
        emit ETHLocked(msg.sender, msg.value);

        emit ETHBridged(chainDest, msg.sender, receiver, msg.value, sessionId,abi.encodePacked("SEND_ETH"));
    }

    function redeemWrappedCET(
        address wrappedCET,
        address coreCET,
        uint256 amount
    ) external {
        if (wrappedCET == address(0) || coreCET == address(0)) {
            revert ZeroAddress();
        }

        if (IComposableERC20(wrappedCET).getRemoteAsset() != coreCET) {
            revert InvalidAssetAddress();
        }

        IComposableERC20(wrappedCET).crosschainBurn(msg.sender, amount);
        IComposableERC20(coreCET).crosschainMint(msg.sender, amount);
        emit WrappedCETRedeemed(wrappedCET, coreCET, msg.sender, amount);
    }

    function receiveETH(
        IComposeMailbox.MessageHeader memory msgHeader
    ) external returns (uint256 amount) { // todo nonreentrant ?
        if (msg.sender != msgHeader.receiver) {
            revert NotReceiver();
        }

        if (msgHeader.chainDest != block.chainid) {
            revert WrongDestinationChain();
        }

        if (keccak256(abi.encodePacked(msgHeader.label)) != keccak256(abi.encodePacked("SEND_ETH"))) {
            revert InvalidMessage();
        }

        bytes memory m = mailbox.read(msgHeader);
        if (m.length == 0) {
            revert NoSendMessage();
        }

        uint256 remoteChainID;
        (remoteChainID, amount) = abi.decode(m, (uint256, uint256));

        ETHLiquidity.mint(amount);

        IComposeMailbox.MessageHeader memory ackHeader = IComposeMailbox.MessageHeader({
            sessionId: msgHeader.sessionId,
            chainSrc: msgHeader.chainDest,
            chainDest: msgHeader.chainSrc,
            sender: msgHeader.receiver,
            receiver: msgHeader.sender,
            label: "ACK"
        });

        IComposeMailbox.Message memory ack = IComposeMailbox.Message({
            header: ackHeader,
            payload: abi.encode(address(0), amount)
        });

        mailbox.write(ack);

        emit ETHReceived(msg.sender, amount);
        emit MailboxAckWrite(msgHeader.chainSrc, msgHeader.receiver, msgHeader.sessionId, "ACK");

        (bool success, bytes memory err) = msg.sender.call{ value: amount }("");
        if (!success) {
            revert EthReceiveFailed(err);
        }

        return amount;
    }

    function checkAck(
        uint256 sessionID,
        uint256 ackChainSrc,
        address ackReceiver,
        address ackSender,
        address tokenSrc,
        uint256 amount
    ) private {
        IComposeMailbox.MessageHeader memory ackHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionID,
            chainSrc: ackChainSrc,
            chainDest: block.chainid,
            sender: ackReceiver,
            receiver: ackSender,
            label: "ACK"
        });

        bytes memory ackPayload = mailbox.read(ackHeader);

        if (ackPayload.length == 0) {
            revert NoAckMessage();
        }

        if (ackPayload.length != 32+32) {
            revert InvalidAckPayload();
        }

        (address ackTokenSrc, uint256 ackAmount) = abi.decode(ackPayload, (address, uint256));

        if (ackTokenSrc != tokenSrc) {
            revert AckSourceTokenMismatch();
        }

        if (ackAmount != amount) {
            revert AckAmountMismatch();
        }
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
        string memory name,
        string memory symbol,
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

        if (cet != predicted) {
            revert InvalidCetAddress();
        }

        IComposableERC20(cet).crosschainMint(to, amount);
        return cet;
    }

    // to allow receiving eth
    receive() external payable {}
}