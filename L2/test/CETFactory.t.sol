// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { ComposableERC20 } from "@ssv/src/bridge/ComposableErc20.sol";
import { ICETFactory } from "@ssv/src/bridge/interfaces/ICetFactory.sol";
import { CetFactory } from "@ssv/src/bridge/CetFactory.sol";

contract CETFactoryTest is Test {
    CetFactory internal factory;

    address internal remoteAssetAddress = address(123);
    address internal bridgeAddress = address(456);
    uint256 internal remoteChainId = 1337;
    string internal name = "SomeToken";
    string internal symbol = "SomeSymbol";
    uint8 internal decimals = 6;

    function setUp() public {
        factory = new CetFactory();
    }

    function testComputeSalt() public {
        bytes32 expectedSalt = keccak256(abi.encode(remoteAssetAddress, remoteChainId));
        bytes32 returnedSalt = factory.computeSalt(remoteAssetAddress, remoteChainId);

        assertEq(expectedSalt, returnedSalt);
    }

    function testPredictAddress() public {
        bytes32 expectedSalt = keccak256(abi.encode(remoteAssetAddress, remoteChainId));

        bytes memory ctorArgs = abi.encode(
            remoteAssetAddress,
            remoteChainId,
            name,
            symbol,
            decimals,
            bridgeAddress
        );

        bytes32 creationHash = keccak256(
            abi.encodePacked(type(ComposableERC20).creationCode, ctorArgs)
        );

        address expectedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(factory),
                            expectedSalt,
                            creationHash
                        )
                    )
                )
            )
        );

        address returnedAddress = factory.predictAddress(
            remoteAssetAddress,
            remoteChainId,
            decimals,
            name,
            symbol,
            bridgeAddress
        );

        assertEq(expectedAddress, returnedAddress);
    }

    function testFuzzPredictAddress(
        address l1Asset,
        uint256 remoteChainID,
        uint8 decimals,
        string memory name,
        string memory symbol,
        address bridge
    ) public {
        vm.assume(remoteChainID != 0);

        vm.assume(bytes(name).length > 0);
        vm.assume(bytes(symbol).length > 0);

        vm.assume(decimals <= 18);

        bytes32 expectedSalt = keccak256(abi.encode(l1Asset, remoteChainID));

        bytes memory ctorArgs = abi.encode(
            l1Asset,
            remoteChainID,
            name,
            symbol,
            decimals,
            bridge
        );

        bytes32 creationHash = keccak256(
            abi.encodePacked(type(ComposableERC20).creationCode, ctorArgs)
        );

        address expectedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(factory),
                            expectedSalt,
                            creationHash
                        )
                    )
                )
            )
        );

        address returnedAddress = factory.predictAddress(
            l1Asset,
            remoteChainID,
            decimals,
            name,
            symbol,
            bridge
        );

        assertEq(expectedAddress, returnedAddress, "Predict address mismatch");
    }

    function testDeployIfAbsent_FirstDeployment() public {
        address predicted = _predictAddress();

        assertEq(predicted.code.length, 0, "Predicted address already has code");

        address deployed = factory.deployIfAbsent(
            remoteAssetAddress,
            remoteChainId,
            decimals,
            name,
            symbol,
            bridgeAddress
        );

        assertEq(deployed, predicted, "Deployed != predicted");

        assertGt(deployed.code.length, 0, "No bytecode at deployed address");

        ComposableERC20 token = ComposableERC20(deployed);
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);
    }

    function testDeployIfAbsent_SecondCallReturnsSameAddress() public {
        address first = factory.deployIfAbsent(
            remoteAssetAddress,
            remoteChainId,
            decimals,
            name,
            symbol,
            bridgeAddress
        );

        address second = factory.deployIfAbsent(
            remoteAssetAddress,
            remoteChainId,
            decimals,
            name,
            symbol,
            bridgeAddress
        );

        assertEq(first, second, "Second call returned different address");

        ComposableERC20 token = ComposableERC20(second);
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);
    }

    function _predictAddress() internal view returns (address) {
        return factory.predictAddress(
            remoteAssetAddress,
            remoteChainId,
            decimals,
            name,
            symbol,
            bridgeAddress
        );
    }
}
