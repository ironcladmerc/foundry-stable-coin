// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployDecentralizedStableCoin} from "script/DeployDecentralizedStableCoin.s.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";

contract TestDecentralizedStableCoin is Test {
    DeployDecentralizedStableCoin deployer =
        new DeployDecentralizedStableCoin();
    DecentralizedStableCoin dsc;
    address public USER = makeAddr("user");

    function setUp() public {
        dsc = deployer.run();
    }

    function testMintBalanceIsCorrect() public {
        dsc.mint(address(this), 100);
        assertEq(dsc.balanceOf(address(this)), 100);
    }

    function testMintToAddressZeroShouldRevert() public {
        vm.expectRevert();
        dsc.mint(address(0), 100);
    }

    function testMintingZeroCoinsShouldRevert() public {
        vm.expectRevert();
        dsc.mint(address(this), 0);
    }

    function testNonOwnerShouldNotBeAbleToMint() public {
        vm.prank(USER);
        vm.expectRevert();
        dsc.mint(USER, 100);
    }

    function testMintToUserBalanceIsCorrect() public {
        dsc.mint(USER, 100);
        assertEq(dsc.balanceOf(USER), 100);
    }

    function testOwnerIsCorrect() public {
        assertEq(dsc.getOwner(), address(this));
    }

    function testBurnBalanceIsCorrect() public {
        dsc.mint(address(this), 100);
        dsc.burn(100);
        assertEq(dsc.balanceOf(address(this)), 0);
    }

    function testPartialBurnBalanceIsCorrect() public {
        dsc.mint(address(this), 100);
        dsc.burn(50);
        assertEq(dsc.balanceOf(address(this)), 50);
    }

    function testNonOwnerShouldNotBeAbleToBurn() public {
        dsc.mint(USER, 100);
        vm.prank(USER);
        vm.expectRevert();
        dsc.burn(100);
    }

    function testCannotBurnMoreThanBalance() public {
        dsc.mint(address(this), 100);
        vm.expectRevert();
        dsc.burn(101);
    }

    function testCannotBurnZero() public {
        dsc.mint(address(this), 100);
        vm.expectRevert();
        dsc.burn(0);
    }
}
