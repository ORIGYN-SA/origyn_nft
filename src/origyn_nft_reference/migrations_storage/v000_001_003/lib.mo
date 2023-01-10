import MigrationTypes "../types";
import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 
import MerkleTree "mo:merkle_tree_0_1_1";
import Map_lib "mo:map_7_0_0/Map";
import Map_6 "mo:map_6_0_0/Map"; 
import CandyTypes_lib "mo:candy_0_1_12/types"; 
import D "mo:base/Debug"; 
import v0_1_0_types "../v000_001_000/types";
import v0_1_3_types = "types";


module {

  let { ihash; nhash; thash; phash; calcHash } = Map_lib;

  public func upgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    

    D.print("in upgrade v0.1.3");

    let state = switch (prev_migration_state) { case (#v0_1_0(#data(state))) state; case (_) D.trap("Unexpected migration state") };

    let nft_metadata = Map_lib.fromIter<Text, CandyTypes_lib.CandyValue>(Map_6.entries<Text, CandyTypes_lib.CandyValue>(state.nft_metadata), thash);

    let allocations  = Map_lib.fromIter<(Text, Text), v0_1_0_types.AllocationRecord>(Map_6.entries<(Text, Text), v0_1_0_types.AllocationRecord>(state.allocations),(v0_1_3_types.library_hash, v0_1_3_types.library_equal));

    return #v0_1_3(#data({
      var nft_metadata : Map_lib.Map<Text, CandyTypes_lib.CandyValue> = Map_lib.new<Text, CandyTypes_lib.CandyValue>();
      var collection_data = state.collection_data;
      var canister_availible_space = state.canister_availible_space;
      var canister_allocated_storage = state.canister_allocated_storage;
      var allocations = allocations;
      var access_tokens = Map_lib.new<Text, v0_1_3_types.HttpAccess>();
      var certified_assets = MerkleTree.empty();
   }));
  };

   public func downgrade(migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    return #v0_0_0(#data);
  };

  
};