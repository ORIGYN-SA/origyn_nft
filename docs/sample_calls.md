
Starting an auction. Be sure to update the end date

```
dfx canister call origyn_nft_reference market_transfer_nft_origyn '( record {
    token_id="bayc-0";
    sales_config =  record {
        escrow_receipt = null;
        pricing = variant {
            auction = record{
                reserve = null;
                token = variant {
                    ic = record{
                        canister = principal "ryjl3-tyaaa-aaaaa-aaaba-cai";
                        standard = variant {Ledger =null};
                        decimals = 8:nat;
                        symbol = "ICP";
                        fee = 10000;
                    }
                };
                buy_now= null;
                start_price = 100_000:nat;
                start_date = 0;
                ending = variant{date = 1650414333000000000:int};
                min_increase = variant{amount = 100_000:nat};
            }
        }
    }
})'
```

Checking balance

dfx canister call origyn_nft_reference balance_of_nft_origyn '(variant {"principal" = principal "6i6da-t3dfv-vteyg-v5agl-tpgrm-63p4y-t5nmm-gi7nl-o72zu-jd3sc-7qe"})'


Checking the current sale of an NFT:

dfx canister call origyn_nft_reference nft_origyn '("bayc-0")'

getting the history of an nft: 

dfx canister call origyn_nft_reference history_nft_origyn '("bayc-0",null,null)'


end an auction:

dfx canister call origyn_nft_reference end_sale_nft_origyn '("bayc-0")'


Set the canister to test mode

dfx canister call origyn_nft_reference __set_time_mode '(variant{test=null})'

Advance time (so you can end an auction);

dfx canister call origyn_nft_reference __advance_time '(1650414333000001:int)'
