import MigrationTypes "../types";
import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 
import Map_lib "mo:map_6_0_0/Map"; 
import CandyTypes_lib "mo:candy_0_1_10/types"; 
import v0_1_0_types = "types";

module {
  public func upgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {


    return #v0_1_0(#data({
      var nft_metadata : Map_lib.Map<Text, CandyTypes_lib.CandyValue> = Map_lib.new<Text, CandyTypes_lib.CandyValue>();
      var collection_data : v0_1_0_types.CollectionDataForStorage = {
          var owner = args.gateway_canister;
          var managers = [args.caller];
          var network = args.network;
      };
      var canister_availible_space = args.storage_space;
      var canister_allocated_storage = args.storage_space;
      
      var allocations : Map_lib.Map<(Text, Text), v0_1_0_types.AllocationRecord> = Map_lib.new<(Text, Text), v0_1_0_types.AllocationRecord>();

      //basic logging functionality for the NFT
      var log = SB_lib.initPresized<v0_1_0_types.LogEntry>(1000);
      var log_history = SB_lib.initPresized<[v0_1_0_types.LogEntry]>(1); //holds log history
      var log_harvester: Principal = args.caller;  //can pull and delete logs
   }));
  };

   public func downgrade(migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    return #v0_0_0(#data);
  };

  
};