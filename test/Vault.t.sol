// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Vault.sol";
import "src/test/mocks/MockPositionManager.sol";
import "src/test/mocks/MockERC20.sol";

contract VaultTest is Test {
    Vault public vault;
    MockPositionManager public mockPositionManager;
    MockERC20 public token;

    function setUp() public {
        mockPositionManager = new MockPositionManager();
        vault = new Vault(address(mockPositionManager));
        token = new MockERC20("Test Token", "TST");
    }

    function test_Deposit() public {
        address tokenAddress = address(token);
        uint256 amount = 100;

        // Mint tokens to MockPositionManager
        token.mint(address(mockPositionManager), amount);
        // Approve Vault from MockPositionManager
        vm.prank(address(mockPositionManager));
        token.approve(address(vault), amount);
        mockPositionManager.setVault(address(vault));
        vm.prank(address(mockPositionManager));
        mockPositionManager.deposit(tokenAddress, amount);

        assertEq(vault.totalAssets(tokenAddress), amount);
    }

    function test_Withdraw() public {
        address tokenAddress = address(token);
        uint256 amount = 100;

        // Mint tokens to MockPositionManager
        token.mint(address(mockPositionManager), amount);
        // Approve Vault from MockPositionManager
        vm.prank(address(mockPositionManager));
        token.approve(address(vault), amount);
        mockPositionManager.setVault(address(vault));
        vm.prank(address(mockPositionManager));
        mockPositionManager.deposit(tokenAddress, amount);
        vm.prank(address(mockPositionManager));
        mockPositionManager.withdraw(tokenAddress, address(this), amount);

        assertEq(vault.totalAssets(tokenAddress), 0);
    }

    function test_FailDepositFromNonPositionManager() public {
        address tokenAddress = address(token);
        uint256 amount = 100;

        token.mint(address(this), amount);
        token.approve(address(vault), amount);
        vm.expectRevert("caller is not PositionManager");
        vault.deposit(tokenAddress, amount);
    }

    function test_FailWithdrawFromNonPositionManager() public {
        address tokenAddress = address(token);
        uint256 amount = 100;

        // Mint tokens to MockPositionManager
        token.mint(address(mockPositionManager), amount);
        // Approve Vault from MockPositionManager
        vm.prank(address(mockPositionManager));
        token.approve(address(vault), amount);
        mockPositionManager.setVault(address(vault));
        vm.prank(address(mockPositionManager));
        mockPositionManager.deposit(tokenAddress, amount);

        vm.expectRevert("caller is not PositionManager");
        vault.withdraw(tokenAddress, address(this), amount);
    }
}
