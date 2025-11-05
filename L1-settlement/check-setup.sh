#!/usr/bin/env bash
# Validate environment setup for Compose Contracts deployment

set -euo pipefail

echo "Checking Compose Contracts deployment setup..."
echo ""

ERRORS=0

# Check for required tools
echo "=== Required Tools ==="

if command -v forge &> /dev/null; then
    FORGE_VERSION=$(forge --version | head -1)
    echo "✓ Foundry: $FORGE_VERSION"
else
    echo "✗ Foundry not found. Install from: https://book.getfoundry.sh"
    ERRORS=$((ERRORS+1))
fi

if command -v just &> /dev/null; then
    JUST_VERSION=$(just --version)
    echo "✓ just: $JUST_VERSION"
else
    echo "✗ just not found. Install from: https://github.com/casey/just"
    ERRORS=$((ERRORS+1))
fi

if command -v jq &> /dev/null; then
    JQ_VERSION=$(jq --version)
    echo "✓ jq: $JQ_VERSION"
else
    echo "✗ jq not found. Install with: brew install jq (macOS) or apt install jq (Linux)"
    ERRORS=$((ERRORS+1))
fi

if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    echo "✓ git: $GIT_VERSION"
else
    echo "✗ git not found"
    ERRORS=$((ERRORS+1))
fi

echo ""

# Check for git submodules
echo "=== Git Submodules ==="

if [ -e "lib/optimism/.git" ]; then
    cd lib/optimism
    OPTIMISM_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    OPTIMISM_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    cd ../..
    echo "✓ Optimism submodule initialized"
    echo "  Branch: $OPTIMISM_BRANCH"
    echo "  Commit: $OPTIMISM_COMMIT"
    
    if [ "$OPTIMISM_BRANCH" != "op-deployer/v0.3.3" ] && [ "$OPTIMISM_BRANCH" != "HEAD" ]; then
        echo "  Warning: Expected branch 'op-deployer/v0.3.3', got '$OPTIMISM_BRANCH'"
        echo "  Run: cd lib/optimism && git checkout op-deployer/v0.3.3"
    fi
else
    echo "✗ Optimism submodule not initialized. Run: just setup"
    ERRORS=$((ERRORS+1))
fi

if [ -e "lib/forge-std/.git" ]; then
    echo "✓ forge-std submodule initialized"
else
    echo "✗ forge-std submodule not initialized. Run: just setup"
    ERRORS=$((ERRORS+1))
fi

echo ""

# Check for configuration files
echo "=== Configuration Files ==="

if [ -f ".env" ]; then
    echo "✓ .env file exists"
    
    # Check for required variables
    if grep -q "^DEPLOYER_PRIVATE_KEY=" .env && ! grep -q "^DEPLOYER_PRIVATE_KEY=$" .env && ! grep -q "^DEPLOYER_PRIVATE_KEY=0x\.\.\.$" .env; then
        echo "  ✓ DEPLOYER_PRIVATE_KEY is set"
    else
        echo "  ✗ DEPLOYER_PRIVATE_KEY not configured in .env"
        ERRORS=$((ERRORS+1))
    fi
    
    if grep -q "^ETHERSCAN_API_KEY=" .env && ! grep -q "^ETHERSCAN_API_KEY=$" .env && ! grep -q "^ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY$" .env; then
        echo "  ✓ ETHERSCAN_API_KEY is set"
    else
        echo "  ⚠ ETHERSCAN_API_KEY not configured (verification will be skipped)"
    fi
else
    echo "✗ .env file not found. Copy .env.example: cp .env.example .env"
    ERRORS=$((ERRORS+1))
fi

if [ -f "networks.toml" ]; then
    echo "✓ networks.toml file exists"
    NETWORK_COUNT=$(grep -c "^\[networks\." networks.toml || echo 0)
    echo "  Configured networks: $NETWORK_COUNT"
else
    echo "✗ networks.toml not found. Copy networks.toml.example: cp networks.toml.example networks.toml"
    ERRORS=$((ERRORS+1))
fi

echo ""

# Check if contracts are built
echo "=== Build Status ==="

if [ -d "out" ] && [ "$(ls -A out 2>/dev/null)" ]; then
    echo "✓ Contracts built (out/ directory exists)"
else
    echo "⚠ Contracts not built yet. Run: just build"
fi

echo ""

# Summary
echo "=== Summary ==="
if [ $ERRORS -eq 0 ]; then
    echo "✓ All checks passed! Ready to deploy."
    echo ""
    echo "Next steps:"
    echo "  1. Configure networks in networks.toml"
    echo "  2. Set DEPLOYER_PRIVATE_KEY in .env"
    echo "  3. Run: just build"
    echo "  4. Run: just deploy-network <network>"
    exit 0
else
    echo "✗ Found $ERRORS error(s). Please fix them before deploying."
    exit 1
fi
