// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.30;

contract EthLiquidityMock {
    function burn() external payable {
        address(0).call{ value: msg.value }("");
    }
    function mint(uint256 amount) external payable {
        msg.sender.call{ value: amount }("");
    }
}