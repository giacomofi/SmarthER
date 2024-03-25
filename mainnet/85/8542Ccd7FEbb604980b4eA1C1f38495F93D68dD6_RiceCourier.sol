// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract RiceCourier is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public maxPerTx = 20;
    uint256 public maxPerTxFree = 3;
    uint256 public maxSupply = 2500;
    uint256 public freeMintMax = 2223;
    uint256 public price = 0.0025 ether;

    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmXPRrMEfCqkHoWoWGL98h7GVEMEqgn6BiLNjd2VMm9pTu/";
    string public constant baseExtension = ".json";

    bool public paused = true;
    error freeMintIsOver();

    constructor() ERC721A("Rice Courier NFT", "RiceCNFT") {
         _safeMint(msg.sender, 5);
    }

    function mint(uint256 _amount) external payable {
        address _caller = _msgSender();
        require(!paused, "Contract Paused.");
        require(maxSupply >= totalSupply() + _amount, "Minting would exceed maxSupply.");
        require(_amount > 0, "Must mint at least one token.");
        require(maxPerTx >= _amount , "Must mint less than maxPerTx.");
        
        if(freeMintMax >= totalSupply()){
            require(maxPerTxFree >= _amount , "Minting would exceed maxPerTxFree.");
        }else{
            require(maxPerTx >= _amount , "Minting would exceed maxPerTx.");
            require(_amount * price == msg.value, "Insufficient value.");
        }
        _safeMint(_caller, _amount);
    }

    function setMaxFreeMint(uint256 _max) public onlyOwner {
        freeMintMax = _max;
    }

    function setMaxTrxForAll(uint256 _max) public onlyOwner {
        maxPerTx = _max;
    }

    function setMaxTrxFree(uint256 _max) public onlyOwner {
        maxPerTxFree = _max;
    }

    function setMaxxSupply(uint256 _max) public onlyOwner {
        maxSupply = _max;
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function minted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        
        _withdraw(_msgSender(), address(this).balance);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "URI does not exist.");
        return bytes(baseURI).length > 0 ? string( abi.encodePacked( baseURI, Strings.toString(_tokenId), baseExtension)) : "";
    }
}