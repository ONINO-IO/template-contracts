// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BasicDataValidator {
    // Public state variable to store the owner's address.
    address public owner;

    // Mapping to keep track of auditor addresses.
    // True if an address is an auditor, false otherwise.
    mapping(address => bool) public auditors;

    // Structure to represent a data point with a hash and a timestamp.
    struct DataPoint {
        bytes dataHash; // Dynamically-sized byte array to store SHA256 hash.
        uint256 timestamp; // Timestamp of when the data point was stored.
    }

    // Mapping from an ID to the corresponding data point.
    mapping(uint256 => DataPoint) public dataPoints;

    // Counter to track the next ID to be assigned to a data point.
    uint256 public nextDataPointId;

    // Events for logging actions on the blockchain.
    event DataPointStored(uint256 indexed id, bytes indexed dataHash, uint256 timestamp);
    event AuditorAdded(address auditor);
    event AuditorRemoved(address auditor);

    // Constructor sets the contract deployer as the owner.
    constructor() {
        owner = msg.sender;
    }

    // Modifier to restrict function access to only the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    // Modifier to restrict function access to only the auditors.
    modifier onlyAuditor() {
        require(auditors[msg.sender], "Only auditor is allowed");
        _;
    }

    // Adds a new auditor. Only callable by the owner.
    // @param _auditor Address of the auditor to be added.
    function addAuditor(address _auditor) public onlyOwner {
        auditors[_auditor] = true;
        emit AuditorAdded(_auditor);
    }

    // Removes an existing auditor. Only callable by the owner.
    // @param _auditor Address of the auditor to be removed.
    function removeAuditor(address _auditor) public onlyOwner {
        auditors[_auditor] = false;
        emit AuditorRemoved(_auditor);
    }

    // Stores a new data point with an automatically assigned ID.
    // Only callable by the owner.
    // @param dataHash The SHA256 hash of the data to be stored.
    function storeDataPoint(bytes memory dataHash) public onlyOwner {
        uint256 id = nextDataPointId++;
        dataPoints[id] = DataPoint(dataHash, block.timestamp);
        emit DataPointStored(id, dataHash, block.timestamp);
    }

    // Validates a data point by comparing the provided hash with the stored hash.
    // Only callable by an auditor.
    // @param id The ID of the data point to validate.
    // @param dataHash The hash to compare against the stored hash.
    // @returns isValid True if the provided hash matches the stored hash, false otherwise.
    function validateDataPoint(uint256 id, bytes memory dataHash) public view onlyAuditor returns (bool isValid) {
        DataPoint memory dataPoint = dataPoints[id];
        return keccak256(dataPoint.dataHash) == keccak256(dataHash);
    }
}