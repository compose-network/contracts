# Quick Start Guide

Get up and running with Compose Contracts deployment in 5 minutes.

## Prerequisites

Install required tools:

```bash
# macOS
brew install just jq

# Linux
cargo install just && sudo apt-get install jq

# Install Foundry (all platforms)
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## Step-by-Step Deployment

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/compose-network/compose-contracts.git
cd compose-contracts

# Initialize submodules and dependencies
just setup
```

This will:
- Initialize all git submodules
- Checkout Optimism contracts at `op-deployer/v0.3.3`
- Install Forge dependencies

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your configuration
# Required:
# - DEPLOYER_PRIVATE_KEY=0x...
# - ETHERSCAN_API_KEY=...
```

### 3. Configure Networks

```bash
# Copy network configuration template
cp networks.toml.example networks.toml

# Edit networks.toml with your network details
# For each network, configure:
# - RPC URL and chain ID
# - Explorer URLs
# - ComposeL2OutputOracle parameters (verifier, owner, proposer, etc.)
# - DisputeGameFactory admin address
```

**Example network configuration:**

```toml
[networks.sepolia]
name = "Ethereum Sepolia"
rpc_url = "https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY"
chain_id = 11155111
explorer_url = "https://sepolia.etherscan.io"
explorer_api_url = "https://api-sepolia.etherscan.io/api"

verifier_address = "0x17Ef331C3c90E9e5718e81085c721a404eF18436"
owner_address = "0xYourOwnerAddress"
proposer_address = "0xYourProposerAddress"
aggregation_vkey = "0x0059ae2f8c8ad61a6af02594067148b58dbecff2e3352170923efda8ea603f1e"
starting_superblock_number = 0
admin_address = "0xYourAdminAddress"
```

### 4. Validate Setup

```bash
# Check that everything is configured correctly
just check-setup
```

This validates:
- Required tools are installed
- Submodules are initialized
- Configuration files exist
- Environment variables are set

### 5. Build Contracts

```bash
# Compile all contracts
just build
```

### 6. Deploy

#### Deploy to Single Network

```bash
# List available networks
just list-networks

# Deploy to specific network
just deploy-network sepolia
```

#### Deploy to Multiple Networks

```bash
# Deploy to multiple networks at once
just deploy-multi sepolia hoodi
```

### 7. View Deployment Addresses

```bash
# Show all deployments in pretty format
just show-deployments

# Get JSON output for specific network
just get-deployment sepolia
```

## What Gets Deployed?

The deployment script automatically deploys in this order:

1. **ComposeL2OutputOracle**
   - Implementation contract
   - ERC1967 Proxy
   - Initializes with network-specific parameters

2. **ComposeDisputeGame**
   - Implementation contract
   - Uses ComposeL2OutputOracle proxy address

3. **DisputeGameFactory**
   - ProxyAdmin contract
   - Implementation contract
   - Bedrock Proxy
   - Initializes with admin address

## Deployment Output

After successful deployment, you'll see:

```
=========================================
✓ Deployment to sepolia complete!
=========================================

=== Deployment Summary for sepolia ===
Chain ID:               11155111

ComposeL2OutputOracle:
  Proxy:                0x...
  Implementation:       0x...

ComposeDisputeGame:
  Implementation:       0x...

DisputeGameFactory:
  Proxy:                0x...
  Implementation:       0x...
  ProxyAdmin:           0x...

Deployed at:            2025-10-17 01:00:00 UTC
========================================
```

All addresses are automatically saved to `deployments.json`.

## Verification

Contracts are automatically verified on Etherscan during deployment if `ETHERSCAN_API_KEY` is set.

To manually verify all contracts:

```bash
just verify-all sepolia
```

## Common Issues

### "Submodule not found"
```bash
just setup
```

### "Build failed"
```bash
just clean
just build
```

### "Network not found"
Check that your network is configured in `networks.toml`:
```bash
just list-networks
```

### "Insufficient funds"
Ensure your deployer wallet has enough ETH:
- Testnet: ~0.1 ETH
- Mainnet: ~0.5 ETH (depends on gas prices)

### "RPC connection failed"
Test your network connection:
```bash
just test-network sepolia
```

## Next Steps

- ✅ View all deployments: `just show-deployments`
- ✅ Deploy to additional networks: `just deploy-network <network>`
- ✅ Verify contracts: `just verify-all <network>`
- ✅ Read detailed guides in [docs/](.)

## Quick Reference

```bash
# Setup
just setup                    # One-time setup
just check-setup             # Validate environment

# Build
just build                   # Compile contracts
just clean                   # Clean artifacts

# Deploy
just list-networks           # Show configured networks
just deploy-network <name>   # Deploy to one network
just deploy-multi <names>    # Deploy to multiple networks

# View
just show-deployments        # Show all deployments
just get-deployment <name>   # Get specific network

# Verify
just verify-all <network>    # Verify all contracts
```

## Need Help?

- Read [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed walkthrough
- Check [NETWORK_CONFIG.md](NETWORK_CONFIG.md) for network setup
- See [CONTRACT_PARAMS.md](CONTRACT_PARAMS.md) for parameter explanations

## That's It! 🎉

Your contracts are now deployed and ready to use!
