// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    // Mapping of registered minters
    mapping(address => bool) internal _registeredMinters;
    constructor() ERC20("TEST", "TEST") {
        // Add deployer to list of registered minters
        _registeredMinters[msg.sender] = true;
    }

    modifier onlyMinter() {
        _onlyMinter();
        _;
    }

    function _onlyMinter() internal view {
        require(_registeredMinters[msg.sender], "TestToken: Unreg minter");
    }

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    function burn(address tokenOwner, uint256 amount) public onlyMinter {
        _burn(tokenOwner, amount);
    }

}