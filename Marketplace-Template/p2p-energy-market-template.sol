// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

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

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, _owner);
    }
}

contract EnergyMarketplace is Ownable {
    IERC20 public energyToken;
    uint256 public pricePerEnergyUnit;
    bool private initialized;

    event EnergyPurchased(address indexed buyer, uint256 amount, uint256 totalCost);
    event EnergySold(address indexed seller, uint256 amount);

    constructor() Ownable() {
        initialized = false;
    }

    function initialize(address _tokenAddress, uint256 _initialPrice) public onlyOwner {
        require(!initialized, "Contract is already initialized");
        energyToken = IERC20(_tokenAddress);
        pricePerEnergyUnit = _initialPrice;
        initialized = true;
    }

    // Function to buy energy credits
    function buyEnergy(uint256 amount) external payable {
        uint256 cost = amount * pricePerEnergyUnit;
        require(msg.value >= cost, "Insufficient payment");
        
        // Transfer energy tokens to buyer
        require(energyToken.transfer(msg.sender, amount), "Energy token transfer failed");

        emit EnergyPurchased(msg.sender, amount, cost);
    }

    // Function for producers to sell energy credits
    function sellEnergy(uint256 amount) external {
        require(energyToken.transferFrom(msg.sender, address(this), amount), "Energy token transfer failed");
        uint256 payment = amount * pricePerEnergyUnit;

        // Pay the seller in Ether
        (bool success, ) = msg.sender.call{value: payment}("");
        require(success, "Payment failed");

        emit EnergySold(msg.sender, amount);
    }

    // Admin function to update the energy token's price
    function updatePrice(uint256 newPrice) external onlyOwner {
        pricePerEnergyUnit = newPrice;
    }

    // Fallback function to handle direct Ether transfers
    receive() external payable {}

    // Withdraw function for admin to withdraw Ether
    function withdrawEther(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    // Update energy token address
    function updateEnergyToken(address newAddress) external onlyOwner {
        energyToken = IERC20(newAddress);
    }
}