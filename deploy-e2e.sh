#!/bin/bash
# =============================================================================
# End-to-End Deployment & Integration Test Script
# Synthetic Asset Minter with CRE Oracle Integration
# =============================================================================
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAMBDA_DIR="$SCRIPT_DIR/sample-cre-pricefeeds-por/price-feed-por-dynamodb-crud"
CRE_DIR="$SCRIPT_DIR/sample-cre-pricefeeds-por/aws-oracle-cre"
MINTER_DIR="$SCRIPT_DIR/synthetic-asset-minter"

# Output file for deployed addresses
DEPLOYED_ADDRESSES="$SCRIPT_DIR/deployed-addresses.json"

# Source root .env if it exists (secrets, API keys, config)
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Default configuration (env vars from .env or shell take precedence)
RPC_URL="${RPC_URL:-https://ethereum-sepolia-rpc.publicnode.com}"
USDC_ADDRESS="${USDC_ADDRESS:-0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238}"
KEYSTONE_FORWARDER="${KEYSTONE_FORWARDER:-0x15fC6ae953E024d975e77382eEeC56A9101f9F88}"
CHAIN_ID=11155111
AWS_REGION_OVERRIDE=""

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

# =============================================================================
# PHASE 0: Prerequisites Check
# =============================================================================
check_prerequisites() {
    log "Checking prerequisites..."
    
    local missing=()
    
    command -v aws &>/dev/null || missing+=("aws")
    command -v sam &>/dev/null || missing+=("sam")
    command -v forge &>/dev/null || missing+=("forge")
    command -v cast &>/dev/null || missing+=("cast")
    command -v jq &>/dev/null || missing+=("jq")
    command -v curl &>/dev/null || missing+=("curl")
    command -v node &>/dev/null || missing+=("node")
    command -v go &>/dev/null || missing+=("go")
    command -v esbuild &>/dev/null || missing+=("esbuild (npm install -g esbuild)")
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing tools: ${missing[*]}\nRun: ./sample-cre-pricefeeds-por/deploy-all.sh to auto-install"
    fi
    
    # Check AWS credentials
    aws sts get-caller-identity &>/dev/null || error "AWS credentials not configured"
    
    # Check private key
    if [ -z "$PRIVATE_KEY" ]; then
        if [ -f "$CRE_DIR/.env" ]; then
            source "$CRE_DIR/.env"
            if [ -n "$CRE_ETH_PRIVATE_KEY" ]; then
                export PRIVATE_KEY="0x$CRE_ETH_PRIVATE_KEY"
            fi
        fi
    fi
    [ -z "$PRIVATE_KEY" ] && error "PRIVATE_KEY not set. Export it or add CRE_ETH_PRIVATE_KEY to $CRE_DIR/.env"
    
    # Derive owner address
    export OWNER_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)
    export FEE_RECIPIENT=$OWNER_ADDRESS

    # Check ETH balance (need ~0.05 ETH for all deploys + config txns)
    local BALANCE_WEI=$(cast balance $OWNER_ADDRESS --rpc-url $RPC_URL)
    local BALANCE_ETH=$(echo "scale=6; $BALANCE_WEI / 1000000000000000000" | bc)
    local MIN_BALANCE=20000000000000000  # 0.02 ETH minimum
    if [ "$BALANCE_WEI" -lt "$MIN_BALANCE" ] 2>/dev/null; then
        warn "Low ETH balance: ${BALANCE_ETH} ETH. Deployments require ~0.05 ETH."
        warn "Get Sepolia ETH from https://www.alchemy.com/faucets/ethereum-sepolia"
    fi

    success "Prerequisites OK - Deployer: $OWNER_ADDRESS (${BALANCE_ETH} ETH)"
}

# =============================================================================
# PHASE 1: Deploy AWS Lambda Infrastructure
# =============================================================================
deploy_lambda() {
    log "PHASE 1: Deploying AWS Lambda infrastructure..."
    
    cd "$LAMBDA_DIR"
    
    # Install dependencies and build
    npm install --silent
    sam build --cached

    # Build parameter overrides for stock API keys and symbol
    PARAM_OVERRIDES="--parameter-overrides StockSymbol=${STOCK_SYMBOL:-SPY}"
    [ -n "$FINNHUB_API_KEY" ] && PARAM_OVERRIDES="$PARAM_OVERRIDES StockApiKey=$FINNHUB_API_KEY"
    [ -n "$ALPHA_VANTAGE_API_KEY" ] && PARAM_OVERRIDES="$PARAM_OVERRIDES AlphaVantageApiKey=$ALPHA_VANTAGE_API_KEY"

    # Determine region
    if [ -n "$AWS_REGION_OVERRIDE" ]; then
        LAMBDA_REGION="$AWS_REGION_OVERRIDE"
        PARAM_OVERRIDES="$PARAM_OVERRIDES --region $LAMBDA_REGION"
    fi

    # Deploy
    sam deploy --no-confirm-changeset --no-fail-on-empty-changeset $PARAM_OVERRIDES

    # Get the region SAM deployed to (from samconfig.toml or override)
    if [ -z "$LAMBDA_REGION" ]; then
        LAMBDA_REGION=$(grep -m1 'region' samconfig.toml | awk -F'"' '{print $2}')
        LAMBDA_REGION="${LAMBDA_REGION:-us-east-1}"
    fi

    # Get outputs
    export API_URL=$(aws cloudformation describe-stacks \
        --stack-name asset-price-service --region $LAMBDA_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`AssetPriceApiUrl`].OutputValue' \
        --output text)

    API_KEY_ID=$(aws cloudformation describe-stacks \
        --stack-name asset-price-service --region $LAMBDA_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ApiKeyId`].OutputValue' \
        --output text)
    
    export API_KEY_VALUE=$(aws apigateway get-api-key --api-key $API_KEY_ID --include-value --region $LAMBDA_REGION --query 'value' --output text)
    
    # Populate test data
    curl -sX POST "${API_URL}simulate" -H "x-api-key: ${API_KEY_VALUE}" -H "Content-Type: application/json" >/dev/null
    
    # Verify stock price endpoint
    STOCK_RESPONSE=$(curl -s "${API_URL}stock-price/latest" -H "x-api-key: ${API_KEY_VALUE}")
    STOCK_PRICE=$(echo "$STOCK_RESPONSE" | jq -r '.price // empty')
    
    [ -z "$STOCK_PRICE" ] && error "Stock price endpoint not returning data"
    
    success "Lambda deployed - API: $API_URL, Stock Price: \$$STOCK_PRICE"
    cd "$SCRIPT_DIR"
}

# =============================================================================
# PHASE 2: Deploy CRE Oracle Contracts (PriceFeed + CollateralizationMonitor)
# =============================================================================
deploy_cre_contracts() {
    log "PHASE 2: Deploying CRE oracle contracts..."

    cd "$CRE_DIR/contracts/evm"

    # Ensure forge dependencies are installed
    forge install --no-commit 2>/dev/null || true

    export SEPOLIA_RPC_URL="$RPC_URL"
    
    # Get gas prices
    BASE_FEE=$(cast gas-price --rpc-url $RPC_URL 2>/dev/null || echo "1000000000")
    PRIORITY_FEE=$((BASE_FEE / 10))
    [ $PRIORITY_FEE -lt 1000000000 ] && PRIORITY_FEE=1000000000
    MAX_FEE=$((BASE_FEE + PRIORITY_FEE + PRIORITY_FEE))
    
    # Deploy PriceFeed
    log "Deploying PriceFeed..."
    local pf_rc=0
    PF_OUTPUT=$(forge script script/DeployPriceFeed.s.sol:DeployPriceFeed \
        --rpc-url $RPC_URL --broadcast \
        --priority-gas-price $PRIORITY_FEE --with-gas-price $MAX_FEE -vvv 2>&1) || pf_rc=$?

    if [ $pf_rc -ne 0 ]; then
        echo "$PF_OUTPUT" | tail -20
        error "Failed to deploy PriceFeed (forge exit code $pf_rc)"
    fi

    export PRICE_FEED_ADDRESS=$(echo "$PF_OUTPUT" | grep "PriceFeed deployed to:" | awk '{print $NF}')
    [ -z "$PRICE_FEED_ADDRESS" ] && error "Failed to deploy PriceFeed (no address in output)"

    # Deploy CollateralizationMonitor
    log "Deploying CollateralizationMonitor..."
    local cm_rc=0
    CM_OUTPUT=$(forge script script/DeployCollateralizationMonitor.s.sol:DeployCollateralizationMonitor \
        --rpc-url $RPC_URL --broadcast \
        --priority-gas-price $PRIORITY_FEE --with-gas-price $MAX_FEE -vvv 2>&1) || cm_rc=$?

    if [ $cm_rc -ne 0 ]; then
        echo "$CM_OUTPUT" | tail -20
        error "Failed to deploy CollateralizationMonitor (forge exit code $cm_rc)"
    fi

    export COLLATERAL_MONITOR_ADDRESS=$(echo "$CM_OUTPUT" | grep "CollateralizationMonitor deployed to:" | awk '{print $NF}')
    [ -z "$COLLATERAL_MONITOR_ADDRESS" ] && error "Failed to deploy CollateralizationMonitor (no address in output)"
    
    # Set forwarder to the Chainlink KeystoneForwarder on Sepolia
    log "Setting forwarder on PriceFeed to KeystoneForwarder ($KEYSTONE_FORWARDER)..."
    cast send $PRICE_FEED_ADDRESS "setForwarder(address)" $KEYSTONE_FORWARDER \
        --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
        --priority-gas-price $PRIORITY_FEE --gas-price $MAX_FEE >/dev/null

    log "Setting forwarder on CollateralizationMonitor to KeystoneForwarder ($KEYSTONE_FORWARDER)..."
    cast send $COLLATERAL_MONITOR_ADDRESS "setForwarder(address)" $KEYSTONE_FORWARDER \
        --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
        --priority-gas-price $PRIORITY_FEE --gas-price $MAX_FEE >/dev/null

    success "CRE contracts deployed - PriceFeed: $PRICE_FEED_ADDRESS, Monitor: $COLLATERAL_MONITOR_ADDRESS"
    cd "$SCRIPT_DIR"
}

# =============================================================================
# PHASE 3: Deploy Synthetic Asset Minter Contracts
# =============================================================================
deploy_minter_contracts() {
    log "PHASE 3: Deploying Synthetic Asset Minter contracts..."

    cd "$MINTER_DIR"

    # Ensure forge dependencies are installed
    forge install --no-commit 2>/dev/null || true

    export RPC_URL
    
    # Get gas prices
    BASE_FEE=$(cast gas-price --rpc-url $RPC_URL 2>/dev/null || echo "1000000000")
    PRIORITY_FEE=$((BASE_FEE / 10))
    [ $PRIORITY_FEE -lt 1000000000 ] && PRIORITY_FEE=1000000000
    MAX_FEE=$((BASE_FEE + PRIORITY_FEE + PRIORITY_FEE))
    
    # Deploy SyntheticToken
    log "Deploying SyntheticToken..."
    local tk_rc=0
    TOKEN_OUTPUT=$(forge script script/DeploySyntheticToken.s.sol:DeploySyntheticToken \
        --rpc-url $RPC_URL --broadcast \
        --priority-gas-price $PRIORITY_FEE --with-gas-price $MAX_FEE -vvv 2>&1) || tk_rc=$?

    if [ $tk_rc -ne 0 ]; then
        echo "$TOKEN_OUTPUT" | tail -20
        error "Failed to deploy SyntheticToken (forge exit code $tk_rc)"
    fi

    export SYNTHETIC_TOKEN_ADDRESS=$(echo "$TOKEN_OUTPUT" | grep "SyntheticToken deployed to:" | awk '{print $NF}')
    [ -z "$SYNTHETIC_TOKEN_ADDRESS" ] && error "Failed to deploy SyntheticToken (no address in output)"

    # Deploy SyntheticMinter
    log "Deploying SyntheticMinter..."
    local mt_rc=0
    MINTER_OUTPUT=$(forge script script/DeploySyntheticMinter.s.sol:DeploySyntheticMinter \
        --rpc-url $RPC_URL --broadcast \
        --priority-gas-price $PRIORITY_FEE --with-gas-price $MAX_FEE -vvv 2>&1) || mt_rc=$?

    if [ $mt_rc -ne 0 ]; then
        echo "$MINTER_OUTPUT" | tail -20
        error "Failed to deploy SyntheticMinter (forge exit code $mt_rc)"
    fi

    export SYNTHETIC_MINTER_ADDRESS=$(echo "$MINTER_OUTPUT" | grep "SyntheticMinter deployed to:" | awk '{print $NF}')
    [ -z "$SYNTHETIC_MINTER_ADDRESS" ] && error "Failed to deploy SyntheticMinter (no address in output)"
    
    success "Minter contracts deployed - Token: $SYNTHETIC_TOKEN_ADDRESS, Minter: $SYNTHETIC_MINTER_ADDRESS"
    cd "$SCRIPT_DIR"
}

# =============================================================================
# PHASE 4: Configure Contracts
# =============================================================================
configure_contracts() {
    log "PHASE 4: Configuring contracts..."
    
    BASE_FEE=$(cast gas-price --rpc-url $RPC_URL 2>/dev/null || echo "1000000000")
    PRIORITY_FEE=$((BASE_FEE / 10))
    [ $PRIORITY_FEE -lt 1000000000 ] && PRIORITY_FEE=1000000000
    MAX_FEE=$((BASE_FEE + PRIORITY_FEE + PRIORITY_FEE))
    
    # Set minter on SyntheticToken
    log "Setting SyntheticMinter as authorized minter..."
    cast send $SYNTHETIC_TOKEN_ADDRESS "setMinter(address)" $SYNTHETIC_MINTER_ADDRESS \
        --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
        --priority-gas-price $PRIORITY_FEE --gas-price $MAX_FEE >/dev/null
    
    # Set price feed on SyntheticMinter
    log "Setting PriceFeed address..."
    cast send $SYNTHETIC_MINTER_ADDRESS "setPriceFeed(address)" $PRICE_FEED_ADDRESS \
        --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
        --priority-gas-price $PRIORITY_FEE --gas-price $MAX_FEE >/dev/null
    
    # Set collateral monitor on SyntheticMinter
    log "Setting CollateralMonitor address..."
    cast send $SYNTHETIC_MINTER_ADDRESS "setCollateralMonitor(address)" $COLLATERAL_MONITOR_ADDRESS \
        --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
        --priority-gas-price $PRIORITY_FEE --gas-price $MAX_FEE >/dev/null
    
    success "Contracts configured"
}

# =============================================================================
# PHASE 5: Update CRE Configuration
# =============================================================================
update_cre_config() {
    log "PHASE 5: Updating CRE configuration..."

    CONFIG_FILE="$CRE_DIR/api-oracle/config.staging.json"

    # If API_URL not set (lambda was skipped), try to fetch from CloudFormation
    if [ -z "$API_URL" ]; then
        if [ -n "$AWS_REGION_OVERRIDE" ]; then
            LAMBDA_REGION="$AWS_REGION_OVERRIDE"
        else
            LAMBDA_REGION=$(grep -m1 'region' "$LAMBDA_DIR/samconfig.toml" | awk -F'"' '{print $2}')
            LAMBDA_REGION="${LAMBDA_REGION:-us-east-1}"
        fi
        export API_URL=$(aws cloudformation describe-stacks \
            --stack-name asset-price-service --region $LAMBDA_REGION \
            --query 'Stacks[0].Outputs[?OutputKey==`AssetPriceApiUrl`].OutputValue' \
            --output text 2>/dev/null || echo "")
        if [ -n "$API_URL" ] && [ "$API_URL" != "None" ]; then
            API_KEY_ID=$(aws cloudformation describe-stacks \
                --stack-name asset-price-service --region $LAMBDA_REGION \
                --query 'Stacks[0].Outputs[?OutputKey==`ApiKeyId`].OutputValue' \
                --output text 2>/dev/null)
            export API_KEY_VALUE=$(aws apigateway get-api-key --api-key $API_KEY_ID --include-value --region $LAMBDA_REGION --query 'value' --output text 2>/dev/null || echo "")
            log "Fetched existing Lambda API URL: $API_URL"
        fi
    fi

    # config.staging.json is gitignored (deploy-specific), so a fresh clone won't have one.
    # Without this the jq update below reads a missing file, fails silently, and the CRE
    # workflow later aborts with "ConfigPath must be a valid existing file". Seed a template.
    if [ ! -f "$CONFIG_FILE" ]; then
        log "config.staging.json not found — creating from template"
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" << 'STAGING_EOF'
{
  "schedule": "*/30 * * * * *",
  "apiUrl": "",
  "stockPriceApiUrl": "",
  "minCollateralizationRatio": 1.2,
  "evms": [
    {
      "chainName": "ethereum-testnet-sepolia",
      "priceFeedAddress": "",
      "collateralizationMonitorAddress": "",
      "syntheticMinterAddress": "",
      "syntheticTokenAddress": "",
      "gasLimit": 500000
    }
  ]
}
STAGING_EOF
    fi

    # Update config.staging.json
    jq --arg api "$API_URL" \
       --arg pf "$PRICE_FEED_ADDRESS" \
       --arg cm "$COLLATERAL_MONITOR_ADDRESS" \
       --arg sm "$SYNTHETIC_MINTER_ADDRESS" \
       --arg st "$SYNTHETIC_TOKEN_ADDRESS" \
       '.apiUrl = $api | .stockPriceApiUrl = $api |
        .evms[0].priceFeedAddress = $pf |
        .evms[0].collateralizationMonitorAddress = $cm |
        .evms[0].syntheticMinterAddress = $sm |
        .evms[0].syntheticTokenAddress = $st' \
       "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    
    # Update .env with API key and private key
    ENV_FILE="$CRE_DIR/.env"
    # Strip 0x prefix for CRE (it expects raw hex)
    CRE_KEY="${PRIVATE_KEY#0x}"

    if grep -q "^API_KEY_VALUE=" "$ENV_FILE" 2>/dev/null; then
        sed -i.bak "s|^API_KEY_VALUE=.*|API_KEY_VALUE=$API_KEY_VALUE|" "$ENV_FILE"
        rm -f "${ENV_FILE}.bak"
    else
        echo "API_KEY_VALUE=$API_KEY_VALUE" >> "$ENV_FILE"
    fi

    if grep -q "^CRE_ETH_PRIVATE_KEY=" "$ENV_FILE" 2>/dev/null; then
        sed -i.bak "s|^CRE_ETH_PRIVATE_KEY=.*|CRE_ETH_PRIVATE_KEY=$CRE_KEY|" "$ENV_FILE"
        rm -f "${ENV_FILE}.bak"
    else
        echo "CRE_ETH_PRIVATE_KEY=$CRE_KEY" >> "$ENV_FILE"
    fi

    # Point CRE's chain-write RPC at the configured RPC_URL for this run. project.yaml ships a
    # public default RPC (which can be unreliable / unreachable); the rest of the deploy already
    # uses $RPC_URL, so make CRE consistent. Restore project.yaml on exit so the tracked file is
    # not left holding a (possibly key-bearing) RPC endpoint.
    if [ -n "$RPC_URL" ] && ! grep -q "url: $RPC_URL" "$CRE_DIR/project.yaml"; then
        cp "$CRE_DIR/project.yaml" "$CRE_DIR/project.yaml.deploybak"
        trap 'mv -f "$CRE_DIR/project.yaml.deploybak" "$CRE_DIR/project.yaml" 2>/dev/null || true' EXIT
        sed -i.bak "s|url: https://[^[:space:]]*|url: $RPC_URL|g" "$CRE_DIR/project.yaml"
        rm -f "$CRE_DIR/project.yaml.bak"
        log "CRE RPC set to \$RPC_URL for this run (project.yaml restored on exit)"
    fi

    # Generate Go bindings
    # NOTE: If behind a corporate proxy/firewall, you MUST run: export GOPROXY=direct
    log "Generating CRE Go bindings..."
    cd "$CRE_DIR"
    cre generate-bindings evm 2>/dev/null || warn "Bindings generation skipped (may already exist)"
    go mod tidy 2>/dev/null || true
    cd "$SCRIPT_DIR"
    
    success "CRE configuration updated"
}

# =============================================================================
# PHASE 6: Run CRE Workflow (Dry Run or Broadcast)
# =============================================================================
run_cre_workflow() {
    log "PHASE 6: Running CRE workflow (broadcast to write price on-chain)..."

    cd "$CRE_DIR"

    # Check CRE auth
    if ! cre whoami &>/dev/null; then
        warn "CRE not authenticated. Run 'cre login' first. Skipping CRE workflow."
        cd "$SCRIPT_DIR"
        return 0
    fi

    # Retry the CRE Workflow on transient failures (ie flaky public RPC)
    local max_attempts=3
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if cre workflow simulate ./api-oracle --broadcast --target staging-settings 2>&1; then
            cd "$SCRIPT_DIR"
            success "CRE workflow completed"
            return 0
        fi
        if [ $attempt -lt $max_attempts ]; then
            warn "CRE workflow failed (attempt $attempt/$max_attempts) - retrying in 5s..."
            sleep 5
        fi
        attempt=$((attempt + 1))
    done

    cd "$SCRIPT_DIR"
    warn "CRE workflow failed after $max_attempts attempts (nonce conflicts). Try running manually."
}

# =============================================================================
# PHASE 7: Integration Test (with auto-refresh if stale)
# =============================================================================
run_integration_test() {
    log "PHASE 7: Running integration test..."
    
    parse_uint() { echo "$1" | awk '{print $1}'; }
    
    # Check price feed
    log "Checking CRE price feed..."
    PRICE_DATA=$(cast call $PRICE_FEED_ADDRESS "getLatestPrice()(uint256,uint256)" --rpc-url $RPC_URL)
    PRICE=$(parse_uint "$(echo "$PRICE_DATA" | head -1)")
    PRICE_TS=$(parse_uint "$(echo "$PRICE_DATA" | tail -1)")
    
    NOW=$(date +%s)
    AGE=$((NOW - PRICE_TS))
    
    # Check staleness and auto-refresh if needed
    STALENESS=$(parse_uint "$(cast call $SYNTHETIC_MINTER_ADDRESS 'stalenessWindow()(uint256)' --rpc-url $RPC_URL)")
    
    if [ "$PRICE" = "0" ] || [ "$PRICE_TS" = "0" ] || [ $AGE -gt $STALENESS ]; then
        if [ "$PRICE" = "0" ] || [ "$PRICE_TS" = "0" ]; then
            warn "Price feed not populated. Running CRE workflow to update..."
        else
            warn "Price feed stale (age: ${AGE}s > window: ${STALENESS}s). Running CRE workflow to refresh..."
        fi
        
        # Auto-run CRE workflow with broadcast
        if cre whoami &>/dev/null; then
            log "Running CRE workflow with broadcast..."
            pushd "$CRE_DIR" > /dev/null
            cre workflow simulate ./api-oracle --broadcast --target staging-settings 2>&1 | tail -20
            popd > /dev/null
            
            # Re-check price after refresh
            sleep 2
            PRICE_DATA=$(cast call $PRICE_FEED_ADDRESS "getLatestPrice()(uint256,uint256)" --rpc-url $RPC_URL)
            PRICE=$(parse_uint "$(echo "$PRICE_DATA" | head -1)")
            PRICE_TS=$(parse_uint "$(echo "$PRICE_DATA" | tail -1)")
            NOW=$(date +%s)
            AGE=$((NOW - PRICE_TS))
            
            if [ "$PRICE" = "0" ] || [ $AGE -gt $STALENESS ]; then
                warn "Price feed still stale after refresh. Check CRE workflow logs."
                return 1
            fi
            success "Price feed refreshed successfully"
        else
            warn "CRE not authenticated. Run 'cre login' then re-run with --broadcast."
            return 0
        fi
    fi
    
    PRICE_USD=$(echo "scale=2; $PRICE / 100000000" | bc)
    log "Price: \$$PRICE_USD, Age: ${AGE}s"
    
    # Check USDC balance
    USDC_BAL=$(parse_uint "$(cast call $USDC_ADDRESS 'balanceOf(address)(uint256)' $OWNER_ADDRESS --rpc-url $RPC_URL)")
    USDC_HUMAN=$(echo "scale=6; $USDC_BAL / 1000000" | bc)
    log "USDC Balance: $USDC_HUMAN"
    
    if [ "$USDC_BAL" = "0" ]; then
        warn "No USDC balance. Get testnet USDC from https://faucet.circle.com/"
        return 0
    fi
    
    success "Integration test passed - System ready for minting"
}

# =============================================================================
# Save Deployed Addresses
# =============================================================================
save_addresses() {
    log "Saving deployed addresses..."
    
    cat > "$DEPLOYED_ADDRESSES" << EOF
{
  "network": "sepolia",
  "chainId": $CHAIN_ID,
  "deployedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "aws": {
    "apiUrl": "$API_URL",
    "stackName": "asset-price-service"
  },
  "contracts": {
    "PriceFeed": "$PRICE_FEED_ADDRESS",
    "CollateralizationMonitor": "$COLLATERAL_MONITOR_ADDRESS",
    "SyntheticToken": "$SYNTHETIC_TOKEN_ADDRESS",
    "SyntheticMinter": "$SYNTHETIC_MINTER_ADDRESS",
    "USDC": "$USDC_ADDRESS"
  },
  "configuration": {
    "owner": "$OWNER_ADDRESS",
    "keystoneForwarder": "$KEYSTONE_FORWARDER",
    "minCollateralizationRatio": 150,
    "mintFeeBps": 30,
    "stalenessWindow": 3600
  },
  "etherscan": {
    "PriceFeed": "https://sepolia.etherscan.io/address/$PRICE_FEED_ADDRESS",
    "CollateralizationMonitor": "https://sepolia.etherscan.io/address/$COLLATERAL_MONITOR_ADDRESS",
    "SyntheticToken": "https://sepolia.etherscan.io/address/$SYNTHETIC_TOKEN_ADDRESS",
    "SyntheticMinter": "https://sepolia.etherscan.io/address/$SYNTHETIC_MINTER_ADDRESS"
  }
}
EOF
    
    success "Addresses saved to $DEPLOYED_ADDRESSES"

    # Publish to the web UI so it auto-loads addresses dynamically (no hardcoding)
    cp "$DEPLOYED_ADDRESSES" "$SCRIPT_DIR/ui/deployed-addresses.json"
    rm -f "$SCRIPT_DIR/ui/oracle-addresses.json"
    success "Addresses published to ui/deployed-addresses.json"
}

# =============================================================================
# Print Summary
# =============================================================================
print_summary() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    DEPLOYMENT COMPLETE                         ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}AWS Lambda:${NC}"
    echo "  API URL: $API_URL"
    echo ""
    echo -e "${BLUE}CRE Oracle Contracts:${NC}"
    echo "  PriceFeed:              $PRICE_FEED_ADDRESS"
    echo "  CollateralizationMonitor: $COLLATERAL_MONITOR_ADDRESS"
    echo ""
    echo -e "${BLUE}Synthetic Minter Contracts:${NC}"
    echo "  SyntheticToken (sSPY): $SYNTHETIC_TOKEN_ADDRESS"
    echo "  SyntheticMinter:        $SYNTHETIC_MINTER_ADDRESS"
    echo ""
    echo -e "${BLUE}Configuration:${NC}"
    echo "  Owner: $OWNER_ADDRESS"
    echo "  USDC:  $USDC_ADDRESS"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Get testnet USDC: https://faucet.circle.com/"
    echo "  2. Run CRE workflow: cd sample-cre-pricefeeds-por/aws-oracle-cre && ./run-simulation.sh"
    echo "  3. Test minting: ./synthetic-asset-minter/test-integration.sh"
    echo ""
    echo -e "${BLUE}Etherscan Links:${NC}"
    echo "  https://sepolia.etherscan.io/address/$SYNTHETIC_MINTER_ADDRESS"
    echo ""
}

# =============================================================================
# Main Entry Point
# =============================================================================
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --skip-lambda     Skip AWS Lambda deployment"
    echo "  --skip-cre        Skip CRE oracle contract deployment"
    echo "  --skip-minter     Skip Synthetic Minter contract deployment"
    echo "  --reuse-contracts Reuse all on-chain contracts from a previous deployment"
    echo "  --test-only       Only run integration test (requires prior deployment)"
    echo "  --cleanup         Tear down all deployed resources (Lambda stack + artifacts)"
    echo "  --region REGION   AWS region override (default: from samconfig.toml or us-east-1)"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  PRIVATE_KEY            Ethereum private key (with 0x prefix)"
    echo "  RPC_URL                Sepolia RPC URL (default: public node)"
    echo "  USDC_ADDRESS           USDC contract address (default: Sepolia USDC)"
    echo "  FINNHUB_API_KEY        Finnhub API key for live stock prices"
    echo "  ALPHA_VANTAGE_API_KEY  Alpha Vantage API key (fallback provider)"
    echo "  KEYSTONE_FORWARDER     CRE KeystoneForwarder address (default: Sepolia)"
    echo ""
    echo "Examples:"
    echo "  $0                          # Full deployment (writes price on-chain)"
    echo "  $0 --skip-lambda            # Deploy only contracts"
    echo "  $0 --reuse-contracts        # Redeploy Lambda, reuse existing contracts"
    echo "  $0 --test-only              # Run integration test only"
    echo "  $0 --cleanup                # Tear down all AWS resources"
}

# =============================================================================
# Cleanup: Tear down deployed resources
# =============================================================================
cleanup() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}     Synthetic Asset Minter - Cleanup                           ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    command -v aws &>/dev/null || error "AWS CLI not installed"
    aws sts get-caller-identity &>/dev/null || error "AWS credentials not configured"

    if [ -n "$AWS_REGION_OVERRIDE" ]; then
        LAMBDA_REGION="$AWS_REGION_OVERRIDE"
    else
        LAMBDA_REGION=$(grep -m1 'region' "$LAMBDA_DIR/samconfig.toml" 2>/dev/null | awk -F'"' '{print $2}')
        LAMBDA_REGION="${LAMBDA_REGION:-us-east-1}"
    fi

    local STACK_NAME="asset-price-service"

    echo -e "${YELLOW}⚠️  This will delete the following resources:${NC}"
    echo "   - CloudFormation stack '$STACK_NAME' (API Gateway, Lambdas, DynamoDB table)"
    echo "   - SAM deployment artifacts (S3 bucket contents)"
    echo ""
    read -p "Are you sure? (y/N) " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Cancelled."
        exit 0
    fi
    echo ""

    # Delete CloudFormation stack
    log "Deleting CloudFormation stack '$STACK_NAME' in $LAMBDA_REGION..."
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$LAMBDA_REGION" &>/dev/null; then
        cd "$LAMBDA_DIR"
        sam delete --stack-name "$STACK_NAME" --region "$LAMBDA_REGION" --no-prompts
        cd "$SCRIPT_DIR"
        success "Stack '$STACK_NAME' deleted"
    else
        warn "Stack '$STACK_NAME' not found (already deleted?)"
    fi

    # Keep deployed-addresses.json — contract addresses are still valid on-chain
    # and needed by --reuse-contracts

    echo ""
    success "Cleanup complete"
    echo ""
    echo -e "${BLUE}Note:${NC} On-chain contracts (Sepolia) cannot be deleted."
    echo "  They will remain at their deployed addresses but are no longer active."
}

main() {
    local skip_lambda=false
    local skip_cre=false
    local skip_minter=false
    local reuse_contracts=false
    local test_only=false
    local do_cleanup=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-lambda) skip_lambda=true; shift ;;
            --skip-cre) skip_cre=true; shift ;;
            --skip-minter) skip_minter=true; shift ;;
            --reuse-contracts) reuse_contracts=true; shift ;;
            --test-only) test_only=true; shift ;;
            --cleanup) do_cleanup=true; shift ;;
            --region) AWS_REGION_OVERRIDE="$2"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            *) error "Unknown option: $1" ;;
        esac
    done

    if [ "$reuse_contracts" = "true" ]; then
        skip_cre=true
        skip_minter=true
        # Verify we have addresses to reuse
        CONFIG="$CRE_DIR/api-oracle/config.staging.json"
        if [ ! -f "$DEPLOYED_ADDRESSES" ] && [ ! -f "$CONFIG" ]; then
            error "No previous deployment found. Run a full deployment first."
        fi
    fi

    if [ "$do_cleanup" = "true" ]; then
        cleanup
        exit 0
    fi
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}     Synthetic Asset Minter - End-to-End Deployment            ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    check_prerequisites
    
    if [ "$test_only" = "true" ]; then
        # Load addresses from config
        if [ -f "$DEPLOYED_ADDRESSES" ]; then
            export PRICE_FEED_ADDRESS=$(jq -r '.contracts.PriceFeed' "$DEPLOYED_ADDRESSES")
            export SYNTHETIC_MINTER_ADDRESS=$(jq -r '.contracts.SyntheticMinter' "$DEPLOYED_ADDRESSES")
        else
            # Use config.staging.json
            CONFIG="$CRE_DIR/api-oracle/config.staging.json"
            export PRICE_FEED_ADDRESS=$(jq -r '.evms[0].priceFeedAddress' "$CONFIG")
            export SYNTHETIC_MINTER_ADDRESS=$(jq -r '.evms[0].syntheticMinterAddress' "$CONFIG")
        fi
        run_integration_test
        exit 0
    fi
    
    [ "$skip_lambda" = "false" ] && deploy_lambda
    [ "$skip_cre" = "false" ] && deploy_cre_contracts
    [ "$skip_minter" = "false" ] && deploy_minter_contracts

    # Load addresses from prior deployment if any phases were skipped
    if [ -z "$PRICE_FEED_ADDRESS" ] || [ -z "$SYNTHETIC_MINTER_ADDRESS" ]; then
        if [ -f "$DEPLOYED_ADDRESSES" ]; then
            log "Loading addresses from deployed-addresses.json..."
            [ -z "$PRICE_FEED_ADDRESS" ] && export PRICE_FEED_ADDRESS=$(jq -r '.contracts.PriceFeed' "$DEPLOYED_ADDRESSES")
            [ -z "$COLLATERAL_MONITOR_ADDRESS" ] && export COLLATERAL_MONITOR_ADDRESS=$(jq -r '.contracts.CollateralizationMonitor' "$DEPLOYED_ADDRESSES")
            [ -z "$SYNTHETIC_TOKEN_ADDRESS" ] && export SYNTHETIC_TOKEN_ADDRESS=$(jq -r '.contracts.SyntheticToken' "$DEPLOYED_ADDRESSES")
            [ -z "$SYNTHETIC_MINTER_ADDRESS" ] && export SYNTHETIC_MINTER_ADDRESS=$(jq -r '.contracts.SyntheticMinter' "$DEPLOYED_ADDRESSES")
        else
            CONFIG="$CRE_DIR/api-oracle/config.staging.json"
            log "Loading addresses from config.staging.json..."
            [ -z "$PRICE_FEED_ADDRESS" ] && export PRICE_FEED_ADDRESS=$(jq -r '.evms[0].priceFeedAddress' "$CONFIG")
            [ -z "$COLLATERAL_MONITOR_ADDRESS" ] && export COLLATERAL_MONITOR_ADDRESS=$(jq -r '.evms[0].collateralizationMonitorAddress' "$CONFIG")
            [ -z "$SYNTHETIC_TOKEN_ADDRESS" ] && export SYNTHETIC_TOKEN_ADDRESS=$(jq -r '.evms[0].syntheticTokenAddress' "$CONFIG")
            [ -z "$SYNTHETIC_MINTER_ADDRESS" ] && export SYNTHETIC_MINTER_ADDRESS=$(jq -r '.evms[0].syntheticMinterAddress' "$CONFIG")
        fi
    fi

    # Only configure contracts if at least one contract phase ran
    if [ "$skip_cre" = "false" ] || [ "$skip_minter" = "false" ]; then
        configure_contracts
    fi

    update_cre_config
    run_cre_workflow
    save_addresses
    run_integration_test
    print_summary
}

main "$@"
