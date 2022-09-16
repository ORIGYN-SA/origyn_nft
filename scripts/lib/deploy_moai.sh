set -ex

npm install

dfx identity use local_nft_deployer

ADMIN_PRINCIPAL=$(dfx identity get-principal)
ADMIN_ACCOUNTID=$(dfx ledger account-id)

echo $ADMIN_PRINCIPAL
echo $ADMIN_ACCOUNTID

dfx canister --network $env_network create $env_name || true

NFT_CANISTER_ID=$(dfx canister --network $env_network id $env_name)
NFT_CANISTER_ACCOUNT=$(python3 principal_to_accountid.py $NFT_CANISTER_ID)

echo $NFT_CANISTER_ID
echo $NFT_CANISTER_ACCOUNT

# ********** Setup definitions

awk "{gsub(\"CANISTER-ID\",\"$NFT_CANISTER_ID\"); print}" ./projects/moai/def.json  > ./projects/moai/assets/def_loaded_1.json
awk "{gsub(\"APP-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/moai/assets/def_loaded_1.json  > ./projects/moai/assets/def_loaded_2.json
awk "{gsub(\"CREATOR-PRINCIPAL-ID\",\"$ADMIN_PRINCIPAL\"); print}" ./projects/moai/assets/def_loaded_2.json  > ./projects/moai/assets/def_loaded.json

# **********

# ********** Loop to execute batch commands

exec_batch () {

COUNTER=0
TOTAL=49

while [ $COUNTER -le $TOTAL ]
do
    if [ "$1" = "json" ]
    then
      awk "{gsub(\"XXXXXX\",\"$COUNTER\"); print}" ./projects/moai/assets/def_loaded.json  > ./projects/moai/assets/"def_$COUNTER.json"
    elif [ "$1" = "html" ]
    then
      awk "{gsub(\"XXXXXX\",\"$COUNTER\"); print}" ./projects/moai/def.html  > ./projects/moai/assets/"$COUNTER.html"
    else
      node ./projects/deploy.js --meta=./projects/moai/assets/"def_$COUNTER.json" --token_id="moai-$COUNTER"  --mint_target=$ADMIN_PRINCIPAL --nft_canister=$NFT_CANISTER_ID --mint=true --prod=$env_prod
    fi
    ((COUNTER++))
done

}

# **********

# ********** Exec commands for def.json

exec_batch "json"

# **********

# ********** Exec commands for html

exec_batch "html"

# **********

# ********** Deploy origyn_nft_reference
dfx canister --network $env_network create $env_name || true
dfx build --network $env_network $env_name
yes "yes" | dfx canister --network $env_network install $env_name --mode=reinstall --argument "(record {owner =principal  \"$ADMIN_PRINCIPAL\"})"

# **********

# ********* Dates for SALE canister
DAY_LENGTH=$((60 * 60 * 24 * 10 ** 9))
TWO_DAYS=$((DAY_LENGTH * 2))
# Now in seconds
NOW=$(date +%s)
# Right now in nanos
SALE_OPEN_DATE=$((NOW * 10 ** 9))
# Tomorrow
REGISTRATION_DATE=$((SALE_OPEN_DATE + DAY_LENGTH))
# In two days
END_DATE=$((TOMORROW + TWO_DAYS))

# **********


# ********** Deploy origyn_sale_reference

yes "yes" | dfx deploy origyn_sale_reference --mode=reinstall --argument "(record {owner = principal  \"$ADMIN_PRINCIPAL\" ; allocation_expiration = 900000000000; nft_gateway = null; sale_open_date = opt $SALE_OPEN_DATE; registration_date = opt $REGISTRATION_DATE; end_date = opt $END_DATE ; required_lock_date = null;})"

# **********

# ********** Deploy ledger

yes "yes" | dfx deploy dfxledger --mode=reinstall --argument "(record { minting_account = \"$ADMIN_ACCOUNTID\"; initial_values = vec { record { \"$ADMIN_ACCOUNTID\"; record { e8s = 18446744073709551615: nat64 } } }; max_message_size_bytes = null; transaction_window = null; archive_options = opt record { trigger_threshold = 2000: nat64; num_blocks_to_archive = 1000: nat64; node_max_memory_size_bytes = null; max_message_size_bytes = null; controller_id = principal \"$NFT_CANISTER_ID\"  }; send_whitelist = vec {};standard_whitelist = vec {};transfer_fee = null; token_symbol = null; token_name = null;admin = principal \"$NFT_CANISTER_ID\"})"

# **********

# ********** Exec commands for deploy

exec_batch "deploy"

# **********


