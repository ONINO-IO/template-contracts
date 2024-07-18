// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LoyaltyPoints
 * This contract manages loyalty points for customers in a rewards system.
 */
contract LoyaltyPoints {
    // Define the owner of the contract
    address public owner;

    // Define a struct to hold user details and their loyalty points
    struct User {
        uint256 points;
        bool isRegistered;
    }

    // State variable to keep track of users and their points
    mapping(address => User) public users;

    // Event to be emitted when points are awarded or redeemed
    event PointsAwarded(address indexed user, uint256 points);
    event PointsRedeemed(address indexed user, uint256 points);

    // Modifier to check if the caller is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    // Constructor to set the contract deployer as the owner
    constructor() {
        owner = msg.sender;
    }

    // Function to register a new user
    function registerUser(address userAddress) public onlyOwner {
        require(!users[userAddress].isRegistered, "User already registered.");
        users[userAddress].isRegistered = true;
    }

    // Function to award points to a user
    function awardPoints(address userAddress, uint256 points) public onlyOwner {
        require(users[userAddress].isRegistered, "User not registered.");
        users[userAddress].points += points;
        emit PointsAwarded(userAddress, points);
    }

    // Function for a user to redeem their points
    function redeemPoints(uint256 points) public {
        require(users[msg.sender].isRegistered, "User not registered.");
        require(users[msg.sender].points >= points, "Insufficient points.");
        users[msg.sender].points -= points;
        emit PointsRedeemed(msg.sender, points);
    }

    // Function to check the points balance of a user
    function checkPoints(address userAddress) public view returns (uint256) {
        require(users[userAddress].isRegistered, "User not registered.");
        return users[userAddress].points;
    }
}