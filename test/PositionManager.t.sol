// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/PositionManager.sol";
import "src/Vault.sol";
import "src/Router.sol";
import "src/GLPToken.sol";
import "@chainlink-evm/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract PositionManagerTest is Test {
    PositionManager public positionManager;
    Vault public vault;
    Router public router;
    GLPToken public glpToken;
    AggregatorV3Interface public priceFeed;

    // Mock Price Feed
    address constant ETH_USD_PRICE_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    function setUp() public {
        // Deploy vault with a temporary address
        glpToken = new GLPToken("GLP Token", "GLP");
        vault = new Vault(address(0xdead));
        router = new Router(PositionManager(address(0xdead)));
        priceFeed = AggregatorV3Interface(ETH_USD_PRICE_FEED);
        positionManager = new PositionManager(address(router), vault, glpToken, ETH_USD_PRICE_FEED);
        // Re-deploy vault and router with correct positionManager address
        vault = new Vault(address(positionManager));
        router = new Router(positionManager);
    }

    function test_CreatePosition() public {
        // Add test logic here
    }

    function test_ClosePosition() public {
        // Add test logic here
    }

    function test_LiquidatePosition() public {
        // Add test logic here
    }

    function test_UpdateFundingRate() public {
        // Add test logic here
    }
}
