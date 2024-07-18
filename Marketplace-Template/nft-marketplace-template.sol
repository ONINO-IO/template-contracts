// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// NFT Marketplace contract
contract NFTMarketplace {
    struct Listing {
        address seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    address public owner;
    uint256 public listingFee = 0.01 ether;
    mapping(uint256 => Listing) public listings;
    uint256 private _listingId = 0;
    bool private _notEntered;

    event Listed(uint256 indexed listingId, address indexed seller, address indexed tokenAddress, uint256 tokenId, uint256 price);
    event Sale(uint256 indexed listingId, address indexed buyer, uint256 price);
    event ListingUpdated(uint256 indexed listingId, uint256 price);
    event ListingCancelled(uint256 indexed listingId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    constructor() {
        owner = msg.sender;
        _notEntered = true;
    }

    // Simplified listToken function without IERC721 compliance checks
    function listToken(address tokenAddress, uint256 tokenId, uint256 price) external payable nonReentrant {
        require(msg.value == listingFee, "Incorrect listing fee");
        require(price > 0, "Price must be greater than zero");

        uint256 listingId = _listingId++;
        listings[listingId] = Listing(msg.sender, tokenAddress, tokenId, price, true);

        emit Listed(listingId, msg.sender, tokenAddress, tokenId, price);
    }

    // Simplified buyToken function without IERC721 transfer call
    function buyToken(uint256 listingId) external payable nonReentrant {
        Listing memory listing = listings[listingId];
        require(listing.active, "Listing is not active");
        require(msg.value == listing.price, "Incorrect value sent");

        payable(listing.seller).transfer(listing.price);
        listing.active = false;
        listings[listingId] = listing;

        emit Sale(listingId, msg.sender, listing.price);
    }

    function updateListing(uint256 listingId, uint256 newPrice) external {
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender, "Not the seller");
        require(listing.active, "Listing is not active");

        listing.price = newPrice;
        emit ListingUpdated(listingId, newPrice);
    }

    function cancelListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender, "Not the seller");
        require(listing.active, "Listing is not active");

        listing.active = false;
        emit ListingCancelled(listingId);
    }

    function setListingFee(uint256 newFee) external onlyOwner {
        listingFee = newFee;
    }
}