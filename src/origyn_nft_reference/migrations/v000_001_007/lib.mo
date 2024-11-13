import D "mo:base/Debug";
import Deque "mo:base/Deque";

import CandyTypes = "mo:candy/types";

import SB_lib "mo:stablebuffer_0_2_0/StableBuffer";
import Map_lib "mo:map_7_0_0/Map";
import Buffer "mo:base/Buffer";
import TimerTool "mo:timer-tool";

import MigrationTypes "../types";
import v0_1_5 "../v000_001_005/types";
import v0_1_6 = "types";

import BlockTypes "../../ledger/block_types";

import CertTree "mo:cert/CertTree";

import ICRC3 "mo:icrc3-mo";
import Market "../../market";

module {

  let { ihash; nhash; thash; phash; calcHash } = v0_1_6.Map;
  let Map = v0_1_6.Map;

  let upgradeAuctionConfig = func(x : v0_1_5.AuctionConfig) : v0_1_6.AuctionConfig {

    {
      reserve = x.reserve;
      token = x.token;
      buy_now = x.buy_now;
      start_price = x.start_price;
      start_date = x.start_date;
      ending = x.ending;
      min_increase = x.min_increase;
      allow_list = x.allow_list;
    };

  };

  let upgradeAskConfig = func(x : v0_1_5.AskConfig) : v0_1_6.AskConfig {
    switch (x) {
      case (?val) {
        let resultMap = Map.new<v0_1_6.AskFeatureKey, v0_1_6.AskFeature>();
        for (thisItem in Map.vals(val)) {
          switch (thisItem) {
            case (#reserve(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #reserve, #reserve(val));
            };
            case (#token(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #token, #token(val));
            };
            case (#buy_now(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #buy_now, #buy_now(val));
            };
            case (#start_price(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #start_price, #start_price(val));
            };
            case (#start_date(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #start_date, #start_date(val));
            };
            case (#ending(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #ending, #ending(val));
            };
            case (#min_increase(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #min_increase, #min_increase(val));
            };
            case (#allow_list(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #allow_list, #allow_list(val));
            };
            case (#atomic(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #atomic, #atomic(val));
            };
            case (#dutch(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #dutch, #dutch(val));
            };
            case (#kyc(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #kyc, #kyc(val));
            };
            case (#nifty_settlement(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #nifty_settlement, #nifty_settlement(val));
            };
            case (#notify(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #notify, #notify(val));
            };
            case (#wait_for_quiet(val)) {
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #wait_for_quiet, #wait_for_quiet(val));
            };

          };
        };
        return ?resultMap;
      };
      case (_) return null;
    };
  };

  let upgradeSaleStatus = func(key : Text, x : v0_1_5.SaleStatus) : ?v0_1_6.SaleStatus {
    let z : v0_1_6.AuctionState = switch (x.sale_type) {
      case (#auction(val)) {
        let config = switch (val.config) {
          case (#auction(x)) {
            #auction(upgradeAuctionConfig(x));
          };
          case (#ask(x)) {
            #ask(upgradeAskConfig(x));
          };
          case (_) {
            return null;
          };
        };

        let _config = switch (val.current_broker_id) {
          case (?_broker) {
            ?MigrationTypes.Current.bidfeatures_to_map([#broker(#principal(_broker))]);
          };
          case (null) {
            null;
          };
        };

        switch (val.current_escrow) {
          case (?_current_escrow) {
            {
              config = config;
              var current_bid_amount = val.current_bid_amount;
              var current_config = _config;
              var end_date = val.end_date;
              var start_date = val.start_date;
              token = val.token;
              var min_next_bid = val.min_next_bid;
              var current_escrow = ?{
                amount = _current_escrow.amount;
                buyer = _current_escrow.buyer;
                seller = _current_escrow.seller;
                token_id = _current_escrow.token_id;
                token = _current_escrow.token;
                sale_id = null;
                lock_to_date = null;
                account_hash = null;
              };
              var wait_for_quiet_count = val.wait_for_quiet_count;
              allow_list = val.allow_list;
              var participants = val.participants;
              var status = val.status;
              var winner = val.winner;
              var notify_queue = ?(Deque.empty<(Principal, ?MigrationTypes.Current.SubscriptionID)>());
            };

          };
          case (null) {
            {
              config = config;
              var current_bid_amount = val.current_bid_amount;
              var current_config = _config;
              var end_date = val.end_date;
              var start_date = val.start_date;
              token = val.token;
              var min_next_bid = val.min_next_bid;
              var current_escrow = null;
              var wait_for_quiet_count = val.wait_for_quiet_count;
              allow_list = val.allow_list;
              var participants = val.participants;
              var status = val.status;
              var winner = val.winner;
              var notify_queue = ?(Deque.empty<(Principal, ?MigrationTypes.Current.SubscriptionID)>());
            };
          };
        };
      };
      case (_) {
        return null;
      };
    };

    ?{
      x with
      sale_type = #auction(z);
    };
  };

  public func upgrade(prev_migration_state : MigrationTypes.State, args : MigrationTypes.Args, caller : Principal) : MigrationTypes.State {

    let state = switch (prev_migration_state) {
      case (#v0_1_5(#data(state))) state;
      case (_) D.trap("Unexpected migration state");
    };

    D.print("did init work?");

    let new_sales : Map.Map<Text, v0_1_6.SaleStatus> = Map.mapFilter<Text, v0_1_5.SaleStatus, v0_1_6.SaleStatus>(
      state.nft_sales,
      upgradeSaleStatus,
    );

    let upgradePricingConfig = func(x : v0_1_5.PricingConfig) : v0_1_6.PricingConfig {
      switch (x) {
        case (#instant) { #instant(null) };
        case (#auction(e)) { #auction(e) };
        case (#extensible(e)) { #extensible(e) };
        case (#ask(e)) {
          switch (e) {
            case (?val) {
              let m = Map.new<v0_1_6.AskFeatureKey, v0_1_6.AskFeature>();
              for ((key, value : v0_1_5.AskFeature) in Map.entries(val)) {
                let updatedValue : v0_1_6.AskFeature = switch (value) {
                  case (#atomic) { #atomic };
                  case (#buy_now(e)) { #buy_now(e) };
                  case (#wait_for_quiet(e)) { #wait_for_quiet(e) };
                  case (#allow_list(e)) { #allow_list(e) };
                  case (#notify(e)) { #notify(e) };
                  case (#reserve(e)) { #reserve(e) };
                  case (#start_date(e)) { #start_date(e) };
                  case (#start_price(e)) { #start_price(e) };
                  case (#min_increase(e)) { #min_increase(e) };
                  case (#ending(e)) { #ending(e) };
                  case (#token(e)) { #token(e) };
                  case (#dutch(e)) { #dutch(e) };
                  case (#kyc(e)) { #kyc(e) };
                  case (#nifty_settlement(e)) { #nifty_settlement(e) };
                };
                Map.set<v0_1_6.AskFeatureKey, v0_1_6.AskFeature>(m, MigrationTypes.Current.ask_feature_set_tool, key, updatedValue);
              };

              #ask(?m);
            };
            case (null) {
              #ask(null);
            };
          };
        };
      };
    };

    let upgradePricingConfigShared = func(x : v0_1_5.PricingConfigShared) : v0_1_6.PricingConfigShared {
      switch (x) {
        case (#instant) { #instant(null) };
        case (#auction(e)) { #auction(e) };
        case (#extensible(e)) { #extensible(e) };
        case (#ask(e)) {
          switch (e) {
            case (?val) {
              let buffer : Buffer.Buffer<v0_1_6.AskFeature> = Buffer.Buffer<v0_1_6.AskFeature>(1);

              for (ask_feature in val.vals()) {
                let updatedValue : v0_1_6.AskFeature = switch (ask_feature) {
                  case (#atomic) { #atomic };
                  case (#buy_now(e)) { #buy_now(e) };
                  case (#wait_for_quiet(e)) { #wait_for_quiet(e) };
                  case (#allow_list(e)) { #allow_list(e) };
                  case (#notify(e)) { #notify(e) };
                  case (#reserve(e)) { #reserve(e) };
                  case (#start_date(e)) { #start_date(e) };
                  case (#start_price(e)) { #start_price(e) };
                  case (#min_increase(e)) { #min_increase(e) };
                  case (#ending(e)) { #ending(e) };
                  case (#token(e)) { #token(e) };
                  case (#dutch(e)) { #dutch(e) };
                  case (#kyc(e)) { #kyc(e) };
                  case (#nifty_settlement(e)) { #nifty_settlement(e) };
                };
                buffer.add(updatedValue);
              };

              #ask(?Buffer.toArray(buffer));
            };
            case (null) {
              #ask(null);
            };
          };
        };
      };
    };

    let stable_buffer_v1_5_to_v1_6 = func(key : Text, v1 : SB_lib.StableBuffer<v0_1_5.TransactionRecord>) : SB_lib.StableBuffer<v0_1_6.TransactionRecord> {
      let buffer = SB_lib.initPresized<v0_1_6.TransactionRecord>(SB_lib.size(v1));

      for (thisItem in SB_lib.vals<v0_1_5.TransactionRecord>(v1)) {
        SB_lib.add<v0_1_6.TransactionRecord>(
          buffer,
          {
            token_id = thisItem.token_id;
            index = thisItem.index;
            timestamp = thisItem.timestamp;
            txn_type = switch (thisItem.txn_type) {
              case (#auction_bid(e)) {
                #auction_bid(e);
              };
              case (#mint(e)) {
                #mint(e);
              };
              case (#sale_ended(e)) {
                #sale_ended(e);
              };
              case (#royalty_paid(e)) {
                #royalty_paid(e);
              };
              case (#sale_opened(e)) {
                #sale_opened({
                  sale_id = e.sale_id;
                  extensible = e.extensible;
                  pricing = upgradePricingConfigShared(e.pricing);
                });
              };
              case (#owner_transfer(e)) {
                #owner_transfer(e);
              };
              case (#escrow_deposit(e)) {
                #escrow_deposit(e);
              };
              case (#escrow_withdraw(e)) {
                #escrow_withdraw(e);
              };
              case (#deposit_withdraw(e)) {
                #deposit_withdraw(e);
              };
              case (#sale_withdraw(e)) {
                #sale_withdraw(e);
              };
              case (#canister_owner_updated(e)) {
                #canister_owner_updated(e);
              };
              case (#canister_managers_updated(e)) {
                #canister_managers_updated(e);
              };
              case (#canister_network_updated(e)) {
                #canister_network_updated(e);
              };
              case (#data(e)) {
                #data(e);
              };
              case (#burn(e)) {
                #burn(e);
              };
              case (#extensible(e)) {
                #extensible(e);
              };
            };
          },
        );
      };
      return buffer;
    };

    //icrc3
    var icrc3_migration_state = ICRC3.init(
      ICRC3.initialState(),
      #v0_1_0(#id),
      v0_1_6.defaultICRC3Config(caller),
      caller,
    );

    let cert_store : CertTree.Store = CertTree.newStore();

    D.print("in upgrading ledgers");
    let new_ledgers = Map_lib.map<Text, SB_lib.StableBuffer<v0_1_5.TransactionRecord>, SB_lib.StableBuffer<v0_1_6.TransactionRecord>>(
      state.nft_ledgers,
      stable_buffer_v1_5_to_v1_6,
    );
    D.print("in upgrading new_master_ledger");

    let new_master_ledger : SB_lib.StableBuffer<v0_1_6.TransactionRecord> = stable_buffer_v1_5_to_v1_6("", state.master_ledger);

    D.print("update done");

    // init timer tool
    let timerTool = TimerTool.init(TimerTool.initialState(), #v0_1_0(#id), null, caller);

    return #v0_1_6(
      #data({
        var collection_data = state.collection_data;
        var buckets = state.buckets;
        var allocations = state.allocations;
        var canister_availible_space = state.canister_availible_space;
        var canister_allocated_storage = state.canister_allocated_storage;
        var offers = state.offers;
        var nft_metadata = state.nft_metadata;
        var escrow_balances = state.escrow_balances;
        var sales_balances = state.sales_balances;
        var fee_deposit_balances = Map.new<v0_1_6.Account, Map.Map<v0_1_6.TokenSpec, v0_1_6.FeeDepositDetail>>();
        var nft_ledgers = new_ledgers;
        var master_ledger = new_master_ledger;
        var nft_sales = new_sales;
        var access_tokens = state.access_tokens;
        var kyc_cache = state.kyc_cache;
        var droute = state.droute;
        var use_stableBTree = state.use_stableBTree;
        var pending_sale_notifications = state.pending_sale_notifications;
        var icrc3_migration_state = icrc3_migration_state;
        var cert_store = cert_store;
        var timerState = ?timerTool;
        /* add certification ref here */
      })
    );
  };

  public func downgrade(migration_state : MigrationTypes.State, args : MigrationTypes.Args, caller : Principal) : MigrationTypes.State {
    return #v0_0_0(#data);
  };

};
