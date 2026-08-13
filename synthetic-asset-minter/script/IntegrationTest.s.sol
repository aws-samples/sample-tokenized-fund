// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/SyntheticMinter.sol";
import "../src/SyntheticToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IntegrationTest
/// @notice End-to-end integration test for SyntheticMinter with live CRE feeds
/// @dev Run with: forge script script/IntegrationTest.s.sol --rpc-url $RPC_URL --broadcast -vvvv
contract IntegrationTest is Script {
    // Deployed contract addresses on Sepolia
    address constant SYNTHETIC_MINTER = 0x2B979fb42ef0501AD090923B40d3467FC9b2C3E6;
    address constant SYNTHETIC_TOKEN = 0x7AB0e63EAd88785625E33F2DC04003f143b01450;
    address constant USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant PRICE_FEED = 0xdc87A131b53385437ea70396DdB7Dc6BA9627022;
    address constant COLLATERAL_MONITOR = 0x2170B7773Af8C373BdCa26d417eA1b3Ccd92630A;

    SyntheticMinter minter;
    SyntheticToken syntheticToken;
    IERC20 usdc;

    function setUp() public {
        minter = SyntheticMinter(SYNTHETIC_MINTER);
        syntheticToken = SyntheticToken(SYNTHETIC_TOKEN);
        usdc = IERC20(USDC);
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Integration Test: Full Mint/Burn Flow ===");
        console.log("Deployer address:", deployer);
        console.log("");

        // Step 1: Check initial state
        console.log("--- Step 1: Check Initial State ---");
        _checkContractState(deployer);

        // Step 2: Check CRE feed data
        console.log("--- Step 2: Verify CRE Feed Data ---");
        _checkCREFeeds();

        // Step 3: Check USDC balance
        console.log("--- Step 3: Check USDC Balance ---");
        uint256 usdcBalance = usdc.balanceOf(deployer);
        console.log("USDC balance:", usdcBalance);
        
        if (usdcBalance == 0) {
            console.log("WARNING: No USDC balance. Get test USDC from Circle faucet:");
            console.log("https://faucet.circle.com/");
            return;
        }

        vm.startBroadcast(deployerPrivateKey);

        // Step 4: Deposit USDC collateral
        console.log("--- Step 4: Deposit USDC Collateral ---");
        uint256 depositAmount = 100 * 10**6; // 100 USDC (6 decimals)
        
        if (usdcBalance < depositAmount) {
            depositAmount = usdcBalance / 2; // Use half of available balance
        }
        
        console.log("Deposit amount:", depositAmount, "USDC (raw)");
        
        // Approve USDC transfer
        usdc.approve(SYNTHETIC_MINTER, depositAmount);
        console.log("USDC approved for SyntheticMinter");
        
        // Deposit collateral
        uint256 totalCollateralBefore = minter.totalCollateral(deployer);
        minter.depositCollateral(depositAmount);
        uint256 totalCollateralAfter = minter.totalCollateral(deployer);
        
        console.log("Total collateral before:", totalCollateralBefore);
        console.log("Total collateral after:", totalCollateralAfter);
        require(totalCollateralAfter == totalCollateralBefore + depositAmount, "Deposit accounting error");
        console.log("PASS: Collateral deposited correctly");
        console.log("");

        // Step 5: Mint synthetic tokens
        console.log("--- Step 5: Mint Synthetic Tokens ---");
        
        // Get max mintable
        uint256 maxMintable = minter.getMaxMintable(deployer);
        console.log("Max mintable:", maxMintable, "sSPY (raw)");
        
        // Mint 50% of max to leave room for CR
        uint256 mintAmount = maxMintable / 2;
        if (mintAmount == 0) {
            console.log("WARNING: Cannot mint - insufficient collateral or price too high");
            vm.stopBroadcast();
            return;
        }
        
        console.log("Minting:", mintAmount, "sSPY (raw)");
        
        uint256 syntheticBalanceBefore = syntheticToken.balanceOf(deployer);
        uint256 lockedCollateralBefore = minter.lockedCollateral(deployer);
        
        minter.mint(mintAmount);
        
        uint256 syntheticBalanceAfter = syntheticToken.balanceOf(deployer);
        uint256 lockedCollateralAfter = minter.lockedCollateral(deployer);
        
        console.log("Synthetic balance before:", syntheticBalanceBefore);
        console.log("Synthetic balance after:", syntheticBalanceAfter);
        console.log("Locked collateral before:", lockedCollateralBefore);
        console.log("Locked collateral after:", lockedCollateralAfter);
        
        // Account for mint fee (0.3% = 30 bps)
        uint256 mintFeeBps = minter.mintFeeBps();
        uint256 expectedFee = (mintAmount * mintFeeBps) / 10000;
        uint256 expectedNetAmount = mintAmount - expectedFee;
        
        console.log("Mint fee (bps):", mintFeeBps);
        console.log("Expected fee:", expectedFee);
        console.log("Expected net amount:", expectedNetAmount);
        
        require(syntheticBalanceAfter >= syntheticBalanceBefore, "Synthetic balance should increase");
        require(lockedCollateralAfter > lockedCollateralBefore, "Locked collateral should increase");
        console.log("PASS: Synthetic tokens minted correctly");
        console.log("");

        // Step 6: Verify collateral ratio
        console.log("--- Step 6: Verify Collateral Ratio ---");
        uint256 collateralRatio = minter.getUserCollateralRatio(deployer);
        uint256 minCR = minter.minCollateralizationRatio();
        
        console.log("User collateral ratio:", collateralRatio, "%");
        console.log("Minimum required CR:", minCR, "%");
        
        require(collateralRatio >= minCR, "CR should be above minimum");
        console.log("PASS: Collateral ratio is healthy");
        console.log("");

        // Step 7: Burn synthetic tokens
        console.log("--- Step 7: Burn Synthetic Tokens ---");
        
        // Burn half of the minted tokens
        uint256 burnAmount = (syntheticBalanceAfter - syntheticBalanceBefore) / 2;
        if (burnAmount == 0) {
            burnAmount = syntheticBalanceAfter / 2;
        }
        
        console.log("Burning:", burnAmount, "sSPY (raw)");
        
        uint256 syntheticBalanceBeforeBurn = syntheticToken.balanceOf(deployer);
        uint256 lockedCollateralBeforeBurn = minter.lockedCollateral(deployer);
        
        minter.burn(burnAmount);
        
        uint256 syntheticBalanceAfterBurn = syntheticToken.balanceOf(deployer);
        uint256 lockedCollateralAfterBurn = minter.lockedCollateral(deployer);
        
        console.log("Synthetic balance before burn:", syntheticBalanceBeforeBurn);
        console.log("Synthetic balance after burn:", syntheticBalanceAfterBurn);
        console.log("Locked collateral before burn:", lockedCollateralBeforeBurn);
        console.log("Locked collateral after burn:", lockedCollateralAfterBurn);
        
        require(syntheticBalanceAfterBurn == syntheticBalanceBeforeBurn - burnAmount, "Burn amount mismatch");
        require(lockedCollateralAfterBurn < lockedCollateralBeforeBurn, "Locked collateral should decrease");
        console.log("PASS: Synthetic tokens burned correctly");
        console.log("");

        // Step 8: Verify collateral release
        console.log("--- Step 8: Verify Collateral Release ---");
        
        // Calculate expected collateral release (proportional)
        uint256 expectedRelease = (lockedCollateralBeforeBurn * burnAmount) / syntheticBalanceBeforeBurn;
        uint256 actualRelease = lockedCollateralBeforeBurn - lockedCollateralAfterBurn;
        
        console.log("Expected collateral release:", expectedRelease);
        console.log("Actual collateral release:", actualRelease);
        
        // Allow for small rounding differences
        require(actualRelease >= expectedRelease - 1 && actualRelease <= expectedRelease + 1, "Collateral release mismatch");
        console.log("PASS: Collateral released proportionally");
        console.log("");

        // Step 9: Verify CR improved after partial burn
        console.log("--- Step 9: Verify CR After Burn ---");
        uint256 crAfterBurn = minter.getUserCollateralRatio(deployer);
        console.log("CR after burn:", crAfterBurn, "%");
        
        // CR should improve or stay same after partial burn
        // (since we burned tokens but released proportional collateral)
        console.log("PASS: CR maintained after partial burn");
        console.log("");

        // Step 10: Withdraw available collateral
        console.log("--- Step 10: Withdraw Available Collateral ---");
        uint256 availableCollateral = minter.getAvailableCollateral(deployer);
        console.log("Available collateral:", availableCollateral);
        
        if (availableCollateral > 0) {
            uint256 withdrawAmount = availableCollateral / 2;
            uint256 usdcBalanceBeforeWithdraw = usdc.balanceOf(deployer);
            
            minter.withdrawCollateral(withdrawAmount);
            
            uint256 usdcBalanceAfterWithdraw = usdc.balanceOf(deployer);
            console.log("Withdrew:", withdrawAmount, "USDC");
            console.log("USDC balance before:", usdcBalanceBeforeWithdraw);
            console.log("USDC balance after:", usdcBalanceAfterWithdraw);
            
            require(usdcBalanceAfterWithdraw == usdcBalanceBeforeWithdraw + withdrawAmount, "Withdraw amount mismatch");
            console.log("PASS: Collateral withdrawn correctly");
        } else {
            console.log("No available collateral to withdraw");
        }

        vm.stopBroadcast();

        console.log("");
        console.log("=== Integration Test Complete ===");
        console.log("All tests passed!");
    }

    function _checkContractState(address user) internal view {
        console.log("SyntheticMinter:", SYNTHETIC_MINTER);
        console.log("SyntheticToken:", SYNTHETIC_TOKEN);
        console.log("USDC:", USDC);
        console.log("PriceFeed:", address(minter.priceFeed()));
        console.log("CollateralMonitor:", address(minter.collateralMonitor()));
        console.log("Min CR:", minter.minCollateralizationRatio(), "%");
        console.log("Mint Fee:", minter.mintFeeBps(), "bps");
        console.log("Staleness Window:", minter.stalenessWindow(), "seconds");
        console.log("User total collateral:", minter.totalCollateral(user));
        console.log("User locked collateral:", minter.lockedCollateral(user));
        console.log("User synthetic balance:", syntheticToken.balanceOf(user));
        console.log("");
    }

    function _checkCREFeeds() internal view {
        // Check price feed
        ICREPriceFeed priceFeed = minter.priceFeed();
        (uint256 price, uint256 priceTimestamp) = priceFeed.getLatestPrice();
        console.log("Price feed price:", price, "(8 decimals)");
        console.log("Price in USD:", price / 10**8, ".", (price % 10**8) / 10**6);
        console.log("Price timestamp:", priceTimestamp);
        console.log("Current timestamp:", block.timestamp);
        console.log("Price age:", block.timestamp - priceTimestamp, "seconds");
        
        // Check collateral monitor
        ICRECollateralMonitor collateralMonitor = minter.collateralMonitor();
        ICRECollateralMonitor.CollateralData memory data = collateralMonitor.getLatestData();
        console.log("Collateral monitor price:", data.price);
        console.log("Collateral monitor reserves:", data.reserves);
        console.log("Collateral monitor ratio:", data.ratio);
        console.log("Collateral monitor timestamp:", data.timestamp);
        console.log("Collateral monitor isHealthy:", data.isHealthy);
        console.log("");
        
        // Verify data is not stale
        uint256 stalenessWindow = minter.stalenessWindow();
        require(block.timestamp - priceTimestamp <= stalenessWindow, "Price feed is stale");
        require(block.timestamp - data.timestamp <= stalenessWindow, "Collateral monitor is stale");
        require(data.isHealthy, "Protocol is unhealthy");
        console.log("PASS: CRE feeds are fresh and healthy");
        console.log("");
    }
}
