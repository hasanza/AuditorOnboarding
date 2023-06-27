# Onboarding Walkthrough

Going through the onboarding task list.

## [TASK1] Create TestToken exchange contract ✅

   1. Exchange's **constructor** sets the exchange rate, sets itself as registered minter and sets deployer as owner.
   2. Exchange.**buyToken()** accepts ETH, calculates token amount (ETH*rate), mints tokens, sends tokens to buyer.
   3. Exchange.**sellToken(uint256 tokenAmount)** calculates ETH amount to be returned based on rate (tokenAmount/rate), transfers this token amount from seller to Exchange, burns this amount, sends calculated ETH to seller.
   4. Exchange.**transferOwnership(address newOwner)** allows current owner to transfer Exchange ownership to new owner, emitting the relevant event.
   5. Exchange.**setRate(uint256 newRate)** allows current owner to set a new rate for the Exchange, emitting the relevant event.
   6. Test suite should test:
      1. That correct amount is returned by Exchange.**buyTokens**
      2. That if a user buys tokens for ETH, then sells them back, he should get the original amount of ETH back.
      3. That calls revert if unauthorized calls are made to restricted functions.

## [TASK2] Answer questions regarding given reading ✅

### Could you have used immutable variables or constants in your contract? If so, where?

Perhaps if the `rate` were fixed; in that case I would have used a immutable variable.

### How much storage space does the string “Hello” consume?

`string` is an alias for `bytes1[]`. In this case, Hello has 5 characters so it is 5 bytes in size. Given that this is a dynamic bytes array with a size less than 32 bytes, the array elements are stored along with the length (stored in the lowest order byte) in the same storage slot. However, the entire slot 32 byte slot will by occupied given how EVM works. In conclusion, the string "Hello" will consume 32 bytes of storage space (one out of the `2^256` storage slots).

The storage slot would look like this:

`0x48656c6c6f000000000000000000000000000000000000000000000000000005`

We can confirm this using this `TestString` contract and the `sol2uml` storage layout visualization package:

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestString {
    string public s = "Hello";
    constructor() payable {}
}
```

Running

`sol2uml storage ./src/ -c TestString -o gasStorage.svg`

in the directory outputs the storage layout:

![image](https://github.com/hasanza/AuditorOnboarding/assets/49759922/01b01ab7-c6bf-403b-924c-e7ea365e4f81)


### Can you use the .push() function for uint arrays in memory? If yes, what is the estimated gas cost? If not, why not?

The `push()` method does **not** exist on fixed-sze memory arrays. The documentation states that only dynamic storage arrays and `bytes` (alias for `byte[]` and can store arbitrary length byte data) have this member.

![image](https://github.com/hasanza/AuditorOnboarding/assets/49759922/e762ba23-61b9-414a-ad45-78eb4017a22d)

The error states that: `Member "push" is not available in uint256[] memory outside of storage`.

### What is the difference between a constant and an immutable variable?

Both are similar in the following regards:

- No storage slot is reserved for them and their mention is replaced with their values.

Both are different in the following regards:

- The difference is that in case of `constant`, the expression assigned to a constant variable is evaluated each time it is mentioned. On the other hand, in case of `immutable`, the value is evaluated and assigned at construction time, after which it is copied everywhere the variable is mentioned.
    
- In addition, a `constant`'s value is fixed at compile time and the code is replaced with the expression assigned to it is copied everywhere the variable is mentioned in the compiled code. On the other hand, an `immutable` can be assigned value at declaration or in the `constructor`, but it cannot be read during construction.
    
- More over, no matter the size of an `immutable`, 32 bytes are reserved for it.
