# evm-modules-contracts

## ccip-contracts

**[Supported Networks(Testnet)](https://docs.chain.link/ccip/supported-networks/v1_2_0/testnet#overview)**

### Contract(Rate CCIP Message) deploy

#### manual deployment
1. deploy Sender (router address https://docs.chain.link/ccip/supported-networks)
   * deploy
   * addTokenInfo
2. deploy Receiver
3. deploy CCIPRateProvider (rate+address(Receiver))
4. send link to Sender

#### automatic deployment

```bash
cp ./scripts/RateMsg/config.example.json ./scripts/RateMsg/config.json
```

```bash
# chain_source, chain_dst Need to be configured in hardhat.config.js
NETWORK_SOURCE=chain_source NETWORK_DESTINATION=chain_dst ./scripts/RateMsg/deploy_all.sh
```

#### Configure RateSender at ccip automation

[automation](https://automation.chain.link/)

## Connext bridge(L2 Native Restaking) Module

<!-- todo -->