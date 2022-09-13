import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 
import Map_lib "mo:map_6_0_0/Map"; 
import CandyTypes_lib "mo:candy_0_1_10/types"; 
// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead


module {
  
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  

  public let SB = SB_lib;
  public let Map = Map_lib;
  public let CandyTypes = CandyTypes_lib;

  public type CollectionData = {
        var owner : Principal;
        var managers: [Principal];
        var network: ?Principal;   
    };

  public type CollectionDataForStorage = {

        var owner : Principal;
        var managers: [Principal];
        var network: ?Principal;

    };

    public type AllocationRecord = {
        canister : Principal;
        allocated_space: Nat;
        var available_space: Nat;
        var chunks: SB.StableBuffer<Nat>;
        token_id: Text;
        library_id: Text;
    };

    public type LogEntry = {
        event : Text;
        timestamp: Int;
        data: CandyTypes.CandyValue;
        caller: ?Principal;
    };

  public type State = {
    // this is the data you previously had as stable variables inside your actor class
    var nft_metadata : Map.Map<Text,CandyTypes.CandyValue>;

    var collection_data : CollectionData;
    var allocations : Map.Map<(Text, Text), AllocationRecord>;
    var canister_availible_space : Nat;
    var canister_allocated_storage : Nat;
    var log : SB.StableBuffer<LogEntry>;
    var log_history : SB.StableBuffer<[LogEntry]>;
    var log_harvester :  Principal;
  };
};