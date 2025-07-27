#!/bin/bash
set -e

echo "Setting up Solana voting program environment..."

# Source cargo environment
source $HOME/.cargo/env

# Set PATH for Solana
export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"

# Set PATH for Cargo
export PATH="/root/.cargo/bin:$PATH"

# Create test wallet if it doesn't exist
if [ ! -f /root/.config/solana/id.json ]; then
    echo "Creating test wallet..."
    solana-keygen new --no-bip39-passphrase -o /root/.config/solana/id.json
fi

echo "Verifying installations..."
solana --version
anchor --version

echo "Building the program..."
anchor build

echo "Starting Solana validator..."
solana-test-validator --rpc-port 8899 &
sleep 5

echo "Running tests..."
anchor test --skip-local-validator 