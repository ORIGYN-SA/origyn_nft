set -ex

ADMIN_PRINCIPAL=$(dfx identity get-principal)

dfx canister create origyn_nft_reference 
dfx build origyn_nft_reference
gzip -kf ./.dfx/local/canisters/origyn_nft_reference/origyn_nft_reference.wasm
dfx canister  install origyn_nft_reference --mode=reinstall --wasm ./.dfx/local/canisters/origyn_nft_reference/origyn_nft_reference.wasm.gz 

dfx canister call origyn_nft_reference manage_storage_nft_origyn '(variant {configure_storage = variant {stableBtree = null})'
dfx canister call origyn_nft_reference collection_update_nft_origyn '(variant {UpdateOwner = principal \"$ADMIN_PRINCIPAL\"})'

