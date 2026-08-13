#!/bin/bash

# Deploy SyntheticToken and SyntheticMinter contracts to Sepolia testnet
# Usage: ./deploy.sh

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Synthetic Asset Minter Deployment Script ===${NC}"

# Check if required environment variables are set
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY environment variable is not set${NC}"
    echo "Please set it with: export PRIVATE_KEY=your_private_key"
    exit 1
fi

if [ -z "$OWNER_ADDRESS" ]; then
    echo -e "${YELLOW}OWNER_ADDRESS not set, deriving from PRIVATE_KEY...${NC}"
    export OWNER_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)
fi

# Set default RPC URL if not provided
if [ -z "$RPC_URL" ]; then
    echo -e "${YELLOW}Warning: RPC_URL not set, using default Sepolia RPC${NC}"
    export RPC_URL="https://ethereum-sepolia-rpc.publicnode.com"
fi

# Set default USDC address for Sepolia if not provided
# Circle's official USDC on Sepolia: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
if [ -z "$USDC_ADDRESS" ]; then
    echo -e "${YELLOW}Warning: USDC_ADDRESS not set, using Sepolia USDC${NC}"
    export USDC_ADDRESS="0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"
fi

# Set fee recipient to owner if not provided
if [ -z "$FEE_RECIPIENT" ]; then
    export FEE_RECIPIENT=$OWNER_ADDRESS
fi

# Check if forge is installed
if ! command -v forge &> /dev/null; then
    echo -e "${RED}Error: forge is not installed${NC}"
    echo "Please install Foundry: https://book.getfoundry.sh/getting-started/installation"
    exit 1
fi

echo -e "${GREEN}Configuration:${NC}"
echo "  RPC URL: $RPC_URL"
echo "  Owner: $OWNER_ADDRESS"
echo "  USDC: $USDC_ADDRESS"
echo "  Fee Recipient: $FEE_RECIPIENT"
echo ""

# Fetch current gas prices
echo -e "${GREEN}Step 1: Fetching current gas prices${NC}"
BASE_FEE=$(cast gas-price --rpc-url $RPC_URL 2>/dev/null || echo "1000000000")
PRIORITY_FEE=$((BASE_FEE / 10))
if [ $PRIORITY_FEE -lt 1000000000 ]; then
    PRIORITY_FEE=1000000000  # Minimum 1 gwei
fi
MAX_FEE=$((BASE_FEE + PRIORITY_FEE + PRIORITY_FEE))
echo "  Base fee: $BASE_FEE wei"
echo "  Priority fee: $PRIORITY_FEE wei"
echo "  Max fee: $MAX_FEE wei"
echo ""

# Deploy SyntheticToken
echo -e "${GREEN}Step 2: Deploying SyntheticToken${NC}"
TOKEN_OUTPUT=$(forge script script/DeploySyntheticToken.s.sol:DeploySyntheticToken \
    --rpc-url $RPC_URL \
    --broadcast \
    --priority-gas-price $PRIORITY_FEE \
    --with-gas-price $MAX_FEE \
    -vvv 2>&1)

echo "$TOKEN_OUTPUT"

# Extract SyntheticToken address from output
SYNTHETIC_TOKEN_ADDRESS=$(echo "$TOKEN_OUTPUT" | grep "SyntheticToken deployed to:" | awk '{print $NF}')

if [ -z "$SYNTHETIC_TOKEN_ADDRESS" ]; then
    echo -e "${RED}Error: Failed to extract SyntheticToken address${NC}"
    exit 1
fi

echo -e "${GREEN}SyntheticToken deployed at: $SYNTHETIC_TOKEN_ADDRESS${NC}"
export SYNTHETIC_TOKEN_ADDRESS
echo ""

# Deploy SyntheticMinter
echo -e "${GREEN}Step 3: Deploying SyntheticMinter${NC}"
MINTER_OUTPUT=$(forge script script/DeploySyntheticMinter.s.sol:DeploySyntheticMinter \
    --rpc-url $RPC_URL \
    --broadcast \
    --priority-gas-price $PRIORITY_FEE \
    --with-gas-price $MAX_FEE \
    -vvv 2>&1)

echo "$MINTER_OUTPUT"

# Extract SyntheticMinter address from output
SYNTHETIC_MINTER_ADDRESS=$(echo "$MINTER_OUTPUT" | grep "SyntheticMinter deployed to:" | awk '{print $NF}')

if [ -z "$SYNTHETIC_MINTER_ADDRESS" ]; then
    echo -e "${RED}Error: Failed to extract SyntheticMinter address${NC}"
    exit 1
fi

echo -e "${GREEN}SyntheticMinter deployed at: $SYNTHETIC_MINTER_ADDRESS${NC}"
export SYNTHETIC_MINTER_ADDRESS
echo ""

# Set SyntheticMinter as minter on SyntheticToken
echo -e "${GREEN}Step 4: Setting SyntheticMinter as authorized minter${NC}"
cast send $SYNTHETIC_TOKEN_ADDRESS \
    "setMinter(address)" $SYNTHETIC_MINTER_ADDRESS \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --priority-gas-price $PRIORITY_FEE \
    --gas-price $MAX_FEE

echo -e "${GREEN}Minter configured successfully${NC}"
echo ""

# Print deployment summary
echo -e "${BLUE}=== Deployment Summary ===${NC}"
echo -e "SyntheticToken (sSPY): ${GREEN}$SYNTHETIC_TOKEN_ADDRESS${NC}"
echo -e "SyntheticMinter:        ${GREEN}$SYNTHETIC_MINTER_ADDRESS${NC}"
echo -e "USDC:                   ${GREEN}$USDC_ADDRESS${NC}"
echo -e "Owner:                  ${GREEN}$OWNER_ADDRESS${NC}"
echo ""

# Save addresses to file
ADDRESSES_FILE="deployed-addresses.json"
cat > $ADDRESSES_FILE << EOF
{
  "network": "sepolia",
  "chainId": 11155111,
  "deployedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "contracts": {
    "SyntheticToken": "$SYNTHETIC_TOKEN_ADDRESS",
    "SyntheticMinter": "$SYNTHETIC_MINTER_ADDRESS",
    "USDC": "$USDC_ADDRESS"
  },
  "configuration": {
    "owner": "$OWNER_ADDRESS",
    "feeRecipient": "$FEE_RECIPIENT",
    "minCollateralizationRatio": 150,
    "mintFeeBps": 30,
    "stalenessWindow": 3600
  }
}
EOF
echo -e "${GREEN}Addresses saved to: $ADDRESSES_FILE${NC}"

# Publish to the web UI so it auto-loads the new addresses (no manual edit needed)
cp "$ADDRESSES_FILE" ../ui/deployed-addresses.json 2>/dev/null && \
  echo -e "${GREEN}Addresses published to: ui/deployed-addresses.json${NC}"
echo ""

# Print next steps
echo -e "${BLUE}=== Next Steps ===${NC}"
echo ""
echo "1. Configure CRE feed addresses (after deploying PriceFeed and CollateralizationMonitor):"
echo ""
echo -e "   ${YELLOW}export PRICE_FEED_ADDRESS=<your-price-feed-address>${NC}"
echo -e "   ${YELLOW}export COLLATERAL_MONITOR_ADDRESS=<your-collateral-monitor-address>${NC}"
echo ""
echo "   cast send $SYNTHETIC_MINTER_ADDRESS \\"
echo "     \"setPriceFeed(address)\" \$PRICE_FEED_ADDRESS \\"
echo "     --rpc-url $RPC_URL \\"
echo "     --private-key \$PRIVATE_KEY"
echo ""
echo "   cast send $SYNTHETIC_MINTER_ADDRESS \\"
echo "     \"setCollateralMonitor(address)\" \$COLLATERAL_MONITOR_ADDRESS \\"
echo "     --rpc-url $RPC_URL \\"
echo "     --private-key \$PRIVATE_KEY"
echo ""
echo "2. Update config.staging.json with deployed addresses:"
echo ""
echo "   \"syntheticMinterAddress\": \"$SYNTHETIC_MINTER_ADDRESS\","
echo "   \"syntheticTokenAddress\": \"$SYNTHETIC_TOKEN_ADDRESS\""
echo ""
echo "3. Generate Go bindings for CRE workflow:"
echo ""
echo "   cd ../sample-cre-pricefeeds-por/aws-oracle-cre"
echo "   cre generate-bindings evm"
echo ""

echo -e "${BLUE}=== Etherscan Links ===${NC}"
echo "SyntheticToken: https://sepolia.etherscan.io/address/$SYNTHETIC_TOKEN_ADDRESS"
echo "SyntheticMinter: https://sepolia.etherscan.io/address/$SYNTHETIC_MINTER_ADDRESS"
echo ""

echo -e "${BLUE}=== Verification Commands ===${NC}"
echo ""
echo "forge verify-contract $SYNTHETIC_TOKEN_ADDRESS \\"
echo "  src/SyntheticToken.sol:SyntheticToken \\"
echo "  --chain-id 11155111 \\"
echo "  --constructor-args \$(cast abi-encode \"constructor(string,string,address)\" \"Synthetic S&P 500\" \"sSPY\" $OWNER_ADDRESS) \\"
echo "  --etherscan-api-key \$ETHERSCAN_API_KEY"
echo ""
echo "forge verify-contract $SYNTHETIC_MINTER_ADDRESS \\"
echo "  src/SyntheticMinter.sol:SyntheticMinter \\"
echo "  --chain-id 11155111 \\"
echo "  --constructor-args \$(cast abi-encode \"constructor(address,address,address,address)\" $USDC_ADDRESS $SYNTHETIC_TOKEN_ADDRESS $OWNER_ADDRESS $FEE_RECIPIENT) \\"
echo "  --etherscan-api-key \$ETHERSCAN_API_KEY"
echo ""

echo -e "${GREEN}=== Deployment Complete ===${NC}"
