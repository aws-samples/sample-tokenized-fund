#!/bin/bash
# Serves the UI + CRE trigger endpoint (MetaMask requires http://, not file://)
echo "Starting server at http://localhost:3000"
echo "Open http://localhost:3000 in your browser"
cd "$(dirname "$0")"
python3 server.py
