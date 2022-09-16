set -ex

npm install

dfx identity use local_nft_deployer

ADMIN_PRINCIPAL=$(dfx identity get-principal)
ADMIN_ACCOUNTID=$(dfx ledger account-id)

echo $ADMIN_PRINCIPAL
echo $ADMIN_ACCOUNTID

dfx canister --network $env_network create origyn_nft_reference || true

NFT_CANISTER_ID=$(dfx canister --network $env_network id origyn_nft_reference)
NFT_CANISTER_ACCOUNT=$(python3 principal_to_accountid.py $NFT_CANISTER_ID)

echo $NFT_CANISTER_ID
echo $NFT_CANISTER_ACCOUNT

awk "{gsub(\"CANISTER-ID\",\"$NFT_CANISTER_ID\"); print}" ./projects/uefa202204/def.json  > ./projects/uefa202204/def_loaded_1.json
awk "{gsub(\"APP-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/uefa202204/def_loaded_1.json  > ./projects/uefa202204/def_loaded_2.json
awk "{gsub(\"CREATOR-PRINCIPAL-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/uefa202204/def_loaded_2.json  > ./projects/uefa202204/def_loaded.json

dfx build --network $env_network origyn_nft_reference
yes "yes" | dfx canister --network $env_network install origyn_nft_reference --mode=reinstall --argument "(record {owner =principal  \"$ADMIN_PRINCIPAL\"})"


node ./projects/deploy.js --meta=./projects/uefa202204/def_loaded.json --token_id="uefa-nft4g-1" --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=true

