# Shared Infrastructure Deployment (Phase 1)

Guide to deploying Compose's shared L1 settlement infrastructure.

## Overview

**Phase 1** deploys cluster-wide components shared across all rollups:

- **SuperchainConfig** - Cluster governance and pause controls
- **DisputeGameFactory** - Creates dispute games for superblocks
- **ComposeDisputeGame** - Validity game that verifies SP1 proofs
- **AnchorStateRegistry** - Tracks finalized superblock anchor states
- **ETHLockbox** - Shared liquidity pool for withdrawals
- **ProxyAdmin** - Proxy administration

These contracts are deployed **once per L1 network** and used by **all rollups** migrating to Compose.

---

## Architecture

### Components

```
┌──────────────────────────────────────────────────────────┐
│                  Compose Shared Infrastructure           │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────┐      ┌───────────────────────┐     │
│  │ SuperchainConfig │◄─────│ Guardian (multisig)   │     │
│  │ (Governance)     │      └───────────────────────┘     │
│  └────────┬─────────┘                                    │
│           │ paused()                                     │
│           ├────────────────────────┬─────────────────┐   │
│           ▼                        ▼                 ▼   │
│  ┌─────────────────┐   ┌──────────────────┐  ┌──────────┐│
│  │ ETHLockbox      │   │ AnchorStateReg   │  │ DGFactory││
│  │ (Liquidity)     │   │ (Anchor States)  │  │ (Games)  ││
│  └─────────────────┘   └──────────────────┘  └──────────┘│
│           │                       │                 │    │
│           │                       │                 │    │
│  Authorized Portals         Respected Game    Game Impls │
│           │                       │                 │    │
│           ▼                       ▼                 ▼    │
│    ┌──────────────┐      ┌──────────────────────────┐    │
│    │ Portal A, B  │      │ ComposeDisputeGame       │    │
│    │ (rollups)    │      │ (SP1 validity proofs)    │    │
│    └──────────────┘      └──────────────────────────┘    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Contract Details

#### 1. SuperchainConfig

**Purpose:** Cluster-wide governance and emergency pause

**Key Functions:**
- `pause(identifier)` - Guardian can pause specific or all contracts
- `unpause()` - Guardian resumes operations
- `guardian()` - Returns guardian address

**Used By:**
- ETHLockbox - checks `paused()` before withdrawals
- AnchorStateRegistry - checks `paused()` before state updates

**Deployment:**
- Proxy + Implementation pattern
- Initialized with guardian address
- Guardian should be multisig for mainnet

#### 2. DisputeGameFactory

**Purpose:** Creates and tracks dispute games

**Key Functions:**
- `create(gameType, rootClaim, extraData)` - Create new game
- `gameImpls(gameType)` - Get implementation for game type
- `setImplementation(gameType, impl)` - Set game implementation

**Game Type:**
- Compose uses `GameType.wrap(5555)` for superblock validity games

**Deployment:**
- Proxy + Implementation + ProxyAdmin pattern
- Initialized with owner
- Owner sets game implementations

#### 3. ComposeDisputeGame

**Purpose:** Validity game that verifies SP1 proofs of superblocks

**Key Functions:**
- `resolve()` - Verifies SP1 proof and resolves game
- `rootClaim()` - Returns superblock root hash
- `status()` - Returns game status (In Progress, Defender Wins, Challenger Wins)

**SP1 Integration:**
- Takes SP1 proof as input
- Calls SP1Verifier to verify proof
- Proof verifies aggregated rollup outputs

**Deployment:**
- Implementation only (created by factory)
- Registered with DisputeGameFactory at type 5555

#### 4. AnchorStateRegistry

**Purpose:** Tracks finalized anchor states for superblocks

**Key Functions:**
- `anchors(gameType)` - Get anchor state for game type
- `setAnchorState(game)` - Update anchor after game finalization
- `respectedGameType()` - Returns game type used for anchoring

**Finalization Flow:**
1. Game created with superblock root
2. Game resolves (Defender Wins after SP1 proof verification)
3. After `DISPUTE_GAME_FINALITY_DELAY`, game becomes finalized
4. Anchor state updated with new superblock root

**Deployment:**
- Proxy + Implementation pattern
- Initialized with placeholder anchor
- Points to DisputeGameFactory and SuperchainConfig

#### 5. ETHLockbox

**Purpose:** Shared liquidity pool for rollup withdrawals

**Key Functions:**
- `authorizePortal(portal)` - Owner adds authorized portal
- `donate()` - Anyone can deposit ETH
- `unlock(recipient, amount)` - Authorized portals withdraw

**Security:**
- Only authorized OptimismPortals can withdraw
- Checks SuperchainConfig for pause state
- ProxyAdmin owner manages authorizations

**Deployment:**
- Proxy + Implementation pattern
- Initialized with SuperchainConfig reference
- Empty authorized portals list (added during rollup migration)

#### 6. ProxyAdmin

**Purpose:** Manages proxy upgrades

**Key Functions:**
- `upgrade(proxy, implementation)` - Upgrade proxy
- `upgradeAndCall(proxy, implementation, data)` - Upgrade with initialization
- `owner()` - Returns owner address

**Controls:**
- SuperchainConfig proxy
- DisputeGameFactory proxy
- AnchorStateRegistry proxy
- ETHLockbox proxy

**Deployment:**
- Standalone contract
- Owner set during deployment
- Owner should be multisig for mainnet

---

## Deployment Process

### Prerequisites

1. **Configure network** in `networks.toml`:
   ```toml
   [networks.hoodi-stage]
   guardian = "0x..."
   proxy_admin_owner = "0x..."
   authorized_proposer = "0x..."
   sp1_verifier = "0x..."
   aggregation_vkey = "0x..."
   ```

2. **Set private key** in `.env`:
   ```bash
   PRIVATE_KEY=0x...
   ETHERSCAN_API_KEY=...
   ```

3. **Ensure sufficient funds** (~0.5 ETH for gas)

### Deployment Command

```bash
just deploy-network hoodi-stage
```

This runs `script/deploy/DeploySharedInfra.s.sol` which:

1. Deploys ProxyAdmin
2. Deploys SuperchainConfig (impl + proxy)
3. Deploys DisputeGameFactory (impl + proxy)
4. Deploys ComposeDisputeGame (impl)
5. Deploys AnchorStateRegistry (impl + proxy)
6. Deploys ETHLockbox (impl + proxy)
7. Registers ComposeDisputeGame with factory
8. Verifies all contracts on block explorer

### Deployment Output

Addresses saved to `deployments/compose/<network>.json`:

```json
{
  "hoodi-stage": {
    "chainId": 560048,
    "deployment_block": 1525000,
    "timestamp": "2025-11-01T12:00:00Z",
    "deployer": "0x...",
    "governance": {
      "ProxyAdmin": {
        "address": "0x...",
        "owner": "0x..."
      },
      "SuperchainConfig": {
        "proxy": "0x...",
        "implementation": "0x..."
      }
    },
    "core": {
      "DisputeGameFactory": {
        "proxy": "0x...",
        "implementation": "0x..."
      },
      "AnchorStateRegistry": {
        "proxy": "0x...",
        "implementation": "0x..."
      },
      "ETHLockbox": {
        "proxy": "0x...",
        "implementation": "0x..."
      }
    },
    "gameImpls": {
      "ComposeDisputeGame": {
        "implementation": "0x...",
        "gameType": 5555
      }
    }
  }
}
```

### View Deployments

```bash
# Show all deployments
just show-deployments

# Get specific network
just get-deployment hoodi-stage

# Validate deployment
just validate-deployment hoodi-stage
```

---

## Post-Deployment

### 1. Verify Contracts

Contracts are auto-verified if `ETHERSCAN_API_KEY` is set. Manual verification:

```bash
just verify-network hoodi-stage
```

### 2. Check Deployment

```bash
# Get deployment info
DEPLOYMENT=$(just get-deployment hoodi-stage)

# Extract addresses
SUPERCHAIN_CONFIG=$(echo $DEPLOYMENT | jq -r '.["hoodi-stage"].governance.SuperchainConfig.proxy')
LOCKBOX=$(echo $DEPLOYMENT | jq -r '.["hoodi-stage"].core.ETHLockbox.proxy')
ASR=$(echo $DEPLOYMENT | jq -r '.["hoodi-stage"].core.AnchorStateRegistry.proxy')

# Verify guardian
cast call $SUPERCHAIN_CONFIG "guardian()" --rpc-url $RPC_URL

# Check pause status
cast call $LOCKBOX "paused()" --rpc-url $RPC_URL

# Check respected game type
cast call $ASR "respectedGameType()(uint32)" --rpc-url $RPC_URL
# Should return: 5555
```

### 3. Security Checklist

**Before Production:**

- [ ] Guardian is multisig (3-of-5 or higher)
- [ ] ProxyAdmin owner is multisig
- [ ] All contracts verified on explorer
- [ ] Pause/unpause tested
- [ ] Game creation tested with bond
- [ ] SP1 verifier address correct
- [ ] Aggregation vkey matches proving key
- [ ] Deployment addresses backed up
- [ ] Monitor infrastructure set up

### 4. Test Infrastructure

```bash
# Test pause (as guardian)
cast send $SUPERCHAIN_CONFIG "pause(address)" 0x0000000000000000000000000000000000000000 \
  --private-key $GUARDIAN_KEY \
  --rpc-url $RPC_URL

# Verify paused
cast call $LOCKBOX "paused()" --rpc-url $RPC_URL
# Should return: true

# Unpause
cast send $SUPERCHAIN_CONFIG "unpause()" \
  --private-key $GUARDIAN_KEY \
  --rpc-url $RPC_URL
```

---

## Parameters

### Timing Parameters

**`proof_maturity_delay_seconds`** (default: 604800 = 7 days)
- How long before a withdrawal can be finalized
- Allows time for challenge period
- Standard: 7 days mainnet, 1 hour testnet

**`dispute_game_finality_delay_seconds`** (default: 302400 = 3.5 days)
- Additional delay after game resolution
- Ensures game result is stable
- Standard: 3.5 days mainnet, 30 min testnet

### Economic Parameters

**`dispute_game_init_bond`** (default: "80000000000000000" = 0.08 ETH)
- Bond required to create a dispute game
- Prevents spam
- Returned if defender wins
- Standard: 0.08-0.1 ETH mainnet, 0.01 ETH testnet

### Security Parameters

**Guardian**
- Emergency pause authority
- Must be trusted entity
- Mainnet: Use multisig
- Testnet: EOA acceptable

**ProxyAdmin Owner**
- Upgrade authority
- Must be trusted entity
- Mainnet: Use multisig
- Testnet: EOA acceptable

**Authorized Proposer**
- Publishes superblocks
- Hot wallet for automation
- Needs gas funds
- Compromise: Can only propose, not steal funds

---

## Upgrade Process

### Upgrading Proxies

Only ProxyAdmin owner can upgrade:

```bash
# Upgrade SuperchainConfig
cast send $PROXY_ADMIN "upgrade(address,address)" \
  $SUPERCHAIN_CONFIG_PROXY \
  $NEW_IMPLEMENTATION \
  --private-key $OWNER_KEY \
  --rpc-url $RPC_URL

# Upgrade with initialization
cast send $PROXY_ADMIN "upgradeAndCall(address,address,bytes)" \
  $LOCKBOX_PROXY \
  $NEW_IMPLEMENTATION \
  $(cast abi-encode "initialize(address)" $SUPERCHAIN_CONFIG) \
  --private-key $OWNER_KEY \
  --rpc-url $RPC_URL
```

### Updating Game Implementation

Only DisputeGameFactory owner can update:

```bash
# Deploy new game implementation
NEW_GAME=$(forge create src/ComposeDisputeGame.sol:ComposeDisputeGame ...)

# Update factory
cast send $DGF_PROXY "setImplementation(uint32,address)" \
  5555 \
  $NEW_GAME \
  --private-key $OWNER_KEY \
  --rpc-url $RPC_URL
```

---

## Monitoring

### Key Metrics

**SuperchainConfig:**
- Guardian address
- Pause status
- Pause history

**DisputeGameFactory:**
- Game creation rate
- Active games count
- Resolution rate

**AnchorStateRegistry:**
- Current anchor state
- Last update time
- Update frequency

**ETHLockbox:**
- Total balance
- Authorized portals count
- Withdrawal volume

### Events to Monitor

```solidity
// SuperchainConfig
event Paused(string identifier);
event Unpaused();

// DisputeGameFactory
event DisputeGameCreated(address indexed disputeProxy, GameType indexed gameType, Claim indexed rootClaim);

// AnchorStateRegistry  
event AnchorUpdated(GameType indexed gameType, OutputRoot indexed outputRoot);

// ETHLockbox
event PortalAuthorized(address indexed portal);
event Unlocked(address indexed recipient, uint256 amount);
```

---

## Troubleshooting

### "Deployment reverted"

Check:
- Sufficient funds for gas
- RPC endpoint working
- Configuration valid
- No naming conflicts

### "Guardian not set"

Add to `networks.toml`:
```toml
guardian = "0xYourAddress"
```

### "SP1 verification failed"

Ensure:
- `sp1_verifier` address is correct
- `aggregation_vkey` matches proving key
- SP1 verifier contract deployed

### "Pause not working"

Verify:
- Caller is guardian
- Guardian address correct in contract
- Not already paused

---

## Next Steps

After deploying shared infrastructure:

1. ✅ **Phase 1 Complete** - Shared infrastructure deployed
2. 📋 **Prepare Rollups** - Create configs in `script/config/rollups/`
3. 🔄 **Phase 2** - Migrate rollups (see [ROLLUP_MIGRATION.md](./ROLLUP_MIGRATION.md))
4. 🚀 **Publish** - Start publishing superblocks

---

## Reference

- **Deployment Script:** `script/deploy/DeploySharedInfra.s.sol`
- **Configuration:** [NETWORK_CONFIG.md](./NETWORK_CONFIG.md)
- **Migration:** [ROLLUP_MIGRATION.md](./ROLLUP_MIGRATION.md)
- **Commands:** Run `just` for full list
