// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink-evm/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Vault.sol";
import "./GLPToken.sol";

/// @title PositionManager
/// @notice Core logic for opening and closing leveraged positions
contract PositionManager {

    Vault public immutable vault;
    address public immutable router;
    GLPToken public immutable glpToken;
    AggregatorV3Interface internal priceFeed;

    struct Position {
        address account;
        address collateralToken;
        address indexToken;
        uint256 size; // notional position size
        uint256 collateralValue;
        uint256 entryPrice;
        bool isLong;
        uint256 lastFundingTime;
    }

    mapping(bytes32 => Position) public positions;
    uint256 public totalLongInterest;
    uint256 public totalShortInterest;
    uint256 public positionIndex;

    constructor(address _router, Vault _vault, GLPToken _glpToken, address _priceFeed) {
        require(_router != address(0), "router 0");
        require(address(_vault) != address(0), "vault 0");
        require(address(_glpToken) != address(0), "glp 0");
        require(_priceFeed != address(0), "oracle 0");
        router = _router;
        vault = _vault;
        glpToken = _glpToken;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    modifier onlyRouter() {
        require(msg.sender == router, "only router");
        _;
    }

    function _getOraclePrice(address /*_indexToken*/) internal view returns (uint256 price) {
        (, int256 answer,, uint256 updatedAt,) = priceFeed.latestRoundData();
        require(updatedAt > block.timestamp - 1 hours, "stale price");
        require(answer > 0, "invalid price");
        price = uint256(answer);
    }

    function openPosition(address collateralToken, uint256 collateralAmount, address indexToken, bool isLong, uint256 leverage, address trader) external onlyRouter returns (bytes32 key) {
        require(collateralAmount > 0, "amount 0");
        require(leverage >= 1 && leverage <= 10, "invalid leverage");

        IERC20(collateralToken).transferFrom(trader, address(this), collateralAmount);
        IERC20(collateralToken).approve(address(vault), collateralAmount);
        vault.deposit(collateralToken, collateralAmount);

        uint256 price = _getOraclePrice(indexToken);
        uint256 size = collateralAmount * leverage;

        key = keccak256(abi.encodePacked(trader, positionIndex++));
        positions[key] = Position({
            account: trader,
            collateralToken: collateralToken,
            indexToken: indexToken,
            size: size,
            collateralValue: collateralAmount,
            entryPrice: price,
            isLong: isLong,
            lastFundingTime: block.timestamp
        });

        if (isLong) {
            totalLongInterest += size;
        } else {
            totalShortInterest += size;
        }
    }

    function closePosition(bytes32 key, address recipient) external onlyRouter {
        Position storage pos = positions[key];
        require(pos.account == recipient, "not owner");
        uint256 amount = pos.collateralValue; // TODO: include PnL
        delete positions[key];
        vault.withdraw(pos.collateralToken, recipient, amount);

        if (pos.isLong) {
            totalLongInterest -= pos.size;
        } else {
            totalShortInterest -= pos.size;
        }
    }
}