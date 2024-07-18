// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title LoyaltyPoints
 * @dev Manages loyalty points for customers in a rewards system.
 */
contract LoyaltyPoints {
    /// @notice Owner of the contract
    address public owner;

    /// @notice Struct to hold user details and their loyalty points
    struct User {
        uint256 points;
        bool isRegistered;
    }

    /// @notice Mapping to keep track of users and their points
    mapping(address => User) public users;

    /// @notice Event emitted when points are awarded
    event PointsAwarded(address indexed user, uint256 points);

    /// @notice Event emitted when points are redeemed
    event PointsRedeemed(address indexed user, uint256 points);

    /// @dev Modifier to check if the caller is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets the deployer as the initial owner of the contract.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Registers a new user.
     * @param userAddress The address of the user to register.
     */
    function registerUser(address userAddress) external onlyOwner {
        require(!users[userAddress].isRegistered, "User already registered.");
        users[userAddress].isRegistered = true;
    }

    /**
     * @notice Awards points to a registered user.
     * @param userAddress The address of the user to award points to.
     * @param points The number of points to award.
     */
    function awardPoints(address userAddress, uint256 points) external onlyOwner {
        require(users[userAddress].isRegistered, "User not registered.");
        users[userAddress].points += points;
        emit PointsAwarded(userAddress, points);
    }

    /**
     * @notice Redeems points for the caller.
     * @param points The number of points to redeem.
     */
    function redeemPoints(uint256 points) external {
        require(users[msg.sender].isRegistered, "User not registered.");
        require(users[msg.sender].points >= points, "Insufficient points.");
        users[msg.sender].points -= points;
        emit PointsRedeemed(msg.sender, points);
    }

    /**
     * @notice Checks the points balance of a user.
     * @param userAddress The address of the user to check.
     * @return The number of points the user has.
     */
    function checkPoints(address userAddress) external view returns (uint256) {
        require(users[userAddress].isRegistered, "User not registered.");
        return users[userAddress].points;
    }

    /**
     * @notice Transfers ownership of the contract to a new address.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address.");
        owner = newOwner;
    }
}
