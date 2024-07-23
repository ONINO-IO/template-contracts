// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title EnergyMarketplace
 * @dev A P2P energy trading marketplace for buying and selling energy credits. Users can buy energy credits by sending Ether and sell energy credits for Ether.
 */
contract EnergyMarketplace is Ownable {
    /// @notice ERC20 token used for energy credits
    IERC20 public energyToken;

    /// @notice Price per unit of energy in Wei
    uint256 public pricePerEnergyUnit;

    /// @notice Indicates if the contract has been initialized
    bool private initialized;

    /// @notice Event emitted when energy is purchased
    /// @param buyer The address of the buyer
    /// @param amount The amount of energy credits purchased
    /// @param totalCost The total cost in Wei
    event EnergyPurchased(address indexed buyer, uint256 amount, uint256 totalCost);

    /// @notice Event emitted when energy is sold
    /// @param seller The address of the seller
    /// @param amount The amount of energy credits sold
    event EnergySold(address indexed seller, uint256 amount);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() Ownable(msg.sender) {
        initialized = false;
    }

    /**
     * @notice Initializes the marketplace with the energy token address and initial price.
     * @dev Can only be called once by the owner. Sets the energy token address and initial price per unit of energy.
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
     * @dev Users send Ether to buy a specified amount of energy credits. Excess Ether is refunded.
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
     * @dev Producers transfer energy credits to the contract and receive Ether in return.
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
     * @dev Can only be called by the owner. Sets a new price per unit of energy in Wei.
     * @param newPrice The new price per unit of energy in Wei.
     */
    function updatePrice(uint256 newPrice) external onlyOwner {
        pricePerEnergyUnit = newPrice;
    }

    /**
     * @dev Fallback function to handle direct Ether transfers. Allows the contract to receive Ether.
     */
    receive() external payable {}

    /**
     * @notice Allows the owner to withdraw Ether from the contract.
     * @dev Can only be called by the owner. The contract must have a sufficient balance.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawEther(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @notice Updates the address of the energy token.
     * @dev Can only be called by the owner. Sets a new address for the ERC20 energy token.
     * @param newAddress The new address of the ERC20 energy token.
     */
    function updateEnergyToken(address newAddress) external onlyOwner {
        energyToken = IERC20(newAddress);
    }
}
