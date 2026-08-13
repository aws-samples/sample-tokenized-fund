#!/bin/bash

# Test deployed contracts
# Usage: ./test-contracts.sh

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Contract Testing Script ===${NC}"

# Read addresses from config.json
CONFIG_FILE="../api-oracle/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: config.json not found at $CONFIG_FILE${NC}"
    exit 1
fi

# Extract addresses using grep and sed (works without jq)
PRICE_FEED_ADDRESS=$(grep -o '"priceFeedAddress"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"\([^"]*\)".*/\1/')
MONITOR_ADDRESS=$(grep -o '"collateralizationMonitorAddress"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"\([^"]*\)".*/\1/')

if [ "$PRICE_FEED_ADDRESS" == "0x0000000000000000000000000000000000000000" ]; then
    echo -e "${RED}Error: PriceFeed address not set in config.json${NC}"
    echo "Please deploy contracts first using: ./deploy.sh"
    exit 1
fi

if [ "$MONITOR_ADDRESS" == "0x0000000000000000000000000000000000000000" ]; then
    echo -e "${RED}Error: CollateralizationMonitor address not set in config.json${NC}"
    echo "Please deploy contracts first using: ./deploy.sh"
    exit 1
fi

echo -e "${GREEN}PriceFeed Address: $PRICE_FEED_ADDRESS${NC}"
echo -e "${GREEN}CollateralizationMonitor Address: $MONITOR_ADDRESS${NC}"

if [ -z "$SEPOLIA_RPC_URL" ]; then
    export SEPOLIA_RPC_URL="https://por.bcy-p.metalhosts.com/cre-alpha/MvqtrdftrbxcP3ZgGBJb3bK5/ethereum/sepolia"
fi

echo -e "${BLUE}Testing PriceFeed contract...${NC}"

# Check if cast is available
if ! command -v cast &> /dev/null; then
    echo -e "${RED}Error: cast is not installed${NC}"
    echo "Please install Foundry: https://book.getfoundry.sh/getting-started/installation"
    exit 1
fi

# Test getLatestPrice
echo -e "${YELLOW}Calling getLatestPrice()...${NC}"
PRICE_DATA=$(cast call $PRICE_FEED_ADDRESS "getLatestPrice()" --rpc-url $SEPOLIA_RPC_URL 2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PriceFeed contract is accessible${NC}"
    echo "  Response: $PRICE_DATA"
else
    echo -e "${RED}✗ Failed to call PriceFeed contract${NC}"
    echo "  Error: $PRICE_DATA"
fi

echo ""
echo -e "${BLUE}Testing CollateralizationMonitor contract...${NC}"

# Test getLatestData
echo -e "${YELLOW}Calling getLatestData()...${NC}"
MONITOR_DATA=$(cast call $MONITOR_ADDRESS "getLatestData()" --rpc-url $SEPOLIA_RPC_URL 2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ CollateralizationMonitor contract is accessible${NC}"
    echo "  Response: $MONITOR_DATA"
else
    echo -e "${RED}✗ Failed to call CollateralizationMonitor contract${NC}"
    echo "  Error: $MONITOR_DATA"
fi

# Test minRatio
echo -e "${YELLOW}Calling minRatio()...${NC}"
MIN_RATIO=$(cast call $MONITOR_ADDRESS "minRatio()" --rpc-url $SEPOLIA_RPC_URL 2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ minRatio: $MIN_RATIO (120 = 1.2x)${NC}"
else
    echo -e "${RED}✗ Failed to call minRatio${NC}"
fi

echo ""
echo -e "${BLUE}=== Test Summary ===${NC}"
echo "View contracts on Etherscan:"
echo "  PriceFeed: https://sepolia.etherscan.io/address/$PRICE_FEED_ADDRESS"
echo "  CollateralizationMonitor: https://sepolia.etherscan.io/address/$MONITOR_ADDRESS"

echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Run workflow simulation: cd ../api-oracle && cre workflow simulate ..."
echo "2. Verify on-chain state after workflow execution"
echo "3. Check transaction hashes on Etherscan"
