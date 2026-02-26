#!/bin/bash
set -e # Exit on any error

echo "--- Setting up Project Aether Environment ---"

# 1. Check for Go
if ! command -v go &> /dev/null; then
    echo "Go is not installed. Please install Go 1.21+."
    exit 1
fi

# 2. Install dependencies (networking/eBPF tools)
echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    libelf-dev \
    llvm \
    clang \
    iproute2 \
    strace

# 3. Pull Go dependencies
echo "Fetching Go modules..."
go mod download
go mod tidy

# 4. Success message
echo "--- Setup Complete! ---"
echo "Note: Networking tasks will require 'sudo' or CAP_NET_ADMIN."