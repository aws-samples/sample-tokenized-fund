// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SyntheticToken.sol";
import "../src/SyntheticMinter.sol";

/// @title ConfigureMinter
/// @notice Script to configure SyntheticToken minter and SyntheticMinter feed addresses
contract ConfigureMinter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address syntheticTokenAddress = vm.envAddress("SYNTHETIC_TOKEN_ADDRESS");
        address syntheticMinterAddress = vm.envAddress("SYNTHETIC_MINTER_ADDRESS");
        address priceFeedAddress = vm.envAddress("PRICE_FEED_ADDRESS");
        address collateralMonitorAddress = vm.envAddress("COLLATERAL_MONITOR_ADDRESS");
        
        SyntheticToken syntheticToken = SyntheticToken(syntheticTokenAddress);
        SyntheticMinter syntheticMinter = SyntheticMinter(syntheticMinterAddress);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Set SyntheticMinter as the authorized minter on SyntheticToken
        console.log("Setting SyntheticMinter as minter on SyntheticToken...");
        syntheticToken.setMinter(syntheticMinterAddress);
        console.log("Minter set to:", syntheticMinterAddress);
        
        // Step 2: Configure price feed on SyntheticMinter
        console.log("Setting price feed on SyntheticMinter...");
        syntheticMinter.setPriceFeed(priceFeedAddress);
        console.log("Price feed set to:", priceFeedAddress);
        
        // Step 3: Configure collateral monitor on SyntheticMinter
        console.log("Setting collateral monitor on SyntheticMinter...");
        syntheticMinter.setCollateralMonitor(collateralMonitorAddress);
        console.log("Collateral monitor set to:", collateralMonitorAddress);
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Configuration Complete ===");
        console.log("SyntheticToken:", syntheticTokenAddress);
        console.log("SyntheticMinter:", syntheticMinterAddress);
        console.log("PriceFeed:", priceFeedAddress);
        console.log("CollateralMonitor:", collateralMonitorAddress);
    }
}
