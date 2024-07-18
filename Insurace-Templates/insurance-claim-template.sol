// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// InsuranceClaimProcessing contract for managing insurance claims in a healthcare context.
contract InsuranceClaimProcessing {

    // Struct to store details of an insurance claim.
    struct Claim {
        address payable patient; // Address of the patient filing the claim.
        address hospitalAdmin; // Address of the hospital administrator verifying the claim.
        uint claimAmount; // Amount of the claim.
        bool isBillVerifiedByHospital; // Flag to indicate if the bill is verified by the hospital.
        string nftId; // An NFT identifier associated with the claim, for additional verification or tracking.
    }

    // Struct to aggregate multiple claim details.
    struct ClaimDetails {
        uint[] claimIds;
        address[] patients;
        address[] hospitalAdmins;
        uint[] claimAmounts;
        bool[] billVerifications;
        string[] nftIds;
        ClaimStatus[] claimStatuses;
    }

    // Enum to represent the status of a claim.
    enum ClaimStatus { Submitted, VerifiedByHospital, Processed }

    // Mapping to store claims by their IDs.
    mapping (uint => Claim) public claims;

    // Mapping from patient address to their claim IDs.
    mapping (address => uint[]) public patientClaims;

    // Mapping to store the status of each claim by its ID.
    mapping (uint => ClaimStatus) public claimsStatus;

    // Counter to generate unique claim IDs.
    uint public nextClaimId = 1;

    // Address of the insurance company that manages the funds and processes claims.
    address payable public insuranceCompany;

    // Events for logging various actions.
    event LogBillSubmitted(uint indexed claimId, address indexed patient, string nftId);
    event LogBillVerifiedByHospital(uint indexed claimId, address indexed hospitalAdmin, uint claimAmount);
    event LogClaimProcessed(uint indexed claimId, address indexed insuranceCompany, uint claimAmount);
    event FundsDeposited(uint indexed amount);

   // Constructor to set the insurance company's address.
    constructor() {
        insuranceCompany = payable(msg.sender);
    }

    // Function to allow the insurance company to deposit funds into the contract.
    function depositFunds() public payable {
        require(msg.sender == insuranceCompany, "Only insurance company can deposit funds");
        emit FundsDeposited(msg.value);
    }

    // Function to submit a new insurance claim.
    function submitBill(address _hospitalAdmin, string memory _nftId) public {
        uint claimId = nextClaimId++;
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

    // Function for hospital admins to verify bills related to a claim.
    function verifyBillHospital(uint _claimId, uint _claimAmount) public {
        Claim storage claim = claims[_claimId];
        require(msg.sender == claim.hospitalAdmin, "Only hospital admin can verify the bill");
        claim.isBillVerifiedByHospital = true;
        claim.claimAmount = _claimAmount;
        claimsStatus[_claimId] = ClaimStatus.VerifiedByHospital;
        emit LogBillVerifiedByHospital(_claimId, claim.hospitalAdmin, _claimAmount);
    }

    // Function for the insurance company to process and pay out a verified claim.
    function processClaim(uint _claimId) public {
        require(msg.sender == insuranceCompany, "Only insurance company can process claims");
        Claim storage claim = claims[_claimId];
        require(claim.isBillVerifiedByHospital, "Hospital must first verify the bill");
        require(address(this).balance >= claim.claimAmount, "Contract does not have sufficient funds to process this claim");
        claim.patient.transfer(claim.claimAmount);
        claimsStatus[_claimId] = ClaimStatus.Processed;
        emit LogClaimProcessed(_claimId, insuranceCompany, claim.claimAmount);
    }

    // Function to retrieve details of all claims made by a specific patient.
    function getPatientClaims(address patient) public view returns (ClaimDetails memory) {
        uint length = patientClaims[patient].length;
        ClaimDetails memory details;

        details.claimIds = new uint[](length);
        details.patients = new address[](length);
        details.hospitalAdmins = new address[](length);
        details.claimAmounts = new uint[](length);
        details.billVerifications = new bool[](length);
        details.nftIds = new string[](length);
        details.claimStatuses = new ClaimStatus[](length);

        for (uint i = 0; i < length; i++) {
            uint claimId = patientClaims[patient][i];
            Claim storage claim = claims[claimId];
            
            details.claimIds[i] = claimId;
            details.patients[i] = claim.patient;
            details.hospitalAdmins[i] = claim.hospitalAdmin;
            details.claimAmounts[i] = claim.claimAmount;
            details.billVerifications[i] = claim.isBillVerifiedByHospital;
            details.nftIds[i] = claim.nftId;
            details.claimStatuses[i] = claimsStatus[claimId];
        }

        return details;
    }

    // Function to get the status of a specific claim.
    function getClaimStatus(uint _claimId) external view returns (ClaimStatus) {
        return claimsStatus[_claimId];
    }
}