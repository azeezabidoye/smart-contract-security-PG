// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/staking.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20("USDC", "USDC") {
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}

contract StakingTest is Test {
    Staking public staking;
    MockERC20 public stakeToken;

    address owner = makeAddr("owner");
    address alice = makeAddr("alice");

    function setUp() public {
        vm.warp(1775586192);
        stakeToken = new MockERC20();
        deal(address(stakeToken), owner, 20000e6);
        deal(owner, 5 ether);
        deal(alice, 5 ether);
        deal(address(stakeToken), alice, 5000e6);

        vm.startPrank(owner);
        staking = new Staking{value: 5 ether}(IERC20(address(stakeToken)));

        assertEq(address(staking.stakeToken()), address(stakeToken));
        assertEq(staking.ethRewardAvailable(), 5 ether);
        assertEq(staking.owner(), owner);

        stakeToken.approve(address(staking), type(uint256).max);
        staking.addTokenRewards(20000e6);
        assertEq(stakeToken.balanceOf(address(staking)), 20000e6);
    }

    function test_onlyOwner_can_add_token_rewards() public {
        deal(address(stakeToken), alice, 1e18);
        vm.startPrank(alice);
        stakeToken.approve(address(staking), 1e18);
        vm.expectRevert(Staking.NotOwner.selector);
        staking.addTokenRewards(1e6);

    }

    function test_stakeETH_success() public {
        vm.startPrank(alice);
        // alice attempts to stake less than min stake
        vm.expectRevert(Staking.InvalidAmount.selector);
        staking.stakeEth();

        staking.stakeEth{value: 1 ether}();

        Staking.ethStakeInfo memory stake;
        (, stake.amountStaked,,) = staking.userEthStakeInfo(alice);
        assertEq(stake.amountStaked, 1 ether);
        
        // assume alice tries to stake again
       vm.expectRevert(Staking.AlreadyStaked.selector);
       staking.stakeEth{value: 1 ether}();
    }

    function test_stakeETH_success_fuzz(uint256 _amount) public {
        vm.startPrank(alice);
        // vm.assume(_amount > 1e4);
        _amount = bound(_amount, 1e5, type(uint64).max - 1e18);
        deal(alice, _amount);

        staking.stakeEth{value: _amount}();
    }

    function test_unstake_eth() public {
        test_stakeETH_success();
        vm.expectRevert(Staking.StakeNotEnded.selector);
        staking.unstake(true);
`
        vm.warp(staking.stakeEndTime() + 1);
        // skip(10 days);
        staking.unstake(true);

    }


}