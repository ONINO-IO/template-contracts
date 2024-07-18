// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Assuming the token contract follows a standard interface like ERC20
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract SimpleDAO {
    // Token used for voting and membership
    // State variables
    IERC20 public votingToken;
    uint256 public minBalanceForVoting;
    bool private initialized;
    mapping(address => uint256) public tokenBalance;

    // Structure to hold proposal details
    struct Proposal {
        string description;
        uint256 deadline;
        bool executed;
        int256 votes;
        mapping(address => bool) voted;
    }
    // Modifier to ensure initialization happens only once
    modifier onlyOnce() {
        require(!initialized, "Already initialized");
        _;
        initialized = true;
    }

    // Modifier for members only with minimum balance requirement
    modifier onlyMember() {
        require(votingToken.balanceOf(msg.sender) >= minBalanceForVoting, "Insufficient balance for voting");
        _;
    }
    // Mapping of proposals
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    // DAO Treasury
    uint256 public treasuryBalance;

    // Events
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 deadline);
    event Voted(uint256 indexed proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 indexed proposalId, bool executed);

    // Constructor
    constructor() {
        // Initial setup
    }

    // Initialization function
    function initialize(address tokenAddress, uint256 minBalance) public onlyOnce {
        votingToken = IERC20(tokenAddress);
        minBalanceForVoting = minBalance;
    }


    // Function to create a proposal
    function createProposal(string memory description) public onlyMember {
        Proposal storage proposal = proposals[nextProposalId];
        proposal.description = description;
        proposal.deadline = block.timestamp + 7 days; // 1 week duration

        emit ProposalCreated(nextProposalId, description, proposal.deadline);
        nextProposalId++;
    }

    // Function to list all proposal descriptions
    function listProposalDescriptions() public view returns (string[] memory) {
        string[] memory descriptions = new string[](nextProposalId);
        for (uint256 i = 0; i < nextProposalId; i++) {
            descriptions[i] = proposals[i].description;
        }
        return descriptions;
    }

    // Function to vote on a proposal
    function castVote(uint256 proposalId, bool vote) public onlyMember {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.deadline, "Voting period over");
        require(!proposal.voted[msg.sender], "Already voted");

        proposal.voted[msg.sender] = true;
        if (vote) {
            proposal.votes += int256(tokenBalance[msg.sender]);
        } else {
            proposal.votes -= int256(tokenBalance[msg.sender]);
        }

        emit Voted(proposalId, msg.sender, vote);
    }

    // Function to execute a proposal
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.deadline, "Voting period not over");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;
        if (proposal.votes > 0) {
            // Execute the proposal actions (e.g., financial disbursement)
            // This is where the DAO's decisions are enforced.
        }

        emit ProposalExecuted(proposalId, proposal.votes > 0);
    }

    // Function to deposit funds into DAO Treasury
    function depositFunds() public payable {
        treasuryBalance += msg.value;
    }

    // Other DAO functionalities like token-based membership handling, treasury management, etc.
}