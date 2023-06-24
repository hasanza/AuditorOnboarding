// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Exchange.sol";

contract ExchangeTest is Test {
    // Variables
    Exchange public exchange;
    // User addr
    address public alex;

    function setUp() public {
    
        // Instantiate the Exchange, 2 Wei is the rate. So, when user givbes 3 wei, he hets 9 tokens
        exchange = new Exchange(3);
        // Create a user addr
        alex = makeAddr("alex");
        // Mint ETH to alex
        vm.deal(alex, 100_000_000 ether);
     
    }

    // Tests buying tokens with ETH
    function test_buyTokens() public {
        vm.startPrank(alex);
        // Buy tokens worth 2 Eth
        uint256 tokensBought = exchange.buyTokens{value: 2 ether}();
        // Since rate is 2, we will get twice the amount of ETH as tokens, so 6 tokens
        assertEq(tokensBought, 6 ether);
        // Exchange ETH balance should now be 2 ETH
        assertEq(address(exchange).balance, 2 ether);
    }

    ///@notice Buy tokens, then sell them back; ensure we receive same amount we paid for the tokens
    function test_sellTokens() public {

        uint256 ethPaid = 23 ether;
        vm.startPrank(alex);

        // Buy tokens for ETH
        uint256 tokensBought = exchange.buyTokens{value: ethPaid}();
        // Approve Exchange to handle tokens bought, as we prepare to sell them
        exchange.testToken().approve(address(exchange), tokensBought);
        // Sell the tokens for ETH
        uint256 EthReceived = exchange.sellTokens(tokensBought);

        // Assert that the ETH we received in exchange for tokens is the same amount that we paid
        assertEq(ethPaid, EthReceived);
    }

    ///@notice Buy tokens with eth, then sell them to get the eth back, assert equivalence b/w eth amounts
    function testFuzz_biconditionality(uint256 ethAmount) public {

        vm.startPrank(alex);
        vm.assume(ethAmount != 0 && ethAmount < 100_000_000 ether);

        // Buy tokens
        uint256 tokens = exchange.buyTokens{value: ethAmount}();
        // Sell tokens
        exchange.testToken().approve(address(exchange), tokens);
        uint256 eth = exchange.sellTokens(tokens);

        assertEq(eth, ethAmount);
    }
}