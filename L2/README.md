# L2 Rollup Contracts

Cross-rollup messaging, bridging, and DEX contracts for L2 execution layers.

## 📋 Overview

This project contains L2 contracts organized into two main modules:

### Core Contracts (Cross-Rollup Communication)
- **Mailbox** - Cross-rollup message handling (for native rollups)
- **StagedMailbox** - Modified mailbox for external rollups (pre-populated messages)
- **PingPong** - Cross-rollup message demo
- **Bridge** - Asset bridging between rollups
- **BridgeableToken** - Token with cross-rollup support

### DEX Contracts (Decentralized Exchange)
- **SSVMintable** - SSV token (18 decimals)
- **USDCMintable** - USDC token (18 decimals)
- **WETH9** - Wrapped Ether (18 decimals)
- **USDC_SSV_WETH_Swapper** - Simple 3-token swapper with 0.3% fee

## 🔄 Mailbox vs StagedMailbox

The L2 contracts include two types of mailbox contracts:

- **Mailbox**: Standard cross-rollup message handling for **native rollups** within the Compose network. Messages are directly written and read during transaction execution.

- **StagedMailbox**: Modified mailbox for **external rollups** outside the Compose network. All messages are pre-populated by the Wrapped Sequencer (WS) before transaction execution, enabling atomic cross-domain composability. See the Cross-Domain Composability Protocol (CDCP) for details.

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

### 3. Deploy Core Contracts

```bash
# Deploy core contracts to a specific network
just deploy-core rollup-a

# Deploy to multiple networks
just deploy-multi rollup-a rollup-b
```

### 4. Deploy DEX Contracts (Optional)

```bash
# Deploy DEX tokens (WETH, USDC, SSV) to a network
just deploy-dex-tokens rollup-b

# Deploy swapper contract (requires tokens deployed first)
just deploy-dex-swapper rollup-b

# Fund swapper with liquidity (default: 1M of each token)
just fund-dex-swapper rollup-b

# Or deploy everything at once
just deploy-dex-all rollup-b
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

### Core Deployment
```bash
just deploy-core <network>        # Deploy core contracts to specific network
just deploy-multi <net1> <net2>   # Deploy to multiple networks
just show-deployments             # Show all deployments
just get-deployment <network>     # Get deployment for network
```

### DEX Deployment
```bash
just deploy-dex-tokens <network>                    # Deploy DEX tokens (WETH, USDC, SSV)
just deploy-dex-swapper <network>                   # Deploy swapper contract
just fund-dex-swapper <network>                     # Fund with default amounts (1M each)
just fund-dex-swapper-custom <net> <w> <u> <s>     # Fund with custom amounts
just deploy-dex-all <network>                       # Deploy and fund complete DEX stack
```

### DEX Queries
```bash
just get-dex-info <network>                  # View DEX deployment info
just get-dex-reserves <network>              # View swapper reserves
just check-swap-price <net> <in> <out> <amt> # Check swap price
                                             # Token IDs: 0=WETH, 1=USDC, 2=SSV
```

### Verification (Blockscout)

**Core Contracts**
```bash
just verify-all <network>                              # Verify all core contracts
just verify-mailbox <net> <addr> <coordinator>         # Verify Mailbox
just verify-staged-mailbox <net> <addr> <coordinator>  # Verify StagedMailbox
just verify-pingpong <net> <addr> <mailbox>            # Verify PingPong
just verify-bridge <net> <addr> <mailbox>              # Verify Bridge
just verify-token <net> <addr> <bridge>                # Verify BridgeableToken
```

**DEX Contracts**
```bash
just verify-all-dex <network>                    # Verify all DEX contracts
just verify-weth <net> <addr>                    # Verify WETH9
just verify-usdc <net> <addr>                    # Verify USDC
just verify-ssv <net> <addr>                     # Verify SSV
just verify-swapper <net> <addr> <weth> <usdc> <ssv>  # Verify Swapper
```

### Contract Queries (Core)
```bash
just get-mailbox <network>         # Get Mailbox address
just get-staged-mailbox <network>  # Get StagedMailbox address
just get-pingpong <network>        # Get PingPong address
just get-bridge <network>          # Get Bridge address
just get-token <network>           # Get Token address
```

## 📁 Project Structure

```
L2/
├── src/
│   ├── core/                          # Core L2 contracts
│   │   ├── interfaces/
│   │   │   ├── IMailbox.sol
│   │   │   ├── IStagedMailbox.sol
│   │   │   ├── IBridge.sol
│   │   │   ├── IPingPong.sol
│   │   │   └── IBridgeableToken.sol
│   │   ├── Mailbox.sol
│   │   ├── StagedMailbox.sol
│   │   ├── Bridge.sol
│   │   ├── PingPong.sol
│   │   └── BridgeableToken.sol
│   └── dex/                           # DEX contracts
│       ├── SSVMintable.sol
│       ├── USDCMintable.sol
│       └── USDC_SSV_WETH_Swapper.sol
├── lib/
│   ├── forge-std/                     # Foundry standard library
│   ├── openzeppelin-contracts/        # OpenZeppelin contracts
│   └── external/                      # External contracts
│       └── WETH9.sol
├── script/
│   ├── core/                          # Core deployment scripts
│   │   ├── DeployContracts.s.sol
│   │   ├── DeployAll.sol
│   │   ├── DeployRollupA.s.sol
│   │   ├── DeployRollupB.s.sol
│   │   └── PlayPingPong.s.sol
│   └── dex/                           # DEX deployment scripts
│       ├── DeployDEXTokens.s.sol
│       ├── DeployWETH.s.sol
│       ├── DeploySwapper.s.sol
│       └── FundSwapper.s.sol
├── scripts/                           # Helper scripts
│   ├── deploy-core.sh
│   ├── parse-network.sh
│   ├── save-deployment.sh
│   └── dex/
│       ├── deploy-tokens.sh
│       ├── deploy-swapper.sh
│       └── fund-swapper.sh
├── test/                              # Test files
├── artifacts/                         # Deployment artifacts (gitignored)
├── .env                               # Environment config (gitignored)
├── networks.toml                      # Network configs (gitignored)
├── deployments.json                   # Deployment tracking (gitignored)
├── foundry.toml                       # Foundry configuration
├── remappings.txt                     # Import path mappings
└── justfile                           # Command runner
```

## 🎯 Deployment Workflows

### Core Contracts Deployment

1. **Configure**: Set up `.env` and `networks.toml`
2. **Build**: `just build`
3. **Deploy Core**: `just deploy-core <network>`
4. **Verify**: Check `deployments.json` for deployed addresses
5. **Test**: Use `PlayPingPong.s.sol` to test cross-rollup messaging

### DEX Contracts Deployment

1. **Deploy Tokens** (to all networks for cross-rollup support):
   ```bash
   just deploy-dex-tokens rollup-a
   just deploy-dex-tokens rollup-b
   ```

2. **Deploy Swapper** (to one network, e.g., rollup-b):
   ```bash
   # Reads token addresses from deployments.json
   just deploy-dex-swapper rollup-b
   ```

3. **Fund Swapper** (provide liquidity):
   ```bash
   # Default: 1M tokens each
   just fund-dex-swapper rollup-b
   
   # Or custom amounts (in ether units)
   just fund-dex-swapper-custom rollup-b 2000000 2000000 2000000
   ```

4. **Query DEX State**:
   ```bash
   # View deployment info
   just get-dex-info rollup-b
   
   # Check reserves
   just get-dex-reserves rollup-b
   
   # Check swap price (WETH→USDC, 1 token = 1e18 wei)
   just check-swap-price rollup-b 0 1 1000000000000000000
   ```

5. **Verify Contracts** (optional):
   ```bash
   # Verify all DEX contracts on the network
   just verify-all-dex rollup-b
   
   # Or verify individual contracts
   just verify-weth rollup-b <weth-address>
   just verify-usdc rollup-b <usdc-address>
   just verify-ssv rollup-b <ssv-address>
   just verify-swapper rollup-b <swapper-addr> <weth> <usdc> <ssv>
   ```

## 💱 DEX Features

### Token Specifications
- **SSV**: ERC20 token with 18 decimals, mintable/burnable
- **USDC**: ERC20 token with 18 decimals, mintable/burnable
- **WETH9**: Wrapped Ether with 18 decimals (ported to Solidity 0.8.30)

### Swapper Contract
- **3-Token Pool**: Supports WETH, USDC, and SSV
- **Trading Fee**: 0.3% (300 basis points)
- **Simple Pricing**: Constant product AMM formula
- **Token IDs**: 
  - `0` = WETH
  - `1` = USDC
  - `2` = SSV

### Example Swap Query
```bash
# Check price for swapping 1 WETH to USDC
just check-swap-price rollup-b 0 1 1000000000000000000

# Check price for swapping 1000 USDC to SSV
just check-swap-price rollup-b 1 2 1000000000000000000000
```

## 📊 Deployment Tracking

The `deployments.json` file tracks both core and DEX deployments:

```json
{
  "rollup-a": {
    "contracts": {
      "Mailbox": "0x...",
      "StagedMailbox": "0x...",
      "Bridge": "0x...",
      "PingPong": "0x...",
      "BridgeableToken": "0x..."
    },
    "dex": {
      "WETH": "0x...",
      "USDC": "0x...",
      "SSV": "0x...",
      "Swapper": null
    }
  },
  "rollup-b": {
    "contracts": { ... },
    "dex": {
      "WETH": "0x...",
      "USDC": "0x...",
      "SSV": "0x...",
      "Swapper": "0x..."
    }
  }
}
```

## 🔐 Security Notes

- Never commit `.env` file (contains private keys)
- `networks.toml` and `deployments.json` are gitignored
- Use CREATE2 for deterministic addresses across rollups
- Always verify deployed contract addresses
- DEX tokens are mintable - only for testing/demo purposes

## 📝 Technical Notes

### Compilation
- **Unified Version**: All contracts use Solidity 0.8.30
- **Auto-Detection**: Foundry auto-detects required compiler versions
- **WETH9**: Ported from 0.7.6 to 0.8.30 for unified compilation

### Deployment
- **CREATE2**: All contracts deployed with CREATE2 for deterministic addresses
- **Salt**: Uses `DEPLOY_SALT` from `.env` for consistent addresses
- **Coordinator**: Same `COORDINATOR_ADDRESS` used across all networks
- **Artifacts**: Saved to `artifacts/deploy-{type}-{network}.json`
- **Tracking**: All deployments tracked in `deployments.json`

### Project Organization
- **Core**: Cross-rollup messaging and bridging (`src/core/`)
- **DEX**: Decentralized exchange contracts (`src/dex/`)
- **External**: Third-party contracts (`lib/external/`)
- **Separate Scripts**: Core and DEX have dedicated deployment infrastructure