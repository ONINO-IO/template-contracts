// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title NFTMarketplace
 * @dev A marketplace for buying and selling NFTs with listing fees and non-reentrant protections.
 * This contract allows users to list, buy, update, and cancel listings of NFTs.
 */
contract NFTMarketplace is Ownable, ReentrancyGuard {
    /// @notice Struct to hold listing details
    struct Listing {
        address seller;        /// @notice The address of the seller.
        address tokenAddress;  /// @notice The address of the NFT contract.
        uint256 tokenId;       /// @notice The ID of the NFT.
        uint256 price;         /// @notice The listing price in Wei.
        bool active;           /// @notice Indicates if the listing is active.
    }

    /// @notice Fee for listing an NFT on the marketplace
    uint256 public listingFee = 0.01 ether;
    uint256 private _listingId = 0;

    /// @notice Mapping to store listings by their IDs
    mapping(uint256 => Listing) public listings;

    /// @notice Event emitted when an NFT is listed
    /// @param listingId The ID of the listing
    /// @param seller The address of the seller
    /// @param tokenAddress The address of the NFT contract
    /// @param tokenId The ID of the NFT
    /// @param price The listing price in Wei
    event Listed(uint256 indexed listingId, address indexed seller, address indexed tokenAddress, uint256 tokenId, uint256 price);

    /// @notice Event emitted when an NFT is sold
    /// @param listingId The ID of the listing
    /// @param buyer The address of the buyer
    /// @param price The sale price in Wei
    event Sale(uint256 indexed listingId, address indexed buyer, uint256 price);

    /// @notice Event emitted when a listing is updated
    /// @param listingId The ID of the listing
    /// @param price The updated listing price in Wei
    event ListingUpdated(uint256 indexed listingId, uint256 price);

    /// @notice Event emitted when a listing is cancelled
    /// @param listingId The ID of the listing
    event ListingCancelled(uint256 indexed listingId);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() Ownable(msg.sender) ReentrancyGuard() {}

    /**
     * @notice Lists an NFT on the marketplace.
     * @dev The NFT must be approved for transfer by this contract. The caller must pay the listing fee.
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
        listings[listingId] = Listing({
            seller: msg.sender,
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            price: price,
            active: true
        });

        emit Listed(listingId, msg.sender, tokenAddress, tokenId, price);
    }

    /**
     * @notice Buys an NFT from the marketplace.
     * @dev The caller must send the exact price in Wei. The listing must be active.
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
     * @dev Only the seller can update the listing. The listing must be active.
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
     * @dev Only the seller can cancel the listing. The listing must be active.
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
     * @dev Only the owner can set the listing fee.
     * @param newFee New listing fee in Wei.
     */
    function setListingFee(uint256 newFee) external onlyOwner {
        listingFee = newFee;
    }

    /**
     * @notice Withdraws Ether from the contract.
     * @dev Only the owner can withdraw Ether. The contract must have a sufficient balance.
     * @param amount Amount of Ether to withdraw in Wei.
     */
    function withdrawEther(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev Fallback function to handle direct Ether transfers.
     * Allows the contract to receive Ether directly.
     */
    receive() external payable {}
}
