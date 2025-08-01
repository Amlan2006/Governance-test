//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {VotingSystem} from "src/VotingSystem.sol";
import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";

contract VotingTest is Test{
    VotingSystem public votingSystem;
    function setUp() public{
        votingSystem = new VotingSystem(1000e18);
    }

    function testVoter() public{
        // uint256 initialBalance = votingSystem.checkBalanceofThisContract();
        // console2.log(initialBalance);
        address voter = makeAddr("voter");
            vm.startPrank(voter);
            uint256 totaltokens = votingSystem.registerVoter(voter);
            vm.stopPrank();
            console2.log(totaltokens);
                    uint256 votercount = votingSystem.voterCount();
        console2.log(votercount);
        address voter1 = makeAddr("voter1");
            vm.startPrank(voter1);
            uint256 totaltokens1 = votingSystem.registerVoter(voter1);
            vm.stopPrank();
            console2.log(totaltokens1);
                    uint256 votercount1 = votingSystem.voterCount();
        console2.log(votercount1);
        address voter2 = makeAddr("voter2");
            vm.startPrank(voter2);
            uint256 totaltokens2 = votingSystem.registerVoter(voter2);
            vm.stopPrank();
            console2.log(totaltokens2);
                    uint256 votercount2 = votingSystem.voterCount();
        console2.log(votercount2);
        
        // uint256 totaltokens = votingSystem.registerVoter(voter);
        // assert(totaltokens == 1000e18);
        // console2.log(totaltokens);
        

        

    
    }
}