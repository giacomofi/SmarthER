//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../../../utils/Constants.sol';
import './StakingFraxCurveConvexStratBase.sol';

contract XAIStakingFraxCurveConvex is StakingFraxCurveConvexStratBase {
    constructor(Config memory config)
        StakingFraxCurveConvexStratBase(
            config,
            Constants.FRAX_USDC_ADDRESS,
            Constants.FRAX_USDC_LP_ADDRESS,
            Constants.CRV_FRAX_XAI_ADDRESS,
            Constants.CRV_FRAX_XAI_LP_ADDRESS,
            Constants.CVX_FRAX_XAI_PID // 38
        )
    {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Constants {
    bytes32 internal constant USDC_TICKER = 'usdc';
    bytes32 internal constant USDT_TICKER = 'usdt';
    bytes32 internal constant DAI_TICKER = 'dai';
    bytes32 internal constant CRV_TICKER = 'a3CRV';

    uint256 internal constant CVX_BUSD_PID = 3;
    uint256 internal constant CVX_SUSD_PID = 4;
    uint256 internal constant CVX_USDK_PID = 12;
    uint256 internal constant CVX_USDN_PID = 13;
    uint256 internal constant CVX_MUSD_PID = 14;
    uint256 internal constant CVX_RSV_PID = 15;
    uint256 internal constant CVX_DUSD_PID = 17;
    uint256 internal constant CVX_AAVE_PID = 24;
    uint256 internal constant CVX_USDP_PID = 28;
    uint256 internal constant CVX_IRONBANK_PID = 29;
    uint256 internal constant CVX_TUSD_PID = 31;
    uint256 internal constant CVX_FRAX_PID = 32;
    uint256 internal constant CVX_LUSD_PID = 33;
    uint256 internal constant CVX_BUSDV2_PID = 34;
    uint256 internal constant CVX_FRAX_XAI_PID = 38;
    uint256 internal constant CVX_MIM_PID = 40;
    uint256 internal constant CVX_OUSD_PID = 56;
    uint256 internal constant CVX_UST_PID = 59;
    uint256 internal constant CVX_D3_PID = 58;
    uint256 internal constant CVX_PUSD_PID = 91;
    uint256 internal constant CVX_USDD_PID = 96;
    uint256 internal constant CVX_DOLA_PID = 62;
    uint256 internal constant CVX_FRAX_LUSD_PID = 102;
    uint256 internal constant CVX_FRAX_ALUSD_PID = 106;

    uint256 internal constant TRADE_DEADLINE = 2000;

    address internal constant CVX_ADDRESS = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address internal constant CRV_ADDRESS = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant TUSD_ADDRESS = 0x0000000000085d4780B73119b644AE5ecd22b376;
    address internal constant SUSD_ADDRESS = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address internal constant BUSD_ADDRESS = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address internal constant OUSD_ADDRESS = 0x2A8e1E676Ec238d8A992307B495b45B3fEAa5e86;
    address internal constant MUSD_ADDRESS = 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5;
    address internal constant MIM_ADDRESS = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;
    address internal constant DUSD_ADDRESS = 0x5BC25f649fc4e26069dDF4cF4010F9f706c23831;
    address internal constant ALUSD_ADDRESS = 0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9;
    address internal constant LUSD_ADDRESS = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address internal constant USDP_ADDRESS = 0x1456688345527bE1f37E9e627DA0837D6f08C925;
    address internal constant USDN_ADDRESS = 0x674C6Ad92Fd080e4004b2312b45f796a192D27a0;
    address internal constant USDK_ADDRESS = 0x1c48f86ae57291F7686349F12601910BD8D470bb;
    address internal constant FRAX_ADDRESS = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address internal constant RSV_ADDRESS = 0x196f4727526eA7FB1e17b2071B3d8eAA38486988;
    address internal constant UST_ADDRESS = 0xa47c8bf37f92aBed4A126BDA807A7b7498661acD;
    address internal constant PUSD_ADDRESS = 0x466a756E9A7401B5e2444a3fCB3c2C12FBEa0a54;
    address internal constant USDD_ADDRESS = 0x0C10bF8FcB7Bf5412187A595ab97a3609160b5c6;
    address internal constant DOLA_ADDRESS = 0x865377367054516e17014CcdED1e7d814EDC9ce4;
    address internal constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant SUSHI_ROUTER_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address internal constant SUSHI_CRV_WETH_ADDRESS = 0x58Dc5a51fE44589BEb22E8CE67720B5BC5378009;
    address internal constant SUSHI_WETH_CVX_ADDRESS = 0x05767d9EF41dC40689678fFca0608878fb3dE906;
    address internal constant SUSHI_WETH_USDT_ADDRESS = 0x06da0fd433C1A5d7a4faa01111c044910A184553;
    address internal constant CVX_BOOSTER_ADDRESS = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address internal constant CRV_3POOL_ADDRESS = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address internal constant CRV_3POOL_LP_ADDRESS = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address internal constant CRV_AAVE_ADDRESS = 0xDeBF20617708857ebe4F679508E7b7863a8A8EeE;
    address internal constant CRV_AAVE_LP_ADDRESS = 0xFd2a8fA60Abd58Efe3EeE34dd494cD491dC14900;
    address internal constant CVX_AAVE_REWARDS_ADDRESS = 0xE82c1eB4BC6F92f85BF7EB6421ab3b882C3F5a7B;
    address internal constant CRV_IRONBANK_ADDRESS = 0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF;
    address internal constant CRV_IRONBANK_LP_ADDRESS = 0x5282a4eF67D9C33135340fB3289cc1711c13638C;
    address internal constant CVX_IRONBANK_REWARDS_ADDRESS =
        0x3E03fFF82F77073cc590b656D42FceB12E4910A8;
    address internal constant CRV_TUSD_ADDRESS = 0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1;
    address internal constant CRV_TUSD_LP_ADDRESS = 0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1;
    address internal constant CVX_TUSD_REWARDS_ADDRESS = 0x308b48F037AAa75406426dACFACA864ebd88eDbA;
    address internal constant CRV_SUSD_ADDRESS = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address internal constant CRV_SUSD_LP_ADDRESS = 0xC25a3A3b969415c80451098fa907EC722572917F;
    address internal constant CVX_SUSD_REWARDS_ADDRESS = 0x22eE18aca7F3Ee920D01F25dA85840D12d98E8Ca;
    address internal constant CVX_SUSD_EXTRA_ADDRESS = 0x81fCe3E10D12Da6c7266a1A169c4C96813435263;
    address internal constant SUSD_EXTRA_ADDRESS = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address internal constant SUSD_EXTRA_PAIR_ADDRESS = 0xA1d7b2d891e3A1f9ef4bBC5be20630C2FEB1c470;
    address internal constant CRV_USDK_ADDRESS = 0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb;
    address internal constant CRV_USDK_LP_ADDRESS = 0x97E2768e8E73511cA874545DC5Ff8067eB19B787;
    address internal constant CVX_USDK_REWARDS_ADDRESS = 0xa50e9071aCaD20b31cd2bbe4dAa816882De82BBe;
    address internal constant CRV_USDP_ADDRESS = 0x42d7025938bEc20B69cBae5A77421082407f053A;
    address internal constant CRV_USDP_LP_ADDRESS = 0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6;
    address internal constant CVX_USDP_REWARDS_ADDRESS = 0x24DfFd1949F888F91A0c8341Fc98a3F280a782a8;
    address internal constant CVX_USDP_EXTRA_ADDRESS = 0x5F91615268bE6b4aDD646b2560785B8F17dccBb4;
    address internal constant USDP_EXTRA_ADDRESS = 0x92E187a03B6CD19CB6AF293ba17F2745Fd2357D5;
    address internal constant USDP_EXTRA_PAIR_ADDRESS = 0x69aa90C6cD099BF383Bd9A0ac29E61BbCbF3b8D9;
    address internal constant CRV_BUSD_ADDRESS = 0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27;
    address internal constant CRV_BUSD_LP_ADDRESS = 0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;
    address internal constant CVX_BUSD_REWARDS_ADDRESS = 0x602c4cD53a715D8a7cf648540FAb0d3a2d546560;
    address internal constant CRV_BUSDV2_ADDRESS = 0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a;
    address internal constant CRV_BUSDV2_LP_ADDRESS = 0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a;
    address internal constant CVX_BUSDV2_REWARDS_ADDRESS =
        0xbD223812d360C9587921292D0644D18aDb6a2ad0;
    address internal constant CRV_OUSD_ADDRESS = 0x87650D7bbfC3A9F10587d7778206671719d9910D;
    address internal constant CRV_OUSD_LP_ADDRESS = 0x87650D7bbfC3A9F10587d7778206671719d9910D;
    address internal constant CRV_OUSD_EXTRA_ADDRESS = 0x8A05801c1512F6018e450b0F69e9Ca7b985fCea3;
    address internal constant OUSD_EXTRA_ADDRESS = 0x8207c1FfC5B6804F6024322CcF34F29c3541Ae26;
    address internal constant OUSD_EXTRA_PAIR_ADDRESS = 0x72ea6Ca0D47b337f1EA44314d9d90E2A897eDaF5;
    address internal constant CVX_OUSD_REWARDS_ADDRESS = 0x7D536a737C13561e0D2Decf1152a653B4e615158;
    address internal constant CRV_USDN_ADDRESS = 0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1;
    address internal constant CRV_USDN_LP_ADDRESS = 0x4f3E8F405CF5aFC05D68142F3783bDfE13811522;
    address internal constant CVX_USDN_REWARDS_ADDRESS = 0x4a2631d090e8b40bBDe245e687BF09e5e534A239;
    address internal constant CRV_LUSD_ADDRESS = 0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address internal constant CRV_LUSD_LP_ADDRESS = 0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address internal constant CVX_LUSD_REWARDS_ADDRESS = 0x2ad92A7aE036a038ff02B96c88de868ddf3f8190;
    address internal constant CRV_MUSD_ADDRESS = 0x8474DdbE98F5aA3179B3B3F5942D724aFcdec9f6;
    address internal constant CRV_MUSD_LP_ADDRESS = 0x1AEf73d49Dedc4b1778d0706583995958Dc862e6;
    address internal constant CVX_MUSD_REWARDS_ADDRESS = 0xDBFa6187C79f4fE4Cda20609E75760C5AaE88e52;
    address internal constant CVX_MUSD_EXTRA_ADDRESS = 0x93A5C724c4992FCBDA6b96F06fa15EB8B5c485b7;
    address internal constant MUSD_EXTRA_ADDRESS = 0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2;
    address internal constant MUSD_EXTRA_PAIR_ADDRESS = 0x663242D053057f317A773D7c262B700616d0b9A0;
    address internal constant CRV_DUSD_ADDRESS = 0x8038C01A0390a8c547446a0b2c18fc9aEFEcc10c;
    address internal constant CRV_DUSD_LP_ADDRESS = 0x3a664Ab939FD8482048609f652f9a0B0677337B9;
    address internal constant CVX_DUSD_REWARDS_ADDRESS = 0x1992b82A8cCFC8f89785129D6403b13925d6226E;
    address internal constant CVX_DUSD_EXTRA_ADDRESS = 0x666F8eEE6FD6839853993977CC86a7A51425673C;
    address internal constant DUSD_EXTRA_ADDRESS = 0x20c36f062a31865bED8a5B1e512D9a1A20AA333A;
    address internal constant DUSD_EXTRA_PAIR_ADDRESS = 0x663242D053057f317A773D7c262B700616d0b9A0;
    address internal constant CRV_RSV_ADDRESS = 0xC18cC39da8b11dA8c3541C598eE022258F9744da;
    address internal constant CRV_RSV_LP_ADDRESS = 0xC2Ee6b0334C261ED60C72f6054450b61B8f18E35;
    address internal constant CVX_RSV_REWARDS_ADDRESS = 0xedfCCF611D7c40F43e77a1340cE2C29EEEC27205;
    address internal constant CRV_FRAX_ADDRESS = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address internal constant CRV_FRAX_LP_ADDRESS = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address internal constant CVX_FRAX_REWARDS_ADDRESS = 0xB900EF131301B307dB5eFcbed9DBb50A3e209B2e;
    address internal constant CRV_MIM_ADDRESS = 0x5a6A4D54456819380173272A5E8E9B9904BdF41B;
    address internal constant CRV_MIM_LP_ADDRESS = 0x5a6A4D54456819380173272A5E8E9B9904BdF41B;
    address internal constant CVX_MIM_REWARDS_ADDRESS = 0xFd5AbF66b003881b88567EB9Ed9c651F14Dc4771;
    address internal constant CVX_MIM_EXTRA_ADDRESS = 0x69a92f1656cd2e193797546cFe2EaF32EACcf6f7;
    address internal constant MIM_EXTRA_ADDRESS = 0x090185f2135308BaD17527004364eBcC2D37e5F6;
    address internal constant MIM_EXTRA_PAIR_ADDRESS = 0xb5De0C3753b6E1B4dBA616Db82767F17513E6d4E;
    address internal constant CRV_UST_WORMHOLE_ADDRESS = 0xCEAF7747579696A2F0bb206a14210e3c9e6fB269;
    address internal constant CRV_UST_WORMHOLE_LP_ADDRESS =
        0xCEAF7747579696A2F0bb206a14210e3c9e6fB269;
    address internal constant CVX_UST_WORMHOLE_REWARDS_ADDRESS =
        0x7e2b9B5244bcFa5108A76D5E7b507CFD5581AD4A;
    address internal constant CRV_D3_ADDRESS = 0xBaaa1F5DbA42C3389bDbc2c9D2dE134F5cD0Dc89;
    address internal constant CRV_D3_LP_ADDRESS = 0xBaaa1F5DbA42C3389bDbc2c9D2dE134F5cD0Dc89;
    address internal constant CVX_D3_REWARDS_ADDRESS = 0x329cb014b562d5d42927cfF0dEdF4c13ab0442EF;
    address internal constant CRV_PUSD_ADDRESS = 0x8EE017541375F6Bcd802ba119bdDC94dad6911A1;
    address internal constant CRV_PUSD_LP_ADDRESS = 0x8EE017541375F6Bcd802ba119bdDC94dad6911A1;
    address internal constant CVX_PUSD_REWARDS_ADDRESS = 0x83a3CE160915675F5bC7cC3CfDA5f4CeBC7B7a5a;
    address internal constant CRV_USDD_ADDRESS = 0xe6b5CC1B4b47305c58392CE3D359B10282FC36Ea;
    address internal constant CRV_USDD_LP_ADDRESS = 0xe6b5CC1B4b47305c58392CE3D359B10282FC36Ea;
    address internal constant CVX_USDD_REWARDS_ADDRESS = 0x7D475cc8A5E0416f0e63042547aDB94ca7045A5b;
    address internal constant CRV_DOLA_ADDRESS = 0xAA5A67c256e27A5d80712c51971408db3370927D;
    address internal constant CRV_DOLA_LP_ADDRESS = 0xAA5A67c256e27A5d80712c51971408db3370927D;
    address internal constant CRV_DOLA_REWARDS_ADDRESS = 0x835f69e58087E5B6bffEf182fe2bf959Fe253c3c;
    address internal constant CRV_FRAX_LUSD_ADDRESS = 0x497CE58F34605B9944E6b15EcafE6b001206fd25;
    address internal constant CRV_FRAX_LUSD_LP_ADDRESS = 0x497CE58F34605B9944E6b15EcafE6b001206fd25;
    address internal constant CVX_FRAX_LUSD_REWARDS_ADDRESS =
        0x053e1dad223A206e6BCa24C77786bb69a10e427d;
    address internal constant CRV_FRAX_ALUSD_ADDRESS = 0xB30dA2376F63De30b42dC055C93fa474F31330A5;
    address internal constant CRV_FRAX_ALUSD_LP_ADDRESS =
        0xB30dA2376F63De30b42dC055C93fa474F31330A5;
    address internal constant CVX_FRAX_ALUSD_REWARDS_ADDRESS =
        0x26598e3E511ADFadefD70ab2C3475Ff741741104;
    address internal constant FRAX_USDC_ADDRESS = 0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2;
    address internal constant FRAX_USDC_LP_ADDRESS = 0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC;
    address internal constant SDT_MIM_VAULT_ADDRESS = 0x98dd95D0ac5b70B0F4ae5080a1C2EeA8c5c48387;
    address internal constant SDT_MIM_SPELL_ADDRESS = 0x090185f2135308BaD17527004364eBcC2D37e5F6;

    address internal constant CRV_FRAX_XAI_ADDRESS = 0x326290A1B0004eeE78fa6ED4F1d8f4b2523ab669;
    address internal constant CRV_FRAX_XAI_LP_ADDRESS = 0x326290A1B0004eeE78fa6ED4F1d8f4b2523ab669;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../../../utils/Constants.sol';
import '../../../../interfaces/IZunami.sol';
import '../../../interfaces/IRewardManager.sol';
import '../../interfaces/ICurvePool2.sol';
import '../interfaces/IConvexStakingBooster.sol';
import '../interfaces/IStakingProxyConvex.sol';
import '../../../interfaces/IStableConverter.sol';

//import "hardhat/console.sol";

abstract contract StakingFraxCurveConvexStratBase is Context, Ownable {
    using SafeERC20 for IERC20Metadata;

    enum WithdrawalType {
        Base,
        OneCoin
    }

    struct Config {
        IERC20Metadata[3] tokens;
        IERC20Metadata[] rewards;
        IConvexStakingBooster booster;
    }

    Config internal _config;

    IZunami public zunami;
    IRewardManager public rewardManager;
    IStableConverter public stableConverter;

    uint256 public constant CURVE_PRICE_DENOMINATOR = 1e18;
    uint256 public constant DEPOSIT_DENOMINATOR = 10000;
    uint256 public constant ZUNAMI_DAI_TOKEN_ID = 0;
    uint256 public constant ZUNAMI_USDC_TOKEN_ID = 1;
    uint256 public constant ZUNAMI_USDT_TOKEN_ID = 2;

    uint256 constant FRAX_USDC_POOL_USDC_ID = 1;
    int128 constant FRAX_USDC_POOL_USDC_ID_INT = 1;
    uint256 constant CRVFRAX_TOKEN_POOL_CRVFRAX_ID = 1;
    int128 constant CRVFRAX_TOKEN_POOL_CRVFRAX_ID_INT = 1;

    uint256 constant CRVFRAX_TOKEN_POOL_TOKEN_ID = 0;

    uint256 public minDepositAmount = 9975; // 99.75%
    address public feeDistributor;

    uint256 public managementFees = 0;
    uint256 public feeTokenId = ZUNAMI_USDT_TOKEN_ID;

    uint256 public cvxPoolPID;

    uint256[3] public decimalsMultipliers;

    // fraxUsdcPool = FRAX + USDC => crvFrax
    ICurvePool2 public fraxUsdcPool;
    IERC20Metadata public fraxUsdcPoolLp; // crvFrax

    // crvFraxTokenPool = crvFrax + Token
    ICurvePool2 public crvFraxTokenPool;
    IERC20Metadata public crvFraxTokenPoolLp;

    IStakingProxyConvex public stakingVault;
    bytes32 public kekId;
    uint256 public lockingIntervalSec = 594000; // 6.875 * 86400 (~7 day)

    event SetRewardManager(address rewardManager);
    event SetStableConverter(address stableConverter);

    /**
     * @dev Throws if called by any account other than the Zunami
     */
    modifier onlyZunami() {
        require(_msgSender() == address(zunami), 'must be called by Zunami contract');
        _;
    }

    constructor(
        Config memory config_,
        address fraxUsdcPoolAddr,
        address fraxUsdcPoolLpAddr,
        address crvFraxTokenPoolAddr,
        address crvFraxTokenPoolLpAddr,
        uint256 poolPID
    ) {
        _config = config_;

        for (uint256 i; i < 3; i++) {
            decimalsMultipliers[i] = calcTokenDecimalsMultiplier(_config.tokens[i]);
        }

        cvxPoolPID = poolPID;
        feeDistributor = _msgSender();

        fraxUsdcPool = ICurvePool2(fraxUsdcPoolAddr);
        fraxUsdcPoolLp = IERC20Metadata(fraxUsdcPoolLpAddr);

        crvFraxTokenPool = ICurvePool2(crvFraxTokenPoolAddr);
        crvFraxTokenPoolLp = IERC20Metadata(crvFraxTokenPoolLpAddr);

        feeTokenId = ZUNAMI_USDC_TOKEN_ID;
    }

    function config() external view returns (Config memory) {
        return _config;
    }

    function token() external view returns (address) {
        return crvFraxTokenPool.coins(CRVFRAX_TOKEN_POOL_TOKEN_ID);
    }

    /**
     * @dev Returns deposited amount in USD.
     * If deposit failed return zero
     * @return Returns deposited amount in USD.
     * @param amounts - amounts in stablecoins that user deposit
     */
    function deposit(uint256[3] memory amounts) external returns (uint256) {
        if (!checkDepositSuccessful(amounts)) {
            return 0;
        }

        uint256 poolLPs = depositPool(amounts);

        return (poolLPs * getCurvePoolPrice()) / CURVE_PRICE_DENOMINATOR;
    }

    function transferAllTokensOut(address withdrawer, uint256[] memory prevBalances) internal {
        uint256 transferAmount;
        for (uint256 i = 0; i < 3; i++) {
            transferAmount =
                _config.tokens[i].balanceOf(address(this)) -
                prevBalances[i] -
                ((i == feeTokenId) ? managementFees : 0);
            if (transferAmount > 0) {
                _config.tokens[i].safeTransfer(withdrawer, transferAmount);
            }
        }
    }

    function transferZunamiAllTokens() internal {
        uint256 transferAmount;
        for (uint256 i = 0; i < 3; i++) {
            uint256 managementFee = (i == feeTokenId) ? managementFees : 0;
            transferAmount = _config.tokens[i].balanceOf(address(this)) - managementFee;
            if (transferAmount > 0) {
                _config.tokens[i].safeTransfer(_msgSender(), transferAmount);
            }
        }
    }

    /**
     * @dev Returns true if withdraw success and false if fail.
     * Withdraw failed when user removingCrvLps < requiredCrvLPs (wrong minAmounts)
     * @return Returns true if withdraw success and false if fail.
     * @param withdrawer - address of user that deposit funds
     * @param userRatioOfCrvLps - user's Ratio of ZLP for withdraw
     * @param tokenAmounts -  array of amounts stablecoins that user want minimum receive
     */
    function withdraw(
        address withdrawer,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256[3] memory tokenAmounts,
        WithdrawalType withdrawalType,
        uint128 tokenIndex
    ) external virtual onlyZunami returns (bool) {
        require(userRatioOfCrvLps > 0 && userRatioOfCrvLps <= 1e18, 'Wrong lp Ratio');
        (bool success, uint256 removingCrvLps, uint256[] memory tokenAmountsDynamic) = calcCrvLps(
            withdrawalType,
            userRatioOfCrvLps,
            tokenAmounts,
            tokenIndex
        );

        if (!success) {
            return false;
        }

        uint256[] memory prevBalances = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            prevBalances[i] =
                _config.tokens[i].balanceOf(address(this)) -
                ((i == feeTokenId) ? managementFees : 0);
        }

        // withdraw all crv lps
        releaseCurveLp();

        // stake back other curve lps
        stakeCurveLp(crvFraxTokenPoolLp.balanceOf(address(this)) - removingCrvLps);

        removeCrvLps(removingCrvLps, tokenAmountsDynamic, withdrawalType, tokenAmounts, tokenIndex);

        transferAllTokensOut(withdrawer, prevBalances);

        return true;
    }

    function calcTokenDecimalsMultiplier(IERC20Metadata token) internal view returns (uint256) {
        uint8 decimals = token.decimals();
        require(decimals <= 18, 'Zunami: wrong token decimals');
        if (decimals == 18) return 1;
        return 10**(18 - decimals);
    }

    /**
     * @dev anyone can sell rewards, func do nothing if config crv&cvx balance is zero
     */
    function sellRewards() internal virtual {
        uint256[] memory rewardBalances = new uint256[](_config.rewards.length);
        bool allRewardsEmpty = true;
        for (uint256 i = 0; i < _config.rewards.length; i++) {
            rewardBalances[i] = _config.rewards[i].balanceOf(address(this));
            if (rewardBalances[i] > 0) {
                allRewardsEmpty = false;
            }
        }
        if (allRewardsEmpty) {
            return;
        }

        uint256 feeTokenBalanceBefore = _config.tokens[feeTokenId].balanceOf(address(this));

        for (uint256 i = 0; i < _config.rewards.length; i++) {
            if (rewardBalances[i] == 0) continue;
            _config.rewards[i].transfer(address(address(rewardManager)), rewardBalances[i]);
            rewardManager.handle(
                address(_config.rewards[i]),
                rewardBalances[i],
                address(_config.tokens[feeTokenId])
            );
        }

        uint256 feeTokenBalanceAfter = _config.tokens[feeTokenId].balanceOf(address(this));

        managementFees += zunami.calcManagementFee(feeTokenBalanceAfter - feeTokenBalanceBefore);
    }

    function autoCompound() public onlyZunami {
        try stakingVault.getReward(true) {} catch {
            stakingVault.getReward(false);
        }

        sellRewards();

        uint256 feeTokenBalance = _config.tokens[feeTokenId].balanceOf(address(this)) -
            managementFees;

        uint256[3] memory amounts;
        amounts[feeTokenId] = feeTokenBalance;

        if (feeTokenBalance > 0) depositPool(amounts);
    }

    /**
     * @dev Returns total USD holdings in strategy.
     * return amount is lpBalance x lpPrice + cvx x cvxPrice + _config.crv * crvPrice.
     * @return Returns total USD holdings in strategy
     */
    function totalHoldings() public view virtual returns (uint256) {
        uint256 crvLpHoldings;
        uint256 rewardEarningInFeeToken;
        if (address(stakingVault) != address(0)) {
            crvLpHoldings =
                (stakingVault.stakingAddress().lockedLiquidityOf(address(stakingVault)) *
                    getCurvePoolPrice()) /
                CURVE_PRICE_DENOMINATOR;

            (address[] memory tokenAddresses, uint256[] memory totalEarned) = stakingVault.earned();

            for (uint256 i = 0; i < tokenAddresses.length; i++) {
                uint256 amountIn = totalEarned[i] +
                    IERC20Metadata(tokenAddresses[i]).balanceOf(address(this));
                if (amountIn == 0) continue;
                rewardEarningInFeeToken += rewardManager.valuate(
                    tokenAddresses[i],
                    amountIn,
                    address(_config.tokens[feeTokenId])
                );
            }
        }

        uint256 tokensHoldings = 0;
        for (uint256 i = 0; i < 3; i++) {
            tokensHoldings += _config.tokens[i].balanceOf(address(this)) * decimalsMultipliers[i];
        }

        return
            tokensHoldings +
            crvLpHoldings +
            rewardEarningInFeeToken *
            decimalsMultipliers[feeTokenId];
    }

    /**
     * @dev dev claim managementFees from strategy.
     * when tx completed managementFees = 0
     */
    function claimManagementFees() public returns (uint256) {
        uint256 feeTokenBalance = _config.tokens[feeTokenId].balanceOf(address(this));
        uint256 transferBalance = managementFees > feeTokenBalance
            ? feeTokenBalance
            : managementFees;
        if (transferBalance > 0) {
            _config.tokens[feeTokenId].safeTransfer(feeDistributor, transferBalance);
        }
        managementFees = 0;

        return transferBalance;
    }

    /**
     * @dev dev can update minDepositAmount but it can't be higher than 10000 (100%)
     * If user send deposit tx and get deposit amount lower than minDepositAmount than deposit tx failed
     * @param _minDepositAmount - amount which must be the minimum (%) after the deposit, min amount 1, max amount 10000
     */
    function updateMinDepositAmount(uint256 _minDepositAmount) public onlyOwner {
        require(_minDepositAmount > 0 && _minDepositAmount <= 10000, 'Wrong amount!');
        minDepositAmount = _minDepositAmount;
    }

    /**
     * @dev disable renounceOwnership for safety
     */
    function renounceOwnership() public view override onlyOwner {
        revert('The strategy must have an owner');
    }

    /**
     * @dev dev set Zunami (main contract) address
     * @param zunamiAddr - address of main contract (Zunami)
     */
    function setZunami(address zunamiAddr) external onlyOwner {
        zunami = IZunami(zunamiAddr);
    }

    function setRewardManager(address rewardManagerAddr) external onlyOwner {
        rewardManager = IRewardManager(rewardManagerAddr);
        emit SetRewardManager(rewardManagerAddr);
    }

    function setStableConverter(address stableConverterAddr) external onlyOwner {
        stableConverter = IStableConverter(stableConverterAddr);
        emit SetStableConverter(stableConverterAddr);
    }

    function setFeeTokenId(uint256 feeTokenIdParam) external onlyOwner {
        feeTokenId = feeTokenIdParam;
    }

    /**
     * @dev governance can withdraw all stuck funds in emergency case
     * @param _token - IERC20Metadata token that should be fully withdraw from Strategy
     */
    function withdrawStuckToken(IERC20Metadata _token) external onlyOwner {
        uint256 tokenBalance = _token.balanceOf(address(this));
        if (tokenBalance > 0) {
            _token.safeTransfer(_msgSender(), tokenBalance);
        }
    }

    /**
     * @dev governance can set feeDistributor address for distribute protocol fees
     * @param _feeDistributor - address feeDistributor that be used for claim fees
     */
    function changeFeeDistributor(address _feeDistributor) external onlyOwner {
        feeDistributor = _feeDistributor;
    }

    function lockLonger() external onlyOwner {
        stakingVault.lockLonger(kekId, block.timestamp + lockingIntervalSec);
    }

    /**
     * @dev can be called by Zunami contract.
     * This function need for moveFunds between strategies.
     */
    function withdrawAll() external virtual onlyZunami {
        releaseCurveLp();

        sellRewards();

        withdrawAllSpecific();

        transferZunamiAllTokens();
    }

    function checkDepositSuccessful(uint256[3] memory tokenAmounts)
        internal
        view
        returns (bool isValidDepositAmount)
    {
        uint256 amountsTotal;
        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            amountsTotal += tokenAmounts[i] * decimalsMultipliers[i];
        }

        uint256 amountsMin = (amountsTotal * minDepositAmount) / DEPOSIT_DENOMINATOR;

        uint256[2] memory amounts;
        amounts[FRAX_USDC_POOL_USDC_ID] = amountsTotal / 1e12;

        uint256 lpPrice = fraxUsdcPool.get_virtual_price();
        uint256 depositedLp = fraxUsdcPool.calc_token_amount(amounts, true);

        isValidDepositAmount = (depositedLp * lpPrice) / CURVE_PRICE_DENOMINATOR >= amountsMin;
    }

    function depositPool(uint256[3] memory tokenAmounts)
        internal
        returns (uint256 crvFraxTokenLpAmount)
    {
        uint256 usdcBalanceBefore = _config.tokens[ZUNAMI_USDC_TOKEN_ID].balanceOf(address(this));
        if (tokenAmounts[ZUNAMI_DAI_TOKEN_ID] > 0) {
            swapTokenToUSDC(IERC20Metadata(Constants.DAI_ADDRESS));
        }

        if (tokenAmounts[ZUNAMI_USDT_TOKEN_ID] > 0) {
            swapTokenToUSDC(IERC20Metadata(Constants.USDT_ADDRESS));
        }

        uint256 usdcAmount = _config.tokens[ZUNAMI_USDC_TOKEN_ID].balanceOf(address(this)) -
            usdcBalanceBefore +
            tokenAmounts[ZUNAMI_USDC_TOKEN_ID];

        uint256[2] memory amounts;
        amounts[FRAX_USDC_POOL_USDC_ID] = usdcAmount;
        _config.tokens[ZUNAMI_USDC_TOKEN_ID].safeIncreaseAllowance(
            address(fraxUsdcPool),
            usdcAmount
        );
        uint256 crvFraxAmount = fraxUsdcPool.add_liquidity(amounts, 0);

        fraxUsdcPoolLp.safeIncreaseAllowance(address(crvFraxTokenPool), crvFraxAmount);
        amounts[CRVFRAX_TOKEN_POOL_CRVFRAX_ID] = crvFraxAmount;
        crvFraxTokenLpAmount = crvFraxTokenPool.add_liquidity(amounts, 0);

        stakeCurveLp(crvFraxTokenLpAmount);
    }

    function stakeCurveLp(uint256 curveLpAmount) internal {
        if (address(stakingVault) == address(0)) {
            stakingVault = IStakingProxyConvex(_config.booster.createVault(cvxPoolPID));
        }

        crvFraxTokenPoolLp.safeIncreaseAllowance(address(stakingVault), curveLpAmount);
        if (kekId == 0) {
            kekId = stakingVault.stakeLockedCurveLp(curveLpAmount, lockingIntervalSec);
        } else {
            stakingVault.lockAdditionalCurveLp(kekId, curveLpAmount);
        }
    }

    function releaseCurveLp() internal {
        stakingVault.withdrawLockedAndUnwrap(kekId);
        kekId = 0;
    }

    function getCurvePoolPrice() internal view returns (uint256) {
        return crvFraxTokenPool.get_virtual_price();
    }

    function calcWithdrawOneCoin(uint256 userRatioOfCrvLps, uint128 tokenIndex)
        external
        view
        returns (uint256)
    {
        uint256 removingCrvLps = (stakingVault.stakingAddress().lockedLiquidityOf(
            address(stakingVault)
        ) * userRatioOfCrvLps) / 1e18;

        uint256 crvFraxAmount = crvFraxTokenPool.calc_withdraw_one_coin(
            removingCrvLps,
            CRVFRAX_TOKEN_POOL_CRVFRAX_ID_INT
        );

        uint256 usdcAmount = fraxUsdcPool.calc_withdraw_one_coin(
            crvFraxAmount,
            FRAX_USDC_POOL_USDC_ID_INT
        );

        if (tokenIndex == ZUNAMI_USDC_TOKEN_ID) return usdcAmount;
        return
            stableConverter.valuate(
                address(_config.tokens[ZUNAMI_USDC_TOKEN_ID]),
                address(_config.tokens[tokenIndex]),
                usdcAmount
            );
    }

    function calcSharesAmount(uint256[3] memory tokenAmounts, bool isDeposit)
        external
        view
        returns (uint256)
    {
        uint256[2] memory amounts = convertZunamiTokensToFraxUsdcs(tokenAmounts, isDeposit);
        return crvFraxTokenPool.calc_token_amount(amounts, isDeposit);
    }

    function convertZunamiTokensToFraxUsdcs(uint256[3] memory tokenAmounts, bool isDeposit)
        internal
        view
        returns (uint256[2] memory amounts)
    {
        amounts[FRAX_USDC_POOL_USDC_ID] =
            tokenAmounts[0] /
            1e12 +
            tokenAmounts[1] +
            tokenAmounts[2];
        amounts[CRVFRAX_TOKEN_POOL_CRVFRAX_ID] = fraxUsdcPool.calc_token_amount(amounts, isDeposit);
    }

    function calcCrvLps(
        WithdrawalType,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256[3] memory tokenAmounts,
        uint128
    )
        internal
        view
        returns (
            bool success,
            uint256 removingCrvLps,
            uint256[] memory tokenAmountsDynamic
        )
    {
        removingCrvLps =
            (stakingVault.stakingAddress().lockedLiquidityOf(address(stakingVault)) *
                userRatioOfCrvLps) /
            1e18;

        uint256[2] memory minAmounts = convertZunamiTokensToFraxUsdcs(tokenAmounts, false);
        success = removingCrvLps >= crvFraxTokenPool.calc_token_amount(minAmounts, false);

        tokenAmountsDynamic = new uint256[](2);
    }

    function removeCrvLps(
        uint256 removingCrvLps,
        uint256[] memory,
        WithdrawalType withdrawalType,
        uint256[3] memory tokenAmounts,
        uint128 tokenIndex
    ) internal {
        removeCrvLpsInternal(removingCrvLps, tokenAmounts[ZUNAMI_USDC_TOKEN_ID]);

        if (withdrawalType == WithdrawalType.OneCoin && tokenIndex != ZUNAMI_USDC_TOKEN_ID) {
            swapUSDCToToken(_config.tokens[tokenIndex]);
        }
    }

    function removeCrvLpsInternal(uint256 removingCrvLps, uint256 minUsdcAmount) internal {
        uint256 crvFraxAmount = crvFraxTokenPool.remove_liquidity_one_coin(
            removingCrvLps,
            CRVFRAX_TOKEN_POOL_CRVFRAX_ID_INT,
            0
        );

        fraxUsdcPool.remove_liquidity_one_coin(
            crvFraxAmount,
            FRAX_USDC_POOL_USDC_ID_INT,
            minUsdcAmount
        );
    }

    function withdrawAllSpecific() internal {
        removeCrvLpsInternal(crvFraxTokenPoolLp.balanceOf(address(this)), 0);
    }

    function swapTokenToUSDC(IERC20Metadata token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;

        token.safeTransfer(address(address(stableConverter)), balance);
        stableConverter.handle(
            address(token),
            address(_config.tokens[ZUNAMI_USDC_TOKEN_ID]),
            balance,
            0
        );
    }

    function swapUSDCToToken(IERC20Metadata token) internal {
        uint256 balance = _config.tokens[ZUNAMI_USDC_TOKEN_ID].balanceOf(address(this));
        if (balance == 0) return;

        _config.tokens[ZUNAMI_USDC_TOKEN_ID].safeTransfer(
            address(address(stableConverter)),
            balance
        );
        stableConverter.handle(
            address(_config.tokens[ZUNAMI_USDC_TOKEN_ID]),
            address(token),
            balance,
            0
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZunami {
    function totalDeposited() external returns (uint256);

    function deposited(address account) external returns (uint256);

    function totalHoldings() external returns (uint256);

    function calcManagementFee(uint256 amount) external returns (uint256);

    function delegateDeposit(uint256[3] memory amounts) external;

    function delegateWithdrawal(uint256 lpShares, uint256[3] memory tokenAmounts) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardManager {
    function handle(
        address reward,
        uint256 amount,
        address feeToken
    ) external;

    function valuate(
        address reward,
        uint256 amount,
        address feeToken
    ) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStableConverter {
    function handle(
        address from,
        address to,
        uint256 amount,
        uint256 slippage
    ) external;

    function valuate(
        address from,
        address to,
        uint256 amount
    ) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../../interfaces/ICurvePoolPricable.sol';

interface ICurvePool2 is ICurvePoolPricable {
    function coins(uint256 i) external view returns (address);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity(uint256 burn_amount, uint256[2] memory min_amounts)
        external
        returns (uint256[2] memory);

    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 max_burn_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 burn_amount,
        int128 i,
        uint256 min_received
    ) external returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 input,
        uint256 min_output
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 input,
        uint256 min_output
    ) external;

    function calc_token_amount(uint256[2] memory amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(
        uint256[2] memory amounts,
        bool is_deposit,
        bool previous
    ) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 burn_amount, int128 i) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IFraxFarmERC20.sol';

interface IStakingProxyConvex {
    function stakingAddress() external view returns (IFraxFarmERC20);

    function stakeLockedCurveLp(uint256 _liquidity, uint256 _secs)
        external
        returns (bytes32 kek_id);

    function lockAdditionalCurveLp(bytes32 _kek_id, uint256 _addl_liq) external;

    function lockLonger(bytes32 _kek_id, uint256 new_ending_ts) external;

    function withdrawLockedAndUnwrap(bytes32 _kek_id) external;

    function earned()
        external
        view
        returns (address[] memory token_addresses, uint256[] memory total_earned);

    function getReward(bool _claim) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IConvexStakingBooster {
    function createVault(uint256 _pid) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurvePoolPricable {
    function get_virtual_price() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFraxFarmERC20 {
    function lockedLiquidityOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}