// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {IStakedAgave} from "../src/interfaces/IStakedAgave.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {InitializableAdminUpgradeabilityProxy} from "src/interfaces/InitializableAdminUpgradeabilityProxy.sol";

contract StakedAgaveUpgradeTest is Test {
    event Upgraded(address indexed implementation);

    IStakedAgave public stkAGVE;
    IERC20 public   AGVE;

    address public DAO = 0xb4c575308221CAA398e0DD2cDEB6B2f10d7b000A;
    address public newImpl = 0x2e91cd1bf5AB2104633112ef35A7EB6998EC2695;
    address public proxyOwner = 0x70225281599Ba586039E7BD52736681DFf6c2Fc4;
    InitializableAdminUpgradeabilityProxy proxy = InitializableAdminUpgradeabilityProxy(payable(0x610525b415c1BFAeAB1a3fc3d85D87b92f048221));

    uint256 gnosisFork;
    string RPC_GNOSIS = vm.envString("RPC_GNOSIS");

    function setUp() public {
        gnosisFork = vm.createFork(RPC_GNOSIS);
        vm.selectFork(gnosisFork);
        stkAGVE = IStakedAgave(address(proxy));
        AGVE = IERC20(stkAGVE.REWARD_TOKEN());
    }

    function test_upgradeImplementation( )public{
        vm.expectEmit(true,true,true,true,address(proxy));
        emit Upgraded(newImpl);
        vm.prank(0x70225281599Ba586039E7BD52736681DFf6c2Fc4);
        proxy.upgradeTo(newImpl);
    }

    function test_checkImplementationValues() public{
        test_upgradeImplementation();
        assertEq(stkAGVE.COOLDOWN_SECONDS(),30);
        assertEq(stkAGVE.UNSTAKE_WINDOW(),3600);
        assertEq(stkAGVE.DISTRIBUTION_END(),1710701215);
        assertEq(stkAGVE.STAKED_TOKEN(),0x3a97704a1b25F08aa230ae53B352e2e72ef52843);
        assertEq(stkAGVE.REWARD_TOKEN(),0x3a97704a1b25F08aa230ae53B352e2e72ef52843);
        assertEq(stkAGVE.EMISSION_MANAGER(),0x70225281599Ba586039E7BD52736681DFf6c2Fc4);
    }


    function test_userClaim() public{
        test_upgradeImplementation();
        address user = 0xc44caeb7F0724A156806664d2361fD6f32a2d2C8;
        uint initialBalance = AGVE.balanceOf(user);
        uint initialUnclaimed = stkAGVE.getTotalRewardsBalance(user);
        vm.startPrank(user);
        stkAGVE.claimRewards(user, initialUnclaimed);
        assertGe(AGVE.balanceOf(user),initialBalance + initialUnclaimed);
    }

    function test_userCooldownAndRedeem() public{
        test_upgradeImplementation();
        address user = 0xc44caeb7F0724A156806664d2361fD6f32a2d2C8;
        uint initialAGVEBalance = AGVE.balanceOf(user);
        uint initialStakedBalance = IERC20(address(stkAGVE)).balanceOf(user);
        vm.warp(1710701215 - 100);
        vm.startPrank(user);
        stkAGVE.cooldown();
        uint256 cooldownUser = stkAGVE.stakersCooldowns(user);
        assertGe(cooldownUser, stkAGVE.COOLDOWN_SECONDS());

        vm.expectRevert("INSUFFICIENT_COOLDOWN");
        stkAGVE.redeem(user, initialStakedBalance);

        vm.warp(1710701215 + 500);
        
        console2.log("unclaimed before: %s", stkAGVE.getTotalRewardsBalance(user));

        vm.warp(1710701215 + 2000);
        uint unclaimed = stkAGVE.getTotalRewardsBalance(user);
        console2.log("actually claimed: %s", unclaimed);
        stkAGVE.claimRewards(user, unclaimed);
        assertEq(initialAGVEBalance + unclaimed,  AGVE.balanceOf(user), "did not claim");
        console2.log("unclaimed after: %s", stkAGVE.getTotalRewardsBalance(user));

        stkAGVE.redeem(user, initialStakedBalance);
        assertEq(initialStakedBalance + initialAGVEBalance + unclaimed,  AGVE.balanceOf(user), "did not redeem");
        console2.log("Final Balance: %s", AGVE.balanceOf(user));
    }
}
