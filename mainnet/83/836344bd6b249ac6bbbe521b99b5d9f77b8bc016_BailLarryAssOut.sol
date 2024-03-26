/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address, uint256) external;
}

interface IFraxGaugeUniV3 {
    struct LockedNFT {
        uint256 token_id; // for Uniswap V3 LPs
        uint256 liquidity;
        uint256 start_timestamp;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
        int24 tick_lower;
        int24 tick_upper;
    }

    function lockedNFTsOf(address account)
        external
        view
        returns (LockedNFT[] memory);
}

interface IStrategyProxy {
    function withdrawV3(
        address _gauge,
        uint256 _tokenId,
        address[] memory _rewardTokens
    ) external returns (uint256);
}

interface IUniswapV3PositionsNFT {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);
}

contract BailLarryAssOut {
    function bail() external {
        address recipient = 0x324E0b53CefA84CF970833939249880f814557c6;
        address gauge = 0x3EF26504dbc8Dd7B7aa3E97Bc9f3813a9FC0B4B0;
        address locker = 0xd639C2eA4eEFfAD39b599410d00252E6c80008DF;

        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address frax = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
        address fxs = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
        address strategyProxy = 0x7a10B3C48216A54D1a1a1d268D24F69A77Ac94AD;

        // First, we get all the Uni V3 NFTs into the strategy
        address[] memory rewardTokens = new address[](3);
        rewardTokens[0] = fxs;
        rewardTokens[1] = usdc;
        rewardTokens[2] = frax;

        IFraxGaugeUniV3.LockedNFT[] memory lockedNfts = IFraxGaugeUniV3(gauge)
            .lockedNFTsOf(address(locker));
        for (uint256 i = 0; i < lockedNfts.length; i++) {
            if (lockedNfts[i].token_id > 0 && lockedNfts[i].liquidity > 0) {
                IStrategyProxy(strategyProxy).withdrawV3(
                    gauge,
                    lockedNfts[i].token_id,
                    rewardTokens
                );

                // Next, we unwind liquidity
                IUniswapV3PositionsNFT nftManager = IUniswapV3PositionsNFT(
                    0xC36442b4a4522E871399CD717aBDD847Ab11FE88
                );

                nftManager.decreaseLiquidity(
                    IUniswapV3PositionsNFT.DecreaseLiquidityParams({
                        tokenId: lockedNfts[i].token_id,
                        liquidity: uint128(lockedNfts[i].liquidity),
                        amount0Min: 0,
                        amount1Min: 0,
                        deadline: block.timestamp + 300
                    })
                );

                nftManager.collect(
                    IUniswapV3PositionsNFT.CollectParams({
                        tokenId: lockedNfts[i].token_id,
                        recipient: address(this),
                        amount0Max: type(uint128).max,
                        amount1Max: type(uint128).max
                    })
                );
            }
        }

        IERC20(fxs).transfer(recipient, IERC20(fxs).balanceOf(address(this)));
        IERC20(usdc).transfer(recipient, IERC20(usdc).balanceOf(address(this)));
        IERC20(frax).transfer(recipient, IERC20(frax).balanceOf(address(this)));
    }
}