// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Vm } from "forge-std/Vm.sol";
import { stdToml } from "forge-std/StdToml.sol";

/// @title ComposeConfig
/// @notice Centralized configuration management from networks.toml.
///         Reads network-specific configuration based on NETWORK_NAME env var.
library ComposeConfig {
    using stdToml for string;
    
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    
    /// @notice Path to networks configuration file
    string private constant NETWORKS_TOML = "networks.toml";
    
    /// @notice Get the current network name from env
    function networkName() internal view returns (string memory) {
        return vm.envOr("NETWORK_NAME", string(""));
    }
    
    /// @notice Build TOML key path for current network
    function networkKey(string memory key) internal view returns (string memory) {
        string memory network = networkName();
        require(bytes(network).length > 0, "ComposeConfig: NETWORK_NAME not set");
        return string(abi.encodePacked(".networks.", network, ".", key));
    }
    
    /// @notice Read TOML file content
    function tomlContent() internal view returns (string memory) {
        return vm.readFile(NETWORKS_TOML);
    }
    
    // ============ Deployment Configuration ============
    
    /// @notice Address of the Compose guardian (can pause cluster)
    function guardian() internal view returns (address) {
        address addr = vm.parseTomlAddress(tomlContent(), networkKey("guardian"));
        require(addr != address(0), "ComposeConfig: guardian not set in networks.toml");
        return addr;
    }
    
    /// @notice Address of the proxy admin owner
    function proxyAdminOwner() internal view returns (address) {
        address addr = vm.parseTomlAddress(tomlContent(), networkKey("proxy_admin_owner"));
        require(addr != address(0), "ComposeConfig: proxy_admin_owner not set in networks.toml");
        return addr;
    }
    
    /// @notice Address of the authorized proposer (shared publisher)
    function authorizedProposer() internal view returns (address) {
        address addr = vm.parseTomlAddress(tomlContent(), networkKey("authorized_proposer"));
        require(addr != address(0), "ComposeConfig: authorized_proposer not set in networks.toml");
        return addr;
    }
    
    /// @notice SP1 verifier contract address
    function sp1Verifier() internal view returns (address) {
        address addr = vm.parseTomlAddress(tomlContent(), networkKey("sp1_verifier"));
        require(addr != address(0), "ComposeConfig: sp1_verifier not set in networks.toml");
        return addr;
    }
    
    /// @notice Aggregation verification key (bytes32)
    function aggregationVkey() internal view returns (bytes32) {
        bytes32 vkey = vm.parseTomlBytes32(tomlContent(), networkKey("aggregation_vkey"));
        require(vkey != bytes32(0), "ComposeConfig: aggregation_vkey not set in networks.toml");
        return vkey;
    }
    
    /// @notice Proof maturity delay in seconds (default: 7 days)
    function proofMaturityDelaySeconds() internal view returns (uint256) {
        try vm.parseTomlUint(tomlContent(), networkKey("proof_maturity_delay_seconds")) returns (uint256 delay) {
            return delay;
        } catch {
            return 7 days;
        }
    }
    
    /// @notice Dispute game finality delay in seconds (default: 3.5 days)
    function disputeGameFinalityDelaySeconds() internal view returns (uint256) {
        try vm.parseTomlUint(tomlContent(), networkKey("dispute_game_finality_delay_seconds")) returns (uint256 delay) {
            return delay;
        } catch {
            return 3.5 days;
        }
    }
    
    /// @notice Initial bond amount for dispute games (default: 0.08 ether)
    function disputeGameInitBond() internal view returns (uint256) {
        try vm.parseTomlUint(tomlContent(), networkKey("dispute_game_init_bond")) returns (uint256 bond) {
            return bond;
        } catch {
            return 0.08 ether;
        }
    }
    
    
    // ============ Validation ============
    
    /// @notice Validates that all required config is set for deployment
    /// @dev All getter functions now enforce requirements, so this just checks network name
    function validateConfig() internal view {
        string memory network = networkName();
        require(bytes(network).length > 0, "ComposeConfig: NETWORK_NAME not set");
        
        // Calling these will revert if not set
        guardian();
        proxyAdminOwner();
        authorizedProposer();
        sp1Verifier();
        aggregationVkey();
    }
}
