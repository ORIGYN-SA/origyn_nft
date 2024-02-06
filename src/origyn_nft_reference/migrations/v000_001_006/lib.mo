import D "mo:base/Debug"; 
import Deque "mo:base/Deque";

import CandyTypes = "mo:candy/types";

import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 


import MigrationTypes "../types";
import v0_1_5 "../v000_001_005/types";
import v0_1_6 = "types";

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
    switch(x){
      case(?val){
        let resultMap = Map.new<v0_1_6.AskFeatureKey, v0_1_6.AskFeature>();
        for(thisItem in Map.vals(val)){
          switch(thisItem){
            case(#reserve(val)){
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #reserve, #reserve(val));
            };
            case(#token(val)){
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #token, #token(val));
            };
            case(#buy_now(val)){
             ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #buy_now, #buy_now(val));
            };
            case(#start_price(val)){
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #start_price, #start_price(val));
            };
            case(#start_date(val)){
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #start_date, #start_date(val));
            };
            case(#ending(val)){
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #ending, #ending(val));
            };
            case(#min_increase(val)){
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #min_increase, #min_increase(val));
            };
            case(#allow_list(val)){
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #allow_list, #allow_list(val));
            };
            case(#atomic(val)){
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #atomic, #atomic(val));
            };
            case(#dutch(val)){
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #dutch, #dutch(val));
            };
            case(#kyc(val)){
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #kyc, #kyc(val));
            };
            case(#nifty_settlement(val)){
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #nifty_settlement, #nifty_settlement(val));
            };
            case(#notify(val)){
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #notify, #notify(val));
            };
            case(#wait_for_quiet(val)){
              ignore Map.put(resultMap, v0_1_6.ask_feature_set_tool, #wait_for_quiet, #wait_for_quiet(val));
            };
            
          };
        };
        return ?resultMap;
      };
      case(_)return null;
    };
  };

  let upgradeSaleStatus = func(key: Text, x : v0_1_5.SaleStatus) : ?v0_1_6.SaleStatus{
      let z : v0_1_6.AuctionState = switch(x.sale_type){
        case(#auction(val)){
          let config = switch(val.config){
            case(#auction(x)){
              #auction(upgradeAuctionConfig(x));
            };
            case(#ask(x)){
              #ask(upgradeAskConfig(x));
            };
            case(_){
              return null;
            };
          };
          
          
          {
            config = config;
            var current_bid_amount = val.current_bid_amount;
            var current_broker_id = val.current_broker_id;
            var end_date = val.end_date;
            var start_date = val.start_date;
            token = val.token;
            var min_next_bid = val.min_next_bid;
            var current_escrow = val.current_escrow;
            var wait_for_quiet_count = val.wait_for_quiet_count;
            allow_list = val.allow_list;
            var participants = val.participants;
            var status = val.status;
            var winner = val.winner;
            var notify_queue = ?(Deque.empty<(Principal, ?MigrationTypes.Current.SubscriptionID)>())
          };
        };
        case(_){
          return null
        };
      };

      ?{
        x with
        sale_type = #auction(z);
      };
   };

  public func upgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {

   let state = switch (prev_migration_state) { case (#v0_1_5(#data(state))) state; case (_) D.trap("Unexpected migration state") };
   
    D.print("did init work?");

    

    let new_sales : Map.Map<Text, v0_1_6.SaleStatus> = Map.mapFilter<Text, v0_1_5.SaleStatus, v0_1_6.SaleStatus>(state.nft_sales, upgradeSaleStatus
    );

    //init certification here

    return #v0_1_6(#data({
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
      var master_ledger = state.master_ledger;
      var nft_sales = new_sales;
      var access_tokens = state.access_tokens;
      var kyc_cache = state.kyc_cache;
      var droute = state.droute;
      var use_stableBTree = state.use_stableBTree;
      var pending_sale_notifications = state.pending_sale_notifications;
      //add certification ref here
    }));
};
  
public func downgrade(migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
  return #v0_0_0(#data);
};

  
};