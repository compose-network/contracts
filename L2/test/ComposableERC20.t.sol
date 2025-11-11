// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { ComposableERC20 } from "@ssv/src/bridge/ComposableErc20.sol";
import { IComposableERC20 } from "@ssv/src/bridge/interfaces/IComposableERC20.sol";

import { IERC7802 } from "@openzeppelin/contracts/interfaces/draft-IERC7802.sol";

contract ComposableERC20Test is Test {
    ComposableERC20 internal token;

    address internal remoteAssetAddress = address(123);
    address internal bridgeAddress = address(456);
    uint256 internal remoteChainId = 1337;
    string internal name = "SomeToken";
    string internal symbol = "SomeSymbol";
    uint8 internal decimals = 6;

    address internal user = address(0xBEEF);
    uint256 internal mintAmount = 322;

    function setUp() public {
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
        IComposableERC20.BridgedComposeTokenERC20Metadata memory metadata = token.metadata();

        assertEq(metadata.remoteAsset, remoteAssetAddress);
        assertEq(metadata.remoteChainID, remoteChainId);
        assertEq(metadata.name, name);
        assertEq(metadata.symbol, symbol);
        assertEq(metadata.decimals, decimals);

        assertEq(token.bridge(), bridgeAddress);
    }

    function testCrossChainMint() public {
        uint256 userBalanceBefore = token.balanceOf(user);

        vm.prank(bridgeAddress);
        token.crosschainMint(user, mintAmount);

        uint256 userBalanceAfter = token.balanceOf(user);

        assertEq(userBalanceAfter - userBalanceBefore, mintAmount);
    }

    function testCrossChainMingRevertsIfCallerNotBridge() public {
        vm.expectRevert(IComposableERC20.Unauthorized.selector);
        token.crosschainMint(user, mintAmount);
    }

    function testCrossChainBurn() public {
        testCrossChainMint(); // mints mintAmount to user

        uint256 userBalanceBefore = token.balanceOf(user);

        vm.prank(bridgeAddress);
        token.crosschainBurn(user, mintAmount);

        uint256 userBalanceAfter = token.balanceOf(user);

        assertEq(userBalanceBefore, mintAmount);
        assertEq(userBalanceAfter, 0);
    }

    function testCrossChainBurnRevertsIfCallerNotBridge() public {
        vm.expectRevert(IComposableERC20.Unauthorized.selector);
        token.crosschainBurn(user, mintAmount);
    }

    function testGetters() public {
        assertEq(token.getRemoteChainID(), remoteChainId);
        assertEq(token.getRemoteAsset(), remoteAssetAddress);
    }

    function _deployComposableErc20(
        address _remoteAsset,
        uint256 _remoteChainID,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address bridgeAddress
    ) internal returns (ComposableERC20) {
        ComposableERC20 createdToken = new ComposableERC20(
            _remoteAsset,
            _remoteChainID,
            _name,
            _symbol,
            _decimals,
            bridgeAddress
        );

        vm.label(address(createdToken), "CETToken");
        return createdToken;
    }
}