set -ex

source ../local-network-setup/settings/post-setup.sh

npm install


dfx identity import dev --disable-encryption identity.pem || true


dfx identity use dev

ADMIN_PRINCIPAL=$(dfx identity get-principal)
ADMIN_ACCOUNTID=$(dfx ledger account-id)

echo $ADMIN_PRINCIPAL
echo $ADMIN_ACCOUNTID


dfx identity --network $env_network set-wallet $(dfx identity get-principal) || true


dfx canister --network local create origyn_nft_reference || true
dfx canister --network local create origyn_sale_reference || true
dfx canister --network $env_network create $env_name || true
dfx canister --network $env_network create $env_name_sale || true

NFT_CANISTER_ID=$(dfx canister --network $env_network id $env_name)
NFT_CANISTER_Account=$(python3 principal_to_accountid.py $NFT_CANISTER_ID)

NFT_Sale_ID=$(dfx canister --network $env_network id $env_name_sale)
NFT_Sale_Account=$(python3 principal_to_accountid.py $NFT_Sale_ID)

echo $NFT_CANISTER_ID
echo $NFT_CANISTER_Account

awk "{gsub(\"CANISTER-ID\",\"$NFT_CANISTER_ID\"); print}" ./projects/bm/def.json  > ./projects/bm/def_loaded_1.json
awk "{gsub(\"APP-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/bm/def_loaded_1.json  > ./projects/bm/def_loaded_2.json
awk "{gsub(\"CREATOR-PRINCIPAL-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/bm/def_loaded_2.json  > ./projects/bm/def_loaded.json

bash ./projects/bm/build-dapps.sh

awk "{gsub(\"CANISTER-ID\",\"$NFT_CANISTER_ID\"); print}" ./projects/bm/def_collection_build.json  > ./projects/bm/def_collection_1.json
awk "{gsub(\"APP-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/bm/def_collection_1.json  > ./projects/bm/def_collection_2.json
awk "{gsub(\"CREATOR-PRINCIPAL-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/bm/def_collection_2.json  > ./projects/bm/def_collection_loaded.json

awk "{gsub(\"XXXXXX\",\"0\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_0a.json
awk "{gsub(\"XXXXXX\",\"1\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_1a.json
awk "{gsub(\"XXXXXX\",\"2\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_2a.json
awk "{gsub(\"XXXXXX\",\"3\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_3a.json
awk "{gsub(\"XXXXXX\",\"4\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_4a.json
awk "{gsub(\"XXXXXX\",\"5\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_5a.json
awk "{gsub(\"XXXXXX\",\"6\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_6a.json
awk "{gsub(\"XXXXXX\",\"7\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_7a.json
awk "{gsub(\"XXXXXX\",\"8\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_8a.json
awk "{gsub(\"XXXXXX\",\"9\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_9a.json
awk "{gsub(\"XXXXXX\",\"10\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_10a.json
awk "{gsub(\"XXXXXX\",\"11\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_11a.json
awk "{gsub(\"XXXXXX\",\"12\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_12a.json
awk "{gsub(\"XXXXXX\",\"13\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_13a.json
awk "{gsub(\"XXXXXX\",\"14\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_14a.json
awk "{gsub(\"XXXXXX\",\"15\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_15a.json
awk "{gsub(\"XXXXXX\",\"16\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_16a.json
awk "{gsub(\"XXXXXX\",\"17\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_17a.json
awk "{gsub(\"XXXXXX\",\"18\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_18a.json
awk "{gsub(\"XXXXXX\",\"19\"); print}" ./projects/bm/def_loaded.json  > ./projects/bm/def_19a.json

awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_0a.json > ./projects/bm/def_0.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_1a.json > ./projects/bm/def_1.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_2a.json > ./projects/bm/def_2.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_3a.json > ./projects/bm/def_3.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_4a.json > ./projects/bm/def_4.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_5a.json > ./projects/bm/def_5.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_6a.json > ./projects/bm/def_6.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_7a.json > ./projects/bm/def_7.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_8a.json > ./projects/bm/def_8.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_9a.json > ./projects/bm/def_9.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_10a.json > ./projects/bm/def_10.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_11a.json > ./projects/bm/def_11.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_12a.json > ./projects/bm/def_12.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_13a.json > ./projects/bm/def_13.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_14a.json > ./projects/bm/def_14.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bm/def_15a.json > ./projects/bm/def_15.json
awk "{gsub(\"YYYYYY\",\"true\"); print}"   ./projects/bm/def_16a.json > ./projects/bm/def_16.json
awk "{gsub(\"YYYYYY\",\"true\"); print}"   ./projects/bm/def_17a.json > ./projects/bm/def_17.json
awk "{gsub(\"YYYYYY\",\"true\"); print}"   ./projects/bm/def_18a.json > ./projects/bm/def_18.json
awk "{gsub(\"YYYYYY\",\"true\"); print}"   ./projects/bm/def_19a.json > ./projects/bm/def_19.json


awk "{gsub(\"XXXXXX\",\"0\"); print}" ./projects/bm/def.html  > ./projects/bm/0.html
awk "{gsub(\"XXXXXX\",\"1\"); print}" ./projects/bm/def.html  > ./projects/bm/1.html
awk "{gsub(\"XXXXXX\",\"2\"); print}" ./projects/bm/def.html  > ./projects/bm/2.html
awk "{gsub(\"XXXXXX\",\"3\"); print}" ./projects/bm/def.html  > ./projects/bm/3.html
awk "{gsub(\"XXXXXX\",\"4\"); print}" ./projects/bm/def.html  > ./projects/bm/4.html
awk "{gsub(\"XXXXXX\",\"5\"); print}" ./projects/bm/def.html  > ./projects/bm/5.html
awk "{gsub(\"XXXXXX\",\"6\"); print}" ./projects/bm/def.html  > ./projects/bm/6.html
awk "{gsub(\"XXXXXX\",\"7\"); print}" ./projects/bm/def.html  > ./projects/bm/7.html
awk "{gsub(\"XXXXXX\",\"8\"); print}" ./projects/bm/def.html  > ./projects/bm/8.html
awk "{gsub(\"XXXXXX\",\"9\"); print}" ./projects/bm/def.html  > ./projects/bm/9.html
awk "{gsub(\"XXXXXX\",\"10\"); print}" ./projects/bm/def.html  > ./projects/bm/10.html
awk "{gsub(\"XXXXXX\",\"11\"); print}" ./projects/bm/def.html  > ./projects/bm/11.html
awk "{gsub(\"XXXXXX\",\"12\"); print}" ./projects/bm/def.html  > ./projects/bm/12.html
awk "{gsub(\"XXXXXX\",\"13\"); print}" ./projects/bm/def.html  > ./projects/bm/13.html
awk "{gsub(\"XXXXXX\",\"14\"); print}" ./projects/bm/def.html  > ./projects/bm/14.html
awk "{gsub(\"XXXXXX\",\"15\"); print}" ./projects/bm/def.html  > ./projects/bm/15.html
awk "{gsub(\"XXXXXX\",\"16\"); print}" ./projects/bm/def.html  > ./projects/bm/16.html
awk "{gsub(\"XXXXXX\",\"17\"); print}" ./projects/bm/def.html  > ./projects/bm/17.html
awk "{gsub(\"XXXXXX\",\"18\"); print}" ./projects/bm/def.html  > ./projects/bm/18.html
awk "{gsub(\"XXXXXX\",\"19\"); print}" ./projects/bm/def.html  > ./projects/bm/19.html


dfx build --network local origyn_nft_reference
dfx build --network local origyn_sale_reference

gzip .dfx/local/canisters/origyn_nft_reference/origyn_nft_reference.wasm -f
gzip .dfx/local/canisters/origyn_sale_reference/origyn_sale_reference.wasm -f

#Replace below with your test principal

TEST_WALLET=$(echo "coapo-5z5t4-5azo7-idouv-jsvee-vzf6k-33ror-oncap-be2yg-6cavw-pqe")


dfx canister --network $env_network install $env_name  --wasm .dfx/local/canisters/origyn_nft_reference/origyn_nft_reference.wasm.gz --mode=reinstall

dfx canister --network $env_network call $env_name manage_storage_nft_origyn '(variant {configure_storage = variant {heap = opt (500000000:nat)}})'


dfx canister --network $env_network call $env_name collection_update_nft_origyn "(variant {UpdateOwner = principal \"$ADMIN_PRINCIPAL\"})"




dfx canister --network $env_network install $env_name_sale --wasm .dfx/local/canisters/origyn_sale_reference/origyn_sale_reference.wasm.gz --mode=reinstall --argument "(record {owner=principal  \"$ADMIN_PRINCIPAL\"; allocation_expiration = 450000000000; nft_gateway= opt principal \"$NFT_CANISTER_ID\"; sale_open_date=null; registration_date = null; end_date = null; required_lock_date=null})"

node ./projects/deploy.js --meta=./projects/bm/def_collection_loaded.json --token_id=""  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod

echo "done with  collection"

node ./projects/deploy.js --meta=./projects/bm/def_0.json --token_id="bm-0"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_1.json --token_id="bm-1"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_2.json --token_id="bm-2"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_3.json --token_id="bm-3"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_4.json --token_id="bm-4"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_5.json --token_id="bm-5"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_6.json --token_id="bm-6"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_7.json --token_id="bm-7"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_8.json --token_id="bm-8"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_9.json --token_id="bm-9"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_10.json --token_id="bm-10"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_11.json --token_id="bm-11"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_12.json --token_id="bm-12"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_13.json --token_id="bm-13"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_14.json --token_id="bm-14"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_15.json --token_id="bm-15"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_16.json --token_id="bm-16"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_17.json --token_id="bm-17"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_18.json --token_id="bm-18"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bm/def_19.json --token_id="bm-19"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod

rm def_collection_build.json
