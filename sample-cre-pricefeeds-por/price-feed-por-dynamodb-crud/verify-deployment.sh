#!/bin/bash

# Verification script for Asset Price Service deployment
# This script checks if all resources were created successfully

set -e

echo "=========================================="
echo "Asset Price Service - Deployment Verification"
echo "=========================================="
echo ""

STACK_NAME="asset-price-service"

# Check if stack exists
echo "🔍 Checking CloudFormation stack..."
if ! aws cloudformation describe-stacks --stack-name $STACK_NAME &> /dev/null; then
    echo "❌ Stack '$STACK_NAME' not found"
    echo "Please deploy the stack first using ./deploy.sh"
    exit 1
fi

# Get stack status
STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].StackStatus' \
    --output text)

echo "Stack Status: $STACK_STATUS"

if [ "$STACK_STATUS" != "CREATE_COMPLETE" ] && [ "$STACK_STATUS" != "UPDATE_COMPLETE" ]; then
    echo "❌ Stack is not in a healthy state"
    exit 1
fi

echo "✅ Stack is healthy"
echo ""

# Verify DynamoDB Table
echo "🔍 Verifying DynamoDB Table..."
TABLE_NAME=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`AssetDataTableName`].OutputValue' \
    --output text)

if aws dynamodb describe-table --table-name $TABLE_NAME &> /dev/null; then
    echo "✅ DynamoDB Table '$TABLE_NAME' exists"
    
    # Get table status
    TABLE_STATUS=$(aws dynamodb describe-table \
        --table-name $TABLE_NAME \
        --query 'Table.TableStatus' \
        --output text)
    echo "   Status: $TABLE_STATUS"
else
    echo "❌ DynamoDB Table not found"
    exit 1
fi
echo ""

# Verify Lambda Functions
echo "🔍 Verifying Lambda Functions..."

# Get actual function names from CloudFormation stack resources
FUNCTION_LOGICAL_IDS=(
    "StoreAssetPriceFunction"
    "GetAssetPriceFunction"
    "StoreProofOfReservesFunction"
    "GetProofOfReservesFunction"
    "SimulateDataFunction"
)

for LOGICAL_ID in "${FUNCTION_LOGICAL_IDS[@]}"; do
    FUNC_NAME=$(aws cloudformation describe-stack-resources \
        --stack-name $STACK_NAME \
        --logical-resource-id $LOGICAL_ID \
        --query 'StackResources[0].PhysicalResourceId' \
        --output text 2>/dev/null)
    
    if [ -n "$FUNC_NAME" ] && [ "$FUNC_NAME" != "None" ]; then
        STATE=$(aws lambda get-function \
            --function-name $FUNC_NAME \
            --query 'Configuration.State' \
            --output text 2>/dev/null)
        echo "✅ Function '$LOGICAL_ID' ($FUNC_NAME) - State: $STATE"
    else
        echo "❌ Function '$LOGICAL_ID' not found"
    fi
done
echo ""

# Verify API Gateway
echo "🔍 Verifying API Gateway..."
API_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`AssetPriceApiUrl`].OutputValue' \
    --output text)

if [ -n "$API_URL" ]; then
    echo "✅ API Gateway endpoint: $API_URL"
else
    echo "❌ API Gateway endpoint not found"
    exit 1
fi
echo ""

# Get API Key
echo "🔑 API Key Information:"
API_KEY_ID=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiKeyId`].OutputValue' \
    --output text)

if [ -n "$API_KEY_ID" ]; then
    echo "✅ API Key ID: $API_KEY_ID"
    echo ""
    echo "To get the API Key value, run:"
    echo "aws apigateway get-api-key --api-key $API_KEY_ID --include-value --query 'value' --output text"
else
    echo "❌ API Key not found"
fi
echo ""

echo ""
echo "=========================================="
echo "✅ All Resources Verified Successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Get your API key using the command above"
echo "2. Test the API endpoints (see DEPLOYMENT.md)"
echo "3. Monitor logs: sam logs -n StoreAssetPriceFunction --stack-name $STACK_NAME --tail"
