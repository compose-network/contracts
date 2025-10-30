// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Setup } from "@ssv/test/Setup.t.sol";
import { ComposableERC20 } from "@ssv/src/bridge/ComposableErc20.sol";
import { IComposableERC20 } from "@ssv/src/bridge/interfaces/IComposableERC20.sol";

import { IERC7802 } from "@openzeppelin/contracts/interfaces/draft-IERC7802.sol";

contract ComposableErc20Test is Setup {
    ComposableERC20 internal token;

    address internal remoteAssetAddress = address(123);
    address internal bridgeAddress = address(456);
    uint256 internal remoteChainId = 1337;
    string internal name = "SomeToken";
    string internal symbol = "SomeSymbol";
    uint8 internal decimals = 6;

    address internal tokenReceiver = address(789);
    uint256 internal mintAmount = 322;

    function setUp() public override {
        token = _deployComposableErc20(
            remoteAssetAddress,
            remoteChainId,
            name,
            symbol,
            decimals,
            bridgeAddress
        );
    }

    function testConstructor() public {
        assertEq(token.remoteAsset(), remoteAssetAddress);
        assertEq(token.remoteChainID(), remoteChainId);
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);
        assertEq(token.bridge(), bridgeAddress);
    }

    function testCrosschainMint() public {
        vm.prank(bridgeAddress);
        vm.expectEmit(true, true, true, true, address(token));
        emit IERC7802.CrosschainMint(tokenReceiver, mintAmount, bridgeAddress);

        token.crosschainMint(tokenReceiver, mintAmount);

        assertEq(token.balanceOf(tokenReceiver), mintAmount);
    }

    function testCrosschainMintRevertedWhenCallerNotBridge() public {
        vm.expectRevert(IComposableERC20.Unauthorized.selector);
        token.crosschainMint(tokenReceiver, mintAmount);
    }

    function testCrosschainBurn() public {
        vm.startPrank(bridgeAddress);
        token.crosschainMint(tokenReceiver, mintAmount);

        vm.expectEmit(true, true, true, true, address(token));
        emit IERC7802.CrosschainBurn(tokenReceiver, mintAmount, bridgeAddress);

        token.crosschainBurn(tokenReceiver, mintAmount);

        assertEq(token.balanceOf(tokenReceiver), 0);
        vm.stopPrank();
    }

    function testCrossChainBurnRevertedWhenCallerNotBridge() public {
        vm.expectRevert(IComposableERC20.Unauthorized.selector);
        token.crosschainBurn(tokenReceiver, mintAmount);
    }
}