//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {VotingSystem} from "../src/VotingSystem.sol";

contract DeployVotingSystem is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        VotingSystem votingSystem = new VotingSystem(1000e18);
        vm.stopBroadcast();
    }
}