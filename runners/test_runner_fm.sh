set -ex

# dfx identity new test_nft_ref || true
dfx identity use test_nft_ref

ADMIN_PRINCIPAL=$(dfx identity get-principal)
ADMIN_ACCOUNTID=$(dfx ledger account-id)

echo $ADMIN_PRINCIPAL
echo $ADMIN_ACCOUNTID