// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployDecentralizedStableCoin} from "script/DeployDecentralizedStableCoin.s.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";

contract TestDeployDecentralizedStableCoin is Test {
    DeployDecentralizedStableCoin deployer =
        new DeployDecentralizedStableCoin();
    DecentralizedStableCoin dsc;

    function testDeployerShouldBeOwner() public {
        dsc = deployer.run();
        assertEq(dsc.getOwner(), address(this));
    }
}
