# Contract Deployment

**Part of:** [Chainlink CRE + AWS Oracle Demo](../../../docs/README.md)

## Prerequisites

- Sepolia ETH in your wallet ([Get testnet ETH](https://sepoliafaucet.com/))
- `.env` file configured with `CRE_ETH_PRIVATE_KEY`

## Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
```

```bash
source ~/.bashrc
```

```bash
foundryup
```

## Deploy

```bash
cd ~/sample-cre-pricefeeds-por/aws-oracle-cre/contracts/evm
export PRIVATE_KEY=0x$(grep CRE_ETH_PRIVATE_KEY ../../.env | cut -d'=' -f2)
./deploy.sh
```

The deploy script automatically:
- Installs forge-std dependencies
- Compiles contracts
- Deploys to Sepolia
- Updates config.staging.json with contract addresses

**Next Step:** [Run CRE Workflow](../../README.md#4-run-simulation)

## Optional: Verify Contracts

```bash
export ETHERSCAN_API_KEY=your_key
./verify.sh <price_feed_addr> <monitor_addr>
```

## Optional: Test Contracts

```bash
./test-contracts.sh
```

## Contracts

- **PriceFeed** - Stores asset price data
- **CollateralizationMonitor** - Monitors collateral health

Both implement `IReceiver` for CRE workflow integration.

## Related Documentation

- [Main Project Overview](../../../docs/README.md)
- [CRE Workflow Setup](../../README.md) - Uses these contracts
- [AWS Backend Setup](../../../price-feed-por-dynamodb-crud/README.md)
