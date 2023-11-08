// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;
    uint256 deployerKey;
    address initialOwner;
    uint256 public constant DEFAULT_ANVIL_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    address public constant ANVIL_INITIAL_OWNER =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        HelperConfig config = new HelperConfig();
        (
            wethUsdPriceFeed,
            wbtcUsdPriceFeed,
            weth,
            wbtc,
            deployerKey,
            initialOwner
        ) = config.activeNetworkConfig();
        console.log("config = ", address(config));
    }

    function testInitialOwnerIsCorrect() public {
        console.log("initialOwner = ", initialOwner);
        console.log("ANVIL_INITIAL_OWNER = ", ANVIL_INITIAL_OWNER);
        assertEq(initialOwner, ANVIL_INITIAL_OWNER);
    }

    function testWethUsdPriceFeedIsNotZero() public view {
        console.log("wethUsdPriceFeed = ", wethUsdPriceFeed);
        assert(wethUsdPriceFeed != address(0));
    }

    function testBtcUsdPriceFeedIsNotZero() public view {
        console.log("wbtcUsdPriceFeed = ", wbtcUsdPriceFeed);
        assert(wbtcUsdPriceFeed != address(0));
    }

    function wethIsNotZero() public view {
        console.log("weth = ", weth);
        assert(weth != address(0));
    }

    function wbtcIsNotZero() public view {
        console.log("wbtc = ", wbtc);
        assert(wbtc != address(0));
    }

    function deployerKeyIsCorrect() public {
        console.log("deployerKey = ", deployerKey);
        assertEq(deployerKey, DEFAULT_ANVIL_KEY);
    }
}
