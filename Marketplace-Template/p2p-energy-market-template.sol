// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin-5.0.1/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-5.0.1/contracts/access/Ownable.sol";

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
    constructor() Ownable() {
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
