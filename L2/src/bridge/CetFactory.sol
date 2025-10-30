// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.30;

import { ComposableERC20 } from "@ssv/src/bridge/ComposableErc20.sol";
import { ICETFactory } from "@ssv/src/bridge/interfaces/ICetFactory.sol";

contract CetFactory is ICETFactory {
    function computeSalt(address l1Asset, uint256 remoteChainID) public pure returns (bytes32){
        return keccak256(abi.encode(l1Asset, remoteChainID));
    }

    function predictAddress(
        address l1Asset,
        uint256 remoteChainID,
        uint8 decimals,
        string memory name,
        string memory symbol,
        address bridge
    ) public view returns (address) {
        bytes32 salt = computeSalt(l1Asset, remoteChainID);

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

        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            creationHash
                        )
                    )
                )
            )
        );
    }

    function deployIfAbsent(
        address l1Asset,
        uint256 remoteChainID,
        uint8 decimals,
        string calldata name,
        string calldata symbol,
        address bridge
    ) external returns (address deployed) {
        bytes32 salt = computeSalt(l1Asset, remoteChainID);

        address predicted = predictAddress(
            l1Asset,
            remoteChainID,
            decimals,
            name,
            symbol,
            bridge
        );

        if (predicted.code.length > 0) {
            return predicted;
        }

        deployed = address(
            new ComposableERC20{salt: salt}(
                l1Asset,
                remoteChainID,
                name,
                symbol,
                decimals,
                bridge
            )
        );

        require(deployed == predicted, "CetFactory: address mismatch");
        return deployed;
    }
}