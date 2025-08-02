//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {VotingSystem} from "src/VotingSystem.sol";
import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";

contract VotingTest is Test {
    VotingSystem public votingSystem;
    uint256 constant INITIAL_SUPPLY = 1000e18;
    
    address voter1;
    address voter2;
    address voter3;
    address nonVoter;

    function setUp() public {
        votingSystem = new VotingSystem(INITIAL_SUPPLY);
        
        // Create test addresses
        voter1 = makeAddr("voter1");
        voter2 = makeAddr("voter2");
        voter3 = makeAddr("voter3");
        nonVoter = makeAddr("nonVoter");
    }

    // Test initial contract state
    function testInitialState() public {
        assertEq(votingSystem.voterCount(), 0);
        assertEq(votingSystem.checkBalanceofThisContract(), INITIAL_SUPPLY);
        assertEq(votingSystem.hasTransfered(), false);
        assertEq(votingSystem.owner(), address(this));
    }

    // Test registering first voter
    function testRegisterFirstVoter() public {
        vm.startPrank(voter1);
        uint256 tokensReceived = votingSystem.registerVoter(voter1);
        vm.stopPrank();

        assertEq(tokensReceived, INITIAL_SUPPLY);
        assertEq(votingSystem.voterCount(), 1);
        assertEq(votingSystem.votersToTokenCount(voter1), INITIAL_SUPPLY);
        assertEq(votingSystem.hasTransfered(), true);
        assertEq(votingSystem.checkBalanceofThisContract(), 0);
    }

    // Test registering multiple voters with token redistribution
    function testRegisterMultipleVoters() public {
        // Register first voter
        vm.startPrank(voter1);
        uint256 tokens1 = votingSystem.registerVoter(voter1);
        vm.stopPrank();
        
        console2.log("First voter tokens:", tokens1);
        assertEq(tokens1, INITIAL_SUPPLY);

        // Register second voter - should redistribute tokens equally
        vm.startPrank(voter2);
        uint256 tokens2 = votingSystem.registerVoter(voter2);
        vm.stopPrank();
        
        console2.log("Second voter tokens:", tokens2);
        console2.log("First voter tokens after redistribution:", votingSystem.votersToTokenCount(voter1));
        
        // Each voter should have INITIAL_SUPPLY/2 tokens
        uint256 expectedTokensPerVoter = INITIAL_SUPPLY / 2;
        console2.log("voter 1:",votingSystem.votersToTokenCount(voter1));
        console2.log("voter 2:",votingSystem.votersToTokenCount(voter2));
        // assertEq(votingSystem.votersToTokenCount(voter1), expectedTokensPerVoter);
        // assertEq(votingSystem.votersToTokenCount(voter2), expectedTokensPerVoter);
        // assertEq(votingSystem.voterCount(), 2);

        // Register third voter
        vm.startPrank(voter3);
        uint256 tokens3 = votingSystem.registerVoter(voter3);
        vm.stopPrank();
        
        console2.log("Third voter tokens:", tokens3);
        
        // Each voter should have INITIAL_SUPPLY/3 tokens
        expectedTokensPerVoter = INITIAL_SUPPLY / 3;
        console2.log(votingSystem.votersToTokenCount(voter1));
        console2.log(votingSystem.votersToTokenCount(voter2));
        console2.log(votingSystem.votersToTokenCount(voter3));
        // assertEq(votingSystem.votersToTokenCount(voter1), expectedTokensPerVoter);
        // assertEq(votingSystem.votersToTokenCount(voter2), expectedTokensPerVoter);
        // assertEq(votingSystem.votersToTokenCount(voter3), expectedTokensPerVoter);
        // assertEq(votingSystem.voterCount(), 3);
    }

    // Test preventing duplicate voter registration
    function testPreventDuplicateRegistration() public {
        vm.startPrank(voter1);
        votingSystem.registerVoter(voter1);
        
        // Try to register the same voter again
        vm.expectRevert("Voter already registered");
        votingSystem.registerVoter(voter1);
        vm.stopPrank();
    }

    // Test registering voter with zero address
    function testRejectZeroAddress() public {
        vm.expectRevert("Invalid voter address");
        votingSystem.registerVoter(address(0));
    }

    // Test hosting voting options
    function testHostVoting() public {
        string memory option1 = "Option A";
        string memory option2 = "Option B";
        uint256 duration = 7; // 7 days

        votingSystem.hostVoting(option1, duration);
        votingSystem.hostVoting(option2, duration);

        string[] memory options = votingSystem.getVotingOptions();
        assertEq(options.length, 2);
        assertEq(options[0], option1);
        assertEq(options[1], option2);

        // Check that voting options have correct timestamps
        uint256 expectedEndTime = block.timestamp + (duration * 1 days);
        assertEq(votingSystem.votingOptions(option1), expectedEndTime);
        assertEq(votingSystem.votingOptions(option2), expectedEndTime);
    }

    // Test complete voting workflow
    function testCompleteVotingWorkflow() public {
        // Setup: Register voters
        vm.prank(voter1);
        votingSystem.registerVoter(voter1);
        
        vm.prank(voter2);
        votingSystem.registerVoter(voter2);

        // Setup: Host voting options
        string memory optionA = "Option A";
        string memory optionB = "Option B";
        votingSystem.hostVoting(optionA, 7);
        votingSystem.hostVoting(optionB, 7);

        // Vote
        uint256 voteAmount1 = 100e18;
        uint256 voteAmount2 = 200e18;

        vm.prank(voter1);
        votingSystem.giveVotes(voter1, voteAmount1, optionA);

        vm.prank(voter2);
        votingSystem.giveVotes(voter2, voteAmount2, optionB);

        // Check vote counts
        assertEq(votingSystem.optionVotes(optionA), voteAmount1);
        assertEq(votingSystem.optionVotes(optionB), voteAmount2);

        // Check updated voter token balances
        uint256 expectedBalance1 = (INITIAL_SUPPLY / 2) - voteAmount1;
        uint256 expectedBalance2 = (INITIAL_SUPPLY / 2) - voteAmount2;
        assertEq(votingSystem.votersToTokenCount(voter1), expectedBalance1);
        assertEq(votingSystem.votersToTokenCount(voter2), expectedBalance2);

        // Check winner
        string[] memory options = new string[](2);
        options[0] = optionA;
        options[1] = optionB;
        
        (string memory winner, uint256 winningVotes) = votingSystem.checkWinner(options);
        assertEq(winner, optionB);
        assertEq(winningVotes, voteAmount2);
    }

    // Test voting with insufficient tokens
    function testVoteWithInsufficientTokens() public {
        vm.prank(voter1);
        votingSystem.registerVoter(voter1);

        votingSystem.hostVoting("Option A", 7);

        uint256 voterBalance = votingSystem.votersToTokenCount(voter1);
        
        vm.prank(voter1);
        vm.expectRevert("Insufficient tokens");
        votingSystem.giveVotes(voter1, voterBalance + 1, "Option A");
    }

    // Test voting by unregistered voter
    function testVoteByUnregisteredVoter() public {
        votingSystem.hostVoting("Option A", 7);
        
        vm.prank(nonVoter);
        vm.expectRevert("Voter not registered");
        votingSystem.giveVotes(nonVoter, 100e18, "Option A");
    }

    // Test voting with zero amount
    function testVoteWithZeroAmount() public {
        vm.prank(voter1);
        votingSystem.registerVoter(voter1);

        votingSystem.hostVoting("Option A", 7);
        
        vm.prank(voter1);
        vm.expectRevert("Amount must be greater than zero");
        votingSystem.giveVotes(voter1, 0, "Option A");
    }

    // Test voting after deadline
    function testVoteAfterDeadline() public {
        vm.prank(voter1);
        votingSystem.registerVoter(voter1);

        votingSystem.hostVoting("Option A", 7);
        
        // Fast forward past the voting deadline
        vm.warp(block.timestamp + 8 days);
        
        vm.prank(voter1);
        vm.expectRevert("Voting period has ended");
        votingSystem.giveVotes(voter1, 100e18, "Option A");
    }

    // Test winner determination with no votes
    function testWinnerWithNoVotes() public {
        votingSystem.hostVoting("Option A", 7);
        votingSystem.hostVoting("Option B", 7);

        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";
        
        (string memory winner, uint256 winningVotes) = votingSystem.checkWinner(options);
        assertEq(winner, "Option A"); // First option wins in case of tie (0 votes each)
        assertEq(winningVotes, 0);
    }

    // Test winner determination with tie
    function testWinnerWithTie() public {
        vm.prank(voter1);
        votingSystem.registerVoter(voter1);
        
        vm.prank(voter2);
        votingSystem.registerVoter(voter2);

        votingSystem.hostVoting("Option A", 7);
        votingSystem.hostVoting("Option B", 7);

        uint256 voteAmount = 100e18;
        
        vm.prank(voter1);
        votingSystem.giveVotes(voter1, voteAmount, "Option A");
        
        vm.prank(voter2);
        votingSystem.giveVotes(voter2, voteAmount, "Option B");

        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";
        
        (string memory winner, uint256 winningVotes) = votingSystem.checkWinner(options);
        assertEq(winner, "Option A"); // First option wins in case of tie
        assertEq(winningVotes, voteAmount);
    }

    // Test empty options array
    function testWinnerWithEmptyOptions() public {
        string[] memory options = new string[](0);
        
        vm.expectRevert("No options provided");
        votingSystem.checkWinner(options);
    }

    // Test gas efficiency for multiple voter registration
    function testGasEfficiencyMultipleVoters() public {
        address[] memory voters = new address[](10);
        
        // Create 10 voters
        for (uint256 i = 0; i < 10; i++) {
            voters[i] = makeAddr(string(abi.encodePacked("voter", i)));
        }

        // Register all voters and measure gas
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(voters[i]);
            uint256 gasBefore = gasleft();
            votingSystem.registerVoter(voters[i]);
            uint256 gasUsed = gasBefore - gasleft();
            console2.log("Gas used for voter", i, ":", gasUsed);
        }

        // Verify all voters have equal token distribution
        uint256 expectedTokensPerVoter = INITIAL_SUPPLY / 10;
        for (uint256 i = 0; i < 10; i++) {
            assertEq(votingSystem.votersToTokenCount(voters[i]), expectedTokensPerVoter);
        }
    }

    // Test edge case: single voter voting scenario
    function testSingleVoterVoting() public {
        vm.prank(voter1);
        votingSystem.registerVoter(voter1);

        votingSystem.hostVoting("Only Option", 7);

        uint256 voteAmount = 500e18;
        vm.prank(voter1);
        votingSystem.giveVotes(voter1, voteAmount, "Only Option");

        assertEq(votingSystem.optionVotes("Only Option"), voteAmount);
        assertEq(votingSystem.votersToTokenCount(voter1), INITIAL_SUPPLY - voteAmount);

        string[] memory options = new string[](1);
        options[0] = "Only Option";
        
        (string memory winner, uint256 winningVotes) = votingSystem.checkWinner(options);
        assertEq(winner, "Only Option");
        assertEq(winningVotes, voteAmount);
    }
}