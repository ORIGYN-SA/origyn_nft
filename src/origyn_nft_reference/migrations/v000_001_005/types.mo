import CandyTypes_lib "mo:candy_0_2_0/types"; 
import Conversion_lib "mo:candy_0_2_0/conversion";
import CandyJson "mo:candy_0_2_0/json";
import CandyProperties "mo:candy_0_2_0/properties";
import CandyWorkspace "mo:candy_0_2_0/workspace";
import v0_1_4 "../v000_001_004/types";
import AccountIdentifier "mo:principalmo/AccountIdentifier";
import Blob "mo:base/Blob";
import Prim "mo:prim";


import D "mo:base/Debug";

import Order "mo:base/Order";
import Text "mo:base/Text";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import MapUtils "mo:map_7_0_0/utils";

import hex "mo:encoding/Hex";


import Droute "mo:droute_client/Droute";

import KYCTypes "mo:icrc17_kyc/types";
import KYCClass "mo:icrc17_kyc";
import Map_8_1_0 "mo:map_8_1_0/Map";
import Set_8_1_0 "mo:map_8_1_0/Set";
import MapUtils_8_1_0 "mo:map_8_1_0/utils";

// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead


module {
  
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  

  public let SB = v0_1_4.SB;
  public let Map = v0_1_4.Map;
  public let CandyTypes = CandyTypes_lib;
  public let Conversions = Conversion_lib;
  public let Properties = CandyProperties;
  public let JSON = CandyJson;
  public let Workspace = CandyWorkspace;

  public type CollectionData = {
        var logo: ?Text;
        var name: ?Text;
        var symbol: ?Text;
        var metadata: ?CandyTypes.CandyShared;
        var owner : Principal;
        var managers: [Principal];
        var network: ?Principal;
        var allocated_storage: Nat;
        var available_space : Nat;
        var active_bucket: ?Principal;
        var announce_canister : ?Principal;
    };

  public type AllocationRecord = v0_1_4.AllocationRecord;
  public type BucketData = v0_1_4.BucketData;

  

  public type TransactionRecord = {
        token_id: Text;
        index: Nat;
        txn_type: {
            #auction_bid : {
                buyer: Account;
                amount: Nat;
                token: TokenSpec;
                sale_id: Text;
                extensible: CandyTypes.CandyShared;
            };
            #mint : {
                from: Account;
                to: Account;
                //nyi: metadata hash
                sale: ?{token: TokenSpec;
                    amount: Nat; //Nat to support cycles
                    };
                extensible: CandyTypes.CandyShared;
            };
            #sale_ended : {
                seller: Account;
                buyer: Account;
               
                token: TokenSpec;
                sale_id: ?Text;
                amount: Nat;//Nat to support cycles
                extensible: CandyTypes.CandyShared;
            };
            #royalty_paid : {
                seller: Account;
                buyer: Account;
                receiver: Account;
                tag: Text;
                token: TokenSpec;
                sale_id: ?Text;
                amount: Nat;//Nat to support cycles
                extensible: CandyTypes.CandyShared;
            };
            #sale_opened : {
                pricing: PricingConfigShared;
                sale_id: Text;
                extensible: CandyTypes.CandyShared;
            };
            #owner_transfer : {
                from: Account;
                to: Account;
                extensible: CandyTypes.CandyShared;
            }; 
            #escrow_deposit : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat;//Nat to support cycles
                trx_id: TransactionID;
                extensible: CandyTypes.CandyShared;
            };
            #escrow_withdraw : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat;//Nat to support cycles
                fee: Nat;
                trx_id: TransactionID;
                extensible: CandyTypes.CandyShared;
            };
            #deposit_withdraw : {
                buyer: Account;
                token: TokenSpec;
                amount: Nat;//Nat to support cycles
                fee: Nat;
                trx_id: TransactionID;
                extensible: CandyTypes.CandyShared;
            };
            #sale_withdraw : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat; //Nat to support cycles
                fee: Nat;
                trx_id: TransactionID;
                extensible: CandyTypes.CandyShared;
            };
            #canister_owner_updated : {
                owner: Principal;
                extensible: CandyTypes.CandyShared;
            };
            #canister_managers_updated : {
                managers: [Principal];
                extensible: CandyTypes.CandyShared;
            };
            #canister_network_updated : {
                network: Principal;
                extensible: CandyTypes.CandyShared;
            };
            #data : {
              data_dapp: ?Text;
              data_path: ?Text;
              hash: ?[Nat8];
              extensible: CandyTypes.CandyShared;
            }; //nyi
            #burn: {
              from: ?Account;
              extensible: CandyTypes.CandyShared;
            };
            #extensible : CandyTypes.CandyShared;

        };
        timestamp: Int;
    };

  

  public type EscrowReceipt = {
    amount: Nat; //Nat to support cycles
    seller: Account;
    buyer: Account;
    token_id: Text;
    token: TokenSpec;
  };

  public type SaleStatus = {
      sale_id: Text; //sha256?;
      original_broker_id: ?Principal;
      broker_id: ?Principal;
      token_id: Text;
      sale_type: {
          #auction: AuctionState;
      };
  };

  public type HttpAccess= v0_1_4.HttpAccess;

  public type Account = {
      #principal : Principal;
      #account : {owner: Principal; sub_account: ?Blob};
      #account_id : Text;
      #extensible : CandyTypes.CandyShared;
  };

  public type TransactionID = {
        #nat : Nat;
        #text : Text;
        #extensible : CandyTypes.CandyShared
    };

  public type AuctionConfig = {
            reserve: ?Nat;
            token: TokenSpec;
            buy_now: ?Nat;
            start_price: Nat;
            start_date: Int;
            ending: {
                #date: Int;
                #wait_for_quiet: {
                    date: Int;
                    extension: Nat64;
                    fade: Float;
                    max: Nat
                };
            };
            min_increase: {
                #percentage: Float;
                #amount: Nat;
            };
            allow_list : ?[Principal];
        };

  public type AskFeatureKey = {
      #atomic;
      #buy_now;
      #wait_for_quiet;
      #allow_list;
      #notify;
      #reserve;
      #start_date;
      #start_price;
      #min_increase;
      #ending;
      #token;
      #dutch;
      #kyc;
      #nifty_settlement;
    };

    public type DutchParams = {
        time_unit: {
          #hour : Nat;
          #minute : Nat;
          #day : Nat;
        };
        decay_type:{
          #flat: Nat;
          #percent: Float;
        };
    };

    public type AskFeature = {
      #atomic;
      #buy_now: Nat;
      #wait_for_quiet: {
          extension: Nat64;
          fade: Float;
          max: Nat
      };
      #allow_list : [Principal];
      #notify: [Principal];
      #reserve: Nat;
      #start_date: Int;
      #start_price: Nat;
      #min_increase: {
        #percentage: Float;
        #amount: Nat;
      };
      #ending: {
        #date: Int;
        #timeout: Nat;
      };
      #token: TokenSpec;
      #dutch: DutchParams;
      #kyc: Principal;
      #nifty_settlement: {
        duration: ?Int;
        expiration: ?Int;
        fixed: Bool;
        lenderOffer: Bool;
        interestRatePerSecond: Float;
      };
    };

  public type AskFeatureMap = Map_8_1_0.Map<AskFeatureKey, AskFeature>;

  public type AskConfig = ?AskFeatureMap;

  public type AskConfigShared = ?[AskFeature];

  public func ask_feature_set_eq (a: AskFeatureKey, b: AskFeatureKey) : Bool {

    switch(a,b){
      case(#atomic, #atomic){
        return true;
      };
      case(#buy_now, #buy_now){
        return true;
      };
      case(#wait_for_quiet, #wait_for_quiet){
        return true;
      };
      case(#allow_list, #allow_list){
        return true;
      };
      case(#notify, #notify){
        return true;
      };
      case(#reserve, #reserve){
        return true;
      };
      case(#start_date, #start_date){
        return true;
      };
      case(#start_price, #start_price){
        return true;
      };
      case(#min_increase, #min_increase){
        return true;
      };
      case(#ending, #ending){
        return true;
      };
      case(#token, #token){
        return true;
      };
      case(#dutch, #dutch){
        return true;
      };
      case(#kyc, #kyc){
        return true;
      };
      case(#nifty_settlement, #nifty_settlement){
        return true;
      };
      case(_,_) {
        return false;
      };
    };
  };

  public func ask_feature_set_hash (a: AskFeatureKey) : Nat32 {

    switch(a){
      case(#atomic){
        return 11311112;
      };
      case(#buy_now){
        return 222234453;
      };
      case(#wait_for_quiet){
        return 32223345;
      };
      case(#allow_list){
        return 444445324;
      };
      case(#notify){
        return 555554234;
      };
      case(#reserve){
        return 666323;
      };
      case(#start_date){
        return 74424533;
      };
      case(#start_price){
        return 84453456;
      };
      case(#min_increase){
        return 9345455;
      };
      case(#ending){
        return 1044345;
      };
      case(#token){
        return 112345466;
      };
      case(#dutch){
        return 1266844;
      };
      case(#kyc){
        return 13345466;
      };
      case(#nifty_settlement){
        return 14345667;
      };
    };
  };

  public func features_to_map(items: [AskFeature]) : Map_8_1_0.Map<AskFeatureKey, AskFeature>{
    let feature_set = Map_8_1_0.new<AskFeatureKey, AskFeature>(ask_feature_set_tool);

    for(thisItem in items.vals()){
      ignore Map_8_1_0.put<AskFeatureKey,AskFeature>(feature_set, ask_feature_set_tool, 
      feature_to_key(thisItem), thisItem);
    };

    return feature_set;
  };

  public func feature_to_key(request: AskFeature) : AskFeatureKey{

      switch(request){
        case(#atomic){
          return #atomic;
        };
        case(#buy_now(e)){
          return #buy_now;
        };
        case(#wait_for_quiet(e)){
          return #wait_for_quiet;
        };
        case(#allow_list(e)){
          return #allow_list;
        };
        case(#notify(e)){
          return #notify;
        };
        case(#reserve(e)){
          return #reserve;
        };
        case(#start_date(e)){
          return #start_date;
        };
        case(#start_price(e)){
          return #start_price;
        };
        case(#min_increase(e)){
          return #min_increase;
        };
        case(#ending(e)){
          return #ending;
        };
        case(#token(e)){
          return #token;
        };
        case(#dutch(e)){
          return #dutch;
        };
        case(#kyc(e)){
          return #kyc;
        };
        case(#nifty_settlement(e)){
          return #nifty_settlement;
        };
      };
  };

  public let ask_feature_set_tool = (ask_feature_set_hash, ask_feature_set_eq, func() = #atomic) : MapUtils_8_1_0.HashUtils<AskFeatureKey>;

  public type PricingConfig = {
      #instant; //executes an escrow recipt transfer -only available for non-marketable NFTs
      //below have not been signficantly desinged or vetted
      #auction: AuctionConfig; //depricated - use ask
      #ask: AskConfig;
      #extensible: CandyTypes.CandyShared;
  };

  public type PricingConfigShared = {
      #instant; //executes an escrow recipt transfer -only available for non-marketable NFTs
      //below have not been signficantly desinged or vetted
      #auction: AuctionConfig; //depricated - use ask
      #ask: AskConfigShared;
      #extensible: CandyTypes.CandyShared;
  };

  public func pricing_shared_to_pricing(request : PricingConfigShared) : PricingConfig {
    switch(request){
      case(#instant) #instant; //executes an escrow recipt transfer -only available for non-marketable NFTs
      //below have not been signficantly desinged or vetted
      case(#auction(val)) #auction(val); //depricated - use ask
      case(#ask(val)) {
        #ask(?features_to_map(switch(val){
          case(null) [];
          case(?val) val;
        }));
      };
      case(#extensible(e)) #extensible(e);
    };
  };

  public type AuctionState = {
    config: PricingConfig;
    var current_bid_amount: Nat;
    var current_broker_id: ?Principal;
    var end_date: Int;
    var start_date: Int;
    token : TokenSpec;
    var min_next_bid: Nat;
    var next_dutch_timer: ?(Nat, Int); //next price, date
    var current_escrow: ?EscrowReceipt;
    var wait_for_quiet_count: ?Nat;
    allow_list: ?Map.Map<Principal,Bool>; //empty set means everyone
    var participants: Map.Map<Principal,Int>;
    var status: {
        #open;
        #closed;
        #not_started;
    };
    notify_queue: ?Map_8_1_0.Map<Principal, ?SubscriptionID>;
    var winner: ?Account;
  };

  public type SubscriptionID = Nat;

  public type AskSubscriptionInfo = {
     filter: ?{
        token_ids: ?[TokenIDFilter]; 
        tokens: ?[TokenSpecFilter];
      };
     stake: (Principal, Nat, ?Nat);
  };

  public type AskSubscribeRequest = {
      #subscribe: AskSubscriptionInfo;
      #unsubscribe: (Principal, Nat);
    };

    public type TokenIDFilter = {
      token_id: Text;
      tokens: [{
        min_amount: ?Nat;
        max_amount: ?Nat;
        token: TokenSpec;
      }];
      filter_type: {
        #allow;
        #block;
      };
    };

    public type TokenSpecFilter = {
      token: TokenSpec;
      filter_type: {
        #allow;
        #block;
      };
    };


  public type ICTokenSpec = v0_1_4.ICTokenSpec;

  public type TokenSpec = v0_1_4.TokenSpec;

  public type SalesSellerTrie = Map.Map<Account, 
                                    Map.Map<Account,
                                        Map.Map<Text,
                                            Map.Map<TokenSpec,EscrowRecord>>>>;
                                        

    public type SalesBuyerTrie = Map.Map<Account,
                                Map.Map<Text,
                                    Map.Map<TokenSpec,EscrowRecord>>>;

    public type SalesTokenIDTrie = Map.Map<Text,
                                        Map.Map<TokenSpec,EscrowRecord>>;

    public type SalesLedgerTrie = Map.Map<TokenSpec,EscrowRecord>;

    public type EscrowBuyerTrie = Map.Map<Account, 
                                    Map.Map<Account,
                                        Map.Map<Text,
                                            Map.Map<TokenSpec,EscrowRecord>>>>;

    public type EscrowSellerTrie = Map.Map<Account,
                                    Map.Map<Text,
                                        Map.Map<TokenSpec,EscrowRecord>>>;
    
    public type EscrowTokenIDTrie = Map.Map<Text,
                                        Map.Map<TokenSpec,EscrowRecord>>;

    public type EscrowLedgerTrie = Map.Map<TokenSpec,EscrowRecord>;

    public type EscrowRecord = {
        amount: Nat;
        buyer: Account; 
        seller:Account; 
        token_id: Text; 
        token: TokenSpec;
        sale_id: ?Text; //locks the escrow to a specific sale
        lock_to_date: ?Int; //locks the escrow to a timestamp
        account_hash: ?Blob; //sub account the host holds the funds in
    };

  public let compare_library = v0_1_4.compare_library;

  public let library_equal : ((Text, Text), (Text, Text)) -> Bool = v0_1_4.library_equal;

  public let library_hash : ((Text, Text)) -> Nat = v0_1_4.library_hash;

  public func account_hash_uncompressed(a : Account) : Nat{
        switch(a){
          case(#principal(a_principal)){
            MapUtils.hashBlob(Principal.toBlob(a_principal));
          };
          case(#account_id(a_account_id)){

            let accountBlob = switch(hex.decode(a_account_id)){
              case(#ok(item)){Blob.fromArray(item)};
              case(#err(err)){
                D.trap("Not a valid hex");
              };
            };
            MapUtils.hashBlob(accountBlob);
          };
          case(#account(a_account)){
            let account_id = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_account.owner, switch(a_account.sub_account){case(null){null}; case(?val){?Blob.toArray(val)}}));
            let accountBlob = switch(hex.decode(account_id)){
              case(#ok(item)){Blob.fromArray(item)};
              case(#err(err)){
                D.trap("Not a valid hex");
              };
            };
            MapUtils.hashBlob(accountBlob);
          };
          case(#extensible(a_extensible)){
              //unimplemnted; unsafe; probably dont use
              //until a reliable valueToHash function is written
              //if any redenring of classes changes the whole hash
              //will change
            MapUtils.hashBlob(Conversion_lib.candySharedToBlob(#Text(Conversion_lib.candySharedToText(a_extensible))));
          };
      };
    };

  public func token_hash_uncompressed(a : TokenSpec) : Nat {
        switch (a) {
            case (#ic(a)) {
                var hash = MapUtils.hashBlob(Principal.toBlob(a.canister));
                switch(a.id){
                  case(null){};
                  case(?val){
                    hash += MapUtils.hashBlob(Conversions.candySharedToBlob(#Nat(val)));
                  };  
                };
                hash;
            };
            case (#extensible(a_extensible)) {
                //unimplemnted; unsafe; probably dont use
                //until a reliable valueToHash function is written
                //if any redenring of classes changes the whole hash
                //will change
                MapUtils.hashBlob(Conversions.candySharedToBlob(a_extensible));

            };
        };

    };
  
  public func account_hash(a : Account) : Nat{
        switch(a){
            case(#principal(a_principal)){
                Nat32.toNat(Principal.hash(a_principal));
            };
            case(#account_id(a_account_id)){
                Nat32.toNat(Text.hash(a_account_id));

            };
            case(#account(a_account)){
                Nat32.toNat(Text.hash(AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_account.owner, switch(a_account.sub_account){case(null){null}; case(?val){?Blob.toArray(val)}})) ));

            };
            case(#extensible(a_extensible)){
                //unimplemnted; unsafe; probably dont use
                //until a reliable valueToHash function is written
                //if any redenring of classes changes the whole hash
                //will change
                Nat32.toNat(Text.hash(Conversion_lib.candySharedToText(a_extensible)));
            };
        };
    };

    public func account_eq(a : Account, b : Account) : Bool{
        switch(a){
            case(#principal(a_principal)){
                switch(b){
                    case(#principal(b_principal)){
                        return a_principal == b_principal;
                    };
                    case(#account_id(b_account_id)){
                        return AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_principal, null)) == b_account_id;
                    };
                    case(#account(b_account)){
                        return AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_principal, null)) == AccountIdentifier.toText(AccountIdentifier.fromPrincipal(b_account.owner, switch(b_account.sub_account){case(null){null}; case(?val){?Blob.toArray(val)}})) ;
                    };
                    case(#extensible(b_extensible)){
                        //not implemented
                        return false;
                    };
                };
            };
            case(#account_id(a_account_id)){
                switch(b){
                    case(#principal(b_principal)){
                        return a_account_id == AccountIdentifier.toText(AccountIdentifier.fromPrincipal(b_principal,null));
                    };
                    case(#account_id(b_account_id)){
                        return a_account_id == b_account_id;
                    };
                    case(#account(b_account)){
                        return a_account_id == AccountIdentifier.toText(AccountIdentifier.fromPrincipal(b_account.owner, switch(b_account.sub_account){case(null){null}; case(?val){?Blob.toArray(val)}})) ;
                    };
                    case(#extensible(b_extensible)){
                        //not implemented
                        return false;
                    }
                }
            };
            case(#extensible(a_extensible)){
                switch(b){
                    case(#principal(b_principal)){
                        return false;
                    };
                    case(#account_id(b_account_id)){
                        return false;
                    };
                    case(#account(b_account_id)){
                        return false;
                    };
                    case(#extensible(b_extensible)){
                        //not implemented
                        return false;
                    }
                };
            };
            case(#account(a_account)){
                switch(b){
                    case(#principal(b_principal)){
                        return  AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_account.owner, switch(a_account.sub_account){case(null){null}; case(?val){?Blob.toArray(val)}})) == AccountIdentifier.toText(AccountIdentifier.fromPrincipal(b_principal, null)) ;
                    };
                    case(#account_id(b_account_id)){
                        return AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_account.owner, switch(a_account.sub_account){case(null){null}; case(?val){?Blob.toArray(val)}})) == b_account_id;
                    };
                     case(#account(b_account)){
                        return a_account.owner == b_account.owner and a_account.sub_account == b_account.sub_account;
                    };
                    case(#extensible(b_extensible)){
                        //not implemented
                        return false;
                    };
                };
            }
        };
    };

  public let account_handler  = (account_hash, account_eq);

  public func token_hash(a : TokenSpec) : Nat {
        switch(a){
            case(#ic(a)){
              Nat32.toNat(Principal.hash(a.canister));
            };
            case(#extensible(a_extensible)){
                 //unimplemnted; unsafe; probably dont use
                //until a reliable valueToHash function is written
                //if any redenring of classes changes the whole hash
                //will change
                Nat32.toNat(Text.hash(Conversion_lib.candySharedToText(a_extensible)));
            };
        };
    };

  public func token_eq(a : TokenSpec, b : TokenSpec) : Bool{
        /* #ic: {
            canister: Principal;
            standard: {
                #DIP20;
                #Ledger;
                #EXTFungible;
                #ICRC1;
            }
        };
        #extensible : CandyTypes.CandyShared; //#Class*/
        switch(a){
            case(#ic(a_token)){
                switch(b){
                    case(#ic(b_token)){
                        
                        if(a_token.standard != b_token.standard){
                            return false;
                        };
                        if(a_token.canister != b_token.canister){
                            return false;
                        };
                        if(a_token.id != b_token.id){
                            return false;
                        };
                        return true;
                    };
                    case(#extensible(b_token)){
                        //not implemented
                        return false;
                    };
                };
            };
            case(#extensible(a_token)){
                switch(b){
                    case(#ic(b_token)){
                        //not implemented
                        return false;
                    };
                    case(#extensible(b_token)){
                        //not implemented
                        return false;
                    };
                    
                }
            };
        };
    };

  public let token_handler = (token_hash, token_eq);



  public type KYCRequest = KYCTypes.KYCRequest;
  public type KYCResult = KYCTypes.KYCResult;
  public type RunKYCResult = KYCTypes.RunKYCResult;
  public type KYCTokenSpec = KYCTypes.TokenSpec;
  public type KYCCacheMap = KYCTypes.CacheMap;

  public let KYC = KYCClass;

  public type VerifiedReciept = {
    found_asset : {token_spec: TokenSpec; escrow: EscrowRecord};
    found_asset_list : EscrowLedgerTrie;
  };


  public type State  = {
    // this is the data you previously had as stable variables inside your actor class
    var collection_data : CollectionData;
    var buckets : Map.Map<Principal, BucketData>;
    var allocations : Map.Map<(Text, Text), AllocationRecord>;
    var canister_availible_space : Nat;
    var canister_allocated_storage : Nat;
    var offers : Map.Map<Account, Map.Map<Account, Int>>;
    var nft_metadata : Map.Map<Text, CandyTypes.CandyShared>;
    var escrow_balances : EscrowBuyerTrie;
    var sales_balances : SalesSellerTrie;
    var nft_ledgers : Map.Map<Text, SB.StableBuffer<TransactionRecord>>;
    var nft_sales : Map.Map<Text, SaleStatus>;
    var pending_sale_notifications : Set_8_1_0.Set<Text>;
    var pending_sale_dutch : Set_8_1_0.Set<Text>;
    var access_tokens : Map.Map<Text, HttpAccess>;
    var droute: Droute.Droute;
    var kyc_cache : Map.Map<KYCTypes.KYCRequest,KYCTypes.KYCResultFuture>;
    var use_stableBTree : Bool;
   
  };
};