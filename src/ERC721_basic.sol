// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title MyToken
 * @dev Implementation of a basic ERC721 Non-Fungible Token (NFT) with metadata.
 * This contract allows for minting and transferring NFTs, with the name and symbol set during deployment.
 */
contract MyToken is ERC721 {
    /**
     * @dev Constructor initializes the ERC721 contract with a given name and symbol.
     * The name and symbol are template variables that will be replaced with user input during deployment.
     * @param name_ The name of the NFT collection.
     * @param symbol_ The symbol of the NFT collection.
     */
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    /**
     * @notice Mint a new token with a specified tokenId to a given address.
     * @dev This function can be expanded to include access control mechanisms such as onlyOwner or onlyAdmin.
     * @param to The address that will receive the minted token.
     * @param tokenId The unique identifier for the minted token.
     */
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    /**
     * @notice Burn a token, removing it from circulation.
     * @dev This function allows the destruction of a token, removing its existence from the blockchain.
     * @param tokenId The unique identifier of the token to be burned.
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    /**
     * @notice Safe mint a new token with a specified tokenId to a given address.
     * @dev Ensures the recipient is capable of receiving ERC721 tokens to prevent token loss.
     * @param to The address that will receive the minted token.
     * @param tokenId The unique identifier for the minted token.
     */
    function safeMint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }

    /**
     * @notice Safe mint a new token with a specified tokenId to a given address with additional data.
     * @dev Ensures the recipient is capable of receiving ERC721 tokens to prevent token loss and forwards additional data.
     * @param to The address that will receive the minted token.
     * @param tokenId The unique identifier for the minted token.
     * @param data Additional data to send along with the minting operation.
     */
    function safeMint(address to, uint256 tokenId, bytes memory data) external {
        _safeMint(to, tokenId, data);
    }

    /**
     * @notice Approve another address to transfer the specified token on behalf of the token owner.
     * @dev This function allows the owner to delegate transfer rights to another address.
     * @param to The address to be approved for transferring the token.
     * @param tokenId The unique identifier of the token to be approved for transfer.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        _approve(to, tokenId, _msgSender());
    }

    /**
     * @notice Set or unset the approval of a given operator to transfer all tokens of the sender.
     * @dev Operators can transfer all tokens of the sender on their behalf if approved.
     * @param operator The address to grant approval to.
     * @param approved The approval status to be set. True for approval, false to revoke approval.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }
}
