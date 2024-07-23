// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title EscrowService
 * @dev Manages escrow payments with functionalities for payment creation, release, and access control.
 * This contract allows the creation of escrow payments which can be released after a specified release time.
 * The owner can authorize operators to manage payments.
 */
contract EscrowService {
    /// @notice Struct to store payment details.
    struct Payment {
        address payer;       /// @notice Address of the payer.
        address payee;       /// @notice Address of the payee.
        uint256 amount;      /// @notice Amount of the payment in wei.
        bool isRecurring;    /// @notice Indicates if the payment is recurring.
        uint256 releaseTime; /// @notice Timestamp when funds can be released.
        bool fundsReleased;  /// @notice Indicates if the funds have been released.
    }

    /// @notice Address of the contract owner.
    address public owner;

    /// @notice Mapping to track authorized operators.
    mapping(address => bool) public authorizedOperators;

    /// @notice Mapping to track payments by their IDs.
    mapping(uint256 => Payment) public payments;

    /// @notice Counter to generate unique payment IDs.
    uint256 public nextPaymentId;

    /// @notice Event emitted when a new payment is created.
    /// @param paymentId The ID of the created payment.
    /// @param payer The address of the payer.
    /// @param amount The amount of the payment in wei.
    event PaymentCreated(uint256 indexed paymentId, address indexed payer, uint256 amount);

    /// @notice Event emitted when a payment is released.
    /// @param paymentId The ID of the released payment.
    /// @param payee The address of the payee.
    /// @param amount The amount of the released payment in wei.
    event PaymentReleased(uint256 indexed paymentId, address indexed payee, uint256 amount);

    /// @notice Event emitted when an operator is authorized.
    /// @param operator The address of the authorized operator.
    event OperatorAuthorized(address indexed operator);

    /// @notice Event emitted when an operator's authorization is revoked.
    /// @param operator The address of the revoked operator.
    event OperatorRevoked(address indexed operator);

    /**
     * @dev Constructor sets the contract deployer as the owner.
     * The deployer of the contract is assigned as the initial owner.
     */
    constructor() {
        owner = msg.sender;
    }

    /// @dev Modifier to restrict functions to only the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    /// @dev Modifier to restrict functions to authorized operators.
    modifier onlyAuthorized() {
        require(authorizedOperators[msg.sender], "Not an authorized operator");
        _;
    }

    /**
     * @notice Creates a new payment.
     * @dev The caller must send the exact amount specified in the `amount` parameter as `msg.value`.
     * @param payee Address of the payee.
     * @param amount Amount of the payment in wei.
     * @param isRecurring Whether the payment is recurring.
     * @param releaseTime Timestamp when the funds can be released.
     */
    function createPayment(address payee, uint256 amount, bool isRecurring, uint256 releaseTime) external payable {
        require(msg.value == amount, "Incorrect payment amount");
        require(payee != address(0), "Invalid payee address");
        require(amount > 0, "Amount must be greater than zero");

        uint256 paymentId = nextPaymentId++;
        payments[paymentId] = Payment({
            payer: msg.sender,
            payee: payee,
            amount: amount,
            isRecurring: isRecurring,
            releaseTime: releaseTime,
            fundsReleased: false
        });
        emit PaymentCreated(paymentId, msg.sender, amount);
    }

    /**
     * @notice Releases the payment to the payee.
     * @dev Only authorized operators can release payments. The payment must not have been released before and the current time must be past the release time.
     * @param paymentId ID of the payment to be released.
     */
    function releasePayment(uint256 paymentId) external onlyAuthorized {
        Payment storage payment = payments[paymentId];
        require(!payment.fundsReleased, "Funds already released");
        require(block.timestamp >= payment.releaseTime, "Release time not reached");

        payment.fundsReleased = true;
        payable(payment.payee).transfer(payment.amount);
        emit PaymentReleased(paymentId, payment.payee, payment.amount);

        if (payment.isRecurring) {
            payment.releaseTime += 30 days; // Adjust for next release if recurring.
            payment.fundsReleased = false;
        } else {
            delete payments[paymentId];
        }
    }

    /**
     * @notice Authorizes an operator to manage payments.
     * @dev Only the owner can authorize operators. The operator address must be valid (non-zero).
     * @param operator Address of the operator to authorize.
     */
    function authorizeOperator(address operator) external onlyOwner {
        require(operator != address(0), "Invalid operator address");
        authorizedOperators[operator] = true;
        emit OperatorAuthorized(operator);
    }

    /**
     * @notice Revokes the authorization of an operator.
     * @dev Only the owner can revoke operator authorization. The operator must be currently authorized.
     * @param operator Address of the operator to revoke.
     */
    function revokeOperator(address operator) external onlyOwner {
        require(authorizedOperators[operator], "Operator not found");
        authorizedOperators[operator] = false;
        emit OperatorRevoked(operator);
    }

    /**
     * @notice Transfers ownership of the contract to a new address.
     * @dev Only the current owner can transfer ownership. The new owner's address must be valid (non-zero).
     * @param newOwner Address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }

    /**
     * @dev Fallback function to handle receiving Ether directly.
     * Allows the contract to receive Ether directly.
     */
    receive() external payable {
        // Handle received Ether
    }

    /**
     * @notice Withdraws Ether from the contract to the owner's address.
     * @dev Only the owner can withdraw Ether. The contract must have a sufficient balance.
     * @param amount The amount of Ether to withdraw.
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner).transfer(amount);
    }
}
