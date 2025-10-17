#!/usr/bin/env bash
# Parse network configuration from networks.toml

set -euo pipefail

NETWORK_NAME=$1

if [ ! -f networks.toml ]; then
    echo "Error: networks.toml not found. Copy networks.toml.example and configure it."
    exit 1
fi

# Check if network exists in config
if ! grep -q "^\[networks\.$NETWORK_NAME\]" networks.toml; then
    echo "Error: Network '$NETWORK_NAME' not found in networks.toml"
    echo "Available networks:"
    grep "^\[networks\." networks.toml | sed 's/\[networks\.//g' | sed 's/\]//g' | sed 's/^/  - /g'
    exit 1
fi

# Parse network config using awk
parse_value() {
    local key=$1
    awk -F= -v network="$NETWORK_NAME" -v key="$key" '
        /^\[networks\./ { current_network = $0; gsub(/^\[networks\./, "", current_network); gsub(/\].*$/, "", current_network) }
        current_network == network && $1 ~ "^"key {
            value = $2
            gsub(/^[[:space:]]*"?/, "", value)
            gsub(/"?[[:space:]]*$/, "", value)
            gsub(/#.*$/, "", value)
            gsub(/[[:space:]]*$/, "", value)
            print value
            exit
        }
    ' networks.toml
}

# Export network configuration
export NETWORK_NAME
export NETWORK_RPC_URL=$(parse_value "rpc_url")
export NETWORK_CHAIN_ID=$(parse_value "chain_id")
export NETWORK_EXPLORER_URL=$(parse_value "explorer_url")
export NETWORK_EXPLORER_API_URL=$(parse_value "explorer_api_url")

# Export ComposeL2OutputOracle parameters
export NETWORK_VERIFIER_ADDRESS=$(parse_value "verifier_address")
export NETWORK_OWNER_ADDRESS=$(parse_value "owner_address")
export NETWORK_PROPOSER_ADDRESS=$(parse_value "proposer_address")
export NETWORK_AGGREGATION_VKEY=$(parse_value "aggregation_vkey")
export NETWORK_STARTING_SUPERBLOCK_NUMBER=$(parse_value "starting_superblock_number")

# Export DisputeGameFactory parameters
export NETWORK_ADMIN_ADDRESS=$(parse_value "admin_address")

# Load .env for private key and API key
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Validation
if [ -z "$NETWORK_RPC_URL" ]; then
    echo "Error: rpc_url not configured for network '$NETWORK_NAME'"
    exit 1
fi

if [ -z "$NETWORK_CHAIN_ID" ]; then
    echo "Error: chain_id not configured for network '$NETWORK_NAME'"
    exit 1
fi

if [ -z "$DEPLOYER_PRIVATE_KEY" ]; then
    echo "Error: DEPLOYER_PRIVATE_KEY not set in .env"
    exit 1
fi

if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "Warning: ETHERSCAN_API_KEY not set in .env. Verification will be skipped."
fi

# Validate ComposeL2OutputOracle parameters
if [ -z "$NETWORK_VERIFIER_ADDRESS" ]; then
    echo "Error: verifier_address not configured for network '$NETWORK_NAME'"
    exit 1
fi

if [ -z "$NETWORK_OWNER_ADDRESS" ]; then
    echo "Error: owner_address not configured for network '$NETWORK_NAME'"
    exit 1
fi

if [ -z "$NETWORK_PROPOSER_ADDRESS" ]; then
    echo "Error: proposer_address not configured for network '$NETWORK_NAME'"
    exit 1
fi

if [ -z "$NETWORK_AGGREGATION_VKEY" ]; then
    echo "Error: aggregation_vkey not configured for network '$NETWORK_NAME'"
    exit 1
fi

if [ -z "$NETWORK_ADMIN_ADDRESS" ]; then
    echo "Error: admin_address not configured for network '$NETWORK_NAME'"
    exit 1
fi

echo "✓ Network configuration loaded for: $NETWORK_NAME"
