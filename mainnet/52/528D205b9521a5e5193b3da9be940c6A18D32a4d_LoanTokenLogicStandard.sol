/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "AdvancedToken.sol";
import "StorageExtension.sol";
import "IBZx.sol";
import "IPriceFeeds.sol";

contract LoanTokenLogicStandard is AdvancedToken, StorageExtension {
    using SafeMath for uint256;
    using SignedSafeMath for int256;


    //// CONSTANTS ////

    uint256 public constant VERSION = 7;

    address internal constant arbitraryCaller = 0x000F400e6818158D541C3EBE45FE3AA0d47372FF; // mainnet
    //address internal constant arbitraryCaller = 0x81e7dddFAD37E6FAb0eccE95f0B508fd40996e6d; // bsc
    // address internal constant arbitraryCaller = 0x81e7dddFAD37E6FAb0eccE95f0B508fd40996e6d; // polygon
    // address internal constant arbitraryCaller = 0x01207468F48822f8535BC96D1Cf18EddDE4A2392; // arbitrum

    address public constant bZxContract = 0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f; // mainnet
    address public constant wethToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet

    //address public constant bZxContract = 0x5cfba2639a3db0D9Cc264Aa27B2E6d134EeA486a; // kovan
    //address public constant wethToken = 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // kovan

    //address public constant bZxContract = 0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f; // bsc
    //address public constant wethToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // bsc

    // address public constant bZxContract = 0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8; // polygon
    // address public constant wethToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // polygon

    // address public constant bZxContract = 0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB; // arbitrum
    // address public constant wethToken = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // arbitrum

    bytes32 internal constant iToken_ProfitSoFar = 0x37aa2b7d583612f016e4a4de4292cb015139b3d7762663d06a53964912ea2fb6;          // keccak256("iToken_ProfitSoFar")
    bytes32 internal constant iToken_LowerAdminAddress = 0x7ad06df6a0af6bd602d90db766e0d5f253b45187c3717a0f9026ea8b10ff0d4b;    // keccak256("iToken_LowerAdminAddress")
    bytes32 internal constant iToken_LowerAdminContract = 0x34b31cff1dbd8374124bd4505521fc29cab0f9554a5386ba7d784a4e611c7e31;   // keccak256("iToken_LowerAdminContract")

    constructor()
        public
    {
        renounceOwnership();
    }

    function()
        external
        payable
    {
        require(msg.sender == wethToken, "fallback not allowed");
    }

    /* Public functions */

    function mint(
        address receiver,
        uint256 depositAmount)
        external
        nonReentrant
        pausable
        returns (uint256) // mintAmount
    {
        return _mintToken(
            receiver,
            depositAmount
        );
    }

    function burn(
        address receiver,
        uint256 burnAmount)
        external
        nonReentrant
        pausable
        returns (uint256 loanAmountPaid)
    {
        loanAmountPaid = _burnToken(
            burnAmount
        );

        if (loanAmountPaid != 0) {
            _safeTransfer(loanTokenAddress, receiver, loanAmountPaid, "5");
        }
    }

    function flashBorrow(
        uint256 borrowAmount,
        address borrower,
        address target,
        string calldata signature,
        bytes calldata data)
        external
        payable
        nonReentrant
        pausable
        returns (bytes memory)
    {
        require(borrowAmount != 0, "38");

        _settleInterest(0);

        // save before balances
        uint256 beforeEtherBalance = address(this).balance.sub(msg.value);
        uint256 beforeAssetsBalance = _underlyingBalance()
            .add(_totalAssetBorrowStored());

        // lock totalAssetSupply for duration of flash loan
        _flTotalAssetSupply = beforeAssetsBalance;

        // transfer assets to calling contract
        _safeTransfer(loanTokenAddress, borrower, borrowAmount, "39");

        emit FlashBorrow(borrower, target, loanTokenAddress, borrowAmount);

        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // arbitrary call
        (bool success, bytes memory returnData) = arbitraryCaller.call.value(msg.value)(
            abi.encodeWithSelector(
                0xde064e0d, // sendCall(address,bytes)
                target,
                callData
            )
        );
        require(success, "call failed");

        // unlock totalAssetSupply
        _flTotalAssetSupply = 0;
		
		// pay flash borrow fees
        IBZx(bZxContract).payFlashBorrowFees(
            borrower,
            borrowAmount,
            flashBorrowFeePercent
        );
	
        // verifies return of flash loan
        require(
            address(this).balance >= beforeEtherBalance &&
            _underlyingBalance()
                .add(_totalAssetBorrowStored()) >= beforeAssetsBalance,
            "40"
        );

        return returnData;
    }

    function borrow(
        bytes32 loanId,                 // 0 if new loan
        uint256 withdrawAmount,
        uint256 initialLoanDuration,    // duration in seconds
        uint256 collateralTokenSent,    // if 0, loanId must be provided; any ETH sent must equal this value
        address collateralTokenAddress, // if address(0), this means ETH and ETH must be sent with the call or loanId must be provided
        address borrower,
        address receiver,
        bytes memory /*loanDataBytes*/) // arbitrary order data
        public
        payable
        nonReentrant
        pausable
        returns (IBZx.LoanOpenData memory)
    {
        return _borrow(
            loanId,
            withdrawAmount,
            initialLoanDuration,
            collateralTokenSent,
            collateralTokenAddress,
            borrower,
            receiver,
            ""
        );
    }

    // Called to borrow and immediately get into a position
    function marginTrade(
        bytes32 loanId,                 // 0 if new loan
        uint256 leverageAmount,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address trader,
        bytes memory loanDataBytes)     // arbitrary order data
        public
        payable
        nonReentrant
        pausable
        returns (IBZx.LoanOpenData memory)
    {
        return _marginTrade(
            loanId,
            leverageAmount,
            loanTokenSent,
            collateralTokenSent,
            collateralTokenAddress,
            trader,
            loanDataBytes
        );
    }

    function transfer(
        address _to,
        uint256 _value)
        external
        returns (bool)
    {
        return _internalTransferFrom(
            msg.sender,
            _to,
            _value,
            uint256(-1)
        );
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        external
        returns (bool)
    {
        return _internalTransferFrom(
            _from,
            _to,
            _value,
            allowed[_from][msg.sender]
            /*IBZx(bZxContract).isLoanPool(msg.sender) ?
                uint256(-1) :
                allowed[_from][msg.sender]*/
        );
    }

    function _internalTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        uint256 _allowanceAmount)
        internal
        returns (bool)
    {
        if (_allowanceAmount != uint256(-1)) {
            allowed[_from][msg.sender] = _allowanceAmount.sub(_value, "14");
        }

        require(_to != address(0), "15");

        uint256 _balancesFrom = balances[_from];
        uint256 _balancesFromNew = _balancesFrom
            .sub(_value, "16");
        balances[_from] = _balancesFromNew;

        uint256 _balancesTo = balances[_to];
        uint256 _balancesToNew = _balancesTo
            .add(_value);
        balances[_to] = _balancesToNew;

        // handle checkpoint update
        uint256 _currentPrice = tokenPrice();

        _updateCheckpoints(
            _from,
            _balancesFrom,
            _balancesFromNew,
            _currentPrice
        );
        _updateCheckpoints(
            _to,
            _balancesTo,
            _balancesToNew,
            _currentPrice
        );

        emit Transfer(_from, _to, _value);
        return true;
    }

    function _updateCheckpoints(
        address _user,
        uint256 _oldBalance,
        uint256 _newBalance,
        uint256 _currentPrice)
        internal
    {
        bytes32 slot = keccak256(
            abi.encodePacked(_user, iToken_ProfitSoFar)
        );

        int256 _currentProfit;
        if (_newBalance == 0) {
            _currentPrice = 0;
        } else if (_oldBalance != 0) {
            _currentProfit = _profitOf(
                slot,
                _oldBalance,
                _currentPrice,
                checkpointPrices_[_user]
            );
        }

        assembly {
            sstore(slot, _currentProfit)
        }

        checkpointPrices_[_user] = _currentPrice;
    }

    /* Public View functions */

    function profitOf(
        address user)
        public
        view
        returns (int256)
    {
        bytes32 slot = keccak256(
            abi.encodePacked(user, iToken_ProfitSoFar)
        );

        return _profitOf(
            slot,
            balances[user],
            tokenPrice(),
            checkpointPrices_[user]
        );
    }

    function _profitOf(
        bytes32 slot,
        uint256 _balance,
        uint256 _currentPrice,
        uint256 _checkpointPrice)
        internal
        view
        returns (int256 profitSoFar)
    {
        if (_checkpointPrice == 0) {
            return 0;
        }

        assembly {
            profitSoFar := sload(slot)
        }

        profitSoFar = int256(_currentPrice)
            .sub(int256(_checkpointPrice))
            .mul(int256(_balance))
            .div(sWEI_PRECISION)
            .add(profitSoFar);
    }

    function tokenPrice()
        public
        view
        returns (uint256) // price
    {
        return _tokenPrice(_totalAssetSupply(totalAssetBorrow()));
    }

    function checkpointPrice(
        address _user)
        public
        view
        returns (uint256) // price
    {
        return checkpointPrices_[_user];
    }

    // the current rate being paid by borrowers in active loans
    function borrowInterestRate()
        public
        view
        returns (uint256)
    {
        return _nextBorrowInterestRate(
            _totalAssetBorrowStored(),
            0,
            poolTWAI()
        );
    }

    // the minimum rate that new and existing borrowers will pay after the next borrow
    function nextBorrowInterestRate(
        uint256 borrowAmount)
        external
        view
        returns (uint256)
    {
        return _nextBorrowInterestRate(
            totalAssetBorrow(),
            borrowAmount,
            poolTWAI()
        );
    }

    // the current rate being received by suppliers
    function supplyInterestRate()
        external
        view
        returns (uint256)
    {
        uint256 assetBorrow = _totalAssetBorrowStored();
        return _nextSupplyInterestRate(
            _nextBorrowInterestRate(assetBorrow, 0, poolTWAI()),
            assetBorrow,
            _totalAssetSupply(assetBorrow)
        );
    }

    // the minimum rate new and existing suppliers will receive after the next supply
    function nextSupplyInterestRate(
        int256 supplyAmount)
        external
        view
        returns (uint256)
    {
        uint256 assetBorrow = totalAssetBorrow();
        uint256 totalSupply = _totalAssetSupply(assetBorrow);

        if(supplyAmount >= 0)
            totalSupply = totalSupply.add(uint256(supplyAmount));
        else
            totalSupply = totalSupply.sub(uint256(-supplyAmount));

        return _nextSupplyInterestRate(
            _nextBorrowInterestRate(assetBorrow, 0, poolTWAI()),
            assetBorrow,
            totalSupply
        );
    }


    function totalAssetBorrow()
        public
        view
        returns (uint256)
    {
        return IBZx(bZxContract).getTotalPrincipal(
            address(this),
            address(0) // loanTokenAddress (depreciated)
        );
    }

    function _totalAssetBorrowStored()
        internal
        view
        returns (uint256)
    {
        return IBZx(bZxContract).getPoolPrincipalStored(address(this));
    }

    function totalAssetSupply()
        external
        view
        returns (uint256)
    {
        return _totalAssetSupply(totalAssetBorrow());
    }

    function poolLastInterestRate()
        public
        view
        returns (uint256)
    {
        return IBZx(bZxContract).getPoolLastInterestRate(address(this));
    }

    function poolTWAI()
        public
        view
        returns (uint256)
    {
        return IBZx(bZxContract).getTWAI(address(this));
    }

    // returns the user's balance of underlying token
    function assetBalanceOf(
        address _owner)
        external
        view
        returns (uint256)
    {
        return balanceOf(_owner)
            .mul(tokenPrice())
            .div(WEI_PRECISION);
    }

    function getDepositAmountForBorrow(
        uint256 borrowAmount,
        uint256 initialLoanDuration,        // duration in seconds
        address collateralTokenAddress)     // address(0) means ETH
        external
        view
        returns (uint256) // depositAmount
    {
        if (borrowAmount != 0) {
            if (borrowAmount <= _underlyingBalance()) {
                if (collateralTokenAddress == address(0)) {
                    collateralTokenAddress = wethToken;
                }
                return IBZx(bZxContract).getRequiredCollateralByParams(
                    loanParamsIds[uint256(keccak256(abi.encodePacked(
                        collateralTokenAddress,
                        true
                    )))],
                    borrowAmount
                ).add(10); // some dust to compensate for rounding errors
            }
        }
    }

    function getBorrowAmountForDeposit(
        uint256 depositAmount,
        uint256 initialLoanDuration,        // duration in seconds
        address collateralTokenAddress)     // address(0) means ETH
        external
        view
        returns (uint256 borrowAmount)
    {
        if (depositAmount != 0) {
            if (collateralTokenAddress == address(0)) {
                collateralTokenAddress = wethToken;
            }
            borrowAmount = IBZx(bZxContract).getBorrowAmountByParams(
                loanParamsIds[uint256(keccak256(abi.encodePacked(
                    collateralTokenAddress,
                    true
                )))],
                depositAmount
            );

            if (borrowAmount > _underlyingBalance()) {
                borrowAmount = 0;
            }
        }
    }

    function getPoolUtilization()
        external
        view
        returns (uint256)
    {
        uint256 totalBorrow = totalAssetBorrow();
        return _utilizationRate(
            totalBorrow,
            _totalAssetSupply(totalBorrow)
        );
    }

    /* Internal functions */

    function _mintToken(
        address receiver,
        uint256 depositAmount)
        internal
        pausable
        returns (uint256 mintAmount)
    {
        require (depositAmount != 0, "17");

        _settleInterest(0);

        uint256 currentPrice = _tokenPrice(_totalAssetSupply(_totalAssetBorrowStored()));
        mintAmount = depositAmount
            .mul(WEI_PRECISION)
            .div(currentPrice);

        if (msg.value == 0) {
            _safeTransferFrom(loanTokenAddress, msg.sender, address(this), depositAmount, "18");
        } else {
            require(msg.value == depositAmount, "18");
            IWeth(wethToken).deposit.value(depositAmount)();
        }

        _updateCheckpoints(
            receiver,
            balances[receiver],
            _mint(receiver, mintAmount, depositAmount, currentPrice), // newBalance
            currentPrice
        );
    }

    function _burnToken(
        uint256 burnAmount)
        internal
        pausable
        returns (uint256 loanAmountPaid)
    {
        require(burnAmount != 0, "19");

        _settleInterest(0);

        if (burnAmount > balanceOf(msg.sender)) {
            require(burnAmount == uint256(-1), "32");
            burnAmount = balanceOf(msg.sender);
        }

        uint256 currentPrice = _tokenPrice(_totalAssetSupply(_totalAssetBorrowStored()));

        uint256 loanAmountOwed = burnAmount
            .mul(currentPrice)
            .div(WEI_PRECISION);
        uint256 loanAmountAvailableInContract = _underlyingBalance();

        loanAmountPaid = loanAmountOwed;
        require(loanAmountPaid <= loanAmountAvailableInContract, "37");

        _updateCheckpoints(
            msg.sender,
            balances[msg.sender],
            _burn(msg.sender, burnAmount, loanAmountPaid, currentPrice), // newBalance
            currentPrice
        );
    }

    function _borrow(
        bytes32 loanId,                 // 0 if new loan
        uint256 withdrawAmount,
        uint256 initialLoanDuration,    // duration in seconds
        uint256 collateralTokenSent,    // if 0, loanId must be provided; any ETH sent must equal this value
        address collateralTokenAddress, // if address(0), this means ETH and ETH must be sent with the call or loanId must be provided
        address borrower,
        address receiver,
        bytes memory /*loanDataBytes*/) // arbitrary order data
        internal
        pausable
        returns (IBZx.LoanOpenData memory)
    {
        require(withdrawAmount != 0, "6");

        require(msg.value == 0 || msg.value == collateralTokenSent, "7");
        require(collateralTokenSent != 0 || loanId != 0, "8");
        require(collateralTokenAddress != address(0) || msg.value != 0 || loanId != 0, "9");

        // ensures authorized use of existing loan
        require(loanId == 0 || msg.sender == borrower, "13");

        _settleInterest(loanId);

        if (loanId == 0) {
            loanId = keccak256(abi.encodePacked(
                collateralTokenAddress,
                address(this),
                msg.sender,
                borrower,
                block.timestamp
            ));
        }

        if (collateralTokenAddress == address(0)) {
            collateralTokenAddress = wethToken;
        }
        require(collateralTokenAddress != loanTokenAddress, "10");

        address[4] memory sentAddresses;
        uint256[5] memory sentAmounts;

        sentAddresses[0] = address(this); // lender
        sentAddresses[1] = borrower;
        sentAddresses[2] = receiver;
        //sentAddresses[3] = address(0); // manager

        //sentAmounts[0] = 0; // interestRate (found later)
        //sentAmounts[1] = 0; // borrowAmount (found later)
        //sentAmounts[2] = 0; // interestInitialAmount (found later)
        //sentAmounts[3] = 0; // loanTokenSent
        sentAmounts[4] = collateralTokenSent;

        sentAmounts[1] = withdrawAmount;
        sentAmounts[2] = 0; // interestInitialAmount (depreciated)

        return _borrowOrTrade(
            loanId,
            withdrawAmount,
            0, // leverageAmount (calculated later)
            collateralTokenAddress,
            sentAddresses,
            sentAmounts,
            "" // loanDataBytes
        );
    }

    function _marginTrade(
        bytes32 loanId,                 // 0 if new loan
        uint256 leverageAmount,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address trader,
        bytes memory loanDataBytes)
        internal
        pausable
        returns (IBZx.LoanOpenData memory loanOpenData)
    {
        // ensures authorized use of existing loan
        require(loanId == 0 || msg.sender == trader, "13");

        _settleInterest(loanId);

        if (loanId == 0) {
            loanId = keccak256(abi.encodePacked(
                collateralTokenAddress,
                address(this),
                msg.sender,
                trader,
                block.timestamp
            ));
        }

        if (collateralTokenAddress == address(0)) {
            collateralTokenAddress = wethToken;
        }
        require(collateralTokenAddress != loanTokenAddress, "11");

        address[4] memory sentAddresses;
        uint256[5] memory sentAmounts;

        sentAddresses[0] = address(this); // lender
        sentAddresses[1] = trader;
        sentAddresses[2] = trader;
        //sentAddresses[3] = address(0); // manager

        //sentAmounts[0] = 0; // interestRate (found later)
        //sentAmounts[1] = 0; // borrowAmount (found later)
        //sentAmounts[2] = 0; // interestInitialAmount (interest is calculated based on fixed-term loan)
        sentAmounts[3] = loanTokenSent;
        sentAmounts[4] = collateralTokenSent;

        uint256 totalDeposit;
        uint256 collateralToLoanRate;
        (sentAmounts[1],, totalDeposit, collateralToLoanRate) = _getPreMarginData( // borrowAmount, interestRate, totalDeposit, collateralToLoanRate
            collateralTokenAddress,
            collateralTokenSent,
            loanTokenSent,
            leverageAmount
        );
        require(totalDeposit != 0, "12");

        loanOpenData = _borrowOrTrade(
            loanId,
            0, // withdrawAmount
            leverageAmount,
            collateralTokenAddress,
            sentAddresses,
            sentAmounts,
            loanDataBytes
        );

        IBZx(bZxContract).setDepositAmount(
            loanOpenData.loanId,
            totalDeposit,
            totalDeposit
                .mul(WEI_PRECISION)
                .div(collateralToLoanRate)
        );

        return loanOpenData;
    }

    function _settleInterest(
        bytes32 loanId)
        internal
    {   
        IBZx(bZxContract).settleInterest(loanId);
    }

    function _totalDeposit(
        address collateralTokenAddress,
        uint256 collateralTokenSent,
        uint256 loanTokenSent)
        internal
        view
        returns (uint256 totalDeposit, uint256 collateralToLoanRate)
    {
        uint256 collateralToLoanPrecision;
        (collateralToLoanRate, collateralToLoanPrecision) = IPriceFeeds(IBZx(bZxContract).priceFeeds()).queryRate(
            collateralTokenAddress,
            loanTokenAddress
        );
        require(collateralToLoanRate != 0 && collateralToLoanPrecision != 0, "20");
        collateralToLoanRate = collateralToLoanRate
            .mul(WEI_PRECISION)
            .div(collateralToLoanPrecision);

        totalDeposit = loanTokenSent;
        if (collateralTokenSent != 0) {
            totalDeposit = collateralTokenSent
                .mul(collateralToLoanRate)
                .div(WEI_PRECISION)
                .add(totalDeposit);
        }
    }

    // returns newPrincipal
    function _borrowOrTrade(
        bytes32 loanId,
        uint256 withdrawAmount,
        uint256 leverageAmount,
        address collateralTokenAddress,
        address[4] memory sentAddresses,
        uint256[5] memory sentAmounts,
        bytes memory loanDataBytes)
        internal
        returns (IBZx.LoanOpenData memory)
    {
        require (sentAmounts[1] <= _underlyingBalance() && // newPrincipal
            sentAddresses[1] != address(0), // borrower
            "24"
        );

	    if (sentAddresses[2] == address(0)) {
            sentAddresses[2] = sentAddresses[1]; // receiver = borrower
        }

        // handle transfers prior to adding newPrincipal to loanTokenSent
        uint256 msgValue = _verifyTransfers(
            collateralTokenAddress,
            sentAddresses,
            sentAmounts,
            withdrawAmount
        );

        // adding the loan token portion from the lender to loanTokenSent
        sentAmounts[3] = sentAmounts[3]
            .add(sentAmounts[1]); // newPrincipal

        if (withdrawAmount != 0) {
            // withdrawAmount already sent to the borrower, so we aren't sending it to the protocol
            sentAmounts[3] = sentAmounts[3]
                .sub(withdrawAmount);
        }

        bool isTorqueLoan = withdrawAmount != 0 ?
            true :
            false;

        bytes32 loanParamsId = loanParamsIds[uint256(keccak256(abi.encodePacked(
            collateralTokenAddress,
            isTorqueLoan
        )))];

        // converting to initialMargin
        if (leverageAmount != 0) {
            leverageAmount = SafeMath.div(WEI_PRECISION * WEI_PERCENT_PRECISION, leverageAmount);
        }

        return IBZx(bZxContract).borrowOrTradeFromPool.value(msgValue)(
            loanParamsId,
            loanId,
            isTorqueLoan,
            leverageAmount, // initialMargin
            sentAddresses,
            sentAmounts,
            loanDataBytes
        );
    }

    // sentAddresses[0]: lender
    // sentAddresses[1]: borrower
    // sentAddresses[2]: receiver
    // sentAddresses[3]: manager
    // sentAmounts[0]: interestRate
    // sentAmounts[1]: newPrincipal
    // sentAmounts[2]: interestInitialAmount
    // sentAmounts[3]: loanTokenSent
    // sentAmounts[4]: collateralTokenSent
    function _verifyTransfers(
        address collateralTokenAddress,
        address[4] memory sentAddresses,
        uint256[5] memory sentAmounts,
        uint256 withdrawalAmount)
        internal
        returns (uint256 msgValue)
    {
        address _wethToken = wethToken;
        address _loanTokenAddress = loanTokenAddress;
        address receiver = sentAddresses[2];
        uint256 newPrincipal = sentAmounts[1];
        uint256 loanTokenSent = sentAmounts[3];
        uint256 collateralTokenSent = sentAmounts[4];

        require(_loanTokenAddress != collateralTokenAddress, "26");

        msgValue = msg.value;

        if (withdrawalAmount != 0) { // withdrawOnOpen == true
            _safeTransfer(_loanTokenAddress, receiver, withdrawalAmount, "27");
            if (newPrincipal > withdrawalAmount) {
                _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal - withdrawalAmount, "27");
            }
        } else {
            _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal, "27");
        }

        if (collateralTokenSent != 0) {
            if (collateralTokenAddress == _wethToken && msgValue != 0 && msgValue >= collateralTokenSent) {
                IWeth(_wethToken).deposit.value(collateralTokenSent)();
                _safeTransfer(collateralTokenAddress, bZxContract, collateralTokenSent, "28");
                msgValue -= collateralTokenSent;
            } else {
                _safeTransferFrom(collateralTokenAddress, msg.sender, bZxContract, collateralTokenSent, "28");
            }
        }

        if (loanTokenSent != 0) {
            _safeTransferFrom(_loanTokenAddress, msg.sender, bZxContract, loanTokenSent, "29");
        }
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 amount,
        string memory errorMsg)
        internal
    {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20(token).transfer.selector, to, amount),
            errorMsg
        );
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount,
        string memory errorMsg)
        internal
    {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20(token).transferFrom.selector, from, to, amount),
            errorMsg
        );
    }

    function _callOptionalReturn(
        address token,
        bytes memory data,
        string memory errorMsg)
        internal
    {
        (bool success, bytes memory returndata) = token.call(data);
        require(success, errorMsg);

        if (returndata.length != 0) {
            require(abi.decode(returndata, (bool)), errorMsg);
        }
    }

    function _underlyingBalance()
        internal
        view
        returns (uint256)
    {
        return IERC20(loanTokenAddress).balanceOf(address(this));
    }

    function _nextSupplyInterestRate(
        uint256 nextBorrowRate,
        uint256 assetBorrow,
        uint256 assetSupply)
        public
        view
        returns (uint256)
    {
        if (assetBorrow != 0 && assetSupply >= assetBorrow) {
            return nextBorrowRate
                .mul(_utilizationRate(assetBorrow, assetSupply))
                .mul(SafeMath.sub(WEI_PERCENT_PRECISION, IBZx(bZxContract).lendingFeePercent()))
                .div(WEI_PERCENT_PRECISION * WEI_PERCENT_PRECISION);
        }
    }

    function _nextBorrowInterestRate(
        uint256 totalBorrow,
        uint256 newBorrowNotYetRealized,
        uint256 lastIR)
        public
        view
        returns (uint256 nextRate)
    {
        uint256 utilRate = _utilizationRate(
            totalBorrow.add(newBorrowNotYetRealized),
            _totalAssetSupply(totalBorrow)
        );

        //utilRate from 0e18 to 100e18
        nextRate = rateHelper.calculateIR(utilRate, lastIR);
    }

    /* Internal View functions */

    function _tokenPrice(
        uint256 assetSupply)
        internal
        view
        returns (uint256)
    {
        uint256 totalTokenSupply = totalSupply_;

        return totalTokenSupply != 0 ?
            assetSupply
                .mul(WEI_PRECISION)
                .div(totalTokenSupply) : initialPrice;
    }

    function _getPreMarginData(
        address collateralTokenAddress,
        uint256 collateralTokenSent,
        uint256 loanTokenSent,
        uint256 leverageAmount)
        internal
        view
        returns (uint256 borrowAmount, uint256 interestRate, uint256 totalDeposit, uint256 collateralToLoanRate)
    {
        (totalDeposit, collateralToLoanRate) = _totalDeposit(
            collateralTokenAddress,
            collateralTokenSent,
            loanTokenSent
        );

        uint256 initialMargin = SafeMath.div(WEI_PRECISION * WEI_PERCENT_PRECISION, leverageAmount);

        // assumes that loan and collateral token are the same
        borrowAmount = totalDeposit
            .mul(WEI_PERCENT_PRECISION)
            .div(initialMargin);
    }

    function _totalAssetSupply(
        uint256 totalBorrow)
        internal
        view
        returns (uint256 totalSupply)
    {
        totalSupply = _flTotalAssetSupply; // temporary locked totalAssetSupply during a flash loan transaction
        if (totalSupply == 0) {
            totalSupply = _underlyingBalance()
                .add(totalBorrow);
        }
    }

    function _utilizationRate(
        uint256 assetBorrow,
        uint256 assetSupply)
        internal
        pure
        returns (uint256)
    {
        if (assetSupply != 0) {
            // U = total_borrow / total_supply
            return assetBorrow
                .mul(WEI_PERCENT_PRECISION)
                .div(assetSupply);
        }
    }


    /* Owner-Only functions */

    function updateSettings(
        address settingsTarget,
        bytes memory callData)
        public
    {
        if (msg.sender != owner()) {
            address _lowerAdmin;
            address _lowerAdminContract;
            assembly {
                _lowerAdmin := sload(iToken_LowerAdminAddress)
                _lowerAdminContract := sload(iToken_LowerAdminContract)
            }
            require(msg.sender == _lowerAdmin && settingsTarget == _lowerAdminContract);
        }

        address currentTarget = target_;
        target_ = settingsTarget;

        (bool result,) = address(this).call(callData);

        uint256 size;
        uint256 ptr;
        assembly {
            size := returndatasize
            ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            if eq(result, 0) { revert(ptr, size) }
        }

        target_ = currentTarget;

        assembly {
            return(ptr, size)
        }
    }

    function updateFlashBorrowFeePercent(uint256 newFeePercent) public onlyOwner {
        flashBorrowFeePercent = newFeePercent;
    }
}

/*
pragma solidity 0.5.16;

contract ArbitraryCaller {
    function sendCall(
        address target,
        bytes calldata callData)
        external
        payable
    {
        (bool success,) = target.call.value(msg.value)(callData);
        assembly {
            let size := returndatasize()
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            if eq(success, 0) { revert(ptr, size) }
            return(ptr, size)
        }
    }
}
*/

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "AdvancedTokenStorage.sol";


contract AdvancedToken is AdvancedTokenStorage {
    using SafeMath for uint256;

    function approve(
        address _spender,
        uint256 _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval(
        address _spender,
        uint256 _addedValue)
        public
        returns (bool)
    {
        uint256 _allowed = allowed[msg.sender][_spender]
            .add(_addedValue);
        allowed[msg.sender][_spender] = _allowed;

        emit Approval(msg.sender, _spender, _allowed);
        return true;
    }

    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 _allowed = allowed[msg.sender][_spender];
        if (_subtractedValue >= _allowed) {
            _allowed = 0;
        } else {
            _allowed -= _subtractedValue;
        }
        allowed[msg.sender][_spender] = _allowed;

        emit Approval(msg.sender, _spender, _allowed);
        return true;
    }

    function _mint(
        address _to,
        uint256 _tokenAmount,
        uint256 _assetAmount,
        uint256 _price)
        internal
        returns (uint256)
    {
        require(_to != address(0), "15");

        uint256 _balance = balances[_to]
            .add(_tokenAmount);
        balances[_to] = _balance;

        totalSupply_ = totalSupply_
            .add(_tokenAmount);

        emit Mint(_to, _tokenAmount, _assetAmount, _price);
        emit Transfer(address(0), _to, _tokenAmount);

        return _balance;
    }

    function _burn(
        address _who,
        uint256 _tokenAmount,
        uint256 _assetAmount,
        uint256 _price)
        internal
        returns (uint256)
    {
        uint256 _balance = balances[_who].sub(_tokenAmount, "16");
        
        // a rounding error may leave dust behind, so we clear this out
        if (_balance <= 10) {
            _tokenAmount = _tokenAmount.add(_balance);
            _balance = 0;
        }
        balances[_who] = _balance;

        totalSupply_ = totalSupply_.sub(_tokenAmount);

        emit Burn(_who, _tokenAmount, _assetAmount, _price);
        emit Transfer(_who, address(0), _tokenAmount);

        return _balance;
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "LoanTokenBase.sol";


contract AdvancedTokenStorage is LoanTokenBase {
    using SafeMath for uint256;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Mint(
        address indexed minter,
        uint256 tokenAmount,
        uint256 assetAmount,
        uint256 price
    );

    event Burn(
        address indexed burner,
        uint256 tokenAmount,
        uint256 assetAmount,
        uint256 price
    );

    event FlashBorrow(
        address borrower,
        address target,
        address loanToken,
        uint256 loanAmount
    );

    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 internal totalSupply_;

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupply_;
    }

    function balanceOf(
        address _owner)
        public
        view
        returns (uint256)
    {
        return balances[_owner];
    }

    function allowance(
        address _owner,
        address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "SafeMath.sol";
import "SignedSafeMath.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";
import "Address.sol";
import "IWethERC20.sol";
import "PausableGuardian.sol";


contract LoanTokenBase is ReentrancyGuard, Ownable, PausableGuardian {

    uint256 internal constant WEI_PRECISION = 10**18;
    uint256 internal constant WEI_PERCENT_PRECISION = 10**20;

    int256 internal constant sWEI_PRECISION = 10**18;

    string public name;
    string public symbol;
    uint8 public decimals;

    // uint88 for tight packing -> 8 + 88 + 160 = 256
    uint88 internal lastSettleTime_;

    address public loanTokenAddress;

    uint256 internal baseRate_UNUSED;
    uint256 internal rateMultiplier_UNUSED;
    uint256 internal lowUtilBaseRate_UNUSED;
    uint256 internal lowUtilRateMultiplier_UNUSED;
    uint256 internal targetLevel_UNUSED;
    uint256 internal kinkLevel_UNUSED;
    uint256 internal maxScaleRate_UNUSED;

    uint256 internal _flTotalAssetSupply;
    uint256 internal checkpointSupply_UNUSED;
    uint256 public initialPrice;

    mapping (uint256 => bytes32) public loanParamsIds; // mapping of keccak256(collateralToken, isTorqueLoan) to loanParamsId
    mapping (address => uint256) internal checkpointPrices_; // price of token at last user checkpoint
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.5.0 <0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

        /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

pragma solidity >=0.5.0 <0.6.0;


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

    /// @dev Constant for unlocked guard state - non-zero to prevent extra gas costs.
    /// See: https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1056
    uint256 internal constant REENTRANCY_GUARD_FREE = 1;

    /// @dev Constant for locked guard state
    uint256 internal constant REENTRANCY_GUARD_LOCKED = 2;

    /**
    * @dev We use a single lock for the whole contract.
    */
    uint256 internal reentrancyLock = REENTRANCY_GUARD_FREE;

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * If you mark a function `nonReentrant`, you should also
    * mark it `external`. Calling one `nonReentrant` function from
    * another is not supported. Instead, you can implement a
    * `private` function doing the actual work, and an `external`
    * wrapper marked as `nonReentrant`.
    */
    modifier nonReentrant() {
        require(reentrancyLock == REENTRANCY_GUARD_FREE, "nonReentrant");
        reentrancyLock = REENTRANCY_GUARD_LOCKED;
        _;
        reentrancyLock = REENTRANCY_GUARD_FREE;
    }

}

pragma solidity ^0.5.0;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;

import "IWeth.sol";
import "IERC20.sol";


contract IWethERC20 is IWeth, IERC20 {}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;


interface IWeth {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "Ownable.sol";


contract PausableGuardian is Ownable {

    // keccak256("Pausable_FunctionPause")
    bytes32 internal constant Pausable_FunctionPause = 0xa7143c84d793a15503da6f19bf9119a2dac94448ca45d77c8bf08f57b2e91047;

    // keccak256("Pausable_GuardianAddress")
    bytes32 internal constant Pausable_GuardianAddress = 0x80e6706973d0c59541550537fd6a33b971efad732635e6c3b99fb01006803cdf;

    modifier pausable {
        require(!_isPaused(msg.sig), "paused");
        _;
    }

    modifier onlyGuardian {
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");
        _;
    }

    function _isPaused(bytes4 sig) public view returns (bool isPaused) {
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            isPaused := sload(slot)
        }
    }

    function toggleFunctionPause(bytes4 sig) public onlyGuardian {
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            sstore(slot, 1)
        }
    }

    function toggleFunctionUnPause(bytes4 sig) public onlyGuardian {
        // only DAO can unpause, and adding guardian temporarily
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            sstore(slot, 0)
        }
    }

    function changeGuardian(address newGuardian) public onlyGuardian {
        assembly {
            sstore(Pausable_GuardianAddress, newGuardian)
        }
    }

    function getGuardian() public view returns (address guardian) {
        assembly {
            guardian := sload(Pausable_GuardianAddress)
        }
    }

    function pause(bytes4 [] calldata sig)
        external
        onlyGuardian
    {
        for(uint256 i = 0; i < sig.length; ++i){
            toggleFunctionPause(sig[i]);
        }
    }

    function unpause(bytes4 [] calldata sig)
        external
        onlyGuardian
    {
        for(uint256 i = 0; i < sig.length; ++i){
            toggleFunctionUnPause(sig[i]);
        }
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "ICurvedInterestRate.sol";


contract StorageExtension {

    address internal target_;
    uint256 public flashBorrowFeePercent; // set to 0.03%
    ICurvedInterestRate rateHelper;
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0 <0.9.0;

interface ICurvedInterestRate {
    function getInterestRate(
        uint256 _U,
        uint256 _a,
        uint256 _b
    ) external pure returns (uint256 interestRate);

    function getAB(uint256 _IR1) external pure returns (uint256 a, uint256 b);

    function getAB(
        uint256 _IR1,
        uint256 _IR2,
        uint256 _UR1,
        uint256 _UR2
    ) external pure returns (uint256 a, uint256 b);

    function calculateIR(uint256 _U, uint256 _IR1) external pure returns (uint256 interestRate);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache-2.0
 */
// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

/// @title A proxy interface for The Protocol
/// @author bZeroX
/// @notice This is just an interface, not to be deployed itself.
/// @dev This interface is to be used for the protocol interactions.
interface IBZx {
    ////// Protocol //////

    /// @dev adds or replaces existing proxy module
    /// @param target target proxy module address
    function replaceContract(address target) external;

    /// @dev updates all proxy modules addreses and function signatures.
    /// sigsArr and targetsArr should be of equal length
    /// @param sigsArr array of function signatures
    /// @param targetsArr array of target proxy module addresses
    function setTargets(
        string[] calldata sigsArr,
        address[] calldata targetsArr
    ) external;

    /// @dev returns protocol module address given a function signature
    /// @return module address
    function getTarget(string calldata sig) external view returns (address);

    ////// Protocol Settings //////

    /// @dev sets price feed contract address. The contract on the addres should implement IPriceFeeds interface
    /// @param newContract module address for the IPriceFeeds implementation
    function setPriceFeedContract(address newContract) external;

    /// @dev sets swaps contract address. The contract on the addres should implement ISwapsImpl interface
    /// @param newContract module address for the ISwapsImpl implementation
    function setSwapsImplContract(address newContract) external;

    /// @dev sets loan pool with assets. Accepts two arrays of equal length
    /// @param pools array of address of pools
    /// @param assets array of addresses of assets
    function setLoanPool(address[] calldata pools, address[] calldata assets)
        external;

    /// @dev updates list of supported tokens, it can be use also to disable or enable particualr token
    /// @param addrs array of address of pools
    /// @param toggles array of addresses of assets
    /// @param withApprovals resets tokens to unlimited approval with the swaps integration (kyber, etc.)
    function setSupportedTokens(
        address[] calldata addrs,
        bool[] calldata toggles,
        bool withApprovals
    ) external;

    /// @dev sets lending fee with WEI_PERCENT_PRECISION
    /// @param newValue lending fee percent
    function setLendingFeePercent(uint256 newValue) external;

    /// @dev sets trading fee with WEI_PERCENT_PRECISION
    /// @param newValue trading fee percent
    function setTradingFeePercent(uint256 newValue) external;

    /// @dev sets borrowing fee with WEI_PERCENT_PRECISION
    /// @param newValue borrowing fee percent
    function setBorrowingFeePercent(uint256 newValue) external;

    /// @dev sets affiliate fee with WEI_PERCENT_PRECISION
    /// @param newValue affiliate fee percent
    function setAffiliateFeePercent(uint256 newValue) external;

    /// @dev sets liquidation inncetive percent per loan per token. This is the profit percent
    /// that liquidator gets in the process of liquidating.
    /// @param loanTokens array list of loan tokens
    /// @param collateralTokens array list of collateral tokens
    /// @param amounts array list of liquidation inncetive amount
    function setLiquidationIncentivePercent(
        address[] calldata loanTokens,
        address[] calldata collateralTokens,
        uint256[] calldata amounts
    ) external;

    /// @dev sets max swap rate slippage percent.
    /// @param newAmount max swap rate slippage percent.
    function setMaxDisagreement(uint256 newAmount) external;

    /// TODO
    function setSourceBufferPercent(uint256 newAmount) external;

    /// @dev sets maximum supported swap size in ETH
    /// @param newAmount max swap size in ETH.
    function setMaxSwapSize(uint256 newAmount) external;

    /// @dev sets fee controller address
    /// @param newController address of the new fees controller
    function setFeesController(address newController) external;

    /// @dev withdraws lending fees to receiver. Only can be called by feesController address
    /// @param tokens array of token addresses.
    /// @param receiver fees receiver address
    /// @return amounts array of amounts withdrawn
    function withdrawFees(
        address[] calldata tokens,
        address receiver,
        FeeClaimType feeType
    ) external returns (uint256[] memory amounts);

    /*
    Targets still exist, but functions are decommissioned:

    /// @dev withdraw protocol token (BZRX) from vesting contract vBZRX
    /// @param receiver address of BZRX tokens claimed
    /// @param amount of BZRX token to be claimed. max is claimed if amount is greater than balance.
    /// @return rewardToken reward token address
    /// @return withdrawAmount amount
    function withdrawProtocolToken(address receiver, uint256 amount)
        external
        returns (address rewardToken, uint256 withdrawAmount);

    /// @dev depozit protocol token (BZRX)
    /// @param amount address of BZRX tokens to deposit
    function depositProtocolToken(uint256 amount) external;

    function grantRewards(address[] calldata users, uint256[] calldata amounts)
        external
        returns (uint256 totalAmount);*/

    // NOTE: this doesn't sanitize inputs -> inaccurate values may be returned if there are duplicate token inputs
    function queryFees(address[] calldata tokens, FeeClaimType feeType)
        external
        view
        returns (uint256[] memory amountsHeld, uint256[] memory amountsPaid);

    function priceFeeds() external view returns (address);

    function swapsImpl() external view returns (address);

    function logicTargets(bytes4) external view returns (address);

    function loans(bytes32) external view returns (Loan memory);

    function loanParams(bytes32) external view returns (LoanParams memory);

    // we don't use this yet
    // function lenderOrders(address, bytes32) external returns (Order memory);
    // function borrowerOrders(address, bytes32) external returns (Order memory);

    function delegatedManagers(bytes32, address) external view returns (bool);

    function lenderInterest(address, address)
        external
        view
        returns (LenderInterest memory);

    function loanInterest(bytes32) external view returns (LoanInterest memory);

    function feesController() external view returns (address);

    function lendingFeePercent() external view returns (uint256);

    function lendingFeeTokensHeld(address) external view returns (uint256);

    function lendingFeeTokensPaid(address) external view returns (uint256);

    function borrowingFeePercent() external view returns (uint256);

    function borrowingFeeTokensHeld(address) external view returns (uint256);

    function borrowingFeeTokensPaid(address) external view returns (uint256);

    function protocolTokenHeld() external view returns (uint256);

    function protocolTokenPaid() external view returns (uint256);

    function affiliateFeePercent() external view returns (uint256);

    function liquidationIncentivePercent(address, address)
        external
        view
        returns (uint256);

    function loanPoolToUnderlying(address) external view returns (address);

    function underlyingToLoanPool(address) external view returns (address);

    function supportedTokens(address) external view returns (bool);

    function maxDisagreement() external view returns (uint256);

    function sourceBufferPercent() external view returns (uint256);

    function maxSwapSize() external view returns (uint256);

    /// @dev get list of loan pools in the system. Ordering is not guaranteed
    /// @param start start index
    /// @param count number of pools to return
    /// @return loanPoolsList array of loan pools
    function getLoanPoolsList(uint256 start, uint256 count)
        external
        view
        returns (address[] memory loanPoolsList);

    /// @dev checks whether addreess is a loan pool address
    /// @return boolean
    function isLoanPool(address loanPool) external view returns (bool);

    ////// Loan Settings //////

    /// @dev creates new loan param settings
    /// @param loanParamsList array of LoanParams
    /// @return loanParamsIdList array of loan ids created
    function setupLoanParams(LoanParams[] calldata loanParamsList)
        external
        returns (bytes32[] memory loanParamsIdList);

    function setupLoanPoolTWAI(address pool) external;

    function setTWAISettings(uint32 delta, uint32 secondsAgo) external;

    /// @dev Deactivates LoanParams for future loans. Active loans using it are unaffected.
    /// @param loanParamsIdList array of loan ids
    function disableLoanParams(bytes32[] calldata loanParamsIdList) external;

    /// @dev gets array of LoanParams by given ids
    /// @param loanParamsIdList array of loan ids
    /// @return loanParamsList array of LoanParams
    function getLoanParams(bytes32[] calldata loanParamsIdList)
        external
        view
        returns (LoanParams[] memory loanParamsList);

    /// @dev Enumerates LoanParams in the system by owner
    /// @param owner of the loan params
    /// @param start number of loans to return
    /// @param count total number of the items
    /// @return loanParamsList array of LoanParams
    function getLoanParamsList(
        address owner,
        uint256 start,
        uint256 count
    ) external view returns (bytes32[] memory loanParamsList);

    /// @dev returns total loan principal for token address
    /// @param lender address
    /// @param loanToken address
    /// @return total principal of the loan
    function getTotalPrincipal(address lender, address loanToken)
        external
        view
        returns (uint256);

    /// @dev returns total principal for a loan pool that was last settled
    /// @param pool address
    /// @return total stored principal of the loan
    function getPoolPrincipalStored(address pool)
        external
        view
        returns (uint256);

    /// @dev returns the last interest rate founnd during interest settlement
    /// @param pool address
    /// @return the last interset rate
    function getPoolLastInterestRate(address pool)
        external
        view
        returns (uint256);

    ////// Loan Openings //////

    /// @dev This is THE function that borrows or trades on the protocol
    /// @param loanParamsId id of the LoanParam created beforehand by setupLoanParams function
    /// @param loanId id of existing loan, if 0, start a new loan
    /// @param isTorqueLoan boolean whether it is toreque or non torque loan
    /// @param initialMargin in WEI_PERCENT_PRECISION
    /// @param sentAddresses array of size 4:
    ///         lender: must match loan if loanId provided
    ///         borrower: must match loan if loanId provided
    ///         receiver: receiver of funds (address(0) assumes borrower address)
    ///         manager: delegated manager of loan unless address(0)
    /// @param sentValues array of size 5:
    ///         newRate: new loan interest rate
    ///         newPrincipal: new loan size (borrowAmount + any borrowed interest)
    ///         torqueInterest: new amount of interest to escrow for Torque loan (determines initial loan length)
    ///         loanTokenReceived: total loanToken deposit (amount not sent to borrower in the case of Torque loans)
    ///         collateralTokenReceived: total collateralToken deposit
    /// @param loanDataBytes required when sending ether
    /// @return principal of the loan and collateral amount
    function borrowOrTradeFromPool(
        bytes32 loanParamsId,
        bytes32 loanId,
        bool isTorqueLoan,
        uint256 initialMargin,
        address[4] calldata sentAddresses,
        uint256[5] calldata sentValues,
        bytes calldata loanDataBytes
    ) external payable returns (LoanOpenData memory);

    /// @dev sets/disables/enables the delegated manager for the loan
    /// @param loanId id of the loan
    /// @param delegated delegated manager address
    /// @param toggle boolean set enabled or disabled
    function setDelegatedManager(
        bytes32 loanId,
        address delegated,
        bool toggle
    ) external;

    /// @dev calculates required collateral for simulated position
    /// @param loanToken address of loan token
    /// @param collateralToken address of collateral token
    /// @param newPrincipal principal amount of the loan
    /// @param marginAmount margin amount of the loan
    /// @param isTorqueLoan boolean torque or non torque loan
    /// @return collateralAmountRequired amount required
    function getRequiredCollateral(
        address loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 marginAmount,
        bool isTorqueLoan
    ) external view returns (uint256 collateralAmountRequired);

    function getRequiredCollateralByParams(
        bytes32 loanParamsId,
        uint256 newPrincipal
    ) external view returns (uint256 collateralAmountRequired);

    /// @dev calculates borrow amount for simulated position
    /// @param loanToken address of loan token
    /// @param collateralToken address of collateral token
    /// @param collateralTokenAmount amount of collateral token sent
    /// @param marginAmount margin amount
    /// @param isTorqueLoan boolean torque or non torque loan
    /// @return borrowAmount possible borrow amount
    function getBorrowAmount(
        address loanToken,
        address collateralToken,
        uint256 collateralTokenAmount,
        uint256 marginAmount,
        bool isTorqueLoan
    ) external view returns (uint256 borrowAmount);

    function getBorrowAmountByParams(
        bytes32 loanParamsId,
        uint256 collateralTokenAmount
    ) external view returns (uint256 borrowAmount);

    ////// Loan Closings //////

    /// @dev liquidates unhealty loans
    /// @param loanId id of the loan
    /// @param receiver address receiving liquidated loan collateral
    /// @param closeAmount amount to close denominated in loanToken
    /// @return loanCloseAmount amount of the collateral token of the loan
    /// @return seizedAmount sezied amount in the collateral token
    /// @return seizedToken loan token address
    function liquidate(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount
    )
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            address seizedToken
        );

    /// @dev close position with loan token deposit
    /// @param loanId id of the loan
    /// @param receiver collateral token reciever address
    /// @param depositAmount amount of loan token to deposit
    /// @return loanCloseAmount loan close amount
    /// @return withdrawAmount loan token withdraw amount
    /// @return withdrawToken loan token address
    function closeWithDeposit(
        bytes32 loanId,
        address receiver,
        uint256 depositAmount // denominated in loanToken
    )
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );

    /// @dev close position with swap
    /// @param loanId id of the loan
    /// @param receiver collateral token reciever address
    /// @param swapAmount amount of loan token to swap
    /// @param returnTokenIsCollateral boolean whether to return tokens is collateral
    /// @param loanDataBytes custom payload for specifying swap implementation and data to pass
    /// @return loanCloseAmount loan close amount
    /// @return withdrawAmount loan token withdraw amount
    /// @return withdrawToken loan token address
    function closeWithSwap(
        bytes32 loanId,
        address receiver,
        uint256 swapAmount, // denominated in collateralToken
        bool returnTokenIsCollateral, // true: withdraws collateralToken, false: withdraws loanToken
        bytes calldata loanDataBytes
    )
        external
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );

    ////// Loan Closings With Gas Token //////

    /// @dev liquidates unhealty loans by using Gas token
    /// @param loanId id of the loan
    /// @param receiver address receiving liquidated loan collateral
    /// @param gasTokenUser user address of the GAS token
    /// @param closeAmount amount to close denominated in loanToken
    /// @return loanCloseAmount loan close amount
    /// @return seizedAmount loan token withdraw amount
    /// @return seizedToken loan token address
    function liquidateWithGasToken(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 closeAmount // denominated in loanToken
    )
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            address seizedToken
        );

    /// @dev close position with loan token deposit
    /// @param loanId id of the loan
    /// @param receiver collateral token reciever address
    /// @param gasTokenUser user address of the GAS token
    /// @param depositAmount amount of loan token to deposit denominated in loanToken
    /// @return loanCloseAmount loan close amount
    /// @return withdrawAmount loan token withdraw amount
    /// @return withdrawToken loan token address
    function closeWithDepositWithGasToken(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 depositAmount
    )
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );

    /// @dev close position with swap
    /// @param loanId id of the loan
    /// @param receiver collateral token reciever address
    /// @param gasTokenUser user address of the GAS token
    /// @param swapAmount amount of loan token to swap denominated in collateralToken
    /// @param returnTokenIsCollateral  true: withdraws collateralToken, false: withdraws loanToken
    /// @return loanCloseAmount loan close amount
    /// @return withdrawAmount loan token withdraw amount
    /// @return withdrawToken loan token address
    function closeWithSwapWithGasToken(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 swapAmount,
        bool returnTokenIsCollateral,
        bytes calldata loanDataBytes
    )
        external
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );

    ////// Loan Maintenance //////

    /// @dev deposit collateral to existing loan
    /// @param loanId existing loan id
    /// @param depositAmount amount to deposit which must match msg.value if ether is sent
    function depositCollateral(bytes32 loanId, uint256 depositAmount)
        external
        payable;

    /// @dev withdraw collateral from existing loan
    /// @param loanId existing loan id
    /// @param receiver address of withdrawn tokens
    /// @param withdrawAmount amount to withdraw
    /// @return actualWithdrawAmount actual amount withdrawn
    function withdrawCollateral(
        bytes32 loanId,
        address receiver,
        uint256 withdrawAmount
    ) external returns (uint256 actualWithdrawAmount);

    /// @dev settles accrued interest for all active loans from a loan pool
    /// @param loanId existing loan id
    function settleInterest(bytes32 loanId) external;

    function setDepositAmount(
        bytes32 loanId,
        uint256 depositValueAsLoanToken,
        uint256 depositValueAsCollateralToken
    ) external;

    function transferLoan(bytes32 loanId, address newOwner) external;

    // Decommissioned function, but leave interface to allow remaining claims
    function claimRewards(address receiver)
        external
        returns (uint256 claimAmount);

    // Decommissioned function, but leave interface to allow remaining claims
    function rewardsBalanceOf(address user)
        external
        view
        returns (uint256 rewardsBalance);

    function getInterestModelValues(
        address pool,
        bytes32 loanId)
        external
        view
        returns (
        uint256 _poolLastUpdateTime,
        uint256 _poolPrincipalTotal,
        uint256 _poolInterestTotal,
        uint256 _poolRatePerTokenStored,
        uint256 _poolLastInterestRate,
        uint256 _loanPrincipalTotal,
        uint256 _loanInterestTotal,
        uint256 _loanRatePerTokenPaid
        );
    
    function getTWAI(
        address pool)
        external
        view returns (
            uint256 benchmarkRate
        );

    /// @dev gets list of loans of particular user address
    /// @param user address of the loans
    /// @param start of the index
    /// @param count number of loans to return
    /// @param loanType type of the loan: All(0), Margin(1), NonMargin(2)
    /// @param isLender whether to list lender loans or borrower loans
    /// @param unsafeOnly booleat if true return only unsafe loans that are open for liquidation
    /// @return loansData LoanReturnData array of loans
    function getUserLoans(
        address user,
        uint256 start,
        uint256 count,
        LoanType loanType,
        bool isLender,
        bool unsafeOnly
    ) external view returns (LoanReturnData[] memory loansData);

    function getUserLoansCount(address user, bool isLender)
        external
        view
        returns (uint256);

    /// @dev gets existing loan
    /// @param loanId id of existing loan
    /// @return loanData array of loans
    function getLoan(bytes32 loanId)
        external
        view
        returns (LoanReturnData memory loanData);

    /// @dev gets loan principal including interest
    /// @param loanId id of existing loan
    /// @return principal
    function getLoanPrincipal(bytes32 loanId)
        external
        view
        returns (uint256 principal);

    /// @dev gets loan outstanding interest
    /// @param loanId id of existing loan
    /// @return interest
    function getLoanInterestOutstanding(bytes32 loanId)
        external
        view
        returns (uint256 interest);


    /// @dev get current active loans in the system
    /// @param start of the index
    /// @param count number of loans to return
    /// @param unsafeOnly boolean if true return unsafe loan only (open for liquidation)
    function getActiveLoans(
        uint256 start,
        uint256 count,
        bool unsafeOnly
    ) external view returns (LoanReturnData[] memory loansData);

    /// @dev get current active loans in the system
    /// @param start of the index
    /// @param count number of loans to return
    /// @param unsafeOnly boolean if true return unsafe loan only (open for liquidation)
    /// @param isLiquidatable boolean if true return liquidatable loans only
    function getActiveLoansAdvanced(
        uint256 start,
        uint256 count,
        bool unsafeOnly,
        bool isLiquidatable
    ) external view returns (LoanReturnData[] memory loansData);

    function getActiveLoansCount() external view returns (uint256);

    ////// Swap External //////

    /// @dev swap thru external integration
    /// @param sourceToken source token address
    /// @param destToken destintaion token address
    /// @param receiver address to receive tokens
    /// @param returnToSender TODO
    /// @param sourceTokenAmount source token amount
    /// @param requiredDestTokenAmount destination token amount
    /// @param swapData TODO
    /// @return destTokenAmountReceived destination token received
    /// @return sourceTokenAmountUsed source token amount used
    function swapExternal(
        address sourceToken,
        address destToken,
        address receiver,
        address returnToSender,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes calldata swapData
    )
        external
        payable
        returns (
            uint256 destTokenAmountReceived,
            uint256 sourceTokenAmountUsed
        );

    /// @dev swap thru external integration using GAS
    /// @param sourceToken source token address
    /// @param destToken destintaion token address
    /// @param receiver address to receive tokens
    /// @param returnToSender TODO
    /// @param gasTokenUser user address of the GAS token
    /// @param sourceTokenAmount source token amount
    /// @param requiredDestTokenAmount destination token amount
    /// @param swapData TODO
    /// @return destTokenAmountReceived destination token received
    /// @return sourceTokenAmountUsed source token amount used
    function swapExternalWithGasToken(
        address sourceToken,
        address destToken,
        address receiver,
        address returnToSender,
        address gasTokenUser,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes calldata swapData
    )
        external
        payable
        returns (
            uint256 destTokenAmountReceived,
            uint256 sourceTokenAmountUsed
        );

    /// @dev calculate simulated return of swap
    /// @param sourceToken source token address
    /// @param destToken destination token address
    /// @param sourceTokenAmount source token amount
    /// @return amoun denominated in destination token
    function getSwapExpectedReturn(
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount,
        bytes calldata swapData
    ) external view returns (uint256);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;


    /// Guardian Interface

    function _isPaused(bytes4 sig) external view returns (bool isPaused);

    function toggleFunctionPause(bytes4 sig) external;

    function toggleFunctionUnPause(bytes4 sig) external;

    function pause(bytes4 [] calldata sig) external;

    function unpause(bytes4 [] calldata sig) external;

    function changeGuardian(address newGuardian) external;

    function getGuardian() external view returns (address guardian);

    /// Loan Cleanup Interface

    function cleanupLoans(
        address loanToken,
        bytes32[] calldata loanIds)
        external
        payable
        returns (uint256 totalPrincipalIn);

    struct LoanParams {
        bytes32 id;
        bool active;
        address owner;
        address loanToken;
        address collateralToken;
        uint256 minInitialMargin;
        uint256 maintenanceMargin;
        uint256 maxLoanTerm;
    }

    struct LoanOpenData {
        bytes32 loanId;
        uint256 principal;
        uint256 collateral;
    }

    enum LoanType {
        All,
        Margin,
        NonMargin
    }

    struct LoanReturnData {
        bytes32 loanId;
        uint96 endTimestamp;
        address loanToken;
        address collateralToken;
        uint256 principal;
        uint256 collateral;
        uint256 interestOwedPerDay;
        uint256 interestDepositRemaining;
        uint256 startRate;
        uint256 startMargin;
        uint256 maintenanceMargin;
        uint256 currentMargin;
        uint256 maxLoanTerm;
        uint256 maxLiquidatable;
        uint256 maxSeizable;
        uint256 depositValueAsLoanToken;
        uint256 depositValueAsCollateralToken;
    }

    enum FeeClaimType {
        All,
        Lending,
        Trading,
        Borrowing
    }

    struct Loan {
        bytes32 id; // id of the loan
        bytes32 loanParamsId; // the linked loan params id
        bytes32 pendingTradesId; // the linked pending trades id
        uint256 principal; // total borrowed amount outstanding
        uint256 collateral; // total collateral escrowed for the loan
        uint256 startTimestamp; // loan start time
        uint256 endTimestamp; // for active loans, this is the expected loan end time, for in-active loans, is the actual (past) end time
        uint256 startMargin; // initial margin when the loan opened
        uint256 startRate; // reference rate when the loan opened for converting collateralToken to loanToken
        address borrower; // borrower of this loan
        address lender; // lender of this loan
        bool active; // if false, the loan has been fully closed
    }

    struct LenderInterest {
        uint256 principalTotal; // total borrowed amount outstanding of asset
        uint256 owedPerDay; // interest owed per day for all loans of asset
        uint256 owedTotal; // total interest owed for all loans of asset (assuming they go to full term)
        uint256 paidTotal; // total interest paid so far for asset
        uint256 updatedTimestamp; // last update
    }

    struct LoanInterest {
        uint256 owedPerDay; // interest owed per day for loan
        uint256 depositTotal; // total escrowed interest for loan
        uint256 updatedTimestamp; // last update
    }
	
	////// Flash Borrow Fees //////
    function payFlashBorrowFees(
        address user,
        uint256 borrowAmount,
        uint256 flashBorrowFeePercent)
        external;
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.9.0;


interface IPriceFeeds {
    function queryRate(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 rate, uint256 precision);

    function queryPrecision(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 precision);

    function queryReturn(
        address sourceToken,
        address destToken,
        uint256 sourceAmount)
        external
        view
        returns (uint256 destAmount);

    function checkPriceDisagreement(
        address sourceToken,
        address destToken,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 maxSlippage)
        external
        view
        returns (uint256 sourceToDestSwapRate);

    function amountInEth(
        address Token,
        uint256 amount)
        external
        view
        returns (uint256 ethAmount);

    function getMaxDrawdown(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (uint256);

    function getCurrentMarginAndCollateralSize(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralInEthAmount);

    function getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralToLoanRate);

    function shouldLiquidate(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (bool);

    function getFastGasPrice(
        address payToken)
        external
        view
        returns (uint256);
}