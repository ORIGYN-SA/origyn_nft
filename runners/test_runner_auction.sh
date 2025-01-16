set -ex

dfx identity new test_nft_ref || true
dfx identity use test_nft_ref

ADMIN_PRINCIPAL=$(dfx identity get-principal)
ADMIN_ACCOUNTID=$(dfx ledger account-id)

echo $ADMIN_PRINCIPAL
echo $ADMIN_ACCOUNTID

dfx canister create test_runner
dfx canister create test_runner_nft
dfx canister create test_canister_factory
dfx canister create test_storage_factory
dfx canister create dfxledger
dfx canister create dfxledger2

DFX_LEDGER_CANISTER_ID=$(dfx canister id dfxledger)
DFX_LEDGER_ACCOUNT_ID=$(dfx ledger account-id --of-principal $DFX_LEDGER_CANISTER_ID)

DFX_LEDGER_CANISTER2_ID=$(dfx canister id dfxledger2)
DFX_LEDGER_ACCOUNT2_ID=$(dfx ledger account-id --of-principal $DFX_LEDGER_CANISTER2_ID)

TEST_RUNNER_CANISTER_ID=$(dfx canister id test_runner)
TEST_RUNNER_ACCOUNT_ID=$(dfx ledger account-id --of-principal $TEST_RUNNER_CANISTER_ID)

TEST_RUNNER_NFT_CANISTER_ID=$(dfx canister id test_runner_nft)
TEST_RUNNER_NFT_ACCOUNT_ID=$(dfx ledger account-id --of-principal $TEST_RUNNER_NFT_CANISTER_ID)

TEST_CANISTER_FACTORY_ID=$(dfx canister id test_canister_factory)
TEST_STORAGE_FACTORY_ID=$(dfx canister id test_storage_factory)

dfx build test_runner
dfx build test_runner_nft
dfx build test_canister_factory
dfx build test_storage_factory
dfx build dfxledger
dfx build dfxledger2

gzip ./.dfx/local/canisters/test_runner/test_runner.wasm -f
gzip ./.dfx/local/canisters/test_canister_factory/test_canister_factory.wasm -f
gzip ./.dfx/local/canisters/test_storage_factory/test_storage_factory.wasm -f
gzip ./.dfx/local/canisters/test_runner_nft/test_runner_nft.wasm -f

dfx canister install test_canister_factory --mode=reinstall --wasm ./.dfx/local/canisters/test_canister_factory/test_canister_factory.wasm.gz

dfx canister install test_storage_factory --mode=reinstall --wasm ./.dfx/local/canisters/test_storage_factory/test_storage_factory.wasm.gz

dfx canister install test_runner --mode=reinstall --wasm ./.dfx/local/canisters/test_runner/test_runner.wasm.gz --argument "(record { canister_factory = principal \"$TEST_CANISTER_FACTORY_ID\"; storage_factory = principal \"$TEST_STORAGE_FACTORY_ID\";dfx_ledger = opt principal \"$DFX_LEDGER_CANISTER_ID\"; test_runner_nft = opt principal \"$TEST_RUNNER_NFT_CANISTER_ID\"; test_runner_nft_2 = null; test_runner_instant = null; test_runner_data = null; test_runner_utils = null; test_runner_collection = null;test_runner_storage = null;})"

dfx canister install test_runner_nft --wasm ./.dfx/local/canisters/test_runner_nft/test_runner_nft.wasm.gz --mode=reinstall --argument "(principal  \"$DFX_LEDGER_CANISTER_ID\", principal  \"$DFX_LEDGER_CANISTER2_ID\")"

dfx canister install dfxledger --mode=reinstall --argument '(
  variant {
    Init = record {
      decimals = null;
      token_symbol = "LDG";
      transfer_fee = 200_000 : nat;
      metadata = vec {};
      minting_account = record {
        owner = principal "'$ADMIN_PRINCIPAL'"; 
        subaccount = null;
      };
      initial_balances = vec {
        record {
          record {
            owner = principal "'$TEST_RUNNER_CANISTER_ID'";
            subaccount = null;
          };
          18_446_744_073_709_551_615 : nat;
        };
      };
      maximum_number_of_accounts = null;
      accounts_overflow_trim_quantity = null;
      fee_collector_account = null;
      archive_options = record {
        num_blocks_to_archive = 1_000 : nat64;
        max_transactions_per_response = null;
        trigger_threshold = 2_000 : nat64;
        more_controller_ids = null;
        max_message_size_bytes = null;
        cycles_for_archive_creation = null;
        node_max_memory_size_bytes = null;
        controller_id = principal "'$TEST_RUNNER_CANISTER_ID'";
      };
      max_memo_length = null;
      token_name = "tmp1";
      feature_flags = null;
    }
  },
)'
dfx canister install dfxledger2 --mode=reinstall --argument '(
  variant {
    Init = record {
      decimals = null;
      token_symbol = "LDY";
      transfer_fee = 200_000 : nat;
      metadata = vec {};
      minting_account = record {
        owner = principal "'$ADMIN_PRINCIPAL'"; 
        subaccount = null;
      };
      initial_balances = vec {
        record {
          record {
            owner = principal "'$TEST_RUNNER_CANISTER_ID'";
            subaccount = null;
          };
          18_446_744_073_709_551_615 : nat;
        };
      };
      maximum_number_of_accounts = null;
      accounts_overflow_trim_quantity = null;
      fee_collector_account = null;
      archive_options = record {
        num_blocks_to_archive = 1_000 : nat64;
        max_transactions_per_response = null;
        trigger_threshold = 2_000 : nat64;
        more_controller_ids = null;
        max_message_size_bytes = null;
        cycles_for_archive_creation = null;
        node_max_memory_size_bytes = null;
        controller_id = principal "'$TEST_RUNNER_CANISTER_ID'";
      };
      max_memo_length = null;
      token_name = "tmp2";
      feature_flags = null;
    }
  },
)'

dfx canister call test_runner test
