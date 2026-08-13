#!/bin/bash

# Environment Setup Script
# This script exports API_URL and API_KEY environment variables for easy testing

set -e

STACK_NAME="asset-price-service"

echo "=========================================="
echo "Setting up environment variables"
echo "=========================================="
echo ""

# Check if stack exists
if ! aws cloudformation describe-stacks --stack-name $STACK_NAME &> /dev/null; then
    echo "❌ Error: Stack '$STACK_NAME' not found"
    echo "Please deploy the stack first using ./deploy.sh"
    exit 1
fi

# Get API URL
echo "🔍 Getting API URL..."
API_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`AssetPriceApiUrl`].OutputValue' \
    --output text)

if [ -z "$API_URL" ]; then
    echo "❌ Error: Could not retrieve API URL"
    exit 1
fi

echo "✅ API URL: $API_URL"

# Get API Key
echo "🔍 Getting API Key..."
API_KEY_ID=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiKeyId`].OutputValue' \
    --output text)

if [ -z "$API_KEY_ID" ]; then
    echo "❌ Error: Could not retrieve API Key ID"
    exit 1
fi

API_KEY=$(aws apigateway get-api-key \
    --api-key $API_KEY_ID \
    --include-value \
    --query 'value' \
    --output text)

if [ -z "$API_KEY" ]; then
    echo "❌ Error: Could not retrieve API Key value"
    exit 1
fi

echo "✅ API Key: ${API_KEY:0:10}..."
echo ""

# Export variables
export API_URL
export API_KEY

echo "=========================================="
echo "✅ Environment variables set!"
echo "=========================================="

echo "Now you can use the test script:"
echo "./test-api.sh"
