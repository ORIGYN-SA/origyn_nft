set -ex

dfx identity new test_nft_ref || true
dfx identity use test_nft_ref

ADMIN_PRINCIPAL=$(dfx identity get-principal)
ADMIN_ACCOUNTID=$(dfx ledger account-id)

echo $ADMIN_PRINCIPAL
echo $ADMIN_ACCOUNTID


dfx canister create test_runner_nft
dfx canister create dfxledger
dfx canister create dfxledger2
dfx canister create test_canister_factory
dfx canister create test_storage_factory
dfx canister create test_runner

DFX_LEDGER_CANISTER_ID=$(dfx canister id dfxledger)
DFX_LEDGER_ACCOUNT_ID=$(python3 principal_to_accountid.py $DFX_LEDGER_CANISTER_ID)

DFX_LEDGER_CANISTER2_ID=$(dfx canister id dfxledger2)
DFX_LEDGER_ACCOUNT2_ID=$(python3 principal_to_accountid.py $DFX_LEDGER_CANISTER2_ID)

TEST_RUNNER_CANISTER_ID=$(dfx canister id test_runner)
TEST_RUNNER_ACCOUNT_ID=$(python3 principal_to_accountid.py $TEST_RUNNER_CANISTER_ID)


TEST_RUNNER_NFT_CANISTER_ID=$(dfx canister id test_runner_nft)
TEST_RUNNER__NFT_ACCOUNT_ID=$(python3 principal_to_accountid.py $TEST_RUNNER_NFT_CANISTER_ID)

TEST_CANISTER_FACTORY_ID=$(dfx canister id test_canister_factory)
TEST_STORAGE_FACTORY_ID=$(dfx canister id test_storage_factory)

dfx build test_runner_nft
dfx build test_runner
dfx build test_canister_factory
dfx build test_storage_factory
dfx build dfxledger
dfx build dfxledger2
#dfx build test_runner_nft
#dfx build test_runner_nft_2
#dfx build test_runner_instant_transfer
#dfx build test_runner_data
#dfx build test_runner_utils

gzip ./.dfx/local/canisters/test_runner/test_runner.wasm -f
gzip ./.dfx/local/canisters/test_canister_factory/test_canister_factory.wasm -f
gzip ./.dfx/local/canisters/test_storage_factory/test_storage_factory.wasm -f
gzip ./.dfx/local/canisters/test_runner_nft/test_runner_nft.wasm -f

dfx canister install test_canister_factory --mode=reinstall --wasm ./.dfx/local/canisters/test_canister_factory/test_canister_factory.wasm.gz

dfx canister install test_storage_factory --mode=reinstall  --wasm ./.dfx/local/canisters/test_storage_factory/test_storage_factory.wasm.gz



dfx canister install test_runner_nft --mode=reinstall --wasm ./.dfx/local/canisters/test_runner_nft/test_runner_nft.wasm.gz --argument "(principal  \"$DFX_LEDGER_CANISTER_ID\", principal  \"$DFX_LEDGER_CANISTER2_ID\")"

dfx canister install test_runner --mode=reinstall --wasm ./.dfx/local/canisters/test_runner/test_runner.wasm.gz --argument "(record { canister_factory = principal \"$TEST_CANISTER_FACTORY_ID\"; storage_factory = principal \"$TEST_STORAGE_FACTORY_ID\";dfx_ledger = opt principal \"$DFX_LEDGER_CANISTER_ID\"; dfx_ledger2 = opt principal \"$DFX_LEDGER_CANISTER2_ID\";test_runner_nft = opt principal \"$TEST_RUNNER_NFT_CANISTER_ID\";})"

#dfx canister install test_runner_nft --mode=reinstall --argument "(principal  \"$DFX_LEDGER_CANISTER_ID\", principal  \"$DFX_LEDGER_CANISTER2_ID\")"

#dfx canister install test_runner_nft_2 --mode=reinstall --argument "(principal  \"$DFX_LEDGER_CANISTER_ID\", principal  \"$DFX_LEDGER_CANISTER2_ID\")"

#dfx canister install test_runner_utils --mode=reinstall --argument "(principal  \"$DFX_LEDGER_CANISTER_ID\", principal  \"$DFX_LEDGER_CANISTER2_ID\")"

#dfx canister install test_runner_data --mode=reinstall --argument "(principal  \"$DFX_LEDGER_CANISTER_ID\", principal  \"$DFX_LEDGER_CANISTER2_ID\")"

#dfx canister install test_runner_instant_transfer --mode=reinstall --argument "(principal  \"$DFX_LEDGER_CANISTER_ID\", principal  \"$DFX_LEDGER_CANISTER2_ID\")"

dfx canister install dfxledger --mode=reinstall --argument "(record { minting_account = \"$ADMIN_ACCOUNTID\"; initial_values = vec { record { \"$TEST_RUNNER_ACCOUNT_ID\"; record { e8s = 18446744073709551615: nat64 } } }; max_message_size_bytes = null; transaction_window = null; archive_options = opt record { trigger_threshold = 2000: nat64; num_blocks_to_archive = 1000: nat64; node_max_memory_size_bytes = null; max_message_size_bytes = null; controller_id = principal \"$TEST_RUNNER_CANISTER_ID\"  }; send_whitelist = vec {};standard_whitelist = vec {};transfer_fee = opt (record {e8s = 200_000}); token_symbol = null; token_name = null;admin = principal \"$TEST_RUNNER_CANISTER_ID\"})"

dfx canister install dfxledger2 --mode=reinstall --argument "(record { minting_account = \"$ADMIN_ACCOUNTID\"; initial_values = vec { record { \"$TEST_RUNNER_ACCOUNT_ID\"; record { e8s = 18446744073709551615: nat64 } } }; max_message_size_bytes = null; transaction_window = null; archive_options = opt record { trigger_threshold = 2000: nat64; num_blocks_to_archive = 1000: nat64; node_max_memory_size_bytes = null; max_message_size_bytes = null; controller_id = principal \"$TEST_RUNNER_CANISTER_ID\"  }; send_whitelist = vec {};standard_whitelist = vec {};transfer_fee = opt (record {e8s = 200_000}); token_symbol = null; token_name = null;admin = principal \"$TEST_RUNNER_CANISTER_ID\"})"


TEST_RUNNER_ID=$(dfx canister id test_runner)

echo $TEST_RUNNER_ID

dfx canister call test_runner test
#dfx canister call test_runner_nft test
#dfx canister call test_runner_data_nft test
#dfx canister call test_runner_utils_nft test

