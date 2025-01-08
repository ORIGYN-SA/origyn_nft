import D "mo:base/Debug";
import Deque "mo:base/Deque";
import Array "mo:base/Array";

import CandyTypes = "mo:candy/types";

import SB_lib "mo:stablebuffer_0_2_0/StableBuffer";
import Map_lib "mo:map_7_0_0/Map";
import Set_Lib "mo:map_7_0_0/Set";
import Buffer "mo:base/Buffer";
import TimerTool "mo:timer-tool";

import MigrationTypes "../types";
import v0_1_6 "../v000_001_006/types";
import v0_1_7 = "types";
import NFTUtils "../../utils";

import BlockTypes "../../ledger/block_types";

import CertTree "mo:cert/CertTree";

import ICRC3 "mo:icrc3-mo";
import Market "../../market";

module {

  let { ihash; nhash; thash; phash; calcHash } = v0_1_7.Map;
  let Map = v0_1_7.Map;
  let Set = v0_1_7.Set;

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
    let new_escrow_balances = convertEscrowBalancesMap7ToMap9(state.escrow_balances);
    let new_sales_balances = convertSalesBalancesMap7ToMap9(state.sales_balances);
    let new_ledgers = convertLedgersMap7ToMap9(state.nft_ledgers);
    let new_master_ledger = convertMasterLedgerMap7ToMap9(state.master_ledger);

    return #v0_1_7(
      #data({
        var collection_data = state.collection_data;
        var buckets = new_buckets;
        var allocations = new_allocations;
        var canister_availible_space = state.canister_availible_space;
        var canister_allocated_storage = state.canister_allocated_storage;
        var offers = new_offers;
        var nft_metadata = new_nft_metadata;
        var escrow_balances = new_escrow_balances;
        var sales_balances = new_sales_balances;
        var fee_deposit_balances = Map.new<v0_1_7.Account, Map.Map<v0_1_7.TokenSpec, v0_1_7.FeeDepositDetail>>();
        var nft_ledgers = new_ledgers;
        var master_ledger = new_master_ledger;
        var nft_sales = new_sales;
        var access_tokens = new_access_tokens;
        var droute = state.droute;
        var use_stableBTree = state.use_stableBTree;
        var pending_sale_notifications = convertPendingSaleNotificationsSet7ToSet9(state.pending_sale_notifications);
        var icrc3_migration_state = state.icrc3_migration_state;
        var cert_store = state.cert_store;
        var timerState = state.timerState;
        /* add certification ref here */
      })
    );
  };

  public func downgrade(migration_state : MigrationTypes.State, args : MigrationTypes.Args, caller : Principal) : MigrationTypes.State {
    return #v0_0_0(#data);
  };

  public func convertPendingSaleNotificationsSet7ToSet9(set7 : Set_Lib.Set<Text>) : Set.Set<Text> {
    let set9 = Set.new<Text>();
    for (item in Set_Lib.keys(set7)) {
      Set.add<Text>(set9, Set.thash, item);
    };
    return set9;
  };

  public func sales_convertMap7ToMap9(map7 : Map_lib.Map<Text, v0_1_6.SaleStatus>) : Map.Map<Text, v0_1_7.SaleStatus> {
    let map9 = Map.new<Text, v0_1_7.SaleStatus>();
    for ((key, value) in Map_lib.entries(map7)) {
      let newValue = convertSaleStatus7To9(value);
      Map.set(map9, Map.thash, key, newValue);
    };
    return map9;
  };

  public func convertBucketsMap7ToMap9(map7 : Map_lib.Map<Principal, v0_1_6.BucketData>) : Map.Map<Principal, v0_1_7.BucketData> {
    let map9 = Map.new<Principal, v0_1_7.BucketData>();
    for ((key, value) in Map_lib.entries(map7)) {
      let newAllocations = Map.new<(Text, Text), Int>();
      for ((allocKey, allocValue) in Map_lib.entries(value.allocations)) {
        Map.set(newAllocations, (NFTUtils.library_hash, NFTUtils.library_equal), allocKey, allocValue);
      };
      let newValue : v0_1_7.BucketData = {
        principal = value.principal;
        var allocated_space = value.allocated_space;
        var available_space = value.available_space;
        date_added = value.date_added;
        b_gateway = value.b_gateway;
        var version = value.version;
        var allocations = newAllocations;
      };
      Map.set(map9, Map.phash, key, newValue);
    };
    return map9;
  };

  public func convertAllocationsMap7ToMap9(map7 : Map_lib.Map<(Text, Text), v0_1_6.AllocationRecord>) : Map.Map<(Text, Text), v0_1_7.AllocationRecord> {
    let map9 = Map.new<(Text, Text), v0_1_7.AllocationRecord>();
    for ((key, value) in Map_lib.entries(map7)) {
      Map.set(map9, (NFTUtils.library_hash, NFTUtils.library_equal), key, value);
    };
    return map9;
  };

  public func convertOffersMap7ToMap9(map7 : Map_lib.Map<v0_1_6.Account, Map_lib.Map<v0_1_6.Account, Int>>) : Map.Map<v0_1_7.Account, Map.Map<v0_1_7.Account, Int>> {
    let map9 = Map.new<v0_1_7.Account, Map.Map<v0_1_7.Account, Int>>();
    for ((key, value) in Map_lib.entries(map7)) {
      let innerMap = Map.new<v0_1_7.Account, Int>();
      for ((innerKey, innerValue) in Map_lib.entries(value)) {
        Map.set(innerMap, v0_1_7.account_handler, innerKey, innerValue);
      };
      Map.set(map9, v0_1_7.account_handler, key, innerMap);
    };
    return map9;
  };

  public func convertNftMetadataMap7ToMap9(map7 : Map_lib.Map<Text, v0_1_7.CandyTypes.CandyShared>) : Map.Map<Text, v0_1_7.CandyTypes.CandyShared> {
    let map9 = Map.new<Text, v0_1_7.CandyTypes.CandyShared>();
    for ((key, value) in Map_lib.entries(map7)) {
      Map.set(map9, Map.thash, key, value);
    };
    return map9;
  };

  public func convertAccessTokensMap7ToMap9(map7 : Map_lib.Map<Text, v0_1_6.HttpAccess>) : Map.Map<Text, v0_1_7.HttpAccess> {
    let map9 = Map.new<Text, v0_1_7.HttpAccess>();
    for ((key, value) in Map_lib.entries(map7)) {
      Map.set(map9, Map.thash, key, value);
    };
    return map9;
  };

  public func convertEscrowBalancesMap7ToMap9(map7 : Map_lib.Map<v0_1_6.Account, Map_lib.Map<v0_1_6.Account, Map_lib.Map<Text, Map_lib.Map<v0_1_6.TokenSpec, v0_1_6.EscrowRecord>>>>) : Map.Map<v0_1_7.Account, Map.Map<v0_1_7.Account, Map.Map<Text, Map.Map<v0_1_7.TokenSpec, v0_1_7.EscrowRecord>>>> {
    let map9 = Map.new<v0_1_7.Account, Map.Map<v0_1_7.Account, Map.Map<Text, Map.Map<v0_1_7.TokenSpec, v0_1_7.EscrowRecord>>>>();
    for ((key, value) in Map_lib.entries(map7)) {
      let innerMap1 = Map.new<v0_1_7.Account, Map.Map<Text, Map.Map<v0_1_7.TokenSpec, v0_1_7.EscrowRecord>>>();
      for ((innerKey1, innerValue1) in Map_lib.entries(value)) {
        let innerMap2 = Map.new<Text, Map.Map<v0_1_7.TokenSpec, v0_1_7.EscrowRecord>>();
        for ((innerKey2, innerValue2) in Map_lib.entries(innerValue1)) {
          let innerMap3 = Map.new<v0_1_7.TokenSpec, v0_1_7.EscrowRecord>();
          for ((innerKey3, innerValue3) in Map_lib.entries(innerValue2)) {
            Map.set(innerMap3, v0_1_7.token_handler, innerKey3, innerValue3);
          };
          Map.set(innerMap2, Map.thash, innerKey2, innerMap3);
        };
        Map.set(innerMap1, v0_1_7.account_handler, innerKey1, innerMap2);
      };
      Map.set(map9, v0_1_7.account_handler, key, innerMap1);
    };
    return map9;
  };

  public func convertSalesBalancesMap7ToMap9(map7 : Map_lib.Map<v0_1_6.Account, Map_lib.Map<v0_1_6.Account, Map_lib.Map<Text, Map_lib.Map<v0_1_6.TokenSpec, v0_1_6.EscrowRecord>>>>) : Map.Map<v0_1_7.Account, Map.Map<v0_1_7.Account, Map.Map<Text, Map.Map<v0_1_7.TokenSpec, v0_1_7.EscrowRecord>>>> {
    let map9 = Map.new<v0_1_7.Account, Map.Map<v0_1_7.Account, Map.Map<Text, Map.Map<v0_1_7.TokenSpec, v0_1_7.EscrowRecord>>>>();
    for ((key, value) in Map_lib.entries(map7)) {
      let innerMap1 = Map.new<v0_1_7.Account, Map.Map<Text, Map.Map<v0_1_7.TokenSpec, v0_1_7.EscrowRecord>>>();
      for ((innerKey1, innerValue1) in Map_lib.entries(value)) {
        let innerMap2 = Map.new<Text, Map.Map<v0_1_7.TokenSpec, v0_1_7.EscrowRecord>>();
        for ((innerKey2, innerValue2) in Map_lib.entries(innerValue1)) {
          let innerMap3 = Map.new<v0_1_7.TokenSpec, v0_1_7.EscrowRecord>();
          for ((innerKey3, innerValue3) in Map_lib.entries(innerValue2)) {
            Map.set(innerMap3, v0_1_7.token_handler, innerKey3, innerValue3);
          };
          Map.set(innerMap2, Map.thash, innerKey2, innerMap3);
        };
        Map.set(innerMap1, v0_1_7.account_handler, innerKey1, innerMap2);
      };
      Map.set(map9, v0_1_7.account_handler, key, innerMap1);
    };
    return map9;
  };

  public func convertLedgersMap7ToMap9(map7 : Map_lib.Map<Text, SB_lib.StableBuffer<v0_1_6.TransactionRecord>>) : Map.Map<Text, SB_lib.StableBuffer<v0_1_7.TransactionRecord>> {
    let map9 = Map.new<Text, SB_lib.StableBuffer<v0_1_7.TransactionRecord>>();
    for ((key, value) in Map_lib.entries(map7)) {
      let buffer = SB_lib.initPresized<v0_1_7.TransactionRecord>(SB_lib.size(value));
      for (thisItem in SB_lib.vals<v0_1_6.TransactionRecord>(value)) {
        SB_lib.add<v0_1_7.TransactionRecord>(
          buffer,
          {
            token_id = thisItem.token_id;
            index = thisItem.index;
            timestamp = thisItem.timestamp;
            txn_type = switch (thisItem.txn_type) {
              case (#auction_bid(e)) { #auction_bid(e) };
              case (#mint(e)) { #mint(e) };
              case (#sale_ended(e)) { #sale_ended(e) };
              case (#royalty_paid(e)) { #royalty_paid(e) };
              case (#sale_opened(e)) { #sale_opened(convertSaleOpened7To9(e)) };
              case (#owner_transfer(e)) { #owner_transfer(e) };
              case (#escrow_deposit(e)) { #escrow_deposit(e) };
              case (#escrow_withdraw(e)) { #escrow_withdraw(e) };
              case (#deposit_withdraw(e)) { #deposit_withdraw(e) };
              case (#sale_withdraw(e)) { #sale_withdraw(e) };
              case (#canister_owner_updated(e)) { #canister_owner_updated(e) };
              case (#canister_managers_updated(e)) {
                #canister_managers_updated(e);
              };
              case (#canister_network_updated(e)) {
                #canister_network_updated(e);
              };
              case (#data(e)) { #data(e) };
              case (#burn(e)) { #burn(e) };
              case (#fee_deposit(e)) { #fee_deposit(e) };
              case (#fee_deposit_withdraw(e)) { #fee_deposit_withdraw(e) };
              case (#extensible(e)) { #extensible(e) };
            };
          },
        );
      };
      Map.set(map9, Map.thash, key, buffer);
    };
    return map9;
  };

  public func convertMasterLedgerMap7ToMap9(buffer7 : SB_lib.StableBuffer<v0_1_6.TransactionRecord>) : SB_lib.StableBuffer<v0_1_7.TransactionRecord> {
    let buffer9 = SB_lib.initPresized<v0_1_7.TransactionRecord>(SB_lib.size(buffer7));
    for (thisItem in SB_lib.vals<v0_1_6.TransactionRecord>(buffer7)) {
      SB_lib.add<v0_1_7.TransactionRecord>(
        buffer9,
        {
          token_id = thisItem.token_id;
          index = thisItem.index;
          timestamp = thisItem.timestamp;
          txn_type = switch (thisItem.txn_type) {
            case (#auction_bid(e)) { #auction_bid(e) };
            case (#mint(e)) { #mint(e) };
            case (#sale_ended(e)) { #sale_ended(e) };
            case (#royalty_paid(e)) { #royalty_paid(e) };
            case (#sale_opened(e)) { #sale_opened(convertSaleOpened7To9(e)) };
            case (#owner_transfer(e)) { #owner_transfer(e) };
            case (#escrow_deposit(e)) { #escrow_deposit(e) };
            case (#escrow_withdraw(e)) { #escrow_withdraw(e) };
            case (#deposit_withdraw(e)) { #deposit_withdraw(e) };
            case (#sale_withdraw(e)) { #sale_withdraw(e) };
            case (#canister_owner_updated(e)) { #canister_owner_updated(e) };
            case (#canister_managers_updated(e)) {
              #canister_managers_updated(e);
            };
            case (#canister_network_updated(e)) { #canister_network_updated(e) };
            case (#data(e)) { #data(e) };
            case (#burn(e)) { #burn(e) };
            case (#fee_deposit(e)) { #fee_deposit(e) };
            case (#fee_deposit_withdraw(e)) { #fee_deposit_withdraw(e) };
            case (#extensible(e)) { #extensible(e) };
          };
        },
      );
    };
    return buffer9;
  };

  public func convertPricingConfigShared7To9(pricing7 : v0_1_6.PricingConfigShared) : v0_1_7.PricingConfigShared {
    switch (pricing7) {
      case (#instant(config)) {
        #instant(convertInstantConfigShared7To9(config));
      };
      case (#auction(config)) {
        // TODO logs errors ?
        #extensible(#Option(null));
      };
      case (#ask(config)) { #ask(convertAskConfigShared7To9(config)) };
      case (#extensible(ext)) { #extensible(ext) };
    };
  };

  public func convertSaleOpened7To9(
    saleOpened7 : {
      pricing : v0_1_6.PricingConfigShared;
      sale_id : Text;
      extensible : v0_1_6.CandyTypes.CandyShared;
    }
  ) : {
    pricing : v0_1_7.PricingConfigShared;
    sale_id : Text;
    extensible : v0_1_7.CandyTypes.CandyShared;
  } {
    {
      pricing = convertPricingConfigShared7To9(saleOpened7.pricing);
      sale_id = saleOpened7.sale_id;
      extensible = saleOpened7.extensible;
    };
  };

  public func convertAuctionState7To9(state7 : v0_1_6.AuctionState) : v0_1_7.AuctionState {
    {
      config = switch (state7.config) {
        case (#ask(ask_config)) { #ask(convertAskState7To9(ask_config)) };
        case (#auction(auction_config)) {
          // TODO logs errors ?
          #extensible(#Option(null));
        };
        case (#instant(instant_config)) {
          #instant(convertInstantConfig7To9(instant_config));
        };
        case (#extensible(extensible_config)) { #extensible(extensible_config) };
      };
      var current_bid_amount = state7.current_bid_amount;
      var current_config = convertBidConfig7To9(state7.current_config);
      var current_escrow = state7.current_escrow;
      var end_date = state7.end_date;
      var start_date = state7.start_date;
      token = state7.token;
      var min_next_bid = state7.min_next_bid;
      var wait_for_quiet_count = state7.wait_for_quiet_count;
      allow_list = convertAllowList7To9(state7.allow_list);
      var participants = convertParticipantsMap7ToMap9(state7.participants);
      var status = state7.status;
      var notify_queue = state7.notify_queue;
      var winner = state7.winner;
    };
  };

  public func convertAllowList7To9(allowList7 : ?Map_lib.Map<Principal, Bool>) : ?Map.Map<Principal, Bool> {
    switch (allowList7) {
      case (?map7) {
        let map9 = Map.new<Principal, Bool>();
        for ((key, value) in Map_lib.entries(map7)) {
          Map.set(map9, Map.phash, key, value);
        };
        ?map9;
      };
      case (null) { null };
    };
  };

  public func convertParticipantsMap7ToMap9(map7 : Map_lib.Map<Principal, Int>) : Map.Map<Principal, Int> {
    let map9 = Map.new<Principal, Int>();
    for ((key, value) in Map_lib.entries(map7)) {
      Map.set(map9, Map.phash, key, value);
    };
    return map9;
  };

  public func convertAskState7To9(ask6 : v0_1_6.AskConfig) : v0_1_7.AskConfig {
    switch (ask6) {
      case (?val) {
        let innerMap = Map.new<v0_1_7.AskFeatureKey, v0_1_7.AskFeature>();
        for ((innerKey, innerValue) in Map_lib.entries(val)) {
          switch (innerValue) {
            case (#atomic) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #atomic, #atomic);
            };
            case (#buy_now(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #buy_now, #buy_now(e));
            };
            case (#wait_for_quiet(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #wait_for_quiet, #wait_for_quiet(e));
            };
            case (#allow_list(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #allow_list, #allow_list(e));
            };
            case (#notify(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #notify, #notify(e));
            };
            case (#reserve(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #reserve, #reserve(e));
            };
            case (#start_date(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #start_date, #start_date(e));
            };
            case (#start_price(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #start_price, #start_price(e));
            };
            case (#min_increase(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #min_increase, #min_increase(e));
            };
            case (#ending(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #ending, #ending(e));
            };
            case (#token(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #token, #token(e));
            };
            case (#dutch(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #dutch, #dutch(e));
            };
            case (#kyc(e)) {};
            case (#nifty_settlement(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #nifty_settlement, #nifty_settlement(e));
            };
            case (#fee_accounts(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #fee_accounts, #fee_accounts(e));
            };
            case (#fee_schema(e)) {
              Map.set(innerMap, v0_1_7.ask_feature_set_tool, #fee_schema, #fee_schema(e));
            };
          };

        };
        ?innerMap;
      };
      case (null) { null };
    };
  };

  public func convertAskConfigShared7To9(ask6 : v0_1_6.AskConfigShared) : v0_1_7.AskConfigShared {
    switch (ask6) {
      case (?val) {
        let buffer9 = Buffer.Buffer<v0_1_7.AskFeature>(Array.size(val));
        for (feature in Array.vals(val)) {
          let newFeature = switch (feature) {
            case (#atomic) { buffer9.add(#atomic) };
            case (#buy_now(e)) { buffer9.add(#buy_now(e)) };
            case (#wait_for_quiet(e)) {
              buffer9.add(#wait_for_quiet(e));
            };
            case (#allow_list(e)) { buffer9.add(#allow_list(e)) };
            case (#notify(e)) { buffer9.add(#notify(e)) };
            case (#reserve(e)) { buffer9.add(#reserve(e)) };
            case (#start_date(e)) { buffer9.add(#start_date(e)) };
            case (#start_price(e)) { buffer9.add(#start_price(e)) };
            case (#min_increase(e)) { buffer9.add(#min_increase(e)) };
            case (#ending(e)) { buffer9.add(#ending(e)) };
            case (#token(e)) { buffer9.add(#token(e)) };
            case (#dutch(e)) { buffer9.add(#dutch(e)) };
            case (#kyc(e)) {};
            case (#nifty_settlement(e)) {
              buffer9.add(#nifty_settlement(e));
            };
            case (#fee_accounts(e)) { buffer9.add(#fee_accounts(e)) };
            case (#fee_schema(e)) { buffer9.add(#fee_schema(e)) };
          };

        };
        ?Buffer.toArray<v0_1_7.AskFeature>(buffer9);
      };
      case (null) { null };
    };
  };

  public func convertInstantConfig7To9(instant6 : v0_1_6.InstantConfig) : v0_1_7.InstantConfig {
    switch (instant6) {
      case (?val) {
        let innerMap = Map.new<v0_1_7.InstantFeatureKey, v0_1_7.InstantFeature>();
        for ((innerKey, innerValue) in Map_lib.entries(val)) {
          let newValue = switch (innerValue) {
            case (#fee_schema(e)) { #fee_schema(e) };
            case (#fee_accounts(e)) { #fee_accounts(e) };
            case (#transfer(e)) { #transfer(e) };
          };
          Map.set(innerMap, v0_1_7.instant_feature_set_tool, innerKey, newValue);
        };
        ?innerMap;
      };
      case (null) { null };
    };
  };

  public func convertInstantConfigShared7To9(instant6 : v0_1_6.InstantConfigShared) : v0_1_7.InstantConfigShared {
    switch (instant6) {
      case (?val) {
        let buffer9 = Buffer.Buffer<v0_1_7.InstantFeature>(Array.size(val));
        for (feature in Array.vals(val)) {
          let newFeature = switch (feature) {
            case (#fee_schema(e)) { #fee_schema(e) };
            case (#fee_accounts(e)) { #fee_accounts(e) };
            case (#transfer) { #transfer };
          };
          buffer9.add(newFeature);
        };
        ?Buffer.toArray<v0_1_7.InstantFeature>(buffer9);
      };
      case (null) { null };
    };
  };

  public func convertBidConfig7To9(instant6 : v0_1_6.BidConfig) : v0_1_7.BidConfig {
    switch (instant6) {
      case (?val) {
        let innerMap : v0_1_7.BidFeatureMap = Map.new<v0_1_7.BidFeatureKey, v0_1_7.BidFeature>();
        for ((innerKey, innerValue) in Map_lib.entries(val)) {
          let newValue = switch (innerValue) {
            case (#broker(e)) { #broker(e) };
            case (#fee_schema(e)) { #fee_schema(e) };
            case (#fee_accounts(e)) { #fee_accounts(e) };
          };
          Map.set(innerMap, v0_1_7.bid_feature_set_tool, innerKey, newValue);
        };
        ?innerMap;
      };
      case (null) { null };
    };
  };

  public func convertSaleStatus7To9(sale7 : v0_1_6.SaleStatus) : v0_1_7.SaleStatus {
    {
      sale_id = sale7.sale_id;
      original_broker_id = sale7.original_broker_id;
      broker_id = sale7.broker_id;
      token_id = sale7.token_id;
      sale_type = switch (sale7.sale_type) {
        case (#auction(state7)) { #auction(convertAuctionState7To9(state7)) };
      };
    };
  };
};
