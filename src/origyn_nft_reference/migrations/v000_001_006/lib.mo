import D "mo:base/Debug"; 
import Deque "mo:base/Deque";

import CandyTypes = "mo:candy/types";

import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 


import MigrationTypes "../types";
import v0_1_5 "../v000_001_005/types";
import v0_1_6 = "types";

module {

  let { ihash; nhash; thash; phash; calcHash } = v0_1_6.Map;

  public func upgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {

   let state = switch (prev_migration_state) { case (#v0_1_5(#data(state))) state; case (_) D.trap("Unexpected migration state") };
   
    D.print("did init work?");

    //init certification here

    return #v0_1_6(#data({
      var collection_data = state.collection_data;
      var buckets = state.buckets;
      var allocations = state.allocations;
      var canister_availible_space = state.canister_availible_space;
      var canister_allocated_storage = state.canister_allocated_storage;
      var offers = state.offers;
      var nft_metadata = state.nft_metadata;
      var escrow_balances = state.escrow_balances;
      var sales_balances = state.sales_balances;
      var nft_ledgers = state.nft_ledgers;
      var nft_sales = state.nft_sales;
      var access_tokens = state.access_tokens;
      var kyc_cache = state.kyc_cache;
      var droute = state.droute;
      var use_stableBTree = state.use_stableBTree;
      var pending_sale_notifications = state.pending_sale_notifications;
      //add certification ref here
    }));
};
  
public func downgrade(migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
  return #v0_0_0(#data);
};

  
};