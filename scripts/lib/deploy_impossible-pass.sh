set -ex

npm install

dfx identity use local_nft_deployer

dfx canister --network $env_network create $env_name
dfx build --network $env_network $env_name

ADMIN_PRINCIPAL=$(dfx identity get-principal)

echo $ADMIN_PRINCIPAL

NFT_CANISTER_ID=$(dfx canister --network $env_network id $env_name)
NFT_CANISTER_ACCOUNT=$(python3 principal_to_accountid.py $NFT_CANISTER_ID)

awk "{gsub(\"CANISTER-ID\",\"$NFT_CANISTER_ID\"); gsub(\"APP-ID\",\"$ADMIN_PRINCIPAL\"); gsub(\"CREATOR-PRINCIPAL-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/impossible-pass/assets/def-full.json  > ./projects/impossible-pass/assets/def_loaded.json

#generate random token names
arr=$(node ./projects/impossible-pass/assets/generate_names.js)
> ./projects/impossible-pass/assets/list.txt
echo $arr >> ./projects/impossible-pass/assets/list.txt

awk "{gsub(\"%\", \"_\"); gsub(\"&\", \"\n\"); print}" ./projects/impossible-pass/assets/list.txt  > ./projects/impossible-pass/assets/new_list.txt

sed -i '' -e '$ d' ./projects/impossible-pass/assets/new_list.txt || true

FILE=./projects/impossible-pass/assets/new_list.txt
index=0

while read -r line;
do
   echo $line
   awk "{gsub(\"XXXXXX\", \"$index\"); gsub(\"TOKENID\", \"$line\"); print}" ./projects/impossible-pass/assets/def_loaded.json  > ./projects/impossible-pass/assets/def_$index.json
   index=$((index+1));
done < $FILE

index=$((index-1));

yes "yes" | dfx canister --network $env_network install $env_name --mode=reinstall --argument "(record {owner =principal  \"$ADMIN_PRINCIPAL\"; storage_space = null;})"

dfx canister --network $env_network call $env_name collection_update_origyn '(vec {  variant {metadata = opt variant {Class = vec {record {name = "id"; value= variant {Text = "impossible_pass"};immutable=true;};}}};})'

node ./projects/impossible-pass/deploy-mintpass.js --meta=./projects/impossible-pass/assets/collection_def-full.json --token_id=""  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=false --prod=$env_prod

FILE=./projects/impossible-pass/assets/new_list.txt
index=0
while read -r line;
do
   node ./projects/impossible-pass/deploy-mintpass.js --meta=./projects/impossible-pass/assets/def_$index.json --token_id="$line"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
   index=$((index+1));
done < $FILE

index=$((index-1));
