// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {AgaveTreasuryWithdrawer} from "../src/AgaveTreasuryWithdrawer.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {ILendingPool} from "src/interfaces/ILendingPool.sol";
import {DataTypes} from "src/interfaces/DataTypes.sol";

contract AgaveTreasuryWithdrawerTest is Test {
    AgaveTreasuryWithdrawer public withdrawer;
    address public DAO;

    ILendingPool pool =
        ILendingPool(0x5E15d5E33d318dCEd84Bfe3F4EACe07909bE6d9c);

    address[] public reserves;
    address[] public agTokens;
    uint256 gnosisFork;
    string RPC_GNOSIS = vm.envString("RPC_GNOSIS");

    function setUp() public {
        gnosisFork = vm.createFork(RPC_GNOSIS);
        vm.selectFork(gnosisFork);
        withdrawer = new AgaveTreasuryWithdrawer();
        DAO = withdrawer.DAO();
        reserves = pool.getReservesList();

        for (uint8 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory tokenData = pool.getReserveData(reserves[i]);    
            agTokens.push(tokenData.aTokenAddress); 
            vm.prank(DAO);
            IERC20(agTokens[i]).approve(address(withdrawer), UINT256_MAX);
        }
    }

    function test_maxWithdraw() public{
        withdrawer.withdrawMax();
    }

    function test_withdrawAmount(uint256 amount, uint8 i) public {
        vm.assume(i < reserves.length);
        uint256 balance1 = IERC20(agTokens[i]).balanceOf(DAO);
        uint256 owned1 = IERC20(reserves[i]).balanceOf(DAO);
        uint256 available1 = IERC20(reserves[i]).balanceOf(agTokens[i]);
        withdrawer.withdrawAssetOnBehalf(reserves[i], agTokens[i], amount);
        uint256 balance2 = IERC20(agTokens[i]).balanceOf(DAO);
        uint256 owned2 = IERC20(reserves[i]).balanceOf(DAO);
        uint256 available2 = IERC20(reserves[i]).balanceOf(agTokens[i]);

        uint256 withdrawn = (amount > available1) ? available1 : amount;
        withdrawn = (withdrawn > balance1) ? balance1 : withdrawn;

        console2.log(amount, withdrawn);
        console2.log("%s %s", balance1, balance2);
        console2.log("%s %s", owned1, owned2);
        assertApproxEqAbs(owned2, owned1 + withdrawn, 100);
        assertApproxEqAbs(available2, available1 - withdrawn, 100);
    }

    function test_isWithdrawable()public{
        getData();
        bool isok = withdrawer.isWithdrawable();
        test_maxWithdraw();
        assertTrue(isok);
        test_maxWithdraw();
        bool isnot = withdrawer.isWithdrawable();
        getData();
        assertFalse(isnot);
        
    }

    function getData() view public {
        for (uint8 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory tokenData = pool.getReserveData(reserves[i]);    
            uint256 balance = IERC20(agTokens[i]).balanceOf(DAO);
            uint256 available = IERC20(reserves[i]).balanceOf(agTokens[i]);
            console2.log(reserves[i]);
            console2.log("bal: %s ava: %s liquidity: %s", balance, available, tokenData.currentLiquidityRate);
        }
    }
}
