// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/Vault.sol";

contract MockPositionManager {
    Vault public vault;

    function setVault(address _vault) public {
        vault = Vault(_vault);
    }

    function deposit(address _token, uint256 _amount) public {
        vault.deposit(_token, _amount);
    }

    function withdraw(address _token, address _recipient, uint256 _amount) public {
        vault.withdraw(_token, _recipient, _amount);
    }
}
