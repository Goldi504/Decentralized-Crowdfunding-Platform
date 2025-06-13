// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    // State variables
    address public owner;
    string public title;
    string public description;
    uint256 public goalAmount;
    uint256 public deadline;
    uint256 public raisedAmount;
    bool public completed;
    bool public goalReached;
    
    // Mapping to track contributions
    mapping(address => uint256) public contributions;
    address[] public contributors;
    
    // Events
    event ContributionMade(address indexed contributor, uint256 amount);
    event GoalReached(uint256 totalAmount);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event RefundIssued(address indexed contributor, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only project owner can call this function");
        _;
    }
    
    modifier campaignActive() {
        require(block.timestamp < deadline, "Campaign has ended");
        require(!completed, "Campaign already completed");
        _;
    }
    
    modifier campaignEnded() {
        require(block.timestamp >= deadline, "Campaign is still active");
        _;
    }
    
    // Constructor
    constructor(
        string memory _title,
        string memory _description,
        uint256 _goalAmount,
        uint256 _durationInDays
    ) {
        owner = msg.sender;
        title = _title;
        description = _description;
        goalAmount = _goalAmount;
        deadline = block.timestamp + (_durationInDays * 1 days);
        raisedAmount = 0;
        completed = false;
        goalReached = false;
    }
    
    // Core Function 1: Contribute to the project
    function contribute() public payable campaignActive {
        require(msg.value > 0, "Contribution must be greater than 0");
        
        // If this is a new contributor, add to contributors array
        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        
        contributions[msg.sender] += msg.value;
        raisedAmount += msg.value;
        
        emit ContributionMade(msg.sender, msg.value);
        
        // Check if goal is reached
        if (raisedAmount >= goalAmount && !goalReached) {
            goalReached = true;
            emit GoalReached(raisedAmount);
        }
    }
    
    // Core Function 2: Withdraw funds (only if goal is reached)
    function withdrawFunds() public onlyOwner campaignEnded {
        require(goalReached, "Goal not reached, cannot withdraw funds");
        require(!completed, "Funds already withdrawn");
        require(address(this).balance > 0, "No funds to withdraw");
        
        completed = true;
        uint256 amount = address(this).balance;
        
        // Transfer funds to project owner
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    // Core Function 3: Request refund (only if goal is not reached)
    function requestRefund() public campaignEnded {
        require(!goalReached, "Goal was reached, no refunds available");
        require(contributions[msg.sender] > 0, "No contribution found");
        
        uint256 contributionAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        // Transfer refund to contributor
        (bool success, ) = payable(msg.sender).call{value: contributionAmount}("");
        require(success, "Refund transfer failed");
        
        emit RefundIssued(msg.sender, contributionAmount);
    }
    
    // View functions
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getTimeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
    
    function getContributorsCount() public view returns (uint256) {
        return contributors.length;
    }
    
    function getProjectDetails() public view returns (
        string memory,
        string memory,
        uint256,
        uint256,
        uint256,
        bool,
        bool,
        uint256
    ) {
        return (
            title,
            description,
            goalAmount,
            deadline,
            raisedAmount,
            completed,
            goalReached,
            getTimeLeft()
        );
    }
}
