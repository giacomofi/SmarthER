// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/INFT.sol";
import "./interfaces/ITOPIA.sol";
import "./interfaces/IHub.sol";
import "./interfaces/IDogeWorld.sol";
import "./interfaces/IRandomizer.sol";

contract DogeWorld is IDogeWorld, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    // maximum rank for a Dog/Cat
    uint8 public constant MAX_RANK = 8;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
        uint80 stakedAt;
    }

    // struct to store a stake's token, owner, and earning values
    struct StakeAlpha {
        uint16 tokenId;
        uint80 value;
        address owner;
        uint80 stakedAt;
    }

    mapping(uint16 => uint8) public genesisType;

    // number of Cats staked
    uint256 private numCatsStaked;
    // number of Dog staked
    uint256 private numDogStaked;
    // number of Veterinarian staked
    uint256 private numVeterinarianStaked;
    // number of Alpha staked
    uint256 private numAlphasStaked;

    uint256 public PERIOD = 1 days;

    event TokenStaked(address indexed owner, uint256 indexed tokenId, uint8 tokenType, uint256 value);
    event CatClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event CatUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event CatStolen(uint16 indexed tokenId, address indexed victim, address indexed thief, uint256 blockNum, uint256 timeStamp);
    event DogClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event DogUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event DogStolen(uint16 indexed tokenId, address indexed victim, address indexed thief, uint256 blockNum, uint256 timeStamp);
    event VeterinarianClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event VeterinarianUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event AlphaStaked(address indexed owner, uint256 indexed tokenId, uint256 value);
    event AlphaClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event AlphaUnstaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);

    // reference to the NFT contract
    INFT public lfGenesis;

    INFT public lfAlpha;

    // reference to the $TOPIA contract for minting $TOPIA earnings
    ITOPIA public TOPIAToken;

    IHub public HUB;

    // reference to Randomizer
    IRandomizer public randomizer;
    address payable vrf;

    // maps Cat tokenId to stake
    mapping(uint256 => Stake) private cat;

    // maps Alpha tokenId to stakeAlpha
    mapping(uint256 => StakeAlpha) private alpha;

    // maps Dog tokenId to stake
    mapping(uint256 => Stake) private dog;
    // array of Dog token ids;
    // uint256[] private yieldIds;
    EnumerableSet.UintSet private dogIds;
    // maps Veterinarian tokenId to stake
    mapping(uint256 => Stake) private veterinarian;
    // array of Veterinarian token ids;
    EnumerableSet.UintSet private veterinarianIds;

    mapping(address => uint256) ownerBalanceStaked;

    // array of Owned Genesis token ids;
    mapping(address => EnumerableSet.UintSet) genesisOwnedIds;
    // array of Owned Alpha token ids;
    mapping(address => EnumerableSet.UintSet) alphaOwnedIds;


    // any rewards distributed when no Dogs are staked
    uint256 private unaccountedDogRewards;
    // amount of $TOPIA due for each dog staked
    uint256 private TOPIAPerDog;
    // any rewards distributed when no Veterinarians are staked
    uint256 private unaccountedVeterinarianRewards;
    // amount of $TOPIA due for each Veterinarian staked
    uint256 private TOPIAPerVeterinarian;

    // Cats earn 20 $TOPIA per day
    uint256 public DAILY_CAT_RATE = 20 * 10**18;

    // Cats earn 35 $TOPIA per day
    uint256 public DAILY_ALPHA_RATE = 35 * 10**18;

    // Cats must have 2 days worth of $TOPIA to un-stake or else they're still remaining the armory
    uint256 public MINIMUM = 40 * 10**18;

    // rolling price
    uint256 public UPGRADE_COST = 40 * 10**18;

    // Veterinarians take a 3% tax on all $TOPIA claimed
    uint256 public DOG_TAX_RATE = 300;

    // Veterinarians take a 3% tax on all $TOPIA from upgrades
    uint256 public VETERINARIAN_TAX_RATE = 300;

    // tx cost for getting random numbers
    uint256 public SEED_COST = .0008 ether;

    // amount of $TOPIA earned so far
    uint256 public totalTOPIAEarned;
    // the last time $TOPIA was claimed
    uint80 public claimEndTime;

    // emergency rescue to allow un-staking without any checks but without $TOPIA
    bool public rescueEnabled = false;

    /**
     */
    constructor() {
        _pause();
    }

    /** CRITICAL TO SETUP */

    modifier requireContractsSet() {
        require(address(lfGenesis) != address(0) && address(TOPIAToken) != address(0)
        && address(randomizer) != address(0) && address(HUB) != address(0), "Contracts not set");
        _;
    }

    function setContracts(address _lfGenesis, address _lfAlpha, address _TOPIA, address _HUB, address payable _rand) external onlyOwner {
        lfGenesis = INFT(_lfGenesis);
        lfAlpha = INFT(_lfAlpha);
        TOPIAToken = ITOPIA(_TOPIA);
        randomizer = IRandomizer(_rand);
        HUB = IHub(_HUB);
        vrf = _rand;
    }

    // mass update the nftType mapping
    function setBatchNFTType(uint16[] calldata tokenIds, uint8[] calldata _types) external onlyOwner {
        require(tokenIds.length == _types.length , " _idNumbers.length != _types.length: Each token ID must have exactly 1 corresponding type!");
        for (uint16 i = 0; i < tokenIds.length; i++) {
            require(_types[i] != 0 , "Invalid nft type - cannot be 0");
            genesisType[tokenIds[i]] = _types[i];
        }
    }


    /** STAKING */

    /**
     * adds Dogs and Cat
     * @param account the address of the staker
   * @param tokenIds the IDs of the Dogs and Cat to stake
   */
    function addManyToStakingPool(address account, uint16[] calldata tokenIds) external override nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(lfGenesis.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");

            if (genesisType[tokenIds[i]] == 1) {
                lfGenesis.transferFrom(msg.sender, address(this), tokenIds[i]);
                _addCatToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 2) {
                lfGenesis.transferFrom(msg.sender, address(this), tokenIds[i]);
                _addDogToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 3) {
                lfGenesis.transferFrom(msg.sender, address(this), tokenIds[i]);
                _addVeterinarianToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 0) {
                revert('invalid token id');
            }

        }
        HUB.emitGenesisStaked(account, tokenIds, 2);
    }

    /**
     * adds a single Dog to the Armory
     * @param account the address of the staker
   * @param tokenId the ID of the Dog/Veterinarian to add to the Staking Pool
   */
    function _addDogToStakingPool(address account, uint256 tokenId) internal whenNotPaused {
        dog[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(TOPIAPerDog),
        stakedAt : uint80(block.timestamp)
        });
        dogIds.add(tokenId);
        genesisOwnedIds[account].add(tokenId);
        numDogStaked += 1;
        emit TokenStaked(account, tokenId, 2, TOPIAPerDog);
    }


    /**
     * adds a single Veterinarian to the Armory
     * @param account the address of the staker
   * @param tokenId the ID of the Dog/Veterinarian to add to the Staking Pool
   */
    function _addVeterinarianToStakingPool(address account, uint256 tokenId) internal whenNotPaused {
        veterinarian[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(TOPIAPerVeterinarian),
        stakedAt : uint80(block.timestamp)
        });
        veterinarianIds.add(tokenId);
        genesisOwnedIds[account].add(tokenId);
        numVeterinarianStaked += 1;
        emit TokenStaked(account, tokenId, 3, TOPIAPerVeterinarian);
    }


    /**
     * adds a single Cat to the armory
     * @param account the address of the staker
   * @param tokenId the ID of the Cat to add to the Staking Pool
   */
    function _addCatToStakingPool(address account, uint256 tokenId) internal {
        cat[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(block.timestamp),
        stakedAt : uint80(block.timestamp)
        });
        // Add the cat to the armory
        genesisOwnedIds[account].add(tokenId);
        numCatsStaked += 1;
        emit TokenStaked(account, tokenId, 1, block.timestamp);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $TOPIA earnings and optionally unstake tokens from the Armory / Yield
     * to unstake a Cat it will require it has 2 days worth of $TOPIA unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyFromArmoryAndYield(uint16[] calldata tokenIds, bool unstake) external payable whenNotPaused nonReentrant returns (uint16[] memory stolenNFTs){
        require(tx.origin == msg.sender, "Only EOA");
        uint256 numWords = tokenIds.length;
        require(msg.value == SEED_COST * numWords, "Invalid value for randomness");
        
        if(unstake) { 
            stolenNFTs = new uint16[](numWords);
            HUB.emitGenesisUnstaked(msg.sender, tokenIds);
        } else {
            stolenNFTs = new uint16[](1);
            stolenNFTs[0] = 0;
        }
        uint256 remainingWords = randomizer.getRemainingWords();
        require(remainingWords >= numWords, "Not enough random numbers. Please try again soon.");
        uint256[] memory seed = randomizer.getRandomWords(numWords);
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (genesisType[tokenIds[i]] == 1) {
                (uint256 _owed, uint16 _stolen) = _claimCatFromArmory(tokenIds[i], unstake, seed[i]);
                owed += _owed;
                if(unstake) {stolenNFTs[i] = _stolen;}
            } else if (genesisType[tokenIds[i]] == 2) {
                (uint256 _owed, uint16 _stolen) = _claimDogFromYield(tokenIds[i], unstake, seed[i]);
                owed += _owed;
                if(unstake) {stolenNFTs[i] = _stolen;}
            } else if (genesisType[tokenIds[i]] == 3) {
                owed += _claimVeterinarianFromYield(tokenIds[i], unstake);
            } else if (genesisType[tokenIds[i]] == 0) {
                revert('invalid token id');
            }
        }
        if (owed == 0) {
            return stolenNFTs;
        }
        totalTOPIAEarned += owed;
        TOPIAToken.mint(msg.sender, owed);
        HUB.emitTopiaClaimed(msg.sender, owed);
        vrf.transfer(msg.value);
    }


    /**
     * realize $TOPIA earnings for a single Cat and optionally unstake it
     * if not unstaking, lose x% chance * y% percent of accumulated $TOPIA to the staked Dogs based on it's upgrade
     * if unstaking, there is a % chanc of losing Cat NFT
     * @param tokenId the ID of the Cat to claim earnings from
   * @param unstake whether or not to unstake the Cat
   * @return owed - the amount of $TOPIA earned
   */
    function _claimCatFromArmory(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed, uint16 tokId) {     
        require(cat[tokenId].owner == msg.sender, "Don't own the given token");
        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - cat[tokenId].value) * DAILY_CAT_RATE / PERIOD;
        } else if (cat[tokenId].value < claimEndTime) {
            owed = (claimEndTime - cat[tokenId].value) * DAILY_CAT_RATE / PERIOD;
        } else {
            owed = 0;
        }

        uint256 seedChance = seed >> 16;
        bool stolen = false;
        address thief;
        if (unstake) {
            if ((seed & 0xFFFF) % 100 < 10) {
                thief = randomDogOwner(seed);
                lfGenesis.safeTransferFrom(address(this), thief, tokenId);
                stolen = true;
            } else {
                // lose accumulated tokens 50% chance and 60 percent of all token
                if ((seedChance & 0xFFFF) % 100 < 50) {
                    _payTax(owed * 25 / 100);
                    owed = owed * 75 / 100;
                }
            }
            delete cat[tokenId];
            numCatsStaked -= 1;
            genesisOwnedIds[msg.sender].remove(tokenId);
            if (stolen) {
                emit CatStolen(tokenId, msg.sender, thief, block.number, block.timestamp);
                tokId = tokenId;
            } else {
                // Always transfer last to guard against reentrance
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
            }
            emit CatUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {// Claiming
            // lose accumulated tokens 50% chance and 25 percent of all token
            if ((seedChance & 0xFFFF) % 100 < 50) {
                _payTax(owed * 25 / 100);
                owed = owed * 75 / 100;
            }
            cat[tokenId].value = uint80(block.timestamp);
            // reset stake
        }
        emit CatClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $TOPIA earnings for a single Dog and optionally unstake it
     * Dogs earn $TOPIA
     * @param tokenId the ID of the Dog to claim earnings from
   * @param unstake whether or not to unstake the Dog
   */
    function _claimDogFromYield(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed, uint16 tokId) {
        require(dog[tokenId].owner == msg.sender, "Doesn't own given token");
        owed = TOPIAPerDog - dog[tokenId].value;
        if (unstake) {
            address thief;
            bool stolen;
            if ((seed & 0xFFFF) % 100 < 10) {
                thief = randomVeterinarianOwner(seed);
                lfGenesis.safeTransferFrom(address(this), thief, tokenId);
                stolen = true;
            }

            delete dog[tokenId];
            dogIds.remove(tokenId);
            genesisOwnedIds[msg.sender].remove(tokenId);
            numDogStaked -= 1;
            // Always remove last to guard against reentrance
            if (stolen) {
                emit DogStolen(tokenId, msg.sender, thief, block.number, block.timestamp);
                tokId = tokenId;
            } else {
                
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
            }
            emit DogUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {
            dog[tokenId].value = uint80(TOPIAPerDog);
            // reset stake

        }
        emit DogClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $TOPIA earnings for a Veterinarian Dog and optionally unstake it
     * Dogs earn $TOPIA
     * @param tokenId the ID of the Dog to claim earnings from
   * @param unstake whether or not to unstake the Veterinarian Dog
   */
    function _claimVeterinarianFromYield(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(veterinarian[tokenId].owner == msg.sender, "Doesn't own given token");
        owed = TOPIAPerVeterinarian - veterinarian[tokenId].value;
        if (unstake) {
            delete veterinarian[tokenId];
            veterinarianIds.remove(tokenId);
            genesisOwnedIds[msg.sender].remove(tokenId);
            numVeterinarianStaked -= 1;
            // Always remove last to guard against reentrance
            lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
            // Send back Veterinarian
            emit VeterinarianUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {
            veterinarian[tokenId].value = uint80(TOPIAPerVeterinarian);
            // reset stake

        }
        emit VeterinarianClaimed(tokenId, unstake, owed);
    }


    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
   */
    function rescue(uint16[] calldata tokenIds) external nonReentrant {
        require(rescueEnabled, "RESCUE DISABLED");
        uint16 tokenId;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            
            if (genesisType[tokenId] == 1) {
                require(cat[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");
                delete cat[tokenId];
                genesisOwnedIds[msg.sender].remove(tokenId);
                numCatsStaked -= 1;
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
                emit CatClaimed(tokenId, true, 0);
            } else if (genesisType[tokenId] == 2) {
                require(dog[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");
                delete dog[tokenId];
                dogIds.remove(tokenId);
                genesisOwnedIds[msg.sender].remove(tokenId);
                numDogStaked -= 1;
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
                emit DogClaimed(tokenId, true, 0);
            } else if (genesisType[tokenId] == 3) {
                require(veterinarian[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");
                delete veterinarian[tokenId];
                veterinarianIds.remove(tokenId);
                genesisOwnedIds[msg.sender].remove(tokenId);
                numVeterinarianStaked -= 1;
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
                emit VeterinarianClaimed(tokenId, true, 0);
            } else if (genesisType[tokenIds[i]] == 0) {
                revert('invalid token id');
            }
        }
        HUB.emitGenesisUnstaked(msg.sender, tokenIds);
    }

    /** ACCOUNTING */

    /**
     * add $TOPIA to claimable pot for the Yield
     * @param amount $TOPIA to add to the pot
   */
    function _payTax(uint256 amount) internal {
        uint256 _dogTax = amount * DOG_TAX_RATE / 10000;
        uint256 _vetTax = amount * VETERINARIAN_TAX_RATE / 10000;
        if (numDogStaked == 0 && numVeterinarianStaked == 0) {// if there's no staked dogs
            unaccountedDogRewards += _dogTax;
            unaccountedVeterinarianRewards += _vetTax;
            // keep track of $TOPIA due to dogs
            return;
        } else if (numDogStaked == 0 && numVeterinarianStaked > 0) {
            unaccountedDogRewards += _dogTax;
            TOPIAPerVeterinarian += (_vetTax + unaccountedVeterinarianRewards) / numVeterinarianStaked;
            unaccountedVeterinarianRewards = 0;
            return;
        } else if (numDogStaked > 0 && numVeterinarianStaked == 0) {
            TOPIAPerDog += (_dogTax + unaccountedDogRewards) / numDogStaked;
            unaccountedDogRewards = 0;
            unaccountedVeterinarianRewards += _vetTax;
            return;
        } else {
            TOPIAPerDog += (amount + unaccountedDogRewards) / numDogStaked;
            unaccountedDogRewards = 0;
            TOPIAPerVeterinarian += (amount + unaccountedVeterinarianRewards) / numVeterinarianStaked;
            unaccountedVeterinarianRewards = 0;
        }
    }

    /**
     * add $TOPIA to claimable pot for the Veterinarian Yield
     * @param amount $TOPIA to add to the pot
   */
    function _payVeterinarianTax(uint256 amount) internal {
        if (numVeterinarianStaked == 0) {// if there's no staked veterinarians
            unaccountedVeterinarianRewards += amount;
            // keep track of $TOPIA due to veterinarians
            return;
        }
        // makes sure to include any unaccounted $GP
        TOPIAPerVeterinarian += (amount + unaccountedVeterinarianRewards) / numVeterinarianStaked;
        unaccountedVeterinarianRewards = 0;
    }

    /** ALPHA FUNCTIONS */

    /**
     * adds Dogs and Cat
     * @param account the address of the staker
   * @param tokenIds the IDs of the Dogs and Cat to stake
   */
    function addManyAlphaToStakingPool(address account, uint16[] calldata tokenIds) external nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(lfAlpha.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");
            lfAlpha.transferFrom(msg.sender, address(this), tokenIds[i]);

            alpha[tokenIds[i]] = StakeAlpha({
            owner : account,
            tokenId : uint16(tokenIds[i]),
            value : uint80(block.timestamp),
            stakedAt : uint80(block.timestamp)
            });
            // Add the cat to the armory
            alphaOwnedIds[account].add(tokenIds[i]);
            numAlphasStaked += 1;
            emit AlphaStaked(account, tokenIds[i], block.timestamp);
        }
        HUB.emitAlphaStaked(account, tokenIds, 2);
    }

    /**
     * realize $TOPIA earnings and optionally unstake Alpha tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyAlphas(uint16[] calldata tokenIds, bool unstake) external whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) { 
            require(alpha[tokenIds[i]].owner == msg.sender, "Don't own the given token");
            
            if(block.timestamp <= claimEndTime) {
                owed += (block.timestamp - alpha[tokenIds[i]].value) * DAILY_ALPHA_RATE / PERIOD;
            } else if (alpha[tokenIds[i]].value < claimEndTime) {
                owed += (claimEndTime - alpha[tokenIds[i]].value) * DAILY_ALPHA_RATE / PERIOD;
            } else {
                owed += 0;
            }

            if (unstake) {
                delete alpha[tokenIds[i]];
                numAlphasStaked -= 1;
                alphaOwnedIds[msg.sender].remove(tokenIds[i]);
                lfAlpha.transferFrom(address(this), msg.sender, tokenIds[i]);
                emit AlphaUnstaked(msg.sender, tokenIds[i], block.number, block.timestamp);
            } else {
                alpha[tokenIds[i]].value = uint80(block.timestamp);
            }
            emit AlphaClaimed(tokenIds[i], unstake, owed);
        }
        if (owed == 0) {
            return;
        }
        if(unstake) { HUB.emitAlphaUnstaked(msg.sender, tokenIds); }
        HUB.emitTopiaClaimed(msg.sender, owed);
        TOPIAToken.mint(msg.sender, owed);
        totalTOPIAEarned += owed;
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
   */
    function rescueAlpha(uint16[] calldata tokenIds) external nonReentrant {
        require(rescueEnabled, "RESCUE DISABLED");
        uint16 tokenId;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(alpha[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");

            delete alpha[tokenId];
            numAlphasStaked -= 1;
            alphaOwnedIds[msg.sender].remove(tokenId);
            lfAlpha.transferFrom(address(this), msg.sender, tokenId);
            emit AlphaUnstaked(msg.sender, tokenId, block.number, block.timestamp);
        }
        HUB.emitAlphaUnstaked(msg.sender, tokenIds);
    }

    /** ADMIN */

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    function isOwner(uint16 tokenId, address owner) external view override returns (bool validOwner) {
        if (genesisType[tokenId] == 1) {
            return cat[tokenId].owner == owner;
        } else if (genesisType[tokenId] == 2) {
            return dog[tokenId].owner == owner;
        } else if (genesisType[tokenId] == 3) {
            return veterinarian[tokenId].owner == owner;
        }
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** READ ONLY */

    function getUnclaimedAlpha(uint16 tokenId) external view returns (uint256) {
        if(alpha[tokenId].value > 0) {
            if(block.timestamp <= claimEndTime) {
                return (block.timestamp - alpha[tokenId].value) * DAILY_ALPHA_RATE / PERIOD;
            } else if (alpha[tokenId].value < claimEndTime) {
                return (claimEndTime - alpha[tokenId].value) * DAILY_ALPHA_RATE / PERIOD;
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    function getUnclaimedGenesis(uint16 tokenId) external view returns (uint256 owed) {
        owed = 0;
        if (genesisType[tokenId] == 1 && cat[tokenId].value > 0) {
            if(block.timestamp <= claimEndTime) {
                return (block.timestamp - cat[tokenId].value) * DAILY_CAT_RATE / PERIOD;
            } else if (cat[tokenId].value < claimEndTime) {
                return (claimEndTime - cat[tokenId].value) * DAILY_CAT_RATE / PERIOD;
            } else {
                return 0;
            }
        } else if (genesisType[tokenId] == 2 && dog[tokenId].owner != address(0)) {
            return TOPIAPerDog - dog[tokenId].value;
        } else if (genesisType[tokenId] == 3 && veterinarian[tokenId].owner != address(0)) {
            return TOPIAPerVeterinarian - veterinarian[tokenId].value;
        }
        return owed;
    }

    function getUnclaimedTopiaForUser(address _account) external view returns (uint256) {
        uint256 owed;
        uint256 genesisLength = genesisOwnedIds[_account].length();
        uint256 alphaLength = alphaOwnedIds[_account].length();
        for (uint i = 0; i < genesisLength; i++) {
            uint16 tokenId = uint16(genesisOwnedIds[_account].at(i));
            if (genesisType[tokenId] == 1) {
                if(block.timestamp <= claimEndTime) {
                    owed += (block.timestamp - cat[tokenId].value) * DAILY_CAT_RATE / PERIOD;
                } else if (cat[tokenId].value < claimEndTime) {
                    owed += (claimEndTime - cat[tokenId].value) * DAILY_CAT_RATE / PERIOD;
                } else {
                    owed += 0;
                }
            } else if (genesisType[tokenId] == 2) {
                owed += TOPIAPerDog - dog[tokenId].value;
            } else if (genesisType[tokenId] == 3) {
                owed += TOPIAPerVeterinarian - veterinarian[tokenId].value;
            } else if (genesisType[tokenId] == 0) {
                continue;
            }
        }
        for (uint i = 0; i < alphaLength; i++) {
            uint16 tokenId = uint16(alphaOwnedIds[_account].at(i));
            if(block.timestamp <= claimEndTime) {
                owed += (block.timestamp - alpha[tokenId].value) * DAILY_ALPHA_RATE / PERIOD;
            } else if (cat[tokenId].value < claimEndTime) {
                owed += (claimEndTime - alpha[tokenId].value) * DAILY_ALPHA_RATE / PERIOD;
            } else {
                owed += 0;
            }
        }

        return owed;
    }

    function getStakedGenesisForUser(address _account) external view returns (uint16[] memory stakedGensis) {
        uint256 length = genesisOwnedIds[_account].length();
        stakedGensis = new uint16[](length);
        for (uint i = 0; i < length; i++) {
            stakedGensis[i] = uint16(genesisOwnedIds[_account].at(i));
        }
    }

    function getStakedAlphasForUser(address _account) external view returns (uint16[] memory stakedAlphas) {
        uint256 length = alphaOwnedIds[_account].length();
        stakedAlphas = new uint16[](length);
        for (uint i = 0; i < length; i++) {
            stakedAlphas[i] = uint16(alphaOwnedIds[_account].at(i));
        }
    }

    /**
     * chooses a random Dog thief when an unstaking token is stolen
     * @param seed a random value to choose a Dog from
   * @return the owner of the randomly selected Cat thief
   */
    function randomDogOwner(uint256 seed) internal view returns (address) {
        if (dogIds.length() == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % dogIds.length();
        return dog[dogIds.at(bucket)].owner;
    }

    /**
     * chooses a random Veterinarian thief when a an unstaking token is stolen
     * @param seed a random value to choose a Veterinarian from
   * @return the owner of the randomly selected Dog thief
   */
    function randomVeterinarianOwner(uint256 seed) internal view returns (address) {
        if (veterinarianIds.length() == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % veterinarianIds.length();
        return veterinarian[veterinarianIds.at(bucket)].owner;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function updateMinimumExit(uint256 _minimum) external onlyOwner {
        MINIMUM = _minimum;
    }
    
    function updatePeriod(uint256 _period) external onlyOwner {
        PERIOD = _period;
    }

    function updateDailyCatRate(uint256 _rate) external onlyOwner {
        DAILY_CAT_RATE = _rate;
    }

    function updateDailyAlphaRate(uint256 _rate) external onlyOwner {
        DAILY_ALPHA_RATE = _rate;
    }
    
    function updateTaxRates(uint8 _dogRate, uint8 _vetRate) external onlyOwner {
        require(_dogRate + _vetRate == 100, "rates must equal 100");
        DOG_TAX_RATE = _dogRate;
        VETERINARIAN_TAX_RATE = _vetRate;
    }

    function updateSeedCost(uint256 _cost) external onlyOwner {
        SEED_COST = _cost;
    }

    function closeSeasonEearnings(uint80 _timestamp) external onlyOwner {
        claimEndTime = _timestamp;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function requestRandomWords() external returns (uint256);
    function requestManyRandomWords(uint256 numWords) external returns (uint256);
    function getRandomWords(uint256 number) external returns (uint256[] memory);
    function getRemainingWords() external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IDogeWorld {
  function addManyToStakingPool(address account, uint16[] calldata tokenIds) external;
  function isOwner(uint16 tokenId, address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IHub {
    function emitGenesisStaked(address owner, uint16[] calldata tokenIds, uint8 gameId) external;
    function emitAlphaStaked(address owner, uint16[] calldata tokenIds, uint8 gameId) external;
    function emitGenesisUnstaked(address owner, uint16[] calldata tokenIds) external;
    function emitAlphaUnstaked(address owner, uint16[] calldata tokenIds) external;
    function emitTopiaClaimed(address owner, uint256 amount) external;
    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITOPIA {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface INFT is IERC721Enumerable {
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}