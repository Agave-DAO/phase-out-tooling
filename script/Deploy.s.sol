// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Script.sol";
import {console2} from "forge-std/Test.sol";

// Order type
import "src/AgaveTreasuryWithdrawer.sol";
import "src/AgaveReimbursementReclaimer.sol";

contract Deploy is Script {
    function run() external {
        /*//////////////////////////////////////////////////////////////
                                KEY MANAGEMENT
        //////////////////////////////////////////////////////////////*/

        uint256 deployerPrivateKey = 0;
        string memory mnemonic = vm.envString("MNEMONIC");
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        if (bytes(mnemonic).length > 30) {
            deployerPrivateKey = vm.deriveKey(mnemonic, 0);
        } else if (privKey > 1 ether) {
            deployerPrivateKey = privKey;
        }

        /*//////////////////////////////////////////////////////////////
                                OPERATIONS
        //////////////////////////////////////////////////////////////*/

        vm.startBroadcast(deployerPrivateKey);

        // Deploy AgaveTreasuryWithdrawer
        AgaveTreasuryWithdrawer withdrawer = new AgaveTreasuryWithdrawer();
        console2.log("Deployed Treasury Withdrawer: %s", address(withdrawer));

        // Deploy AgaveReimbursementReclaimer
        AgaveReimbursementReclaimer reclaimer = new AgaveReimbursementReclaimer();
        console2.log("Deployed Reimbursement Reclaimer: %s", address(reclaimer));

        vm.stopBroadcast();
    }
}
