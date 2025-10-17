#!/usr/bin/env bash
# ============================================================================
# Save Deployment to deployments.json
# ============================================================================
# Usage: source scripts/save-deployment.sh <network-name>
# ============================================================================

set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Error: Network name required"
    exit 1
fi

NETWORK=$1
ARTIFACT_FILE="artifacts/deploy-${NETWORK}.json"
DEPLOYMENTS_FILE="deployments.json"

# Check if artifact file exists
if [ ! -f "$ARTIFACT_FILE" ]; then
    echo "Warning: Deployment artifact not found: $ARTIFACT_FILE"
    return 0
fi

# Create deployments.json if it doesn't exist
if [ ! -f "$DEPLOYMENTS_FILE" ]; then
    echo "{}" > "$DEPLOYMENTS_FILE"
fi

# Extract deployment info from artifact
CHAIN_ID=$(jq -r '.chainInfo.chainId' "$ARTIFACT_FILE")
DEPLOYMENT_BLOCK=$(jq -r '.chainInfo.deploymentBlock' "$ARTIFACT_FILE")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Extract contract addresses
MAILBOX=$(jq -r '.addresses.Mailbox' "$ARTIFACT_FILE")
PINGPONG=$(jq -r '.addresses.PingPong' "$ARTIFACT_FILE")
BRIDGE=$(jq -r '.addresses.Bridge' "$ARTIFACT_FILE")
TOKEN=$(jq -r '.addresses.BridgeableToken' "$ARTIFACT_FILE")
COORDINATOR=$(jq -r '.addresses.Coordinator' "$ARTIFACT_FILE")

# Update deployments.json using jq
jq --arg network "$NETWORK" \
   --argjson chain_id "$CHAIN_ID" \
   --argjson deployment_block "$DEPLOYMENT_BLOCK" \
   --arg timestamp "$TIMESTAMP" \
   --arg mailbox "$MAILBOX" \
   --arg pingpong "$PINGPONG" \
   --arg bridge "$BRIDGE" \
   --arg token "$TOKEN" \
   --arg coordinator "$COORDINATOR" \
   '.[$network] = {
     "chain_id": $chain_id,
     "deployment_block": $deployment_block,
     "timestamp": $timestamp,
     "contracts": {
       "Mailbox": $mailbox,
       "PingPong": $pingpong,
       "Bridge": $bridge,
       "BridgeableToken": $token,
       "Coordinator": $coordinator
     }
   }' "$DEPLOYMENTS_FILE" > "${DEPLOYMENTS_FILE}.tmp"

mv "${DEPLOYMENTS_FILE}.tmp" "$DEPLOYMENTS_FILE"

echo "✓ Deployment saved to $DEPLOYMENTS_FILE"
