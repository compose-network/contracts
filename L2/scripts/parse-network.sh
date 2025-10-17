#!/usr/bin/env bash
# ============================================================================
# Parse Network Configuration from networks.toml
# ============================================================================
# Usage: source scripts/parse-network.sh <network-name>
# Exports: NETWORK_NAME, NETWORK_CHAIN_ID, NETWORK_RPC_URL, etc.
# ============================================================================

set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Error: Network name required"
    echo "Usage: source scripts/parse-network.sh <network-name>"
    exit 1
fi

NETWORK=$1

# Check if networks.toml exists
if [ ! -f "networks.toml" ]; then
    echo "Error: networks.toml not found"
    echo "Please copy networks.toml.example to networks.toml and configure it"
    exit 1
fi

# Check if network exists in networks.toml
if ! grep -q "^\[$NETWORK\]" networks.toml; then
    echo "Error: Network '$NETWORK' not found in networks.toml"
    echo ""
    echo "Available networks:"
    grep '^\[' networks.toml | tr -d '[]' | sed 's/^/  - /'
    exit 1
fi

# Parse network configuration using awk
parse_toml() {
    local section=$1
    local key=$2
    awk -F= -v section="[$section]" -v key="$key" '
        $0 == section { in_section=1; next }
        /^\[/ { in_section=0 }
        in_section && $1 ~ "^"key {
            gsub(/^[ \t]+|[ \t]+$/, "", $2)  # trim whitespace
            gsub(/^"|"$/, "", $2)             # remove quotes
            gsub(/#.*$/, "", $2)              # remove comments
            gsub(/[ \t]+$/, "", $2)           # trim trailing whitespace again
            print $2
            exit
        }
    ' networks.toml
}

# Export network configuration as environment variables
export NETWORK_NAME=$(parse_toml "$NETWORK" "name")
export NETWORK_CHAIN_ID=$(parse_toml "$NETWORK" "chain_id")
export NETWORK_RPC_URL=$(parse_toml "$NETWORK" "rpc_url")
export NETWORK_EXPLORER_TYPE=$(parse_toml "$NETWORK" "explorer_type")
export NETWORK_EXPLORER_URL=$(parse_toml "$NETWORK" "explorer_url")
export NETWORK_EXPLORER_API_URL=$(parse_toml "$NETWORK" "explorer_api_url")

# Validate required fields
if [ -z "$NETWORK_NAME" ]; then
    echo "Error: 'name' not found for network '$NETWORK'"
    exit 1
fi

if [ -z "$NETWORK_CHAIN_ID" ]; then
    echo "Error: 'chain_id' not found for network '$NETWORK'"
    exit 1
fi

if [ -z "$NETWORK_RPC_URL" ]; then
    echo "Error: 'rpc_url' not found for network '$NETWORK'"
    exit 1
fi

# Success message
echo "✓ Network configuration loaded for: $NETWORK_NAME"
