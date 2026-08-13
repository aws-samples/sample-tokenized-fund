#!/bin/bash

set -e

STACK_NAME="asset-price-service"

echo "🔑 Retrieving API key from CloudFormation stack..."

# Get the API Key ID from CloudFormation outputs
API_KEY_ID=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiKeyId`].OutputValue' \
    --output text)

if [ -z "$API_KEY_ID" ] || [ "$API_KEY_ID" = "None" ]; then
    echo "❌ Could not retrieve API Key ID from stack $STACK_NAME"
    exit 1
fi

# Get the actual API key value using the ID
API_KEY=$(aws apigateway get-api-key --api-key $API_KEY_ID --include-value --query 'value' --output text)

if [ -z "$API_KEY" ] || [ "$API_KEY" = "None" ]; then
    echo "❌ Could not retrieve API key value"
    exit 1
fi

echo "🔗 Retrieving API URL from CloudFormation..."

API_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`AssetPriceApiUrl`].OutputValue' \
    --output text)

if [ -z "$API_URL" ]; then
    echo "❌ Could not retrieve API URL from stack $STACK_NAME"
    exit 1
fi

echo "📝 Setting up .env file..."

# Preserve existing private key if .env exists
EXISTING_PRIVATE_KEY=""
if [ -f .env ]; then
    EXISTING_PRIVATE_KEY=$(grep "^CRE_ETH_PRIVATE_KEY=" .env | cut -d'=' -f2)
fi

# Copy .env-sample to .env
cp .env-sample .env

# Replace the API key placeholder
sed -i.bak "s|your_api_gateway_key_here|$API_KEY|" .env

# Restore existing private key if it was set
if [ ! -z "$EXISTING_PRIVATE_KEY" ] && [ "$EXISTING_PRIVATE_KEY" != "your_64_char_private_key_without_0x_prefix" ]; then
    sed -i.bak "s|your_64_char_private_key_without_0x_prefix|$EXISTING_PRIVATE_KEY|" .env
    echo "✅ Created .env with API_KEY_VALUE=$API_KEY (preserved existing private key)"
else
    echo "✅ Created .env with API_KEY_VALUE=$API_KEY"
fi

rm .env.bak

echo "📝 Updating config.staging.json with API URL..."

CONFIG_FILE="api-oracle/config.staging.json"

if [ -f "$CONFIG_FILE" ]; then
    # Install jq if not present
    if ! command -v jq &> /dev/null; then
        echo "📦 Installing jq..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install jq
        elif command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        else
            echo "⚠️  Could not install jq automatically. Please install manually and re-run."
            exit 1
        fi
    fi
    
    jq --arg url "$API_URL" '.apiUrl = $url' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo "✅ Updated $CONFIG_FILE with apiUrl=$API_URL"
else
    echo "⚠️  $CONFIG_FILE not found"
fi

echo ""
echo "⚠️  NEXT STEP: Add your Ethereum private key to .env"
echo "   Edit .env and replace:"
echo "   CRE_ETH_PRIVATE_KEY=your_64_char_private_key_without_0x_prefix"
echo ""
echo "   Get your private key from MetaMask:"
echo "   Account Details → Show Private Key → Copy (remove 0x prefix)"
