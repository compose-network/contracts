#!/usr/bin/env bash
# ============================================================================
# Deploy DEX Tokens (WETH, USDC, SSV)
# ============================================================================
# Usage: ./scripts/dex/deploy-tokens.sh <network-name>
# ============================================================================

set -euo pipefail

# Change to L2 directory
cd "$(dirname "$0")/../.."

# Check arguments
if [ $# -eq 0 ]; then
    echo "Error: Network name required"
    echo "Usage: ./scripts/dex/deploy-tokens.sh <network-name>"
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

echo "========================================="
echo "Deploying DEX Tokens to $NETWORK_NAME"
echo "========================================="
echo ""
echo "Network:     $NETWORK_NAME"
echo "Chain ID:    $NETWORK_CHAIN_ID"
echo "RPC URL:     $NETWORK_RPC_URL"
echo ""
echo "========================================="
echo ""

# Create logs directory if it doesn't exist
mkdir -p logs

echo "Deploying WETH9..."
forge script script/dex/DeployWETH.s.sol:DeployWETH \
    --rpc-url "$NETWORK_RPC_URL" \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    --broadcast \
    --sig "run(string)" \
    "$NETWORK" \
    2>&1 | tee "logs/deployment-dex-weth-${NETWORK}.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ WETH9 deployment failed"
    exit 1
fi

echo ""
echo "========================================="
echo ""

echo "Deploying SSV and USDC tokens..."
forge script script/dex/DeployDEXTokens.s.sol:DeployDEXTokens \
    --rpc-url "$NETWORK_RPC_URL" \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    --broadcast \
    --sig "run(string)" \
    "$NETWORK" \
    2>&1 | tee "logs/deployment-dex-tokens-${NETWORK}.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ DEX tokens deployment failed"
    exit 1
fi

echo ""
echo "========================================="
echo "✓ All DEX tokens deployed successfully!"
echo "========================================="
echo ""

# Extract addresses from artifacts
if [ -f "artifacts/deploy-weth-${NETWORK}.json" ] && [ -f "artifacts/deploy-dex-tokens-${NETWORK}.json" ]; then
    echo "Deployed Token Addresses:"
    WETH=$(jq -r '.addresses.WETH' "artifacts/deploy-weth-${NETWORK}.json")
    USDC=$(jq -r '.addresses.USDC' "artifacts/deploy-dex-tokens-${NETWORK}.json")
    SSV=$(jq -r '.addresses.SSV' "artifacts/deploy-dex-tokens-${NETWORK}.json")
    
    echo "  WETH: $WETH"
    echo "  USDC: $USDC"
    echo "  SSV:  $SSV"
    echo ""
    
    # Update deployments.json
    if [ -f "deployments.json" ]; then
        echo "Updating deployments.json..."
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        
        jq --arg network "$NETWORK" \
           --arg weth "$WETH" \
           --arg usdc "$USDC" \
           --arg ssv "$SSV" \
           --arg timestamp "$TIMESTAMP" \
           '.[$network].dex = {
             "WETH": $weth,
             "USDC": $usdc,
             "SSV": $ssv,
             "Swapper": null,
             "lastUpdate": $timestamp
           }' deployments.json > deployments.json.tmp
        
        mv deployments.json.tmp deployments.json
        echo "✓ deployments.json updated"
    fi
fi

echo ""
echo "========================================="
echo "Next steps:"
echo "  1. Export token addresses:"
echo "     export WETH_ADDRESS=$WETH"
echo "     export USDC_ADDRESS=$USDC"
echo "     export SSV_ADDRESS=$SSV"
echo "  2. Deploy swapper: just deploy-dex-swapper $NETWORK"
echo "========================================="
