// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {ReentrancyEther} from "src/ReentrancyEther.sol";

contract DeployReentrancyEther is Script {
    ReentrancyEther reentrancyEther;

    function run() external returns (ReentrancyEther) {
        vm.startBroadcast();
        reentrancyEther = new ReentrancyEther();
        vm.stopBroadcast();

        return reentrancyEther;
    }
}
