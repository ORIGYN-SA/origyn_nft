set -ex

ADMIN_PRINCIPAL=$(dfx identity get-principal)

dfx canister create origyn_nft_reference 
dfx build origyn_nft_reference
gzip -kf ./.dfx/local/canisters/origyn_nft_reference/origyn_nft_reference.wasm
dfx canister  install origyn_nft_reference --mode=reinstall --wasm ./.dfx/local/canisters/origyn_nft_reference/origyn_nft_reference.wasm.gz --argument "(record {owner = principal \"$ADMIN_PRINCIPAL\"; storage_space = opt (2048000000:nat)})"