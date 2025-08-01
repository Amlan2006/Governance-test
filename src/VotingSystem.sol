//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import "forge-std/StdMath.sol";
contract VotingSystem is ERC20 {
    address public immutable owner;
    mapping(address voters => uint256 tokenCount) public votersToTokenCount;
    uint256 public voterCount = 1;
    // uint256 INITIAL_SUPPLY = 1000e18;
    string[] public options;
    bool public hasTransfered = false;
    mapping(address voter => mapping(uint256 votes => string optionName))
        public voterVotes;
    mapping(string optionName => uint256 duration) public votingOptions;
    mapping(string optionName => uint256 votes) public optionVotes;
    address[] public voters;

    constructor(uint256 INITIAL_SUPPLY) ERC20("VotingToken", "VT") {
        msg.sender == owner;
        _mint(address(this), INITIAL_SUPPLY);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Register a voter and assign them tokens
    function registerVoter(address voter) public returns (uint256) {
        // voter need to get INITIAL_SUPPLY/voterCount tokens
        // transfer tokens from previous voter to new voter whose sum will be equal to INITIAL_SUPPLY/voterCount
        // the amount each of the previous owners has to pay to new voter will be equal to INITIAL_SUPPLY/voterCount-1
      
        require(voter != address(0), "Invalid voter address");
        // if (votersToTokenCount[voter] > 0) {
            //This has to change
            // _mint(voter, votersToTokenCount[voter]);
            if (hasTransfered == false) {
                votersToTokenCount[voter] = balanceOf(address(this));
                _transfer(address(this), voter, votersToTokenCount[voter]);
                hasTransfered = true;
                voterCount++;
                voters.push(voter);
            } else {
                  uint256 amountToTransfer = balanceOf(address(this)) / voterCount;
        uint256 previousVoterCount = voterCount - 1;
        uint256 amountToPay = amountToTransfer / previousVoterCount;
        uint256 sum = 0;
                for (uint256 i = 0; i < voters.length; i++) {
                    if (voters[i] != voter) {
                    _transfer(voters[i], voter, amountToPay);
                        sum += amountToPay;
                    }
                }
               
                votersToTokenCount[voter] = sum;
                voterCount++;
                voters.push(voter);

                return votersToTokenCount[voter];
            }
        // }
        // revert("Voter already registered");
    }
    function checkBalanceofThisContract() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function hostVoting(string memory option, uint256 durationInDays) public {
        votingOptions[option] = durationInDays * 1 days;
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
        if (votersToTokenCount[voter] == 0) {
            revert("Voter not registered");
        }
        require(amount <= votersToTokenCount[voter], "Insufficient tokens");
        require(amount > 0, "Amount must be greater than zero");
        require(
            block.timestamp < votingOptions[voterVotes[voter][amount]],
            "Voting period has ended"
        );
        _transfer(voter, address(this), amount);
        voterVotes[voter][amount] = option;
        optionVotes[option] += amount;
    }

    function checkWinner(
        string[] memory options
    ) public view returns (string memory winner, uint256 winningVotes) {
        require(options.length > 0, "Option does not exist");

        uint256 maxVotes = 0;
        string memory winningOption = "";

        for (uint256 i = 0; i < options.length; i++) {
            uint256 votes = optionVotes[options[i]];
            if (votes > maxVotes) {
                maxVotes = votes;
                winningOption = options[i];
            }
        }

        return (winningOption, maxVotes);
    }
}
