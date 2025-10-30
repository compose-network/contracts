// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Setup } from "@ssv/test/Setup.t.sol";
import { UniversalBridge } from "@ssv/src/bridge/UniversalBridge.sol";
import { CetFactory } from "@ssv/src/bridge/CetFactory.sol";
import { ComposableERC20 } from "@ssv/src/bridge/ComposableErc20.sol";
import { IMailbox } from "@ssv/src/core/interfaces/IMailbox.sol";
import { IUniversalBridge } from "@ssv/src/bridge/interfaces/IUniversalBridge.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract UniversalBridgeTest is Setup {
    UniversalBridge internal bridgeU;
    CetFactory internal cetFactory;

    address internal l1Asset = address(0xAAAA);
    address internal tokenSrc;
    address internal receiver;
    uint256 internal amount = 1000;
    uint256 internal sessionId = 12345;

    string internal name = "TestToken";
    string internal symbol = "TT";
    uint8 internal decimals = 18;
    uint256 internal originChainId = 1;

    function setUp() public override {
        super.setUp();

        cetFactory = new CetFactory();
        bridgeU = new UniversalBridge(address(mailbox), address(cetFactory));

        tokenSrc = address(
            new ComposableERC20(
                l1Asset,
                block.chainid,
                name,
                symbol,
                decimals,
                address(bridgeU)
            )
        );

        receiver = COORDINATOR;
    }

    function _putAckForCheck(uint256 sessionId_) internal {
        vm.prank(COORDINATOR);
        mailbox.putInbox(
            block.chainid,
            address(bridgeU),
            address(bridgeU),
            sessionId_,
            "ACK",
            abi.encode(true)
        );
    }

    function _putSend(
        uint256 chainSrc,
        address sender,
        address receiverForMailbox,
        uint256 sessionId_,
        bytes memory payload
    ) internal {
        vm.prank(COORDINATOR);
        mailbox.putInbox(
            chainSrc,
            sender,
            receiverForMailbox,
            sessionId_,
            "SEND",
            payload
        );
    }

    function testBridgeERC20To_LocksAndWrites() public {
        _putAckForCheck(sessionId);

        vm.startPrank(address(bridgeU));
        ComposableERC20(tokenSrc).crosschainMint(DEPLOYER, amount);
        vm.stopPrank();

        vm.startPrank(DEPLOYER);
        IERC20(tokenSrc).approve(address(bridgeU), amount);

        vm.expectEmit(true, true, true, true);
        emit IUniversalBridge.TokensLocked(tokenSrc, DEPLOYER, amount);

        vm.expectEmit(true, true, true, true);
        emit IUniversalBridge.MailboxWrite(2, receiver, sessionId, "SEND");

        bridgeU.bridgeERC20To(2, tokenSrc, amount, receiver, sessionId);
        vm.stopPrank();
    }

    function testBridgeCETTo_BurnsAndWrites() public {
        _putAckForCheck(sessionId);

        address cetAddr = cetFactory.deployIfAbsent(
            l1Asset,
            originChainId,
            decimals,
            name,
            symbol,
            address(bridgeU)
        );

        vm.startPrank(address(bridgeU));
        ComposableERC20(cetAddr).crosschainMint(DEPLOYER, amount);
        vm.stopPrank();

        vm.startPrank(DEPLOYER);
        bridgeU.bridgeCETTo(2, cetAddr, amount, receiver, sessionId);
        vm.stopPrank();

        assertEq(ComposableERC20(cetAddr).balanceOf(DEPLOYER), 0);
    }

    function testReceiveTokens_MintsCETWhenNeeded() public {
        bytes memory payload = abi.encode(originChainId, l1Asset, amount);

        _putSend(originChainId, address(bridgeU), address(bridgeU), sessionId, payload);

        IMailbox.MessageHeader memory header = IMailbox.MessageHeader({
            chainSrc: originChainId,
            chainDest: block.chainid,
            sender: address(bridgeU),
            receiver: receiver,
            sessionId: sessionId,
            label: "SEND"
        });

        vm.startPrank(receiver);
        (address token, uint256 amt) = bridgeU.receiveTokens(header, name, symbol, decimals);
        vm.stopPrank();

        assertEq(amt, amount, "amount mismatch");
        assertGt(token.code.length, 0, "CET must exist");
        assertEq(IERC20(token).balanceOf(receiver), amount, "not minted to receiver");
    }

    function testReceiveTokens_RevertsWhenWrongCaller() public {
        IMailbox.MessageHeader memory header = IMailbox.MessageHeader({
            chainSrc: originChainId,
            chainDest: block.chainid,
            sender: address(bridgeU),
            receiver: receiver,
            sessionId: sessionId,
            label: "SEND"
        });

        vm.startPrank(address(0xBAD));
        vm.expectRevert(IUniversalBridge.NotReceiver.selector);
        bridgeU.receiveTokens(header, name, symbol, decimals);
        vm.stopPrank();
    }

    function testReceiveTokens_RevertsOnMissingMessage() public {
        IMailbox.MessageHeader memory header = IMailbox.MessageHeader({
            chainSrc: originChainId,
            chainDest: block.chainid,
            sender: address(bridgeU),
            receiver: receiver,
            sessionId: sessionId,
            label: "SEND"
        });

        vm.startPrank(receiver);
        vm.expectRevert(IMailbox.MessageNotFound.selector);
        bridgeU.receiveTokens(header, name, symbol, decimals);
        vm.stopPrank();
    }

    function testCheckAck_RevertsWithoutAck() public {
        vm.startPrank(address(bridgeU));
        ComposableERC20(tokenSrc).crosschainMint(DEPLOYER, amount);
        vm.stopPrank();

        vm.startPrank(DEPLOYER);
        IERC20(tokenSrc).approve(address(bridgeU), amount);
        vm.expectRevert(IMailbox.MessageNotFound.selector);
        bridgeU.bridgeERC20To(2, tokenSrc, amount, receiver, sessionId);
        vm.stopPrank();
    }
}