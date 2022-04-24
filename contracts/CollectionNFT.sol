// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract CollectionNFT is ERC721A, Ownable {

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public cost;
    uint256 public maxSupply;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply
    ) ERC721A(_tokenName, _tokenSymbol) {
        cost = _cost;
        maxSupply = _maxSupply;
    }

    /// @notice Check that the mint amount is valid
    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "CollectionNFT: Invalid mint amount");
        require(totalSupply() + _mintAmount <= maxSupply, "CollectionNFT: Max supply exceeded");
        _;
    }

    /// @notice Check that the payment amount is sufficient
    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "CollectionNFT: Insufficient funds");
        _;
    }

    /// @notice Mint `_mintAmount` tokens for `msg.sender`
    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        _safeMint(_msgSender(), _mintAmount);
    }

    /// @notice Return the token URI if the token exists
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "CollectionNFT: URI query for nonexistent token");
        return string(abi.encodePacked(uriPrefix, Strings.toString(_tokenId), uriSuffix));
    }

    /// @notice Set the cost
    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    /// @notice Set base URI
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    /// @notice Set the file extension
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /// @notice Withdraw the remaining contract balance to the owner
    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }
}
