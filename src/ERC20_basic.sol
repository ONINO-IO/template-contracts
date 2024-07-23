// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0

pragma solidity ^0.8.20;

// Importing necessary interfaces and libraries from OpenZeppelin
import { IERC20, IERC20Metadata, IERC20Errors } from "@openzeppelin-5.0.0/contracts/token/ERC20/ERC20.sol";
import { Context } from "@openzeppelin-5.0.0/contracts/utils/Context.sol";

/**
 * @title ERC20
 * @dev Implementation of a basic ERC20 token with customizable name and symbol.
 * The token adheres to the ERC20 standard as defined in the EIP and includes
 * optional metadata functions for name, symbol, and decimals.
 */
contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    // Mapping from account addresses to their respective balances
    mapping(address => uint256) private _balances;

    // Mapping from account addresses to a mapping of spender addresses and their allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    // Total supply of the token
    uint256 private _totalSupply;

    // Name of the token
    string private _name;

    // Symbol of the token
    string private _symbol;

    /**
     * @dev Constructor that sets the token name and symbol.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @notice Returns the name of the token.
     * @dev This is an optional metadata function from the ERC20 standard.
     * @return The name of the token as a string.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the token.
     * @dev This is an optional metadata function from the ERC20 standard.
     * @return The symbol of the token as a string.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * @dev The default value is 18, mimicking the relationship between Ether and Wei.
     * @return The number of decimals as an uint8.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @notice Returns the total supply of the token.
     * @dev This is a required function from the ERC20 standard.
     * @return The total supply as a uint256.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Returns the balance of tokens held by a specific account.
     * @dev This is a required function from the ERC20 standard.
     * @param account The address of the account.
     * @return The balance of the account as a uint256.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Transfers tokens to a specified address.
     * @dev This is a required function from the ERC20 standard.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @notice Returns the remaining number of tokens that a spender will be allowed to spend on behalf of an owner.
     * @dev This is a required function from the ERC20 standard.
     * @param owner The address of the owner.
     * @param spender The address of the spender.
     * @return The remaining allowance as a uint256.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Approves a spender to spend a specified amount of the caller's tokens.
     * @dev This is a required function from the ERC20 standard.
     * @param spender The address of the spender.
     * @param value The amount of tokens to approve.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @notice Transfers tokens from one address to another using the allowance mechanism.
     * @dev This is a required function from the ERC20 standard.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Internal function that moves tokens from one address to another.
     * This function is equivalent to `transfer` and can be used to e.g.
     * implement automatic token fees, slashing mechanisms, etc.
     * Emits a {Transfer} event.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Internal function that updates balances during transfers, mints, and burns.
     * Emits a {Transfer} event.
     * @param from The address transferring tokens.
     * @param to The address receiving tokens.
     * @param value The amount of tokens to transfer.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Minting tokens: Increase total supply
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            // Burning tokens: Decrease total supply
            unchecked {
                _totalSupply -= value;
            }
        } else {
            unchecked {
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints tokens to a specified account.
     * Emits a {Transfer} event with `from` set to the zero address.
     * @param account The address to mint tokens to.
     * @param value The amount of tokens to mint.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Internal function that burns tokens from a specified account.
     * Emits a {Transfer} event with `to` set to the zero address.
     * @param account The address to burn tokens from.
     * @param value The amount of tokens to burn.
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Internal function that sets the allowance of a spender for an owner.
     * Emits an {Approval} event.
     * @param owner The address of the owner.
     * @param spender The address of the spender.
     * @param value The amount of tokens to set as allowance.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Internal variant of `_approve` with an optional flag to emit or suppress the {Approval} event.
     * @param owner The address of the owner.
     * @param spender The address of the spender.
     * @param value The amount of tokens to set as allowance.
     * @param emitEvent A boolean flag indicating whether to emit the {Approval} event.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Internal function that updates the allowance of a spender for an owner based on spent tokens.
     * Does not emit an {Approval} event to save gas.
     * @param owner The address of the owner.
     * @param spender The address of the spender.
     * @param value The amount of tokens to spend.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

/**
 * @title {{TOKEN_NAME}} Token
 * @dev Custom ERC20 token implementation with a predefined name and symbol.
 */
contract {{TOKEN_NAME}} is ERC20 {
    /**
     * @dev Constructor that sets the token name and symbol using template variables.
     */
    constructor() MyToken("{{TOKEN_NAME}}", "{{TOKEN_SYMBOL}}") {}
}
