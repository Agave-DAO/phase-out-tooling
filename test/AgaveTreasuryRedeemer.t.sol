// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {AgaveTreasuryWithdrawer} from "../src/AgaveTreasuryWithdrawer.sol";
import {AgaveTreasuryRedeemer} from "../src/AgaveTreasuryRedeemer.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {ILendingPool} from "src/interfaces/ILendingPool.sol";
import {DataTypes} from "src/interfaces/DataTypes.sol";

contract AgaveTreasuryRedeemerTest is Test {
    AgaveTreasuryWithdrawer public withdrawer;
    AgaveTreasuryRedeemer public redeemer;
    address public DAO;

    IERC20 AGVE = IERC20(0x3a97704a1b25F08aa230ae53B352e2e72ef52843);
    ILendingPool pool =
        ILendingPool(0x5E15d5E33d318dCEd84Bfe3F4EACe07909bE6d9c);

    address[] public assets = [
        0x6A023CCd1ff6F2045C3309768eAd9E68F978f6e1, // WETH
        0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb, // GNO
        0xaf204776c7245bF4147c2612BF6e5972Ee483701, // sDAI
        0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d, // WXDAI
        0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83, // USDC
        0x4ECaBa5870353805a9F068101A40E0f32ed605C6 // USDT
    ];

    uint256 gnosisFork;
    string RPC_GNOSIS = vm.envString("RPC_GNOSIS");

    address testUser = 0x458cD345B4C05e8DF39d0A07220feb4Ec19F5e6f;

    function setUp() public {
        gnosisFork = vm.createFork(RPC_GNOSIS);
        vm.selectFork(gnosisFork);
        redeemer = new AgaveTreasuryRedeemer();
        DAO = redeemer.DAO();

        for (uint8 i = 0; i < assets.length; i++) {
            vm.prank(DAO);
            IERC20(assets[i]).approve(address(redeemer), UINT256_MAX);
        }
    }


    function test_RevertWhen_CallerHasNotApprovedAGVE() public{
        vm.startPrank(testUser);
        vm.expectRevert(bytes("Needs approval higher than Amount"));
        redeemer.redeemAll();
    }

    function test_maxRedeem() public{
        vm.startPrank(testUser);
        uint userBalance = AGVE.balanceOf(testUser);
        AGVE.approve(address(redeemer), userBalance);
        redeemer.redeemAll();
    }

    function test_redeemAmount(uint256 amount) public {
        vm.startPrank(testUser);
        uint userBalance = AGVE.balanceOf(testUser);
        AGVE.approve(address(redeemer), userBalance);

        if (amount >= userBalance){
      //      vm.expectEmit(address(redeemer));
        //    emit Redeemed(Rmed[0], Rmed[1], Rmed[2], Rmed[3], Rmed[4], Rmed[5]); 
            redeemer.redeem(amount);
            assertEq(0, AGVE.balanceOf(testUser));

        }
        else if (amount > 1e12){
            redeemer.redeem(amount);
            assertEq(userBalance - amount, AGVE.balanceOf(testUser));
        }
        else {
            vm.expectRevert(bytes("Amount too Low to redeem"));
            redeemer.redeem(amount);
        }
    }
}
