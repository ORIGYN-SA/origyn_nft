dfx canister --network ic call origyn_nft_reference market_transfer_nft_origyn '( record {
    token_id="ogy.nftforgood_uffc.0";
    sales_config =  record {
        escrow_reciept = null;
        pricing = variant {
            auction = record{
                reserve = opt(100000000000000:nat);
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
                ending = variant{date = 1651288696000000000:int};
                min_increase = variant{amount = 100_000:nat};
            }
        }
    }
})'


dfx canister --network ic call origyn_nft_reference end_sale_nft_origyn '("ogy.nftforgood_uffc.0")'


dfx canister --network ic call origyn_nft_reference market_transfer_nft_origyn '( record {
    token_id="ogy.nftforgood_uffc.0";
    sales_config =  record {
        escrow_reciept = null;
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
                start_price = 3_500_000_000:nat;
                start_date = 0;
                ending = variant{date = 1651906800000000000:int};
                min_increase = variant{amount = 100_000_000:nat};
            }
        }
    }
})'

dfx canister --network ic call origyn_nft_reference market_transfer_nft_origyn '( record {
    token_id="ogy.nftforgood_uffc.1";
    sales_config =  record {
        escrow_reciept = null;
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
                start_price = 3_500_000_000:nat;
                start_date = 0;
                ending = variant{date = 1651906800000000000:int};
                min_increase = variant{amount = 100_000_000:nat};
            }
        }
    }
})'

dfx canister --network ic call origyn_nft_reference market_transfer_nft_origyn '( record {
    token_id="ogy.nftforgood_uffc.2";
    sales_config =  record {
        escrow_reciept = null;
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
                start_price = 3_500_000_000:nat;
                start_date = 0;
                ending = variant{date = 1651906800000000000:int};
                min_increase = variant{amount = 100_000_000:nat};
            }
        }
    }
})'