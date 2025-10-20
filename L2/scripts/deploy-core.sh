#!/usr/bin/env bash
# ============================================================================
# Deploy L2 Rollup Contracts
# ============================================================================
# Usage: ./scripts/deploy.sh <network-name>
# ============================================================================

set -euo pipefail

# Change to L2 directory
cd "$(dirname "$0")/.."

# Check arguments
if [ $# -eq 0 ]; then
    echo "Error: Network name required"
    echo "Usage: ./scripts/deploy.sh <network-name>"
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

if [ -z "${COORDINATOR_ADDRESS:-}" ]; then
    echo "Error: COORDINATOR_ADDRESS not set in .env"
    exit 1
fi

if [ -z "${DEPLOY_SALT:-}" ]; then
    echo "Error: DEPLOY_SALT not set in .env"
    exit 1
fi

echo "========================================="
echo "Deploying L2 Contracts to $NETWORK_NAME"
echo "========================================="
echo ""
echo "Network:     $NETWORK_NAME"
echo "Chain ID:    $NETWORK_CHAIN_ID"
echo "RPC URL:     $NETWORK_RPC_URL"
echo "Coordinator: $COORDINATOR_ADDRESS"
echo ""
echo "========================================="
echo ""

# Create logs directory if it doesn't exist
mkdir -p logs

# Run deployment script
forge script script/core/DeployContracts.s.sol:DeployContracts \
    --rpc-url "$NETWORK_RPC_URL" \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    --broadcast \
    --sig "run(address,string)" \
    "$COORDINATOR_ADDRESS" \
    "$NETWORK" \
    2>&1 | tee "logs/deployment-${NETWORK}.log"

# Check if deployment was successful
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo ""
    echo "❌ Deployment failed. Check logs/deployment-${NETWORK}.log for details"
    exit 1
fi

echo ""
echo "========================================="
echo "✓ Deployment completed successfully!"
echo "========================================="
echo ""

# Save deployment to deployments.json
if [ -f "scripts/save-deployment.sh" ]; then
    source scripts/save-deployment.sh "$NETWORK"
fi

# Show deployment info
if [ -f "artifacts/deploy-${NETWORK}.json" ]; then
    echo "Deployment artifact saved to: artifacts/deploy-${NETWORK}.json"
    echo ""
    echo "Deployed contracts:"
    jq -r '.addresses | to_entries[] | "  \(.key): \(.value)"' "artifacts/deploy-${NETWORK}.json"
    echo ""
fi

# Note: For contract verification, use: just verify-all <network>

echo "========================================="
echo "Next steps:"
echo "  1. Verify contracts (if needed)"
echo "  2. Test deployment: just test-network $NETWORK"
echo "  3. View deployments: just show-deployments"
echo "========================================="
