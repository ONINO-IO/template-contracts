// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title BasicDataValidator
 * @dev Contract for managing data validation with owner and auditor roles.
 */
contract BasicDataValidator {
    /// @notice Address of the contract owner.
    address public owner;

    /// @notice Mapping to track auditor addresses.
    mapping(address => bool) public auditors;

    /// @notice Structure to represent a data point with a hash and a timestamp.
    struct DataPoint {
        bytes32 dataHash; // Fixed-size byte array to store SHA256 hash.
        uint256 timestamp; // Timestamp of when the data point was stored.
    }

    /// @notice Mapping from an ID to the corresponding data point.
    mapping(uint256 => DataPoint) public dataPoints;

    /// @notice Counter to track the next ID to be assigned to a data point.
    uint256 public nextDataPointId;

    /// @notice Events for logging actions on the blockchain.
    event DataPointStored(uint256 indexed id, bytes32 indexed dataHash, uint256 timestamp);
    event AuditorAdded(address indexed auditor);
    event AuditorRemoved(address indexed auditor);

    /**
     * @dev Constructor sets the contract deployer as the owner.
     */
    constructor() {
        owner = msg.sender;
    }

    /// @dev Modifier to restrict function access to only the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    /// @dev Modifier to restrict function access to only the auditors.
    modifier onlyAuditor() {
        require(auditors[msg.sender], "Only auditor is allowed");
        _;
    }

    /**
     * @notice Adds a new auditor.
     * @param _auditor Address of the auditor to be added.
     */
    function addAuditor(address _auditor) external onlyOwner {
        auditors[_auditor] = true;
        emit AuditorAdded(_auditor);
    }

    /**
     * @notice Removes an existing auditor.
     * @param _auditor Address of the auditor to be removed.
     */
    function removeAuditor(address _auditor) external onlyOwner {
        auditors[_auditor] = false;
        emit AuditorRemoved(_auditor);
    }

    /**
     * @notice Stores a new data point with an automatically assigned ID.
     * @param dataHash The SHA256 hash of the data to be stored.
     */
    function storeDataPoint(bytes32 dataHash) external onlyOwner {
        uint256 id = nextDataPointId++;
        dataPoints[id] = DataPoint(dataHash, block.timestamp);
        emit DataPointStored(id, dataHash, block.timestamp);
    }

    /**
     * @notice Validates a data point by comparing the provided hash with the stored hash.
     * @param id The ID of the data point to validate.
     * @param dataHash The hash to compare against the stored hash.
     * @return isValid True if the provided hash matches the stored hash, false otherwise.
     */
    function validateDataPoint(uint256 id, bytes32 dataHash) external view onlyAuditor returns (bool isValid) {
        DataPoint memory dataPoint = dataPoints[id];
        return dataPoint.dataHash == dataHash;
    }

    /**
     * @notice Transfers ownership of the contract to a new address.
     * @param newOwner Address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }
}
