// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/console2.sol";
import {AgaveReimbursementReclaimer} from "../src/AgaveReimbursementReclaimer.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {ILendingPool} from "src/interfaces/ILendingPool.sol";
import {DataTypes} from "src/interfaces/DataTypes.sol";

contract AgaveReimbursementReclaimerTest is Test {
    AgaveReimbursementReclaimer public withdrawer;
    address public DAO;
    uint256 gnosisFork;
    string RPC_GNOSIS = vm.envString("RPC_GNOSIS");

    address[] public merkleContracts = [
        0xB77d3295f5D62328C403043E3a6f0baB125A465b,
        0xc21a7B1e58356892F606beE801A00C7bAD72edF7,
        0x6Ce74a957a7520Affdf07FBc3b5563F8b81CCaCC,
        0xb88d66e7721a20b58E7d18D81cdB9682307399bA,
        0x15B7bD2686650eAdB6fEB1BE6e9134C1f9241a95
    ];
    address[] public assets = [
        0x291B5957c9CBe9Ca6f0b98281594b4eB495F4ec1,
        0x44932e3b1E662AdDE2F7bac6D5081C5adab908c6,
        0xA26783eAd6C1f4744685c14079950622674ae8A8,
        0xa286Ce70FB3a6269676c8d99BD9860DE212252Ef,
        0xE2e73A1c69ecF83F464EFCE6A5be353a37cA09b2,
        0xd4e420bBf00b0F409188b338c5D87Df761d6C894,
        0x4863cfaF3392F20531aa72CE19E5783f489817d6,
        0x388Cae2f7d3704C937313d990298Ba67D70a3709,
        0x870Bb2C024513B5c9A69894dCc65fB5c47e422f3
    ];

    function setUp() public {
        gnosisFork = vm.createFork(RPC_GNOSIS);
        vm.selectFork(gnosisFork);
        withdrawer = new AgaveReimbursementReclaimer();
        DAO = withdrawer.DAO();
    }
    /*
    function test_withdrawAll() public {
        uint8 i = 0;
        vm.startPrank(DAO);
        for (i; i < merkleContracts.length; i++) {
            uint8 j = 0;
            for (j; j < assets.length; j++) {
                address target = merkleContracts[i];
                uint256 assetBal = IERC20(assets[j]).balanceOf(target);
                if (assetBal > 0) {
                    (bool success, ) = target.call(
                        abi.encodeWithSignature(
                            "protocolFallback(address,uint256)",
                            assets[j],
                            assetBal
                        )
                    );
                    require(success, "transfer failed");
                }
                assertEq(IERC20(assets[j]).balanceOf(target), 0);
            }
        }
    }
    */

    function _test_withdrawAll_Snapshot() public {
        vm.startPrank(DAO);
        AgaveReimbursementReclaimer.TransactionData[] memory call = withdrawer.withdrawAll();

        console2.log("[");
        for (uint256 i = 0; i < call.length; i++) {
            string memory data = vm.toString(call[i].data);
            address merkle = call[i].to;
            address asset = call[i].asset;
            uint256 amount = call[i].assetAmount;
            if (amount > 0) {
                console2.log("{");
                console2.log('"to": "%s",', merkle);
                console2.log('"operation": "0",');
                console2.log('"value": "0.0",');
                console2.log('"data": "%s",', data);
                console2.log('"method": "protocolFallback(address,uint256)",');
                console2.log('"params": ["%s", "%s"]', asset, amount);
                console2.log("},");
            }
        }
        console2.log("]");
    }

    function _test_withdrawAll_Safe() public {
        vm.startPrank(DAO);
        AgaveReimbursementReclaimer.TransactionData[] memory call = withdrawer.withdrawAll();

        console2.log("[");
        for (uint256 i = 0; i < call.length; i++) {
            string memory data = vm.toString(call[i].data);
            address merkle = call[i].to;
            address asset = call[i].asset;
            uint256 amount = call[i].assetAmount;
            if (amount > 0) {
                console2.log('{"to": "%s",', merkle);
                console2.log('"value": "0","data": null,');
                console2.log(
                    '"contractMethod":{"inputs":[{"internalType":"contractIERC20","name":"token","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],'
                );
                console2.log('"name":"protocolFallback","payable":false},"contractInputsValues":{');
                console2.log('"token": "%s",', asset);
                console2.log('"amount": "%s"', amount);
                console2.log("}},");
            }
        }
        console2.log("]");
    }
}
