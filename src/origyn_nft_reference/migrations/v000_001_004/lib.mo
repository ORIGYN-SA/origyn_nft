import MigrationTypes "../types";
import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 
import Map_lib "mo:map_7_0_0/Map";
import CandyTypes_lib "mo:candy_0_1_12/types"; 
import D "mo:base/Debug"; 
import v0_1_3_types "../v000_001_003/types";
import v0_1_4_types = "types";
import KYCTypes = "mo:icrc17_kyc/types";
import Droute "mo:droute_client/Droute";
import Principal "mo:base/Principal";


module {

  let { ihash; nhash; thash; phash; calcHash } = Map_lib;

  public func upgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {

    var droute_main_id = Principal.fromText("rno2w-sqaaa-aaaaa-aaacq-cai");
    var droute_publisher_id = Principal.fromText("rno2w-sqaaa-aaaaa-aaacq-cai");
    var droute_suscriber_id = Principal.fromText("rno2w-sqaaa-aaaaa-aaacq-cai");

    let droute_client = Droute.new(?{
      mainId = ?droute_main_id;
      publishersIndexId= ?droute_publisher_id;
      subscribersIndexId= ?droute_suscriber_id;
    });

    

    D.print("in upgrade v0.1.4");

    let state = switch (prev_migration_state) { case (#v0_1_3(#data(state))) state; case (_) D.trap("Unexpected migration state") };

    return #v0_1_4(#data({
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
      var kyc_cache = Map_lib.new<KYCTypes.KYCRequest, KYCTypes.KYCResultFuture>();
      var droute = droute_client;

   }));
  };

   public func downgrade(migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    return #v0_0_0(#data);
  };

  
};