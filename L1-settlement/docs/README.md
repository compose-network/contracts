# Compose Contracts Documentation

Complete documentation for deploying and managing Compose Network L1 contracts.

## 📚 Documentation Index

### Quick Start
- **[QUICKSTART.md](QUICKSTART.md)** - Get up and running in 5 minutes
  - Prerequisites installation
  - Step-by-step setup
  - First deployment
  - Common issues

### Comprehensive Guides
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Complete deployment walkthrough
  - Detailed setup instructions
  - Configuration explanation
  - Deployment process
  - Verification steps
  - Post-deployment tasks
  - Troubleshooting

- **[NETWORK_CONFIG.md](NETWORK_CONFIG.md)** - Network configuration guide
  - `networks.toml` structure
  - Field-by-field explanation
  - Network examples (Sepolia, Holesky, Mainnet, Hoodi)
  - RPC provider recommendations
  - Best practices

- **[CONTRACT_PARAMS.md](CONTRACT_PARAMS.md)** - Contract parameters explained
  - ComposeL2OutputOracle parameters
  - DisputeGameFactory parameters
  - How to obtain each parameter
  - Security considerations
  - Common mistakes

## 🎯 Choose Your Path

### I want to deploy quickly
→ Start with [QUICKSTART.md](QUICKSTART.md)

### I need detailed information
→ Read [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

### I'm configuring networks
→ See [NETWORK_CONFIG.md](NETWORK_CONFIG.md)

### I need to understand parameters
→ Check [CONTRACT_PARAMS.md](CONTRACT_PARAMS.md)

## 📋 Quick Reference

### Essential Commands

```bash
# Setup
just setup                    # Initialize submodules
just check-setup             # Validate environment

# Build
just build                   # Compile contracts
just clean                   # Clean artifacts

# Deploy
just deploy-network <name>   # Deploy to one network
just deploy-multi <names>    # Deploy to multiple networks

# View
just show-deployments        # Show all deployments
just get-deployment <name>   # Get specific network

# Verify
just verify-all <network>    # Verify all contracts
```

### Configuration Files

| File | Purpose | Gitignored |
|------|---------|------------|
| `.env` | Private keys and API keys | ✅ Yes |
| `networks.toml` | Network configurations | ✅ Yes |
| `deployments.json` | Deployment addresses | ✅ Yes |
| `.env.example` | Environment template | ❌ No |
| `networks.toml.example` | Network config template | ❌ No |

## 🏗️ Contracts Overview

### ComposeL2OutputOracle
- **Type:** ERC1967 Upgradeable Proxy
- **Purpose:** Manages L2 output proposals with SP1 proof verification
- **Components:** Implementation + Proxy

### ComposeDisputeGame
- **Type:** Implementation Contract
- **Purpose:** Handles dispute resolution for L2 outputs
- **Dependencies:** Requires ComposeL2OutputOracle address

### DisputeGameFactory
- **Type:** Bedrock Proxy (from Optimism)
- **Purpose:** Factory for creating dispute game instances
- **Components:** ProxyAdmin + Implementation + Proxy

## 🔄 Deployment Flow

```
1. ComposeL2OutputOracle
   ├── Deploy Implementation
   ├── Deploy ERC1967Proxy
   └── Initialize with parameters
   
2. ComposeDisputeGame
   ├── Deploy Implementation
   └── Link to Oracle Proxy
   
3. DisputeGameFactory
   ├── Deploy ProxyAdmin
   ├── Deploy Implementation
   ├── Deploy Bedrock Proxy
   └── Initialize with admin
   
4. Save Addresses
   └── Auto-save to deployments.json
```

## 🔐 Security Best Practices

### Configuration Security
- ✅ Never commit `.env` or `networks.toml`
- ✅ Use hardware wallets for mainnet
- ✅ Use multisigs for owner/admin addresses
- ✅ Keep proposer keys in secure key management (HSM/KMS)
- ✅ Test on testnets before mainnet

### Deployment Security
- ✅ Verify all contracts on block explorer
- ✅ Test contract interactions after deployment
- ✅ Backup deployment artifacts
- ✅ Document all deployment parameters
- ✅ Use dedicated deployer wallet

### Operational Security
- ✅ Monitor proposer activity
- ✅ Set up alerts for unusual activity
- ✅ Have incident response plan
- ✅ Regular security audits
- ✅ Keep dependencies updated

## 🐛 Common Issues

### Setup Issues
- **Submodules not initialized** → Run `just setup`
- **Build fails** → Run `just clean && just build`
- **Wrong Optimism tag** → Verify `op-deployer/v0.3.3` in `lib/optimism`

### Configuration Issues
- **Network not found** → Check `networks.toml` syntax
- **Invalid parameters** → Validate with `just check-setup`
- **Missing API key** → Set `ETHERSCAN_API_KEY` in `.env`

### Deployment Issues
- **Insufficient funds** → Ensure deployer wallet has ~0.5 ETH
- **RPC connection failed** → Test with `just test-network <name>`
- **Verification failed** → Wait 2 minutes and retry with `just verify-all`

### See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed troubleshooting.

## 📊 Network Examples

### Ethereum Sepolia (Testnet)
- Chain ID: 11155111
- RPC: Alchemy, Infura
- Faucet: https://sepoliafaucet.com/
- Good for: Initial testing

### Ethereum Holesky (Testnet)
- Chain ID: 17000
- RPC: Public nodes available
- Good for: Alternative testnet

### Ethereum Mainnet (Production)
- Chain ID: 1
- RPC: Alchemy, Infura, QuickNode
- Requirements: Full security setup

### Hoodi (Custom L1)
- Chain ID: Custom
- RPC: Provided by network operators
- Requirements: Network-specific configuration

## 🔗 External Resources

### Tools & Dependencies
- [Foundry](https://book.getfoundry.sh/) - Ethereum development toolkit
- [just](https://github.com/casey/just) - Command runner
- [jq](https://stedolan.github.io/jq/) - JSON processor

### Related Documentation
- [Optimism Bedrock](https://docs.optimism.io/builders/chain-operators/tutorials/create-l2-rollup)
- [SP1 Documentation](https://docs.succinct.xyz/)
- [ERC-1967 Proxy Standard](https://eips.ethereum.org/EIPS/eip-1967)

### Security Tools
- [Gnosis Safe](https://safe.global/) - Multisig wallet
- [Slither](https://github.com/crytic/slither) - Static analyzer
- [Mythril](https://github.com/ConsenSys/mythril) - Security analysis

## 📝 Document Conventions

### Code Blocks
```bash
# Shell commands
just deploy-network sepolia
```

```toml
# Configuration files
[networks.example]
name = "Example Network"
```

```solidity
// Solidity code
function example() external { }
```

### Callouts
- ✅ Recommended action
- ❌ Action to avoid
- ⚠️ Warning / Important note
- 💡 Tip / Best practice

## 🤝 Contributing to Documentation

Found an error or want to improve the docs?

1. Fork the repository
2. Make your changes
3. Test the documentation
4. Submit a pull request

### Documentation Standards
- Clear, concise language
- Code examples that work
- Up-to-date with latest changes
- Tested procedures

## 📞 Support

- **Documentation Issues:** Open a GitHub issue
- **Deployment Help:** See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Configuration Help:** See [NETWORK_CONFIG.md](NETWORK_CONFIG.md)
- **Parameter Help:** See [CONTRACT_PARAMS.md](CONTRACT_PARAMS.md)

## 📄 License

Documentation is provided under the same license as the code (MIT).

---

**Last Updated:** 2025-10-17

**Version:** 1.0.0

**Maintained By:** Compose Network Team
