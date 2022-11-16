
- Check owners of NFTs 

- Instant buy
dfx canister --network local call origyn_nft_reference market_transfer_nft_origyn '(record {token_id="bm-0"; sales_config=record {pricing=variant {auction=record {start_price=200000; token=variant {ic=record {fee=100000; decimals=8; canister=principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"; standard=variant {Ledger}; symbol="ICP"}}; reserve=opt 200000; start_date=1668203992363535000; min_increase=variant {amount=10000}; allow_list=null; buy_now=opt 200000; ending=variant {date=1668204592363535000}}}; escrow_receipt=null}})'

sale id = d51077f1dfa25742255a064e84332a953823992ac3f5e42eb7d22b195fd41ad7

Place an escrow
dfx canister call origyn_nft_reference sale_nft_origyn '(variant {escrow_deposit =record {token_id ="bm-1"; deposit = record { token=variant {ic=record {fee=100000; decimals=8; canister=principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"; standard=variant {Ledger}; symbol="ICP"}}; seller =variant{ "principal" = principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"}; buyer = variant{ "principal" = principal "a32ui-7cnhe-ls6qy-5q44o-ghdd4-oi3pz-4324t-zsast-tylzk-lfxrr-rae"}; amount = 200000; sale_id =opt "d51077f1dfa25742255a064e84332a953823992ac3f5e42eb7d22b195fd41ad7";  trx_id=opt variant {nat=0};  }; lock_date = opt null; } })'

record {token_id="ogy.mintpass.2"; deposit=record {token=variant {ic=record {fee=200000; decimals=8; canister=principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"; standard=variant {Ledger}; symbol="ICP"}}; trx_id=variant {nat=0}; seller=variant {"principal"=principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"}; buyer=variant {"principal"=principal "u74sm-wx4yh-capur-xnz4w-orbcn-l3jlc-m65rb-ue5ah-mqyvz-fmvvc-tae"}; amount=200000; sale_id=opt "f0cd8cec78e60d0442aaa33698f1e0306828045b5a778dcb303c50ba2b2a1a25"}; lock_to_date=null})'

Check ICPs balance in local IC ledger
dfx canister call icp_ledger account_balance_dfx '(record {account = "1bd3f309abb6a3c082512b87bda2e1816bd4a99ed6a671b936e7d6dc18b33f6b"})'
Check OGY balance in local OGY ledger
dfx canister call ogy_ledger account_balance_dfx '(record {account = "8995b8ae84c822eda8830660a827c046e1029d77216eae5c84e5cefc8abbd602"})'

a8b202c71e6443ffe1887934d75f9a4ddf5efd317f903c07fa30810c5c1338e3

dfx canister call origyn_nft_reference sale_nft_origyn '(variant {escrow_deposit =record {token_id ="bm-1"; deposit = record { token=variant {ic=record {fee=100000; decimals=8; canister=principal "yir32-443c5-ekbjf-gaitq-pyfqj-g5lh5-dsqem-pgwol-5vsph-cgkhu-cae"; standard=variant {Ledger}; symbol="ICP"}}; seller =variant{ "principal" = principal "yir32-443c5-ekbjf-gaitq-pyfqj-g5lh5-dsqem-pgwol-5vsph-cgkhu-cae"}; buyer = variant{ "principal" = principal "uzz3u-4rw7n-23urh-bys5m-rdekt-lyhzc-qmool-z5n2h-hxw6x-vjlbp-zqe"}; amount = 200000; sale_id =opt "a8b202c71e6443ffe1887934d75f9a4ddf5efd317f903c07fa30810c5c1338e3";  trx_id=opt variant {nat=0};  }; lock_date = opt null; } })'

dfx canister call origyn_nft_reference sale_nft_origyn '(variant {escrow_deposit =record {token_id ="bm-1"; deposit = record { token=variant {ic=record {fee=100000; decimals=8; canister=principal "yir32-443c5-ekbjf-gaitq-pyfqj-g5lh5-dsqem-pgwol-5vsph-cgkhu-cae"; standard=variant {Ledger}; symbol="ICP"}}; seller =variant{ "principal" = principal "yir32-443c5-ekbjf-gaitq-pyfqj-g5lh5-dsqem-pgwol-5vsph-cgkhu-cae"}; buyer = variant{ "principal" = principal "uzz3u-4rw7n-23urh-bys5m-rdekt-lyhzc-qmool-z5n2h-hxw6x-vjlbp-zqe"}; amount = 200000; sale_id =opt "a8b202c71e6443ffe1887934d75f9a4ddf5efd317f903c07fa30810c5c1338e3";  trx_id=opt variant {nat=0};  }; lock_date = opt null; } })'

dfx canister --network local call origyn_nft_reference market_transfer_nft_origyn '(record {token_id="bm-1"; sales_config=record {pricing=variant {auction=record {start_price=200000; token=variant {ic=record {fee=100000; decimals=8; canister=principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"; standard=variant {Ledger}; symbol="ICP"}}; reserve=opt 200000; start_date=1668203992363535000; min_increase=variant {amount=10000}; allow_list=null; buy_now=opt 200000; ending=variant {date=1668204592363535000}}}; escrow_receipt=null}})'

ea503ef3edd4093c7e5b2d43573aec6349ac6bc2580f52a88dfa49693bcf6038

dfx canister call origyn_nft_reference sale_nft_origyn '(variant {escrow_deposit =record {token_id ="bm-1"; deposit = record { token=variant {ic=record {fee=100000; decimals=8; canister=principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"; standard=variant {Ledger}; symbol="ICP"}}; seller =variant{ "principal" = principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"}; buyer = variant{ "principal" = principal "uzz3u-4rw7n-23urh-bys5m-rdekt-lyhzc-qmool-z5n2h-hxw6x-vjlbp-zqe"}; amount = 200000; sale_id =opt "ea503ef3edd4093c7e5b2d43573aec6349ac6bc2580f52a88dfa49693bcf6038";  trx_id=opt variant {nat=0};  }; lock_date = opt null; } })'

