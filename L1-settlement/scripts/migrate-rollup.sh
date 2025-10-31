#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ROLLUP=$1
COMPOSE_NETWORK=$2
DRY_RUN=${3:-false}

# Check if rollup and compose network parameters are provided
if [ -z "$ROLLUP" ] || [ -z "$COMPOSE_NETWORK" ]; then
    echo -e "${RED}Error: Both rollup and compose network parameters required${NC}"
    echo "Usage: $0 <rollup> <compose_network> [dry-run]"
    echo "Example: $0 rollup-a-stage hoodi-stage"
    echo "Example: $0 rollup-a-prod hoodi-prod dry-run"
    exit 1
fi

# Check if rollup config exists
ROLLUP_CONFIG="script/config/rollups/${ROLLUP}.json"
if [ ! -f "$ROLLUP_CONFIG" ]; then
    echo -e "${RED}Error: Rollup configuration not found: $ROLLUP_CONFIG${NC}"
    exit 1
fi

# Check if compose config exists
COMPOSE_CONFIG="script/config/compose/${COMPOSE_NETWORK}.json"
if [ ! -f "$COMPOSE_CONFIG" ]; then
    echo -e "${RED}Error: Compose configuration not found: $COMPOSE_CONFIG${NC}"
    exit 1
fi

# Check for ETHERSCAN_API_KEY (warn but don't fail)
if [ -z "${ETHERSCAN_API_KEY:-}" ]; then
    echo -e "${YELLOW}Warning: ETHERSCAN_API_KEY not set in .env. Verification will be skipped.${NC}"
fi

# Check for MIGRATION_PROXY_ADMIN_OWNER_KEY (required for live mode)
if [ "$DRY_RUN" != "dry-run" ]; then
    if [ -z "${MIGRATION_PROXY_ADMIN_OWNER_KEY:-}" ]; then
        echo -e "${RED}Error: MIGRATION_PROXY_ADMIN_OWNER_KEY not set in .env${NC}"
        echo "This private key is required to execute the migration (Steps 2-4, 8-9)."
        echo "Add it to your .env file with the Rollup ProxyAdmin owner private key."
        exit 1
    fi
    
    # Warn if COMPOSE_PROXY_ADMIN_OWNER_KEY is not set (needed for Step 6)
    if [ -z "${COMPOSE_PROXY_ADMIN_OWNER_KEY:-}" ]; then
        echo -e "${YELLOW}Warning: COMPOSE_PROXY_ADMIN_OWNER_KEY not set in .env${NC}"
        echo "This key is needed for Step 6 (authorize portal in lockbox)."
        echo "If not set, MIGRATION_PROXY_ADMIN_OWNER_KEY will be used as fallback."
        echo "Set COMPOSE_PROXY_ADMIN_OWNER_KEY if the Compose ProxyAdmin has a different owner."
    fi
fi

# Convert dry-run flag to boolean
IS_DRY_RUN="false"
if [ "$DRY_RUN" = "dry-run" ]; then
    IS_DRY_RUN="true"
fi

echo -e "${GREEN}Migration configuration:${NC}"
echo "  Rollup: $ROLLUP (from $ROLLUP_CONFIG)"
echo "  Compose Network: $COMPOSE_NETWORK (from $COMPOSE_CONFIG)"
echo "  Mode: $([ "$IS_DRY_RUN" = "true" ] && echo "DRY RUN (simulation only)" || echo "LIVE (will broadcast transactions)")"

# Load network configuration
# Set a dummy DEPLOYER_PRIVATE_KEY if not present (migrations use MIGRATION_PROXY_ADMIN_OWNER_KEY instead)
if [ -z "${DEPLOYER_PRIVATE_KEY:-}" ]; then
    export DEPLOYER_PRIVATE_KEY="0x0000000000000000000000000000000000000000000000000000000000000001"
fi

source scripts/parse-network.sh "$COMPOSE_NETWORK"

CHAIN_ID=$(jq -r '.l2ChainId' "$ROLLUP_CONFIG")

echo "Rollup:       $ROLLUP"
echo "Compose Net:  $NETWORK_NAME"
echo "L2 Chain ID:  $CHAIN_ID"
echo "RPC URL:      $NETWORK_RPC_URL"
echo ""

if [ "$IS_DRY_RUN" = "true" ]; then
    echo "========================================="
    echo "DRY RUN: Phase 2 Migration Simulation"
    echo "========================================="
    echo "The following will show detailed traces of what WOULD happen."
    echo "No transactions will be broadcast to the network."
    echo ""
else
    echo "========================================="
    echo "LIVE: Executing Phase 2 Migration"
    echo "========================================="
    echo "WARNING: This will broadcast real transactions!"
    echo ""
fi

# Determine verification flag
VERIFY_FLAG=""
if [ -z "${ETHERSCAN_API_KEY:-}" ]; then
    echo -e "${YELLOW}Warning: Skipping verification (no ETHERSCAN_API_KEY)${NC}"
else
    VERIFY_FLAG="--verify"
fi

# Execute the migration
FORGE_ARGS=(
    "script/migrate/MigrateRollup.s.sol:MigrateRollup"
    "--sig" "run(string,string,bool)"
    "--rpc-url" "$NETWORK_RPC_URL"
)

# Add verification flag if set
if [ -n "$VERIFY_FLAG" ]; then
    FORGE_ARGS+=("$VERIFY_FLAG")
fi

# Add broadcast and private key for live mode, or sender + verbosity for dry-run
if [ "$IS_DRY_RUN" = "false" ]; then
    FORGE_ARGS+=("--broadcast")
    FORGE_ARGS+=("--private-key" "$MIGRATION_PROXY_ADMIN_OWNER_KEY")
else
    # In dry-run, use the ProxyAdmin owner address from rollup config as sender
    PROXY_ADMIN_OWNER=$(jq -r '.proxyAdmin.owner' "$ROLLUP_CONFIG")
    FORGE_ARGS+=("--sender" "$PROXY_ADMIN_OWNER")
    # Add maximum verbosity for dry-run to show all console.log and traces
    FORGE_ARGS+=("-vvv")
fi

# Add function arguments
FORGE_ARGS+=("$ROLLUP" "$COMPOSE_NETWORK" "$IS_DRY_RUN")

if forge script "${FORGE_ARGS[@]}"; then
    if [ "$IS_DRY_RUN" = "true" ]; then
        echo -e "\n${GREEN}Dry run completed successfully!${NC}"
        echo "No transactions were broadcast."
        echo "Review the simulation output above."
        echo ""
        echo "To execute the migration for real, run:"
        echo "  just migrate-rollup $ROLLUP $COMPOSE_NETWORK"
    else
        echo -e "\n${GREEN}Phase 2 migration complete!${NC}"
        
        # Parse deployment addresses from broadcast output
        BROADCAST_FILE="broadcast/MigrateRollup.s.sol/$CHAIN_ID/run-latest.json"
        
        if [ -f "$BROADCAST_FILE" ]; then
            echo ""
            echo "Extracting deployed implementation addresses..."
            
            # Extract implementation addresses
            SYSTEM_CONFIG_IMPL=$(jq -r '.transactions[] | select(.contractName == "SystemConfig") | .contractAddress' "$BROADCAST_FILE" | head -1)
            PORTAL_IMPL=$(jq -r '.transactions[] | select(.contractName == "OptimismPortal2") | .contractAddress' "$BROADCAST_FILE" | head -1)
            XDM_IMPL=$(jq -r '.transactions[] | select(.contractName == "L1CrossDomainMessenger") | .contractAddress' "$BROADCAST_FILE" | head -1)
            BRIDGE_IMPL=$(jq -r '.transactions[] | select(.contractName == "L1StandardBridge") | .contractAddress' "$BROADCAST_FILE" | head -1)
            ERC721_IMPL=$(jq -r '.transactions[] | select(.contractName == "L1ERC721Bridge") | .contractAddress' "$BROADCAST_FILE" | head -1)
            
            echo -e "${GREEN}Migration successful!${NC}"
            echo ""
            echo "New implementations deployed:"
            echo "  SystemConfig:            ${SYSTEM_CONFIG_IMPL:-not found}"
            echo "  OptimismPortal2:         ${PORTAL_IMPL:-not found}"
            echo "  L1CrossDomainMessenger:  ${XDM_IMPL:-not found}"
            echo "  L1StandardBridge:        ${BRIDGE_IMPL:-not found}"
            echo "  L1ERC721Bridge:          ${ERC721_IMPL:-not found}"
            echo ""
            
            # Update deployments.json with Phase 2 information
            echo "Updating deployments.json..."
            
            TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
            
            # Create Phase 2 entry
            jq --arg network "$NETWORK" \
               --arg timestamp "$TIMESTAMP" \
               --arg systemConfigImpl "${SYSTEM_CONFIG_IMPL:-}" \
               --arg portalImpl "${PORTAL_IMPL:-}" \
               --arg xdmImpl "${XDM_IMPL:-}" \
               --arg bridgeImpl "${BRIDGE_IMPL:-}" \
               --arg erc721Impl "${ERC721_IMPL:-}" \
               '.[$network].phase = "phase2-rollup-migration" |
                .[$network].migrated_at = $timestamp |
                .[$network].implementations = {
                    "SystemConfig": $systemConfigImpl,
                    "OptimismPortal2": $portalImpl,
                    "L1CrossDomainMessenger": $xdmImpl,
                    "L1StandardBridge": $bridgeImpl,
                    "L1ERC721Bridge": $erc721Impl
                }' deployments.json > deployments.json.tmp && mv deployments.json.tmp deployments.json
            
            echo -e "${GREEN}Deployment addresses saved to deployments.json${NC}"
        fi
    fi
else
    echo -e "\n${RED}Migration failed!${NC}"
    exit 1
fi
