# CRE Oracle Workflow

CRE workflow that fetches stock prices from AWS Lambda, calculates collateralization ratios, and writes results to PriceFeed + CollateralizationMonitor contracts on Sepolia via DON consensus.

## Quick Start

```bash
cd sample-cre-pricefeeds-por/aws-oracle-cre

# 1. Setup secrets (auto-populates API key from AWS deployment)
./set-api-key.sh

# 2. Add your private key to .env (64 hex chars, NO 0x prefix)
#    CRE_ETH_PRIVATE_KEY=abcdef1234...

# 3. Deploy contracts (updates config.staging.json automatically)
cd contracts/evm && export PRIVATE_KEY=0x<key> && ./deploy.sh && cd ../..

# 4. Generate bindings and run
cre login
cre generate-bindings evm
cre workflow simulate ./api-oracle --target staging-settings --broadcast
```

## Configuration

### Secrets (`.env`)

```bash
API_KEY_VALUE=your_api_gateway_key          # Auto-set by ./set-api-key.sh
CRE_ETH_PRIVATE_KEY=<64-hex-no-0x-prefix>   # You must set this manually
```

The `secrets.yaml` maps logical ID `API_KEY` → env var `API_KEY_VALUE`.

### Workflow Config (`api-oracle/config.staging.json`)

| Field | Description |
|-------|-------------|
| `schedule` | Cron expression (min `*/30 * * * * *` — [CRE quota](https://docs.chain.link/cre/service-quotas)) |
| `apiUrl` / `stockPriceApiUrl` | AWS API Gateway URL |
| `minCollateralizationRatio` | Threshold (1.5 = 150%) |
| `evms[].priceFeedAddress` | PriceFeed contract (auto-set by deploy script) |
| `evms[].collateralizationMonitorAddress` | Monitor contract (auto-set by deploy script) |
| `evms[].syntheticMinterAddress` | SyntheticMinter contract |
| `evms[].gasLimit` | Max gas per tx (default 500000) |

### RPC (`project.yaml`)

Chain RPC URLs are configured in `project.yaml`. Default uses `https://ethereum-sepolia-rpc.publicnode.com`.

## Project Structure

```
aws-oracle-cre/
├── api-oracle/
│   ├── main.go               # Workflow logic (compiled to WASM)
│   ├── workflow.yaml          # Target settings
│   └── config.staging.json   # Contract addresses + API URL
├── contracts/evm/             # PriceFeed + CollateralizationMonitor
├── project.yaml               # RPC URLs
├── secrets.yaml               # Secret ID → env var mapping
├── .env                       # Secret values (not committed)
├── set-api-key.sh             # Fetches API key from AWS
└── run-simulation.sh          # Quick broadcast script
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Secret not found" | Ensure `API_KEY_VALUE` and `CRE_ETH_PRIVATE_KEY` are in `.env` |
| 403 from API | Run `./set-api-key.sh` to refresh; verify Lambda is deployed |
| "Invalid private key" | Must be exactly 64 hex chars, no `0x` prefix, no quotes |
| Chain read errors on dry-run | Normal for fresh contracts; use `--broadcast` instead |

## Links

- [CRE Documentation](https://docs.chain.link/cre)
- [Contract Deployment](./contracts/evm/README.md)
- [CRE Secrets Guide](https://docs.chain.link/cre/guides/workflow/secrets/using-secrets-simulation)

## License

MIT
