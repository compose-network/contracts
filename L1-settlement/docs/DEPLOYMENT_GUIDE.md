# Deployment Guide

Complete guide for deploying Compose Contracts to L1 networks.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Deployment Process](#deployment-process)
- [Verification](#verification)
- [Post-Deployment](#post-deployment)
- [Troubleshooting](#troubleshooting)

## Overview

This repository deploys three main contracts to L1 networks (Ethereum, Hoodi, etc.):

1. **ComposeL2OutputOracle** - Manages L2 output proposals with SP1 proof verification
2. **ComposeDisputeGame** - Handles dispute resolution for outputs
3. **DisputeGameFactory** - Factory contract from Optimism for creating dispute games

### Deployment Architecture

```
L1 Network (Ethereum/Hoodi)
├── ComposeL2OutputOracle
│   ├── Implementation (Logic contract)
│   └── ERC1967Proxy (Upgradeable proxy)
│
├── ComposeDisputeGame
│   └── Implementation (Logic contract)
│
└── DisputeGameFactory
    ├── ProxyAdmin (Admin contract)
    ├── Implementation (Logic contract)
    └── BedrockProxy (Proxy contract)
```

## Prerequisites

### Required Tools

1. **Foundry** - Ethereum development toolkit
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **just** - Command runner
   ```bash
   # macOS
   brew install just
   
   # Linux
   cargo install just
   ```

3. **jq** - JSON processor
   ```bash
   # macOS
   brew install jq
   
   # Linux
   sudo apt-get install jq
   ```

4. **Git** - With submodule support

### Verify Installation

```bash
forge --version
just --version
jq --version
git --version
```

### Network Requirements

- **Deployer wallet** with sufficient funds:
  - Testnet: ~0.1 ETH
  - Mainnet: ~0.5 ETH (varies with gas prices)
  
- **RPC endpoint** for target network

- **Etherscan API key** for contract verification

## Configuration

### Step 1: Initialize Repository

```bash
# Clone repository
git clone https://github.com/compose-network/compose-contracts.git
cd compose-contracts

# Initialize submodules and dependencies
just setup
```

The `just setup` command:
- Initializes all git submodules recursively
- Checks out Optimism contracts at tag `op-deployer/v0.3.3`
- Installs Forge dependencies

### Step 2: Configure Environment Variables

Create `.env` file from template:

```bash
cp .env.example .env
```

Edit `.env` and set:

```bash
# Deployer private key (REQUIRED)
DEPLOYER_PRIVATE_KEY=0x1234567890abcdef...

# Etherscan API key (REQUIRED for verification)
ETHERSCAN_API_KEY=ABCDEF1234567890

# DisputeGameFactory address (optional, set after deployment)
HOODI_GAME_FACTORY_ADDRESS=
```

**Security Notes:**
- Never commit `.env` file
- Use a dedicated deployer wallet
- Keep private keys secure

### Step 3: Configure Networks

Create `networks.toml` from template:

```bash
cp networks.toml.example networks.toml
```

Edit `networks.toml` and configure each target network:

```toml
[networks.sepolia]
name = "Ethereum Sepolia"
rpc_url = "https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY"
chain_id = 11155111
explorer_url = "https://sepolia.etherscan.io"
explorer_api_url = "https://api-sepolia.etherscan.io/api"

# ComposeL2OutputOracle Parameters
verifier_address = "0x17Ef331C3c90E9e5718e81085c721a404eF18436"
owner_address = "0xYourOwnerAddress"
proposer_address = "0xYourProposerAddress"
aggregation_vkey = "0x0059ae2f8c8ad61a6af02594067148b58dbecff2e3352170923efda8ea603f1e"
starting_superblock_number = 0

# DisputeGameFactory Parameters
admin_address = "0xYourAdminAddress"
```

See [NETWORK_CONFIG.md](NETWORK_CONFIG.md) for detailed configuration guide.

### Step 4: Validate Setup

```bash
just check-setup
```

This validates:
- All required tools are installed
- Submodules are initialized correctly
- Configuration files exist and are valid
- Environment variables are set

Expected output:
```
=== Required Tools ===
✓ Foundry: forge 0.2.0
✓ just: just 1.14.0
✓ jq: jq-1.6
✓ git: git version 2.39.0

=== Git Submodules ===
✓ Optimism submodule initialized
  Branch: op-deployer/v0.3.3
✓ forge-std submodule initialized

=== Configuration Files ===
✓ .env file exists
  ✓ DEPLOYER_PRIVATE_KEY is set
  ✓ ETHERSCAN_API_KEY is set
✓ networks.toml file exists
  Configured networks: 3

=== Summary ===
✓ All checks passed! Ready to deploy.
```

## Deployment Process

### Build Contracts

```bash
just build
```

This compiles all contracts, including:
- ComposeL2OutputOracle and dependencies
- ComposeDisputeGame and dependencies
- DisputeGameFactory from Optimism submodule

### List Available Networks

```bash
just list-networks
```

Output:
```
Available networks:
  - sepolia
  - hoodi
  - mainnet
```

### Test Network Connection

Before deploying, test your network connection:

```bash
just test-network sepolia
```

Output:
```
Testing connection to Ethereum Sepolia...
RPC URL: https://eth-sepolia.g.alchemy.com/v2/...
✓ Connected! Current block: 5234567
```

### Deploy to Single Network

```bash
just deploy-network sepolia
```

The deployment script will:

1. **Deploy ComposeL2OutputOracle**
   - Deploy implementation contract
   - Deploy ERC1967Proxy
   - Initialize with network parameters
   - Verify on Etherscan (if API key provided)

2. **Deploy ComposeDisputeGame**
   - Deploy implementation contract
   - Link to ComposeL2OutputOracle proxy
   - Verify on Etherscan

3. **Deploy DisputeGameFactory**
   - Deploy ProxyAdmin
   - Deploy implementation contract
   - Deploy Bedrock Proxy
   - Initialize with admin address
   - Verify on Etherscan

4. **Save Addresses**
   - Automatically save all addresses to `deployments.json`

### Deploy to Multiple Networks

```bash
just deploy-multi sepolia hoodi
```

Deploys sequentially to each network and shows summary at the end.

### View Deployment Addresses

```bash
# Pretty-printed view
just show-deployments

# JSON output for specific network
just get-deployment sepolia
```

## Verification

### Automatic Verification

Contracts are automatically verified during deployment if:
- `ETHERSCAN_API_KEY` is set in `.env`
- Network has `explorer_api_url` in `networks.toml`

### Manual Verification

If automatic verification fails or you need to reverify:

```bash
# Verify all contracts for a network
just verify-all sepolia
```

This verifies:
- ComposeL2OutputOracle implementation
- ComposeDisputeGame implementation
- DisputeGameFactory implementation
- ProxyAdmin

### Individual Contract Verification

```bash
# Get deployed addresses
ORACLE_IMPL=$(just get-deployment sepolia | jq -r '.ComposeL2OutputOracle.implementation')
GAME_IMPL=$(just get-deployment sepolia | jq -r '.ComposeDisputeGame.implementation')

# Verify specific contract
just verify-oracle sepolia $ORACLE_IMPL
just verify-game sepolia $GAME_IMPL
```

## Post-Deployment

### 1. Verify Deployment Success

```bash
# Check all addresses are saved
just show-deployments

# Test contract interaction
cast call <ORACLE_PROXY> "owner()" --rpc-url <RPC_URL>
```

### 2. Backup Deployment Data

```bash
# Backup deployments.json
cp deployments.json deployments.backup.json

# Backup broadcast logs (contain transaction details)
tar -czf broadcast-backup.tar.gz broadcast/
```

### 3. Update Application Configuration

Use deployed addresses in your application:

```javascript
// Example: Use deployed addresses
const addresses = require('./deployments.json');
const oracleAddress = addresses.sepolia.ComposeL2OutputOracle.proxy;
const gameAddress = addresses.sepolia.ComposeDisputeGame.implementation;
const factoryAddress = addresses.sepolia.DisputeGameFactory.proxy;
```

### 4. Test Contracts

```bash
# Run integration tests
forge test --fork-url $RPC_URL
```

### 5. Document Deployment

Keep a record of:
- Deployment date and time
- Deployer address
- All contract addresses
- Network and chain ID
- Git commit hash
- Any deployment notes

## Advanced Usage

### Deploy Individual Contracts

For more control, deploy contracts individually:

```bash
# Deploy only ComposeL2OutputOracle
just deploy-oracle sepolia

# Deploy only ComposeDisputeGame (requires oracle address)
just deploy-game sepolia 0xOracleProxyAddress

# Deploy only DisputeGameFactory
just deploy-factory sepolia
```

### Custom Deployment Script

For special requirements, modify or create custom deployment scripts:

```bash
# Copy and modify existing script
cp scripts/deploy.sh scripts/deploy-custom.sh

# Edit deploy-custom.sh for your needs
vim scripts/deploy-custom.sh

# Run custom script
./scripts/deploy-custom.sh sepolia
```

## Troubleshooting

### Build Issues

**Problem:** Build fails with dependency errors

**Solution:**
```bash
just clean
cd lib/optimism/packages/contracts-bedrock && forge install --force
cd ../../../../
just build
```

### Submodule Issues

**Problem:** Submodule not initialized or wrong version

**Solution:**
```bash
git submodule deinit -f lib/optimism
rm -rf .git/modules/lib/optimism
just setup
```

### RPC Connection Issues

**Problem:** Cannot connect to RPC

**Solution:**
```bash
# Test connection
just test-network sepolia

# Try alternative RPC URL
# Edit networks.toml with different RPC endpoint
```

### Gas Estimation Issues

**Problem:** Transaction fails with "out of gas"

**Solution:**
- Ensure deployer wallet has sufficient funds
- Check gas prices: `cast gas-price --rpc-url $RPC_URL`
- Increase gas limit in Foundry config if needed

### Verification Failures

**Problem:** Contract verification fails

**Solution:**
```bash
# Wait a few minutes (block explorer needs to index)
sleep 120

# Retry verification
just verify-all sepolia

# Check Etherscan API key is valid
echo $ETHERSCAN_API_KEY

# Verify API URL is correct in networks.toml
```

### Deployment Address Extraction Issues

**Problem:** Cannot find deployed addresses in broadcast logs

**Solution:**
```bash
# Manually check broadcast directory
ls -lah broadcast/*/[CHAIN_ID]/

# View broadcast JSON
jq . broadcast/DeployComposeL2OutputOracle.s.sol/[CHAIN_ID]/run-latest.json
```

### Network-Specific Issues

**Sepolia:**
- Get testnet ETH from [Sepolia Faucet](https://sepoliafaucet.com/)
- Use Alchemy or Infura for reliable RPC

**Hoodi:**
- Contact network operators for RPC access
- Ensure custom network parameters are correct

**Mainnet:**
- Double-check all configurations
- Test on testnet first
- Use hardware wallet for mainnet deployments

## Best Practices

### Before Deployment

- ✅ Test on testnet first
- ✅ Verify all configuration parameters
- ✅ Ensure sufficient funds in deployer wallet
- ✅ Backup existing deployments
- ✅ Run `just check-setup`

### During Deployment

- ✅ Monitor transaction status
- ✅ Keep terminal output logs
- ✅ Note any warnings or errors

### After Deployment

- ✅ Verify all contracts on block explorer
- ✅ Test contract interactions
- ✅ Backup `deployments.json` and `broadcast/`
- ✅ Document addresses for team
- ✅ Update application configuration

## Security Checklist

- [ ] Private keys never committed to git
- [ ] `.env` file is gitignored
- [ ] `networks.toml` is gitignored
- [ ] Deployer wallet is dedicated (not main wallet)
- [ ] All contracts verified on block explorer
- [ ] Contract addresses documented securely
- [ ] Deployment tested on testnet first
- [ ] Admin/owner addresses are correct
- [ ] Proposer address is correct

## Support

- Documentation: [docs/](.)
- GitHub Issues: [compose-contracts/issues](https://github.com/compose-network/compose-contracts/issues)

## References

- [Optimism Bedrock Docs](https://docs.optimism.io/builders/chain-operators/tutorials/create-l2-rollup)
- [Foundry Book](https://book.getfoundry.sh/)
- [ERC-1967 Proxy](https://eips.ethereum.org/EIPS/eip-1967)
