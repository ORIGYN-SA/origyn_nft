set -ex

npm install

dfx identity use local_nft_deployer

ADMIN_PRINCIPAL=$(dfx identity get-principal)
ADMIN_ACCOUNTID=$(dfx ledger account-id)

echo $ADMIN_PRINCIPAL
echo $ADMIN_ACCOUNTID

dfx canister  --network $env_network create $env_name || true

NFT_CANISTER_ID=$(dfx canister --network $env_network id $env_name)
NFT_CANISTER_ACCOUNT=$(python3 principal_to_accountid.py $NFT_CANISTER_ID)

echo $NFT_CANISTER_ID
echo $NFT_CANISTER_ACCOUNT

awk "{gsub(\"CANISTER-ID\",\"$NFT_CANISTER_ID\"); print}" ./projects/origynator/def.json  > ./projects/origynator/def_loaded_1.json
awk "{gsub(\"APP-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/origynator/def_loaded_1.json  > ./projects/origynator/def_loaded_2.json
awk "{gsub(\"CREATOR-PRINCIPAL-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/origynator/def_loaded_2.json  > ./projects/origynator/def_loaded.json

dfx build --network $env_network $env_name
yes "yes" | dfx canister --network $env_network install $env_name --mode=reinstall --argument "(record {owner =principal  \"$ADMIN_PRINCIPAL\"})"

node ./projects/deploy.js --meta=./projects/origynator/def_loaded.json --token_id="1" --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=true

