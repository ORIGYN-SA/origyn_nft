import D "mo:base/Debug";


import CandyTypes_lib "mo:candy_0_1_12/types"; 
import Map_6 "mo:map_6_0_0/Map"; 
import Map_lib "mo:map_7_0_0/Map"; 
import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 
import MerkleTree "mo:merkle_tree_0_1_1";

import MigrationTypes "../types";

import v0_1_0 "../v000_000_000/types";
import v0_1_1 "../v000_001_000/types";
import v0_1_3 "types";


module {

  let { ihash; nhash; thash; phash; calcHash } = Map_lib;

  public func upgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {

    D.print("in upgrade v0.1.3");

    let state = switch (prev_migration_state) { case (#v0_1_0(#data(state))) state; case (_) D.trap("Unexpected migration state") };

    let buckets = Map_lib.new<Principal, v0_1_3.BucketData>();
    
    for(thisItem in Map_6.entries(state.buckets)){
      let allocations = Map_lib.fromIter<(Text, Text), Int>(Map_6.entries(thisItem.1.allocations), (v0_1_3.library_hash, v0_1_3.library_equal));
      ignore Map_lib.put(buckets, phash, thisItem.0, {
        principal = thisItem.1.principal;
        var allocated_space = thisItem.1.allocated_space;
        var available_space = thisItem.1.available_space;
        date_added = thisItem.1.date_added;
        b_gateway = thisItem.1.b_gateway;
        var version = thisItem.1.version;
        //var allocations = Map_lib.fromIter<(Text, Text), Int>(Map_6.entries(thisItem.1.allocations), (library_hash,library_equal));
        var allocations = allocations;
      });
    };

    let offers = Map_lib.new<v0_1_3.Account, Map_lib.Map<v0_1_3.Account, Int>>();

    for(thisItem in Map_6.entries(state.offers)){
      ignore Map_lib.put<v0_1_3.Account, Map_lib.Map<v0_1_3.Account, Int>>(offers, v0_1_3.account_handler, thisItem.0, Map_lib.fromIter<v0_1_3.Account, Int>(Map_6.entries(thisItem.1), v0_1_3.account_handler));
    };

    let metadata = Map_lib.fromIter<Text, CandyTypes_lib.CandyValue>(Map_6.entries(state.nft_metadata), thash);

    let escrows = Map_lib.new<v0_1_3.Account, 
                                    Map_lib.Map<v0_1_3.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_3.TokenSpec,v0_1_3.EscrowRecord>>>>();

    for(thisFrom in Map_6.entries(state.escrow_balances)){
      let to = Map_lib.new<v0_1_3.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_3.TokenSpec, v0_1_3.EscrowRecord>>>();
      for(thisTo in Map_6.entries(thisFrom.1)){
        let tokens = Map_lib.new<Text,
                                            Map_lib.Map<v0_1_3.TokenSpec,v0_1_3.EscrowRecord>>();
        for(thisToken in Map_6.entries(thisTo.1)){
          
          ignore Map_lib.put<Text,
                                            Map_lib.Map<v0_1_3.TokenSpec,v0_1_3.EscrowRecord>>(tokens, thash, thisToken.0, Map_lib.fromIter<v0_1_3.TokenSpec, v0_1_3.EscrowRecord>(Map_6.entries(thisToken.1), v0_1_3.token_handler));
        };

        ignore Map_lib.put<v0_1_3.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_3.TokenSpec,v0_1_3.EscrowRecord>>>(to, v0_1_3.account_handler, thisTo.0, tokens);
      };
      ignore Map_lib.put<v0_1_3.Account, 
                                    Map_lib.Map<v0_1_3.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_3.TokenSpec,v0_1_3.EscrowRecord>>>>(escrows, v0_1_3.account_handler, thisFrom.0, to);
    };


    let sales = Map_lib.new<v0_1_3.Account, 
                                    Map_lib.Map<v0_1_3.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_3.TokenSpec,v0_1_3.EscrowRecord>>>>();

    for(thisTo in Map_6.entries(state.escrow_balances)){
      let from = Map_lib.new<v0_1_3.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_3.TokenSpec, v0_1_3.EscrowRecord>>>();
      for(thisFrom in Map_6.entries(thisTo.1)){
        let tokens = Map_lib.new<Text,
                                            Map_lib.Map<v0_1_3.TokenSpec,v0_1_3.EscrowRecord>>();
        for(thisToken in Map_6.entries(thisFrom.1)){
          
          ignore Map_lib.put<Text,
                                            Map_lib.Map<v0_1_3.TokenSpec,v0_1_3.EscrowRecord>>(tokens, thash, thisToken.0, Map_lib.fromIter<v0_1_3.TokenSpec, v0_1_3.EscrowRecord>(Map_6.entries(thisToken.1), v0_1_3.token_handler));
        };

        ignore Map_lib.put<v0_1_3.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_3.TokenSpec,v0_1_3.EscrowRecord>>>(from, v0_1_3.account_handler, thisFrom.0, tokens);
      };
      ignore Map_lib.put<v0_1_3.Account, 
                                    Map_lib.Map<v0_1_3.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_3.TokenSpec,v0_1_3.EscrowRecord>>>>(sales, v0_1_3.account_handler, thisTo.0, from);
    };



    let nft_ledgers = Map_lib.fromIter<Text, v0_1_3.SB.StableBuffer<v0_1_3.TransactionRecord>>(Map_6.entries(state.nft_ledgers), thash);

    let nft_sales = Map_lib.fromIter<Text, v0_1_3.SaleStatus>(Map_6.entries(state.nft_sales), thash);

    let access_tokens = Map_lib.new<Text, v0_1_3.HttpAccess>();

    return  #v0_1_3(#data({
      var collection_data = state.collection_data;
      var buckets = buckets;
      var allocations = state.allocations;
      var canister_availible_space = state.canister_availible_space;
      var canister_allocated_storage = state.canister_allocated_storage;
      var log = state.log;
      var log_history = state.log_history;
      var log_harvester = state.log_harvester;
      var offers = offers;
      var nft_metadata = metadata;
      var escrow_balances = escrows;
      var sales_balances = sales;
      var nft_ledgers = nft_ledgers;
      var nft_sales = nft_sales;
      var access_tokens = access_tokens;
      var certified_assets = MerkleTree.empty();
    }));
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func downgrade(migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    return #v0_0_0(#data);
  };
};