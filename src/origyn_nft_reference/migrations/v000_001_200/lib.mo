import D "mo:base/Debug";

import CandyTypes_lib "mo:candy_0_1_10/types"; 
import Map_lib "mo:map_6_0_0/Map"; 
import SB_lib "mo:stablebuffer_0_2_0/StableBuffer";

import MigrationTypes "../types";
import v0_0_0 "../v000_000_000/types";
import v0_1_0 "types";

module {
  public func upgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {

    let state = switch (prev_migration_state) { case (#v0_1_0(#data(state))) state; case (_) D.trap("Unexpected migration state") };
    
    
    D.print("in upgrade");
    return #v0_1_2(#data({
        //holds info about the collection
            var collection_data = state.collection_data;
           
            //tracks storage buckets where library files can be stored
            // var buckets : Map_lib.Map<Principal, v0_1_0.BucketData> = Map_lib.new<Principal, v0_1_0.BucketData>();
            var buckets = state.buckets;
            
            //tracks token-id, library-id allocations and information about where the asset resides
            var allocations = state.allocations;
            
            //tracks space on the gateway canister
            var canister_availible_space = state.canister_availible_space;
            var canister_allocated_storage = state.canister_allocated_storage;

            //basic logging functionality for the NFT
            // var log = SB_lib.initPresized<v0_1_0.LogEntry>(1000);
            // var log_history = SB_lib.initPresized<[v0_1_0.LogEntry]>(1); //holds log history
            // var log_harvester: Principal = args.owner;  //can pull and delete logs

            //tracks metadata for a token-id
            var nft_metadata = state.nft_metadata;

            //tracks escrows for sales
            var escrow_balances = state.escrow_balances;

            //tracks sales revenue for sales
            var sales_balances = state.sales_balances;
            

            //tracks offers made from one user to another
            var offers = state.offers;

            //tracks the history of each token-id and the collection at token-id ""
            var nft_ledgers = state.nft_ledgers;
            
            //tracks the active sales in the canister
            //nyi: currently only store the latest sale so other data is destoyed, probably need to store somewhere, basic data is available in the ledger
            var nft_sales = state.nft_sales;
            
            // Add the two new fields for v0_1_2
            var halt = false;
            var data_harvester_page_size = 100;
      }));
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func downgrade(migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    let state = switch (migration_state) { case (#v0_1_2(#data(state))) state; case (_) D.trap("Unexpected migration state") };

    return #v0_1_0(#data({
        //holds info about the collection
            var collection_data = state.collection_data;
           
            //tracks storage buckets where library files can be stored
            // var buckets : Map_lib.Map<Principal, v0_1_0.BucketData> = Map_lib.new<Principal, v0_1_0.BucketData>();
            var buckets = state.buckets;
            
            //tracks token-id, library-id allocations and information about where the asset resides
            var allocations = state.allocations;
            //tracks space on the gateway canister
            var canister_availible_space = state.canister_availible_space;
            var canister_allocated_storage = state.canister_allocated_storage;

            //basic logging functionality for the NFT
            var log = SB_lib.initPresized<v0_1_0.LogEntry>(1000);
            var log_history = SB_lib.initPresized<[v0_1_0.LogEntry]>(1); //holds log history
            var log_harvester: Principal = args.owner;  //can pull and delete logs

            //tracks metadata for a token-id
            var nft_metadata = state.nft_metadata;

            //tracks escrows for sales
            var escrow_balances = state.escrow_balances;

            //tracks sales revenue for sales
            var sales_balances = state.sales_balances;
            

            //tracks offers made from one user to another
            var offers = state.offers;

            //tracks the history of each token-id and the collection at token-id ""
            var nft_ledgers = state.nft_ledgers;
            
            //tracks the active sales in the canister
            //nyi: currently only store the latest sale so other data is destoyed, probably need to store somewhere, basic data is available in the ledger
            var nft_sales = state.nft_sales;

            // Without two new fields
      }));
  };
};