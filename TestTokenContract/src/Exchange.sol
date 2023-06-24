// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestToken.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/access/Ownable.sol";


contract Exchange is Ownable, ReentrancyGuard {
    // Using OZ's safeERC20 to handle transfer return values, among other stuff
    using SafeERC20 for TestToken;
    // To store TestToken instance address
    TestToken public testToken;
    // Defines how much ETH (in Wei) is required to be deposited for 1 TTK
    uint256 public rate;
    // Relevant events
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event TokensSold(address indexed seller, uint256 amount, uint256 revenue);
    event RateSet(uint256 indexed previousRate, uint256 indexed newRate);

    /**
    @notice Sets the exchange rate, deploys TestToken, makes deployer the owner
     */
    constructor(uint256 _rate) {
        // Deploy the TestToken and store the instance address
        testToken = new TestToken();
        // Ensure the supplied rate is greater than 0
        require(_rate > 0, "TestVault: Rate must be greater than zero");
        rate = _rate;
    }


    function tokensForEth(uint256 ethAmount) public view returns (uint256) {
        return ethAmount * rate;
    }
    function ethForTokens(uint256 tokenAmount) public view returns (uint256) {
        return tokenAmount / rate;
    }

    /**
    @notice Function to buy TestTokens in exchange for ETH, as per the rate.
     */
    function buyTokens() external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "TestVault: Insufficient ETH provided");
        uint256 tokenAmount = msg.value * rate;
        require(tokenAmount > 0, "TestVault: Invalid token amount");
        // Mint TestTokens to caller 
        testToken.mint(msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, tokenAmount, msg.value);
        // Return bought TestToken amount
        return tokenAmount;
    }

    function sellTokens(uint256 amount) external nonReentrant returns (uint256) {
        require(amount > 0, "TestVault: Invalid token amount");
        // ETH amount to return to seller; Tokens/ rate
        uint256 ethAmount = amount / rate;
        require(ethAmount > 0, "TestVault: Insufficient token amount");

        require(testToken.balanceOf(msg.sender) >= amount, "TestVault: Insufficient token balance");
        // Transfer tokens being sold from seller to this contract  
        testToken.safeTransferFrom(msg.sender, address(this), amount);
        // Burn the tokens sold
        testToken.burn(address(this), amount);

        // Transfer commensurate ETH amount to the caller/ seller
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "TestVault: Failed to send ETH to seller");

        emit TokensSold(msg.sender, amount, ethAmount);

        return (ethAmount);
    }

    function setRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "TestVault: Rate must be greater than zero");

        uint256 previousRate = rate;
        rate = newRate;

        emit RateSet(previousRate, newRate);
    }

    fallback() external payable {
        revert("TestVault: No direct calls");
    }

    receive() external payable {
        revert("TestVault: No direct deposits");
    }
}