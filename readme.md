# Onboarding Walkthrough

Going through the onboarding task list.

## [TASK1] Create TestToken exchange contract.

   1. Exchange's **constructor** sets the exchange rate, sets itself as registered minter and sets deployer as owner.
   2. Exchange.**buyToken()** accepts ETH, calculates token amount (ETH*rate), mints tokens, sends tokens to buyer.
   3. Exchange.**sellToken(uint256 tokenAmount)** calculates ETH amount to be returned based on rate (tokenAmount/rate), transfers this token amount from seller to Exchange, burns this amount, sends calculated ETH to seller.
   4. Exchange.**transferOwnership(address newOwner)** allows current owner to transfer Exchange ownership to new owner, emitting the relevant event.
   5. Exchange.**setRate(uint256 newRate)** allows current owner to set a new rate for the Exchange, emitting the relevant event.
   6. Test suite should test:
      1. That correct amount is returned by Exchange.**buyTokens**
      2. That if a user buys tokens for ETH, then sells them back, he should get the original amount of ETH back.
      3. That calls revert if unauthorized calls are made to restricted functions.
