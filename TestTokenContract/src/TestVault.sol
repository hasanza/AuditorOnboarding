// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract TestVault is Ownable, ERC20 {
    uint public rate;

    event TokensPurchased(address indexed buyer, uint amount, uint cost);
    event TokensSold(address indexed seller, uint amount, uint revenue);
    event RateSet(uint indexed previousRate, uint indexed newRate);

    /**
    @notice wSets the exchange rate, deploys TestToken, makes deployer the owner
     */
    constructor(uint _rate) ERC20("TestToken", "TTK") {
        require(_rate > 0, "TestVault: Rate must be greater than zero");
        // The rate defines how much ETH is required to be deposited for 1 TTK
        rate = _rate;
    }

    function buyTokens() external payable {
        require(msg.value > 0, "TestVault: Insufficient ETH provided");
        uint tokenAmount = msg.value * rate;
        require(tokenAmount > 0, "TestVault: Invalid token amount");
        // Transfer to caller
        transfer(msg.sender, tokenAmount);
    
        emit TokensPurchased(msg.sender, tokenAmount, msg.value);
    }

    function sellTokens(uint amount) external {
        require(amount > 0, "TestVault: Invalid token amount");

        uint ethAmount = amount / rate;
        require(ethAmount > 0, "TestVault: Insufficient token amount");

        require(balanceOf(msg.sender) >= amount, "TestVault: Insufficient token balance");

        transferFrom(msg.sender, address(this), amount);

        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "TestVault: Failed to send ETH to seller");

        emit TokensSold(msg.sender, amount, ethAmount);
    }

    function setRate(uint newRate) external onlyOwner {
        require(newRate > 0, "TestVault: Rate must be greater than zero");

        uint previousRate = rate;
        rate = newRate;

        emit RateSet(previousRate, newRate);
    }
}