#!/bin/bash
# -e (exit on error) -x verbose debugging output
set -ex

# ******************************************************
# Input variables
# Note: The args passed to csm config should not change

# The canister install mode.
# 'install', 'reinstall' or 'upgrade'
INSTALL_MODE='reinstall'

# ******************************************************


# change directory to path of script, not the terminal
SCRIPT_FOLDER=./projects/simple-video

# setup additional variables from input

echo "The canister name is: $env_name"
echo "The origyn environment is: $env_network"
echo "The internet computer network is: $env_network"
echo "The install mode is: $INSTALL_MODE"

# canister deployment
npm ci

# dfx identity import local_nft_deployer identity.pem --disable-encryption || true
dfx identity use local_nft_deployer

dfx canister --network $env_network create $env_name || true
dfx build --network $env_network $env_name

ADMIN_PRINCIPAL=$(dfx identity get-principal)
NFT_CANISTER_ID=$(dfx canister --network $env_network id $env_name)
NFT_CANISTER_ACCOUNT=$(python3 principal_to_accountid.py $NFT_CANISTER_ID)

yes "yes" | dfx canister --network $env_network install $env_name --mode=$INSTALL_MODE --argument "(record {owner =principal  \"$ADMIN_PRINCIPAL\"; storage_space = null;})"

dfx canister --network $env_network call $env_name collection_update_origyn '(vec {  variant {metadata = opt variant {Class = vec {record {name = "id"; value= variant {Text = "kobe"};immutable=true;};}}};})'

# start NFT deployment

# create config file
node ./projects/csm config \
-e localhost \
-c 'simple' \
-d 'Simple' \
-t 'simple_' \
-n 'ogy.simple' \
-i $NFT_CANISTER_ID \
-p $ADMIN_PRINCIPAL \
-s 'false' \
-f $SCRIPT_FOLDER/'assets' \
-m 'primary:index.html, experience:index.html, preview:over-2mb.png' \
-q '3'

# stage NFT assets
node ./projects/csm stage -f="$SCRIPT_FOLDER/assets" -s=seed.txt

# mint NFTs
node ./projects/csm mint -f="$SCRIPT_FOLDER/assets" -s=seed.txt


