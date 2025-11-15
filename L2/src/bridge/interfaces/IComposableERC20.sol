// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC7802 } from "@openzeppelin/contracts/interfaces/draft-IERC7802.sol";

interface IComposableERC20 {
    /// @notice Storage struct for the BridgedComposeTokenERC20 metadata.
    struct BridgedComposeTokenERC20Metadata {
        /// @notice The ChainID where this token was originally minted.
        uint256 remoteChainID;
        /// @notice Address of the corresponding version of this token on the remote chain.
        address remoteAsset;
        /// @notice Name of the token
        string name;
        /// @notice Symbol of the token
        string symbol;
        /// @notice Decimals of the token
        uint8 decimals;
    }

    error Unauthorized();
    error AlreadyInitialized();

    function crosschainMint(address _to, uint256 _amount) external;
    function crosschainBurn(address _to, uint256 _amount) external;
    function metadata() external view returns (BridgedComposeTokenERC20Metadata memory);
    /// @notice Returns the remote chain ID where this token was originally minted.
    function getRemoteChainID() external view returns (uint256);

    /// @notice Returns the remote asset address corresponding to this token on the remote chain.
    function getRemoteAsset() external view returns (address);
}