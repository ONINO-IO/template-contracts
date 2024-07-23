// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title InsuranceClaimProcessing
 * @dev Manages insurance claims in a healthcare context, including claim submission, verification, and processing.
 * This contract allows patients to submit claims, hospital administrators to verify claims, and the insurance company to process claims.
 */
contract InsuranceClaimProcessing {

    /// @notice Struct to store details of an insurance claim.
    struct Claim {
        address payable patient;        /// @notice Address of the patient filing the claim.
        address hospitalAdmin;          /// @notice Address of the hospital administrator verifying the claim.
        uint256 claimAmount;            /// @notice Amount of the claim in wei.
        bool isBillVerifiedByHospital;  /// @notice Flag to indicate if the bill is verified by the hospital.
        string nftId;                   /// @notice An NFT identifier associated with the claim, for additional verification or tracking.
    }

    /// @notice Struct to aggregate multiple claim details.
    struct ClaimDetails {
        uint256[] claimIds;           /// @notice Array of claim IDs.
        address[] patients;           /// @notice Array of patient addresses.
        address[] hospitalAdmins;     /// @notice Array of hospital administrator addresses.
        uint256[] claimAmounts;       /// @notice Array of claim amounts in wei.
        bool[] billVerifications;     /// @notice Array of bill verification statuses.
        string[] nftIds;              /// @notice Array of NFT identifiers associated with the claims.
        ClaimStatus[] claimStatuses;  /// @notice Array of claim statuses.
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

    /// @notice Event emitted when a new claim is submitted.
    /// @param claimId The ID of the submitted claim.
    /// @param patient The address of the patient.
    /// @param nftId The NFT identifier associated with the claim.
    event LogBillSubmitted(uint256 indexed claimId, address indexed patient, string nftId);

    /// @notice Event emitted when a claim is verified by a hospital administrator.
    /// @param claimId The ID of the verified claim.
    /// @param hospitalAdmin The address of the hospital administrator.
    /// @param claimAmount The amount of the claim in wei.
    event LogBillVerifiedByHospital(uint256 indexed claimId, address indexed hospitalAdmin, uint256 claimAmount);

    /// @notice Event emitted when a claim is processed by the insurance company.
    /// @param claimId The ID of the processed claim.
    /// @param insuranceCompany The address of the insurance company.
    /// @param claimAmount The amount of the claim in wei.
    event LogClaimProcessed(uint256 indexed claimId, address indexed insuranceCompany, uint256 claimAmount);

    /// @notice Event emitted when funds are deposited into the contract.
    /// @param amount The amount of funds deposited in wei.
    event FundsDeposited(uint256 indexed amount);

    /**
     * @dev Constructor to set the insurance company's address.
     * The deployer of the contract is assigned as the insurance company.
     */
    constructor() {
        insuranceCompany = payable(msg.sender);
    }

    /**
     * @notice Allows the insurance company to deposit funds into the contract.
     * @dev Only the insurance company can deposit funds.
     */
    function depositFunds() external payable {
        require(msg.sender == insuranceCompany, "Only insurance company can deposit funds");
        emit FundsDeposited(msg.value);
    }

    /**
     * @notice Submits a new insurance claim.
     * @dev Patients can submit a claim with the address of the hospital administrator and an NFT identifier for verification or tracking.
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
     * @dev Only the assigned hospital administrator can verify the bill and specify the claim amount.
     * @param _claimId The ID of the claim to verify.
     * @param _claimAmount The amount of the claim in wei.
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
     * @dev Only the insurance company can process claims. The claim must be verified by the hospital and there must be sufficient funds in the contract.
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
     * @dev Returns aggregated claim details including claim IDs, patients, hospital administrators, claim amounts, bill verification statuses, NFT IDs, and claim statuses.
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
     * @dev Returns the status of the claim which can be Submitted, VerifiedByHospital, or Processed.
     * @param _claimId The ID of the claim.
     * @return The status of the claim.
     */
    function getClaimStatus(uint256 _claimId) external view returns (ClaimStatus) {
        return claimsStatus[_claimId];
    }
}
