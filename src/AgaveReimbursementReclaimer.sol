// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {ILendingPool} from "./interfaces/ILendingPool.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {DataTypes} from "src/interfaces/DataTypes.sol";

contract AgaveReimbursementReclaimer {
    ILendingPool pool = ILendingPool(0x5E15d5E33d318dCEd84Bfe3F4EACe07909bE6d9c);
    address public DAO = 0xb4c575308221CAA398e0DD2cDEB6B2f10d7b000A;

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

    struct TransactionData {
        address to;
        bytes data;
        address asset;
        uint256 assetAmount;
    }

    function encodeTightlyPacked(bytes[] memory arr) internal pure returns (bytes memory encoded) {
        uint256 len = arr.length;
        for (uint256 i = 0; i < len; i++) {
            encoded = bytes.concat(encoded, abi.encodePacked(arr[i]));
        }
    }

    function withdrawAll() public returns (TransactionData[] memory encoded_call) {
        encoded_call = new TransactionData[](merkleContracts.length * assets.length);
        uint8 i = 0;
        for (i; i < merkleContracts.length; i++) {
            uint8 j = 0;
            for (j; j < assets.length; j++) {
                address target = merkleContracts[i];
                uint256 assetBal = IERC20(assets[j]).balanceOf(target);
                if (assetBal > 0) {
                    bytes memory callData =
                        abi.encodeWithSignature("protocolFallback(address,uint256)", assets[j], assetBal);
                    TransactionData memory call =
                        TransactionData({to: target, data: callData, asset: assets[j], assetAmount: assetBal});
                    encoded_call[((i * assets.length) + j)] = call;
                }
            }
        }
    }
}
