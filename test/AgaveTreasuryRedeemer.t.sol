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
    uint256 internal tSupply = 100_000 ether;

    IERC20 AGVE = IERC20(0x3a97704a1b25F08aa230ae53B352e2e72ef52843);
    ILendingPool pool = ILendingPool(0x5E15d5E33d318dCEd84Bfe3F4EACe07909bE6d9c);

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

    address internal kpk = 0x458cD345B4C05e8DF39d0A07220feb4Ec19F5e6f;
    address internal dex = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address internal hive = 0xc6c2E9EFB898A42DB4137B07b727b45e0C353d81;
    address testUser;

    function setUp() public {
        gnosisFork = vm.createFork(RPC_GNOSIS);
        vm.selectFork(gnosisFork);
        redeemer = new AgaveTreasuryRedeemer();
        DAO = 0xb4c575308221CAA398e0DD2cDEB6B2f10d7b000A;
        testUser = hive;

        for (uint8 i = 0; i < assets.length; i++) {
            vm.prank(DAO);
            IERC20(assets[i]).approve(address(redeemer), UINT256_MAX);
        }
        withdrawer = redeemer.withdrawer();
        withdrawer.withdrawMax();
        withdrawer.withdrawMax(); // twice to make sure everything is collected!
    }

    function test_RevertWhen_CallerHasNotApprovedAGVE() public {
        vm.startPrank(testUser);
        vm.expectRevert(bytes("Needs approval higher than Amount"));
        redeemer.redeemAll();
    }

    function test_RevertWhen_DAOHasNotApprovedAsset() public {
        vm.startPrank(testUser);
        vm.expectRevert(bytes("Needs approval higher than Amount"));
        redeemer.redeemAll();
    }

    function test_sequenceOfUsers() public {
        uint256 burned = AGVE.balanceOf(DAO);
        uint256[] memory preDAO = updateDAO();
        uint256[] memory preUser = userBalances(testUser);

        // testUser wallet
        uint256 testBalance = AGVE.balanceOf(testUser);
        uint256[] memory preExpRedemption = expectedRedemption(testBalance);

        // kpk wallet
        uint256 kpkBalance = AGVE.balanceOf(kpk);
        uint256[] memory kpkRedemptions = expectedRedemption(kpkBalance);

        // dex wallet - just needed large wallet with AGVE to impact circ supply
        uint256 dexBalance = AGVE.balanceOf(dex);
        uint256[] memory dexRedemption = expectedRedemption(dexBalance);

        vm.startPrank(dex);
        AGVE.approve(address(redeemer), dexBalance);
        redeemer.redeemAll();
        vm.stopPrank();

        vm.startPrank(kpk);
        AGVE.approve(address(redeemer), kpkBalance);
        redeemer.redeemAll();
        vm.stopPrank();

        uint256[] memory postDAO = updateDAO();
        uint256[] memory postUser = userBalances(testUser);
        uint256[] memory postExpRedemption = expectedRedemption(testBalance);

        for (uint8 i = 0; i < assets.length; i++) {
            assertEq(postUser[i], preUser[i], '1');
            assertApproxEqAbs(preDAO[i] - postDAO[i], kpkRedemptions[i] + dexRedemption[i], 1, '2');
            assertApproxEqAbs(postExpRedemption[i], preExpRedemption[i], 1, '3');
        }
        assertEq(kpkBalance + dexBalance, AGVE.balanceOf(DAO) - burned, '4');
        assertEq(AGVE.balanceOf(kpk),0, '5');
        assertEq(AGVE.balanceOf(dex),0, '6');
    }

    function test_maxRedeem() public {
        uint256 burned = AGVE.balanceOf(DAO);
        uint256 userBalance = AGVE.balanceOf(testUser);
        uint256[] memory preDAO = updateDAO();
        uint256[] memory preUser = userBalances(testUser);
        uint256[] memory preExpRedemptions = expectedRedemption(userBalance);

        vm.startPrank(testUser);
        AGVE.approve(address(redeemer), userBalance);
        redeemer.redeemAll();
        vm.stopPrank();

        uint256[] memory postDAO = updateDAO();
        uint256[] memory postUser = userBalances(testUser);
        uint256[] memory postExpRedemption = expectedRedemption(userBalance);

        for (uint8 i = 0; i < assets.length; i++) {
            assertEq(postUser[i] - preUser[i], preExpRedemptions[i]);
            assertEq(userBalance, AGVE.balanceOf(DAO) - burned);
            assertEq(preDAO[i] - postDAO[i], preExpRedemptions[i]);
            assertApproxEqAbs(preExpRedemptions[i], postExpRedemption[i], 10);
        }
        assertEq(AGVE.balanceOf(testUser), 0);
    }

    function test_minRedeem() public {
        uint256 burned = AGVE.balanceOf(DAO);
        uint256 minAmount = 1e16;
        uint256[] memory preDAO = updateDAO();
        uint256[] memory preUser = userBalances(testUser);
        uint256[] memory expRedemptions = expectedRedemption(minAmount);

        vm.startPrank(testUser);
        AGVE.approve(address(redeemer), minAmount);
        redeemer.redeem(minAmount);
        vm.stopPrank();

        uint256[] memory postDAO = updateDAO();
        uint256[] memory postUser = userBalances(testUser);

        for (uint8 i = 0; i < assets.length; i++) {
            assertEq(postUser[i] - preUser[i], expRedemptions[i]);
            assertEq(minAmount, AGVE.balanceOf(DAO) - burned);
            assertEq(preDAO[i] - postDAO[i], expRedemptions[i]);
        }
    }

    function test_redeemAmount(uint256 amount) public {
        uint256 burned = AGVE.balanceOf(DAO);
        uint256[] memory preDAO = updateDAO();
        vm.startPrank(testUser);
        uint256 userBalance = AGVE.balanceOf(testUser);
        AGVE.approve(address(redeemer), userBalance);
        uint256[] memory preUser = userBalances(testUser);

        if (amount >= userBalance) {
            uint256[] memory expRedemptions = expectedRedemption(userBalance);
            redeemer.redeem(amount);
            uint256[] memory postDAO = updateDAO();
            uint256[] memory postUser = userBalances(testUser);
            assertEq(0, AGVE.balanceOf(testUser));
            for (uint8 i = 0; i < assets.length; i++) {
                assertApproxEqAbs(postUser[i] - preUser[i], expRedemptions[i], 10);
                assertApproxEqAbs(preDAO[i] - postDAO[i], expRedemptions[i], 10);
                assertApproxEqAbs(userBalance, AGVE.balanceOf(DAO) - burned, 10);
            }
        } else if (amount >= 1e16) {
            uint256[] memory expRedemptions = expectedRedemption(amount);
            redeemer.redeem(amount);
            uint256[] memory postDAO = updateDAO();
            uint256[] memory postUser = userBalances(testUser);
            assertApproxEqAbs(AGVE.balanceOf(testUser), userBalance - amount, 10);
            for (uint8 i = 0; i < assets.length; i++) {
                assertApproxEqAbs(postUser[i] - preUser[i], expRedemptions[i], 10);
                assertApproxEqAbs(amount, AGVE.balanceOf(DAO) - burned, 10);
                assertApproxEqAbs(preDAO[i] - postDAO[i], expRedemptions[i], 10);
            }
        } else {
            vm.expectRevert(bytes("Amount too Low to redeem"));
            redeemer.redeem(amount);
        }
    }

    function userBalances(address user) public view returns (uint256[] memory user_balances) {
        user_balances = new uint[](6);
        for (uint8 i = 0; i < assets.length; i++) {
            user_balances[i] = IERC20(assets[i]).balanceOf(user);
        }
    }

    function updateDAO() public view returns (uint256[] memory dao_balances) {
        dao_balances = new uint[](6);
        for (uint8 i = 0; i < assets.length; i++) {
            dao_balances[i] = IERC20(assets[i]).balanceOf(DAO);
        }
    }

    function expectedRedemption(uint256 redeemedAmount) public view returns (uint256[] memory redemption_values) {
        uint256 daoSupply = AGVE.balanceOf(DAO);
        uint256 cSupply = tSupply - daoSupply;
        redemption_values = new uint[](6);
        uint256[] memory daoAssets = userBalances(DAO);
        for (uint8 i = 0; i < assets.length; i++) {
            uint256 amountToRedeem = ((daoAssets[i] * redeemedAmount * 1e20) / cSupply) / 1e20;
            redemption_values[i] = amountToRedeem;
        }
    }
}
