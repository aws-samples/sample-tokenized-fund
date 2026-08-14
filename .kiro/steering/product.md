# Product Overview

A synthetic asset minting protocol that allows users to deposit USDC as collateral and mint tokenized synthetic ETFs (sSPY for the S&P 500). The system integrates AWS serverless infrastructure with Chainlink Runtime Environment (CRE) for real-time stock price feeds and protocol health monitoring.

**Economic model:** collateralized debt (CDP). Minted sSPY is an over-collateralized debt the minter repays by burning to reclaim their locked USDC — burning is proportional to the debt repaid and independent of the SPY price, not a price-based payout. Positions are marked to the live oracle price and liquidated if they fall below the liquidation threshold. The contract holds only minters' own USDC, so it never pays minters SPY gains (that would consume other users' collateral); long-SPY exposure accrues to sSPY holders.

## Components

### 1. AWS Lambda Backend (`sample-cre-pricefeeds-por/price-feed-por-dynamodb-crud/`)

Serverless infrastructure providing stock price data:
- Fetches real-time SPY prices from Finnhub/Alpha Vantage APIs
- Caches prices in DynamoDB
- Exposes data via API Gateway with API key authentication

### 2. CRE Workflow (`sample-cre-pricefeeds-por/aws-oracle-cre/`)

Chainlink Runtime Environment workflow that:
- Fetches stock prices from Lambda API
- Reads on-chain collateral state from SyntheticMinter
- Calculates global collateralization ratio
- Writes price and health data to on-chain contracts via DON consensus

### 3. Synthetic Asset Minter (`synthetic-asset-minter/`)

Solidity smart contracts for the minting protocol:
- **SyntheticMinter**: Manages USDC collateral, minting, and burning
- **SyntheticToken**: ERC20 token representing synthetic ETF (sSPY)
- **PriceFeed**: On-chain oracle for SPY/USD price
- **CollateralizationMonitor**: Protocol health status oracle

## Key Features

- 150% minimum collateralization ratio to open/increase a position
- Liquidation of positions below the liquidation threshold (default 120%), with a bounded liquidator bonus (default 10%, max 30%)
- Debt tracked separately from the sSPY token balance so transfers cannot distort collateral release
- Configurable mint fees (default 0.3%)
- Staleness checks on oracle data
- Circuit breaker for emergency pauses
- Reentrancy protection

## Target Network

**Ethereum Sepolia testnet**
