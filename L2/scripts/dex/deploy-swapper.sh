#!/usr/bin/env bash
# ============================================================================
# Deploy DEX Swapper
# ============================================================================
# Usage: ./scripts/dex/deploy-swapper.sh <network-name>
# ============================================================================

set -euo pipefail

# Change to L2 directory
cd "$(dirname "$0")/../.."

# Check arguments
if [ $# -eq 0 ]; then
    echo "Error: Network name required"
    echo "Usage: ./scripts/dex/deploy-swapper.sh <network-name>"
    echo ""
    echo "Available networks:"
    grep '^\[' networks.toml 2>/dev/null | tr -d '[]' | sed 's/^/  - /' || echo "  (networks.toml not found)"
    exit 1
fi

NETWORK=$1

# Load network configuration
source scripts/parse-network.sh "$NETWORK"

# Load environment variables
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    echo "Please copy .env.example to .env and configure it"
    exit 1
fi

source .env

# Validate required environment variables
if [ -z "${DEPLOYER_PRIVATE_KEY:-}" ]; then
    echo "Error: DEPLOYER_PRIVATE_KEY not set in .env"
    exit 1
fi

if [ -z "${DEPLOY_SALT:-}" ]; then
    echo "Error: DEPLOY_SALT not set in .env"
    exit 1
fi

# Get token addresses from deployments.json or environment
if [ -f "deployments.json" ]; then
    WETH_ADDRESS=${WETH_ADDRESS:-$(jq -r ".\"$NETWORK\".dex.WETH // empty" deployments.json)}
    USDC_ADDRESS=${USDC_ADDRESS:-$(jq -r ".\"$NETWORK\".dex.USDC // empty" deployments.json)}
    SSV_ADDRESS=${SSV_ADDRESS:-$(jq -r ".\"$NETWORK\".dex.SSV // empty" deployments.json)}
fi

# Validate token addresses
if [ -z "${WETH_ADDRESS:-}" ] || [ "$WETH_ADDRESS" == "null" ]; then
    echo "Error: WETH_ADDRESS not found"
    echo "Please set WETH_ADDRESS environment variable or deploy tokens first"
    exit 1
fi

if [ -z "${USDC_ADDRESS:-}" ] || [ "$USDC_ADDRESS" == "null" ]; then
    echo "Error: USDC_ADDRESS not found"
    echo "Please set USDC_ADDRESS environment variable or deploy tokens first"
    exit 1
fi

if [ -z "${SSV_ADDRESS:-}" ] || [ "$SSV_ADDRESS" == "null" ]; then
    echo "Error: SSV_ADDRESS not found"
    echo "Please set SSV_ADDRESS environment variable or deploy tokens first"
    exit 1
fi

# Export token addresses so forge script can access them
export WETH_ADDRESS
export USDC_ADDRESS
export SSV_ADDRESS

echo "========================================="
echo "Deploying Swapper to $NETWORK_NAME"
echo "========================================="
echo ""
echo "Network:     $NETWORK_NAME"
echo "Chain ID:    $NETWORK_CHAIN_ID"
echo "RPC URL:     $NETWORK_RPC_URL"
echo ""
echo "Token Addresses:"
echo "  WETH: $WETH_ADDRESS"
echo "  USDC: $USDC_ADDRESS"
echo "  SSV:  $SSV_ADDRESS"
echo ""
echo "========================================="
echo ""

# Create logs directory if it doesn't exist
mkdir -p logs

# Deploy Swapper
forge script script/dex/DeploySwapper.s.sol:DeploySwapper \
    --rpc-url "$NETWORK_RPC_URL" \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    --broadcast \
    --sig "run(string)" \
    "$NETWORK" \
    2>&1 | tee "logs/deployment-swapper-${NETWORK}.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo ""
    echo "❌ Swapper deployment failed. Check logs/deployment-swapper-${NETWORK}.log for details"
    exit 1
fi

echo ""
echo "========================================="
echo "✓ Swapper deployed successfully!"
echo "========================================="
echo ""

# Extract swapper address from artifact
if [ -f "artifacts/deploy-swapper-${NETWORK}.json" ]; then
    SWAPPER_ADDRESS=$(jq -r '.addresses.Swapper' "artifacts/deploy-swapper-${NETWORK}.json")
    echo "Swapper Address: $SWAPPER_ADDRESS"
    echo ""
    
    # Update deployments.json
    if [ -f "deployments.json" ]; then
        echo "Updating deployments.json..."
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        
        jq --arg network "$NETWORK" \
           --arg swapper "$SWAPPER_ADDRESS" \
           --arg timestamp "$TIMESTAMP" \
           '.[$network].dex.Swapper = $swapper |
            .[$network].dex.lastUpdate = $timestamp' \
           deployments.json > deployments.json.tmp
        
        mv deployments.json.tmp deployments.json
        echo "✓ deployments.json updated"
    fi
fi

echo ""
echo "========================================="
echo "Next steps:"
echo "  1. Fund swapper with liquidity:"
echo "     just fund-dex-swapper $NETWORK"
echo "  2. Or with custom amounts:"
echo "     just fund-dex-swapper-custom $NETWORK <weth> <usdc> <ssv>"
echo "========================================="
