# Quick Reference - After Restructuring

## 🎯 Most Important Change

**All L1 commands must now be run from the `L1-settlement/` directory.**

## 🚀 Quick Commands

### L1 Development
```bash
# Navigate to L1
cd L1-settlement

# Setup (first time only)
just setup

# Build
just build

# Deploy
just deploy-network sepolia

# View deployments
just show-deployments
```

### L2 Development (when added)
```bash
# Navigate to L2
cd L2

# (Commands will depend on L2 project structure)
```

### Git Operations
```bash
# After pulling changes
git submodule sync
git submodule update --init --recursive

# Stage L1 changes
git add L1-settlement/

# Stage L2 changes
git add L2/

# Stage root changes
git add README.md .gitmodules
```

## 📁 Structure

```
Root
├── L1-settlement/    ← All L1 work here
│   └── just ...      ← Run commands from here
└── L2/              ← All L2 work here (when added)
```

## ✅ That's It!

Just remember: `cd L1-settlement` before running L1 commands.

---

**Full details:** See repository documentation
