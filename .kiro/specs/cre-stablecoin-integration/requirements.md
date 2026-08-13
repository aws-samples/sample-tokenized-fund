# Requirements Document

## Introduction

This specification defines a Synthetic Asset Minter that allows users to deposit USDC as collateral and mint tokenized synthetic ETFs (e.g., sSPY for the S&P 500). The system integrates with CRE (Chainlink Runtime Environment) oracle feeds to fetch real-time stock prices and monitor protocol collateralization health, enforcing mint/burn rules with configurable risk parameters.

## Glossary

- **Synthetic_Minter**: The smart contract that manages USDC collateral deposits, minting synthetic stock tokens, and redemptions
- **Synthetic_Token**: An ERC20 token representing a synthetic ETF (e.g., sSPY tracks S&P 500 price)
- **CRE_Price_Feed**: The CRE contract providing real-time asset prices (e.g., SPY/USD) with timestamps
- **CRE_Collateral_Monitor**: The CRE contract providing global protocol collateralization ratio and health status
- **Collateralization_Ratio**: The ratio of USDC collateral value to synthetic token value, expressed as a percentage (e.g., 150 = 150%)
- **Staleness_Window**: Maximum age in seconds for feed data to be considered valid
- **Circuit_Breaker**: Emergency mechanism to pause operations when feeds are invalid or unhealthy
- **USDC**: The stablecoin used as collateral (6 decimals)

## Requirements

### Requirement 1: Lambda Stock Price Fetching

**User Story:** As a protocol operator, I want a Lambda function to fetch real-time Amazon stock prices from public APIs, so that the data is available for CRE to consume.

#### Acceptance Criteria

1. THE Lambda_Handler SHALL fetch SPY (S&P 500 ETF) stock price from a public stock API (e.g., Alpha Vantage, Finnhub)
2. THE Lambda_Handler SHALL store the stock price and timestamp in DynamoDB
3. THE Lambda_Handler SHALL expose the latest price via API Gateway endpoint
4. THE Lambda_Handler SHALL validate that the price is positive before storing
5. WHEN the stock API returns an error, THE Lambda_Handler SHALL return an error response and not update DynamoDB
6. THE Lambda_Handler SHALL support configurable stock symbol via environment variable

### Requirement 2: CRE Workflow Integration

**User Story:** As a protocol operator, I want the CRE workflow to fetch stock prices from Lambda and read on-chain collateral state, so that both price and health data are written on-chain with DON consensus.

#### Acceptance Criteria

1. THE CRE_Workflow SHALL fetch stock price from the Lambda API Gateway endpoint
2. THE CRE_Workflow SHALL read `SyntheticMinter.getCollateralValue()` from on-chain
3. THE CRE_Workflow SHALL read `SyntheticToken.totalSupply()` from on-chain
4. THE CRE_Workflow SHALL calculate global collateralization ratio as: `collateralValue / (totalSupply * stockPrice)`
5. THE CRE_Workflow SHALL determine `isHealthy` based on ratio >= configured minimum threshold
6. THE CRE_Workflow SHALL write stock price and timestamp to `PriceFeed.sol`
7. THE CRE_Workflow SHALL write collateral metrics to `CollateralizationMonitor.sol`
8. THE CRE_Workflow SHALL use consensus aggregation for all data across DON nodes

### Requirement 3: CRE Feed Interface Definition

**User Story:** As a smart contract developer, I want minimal interfaces for CRE feeds, so that the minter can read price and collateral data without tight coupling.

#### Acceptance Criteria

1. THE Synthetic_Minter SHALL define an `ICREPriceFeed` interface with `getLatestPrice()` returning price and timestamp
2. THE Synthetic_Minter SHALL define an `ICRECollateralMonitor` interface with `getLatestData()` returning collateral metrics including ratio, timestamp, and health status
3. THE Synthetic_Minter SHALL reuse existing CRE contract function signatures where compatible
4. WHEN a feed address is not set, THE Synthetic_Minter SHALL revert with a descriptive error

### Requirement 4: Collateral Management with USDC

**User Story:** As a user, I want to deposit USDC as collateral, so that I can mint synthetic stock tokens.

#### Acceptance Criteria

1. THE Synthetic_Minter SHALL accept USDC deposits via `depositCollateral(uint256 amount)`
2. WHEN depositing, THE Synthetic_Minter SHALL transfer USDC from user to contract using `transferFrom`
3. THE Synthetic_Minter SHALL track each user's total deposited collateral
4. THE Synthetic_Minter SHALL track each user's collateral currently backing minted tokens
5. WHEN a deposit succeeds, THE Synthetic_Minter SHALL emit `CollateralDeposited` event with user address and amount
6. THE Synthetic_Minter SHALL provide `withdrawCollateral(uint256 amount)` to withdraw unused collateral

### Requirement 5: Feed Address Configuration

**User Story:** As a contract administrator, I want to configure CRE feed addresses with access control, so that only authorized parties can change oracle sources.

#### Acceptance Criteria

1. THE Synthetic_Minter SHALL provide `setPriceFeed(address)` callable only by owner
2. THE Synthetic_Minter SHALL provide `setCollateralMonitor(address)` callable only by owner
3. WHEN a zero address is provided, THE Synthetic_Minter SHALL revert with "Invalid feed address"
4. WHEN a feed address is updated, THE Synthetic_Minter SHALL emit a `FeedUpdated` event with feed type, old and new addresses
5. THE Synthetic_Minter SHALL NOT hardcode any feed addresses in the contract bytecode

### Requirement 6: Risk Parameter Configuration

**User Story:** As a risk manager, I want to configure collateralization thresholds and fees, so that the protocol can adapt to market conditions.

#### Acceptance Criteria

1. THE Synthetic_Minter SHALL store configurable `minCollateralizationRatio` (default 150%, meaning $150 USDC per $100 synthetic)
2. THE Synthetic_Minter SHALL store configurable `mintFeeBps` (default 30 = 0.3%, max 1000 = 10%)
3. THE Synthetic_Minter SHALL store configurable `stalenessWindow` in seconds (default 3600)
4. WHEN risk parameters are updated, THE Synthetic_Minter SHALL emit a `RiskParamsUpdated` event
5. THE Synthetic_Minter SHALL provide setter functions for each parameter callable only by owner

### Requirement 7: Staleness and Validity Checks

**User Story:** As a protocol user, I want the system to reject stale or invalid feed data, so that my transactions use accurate pricing.

#### Acceptance Criteria

1. WHEN price feed timestamp is older than `stalenessWindow`, THE Synthetic_Minter SHALL revert with "Price feed stale"
2. WHEN collateral monitor timestamp is older than `stalenessWindow`, THE Synthetic_Minter SHALL revert with "Collateral feed stale"
3. WHEN price feed returns zero price, THE Synthetic_Minter SHALL revert with "Invalid price"
4. WHEN collateral monitor reports `isHealthy = false`, THE Synthetic_Minter SHALL revert with "Protocol unhealthy"

### Requirement 8: Mint Synthetic Tokens

**User Story:** As a user, I want to mint synthetic stock tokens by locking my USDC collateral, so that I can gain exposure to stock price movements.

#### Acceptance Criteria

1. WHEN `mint(uint256 syntheticAmount)` is called, THE Synthetic_Minter SHALL fetch current stock price from CRE_Price_Feed
2. WHEN `mint()` is called, THE Synthetic_Minter SHALL fetch protocol health from CRE_Collateral_Monitor
3. THE Synthetic_Minter SHALL calculate required USDC as: `(syntheticAmount * stockPrice * minCollateralizationRatio) / (100 * 10^priceFeedDecimals)`
4. WHEN user's available collateral is less than required, THE Synthetic_Minter SHALL revert with "Insufficient collateral"
5. WHEN user's resulting collateralization ratio would be below `minCollateralizationRatio`, THE Synthetic_Minter SHALL revert with "Below min collateralization"
6. WHEN minting succeeds, THE Synthetic_Minter SHALL emit `SyntheticMinted` event including amount, price used, and resulting collateral ratio
7. IF `mintFeeBps > 0`, THEN THE Synthetic_Minter SHALL deduct fee from minted amount and record fee for protocol

### Requirement 9: Burn and Redeem

**User Story:** As a user, I want to burn synthetic tokens to unlock my USDC collateral, with the system preventing actions that would harm protocol health.

#### Acceptance Criteria

1. WHEN `burn(uint256 syntheticAmount)` is called, THE Synthetic_Minter SHALL fetch current stock price from CRE_Price_Feed
2. THE Synthetic_Minter SHALL calculate USDC to release based on current price and user's collateral ratio
3. WHEN burn succeeds, THE Synthetic_Minter SHALL reduce user's locked collateral proportionally
4. WHEN burn succeeds, THE Synthetic_Minter SHALL emit `SyntheticBurned` event including amount and price used
5. THE Synthetic_Minter SHALL allow partial burns that improve user's collateralization ratio

### Requirement 10: Circuit Breaker and Pause Functionality

**User Story:** As a protocol administrator, I want emergency controls to pause operations when feeds are compromised, so that user funds are protected.

#### Acceptance Criteria

1. THE Synthetic_Minter SHALL implement `pause()` and `unpause()` functions callable only by owner
2. WHILE the contract is paused, THE Synthetic_Minter SHALL revert on `mint()`, `burn()`, and `depositCollateral()`
3. WHEN paused, THE Synthetic_Minter SHALL emit a `Paused` event with the caller address
4. WHEN unpaused, THE Synthetic_Minter SHALL emit an `Unpaused` event with the caller address
5. THE Synthetic_Minter SHALL allow `withdrawCollateral()` while paused to enable user exits (for unused collateral only)

### Requirement 11: Reentrancy Protection

**User Story:** As a security auditor, I want the contract to prevent reentrancy attacks, so that funds cannot be drained through recursive calls.

#### Acceptance Criteria

1. THE Synthetic_Minter SHALL use OpenZeppelin's ReentrancyGuard for `mint()`, `burn()`, `depositCollateral()`, and `withdrawCollateral()`
2. THE Synthetic_Minter SHALL follow checks-effects-interactions pattern for all state-changing functions
3. WHEN a reentrant call is detected, THE Synthetic_Minter SHALL revert with "ReentrancyGuard: reentrant call"

### Requirement 12: View Functions for User Position

**User Story:** As a user, I want to query my position details, so that I can make informed decisions about minting or burning.

#### Acceptance Criteria

1. THE Synthetic_Minter SHALL provide `getUserCollateralRatio(address user)` returning current ratio as percentage
2. THE Synthetic_Minter SHALL provide `getAvailableCollateral(address user)` returning USDC not backing any position
3. THE Synthetic_Minter SHALL provide `getMaxMintable(address user)` returning maximum synthetic tokens user can mint
4. THE Synthetic_Minter SHALL provide `getPositionValue(address user)` returning USD value of user's synthetic holdings
5. THE Synthetic_Minter SHALL provide `getLatestPrice()` returning current stock price from CRE feed
