// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin-5.0.1/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin-5.0.1/contracts/access/Ownable.sol";
import "@openzeppelin-5.0.1/contracts/security/ReentrancyGuard.sol";

/**
 * @title NFTMarketplace
 * @dev A marketplace for buying and selling NFTs with listing fees and non-reentrant protections.
 */
contract NFTMarketplace is Ownable, ReentrancyGuard {
    struct Listing {
        address seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    /// @notice Fee for listing an NFT on the marketplace
    uint256 public listingFee = 0.01 ether;
    uint256 private _listingId = 0;

    mapping(uint256 => Listing) public listings;

    /// @notice Event emitted when an NFT is listed
    event Listed(uint256 indexed listingId, address indexed seller, address indexed tokenAddress, uint256 tokenId, uint256 price);

    /// @notice Event emitted when an NFT is sold
    event Sale(uint256 indexed listingId, address indexed buyer, uint256 price);

    /// @notice Event emitted when a listing is updated
    event ListingUpdated(uint256 indexed listingId, uint256 price);

    /// @notice Event emitted when a listing is cancelled
    event ListingCancelled(uint256 indexed listingId);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() Ownable() ReentrancyGuard() {}

    /**
     * @notice Lists an NFT on the marketplace.
     * @dev The NFT must be approved for transfer by this contract.
     * @param tokenAddress Address of the NFT contract.
     * @param tokenId ID of the NFT to list.
     * @param price Listing price in Wei.
     */
    function listToken(address tokenAddress, uint256 tokenId, uint256 price) external payable nonReentrant {
        require(msg.value == listingFee, "Incorrect listing fee");
        require(price > 0, "Price must be greater than zero");

        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender, "Caller is not the owner of the token");
        require(tokenContract.isApprovedForAll(msg.sender, address(this)) || tokenContract.getApproved(tokenId) == address(this), "Contract is not approved to transfer this token");

        uint256 listingId = _listingId++;
        listings[listingId] = Listing(msg.sender, tokenAddress, tokenId, price, true);

        emit Listed(listingId, msg.sender, tokenAddress, tokenId, price);
    }

    /**
     * @notice Buys an NFT from the marketplace.
     * @param listingId ID of the listing to buy.
     */
    function buyToken(uint256 listingId) external payable nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing is not active");
        require(msg.value == listing.price, "Incorrect value sent");

        listing.active = false;
        listings[listingId] = listing;

        // Transfer payment to the seller
        (bool paymentSuccess, ) = payable(listing.seller).call{value: listing.price}("");
        require(paymentSuccess, "Payment to seller failed");

        // Transfer the NFT to the buyer
        IERC721(listing.tokenAddress).safeTransferFrom(listing.seller, msg.sender, listing.tokenId);

        emit Sale(listingId, msg.sender, listing.price);
    }

    /**
     * @notice Updates the price of an active listing.
     * @param listingId ID of the listing to update.
     * @param newPrice New price in Wei.
     */
    function updateListing(uint256 listingId, uint256 newPrice) external {
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender, "Caller is not the seller");
        require(listing.active, "Listing is not active");

        listing.price = newPrice;
        emit ListingUpdated(listingId, newPrice);
    }

    /**
     * @notice Cancels an active listing.
     * @param listingId ID of the listing to cancel.
     */
    function cancelListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender, "Caller is not the seller");
        require(listing.active, "Listing is not active");

        listing.active = false;
        emit ListingCancelled(listingId);
    }

    /**
     * @notice Sets the listing fee.
     * @param newFee New listing fee in Wei.
     */
    function setListingFee(uint256 newFee) external onlyOwner {
        listingFee = newFee;
    }

    /**
     * @notice Withdraws Ether from the contract.
     * @param amount Amount of Ether to withdraw in Wei.
     */
    function withdrawEther(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev Fallback function to handle direct Ether transfers.
     */
    receive() external payable {}
}
