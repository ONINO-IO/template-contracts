// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0

pragma solidity ^0.8.20;

// Importing necessary interfaces and libraries from OpenZeppelin
import { IERC20, IERC20Metadata, IERC20Errors } from "@openzeppelin-5.0.0/contracts/token/ERC20/ERC20.sol";
import { Context } from "@openzeppelin-5.0.0/contracts/utils/Context.sol";
import { ERC20Burnable } from "@openzeppelin-5.0.0/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title {{TOKEN_NAME}} Token
 * @dev Implementation of a burnable ERC20 token with customizable name and symbol.
 * The token adheres to the ERC20 standard as defined in the EIP and includes
 * optional metadata functions for name, symbol, and decimals. Additionally, it
 * includes burn functionality to allow token holders to destroy their tokens.
 */
contract {{TOKEN_NAME}} is Context, ERC20, ERC20Burnable {
    /**
     * @dev Constructor that sets the token name and symbol using template variables.
     */
    constructor() ERC20("{{TOKEN_NAME}}", "{{TOKEN_SYMBOL}}") {}

    // The following functions are inherited from the ERC20 and ERC20Burnable contracts

    /**
     * @notice Returns the name of the token.
     * @dev This is an optional metadata function from the ERC20 standard.
     * @return The name of the token as a string.
     */
    function name() public view virtual override(IERC20Metadata, ERC20) returns (string memory) {
        return ERC20.name();
    }

    /**
     * @notice Returns the symbol of the token.
     * @dev This is an optional metadata function from the ERC20 standard.
     * @return The symbol of the token as a string.
     */
    function symbol() public view virtual override(IERC20Metadata, ERC20) returns (string memory) {
        return ERC20.symbol();
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * @dev The default value is 18, mimicking the relationship between Ether and Wei.
     * @return The number of decimals as an uint8.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return ERC20.decimals();
    }

    /**
     * @notice Returns the total supply of the token.
     * @dev This is a required function from the ERC20 standard.
     * @return The total supply as a uint256.
     */
    function totalSupply() public view virtual override(IERC20, ERC20) returns (uint256) {
        return ERC20.totalSupply();
    }

    /**
     * @notice Returns the balance of tokens held by a specific account.
     * @dev This is a required function from the ERC20 standard.
     * @param account The address of the account.
     * @return The balance of the account as a uint256.
     */
    function balanceOf(address account) public view virtual override(IERC20, ERC20) returns (uint256) {
        return ERC20.balanceOf(account);
    }

    /**
     * @notice Transfers tokens to a specified address.
     * @dev This is a required function from the ERC20 standard.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transfer(address to, uint256 value) public virtual override(IERC20, ERC20) returns (bool) {
        return ERC20.transfer(to, value);
    }

    /**
     * @notice Returns the remaining number of tokens that a spender will be allowed to spend on behalf of an owner.
     * @dev This is a required function from the ERC20 standard.
     * @param owner The address of the owner.
     * @param spender The address of the spender.
     * @return The remaining allowance as a uint256.
     */
    function allowance(address owner, address spender) public view virtual override(IERC20, ERC20) returns (uint256) {
        return ERC20.allowance(owner, spender);
    }

    /**
     * @notice Approves a spender to spend a specified amount of the caller's tokens.
     * @dev This is a required function from the ERC20 standard.
     * @param spender The address of the spender.
     * @param value The amount of tokens to approve.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 value) public virtual override(IERC20, ERC20) returns (bool) {
        return ERC20.approve(spender, value);
    }

    /**
     * @notice Transfers tokens from one address to another using the allowance mechanism.
     * @dev This is a required function from the ERC20 standard.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transferFrom(address from, address to, uint256 value) public virtual override(IERC20, ERC20) returns (bool) {
        return ERC20.transferFrom(from, to, value);
    }

    /**
     * @notice Destroys a specified amount of tokens from the caller.
     * @dev This function calls the internal _burn function from ERC20.
     * @param value The amount of tokens to burn.
     */
    function burn(uint256 value) public virtual override {
        super.burn(value);
    }

    /**
     * @notice Destroys a specified amount of tokens from a specified account, deducting from the caller's allowance.
     * @dev This function calls the internal _burn function from ERC20 and _spendAllowance function from ERC20Burnable.
     * @param account The address to burn tokens from.
     * @param value The amount of tokens to burn.
     */
    function burnFrom(address account, uint256 value) public virtual override {
        super.burnFrom(account, value);
    }
}
