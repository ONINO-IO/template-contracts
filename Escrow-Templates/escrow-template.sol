// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EscrowService {
    // Struct to store payment details
    struct Payment {
        address payer;
        address payee;
        uint256 amount;
        bool isRecurring;
        uint256 releaseTime; // Timestamp when funds can be released
        bool fundsReleased;
    }

    // Access roles
    address public owner;
    mapping(address => bool) public authorizedOperators;

    // Payment tracking
    mapping(uint256 => Payment) public payments;
    uint256 public nextPaymentId;

    // Events
    event PaymentCreated(uint256 indexed paymentId, address indexed payer, uint256 amount);
    event PaymentReleased(uint256 indexed paymentId, address indexed payee, uint256 amount);
    event OperatorAuthorized(address indexed operator);
    event OperatorRevoked(address indexed operator);

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedOperators[msg.sender], "Not an authorized operator");
        _;
    }

    // Function to create a payment
    function createPayment(address payee, uint256 amount, bool isRecurring, uint256 releaseTime) public payable {
        require(msg.value == amount, "Incorrect payment amount");
        require(payee != address(0), "Invalid payee address");
        require(amount > 0, "Amount must be greater than zero");

        uint256 paymentId = nextPaymentId++;
        payments[paymentId] = Payment(msg.sender, payee, amount, isRecurring, releaseTime, false);
        emit PaymentCreated(paymentId, msg.sender, amount);
    }

    // Function to release payment to payee
    function releasePayment(uint256 paymentId) public onlyAuthorized {
        Payment storage payment = payments[paymentId];
        require(!payment.fundsReleased, "Funds already released");
        require(block.timestamp >= payment.releaseTime, "Release time not reached");
        
        payment.fundsReleased = true;
        payable(payment.payee).transfer(payment.amount);
        emit PaymentReleased(paymentId, payment.payee, payment.amount);

        if (payment.isRecurring) {
            // Checking for overflow is not necessary in Solidity ^0.8.0
            payment.releaseTime += 30 days; // Adjust for next release if recurring
            payment.fundsReleased = false;
        } else {
            delete payments[paymentId];
        }
    }

    // Access control functions
    function authorizeOperator(address operator) public onlyOwner {
        require(operator != address(0), "Invalid operator address");
        authorizedOperators[operator] = true;
        emit OperatorAuthorized(operator);
    }

    function revokeOperator(address operator) public onlyOwner {
        require(authorizedOperators[operator], "Operator not found");
        authorizedOperators[operator] = false;
        emit OperatorRevoked(operator);
    }

    // Function to transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }

    // Fallback function to handle receiving Ether directly
    receive() external payable {
        // Handle received Ether
    }

    // Optionally: add a function to upgrade contract
    // Note: Implementing upgradeable contracts requires careful consideration of proxy patterns
}