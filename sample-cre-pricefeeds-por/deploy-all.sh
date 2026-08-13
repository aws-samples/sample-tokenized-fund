#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "AWS + Chainlink CRE Complete Deployment"
echo -e "==========================================${NC}\n"

# ----------------------------
# Auto-install prerequisites
# ----------------------------
echo -e "${BLUE}Checking prerequisites (auto-install if missing)...${NC}"

need_sudo() { command -v sudo >/dev/null 2>&1; }

detect_pm() {
  if command -v brew >/dev/null 2>&1; then echo "brew"
  elif command -v apt-get >/dev/null 2>&1; then echo "apt"
  elif command -v dnf >/dev/null 2>&1; then echo "dnf"
  elif command -v yum >/dev/null 2>&1; then echo "yum"
  elif command -v pacman >/dev/null 2>&1; then echo "pacman"
  else echo "unknown"
  fi
}

pm_update() {
  local pm="$1"
  case "$pm" in
    brew) brew update ;;
    apt)  sudo apt-get update -y ;;
    dnf)  sudo dnf -y makecache ;;
    yum)  sudo yum -y makecache ;;
    pacman) sudo pacman -Sy --noconfirm ;;
  esac
}

pm_install() {
  local pm="$1"; shift
  case "$pm" in
    brew) brew install "$@" ;;
    apt)  sudo apt-get install -y "$@" ;;
    dnf)  sudo dnf install -y "$@" ;;
    yum)  sudo yum install -y "$@" ;;
    pacman) sudo pacman -S --noconfirm --needed "$@" ;;
    *)
      echo -e "${RED}❌ No supported package manager found. Install missing tools manually.${NC}"
      return 1
      ;;
  esac
}

ensure_cmd() {
  local cmd="$1"
  local pm="$2"
  local pkgs=("${@:3}")

  if command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ $cmd found${NC}"
    return 0
  fi

  echo -e "${YELLOW}⚠️  $cmd not found — attempting install...${NC}"
  pm_install "$pm" "${pkgs[@]}" || return 1

  if command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ $cmd installed${NC}"
    return 0
  fi

  echo -e "${RED}❌ Failed to install $cmd${NC}"
  return 1
}

install_sam_cli_fallback() {
  # Add .local/bin to PATH for this session
  export PATH="$HOME/.local/bin:$PATH"
  
  if command -v sam >/dev/null 2>&1; then return 0; fi

  echo -e "${YELLOW}⚠️  SAM CLI not found — attempting fallback install...${NC}"

  # Try pip first (simpler, more common)
  if command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1; then
    python3 -m pip install --user --upgrade aws-sam-cli 2>/dev/null || pip install --user --upgrade aws-sam-cli 2>/dev/null || true
    if command -v sam >/dev/null 2>&1; then return 0; fi
  fi

  # Fallback to pipx if pip failed
  if ! command -v pipx >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing pipx...${NC}"
    case "$PM" in
      apt) pm_install "$PM" pipx ;;
      dnf|yum) pm_install "$PM" pipx ;;
      *) return 1 ;;
    esac
  fi

  if command -v pipx >/dev/null 2>&1; then
    pipx install aws-sam-cli || pipx upgrade aws-sam-cli || true
    pipx ensurepath || true
  fi

  command -v sam >/dev/null 2>&1
}

install_cre_cli() {
  if command -v cre >/dev/null 2>&1; then
    echo -e "${GREEN}✅ cre found${NC}"
    return 0
  fi

  echo -e "${YELLOW}⚠️  CRE CLI not found — installing via official installer...${NC}"
  curl -sSL https://cre.chain.link/install.sh | bash

  # Common install locations (depends on installer version)
  export PATH="$HOME/.cre/bin:$HOME/.cre:$PATH"

  if command -v cre >/dev/null 2>&1; then
    echo -e "${GREEN}✅ cre installed${NC}"
    return 0
  fi

  echo -e "${RED}❌ CRE CLI install ran but 'cre' not on PATH.${NC}"
  echo -e "${YELLOW}Try: export PATH=\"\$HOME/.cre/bin:\$PATH\"${NC}"
  return 1
}

install_go() {
  if command -v go >/dev/null 2>&1; then
    echo -e "${GREEN}✅ go found${NC}"
    return 0
  fi

  echo -e "${YELLOW}⚠️  Go not found — attempting install...${NC}"
  case "$PM" in
    brew) pm_install "$PM" go ;;
    apt)  pm_install "$PM" golang-go ;;
    dnf|yum) pm_install "$PM" golang ;;
    pacman) pm_install "$PM" go ;;
    *)
      echo -e "${RED}❌ No supported package manager for Go.${NC}"
      return 1
      ;;
  esac

  if command -v go >/dev/null 2>&1; then
    echo -e "${GREEN}✅ go installed${NC}"
    return 0
  fi

  echo -e "${RED}❌ Go install failed. Install manually from go.dev if needed.${NC}"
  return 1
}

install_foundry() {
  if command -v forge >/dev/null 2>&1 && command -v cast >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Foundry (forge/cast) found${NC}"
    return 0
  fi

  echo -e "${YELLOW}⚠️  Foundry not found — installing via foundryup...${NC}"
  curl -L https://foundry.paradigm.xyz | bash

  export PATH="$HOME/.foundry/bin:$PATH"

  if command -v foundryup >/dev/null 2>&1; then
    foundryup
  fi

  if command -v forge >/dev/null 2>&1 && command -v cast >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Foundry installed${NC}"
    return 0
  fi

  echo -e "${RED}❌ Foundry install ran but forge/cast not on PATH.${NC}"
  echo -e "${YELLOW}Try: export PATH=\"\$HOME/.foundry/bin:\$PATH\"${NC}"
  return 1
}

PM="$(detect_pm)"
if [ "$PM" = "unknown" ]; then
  echo -e "${RED}❌ No supported package manager found (brew/apt/dnf/yum/pacman). Install dependencies manually.${NC}"
  exit 1
fi

# sudo needed for Linux package managers
if [[ "$PM" != "brew" ]] && ! need_sudo; then
  echo -e "${RED}❌ sudo not available. Re-run as root or install dependencies manually.${NC}"
  exit 1
fi

pm_update "$PM" || true

# Core tools used by this script
ensure_cmd curl "$PM" curl
ensure_cmd jq   "$PM" jq
ensure_cmd git  "$PM" git

# AWS CLI
if ! command -v aws >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  aws not found — attempting install...${NC}"
  if ! pm_install "$PM" awscli 2>/dev/null && ! pm_install "$PM" awscli2 2>/dev/null; then
    # Fallback: Install AWS CLI v2 manually
    echo -e "${YELLOW}Installing AWS CLI v2 manually...${NC}"
    curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    if command -v unzip >/dev/null 2>&1 || pm_install "$PM" unzip; then
      unzip -q /tmp/awscliv2.zip -d /tmp
      sudo /tmp/aws/install
      rm -rf /tmp/aws /tmp/awscliv2.zip
    else
      echo -e "${RED}❌ Could not install AWS CLI: unzip not available${NC}"
      exit 1
    fi
  fi
fi
command -v aws >/dev/null 2>&1 || { echo -e "${RED}❌ AWS CLI still missing${NC}"; exit 1; }
echo -e "${GREEN}✅ aws found${NC}"

# SAM CLI
if ! command -v sam >/dev/null 2>&1; then
  if [ "$PM" = "brew" ]; then
    pm_install "$PM" aws-sam-cli || true
  else
    pm_install "$PM" aws-sam-cli 2>/dev/null || true
  fi
  install_sam_cli_fallback || { 
    echo -e "${RED}❌ SAM CLI install failed${NC}"
    echo -e "${YELLOW}Install manually: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html${NC}"
    exit 1
  }
fi
echo -e "${GREEN}✅ sam found${NC}"

# Node.js (required for SAM builds with esbuild)
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  Node.js not found — attempting install...${NC}"
  case "$PM" in
    brew) pm_install "$PM" node ;;
    apt)  pm_install "$PM" nodejs npm ;;
    dnf|yum) pm_install "$PM" nodejs npm ;;
    pacman) pm_install "$PM" nodejs npm ;;
  esac
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Node.js installed${NC}"
  else
    echo -e "${RED}❌ Node.js install failed${NC}"
    exit 1
  fi
else
  echo -e "${GREEN}✅ Node.js found${NC}"
fi

# esbuild (required for SAM builds)
if ! command -v esbuild >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  esbuild not found — installing globally via npm...${NC}"
  sudo npm install -g esbuild 2>/dev/null || npm install -g esbuild
  if command -v esbuild >/dev/null 2>&1; then
    echo -e "${GREEN}✅ esbuild installed${NC}"
  else
    echo -e "${RED}❌ esbuild install failed${NC}"
    exit 1
  fi
else
  echo -e "${GREEN}✅ esbuild found${NC}"
fi

# Go (needed for `go mod tidy` and bindings steps)
install_go || exit 1

# Foundry (needed for contracts deploy.sh)
install_foundry || exit 1

# CRE CLI
install_cre_cli || exit 1

# Auth check for CRE
if ! cre whoami &> /dev/null; then
  echo -e "${RED}❌ CRE CLI not authenticated${NC}"
  echo -e "Run: ${GREEN}cre login${NC}"
  exit 1
fi
echo -e "${GREEN}✅ CRE authenticated${NC}"

# AWS credentials check
if ! aws sts get-caller-identity &> /dev/null; then
  echo -e "${RED}❌ AWS credentials not configured${NC}"
  exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}\n"

# Step 1: Deploy AWS Infrastructure
echo -e "${BLUE}=========================================="
echo "Step 1: Deploying AWS Infrastructure"
echo -e "==========================================${NC}\n"

cd price-feed-por-dynamodb-crud
./deploy.sh
cd ..

echo -e "${GREEN}✅ AWS Infrastructure deployed${NC}\n"

# Step 1.5: Populate API with test data
echo -e "${BLUE}=========================================="
echo "Step 1.5: Populating API with Test Data"
echo -e "==========================================${NC}\n"

API_KEY=$(aws cloudformation describe-stacks \
    --stack-name asset-price-service \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiKeyId`].OutputValue' \
    --output text | xargs -I {} aws apigateway get-api-key --api-key {} --include-value --query 'value' --output text)

API_URL=$(aws cloudformation describe-stacks \
    --stack-name asset-price-service \
    --query 'Stacks[0].Outputs[?OutputKey==`AssetPriceApiUrl`].OutputValue' \
    --output text)

curl -X POST "${API_URL}simulate" -H "x-api-key: ${API_KEY}" -H "Content-Type: application/json"

echo -e "\n${GREEN}✅ Test data populated${NC}\n"

# Step 2: Configure CRE with API Key
echo -e "${BLUE}=========================================="
echo "Step 2: Configuring CRE with API Key"
echo -e "==========================================${NC}\n"

cd aws-oracle-cre
./set-api-key.sh

# Check if private key is set
if ! grep -q "^CRE_ETH_PRIVATE_KEY=.\{64\}" .env 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Private key not configured${NC}"
    echo -e "${YELLOW}Please add your Ethereum private key to aws-oracle-cre/.env:${NC}"
    echo -e "${YELLOW}CRE_ETH_PRIVATE_KEY=your_64_char_private_key_without_0x_prefix${NC}\n"
    echo -e "${YELLOW}Get your private key from MetaMask:${NC}"
    echo -e "${YELLOW}Account Details → Show Private Key → Copy (remove 0x prefix)${NC}\n"
    echo -e "${YELLOW}Press Enter after adding your private key...${NC}"
    read
fi

# Verify private key is now set
if ! grep -q "^CRE_ETH_PRIVATE_KEY=.\{64\}" .env; then
    echo -e "${RED}❌ Private key still not configured${NC}"
    echo -e "${RED}Edit aws-oracle-cre/.env and add:${NC}"
    echo -e "${RED}CRE_ETH_PRIVATE_KEY=your_64_char_private_key_without_0x_prefix${NC}"
    exit 1
fi

echo -e "${GREEN}✅ CRE configured${NC}\n"

# Step 3: Deploy Smart Contracts
echo -e "${BLUE}=========================================="
echo "Step 3: Deploying Smart Contracts"
echo -e "==========================================${NC}\n"

# Export private key for Foundry (add 0x prefix if not present)
PRIVATE_KEY_RAW=$(grep "^CRE_ETH_PRIVATE_KEY=" .env | cut -d'=' -f2)
export PRIVATE_KEY="0x${PRIVATE_KEY_RAW}"
export SEPOLIA_RPC_URL="https://ethereum-sepolia-rpc.publicnode.com"

cd contracts/evm
./deploy.sh
cd ../..

echo -e "${GREEN}✅ Smart contracts deployed${NC}\n"

# Step 4: Generate CRE Bindings
echo -e "${BLUE}=========================================="
echo "Step 4: Generating CRE Bindings"
echo -e "==========================================${NC}\n"

cre generate-bindings evm
go mod tidy

echo -e "${GREEN}✅ CRE bindings generated${NC}\n"

# Step 5: Test Workflow (Dry Run)
echo -e "${BLUE}=========================================="
echo "Step 5: Testing Workflow (Dry Run)"
echo -e "==========================================${NC}\n"

echo -e "${YELLOW}Running workflow simulation without broadcast...${NC}"
cre workflow simulate api-oracle --target staging-settings

echo -e "${GREEN}✅ Workflow test successful${NC}\n"

# Final Summary
echo -e "${BLUE}=========================================="
echo "Deployment Complete!"
echo -e "==========================================${NC}\n"

echo -e "${GREEN}✅ AWS Infrastructure deployed${NC}"
echo -e "${GREEN}✅ Smart contracts deployed to Sepolia${NC}"
echo -e "${GREEN}✅ CRE workflow configured and tested${NC}\n"

# Get contract addresses
PRICE_FEED=$(jq -r '.evms[0].priceFeedAddress' api-oracle/config.staging.json)
MONITOR=$(jq -r '.evms[0].collateralizationMonitorAddress' api-oracle/config.staging.json)
API_URL=$(jq -r '.apiUrl' api-oracle/config.staging.json)

echo -e "${BLUE}Deployed Resources:${NC}"
echo -e "API URL: ${GREEN}$API_URL${NC}"
echo -e "PriceFeed: ${GREEN}$PRICE_FEED${NC}"
echo -e "CollateralizationMonitor: ${GREEN}$MONITOR${NC}\n"

echo -e "${BLUE}Next Steps:${NC}"
echo -e "1. To broadcast transactions to Sepolia:"
echo -e "   ${GREEN}cd aws-oracle-cre && ./run-simulation.sh${NC}\n"
echo -e "2. Monitor transactions on Sepolia:"
echo -e "   PriceFeed Contract: ${GREEN}https://sepolia.etherscan.io/address/$PRICE_FEED${NC}"
echo -e "   CollateralizationMonitor Contract: ${GREEN}https://sepolia.etherscan.io/address/$MONITOR${NC}"

cd ..
