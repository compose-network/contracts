# Getting Started with L2 Rollup Contracts

Quick guide to deploy cross-rollup messaging contracts to your L2 networks.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- [just](https://github.com/casey/just#installation) command runner installed
- Private key with funds on target rollups
- RPC endpoints for your rollup networks

## Step 1: Initial Setup

```bash
# Navigate to L2 directory
cd L2

# Initialize configuration files from examples
just init-config
```

This creates:
- `.env` (from `.env.example`)
- `networks.toml` (from `networks.toml.example`)

## Step 2: Configure Environment

Edit `.env` file:

```bash
# Required: Your deployer private key
DEPLOYER_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE

# Required: CREATE2 salt for deterministic addresses
DEPLOY_SALT=0x0000000000000000000000000000000000000000000000000000000000000000

# Required: Coordinator address (same across all rollups)
COORDINATOR_ADDRESS=0xYOUR_COORDINATOR_ADDRESS

# Optional: Blockscout API key for verification
BLOCKSCOUT_API_KEY=your_api_key_here
```

## Step 3: Configure Networks

Edit `networks.toml` file:

```toml
[rollup-a]
name = "Rollup A"
chain_id = 77777
rpc_url = "http://57.129.73.156:31130/"
blockscout_url = ""  # Optional
blockscout_api_key = "${BLOCKSCOUT_API_KEY}"

[rollup-b]
name = "Rollup B"
chain_id = 88888
rpc_url = "http://57.129.73.144:31133"
blockscout_url = ""  # Optional
blockscout_api_key = "${BLOCKSCOUT_API_KEY}"
```

**Add more networks as needed following the same pattern.**

## Step 4: Validate Setup

```bash
# Check if everything is configured correctly
just check-setup
```

Output should show:
```
=== Configuration Files ===
✓ .env file exists
  ✓ DEPLOYER_PRIVATE_KEY is set
  ✓ COORDINATOR_ADDRESS is set
✓ networks.toml file exists
  Configured networks: 2
```

## Step 5: Build Contracts

```bash
just build
```

## Step 6: Test Network Connection

Before deploying, test that you can connect to your networks:

```bash
# Test connection to rollup-a
just test-network rollup-a

# Test connection to rollup-b
just test-network rollup-b
```

## Step 7: Deploy

### Deploy to Single Network

```bash
just deploy-core rollup-a
```

### Deploy to Multiple Networks

```bash
just deploy-multi rollup-a rollup-b
```

## Step 8: Verify Deployment

```bash
# Show all deployments
just show-deployments

# Show specific network deployment
just get-deployment rollup-a

# Get specific contract address
just get-mailbox rollup-a
just get-bridge rollup-a
just get-pingpong rollup-a
just get-token rollup-a
```

## Step 9: Verify Contracts on Blockscout (Optional)

After deployment, verify your contracts on Blockscout for transparency:

```bash
# Verify all contracts at once
just verify-all rollup-a

# Or verify individual contracts
just verify-mailbox rollup-a <address> <coordinator>
just verify-pingpong rollup-a <address> <mailbox>
just verify-bridge rollup-a <address> <mailbox>
just verify-token rollup-a <address>
```

The verification uses the explorer URLs configured in `networks.toml`:
- `explorer_url` - RPC endpoint for Blockscout
- `explorer_api_url` - API endpoint for verification

## 📁 Deployment Artifacts

After deployment, you'll find:

- `artifacts/deploy-{network}.json` - Per-network deployment info
- `deployments.json` - Unified tracking of all deployments
- `deployment-{network}.log` - Deployment logs
- `broadcast/` - Forge broadcast files

## 🔄 Deterministic Addresses

All contracts use CREATE2 deployment with the same `DEPLOY_SALT`, ensuring:
- **Consistent addresses across all rollups**
- **Predictable contract locations**
- **Simplified cross-rollup integration**

## 🧪 Testing Cross-Rollup Messaging

After deploying to multiple rollups, test the PingPong functionality:

```bash
# Use the PlayPingPong.s.sol script
forge script script/PlayPingPong.s.sol \
    --rpc-url <your-rpc> \
    --broadcast
```

## 📊 Example Workflow

Complete workflow for deploying to two rollups:

```bash
cd L2

# 1. Setup
just init-config
vim .env          # Configure your keys
vim networks.toml # Configure your networks (including explorer URLs)

# 2. Validate
just check-setup

# 3. Build
just build

# 4. Test connections
just test-network rollup-a
just test-network rollup-b

# 5. Deploy to both
just deploy-multi rollup-a rollup-b

# 6. Verify on Blockscout
just verify-all rollup-a
just verify-all rollup-b

# 7. Check deployments
just show-deployments
```

## 🆘 Troubleshooting

### "networks.toml not found"
```bash
just init-config
```

### "DEPLOYER_PRIVATE_KEY not set"
Edit `.env` and add your private key (with 0x prefix)

### "Connection failed"
- Check RPC URL in `networks.toml`
- Ensure network is accessible
- Test with: `cast block-number --rpc-url <your-rpc>`

### "Deployment failed"
- Check deployment logs: `just logs <network>`
- Ensure you have funds on the deployer address
- Verify COORDINATOR_ADDRESS is valid

### Contracts not building
```bash
just clean
just build
```

## 🔐 Security Reminders

- ⚠️ **Never commit `.env` file** - it contains your private key
- ⚠️ **Keep `networks.toml` private** - may contain sensitive endpoints
- ✅ **Use test networks first** - before deploying to production
- ✅ **Verify contract addresses** - after deployment
- ✅ **Keep backups** - of `deployments.json` and artifact files

## 📚 Next Steps

1. **Verify contracts** on Blockscout (if configured)
2. **Test messaging** between rollups using PingPong
3. **Integrate bridge** into your application
4. **Monitor deployments** using block explorers

## 🔗 Related Documentation

- [L2 README](README.md) - Full project documentation
- [Root README](../README.md) - Repository overview
- [L1 Settlement](../L1-settlement/README.md) - L1 contracts documentation

## 💡 Tips

- Use the same `DEPLOY_SALT` for consistent addresses
- Deploy to all rollups before testing cross-rollup features
- Save your `deployments.json` file for reference
- Check deployment logs if something goes wrong
- Use `just list-networks` to see available networks
