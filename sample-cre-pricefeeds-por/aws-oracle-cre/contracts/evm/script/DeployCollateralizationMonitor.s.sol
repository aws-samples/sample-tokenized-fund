// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/CollateralizationMonitor.sol";

contract DeployCollateralizationMonitor is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Optional: forwarder address can be set post-deploy via setForwarder(address).
        // If FORWARDER_ADDRESS is unset we deploy with address(0) and the owner
        // must call setForwarder() before onReport can succeed.
        address forwarder = vm.envOr("FORWARDER_ADDRESS", address(0));

        vm.startBroadcast(deployerPrivateKey);

        CollateralizationMonitor monitor = new CollateralizationMonitor(forwarder);

        console.log("CollateralizationMonitor deployed to:", address(monitor));
        console.log("Initial forwarder:", forwarder);
        if (forwarder == address(0)) {
            console.log("WARNING: forwarder is zero; call setForwarder() before the workflow runs.");
        }

        vm.stopBroadcast();
    }
}
