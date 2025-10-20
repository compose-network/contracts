// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { WETH9 } from "@external/WETH9.sol";

/**
 * @title DeployWETH
 * @notice Deployment script for WETH9 token on L2 networks
 * @dev Deploys WETH9 using CREATE2 for deterministic addresses across networks
 * @dev Note: WETH9 ported to 0.8.30 for unified compilation
 */
contract DeployWETH is Script {
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
        console.log("Deploying WETH9 to:", networkName);
        console.log("Chain ID:", block.chainid);
        console.log("Deploy Salt:", vm.toString(salt));
        console.log("========================================");

        vm.startBroadcast();

        // Deploy WETH9
        address wethAddr = _deployCreate2(
            salt,
            type(WETH9).creationCode
        );
        WETH9 weth = WETH9(payable(wethAddr));

        vm.stopBroadcast();

        console.log("========================================");
        console.log("WETH9 Deployment Summary:");
        console.log("  WETH:", address(weth));
        console.log("  Name:", weth.name());
        console.log("  Symbol:", weth.symbol());
        console.log("========================================");

        // Save deployment info to JSON
        finalJson = _saveToJson(weth);
        
        // Write to artifacts directory with network name
        string memory filename = string.concat("artifacts/deploy-weth-", networkName, ".json");
        vm.writeJson(finalJson, filename);
        
        console.log("Deployment saved to:", filename);
        
        return finalJson;
    }

    /**
     * @notice Create JSON output with deployment information
     */
    function _saveToJson(WETH9 weth) internal returns (string memory) {
        string memory parent = "parent";

        string memory deployed_addresses = "addresses";
        string memory deployed_addresses_output = vm.serializeAddress(
            deployed_addresses,
            "WETH",
            address(weth)
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
