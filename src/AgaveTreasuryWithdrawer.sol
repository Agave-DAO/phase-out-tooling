// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {ILendingPool} from "./interfaces/ILendingPool.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {DataTypes} from "src/interfaces/DataTypes.sol";

contract AgaveTreasuryWithdrawer {
    ILendingPool pool = ILendingPool(0x5E15d5E33d318dCEd84Bfe3F4EACe07909bE6d9c);
    address public DAO = 0xb4c575308221CAA398e0DD2cDEB6B2f10d7b000A;
    address[] public agTokens;
    address[] public reserves;
    uint256 private constant UINT256_MAX =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    constructor() {
        reserves = pool.getReservesList();
        for (uint8 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory tokenData = pool.getReserveData(reserves[i]);
            agTokens.push(tokenData.aTokenAddress);
        }
    }

    function withdrawAssetOnBehalf(address reserve, address agToken, uint256 amount) public {
        uint256 balance = IERC20(agToken).balanceOf(DAO);
        uint256 available = IERC20(reserve).balanceOf(agToken);
        if (balance == 0 || available == 0 || amount == 0) return;
        uint256 val = (amount > balance) ? balance : amount;
        val = (val > available) ? available : val;
        IERC20(agToken).transferFrom(DAO, address(this), val);

        uint256 thisBalance = IERC20(agToken).balanceOf(address(this));
        pool.withdraw(reserve, thisBalance, DAO);
    }

    function withdrawMax() public {
        uint8 i = 0;
        for (i; i < reserves.length; i++) {
            withdrawAssetOnBehalf(reserves[i], agTokens[i], UINT256_MAX);
        }
    }

    function isWithdrawable() public view returns (bool) {
        uint8 i = 0;
        for (i; i < reserves.length; i++) {
            uint256 balance = IERC20(agTokens[i]).balanceOf(DAO);
            uint256 available = IERC20(reserves[i]).balanceOf(agTokens[i]);
            if (balance > 0 && available > 100000) return true;
        }
        return false;
    }
}
