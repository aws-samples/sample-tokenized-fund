// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SyntheticMinter.sol";

contract DeploySyntheticMinter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address usdc = vm.envAddress("USDC_ADDRESS");
        address syntheticToken = vm.envAddress("SYNTHETIC_TOKEN_ADDRESS");
        address owner = vm.envAddress("OWNER_ADDRESS");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT");
        
        vm.startBroadcast(deployerPrivateKey);
        
        SyntheticMinter syntheticMinter = new SyntheticMinter(
            usdc,
            syntheticToken,
            owner,
            feeRecipient
        );
        
        console.log("SyntheticMinter deployed to:", address(syntheticMinter));
        console.log("USDC:", usdc);
        console.log("SyntheticToken:", syntheticToken);
        console.log("Owner:", owner);
        console.log("Fee Recipient:", feeRecipient);
        
        vm.stopBroadcast();
    }
}
