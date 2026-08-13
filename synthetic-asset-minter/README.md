# Synthetic Asset Minter

Solidity contracts for minting synthetic ETF tokens (sSPY) backed by USDC collateral, with real-time pricing from CRE oracle feeds.

## Contracts

| Contract | Description |
|----------|-------------|
| `SyntheticMinter.sol` | Main protocol — collateral deposits, minting, burning, risk checks |
| `SyntheticToken.sol` | ERC20 token (sSPY) with authorized minter pattern |
| `interfaces/ICREPriceFeed.sol` | Interface for CRE price oracle |
| `interfaces/ICRECollateralMonitor.sol` | Interface for CRE health oracle |

## Deployment

```bash
cd synthetic-asset-minter
export PRIVATE_KEY=<your-private-key>
export RPC_URL=https://ethereum-sepolia-rpc.publicnode.com

# Deploy all contracts (OWNER_ADDRESS auto-derived from PRIVATE_KEY)
./deploy.sh
```

After deploying, wire the CRE feeds (done automatically by `deploy-e2e.sh`):
```bash
cast send <SyntheticMinter> "setPriceFeed(address)" <PriceFeed> \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
cast send <SyntheticMinter> "setCollateralMonitor(address)" <CollateralizationMonitor> \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

## User Operations

Set up environment:
```bash
export PRIVATE_KEY=<your-private-key>
export RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
export MINTER=<deployed-synthetic-minter>
export TOKEN=<deployed-synthetic-token>
export USDC=0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238  # Sepolia USDC
export DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)
```

### Deposit Collateral

```bash
# Get Sepolia USDC from https://faucet.circle.com/
# Approve + deposit 1000 USDC (6 decimals)
cast send $USDC "approve(address,uint256)" $MINTER 1000000000 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
cast send $MINTER "depositCollateral(uint256)" 1000000000 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

### Mint Synthetic Tokens

```bash
# Mint 1 sSPY (18 decimals) — requires 150% collateralization
cast send $MINTER "mint(uint256)" 1000000000000000000 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

### Query Position

```bash
cast call $MINTER "getAvailableCollateral(address)(uint256)" $DEPLOYER --rpc-url $RPC_URL
cast call $MINTER "getMaxMintable(address)(uint256)" $DEPLOYER --rpc-url $RPC_URL
cast call $MINTER "getUserCollateralRatio(address)(uint256)" $DEPLOYER --rpc-url $RPC_URL
```

### Burn and Withdraw

```bash
cast send $MINTER "burn(uint256)" 500000000000000000 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
cast send $MINTER "withdrawCollateral(uint256)" 500000000 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

### Automated Integration Test

```bash
export PRIVATE_KEY=<your-private-key>
./test-integration.sh
```

## Risk Parameters

Owner-configurable:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `minCollateralizationRatio` | 150 | Minimum CR as percentage |
| `mintFeeBps` | 30 | Mint fee in basis points (0.3%) |
| `stalenessWindow` | 3600 | Max oracle data age in seconds |

```bash
# Example: update minimum CR to 200%
cast send $MINTER "setMinCollateralizationRatio(uint256)" 200 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

## CRE Feed Interfaces

**ICREPriceFeed**:
```solidity
function getLatestPrice() external view returns (uint256 price, uint256 timestamp);
// price: 8 decimals (e.g., 18500000000 = $185.00)
```

**ICRECollateralMonitor**:
```solidity
struct CollateralData {
    uint256 price;      // Asset price (8 decimals)
    uint256 reserves;   // Total reserves value
    uint256 ratio;      // Collateralization ratio (percentage)
    uint256 timestamp;  // Unix timestamp
    bool isHealthy;     // Protocol health status
}
function getLatestData() external view returns (CollateralData memory);
```

## Testing

```bash
forge test -vvv                                    # All tests
forge test --match-contract SyntheticMinterTest    # Minter only
forge coverage                                     # Coverage report
```

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `PRICE_DECIMALS` | 8 | CRE price feed decimals |
| `USDC_DECIMALS` | 6 | USDC token decimals |
| `SYNTHETIC_DECIMALS` | 18 | Synthetic token decimals |
| `BPS_DENOMINATOR` | 10000 | Basis points denominator |

## License

MIT
