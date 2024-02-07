#!/bin/bash
set -ex

for (( i=0; i<=$2; i++ ))
do
    dfx canister --network ic call $1 back_up "($i : nat)" --query --candid .dfx/local/canisters/origyn_nft_reference/origyn_nft_reference.did >> backup_result$1.$i
    echo "done with page $i"
done