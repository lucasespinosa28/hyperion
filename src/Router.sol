// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PositionManager.sol";

/// @title Router
/// @notice Frontend entry contract for Hyperion
contract Router {
    PositionManager public immutable positionManager;

    constructor(PositionManager _pm) {
        positionManager = _pm;
    }

    function openPosition(address collateralToken, uint256 collateralAmount, address indexToken, bool isLong, uint256 leverage) external {
        IERC20(collateralToken).transferFrom(msg.sender, address(positionManager), collateralAmount);
        positionManager.openPosition(collateralToken, collateralAmount, indexToken, isLong, leverage, msg.sender);
    }

    function closePosition(bytes32 key) external {
        positionManager.closePosition(key, msg.sender);
    }
}