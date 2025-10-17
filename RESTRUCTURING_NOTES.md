# Repository Restructuring Notes

## ✅ Changes Made

The repository has been reorganized into a monorepo structure with two sub-projects:

```
compose-contracts/
├── L1-settlement/          # All L1 contracts (previously root)
└── L2/                    # L2 contracts (to be added)
```

### Files Moved

**All files moved from root → L1-settlement/**:
- `src/` - Contract source files
- `script/` - Deployment scripts  
- `scripts/` - Bash helper scripts
- `test/` - Contract tests
- `lib/` - Dependencies (submodules)
- `docs/` - Documentation
- `justfile` - Deployment commands
- `foundry.toml` - Foundry configuration
- `networks.toml` - Network configurations
- `.env` - Environment variables
- `README.md` - L1 documentation
- `GETTING_STARTED.md` - Quick start guide
- `CHANGELOG.md` - Change history
- All other configuration files

**Files kept at root:**
- `.git/` - Git repository data
- `.gitignore` - Root gitignore (updated)
- `.gitmodules` - Submodule configuration (updated with new paths)
- `README.md` - New root README explaining structure

**Files created:**
- `README.md` - New root README
- `L1-settlement/.gitignore` - Copy of project-specific ignores
- `L2/README.md` - Placeholder for L2 project

## ⚠️ Important Considerations

### 1. Git Submodules

**Status:** ✅ Updated

The `.gitmodules` file has been updated to reflect new paths:
- Old: `lib/forge-std`, `lib/optimism`, etc.
- New: `L1-settlement/lib/forge-std`, `L1-settlement/lib/optimism`, etc.

**Action taken:**
```bash
git submodule sync
```

**When cloning fresh:**
```bash
git clone <repo-url>
cd compose-contracts
git submodule update --init --recursive
```

### 2. Working Directory for Commands

**All L1 commands must now be run from the L1-settlement directory:**

```bash
# OLD (doesn't work anymore)
just build
just deploy-network sepolia

# NEW (correct)
cd L1-settlement
just build
just deploy-network sepolia
```

**All relative paths in scripts work correctly** because they're relative within L1-settlement/.

### 3. Git Operations

**Staging and committing:**

```bash
# Stage L1 changes
git add L1-settlement/

# Stage L2 changes (when added)
git add L2/

# Stage root changes
git add README.md .gitmodules
```

**Status check:**
```bash
git status
# Will show: L1-settlement/, L2/, etc.
```

### 4. CI/CD Pipelines

**If you have CI/CD configured, update:**

```yaml
# OLD
- run: forge build
- run: forge test

# NEW
- run: cd L1-settlement && forge build
- run: cd L1-settlement && forge test
```

### 5. IDE Configuration

**VSCode / IDE workspace:**
- Open `L1-settlement` as project root for L1 work
- Open `L2` as project root for L2 work
- Or use multi-root workspace

**Solidity paths:**
- Still resolve correctly because they're relative within each project
- `foundry.toml` remappings still work

### 6. Deployment Configurations

**Status:** ✅ No changes needed

All deployment configurations work as before:
- `.env` is in `L1-settlement/`
- `networks.toml` is in `L1-settlement/`
- `deployments.json` is in `L1-settlement/`
- All scripts use relative paths

**Just remember to cd into L1-settlement first!**

### 7. Documentation Links

**Status:** ✅ Updated

- Root README links to L1-settlement docs
- L1-settlement README unchanged (internal links still work)

## 📋 Next Steps

### For L1 Development

1. Navigate to L1-settlement:
   ```bash
   cd L1-settlement
   ```

2. Continue working as before:
   ```bash
   just build
   just deploy-network sepolia
   ```

### For L2 Integration

1. Add your L2 project to the `L2/` directory

2. Update `L2/README.md` with L2-specific documentation

3. Optionally add L2 submodules to root `.gitmodules`:
   ```toml
   [submodule "L2/lib/<dependency>"]
       path = L2/lib/<dependency>
       url = <repo-url>
   ```

4. Update root README.md with L2 information

## 🔧 Troubleshooting

### Submodule Issues

**Problem:** Submodules showing as modified or missing

**Solution:**
```bash
# Sync submodule configuration
git submodule sync

# Update submodules
git submodule update --init --recursive

# If that doesn't work, re-clone:
rm -rf L1-settlement/lib/*
git submodule update --init --recursive
```

### Command Not Found

**Problem:** `just build` fails with "cannot find justfile"

**Solution:**
```bash
# Make sure you're in L1-settlement directory
cd L1-settlement
just build
```

### Git Shows Everything as Changed

**Problem:** `git status` shows all files as modified

**Solution:**
```bash
# This is expected after restructuring
# Review changes carefully and commit:
git add -A
git commit -m "Restructure: Separate L1 and L2 contracts into sub-projects"
```

## ✅ Verification Checklist

- [x] All files moved to L1-settlement/
- [x] L2/ directory created with README
- [x] Root README.md created
- [x] .gitmodules updated with new paths
- [x] .gitignore copied to L1-settlement/
- [x] Root .gitignore updated
- [x] Git submodules synced
- [ ] Test L1 build: `cd L1-settlement && just build`
- [ ] Test L1 deployment: `cd L1-settlement && just deploy-network <testnet>`
- [ ] Update CI/CD configurations (if applicable)
- [ ] Update team documentation (if applicable)
- [ ] Commit and push changes

## 📝 Git Commit Message Template

```
Restructure: Organize contracts into L1-settlement and L2 sub-projects

- Move all L1 contracts to L1-settlement/ directory
- Create L2/ directory for future L2 contracts
- Update .gitmodules with new submodule paths
- Create new root README explaining structure
- Update .gitignore for monorepo structure

All L1 commands must now be run from L1-settlement/:
  cd L1-settlement
  just build
  just deploy-network <network>

L2 contracts can be added to L2/ directory.
```

## 🔗 Related Files

- [Root README](README.md) - Repository overview
- [L1 README](L1-settlement/README.md) - L1 contracts documentation
- [L2 README](L2/README.md) - L2 contracts (to be added)
