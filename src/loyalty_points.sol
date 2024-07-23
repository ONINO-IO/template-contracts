// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title LoyaltyPoints
 * @dev Manages loyalty points for customers in a rewards system. This contract allows the owner to register users, award points, and users to redeem their points.
 */
contract LoyaltyPoints {
    /// @notice Owner of the contract
    address public owner;

    /// @notice Struct to hold user details and their loyalty points
    struct User {
        uint256 points;        /// @notice The number of loyalty points the user has.
        bool isRegistered;     /// @notice Indicates if the user is registered in the system.
    }

    /// @notice Mapping to keep track of users and their points
    mapping(address => User) public users;

    /// @notice Event emitted when points are awarded
    /// @param user The address of the user who is awarded points
    /// @param points The number of points awarded
    event PointsAwarded(address indexed user, uint256 points);

    /// @notice Event emitted when points are redeemed
    /// @param user The address of the user who redeems points
    /// @param points The number of points redeemed
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
     * @dev Only the owner can register a new user. The user must not already be registered.
     * @param userAddress The address of the user to register.
     */
    function registerUser(address userAddress) external onlyOwner {
        require(!users[userAddress].isRegistered, "User already registered.");
        users[userAddress].isRegistered = true;
    }

    /**
     * @notice Awards points to a registered user.
     * @dev Only the owner can award points to a user. The user must be registered in the system.
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
     * @dev The caller must be a registered user and must have enough points to redeem.
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
     * @dev Returns the number of points the user has. The user must be registered in the system.
     * @param userAddress The address of the user to check.
     * @return The number of points the user has.
     */
    function checkPoints(address userAddress) external view returns (uint256) {
        require(users[userAddress].isRegistered, "User not registered.");
        return users[userAddress].points;
    }

    /**
     * @notice Transfers ownership of the contract to a new address.
     * @dev Only the owner can transfer ownership. The new owner's address must be valid (non-zero).
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address.");
        owner = newOwner;
    }
}
