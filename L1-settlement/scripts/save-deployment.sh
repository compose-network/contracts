#!/usr/bin/env bash
# Save deployment addresses to deployments.json

set -euo pipefail

NETWORK_NAME=$1
CHAIN_ID=$2
PROXY_ADMIN=$3
SUPERCHAIN_CONFIG_PROXY=$4
DISPUTE_GAME_FACTORY_PROXY=$5
ANCHOR_STATE_REGISTRY_PROXY=$6
ETH_LOCKBOX_PROXY=$7
DISPUTE_GAME_IMPL=$8

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
    "phase": "phase1-shared-infrastructure",
    "ProxyAdmin": "$PROXY_ADMIN",
    "SuperchainConfig": {
      "proxy": "$SUPERCHAIN_CONFIG_PROXY"
    },
    "DisputeGameFactory": {
      "proxy": "$DISPUTE_GAME_FACTORY_PROXY"
    },
    "AnchorStateRegistry": {
      "proxy": "$ANCHOR_STATE_REGISTRY_PROXY"
    },
    "ETHLockbox": {
      "proxy": "$ETH_LOCKBOX_PROXY"
    },
    "ComposeDisputeGame": {
      "implementation": "$DISPUTE_GAME_IMPL"
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
echo "Chain ID:                    $CHAIN_ID"
echo "Phase:                       Phase 1 - Shared Infrastructure"
echo ""
echo "Governance:"
echo "  ProxyAdmin:                $PROXY_ADMIN"
echo "  SuperchainConfig (Proxy):  $SUPERCHAIN_CONFIG_PROXY"
echo ""
echo "Settlement:"
echo "  DisputeGameFactory (Proxy): $DISPUTE_GAME_FACTORY_PROXY"
echo "  AnchorStateRegistry (Proxy): $ANCHOR_STATE_REGISTRY_PROXY"
echo "  ComposeDisputeGame (Impl):   $DISPUTE_GAME_IMPL"
echo ""
echo "Liquidity:"
echo "  ETHLockbox (Proxy):        $ETH_LOCKBOX_PROXY"
echo ""
echo "Deployed at:                 $TIMESTAMP"
echo "========================================"
