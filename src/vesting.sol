// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TokenVesting
 * @dev Contract for handling token vesting. Manages vesting schedules for beneficiaries, allowing for timed releases of tokens.
 */
contract TokenVesting {
    /// @notice Defines the structure of a vesting schedule for a beneficiary.
    struct VestingSchedule {
        uint256 start;      /// @notice Time when vesting starts.
        uint256 cliff;      /// @notice Duration after which the first portion of tokens can be released.
        uint256 duration;   /// @notice Total duration of the vesting period.
        uint256 amount;     /// @notice Total amount of tokens to be vested.
        uint256 released;   /// @notice Amount of tokens already released.
        bool isBlocked;     /// @notice Flag indicating if withdrawals are blocked.
    }

    /// @notice Owner of the contract (usually the deployer).
    address public owner;

    /// @notice Mapping from token address to beneficiary to their vesting schedule.
    mapping(address => mapping(address => VestingSchedule)) public vestingSchedules;

    /// @notice Constants for default vesting cliff and duration.
    uint256 private constant DEFAULT_CLIFF = 365 days;
    uint256 private constant DEFAULT_DURATION = 4 * 365 days;

    /// @notice Events to log contract activities.
    event VestingAdded(address indexed token, address indexed beneficiary, uint256 amount, uint256 start, uint256 cliff, uint256 duration);
    event Released(address indexed token, address indexed beneficiary, uint256 amount);
    event WithdrawalBlocked(address indexed token, address indexed beneficiary);
    event WithdrawalUnblocked(address indexed token, address indexed beneficiary);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Modifier to restrict function calls to the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /**
     * @dev Constructor sets the deployer as the owner.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Deposits tokens into the vesting contract for a beneficiary.
     * @dev Only the owner can call this function. Tokens are transferred from the owner to the contract.
     * @param tokenAddress The address of the ERC20 token.
     * @param beneficiary The address of the beneficiary.
     * @param amount The amount of tokens to be vested.
     */
    function depositTokens(address tokenAddress, address beneficiary, uint256 amount) public onlyOwner {
        require(beneficiary != address(0), "Beneficiary cannot be the zero address");
        require(amount > 0, "Amount should be greater than zero");

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(msg.sender) >= amount, "Insufficient token balance");
        require(vestingSchedules[tokenAddress][beneficiary].amount == 0, "Vesting schedule already exists for beneficiary and token");

        require(token.transferFrom(owner, address(this), amount), "Token transfer failed");

        uint256 startTime = block.timestamp;
        vestingSchedules[tokenAddress][beneficiary] = VestingSchedule(startTime, DEFAULT_CLIFF, DEFAULT_DURATION, amount, 0, false);

        emit VestingAdded(tokenAddress, beneficiary, amount, startTime, DEFAULT_CLIFF, DEFAULT_DURATION);
    }

    /**
     * @notice Blocks the withdrawal of vested tokens for a specific beneficiary.
     * @dev Only the owner can call this function.
     * @param tokenAddress The address of the ERC20 token.
     * @param beneficiary The address of the beneficiary.
     */
    function blockWithdrawal(address tokenAddress, address beneficiary) public onlyOwner {
        require(vestingSchedules[tokenAddress][beneficiary].amount > 0, "Beneficiary does not have a vesting schedule");
        vestingSchedules[tokenAddress][beneficiary].isBlocked = true;
        emit WithdrawalBlocked(tokenAddress, beneficiary);
    }

    /**
     * @notice Unblocks the withdrawal of vested tokens for a specific beneficiary.
     * @dev Only the owner can call this function.
     * @param tokenAddress The address of the ERC20 token.
     * @param beneficiary The address of the beneficiary.
     */
    function unblockWithdrawal(address tokenAddress, address beneficiary) public onlyOwner {
        require(vestingSchedules[tokenAddress][beneficiary].amount > 0, "Beneficiary does not have a vesting schedule");
        vestingSchedules[tokenAddress][beneficiary].isBlocked = false;
        emit WithdrawalUnblocked(tokenAddress, beneficiary);
    }

    /**
     * @notice Releases vested tokens for a beneficiary.
     * @dev Beneficiaries can call this function to release their vested tokens.
     * @param tokenAddress The address of the ERC20 token.
     * @param beneficiary The address of the beneficiary.
     */
    function release(address tokenAddress, address beneficiary) public {
        VestingSchedule storage schedule = vestingSchedules[tokenAddress][beneficiary];
        require(schedule.amount > 0, "No vesting schedule found");
        require(!schedule.isBlocked, "Withdrawal is blocked for this beneficiary");

        uint256 unreleased = releasableAmount(tokenAddress, beneficiary);
        require(unreleased > 0, "No tokens are due for release");

        schedule.released += unreleased;
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(beneficiary, unreleased), "Token transfer failed");

        emit Released(tokenAddress, beneficiary, unreleased);
    }

    /**
     * @notice Calculates the amount of tokens that can be released to a beneficiary.
     * @dev This function considers the current time, vesting schedule, and already released tokens.
     * @param tokenAddress The address of the ERC20 token.
     * @param beneficiary The address of the beneficiary.
     * @return The amount of tokens that can be released.
     */
    function releasableAmount(address tokenAddress, address beneficiary) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[tokenAddress][beneficiary];

        if (block.timestamp < schedule.start + schedule.cliff) {
            return 0;
        } else if (block.timestamp >= schedule.start + schedule.cliff + schedule.duration) {
            return schedule.amount - schedule.released;
        } else {
            uint256 vestedAmount = (schedule.amount * (block.timestamp - schedule.start)) / schedule.duration;
            return vestedAmount - schedule.released;
        }
    }

    /**
     * @notice Transfers ownership of the contract to a new owner.
     * @dev Only the current owner can call this function.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
