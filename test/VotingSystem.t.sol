//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {VotingSystem} from "src/VotingSystem.sol";
import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";

contract VotingTest is Test{
    VotingSystem public votingSystem;
    function setUp() public{
        votingSystem = new VotingSystem();
    }

    function testVoter() public{
        address voter = makeAddr("voter");
        for (uint256 i = 0; i < 10; i++) {
            vm.startPrank(voter);
            uint256 totaltokens = votingSystem.registerVoter(voter);
            vm.stopPrank();
            console2.log(totaltokens);
                    uint256 votercount = votingSystem.voterCount();
        console2.log(votercount);
        }
        // uint256 totaltokens = votingSystem.registerVoter(voter);
        // assert(totaltokens == 1000e18);
        // console2.log(totaltokens);
        

        

    
    }
}