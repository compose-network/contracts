# Changelog

## 2025-10-17 - Initial Deployment System

### Added
- Complete deployment system for Compose Contracts
- Multi-chain deployment support via `networks.toml`
- Automatic address tracking in `deployments.json`
- Automatic Etherscan verification
- Comprehensive documentation

### Changed
- **BREAKING:** `DeployComposeL2OutputOracle.s.sol` now accepts parameters via function signature
  - Old: `run()` reading from env vars
  - New: `run(address verifier, address owner, address proposer, bytes32 aggregationVkey, uint256 startingSuperBlockNumber)`
  
- **BREAKING:** `DeployDisputeGameFactory.s.sol` now accepts parameters via function signature
  - Old: `run()` reading from `HOODI_ADMIN_ADDRESS` env var
  - New: `run(address admin)`

- All deployment parameters now read from `networks.toml` instead of environment variables
- Updated `scripts/deploy.sh` to pass parameters from network config
- Updated `justfile` commands to pass parameters from network config

### Migration Guide

If you have existing deployment scripts calling these contracts:

**Before:**
```bash
export HOODI_ADMIN_ADDRESS=0x...
export HOODI_VERIFIER_ADDRESS=0x...
export HOODI_OWNER_ADDRESS=0x...
export HOODI_PROPOSER_ADDRESS=0x...
export HOODI_AGG_VKEY=0x...
export HOODI_STARTING_SUPERBLOCK_NUMBER=0

forge script script/DeployDisputeGameFactory.s.sol:DeployDisputeGameFactory --rpc-url $RPC --broadcast
```

**After:**
```bash
# Configure in networks.toml
just deploy-network sepolia

# Or manually:
forge script script/DeployDisputeGameFactory.s.sol:DeployDisputeGameFactory \
  --sig "run(address)" "$ADMIN_ADDRESS" \
  --rpc-url $RPC --broadcast
```

### Files Modified
- `script/DeployComposeL2OutputOracle.s.sol` - Changed to accept parameters
- `script/DeployDisputeGameFactory.s.sol` - Changed to accept admin address parameter
- `scripts/deploy.sh` - Updated to pass parameters via `--sig`
- `justfile` - Updated `deploy-oracle` and `deploy-factory` commands

### Benefits
- ✅ All network configuration in one place (`networks.toml`)
- ✅ No more environment variable management
- ✅ Easier multi-chain deployments
- ✅ Better parameter validation
- ✅ Clearer deployment flow
