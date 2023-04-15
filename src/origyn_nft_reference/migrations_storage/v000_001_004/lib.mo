import MigrationTypes "../types";
import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 
import Map_lib "mo:map_7_0_0/Map";
import CandyTypes_lib "mo:candy_0_2_0/types"; 
import D "mo:base/Debug"; 
import v0_1_3_types "../v000_001_003/types";
import v0_1_4_types = "types";

import CandyTypes_old "mo:candy_0_1_12/types"; 

import CandyUpgrade "mo:candy_0_2_0/upgrade"; 

module {

  let { ihash; nhash; thash; phash; calcHash } = Map_lib;

  public func upgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    

    D.print("in storage upgrade v0.1.4");

    let state = switch (prev_migration_state) { case (#v0_1_3(#data(state))) state; case (_) D.trap("Unexpected migration state") };

    

    return #v0_1_4(#data({
      var nft_metadata = Map_lib.map<Text, CandyTypes_old.CandyValue, CandyTypes_lib.CandyShared>(state.nft_metadata, func(k : Text, V1 : CandyTypes_old.CandyValue) : CandyTypes_lib.CandyShared{
        CandyUpgrade.upgradeCandyShared(V1);
      });
      var collection_data = state.collection_data;
      var canister_availible_space = state.canister_availible_space;
      var canister_allocated_storage = state.canister_allocated_storage;
      var allocations = state.allocations;
      var access_tokens = Map_lib.new<Text, v0_1_3_types.HttpAccess>();
   }));
  };

   public func downgrade(migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    return #v0_0_0(#data);
  };

  
};