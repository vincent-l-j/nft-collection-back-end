// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


//   ______             __  __                        __      __                            __    __  ________  ________
//  /      \           /  |/  |                      /  |    /  |                          /  \  /  |/        |/        |
// /$$$$$$  |  ______  $$ |$$ |  ______    _______  _$$ |_   $$/   ______   _______        $$  \ $$ |$$$$$$$$/ $$$$$$$$/
// $$ |  $$/  /      \ $$ |$$ | /      \  /       |/ $$   |  /  | /      \ /       \       $$$  \$$ |$$ |__       $$ |
// $$ |      /$$$$$$  |$$ |$$ |/$$$$$$  |/$$$$$$$/ $$$$$$/   $$ |/$$$$$$  |$$$$$$$  |      $$$$  $$ |$$    |      $$ |
// $$ |   __ $$ |  $$ |$$ |$$ |$$    $$ |$$ |        $$ | __ $$ |$$ |  $$ |$$ |  $$ |      $$ $$ $$ |$$$$$/       $$ |
// $$ \__/  |$$ \__$$ |$$ |$$ |$$$$$$$$/ $$ \_____   $$ |/  |$$ |$$ \__$$ |$$ |  $$ |      $$ |$$$$ |$$ |         $$ |
// $$    $$/ $$    $$/ $$ |$$ |$$       |$$       |  $$  $$/ $$ |$$    $$/ $$ |  $$ |      $$ | $$$ |$$ |         $$ |
//  $$$$$$/   $$$$$$/  $$/ $$/  $$$$$$$/  $$$$$$$/    $$$$/  $$/  $$$$$$/  $$/   $$/       $$/   $$/ $$/          $$/


contract CollectionNFT is ERC721A, Ownable {

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;

    bool public paused = true;
    bool public revealed = false;
    bool public whitelistMintEnabled = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        cost = _cost;
        maxSupply = _maxSupply;
        maxMintAmountPerTx = _maxMintAmountPerTx;
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    /// @notice Check that the mint amount is valid
    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "CollectionNFT: Invalid mint amount");
        require(_mintAmount <= maxMintAmountPerTx, "CollectionNFT: Max mint amount per transaction exceeded");
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
        require(!paused, "CollectionNFT: The contract is paused");

        _safeMint(_msgSender(), _mintAmount);
    }

    /// @notice Mint when whitelist is enabled
    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "CollectionNFT: The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "CollectionNFT: Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "CollectionNFT: Invalid proof!");

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    /// @notice Return the token URI if the token exists
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "CollectionNFT: URI query for nonexistent token");

        if (!revealed) {
            return hiddenMetadataUri;
        }

        return string(abi.encodePacked(uriPrefix, Strings.toString(_tokenId), uriSuffix));
    }

    /// @notice Set the cost
    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    /// @notice Set the hidden metadata URI
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    /// @notice Set the max mint amount per transaction
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    /// @notice Set the merkleroot of whitelisted addresses
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @notice Pause or unpause the contract
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    /// @notice Reveal or hide the collection
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    /// @notice Set base URI
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    /// @notice Set the file extension
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /// @notice Enable or disable whitelist minting
    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    /// @notice Withdraw the remaining contract balance to the owner
    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }
}
