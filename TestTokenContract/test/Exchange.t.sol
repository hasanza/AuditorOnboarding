// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Exchange.sol";
import "../src/TestToken.sol";

contract ExchangeTest is Test {
    // Variables
    Exchange public exchange;
    TestToken public localTestToken;
    // User addr
    address public alex;
    address public bob;

    function setUp() public {
        // Instantiate the Exchange, 2 Wei is the rate. So, when user givbes 3 wei, he hets 9 tokens
        exchange = new Exchange(3);
        localTestToken = new TestToken();
        // Create a user addr
        alex = makeAddr("alex");
        bob = makeAddr("bob");
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
    function testFuzz_ethTokenEquivalence(uint256 ethAmount) public {
        vm.startPrank(alex);
        vm.assume(ethAmount != 0 && ethAmount < 100_000_000 ether);

        // Buy tokens
        uint256 tokens = exchange.buyTokens{value: ethAmount}();
        // Sell tokens
        ERC20(exchange.testToken()).approve(address(exchange), tokens);
        uint256 eth = exchange.sellTokens(tokens);

        assertEq(eth, ethAmount);
    }

    ///@notice Ensures all authorized functions are only callable by appropriate caller
    function test_ownershipTransferAuth() public {
        // Alex cannot transfer ownership
        vm.prank(alex);
        vm.expectRevert("Ownable: caller is not the owner");
        exchange.transferOwnership(bob);
        // But owner can
        exchange.transferOwnership(bob);
    }

    function test_mintAuth() public {
        // Unregistered caller cannot mint TestTokens
        vm.prank(alex);
        vm.expectRevert("TestToken: Unreg minter");
        localTestToken.mint(bob, 1000 ether);
        // But registered minter can
        localTestToken.mint(bob, 1000 ether);
    }
}
