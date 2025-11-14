# Compose L1 Settlement Tests

## Overview

Test suite for Compose shared L1 settlement infrastructure.

## Test Structure

```
test/
├── ComposeAnchorStateRegistry.t.sol  - ASR unit tests
├── ComposeDisputeGame.t.sol          - Dispute game unit tests  
├── ComposeETHLockbox.t.sol           - ETHLockbox unit tests
├── scripts/
│   └── DeploySharedInfra.t.sol       - Deployment script integration tests
├── setup/
│   ├── ComposeSetup.sol              - Base test setup (deploys infrastructure)
│   └── ComposeCommonTest.sol         - Common test utilities
└── mock/
    └── MockVerifier.sol              - Mock SP1 verifier for tests

## Running Tests

### All Tests
```bash
# Set up test config
cp networks.test.toml networks.toml

# Run all tests
NETWORK_NAME=test forge test

# With verbose output
NETWORK_NAME=test forge test -vv
```

### Specific Test Files
```bash
NETWORK_NAME=test forge test --match-path "test/ComposeETHLockbox.t.sol"
```

### Specific Test Functions
```bash
NETWORK_NAME=test forge test --match-test "test_lockETH_success"
```

## Test Configuration

Tests use `networks.test.toml` which configures all roles to use the same test deployer address for simplicity.

## Writing New Tests

1. Inherit from `ComposeCommonTest`
2. Override `setUp()` if needed (call `super.setUp()` first)
3. Use inherited contract references (e.g., `composeETHLockbox`)
4. Use test actor addresses (e.g., `guardian`, `alice`, `bob`)

Example:
```solidity
contract MyNewTest is ComposeCommonTest {
    function setUp() public override {
        super.setUp(); // Deploys all infrastructure
        // Your additional setup
    }
    
    function test_myFeature() public {
        // Use composeETHLockbox, alice, bob, etc.
    }
}
```

## Known Issues

- Tests require `NETWORK_NAME=test` environment variable
- `networks.toml` must exist with valid test configuration
