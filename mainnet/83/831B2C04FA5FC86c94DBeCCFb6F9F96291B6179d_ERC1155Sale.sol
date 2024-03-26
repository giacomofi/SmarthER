// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ERC1155SaleNonceHolder.sol";
import "../tokens/HasSecondarySale.sol";
import "../tokens/HasAffiliateFees.sol";
import "../proxy/TransferProxy.sol";
import "../proxy/ServiceFeeProxy.sol";
import "../interfaces/IIkonictoken.sol";
import "../interfaces/IIkonicERC1155Token.sol";

contract ERC1155Sale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    uint256 orderId;

    event CloseOrder(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 nonce,
        uint256 orderId
    );

    event Buy(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        uint8 currencyId,
        address buyer,
        uint256 buyingAmount,
        uint256 orderId
    );

    event Sell(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        uint8 currencyId,
        uint8[] accCurIds,
        uint256 expSaleDate,
        uint256 orderId
    );

    event UpdatePriceAndCurrency(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        uint8 currencyId,
        uint256 orderId
    );

    event UpdateExpSaleDate(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 expSaleDate,
        uint256 orderId
    );

    event UpdateSaleAmount(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 expSaleDate,
        uint256 orderId
    );

    event Withdrawn(
        address receiver,
        uint256 amount,
        uint256 balance
    );

    struct SaleInfo {
        address owner;
        uint256 price;
        uint8 currencyId;
        uint8[] accCurIds; // acceptable currency Id lists
        uint256 amount;
        uint256 orderId;
        uint256 expSaleDate;
    }

    bytes constant EMPTY = "";
    bytes4 private constant _INTERFACE_ID_HAS_SECONDARY_SALE = 0x5595380a;
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    /// @dev token address -> order ID -> token id -> sale info
    mapping(address => mapping(uint256 => mapping(uint256 => SaleInfo))) public saleInfos;

    /// @dev token address -> token id -> latestListingPrice
    mapping(address => mapping(uint256 => uint256)) public latestListingPrices;

    /// @dev token address -> token id -> latestSalePrice
    mapping(address => mapping(uint256 => uint256)) public latestSalePrices;

    /// @dev currencyType -> currency Address 
    mapping(uint8 => address) public supportCurrencies;

    string[] public supportCurrencyName = ["ETH"];

    TransferProxy private transferProxy;
    ServiceFeeProxy private serviceFeeProxy;
    ERC1155SaleNonceHolder private nonceHolder;

    constructor(
        TransferProxy _transferProxy,
        ERC1155SaleNonceHolder _nonceHolder,
        ServiceFeeProxy _serviceFeeProxy
    ) {
        require(
            address(_transferProxy) != address(0x0) && 
            address(_nonceHolder) != address(0x0) &&
            address(_serviceFeeProxy) != address(0x0)
        );
        transferProxy = _transferProxy;
        nonceHolder = _nonceHolder;
        serviceFeeProxy = _serviceFeeProxy;
    }

    /**
     * @notice list token on sale list
     * @param _token ERC1155 Token
     * @param _tokenId Id of token
     * @param _expSaleDate approve sale date of token
     * @param _price price of token
     * @param _currencyId currency Index
     * @param _accCurrencyIds acceptable currency id list
     * @param _amount amount of token for sell
     * @param _signature signature from frontend
     */
     function sell(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _expSaleDate,
        uint256 _price,
        uint8 _currencyId,
        uint8[] memory _accCurrencyIds,
        uint256 _amount,
        bytes memory _signature
    ) external nonReentrant {
        require(
            _token.balanceOf(msg.sender, _tokenId) >= _amount,
            "ERC1155Sale.sell: Sell amount exceeds balance"
        );
        
        require(_expSaleDate >= _getNow(), "ERC1155Sale.sell: Approved sale date invalid");
        require(_price > 0, "ERC1155Sale.sell: Price should be positive");
        require(isCurrencyValid(_currencyId), "ERC1155Sale.sell: Base currency is not supported");
        unchecked {
            for (uint256 index = 0; index < _accCurrencyIds.length; index++) {
                require(isCurrencyValid(_accCurrencyIds[index]), "ERC1155Sale.sell: Acceptable currencies are not supported");
            }
        }

        require(
            keccak256(abi.encodePacked(address(_token), _tokenId, _price, uint256(_currencyId), _amount))
                .toEthSignedMessageHash()
                .recover(_signature) == _token.getSignerAddress(),
            "ERC1155Sale.sell: Incorrect signature"
        );
        orderId++;

        saleInfos[address(_token)][orderId][_tokenId] = SaleInfo({
            owner: msg.sender,
            price: _price,
            currencyId: _currencyId,
            accCurIds: _accCurrencyIds,
            expSaleDate: _expSaleDate,
            amount: _amount,
            orderId: orderId
        });

        // Update the latest listing price with the _price value
        latestListingPrices[address(_token)][_tokenId] = _price;
        
        emit Sell(
            address(_token),
            _tokenId,
            msg.sender,
            _price,
            _currencyId,
            _accCurrencyIds,
            _expSaleDate,
            orderId
        );
    }

    /**
     * @notice buy token
     * @param _token ERC1155 Token
     * @param _tokenId Id of token
     * @param _orderId Id of order list
     * @param _price price of token
     * @param _currencyId currency Index
     * @param _amount buying Amount
     * @param _signature signature from frontend
     */

    function buy(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _orderId,
        uint256 _price,
        uint8 _currencyId,
        uint256 _amount,
        bytes memory _signature
    ) external nonReentrant payable {
        require(
            saleInfos[address(_token)][_orderId][_tokenId].amount > 0,
            "ERC1155Sale.buy: Doesn't listed for sale"
        );
        require(
            saleInfos[address(_token)][_orderId][_tokenId].expSaleDate >= _getNow(),
            "ERC1155Sale.buy: Token sale expired"
        );

        require(
            saleInfos[address(_token)][_orderId][_tokenId].amount >= _amount,
            "ERC1155Sale.buy: Buying amount exceeds balance"
        );

        require(isCurrencyValid(_currencyId), "ERC1155Sale.buy: Currency is not supported");
        require(isCurrencyAcceptable(_token, _tokenId, _orderId, _currencyId), "ERC1155Sale.buy: Buying currency is not acceptable");

        address _owner = saleInfos[address(_token)][_orderId][_tokenId].owner;

        uint256 nonce = verifySignature(
            _token,
            _tokenId,
            _owner,
            _price,
            _currencyId,
            _amount,
            _signature
        );
        verifyOpenAndModifyState(address(_token), _tokenId, _orderId, _owner, nonce);

        uint256 price = _price.mul(_amount).add(_price.mul(_amount).mul(serviceFeeProxy.getBuyServiceFeeBps()).div(10000));

        if (_currencyId == 0) {    
            require(msg.value >= price, "ERC1155Sale.buy: Insufficient funds");
            // return change if any
            if (msg.value > price) {
                (bool sent, ) = payable(msg.sender).call{value: msg.value - price}("");
                require(sent, "ERC1155Sale.buy: Change transfer failed");
            }
        } else {
            if (msg.value > 0) {
                (bool sent, ) = payable(msg.sender).call{value: msg.value}("");
                require(sent, "ERC1155Sale.buy: Change transfer failed");
            }
            IERC20(supportCurrencies[_currencyId]).transferFrom(msg.sender, address(this), price);
        }
            
        distributePayment(_token, _tokenId, _orderId, _price, _currencyId, _amount);
        transferProxy.erc1155safeTransferFrom(
            _token,
            _owner,
            msg.sender,
            _tokenId,
            _amount,
            EMPTY
        );
        
        // Remove from sale info list
        saleInfos[address(_token)][_orderId][_tokenId].amount = saleInfos[address(_token)][_orderId][_tokenId].amount.sub(_amount);
        if(saleInfos[address(_token)][_orderId][_tokenId].amount == 0) {
            delete saleInfos[address(_token)][_orderId][_tokenId];
            delete latestListingPrices[address(_token)][_tokenId];
        }

        // Update latest sale price list
        latestSalePrices[address(_token)][_tokenId] = _price;

        if (_token.supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE)) {
            HasSecondarySale SecondarySale = HasSecondarySale(address(_token));
            SecondarySale.setSecondarySale(_tokenId);
        }

        emit Buy(
            address(_token),
            _tokenId,
            _owner,
            price,
            _currencyId,
            msg.sender,
            _amount,
            _orderId
        );
    }

    /**
     * @notice Send payment to seller, service fee recipient and royalty recipient
     * @param _token ERC1155 Token
     * @param _tokenId Id of token
     * @param _orderId order index
     * @param _price price of token     
     * @param _currencyId currency Index
     * @param _amount buying amount
     */
    function distributePayment(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _orderId,
        uint256 _price,
        uint8 _currencyId,
        uint256 _amount
    ) internal {
        // uint256 sellerServiceFeeBps = serviceFeeProxy.getSellServiceFeeBps();
        // uint256 buyerServiceFeeBps = serviceFeeProxy.getBuyServiceFeeBps();

        uint256 tokenPrice = _price.mul(_amount);
        uint256 sellerServiceFee = tokenPrice.mul(serviceFeeProxy.getSellServiceFeeBps()).div(10000);

        uint256 ownerReceivingAmount = tokenPrice.sub(sellerServiceFee);
        uint256 totalServiceFeeAmount = sellerServiceFee.add(tokenPrice.mul(serviceFeeProxy.getBuyServiceFeeBps()).div(10000));

        if (_token.supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE)) {
            HasSecondarySale SecondarySale = HasSecondarySale(address(_token));
            bool isSecondarySale = SecondarySale.checkSecondarySale(_tokenId);
            if(isSecondarySale) {
                (address receiver, uint256 royaltyAmount) = _token.royaltyInfo(_tokenId, tokenPrice);
                if ( _currencyId == 0 ) {
                    (bool royaltySent, ) = payable(receiver).call{value: royaltyAmount}("");
                    require(royaltySent, "ERC1155Sale.distributePayment: Royalty transfer failed");
                } else {
                    IERC20(supportCurrencies[_currencyId]).transfer(receiver, royaltyAmount);
                }
                ownerReceivingAmount = ownerReceivingAmount.sub(royaltyAmount);
                uint256 fee = checkFee(_token, _tokenId, tokenPrice, _currencyId);
                ownerReceivingAmount = ownerReceivingAmount.sub(fee);
            }
        }

        if (_token.supportsInterface(_INTERFACE_ID_FEES)) {
            uint256 sumAffFee = distributeFee(_token, _tokenId, tokenPrice, _currencyId);
            ownerReceivingAmount = ownerReceivingAmount.sub(sumAffFee);
        }
        
        if ( _currencyId == 0) {
            // address that should collect Ikonic service fee
            (bool serviceFeeSent, ) = payable(serviceFeeProxy.getServiceFeeRecipient()).call{value: totalServiceFeeAmount}("");
            require(serviceFeeSent, "ERC1155Sale.distributePayment: ServiceFee transfer failed");

            (bool ownerReceivingAmountSent, ) = payable(saleInfos[address(_token)][_orderId][_tokenId].owner).call{value: ownerReceivingAmount}("");
            require(ownerReceivingAmountSent, "ERC1155Sale.distributePayment: ownerReceivingAmount transfer failed");
        } else {
            IERC20(supportCurrencies[_currencyId]).transfer(serviceFeeProxy.getServiceFeeRecipient(), totalServiceFeeAmount);
            IERC20(supportCurrencies[_currencyId]).transfer(saleInfos[address(_token)][_orderId][_tokenId].owner, ownerReceivingAmount);
        }
    }

    function distributeFee(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _price,
        uint8 _currencyId
    ) internal returns(uint) {
        HasAffiliateFees withFees = HasAffiliateFees(address(_token));
        address [] memory recipients = withFees.getFeeRecipients(_tokenId);
        uint256[] memory fees = withFees.getFeeBps(_tokenId);
        require(fees.length == recipients.length);
        uint256 sumFee;
        unchecked {
            for (uint256 i = 0; i < fees.length; i++) {
                uint256 current = _price.mul(fees[i]).div(10000);
                if ( _currencyId == 0 ) {
                    (bool royaltySent, ) = payable(recipients[i]).call{value: current}("");
                    require(royaltySent, "ERC1155Sale.distributePayment: Affiliate royalty transfer failed");
                } else {
                    IERC20(supportCurrencies[_currencyId]).transfer(recipients[i], current);
                }
                sumFee = sumFee.add(current);
            }
        }
        return sumFee;
    }

    function checkFee(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _price,
        uint8 _currencyId
    ) internal returns(uint) {
        if (_token.supportsInterface(_INTERFACE_ID_FEES)) {
            HasAffiliateFees AffiliateSale = HasAffiliateFees(address(_token));
            bool isAffiliateSale = AffiliateSale.checkAffiliateSale(_tokenId);
            address affiliateRecipient = AffiliateSale.getAffiliateFeeRecipient();
            uint256 affiliateAmount = _price.mul(AffiliateSale.getAffiliateFee()).div(10000);
            if (isAffiliateSale) {
                if ( _currencyId == 0 ) {
                    (bool Sent, ) = payable(affiliateRecipient).call{value: affiliateAmount}("");
                    require(Sent, "ERC1155Sale.distributePayment: Affiliate Royalty transfer failed");
                } else {
                    IERC20(supportCurrencies[_currencyId]).transfer(affiliateRecipient, affiliateAmount);
                }
                return affiliateAmount;
            } else {
                AffiliateSale.setAffiliateSale(_tokenId);
            }
        }
        return 0;
    }

    /**
     * @notice Cancel listing of token
     * @param _token ERC1155 Token
     * @param _tokenId token Id
     * @param _orderId order Id
     */
    function cancel(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _orderId
    ) external {
        address _owner = saleInfos[address(_token)][_orderId][_tokenId].owner;

        require(
            _owner == msg.sender,
            "ERC1155Sale.cancel: Caller is not the owner of the token"
        );

        uint256 nonce = nonceHolder.getNonce(
            address(_token),
            _tokenId,
            msg.sender
        );

        nonceHolder.setNonce(
            address(_token),
            _tokenId,
            msg.sender,
            nonce.add(1)
        );

        delete saleInfos[address(_token)][_orderId][_tokenId];
        
        emit CloseOrder(
            address(_token),
            _tokenId,
            msg.sender,
            nonce.add(1),
            _orderId
        );
    }

    /**
     * @notice Recover signer address from signature and verify it's correct
     * @param token ERC1155 Token
     * @param tokenId token Id
     * @param owner owner address of token
     * @param price price of token
     * @param currencyId currency index
     * @param amount buying amount of ERC1155 token
     * @param signature signature 
     */
    function verifySignature(
        IIkonicERC1155Token token,
        uint256 tokenId,
        address owner,
        uint256 price,
        uint8 currencyId,
        uint256 amount,
        bytes memory signature
    ) internal view returns (uint256 nonce) {
        nonce = nonceHolder.getNonce(address(token), tokenId, owner);
        require(
            keccak256(abi.encodePacked(address(token), tokenId, price, uint256(currencyId), amount, nonce))
                .toEthSignedMessageHash()
                .recover(signature) == token.getSignerAddress(),
            "ERC1155Sale.verifySignature: Incorrect signature"
        );
    }

    /**
     * @notice Modify state by setting nonce and closing order
     * @param _token ERC1155 Token
     * @param _tokenId token Id
     * @param _orderId order Id 
     * @param _owner owner address of token
     * @param _nonce nonce value of token
     */
    function verifyOpenAndModifyState(
        address _token,
        uint256 _tokenId,
        uint256 _orderId,
        address _owner,
        uint256 _nonce
    ) internal {
        nonceHolder.setNonce(_token, _tokenId, _owner, _nonce.add(1));
        emit CloseOrder(_token, _tokenId, _owner, _nonce.add(1), _orderId);
    }

    /**
     * @notice update price and currency of token
     * @param _token ERC1155 Token Interface
     * @param _tokenId Id of token
     * @param _price price of token
     * @param _orderId Id of order list
     */
     function updatePriceAndCurrency(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _price,
        uint8 _currencyId,
        uint256 _orderId
    ) external {
        address _owner = saleInfos[address(_token)][_orderId][_tokenId].owner;
        require(
            _owner == msg.sender,
            "ERC1155Sale.updatePriceAndCurrency: Caller is not the owner of the token"
        );

        require(_price > 0, "ERC1155Sale.updatePriceAndCurrency: Price should be positive");
        require(isCurrencyValid(_currencyId), "ERC1155Sale.updatePriceAndCurrency: Currency is not supported");

        saleInfos[address(_token)][_orderId][_tokenId].price = _price;
        saleInfos[address(_token)][_orderId][_tokenId].currencyId = _currencyId;

        emit UpdatePriceAndCurrency(
            address(_token),
            _tokenId,
            msg.sender,
            _price,
            _currencyId,
            _orderId
        );
    }

    /**
     * @notice update expiration date
     * @param _token ERC1155 Token Interface
     * @param _tokenId Id of token
     * @param _expSaleDate expiration date
     * @param _orderId Id of order list
     */
     function updateExpSaleDate(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _expSaleDate,
        uint256 _orderId
    ) external {
        address _owner = saleInfos[address(_token)][_orderId][_tokenId].owner;
        require(
            _owner == msg.sender,
            "ERC1155Sale.updateExpSaleDate: Caller is not the owner of the token"
        );

        require(_expSaleDate >= _getNow(), "ERC1155Sale.updateExpSaleDate: Approved sale date invalid");

        saleInfos[address(_token)][_orderId][_tokenId].expSaleDate = _expSaleDate;
        emit UpdateExpSaleDate(
            address(_token),
            _tokenId,
            msg.sender,
            _expSaleDate,
            _orderId
        );
    }

    /**
     * @notice update sale amount
     * @param _token ERC1155 Token Interface
     * @param _tokenId Id of token
     * @param _amount amount of token for sell
     * @param _orderId Id of order list
     */
     function updateSaleAmount(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _orderId
    ) external {
        address _owner = saleInfos[address(_token)][_orderId][_tokenId].owner;
        require(
            _owner == msg.sender,
            "ERC1155Sale.updateSaleAmount: Caller is not the owner of the token"
        );
        
        require(_amount != 0, "ERC1155Sale.updateSaleAmount: Amount should be positive");
        
        require(
            _token.balanceOf(msg.sender, _tokenId) >= _amount,
            "ERC1155Sale.updateSaleAmount: Selling amount exceeds balance"
        );


        saleInfos[address(_token)][_orderId][_tokenId].amount = _amount;
        emit UpdateSaleAmount(
            address(_token),
            _tokenId,
            msg.sender,
            _amount,
            _orderId
        );
    }

    /**
     * @notice Get Sale info with owner address and token id
     * @param _token ERC1155 Token Interface
     * @param _tokenId Id of token
     * @param _orderId Id of order list
     */
    function getSaleInfo(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _orderId
    ) external view returns(SaleInfo memory) {
        return saleInfos[address(_token)][_orderId][_tokenId];
    }

    /**
     * @notice Get Sale price with token address and token id
     * @param _token ERC1155 Token Interface
     * @param _tokenId Id of token
     */
    function getSalePrice(
        IIkonicERC1155Token _token,
        uint256 _tokenId
    ) external view returns (uint256) {
        if(latestListingPrices[address(_token)][_tokenId] != 0) {
            return latestListingPrices[address(_token)][_tokenId];
        }

        if(latestSalePrices[address(_token)][_tokenId] != 0) {
            return latestSalePrices[address(_token)][_tokenId];
        }

        return 0;
    }

    /**
     * @notice send / withdraw amount to receiver
     * @param receiver recipient address
     * @param amount amount to withdraw
     * @param curId currency index
    */
    function withdrawTo(address receiver, uint256 amount, uint8 curId) external onlyOwner {
        require(receiver != address(0) && receiver != address(this), "ERC1155Sale.withdrawTo: Invalid withdrawal recipient address");
        if (curId == 0) {    
            require(amount > 0 && amount <= address(this).balance, "ERC1155Sale.withdrawTo: Invalid withdrawal amount");
            (bool sent, ) = payable(receiver).call{value: amount}("");
            require(sent, "ERC1155Sale.withdrawTo: Transfer failed");
        } else {
            require(amount > 0 && amount <= IERC20(supportCurrencies[curId]).balanceOf(address(this)), "ERC1155Sale.withdrawTo: Invalid withdrawal amount");
            IERC20(supportCurrencies[curId]).transfer(receiver, amount);
        }
        emit Withdrawn(receiver, amount, address(this).balance);
    }

    /// @notice returns current block timestamp
    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice returns currency name by index
     * @param curIndex index of currency
     */
    function getCurrencyName(uint8 curIndex) external view returns (string memory) {
        require(isCurrencyValid(curIndex), "ERC1155Sale.getCurrencyName: Currency is not supported");
        return supportCurrencyName[curIndex];
    }

    /// @notice returns count of supporting currency names
    function getCurrencyNameCount() external view returns (uint) {
        return supportCurrencyName.length;
    }

    /**
     * @notice add new currency
     * @param curName name of new currency
     * @param curAddress address of new currency
     */
    function addSupportCurrency(string memory curName, address curAddress) external onlyOwner {
        uint8 i = 0;
        uint256 curLength = supportCurrencyName.length;
        unchecked {
            for (i = 1; i < curLength; i++) {   
                require(supportCurrencies[i] != curAddress, "ERC1155Sale.addSupportCurrency: This currency already exists");
            }
        }
        supportCurrencies[i] = curAddress;
        supportCurrencyName.push(curName);
    }
    
    /**
     * @notice update currency
     * @param curIndex index of currency
     * @param curAddress address of currency
     */
    function updateCurrencyAddress(uint8 curIndex, address curAddress) external onlyOwner {
        require(isCurrencyValid(curIndex), "ERC1155Sale.updateCurrencyAddress: Currency is not supported");
        supportCurrencies[curIndex] = curAddress;
    }

    /**
     * @notice check if currency is added to currency supporting list or not
     * @param curIndex index of currency
     */
    function isCurrencyValid(uint8 curIndex) public view returns (bool) {
        return (curIndex == 0 || supportCurrencies[curIndex] != address(0x0)) ? true : false;
    }

    /**
     * @notice check if currency is added to acceptable list
     * @param _token ERC1155 Token
     * @param _tokenId Id of token
     * @param _currencyId index of currency
     */
    function isCurrencyAcceptable(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _orderId,
        uint8 _currencyId
    ) internal view returns (bool) {
        uint8 listedCurId = saleInfos[address(_token)][_orderId][_tokenId].currencyId;
        if (listedCurId == _currencyId) {
            return true;    
        }
        uint8[] memory accCurIds = saleInfos[address(_token)][_orderId][_tokenId].accCurIds;
        unchecked {
            for (uint256 index = 0; index < accCurIds.length; index++) {
                if (accCurIds[index] == _currencyId) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @notice returns acceptable currency id list
     * @param _token ERC1155 Token
     * @param _tokenId Id of token
     */
    function getAcceptableCurrencyIds(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _orderId
    ) external view returns (uint8[] memory) {
        return saleInfos[address(_token)][_orderId][_tokenId].accCurIds;
    }
}

pragma solidity 0.8.13;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

abstract contract HasSecondarySale is ERC165Storage {

    /*
     * bytes4(keccak256('checkSecondarySale(uint256)')) == 0x0e883747
     * bytes4(keccak256('setSecondarySale(uint256)')) == 0x5b1d0f4d
     *
     * => 0x0e883747 ^ 0x5b1d0f4d == 0x5595380a
     */
    bytes4 private constant _INTERFACE_ID_HAS_SECONDARY_SALE = 0x5595380a;

    constructor() {
        _registerInterface(_INTERFACE_ID_HAS_SECONDARY_SALE);
    }

    /**
     * @notice virtual function to check secondary sale
     * @param id token ID
     * @return return state value if sale is secondary sale or not
     */
    function checkSecondarySale(uint256 id) external virtual view returns (bool);

    /// @notice virtual function to set secondary sale state value
    function setSecondarySale(uint256 id) external virtual;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

abstract contract HasAffiliateFees is ERC165Storage {

    event AffiliateFees(uint256 tokenId, address[] recipients, uint[] bps);

    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    constructor() {
        _registerInterface(_INTERFACE_ID_FEES);
    }

    function checkAffiliateSale(uint256 id) external virtual view returns (bool);
    function setAffiliateSale(uint256 id) external virtual;
    function getFeeRecipients(uint256 id) public virtual view returns (address[] memory);
    function getFeeBps(uint256 id) public virtual view returns (uint[] memory);
    function getAffiliateFeeRecipient() external virtual returns (address);
    function getAffiliateFee() external virtual returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "../roles/OperatorRole.sol";

contract ERC1155SaleNonceHolder is OperatorRole {
    // keccak256(token, owner, tokenId) => nonce
    mapping(bytes32 => uint256) public nonces;

    /**
     * @notice returns nonce value
     * @param token ERC1155 token address
     * @param tokenId Id of token
     * @param owner owner of token
     */
    function getNonce(
        address token,
        uint256 tokenId,
        address owner
    ) external view returns (uint256) {
        return nonces[getNonceKey(token, tokenId, owner)];
    }

    /**
     * @notice set nonce value
     * @param token ERC1155 token address
     * @param tokenId Id of token
     * @param owner owner of token
     * @param nonce nonce value
     */
    function setNonce(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce
    ) external onlyOperator {
        nonces[getNonceKey(token, tokenId, owner)] = nonce;
    }

    /**
     * @notice returns hashed nonce key
     * @param token ERC1155 token address
     * @param tokenId Id of token
     * @param owner owner of token
     */
    function getNonceKey(
        address token,
        uint256 tokenId,
        address owner
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, tokenId, owner));
    }
}

pragma solidity 0.8.13;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OperatorRole is AccessControl, Ownable {
    
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @notice 
     */
    modifier onlyOperator() {
        require(isOperator(_msgSender()), "OperatorRole: caller is not the operator");
        _;
    }
    
    /**
     * @notice Add operator
     * @param _account account address
     */
    function addOperator(address _account) public onlyOwner {
        _setupRole(OPERATOR_ROLE , _account);
    }

    /**
     * @notice remove operator
     * @param _account account address
     */
    function removeOperator(address _account) public onlyOwner {
        revokeRole(OPERATOR_ROLE , _account);
    }

    /**
     * @notice Check if account has operator role 
     * @param _account account address
     */
    function isOperator(address _account) internal virtual view returns(bool) {
        return hasRole(OPERATOR_ROLE , _account);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../roles/OperatorRole.sol";

contract TransferProxy is OperatorRole {
    /**
     * @notice transfer ERC721 token 
     * @param token interface of ERC721 token
     * @param from sender address
     * @param to recipient address
     * @param tokenId ERC721 token ID
     */
    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint tokenId
    ) external onlyOperator {
        token.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice transfer ERC1155 token 
     * @param token interface of ERC1155 token
     * @param from sender address
     * @param to recipient address
     * @param tokenId ERC1155 token ID
     * @param value amount value to transfer
     * @param data callback data
     */
    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint tokenId,
        uint value,
        bytes calldata data
    ) external onlyOperator {
        token.safeTransferFrom(from, to, tokenId, value, data);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "../interfaces/IServiceFee.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Service Fee Proxy to communicate service fee contract
 */
contract ServiceFeeProxy is Ownable {
    
    IServiceFee private serviceFeeContract;

    event ServiceFeeContractUpdated(address serviceFeeContract);

    /**
     * @notice Let admin set the service fee contract
     * @param _serviceFeeContract address of serviceFeeContract
     */
    function setServiceFeeContract(address _serviceFeeContract) onlyOwner external {
        require(
            _serviceFeeContract != address(0),
            "ServiceFeeProxy.setServiceFeeContract: Zero address"
        );
        serviceFeeContract = IServiceFee(_serviceFeeContract);
        emit ServiceFeeContractUpdated(_serviceFeeContract);
    }

    /**
     * @notice Set seller service fee
     * @param _sellerFee seller service fee
     */
    function setSellServiceFee(uint256 _sellerFee) external onlyOwner {
        require(
            _sellerFee != 0,
            "ServiceFee.setSellServiceFee: Zero value"
        );
        
        serviceFeeContract.setSellServiceFee(_sellerFee);
    }

    /**
     * @notice Set buyer service fee
     * @param _buyerFee buyer service fee
     */
    function setBuyServiceFee(uint256 _buyerFee) external onlyOwner {
        require(
            _buyerFee != 0,
            "ServiceFee.setBuyServiceFee: Zero value"
        );
        
        serviceFeeContract.setBuyServiceFee(_buyerFee);
    }

    /**
     * @notice Fetch sell service fee bps from service fee contract
     */
    function getSellServiceFeeBps() external view returns (uint256) {
        return serviceFeeContract.getSellServiceFeeBps();
    }

    /**
     * @notice Fetch buy service fee bps from service fee contract
     */
    function getBuyServiceFeeBps() external view returns (uint256) {
        return serviceFeeContract.getBuyServiceFeeBps();
    }

    /**
     * @notice Get service fee recipient address
     */
    function getServiceFeeRecipient() external view returns (address) {
        return serviceFeeContract.getServiceFeeRecipient();
    }

    /**
     * @notice Set service fee recipient address
     * @param _serviceFeeRecipient address of recipient
     */
    function setServiceFeeRecipient(address _serviceFeeRecipient) external onlyOwner {
        require(
            _serviceFeeRecipient != address(0),
            "ServiceFeeProxy.setServiceFeeRecipient: Zero address"
        );

        serviceFeeContract.setServiceFeeRecipient(_serviceFeeRecipient);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

/**
 * @notice Service Fee interface for Ikonic NFT Marketplace 
 */
interface IServiceFee {

    /**
     * @notice Admin can add proxy address
     * @param _proxyAddr address of proxy
     */
    function addProxy(address _proxyAddr) external;

    /**
     * @notice Admin can remove proxy address
     * @param _proxyAddr address of proxy
     */
    function removeProxy(address _proxyAddr) external;

    /**
     * @notice Calculate the seller service fee
     */
    function getSellServiceFeeBps() external view returns (uint256);

    /**
     * @notice Calculate the buyer service fee
     */
    function getBuyServiceFeeBps() external view returns (uint256);

    /**
     * @notice Get service fee recipient address
     */
    function getServiceFeeRecipient() external view returns (address);

    /**
     * @notice Set service fee recipient address
     * @param _serviceFeeRecipient address of recipient
     */
    function setServiceFeeRecipient(address _serviceFeeRecipient) external;

    /**
     * @notice Set seller service fee
     * @param _sellerFee seller service fee
     */
    function setSellServiceFee(uint256 _sellerFee) external;

    /**
     * @notice Set buyer service fee
     * @param _buyerFee buyer service fee
     */
    function setBuyServiceFee(uint256 _buyerFee) external; 
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IIkonicToken {

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the token name.
   */
  function name() external view returns (string memory);

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account)
    external
    view
    returns (uint256);

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount)
    external
    returns (bool);

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount)
    external
    returns (bool);

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IERC2981Royalties.sol";

/// @title IIkonicERC1155Token
/// @dev Interface for IIkonicERC1155Token
interface IIkonicERC1155Token is IERC1155, IERC2981Royalties{
    /**
     * @dev Returns signer address.
    */
    function getSignerAddress() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}