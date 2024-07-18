// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title SupplyChain
 * @dev Implements a basic supply chain tracking solution with role-based access control.
 */
contract SupplyChain {
    // Define role constants
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant SUPPLIER_ROLE = keccak256("SUPPLIER_ROLE");
    bytes32 public constant VENDOR_ROLE = keccak256("VENDOR_ROLE");
    bytes32 public constant TRANSPORTER_ROLE = keccak256("TRANSPORTER_ROLE");

    // Struct to store role data
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    // Events for role management
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // Modifier to check for specific role
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "AccessControl: account does not have the correct role");
        _;
    }

    /**
     * @dev Initializes the contract, setting up roles for the deployer.
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPLIER_ROLE, msg.sender);
        _setupRole(VENDOR_ROLE, msg.sender);
        _setupRole(TRANSPORTER_ROLE, msg.sender);
    }

    /**
     * @notice Checks if an account has a specific role.
     * @param role The role to check.
     * @param account The account to check.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Grants a role to an account.
     * @param role The role to grant.
     * @param account The account to grant the role to.
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes a role from an account.
     * @param role The role to revoke.
     * @param account The account to revoke the role from.
     */
    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    /**
     * @dev Sets up a role for an account.
     * @param role The role to set up.
     * @param account The account to set up the role for.
     */
    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    /**
     * @notice Assigns a role to an account.
     * @param role The role to assign.
     * @param account The account to assign the role to.
     */
    function assignRole(bytes32 role, address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @notice Revokes a role from an account.
     * @param role The role to revoke.
     * @param account The account to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    // Struct to store item details
    struct Item {
        string name;
        string currentLocation;
        string status; // "created", "in transit", "delivered"
        address currentHandler;
    }

    mapping(uint256 => Item) public items;
    uint256 public nextItemId;

    // Events for item management
    event ItemCreated(uint256 indexed itemId, string name);
    event ItemStatusUpdated(uint256 indexed itemId, string newStatus, string newLocation, address indexed handler);

    /**
     * @notice Creates a new item in the supply chain.
     * @param name The name of the item.
     */
    function createItem(string memory name) public onlyRole(SUPPLIER_ROLE) {
        uint256 itemId = nextItemId++;
        items[itemId] = Item(name, "Supplier", "created", msg.sender);
        emit ItemCreated(itemId, name);
    }

    /**
     * @notice Updates the status and location of an item.
     * @param itemId The ID of the item to update.
     * @param newStatus The new status of the item.
     * @param newLocation The new location of the item.
     */
    function updateItem(uint256 itemId, string memory newStatus, string memory newLocation) public {
        require(hasRole(TRANSPORTER_ROLE, msg.sender) || hasRole(VENDOR_ROLE, msg.sender), "Unauthorized");
        require(keccak256(bytes(items[itemId].status)) != keccak256(bytes("delivered")), "Item already delivered");

        items[itemId].status = newStatus;
        items[itemId].currentLocation = newLocation;
        items[itemId].currentHandler = msg.sender;

        emit ItemStatusUpdated(itemId, newStatus, newLocation, msg.sender);
    }
}
