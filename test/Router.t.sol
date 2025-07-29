// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Router.sol";
import "src/PositionManager.sol";
import "src/Vault.sol";
import "src/GLPToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RouterTest is Test {
    Router public router;
    PositionManager public positionManager;
    Vault public vault;
    GLPToken public glpToken;
    ERC20 public collateralToken;

    address constant ETH_USD_PRICE_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    function setUp() public {
        glpToken = new GLPToken("GLP Token", "GLP");
        vault = new Vault(address(0)); // Will be set to PositionManager later
        router = new Router(address(vault), address(0), address(glpToken)); // Will be set to PositionManager later
        positionManager = new PositionManager(address(router), vault, glpToken, ETH_USD_PRICE_FEED);

        // Set the position manager address in the vault and router
        vault.transferOwnership(address(positionManager));
        router.transferOwnership(address(positionManager));

        collateralToken = new ERC20("Test Collateral", "COL");
    }

    function test_OpenPosition() public {
        address collateralTokenAddress = address(collateralToken);
        uint256 collateralAmount = 1000;
        address indexToken = address(0); // ETH
        bool isLong = true;
        uint256 leverage = 10;

        collateralToken.mint(address(this), collateralAmount);
        collateralToken.approve(address(router), collateralAmount);

        router.openPosition(collateralTokenAddress, collateralAmount, indexToken, isLong, leverage);

        // Add assertions here
        (bytes32 key) = router.getPositionKey(address(this), 0);
        (address account,,,,,,,) = positionManager.positions(key);
        assertEq(account, address(this));
    }

    function test_ClosePosition() public {
        // Add test logic here
    }

    function test_DepositLiquidity() public {
        address tokenAddress = address(collateralToken);
        uint256 amount = 5000;

        collateralToken.mint(address(this), amount);
        collateralToken.approve(address(router), amount);

        router.depositLiquidity(tokenAddress, amount);

        assertEq(glpToken.balanceOf(address(this)), amount);
    }

    function test_WithdrawLiquidity() public {
        // Add test logic here
    }
}
