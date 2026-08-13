# Project Structure

```
├── sample-cre-pricefeeds-por/          # AWS + CRE infrastructure
│   ├── docs/                           # Documentation and architecture diagrams
│   ├── price-feed-por-dynamodb-crud/   # AWS Serverless backend
│   │   ├── src/
│   │   │   ├── handlers/               # Lambda function handlers
│   │   │   │   ├── getStockPrice.ts    # Stock price fetcher (Finnhub/Alpha Vantage)
│   │   │   │   ├── getAssetPrice.ts
│   │   │   │   ├── storeAssetPrice.ts
│   │   │   │   ├── getProofOfReserves.ts
│   │   │   │   ├── storeProofOfReserves.ts
│   │   │   │   └── simulateData.ts
│   │   │   ├── types/                  # TypeScript interfaces
│   │   │   └── utils/                  # Validation utilities
│   │   ├── template.yaml               # SAM CloudFormation template
│   │   └── samconfig.toml              # SAM deployment config
│   │
│   ├── aws-oracle-cre/                 # CRE workflow implementation
│   │   ├── api-oracle/
│   │   │   ├── main.go                 # Workflow logic (WASM)
│   │   │   ├── workflow.yaml           # Workflow settings
│   │   │   ├── config.staging.json     # Staging environment config
│   │   │   └── config.production.json  # Production config
│   │   ├── contracts/evm/
│   │   │   ├── src/
│   │   │   │   ├── PriceFeed.sol
│   │   │   │   ├── CollateralizationMonitor.sol
│   │   │   │   ├── abi/                # Contract ABIs
│   │   │   │   ├── generated/          # Go bindings (auto-generated)
│   │   │   │   └── keystone/           # CRE interfaces (IReceiver)
│   │   │   └── script/                 # Foundry deployment scripts
│   │   ├── project.yaml                # CRE project settings (RPC URLs)
│   │   ├── secrets.yaml                # Secret name mappings
│   │   └── .env                        # Secret values (not committed)
│   │
│   └── deploy-all.sh                   # Full stack deployment script
│
└── synthetic-asset-minter/             # Minting protocol contracts
    ├── src/
    │   ├── SyntheticMinter.sol         # Main minting contract
    │   ├── SyntheticToken.sol          # sSPY ERC20 token
    │   └── interfaces/
    │       ├── ICREPriceFeed.sol       # Price feed interface
    │       └── ICRECollateralMonitor.sol
    ├── test/
    │   ├── SyntheticMinter.t.sol       # Minter tests (unit + property)
    │   └── SyntheticToken.t.sol        # Token tests
    ├── script/                         # Foundry deployment scripts
    ├── lib/                            # Dependencies (forge-std, openzeppelin)
    └── foundry.toml                    # Foundry configuration
```

## Key Patterns

- **Lambda handlers**: One file per endpoint in `src/handlers/`, export `handler` function
- **Types**: Shared interfaces in `src/types/index.ts`
- **Validation**: Reusable validators in `src/utils/validation.ts`
- **CRE workflows**: Build tag `//go:build wasip1`, config via JSON files
- **Smart contracts**: Implement `IReceiver` interface for CRE report delivery
- **Generated bindings**: Run `cre generate-bindings evm` after contract changes
- **Foundry tests**: Property-based tests use `testFuzz_` prefix
