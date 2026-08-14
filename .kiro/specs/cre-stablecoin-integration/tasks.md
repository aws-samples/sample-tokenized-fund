# Implementation Plan: Synthetic Asset Minter with CRE Integration

## Overview

This plan implements a Synthetic Asset Minter that allows users to deposit USDC and mint synthetic ETF tokens (sSPY) using CRE oracle feeds for real-time stock prices. The architecture includes:
- Lambda function to fetch stock prices from public APIs
- CRE workflow that reads stock prices from Lambda AND on-chain collateral state
- Solidity contracts for the synthetic minter

## Tasks

- [x] 1. Create Lambda handler for stock price fetching
  - [x] 1.1 Create `getStockPrice.ts` handler in `price-feed-por-dynamodb-crud/src/handlers/`
    - Fetch SPY stock price from Alpha Vantage or Finnhub API
    - Parse response to extract price and timestamp
    - Store in DynamoDB with asset type "STOCK_SPY"
    - Return latest price via API response
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [x] 1.2 Add stock price types to `src/types/index.ts`
    - Add `StockPriceRecord` interface
    - Add `StockPriceResponse` interface
    - _Requirements: 1.1_

  - [x] 1.3 Update `template.yaml` with new Lambda and API Gateway endpoint
    - Add `GetStockPriceFunction` Lambda resource
    - Add `/stock-price/latest` GET endpoint
    - Add environment variable for stock API key
    - _Requirements: 1.3, 1.6_

  - [x] 1.4 Write unit tests for stock price handler
    - Test successful price fetch and storage
    - Test error handling for API failures
    - Test validation of positive prices
    - _Requirements: 1.4, 1.5_

- [x] 2. Update CRE workflow to read on-chain state
  - [x] 2.1 Add on-chain read functions to `main.go`
    - Add `readCollateralValue()` to call `SyntheticMinter.getCollateralValue()`
    - Add `readTotalSupply()` to call `SyntheticToken.totalSupply()`
    - Use CRE EVM client for on-chain reads
    - _Requirements: 2.2, 2.3_

  - [x] 2.2 Update `fetchAssetData()` to use Lambda stock price endpoint
    - Change API URL to point to stock price endpoint
    - Parse stock price response
    - _Requirements: 2.1_

  - [x] 2.3 Update collateral ratio calculation
    - Calculate ratio from on-chain collateral value, total supply, and stock price
    - Determine `isHealthy` based on configured threshold
    - _Requirements: 2.4, 2.5_

  - [x] 2.4 Update `config.staging.json` with new configuration
    - Add `stockPriceApiUrl` pointing to Lambda endpoint
    - Add `syntheticMinterAddress` for on-chain reads
    - Add `syntheticTokenAddress` for on-chain reads
    - _Requirements: 2.1, 2.2, 2.3_

  - [x] 2.5 Generate Go bindings for SyntheticMinter and SyntheticToken
    - Run `cre generate-bindings evm` after contracts are deployed
    - Import generated bindings in `main.go`
    - _Requirements: 2.2, 2.3_

- [x] 3. Set up Solidity project structure and interfaces
  - Create `synthetic-asset-minter/` directory at workspace root
  - Initialize Foundry project with `forge init --no-commit`
  - Install OpenZeppelin contracts: `forge install OpenZeppelin/openzeppelin-contracts --no-commit`
  - Create `src/interfaces/ICREPriceFeed.sol` with `getLatestPrice()` signature
  - Create `src/interfaces/ICRECollateralMonitor.sol` with `getLatestData()` and `CollateralData` struct
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 4. Implement SyntheticToken contract
  - [x] 4.1 Create `src/SyntheticToken.sol` extending OpenZeppelin ERC20 and Ownable
    - Add `minter` address state variable
    - Implement `setMinter(address)` callable only by owner
    - Implement `mint(address to, uint256 amount)` callable only by minter
    - Implement `burn(address from, uint256 amount)` callable only by minter
    - Constructor takes name, symbol, and initial owner
    - _Requirements: 7.6, 8.4_

  - [x] 4.2 Write unit tests for SyntheticToken
    - Test minter-only access for mint/burn
    - Test owner-only access for setMinter
    - Test standard ERC20 functionality
    - _Requirements: 7.6, 8.4_

- [x] 5. Implement SyntheticMinter core structure
  - [x] 5.1 Create `src/SyntheticMinter.sol` with inheritance and state variables
    - Inherit from Ownable, Pausable, ReentrancyGuard
    - Declare feed interfaces: `ICREPriceFeed priceFeed`, `ICRECollateralMonitor collateralMonitor`
    - Declare tokens: `IERC20 immutable usdc`, `SyntheticToken immutable syntheticToken`
    - Declare risk params: `minCollateralizationRatio`, `mintFeeBps`, `stalenessWindow`
    - Declare user mappings: `totalCollateral`, `lockedCollateral`
    - Declare fee state: `feeRecipient`, `accumulatedFees`
    - Declare constants: `PRICE_DECIMALS`, `USDC_DECIMALS`, `SYNTHETIC_DECIMALS`, `BPS_DENOMINATOR`
    - Add `getCollateralValue()` view function for CRE to read
    - _Requirements: 6.1, 6.2, 6.3_

  - [x] 5.2 Implement constructor and admin setters
    - Constructor takes USDC address, SyntheticToken address, initial owner, fee recipient
    - Implement `setPriceFeed(address)` with zero-address check and event
    - Implement `setCollateralMonitor(address)` with zero-address check and event
    - Implement `setMinCollateralizationRatio(uint256)` with event
    - Implement `setMintFeeBps(uint256)` with max 1000 check and event
    - Implement `setStalenessWindow(uint256)` with event
    - Implement `setFeeRecipient(address)` with zero-address check
    - All setters owner-only
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 6.4, 6.5_

  - [x] 5.3 Write property test for owner-only access control
    - **Property 4: Owner-Only Access Control**
    - Fuzz test: for any non-owner address, all admin functions revert
    - **Validates: Requirements 5.1, 5.2, 6.5, 10.1**

- [x] 6. Implement feed validation helpers
  - [x] 6.1 Create internal `_validatePriceFeed()` function
    - Check `address(priceFeed) != address(0)`, revert "Feed not set"
    - Call `priceFeed.getLatestPrice()` to get price and timestamp
    - Check `price > 0`, revert "Invalid price"
    - Check `block.timestamp - timestamp <= stalenessWindow`, revert "Price feed stale"
    - Return validated price
    - _Requirements: 3.4, 7.1, 7.3_

  - [x] 6.2 Create internal `_validateCollateralMonitor()` function
    - Check `address(collateralMonitor) != address(0)`, revert "Feed not set"
    - Call `collateralMonitor.getLatestData()` to get CollateralData
    - Check `block.timestamp - data.timestamp <= stalenessWindow`, revert "Collateral feed stale"
    - Check `data.isHealthy == true`, revert "Protocol unhealthy"
    - Return validated data
    - _Requirements: 3.4, 7.2, 7.4_

  - [x] 6.3 Write property test for staleness validation
    - **Property 5: Staleness Check Rejects Old Data**
    - Fuzz test: for any timestamp where `block.timestamp - timestamp > stalenessWindow`, operations revert
    - **Validates: Requirements 7.1, 7.2**

  - [x] 6.4 Write property test for unhealthy protocol
    - **Property 6: Unhealthy Protocol Blocks Operations**
    - Test: when `isHealthy = false`, mint reverts with "Protocol unhealthy"
    - **Validates: Requirements 7.4**

- [x] 7. Implement collateral deposit and withdraw
  - [x] 7.1 Implement `depositCollateral(uint256 amount)` function
    - Add `nonReentrant` and `whenNotPaused` modifiers
    - Require `amount > 0`
    - Call `usdc.transferFrom(msg.sender, address(this), amount)`
    - Increment `totalCollateral[msg.sender] += amount`
    - Get current price for event (handle if feed not set yet)
    - Emit `CollateralDeposited(msg.sender, amount, priceAtDeposit)`
    - _Requirements: 4.1, 4.2, 4.3, 4.5_

  - [x] 7.2 Implement `withdrawCollateral(uint256 amount)` function
    - Add `nonReentrant` modifier (NO whenNotPaused - allowed while paused)
    - Calculate `available = totalCollateral[msg.sender] - lockedCollateral[msg.sender]`
    - Require `amount <= available`, revert "Insufficient available collateral"
    - Decrement `totalCollateral[msg.sender] -= amount`
    - Call `usdc.transfer(msg.sender, amount)`
    - Emit `CollateralWithdrawn(msg.sender, amount)`
    - _Requirements: 4.6, 10.5_

  - [x] 7.3 Write property test for deposit accounting
    - **Property 1: Deposit Increases Collateral Balance**
    - Fuzz test: for any valid amount, deposit increases totalCollateral by exactly amount
    - **Validates: Requirements 4.1, 4.3, 4.5**

  - [x] 7.4 Write property test for collateral invariant
    - **Property 2: Collateral Accounting Invariant**
    - Fuzz test: for any user, totalCollateral >= lockedCollateral always holds
    - **Validates: Requirements 4.3, 4.4**

  - [x] 7.5 Write property test for withdraw
    - **Property 3: Withdraw Decreases Available Collateral**
    - Fuzz test: for any valid withdraw, totalCollateral decreases by amount
    - **Validates: Requirements 4.6**

  - [x] 7.6 Write property test for withdraw while paused
    - **Property 13: Withdraw Allowed While Paused**
    - Test: withdrawCollateral succeeds even when paused
    - **Validates: Requirements 10.5**

- [x] 8. Checkpoint - Verify collateral management
  - Ensure all tests pass, ask the user if questions arise.
  - Run `forge test --match-contract SyntheticMinterCollateralTest -vvv`

- [x] 9. Implement mint function
  - [x] 9.1 Implement `mint(uint256 syntheticAmount)` function
    - Add `nonReentrant` and `whenNotPaused` modifiers
    - Call `_validatePriceFeed()` to get validated price
    - Call `_validateCollateralMonitor()` to validate protocol health
    - Calculate `requiredCollateral = (syntheticAmount * price * minCollateralizationRatio) / (100 * 10^PRICE_DECIMALS)` with decimal adjustment
    - Calculate `available = totalCollateral[msg.sender] - lockedCollateral[msg.sender]`
    - Require `available >= requiredCollateral`, revert "Insufficient collateral"
    - Calculate fee: `fee = syntheticAmount * mintFeeBps / BPS_DENOMINATOR`
    - Calculate `netAmount = syntheticAmount - fee`
    - Increment `lockedCollateral[msg.sender] += requiredCollateral`
    - Increment `accumulatedFees += fee`
    - Call `syntheticToken.mint(msg.sender, netAmount)`
    - Calculate resulting CR for event
    - Emit `SyntheticMinted(msg.sender, netAmount, price, collateralRatio)`
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

  - [x] 9.2 Write property test for mint collateral calculation
    - **Property 7: Mint Collateral Calculation**
    - Fuzz test: verify required collateral matches formula exactly
    - **Validates: Requirements 8.3**

  - [x] 9.3 Write property test for insufficient collateral
    - **Property 8: Insufficient Collateral Blocks Mint**
    - Fuzz test: when requiredCollateral > available, mint reverts
    - **Validates: Requirements 8.4**

  - [x] 9.4 Write property test for mint fee deduction
    - **Property 9: Mint Fee Deduction**
    - Fuzz test: user receives (amount - fee), fees accumulate correctly
    - **Validates: Requirements 8.7**

- [x] 10. Implement burn function
  - [x] 10.1 Implement `burn(uint256 syntheticAmount)` function
    - Add `nonReentrant` and `whenNotPaused` modifiers
    - Call `_validatePriceFeed()` to get validated price
    - Get user's synthetic balance: `userBalance = syntheticToken.balanceOf(msg.sender)`
    - Require `syntheticAmount <= userBalance`, revert "Insufficient balance"
    - Calculate collateral to release: `collateralToRelease = lockedCollateral[msg.sender] * syntheticAmount / userBalance`
    - Decrement `lockedCollateral[msg.sender] -= collateralToRelease`
    - Call `syntheticToken.burn(msg.sender, syntheticAmount)`
    - Emit `SyntheticBurned(msg.sender, syntheticAmount, price, collateralToRelease)`
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

  - [x] 10.2 Write property test for burn collateral release
    - **Property 10: Burn Releases Proportional Collateral**
    - Fuzz test: released collateral = lockedCollateral * burnAmount / totalSynthetic
    - **Validates: Requirements 9.2**

  - [x] 10.3 Write property test for partial burn CR improvement
    - **Property 11: Partial Burn Improves or Maintains CR**
    - Fuzz test: after partial burn, CR >= CR before burn
    - **Validates: Requirements 9.5**

- [x] 11. Implement pause functionality
  - [x] 11.1 Implement pause/unpause functions
    - Implement `pause()` with `onlyOwner`, calls `_pause()`, emits Paused event
    - Implement `unpause()` with `onlyOwner`, calls `_unpause()`, emits Unpaused event
    - _Requirements: 10.1, 10.3, 10.4_

  - [x] 11.2 Write property test for pause blocking operations
    - **Property 12: Pause Blocks Mutable Operations**
    - Test: mint, burn, depositCollateral revert when paused
    - **Validates: Requirements 10.2**

- [x] 12. Checkpoint - Verify mint/burn/pause
  - Ensure all tests pass, ask the user if questions arise.
  - Run `forge test --match-contract SyntheticMinterTest -vvv`

- [x] 13. Implement view functions
  - [x] 13.1 Implement position query functions
    - `getLatestPrice()` - returns price from CRE feed (with staleness check)
    - `getCollateralValue()` - returns total USDC in contract (for CRE to read)
    - `getUserCollateralRatio(address user)` - returns (lockedCollateral * 100 * 10^PRICE_DECIMALS) / (syntheticBalance * price)
    - `getAvailableCollateral(address user)` - returns totalCollateral - lockedCollateral
    - `getMaxMintable(address user)` - returns max synthetic tokens user can mint given available collateral
    - `getPositionValue(address user)` - returns syntheticBalance * price / 10^PRICE_DECIMALS
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 2.2_

  - [x] 13.2 Write property test for collateral ratio calculation
    - **Property 14: Collateral Ratio Calculation**
    - Fuzz test: verify getUserCollateralRatio matches formula
    - **Validates: Requirements 12.1**

  - [x] 13.3 Write property test for max mintable boundary
    - **Property 15: Max Mintable Boundary**
    - Fuzz test: mint(getMaxMintable(user)) succeeds, mint(getMaxMintable(user) + 1) reverts
    - **Validates: Requirements 12.3**

- [x] 14. Implement fee collection
  - [x] 14.1 Implement `collectFees()` function
    - Only callable by owner or feeRecipient
    - Transfer accumulated fees to feeRecipient
    - Reset accumulatedFees to 0
    - Emit `FeesCollected(feeRecipient, amount)`
    - _Requirements: 8.7_

- [x] 15. Create integration README
  - [x] 15.1 Write `synthetic-asset-minter/README.md`
    - Document deployment steps for SyntheticToken and SyntheticMinter
    - Document configuration: setting feed addresses, risk params
    - Document CRE feed integration requirements
    - Document Lambda deployment for stock prices
    - Include example deployment script commands
    - _Requirements: all (documentation)_

- [x] 16. Final checkpoint - Full Solidity test suite
  - Ensure all tests pass, ask the user if questions arise.
  - Run `forge test -vvv`
  - Run `forge coverage` to verify test coverage

- [x] 17. End-to-end integration test
  - [x] 17.1 Deploy Lambda and verify stock price endpoint
    - Deploy updated Lambda stack with `./deploy.sh`
    - Test `/stock-price/latest` endpoint returns valid data
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 17.2 Deploy contracts to Sepolia testnet
    - Deploy SyntheticToken
    - Deploy SyntheticMinter with USDC address
    - Set SyntheticMinter as minter on SyntheticToken
    - Configure feed addresses
    - _Requirements: all Solidity_

  - [x] 17.3 Configure and run CRE workflow simulation
    - Update `config.staging.json` with deployed contract addresses
    - Run `cre workflow simulate api-oracle --target staging-settings`
    - Verify price data and collateral metrics appear on-chain
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

  - [x] 17.4 Test full mint/burn flow with live CRE feeds
    - Deposit USDC collateral
    - Mint synthetic tokens using live price feed
    - Verify collateral ratio calculations
    - Burn tokens and verify collateral release
    - _Requirements: 4, 7, 8_

- [x] 18. Resolve economic model and add liquidation
  - [x] 18.1 Track minted debt separately from token balance (`syntheticDebt`, `totalSyntheticDebt`)
    - Fixes the burn accounting so collateral release is keyed on tracked debt, not the transferable `balanceOf`
    - _Requirements: 9.2, 9.3, 9.5_
  - [x] 18.2 Add liquidation with a configurable `liquidationThreshold` and bounded `liquidationBonusBps`
    - `liquidate(address,uint256)` repays debt, seizes collateral + bonus (capped at locked), closes fully-repaid positions, surfaces bad debt
    - CR computed from current oracle-priced debt; owner-only bounded setters
    - _Requirements: 13.1–13.8_
  - [x] 18.3 Charge the mint fee in USDC instead of sSPY
    - Fee is taken from the minter's collateral and accrues/pays in USDC; `collectFees()` transfers USDC (mints no sSPY), so `totalSupply == totalSyntheticDebt`. `getMaxMintable` accounts for the fee.
    - _Requirements: 8.7_
  - [x] 18.4 Replace/extend tests to encode the CDP model
    - Reframe Property 10 to debt-proportional release; add settlement (SPY unchanged/up/down), liquidation eligibility, improve-or-close, bounded incentive, extreme-gap/bad-debt, staleness, pause, solvency invariant, and end-to-end (mint at X → liquidate at Y) tests
    - _Requirements: 9, 13_

## Notes

- **Economic model resolved to collateralized debt (CDP).** The original docs described "long synthetic exposure" for the minter, but the code released collateral proportionally and price-independently. True long-SPY exposure for the minter cannot be delivered by this self-collateralized architecture without a counterparty/sponsor/hedge (it would consume other users' collateral). The coherent, solvent model is CDP issuance: burning repays debt and unlocks the minter's own collateral; the SPY price marks collateralization and triggers liquidation. See requirements Introduction and Requirement 13.
- All tasks are required including property-based tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties using Foundry fuzzing
- Unit tests validate specific examples and edge cases
- All contracts use Solidity ^0.8.20 for consistency with existing codebase
- CRE workflow reads on-chain state for collateral monitoring (no off-chain reserves needed)
