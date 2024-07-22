// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/contract-templates/template-contracts/Marketplace-Template/p2p-energy-market-template.sol


pragma solidity ^0.8.18;



/**
 * @title EnergyMarketplace
 * @dev A P2P energy trading marketplace for buying and selling energy credits.
 */
contract EnergyMarketplace is Ownable {
    /// @notice ERC20 token used for energy credits
    IERC20 public energyToken;

    /// @notice Price per unit of energy in Wei
    uint256 public pricePerEnergyUnit;

    /// @notice Indicates if the contract has been initialized
    bool private initialized;

    /// @notice Event emitted when energy is purchased
    event EnergyPurchased(address indexed buyer, uint256 amount, uint256 totalCost);

    /// @notice Event emitted when energy is sold
    event EnergySold(address indexed seller, uint256 amount);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() Ownable(msg.sender) {
        initialized = false;
    }

    /**
     * @notice Initializes the marketplace with the energy token address and initial price.
     * @param _tokenAddress Address of the ERC20 energy token.
     * @param _initialPrice Initial price per unit of energy in Wei.
     */
    function initialize(address _tokenAddress, uint256 _initialPrice) external onlyOwner {
        require(!initialized, "Contract is already initialized");
        energyToken = IERC20(_tokenAddress);
        pricePerEnergyUnit = _initialPrice;
        initialized = true;
    }

    /**
     * @notice Allows users to buy energy credits by sending Ether.
     * @param amount The amount of energy credits to buy.
     */
    function buyEnergy(uint256 amount) external payable {
        uint256 cost = amount * pricePerEnergyUnit;
        require(msg.value >= cost, "Insufficient payment");

        // Transfer energy tokens to buyer
        require(energyToken.transfer(msg.sender, amount), "Energy token transfer failed");

        // Refund any excess Ether sent
        if (msg.value > cost) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - cost}("");
            require(refundSuccess, "Refund failed");
        }

        emit EnergyPurchased(msg.sender, amount, cost);
    }

    /**
     * @notice Allows producers to sell energy credits for Ether.
     * @param amount The amount of energy credits to sell.
     */
    function sellEnergy(uint256 amount) external {
        require(energyToken.transferFrom(msg.sender, address(this), amount), "Energy token transfer failed");
        uint256 payment = amount * pricePerEnergyUnit;

        // Pay the seller in Ether
        (bool success, ) = msg.sender.call{value: payment}("");
        require(success, "Payment failed");

        emit EnergySold(msg.sender, amount);
    }

    /**
     * @notice Updates the price per unit of energy.
     * @param newPrice The new price per unit of energy in Wei.
     */
    function updatePrice(uint256 newPrice) external onlyOwner {
        pricePerEnergyUnit = newPrice;
    }

    /**
     * @dev Fallback function to handle direct Ether transfers.
     */
    receive() external payable {}

    /**
     * @notice Allows the owner to withdraw Ether from the contract.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawEther(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @notice Updates the address of the energy token.
     * @param newAddress The new address of the ERC20 energy token.
     */
    function updateEnergyToken(address newAddress) external onlyOwner {
        energyToken = IERC20(newAddress);
    }
}
