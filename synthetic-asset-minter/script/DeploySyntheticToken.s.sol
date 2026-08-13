// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SyntheticToken.sol";

contract DeploySyntheticToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        SyntheticToken syntheticToken = new SyntheticToken(
            "Synthetic S&P 500",
            "sSPY",
            owner
        );
        
        console.log("SyntheticToken deployed to:", address(syntheticToken));
        console.log("Owner:", owner);
        
        vm.stopBroadcast();
    }
}
