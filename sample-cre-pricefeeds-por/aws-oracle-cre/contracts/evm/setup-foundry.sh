#!/bin/bash

# Setup script for Foundry installation
# This script installs Foundry (forge, cast, anvil, chisel)

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Foundry Setup Script ===${NC}"

# Check if foundryup is already installed
if command -v foundryup &> /dev/null; then
    echo -e "${GREEN}Foundry is already installed. Updating...${NC}"
    foundryup
    exit 0
fi

echo -e "${BLUE}Installing Foundry...${NC}"

# Install Foundry
curl -L https://foundry.paradigm.xyz | bash

echo -e "${GREEN}Foundry installer downloaded${NC}"
echo -e "${BLUE}Please run the following command to complete installation:${NC}"
echo -e "${GREEN}source ~/.bashrc && foundryup${NC}"
echo ""
echo -e "Or if using zsh:"
echo -e "${GREEN}source ~/.zshrc && foundryup${NC}"
echo ""
echo -e "After that, run: ${GREEN}./deploy.sh${NC}"
