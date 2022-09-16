#!/usr/bin/env bash
set -ex

env_network="testnet"
env_prod='false'
export env_network
export env_prod

dfx identity new default --disable-encryption || true

mkdir ~/.config/dfx/identity/local_nft_deployer/

mkdir .dfx/${env_network}/
mkdir .dfx/local/
echo ${CANISTER_IDS} > .dfx/${env_network}/canister_ids.json
echo ${WALLET_ID} > .dfx/local/wallets.json

cp identity.pem ~/.config/dfx/identity/local_nft_deployer/identity.pem

dfx identity use local_nft_deployer

dfx identity whoami
dfx canister --network local create origyn_nft_reference
dfx build --network local origyn_nft_reference
dfx canister --network local create origyn_sale_reference
dfx build --network local origyn_sale_reference

env_name='origyn_nft_reference_dev'
env_name_sale='dev_sales_canister'
export env_name
export env_name_sale
echo "deploy_bayc"
./scripts/lib/deploy_bayc.sh

env_name='dev_mintpass_ogy_reference'
export env_name
echo "deploy_impossible-pass"
./scripts/lib/deploy_impossible-pass.sh

env_name='dev_kobe_mint'
export env_name
echo "deploy_kobe"
./scripts/lib/deploy_kobe.sh
