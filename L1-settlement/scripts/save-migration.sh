#!/usr/bin/env bash
# Save rollup migration data to deployments/rollups/{ROLLUP}.json with enhanced metadata

set -euo pipefail

ROLLUP_NAME=$1
COMPOSE_NETWORK=$2
L2_CHAIN_ID=$3
NETWORK_CHAIN_ID=$4
IS_FORK=${5:-false}

# Proxy addresses from rollup config
SYSTEM_CONFIG_PROXY=$6
OPTIMISM_PORTAL_PROXY=$7
L1_CROSS_DOMAIN_MESSENGER_PROXY=$8
L1_STANDARD_BRIDGE_PROXY=$9
L1_ERC721_BRIDGE_PROXY=$10

# Old implementation addresses from rollup config
OLD_OPTIMISM_PORTAL_IMPL=${11}

# Determine output directory and broadcast path based on whether this is a fork migration
if [ "$IS_FORK" = "true" ]; then
    DEPLOYMENTS_DIR="deployments/rollups/fork"
    BROADCAST_DIR="broadcast/MigrateRollup.s.sol/$NETWORK_CHAIN_ID/dry-run"
else
    DEPLOYMENTS_DIR="deployments/rollups"
    BROADCAST_DIR="broadcast/MigrateRollup.s.sol/$NETWORK_CHAIN_ID"
fi

DEPLOYMENT_FILE="$DEPLOYMENTS_DIR/${ROLLUP_NAME}.json"

# Create deployments directory if it doesn't exist
mkdir -p "$DEPLOYMENTS_DIR"

# Parse broadcast data for enhanced metadata
# Disable exit-on-error temporarily for the ls command
set +e
BROADCAST_FILE=$(ls -t "$BROADCAST_DIR"/run-*.json 2>/dev/null | head -1)
set -e

if [ -z "$BROADCAST_FILE" ]; then
    echo "Error: Could not find broadcast output for MigrateRollup in $BROADCAST_DIR"
    echo "Available files in directory:"
    ls -la "$BROADCAST_DIR" 2>&1 || echo "Directory does not exist"
    exit 1
fi

# Get migration metadata from receipts (actual onchain data)
# For fork/dry-run, receipts may be null, so use transactions data as fallback
MIGRATION_BLOCK=$(jq -r '.receipts[0].blockNumber // "0"' "$BROADCAST_FILE")
MIGRATION_BLOCK_DEC=$((MIGRATION_BLOCK))
MIGRATOR=$(jq -r '.receipts[0].from // .transactions[0].from // "0x0000000000000000000000000000000000000000"' "$BROADCAST_FILE")
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# Get new implementation addresses from CREATE transactions
SYSTEM_CONFIG_IMPL=$(jq -r '.transactions[] | select(.contractName == "SystemConfig" and .transactionType == "CREATE") | .contractAddress' "$BROADCAST_FILE" | head -1)
OPTIMISM_PORTAL_IMPL=$(jq -r '.transactions[] | select(.contractName == "OptimismPortalInterop" and .transactionType == "CREATE") | .contractAddress' "$BROADCAST_FILE" | head -1)
L1_CROSS_DOMAIN_MESSENGER_IMPL=$(jq -r '.transactions[] | select(.contractName == "L1CrossDomainMessenger" and .transactionType == "CREATE") | .contractAddress' "$BROADCAST_FILE" | head -1)
L1_STANDARD_BRIDGE_IMPL=$(jq -r '.transactions[] | select(.contractName == "L1StandardBridge" and .transactionType == "CREATE") | .contractAddress' "$BROADCAST_FILE" | head -1)
L1_ERC721_BRIDGE_IMPL=$(jq -r '.transactions[] | select(.contractName == "L1ERC721Bridge" and .transactionType == "CREATE") | .contractAddress' "$BROADCAST_FILE" | head -1)

# Get constructor arguments for each implementation
SYSTEM_CONFIG_CONSTRUCTOR_ARGS=$(jq -c '.transactions[] | select(.contractName == "SystemConfig" and .transactionType == "CREATE") | .arguments // []' "$BROADCAST_FILE" | head -1)
OPTIMISM_PORTAL_CONSTRUCTOR_ARGS=$(jq -c '.transactions[] | select(.contractName == "OptimismPortalInterop" and .transactionType == "CREATE") | .arguments // []' "$BROADCAST_FILE" | head -1)
L1_CROSS_DOMAIN_MESSENGER_CONSTRUCTOR_ARGS=$(jq -c '.transactions[] | select(.contractName == "L1CrossDomainMessenger" and .transactionType == "CREATE") | .arguments // []' "$BROADCAST_FILE" | head -1)
L1_STANDARD_BRIDGE_CONSTRUCTOR_ARGS=$(jq -c '.transactions[] | select(.contractName == "L1StandardBridge" and .transactionType == "CREATE") | .arguments // []' "$BROADCAST_FILE" | head -1)
L1_ERC721_BRIDGE_CONSTRUCTOR_ARGS=$(jq -c '.transactions[] | select(.contractName == "L1ERC721Bridge" and .transactionType == "CREATE") | .arguments // []' "$BROADCAST_FILE" | head -1)

# Get upgrade/initialize call data from upgradeAndCall transactions (case-insensitive matching)
SYSTEM_CONFIG_UPGRADE_DATA=$(jq -r '.transactions[] | select(.function == "upgradeAndCall(address,address,bytes)" and (.arguments[0] | ascii_downcase) == ("'$SYSTEM_CONFIG_PROXY'" | ascii_downcase)) | .arguments[2]' "$BROADCAST_FILE" | head -1)
L1_CROSS_DOMAIN_MESSENGER_UPGRADE_DATA=$(jq -r '.transactions[] | select(.function == "upgradeAndCall(address,address,bytes)" and (.arguments[0] | ascii_downcase) == ("'$L1_CROSS_DOMAIN_MESSENGER_PROXY'" | ascii_downcase)) | .arguments[2]' "$BROADCAST_FILE" | head -1)
L1_STANDARD_BRIDGE_UPGRADE_DATA=$(jq -r '.transactions[] | select(.function == "upgradeAndCall(address,address,bytes)" and (.arguments[0] | ascii_downcase) == ("'$L1_STANDARD_BRIDGE_PROXY'" | ascii_downcase)) | .arguments[2]' "$BROADCAST_FILE" | head -1)
L1_ERC721_BRIDGE_UPGRADE_DATA=$(jq -r '.transactions[] | select(.function == "upgradeAndCall(address,address,bytes)" and (.arguments[0] | ascii_downcase) == ("'$L1_ERC721_BRIDGE_PROXY'" | ascii_downcase)) | .arguments[2]' "$BROADCAST_FILE" | head -1)

# Get transaction hashes and block numbers from receipts for each contract
SYSTEM_CONFIG_TX=$(jq -r '.receipts[] | select(.contractAddress == "'$SYSTEM_CONFIG_IMPL'") | .transactionHash' "$BROADCAST_FILE" | head -1)
SYSTEM_CONFIG_BLOCK=$(jq -r '.receipts[] | select(.contractAddress == "'$SYSTEM_CONFIG_IMPL'") | .blockNumber' "$BROADCAST_FILE" | head -1)

OPTIMISM_PORTAL_TX=$(jq -r '.receipts[] | select(.contractAddress == "'$OPTIMISM_PORTAL_IMPL'") | .transactionHash' "$BROADCAST_FILE" | head -1)
OPTIMISM_PORTAL_BLOCK=$(jq -r '.receipts[] | select(.contractAddress == "'$OPTIMISM_PORTAL_IMPL'") | .blockNumber' "$BROADCAST_FILE" | head -1)

L1_CROSS_DOMAIN_MESSENGER_TX=$(jq -r '.receipts[] | select(.contractAddress == "'$L1_CROSS_DOMAIN_MESSENGER_IMPL'") | .transactionHash' "$BROADCAST_FILE" | head -1)
L1_CROSS_DOMAIN_MESSENGER_BLOCK=$(jq -r '.receipts[] | select(.contractAddress == "'$L1_CROSS_DOMAIN_MESSENGER_IMPL'") | .blockNumber' "$BROADCAST_FILE" | head -1)

L1_STANDARD_BRIDGE_TX=$(jq -r '.receipts[] | select(.contractAddress == "'$L1_STANDARD_BRIDGE_IMPL'") | .transactionHash' "$BROADCAST_FILE" | head -1)
L1_STANDARD_BRIDGE_BLOCK=$(jq -r '.receipts[] | select(.contractAddress == "'$L1_STANDARD_BRIDGE_IMPL'") | .blockNumber' "$BROADCAST_FILE" | head -1)

L1_ERC721_BRIDGE_TX=$(jq -r '.receipts[] | select(.contractAddress == "'$L1_ERC721_BRIDGE_IMPL'") | .transactionHash' "$BROADCAST_FILE" | head -1)
L1_ERC721_BRIDGE_BLOCK=$(jq -r '.receipts[] | select(.contractAddress == "'$L1_ERC721_BRIDGE_IMPL'") | .blockNumber' "$BROADCAST_FILE" | head -1)

# Convert hex block numbers to decimal
SYSTEM_CONFIG_BLOCK_DEC=$((SYSTEM_CONFIG_BLOCK))
OPTIMISM_PORTAL_BLOCK_DEC=$((OPTIMISM_PORTAL_BLOCK))
L1_CROSS_DOMAIN_MESSENGER_BLOCK_DEC=$((L1_CROSS_DOMAIN_MESSENGER_BLOCK))
L1_STANDARD_BRIDGE_BLOCK_DEC=$((L1_STANDARD_BRIDGE_BLOCK))
L1_ERC721_BRIDGE_BLOCK_DEC=$((L1_ERC721_BRIDGE_BLOCK))

# Create migration JSON
jq -n \
  --arg rollup_name "$ROLLUP_NAME" \
  --arg l2_chain_id "$L2_CHAIN_ID" \
  --arg compose_network "$COMPOSE_NETWORK" \
  --arg migration_block "$MIGRATION_BLOCK_DEC" \
  --arg timestamp "$TIMESTAMP" \
  --arg migrator "$MIGRATOR" \
  --arg system_config_proxy "$SYSTEM_CONFIG_PROXY" \
  --arg system_config_impl "$SYSTEM_CONFIG_IMPL" \
  --argjson system_config_constructor_args "$SYSTEM_CONFIG_CONSTRUCTOR_ARGS" \
  --arg system_config_upgrade_data "$SYSTEM_CONFIG_UPGRADE_DATA" \
  --arg system_config_tx "$SYSTEM_CONFIG_TX" \
  --arg system_config_block "$SYSTEM_CONFIG_BLOCK_DEC" \
  --arg optimism_portal_proxy "$OPTIMISM_PORTAL_PROXY" \
  --arg optimism_portal_old_impl "$OLD_OPTIMISM_PORTAL_IMPL" \
  --arg optimism_portal_impl "$OPTIMISM_PORTAL_IMPL" \
  --argjson optimism_portal_constructor_args "$OPTIMISM_PORTAL_CONSTRUCTOR_ARGS" \
  --arg optimism_portal_tx "$OPTIMISM_PORTAL_TX" \
  --arg optimism_portal_block "$OPTIMISM_PORTAL_BLOCK_DEC" \
  --arg l1_cross_domain_messenger_proxy "$L1_CROSS_DOMAIN_MESSENGER_PROXY" \
  --arg l1_cross_domain_messenger_impl "$L1_CROSS_DOMAIN_MESSENGER_IMPL" \
  --argjson l1_cross_domain_messenger_constructor_args "$L1_CROSS_DOMAIN_MESSENGER_CONSTRUCTOR_ARGS" \
  --arg l1_cross_domain_messenger_upgrade_data "$L1_CROSS_DOMAIN_MESSENGER_UPGRADE_DATA" \
  --arg l1_cross_domain_messenger_tx "$L1_CROSS_DOMAIN_MESSENGER_TX" \
  --arg l1_cross_domain_messenger_block "$L1_CROSS_DOMAIN_MESSENGER_BLOCK_DEC" \
  --arg l1_standard_bridge_proxy "$L1_STANDARD_BRIDGE_PROXY" \
  --arg l1_standard_bridge_impl "$L1_STANDARD_BRIDGE_IMPL" \
  --argjson l1_standard_bridge_constructor_args "$L1_STANDARD_BRIDGE_CONSTRUCTOR_ARGS" \
  --arg l1_standard_bridge_upgrade_data "$L1_STANDARD_BRIDGE_UPGRADE_DATA" \
  --arg l1_standard_bridge_tx "$L1_STANDARD_BRIDGE_TX" \
  --arg l1_standard_bridge_block "$L1_STANDARD_BRIDGE_BLOCK_DEC" \
  --arg l1_erc721_bridge_proxy "$L1_ERC721_BRIDGE_PROXY" \
  --arg l1_erc721_bridge_impl "$L1_ERC721_BRIDGE_IMPL" \
  --argjson l1_erc721_bridge_constructor_args "$L1_ERC721_BRIDGE_CONSTRUCTOR_ARGS" \
  --arg l1_erc721_bridge_upgrade_data "$L1_ERC721_BRIDGE_UPGRADE_DATA" \
  --arg l1_erc721_bridge_tx "$L1_ERC721_BRIDGE_TX" \
  --arg l1_erc721_bridge_block "$L1_ERC721_BRIDGE_BLOCK_DEC" \
  '{
    ($rollup_name): {
      l2ChainId: ($l2_chain_id | tonumber),
      composeNetwork: $compose_network,
      migration_block: ($migration_block | tonumber),
      timestamp: $timestamp,
      migrator: $migrator,
      contracts: {
        SystemConfig: {
          proxyAddress: $system_config_proxy,
          oldImplAddress: "",
          newImplAddress: $system_config_impl,
          constructorArgs: $system_config_constructor_args,
          upgradeData: $system_config_upgrade_data,
          txHash: $system_config_tx,
          migrationBlock: ($system_config_block | tonumber)
        },
        OptimismPortal: {
          proxyAddress: $optimism_portal_proxy,
          oldImplAddress: $optimism_portal_old_impl,
          newImplAddress: $optimism_portal_impl,
          constructorArgs: $optimism_portal_constructor_args,
          upgradeData: "",
          txHash: $optimism_portal_tx,
          migrationBlock: ($optimism_portal_block | tonumber)
        },
        L1CrossDomainMessenger: {
          proxyAddress: $l1_cross_domain_messenger_proxy,
          oldImplAddress: "",
          newImplAddress: $l1_cross_domain_messenger_impl,
          constructorArgs: $l1_cross_domain_messenger_constructor_args,
          upgradeData: $l1_cross_domain_messenger_upgrade_data,
          txHash: $l1_cross_domain_messenger_tx,
          migrationBlock: ($l1_cross_domain_messenger_block | tonumber)
        },
        L1StandardBridge: {
          proxyAddress: $l1_standard_bridge_proxy,
          oldImplAddress: "",
          newImplAddress: $l1_standard_bridge_impl,
          constructorArgs: $l1_standard_bridge_constructor_args,
          upgradeData: $l1_standard_bridge_upgrade_data,
          txHash: $l1_standard_bridge_tx,
          migrationBlock: ($l1_standard_bridge_block | tonumber)
        },
        L1ERC721Bridge: {
          proxyAddress: $l1_erc721_bridge_proxy,
          oldImplAddress: "",
          newImplAddress: $l1_erc721_bridge_impl,
          constructorArgs: $l1_erc721_bridge_constructor_args,
          upgradeData: $l1_erc721_bridge_upgrade_data,
          txHash: $l1_erc721_bridge_tx,
          migrationBlock: ($l1_erc721_bridge_block | tonumber)
        }
      }
    }
  }' > "$DEPLOYMENT_FILE"

echo ""
echo "✓ Migration data saved to $DEPLOYMENT_FILE"
echo ""
echo "=== Migration Summary for $ROLLUP_NAME ==="
echo "L2 Chain ID:              $L2_CHAIN_ID"
echo "Compose Network:          $COMPOSE_NETWORK"
echo "Migration Block:          $MIGRATION_BLOCK_DEC"
echo "Migrator:                 $MIGRATOR"
echo "Timestamp:                $TIMESTAMP"
echo ""
echo "Upgraded Contracts:"
echo "  SystemConfig:           $SYSTEM_CONFIG_PROXY"
echo "  OptimismPortal:         $OPTIMISM_PORTAL_PROXY"
echo "  L1CrossDomainMessenger: $L1_CROSS_DOMAIN_MESSENGER_PROXY"
echo "  L1StandardBridge:       $L1_STANDARD_BRIDGE_PROXY"
echo "  L1ERC721Bridge:         $L1_ERC721_BRIDGE_PROXY"
echo ""
echo "New Implementations:"
echo "  SystemConfig:           $SYSTEM_CONFIG_IMPL"
echo "  OptimismPortal:         $OPTIMISM_PORTAL_IMPL"
echo "  L1CrossDomainMessenger: $L1_CROSS_DOMAIN_MESSENGER_IMPL"
echo "  L1StandardBridge:       $L1_STANDARD_BRIDGE_IMPL"
echo "  L1ERC721Bridge:         $L1_ERC721_BRIDGE_IMPL"
echo ""
echo "Migration file:           $DEPLOYMENT_FILE"
echo "========================================"
