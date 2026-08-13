// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/PriceFeed.sol";

contract DeployPriceFeed is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Optional: forwarder address can be set post-deploy via setForwarder(address).
        // If FORWARDER_ADDRESS is unset we deploy with address(0) and the owner
        // must call setForwarder() before onReport can succeed.
        address forwarder = vm.envOr("FORWARDER_ADDRESS", address(0));

        vm.startBroadcast(deployerPrivateKey);

        PriceFeed priceFeed = new PriceFeed(forwarder);

        console.log("PriceFeed deployed to:", address(priceFeed));
        console.log("Initial forwarder:", forwarder);
        if (forwarder == address(0)) {
            console.log("WARNING: forwarder is zero; call setForwarder() before the workflow runs.");
        }

        vm.stopBroadcast();
    }
}
