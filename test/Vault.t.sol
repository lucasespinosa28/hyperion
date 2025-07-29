// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Vault.sol";
import "src/test/mocks/MockPositionManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VaultTest is Test {
    Vault public vault;
    MockPositionManager public mockPositionManager;
    ERC20 public token;

    function setUp() public {
        mockPositionManager = new MockPositionManager();
        vault = new Vault(address(mockPositionManager));
        token = new ERC20("Test Token", "TST");
    }

    function test_Deposit() public {
        address tokenAddress = address(token);
        uint256 amount = 100;

        mockPositionManager.setVault(address(vault));
        mockPositionManager.deposit(tokenAddress, amount);

        assertEq(vault.totalAssets(tokenAddress), amount);
    }

    function test_Withdraw() public {
        address tokenAddress = address(token);
        uint256 amount = 100;

        mockPositionManager.setVault(address(vault));
        mockPositionManager.deposit(tokenAddress, amount);
        mockPositionManager.withdraw(tokenAddress, address(this), amount);

        assertEq(vault.totalAssets(tokenAddress), 0);
    }

    function test_FailDepositFromNonPositionManager() public {
        address tokenAddress = address(token);
        uint256 amount = 100;

        vm.expectRevert("Vault: FORBIDDEN");
        vault.deposit(tokenAddress, amount);
    }

    function test_FailWithdrawFromNonPositionManager() public {
        address tokenAddress = address(token);
        uint256 amount = 100;

        mockPositionManager.setVault(address(vault));
        mockPositionManager.deposit(tokenAddress, amount);

        vm.expectRevert("Vault: FORBIDDEN");
        vault.withdraw(tokenAddress, address(this), amount);
    }
}
