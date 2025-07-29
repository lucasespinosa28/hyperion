
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Router.sol";
import "src/PositionManager.sol";
import "src/Vault.sol";
import "src/GLPToken.sol";
import "src/test/mocks/MockERC20.sol";

contract RouterTest is Test {
    Router public router;
    PositionManager public positionManager;
    Vault public vault;
    GLPToken public glpToken;
    MockERC20 public collateralToken;

    address constant ETH_USD_PRICE_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    address public user;

    function setUp() public {
        user = address(0x1234);
        glpToken = new GLPToken("GLP Token", "GLP");
        collateralToken = new MockERC20("Test Collateral", "COL");

        // Compute addresses ahead of time to solve circular dependency
        // Current nonce for this contract: after glpToken and collateralToken = 2
        address predictedVault = vm.computeCreateAddress(address(this), vm.getNonce(address(this)));
        address predictedPositionManager = vm.computeCreateAddress(address(this), vm.getNonce(address(this)) + 1);
        address predictedRouter = vm.computeCreateAddress(address(this), vm.getNonce(address(this)) + 2);
        
        // Deploy contracts with predicted addresses
        vault = new Vault(predictedPositionManager);
        positionManager = new PositionManager(predictedRouter, vault, glpToken, ETH_USD_PRICE_FEED);
        router = new Router(positionManager);
        
        // Verify the addresses match our predictions
        require(address(vault) == predictedVault, "vault address mismatch");
        require(address(positionManager) == predictedPositionManager, "position manager address mismatch");
        require(address(router) == predictedRouter, "router address mismatch");
    }

    function test_OpenPosition() public {
        address collateralTokenAddress = address(collateralToken);
        uint256 collateralAmount = 1000;
        address indexToken = address(0); // ETH
        bool isLong = true;
        uint256 leverage = 10;

        // User mints and approves tokens
        vm.startPrank(user);
        collateralToken.mint(user, collateralAmount);
        collateralToken.approve(address(router), collateralAmount);
        // User calls router to open position
        router.openPosition(collateralTokenAddress, collateralAmount, indexToken, isLong, leverage);
        vm.stopPrank();

        // Assert position is created for user
        bytes32 key = keccak256(abi.encodePacked(user, uint256(0)));
        (address account,,,,,,,) = positionManager.positions(key);
        assertEq(account, user);
    }

    // Additional realistic tests can be added here
}
