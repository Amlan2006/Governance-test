//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VotingSystem is ERC20 {
    address public immutable owner;
    mapping(address voters => uint256 tokenCount) public votersToTokenCount;
    uint256 public voterCount = 0;
    string[] public options;
    bool public hasTransfered = false;
    mapping(address voter => mapping(uint256 votes => string optionName))
        public voterVotes;
    mapping(string optionName => uint256 duration) public votingOptions;
    mapping(string optionName => uint256 votes) public optionVotes;
    address[] public voters;

    constructor(uint256 INITIAL_SUPPLY) ERC20("VotingToken", "VT") {
        owner = msg.sender; // Fixed: was msg.sender == owner
        _mint(address(this), INITIAL_SUPPLY);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Register a voter and assign them tokens
    function registerVoter(address voter) public returns (uint256) {
        require(voter != address(0), "Invalid voter address");
        require(votersToTokenCount[voter] == 0, "Voter already registered");
        
        if (voterCount == 0) {
            // First voter gets all tokens from contract
            uint256 contractBalance = balanceOf(address(this));
            votersToTokenCount[voter] = contractBalance;
            _transfer(address(this), voter, contractBalance);
            voterCount++;
            voters.push(voter);
            return votersToTokenCount[voter];
        } else {
            // Calculate total tokens currently distributed among voters
            uint256 totalDistributedTokens = 0;
            for (uint256 i = 0; i < voters.length; i++) {
                totalDistributedTokens += votersToTokenCount[voters[i]];
            }
            
            // Calculate how many tokens each voter should have after redistribution
            uint256 newVoterCount = voterCount + 1;
            uint256 tokensPerVoter = totalDistributedTokens / newVoterCount;
            uint256 tokensForNewVoter = 0;
            
            // Redistribute tokens from existing voters to new voter
            for (uint256 i = 0; i < voters.length; i++) {
                uint256 currentBalance = votersToTokenCount[voters[i]];
                uint256 newBalance = tokensPerVoter;
                
                if (currentBalance > newBalance) {
                    uint256 tokensToTransfer = currentBalance - newBalance;
                    _transfer(voters[i], voter, tokensToTransfer);
                    votersToTokenCount[voters[i]] = newBalance;
                    tokensForNewVoter += tokensToTransfer;
                }
            }
            
            votersToTokenCount[voter] = tokensForNewVoter;
            voterCount++;
            voters.push(voter);
            return tokensForNewVoter;
        }
    }
    
    function checkBalanceofThisContract() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function hostVoting(string memory option, uint256 durationInDays) public {
        votingOptions[option] = block.timestamp + (durationInDays * 1 days); // Fixed: should be absolute timestamp
        options.push(option);
    }

    function getVotingOptions() public view returns (string[] memory) {
        string[] memory opts = new string[](options.length);
        for (uint256 i = 0; i < options.length; i++) {
            opts[i] = options[i];
        }
        return opts;
    }

    function giveVotes(
        address voter,
        uint256 amount,
        string memory option
    ) public {
        require(votersToTokenCount[voter] > 0, "Voter not registered");
        require(amount <= votersToTokenCount[voter], "Insufficient tokens");
        require(amount > 0, "Amount must be greater than zero");
        require(
            block.timestamp < votingOptions[option], // Fixed: should check the option directly
            "Voting period has ended"
        );
        
        _transfer(voter, address(this), amount);
        votersToTokenCount[voter] = balanceOf(voter); // Update voter's token count
        voterVotes[voter][amount] = option;
        optionVotes[option] += amount;
    }

    function checkWinner(
        string[] memory optionsList // Fixed: renamed parameter to avoid shadowing
    ) public view returns (string memory winner, uint256 winningVotes) {
        require(optionsList.length > 0, "No options provided");

        uint256 maxVotes = 0;
        string memory winningOption = "";

        for (uint256 i = 0; i < optionsList.length; i++) {
            uint256 votes = optionVotes[optionsList[i]];
            if (votes > maxVotes) {
                maxVotes = votes;
                winningOption = optionsList[i];
            }
        }

        return (winningOption, maxVotes);
    }
}