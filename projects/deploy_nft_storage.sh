set -ex


# STORAGE_SPACE=100000000
STORAGE_SPACE=2048000000

if [[ $# -eq 0 ]]
then
    echo "No params"
else 
    echo "$# params with values: $1 "

    dfx identity use local_nft_deployer

    ADMIN_PRINCIPAL=$(dfx identity get-principal)

    # Install NFT canister 
    dfx deploy  origyn_nft_reference --mode=reinstall --argument "(record {owner =principal  \"$ADMIN_PRINCIPAL\"; storage_space =opt $STORAGE_SPACE;})"

    # Get NFT canister id
    NFT_CANISTER_ID=$(dfx canister --network local id origyn_nft_reference)

    COUNTER=1
    TOTAL=$1
    
   while [ $COUNTER -le $TOTAL ]
   do
        storage_canister_num="storage_canister_$COUNTER"

        # Install storage canister(s)
        dfx deploy $storage_canister_num  --argument "(record{gateway_canister=principal \"$NFT_CANISTER_ID\"; network=null; storage_space=opt $STORAGE_SPACE})"
        STORAGE_CAN_NUM=$(dfx canister --network local id $storage_canister_num)

        # Add storage canister(s) to NFT canister or gateway
        dfx canister call origyn_nft_reference manage_storage_nft_origyn "(variant {add_storage_canisters = vec {record {principal \"$STORAGE_CAN_NUM\"; $STORAGE_SPACE; record {0; 0; 1}}}})"
        ((COUNTER++))
    done

    # Run config, stage and mint script
#    bash  ./projects/small-scale/config-stage-mint.sh
fi