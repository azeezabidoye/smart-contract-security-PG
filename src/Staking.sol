// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "forge-std/Test.sol";

contract Staking {
    // we want to stake eth and erc20?
    // stake unstake/withdraw
    // min stake
    // stake eth get eth, stake token get token
    // we will need to create a function to add claimable rewards

    IERC20 public stakeToken;
    uint256 public stakeEndTime;
    uint256 public totalStakedEth;
    uint256 public totalTokenStaked;
    uint256 public ethRewardAvailable;
    uint256 public tokenRewardAvailable;
    uint256 public minStakeAmt = 1e4;
    uint256 public constant BASIS_POINT = 1e4;
    uint256 public constant DURATION = 20 days;
    uint256 public rewardRate;
    address public owner;
    uint256 public startTime;

    struct ethStakeInfo {
        bool hasStaked;
        uint256 amountStaked;
        uint256 lastStakeTime;
        bool withdrawn;
    }

    struct erc20StakeInfo {
        bool hasStaked;
        uint256 amountStaked;
        uint256 lastStakeTime;
        bool withdrawn;
    }

    mapping(address => ethStakeInfo) public userEthStakeInfo;
    mapping(address => erc20StakeInfo) public userTokenStakeInfo;

    error InvalidAmount();
    error AlreadyStaked();
    error StakeNotEnded();
    error AlreadyWithdrawn();
    error WithdrawalFailed();
    error NotOwner();

    event Staked(address user, uint256 _amount, uint256 time, bool isEthStake);
    event Unstaked(address user, uint256 _amount, bool isEth);

    constructor(IERC20 _stakeToken) payable {
        stakeToken = _stakeToken;
        ethRewardAvailable = msg.value;
        startTime = block.timestamp;
        stakeEndTime = startTime + DURATION;
        owner = msg.sender;
    }

    function addTokenRewards(uint256 _amount) external {
        require(msg.sender == owner, NotOwner());
        tokenRewardAvailable = _amount;
        stakeToken.transferFrom(msg.sender, address(this), _amount);
    }

    function stakeEth() external payable {
        require(msg.value >= minStakeAmt, InvalidAmount());
        ethStakeInfo storage _stake = userEthStakeInfo[msg.sender];
        require(!_stake.hasStaked, AlreadyStaked());
        _stake.hasStaked = true;
        _stake.amountStaked += msg.value;
        _stake.lastStakeTime = block.timestamp;
        totalStakedEth += msg.value;

        emit Staked(msg.sender, msg.value, block.timestamp, true);
    }

    function stakeErc20(uint256 _amount) external payable {
        require(_amount >= minStakeAmt, InvalidAmount());
        stakeToken.transferFrom(msg.sender, address(this), _amount);
        erc20StakeInfo storage _stake = userTokenStakeInfo[msg.sender];
        require(!_stake.hasStaked, AlreadyStaked());
        _stake.hasStaked = true;
        _stake.amountStaked += _amount;
        _stake.lastStakeTime = block.timestamp;
        totalTokenStaked += _amount;

        emit Staked(msg.sender, _amount, block.timestamp, false);
    }

    function unstake(bool isEth) external {
        require(block.timestamp > stakeEndTime, StakeNotEnded());
        uint256 _reward;
        uint256 withdrawn;
        if (isEth) {
            ethStakeInfo storage _stake = userEthStakeInfo[msg.sender];
            uint256 _amount = _stake.amountStaked;
            require(_amount >= 0, InvalidAmount());
            require(!_stake.withdrawn, AlreadyWithdrawn());
            _stake.withdrawn = true;
            _reward = _caluculateRewardClaimable(_amount, true);
            withdrawn = _reward + _amount;
            (bool s, ) = msg.sender.call{value: withdrawn}("");
            require(s, WithdrawalFailed());

            emit Unstaked(msg.sender, withdrawn, true);
        } else {
            erc20StakeInfo storage _stake = userTokenStakeInfo[msg.sender];
            uint256 _amount = _stake.amountStaked;
            require(_amount >= 0, InvalidAmount());
            require(!_stake.withdrawn, AlreadyWithdrawn());
            _stake.withdrawn = true;
            _reward = _caluculateRewardClaimable(_amount, false);
            withdrawn = _reward + _amount;
            require(
                stakeToken.transfer(msg.sender, withdrawn),
                WithdrawalFailed()
            );

            emit Unstaked(msg.sender, withdrawn, false);
        }
    }

    function _caluculateRewardClaimable(
        uint256 _amount,
        bool isEth
    ) internal view returns (uint256 reward) {
        uint256 _userStakeDuration;
        uint256 _userShares;
        if (isEth) {
            ethStakeInfo storage _stake = userEthStakeInfo[msg.sender];
            _userStakeDuration = stakeEndTime - _stake.lastStakeTime;
            _userShares =
                (_userStakeDuration * _stake.amountStaked) /
                (totalStakedEth * DURATION);
            reward = _userShares * ethRewardAvailable;
        } else {
            erc20StakeInfo storage _stake = userTokenStakeInfo[msg.sender];
            _userStakeDuration = stakeEndTime - _stake.lastStakeTime;
            _userShares =
                ((_userStakeDuration * _stake.amountStaked) /
                    totalTokenStaked) *
                DURATION;
            reward = _userShares * tokenRewardAvailable;
        }
    }
}
