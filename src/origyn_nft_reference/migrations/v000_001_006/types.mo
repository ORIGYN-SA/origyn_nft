
import v0_1_5 "../v000_001_005/types";

import D "mo:base/Debug";

import Text "mo:base/Text";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import MapUtils "mo:map_7_0_0/utils";


import Droute "mo:droute_client/Droute";



import Set "mo:map_7_0_0/Set";

import KYCTypes "mo:icrc17_kyc/types";


// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead


module {
  
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  

  public let SB = v0_1_5.SB;
  public let Map = v0_1_5.Map;
  public let CandyTypes = v0_1_5.CandyTypes;
  public let Conversions = v0_1_5.Conversions;
  public let Properties = v0_1_5.Properties;
  public let JSON = v0_1_5.JSON;
  public let Workspace = v0_1_5.Workspace;



  public type CollectionData = v0_1_5.CollectionData;

  public type AllocationRecord = v0_1_5.AllocationRecord;
  public type BucketData = v0_1_5.BucketData;

  

  public type TransactionRecord = v0_1_5.TransactionRecord;

  public type SaleStatus = v0_1_5.SaleStatus;

  public type HttpAccess= v0_1_5.HttpAccess;

  public type Account = v0_1_5.Account;

  public type TransactionID = v0_1_5.TransactionID;

  public type AuctionConfig = v0_1_5.AuctionConfig;

  public type AskFeatureKey = v0_1_5.AskFeatureKey;

    public type DutchParams = v0_1_5.DutchParams;

    public type FeeAccountsParams = [(Text, Account)];

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
      #fee_accounts : FeeAccountsParams;
    };

  public type AskFeatureMap = Map.Map<AskFeatureKey, AskFeature>;

  public type AskConfig = ?AskFeatureMap;

  public type AskConfigShared = ?[AskFeature];

  public let  ask_feature_set_eq : (a: AskFeatureKey, b: AskFeatureKey) -> Bool  =v0_1_5.ask_feature_set_eq;

  public let ask_feature_set_hash : (a: AskFeatureKey) -> Nat = v0_1_5.ask_feature_set_hash;

  public let features_to_map : (items: [AskFeature]) -> Map.Map<AskFeatureKey, AskFeature> = v0_1_5.features_to_map;

  public let feature_to_key : (request: AskFeature) -> AskFeatureKey = v0_1_5.feature_to_key;

  //public let ask_feature_set_tool = (ask_feature_set_hash, ask_feature_set_eq, func() = #atomic) : MapUtils.HashUtils<AskFeatureKey>;
  public let ask_feature_set_tool = v0_1_5.ask_feature_set_tool;

  public type PricingConfig = v0_1_5.PricingConfig;

  public type PricingConfigShared = v0_1_5.PricingConfigShared;

  public let pricing_shared_to_pricing : (request : PricingConfigShared) -> PricingConfig = v0_1_5.pricing_shared_to_pricing;

  public type AuctionState = v0_1_5.AuctionState;

  public type SubscriptionID = Nat;

  public type AskSubscriptionInfo = v0_1_5.AskSubscriptionInfo;

  public type AskSubscribeRequest = v0_1_5.AskSubscribeRequest;

  public type TokenSpecFilter = v0_1_5.TokenSpecFilter;


  public type ICTokenSpec = v0_1_5.ICTokenSpec;

  public type TokenSpec = v0_1_5.TokenSpec;

  public type SalesSellerTrie = v0_1_5.SalesSellerTrie;
                                        

    public type SalesBuyerTrie = v0_1_5.SalesBuyerTrie;

    public type SalesTokenIDTrie = v0_1_5.SalesTokenIDTrie;

    public type SalesLedgerTrie = v0_1_5.SalesLedgerTrie;

    public type EscrowBuyerTrie = v0_1_5.EscrowBuyerTrie;

    public type EscrowSellerTrie = v0_1_5.EscrowSellerTrie;
    
    public type EscrowTokenIDTrie = v0_1_5.EscrowTokenIDTrie;

    public type EscrowLedgerTrie = v0_1_5.EscrowLedgerTrie;

    public type EscrowRecord = v0_1_5.EscrowRecord;

     public type EscrowReceipt = v0_1_5.EscrowReceipt;

  public let compare_library = v0_1_5.compare_library;

  public let library_equal : ((Text, Text), (Text, Text)) -> Bool = v0_1_5.library_equal;

  public let library_hash : ((Text, Text)) -> Nat = v0_1_5.library_hash;

  public let account_hash_uncompressed :(a : Account) ->  Nat= v0_1_5.account_hash_uncompressed;

  public let token_hash_uncompressed: (a : TokenSpec) -> Nat = v0_1_5.token_hash_uncompressed;
  
  public let account_hash : (a : Account) -> Nat = v0_1_5.account_hash;

  public let account_eq : (a : Account, b : Account) -> Bool = v0_1_5.account_eq;

  public let account_handler  = v0_1_5.account_handler;

  public let token_hash : (a : TokenSpec) ->  Nat = v0_1_5.token_hash;

  public let  token_eq : (a : TokenSpec, b : TokenSpec) -> Bool = v0_1_5.token_eq;

  public let token_handler = v0_1_5.token_handler;

  public type KYCRequest = KYCTypes.KYCRequest;
  public type KYCResult = KYCTypes.KYCResult;
  public type RunKYCResult = KYCTypes.RunKYCResult;
  public type KYCTokenSpec = KYCTypes.TokenSpec;
  public type KYCCacheMap = KYCTypes.CacheMap;

  public let KYC = v0_1_5.KYC;

  public type VerifiedReciept = v0_1_5.VerifiedReciept;


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
    var pending_sale_notifications : Set.Set<Text>;
    var access_tokens : Map.Map<Text, HttpAccess>;
    var droute: Droute.Droute;
    var kyc_cache : Map.Map<KYCTypes.KYCRequest, KYCTypes.KYCResultFuture>;
    var use_stableBTree : Bool;

    //add certification type here
   
  };
};