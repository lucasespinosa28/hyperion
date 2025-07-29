// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title GLPToken
/// @notice ERC20 token representing liquidity provider shares in Hyperion
contract GLPToken is ERC20Burnable, Ownable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) Ownable(msg.sender) {}

    /// @notice mint new GLP tokens
    /// @dev Only callable by the owner (PositionManager)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice burn GLP tokens from an account
    /// @dev Only callable by the owner (PositionManager)
    function burnFromAccount(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}