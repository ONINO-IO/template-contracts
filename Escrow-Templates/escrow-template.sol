// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title EscrowService
 * @dev Manages escrow payments with functionalities for payment creation, release, and access control.
 */
contract EscrowService {
    /// @notice Struct to store payment details.
    struct Payment {
        address payer;
        address payee;
        uint256 amount;
        bool isRecurring;
        uint256 releaseTime; // Timestamp when funds can be released.
        bool fundsReleased;
    }

    /// @notice Address of the contract owner.
    address public owner;

    /// @notice Mapping to track authorized operators.
    mapping(address => bool) public authorizedOperators;

    /// @notice Mapping to track payments by their IDs.
    mapping(uint256 => Payment) public payments;

    /// @notice Counter to generate unique payment IDs.
    uint256 public nextPaymentId;

    /// @notice Events for logging various actions.
    event PaymentCreated(uint256 indexed paymentId, address indexed payer, uint256 amount);
    event PaymentReleased(uint256 indexed paymentId, address indexed payee, uint256 amount);
    event OperatorAuthorized(address indexed operator);
    event OperatorRevoked(address indexed operator);

    /**
     * @dev Constructor sets the contract deployer as the owner.
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
     * @param operator Address of the operator to authorize.
     */
    function authorizeOperator(address operator) external onlyOwner {
        require(operator != address(0), "Invalid operator address");
        authorizedOperators[operator] = true;
        emit OperatorAuthorized(operator);
    }

    /**
     * @notice Revokes the authorization of an operator.
     * @param operator Address of the operator to revoke.
     */
    function revokeOperator(address operator) external onlyOwner {
        require(authorizedOperators[operator], "Operator not found");
        authorizedOperators[operator] = false;
        emit OperatorRevoked(operator);
    }

    /**
     * @notice Transfers ownership of the contract to a new address.
     * @param newOwner Address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }

    /**
     * @dev Fallback function to handle receiving Ether directly.
     */
    receive() external payable {
        // Handle received Ether
    }

    /**
     * @notice Withdraws Ether from the contract to the owner's address.
     * @param amount The amount of Ether to withdraw.
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner).transfer(amount);
    }
}
