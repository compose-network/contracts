# Compose Network Contracts

This repository contains the smart contracts for the Compose Network, organized into two main components:

## 📁 Repository Structure

```
compose-contracts/
├── L1-settlement/          # L1 settlement layer contracts
│   ├── src/               # ComposeL2OutputOracle, ComposeDisputeGame
│   ├── script/            # Deployment scripts
│   ├── test/              # Contract tests
│   ├── justfile           # Deployment commands
│   └── README.md          # L1 documentation
│
└── L2/                    # L2 execution layer contracts
    └── (to be added)
```

## 🏗️ Components

### L1-settlement

The L1 settlement layer contracts handle:
- **ComposeL2OutputOracle** - Manages L2 output proposals with SP1 proof verification
- **ComposeDisputeGame** - Handles dispute resolution for L2 outputs  
- **DisputeGameFactory** - Factory for creating dispute game instances

**📚 Full documentation:** [L1-settlement/README.md](L1-settlement/README.md)

**Quick start:**
```bash
cd L1-settlement
just setup
just build
just deploy-network sepolia
```

### L2

L2 execution layer contracts (to be added).

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [just](https://github.com/casey/just#installation)
- [jq](https://stedolan.github.io/jq/)

### Installation

```bash
# Clone repository
git clone https://github.com/compose-network/compose-contracts.git
cd compose-contracts

# Initialize submodules
git submodule update --init --recursive

# For L1 deployment
cd L1-settlement
just setup
just build

# For L2 (when available)
cd ../L2
# (instructions to be added)
```

## 📖 Documentation

### Repository Structure & Setup
- **[Quick Reference](QUICK_REFERENCE.md)** - Essential commands
- **[Restructuring Summary](RESTRUCTURING_SUMMARY.md)** - Migration guide
- **[Submodule Fix Notes](SUBMODULE_FIX_NOTES.md)** - Git submodule troubleshooting

### L1 Settlement Layer
- **[L1 README](L1-settlement/README.md)** - Main L1 documentation
- **[Quick Start](L1-settlement/GETTING_STARTED.md)** - Get started guide
- **[Deployment Guide](L1-settlement/docs/DEPLOYMENT_GUIDE.md)** - Deploy contracts
- **[Network Configuration](L1-settlement/docs/NETWORK_CONFIG.md)** - Configure networks
- **[Contract Parameters](L1-settlement/docs/CONTRACT_PARAMS.md)** - Parameter reference

### L2 Execution Layer
- **L2 Documentation:** (to be added)

## 🏛️ Architecture

```
┌─────────────────────────────────────────┐
│          L1 Networks                     │
│  (Ethereum, Hoodi, etc.)                │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  ComposeL2OutputOracle (Proxy)    │ │
│  │  - Verifies L2 state roots        │ │
│  │  - Uses SP1 proofs                │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  ComposeDisputeGame               │ │
│  │  - Dispute resolution             │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  DisputeGameFactory               │ │
│  │  - Creates dispute games          │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│          L2 Network                      │
│  (Compose Execution Layer)              │
│                                          │
│  (Contracts to be added)                │
└─────────────────────────────────────────┘
```

## 🔗 Links

- [Compose Network Documentation](https://docs.compose.network) (if available)
- [Optimism Bedrock](https://github.com/ethereum-optimism/optimism)
- [SP1 Documentation](https://docs.succinct.xyz/)

## 📄 License

MIT License - see individual project LICENSE files for details.

## 🤝 Contributing

Contributions welcome! Please see individual project READMEs for specific contribution guidelines.

## 📞 Support

- L1 Settlement Issues: See [L1-settlement/README.md](L1-settlement/README.md)
- L2 Execution Issues: (to be added)
- General Issues: [GitHub Issues](https://github.com/compose-network/compose-contracts/issues)
