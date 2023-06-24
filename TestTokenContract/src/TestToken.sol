// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract TestToken is ERC20, ERC20Burnable {
    // Mapping of registered minters
    mapping(address => bool) internal _registeredMinters;
    constructor() ERC20("TestToken", "TTK") {
        // Add deployer to list of registered minters
        _registeredMinters[msg.sender] = true;
    }

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    function burn(address tokenOwner, uint256 amount) public onlyMinter {
        _burn(tokenOwner, amount);
    }

    modifier onlyMinter() {
        _onlyMinter();
        _;
    }

    function _onlyMinter() internal view {
        require(_registeredMinters[msg.sender], "TestToken: Unreg minter");
    }

    function checkMinter(address _possibleMinter) external view returns (bool) {
        return _registeredMinters[_possibleMinter];
    }

}