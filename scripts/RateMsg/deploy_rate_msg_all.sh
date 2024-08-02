#!/bin/bash

set -e

# Set the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Deploy to Source Chain
echo "Deploying to Source Chain..." >&2
chain_source_result=$(npx hardhat run ${SCRIPT_DIR}/deploy_rate_msg_source.js --network ${NETWORK_SOURCE} 2>&1 | tee >(cat >&2))

# Extract addresses from Source Chain deployment
json_output=$(echo "$chain_source_result" | grep -o '{.*}' | tail -n 1)

# Extract addresses from JSON
rate_sender_address=$(echo "$json_output" | jq -r .rateSenderAddress)
mock_token_address=$(echo "$json_output" | jq -r .deployedTokens)

if [ -z "$rate_sender_address" ]; then
    echo "Error: Failed to get rate_sender_address" >&2
    exit 1
fi

# Deploy to Destination Chain
echo "Deploying to Destination Chain..." >&2
export RATE_SENDER_ADDRESS=$rate_sender_address
chain_destination_result=$(RATE_SENDER_ADDRESS=$rate_sender_address npx hardhat run ${SCRIPT_DIR}/deploy_rate_msg_destination.js --network ${NETWORK_DESTINATION} 2>&1 | tee >(cat >&2))

# Extract addresses from Destination Chain deployment
rate_receiver_address=$(echo "$chain_destination_result" | grep -o '{.*}' | jq -r .rateReceiverAddress)
ccip_rate_provider_address=$(echo "$chain_destination_result" | grep -o '{.*}' | jq -r .ccipRateProviderAddress)

# Print final deployment information
echo "Deployment Summary:" >&2
echo "Source Chain (${NETWORK_SOURCE}):" >&2
echo "  MockToken: $mock_token_address" >&2
echo "  RateSender: $rate_sender_address" >&2
echo "Destination Chain (${NETWORK_DESTINATION}):" >&2
echo "  RateReceiver: $rate_receiver_address" >&2
echo "  CCIPRateProvider: $ccip_rate_provider_address" >&2