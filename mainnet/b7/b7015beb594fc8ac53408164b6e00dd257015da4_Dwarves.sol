// SPDX-License-Identifier: No License
// ERC721A Contracts v4.2.3
// Creator: Aurae

/*
Dwarves of Thurinor is a collection of digital artworks (NFTs) running on the Ethereum network. 
Users are entirely responsible for the safety and management of their own private Ethereum wallets and for validating 
all transactions and contracts generated by this website before approval. 
The Dwarves of Thurinor Smart Contract runs on the Ethereum network, so there is no ability to undo, reverse, or restore any transactions.


This contract and its connected services are provided without warranty of any kind. By using this website you are accepting sole 
responsibility for any and all transactions involving the Dwarves of Thurinor artwork. 
We do not encourage speculation of any kind and remind people that this is an artwork and the price reflects the artistic value and cost of production.
We have no roadmap. Do not buy our artwork if you expect anything more than art. Everything we do for the community, we do voluntarily and without promises.
There are no promises of financial returns attached to this artwork.
*/

pragma solidity ^0.8.4;

import './ERC721A.sol';
import './Ownable.sol';
import './DefaultOperatorFilterer.sol';


contract Dwarves is ERC721A, DefaultOperatorFilterer, Ownable {
    // =============================================================
    //                           STORAGE
    // =============================================================

    uint256 constant private MAX_SUPPLY = 10000;
    uint256 private MAX_MINT = 2;
    uint256 public RESERVED = 400;

    uint256 private cost = 0.0 ether;

    bool public paused = true;
    bool public revealed = false;

    string private baseExtension = ".json";
    string public notRevealedUri;


    // =============================================================
    //                           CONSTRUCTOR
    // =============================================================

    constructor() ERC721A("Dwarves of Thurinor", "DWARF") {}


    // =============================================================
    //                           FUNCTIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _getBaseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), baseExtension))
            : "";
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function mint(uint256 quantity) public payable {
        require(!paused, "Dwarves: Mint is paused");
        require(withinTotalSupply(quantity), "Dwarves: Total Supply exceeded");
        require(uint256(_getAux(msg.sender)) + quantity <= MAX_MINT, "Dwarves: Maximum mint amount exceeded");
        require(msg.value == cost * quantity, "Dwarves: Insufficient balance");

        // update amount minted
        uint64 minted = _getAux(msg.sender);
        _setAux(msg.sender, uint64(quantity) + minted);

        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _setBaseURI(newBaseURI);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setCost(uint256 newCost) public onlyOwner {
        cost = newCost;
    }

    function setReserved(uint256 reserved) public onlyOwner {
        RESERVED = reserved;
    }

    function setMaxMint(uint256 maxMint) public onlyOwner {
        MAX_MINT = maxMint;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success);
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function mintManyOnlyOwner(address[] calldata _users, uint256[] calldata _quantities) public onlyOwner {
        require(_users.length == _quantities.length, "Dwarves: Lists have different sizes");

        for (uint256 i = 0; i < _users.length; i++) {
            require(totalSupply() + _quantities[i] <= MAX_SUPPLY, "Dwarves: Total Supply exceeded");

            _mint(_users[i], _quantities[i]);
        }
    }

    function mintOnlyOwner(address receiver, uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Dwarves: Total Supply exceeded");
      
        _mint(receiver, quantity);
    }

    function mintReserved(address receiver, uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Dwarves: Total Supply exceeded");
        require(quantity <= RESERVED, "Dwarves: Reserved Supply exceeded");

        // lower reserved amount
        RESERVED -= quantity;

        _mint(receiver, quantity);
    }

    function getCost() public view returns(uint256) {
        return cost;
    }

    function withinTotalSupply(uint256 quantity) private view returns(bool) {
        return totalSupply() + quantity + RESERVED <= MAX_SUPPLY;
    }

    function getNumberMinted(address owner) public view returns(uint256) {
        return uint256(_getAux(owner));
    }
}