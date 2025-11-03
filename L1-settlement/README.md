# Compose L1 Settlement

L1 smart contracts for Compose's aggregated settlement infrastructure. Enables multiple OP Stack rollups (v3.x.x) to share settlement infrastructure with validity proofs and pooled liquidity.

## What is Compose?

Compose provides **shared L1 settlement infrastructure** for multiple OP Stack rollups:

- **Shared Infrastructure**: Deploy once, use for all rollups
- **Validity Proofs**: SP1-powered aggregated proofs for superblocks  
- **Pooled Liquidity**: Shared ETH lockbox for efficient capital usage
- **Lower Costs**: Amortize L1 settlement costs across multiple rollups

## Architecture

### Phase 1: Shared Infrastructure (Compose Network)
Deploy cluster-wide components:
- `SuperchainConfig` - Cluster governance and pause controls
- `DisputeGameFactory` - Creates dispute games for superblocks
- `ComposeDisputeGame` - Validity game that verifies SP1 proofs
- `AnchorStateRegistry` - Tracks finalized superblock anchor states
- `ETHLockbox` - Shared liquidity pool for withdrawals
- `ProxyAdmin` - Proxy administration

### Phase 2: Rollup Migration (Per Rollup)
Migrate existing OP Stack rollups to use shared infrastructure:
- Upgrade `SystemConfig`, `OptimismPortal`, `L1CrossDomainMessenger`, `L1StandardBridge`, `L1ERC721Bridge`
- Point to shared `AnchorStateRegistry` and `ETHLockbox`
- Enable super root withdrawal proving

## 🚀 Quick Start

See [QUICKSTART.md](./QUICKSTART.md) for detailed setup.

```bash
# 1. Setup
just setup && just build

# 2. Configure
cp .env.example .env
cp networks.toml.example networks.toml
# Edit both files

# 3. Deploy shared infrastructure (Phase 1)
just deploy-network hoodi-stage

# 4. Migrate a rollup (Phase 2)
just migrate-rollup rollup-a-stage hoodi-stage
```

## 📋 Prerequisites

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

## ⚙️ Configuration

Two files control deployment:

**`.env`** (private keys, never commit):
```bash
PRIVATE_KEY=0x...
ETHERSCAN_API_KEY=...
```

**`networks.toml`** (network parameters):
```toml
[networks.hoodi-stage]
rpc_url = "https://..."
chain_id = 560048
guardian = "0x..."
sp1_verifier = "0x..."
# ... more parameters
```

See [docs/NETWORK_CONFIG.md](./docs/NETWORK_CONFIG.md) for complete configuration guide.

## 📝 Common Commands

```bash
# Setup
just setup                          # Initialize project
just build                          # Build contracts

# Phase 1: Shared Infrastructure
just deploy-network hoodi-stage     # Deploy shared infra
just show-deployments               # View deployed contracts

# Phase 2: Rollup Migration  
just migrate-rollup rollup-a hoodi  # Migrate a rollup
just migrate-fork rollup-a hoodi 123 # Test on fork
just show-migrations                # View migrations
```

Run `just` to see all available commands.

## 📁 Repository Structure

```
L1-settlement/
├── src/                    # Compose contracts
│   ├── ComposeDisputeGame.sol
│   ├── ComposeAnchorStateRegistry.sol
│   └── ComposeETHLockbox.sol
├── script/
│   ├── config/           # Network & rollup configs
│   ├── deploy/           # Phase 1 deployment
│   └── migrate/          # Phase 2 migration
├── scripts/              # Bash automation
├── deployments/          # Deployment outputs
│   ├── compose/          # Shared infra
│   └── rollups/          # Rollup migrations
├── docs/                 # Documentation
├── networks.toml         # Network configs (gitignored)
└── .env                  # Private keys (gitignored)
```

## 📚 Documentation

- **[QUICKSTART.md](./QUICKSTART.md)** - 5-minute getting started guide
- **[docs/NETWORK_CONFIG.md](./docs/NETWORK_CONFIG.md)** - Network configuration guide
- **[docs/SHARED_INFRA.md](./docs/SHARED_INFRA.md)** - Shared infrastructure deployment
- **[docs/ROLLUP_MIGRATION.md](./docs/ROLLUP_MIGRATION.md)** - Rollup migration guide

## 🔐 Security Notes

- **Never commit `.env`** - Contains private keys
- **Never commit `networks.toml`** - May contain sensitive data
- **Never commit `deployments.json`** - May contain sensitive addresses
- Use a dedicated deployer wallet, not your main wallet
- Test on testnets before mainnet deployment
- Always verify contract source code after deployment

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Submodule not initialized | `just setup` |
| Build failed | `just clean && just build` |
| Network connection failed | Check RPC URL in `networks.toml` |
| Verification failed | Check `ETHERSCAN_API_KEY` in `.env` |

See documentation for detailed troubleshooting.

## 🔗 References

- [OP Stack](https://github.com/ethereum-optimism/optimism) - Base rollup infrastructure
- [SP1](https://docs.succinct.xyz/) - Zero-knowledge proof system
- [Foundry](https://book.getfoundry.sh/) - Ethereum development toolkit

---

**License:** MIT | **Contributing:** PRs welcome | **Support:** Open an issue
