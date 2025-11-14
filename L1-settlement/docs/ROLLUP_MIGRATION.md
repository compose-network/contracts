# Rollup Migration Guide (Phase 2)

Complete guide for migrating OP Stack v3.x.x rollups to Compose shared settlement.

## Overview

**Phase 2** migrates existing OP Stack rollups to use Compose shared infrastructure:

- Upgrades 5 L1 contracts to Compose-compatible versions
- Points to shared AnchorStateRegistry and ETHLockbox
- Enables super root withdrawal proving
- **L2 operations continue uninterrupted** - only L1 withdrawal proving changes

### Prerequisites

- ✅ Phase 1 shared infrastructure deployed (see [SHARED_INFRA.md](./SHARED_INFRA.md))
- ✅ Rollup must be OP Stack v3.x.x compatible
- ✅ ProxyAdmin owner access to authorize migration
- ✅ Rollup configuration file created

---

## What Gets Upgraded

### Contracts Upgraded

| Contract | Changes | Why |
|----------|---------|-----|
| **SystemConfig** | Points to shared AnchorStateRegistry | Withdrawals query shared anchor states |
| **OptimismPortal** | Uses shared ETHLockbox + ASR | Withdrawals from shared liquidity pool |
| **L1CrossDomainMessenger** | Updated for SystemConfig changes | Message passing compatibility |
| **L1StandardBridge** | Updated for SystemConfig changes | Bridge compatibility |
| **L1ERC721Bridge** | Updated for SystemConfig changes | NFT bridge compatibility |

### What Doesn't Change

- ✅ L2 chain continues producing blocks normally
- ✅ L2 data availability (blobs) unchanged
- ✅ L2 contract state unchanged
- ✅ Existing deposits/withdrawals in flight complete normally
- ✅ Proxy addresses stay the same

---

## Step-by-Step Migration

### Step 1: Create Rollup Configuration

Create `script/config/rollups/<your-rollup>.json`:

```json
{
  "l2ChainId": 77777,
  "l1SystemConfigAddress": "0xdb356c4ed9a9ef4833eea2a8052668b05eafc7d7",
  "optimismPortal": {
    "proxy": "0xB8b340D118A807BA7E6abce111eb3816152072d1",
    "impl": "0xB443Da3e07052204A02d630a8933dAc05a0d6fB4"
  },
  "l1CrossDomainMessenger": "0xf705129966C71b94534a7E84bCc52edefe1e6706",
  "l1StandardBridge": "0xE6456C49bAe7FF20Bee0D01948d6d0F82dD821E9",
  "l1ERC721Bridge": "0xfc67ad4195E5c86A89676d8b0f3BfEe5150e5D6C",
  "proxyAdmin": {
    "impl": "0x3b0e5218B083d9e0e3fB1094b47ca7ec0515c313",
    "owner": "0xA139A1776E60F9645533a9AD419461818D6839a1"
  }
}
```

See [NETWORK_CONFIG.md Part 2](./NETWORK_CONFIG.md#part-2-rollup-configuration) for finding these addresses.

### Step 2: Test on Fork (Recommended)

**Always test first!**

```bash
# Get recent block number
BLOCK=$(cast block-number --rpc-url $L1_RPC)

# Test migration on fork
just migrate-fork your-rollup hoodi-stage $BLOCK
```

This:
- Forks L1 at specified block
- Simulates migration transactions
- Saves output to `deployments/rollups/fork/<rollup>.json`
- No real transactions broadcast

### Step 3: Review Fork Output

```bash
# View migration details
just get-migration your-rollup fork

# Validate structure
just validate-migration your-rollup fork
```

Check:
- [ ] All 5 contracts show new implementations
- [ ] Constructor args look correct
- [ ] Upgrade data present where expected
- [ ] No errors in migration script

### Step 4: Execute Real Migration

**⚠️ This broadcasts real transactions!**

```bash
# Ensure ProxyAdmin owner key in .env
PRIVATE_KEY=0x... # ProxyAdmin owner

# Execute migration
just migrate-rollup your-rollup hoodi-stage
```

This:
1. Deploys 5 new implementations
2. Upgrades 5 proxies via ProxyAdmin
3. Initializes contracts with new parameters
4. Authorizes OptimismPortal in ETHLockbox
5. Migrates liquidity to shared pool
6. Verifies contracts on explorer
7. Saves output to `deployments/rollups/<rollup>.json`

### Step 5: Verify Migration

```bash
# Check migration output
just show-migrations
just get-migration your-rollup

# Verify on-chain
PORTAL=$(jq -r '.\"your-rollup\".contracts.OptimismPortal.proxyAddress' deployments/rollups/your-rollup.json)

# Check new implementation
cast implementation $PORTAL --rpc-url $L1_RPC

# Check lockbox authorization
LOCKBOX=$(just get-deployment hoodi-stage | jq -r '.\"hoodi-stage\".core.ETHLockbox.proxy')
cast call $LOCKBOX "authorizedPortals(address)(bool)" $PORTAL --rpc-url $L1_RPC
# Should return: true
```

---

## Migration Transactions

The migration executes these transactions (in order):

1. **Deploy SystemConfig impl** - New implementation with ASR reference
2. **Deploy OptimismPortal impl** - New implementation with ETHLockbox
3. **Deploy L1CrossDomainMessenger impl** - Compatible with new SystemConfig
4. **Deploy L1StandardBridge impl** - Compatible with new SystemConfig
5. **Deploy L1ERC721Bridge impl** - Compatible with new SystemConfig
6. **Upgrade SystemConfig** - ProxyAdmin.upgradeAndCall()
7. **Enable ETH_LOCKBOX feature** - SystemConfig.setFeature()
8. **Upgrade OptimismPortal** - ProxyAdmin.upgrade()
9. **Authorize Portal in ASR** - AnchorStateRegistry.authorizePortal()
10. **Upgrade L1CrossDomainMessenger** - ProxyAdmin.upgradeAndCall()
11. **Upgrade L1StandardBridge** - ProxyAdmin.upgradeAndCall()
12. **Upgrade L1ERC721Bridge** - ProxyAdmin.upgradeAndCall()
13. **Migrate to Super Roots** - OptimismPortal.migrateToSuperRoots()
14. **Migrate Liquidity** - OptimismPortal.migrateLiquidity()

### Gas Costs

Approximate gas costs (testnet):
- Total: ~15-20M gas
- Cost at 20 gwei: ~0.3-0.4 ETH
- Cost at 50 gwei: ~0.75-1 ETH

Mainnet costs vary by congestion.

---

## Post-Migration

### 1. Test Withdrawals

```bash
# Initiate withdrawal on L2
# ... (L2 transaction)

# After finalization period, prove withdrawal
cast send $PORTAL "proveWithdrawalTransaction(...)" \
  --private-key $USER_KEY \
  --rpc-url $L1_RPC

# After maturity delay, finalize withdrawal
cast send $PORTAL "finalizeWithdrawalTransaction(...)" \
  --private-key $USER_KEY \
  --rpc-url $L1_RPC
```

### 2. Monitor Operations

**Key Metrics:**
- Withdrawal success rate
- Time to finalization
- ETHLockbox balance
- Failed transactions

**Events to Watch:**
```solidity
// OptimismPortal
event WithdrawalProven(bytes32 indexed withdrawalHash, address indexed from, address indexed to);
event WithdrawalFinalized(bytes32 indexed withdrawalHash, bool success);

// ETHLockbox
event Unlocked(address indexed recipient, uint256 amount);
```

### 3. Communication

Inform users:
- ✅ Migration complete
- ✅ L2 operations unchanged
- ✅ Withdrawals use new proving method
- ✅ Existing in-flight withdrawals complete normally

---

## Troubleshooting

### "ProxyAdmin owner mismatch"

Ensure `.env` has correct ProxyAdmin owner key:
```bash
PRIVATE_KEY=0x... # Must be proxyAdmin.owner from config
```

### "Contract already initialized"

Some contracts may already be initialized. This is OK if re-running migration. Check error details.

### "Insufficient lockbox balance"

ETHLockbox needs initial funds. Owner should:
```bash
cast send $LOCKBOX --value 10ether --rpc-url $L1_RPC
```

### "ASR anchor state not set"

Wait for first superblock publication after migration.

### "Fork migration failed"

Check:
- Block number is recent
- RPC endpoint supports forking
- All addresses in config are correct

---

## Deployment Output

After migrating a rollup, detailed migration data is automatically saved to structured JSON files under `deployments/rollups/`.

### Directory Structure

```
deployments/
├── compose/           # Compose shared infrastructure deployments
│   └── hoodi-stage.json
└── rollups/           # Rollup migration outputs
    ├── rollup-a-stage.json       # Regular migrations
    ├── rollup-b-prod.json
    └── fork/                      # Fork migrations (testing)
        ├── rollup-a-stage.json
        └── rollup-b-stage.json
```

### Migration Output Format

Each migration file follows this structure:

```json
{
  "rollup-a-stage": {
    "l2ChainId": 77777,
    "composeNetwork": "hoodi-stage",
    "migration_block": 1525977,
    "timestamp": "2025-11-02T01:42:00Z",
    "migrator": "0x64f38fe8ec155134df973012ed8bb40f10d31f77",
    "contracts": {
      "SystemConfig": {
        "proxyAddress": "0xdb356c4ed9a9ef4833eea2a8052668b05eafc7d7",
        "oldImplAddress": "",
        "newImplAddress": "0x...",
        "constructorArgs": [],
        "upgradeData": "0x...",
        "txHash": "0x...",
        "migrationBlock": 1525977
      },
      "OptimismPortal": {
        "proxyAddress": "0xB8b340D118A807BA7E6abce111eb3816152072d1",
        "oldImplAddress": "0xB443Da3e07052204A02d630a8933dAc05a0d6fB4",
        "newImplAddress": "0x...",
        "constructorArgs": ["604800"],
        "upgradeData": "",
        "txHash": "0x...",
        "migrationBlock": 1525978
      },
      "L1CrossDomainMessenger": {
        "proxyAddress": "0xf705129966C71b94534a7E84bCc52edefe1e6706",
        "oldImplAddress": "",
        "newImplAddress": "0x...",
        "constructorArgs": [],
        "upgradeData": "0x...",
        "txHash": "0x...",
        "migrationBlock": 1525979
      },
      "L1StandardBridge": {
        "proxyAddress": "0xE6456C49bAe7FF20Bee0D01948d6d0F82dD821E9",
        "oldImplAddress": "",
        "newImplAddress": "0x...",
        "constructorArgs": [],
        "upgradeData": "0x...",
        "txHash": "0x...",
        "migrationBlock": 1525980
      },
      "L1ERC721Bridge": {
        "proxyAddress": "0xfc67ad4195E5c86A89676d8b0f3BfEe5150e5D6C",
        "oldImplAddress": "",
        "newImplAddress": "0x...",
        "constructorArgs": [],
        "upgradeData": "0x...",
        "txHash": "0x...",
        "migrationBlock": 1525981
      }
    }
  }
}
```

### Key Fields

**Top Level:**
- `l2ChainId`: The L2 chain ID of the rollup
- `composeNetwork`: The Compose network this rollup migrated to (e.g., `hoodi-stage`)
- `migration_block`: Block number when first migration transaction was executed
- `timestamp`: UTC timestamp of migration
- `migrator`: Address that executed the migration (rollup ProxyAdmin owner)

**Per Contract:**
- `proxyAddress`: The proxy address (unchanged during migration)
- `oldImplAddress`: Previous implementation address (from rollup config)
- `newImplAddress`: New implementation address (deployed during migration)
- `constructorArgs`: Constructor arguments for the new implementation
- `upgradeData`: Encoded calldata for `upgradeAndCall` (if upgrade function was called)
- `txHash`: Transaction hash for implementation deployment
- `migrationBlock`: Block number when this specific contract was upgraded

### Management Commands

```bash
# View all migrations
just show-migrations

# View specific migration
just get-migration rollup-a-stage          # Regular
just get-migration rollup-a-stage fork     # Fork

# List migration files
just list-migrations

# Validate migration
just validate-migration rollup-a-stage
just validate-migration rollup-a-stage fork
```

### Use Cases

**1. Audit Trail**
Complete record of what was upgraded, when, and by whom.

**2. Rollback Reference**
If needed, old implementation addresses are recorded.

**3. Cross-Network Comparison**
Compare migrations across different environments.

**4. Verification**
Verify that contracts were upgraded correctly:

```bash
# Get new implementation address
NEW_IMPL=$(just get-migration rollup-a | jq -r '.["rollup-a"].contracts.OptimismPortal.newImplAddress')

# Verify on-chain
cast implementation $PROXY_ADDRESS --rpc-url $RPC_URL
```

---

## Security Checklist

Before migration:

- [ ] Tested on fork successfully
- [ ] ProxyAdmin owner key secured
- [ ] Rollup config addresses verified
- [ ] Shared infrastructure deployed and verified
- [ ] Communication plan for users ready
- [ ] Monitoring infrastructure set up
- [ ] Rollback plan documented

During migration:

- [ ] Migration transactions executing successfully
- [ ] No reverts or unexpected errors
- [ ] Gas costs within expected range
- [ ] Contracts verified on explorer

After migration:

- [ ] All contracts upgraded successfully
- [ ] Lockbox authorization confirmed
- [ ] Test withdrawal completed
- [ ] Users notified
- [ ] Migration output backed up

---

## Reference

- **Migration Script:** `script/migrate/MigrateRollup.s.sol`
- **Rollup Configs:** `script/config/rollups/`
- **Network Config:** [NETWORK_CONFIG.md](./NETWORK_CONFIG.md)
- **Shared Infrastructure:** [SHARED_INFRA.md](./SHARED_INFRA.md)
- **Commands:** Run `just` for full list
