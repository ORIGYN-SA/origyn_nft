import D "mo:base/Debug";
import Deque "mo:base/Deque";

import CandyTypes = "mo:candy/types";

import SB_lib "mo:stablebuffer_0_2_0/StableBuffer";
import Map_lib "mo:map_7_0_0/Map";
import Buffer "mo:base/Buffer";
import TimerTool "mo:timer-tool";

import MigrationTypes "../types";
import v0_1_6 "../v000_001_006/types";
import v0_1_7 = "types";

import BlockTypes "../../ledger/block_types";

import CertTree "mo:cert/CertTree";

import ICRC3 "mo:icrc3-mo";
import Market "../../market";

module {

  let { ihash; nhash; thash; phash; calcHash } = v0_1_7.Map;
  let Map = v0_1_7.Map;

  public func upgrade(prev_migration_state : MigrationTypes.State, args : MigrationTypes.Args, caller : Principal) : MigrationTypes.State {

    let state = switch (prev_migration_state) {
      case (#v0_1_6(#data(state))) state;
      case (_) D.trap("Unexpected migration state");
    };

    D.print("did init work?");

    let new_sales : Map.Map<Text, v0_1_7.SaleStatus> = sales_convertMap7ToMap9(state.nft_sales);
    let new_buckets = convertBucketsMap7ToMap9(state.buckets);
    let new_allocations = convertAllocationsMap7ToMap9(state.allocations);
    let new_offers = convertOffersMap7ToMap9(state.offers);
    let new_nft_metadata = convertNftMetadataMap7ToMap9(state.nft_metadata);
    let new_access_tokens = convertAccessTokensMap7ToMap9(state.access_tokens);
    let new_kyc_cache = convertKycCacheMap7ToMap9(state.kyc_cache);
    let new_subcanister_state = Map.new<Principal, v0_1_7.SubcanisterState>();

    return #v0_1_7(
      #data({
        var collection_data = state.collection_data;
        var buckets = new_buckets;
        var allocations = new_allocations;
        var canister_availible_space = state.canister_availible_space;
        var canister_allocated_storage = state.canister_allocated_storage;
        var offers = new_offers;
        var nft_metadata = new_nft_metadata;
        var escrow_balances = state.escrow_balances;
        var sales_balances = state.sales_balances;
        var fee_deposit_balances = Map.new<v0_1_7.Account, Map.Map<v0_1_7.TokenSpec, v0_1_7.FeeDepositDetail>>();
        var nft_ledgers = new_ledgers;
        var master_ledger = new_master_ledger;
        var nft_sales = new_sales;
        var access_tokens = new_access_tokens;
        var kyc_cache = new_kyc_cache;
        var droute = state.droute;
        var use_stableBTree = state.use_stableBTree;
        var pending_sale_notifications = state.pending_sale_notifications;
        var icrc3_migration_state = state.icrc3_migration_state;
        var cert_store = state.cert_store;
        var timerState = state.timerTool;
        var subcanister_state = new_subcanister_state;
        /* add certification ref here */
      })
    );
  };

  public func downgrade(migration_state : MigrationTypes.State, args : MigrationTypes.Args, caller : Principal) : MigrationTypes.State {
    return #v0_0_0(#data);
  };

  public func sales_convertMap7ToMap9(map7 : Map_lib.Map<Text, v0_1_6.SaleStatus>) : Map.Map<Text, v0_1_7.SaleStatus> {
    let map9 = Map.new<Text, v0_1_7.SaleStatus>();
    for ((key, value) in Map_lib.entries(map7)) {
      let newValue : v0_1_7.SaleStatus = switch (value) {
        case (#active(e)) { #active(e) };
        case (#completed(e)) { #completed(e) };
        case (#cancelled(e)) { #cancelled(e) };
      };
      Map.set(map9, key, newValue);
    };
    return map9;
  };

  public func convertBucketsMap7ToMap9(map7 : Map_lib.Map<Principal, v0_1_6.BucketData>) : Map.Map<Principal, v0_1_7.BucketData> {
    let map9 = Map.new<Principal, v0_1_7.BucketData>();
    for ((key, value) in Map_lib.entries(map7)) {
      let newAllocations = Map.new<(Text, Text), Int>();
      for ((allocKey, allocValue) in Map_lib.entries(value.allocations)) {
        Map.set(newAllocations, allocKey, allocValue);
      };
      let newValue : v0_1_7.BucketData = {
        principal = value.principal;
        allocated_space = value.allocated_space;
        available_space = value.available_space;
        date_added = value.date_added;
        b_gateway = value.b_gateway;
        version = value.version;
        allocations = newAllocations;
      };
      Map.set(map9, key, newValue);
    };
    return map9;
  };

  public func convertAllocationsMap7ToMap9(map7 : Map_lib.Map<(Text, Text), v0_1_6.AllocationRecord>) : Map.Map<(Text, Text), v0_1_7.AllocationRecord> {
    let map9 = Map.new<(Text, Text), v0_1_7.AllocationRecord>();
    for ((key, value) in Map_lib.entries(map7)) {
      Map.set(map9, key, value);
    };
    return map9;
  };

  public func convertOffersMap7ToMap9(map7 : Map_lib.Map<v0_1_6.Account, Map_lib.Map<v0_1_6.Account, Int>>) : Map.Map<v0_1_7.Account, Map.Map<v0_1_7.Account, Int>> {
    let map9 = Map.new<v0_1_7.Account, Map_lib.Map<v0_1_7.Account, Int>>();
    for ((key, value) in Map_lib.entries(map7)) {
      let innerMap = Map.new<v0_1_7.Account, Int>();
      for ((innerKey, innerValue) in Map_lib.entries(value)) {
        Map.set(innerMap, innerKey, innerValue);
      };
      Map.set(map9, key, innerMap);
    };
    return map9;
  };

  public func convertNftMetadataMap7ToMap9(map7 : Map_lib.Map<Text, v0_1_7.CandyTypes.CandyShared>) : Map.Map<Text, v0_1_7.CandyTypes.CandyShared> {
    let map9 = Map.new<Text, v0_1_7.CandyTypes.CandyShared>();
    for ((key, value) in Map_lib.entries(map7)) {
      Map.set(map9, key, value);
    };
    return map9;
  };

  public func convertAccessTokensMap7ToMap9(map7 : Map_lib.Map<Text, v0_1_6.HttpAccess>) : Map.Map<Text, v0_1_7.HttpAccess> {
    let map9 = Map.new<Text, v0_1_7.HttpAccess>();
    for ((key, value) in Map_lib.entries(map7)) {
      Map.set(map9, key, value);
    };
    return map9;
  };

  public func convertKycCacheMap7ToMap9(map7 : Map_lib.Map<v0_1_6.KYCTypes.KYCRequest, v0_1_6.KYCTypes.KYCResultFuture>) : Map.Map<v0_1_7.KYCTypes.KYCRequest, v0_1_7.KYCTypes.KYCResultFuture> {
    let map9 = Map.new<v0_1_7.KYCTypes.KYCRequest, v0_1_7.KYCTypes.KYCResultFuture>();
    for ((key, value) in Map_lib.entries(map7)) {
      Map.set(map9, key, value);
    };
    return map9;
  };
};
