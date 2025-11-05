// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { SSVMintable } from "@ssv/src/dex/SSVMintable.sol";
import { USDCMintable } from "@ssv/src/dex/USDCMintable.sol";

/**
 * @title DeployDEXTokens
 * @notice Deployment script for SSV and USDC tokens on L2 networks
 * @dev Deploys tokens using CREATE2 for deterministic addresses across networks
 */
contract DeployDEXTokens is Script {
    using stdJson for string;

    /**
     * @notice Main deployment function
     * @param networkName Name of the network (for output filename)
     * @return finalJson JSON string with deployment information
     */
    function run(string memory networkName) 
        public 
        returns (string memory finalJson) 
    {
        bytes32 salt = vm.envBytes32("DEPLOY_SALT");

        console.log("========================================");
        console.log("Deploying DEX Tokens to:", networkName);
        console.log("Chain ID:", block.chainid);
        console.log("Deploy Salt:", vm.toString(salt));
        console.log("========================================");

        vm.startBroadcast();

        // Deploy SSV Token
        address ssvAddr = _deployCreate2(
            salt,
            type(SSVMintable).creationCode
        );
        SSVMintable ssv = SSVMintable(ssvAddr);
        console.log("SSV Token deployed at:", address(ssv));

        // Deploy USDC Token
        address usdcAddr = _deployCreate2(
            salt,
            type(USDCMintable).creationCode
        );
        USDCMintable usdc = USDCMintable(usdcAddr);
        console.log("USDC Token deployed at:", address(usdc));

        vm.stopBroadcast();

        console.log("========================================");
        console.log("DEX Tokens Deployment Summary:");
        console.log("  SSV:   ", address(ssv));
        console.log("  USDC:  ", address(usdc));
        console.log("========================================");

        // Save deployment info to JSON
        finalJson = _saveToJson(ssv, usdc);
        
        // Write to artifacts directory with network name
        string memory filename = string.concat("artifacts/deploy-dex-tokens-", networkName, ".json");
        vm.writeJson(finalJson, filename);
        
        console.log("Deployment saved to:", filename);
        
        return finalJson;
    }

    /**
     * @notice Create JSON output with deployment information
     */
    function _saveToJson(
        SSVMintable ssv,
        USDCMintable usdc
    ) internal returns (string memory) {
        string memory parent = "parent";

        string memory deployed_addresses = "addresses";
        vm.serializeAddress(deployed_addresses, "SSV", address(ssv));
        string memory deployed_addresses_output = vm.serializeAddress(
            deployed_addresses,
            "USDC",
            address(usdc)
        );

        string memory chain_info = "chainInfo";
        vm.serializeUint(chain_info, "deploymentBlock", block.number);
        string memory chain_info_output = vm.serializeUint(
            chain_info,
            "chainId",
            block.chainid
        );

        vm.serializeString(
            parent,
            deployed_addresses,
            deployed_addresses_output
        );
        return vm.serializeString(parent, chain_info, chain_info_output);
    }

    /**
     * @notice Deploy contract using CREATE2 for deterministic addresses
     * @param salt Salt for CREATE2
     * @param code Contract bytecode
     * @return addr Deployed contract address
     */
    function _deployCreate2(bytes32 salt, bytes memory code) 
        internal 
        returns (address addr) 
    {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }
}
