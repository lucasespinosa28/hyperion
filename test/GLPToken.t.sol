// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/GLPToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "src/test/mocks/MockPositionManager.sol";
import "src/PositionManager.sol";

contract GLPTokenTest is Test {
    GLPToken public glpToken;
    address public positionManager;

    function setUp() public {
        glpToken = new GLPToken("GLP Token", "GLP");
        positionManager = address(new MockPositionManager());
        glpToken.transferOwnership(positionManager);
    }

    function test_Mint() public {
        address recipient = address(0x123);
        uint256 amount = 100;

        vm.prank(positionManager);
        glpToken.mint(recipient, amount);

        assertEq(glpToken.balanceOf(recipient), amount);
    }

    function test_Burn() public {
        address recipient = address(0x123);
        uint256 amount = 100;

        vm.prank(positionManager);
        glpToken.mint(recipient, amount);

        vm.prank(positionManager);
        glpToken.burnFromAccount(recipient, amount);

        assertEq(glpToken.balanceOf(recipient), 0);
    }

    function test_FailMintFromNonMinter() public {
        address recipient = address(0x123);
        uint256 amount = 100;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        glpToken.mint(recipient, amount);
    }

    function test_FailBurnFromNonMinter() public {
        address recipient = address(0x123);
        uint256 amount = 100;

        vm.prank(positionManager);
        glpToken.mint(recipient, amount);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        glpToken.burnFromAccount(recipient, amount);
    }
}
