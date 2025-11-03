# Compose L1 - Quick Start

Get Compose deployed in 5 minutes.

## Prerequisites

Install required tools:
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Install just (macOS)
brew install just
# OR (Linux)
cargo install just

# Install jq
brew install jq  # macOS
sudo apt install jq  # Linux
```

## 5-Minute Setup

### 1. Clone and Setup
```bash
git clone <repo>
cd compose-contracts/L1-settlement
just setup
just build
```

### 2. Configure

**Create `.env`:**
```bash
cp .env.example .env
# Edit .env:
PRIVATE_KEY=0xYourPrivateKey
ETHERSCAN_API_KEY=YourAPIKey
```

**Create `networks.toml`:**
```bash
cp networks.toml.example networks.toml
# Edit networks.toml - see example below
```

**Minimal Example (testnet):**
```toml
[networks.sepolia]
name = "Sepolia"
rpc_url = "https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY"
chain_id = 11155111
explorer_url = "https://sepolia.etherscan.io"
explorer_api_url = "https://api-sepolia.etherscan.io/api"

guardian = "0xYourAddress"
proxy_admin_owner = "0xYourAddress"  
authorized_proposer = "0xYourAddress"
sp1_verifier = "0xSP1VerifierAddress"
aggregation_vkey = "0xYourAggregationVkey"
```

### 3. Deploy Phase 1 (Shared Infrastructure)
```bash
just deploy-network sepolia
```

This deploys:
- SuperchainConfig
- DisputeGameFactory  
- ComposeDisputeGame
- AnchorStateRegistry
- ETHLockbox
- ProxyAdmin

### 4. Migrate a Rollup (Phase 2)

Create rollup config at `script/config/rollups/your-rollup.json`:
```json
{
  "l2ChainId": 12345,
  "l1SystemConfigAddress": "0x...",
  "optimismPortal": {"proxy": "0x...", "impl": "0x..."},
  "l1CrossDomainMessenger": "0x...",
  "l1StandardBridge": "0x...",
  "l1ERC721Bridge": "0x...",
  "proxyAdmin": {"impl": "0x...", "owner": "0x..."}
}
```

Migrate:
```bash
just migrate-rollup your-rollup sepolia
```

## Common Commands

```bash
# Validate setup
just check-setup

# List networks
just list-networks

# Test network connection
just test-network sepolia

# View deployments
just show-deployments
just get-deployment sepolia

# View migrations
just show-migrations
just get-migration your-rollup

# Fork testing (before real migration)
just migrate-fork your-rollup sepolia 1234567
```

## Verification

Contracts are auto-verified if `ETHERSCAN_API_KEY` is set.

Manual verification:
```bash
just verify-network sepolia
```

## Testing

```bash
# Run all tests
forge test

# With verbose output
forge test -vvv

# Gas report
forge test --gas-report
```

##  Troubleshooting

| Issue | Solution |
|-------|----------|
| "Guardian not set" | Set `guardian` in `networks.toml` |
| "Submodule not found" | Run `just setup` |
| "RPC connection failed" | Check `rpc_url` in `networks.toml` |
| "Insufficient funds" | Ensure deployer has ~0.5 ETH |

## Next Steps

1. ✅ **Deployed Phase 1** - Shared infrastructure ready
2. 📖 **Read docs** - Understand architecture
   - [docs/SHARED_INFRA.md](./docs/SHARED_INFRA.md) - Component details
   - [docs/ROLLUP_MIGRATION.md](./docs/ROLLUP_MIGRATION.md) - Migration process
3. 🔄 **Migrate Rollups** - Start with fork test
4. 🚀 **Publish Superblocks** - Aggregate settlement

## Inspecting Deployed Contracts

```bash
# Get deployment addresses
SUPERCHAIN_CONFIG=$(just get-deployment sepolia | jq -r '.["sepolia"].governance.SuperchainConfig.proxy')
LOCKBOX=$(just get-deployment sepolia | jq -r '.["sepolia"].core.ETHLockbox.proxy')

# Check guardian
cast call $SUPERCHAIN_CONFIG "guardian()" --rpc-url $RPC_URL

# Check if paused
cast call $LOCKBOX "paused()" --rpc-url $RPC_URL
```

## Further Reading

- **[docs/NETWORK_CONFIG.md](./docs/NETWORK_CONFIG.md)** - Complete configuration reference
- **[docs/SHARED_INFRA.md](./docs/SHARED_INFRA.md)** - Understand deployed components
- **[docs/ROLLUP_MIGRATION.md](./docs/ROLLUP_MIGRATION.md)** - Migrate OP Stack rollups

---

**That's it!** You've deployed Compose shared infrastructure. Next: migrate your rollups to start using aggregated settlement.
