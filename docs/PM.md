
- Check owners of NFTs 

- Instant buy
dfx canister --network local call origyn_nft_reference market_transfer_nft_origyn '(record {token_id="bm-0"; sales_config=record {pricing=variant {auction=record {start_price=200000; token=variant {ic=record {fee=100000; decimals=8; canister=principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"; standard=variant {Ledger}; symbol="ICP"}}; reserve=opt 200000; start_date=1668116562196989000; min_increase=variant {amount=10000}; allow_list=null; buy_now=opt 200000; ending=variant {date=1668116904228601000}}}; escrow_receipt=null}})'

sale id = d51077f1dfa25742255a064e84332a953823992ac3f5e42eb7d22b195fd41ad7

Place an escrow
dfx canister call origyn_nft_reference sale_nft_origyn '(variant {escrow_deposit =record {token_id ="bm-1"; deposit = record { token=variant {ic=record {fee=100000; decimals=8; canister=principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"; standard=variant {Ledger}; symbol="ICP"}}; seller =variant{ "principal" = principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"}; buyer = variant{ "principal" = principal "a32ui-7cnhe-ls6qy-5q44o-ghdd4-oi3pz-4324t-zsast-tylzk-lfxrr-rae"}; amount = 200000; sale_id =opt "d51077f1dfa25742255a064e84332a953823992ac3f5e42eb7d22b195fd41ad7";  trx_id=opt variant {nat=0};  }; lock_date = opt null; } })'

record {token_id="ogy.mintpass.2"; deposit=record {token=variant {ic=record {fee=200000; decimals=8; canister=principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"; standard=variant {Ledger}; symbol="ICP"}}; trx_id=variant {nat=0}; seller=variant {"principal"=principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"}; buyer=variant {"principal"=principal "u74sm-wx4yh-capur-xnz4w-orbcn-l3jlc-m65rb-ue5ah-mqyvz-fmvvc-tae"}; amount=200000; sale_id=opt "f0cd8cec78e60d0442aaa33698f1e0306828045b5a778dcb303c50ba2b2a1a25"}; lock_to_date=null})'