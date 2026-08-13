#!/bin/bash

# API Testing Script
# Tests all endpoints of the Asset Price Service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Asset Price Service - API Testing"
echo "=========================================="
echo ""

# Check if API_URL and API_KEY are set
if [ -z "$API_URL" ]; then
    echo -e "${RED}❌ Error: API_URL environment variable not set${NC}"
    echo ""
    echo "Get your API URL from the deployment output or run:"
    echo "export API_URL=\$(aws cloudformation describe-stacks --stack-name asset-price-service --query 'Stacks[0].Outputs[?OutputKey==\`AssetPriceApiUrl\`].OutputValue' --output text)"
    exit 1
fi

if [ -z "$API_KEY" ]; then
    echo -e "${RED}❌ Error: API_KEY environment variable not set${NC}"
    echo ""
    echo "Get your API Key by running:"
    echo "API_KEY_ID=\$(aws cloudformation describe-stacks --stack-name asset-price-service --query 'Stacks[0].Outputs[?OutputKey==\`ApiKeyId\`].OutputValue' --output text)"
    echo "export API_KEY=\$(aws apigateway get-api-key --api-key \$API_KEY_ID --include-value --query 'value' --output text)"
    exit 1
fi

echo -e "${GREEN}✅ API URL: $API_URL${NC}"
echo -e "${GREEN}✅ API Key: ${API_KEY:0:10}...${NC}"
echo ""

# Test 1: Simulate Data
echo "=========================================="
echo "Test 1: Generate Simulated Data"
echo "=========================================="
RESPONSE=$(curl -s -X POST "${API_URL}simulate" \
    -H "x-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Success (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
else
    echo -e "${RED}❌ Failed (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
fi
echo ""
sleep 1

# Test 2: Get Latest Asset Price
echo "=========================================="
echo "Test 2: Get Latest Asset Price"
echo "=========================================="
RESPONSE=$(curl -s -X GET "${API_URL}asset-price/latest" \
    -H "x-api-key: ${API_KEY}" \
    -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Success (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
else
    echo -e "${RED}❌ Failed (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
fi
echo ""
sleep 1

# Test 3: Get Latest Proof of Reserves
echo "=========================================="
echo "Test 3: Get Latest Proof of Reserves"
echo "=========================================="
RESPONSE=$(curl -s -X GET "${API_URL}proof-of-reserves/latest" \
    -H "x-api-key: ${API_KEY}" \
    -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Success (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
else
    echo -e "${RED}❌ Failed (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
fi
echo ""
sleep 1

# Test 4: Store Custom Asset Price
echo "=========================================="
echo "Test 4: Store Custom Asset Price"
echo "=========================================="
CUSTOM_PRICE=9999.99
RESPONSE=$(curl -s -X POST "${API_URL}asset-price" \
    -H "x-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"price\": $CUSTOM_PRICE}" \
    -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 201 ]; then
    echo -e "${GREEN}✅ Success (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
else
    echo -e "${RED}❌ Failed (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
fi
echo ""
sleep 1

# Test 5: Store Custom Proof of Reserves
echo "=========================================="
echo "Test 5: Store Custom Proof of Reserves"
echo "=========================================="
CUSTOM_COLLATERAL=12000000
RESPONSE=$(curl -s -X POST "${API_URL}proof-of-reserves" \
    -H "x-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"collateralUsd\": $CUSTOM_COLLATERAL}" \
    -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 201 ]; then
    echo -e "${GREEN}✅ Success (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
else
    echo -e "${RED}❌ Failed (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
fi
echo ""
sleep 1

# Test 6: Verify Latest Records Updated
echo "=========================================="
echo "Test 6: Verify Latest Records"
echo "=========================================="
echo "Getting latest asset price (should be $CUSTOM_PRICE)..."
RESPONSE=$(curl -s -X GET "${API_URL}asset-price/latest" \
    -H "x-api-key: ${API_KEY}")
echo "Response: $RESPONSE"
echo ""

echo "Getting latest proof of reserves (should be $CUSTOM_COLLATERAL)..."
RESPONSE=$(curl -s -X GET "${API_URL}proof-of-reserves/latest" \
    -H "x-api-key: ${API_KEY}")
echo "Response: $RESPONSE"
echo ""

# Test 7: Error Handling - Invalid Price
echo "=========================================="
echo "Test 7: Error Handling - Invalid Price"
echo "=========================================="
RESPONSE=$(curl -s -X POST "${API_URL}asset-price" \
    -H "x-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"price": -100}' \
    -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 400 ]; then
    echo -e "${GREEN}✅ Correctly rejected invalid input (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
else
    echo -e "${YELLOW}⚠️  Expected HTTP 400, got $HTTP_CODE${NC}"
    echo "Response: $BODY"
fi
echo ""

# Test 8: Error Handling - Missing API Key
echo "=========================================="
echo "Test 8: Error Handling - Missing API Key"
echo "=========================================="
RESPONSE=$(curl -s -X GET "${API_URL}asset-price/latest" \
    -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 403 ]; then
    echo -e "${GREEN}✅ Correctly rejected request without API key (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
else
    echo -e "${YELLOW}⚠️  Expected HTTP 403, got $HTTP_CODE${NC}"
    echo "Response: $BODY"
fi
echo ""

echo "=========================================="
echo -e "${GREEN}✅ API Testing Complete!${NC}"
echo "=========================================="
