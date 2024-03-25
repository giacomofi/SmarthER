pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract NFT_Contract is ERC721A, Ownable {
    using Strings for uint256;
    mapping(address => uint256) public whitelistClaimed;

    string public baseURI;
    uint256 public whitelistCost = 0.11 ether;
    uint256 public publicCost = 0.11 ether;
    bool public whitelistEnabled = false;
    string public baseExtension = ".json";

    bool public paused = true;
    bool public freeMint;
    bytes32 public merkleRoot;
    uint256 public maxWhitelist = 1; // initial for the free mint
    uint256 public maxPublic = 10;
    uint256 public maxTX = 1;
    uint256 public maxSupply = 3333;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof)
        public
        payable
    {
        uint256 supply = totalSupply();
        require(quantity <= maxTX, "Please Check Your Quantity Amount");
        require(supply + quantity <= maxSupply, "Max Supply Reached");
        require(whitelistEnabled, "The whitelist sale is not enabled!");
        require(
            whitelistClaimed[msg.sender] + quantity <= maxWhitelist,
            "You're not allowed to mint this Much!"
        );
        if (!freeMint)
            require(
                msg.value >= whitelistCost * quantity,
                "Insufficient Funds"
            );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable {
        uint256 supply = totalSupply();
        require(!paused, "The contract is paused!");
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(supply + quantity <= maxSupply, "Max Supply Reached");

        if (msg.sender != owner()) {
            require(
                quantity <= maxPublic,
                "You're Not Allowed To Mint more than maxMint Amount"
            );
            require(msg.value >= publicCost * quantity, "Insufficient Funds");
        }
        _safeMint(msg.sender, quantity);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setCost(uint256 _whitelistCost, uint256 _publicCost)
        public
        onlyOwner
    {
        whitelistCost = _whitelistCost;
        publicCost = _publicCost;
    }

    function setFreeMint(bool _Status) public onlyOwner {
        freeMint = _Status;
    }

    function ActivateWhitelist() public onlyOwner {
        freeMint = false;
        maxWhitelist = 5;
        whitelistEnabled = true;
    }

    function setMax(
        uint256 _whitelist,
        uint256 _public,
        uint256 _normalTX
    ) public onlyOwner {
        maxWhitelist = _whitelist;
        maxPublic = _public;
        maxTX = _normalTX;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistEnabled(bool _state) public onlyOwner {
        whitelistEnabled = _state;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}