// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;

    address public USER = makeAddr("USER");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant MINT_AMOUNT_MIN = 1 ether;
    uint256 public constant MINT_AMOUNT_MAX = 5 ether;
    uint256 public constant MINT_AMOUNT_OVER = 10 ether;
    uint256 public constant MIN_HEALTH_FACTOR = 1;

    function setUp() public {
        console.log("Test msg.sender = ", msg.sender);
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (ethUsdPriceFeed, , weth, , , ) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    //////////////////////////
    // Constructor tests   //
    ////////////////////////

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);
        vm.expectRevert(
            DSCEngine
                .DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength
                .selector
        );
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    //////////////////////////////
    // Deposit Collateral tests //
    /////////////////////////////
    function testRevertIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock();
        ranToken.mint(USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__TokenNotSupported.selector);
        engine.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    modifier mintedDsc() {
        vm.startPrank(USER);
        engine.mintDsc(MINT_AMOUNT_MIN);
        vm.stopPrank();
        _;
    }

    modifier depositedCollateralAndMintedDsc() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintDSC(
            weth,
            AMOUNT_COLLATERAL,
            MINT_AMOUNT_MIN
        );
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndMintDsc()
        public
        depositedCollateralAndMintedDsc
    {
        uint256 expectedTotalDscMinted = MINT_AMOUNT_MIN;
        (uint256 totalDscMinted, uint256 totalCollateralValueInUsd) = engine
            .getAccountInformation(USER);
        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(
            totalCollateralValueInUsd,
            engine.getUsdValue(weth, AMOUNT_COLLATERAL)
        );
    }

    function testCanDepositCollateralAndGetAccountInfo()
        public
        depositedCollateral
    {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine
            .getAccountInformation(USER);
        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = engine.getTokenAmountFromUsd(
            weth,
            collateralValueInUsd
        );
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
        assertEq(totalDscMinted, expectedTotalDscMinted);
    }

    function testCanMintDsc() public depositedCollateral {
        vm.startPrank(USER);
        engine.mintDsc(MINT_AMOUNT_MIN);
        vm.stopPrank();
        uint256 expectedTotalDscMinted = MINT_AMOUNT_MIN;
        (uint256 totalDscMinted, ) = engine.getAccountInformation(USER);
        assertEq(totalDscMinted, expectedTotalDscMinted);
    }

    function testCanBurnDsc() public depositedCollateral mintedDsc {
        vm.startPrank(USER);
        dsc.approve(address(engine), MINT_AMOUNT_MIN);
        engine.burnDsc(MINT_AMOUNT_MIN);
        vm.stopPrank();
        uint256 expectedTotalDscMinted = 0;
        (uint256 totalDscMinted, ) = engine.getAccountInformation(USER);
        assertEq(totalDscMinted, expectedTotalDscMinted);
    }

    function testCanRedeemCollateral() public depositedCollateral {
        vm.startPrank(USER);
        engine.redeemCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        uint256 expectedTotalDscMinted = 0;
        (uint256 totalDscMinted, ) = engine.getAccountInformation(USER);
        assertEq(totalDscMinted, expectedTotalDscMinted);
    }

    function testCanRedeemCollateralForDsc()
        public
        depositedCollateralAndMintedDsc
    {
        vm.startPrank(USER);
        dsc.approve(address(engine), MINT_AMOUNT_MIN);
        engine.redeemCollateralForDsc(weth, AMOUNT_COLLATERAL, MINT_AMOUNT_MIN);
        vm.stopPrank();
        uint256 expectedTotalDscMinted = 0;
        (uint256 totalDscMinted, ) = engine.getAccountInformation(USER);
        assertEq(totalDscMinted, expectedTotalDscMinted);
    }

    function testCannotRedeemCollateralIfHealthFactorIsBroken()
        public
        depositedCollateral
        mintedDsc
    {
        vm.startPrank(USER);
        vm.expectRevert(
            abi.encodeWithSelector(
                DSCEngine.DSCEngine__BreaksHealthFactor.selector,
                0
            )
        );
        engine.redeemCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testHealthFactorIsCorrect() public depositedCollateral {
        vm.startPrank(USER);
        engine.mintDsc(1 ether);
        uint256 expectedHealthFactor = 1e15;
        uint256 actualHealthFactor = engine.getHealthFactor(USER);
        assertEq(expectedHealthFactor, actualHealthFactor);
    }

    function testGetHealthFactorWithNoMintedDsc() public depositedCollateral {
        uint256 expectedHealthFactor = 1e18;
        uint256 actualHealthFactor = engine.getHealthFactor(USER);
        assertEq(expectedHealthFactor, actualHealthFactor);
    }

    //////////////////////////
    // Liquidate tests     //
    ////////////////////////

    function testLiquidateRevertsIfHealthFactorOk()
        public
        depositedCollateralAndMintedDsc
    {
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorOk.selector);
        engine.liquidate(address(dsc), USER, 1 ether);
    }

    function testLiquidateRevertsIfZeroAmount()
        public
        depositedCollateralAndMintedDsc
    {
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        engine.liquidate(address(dsc), USER, 0);
    }

    // function testHealthFactorIsBad() public depositedCollateral {
    //     vm.startPrank(USER);
    //     engine.mintDsc(MINT_AMOUNT_OVER);
    //     vm.stopPrank();
    //     uint256 userHealthFactor = engine.getHealthFactor(USER);
    //     (uint256 totalDscMinted, uint256 totalCollaterValueInUsd) = engine
    //         .getAccountInformation(USER);
    //     console.log("DSC Minted: ", totalDscMinted);
    //     console.log("Total Collateral value: ", totalCollaterValueInUsd);
    //     console.log("user health factor: ", userHealthFactor);
    //     console.log("Min Health Factor: ", MIN_HEALTH_FACTOR);
    //     assert(userHealthFactor < MIN_HEALTH_FACTOR);
    // }

    //////////////////////////
    // Price tests         //
    ////////////////////////

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;

        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = engine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = engine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWeth, actualWeth);
    }

    function testGetAccountCollateralValue() public depositedCollateral {
        uint256 totalCollateralValueInUsd = engine.getAccountCollateralValue(
            USER
        );

        console.log("totalCollateralValueInUsd = ", totalCollateralValueInUsd);

        uint256 expectedCollateralValueInUsd = engine.getUsdValue(
            weth,
            AMOUNT_COLLATERAL
        );

        console.log(
            "expectedCollateralValueInUsd = ",
            expectedCollateralValueInUsd
        );

        assertEq(
            totalCollateralValueInUsd,
            expectedCollateralValueInUsd,
            "Collateral value in USD should be equal to the amount of collateral deposited"
        );
    }
}
