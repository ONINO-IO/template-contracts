// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title IERC20 Interface
/// @dev Interface for interacting with ERC20 tokens
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title SimpleDAO
 * @dev Basic Decentralized Autonomous Organization (DAO) template with proposal creation, voting, and execution functionality.
 * This contract allows members to create proposals, vote on them, and execute them if they pass.
 * Membership and voting rights are determined by holding a minimum balance of a specified ERC20 token.
 */
contract SimpleDAO {
    /// @notice ERC20 token used for voting and membership
    IERC20 public votingToken;

    /// @notice Minimum balance required for voting eligibility
    uint256 public minBalanceForVoting;

    /// @notice Indicates if the contract has been initialized
    bool private initialized;

    /// @notice Structure to hold proposal details
    struct Proposal {
        string description;  /// @notice Description of the proposal
        uint256 deadline;    /// @notice Deadline for voting on the proposal
        bool executed;       /// @notice Indicates if the proposal has been executed
        int256 votes;        /// @notice Net votes received by the proposal
        mapping(address => bool) voted;  /// @notice Tracks whether an address has voted
    }

    /// @notice Mapping of proposals by their IDs
    mapping(uint256 => Proposal) public proposals;

    /// @notice Counter to track the next proposal ID
    uint256 public nextProposalId;

    /// @notice Balance of the DAO's treasury
    uint256 public treasuryBalance;

    /// @notice Event emitted when a new proposal is created
    /// @param proposalId The unique ID of the newly created proposal
    /// @param description The description of the newly created proposal
    /// @param deadline The deadline timestamp for voting on the proposal
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 deadline);

    /// @notice Event emitted when a vote is cast on a proposal
    /// @param proposalId The ID of the proposal that was voted on
    /// @param voter The address of the voter
    /// @param vote The vote cast (true for 'yes', false for 'no')
    event Voted(uint256 indexed proposalId, address indexed voter, bool vote);

    /// @notice Event emitted when a proposal is executed
    /// @param proposalId The ID of the executed proposal
    /// @param executed Indicates if the proposal was executed successfully
    event ProposalExecuted(uint256 indexed proposalId, bool executed);

    /// @dev Modifier to ensure initialization happens only once
    modifier onlyOnce() {
        require(!initialized, "Already initialized");
        _;
        initialized = true;
    }

    /// @dev Modifier to restrict functions to members only, with a minimum balance requirement
    modifier onlyMember() {
        require(votingToken.balanceOf(msg.sender) >= minBalanceForVoting, "Insufficient balance for voting");
        _;
    }

    /**
     * @dev Constructor sets the contract deployer as the owner (if needed)
     */
    constructor() {
        // Initial setup, if necessary
    }

    /**
     * @notice Initializes the DAO with the voting token and minimum balance for voting
     * @dev Can only be called once. Sets the ERC20 token used for voting and the minimum balance required to vote.
     * @param tokenAddress Address of the ERC20 token used for voting
     * @param minBalance Minimum token balance required to be eligible for voting
     */
    function initialize(address tokenAddress, uint256 minBalance) external onlyOnce {
        votingToken = IERC20(tokenAddress);
        minBalanceForVoting = minBalance;
    }

    /**
     * @notice Creates a new proposal
     * @dev Only members with the minimum balance can create a proposal. The proposal is assigned a unique ID and a deadline is set.
     * @param description Description of the proposal
     */
    function createProposal(string memory description) external onlyMember {
        Proposal storage proposal = proposals[nextProposalId];
        proposal.description = description;
        proposal.deadline = block.timestamp + 7 days; // 1 week duration

        emit ProposalCreated(nextProposalId, description, proposal.deadline);
        nextProposalId++;
    }

    /**
     * @notice Lists all proposal descriptions
     * @dev Returns an array of all proposal descriptions. Useful for clients to fetch and display all proposals.
     * @return descriptions Array of proposal descriptions
     */
    function listProposalDescriptions() external view returns (string[] memory descriptions) {
        descriptions = new string[](nextProposalId);
        for (uint256 i = 0; i < nextProposalId; i++) {
            descriptions[i] = proposals[i].description;
        }
    }

    /**
     * @notice Casts a vote on a proposal
     * @dev Members can vote on a proposal before the deadline. Each member can vote only once per proposal.
     *      The voting power is determined by the member's token balance.
     * @param proposalId ID of the proposal to vote on
     * @param vote True for 'yes', false for 'no'
     */
    function castVote(uint256 proposalId, bool vote) external onlyMember {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.deadline, "Voting period over");
        require(!proposal.voted[msg.sender], "Already voted");

        proposal.voted[msg.sender] = true;
        uint256 voterBalance = votingToken.balanceOf(msg.sender);
        if (vote) {
            proposal.votes += int256(voterBalance);
        } else {
            proposal.votes -= int256(voterBalance);
        }

        emit Voted(proposalId, msg.sender, vote);
    }

    /**
     * @notice Executes a proposal if it has passed
     * @dev Can only be executed if the proposal has not been executed yet and the voting period is over.
     *      The proposal is considered passed if it has more positive votes than negative votes.
     * @param proposalId ID of the proposal to execute
     */
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.deadline, "Voting period not over");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;
        bool passed = proposal.votes > 0;
        if (passed) {
            // Execute the proposal actions (e.g., financial disbursement, contract interaction)
            // This is where the DAO's decisions are enforced.
        }

        emit ProposalExecuted(proposalId, passed);
    }

    /**
     * @notice Deposits funds into the DAO Treasury
     * @dev Allows anyone to deposit funds into the DAO's treasury. Increases the treasury balance.
     */
    function depositFunds() external payable {
        treasuryBalance += msg.value;
    }

    /**
     * @notice Withdraws funds from the DAO Treasury
     * @dev Only members can withdraw funds from the treasury. This function is only for demonstration purposes and should be adjusted as needed.
     * @param amount Amount to withdraw in wei
     * @param to Address to send the withdrawn funds to
     */
    function withdrawFunds(uint256 amount, address payable to) external onlyMember {
        require(amount <= treasuryBalance, "Insufficient treasury balance");
        treasuryBalance -= amount;
        to.transfer(amount);
    }

    /**
     * @notice Gets the balance of the treasury
     * @dev Returns the current balance of the DAO's treasury.
     * @return balance Treasury balance in wei
     */
    function getTreasuryBalance() external view returns (uint256 balance) {
        balance = treasuryBalance;
    }

    /**
     * @dev Fallback function to handle receiving Ether directly
     * @notice Receives Ether and increases the treasury balance.
     */
    receive() external payable {
        treasuryBalance += msg.value;
    }
}
