#!/bin/bash

# Verify contracts on Etherscan
# Usage: ./verify.sh <price_feed_address> <monitor_address>

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Contract Verification Script ===${NC}"

if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${RED}Error: Missing contract addresses${NC}"
    echo "Usage: ./verify.sh <price_feed_address> <monitor_address>"
    exit 1
fi

PRICE_FEED_ADDRESS=$1
MONITOR_ADDRESS=$2

if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo -e "${RED}Error: ETHERSCAN_API_KEY environment variable is not set${NC}"
    echo "Get your API key from: https://etherscan.io/myapikey"
    echo "Then set it with: export ETHERSCAN_API_KEY=your_api_key"
    exit 1
fi

echo -e "${GREEN}Verifying PriceFeed contract at $PRICE_FEED_ADDRESS${NC}"
forge verify-contract $PRICE_FEED_ADDRESS \
    src/PriceFeed.sol:PriceFeed \
    --chain-id 11155111 \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --watch || echo -e "${RED}PriceFeed verification failed or already verified${NC}"

echo -e "${GREEN}Verifying CollateralizationMonitor contract at $MONITOR_ADDRESS${NC}"
forge verify-contract $MONITOR_ADDRESS \
    src/CollateralizationMonitor.sol:CollateralizationMonitor \
    --chain-id 11155111 \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --watch || echo -e "${RED}CollateralizationMonitor verification failed or already verified${NC}"

echo -e "${BLUE}=== Verification Complete ===${NC}"
echo "View contracts on Etherscan:"
echo "PriceFeed: https://sepolia.etherscan.io/address/$PRICE_FEED_ADDRESS"
echo "CollateralizationMonitor: https://sepolia.etherscan.io/address/$MONITOR_ADDRESS"
