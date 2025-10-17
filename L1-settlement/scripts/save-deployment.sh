#!/usr/bin/env bash
# Save deployment addresses to deployments.json

set -euo pipefail

NETWORK_NAME=$1
CHAIN_ID=$2
ORACLE_PROXY=$3
ORACLE_IMPL=$4
GAME_IMPL=$5
FACTORY_PROXY=$6
FACTORY_IMPL=$7
PROXY_ADMIN=$8

DEPLOYMENT_FILE="deployments.json"

# Create deployments.json if it doesn't exist
if [ ! -f "$DEPLOYMENT_FILE" ]; then
    echo "{}" > "$DEPLOYMENT_FILE"
fi

# Get current timestamp
TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

# Create deployment entry
DEPLOYMENT_JSON=$(cat <<EOF
{
  "$NETWORK_NAME": {
    "chain_id": "$CHAIN_ID",
    "ComposeL2OutputOracle": {
      "proxy": "$ORACLE_PROXY",
      "implementation": "$ORACLE_IMPL"
    },
    "ComposeDisputeGame": {
      "implementation": "$GAME_IMPL"
    },
    "DisputeGameFactory": {
      "proxy": "$FACTORY_PROXY",
      "implementation": "$FACTORY_IMPL",
      "proxyAdmin": "$PROXY_ADMIN"
    },
    "deployed_at": "$TIMESTAMP"
  }
}
EOF
)

# Merge with existing deployments
TMP_FILE=$(mktemp)
jq -s '.[0] * .[1]' "$DEPLOYMENT_FILE" <(echo "$DEPLOYMENT_JSON") > "$TMP_FILE"
mv "$TMP_FILE" "$DEPLOYMENT_FILE"

echo ""
echo "✓ Deployment addresses saved to $DEPLOYMENT_FILE"
echo ""
echo "=== Deployment Summary for $NETWORK_NAME ==="
echo "Chain ID:               $CHAIN_ID"
echo ""
echo "ComposeL2OutputOracle:"
echo "  Proxy:                $ORACLE_PROXY"
echo "  Implementation:       $ORACLE_IMPL"
echo ""
echo "ComposeDisputeGame:"
echo "  Implementation:       $GAME_IMPL"
echo ""
echo "DisputeGameFactory:"
echo "  Proxy:                $FACTORY_PROXY"
echo "  Implementation:       $FACTORY_IMPL"
echo "  ProxyAdmin:           $PROXY_ADMIN"
echo ""
echo "Deployed at:            $TIMESTAMP"
echo "========================================"
