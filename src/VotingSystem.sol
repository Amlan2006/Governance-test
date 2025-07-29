//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract VotingSystem is ERC20{
    address public immutable owner;
    mapping(address voters => uint256 tokenCount) public votersToTokenCount;
    uint256 public voterCount = 1;
    uint256 INITIAL_SUPPLY = 1000e18;
    // Add mapping of option and address to votes

    constructor() ERC20("VotingToken", "VT") { 
        msg.sender == owner;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    // Register a voter and assign them tokens
    function registerVoter(address voter) public returns(uint256){
        votersToTokenCount[voter] = INITIAL_SUPPLY/voterCount;
        _mint(voter,votersToTokenCount[voter]);
        voterCount++;
        return votersToTokenCount[voter];
    }
    function hostVoting(uint256 optionNumber, uint256 durationInDays) public onlyOwner{

    }
    function giveVotes(address voter, uint256 amount) public{
        if(votersToTokenCount[voter] == 0){
            revert("Voter not registered");
        }

    }




    
}