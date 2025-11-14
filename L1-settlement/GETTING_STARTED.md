# Getting Started with Compose Contracts Deployment

This guide will help you deploy Compose Contracts in 3 simple commands.

## 🚀 Quick Start

```bash
# 1. Setup
just setup

# 2. Build
just build

# 3. Configure
cp .env.example .env
cp networks.toml.example networks.toml
# Edit both files with your configuration

# 4. Deploy
just deploy-network sepolia
```

## ✅ What You Need

### Required Tools
- **Foundry** - `curl -L https://foundry.paradigm.xyz | bash && foundryup`
- **just** - `brew install just` (macOS) or `cargo install just` (Linux)
- **jq** - `brew install jq` (macOS) or `apt install jq` (Linux)

### Required Information
- **Deployer Private Key** - Wallet with funds (~0.5 ETH)
- **Etherscan API Key** - For contract verification
- **Network RPC URL** - Alchemy, Infura, or custom RPC
- **Contract Parameters** - See below

## 📝 Configuration Steps

### 1. Environment Variables (.env)

```bash
cp .env.example .env
```

Edit `.env`:
```bash
DEPLOYER_PRIVATE_KEY=0xYourPrivateKey
ETHERSCAN_API_KEY=YourEtherscanAPIKey
```

### 2. Network Configuration (networks.toml)

```bash
cp networks.toml.example networks.toml
```

Edit `networks.toml` for each network:

```toml
[networks.sepolia]
name = "Ethereum Sepolia"
rpc_url = "https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY"
chain_id = 11155111
explorer_url = "https://sepolia.etherscan.io"
explorer_api_url = "https://api-sepolia.etherscan.io/api"

# Required parameters
verifier_address = "0x..."           # SP1Verifier contract
owner_address = "0x..."              # Admin owner (use multisig for mainnet)
proposer_address = "0x..."           # L2 output proposer
aggregation_vkey = "0x..."           # SP1 verification key (32 bytes)
starting_superblock_number = 0       # Usually 0 for new deployments
admin_address = "0x..."              # DisputeGameFactory admin
```

**Parameter Details:**
- `verifier_address` - Deployed SP1Verifier contract address
- `owner_address` - Admin address with update permissions (use multisig for mainnet!)
- `proposer_address` - Authorized to submit L2 outputs (hot wallet)
- `aggregation_vkey` - From your SP1 build output (must match your proving key)
- `starting_superblock_number` - 0 for new deployment, N for migration
- `admin_address` - Controls DisputeGameFactory (can be same as owner)

## 🎯 Deployment

### Check Your Setup
```bash
just check-setup
```

This validates:
- Tools installed
- Submodules initialized
- Configuration files exist
- Environment variables set

### List Available Networks
```bash
just list-networks
```

### Test Network Connection
```bash
just test-network sepolia
```

### Deploy to Single Network
```bash
just deploy-network sepolia
```

This will:
1. Deploy ComposeL2OutputOracle (implementation + proxy)
2. Deploy ComposeDisputeGame (implementation)
3. Deploy DisputeGameFactory (admin + implementation + proxy)
4. Verify all contracts on Etherscan
5. Save addresses to `deployments.json`

### Deploy to Multiple Networks
```bash
just deploy-multi sepolia hoodi
```

### View Deployed Addresses
```bash
# Pretty formatted
just show-deployments

# JSON for specific network
just get-deployment sepolia
```

## 📊 What Gets Deployed

```
ComposeL2OutputOracle
├── Implementation: 0x...
└── Proxy: 0x...

ComposeDisputeGame
└── Implementation: 0x...

DisputeGameFactory
├── ProxyAdmin: 0x...
├── Implementation: 0x...
└── Proxy: 0x...
```

All addresses saved to `deployments.json`:
```json
{
  "sepolia": {
    "chain_id": "11155111",
    "ComposeL2OutputOracle": {
      "proxy": "0x...",
      "implementation": "0x..."
    },
    "ComposeDisputeGame": {
      "implementation": "0x..."
    },
    "DisputeGameFactory": {
      "proxy": "0x...",
      "implementation": "0x...",
      "proxyAdmin": "0x..."
    },
    "deployed_at": "2025-10-17 01:00:00 UTC"
  }
}
```

## 🔍 Verification

Contracts are automatically verified during deployment.

Manual verification:
```bash
just verify-all sepolia
```

## 📚 Full Documentation

- **[README.md](README.md)** - Main documentation
- **[docs/QUICKSTART.md](docs/QUICKSTART.md)** - 5-minute guide
- **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** - Complete walkthrough
- **[docs/NETWORK_CONFIG.md](docs/NETWORK_CONFIG.md)** - Network configuration details
- **[docs/CONTRACT_PARAMS.md](docs/CONTRACT_PARAMS.md)** - Parameter explanations

## 🐛 Common Issues

### "Submodule not initialized"
```bash
just setup
```

### "Build failed"
```bash
just clean
just build
```

### "Network not found in networks.toml"
```bash
# Check available networks
just list-networks

# Verify network name matches exactly
```

### "Insufficient funds"
Ensure deployer wallet has ~0.5 ETH for mainnet or ~0.1 ETH for testnets.

### "RPC connection failed"
```bash
# Test connection
just test-network sepolia

# Update RPC URL in networks.toml
```

## 🔐 Security Notes

- ✅ Never commit `.env` or `networks.toml` (both gitignored)
- ✅ Use multisig for `owner_address` and `admin_address` on mainnet
- ✅ Keep `proposer_address` separate from owner (hot vs cold wallet)
- ✅ Test on testnet before mainnet
- ✅ Verify all contracts on block explorer

## 📞 Need Help?

1. Read full docs in [docs/](docs/)
2. Check [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) for detailed troubleshooting
3. Open a GitHub issue

## ✨ That's It!

You're ready to deploy Compose Contracts. Start with:

```bash
just setup
just build
just check-setup
just deploy-network sepolia
```

Happy deploying! 🚀
