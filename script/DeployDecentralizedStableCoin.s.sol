// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";

contract DeployDecentralizedStableCoin is Script {
    DecentralizedStableCoin dsc;

    function run() public returns (DecentralizedStableCoin) {
        vm.startBroadcast();
        dsc = new DecentralizedStableCoin(msg.sender);
        vm.stopBroadcast();
        return dsc;
    }
}
