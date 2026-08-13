# Technology Stack

## Languages

- **Go** 1.25.3+ - CRE workflow implementation (WASM target: `wasip1`)
- **TypeScript** 5.5+ - AWS Lambda handlers
- **Solidity** ^0.8.20 - Smart contracts

## Frameworks & Libraries

### AWS Backend (`price-feed-por-dynamodb-crud/`)
- AWS SAM (Serverless Application Model)
- AWS Lambda (Node.js 20.x runtime)
- Amazon DynamoDB
- Amazon API Gateway with API key auth
- `@aws-sdk/client-dynamodb`, `@aws-sdk/lib-dynamodb`
- esbuild for bundling

### CRE Workflows (`aws-oracle-cre/`)
- Chainlink CRE SDK (`cre-sdk-go`)
- go-ethereum for contract bindings
- Foundry (forge) for contract development

### Synthetic Asset Minter (`synthetic-asset-minter/`)
- OpenZeppelin Contracts (ERC20, Ownable, Pausable, ReentrancyGuard)
- Foundry for testing and deployment

## Common Commands

### AWS Lambda Service
```bash
cd sample-cre-pricefeeds-por/price-feed-por-dynamodb-crud
npm run build          # Compile TypeScript
npm run test           # Run Jest tests
npm run deploy         # Build + SAM deploy
./deploy.sh            # Full deployment script
./verify-deployment.sh # Verify deployment
```

### CRE Workflows
```bash
cd sample-cre-pricefeeds-por/aws-oracle-cre
cre generate-bindings evm  # Generate contract bindings
go mod tidy                # Update Go dependencies
./run-simulation.sh        # Run workflow simulation
cre workflow simulate api-oracle --target staging-settings  # Dry run
cre workflow simulate api-oracle --target staging-settings --broadcast  # Live
```

### Smart Contracts (CRE)
```bash
cd sample-cre-pricefeeds-por/aws-oracle-cre/contracts/evm
./setup-foundry.sh     # Initialize Foundry
forge build            # Compile contracts
./deploy.sh            # Deploy to Sepolia
./verify.sh            # Verify on Etherscan
```

### Synthetic Asset Minter
```bash
cd synthetic-asset-minter
forge build            # Compile contracts
forge test -vvv        # Run tests with verbosity
forge coverage         # Test coverage report
./deploy.sh            # Deploy to Sepolia
```

## Environment Setup

- CRE CLI v1.0.3+ required (`cre login` to authenticate)
- AWS CLI configured with credentials
- Sepolia ETH for gas (faucet: faucets.chain.link)
- Private key in `.env` as `CRE_ETH_PRIVATE_KEY` (64 hex chars, no 0x prefix)
- Stock API keys from Finnhub and/or Alpha Vantage
