#!/bin/bash

set -e

echo "⚠️  WARNING: This will broadcast transactions to Sepolia testnet"
echo "   Ensure you have testnet ETH in your wallet"
echo ""

echo "🔧 Checking .env file..."
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    exit 1
fi

echo "📦 Loading environment variables..."
set -a
source .env
set +a

if [ -z "$API_KEY_VALUE" ]; then
    echo "❌ API_KEY_VALUE not set in .env file!"
    exit 1
fi

if [ -z "$CRE_ETH_PRIVATE_KEY" ]; then
    echo "❌ CRE_ETH_PRIVATE_KEY not set in .env file!"
    exit 1
fi

echo "✅ Secrets loaded"
echo ""
echo "🚀 Running CRE workflow simulation with --broadcast..."
echo ""

cre workflow simulate ./api-oracle --broadcast --target staging-settings

echo ""
echo "✅ Simulation complete!"
