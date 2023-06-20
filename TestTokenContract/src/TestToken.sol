// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TestVault {
    address public owner;
    uint public rate;
    IERC20 public testToken;

    event TokensPurchased(address indexed buyer, uint amount, uint cost);
    event TokensSold(address indexed seller, uint amount, uint revenue);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RateSet(uint previousRate, uint newRate);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    /**
    Sets the exchange rate, deploys TestToken, makes deployer the owner
     */
    constructor(uint _rate) {
        require(_rate > 0, "Rate must be greater than zero");

        owner = msg.sender;
        rate = _rate;
// Deploy test token
    }

    function buyTokens() external payable {
        uint tokenAmount = msg.value * rate;
        require(tokenAmount > 0, "Insufficient ETH provided");

        testToken.transfer(msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, tokenAmount, msg.value);
    }

    function sellTokens(uint amount) external {
        require(amount > 0, "Invalid token amount");

        uint ethAmount = amount / rate;
        require(ethAmount > 0, "Insufficient token amount");

        require(testToken.balanceOf(msg.sender) >= amount, "Insufficient token balance");

        testToken.transferFrom(msg.sender, address(this), amount);

        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "Failed to send ETH to seller");

        emit TokensSold(msg.sender, amount, ethAmount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function setRate(uint newRate) external onlyOwner {
        require(newRate > 0, "Rate must be greater than zero");

        uint previousRate = rate;
        rate = newRate;

        emit RateSet(previousRate, newRate);
    }
}