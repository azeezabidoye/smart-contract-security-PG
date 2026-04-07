// deploy with 10 ether with an owner address, and try to drain the contrect.
// Note you must not prank owner or the contract. Goodluck

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VulnerableVault {
    mapping(address => uint256) public balances;
    uint256 public totalDeposits;

    constructor() payable {}

    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");
    }

    /// @notice Bonus: deposit on behalf of two users, splitting evenly
    function splitDeposit(address userA, address userB) external payable {
        require(msg.value > 0, "Must send ETH");
        uint256 half = msg.value / 2;
        uint256 bonus = (half * 3) / 100; // 3% "loyalty bonus"

        unchecked {
            balances[userA] += half + bonus;
            balances[userB] += half + bonus;
            totalDeposits += msg.value + bonus + bonus;
        }
    }

    receive() external payable {}
}
