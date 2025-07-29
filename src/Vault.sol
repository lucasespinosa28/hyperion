// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Vault
/// @notice Minimal treasury contract for Project Hyperion
/// @dev Holds collateral and liquidity pool assets. Only the PositionManager
///      can instruct deposits or withdrawals.
contract Vault {
    /// @notice PositionManager address with exclusive rights
    address public immutable positionManager;

    /// @notice total amount of each ERC20 token held
    mapping(address => uint256) public totalAssets;

    constructor(address _positionManager) {
        require(_positionManager != address(0), "invalid position manager");
        positionManager = _positionManager;
    }

    modifier onlyPositionManager() {
        require(msg.sender == positionManager, "caller is not PositionManager");
        _;
    }

    /// @notice deposit tokens into the vault
    /// @param _token ERC20 token address
    /// @param _amount amount to deposit
    function deposit(address _token, uint256 _amount) external onlyPositionManager {
        require(_amount > 0, "zero amount");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        totalAssets[_token] += _amount;
    }

    /// @notice withdraw tokens from the vault to a recipient
    /// @param _token ERC20 token address
    /// @param _recipient receiver address
    /// @param _amount amount to withdraw
    function withdraw(address _token, address _recipient, uint256 _amount) external onlyPositionManager {
        require(_recipient != address(0), "zero recipient");
        require(_amount > 0, "zero amount");
        require(totalAssets[_token] >= _amount, "insufficient asset");
        totalAssets[_token] -= _amount;
        IERC20(_token).transfer(_recipient, _amount);
    }
}