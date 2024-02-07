import D "mo:base/Debug"; 
import Deque "mo:base/Deque";

import CandyTypes = "mo:candy/types";

import Map_lib "mo:map_7_0_0/Map";
import Set_lib "mo:map_7_0_0/Set";
import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 


import MigrationTypes "../types";
import v0_1_4 "../v000_001_004/types";
import v0_1_5 = "types";

module {

  let { ihash; nhash; thash; phash; calcHash } = Map_lib;

  public func upgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {

   let state = switch (prev_migration_state) { case (#v0_1_4(#data(state))) state; case (_) D.trap("Unexpected migration state") };

  let upgradeAuctionConfig = func(x : v0_1_4.PricingConfig) : v0_1_5.AuctionConfig {
    switch(x){
      case(#auction(x)){
        {
          reserve = x.reserve;
          token = x.token;
          buy_now = x.buy_now;
          start_price = x.start_price;
          start_date = x.start_date;
          ending = switch(x.ending){
              case(#date(val)) #date(val);
              case(#waitForQuiet(val)) #wait_for_quiet({
                  val with
                  extension = val.extention;
                }
              );
          };
          min_increase = x.min_increase;
          allow_list = x.allow_list;
        };
      };
    };
  };

   let upgradePricingConfig = func(x : v0_1_4.PricingConfig) : v0_1_5.PricingConfig {
      switch(x){
        case(#instant){#instant};
        case(#flat(e)){
          let features : [v0_1_5.AskFeature] = [
            #start_price(e.amount),
            #buy_now(e.amount),
            #token(e.token),
          ];

          #ask(?(v0_1_5.features_to_map(features)));
        };
        case(#dutch(e)){
          let features : [v0_1_5.AskFeature] = [
            #start_price(e.start_price),
            #dutch({
              time_unit = #hour(1);
              decay_type = e.decay_per_hour;
            }),
            #reserve(switch(e.reserve){
              case(null) 0;
              case(?val) val;
            }),
            #token(e.token),
          ];

          #ask(?(v0_1_5.features_to_map(features)));
        };
        case(#auction(e)){
           #auction({
            reserve = e.reserve;
            token = e.token;
            buy_now = e.buy_now;
            start_price = e.start_price;
            start_date = e.start_date;
            ending = switch(e.ending){
                case(#date(val)) #date(val);
                case(#waitForQuiet(val)) #wait_for_quiet({
                  val with 
                  extension = val.extention
            });
            };
            min_increase = e.min_increase;
            allow_list = e.allow_list;
        })};
        case(#extensible(e)){
          #extensible(e);
        };
        case(#nifty(e)){
          let features : [v0_1_5.AskFeature] = [
            #start_price(e.amount),
            #buy_now(e.amount),
            #nifty_settlement({
              duration = e.duration;
              expiration = e.expiration;
              fixed = e.fixed;
              lenderOffer = e.lenderOffer;
              interestRatePerSecond = e.interestRatePerSecond;
            }),
            #token(e.token),
          ];

          #ask(?(v0_1_5.features_to_map(features)));
        };
      };
   };

   let upgradePricingConfigShared = func(x : v0_1_4.PricingConfig) : v0_1_5.PricingConfigShared {
      switch(x){
        case(#instant){#instant};
        case(#flat(e)){
          let features : [v0_1_5.AskFeature] = [
            #start_price(e.amount),
            #buy_now(e.amount),
            #token(e.token),
          ];

          #ask(?(features));
        };
        case(#dutch(e)){
          let features : [v0_1_5.AskFeature] = [
            #start_price(e.start_price),
            #dutch({
              time_unit = #hour(1);
              decay_type = e.decay_per_hour;
            }),
            #reserve(switch(e.reserve){
              case(null) 0;
              case(?val) val;
            }),
            #token(e.token),
          ];

          #ask(?(features));
        };
        case(#auction(e)){
          #auction({
            reserve = e.reserve;
            token = e.token;
            buy_now = e.buy_now;
            start_price = e.start_price;
            start_date = e.start_date;
            ending = switch(e.ending){
                case(#date(val)) #date(val);
                case(#waitForQuiet(val)) #wait_for_quiet({
                  val with
                  extension = val.extention;
                });
            };
            min_increase = e.min_increase;
            allow_list = e.allow_list;
        })};
        case(#extensible(e)){
          #extensible(e);
        };
        case(#nifty(e)){
          let features : [v0_1_5.AskFeature] = [
            #start_price(e.amount),
            #buy_now(e.amount),
            #nifty_settlement({
              duration = e.duration;
              expiration = e.expiration;
              fixed = e.fixed;
              lenderOffer = e.lenderOffer;
              interestRatePerSecond = e.interestRatePerSecond;
            }),
            #token(e.token),
          ];

          #ask(?(features));
        };
      };
   };

   let upgradeSaleStatus = func(key: Text, x : v0_1_4.SaleStatus) : ?v0_1_5.SaleStatus{
      let z : v0_1_5.AuctionState = switch(x.sale_type){
        case(#auction(val)){
          let config = upgradeAuctionConfig(val.config);
         {

            config = #auction(config);
            var current_bid_amount = val.current_bid_amount;
            var current_broker_id = val.current_broker_id;
            var end_date = val.end_date;
            var start_date = config.start_date;
            token = config.token;
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

    D.print("in upgrade v0.1.4");

    //initialize stable memory



     D.print("in upgrading escrows");

    

    D.print("in upgrading ledgers");
    let new_ledgers = Map_lib.map<
      Text, 
      SB_lib.StableBuffer<v0_1_4.TransactionRecord>, 
      SB_lib.StableBuffer<v0_1_5.TransactionRecord>>(
      state.nft_ledgers, 
      func (key: Text, v1 : SB_lib.StableBuffer<v0_1_4.TransactionRecord>) : SB_lib.StableBuffer<v0_1_5.TransactionRecord>{
        let buffer = SB_lib.initPresized<v0_1_5.TransactionRecord>(SB_lib.size(v1));
        
        for(thisItem in SB_lib.vals<v0_1_4.TransactionRecord>(v1)){
          SB_lib.add<v0_1_5.TransactionRecord>(buffer, {
            token_id = thisItem.token_id;
            index = thisItem.index;
            timestamp = thisItem.timestamp;
              txn_type = switch(thisItem.txn_type){
                case(#auction_bid(e)){
                  #auction_bid(e);
                };
                case(#mint(e)){
                  #mint(e);
                };
                case(#sale_ended(e)){
                  #sale_ended(e);
                };
                case(#royalty_paid(e)){
                  #royalty_paid(e);
                };
                case(#sale_opened(e)){
                  #sale_opened({
                    sale_id = e.sale_id;
                    extensible = e.extensible;
                    pricing = upgradePricingConfigShared(e.pricing);
                  });
                };
                case(#owner_transfer(e)){
                  #owner_transfer(e);
                };
                case(#escrow_deposit(e)){
                  #escrow_deposit(e);
                };
                case(#escrow_withdraw(e)){
                  #escrow_withdraw(e);
                };
                case(#deposit_withdraw(e)){
                  #deposit_withdraw(e);
                };
                case(#sale_withdraw(e)){
                  #sale_withdraw(e);
                };
                case(#canister_owner_updated(e)){
                  #canister_owner_updated(e);
                };
                case(#canister_managers_updated(e)){
                  #canister_managers_updated(e);
                };
                case(#canister_network_updated(e)){
                  #canister_network_updated(e);
                };
                case(#data(e)){
                  #data(e);
                };
                case(#burn(e)){
                  #burn(e);
                };
                case(#extensible(e)){
                  #extensible(e);
                };
              };
          });
        };

        return buffer;
      });

    D.print("in upgrading sale staus");
    
    let new_sales : Map_lib.Map<Text, v0_1_5.SaleStatus> = Map_lib.mapFilter<Text, v0_1_4.SaleStatus, v0_1_5.SaleStatus>(state.nft_sales, upgradeSaleStatus
    );

    //assure ordered transactions

   
    D.print("did init work?");

    return #v0_1_5(#data({
      var collection_data = state.collection_data;
      var buckets = state.buckets;
      var allocations = state.allocations;
      var canister_availible_space = state.canister_availible_space;
      var canister_allocated_storage = state.canister_allocated_storage;
      var offers = state.offers;
      var nft_metadata = state.nft_metadata;
      var escrow_balances = state.escrow_balances;
      var sales_balances = state.sales_balances;
      var nft_ledgers = new_ledgers;
      var master_ledger = SB_lib.init<v0_1_5.TransactionRecord>();
      var nft_sales = new_sales;
      var access_tokens = state.access_tokens;
      var kyc_cache = state.kyc_cache;
      var droute = state.droute;
      var use_stableBTree = state.use_stableBTree;
      var pending_sale_notifications = Set_lib.new<Text>();
    }));
};
  
public func downgrade(migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
  return #v0_0_0(#data);
};

};