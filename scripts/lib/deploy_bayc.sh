set -ex

npm install

dfx identity use local_nft_deployer

ADMIN_PRINCIPAL=$(dfx identity get-principal)
ADMIN_ACCOUNTID=$(dfx ledger account-id)

echo $ADMIN_PRINCIPAL
echo $ADMIN_ACCOUNTID

dfx canister --network $env_network create $env_name || true
dfx canister --network $env_network create $env_name_sale || true

NFT_CANISTER_ID=$(dfx canister --network $env_network id $env_name)
NFT_CANISTER_Account=$(python3 principal_to_accountid.py $NFT_CANISTER_ID)

NFT_Sale_ID=$(dfx canister --network $env_network id $env_name_sale)
NFT_Sale_Account=$(python3 principal_to_accountid.py $NFT_Sale_ID)

echo $NFT_CANISTER_ID
echo $NFT_CANISTER_Account

awk "{gsub(\"CANISTER-ID\",\"$NFT_CANISTER_ID\"); print}" ./projects/bayc/def.json  > ./projects/bayc/def_loaded_1.json
awk "{gsub(\"APP-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/bayc/def_loaded_1.json  > ./projects/bayc/def_loaded_2.json
awk "{gsub(\"CREATOR-PRINCIPAL-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/bayc/def_loaded_2.json  > ./projects/bayc/def_loaded.json

awk "{gsub(\"CANISTER-ID\",\"$NFT_CANISTER_ID\"); print}" ./projects/bayc/def_collection.json  > ./projects/bayc/def_collection_1.json
awk "{gsub(\"APP-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/bayc/def_collection_1.json  > ./projects/bayc/def_collection_2.json
awk "{gsub(\"CREATOR-PRINCIPAL-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/bayc/def_collection_2.json  > ./projects/bayc/def_collection_loaded.json

awk "{gsub(\"XXXXXX\",\"0\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_0a.json
awk "{gsub(\"XXXXXX\",\"1\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_1a.json
awk "{gsub(\"XXXXXX\",\"2\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_2a.json
awk "{gsub(\"XXXXXX\",\"3\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_3a.json
awk "{gsub(\"XXXXXX\",\"4\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_4a.json
awk "{gsub(\"XXXXXX\",\"5\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_5a.json
awk "{gsub(\"XXXXXX\",\"6\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_6a.json
awk "{gsub(\"XXXXXX\",\"7\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_7a.json
awk "{gsub(\"XXXXXX\",\"8\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_8a.json
awk "{gsub(\"XXXXXX\",\"9\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_9a.json
awk "{gsub(\"XXXXXX\",\"10\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_10a.json
awk "{gsub(\"XXXXXX\",\"11\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_11a.json
awk "{gsub(\"XXXXXX\",\"12\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_12a.json
awk "{gsub(\"XXXXXX\",\"13\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_13a.json
awk "{gsub(\"XXXXXX\",\"14\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_14a.json
awk "{gsub(\"XXXXXX\",\"15\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_15a.json
awk "{gsub(\"XXXXXX\",\"16\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_16a.json
awk "{gsub(\"XXXXXX\",\"17\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_17a.json
awk "{gsub(\"XXXXXX\",\"18\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_18a.json
awk "{gsub(\"XXXXXX\",\"19\"); print}" ./projects/bayc/def_loaded.json  > ./projects/bayc/def_19a.json

awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_0a.json > ./projects/bayc/def_0.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_1a.json > ./projects/bayc/def_1.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_2a.json > ./projects/bayc/def_2.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_3a.json > ./projects/bayc/def_3.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_4a.json > ./projects/bayc/def_4.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_5a.json > ./projects/bayc/def_5.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_6a.json > ./projects/bayc/def_6.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_7a.json > ./projects/bayc/def_7.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_8a.json > ./projects/bayc/def_8.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_9a.json > ./projects/bayc/def_9.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_10a.json > ./projects/bayc/def_10.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_11a.json > ./projects/bayc/def_11.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_12a.json > ./projects/bayc/def_12.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_13a.json > ./projects/bayc/def_13.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_14a.json > ./projects/bayc/def_14.json
awk "{gsub(\"YYYYYY\",\"false\"); print}"   ./projects/bayc/def_15a.json > ./projects/bayc/def_15.json
awk "{gsub(\"YYYYYY\",\"true\"); print}"   ./projects/bayc/def_16a.json > ./projects/bayc/def_16.json
awk "{gsub(\"YYYYYY\",\"true\"); print}"   ./projects/bayc/def_17a.json > ./projects/bayc/def_17.json
awk "{gsub(\"YYYYYY\",\"true\"); print}"   ./projects/bayc/def_18a.json > ./projects/bayc/def_18.json
awk "{gsub(\"YYYYYY\",\"true\"); print}"   ./projects/bayc/def_19a.json > ./projects/bayc/def_19.json


awk "{gsub(\"XXXXXX\",\"0\"); print}" ./projects/bayc/def.html  > ./projects/bayc/0.html
awk "{gsub(\"XXXXXX\",\"1\"); print}" ./projects/bayc/def.html  > ./projects/bayc/1.html
awk "{gsub(\"XXXXXX\",\"2\"); print}" ./projects/bayc/def.html  > ./projects/bayc/2.html
awk "{gsub(\"XXXXXX\",\"3\"); print}" ./projects/bayc/def.html  > ./projects/bayc/3.html
awk "{gsub(\"XXXXXX\",\"4\"); print}" ./projects/bayc/def.html  > ./projects/bayc/4.html
awk "{gsub(\"XXXXXX\",\"5\"); print}" ./projects/bayc/def.html  > ./projects/bayc/5.html
awk "{gsub(\"XXXXXX\",\"6\"); print}" ./projects/bayc/def.html  > ./projects/bayc/6.html
awk "{gsub(\"XXXXXX\",\"7\"); print}" ./projects/bayc/def.html  > ./projects/bayc/7.html
awk "{gsub(\"XXXXXX\",\"8\"); print}" ./projects/bayc/def.html  > ./projects/bayc/8.html
awk "{gsub(\"XXXXXX\",\"9\"); print}" ./projects/bayc/def.html  > ./projects/bayc/9.html
awk "{gsub(\"XXXXXX\",\"10\"); print}" ./projects/bayc/def.html  > ./projects/bayc/10.html
awk "{gsub(\"XXXXXX\",\"11\"); print}" ./projects/bayc/def.html  > ./projects/bayc/11.html
awk "{gsub(\"XXXXXX\",\"12\"); print}" ./projects/bayc/def.html  > ./projects/bayc/12.html
awk "{gsub(\"XXXXXX\",\"13\"); print}" ./projects/bayc/def.html  > ./projects/bayc/13.html
awk "{gsub(\"XXXXXX\",\"14\"); print}" ./projects/bayc/def.html  > ./projects/bayc/14.html
awk "{gsub(\"XXXXXX\",\"15\"); print}" ./projects/bayc/def.html  > ./projects/bayc/15.html
awk "{gsub(\"XXXXXX\",\"16\"); print}" ./projects/bayc/def.html  > ./projects/bayc/16.html
awk "{gsub(\"XXXXXX\",\"17\"); print}" ./projects/bayc/def.html  > ./projects/bayc/17.html
awk "{gsub(\"XXXXXX\",\"18\"); print}" ./projects/bayc/def.html  > ./projects/bayc/18.html
awk "{gsub(\"XXXXXX\",\"19\"); print}" ./projects/bayc/def.html  > ./projects/bayc/19.html


dfx build --network $env_network $env_name
dfx build --network $env_network $env_name_sale

TEST_WALLET=$(dfx identity --network $env_network get-wallet)


yes "yes" | dfx canister --network $env_network install $env_name --mode=reinstall --argument "(record {owner =principal  \"$ADMIN_PRINCIPAL\"; storage_space = null;})"
yes "yes" | dfx canister --network $env_network install $env_name_sale --mode=reinstall --argument "(record {owner=principal  \"$ADMIN_PRINCIPAL\"; allocation_expiration = 450000000000; nft_gateway= opt principal \"$NFT_CANISTER_ID\"; sale_open_date=null; registration_date = null; end_date = null; required_lock_date=null})"

node ./projects/deploy.js --meta=./projects/bayc/def_collection_loaded.json --token_id=""  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_0.json --token_id="bayc-0"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_1.json --token_id="bayc-1"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_2.json --token_id="bayc-2"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_3.json --token_id="bayc-3"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_4.json --token_id="bayc-4"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_5.json --token_id="bayc-5"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_6.json --token_id="bayc-6"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_7.json --token_id="bayc-7"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_8.json --token_id="bayc-8"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_9.json --token_id="bayc-9"  --mint_target=$TEST_WALLET --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_10.json --token_id="bayc-10"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_11.json --token_id="bayc-11"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_12.json --token_id="bayc-12"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_13.json --token_id="bayc-13"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_14.json --token_id="bayc-14"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_15.json --token_id="bayc-15"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_16.json --token_id="bayc-16"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_17.json --token_id="bayc-17"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_18.json --token_id="bayc-18"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
node ./projects/deploy.js --meta=./projects/bayc/def_19.json --token_id="bayc-19"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod
