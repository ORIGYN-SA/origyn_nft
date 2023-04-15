import MigrationTypes "../types";
import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 
import Map_lib "mo:map_7_0_0/Map";
import CandyTypes_old "mo:candy_0_1_12/types"; 
import CandyTypes "mo:candy_0_2_0/types"; 
import CandyUpgrade "mo:candy_0_2_0/upgrade"; 
import D "mo:base/Debug"; 
import v0_1_3 "../v000_001_003/types";
import v0_1_4 = "types";
import KYCTypes = "mo:icrc17_kyc/types";
import Droute "mo:droute_client/Droute";
import Principal "mo:base/Principal";
import StableBTree "mo:stableBTree/btreemap";
import BytesConverter "mo:stableBTree/bytesConverter";
import MemoryManager "mo:stableBTree/memoryManager";
import Memory "mo:stableBTree/memory";


module {

  let { ihash; nhash; thash; phash; calcHash } = Map_lib;

  public func upgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {

    let state = switch (prev_migration_state) { case (#v0_1_3(#data(state))) state; case (_) D.trap("Unexpected migration state") };

   let upgradeTokenSpec = func(x :v0_1_3.TokenSpec) : v0_1_4.TokenSpec{
      switch(x){
        case(#ic(ic)){
          #ic(
            {
              ic with
              fee = ?ic.fee;
              standard = ic.standard;
              id = null
          });
        };
        case(#extensible(e)){
          #extensible(CandyUpgrade.upgradeCandyShared(e));
        };
      };
   };

   let upgradeAccount = func(x :v0_1_3.Account) : v0_1_4.Account{
      switch(x){
        case(#principal(x)) #principal(x);
        case(#account(x)) #account(x);
        case(#account_id(x)) #account_id(x);
        case(#extensible(e)){
          #extensible(CandyUpgrade.upgradeCandyShared(e));
        };
      };
   };

   let upgradePricingConfig = func(x :v0_1_3.PricingConfig) : v0_1_4.PricingConfig{
      switch(x){
        case(#instant){#instant};
        case(#flat(e)){
          #flat({e with
          token = upgradeTokenSpec(e.token)})
        };
        case(#dutch(e)){
          #dutch({e with
            decay_per_hour = #percent(e.decay_per_hour);
            start_date = 0;
            allow_list = null;
            token = #extensible(#Option(null));
          });
        };
        case(#auction(e)){
          #auction({e with
            token = upgradeTokenSpec(e.token);
          });
        };
        case(#extensible(e)){
          #extensible(#Option(null));
        };
      };
   };

   let upgradeEscrow = func(x :v0_1_3.EscrowReceipt) : v0_1_4.EscrowReceipt{
      {
        x
        with
        buyer = upgradeAccount(x.buyer);
        seller = upgradeAccount(x.seller);
        token = upgradeTokenSpec(x.token)
      }
   };

   let upgradeSaleStatus = func(x : v0_1_3.SaleStatus) : v0_1_4.SaleStatus{

      let z : v0_1_4.AuctionState = switch(x.sale_type){
        case(#auction(val)){
         {
            config = upgradePricingConfig(val.config);
            var current_bid_amount = val.current_bid_amount;
            var current_broker_id = val.current_broker_id;
            var end_date = val.end_date;
            var min_next_bid = val.min_next_bid;
            var current_escrow = switch(val.current_escrow){
              case(null) null;
              case(?e) {?upgradeEscrow(e)};
            };
            var wait_for_quiet_count = val.wait_for_quiet_count;
            var allow_list = val.allow_list;
            var participants = val.participants;
            var status = val.status;
            var winner = switch(val.winner){
              case(null) null;
              case(?e) ?upgradeAccount(e);
            };
          };
        }
      };

      {
        x with
        sale_type = #auction(z);
      };
   };

   

    let droute_client = Droute.new(?{
      mainId = null;
      publishersIndexId= null;
      subscribersIndexId= null;
    });

    let collection_data : v0_1_4.CollectionData  = {
      var logo = state.collection_data.logo;
      var name = state.collection_data.name;
      var symbol = state.collection_data.symbol;
      var metadata = switch(state.collection_data.metadata){
        case(null) null;
        case(?val){?CandyUpgrade.upgradeCandyShared(val)};
      };
      var owner  = state.collection_data.owner;
      var managers = state.collection_data.managers;
      var network = state.collection_data.network;
      var allocated_storage = state.collection_data.allocated_storage;
      var available_space  = state.collection_data.available_space;
      var active_bucket = state.collection_data.active_bucket;
      var announce_canister = null;
    };

   

    D.print("in upgrade v0.1.4");

    //initialize stable memory

    let escrows = Map_lib.new<v0_1_4.Account, 
                                    Map_lib.Map<v0_1_4.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_4.TokenSpec,v0_1_4.EscrowRecord>>>>();

    for(thisFrom in Map_lib.entries(state.escrow_balances)){
      let to = Map_lib.new<v0_1_4.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map< v0_1_4.TokenSpec, v0_1_4.EscrowRecord>>>();
      for(thisTo in Map_lib.entries(thisFrom.1)){
        let tokens = Map_lib.new<Text,
                                            Map_lib.Map<v0_1_4.TokenSpec, v0_1_4.EscrowRecord>>();
        for(thisToken in Map_lib.entries(thisTo.1)){

          

          let ledgers = Map_lib.new<v0_1_4.TokenSpec, v0_1_4.EscrowRecord>();

          for(thisLedger in Map_lib.entries(thisToken.1)){
            
              let newSpec = upgradeTokenSpec(thisLedger.0);

            ignore Map_lib.put<v0_1_4.TokenSpec, v0_1_4.EscrowRecord>(ledgers, v0_1_4.token_handler, newSpec, 
            {
              thisLedger.1 with
              buyer = upgradeAccount(thisLedger.1.buyer);
              seller = upgradeAccount(thisLedger.1.seller);
              token = newSpec;
            } );                    
          };
          
          ignore Map_lib.put<Text,
            Map_lib.Map<v0_1_4.TokenSpec, v0_1_4.EscrowRecord>>(tokens, thash, thisToken.0, ledgers);
        };

        ignore Map_lib.put<v0_1_4.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_4.TokenSpec,v0_1_4.EscrowRecord>>>(to, v0_1_4.account_handler, upgradeAccount(thisTo.0), tokens);
      };
      ignore Map_lib.put<v0_1_4.Account, 
                                    Map_lib.Map<v0_1_4.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_4.TokenSpec,v0_1_4.EscrowRecord>>>>(escrows, v0_1_4.account_handler, upgradeAccount(thisFrom.0), to);
    };


    let sales = Map_lib.new<v0_1_4.Account, 
                                    Map_lib.Map<v0_1_4.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_4.TokenSpec,v0_1_4.EscrowRecord>>>>();

    for(thisTo in Map_lib.entries(state.escrow_balances)){
      let from = Map_lib.new<v0_1_4.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_4.TokenSpec, v0_1_4.EscrowRecord>>>();
      for(thisFrom in Map_lib.entries(thisTo.1)){
        let tokens = Map_lib.new<Text,
                                            Map_lib.Map<v0_1_4.TokenSpec,v0_1_4.EscrowRecord>>();
        for(thisToken in Map_lib.entries(thisFrom.1)){
          
          let ledgers = Map_lib.new<v0_1_4.TokenSpec, v0_1_4.EscrowRecord>();

          for(thisLedger in Map_lib.entries(thisToken.1)){
            
              let newSpec = upgradeTokenSpec(thisLedger.0);

            ignore Map_lib.put<v0_1_4.TokenSpec, v0_1_4.EscrowRecord>(ledgers, v0_1_4.token_handler, newSpec, 
            {
              thisLedger.1 with
              seller = upgradeAccount(thisLedger.1.seller);
              buyer = upgradeAccount(thisLedger.1.buyer);
              token = newSpec
            } );                    
          };
          
          ignore Map_lib.put<Text,
            Map_lib.Map<v0_1_4.TokenSpec, v0_1_4.EscrowRecord>>(tokens, thash, thisToken.0, ledgers);
        };

        ignore Map_lib.put<v0_1_4.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_4.TokenSpec,v0_1_4.EscrowRecord>>>(from, v0_1_4.account_handler, upgradeAccount(thisFrom.0), tokens);
      };
      ignore Map_lib.put<v0_1_4.Account, 
                                    Map_lib.Map<v0_1_4.Account,
                                        Map_lib.Map<Text,
                                            Map_lib.Map<v0_1_4.TokenSpec,v0_1_4.EscrowRecord>>>>(sales, v0_1_4.account_handler, upgradeAccount(thisTo.0), from);
    };

    let new_ledgers = Map_lib.map<
      Text, 
      SB_lib.StableBuffer<v0_1_3.TransactionRecord>, 
      SB_lib.StableBuffer<v0_1_4.TransactionRecord>>(
      state.nft_ledgers, 
      func (key: Text, v1 : SB_lib.StableBuffer<v0_1_3.TransactionRecord>) : SB_lib.StableBuffer<v0_1_4.TransactionRecord>{
        let buffer = SB_lib.initPresized<v0_1_4.TransactionRecord>(SB_lib.size(v1));
        
        for(thisItem in SB_lib.vals<v0_1_3.TransactionRecord>(v1)){
          SB_lib.add<v0_1_4.TransactionRecord>(buffer, {
            thisItem with
              txn_type = switch(thisItem.txn_type){
                case(#auction_bid(e)){
                  #auction_bid({e with
                    buyer = upgradeAccount(e.buyer);
                    token = upgradeTokenSpec(e.token);
                    extensible = CandyUpgrade.upgradeCandyShared(e.extensible)
                  });
                };
                case(#mint(e)){
                  #mint({
                    e with
                    from = upgradeAccount(e.from);
                    to = upgradeAccount(e.to);
                    sale =  switch(e.sale){
                      case(null) null;
                      case(?val) {
                        ?{
                          val with
                          token = upgradeTokenSpec(val.token);
                        };
                      };
                    };
                    extensible = CandyUpgrade.upgradeCandyShared(e.extensible)
                  });
                };
                case(#sale_ended(e)){
                  #sale_ended({
                    e with
                    seller = upgradeAccount(e.seller);
                    buyer = upgradeAccount(e.buyer);
                    token = upgradeTokenSpec(e.token);
                    extensible = CandyUpgrade.upgradeCandyShared(e.extensible)
                  });
                };
                case(#royalty_paid(e)){
                  #royalty_paid({
                    e with
                    seller = upgradeAccount(e.seller);
                    buyer = upgradeAccount(e.buyer);
                    receiver = upgradeAccount(e.reciever);
                    token = upgradeTokenSpec(e.token);
                    extensible = CandyUpgrade.upgradeCandyShared(e.extensible)
                  });
                };
                case(#sale_opened(e)){
                  #sale_opened({
                    e with
                    pricing = upgradePricingConfig(e.pricing);
                    extensible = CandyUpgrade.upgradeCandyShared(e.extensible)
                  });
                };
                case(#owner_transfer(e)){
                  #owner_transfer({
                    e with
                    from = upgradeAccount(e.from);
                    to = upgradeAccount(e.to);
                    extensible = CandyUpgrade.upgradeCandyShared(e.extensible)
                  });
                };
                case(#escrow_deposit(e)){
                  #escrow_deposit({
                    e with
                    trx_id = switch(e.trx_id){
                      case(#nat(val)) #nat(val);
                      case(#text(val)) #text(val);
                      case(#extensible(val)) #extensible(CandyUpgrade.upgradeCandyShared(val));
                    };
                    seller = upgradeAccount(e.seller);
                    buyer = upgradeAccount(e.buyer);
                    token = upgradeTokenSpec(e.token);
                    extensible = CandyUpgrade.upgradeCandyShared(e.extensible)
                  });
                };
                case(#escrow_withdraw(e)){
                  #escrow_withdraw({
                    e with
                    trx_id = switch(e.trx_id){
                      case(#nat(val)) #nat(val);
                      case(#text(val)) #text(val);
                      case(#extensible(val)) #extensible(CandyUpgrade.upgradeCandyShared(val));
                    };
                    seller = upgradeAccount(e.seller);
                    buyer = upgradeAccount(e.buyer);
                    token = upgradeTokenSpec(e.token);
                    extensible = CandyUpgrade.upgradeCandyShared(e.extensible)
                  });
                };
                case(#deposit_withdraw(e)){
                  #deposit_withdraw({
                    e with
                    trx_id = switch(e.trx_id){
                      case(#nat(val)) #nat(val);
                      case(#text(val)) #text(val);
                      case(#extensible(val)) #extensible(CandyUpgrade.upgradeCandyShared(val));
                    };
                    buyer = upgradeAccount(e.buyer);
                    token = upgradeTokenSpec(e.token);
                    extensible = CandyUpgrade.upgradeCandyShared(e.extensible)
                  });
                };
                case(#sale_withdraw(e)){
                  #sale_withdraw({
                    e with
                    trx_id = switch(e.trx_id){
                      case(#nat(val)) #nat(val);
                      case(#text(val)) #text(val);
                      case(#extensible(val)) #extensible(CandyUpgrade.upgradeCandyShared(val));
                    };
                    seller = upgradeAccount(e.seller);
                    buyer = upgradeAccount(e.buyer);
                    token = upgradeTokenSpec(e.token);
                    extensible = CandyUpgrade.upgradeCandyShared(e.extensible)
                  });
                  
                };
                case(#canister_owner_updated(e)){
                  #canister_owner_updated({
                    e with
                    extensible = CandyUpgrade.upgradeCandyShared(e.extensible)
                  });
                };
                case(#canister_managers_updated(e)){
                  #canister_managers_updated({
                    e with
                    extensible = CandyUpgrade.upgradeCandyShared(e.extensible)
                  });
                };
                case(#canister_network_updated(e)){
                  #canister_network_updated({
                    e with
                    extensible = CandyUpgrade.upgradeCandyShared(e.extensible)
                  });
                };
                case(#data){
                  #data({
                    data_dapp = null;
                    data_path = null;
                    hash = null;
                    extensible = #Option(null);
                  });
                };
                case(#burn){
                  #burn({
                    from = null;
                    extensible = #Option(null);
                  });
                };
                case(#extensible(e)){
                  #extensible(CandyUpgrade.upgradeCandyShared(e));
                };
              };
          });
        };

        return buffer;
      });

    let new_sales : Map_lib.Map<Text, v0_1_4.SaleStatus> = Map_lib.map<Text, v0_1_3.SaleStatus, v0_1_4.SaleStatus>(state.nft_sales, func(k : Text, V1 : v0_1_3.SaleStatus) : v0_1_4.SaleStatus {
        upgradeSaleStatus(V1);
    });

    let new_offers = Map_lib.new<v0_1_4.Account, Map_lib.Map<v0_1_4.Account, Int>>();

    for(thisItem in Map_lib.entries(state.offers)){
      let new_list = Map_lib.new<v0_1_4.Account, Int>();
      for(thisDetail in Map_lib.entries(thisItem.1)){
        ignore Map_lib.put<v0_1_4.Account, Int>(new_list, v0_1_4.account_handler, upgradeAccount(thisDetail.0), thisDetail.1);
      };
      ignore Map_lib.put<v0_1_4.Account, Map_lib.Map<v0_1_4.Account, Int>>(new_offers, v0_1_4.account_handler, upgradeAccount(thisItem.0), new_list);
    };

   
    D.print("did init work?");

    return #v0_1_4(#data({
      var collection_data = collection_data;
      var buckets = state.buckets;
      var allocations = state.allocations;
      var canister_availible_space = state.canister_availible_space;
      var canister_allocated_storage = state.canister_allocated_storage;
      var offers = new_offers;
      var nft_metadata = Map_lib.map<Text, CandyTypes_old.CandyValue, CandyTypes.CandyShared>(state.nft_metadata, func(k : Text, V1 : CandyTypes_old.CandyValue) : CandyTypes.CandyShared{
        CandyUpgrade.upgradeCandyShared(V1);
      });
      var escrow_balances = escrows;
      var sales_balances = sales;
      var nft_ledgers = new_ledgers;
      var nft_sales = new_sales;
      var access_tokens = state.access_tokens;
      var kyc_cache = Map_lib.new<KYCTypes.KYCRequest, KYCTypes.KYCResultFuture>();
      var droute = droute_client;
      var use_stableBTree = false;
     

   }));
  };

   public func downgrade(migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    return #v0_0_0(#data);
  };

  
};