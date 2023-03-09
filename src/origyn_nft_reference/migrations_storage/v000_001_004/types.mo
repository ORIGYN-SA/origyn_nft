import CandyTypes_lib "mo:candy/types"; 
import v0_1_3 "../v000_001_003/types";

import Order "mo:base/Order";
import Text "mo:base/Text";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";

import KYC "mo:icrc17_kyc/types";
// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead


module {
  
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  

  public let SB = v0_1_3.SB;
  public let Map = v0_1_3.Map;

  public type CollectionData = v0_1_3.CollectionData;

  public type CollectionDataForStorage = v0_1_3.CollectionDataForStorage;

  public type AllocationRecord = v0_1_3.AllocationRecord;

  public type HttpAccess= v0_1_3.HttpAccess;

  public func compare_library = v0_1_3.compare_library;

  public func library_equal = v0_1_3.library_equal;

  public func library_hash= v0_1_3.library_hash;

  public type State = {
    // this is the data you previously had as stable variables inside your actor class
    var nft_metadata : Map.Map<Text, CandyTypes_lib.CandyValue>;
    var collection_data : CollectionData;
    var allocations : Map.Map<(Text, Text), AllocationRecord>;
    var kyc_cache : Map.Map<Nat32, 
      {
        result : KYC.KYCResponseFuture; 
        timeout: Nat; //nanoseconds
      }>;
    var canister_availible_space : Nat;
    var canister_allocated_storage : Nat;
    var access_tokens : Map.Map<Text, HttpAccess>; 
  };
};