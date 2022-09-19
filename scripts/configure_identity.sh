#!/usr/bin/env bash
set -ex

dfx identity new first --disable-encryption || true

./scripts/quill generate --pem-file identity_test_nft.pem --seed-file test_nft.txt
mkdir ~/.config/dfx/identity/test_nft_ref/
cp identity_test_nft.pem ~/.config/dfx/identity/test_nft_ref/identity.pem
