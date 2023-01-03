import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 
import Map_lib "mo:map_7_0_0/Map"; 
import CandyTypes_lib "mo:candy/types"; 
import v0_1_0 "../v000_001_000/types";

import Order "mo:base/Order";
import Text "mo:base/Text";
import Nat32 "mo:base/Nat32";
// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead


module {
  
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  

  public let SB = v0_1_0.SB;

  public type CollectionData = v0_1_0.CollectionData;

  public type CollectionDataForStorage = v0_1_0.CollectionDataForStorage;

  public type AllocationRecord = v0_1_0.AllocationRecord;

  public type HttpAccess= {
      identity: Principal;
      expires: Int;
  };

  public func compare_library(x : (Text, Text), y: (Text, Text)) : Order.Order {
        let a = Text.compare(x.0, y.0);
        switch(a){
            case(#equal){
                return  Text.compare(x.1,y.1);
            };
            case(_){
                return a;
            };
        };
    };

    public func library_equal(x : (Text, Text), y: (Text, Text)) : Bool {
        
        switch(compare_library(x, y)){
            case(#equal){
                return  true;
            };
            case(_){
                return false;
            };
        };
    };

    public func library_hash(x : (Text, Text)) : Nat {
        return Nat32.toNat(Text.hash("token_id" # x.0 # "library_id" # x.1));
        
    };

  public type State = {
    // this is the data you previously had as stable variables inside your actor class
    var nft_metadata : Map_lib.Map<Text, CandyTypes_lib.CandyValue>;
    var collection_data : CollectionData;
    var allocations : Map_lib.Map<(Text, Text), AllocationRecord>;
    var canister_availible_space : Nat;
    var canister_allocated_storage : Nat;
    var access_tokens : Map_lib.Map<Text, HttpAccess>; 
  };
};