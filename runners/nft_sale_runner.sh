set -ex


dfx identity new sales_nft_ref || true
dfx identity use sales_nft_ref

ADMIN_PRINCIPAL=$(dfx identity get-principal)
ADMIN_ACCOUNTID=$(dfx ledger account-id)

echo $ADMIN_PRINCIPAL
echo $ADMIN_ACCOUNTID

dfx deploy origyn_sale_reference --mode=reinstall --argument "(record {owner = principal  \"$ADMIN_PRINCIPAL\"})"
