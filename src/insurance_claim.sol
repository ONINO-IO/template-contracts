// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title InsuranceClaimProcessing
 * @dev Manages insurance claims in a healthcare context, including claim submission, verification, and processing.
 */
contract InsuranceClaimProcessing {

    /// @notice Struct to store details of an insurance claim.
    struct Claim {
        address payable patient; // Address of the patient filing the claim.
        address hospitalAdmin; // Address of the hospital administrator verifying the claim.
        uint256 claimAmount; // Amount of the claim.
        bool isBillVerifiedByHospital; // Flag to indicate if the bill is verified by the hospital.
        string nftId; // An NFT identifier associated with the claim, for additional verification or tracking.
    }

    /// @notice Struct to aggregate multiple claim details.
    struct ClaimDetails {
        uint256[] claimIds;
        address[] patients;
        address[] hospitalAdmins;
        uint256[] claimAmounts;
        bool[] billVerifications;
        string[] nftIds;
        ClaimStatus[] claimStatuses;
    }

    /// @notice Enum to represent the status of a claim.
    enum ClaimStatus { Submitted, VerifiedByHospital, Processed }

    /// @notice Mapping to store claims by their IDs.
    mapping (uint256 => Claim) public claims;

    /// @notice Mapping from patient address to their claim IDs.
    mapping (address => uint256[]) public patientClaims;

    /// @notice Mapping to store the status of each claim by its ID.
    mapping (uint256 => ClaimStatus) public claimsStatus;

    /// @notice Counter to generate unique claim IDs.
    uint256 public nextClaimId = 1;

    /// @notice Address of the insurance company that manages the funds and processes claims.
    address payable public insuranceCompany;

    /// @notice Events for logging various actions.
    event LogBillSubmitted(uint256 indexed claimId, address indexed patient, string nftId);
    event LogBillVerifiedByHospital(uint256 indexed claimId, address indexed hospitalAdmin, uint256 claimAmount);
    event LogClaimProcessed(uint256 indexed claimId, address indexed insuranceCompany, uint256 claimAmount);
    event FundsDeposited(uint256 indexed amount);

    /// @dev Constructor to set the insurance company's address.
    constructor() {
        insuranceCompany = payable(msg.sender);
    }

    /**
     * @notice Allows the insurance company to deposit funds into the contract.
     */
    function depositFunds() external payable {
        require(msg.sender == insuranceCompany, "Only insurance company can deposit funds");
        emit FundsDeposited(msg.value);
    }

    /**
     * @notice Submits a new insurance claim.
     * @param _hospitalAdmin The address of the hospital administrator.
     * @param _nftId The NFT identifier associated with the claim.
     */
    function submitBill(address _hospitalAdmin, string memory _nftId) external {
        uint256 claimId = nextClaimId++;
        claims[claimId] = Claim({
            patient: payable(msg.sender),
            hospitalAdmin: _hospitalAdmin,
            claimAmount: 0,
            isBillVerifiedByHospital: false,
            nftId: _nftId
        });
        patientClaims[msg.sender].push(claimId);
        claimsStatus[claimId] = ClaimStatus.Submitted;
        emit LogBillSubmitted(claimId, msg.sender, _nftId);
    }

    /**
     * @notice Allows hospital admins to verify bills related to a claim.
     * @param _claimId The ID of the claim to verify.
     * @param _claimAmount The amount of the claim.
     */
    function verifyBillHospital(uint256 _claimId, uint256 _claimAmount) external {
        Claim storage claim = claims[_claimId];
        require(msg.sender == claim.hospitalAdmin, "Only hospital admin can verify the bill");
        require(!claim.isBillVerifiedByHospital, "Bill already verified");
        claim.isBillVerifiedByHospital = true;
        claim.claimAmount = _claimAmount;
        claimsStatus[_claimId] = ClaimStatus.VerifiedByHospital;
        emit LogBillVerifiedByHospital(_claimId, msg.sender, _claimAmount);
    }

    /**
     * @notice Allows the insurance company to process and pay out a verified claim.
     * @param _claimId The ID of the claim to process.
     */
    function processClaim(uint256 _claimId) external {
        require(msg.sender == insuranceCompany, "Only insurance company can process claims");
        Claim storage claim = claims[_claimId];
        require(claim.isBillVerifiedByHospital, "Hospital must first verify the bill");
        require(address(this).balance >= claim.claimAmount, "Insufficient funds to process this claim");
        claim.patient.transfer(claim.claimAmount);
        claimsStatus[_claimId] = ClaimStatus.Processed;
        emit LogClaimProcessed(_claimId, msg.sender, claim.claimAmount);
    }

    /**
     * @notice Retrieves details of all claims made by a specific patient.
     * @param patient The address of the patient.
     * @return details The aggregated claim details of the patient.
     */
    function getPatientClaims(address patient) external view returns (ClaimDetails memory details) {
        uint256 length = patientClaims[patient].length;
        details.claimIds = new uint256[](length);
        details.patients = new address[](length);
        details.hospitalAdmins = new address[](length);
        details.claimAmounts = new uint256[](length);
        details.billVerifications = new bool[](length);
        details.nftIds = new string[](length);
        details.claimStatuses = new ClaimStatus[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 claimId = patientClaims[patient][i];
            Claim storage claim = claims[claimId];
            details.claimIds[i] = claimId;
            details.patients[i] = claim.patient;
            details.hospitalAdmins[i] = claim.hospitalAdmin;
            details.claimAmounts[i] = claim.claimAmount;
            details.billVerifications[i] = claim.isBillVerifiedByHospital;
            details.nftIds[i] = claim.nftId;
            details.claimStatuses[i] = claimsStatus[claimId];
        }
    }

    /**
     * @notice Gets the status of a specific claim.
     * @param _claimId The ID of the claim.
     * @return The status of the claim.
     */
    function getClaimStatus(uint256 _claimId) external view returns (ClaimStatus) {
        return claimsStatus[_claimId];
    }
}
