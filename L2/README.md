# L2 Rollup Contracts

Cross-rollup messaging and bridging contracts for L2 execution layers.

## 📋 Overview

This project contains the L2 contracts for cross-rollup communication:

- **Mailbox** - Cross-rollup message handling
- **PingPong** - Cross-rollup message demo
- **Bridge** - Asset bridging between rollups
- **BridgeableToken** - Token with cross-rollup support

## 🚀 Quick Start

### 1. Initial Setup

```bash
cd L2

# Initialize configuration files
just init-config

# Edit .env with your private key and coordinator address
vim .env

# Edit networks.toml with your rollup network details
vim networks.toml
```

### 2. Build Contracts

```bash
just build
```

### 3. Deploy to Network

```bash
# Deploy to a specific network
just deploy-network rollup-a

# Deploy to multiple networks
just deploy-multi rollup-a rollup-b
```

## 📖 Configuration

### Environment Variables (`.env`)

```bash
# Deployer Configuration
DEPLOYER_PRIVATE_KEY=0x...  # Your private key

# Deployment Configuration
DEPLOY_SALT=0x0000...       # Salt for CREATE2 deterministic deployment
COORDINATOR_ADDRESS=0x...   # Coordinator for cross-rollup messages
```

### Network Configuration (`networks.toml`)

```toml
[rollup-a]
name = "Rollup A"
chain_id = 77777
rpc_url = "http://..."
# Blockscout explorer configuration
explorer_type = "blockscout"
explorer_url = "https://rollup-a-bck.explorer.testnet.compose.network/api/eth-rpc"
explorer_api_url = "https://rollup-a-bck.explorer.testnet.compose.network/api/"

[rollup-b]
name = "Rollup B"
chain_id = 88888
rpc_url = "http://..."
# ... same fields
```

## 🔧 Available Commands

### Setup & Build
```bash
just setup          # Initialize project
just build          # Compile contracts
just clean          # Clean build artifacts
just test           # Run tests
```

### Configuration
```bash
just init-config        # Create .env and networks.toml from examples
just check-setup        # Validate configuration
just list-networks      # Show available networks
just show-network <net> # Show network details
just test-network <net> # Test network connection
```

### Deployment
```bash
just deploy-network <network>     # Deploy to specific network
just deploy-multi <net1> <net2>   # Deploy to multiple networks
just show-deployments             # Show all deployments
just get-deployment <network>     # Get deployment for network
```

### Verification (Blockscout)
```bash
just verify-all <network>              # Verify all contracts
just verify-mailbox <net> <addr> <coordinator>
just verify-pingpong <net> <addr> <mailbox>
just verify-bridge <net> <addr> <mailbox>
just verify-token <net> <addr> <bridge>
```

### Contract Queries
```bash
just get-mailbox <network>   # Get Mailbox address
just get-pingpong <network>  # Get PingPong address
just get-bridge <network>    # Get Bridge address
just get-token <network>     # Get Token address
```

## 📁 Project Structure

```
L2/
├── src/                    # Contract source files
│   ├── Mailbox.sol
│   ├── PingPong.sol
│   ├── Bridge.sol
│   └── BridgeableToken.sol
├── script/                 # Deployment scripts
│   ├── DeployContracts.s.sol
│   └── PlayPingPong.s.sol
├── scripts/                # Helper scripts
│   ├── parse-network.sh
│   ├── deploy.sh
│   └── save-deployment.sh
├── test/                   # Test files
├── artifacts/              # Deployment artifacts (gitignored)
├── .env                    # Environment config (gitignored)
├── networks.toml           # Network configs (gitignored)
├── deployments.json        # Deployment tracking (gitignored)
└── justfile                # Command runner
```

## 🎯 Deployment Workflow

1. **Configure**: Set up `.env` and `networks.toml`
2. **Build**: `just build`
3. **Deploy**: `just deploy-network <network>`
4. **Verify**: Check `deployments.json` for deployed addresses
5. **Test**: Use `PlayPingPong.s.sol` to test cross-rollup messaging

## 🔐 Security Notes

- Never commit `.env` file (contains private keys)
- `networks.toml` and `deployments.json` are gitignored
- Use CREATE2 for deterministic addresses across rollups
- Always verify deployed contract addresses

## 📝 Notes

- All contracts use CREATE2 deployment for consistent addresses
- The same `COORDINATOR_ADDRESS` is used across all networks
- Deployment artifacts are saved to `artifacts/deploy-{network}.json`
- All deployments are tracked in `deployments.json`