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
        try vm.parseTomlAddress(tomlContent(), networkKey("guardian")) returns (address addr) {
            return addr;
        } catch {
            return address(0);
        }
    }
    
    /// @notice Address of the proxy admin owner
    function proxyAdminOwner() internal view returns (address) {
        try vm.parseTomlAddress(tomlContent(), networkKey("proxy_admin_owner")) returns (address addr) {
            return addr;
        } catch {
            return address(0);
        }
    }
    
    /// @notice Address of the authorized proposer (shared publisher)
    function authorizedProposer() internal view returns (address) {
        try vm.parseTomlAddress(tomlContent(), networkKey("authorized_proposer")) returns (address addr) {
            return addr;
        } catch {
            return address(0);
        }
    }
    
    /// @notice SP1 verifier contract address
    function sp1Verifier() internal view returns (address) {
        try vm.parseTomlAddress(tomlContent(), networkKey("sp1_verifier")) returns (address addr) {
            return addr;
        } catch {
            return address(0);
        }
    }
    
    /// @notice Aggregation verification key (bytes32)
    function aggregationVkey() internal view returns (bytes32) {
        try vm.parseTomlBytes32(tomlContent(), networkKey("aggregation_vkey")) returns (bytes32 vkey) {
            return vkey;
        } catch {
            return bytes32(0);
        }
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
    
    // ============ Network Configuration ============
    
    /// @notice RPC URL from networks.toml
    function rpcUrl() internal view returns (string memory) {
        try vm.parseTomlString(tomlContent(), networkKey("rpc_url")) returns (string memory url) {
            return url;
        } catch {
            return "";
        }
    }
    
    /// @notice Chain ID from networks.toml
    function chainId() internal view returns (uint256) {
        try vm.parseTomlUint(tomlContent(), networkKey("chain_id")) returns (uint256 id) {
            return id;
        } catch {
            return 0;
        }
    }
    
    // ============ Test Configuration ============
    
    /// @notice Whether this is a fork test
    function forkTest() internal view returns (bool) {
        return vm.envOr("FORK_TEST", false);
    }
    
    /// @notice RPC URL for fork tests
    function forkRpcUrl() internal view returns (string memory) {
        return vm.envOr("FORK_RPC_URL", string(""));
    }
    
    /// @notice Block number for fork tests (0 = latest)
    function forkBlockNumber() internal view returns (uint256) {
        return vm.envOr("FORK_BLOCK_NUMBER", uint256(0));
    }
    
    /// @notice Chain ID to fork
    function forkChainId() internal view returns (uint256) {
        return vm.envOr("FORK_CHAIN_ID", uint256(0));
    }
    
    // ============ Output Configuration ============
    
    /// @notice Path to deployment output file
    function deploymentOutfile() internal view returns (string memory) {
        return vm.envOr("DEPLOYMENT_OUTFILE", string("deployments.json"));
    }
    
    /// @notice Path to deployment artifacts directory
    function deploymentsPath() internal view returns (string memory) {
        return vm.envOr("DEPLOYMENTS_PATH", string("deployments/"));
    }
    
    /// @notice Private key for broadcasting (from env, not TOML for security)
    function privateKey() internal view returns (uint256) {
        // Default to anvil test key if not set (unsafe, only for testing)
        return vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
    }
    
    /// @notice Deployer address (derived from private key or set directly)
    function deployer() internal view returns (address) {
        address envDeployer = vm.envOr("DEPLOYER", address(0));
        if (envDeployer != address(0)) {
            return envDeployer;
        }
        // Derive from private key
        return vm.addr(privateKey());
    }
    
    // ============ Validation ============
    
    /// @notice Validates that all required config is set for production deployment
    function validateProductionConfig() internal view {
        string memory network = networkName();
        require(bytes(network).length > 0, "ComposeConfig: NETWORK_NAME not set");
        require(guardian() != address(0), "ComposeConfig: guardian not set in networks.toml");
        require(proxyAdminOwner() != address(0), "ComposeConfig: proxy_admin_owner not set in networks.toml");
        require(authorizedProposer() != address(0), "ComposeConfig: authorized_proposer not set in networks.toml");
        require(sp1Verifier() != address(0), "ComposeConfig: sp1_verifier not set in networks.toml");
        require(aggregationVkey() != bytes32(0), "ComposeConfig: aggregation_vkey not set in networks.toml");
        require(bytes(rpcUrl()).length > 0, "ComposeConfig: rpc_url not set in networks.toml");
        require(chainId() != 0, "ComposeConfig: chain_id not set in networks.toml");
    }
}
