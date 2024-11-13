import v0_1_6 "../v000_001_006/types";

import Text "mo:base/Text";

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Float "mo:base/Float";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Int8 "mo:base/Int8";
import Int16 "mo:base/Int16";
import Int32 "mo:base/Int32";
import Int64 "mo:base/Int64";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Deque "mo:base/Deque";
import MapUtils "mo:map_7_0_0/utils";
import Option "mo:base/Option";
import AccountIdentifier "mo:principalmo/AccountIdentifier";
import TimerTool "mo:timer-tool";

import ICRC3 "mo:icrc3-mo";

import Droute "mo:droute_client/Droute";

import Set "mo:map_7_0_0/Set";

import KYCTypes "mo:icrc17_kyc/types";

import CertTree "mo:cert/CertTree";

// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead

module {
  public let SB = v0_1_6.SB;
  public let Map = v0_1_6.Map;
  public let CandyTypes = v0_1_6.CandyTypes;
  public let Conversions = v0_1_6.Conversions;
  public let Properties = v0_1_6.Properties;
  public let JSON = v0_1_6.JSON;
  public let Workspace = v0_1_6.Workspace;

  public type CollectionData = v0_1_6.CollectionData;

  public type AllocationRecord = v0_1_6.AllocationRecord;
  public type BucketData = v0_1_6.BucketData;

  public type TransactionRecord = v0_1_6.TransactionRecord;

  public type SaleStatus = v0_1_6.SaleStatus;

  public type HttpAccess = v0_1_6.HttpAccess;

  public type Account = v0_1_6.Account;

  public let account_to_principal = v0_1_6.account_to_principal;
  public let account_to_owner_subaccount = v0_1_6.account_to_owner_subaccount;
  public let compare_account = v0_1_6.compare_account;

  public type TransactionID = v0_1_6.TransactionID;

  public type AuctionConfig = v0_1_6.AuctionConfig;

  public type AskFeatureKey = v0_1_6.AskFeatureKey;
  public type DutchParams = v0_1_6.DutchParams;

  public type FeeAccountsParams = v0_1_6.FeeAccountsParams;

  public type BidPaysFeesParams = v0_1_6.BidPaysFeesParams;

  private type WaitForQuietType = {
    extension : Nat64;
    fade : Float;
    max : Nat;
  };

  public type MinIncreaseType = v0_1_6.MinIncreaseType;

  private type EndingType = {
    #date : Int;
    #timeout : Nat;
  };

  private type NiftySettlementType = {
    duration : ?Int;
    expiration : ?Int;
    fixed : Bool;
    lenderOffer : Bool;
    interestRatePerSecond : Float;
  };

  public type AskFeature = v0_1_6.AskFeature;

  public type AskFeatureMap = v0_1_6.AskFeatureMap;
  public type AskFeatureArray = v0_1_6.AskFeatureArray;

  public type AskConfig = v0_1_6.AskConfig;

  public type AskConfigShared = v0_1_6.AskConfigShared;

  public type FeeName = v0_1_6.FeeName;

  public type BidFeatureKey = v0_1_6.BidFeatureKey;

  public type BidFeatureMap = v0_1_6.BidFeatureMap;
  public type BidConfig = v0_1_6.BidConfig;

  public type BidConfigShared = v0_1_6.BidConfigShared;

  public type BidFeature = v0_1_6.BidFeature;

  public let bidfeatures_to_map = v0_1_6.bidfeatures_to_map;
  public let bidfeaturesmap_to_bidfeaturearray = v0_1_6.bidfeaturesmap_to_bidfeaturearray;

  public type BidRequest = v0_1_6.BidRequest;
  public type Royalty = v0_1_6.Royalty;

  public let load_broker_bid_feature = v0_1_6.load_broker_bid_feature;
  public let load_fee_schema_bid_feature = v0_1_6.load_fee_schema_bid_feature;
  public let load_fee_accounts_bid_feature = v0_1_6.load_fee_accounts_bid_feature;

  public type InstantFeatureKey = v0_1_6.InstantFeatureKey;
  public type InstantFeatureMap = v0_1_6.InstantFeatureMap;
  public type InstantConfig = v0_1_6.InstantConfig;

  public type InstantConfigShared = v0_1_6.InstantConfigShared;

  public type InstantFeature = v0_1_6.InstantFeature;

  public let instantfeatures_to_map = v0_1_6.instantfeatures_to_map;
  public let instantfeaturesmap_to_instantfeaturearray = v0_1_6.instantfeaturesmap_to_instantfeaturearray;
  public let load_fee_schema_instant_feature = v0_1_6.load_fee_schema_instant_feature;
  public let load_fee_accounts_instant_feature = v0_1_6.load_fee_accounts_instant_feature;
  public let load_transfer_instant_feature = v0_1_6.load_transfer_instant_feature;

  public let ask_feature_set_eq = v0_1_6.ask_feature_set_eq;
  public let load_atomic_ask_feature = v0_1_6.load_atomic_ask_feature;
  public let load_buy_now_ask_feature = v0_1_6.load_buy_now_ask_feature;
  public let load_wait_for_quiet_ask_feature = v0_1_6.load_wait_for_quiet_ask_feature;
  public let load_allow_list_ask_feature = v0_1_6.load_allow_list_ask_feature;
  public let load_notify_ask_feature = v0_1_6.load_notify_ask_feature;
  public let load_reserve_ask_feature = v0_1_6.load_reserve_ask_feature;
  public let load_start_date_ask_feature = v0_1_6.load_start_date_ask_feature;
  public let load_start_price_ask_feature = v0_1_6.load_start_price_ask_feature;
  public let load_min_increase_ask_feature = v0_1_6.load_min_increase_ask_feature;
  public let load_ending_ask_feature = v0_1_6.load_ending_ask_feature;
  public let load_token_ask_feature = v0_1_6.load_token_ask_feature;
  public let load_dutch_ask_feature = v0_1_6.load_dutch_ask_feature;
  public let load_kyc_ask_feature = v0_1_6.load_kyc_ask_feature;
  public let load_nifty_ask_settlement_feature = v0_1_6.load_nifty_ask_settlement_feature;
  public let load_fee_accounts_ask_feature = v0_1_6.load_fee_accounts_ask_feature;
  public let load_fee_schema_ask_feature = v0_1_6.load_fee_schema_ask_feature;
  public let ask_feature_set_hash = v0_1_6.ask_feature_set_hash;
  public let bid_feature_set_hash = v0_1_6.bid_feature_set_hash;
  public let instant_feature_set_hash = v0_1_6.instant_feature_set_hash;
  public let bid_feature_set_eq = v0_1_6.bid_feature_set_eq;
  public let instant_feature_set_eq = v0_1_6.instant_feature_set_eq;
  public let instant_features_to_value = v0_1_6.instant_features_to_value;
  public let features_to_map = v0_1_6.features_to_map;
  public let bidfeature_to_key = v0_1_6.bidfeature_to_key;
  public let feature_to_key = v0_1_6.feature_to_key;
  public let ask_feature_set_tool = v0_1_6.ask_feature_set_tool;
  public let bid_feature_set_tool = v0_1_6.bid_feature_set_tool;
  public let instant_feature_set_tool = v0_1_6.instant_feature_set_tool;

  public type PricingConfig = v0_1_6.PricingConfig;

  public type PricingConfigShared = v0_1_6.PricingConfigShared;
  public type SalesConfig = v0_1_6.SalesConfig;
  public type MarketTransferRequest = v0_1_6.MarketTransferRequest;

  public let pricing_shared_to_pricing = v0_1_6.pricing_shared_to_pricing;

  public type AuctionState = v0_1_6.AuctionState;
  public type SubscriptionID = v0_1_6.SubscriptionID;
  public type AskSubscriptionInfo = v0_1_6.AskSubscriptionInfo;
  public type AskSubscribeRequest = v0_1_6.AskSubscribeRequest;
  public type TokenSpecFilter = v0_1_6.TokenSpecFilter;
  public type ICTokenSpec = v0_1_6.ICTokenSpec;
  public type TokenSpec = v0_1_6.TokenSpec;
  public type SalesSellerTrie = v0_1_6.SalesSellerTrie;
  public type SalesBuyerTrie = v0_1_6.SalesBuyerTrie;
  public type SalesTokenIDTrie = v0_1_6.SalesTokenIDTrie;
  public type SalesLedgerTrie = v0_1_6.SalesLedgerTrie;
  public type FeeDepositTrie = v0_1_6.FeeDepositTrie;
  public type FeeDepositDetail = v0_1_6.FeeDepositDetail;
  public type EscrowBuyerTrie = v0_1_6.EscrowBuyerTrie;
  public type EscrowSellerTrie = v0_1_6.EscrowSellerTrie;
  public type EscrowTokenIDTrie = v0_1_6.EscrowTokenIDTrie;
  public type EscrowLedgerTrie = v0_1_6.EscrowLedgerTrie;
  public type EscrowRecord = v0_1_6.EscrowRecord;
  public type EscrowReceipt = v0_1_6.EscrowReceipt;

  public let compare_library = v0_1_6.compare_library;

  public let library_equal : ((Text, Text), (Text, Text)) -> Bool = v0_1_6.library_equal;

  public let library_hash : ((Text, Text)) -> Nat = v0_1_6.library_hash;

  public let account_hash_uncompressed : (a : Account) -> Nat = v0_1_6.account_hash_uncompressed;

  public let token_hash_uncompressed : (a : TokenSpec) -> Nat = v0_1_6.token_hash_uncompressed;

  public let account_hash = v0_1_6.account_hash;

  public let account_eq : (a : Account, b : Account) -> Bool = v0_1_6.account_eq;

  public let account_handler = (account_hash, account_eq);

  public let token_hash : (a : TokenSpec) -> Nat = v0_1_6.token_hash;

  public let token_eq : (a : TokenSpec, b : TokenSpec) -> Bool = v0_1_6.token_eq;

  public let token_handler = v0_1_6.token_handler;

  public type KYCRequest = KYCTypes.KYCRequest;
  public type KYCResult = KYCTypes.KYCResult;
  public type RunKYCResult = KYCTypes.RunKYCResult;
  public type KYCTokenSpec = KYCTypes.TokenSpec;
  public type KYCCacheMap = KYCTypes.CacheMap;

  public let KYC = v0_1_6.KYC;

  public type VerifiedReciept = v0_1_6.VerifiedReciept;

  public let account_to_value = v0_1_6.account_to_value;
  public let tokenspec_to_value = v0_1_6.tokenspec_to_value;
  public let dutchparams_to_value = v0_1_6.dutchparams_to_value;
  public let ask_features_to_value = v0_1_6.ask_features_to_value;
  public let pricing_config_to_value = v0_1_6.pricing_config_to_value;

  ///refactor the below away when whe get Candy 3.0 because it is the default there:

  public type ValueShared = v0_1_6.ValueShared;

  ///converts a candyshared value to the reduced set of ValueShared used in many places like ICRC3.  Some types not recoverable
  public let candySharedToValue = v0_1_6.candySharedToValue;
  public let defaultICRC3Config = v0_1_6.defaultICRC3Config;

  public type State = v0_1_6.State;

  // public let OGY_LEDGER_CANISTER_ID = "lkwrt-vyaaa-aaaaq-aadhq-cai"; // production
  public let OGY_LEDGER_CANISTER_ID = "j5naj-nqaaa-aaaal-ajc7q-cai"; // staging

  public let OGY = v0_1_6.OGY;
  public let MAX_NAT = v0_1_6.MAX_NAT;
};
