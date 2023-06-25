// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestToken.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract Exchange is Ownable, ReentrancyGuard {
    // Using OZ's safeERC20 to handle transfer return values, among other stuff
    using SafeERC20 for IERC20;
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
        require(_rate > 0, "Exchange: Rate must be greater than zero");
        rate = _rate;
    }

    /**
    @notice Function to buy TestTokens in exchange for ETH, as per the rate.
     */
    function buyTokens() external payable nonReentrant returns (uint256) {
        // Ensure ETH sent is not 0
        require(msg.value > 0, "Exchange: Insufficient ETH provided");
        // Calculate tokenAmount as per given ETH and the rate
        uint256 tokenAmount = msg.value * rate;
        // Ensure calculated tokenAmount is not 0
        require(tokenAmount > 0, "Exchange: Invalid token amount");
        // Mint tokens
        testToken.mint(address(this), tokenAmount);
        // Transfer minted tokens to user
        IERC20(testToken).safeTransfer(msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, tokenAmount, msg.value);
        // Return bought TestToken amount
        return tokenAmount;
    }

    /**
    @notice Function to sell TestTokens for ETH
     */
    function sellTokens(
        uint256 amount
    ) external nonReentrant returns (uint256) {
        // Ensure amount being sold is not 0
        require(amount > 0, "Exchange: Invalid token amount");
        // Calculate ETH amount to return to seller
        uint256 ethAmount = amount / rate;
        // Ensure calculated eth amount is not 0
        require(ethAmount > 0, "Exchange: Insufficient token amount");
        // Ensure seller has enough balance to sell the given amount of tokens
        require(
            testToken.balanceOf(msg.sender) >= amount,
            "Exchange: Insufficient token balance"
        );
        // Transfer tokens being sold from seller to this contract
        IERC20(testToken).safeTransferFrom(msg.sender, address(this), amount);
        // Burn the tokens sold
        testToken.burn(address(this), amount);
        // Transfer commensurate ETH amount to the caller/ seller
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "Exchange: Failed to send ETH to seller");

        emit TokensSold(msg.sender, amount, ethAmount);

        return (ethAmount);
    }

    /**
    @notice Function to set the rate
     */
    function setRate(uint256 newRate) external onlyOwner returns (uint256) {
        // Cache previous rate for event emission
        uint256 previousRate = rate;
        // Ensure new rate is not 0 and is not the same as current rate
        require(
            newRate > 0 && newRate != previousRate,
            "Exchange: Rate must be non-zero and new"
        );
        // Set new rate
        rate = newRate;

        emit RateSet(previousRate, newRate);

        return newRate;
    }

    /**
    Functions to disallow direct ETH transfers/ calls
     */

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
}
