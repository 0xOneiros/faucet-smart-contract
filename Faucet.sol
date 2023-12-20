// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FaucetNAME {
    address payable public admin;
    uint256 public maxWithdrawalPerDay = 0.3 ether; 
    uint256 public withdrawalFee = 0.001 ether;
    uint256 public lastWithdrawalBlock;
    mapping(address => uint256) public lastWithdrawalTimestamps;
    mapping(address => bool) public whitelist;
    
    event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event MaxWithdrawalPerDayChanged(uint256 newMaxWithdrawalPerDay, uint256 timestamp);
    event WithdrawalFeeChanged(uint256 newWithdrawalFee, uint256 timestamp);
    event WhitelistAdded(address indexed user, uint256 timestamp);
    event WhitelistRemoved(address indexed user, uint256 timestamp);
    
    constructor() {
        admin = payable(msg.sender);
        lastWithdrawalBlock = block.number;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    function withdraw() external {
        require(lastWithdrawalTimestamps[msg.sender] + 1 days <= block.timestamp, "You can only withdraw once per day");
        require(address(this).balance >= maxWithdrawalPerDay, "Insufficient balance");
        require(block.number > lastWithdrawalBlock, "Can only withdraw once per block");
        require(msg.sender != admin, "Admin cannot withdraw");
        require(!whitelist[msg.sender], "Address is whitelisted for higher withdrawal limit");
        
        lastWithdrawalTimestamps[msg.sender] = block.timestamp;
        lastWithdrawalBlock = block.number;
        uint256 withdrawalAmount = maxWithdrawalPerDay - withdrawalFee;
        payable(msg.sender).transfer(withdrawalAmount);
        payable(admin).transfer(withdrawalFee);
        emit Withdrawal(msg.sender, withdrawalAmount, block.timestamp);
    }
    
    function setMaxWithdrawalPerDay(uint256 newMaxWithdrawalPerDay) external onlyAdmin {
        require(newMaxWithdrawalPerDay > 0, "Max withdrawal per day must be greater than zero");
        maxWithdrawalPerDay = newMaxWithdrawalPerDay;
        emit MaxWithdrawalPerDayChanged(newMaxWithdrawalPerDay, block.timestamp);
    }
    
    function setWithdrawalFee(uint256 newWithdrawalFee) external onlyAdmin {
        withdrawalFee = newWithdrawalFee;
        emit WithdrawalFeeChanged(newWithdrawalFee, block.timestamp);
    }
    
    function addToWhitelist(address user) external onlyAdmin {
        whitelist[user] = true;
        emit WhitelistAdded(user, block.timestamp);
    }
    
    function removeFromWhitelist(address user) external onlyAdmin {
        whitelist[user] = false;
        emit WhitelistRemoved(user, block.timestamp);
    }
    
    function withdrawBalance() external onlyAdmin {
        admin.transfer(address(this).balance);
    }
    
    receive() external payable {
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    function deposit() external payable {
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
}