// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { ComposeBridge } from "@ssv/src/bridge/ComposeBridge.sol";
import { CetFactory } from "@ssv/src/bridge/CetFactory.sol";
import { ComposableERC20 } from "@ssv/src/bridge/ComposableErc20.sol";
import { IComposeMailbox } from "@ssv/src/bridge/interfaces/IComposeMailbox.sol";
import { IComposableERC20 } from "@ssv/src/bridge/interfaces/IComposableERC20.sol";
import { IComposeBridge } from "@ssv/src/bridge/interfaces/IComposeBridge.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ComposeMailbox } from "../src/bridge/ComposeMailbox.sol";
import { EthLiquidityMock } from "@ssv/test/mock/EthLiquidityMock.sol";
import { MockToken } from "@ssv/test/mock/MockERC20.sol";

contract ComposeBridgeUnitTest is Test {
    ComposeBridge internal bridge;
    ComposeMailbox internal mailbox;
    ComposableERC20 internal cet;
    EthLiquidityMock internal ethLiquidity;
    CetFactory internal cetFactory;

    MockToken internal erc20;

    address internal l1Asset = address(0xAAAA);
    address internal receiver = address(0xBEEF);
    uint256 internal amount = 1000;
    uint256 internal sessionId = 12345;
    uint256 internal sourceChain = 1;

    string internal name = "TestToken";
    string internal symbol = "TT";
    uint8 internal decimals = 18;

    address internal coordinator = address(0x1234);
    address internal user = address(0xBEEFBEEF);

    function setUp() public {
        erc20 = new MockToken();
        ethLiquidity = new EthLiquidityMock();

        cetFactory = new CetFactory();
        mailbox = new ComposeMailbox(coordinator);

        bridge = new ComposeBridge(
            address(mailbox),
            address(cetFactory),
            address(ethLiquidity)
        );

        cet = new ComposableERC20(
            l1Asset,
            sourceChain,
            name,
            symbol,
            decimals,
            address(bridge)
        );

        vm.prank(coordinator);
        mailbox.setBridge(address(bridge));
    }

    function testConstructor() public {
        assertEq(address(bridge.mailbox()), address(mailbox));
        assertEq(address(bridge.cetFactory()), address(cetFactory));
        assertEq(address(bridge.ETHLiquidity()), address(ethLiquidity));
    }

    function testBridgeERC20To() public {
        erc20.mint(user, amount);

        vm.prank(user);
        erc20.approve(address(bridge), type(uint256).max);

        _putAck(
            sessionId,
            sourceChain,
            user,
            receiver,
            address(erc20),
            amount
        );

        vm.expectEmit(true, true, true, true, address(bridge));
        emit IComposeBridge.MailboxWrite(sourceChain, receiver, sessionId, "SEND_TOKEN");

        vm.expectEmit(true, true, true, true, address(bridge));
        emit IComposeBridge.TokensLocked(address(erc20), user, amount);

        bytes32 messageId = keccak256(abi.encodePacked(sourceChain, receiver, sessionId, "SEND_TOKEN"));
        vm.expectEmit(true, true, true, true, address(bridge));
        emit IComposeBridge.TokensBridged(sourceChain, user, receiver, address(erc20), amount, sessionId, messageId);

        vm.prank(user);
        bridge.bridgeERC20To(
            sourceChain,
            address(erc20),
            amount,
            receiver,
            sessionId
        );

        assertEq(
            erc20.balanceOf(user),
            0,
            "user balance should be deducted"
        );
        assertEq(
            erc20.balanceOf(address(bridge)),
            amount,
            "bridge should now hold the locked tokens"
        );

        IComposeMailbox.MessageHeader memory expectedHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: block.chainid,
            chainDest: sourceChain,
            sender: user,
            receiver: receiver,
            label: "SEND_TOKEN"
        });

        bytes32 key = keccak256(
            abi.encodePacked(
                expectedHeader.sessionId,
                expectedHeader.chainSrc,
                expectedHeader.chainDest,
                expectedHeader.sender,
                expectedHeader.receiver,
                expectedHeader.label
            )
        );

        bytes memory payload = mailbox.outbox(key);
        assertGt(payload.length, 0, "SEND_TOKEN payload should exist in outbox");

        (
            uint256 remoteChainID,
            address remoteAsset,
            uint256 bridgedAmount,
            string memory name,
            string memory symbol,
            uint8 decimals
        ) = abi.decode(payload, (uint256, address, uint256, string, string, uint8));

        assertEq(remoteChainID, block.chainid, "remoteChainID mismatch");
        assertEq(remoteAsset, address(erc20), "remoteAsset mismatch");
        assertEq(bridgedAmount, amount, "bridged amount mismatch");
        assertEq(bytes(name).length > 0, true, "token name should be nonempty");
        assertEq(bytes(symbol).length > 0, true, "token symbol should be nonempty");
        assertEq(decimals, erc20.decimals(), "token decimals mismatch");
    }

    function testBridgeERC20ToRevertsIfNoAckInMailbox() public {
        vm.expectRevert(IComposeMailbox.MessageNotFound.selector);

        vm.prank(user);
        bridge.bridgeERC20To(
            sourceChain,
            address(erc20),
            amount,
            receiver,
            sessionId
        );
    }

    function testBridgeERC20ToRevertsIfAckHasEmptyPayload() public {
        IComposeMailbox.MessageHeader memory ackHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: receiver,
            receiver: user,
            label: "ACK"
        });

        bytes memory payload; // empty payload

        IComposeMailbox.Message memory ackMsg = IComposeMailbox.Message({
            header: ackHeader,
            payload: payload
        });

        vm.prank(coordinator);
        mailbox.putInbox(ackMsg);

        vm.expectRevert(IComposeBridge.NoAckMessage.selector);

        vm.prank(user);
        bridge.bridgeERC20To(
            sourceChain,
            address(erc20),
            amount,
            receiver,
            sessionId
        );
    }

    function testBridgeERC20ToRevertsIfAckHasInvalidPayload() public {
        IComposeMailbox.MessageHeader memory ackHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: receiver,
            receiver: user,
            label: "ACK"
        });

        bytes memory payload = abi.encode("some random data");

        IComposeMailbox.Message memory ackMsg = IComposeMailbox.Message({
            header: ackHeader,
            payload: payload
        });

        vm.prank(coordinator);
        mailbox.putInbox(ackMsg);

        vm.expectRevert(IComposeBridge.InvalidAckPayload.selector);

        vm.prank(user);
        bridge.bridgeERC20To(
            sourceChain,
            address(erc20),
            amount,
            receiver,
            sessionId
        );
    }

    function testBridgeERC20ToRevertsIfAckHasAnotherTokenSource() public {
        _putAck(
            sessionId,
            sourceChain,
            user,
            receiver,
            address(0x111), // not the erc 20 that is about to be bridged
            amount
        );

        vm.expectRevert(IComposeBridge.AckSourceTokenMismatch.selector);

        vm.prank(user);
        bridge.bridgeERC20To(
            sourceChain,
            address(erc20),
            amount,
            receiver,
            sessionId
        );
    }

    function testBridgeERC20ToRevertsIfAckHasAnotherTokenAmount() public {
        _putAck(
            sessionId,
            sourceChain,
            user,
            receiver,
            address(erc20),
            12345 // another amount
        );

        vm.expectRevert(IComposeBridge.AckAmountMismatch.selector);

        vm.prank(user);
        bridge.bridgeERC20To(
            sourceChain,
            address(erc20),
            amount,
            receiver,
            sessionId
        );
    }

    function testBridgeCETTo() public {
        vm.prank(address(bridge));
        cet.crosschainMint(user, amount);

        _putAck(
            sessionId,
            sourceChain,
            user,
            receiver,
            address(cet),
            amount
        );

        vm.expectEmit(true, true, true, true, address(bridge));
        emit IComposeBridge.MailboxWrite(sourceChain, receiver, sessionId, "SEND_TOKEN");

        vm.expectEmit(true, true, true, true, address(bridge));
        emit IComposeBridge.CETBurned(user, amount);

        bytes32 messageId = keccak256(abi.encodePacked(sourceChain, receiver, sessionId, "SEND_TOKEN"));
        vm.expectEmit(true, true, true, true, address(bridge));
        emit IComposeBridge.TokensBridged(
            sourceChain,
            user,
            receiver,
            address(cet),
            amount,
            sessionId,
            messageId
        );

        vm.prank(user);
        bridge.bridgeCETTo(sourceChain, address(cet), amount, receiver, sessionId);

        assertEq(cet.balanceOf(user), 0, "CET should be burned from user");
        assertEq(cet.balanceOf(address(bridge)), 0, "bridge never holds CET after burn");

        IComposeMailbox.MessageHeader memory expectedHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: block.chainid,
            chainDest: sourceChain,
            sender: user,
            receiver: receiver,
            label: "SEND_TOKEN"
        });

        bytes32 key = keccak256(
            abi.encodePacked(
                expectedHeader.sessionId,
                expectedHeader.chainSrc,
                expectedHeader.chainDest,
                expectedHeader.sender,
                expectedHeader.receiver,
                expectedHeader.label
            )
        );

        bytes memory payload = mailbox.outbox(key);
        assertGt(payload.length, 0, "SEND_TOKEN payload should exist in outbox");

        (
            uint256 remoteChainID,
            address remoteAsset,
            uint256 bridgedAmount,
            string memory tokenName,
            string memory tokenSymbol,
            uint8 tokenDecimals
        ) = abi.decode(payload, (uint256, address, uint256, string, string, uint8));

        assertEq(remoteChainID, sourceChain, "remoteChainID mismatch");
        assertEq(remoteAsset, l1Asset, "remoteAsset mismatch");
        assertEq(bridgedAmount, amount, "bridged amount mismatch");
        assertEq(bytes(tokenName).length > 0, true, "token name should be nonempty");
        assertEq(bytes(tokenSymbol).length > 0, true, "token symbol should be nonempty");
        assertEq(tokenDecimals, decimals, "token decimals mismatch");
    }

    function testBridgeCETToRevertsIfNoAckInMailbox() public {
        vm.expectRevert(IComposeMailbox.MessageNotFound.selector);

        vm.prank(user);
        bridge.bridgeCETTo(sourceChain, address(cet), amount, receiver, sessionId);
    }

    function testBridgeCETToRevertsIfAckHasEmptyPayload() public {
        IComposeMailbox.MessageHeader memory ackHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: receiver,
            receiver: user,
            label: "ACK"
        });

        bytes memory payload;

        IComposeMailbox.Message memory ackMsg = IComposeMailbox.Message({
            header: ackHeader,
            payload: payload
        });

        vm.prank(coordinator);
        mailbox.putInbox(ackMsg);

        vm.expectRevert(IComposeBridge.NoAckMessage.selector);

        vm.prank(user);
        bridge.bridgeCETTo(sourceChain, address(cet), amount, receiver, sessionId);
    }


    function testBridgeCETToRevertsIfAckHasInvalidPayload() public {
        IComposeMailbox.MessageHeader memory ackHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: receiver,
            receiver: user,
            label: "ACK"
        });

        bytes memory payload = abi.encode("some invalid random data");

        IComposeMailbox.Message memory ackMsg = IComposeMailbox.Message({
            header: ackHeader,
            payload: payload
        });

        vm.prank(coordinator);
        mailbox.putInbox(ackMsg);

        vm.expectRevert(IComposeBridge.InvalidAckPayload.selector);

        vm.prank(user);
        bridge.bridgeCETTo(sourceChain, address(cet), amount, receiver, sessionId);
    }

    function testBridgeCETToRevertsIfAckHasAnotherTokenSource() public {
        _putAck(
            sessionId,
            sourceChain,
            user,
            receiver,
            address(0x111),
            amount
        );

        vm.expectRevert(IComposeBridge.AckSourceTokenMismatch.selector);

        vm.prank(user);
        bridge.bridgeCETTo(sourceChain, address(cet), amount, receiver, sessionId);
    }

    function testBridgeCETToRevertsIfAckHasAnotherTokenAmount() public {
        _putAck(
            sessionId,
            sourceChain,
            user,
            receiver,
            address(cet),
            12345
        );

        vm.expectRevert(IComposeBridge.AckAmountMismatch.selector);

        vm.prank(user);
        bridge.bridgeCETTo(sourceChain, address(cet), amount, receiver, sessionId);
    }

    function testBridgeEthTo() public {
        uint256 ethAmount = 1 ether;

        _putAck(
            sessionId,
            sourceChain,
            user,
            receiver,
            address(0),
            ethAmount
        );

        vm.expectEmit(true, true, true, true, address(bridge));
        emit IComposeBridge.ETHLocked(user, ethAmount);

        vm.expectEmit(true, true, true, true, address(bridge));
        emit IComposeBridge.ETHBridged(
            sourceChain,
            user,
            receiver,
            ethAmount,
            sessionId,
            abi.encodePacked("SEND_ETH")
        );

        vm.deal(user, ethAmount);

        vm.prank(user);
        bridge.bridgeEthTo{value: ethAmount}(sourceChain, receiver, sessionId);

        IComposeMailbox.MessageHeader memory expectedHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: block.chainid,
            chainDest: sourceChain,
            sender: user,
            receiver: receiver,
            label: "SEND_ETH"
        });

        bytes32 key = keccak256(
            abi.encodePacked(
                expectedHeader.sessionId,
                expectedHeader.chainSrc,
                expectedHeader.chainDest,
                expectedHeader.sender,
                expectedHeader.receiver,
                expectedHeader.label
            )
        );

        bytes memory payload = mailbox.outbox(key);
        assertGt(payload.length, 0, "SEND_ETH payload should exist in outbox");

        (uint256 remoteChainID, uint256 bridgedAmount) = abi.decode(payload, (uint256, uint256));

        assertEq(remoteChainID, block.chainid, "remoteChainID mismatch");
        assertEq(bridgedAmount, ethAmount, "bridged amount mismatch");
    }

    function testBridgeEthToRevertsIfZeroEthSent() public {
        vm.expectRevert(IComposeBridge.ZeroEthSent.selector);

        vm.prank(user);
        bridge.bridgeEthTo{value: 0}(sourceChain, receiver, sessionId);
    }


    function testBridgeEthToRevertsIfNoAckInMailbox() public {
        uint256 ethAmount = 1 ether;
        vm.deal(user, ethAmount);

        vm.expectRevert(IComposeMailbox.MessageNotFound.selector);

        vm.prank(user);
        bridge.bridgeEthTo{value: ethAmount}(sourceChain, receiver, sessionId);
    }

    function testBridgeEthToRevertsIfAckHasEmptyPayload() public {
        uint256 ethAmount = 1 ether;
        vm.deal(user, ethAmount);

        IComposeMailbox.MessageHeader memory ackHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: receiver,
            receiver: user,
            label: "ACK"
        });

        bytes memory payload;

        IComposeMailbox.Message memory ackMsg = IComposeMailbox.Message({
            header: ackHeader,
            payload: payload
        });

        vm.prank(coordinator);
        mailbox.putInbox(ackMsg);

        vm.expectRevert(IComposeBridge.NoAckMessage.selector);

        vm.prank(user);
        bridge.bridgeEthTo{value: ethAmount}(sourceChain, receiver, sessionId);
    }

    function testBridgeEthToRevertsIfAckHasInvalidPayload() public {
        uint256 ethAmount = 1 ether;
        vm.deal(user, ethAmount);

        IComposeMailbox.MessageHeader memory ackHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: receiver,
            receiver: user,
            label: "ACK"
        });

        bytes memory payload = abi.encode("bad data");

        IComposeMailbox.Message memory ackMsg = IComposeMailbox.Message({
            header: ackHeader,
            payload: payload
        });

        vm.prank(coordinator);
        mailbox.putInbox(ackMsg);

        vm.expectRevert(IComposeBridge.InvalidAckPayload.selector);

        vm.prank(user);
        bridge.bridgeEthTo{value: ethAmount}(sourceChain, receiver, sessionId);
    }


    function testBridgeEthToRevertsIfAckHasAnotherTokenSource() public {
        uint256 ethAmount = 1 ether;
        vm.deal(user, ethAmount);

        _putAck(
            sessionId,
            sourceChain,
            user,
            receiver,
            address(0x111),
            ethAmount
        );

        vm.expectRevert(IComposeBridge.AckSourceTokenMismatch.selector);

        vm.prank(user);
        bridge.bridgeEthTo{value: ethAmount}(sourceChain, receiver, sessionId);
    }


    function testBridgeEthToRevertsIfAckHasAnotherTokenAmount() public {
        uint256 ethAmount = 1 ether;
        vm.deal(user, ethAmount);

        _putAck(
            sessionId,
            sourceChain,
            user,
            receiver,
            address(0),
            ethAmount + 1
        );

        vm.expectRevert(IComposeBridge.AckAmountMismatch.selector);

        vm.prank(user);
        bridge.bridgeEthTo{value: ethAmount}(sourceChain, receiver, sessionId);
    }

    function testRedeemWrappedCET() public {
        ComposableERC20 coreCET = new ComposableERC20(
            l1Asset,
            sourceChain,
            name,
            symbol,
            decimals,
            address(bridge)
        );

        ComposableERC20 wrappedCET = new ComposableERC20(
            address(coreCET),
            block.chainid,
            name,
            symbol,
            decimals,
            address(bridge)
        );

        vm.prank(address(bridge));
        coreCET.crosschainMint(user, amount);
        vm.prank(address(bridge));
        wrappedCET.crosschainMint(user, amount);

        assertEq(wrappedCET.balanceOf(user), amount, "wrappedCET balance mismatch");
        assertEq(coreCET.balanceOf(user), amount, "coreCET balance mismatch");

        vm.expectEmit(true, true, true, true, address(bridge));
        emit IComposeBridge.WrappedCETRedeemed(address(wrappedCET), address(coreCET), user, amount);

        vm.prank(user);
        bridge.redeemWrappedCET(address(wrappedCET), address(coreCET), amount);
    }

    function testRedeemWrappedCETRevertsIfZeroAddresses() public {
        vm.expectRevert(IComposeBridge.ZeroAddress.selector);
        vm.prank(user);
        bridge.redeemWrappedCET(address(0), address(0), amount);

        ComposableERC20 coreCET = new ComposableERC20(
            l1Asset,
            sourceChain,
            name,
            symbol,
            decimals,
            address(bridge)
        );

        vm.expectRevert(IComposeBridge.ZeroAddress.selector);
        vm.prank(user);
        bridge.redeemWrappedCET(address(coreCET), address(0), amount);
    }


    function testRedeemWrappedCETRevertsIfInvalidAssetAddress() public {
        ComposableERC20 coreCET = new ComposableERC20(
            l1Asset,
            sourceChain,
            name,
            symbol,
            decimals,
            address(bridge)
        );

        ComposableERC20 wrongWrappedCET = new ComposableERC20(address(0xBADBAD), block.chainid, name, symbol, decimals, address(bridge));

        vm.expectRevert(IComposeBridge.InvalidAssetAddress.selector);

        vm.prank(user);
        bridge.redeemWrappedCET(address(wrongWrappedCET), address(coreCET), amount);
    }

    function testReceiveTokens_LocalAsset() public {
        erc20.mint(address(bridge), amount);

        IComposeMailbox.MessageHeader memory sendHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: user,
            receiver: receiver,
            label: "SEND_TOKEN"
        });

        bytes memory payload = abi.encode(
            block.chainid,
            address(erc20),
            amount,
            erc20.name(),
            erc20.symbol(),
            erc20.decimals()
        );

        IComposeMailbox.Message memory msgData = IComposeMailbox.Message({
            header: sendHeader,
            payload: payload
        });

        vm.prank(coordinator);
        mailbox.putInbox(msgData);

        assertEq(erc20.balanceOf(address(bridge)), amount, "bridge should start with locked tokens");
        assertEq(erc20.balanceOf(receiver), 0, "receiver should start empty");

        vm.expectEmit(true, true, true, true, address(bridge));
        emit IComposeBridge.TokensReceived(address(erc20), amount);

        vm.prank(receiver);
        (address token, uint256 receivedAmount) = bridge.receiveTokens(sendHeader);

        assertEq(token, address(erc20), "token address mismatch");
        assertEq(receivedAmount, amount, "amount mismatch");

        assertEq(erc20.balanceOf(address(bridge)), 0, "bridge balance should be reduced");
        assertEq(erc20.balanceOf(receiver), amount, "receiver should receive tokens");

        IComposeMailbox.MessageHeader memory ackHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sendHeader.chainDest,
            chainDest: sendHeader.chainSrc,
            sender: sendHeader.receiver,
            receiver: sendHeader.sender,
            label: "ACK"
        });

        bytes32 key = keccak256(
            abi.encodePacked(
                ackHeader.sessionId,
                ackHeader.chainSrc,
                ackHeader.chainDest,
                ackHeader.sender,
                ackHeader.receiver,
                ackHeader.label
            )
        );

        bytes memory ackPayload = mailbox.outbox(key);
        (address ackToken, uint256 ackAmount) = abi.decode(ackPayload, (address, uint256));

        assertEq(ackToken, address(erc20), "ack token mismatch");
        assertEq(ackAmount, amount, "ack amount mismatch");
    }

    function testReceiveTokens_MintCET() public {
        IComposeMailbox.MessageHeader memory sendHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: user,
            receiver: receiver,
            label: "SEND_TOKEN"
        });

        bytes memory payload = abi.encode(
            sourceChain,
            l1Asset,
            amount,
            name,
            symbol,
            decimals
        );

        IComposeMailbox.Message memory msgData = IComposeMailbox.Message({
            header: sendHeader,
            payload: payload
        });

        vm.prank(coordinator);
        mailbox.putInbox(msgData);

        address predictedCET = cetFactory.predictAddress(
            l1Asset,
            sourceChain,
            decimals,
            name,
            symbol,
            address(bridge)
        );

        vm.expectEmit(true, true, true, true, address(bridge));
        emit IComposeBridge.TokensReceived(predictedCET, amount);

        vm.prank(receiver);
        (address cet, uint256 receivedAmount) = bridge.receiveTokens(sendHeader);

        assertEq(cet, predictedCET, "CET deployed at unexpected address");
        assertEq(receivedAmount, amount, "amount mismatch");
        assertGt(cet.code.length, 0, "CET should be deployed");
        assertEq(IComposableERC20(cet).getRemoteAsset(), l1Asset, "remote asset mismatch");
        assertEq(IComposableERC20(cet).getRemoteChainID(), sourceChain, "remote chain mismatch");
        assertEq(IERC20(cet).balanceOf(receiver), amount, "receiver should have minted CET");

        IComposeMailbox.MessageHeader memory ackHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sendHeader.chainDest,
            chainDest: sendHeader.chainSrc,
            sender: sendHeader.receiver,
            receiver: sendHeader.sender,
            label: "ACK"
        });

        bytes32 key = keccak256(
            abi.encodePacked(
                ackHeader.sessionId,
                ackHeader.chainSrc,
                ackHeader.chainDest,
                ackHeader.sender,
                ackHeader.receiver,
                ackHeader.label
            )
        );

        bytes memory ackPayload = mailbox.outbox(key);
        (address ackToken, uint256 ackAmount) = abi.decode(ackPayload, (address, uint256));

        assertEq(ackToken, predictedCET, "ack token mismatch");
        assertEq(ackAmount, amount, "ack amount mismatch");
    }

    function testReceiveTokens_RevertsIfNotReceiver() public {
        IComposeMailbox.MessageHeader memory sendHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: user,
            receiver: receiver,
            label: "SEND_TOKEN"
        });

        vm.expectRevert(IComposeBridge.NotReceiver.selector);

        vm.prank(user);
        bridge.receiveTokens(sendHeader);
    }

    function testReceiveTokens_RevertsIfWrongDestinationChain() public {
        IComposeMailbox.MessageHeader memory sendHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: 9999, // incorrect destination
            sender: user,
            receiver: receiver,
            label: "SEND_TOKEN"
        });

        vm.expectRevert(IComposeBridge.WrongDestinationChain.selector);

        vm.prank(receiver);
        bridge.receiveTokens(sendHeader);
    }

    function testReceiveTokens_RevertsIfInvalidLabel() public {
        IComposeMailbox.MessageHeader memory sendHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: user,
            receiver: receiver,
            label: "INVALID_LABEL"
        });

        vm.expectRevert(IComposeBridge.InvalidMessage.selector);

        vm.prank(receiver);
        bridge.receiveTokens(sendHeader);
    }

    function testReceiveTokens_RevertsIfSendMessageEmpty() public {
        IComposeMailbox.MessageHeader memory sendHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: user,
            receiver: receiver,
            label: "SEND_TOKEN"
        });

        IComposeMailbox.Message memory msgData = IComposeMailbox.Message({
            header: sendHeader,
            payload: bytes("")
        });

        vm.prank(coordinator);
        mailbox.putInbox(msgData);

        vm.expectRevert(IComposeBridge.NoSendMessage.selector);

        vm.prank(receiver);
        bridge.receiveTokens(sendHeader);
    }

    function testReceiveETH_HappyFlow() public {
        uint256 ethAmount = 1 ether;

        IComposeMailbox.MessageHeader memory sendHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: user,
            receiver: receiver,
            label: "SEND_ETH"
        });

        bytes memory payload = abi.encode(sourceChain, ethAmount);

        IComposeMailbox.Message memory msgData = IComposeMailbox.Message({
            header: sendHeader,
            payload: payload
        });

        vm.prank(coordinator);
        mailbox.putInbox(msgData);

        vm.deal(address(ethLiquidity), ethAmount);
        vm.deal(address(bridge), ethAmount);

        vm.expectEmit(true, true, true, true, address(bridge));
        emit IComposeBridge.ETHReceived(receiver, ethAmount);

        vm.expectEmit(true, true, true, true, address(bridge));
        emit IComposeBridge.MailboxAckWrite(sourceChain, receiver, sessionId, "ACK");

        uint256 receiverBalanceBefore = receiver.balance;

        vm.prank(receiver);
        uint256 receivedAmount = bridge.receiveETH(sendHeader);

        assertEq(receivedAmount, ethAmount, "received amount mismatch");
        assertEq(receiver.balance, receiverBalanceBefore + ethAmount, "receiver should get ETH");

        IComposeMailbox.MessageHeader memory ackHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sendHeader.chainDest,
            chainDest: sendHeader.chainSrc,
            sender: sendHeader.receiver,
            receiver: sendHeader.sender,
            label: "ACK"
        });

        bytes32 key = keccak256(
            abi.encodePacked(
                ackHeader.sessionId,
                ackHeader.chainSrc,
                ackHeader.chainDest,
                ackHeader.sender,
                ackHeader.receiver,
                ackHeader.label
            )
        );

        bytes memory ackPayload = mailbox.outbox(key);
        (address ackToken, uint256 ackAmount) = abi.decode(ackPayload, (address, uint256));

        assertEq(ackToken, address(0), "ack token should be ETH (address(0))");
        assertEq(ackAmount, ethAmount, "ack amount mismatch");
    }

    function testReceiveETH_RevertsIfNotReceiver() public {
        IComposeMailbox.MessageHeader memory sendHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: user,
            receiver: receiver,
            label: "SEND_ETH"
        });

        vm.expectRevert(IComposeBridge.NotReceiver.selector);

        vm.prank(user);
        bridge.receiveETH(sendHeader);
    }

    function testReceiveETH_RevertsIfWrongDestinationChain() public {
        IComposeMailbox.MessageHeader memory sendHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: 9999,
            sender: user,
            receiver: receiver,
            label: "SEND_ETH"
        });

        vm.expectRevert(IComposeBridge.WrongDestinationChain.selector);

        vm.prank(receiver);
        bridge.receiveETH(sendHeader);
    }

    function testReceiveETH_RevertsIfInvalidLabel() public {
        IComposeMailbox.MessageHeader memory sendHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: user,
            receiver: receiver,
            label: "INVALID_LABEL"
        });

        vm.expectRevert(IComposeBridge.InvalidMessage.selector);

        vm.prank(receiver);
        bridge.receiveETH(sendHeader);
    }

    function testReceiveETH_RevertsIfSendMessageEmpty() public {
        IComposeMailbox.MessageHeader memory sendHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId,
            chainSrc: sourceChain,
            chainDest: block.chainid,
            sender: user,
            receiver: receiver,
            label: "SEND_ETH"
        });

        IComposeMailbox.Message memory msgData = IComposeMailbox.Message({
            header: sendHeader,
            payload: bytes("")
        });

        vm.prank(coordinator);
        mailbox.putInbox(msgData);

        vm.expectRevert(IComposeBridge.NoSendMessage.selector);

        vm.prank(receiver);
        bridge.receiveETH(sendHeader);
    }

    function _putAck(
        uint256 sessionId_,
        uint256 srcChainId,
        address senderOnSrc,
        address receiverOnDest,
        address tokenSrc,
        uint256 amount
    ) internal {
        IComposeMailbox.MessageHeader memory ackHeader = IComposeMailbox.MessageHeader({
            sessionId: sessionId_,
            chainSrc: srcChainId,
            chainDest: block.chainid,
            sender: receiverOnDest,
            receiver: senderOnSrc,
            label: "ACK"
        });

        bytes memory payload = abi.encode(tokenSrc, amount);

        IComposeMailbox.Message memory ackMsg = IComposeMailbox.Message({
            header: ackHeader,
            payload: payload
        });

        vm.prank(coordinator);
        mailbox.putInbox(ackMsg);
    }
}