// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "../../interfaces/IERC20.sol";
import "../../libraries/SafeERC20.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/ICurvePoolFactory.sol";

interface ICurvePool {
    function add_liquidity(uint256[2] memory _deposit_amounts, uint256 _min_mint_amount) external returns (uint256);

    function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts)
        external
        returns (uint256[2] memory);
}

error CurveStrategy_NotIncurDebtAddress();
error CurveStrategy_AmountsDoNotMatch();
error CurveStrategy_LPTokenDoesNotMatch();
error CurveStrategy_OhmAddressNotFound();

/**
    @title CurveStrategy
    @notice This contract provides liquidity to curve on behalf of IncurDebt contract.
 */
contract CurveStrategy is IStrategy {
    using SafeERC20 for IERC20;

    ICurvePoolFactory factory;
    address public immutable incurDebtAddress;
    address public immutable ohmAddress;

    constructor(
        address _incurDebtAddress,
        address _ohmAddress,
        address _factory
    ) {
        factory = ICurvePoolFactory(_factory);
        incurDebtAddress = _incurDebtAddress;
        ohmAddress = _ohmAddress;
    }

    /**
     * @dev Make sure input amounts is in the same order as the order of the tokens in the pool when calling get_coins
     */
    function addLiquidity(
        bytes memory _data,
        uint256 _ohmAmount,
        address _user
    )
        external
        returns (
            uint256 liquidity,
            uint256 ohmUnused,
            address lpTokenAddress
        )
    {
        if (msg.sender != incurDebtAddress) revert CurveStrategy_NotIncurDebtAddress();

        (uint256[2] memory amounts, uint256 min_mint_amount, address pairTokenAddress, address poolAddress) = abi
            .decode(_data, (uint256[2], uint256, address, address));

        address[4] memory poolTokens = factory.get_coins(poolAddress);

        if (poolTokens[0] == ohmAddress) {
            if (poolTokens[1] != pairTokenAddress) revert CurveStrategy_LPTokenDoesNotMatch();
            if (_ohmAmount != amounts[0]) revert CurveStrategy_AmountsDoNotMatch();

            IERC20(ohmAddress).safeTransferFrom(incurDebtAddress, address(this), _ohmAmount);
            IERC20(pairTokenAddress).safeTransferFrom(_user, address(this), amounts[1]);

            IERC20(pairTokenAddress).approve(poolAddress, amounts[1]);
        } else if (poolTokens[1] == ohmAddress) {
            if (poolTokens[0] != pairTokenAddress) revert CurveStrategy_LPTokenDoesNotMatch();
            if (_ohmAmount != amounts[1]) revert CurveStrategy_AmountsDoNotMatch();

            IERC20(ohmAddress).safeTransferFrom(incurDebtAddress, address(this), _ohmAmount);
            IERC20(pairTokenAddress).safeTransferFrom(_user, address(this), amounts[0]);

            IERC20(pairTokenAddress).approve(poolAddress, amounts[0]);
        } else {
            revert CurveStrategy_LPTokenDoesNotMatch();
        }

        IERC20(ohmAddress).approve(poolAddress, _ohmAmount);
        liquidity = ICurvePool(poolAddress).add_liquidity(amounts, min_mint_amount); // Ohm unused will be 0 since curve uses up all input tokens for LP.

        lpTokenAddress = poolAddress; // For factory pools on curve, the LP token is the pool contract.
        IERC20(lpTokenAddress).safeTransfer(incurDebtAddress, liquidity);
    }

    function removeLiquidity(
        bytes memory _data,
        uint256 _liquidity,
        address _lpTokenAddress,
        address _user
    ) external returns (uint256 ohmRecieved) {
        if (msg.sender != incurDebtAddress) revert CurveStrategy_NotIncurDebtAddress();

        (uint256 _burn_amount, uint256[2] memory _min_amounts) = abi.decode(_data, (uint256, uint256[2]));

        if (_burn_amount != _liquidity) revert CurveStrategy_AmountsDoNotMatch();

        uint256[2] memory resultAmounts = ICurvePool(_lpTokenAddress).remove_liquidity(_burn_amount, _min_amounts);

        address[4] memory poolTokens = factory.get_coins(_lpTokenAddress);

        if (poolTokens[0] == ohmAddress) {
            ohmRecieved = resultAmounts[0];
            IERC20(poolTokens[1]).safeTransfer(_user, resultAmounts[1]);
        } else {
            ohmRecieved = resultAmounts[1];
            IERC20(poolTokens[0]).safeTransfer(_user, resultAmounts[0]);
        }

        IERC20(ohmAddress).safeTransfer(incurDebtAddress, ohmRecieved);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
    @title IStrategy
    @notice This interface is implemented by strategy contracts to provide liquidity on behalf of incurdebt contract.
 */
interface IStrategy {
    /**
        @notice Add liquidity to the dex using this strategy.
        @dev Some strategies like uniswap will have tokens left over which is either sent back to 
        incur debt contract (OHM) or back to LPer's wallet address (pair token). Other strategies like
        curve will have no leftover tokens.
        This function is also only for LPing for pools with two tokens. Do not use this for pools with more than 2 tokens.
        @param _data Data needed to input into external call to add liquidity. Different for different strategies.
        @param _ohmAmount amount of OHM to LP 
        @param _user address of user that called incur debt function to do this operation.
        @return liquidity : total amount of lp tokens gained.
        ohmUnused : total amount of ohm unused in LP process and sent back to incur debt address.
        lpTokenAddress : address of LP token gained.
    */
    function addLiquidity(
        bytes memory _data,
        uint256 _ohmAmount,
        address _user
    )
        external
        returns (
            uint256 liquidity,
            uint256 ohmUnused,
            address lpTokenAddress
        );

    /**
        @notice Remove liquidity to the dex using this strategy.
        @param _data Data needed to input into external call to remove liquidity. Different for different strategies.
        @param _liquidity amount of LP tokens to remove liquidity from.
        @param _lpTokenAddress address of LP token to remove.
        @param _user address of user that called incur debt function to do this operation.
        @return ohmRecieved : total amount of ohm recieved from removing the LP. Send back to incurdebt contract.
    */
    function removeLiquidity(
        bytes memory _data,
        uint256 _liquidity,
        address _lpTokenAddress,
        address _user
    ) external returns (uint256 ohmRecieved);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

interface ICurvePoolFactory {
    function get_coins(address _pool) external view returns (address[4] memory);

    function deploy_plain_pool(
        string memory _name,
        string memory _symbol,
        address[4] memory _coins,
        uint256 _A,
        uint256 _fee
    ) external returns (address);

    function pool_list(uint256 _arg) external view returns (address);

    function pool_count() external view returns (uint256);
}