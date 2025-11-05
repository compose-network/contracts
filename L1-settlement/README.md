# Compose Contracts

⚠️ **WARNING: HEAVY DEVELOPMENT** ⚠️

This project is currently in **heavy development phase** and has **NOT been audited**. The L1 settlement contracts are **NOT production-ready** and should not be used in mainnet environments or with real assets. Use at your own risk.

---

Smart contracts for the Compose Network L1 deployment. This repository contains the core contracts for managing L2 outputs and dispute resolution.

## Contracts

- **ComposeL2OutputOracle**: ERC1967 upgradeable proxy contract for proposing and verifying L2 outputs using SP1 proofs
- **ComposeDisputeGame**: Dispute game implementation for output validation
- **DisputeGameFactory**: Optimism's factory contract for creating dispute games

## Quick Start

Deploy all contracts to a network in 3 commands:

```bash
# 1. Setup submodules and dependencies
just setup

# 2. Build contracts
just build

# 3. Configure (edit .env and networks.toml manually)
cp .env.example .env
cp networks.toml.example networks.toml
# Edit both files with your configuration

# 4. Deploy to specific network
just deploy-network sepolia

# OR deploy to multiple networks
just deploy-multi sepolia hoodi
```

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) - Ethereum development toolkit
- [just](https://github.com/casey/just#installation) - Command runner
- [jq](https://stedolan.github.io/jq/) - JSON processor
- Git with submodule support

### Installation

**macOS:**
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install just
brew install just

# Install jq
brew install jq
```

**Linux:**
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install just
cargo install just
# or
wget -qO- https://github.com/casey/just/releases/latest/download/just-$(uname -m)-unknown-linux-musl.tar.gz | sudo tar xvz -C /usr/local/bin

# Install jq
sudo apt-get install jq  # Debian/Ubuntu
sudo yum install jq      # RHEL/CentOS
```

## Configuration

### 1. Environment Variables (.env)

Copy `.env.example` and configure:

```bash
cp .env.example .env
```

Required variables:
```bash
# Deployer private key (keep secure!)
DEPLOYER_PRIVATE_KEY=0x...

# Etherscan API key for contract verification
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY

# DisputeGameFactory address (set after deployment)
HOODI_GAME_FACTORY_ADDRESS=
```

### 2. Network Configuration (networks.toml)

Copy `networks.toml.example` and configure your target networks:

```bash
cp networks.toml.example networks.toml
```

Each network requires:
- RPC URL and chain ID
- Explorer URLs for verification
- ComposeL2OutputOracle initialization parameters:
  - `verifier_address` - SP1Verifier contract address
  - `owner_address` - Owner with admin permissions
  - `proposer_address` - Approved proposer address
  - `aggregation_vkey` - SP1 aggregation verification key
  - `starting_superblock_number` - Starting superblock (usually 0)
- DisputeGameFactory parameters:
  - `admin_address` - Admin address for the factory

Example:
```toml
[networks.sepolia]
name = "Ethereum Sepolia"
rpc_url = "https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY"
chain_id = 11155111
explorer_url = "https://sepolia.etherscan.io"
explorer_api_url = "https://api-sepolia.etherscan.io/api"

verifier_address = "0x..."
owner_address = "0x..."
proposer_address = "0x..."
aggregation_vkey = "0x..."
starting_superblock_number = 0
admin_address = "0x..."
```

See `networks.toml.example` for complete examples.

## Available Commands

Run `just` to see all available commands:

### Setup & Build
```bash
just setup                # Initialize submodules and dependencies
just build                # Build all contracts
just clean                # Clean build artifacts
just check-setup          # Validate environment setup
```

### Network Management
```bash
just list-networks        # List available networks
just test-network <name>  # Test network connection
```

### Deployment
```bash
# Multi-chain deployment (recommended)
just deploy-network <network>       # Deploy to specific network
just deploy-multi <networks...>     # Deploy to multiple networks

# View deployments
just show-deployments               # Show all deployed addresses
just get-deployment <network>       # Get addresses for specific network
```

### Verification
```bash
just verify-all <network>           # Verify all contracts on Etherscan
```

### Advanced (Individual Contract Deployment)
```bash
just deploy-oracle <network>        # Deploy only ComposeL2OutputOracle
just deploy-game <network> <addr>   # Deploy only ComposeDisputeGame
just deploy-factory <network>       # Deploy only DisputeGameFactory
```

## Deployment Flow

The deployment process automatically deploys contracts in the correct order:

```
1. ComposeL2OutputOracle (Implementation + ERC1967 Proxy)
   └── Initializes with network-specific parameters
   
2. ComposeDisputeGame (Implementation)
   └── Requires ComposeL2OutputOracle proxy address
   
3. DisputeGameFactory (ProxyAdmin + Implementation + Bedrock Proxy)
   └── Initializes with admin address
```

All addresses are automatically saved to `deployments.json`.

## Deployment Tracking

Deployment addresses are automatically saved in `deployments.json`:

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

View deployments:
```bash
just show-deployments           # Pretty-printed view
just get-deployment sepolia     # Get specific network (JSON)
```

## Contract Verification

Contracts are automatically verified on Etherscan during deployment if `ETHERSCAN_API_KEY` is set.

Manual verification:
```bash
just verify-all sepolia
```

## Development

### Build Contracts
```bash
just build
```

### Clean Artifacts
```bash
just clean
```

### Run Tests
```bash
forge test
```

### Check Setup
```bash
just check-setup
```

## Documentation

- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) - Detailed deployment walkthrough
- [Quick Start](docs/QUICKSTART.md) - 5-minute setup guide
- [Network Configuration](docs/NETWORK_CONFIG.md) - Network setup details
- [Contract Parameters](docs/CONTRACT_PARAMS.md) - Parameter explanations

## Repository Structure

```
compose-contracts/
├── src/                          # Contract source files
│   ├── ComposeL2OutputOracle.sol
│   ├── ComposeDisputeGame.sol
│   └── interfaces/
├── script/                       # Deployment scripts
│   ├── DeployComposeL2OutputOracle.s.sol
│   ├── DeployComposeDisputeGame.s.sol
│   └── DeployDisputeGameFactory.s.sol
├── scripts/                      # Bash helper scripts
│   ├── deploy.sh                 # Main deployment orchestrator
│   ├── parse-network.sh          # Parse networks.toml
│   └── save-deployment.sh        # Save addresses to JSON
├── test/                         # Contract tests
├── docs/                         # Documentation
├── lib/                          # Dependencies (gitmodules)
│   └── optimism/                 # Optimism contracts (op-deployer/v0.3.3)
├── justfile                      # Command definitions
├── networks.toml                 # Network configurations (gitignored)
├── networks.toml.example         # Example network config
├── deployments.json              # Deployment addresses (gitignored)
├── .env                          # Private config (gitignored)
├── .env.example                  # Environment template
└── foundry.toml                  # Foundry configuration
```

## Security Notes

- **Never commit `.env`** - Contains private keys
- **Never commit `networks.toml`** - May contain sensitive data
- **Never commit `deployments.json`** - May contain sensitive addresses
- Use a dedicated deployer wallet, not your main wallet
- Test on testnets before mainnet deployment
- Always verify contract source code after deployment

## Troubleshooting

### "Submodule not initialized"
```bash
just setup
```

### "Build failed"
```bash
just clean
just build
```

### "Network connection failed"
```bash
# Test your network configuration
just test-network sepolia

# Check RPC URL in networks.toml
```

### "Verification failed"
- Ensure `ETHERSCAN_API_KEY` is set in `.env`
- Wait a few minutes and retry: `just verify-all <network>`
- Check explorer API URL in `networks.toml`

### "Contract size exceeded"
The contracts are built with optimizations enabled in `foundry.toml`. If size issues occur:
- Ensure you're using the latest Solidity version
- Check that all submodules are properly initialized

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions welcome! Please follow the standard GitHub flow:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

- [Documentation](docs/)
- [GitHub Issues](https://github.com/compose-network/compose-contracts/issues)

## 🔗 References

- [Optimism Bedrock](https://github.com/ethereum-optimism/optimism)
- [SP1 Contracts](https://github.com/succinctlabs/sp1-contracts)
- [Foundry Book](https://book.getfoundry.sh/)
