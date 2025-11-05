# Third-Party Licenses

This project incorporates code from several open-source projects. We are grateful to the authors and maintainers of these libraries.

## Dependencies

### Foundry Forge Standard Library
- **Repository**: [foundry-rs/forge-std](https://github.com/foundry-rs/forge-std)
- **License**: MIT License / Apache-2.0
- **Usage**: Testing and scripting utilities
- **Description**: Forge Standard Library is the preferred testing library for Foundry projects

### OpenZeppelin Contracts
- **Repository**: [OpenZeppelin/openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
- **License**: MIT License
- **Usage**: Core contract implementations (ERC20, proxy patterns, security utilities)
- **Description**: Industry-standard library for secure smart contract development

### OpenZeppelin Contracts Upgradeable
- **Repository**: [OpenZeppelin/openzeppelin-contracts-upgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable)
- **License**: MIT License
- **Usage**: Upgradeable contract implementations
- **Description**: Upgradeable variant of OpenZeppelin contracts for proxy patterns

### Optimism Monorepo
- **Repository**: [ethereum-optimism/optimism](https://github.com/ethereum-optimism/optimism)
- **License**: MIT License
- **Copyright**: 2020-2025 Optimism
- **Branch**: op-deployer/v0.4.5
- **Usage**: L1 settlement contracts, dispute game interfaces, and core types
- **Description**: Optimism's Layer 2 scaling solution contracts and infrastructure

### Solady
- **Repository**: [Vectorized/solady](https://github.com/Vectorized/solady)
- **License**: MIT License
- **Copyright**: © 2022 Solady
- **Usage**: Gas-optimized utilities (Clone pattern)
- **Description**: Optimized Solidity snippets and utilities

### SP1 Contracts
- **Repository**: [zobront/sp1-contracts](https://github.com/zobront/sp1-contracts)
- **License**: MIT License
- **Usage**: SP1 zero-knowledge proof verifier interfaces
- **Description**: Contracts for SP1 zkVM proof verification
- **Note**: Verified via SPDX headers in contract files

### Lib-Keccak
- **Repository**: [ethereum-optimism/lib-keccak](https://github.com/ethereum-optimism/lib-keccak)
- **License**: MIT License
- **Copyright**: © 2023 clabby
- **Usage**: Keccak cryptographic functions
- **Description**: Optimized Keccak hash function implementations

---

## License Compatibility

All third-party dependencies listed above are under permissive licenses (MIT or Apache-2.0), which are compatible with our GPL-3.0-or-later license. This means:

- ✅ We can use these libraries in our GPL-3.0-or-later licensed code
- ✅ Derivative works must be licensed under GPL-3.0-or-later
- ✅ All original library copyright notices are preserved in their respective directories

## Verification

To verify the licenses of the dependencies:

```bash
# Initialize submodules
git submodule update --init --recursive

# Check individual licenses
cat L1-settlement/lib/forge-std/LICENSE
cat L1-settlement/lib/openzeppelin-contracts/LICENSE.md
cat L1-settlement/lib/openzeppelin-contracts-upgradeable/LICENSE.md
cat L1-settlement/lib/optimism/LICENSE
cat L1-settlement/lib/solady/LICENSE
cat L1-settlement/lib/sp1-contracts/contracts/src/ISP1Verifier.sol  # Check SPDX header
cat L1-settlement/lib/lib-keccak/LICENSE.md
```

## Attribution

When redistributing this software, please ensure:
1. This THIRD_PARTY_LICENSES.md file is included
2. The main LICENSE file (GPL-3.0) is included
3. All copyright notices in dependency directories remain intact

## Questions

If you have questions about licensing or need clarification on any third-party dependency, please open an issue on our GitHub repository.

---

## Verification Status

✅ **All licenses verified** - November 5, 2024

All dependencies have been initialized and their licenses confirmed from actual LICENSE files in the repository submodules.
