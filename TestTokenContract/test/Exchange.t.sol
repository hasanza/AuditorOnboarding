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
    function test_buyAndSellTokens() public {
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
        exchange.testToken().approve(address(exchange), tokens);
        uint256 eth = exchange.sellTokens(tokens);

        assertEq(eth, ethAmount);
    }

    function test_setRate() public {
        // Revert if rate of 0 is set
        vm.expectRevert("Exchange: Rate must be non-zero and new");
        exchange.setRate(0);
        // Revert if rate is set by non-owner
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(alex);
        exchange.setRate(3);
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function test_ownershipTransferAuthEvent() public {
        vm.expectEmit();
        emit OwnershipTransferred(address(this), alex);
        exchange.transferOwnership(alex);
    }


    event RateSet(uint256 indexed previousRate, uint256 indexed newRate);
    function test_setRateEvent() public {

        uint256 prevRate = exchange.rate();
        uint256 newRate = 5;

        vm.expectEmit();
        emit RateSet(prevRate, newRate);
        exchange.setRate(newRate);
    }


    function test_mintAuth() public {
        // Unregistered caller cannot mint TestTokens
        vm.prank(alex);
        vm.expectRevert("TestToken: Unreg minter");
        localTestToken.mint(bob, 1000 ether);
        // But registered minter can
        localTestToken.mint(bob, 1000 ether);
    }

    function test_burnAuth() public {
        // Mint tokens
        localTestToken.mint(bob, 1000 ether);
        // Unregistered caller cannot mint TestTokens
        vm.prank(alex);
        vm.expectRevert("TestToken: Unreg minter");
        localTestToken.burn(bob, 1000 ether);
        // But registered minter can
        localTestToken.burn(bob, 1000 ether);
    }

    function test_directEthTransfer() public {
        vm.prank(alex);
        //Send ETH directly, hits receive()
        vm.expectRevert();
        (bool success,) = address(exchange).call{value: 2 ether}("");
        require(success);
    }


     function test_directCall() public {
         vm.prank(alex);
         // Calls func directly, hits fallback()
         vm.expectRevert();
         (bool success,) = address(exchange).call{value: 2 ether}(
             abi.encodeWithSignature("joeMama()")
         );
         require(success);
     }

}
