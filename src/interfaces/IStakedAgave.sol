// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

interface IStakedAgave {
  function stake(address to, uint256 amount) external;

  function redeem(address to, uint256 amount) external;

  function cooldown() external;

  function claimRewards(address to, uint256 amount) external;

  function getTotalRewardsBalance(address user) external returns(uint256);
  function stakersCooldowns(address user) external view returns(uint256);

  // Variables
  function COOLDOWN_SECONDS() external returns(uint256);
  function UNSTAKE_WINDOW() external returns(uint256);
  function DISTRIBUTION_END() external returns(uint256);
  function STAKED_TOKEN() external returns(address);
  function REWARD_TOKEN() external returns(address);
  function REWARDS_VAULT() external returns(address);
  function EMISSION_MANAGER() external returns(address);
}
