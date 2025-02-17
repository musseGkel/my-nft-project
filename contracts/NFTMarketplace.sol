// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct NFT {
        uint256 id;
        string uri;
        address creator;
        uint256 price;
        bool isListed;
        string rarity;  
        string traits;  
    }

    mapping(uint256 => NFT) public nfts;

    event Minted(uint256 indexed tokenId, address indexed creator, string uri, uint256 price, string rarity, string traits);
    event Purchased(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event Listed(uint256 indexed tokenId, uint256 price);
    event Delisted(uint256 indexed tokenId);

    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}

    function mintNFT(string memory tokenURI, uint256 price, string memory rarity, string memory traits) public {
        require(price > 0, "Price must be greater than zero");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        
        nfts[newItemId] = NFT(newItemId, tokenURI, msg.sender, price, false, rarity, traits);
        emit Minted(newItemId, msg.sender, tokenURI, price, rarity, traits);
    }

    function listNFT(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "You must own the NFT to list it");
        require(price > 0, "Price must be greater than zero");
        
        nfts[tokenId].price = price;
        nfts[tokenId].isListed = true;
        emit Listed(tokenId, price);
    }

    function delistNFT(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You must own the NFT to delist it");
        require(nfts[tokenId].isListed, "NFT is not listed");

        nfts[tokenId].isListed = false;
        emit Delisted(tokenId);
    }

    function buyNFT(uint256 tokenId) public payable {
        require(nfts[tokenId].isListed, "NFT is not listed for sale");
        require(msg.value >= nfts[tokenId].price, "Insufficient funds");
        
        address seller = ownerOf(tokenId);
        _transfer(seller, msg.sender, tokenId);
        nfts[tokenId].isListed = false;
        payable(seller).transfer(msg.value);
        
        emit Purchased(tokenId, msg.sender, msg.value);
    }
}
