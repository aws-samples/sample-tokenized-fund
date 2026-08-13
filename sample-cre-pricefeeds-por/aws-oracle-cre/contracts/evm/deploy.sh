#!/bin/bash

# Deploy and verify contracts to Sepolia testnet
# Usage: ./deploy.sh

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Contract Deployment Script ===${NC}"

# Check if required environment variables are set
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY environment variable is not set${NC}"
    echo "Please set it with: export PRIVATE_KEY=your_private_key"
    exit 1
fi

if [ -z "$SEPOLIA_RPC_URL" ]; then
    echo -e "${RED}Warning: SEPOLIA_RPC_URL environment variable is not set${NC}"
    echo "Using default public Sepolia RPC..."
    export SEPOLIA_RPC_URL="https://ethereum-sepolia-rpc.publicnode.com"
fi

# Check if forge is installed
if ! command -v forge &> /dev/null; then
    echo -e "${RED}Error: forge is not installed${NC}"
    echo "Please install Foundry: https://book.getfoundry.sh/getting-started/installation"
    exit 1
fi

echo -e "${GREEN}Step 1: Installing forge-std dependency${NC}"
forge install foundry-rs/forge-std || true

echo -e "${GREEN}Step 2: Fetching current gas prices${NC}"
BASE_FEE=$(cast gas-price --rpc-url $SEPOLIA_RPC_URL)
PRIORITY_FEE=$((BASE_FEE / 10))  # 10% of base fee as priority
if [ $PRIORITY_FEE -lt 1000000000 ]; then
    PRIORITY_FEE=1000000000  # Minimum 1 gwei
fi
MAX_FEE=$((BASE_FEE + PRIORITY_FEE))
echo "Using base fee: $BASE_FEE wei, priority fee: $PRIORITY_FEE wei, max fee: $MAX_FEE wei"

echo -e "${GREEN}Step 3: Deploying PriceFeed contract${NC}"
PRICE_FEED_OUTPUT=$(forge script script/DeployPriceFeed.s.sol:DeployPriceFeed \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --priority-gas-price $PRIORITY_FEE \
    --with-gas-price $MAX_FEE \
    --gas-limit 3000000 \
    -vvv)

echo "$PRICE_FEED_OUTPUT"

# Extract PriceFeed address from output
PRICE_FEED_ADDRESS=$(echo "$PRICE_FEED_OUTPUT" | grep "PriceFeed deployed to:" | awk '{print $NF}')

if [ -z "$PRICE_FEED_ADDRESS" ]; then
    echo -e "${RED}Error: Failed to extract PriceFeed address${NC}"
    exit 1
fi

echo -e "${GREEN}PriceFeed deployed at: $PRICE_FEED_ADDRESS${NC}"

echo -e "${GREEN}Step 4: Deploying CollateralizationMonitor contract${NC}"
MONITOR_OUTPUT=$(forge script script/DeployCollateralizationMonitor.s.sol:DeployCollateralizationMonitor \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --priority-gas-price $PRIORITY_FEE \
    --with-gas-price $MAX_FEE \
    --gas-limit 3000000 \
    -vvv)

echo "$MONITOR_OUTPUT"

# Extract CollateralizationMonitor address from output
MONITOR_ADDRESS=$(echo "$MONITOR_OUTPUT" | grep "CollateralizationMonitor deployed to:" | awk '{print $NF}')

if [ -z "$MONITOR_ADDRESS" ]; then
    echo -e "${RED}Error: Failed to extract CollateralizationMonitor address${NC}"
    exit 1
fi

echo -e "${GREEN}CollateralizationMonitor deployed at: $MONITOR_ADDRESS${NC}"

echo -e "${BLUE}=== Deployment Summary ===${NC}"
echo -e "PriceFeed: ${GREEN}$PRICE_FEED_ADDRESS${NC}"
echo -e "CollateralizationMonitor: ${GREEN}$MONITOR_ADDRESS${NC}"

echo -e "${GREEN}Step 5: Setting KeystoneForwarder on deployed contracts${NC}"
KEYSTONE_FORWARDER="${KEYSTONE_FORWARDER:-0x15fC6ae953E024d975e77382eEeC56A9101f9F88}"
echo "Using KeystoneForwarder: $KEYSTONE_FORWARDER"

cast send $PRICE_FEED_ADDRESS "setForwarder(address)" $KEYSTONE_FORWARDER \
    --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY \
    --priority-gas-price $PRIORITY_FEE --gas-price $MAX_FEE
echo -e "${GREEN}PriceFeed forwarder set${NC}"

cast send $MONITOR_ADDRESS "setForwarder(address)" $KEYSTONE_FORWARDER \
    --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY \
    --priority-gas-price $PRIORITY_FEE --gas-price $MAX_FEE
echo -e "${GREEN}CollateralizationMonitor forwarder set${NC}"
echo ""

echo -e "${BLUE}=== Updating config.staging.json ===${NC}"

# Update config.staging.json with deployed addresses
CONFIG_FILE="../../api-oracle/config.staging.json"
if [ -f "$CONFIG_FILE" ]; then
    sed -i.bak "s|\"priceFeedAddress\": \"[^\"]*\"|\"priceFeedAddress\": \"$PRICE_FEED_ADDRESS\"|" "$CONFIG_FILE"
    sed -i.bak "s|\"collateralizationMonitorAddress\": \"[^\"]*\"|\"collateralizationMonitorAddress\": \"$MONITOR_ADDRESS\"|" "$CONFIG_FILE"
    rm -f "${CONFIG_FILE}.bak"
    echo -e "${GREEN}Updated config.staging.json with deployed addresses${NC}"
else
    echo -e "${RED}config.staging.json not found at $CONFIG_FILE${NC}"
fi

# Publish feed addresses to the web UI so it auto-loads them
UI_ADDR="../../../../ui/oracle-addresses.json"
cat > "$UI_ADDR" <<EOF
{
  "contracts": {
    "PriceFeed": "$PRICE_FEED_ADDRESS",
    "CollateralizationMonitor": "$MONITOR_ADDRESS"
  }
}
EOF
echo -e "${GREEN}Feed addresses published to: ui/oracle-addresses.json${NC}"

echo -e "${BLUE}=== Verification Instructions ===${NC}"
echo "To verify contracts on Etherscan, run:"
echo ""
echo -e "${GREEN}forge verify-contract $PRICE_FEED_ADDRESS \\${NC}"
echo -e "${GREEN}  src/PriceFeed.sol:PriceFeed \\${NC}"
echo -e "${GREEN}  --chain-id 11155111 \\${NC}"
echo -e "${GREEN}  --etherscan-api-key \$ETHERSCAN_API_KEY${NC}"
echo ""
echo -e "${GREEN}forge verify-contract $MONITOR_ADDRESS \\${NC}"
echo -e "${GREEN}  src/CollateralizationMonitor.sol:CollateralizationMonitor \\${NC}"
echo -e "${GREEN}  --chain-id 11155111 \\${NC}"
echo -e "${GREEN}  --etherscan-api-key \$ETHERSCAN_API_KEY${NC}"

echo ""
echo -e "${BLUE}=== Monitor Transactions ===${NC}"
echo "PriceFeed: https://sepolia.etherscan.io/address/$PRICE_FEED_ADDRESS"
echo "CollateralizationMonitor: https://sepolia.etherscan.io/address/$MONITOR_ADDRESS"

echo -e "${BLUE}=== Deployment Complete ===${NC}"
