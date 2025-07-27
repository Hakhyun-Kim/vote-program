#!/bin/bash
echo "Starting Solana validator..."
solana-test-validator --rpc-port 8899 &
sleep 5
echo "Running tests..."
anchor test --skip-local-validator 