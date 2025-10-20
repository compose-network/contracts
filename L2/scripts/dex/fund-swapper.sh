#!/usr/bin/env bash
# ============================================================================
# Fund DEX Swapper with Liquidity
# ============================================================================
# Usage: ./scripts/dex/fund-swapper.sh <network-name> [weth-amount] [usdc-amount] [ssv-amount]
# ============================================================================

set -euo pipefail

# Change to L2 directory
cd "$(dirname "$0")/../.."

# Check arguments
if [ $# -eq 0 ]; then
    echo "Error: Network name required"
    echo "Usage: ./scripts/dex/fund-swapper.sh <network-name> [weth-amount] [usdc-amount] [ssv-amount]"
    echo ""
    echo "Amounts are in ether units (e.g., 1000000 = 1,000,000 tokens)"
    echo "If amounts not provided, defaults to 1,000,000 of each token"
    echo ""
    echo "Available networks:"
    grep '^\[' networks.toml 2>/dev/null | tr -d '[]' | sed 's/^/  - /' || echo "  (networks.toml not found)"
    exit 1
fi

NETWORK=$1
WETH_AMOUNT=${2:-1000000}
USDC_AMOUNT=${3:-1000000}
SSV_AMOUNT=${4:-1000000}

# Convert to wei (multiply by 10^18)
WETH_WEI="${WETH_AMOUNT}000000000000000000"
USDC_WEI="${USDC_AMOUNT}000000000000000000"
SSV_WEI="${SSV_AMOUNT}000000000000000000"

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

# Get addresses from deployments.json or environment
if [ -f "deployments.json" ]; then
    SWAPPER_ADDRESS=${SWAPPER_ADDRESS:-$(jq -r ".\"$NETWORK\".dex.Swapper // empty" deployments.json)}
    WETH_ADDRESS=${WETH_ADDRESS:-$(jq -r ".\"$NETWORK\".dex.WETH // empty" deployments.json)}
    USDC_ADDRESS=${USDC_ADDRESS:-$(jq -r ".\"$NETWORK\".dex.USDC // empty" deployments.json)}
    SSV_ADDRESS=${SSV_ADDRESS:-$(jq -r ".\"$NETWORK\".dex.SSV // empty" deployments.json)}
fi

# Validate addresses
if [ -z "${SWAPPER_ADDRESS:-}" ] || [ "$SWAPPER_ADDRESS" == "null" ]; then
    echo "Error: SWAPPER_ADDRESS not found"
    echo "Please deploy swapper first: just deploy-dex-swapper $NETWORK"
    exit 1
fi

if [ -z "${WETH_ADDRESS:-}" ] || [ "$WETH_ADDRESS" == "null" ]; then
    echo "Error: WETH_ADDRESS not found"
    echo "Please deploy tokens first: just deploy-dex-tokens $NETWORK"
    exit 1
fi

if [ -z "${USDC_ADDRESS:-}" ] || [ "$USDC_ADDRESS" == "null" ]; then
    echo "Error: USDC_ADDRESS not found"
    echo "Please deploy tokens first: just deploy-dex-tokens $NETWORK"
    exit 1
fi

if [ -z "${SSV_ADDRESS:-}" ] || [ "$SSV_ADDRESS" == "null" ]; then
    echo "Error: SSV_ADDRESS not found"
    echo "Please deploy tokens first: just deploy-dex-tokens $NETWORK"
    exit 1
fi

# Export addresses so forge script can access them
export WETH_ADDRESS
export USDC_ADDRESS
export SSV_ADDRESS

echo "========================================="
echo "Funding Swapper on $NETWORK_NAME"
echo "========================================="
echo ""
echo "Network:     $NETWORK_NAME"
echo "Chain ID:    $NETWORK_CHAIN_ID"
echo "RPC URL:     $NETWORK_RPC_URL"
echo ""
echo "Swapper:     $SWAPPER_ADDRESS"
echo ""
echo "Funding Amounts:"
echo "  WETH: $WETH_AMOUNT tokens ($WETH_WEI wei)"
echo "  USDC: $USDC_AMOUNT tokens ($USDC_WEI wei)"
echo "  SSV:  $SSV_AMOUNT tokens ($SSV_WEI wei)"
echo ""
echo "========================================="
echo ""

# Note: FundSwapper script expects ETH to deposit for WETH
# The deployer needs to have enough ETH balance
echo "Note: Funding requires ETH balance for WETH deposit"
echo "Checking if you have custom amounts or using default..."
echo ""

# Create logs directory if it doesn't exist
mkdir -p logs

# Determine which run method to use
if [ $# -eq 1 ]; then
    # Use default amounts
    echo "Using default funding amounts (1,000,000 of each token)..."
    forge script script/dex/FundSwapper.s.sol:FundSwapper \
        --rpc-url "$NETWORK_RPC_URL" \
        --private-key "$DEPLOYER_PRIVATE_KEY" \
        --broadcast \
        --sig "runDefault(address)" \
        "$SWAPPER_ADDRESS" \
        2>&1 | tee "logs/funding-swapper-${NETWORK}.log"
else
    # Use custom amounts
    echo "Using custom funding amounts..."
    forge script script/dex/FundSwapper.s.sol:FundSwapper \
        --rpc-url "$NETWORK_RPC_URL" \
        --private-key "$DEPLOYER_PRIVATE_KEY" \
        --broadcast \
        --sig "run(address,uint256,uint256,uint256)" \
        "$SWAPPER_ADDRESS" \
        "$WETH_WEI" \
        "$USDC_WEI" \
        "$SSV_WEI" \
        2>&1 | tee "logs/funding-swapper-${NETWORK}.log"
fi

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo ""
    echo "❌ Swapper funding failed. Check logs/funding-swapper-${NETWORK}.log for details"
    exit 1
fi

echo ""
echo "========================================="
echo "✓ Swapper funded successfully!"
echo "========================================="
echo ""
echo "You can now:"
echo "  - Check reserves: cast call $SWAPPER_ADDRESS \"getReserves()(uint256,uint256,uint256)\" --rpc-url $NETWORK_RPC_URL"
echo "  - Get swap price: cast call $SWAPPER_ADDRESS \"getSwapPrice(uint8,uint8,uint256)(uint256,uint256)\" 0 1 1000000000000000000 --rpc-url $NETWORK_RPC_URL"
echo "========================================="
