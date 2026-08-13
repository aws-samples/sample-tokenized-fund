# AWS + CRE Infrastructure

This directory contains the AWS serverless backend and Chainlink Runtime Environment (CRE) workflow that power the synthetic asset minting protocol.

## Components

```
sample-cre-pricefeeds-por/
├── price-feed-por-dynamodb-crud/   # AWS Lambda backend
│   ├── src/handlers/               # Lambda function handlers
│   ├── template.yaml               # SAM CloudFormation template
│   └── deploy.sh                   # Deployment script
│
└── aws-oracle-cre/                 # CRE workflow
    ├── api-oracle/                 # Workflow implementation
    │   ├── main.go                 # Workflow logic (WASM)
    │   └── config.staging.json     # Environment config
    ├── contracts/evm/              # Oracle contracts
    │   └── src/
    │       ├── PriceFeed.sol
    │       └── CollateralizationMonitor.sol
    └── project.yaml                # CRE project settings
```

## AWS Lambda Backend

Fetches real-time stock prices and exposes them via API Gateway.

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/stock-price?symbol=SPY` | GET | Get current stock price |
| `/asset-price` | GET/POST | Asset price CRUD |
| `/proof-of-reserves` | GET/POST | Proof of reserves CRUD |

### Deployment

```bash
cd price-feed-por-dynamodb-crud

# Set API keys
export FINNHUB_API_KEY=<your-key>
export ALPHA_VANTAGE_API_KEY=<your-key>

# Deploy
./deploy.sh

# Verify
./verify-deployment.sh
```

See [price-feed-por-dynamodb-crud/README.md](./price-feed-por-dynamodb-crud/README.md) for details.

## CRE Workflow

Chainlink workflow that fetches prices and writes to on-chain oracles.

### What It Does

1. Fetches SPY price from Lambda API (every 30 seconds)
2. Reads on-chain collateral state from SyntheticMinter
3. Calculates global collateralization ratio
4. Writes price to PriceFeed.sol via DON consensus
5. Writes health metrics to CollateralizationMonitor.sol

### Running the Workflow

```bash
cd aws-oracle-cre

# Generate contract bindings
cre generate-bindings evm

# Dry run (simulation only)
cre workflow simulate api-oracle --target staging-settings

# Live (writes to chain)
cre workflow simulate api-oracle --target staging-settings --broadcast
```

See [aws-oracle-cre/README.md](./aws-oracle-cre/README.md) for details.

## Quick Deploy (Both Components)

```bash
./deploy-all.sh
```

This deploys both the Lambda backend and CRE contracts in sequence.
