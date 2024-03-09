// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {AgaveTreasuryWithdrawer} from "./AgaveTreasuryWithdrawer.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {DataTypes} from "src/interfaces/DataTypes.sol";

contract AgaveTreasuryRedeemer {
    AgaveTreasuryWithdrawer public withdrawer =
        AgaveTreasuryWithdrawer(0x91eD5609E5b9d6991F024570025c872382890018);
    address public DAO = 0xb4c575308221CAA398e0DD2cDEB6B2f10d7b000A;
    IERC20 AGVE = IERC20(0x3a97704a1b25F08aa230ae53B352e2e72ef52843);
    uint256 totalSupply = AGVE.totalSupply();

    uint256 private constant UINT256_MAX =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    address[] public assets = [
        0x6A023CCd1ff6F2045C3309768eAd9E68F978f6e1, // WETH
        0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb, // GNO
        0xaf204776c7245bF4147c2612BF6e5972Ee483701, // sDAI
        0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d, // WXDAI
        0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83, // USDC
        0x4ECaBa5870353805a9F068101A40E0f32ed605C6 // USDT
    ];

    event Redeemed(
        uint256 WETH,
        uint256 GNO,
        uint256 sDAI,
        uint256 WXDAI,
        uint256 USDC,
        uint256 USDT
    );

    function redeem(uint256 amount) public {
        require(amount >= 1e16, "Amount too Low to redeem");
        uint256 userSupply = AGVE.balanceOf(msg.sender);
        amount = (amount >= userSupply) ? userSupply : amount;
        require(
            AGVE.allowance(msg.sender, address(this)) >= amount,
            "Needs approval higher than Amount"
        );
        uint256 daoSupply = AGVE.balanceOf(DAO);
        uint256 circSupply = totalSupply - daoSupply;
        require(AGVE.transferFrom(msg.sender, DAO, amount), "transfer failed");
        uint256[] memory Rmed = new uint256[](6);
        uint8 i = 0;
        for (i; i < assets.length; i++) {
            uint256 bal = IERC20(assets[i]).balanceOf(DAO);
            uint256 amountToRedeem = ((bal * amount * 1e20) / circSupply) /
                1e20;
            require(
                IERC20(assets[i]).transferFrom(DAO, msg.sender, amountToRedeem),
                "transfer failed"
            );
            Rmed[i] = amountToRedeem;
        }
        emit Redeemed(Rmed[0], Rmed[1], Rmed[2], Rmed[3], Rmed[4], Rmed[5]);
    }

    function redeemAll() public {
        withdrawer.withdrawMax();
        redeem(UINT256_MAX);
    }
}
