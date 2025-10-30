// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.30;

interface ICETFactory {
    error DeploymentFailed();

    function computeSalt(address l1Asset, uint256 remoteChainID) external pure returns (bytes32);
    function predictAddress(
        address l1Asset,
        uint256 remoteChainID,
        uint8 decimals,
        string memory name,
        string memory symbol,
        address bridge
    ) external view returns (address);
    function deployIfAbsent(
        address l1Asset,
        uint256 remoteChainID,
        uint8 decimals,
        string calldata name,
        string calldata symbol,
        address bridge
    ) external returns (address deployed);
}