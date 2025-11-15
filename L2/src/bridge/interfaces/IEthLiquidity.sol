// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.30;

interface IEthLiquidity {
    function burn() external payable;
    function mint(uint256 amount) external payable;
}