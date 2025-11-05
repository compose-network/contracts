# Network Configuration Guide

Complete guide for configuring networks in `networks.toml`.

## Overview

The `networks.toml` file contains all network-specific configuration for deploying Compose Contracts. Each network section defines RPC endpoints, explorer settings, and contract initialization parameters.

## Configuration Structure

```toml
[networks.<network-id>]
# Basic network information
name = "Network Display Name"
rpc_url = "https://rpc.endpoint.com"
chain_id = 12345
explorer_url = "https://explorer.com"
explorer_api_url = "https://api.explorer.com/api"

# ComposeL2OutputOracle initialization parameters
verifier_address = "0x..."
owner_address = "0x..."
proposer_address = "0x..."
aggregation_vkey = "0x..."
starting_superblock_number = 0

# DisputeGameFactory initialization parameters
admin_address = "0x..."
```

## Field Descriptions

### Basic Network Information

#### `name` (string)
Human-readable network name displayed in logs.

**Example:**
```toml
name = "Ethereum Sepolia"
```

#### `rpc_url` (string)
RPC endpoint URL for the network. Use a reliable provider with sufficient rate limits.

**Examples:**
```toml
# Alchemy
rpc_url = "https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY"

# Infura
rpc_url = "https://sepolia.infura.io/v3/YOUR_PROJECT_ID"

# Public endpoint (not recommended for production)
rpc_url = "https://eth-sepolia.public.blastapi.io"

# Custom/Hoodi network
rpc_url = "https://hoodi-rpc.example.com"
```

**Tips:**
- Use dedicated RPC providers (Alchemy, Infura) for reliability
- Avoid public RPCs for production deployments
- Ensure sufficient rate limits for deployment

#### `chain_id` (integer)
Network chain ID. Must match the actual chain ID.

**Examples:**
```toml
chain_id = 1           # Ethereum Mainnet
chain_id = 11155111    # Sepolia
chain_id = 17000       # Holesky
chain_id = 12345       # Custom network
```

**How to find:**
```bash
cast chain-id --rpc-url <RPC_URL>
```

#### `explorer_url` (string)
Block explorer homepage URL. Used for displaying links.

**Examples:**
```toml
explorer_url = "https://etherscan.io"
explorer_url = "https://sepolia.etherscan.io"
explorer_url = "https://holesky.etherscan.io"
explorer_url = "https://hoodi.explorer.example.com"
```

#### `explorer_api_url` (string)
Block explorer API endpoint for contract verification.

**Examples:**
```toml
# Etherscan networks
explorer_api_url = "https://api.etherscan.io/api"
explorer_api_url = "https://api-sepolia.etherscan.io/api"
explorer_api_url = "https://api-holesky.etherscan.io/api"

# Custom explorers
explorer_api_url = "https://api.hoodi-explorer.com/api"
```

**Note:** Ensure the API URL is correct for your network. Test with:
```bash
curl "https://api-sepolia.etherscan.io/api?module=contract&action=getabi&address=0x..."
```

### ComposeL2OutputOracle Parameters

#### `verifier_address` (address)
Address of the deployed SP1Verifier contract used to verify ZK proofs.

**Example:**
```toml
verifier_address = "0x17Ef331C3c90E9e5718e81085c721a404eF18436"
```

**How to obtain:**
- Deploy SP1Verifier contract first
- Or use existing deployment on the network
- Must be a valid contract address

**Validation:**
```bash
# Check if contract exists
cast code <VERIFIER_ADDRESS> --rpc-url <RPC_URL>
```

#### `owner_address` (address)
Owner address with admin permissions for ComposeL2OutputOracle.

**Example:**
```toml
owner_address = "0xA139A1776E60F9645533a9AD419461818D6839a1"
```

**Responsibilities:**
- Update aggregation verification key
- Update verifier contract address
- Update approved proposer address
- Critical admin functions

**Security:**
- Use a multisig or secure wallet
- Never use the deployer wallet
- Consider using a Gnosis Safe

#### `proposer_address` (address)
Approved proposer address authorized to submit L2 outputs.

**Example:**
```toml
proposer_address = "0xb054981b2Ef67603E50B1bD840D0834ef5bcceE4"
```

**Purpose:**
- Only this address can propose L2 outputs
- Acts as the trusted sequencer/proposer
- Can be updated by owner

**Security:**
- Should be a dedicated proposer service
- Keep private keys secure
- Monitor proposer activity

#### `aggregation_vkey` (bytes32)
Verification key for the SP1 aggregation program.

**Example:**
```toml
aggregation_vkey = "0x0059ae2f8c8ad61a6af02594067148b58dbecff2e3352170923efda8ea603f1e"
```

**How to obtain:**
- Generated during SP1 program compilation
- Specific to your SP1 aggregation circuit
- Format: 32-byte hex string with `0x` prefix

**Validation:**
```bash
# Ensure it's a valid 32-byte hex string
echo "0x0059ae2f..." | grep -E '^0x[0-9a-fA-F]{64}$'
```

#### `starting_superblock_number` (integer)
Starting superblock number for the oracle. Usually `0` for new deployments.

**Example:**
```toml
starting_superblock_number = 0
```

**When to change:**
- `0` - New deployment, start from beginning
- `N` - Migrating from existing deployment, continue from block N

### DisputeGameFactory Parameters

#### `admin_address` (address)
Admin address that controls the DisputeGameFactory.

**Example:**
```toml
admin_address = "0xA139A1776E60F9645533a9AD419461818D6839a1"
```

**Responsibilities:**
- Register new game types
- Update game implementations
- Manage factory settings

**Security:**
- Use a multisig or secure wallet
- Can be same as oracle owner address
- Consider using a Gnosis Safe

## Network Examples

### Ethereum Sepolia (Testnet)

```toml
[networks.sepolia]
name = "Ethereum Sepolia"
rpc_url = "https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY"
chain_id = 11155111
explorer_url = "https://sepolia.etherscan.io"
explorer_api_url = "https://api-sepolia.etherscan.io/api"

# Testnet values
verifier_address = "0x17Ef331C3c90E9e5718e81085c721a404eF18436"
owner_address = "0xYourTestOwnerAddress"
proposer_address = "0xYourTestProposerAddress"
aggregation_vkey = "0x0059ae2f8c8ad61a6af02594067148b58dbecff2e3352170923efda8ea603f1e"
starting_superblock_number = 0
admin_address = "0xYourTestAdminAddress"
```

### Ethereum Holesky (Testnet)

```toml
[networks.holesky]
name = "Ethereum Holesky"
rpc_url = "https://ethereum-holesky-rpc.publicnode.com"
chain_id = 17000
explorer_url = "https://holesky.etherscan.io"
explorer_api_url = "https://api-holesky.etherscan.io/api"

verifier_address = "0x..."
owner_address = "0x..."
proposer_address = "0x..."
aggregation_vkey = "0x..."
starting_superblock_number = 0
admin_address = "0x..."
```

### Ethereum Mainnet

```toml
[networks.mainnet]
name = "Ethereum Mainnet"
rpc_url = "https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY"
chain_id = 1
explorer_url = "https://etherscan.io"
explorer_api_url = "https://api.etherscan.io/api"

# Production values
verifier_address = "0xYourProductionVerifier"
owner_address = "0xYourMultisigAddress"
proposer_address = "0xYourProposerService"
aggregation_vkey = "0xYourProductionVkey"
starting_superblock_number = 0
admin_address = "0xYourMultisigAddress"
```

### Hoodi Custom L1

```toml
[networks.hoodi]
name = "Hoodi L1"
rpc_url = "https://hoodi-rpc.example.com"
chain_id = 12345
explorer_url = "https://hoodi.explorer.example.com"
explorer_api_url = "https://api.hoodi.explorer.example.com/api"

verifier_address = "0x..."
owner_address = "0x..."
proposer_address = "0x..."
aggregation_vkey = "0x..."
starting_superblock_number = 0
admin_address = "0x..."
```

## Configuration Best Practices

### Security

1. **Use Secure Wallets**
   - Owner/admin: Multisig (Gnosis Safe)
   - Proposer: Dedicated service wallet
   - Never reuse deployer wallet

2. **Protect Configuration Files**
   - Never commit `networks.toml` (gitignored)
   - Store securely in password manager
   - Use different keys for testnet/mainnet

3. **Validate Addresses**
   ```bash
   # Verify address has code (for contracts)
   cast code <ADDRESS> --rpc-url <RPC_URL>
   
   # Check address balance (for EOAs)
   cast balance <ADDRESS> --rpc-url <RPC_URL>
   ```

### Testing

1. **Test on Testnet First**
   ```bash
   # Always deploy to testnet before mainnet
   just deploy-network sepolia
   ```

2. **Verify Configuration**
   ```bash
   # Test network connection
   just test-network sepolia
   
   # Validate setup
   just check-setup
   ```

3. **Check Gas Costs**
   ```bash
   # Check current gas prices
   cast gas-price --rpc-url <RPC_URL>
   
   # Estimate deployment cost
   # Approximately 3-5M gas total
   ```

### Maintenance

1. **Document Changes**
   - Keep changelog of network config changes
   - Note when parameters are updated
   - Track reason for changes

2. **Backup Configurations**
   ```bash
   # Backup networks.toml
   cp networks.toml networks.toml.backup
   ```

3. **Multiple Environments**
   ```toml
   # Separate testnet and mainnet configs
   [networks.sepolia-dev]
   # Development environment
   
   [networks.sepolia-staging]
   # Staging environment
   
   [networks.mainnet-prod]
   # Production environment
   ```

## Troubleshooting

### RPC Issues

**Problem:** RPC connection fails

**Solutions:**
```bash
# Test RPC manually
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  <RPC_URL>

# Try alternative RPC provider
# Update rpc_url in networks.toml
```

### Chain ID Mismatch

**Problem:** Chain ID doesn't match network

**Solution:**
```bash
# Check actual chain ID
cast chain-id --rpc-url <RPC_URL>

# Update chain_id in networks.toml
```

### Verification Fails

**Problem:** Cannot verify contracts

**Solutions:**
- Check explorer_api_url is correct
- Ensure ETHERSCAN_API_KEY is set
- Wait 1-2 minutes after deployment
- Check if network supports verification

### Invalid Addresses

**Problem:** Address validation fails

**Solution:**
```bash
# Verify address format (should start with 0x, 42 chars total)
echo "0x..." | grep -E '^0x[0-9a-fA-F]{40}$'

# Check if contract exists (should return bytecode)
cast code <ADDRESS> --rpc-url <RPC_URL>
```

## RPC Provider Recommendations

### Ethereum Networks

**Recommended:**
- [Alchemy](https://www.alchemy.com/) - Reliable, good free tier
- [Infura](https://www.infura.io/) - Industry standard
- [QuickNode](https://www.quicknode.com/) - Fast, dedicated nodes

**For Testing:**
- Public RPCs (limited rate)
- Local nodes (most reliable for dev)

### Custom Networks (Hoodi)

- Contact network operators for RPC access
- Request dedicated endpoint for deployments
- Ensure sufficient rate limits

## Security Checklist

- [ ] All addresses are checksummed (mixed case)
- [ ] RPC URLs use HTTPS, not HTTP
- [ ] Owner/admin addresses are multisigs
- [ ] Proposer address is dedicated service
- [ ] Aggregation vkey is correct format (32 bytes)
- [ ] Testnet and mainnet configs are separate
- [ ] `networks.toml` is gitignored
- [ ] Configuration is backed up securely

## Next Steps

- ✅ Configure networks: Edit `networks.toml`
- ✅ Validate configuration: `just check-setup`
- ✅ Test network connection: `just test-network <name>`
- ✅ Deploy: `just deploy-network <name>`

## References

- [CONTRACT_PARAMS.md](CONTRACT_PARAMS.md) - Detailed parameter explanations
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Full deployment walkthrough
- [Foundry Configuration](https://book.getfoundry.sh/reference/config/)
