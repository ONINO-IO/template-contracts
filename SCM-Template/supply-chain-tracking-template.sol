// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChain {
    // AccessControl logic
    struct RoleData {
        mapping(address => bool) members;
        string adminRole; // Note: This field is declared but not used in your contract
    }

    mapping(string => RoleData) private _roles;

    // Define role constants
    string private constant DEFAULT_ADMIN_ROLE = "DEFAULT_ADMIN_ROLE";
    string private constant SUPPLIER_ROLE = "supplier";
    string private constant VENDOR_ROLE = "vendor";
    string private constant TRANSPORTER_ROLE = "transporter";

    event RoleAdminChanged(string indexed role, string indexed previousAdminRole, string indexed newAdminRole);
    event RoleGranted(string indexed role, address indexed account, address indexed sender);
    event RoleRevoked(string indexed role, address indexed account, address indexed sender);

    modifier onlyRole(string memory roleName) {
        require(hasRole(roleName, msg.sender), "AccessControl: account does not have the correct role");
        _;
    }

    function hasRole(string memory roleName, address account) public view returns (bool) {
        return _roles[roleName].members[account];
    }

    function _setupRole(string memory roleName, address account) internal {
        _grantRole(roleName, account);
    }

    function _grantRole(string memory roleName, address account) internal {
        if (!hasRole(roleName, account)) {
            _roles[roleName].members[account] = true;
            emit RoleGranted(roleName, account, msg.sender);
        }
    }

    function _revokeRole(string memory roleName, address account) internal {
        if (hasRole(roleName, account)) {
            _roles[roleName].members[account] = false;
            emit RoleRevoked(roleName, account, msg.sender);
        }
    }

    struct Item {
        string name;
        string currentLocation;
        string status; // "created", "in transit", "delivered"
        address currentHandler;
    }

    mapping(uint256 => Item) public items;
    uint256 public nextItemId;

    // Events
    event ItemCreated(uint256 indexed itemId, string name);
    event ItemStatusUpdated(uint256 indexed itemId, string newStatus, string newLocation);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPLIER_ROLE, msg.sender); // Assigning the supplier role to the contract deployer for demonstration purposes
        _setupRole(VENDOR_ROLE, msg.sender);   // Assigning the vendor role to the contract deployer for demonstration purposes
        // Add setup for TRANSPORTER_ROLE if necessary
    }

    // Create a new item in the supply chain
    function createItem(string memory name) public onlyRole(SUPPLIER_ROLE) {
        uint256 itemId = nextItemId++;
        items[itemId] = Item(name, "Supplier", "created", msg.sender);
        emit ItemCreated(itemId, name);
    }

    // Update item status and location
    function updateItem(uint256 itemId, string memory newStatus, string memory newLocation) public {
        require(hasRole(TRANSPORTER_ROLE, msg.sender) || hasRole(VENDOR_ROLE, msg.sender), "Unauthorized");
        require(keccak256(bytes(items[itemId].status)) != keccak256(bytes("delivered")), "Item already delivered");

        items[itemId].status = newStatus;
        items[itemId].currentLocation = newLocation;
        items[itemId].currentHandler = msg.sender;

        emit ItemStatusUpdated(itemId, newStatus, newLocation);
    }

  

    // Assign roles to accounts using string role names
    function assignRole(string memory roleName, address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(roleName, account);
    }

    // Revoke roles from accounts
    function revokeRole(string memory roleName, address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(roleName, account);
    }
}