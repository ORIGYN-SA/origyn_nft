import v0_1_6 "../v000_001_006/types";
import Conversion_lib "mo:candy_0_2_0/conversion";

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
import Option "mo:base/Option";
import AccountIdentifier "mo:principalmo/AccountIdentifier";
import TimerTool "mo:timer-tool";
import Map9 "mo:map9/Map";

import ICRC3 "mo:icrc3-mo";

import Droute "mo:droute_client/Droute";

import Set9 "mo:map9/Set";

import CertTree "mo:cert/CertTree";

// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead

module {
  public let SB = v0_1_6.SB;
  public let Map = Map9;
  public let Set = Set9;
  public let CandyTypes = v0_1_6.CandyTypes;
  public let Conversions = v0_1_6.Conversions;
  public let Properties = v0_1_6.Properties;
  public let JSON = v0_1_6.JSON;
  public let Workspace = v0_1_6.Workspace;
  public let KYCTypes = v0_1_6.KYCTypes;

  public type CollectionData = v0_1_6.CollectionData;

  public type AllocationRecord = v0_1_6.AllocationRecord;
  public type BucketData = {
    principal : Principal;
    var allocated_space : Nat;
    var available_space : Nat;
    date_added : Int;
    b_gateway : Bool;
    var version : (Nat, Nat, Nat);
    var allocations : Map.Map<(Text, Text), Int>; // (token_id, library_id), Timestamp
  };

  public type TransactionRecord = v0_1_6.TransactionRecord;

  public type SaleStatus = {
    sale_id : Text; //sha256?;
    original_broker_id : ?Principal;
    broker_id : ?Principal;
    token_id : Text;
    sale_type : {
      #auction : AuctionState;
    };
  };

  public type HttpAccess = v0_1_6.HttpAccess;

  public type Account = {
    #principal : Principal;
    #account : { owner : Principal; sub_account : ?Blob };
    #account_id : Text;
    #extensible : CandyTypes.CandyShared;
  };

  public let account_to_principal = v0_1_6.account_to_principal;
  public let account_to_owner_subaccount = v0_1_6.account_to_owner_subaccount;
  public let compare_account = v0_1_6.compare_account;

  public type TransactionID = v0_1_6.TransactionID;

  public type AuctionConfig = v0_1_6.AuctionConfig;

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
    #nifty_settlement;
    #fee_accounts;
    #fee_schema;
  };
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

  public type AskFeature = {
    #atomic;
    #buy_now : Nat;
    #wait_for_quiet : WaitForQuietType;
    #allow_list : [Principal];
    #notify : [Principal];
    #reserve : Nat;
    #start_date : Int;
    #start_price : Nat;
    #min_increase : MinIncreaseType;
    #ending : EndingType;
    #token : TokenSpec;
    #dutch : DutchParams;
    #nifty_settlement : NiftySettlementType;
    #fee_accounts : FeeAccountsParams;
    #fee_schema : Text;
  };

  public type AskFeatureMap = Map.Map<AskFeatureKey, AskFeature>;
  public type AskFeatureArray = v0_1_6.AskFeatureArray;

  public type AskConfig = ?AskFeatureMap;

  public type AskConfigShared = v0_1_6.AskConfigShared;

  public type FeeName = v0_1_6.FeeName;

  public type BidFeatureKey = {
    #broker;
    #fee_schema;
    #fee_accounts;
    // #amm;
  };

  public type BidFeatureMap = Map.Map<BidFeatureKey, BidFeature>;
  public type BidConfig = ?BidFeatureMap;

  public type BidConfigShared = v0_1_6.BidConfigShared;

  public type BidFeature = {
    #broker : Account;
    #fee_schema : Text;
    #fee_accounts : FeeAccountsParams;
    // #amm : AMMParams; //see ICRC-62: AMMs for Ledger Native Markets
  };

  public func bidfeatures_to_map(items : [BidFeature]) : BidFeatureMap {
    let feature_set = Map.new<BidFeatureKey, BidFeature>();

    for (thisItem in items.vals()) {
      ignore Map.put<BidFeatureKey, BidFeature>(
        feature_set,
        bid_feature_set_tool,
        bidfeature_to_key(thisItem),
        thisItem,
      );
    };

    return feature_set;
  };
  public func bidfeaturesmap_to_bidfeaturearray(items : BidFeatureMap) : [BidFeature] {
    let feature_arr = Buffer.Buffer<BidFeature>(3);

    for (thisItem in Map.vals(items)) {
      feature_arr.add(thisItem);
    };

    return Buffer.toArray(feature_arr);
  };

  public type BidRequest = v0_1_6.BidRequest;
  public type Royalty = v0_1_6.Royalty;

  public func load_broker_bid_feature(_config : BidConfig) : ?Account {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#broker(broker)) = Map.get<BidFeatureKey, BidFeature>(config, bid_feature_set_tool, #broker) else {
      return null;
    };
    return ?broker;
  };

  public func load_fee_schema_bid_feature(_config : BidConfig) : ?Text {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#fee_schema(fee_schema)) = Map.get<BidFeatureKey, BidFeature>(config, bid_feature_set_tool, #fee_schema) else {
      return null;
    };
    return ?fee_schema;
  };

  public func load_fee_accounts_bid_feature(_config : BidConfig) : ?FeeAccountsParams {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#fee_accounts(fee_accounts)) = Map.get<BidFeatureKey, BidFeature>(config, bid_feature_set_tool, #fee_accounts) else {
      return null;
    };
    return ?fee_accounts;
  };

  public type InstantFeatureKey = {
    #fee_schema;
    #fee_accounts;
    #transfer;
  };

  public type InstantFeatureMap = Map.Map<InstantFeatureKey, InstantFeature>;
  public type InstantConfig = ?InstantFeatureMap;

  public type InstantConfigShared = ?[InstantFeature];

  public type InstantFeature = {
    #fee_schema : Text;
    #fee_accounts : FeeAccountsParams;
    #transfer;
  };

  public func instantfeatures_to_map(items : [InstantFeature]) : InstantFeatureMap {
    let feature_set = Map.new<InstantFeatureKey, InstantFeature>();

    for (thisItem in items.vals()) {
      ignore Map.put<InstantFeatureKey, InstantFeature>(
        feature_set,
        instant_feature_set_tool,
        instantfeature_to_key(thisItem),
        thisItem,
      );
    };

    return feature_set;
  };

  public func instantfeaturesmap_to_instantfeaturearray(items : InstantFeatureMap) : [InstantFeature] {
    let feature_arr = Buffer.Buffer<InstantFeature>(3);

    for (thisItem in Map.vals(items)) {
      feature_arr.add(thisItem);
    };

    return Buffer.toArray(feature_arr);
  };

  public func load_fee_schema_instant_feature(_config : InstantConfig) : ?Text {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#fee_schema(fee_schema)) = Map.get<InstantFeatureKey, InstantFeature>(config, instant_feature_set_tool, #fee_schema) else {
      return null;
    };
    return ?fee_schema;
  };

  public func load_fee_accounts_instant_feature(_config : InstantConfig) : ?FeeAccountsParams {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#fee_accounts(fee_accounts)) = Map.get<InstantFeatureKey, InstantFeature>(config, instant_feature_set_tool, #fee_accounts) else {
      return null;
    };
    return ?fee_accounts;
  };

  public func load_transfer_instant_feature(_config : InstantConfig) : Bool {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return false);
    };

    let ?(#transfer) = Map.get<InstantFeatureKey, InstantFeature>(config, instant_feature_set_tool, #transfer) else {
      return false;
    };
    return true;
  };

  public func ask_feature_set_eq(a : AskFeatureKey, b : AskFeatureKey) : Bool {

    switch (a, b) {
      case (#atomic, #atomic) {
        return true;
      };
      case (#buy_now, #buy_now) {
        return true;
      };
      case (#wait_for_quiet, #wait_for_quiet) {
        return true;
      };
      case (#allow_list, #allow_list) {
        return true;
      };
      case (#notify, #notify) {
        return true;
      };
      case (#reserve, #reserve) {
        return true;
      };
      case (#start_date, #start_date) {
        return true;
      };
      case (#start_price, #start_price) {
        return true;
      };
      case (#min_increase, #min_increase) {
        return true;
      };
      case (#ending, #ending) {
        return true;
      };
      case (#token, #token) {
        return true;
      };
      case (#dutch, #dutch) {
        return true;
      };
      case (#nifty_settlement, #nifty_settlement) {
        return true;
      };
      case (#fee_accounts, #fee_accounts) {
        return true;
      };
      case (#fee_schema, #fee_schema) {
        return true;
      };
      case (_, _) {
        return false;
      };
    };
  };

  public func load_atomic_ask_feature(_config : AskConfig) : ?() {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#atomic()) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #atomic) else {
      return null;
    };
    return ?();
  };

  public func load_buy_now_ask_feature(_config : AskConfig) : ?Nat {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#buy_now(buy_now)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #buy_now) else {
      return null;
    };
    return ?buy_now;
  };

  public func load_wait_for_quiet_ask_feature(_config : AskConfig) : ?WaitForQuietType {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#wait_for_quiet(wait_for_quiet)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #wait_for_quiet) else {
      return null;
    };
    return ?wait_for_quiet;
  };

  public func load_allow_list_ask_feature(_config : AskConfig) : ?[Principal] {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#allow_list(allow_list)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #allow_list) else {
      return null;
    };
    return ?allow_list;
  };

  public func load_notify_ask_feature(_config : AskConfig) : [Principal] {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return []);
    };

    let ?(#notify(notify)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #notify) else {
      return [];
    };
    return notify;
  };

  public func load_reserve_ask_feature(_config : AskConfig) : ?Nat {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#reserve(reserve)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #reserve) else {
      return null;
    };
    return ?reserve;
  };

  public func load_start_date_ask_feature(_config : AskConfig) : ?Int {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#start_date(start_date)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #start_date) else {
      return null;
    };
    return ?start_date;
  };

  public func load_start_price_ask_feature(_config : AskConfig) : ?Nat {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#start_price(start_price)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #start_price) else {
      return null;
    };
    return ?start_price;
  };

  public func load_min_increase_ask_feature(_config : AskConfig) : ?MinIncreaseType {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#min_increase(min_increase)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #min_increase) else {
      return null;
    };
    return ?min_increase;
  };

  public func load_ending_ask_feature(_config : AskConfig) : ?EndingType {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#ending(ending)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #ending) else {
      return null;
    };
    return ?ending;
  };

  public func load_token_ask_feature(_config : AskConfig) : TokenSpec {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return OGY());
    };

    let ?(#token(token)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #token) else {
      return OGY();
    };
    return token;
  };

  public func load_dutch_ask_feature(_config : AskConfig) : ?DutchParams {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#dutch(dutch)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #dutch) else {
      return null;
    };
    return ?dutch;
  };

  public func load_nifty_ask_settlement_feature(_config : AskConfig) : ?NiftySettlementType {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#nifty_settlement(nifty_settlement)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #nifty_settlement) else {
      return null;
    };
    return ?nifty_settlement;
  };

  public func load_fee_accounts_ask_feature(_config : AskConfig) : ?FeeAccountsParams {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#fee_accounts(fee_accounts)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #fee_accounts) else {
      return null;
    };
    return ?fee_accounts;
  };

  public func load_fee_schema_ask_feature(_config : AskConfig) : ?Text {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#fee_schema(fee_schema)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #fee_schema) else {
      return null;
    };
    return ?fee_schema;
  };

  public func ask_feature_set_hash(a : AskFeatureKey) : Nat32 {

    switch (a) {
      case (#atomic) {
        return 11311112;
      };
      case (#buy_now) {
        return 222234453;
      };
      case (#wait_for_quiet) {
        return 32223345;
      };
      case (#allow_list) {
        return 444445324;
      };
      case (#notify) {
        return 555554234;
      };
      case (#reserve) {
        return 666323;
      };
      case (#start_date) {
        return 74424533;
      };
      case (#start_price) {
        return 84453456;
      };
      case (#min_increase) {
        return 9345455;
      };
      case (#ending) {
        return 1044345;
      };
      case (#token) {
        return 112345466;
      };
      case (#dutch) {
        return 1266844;
      };
      case (#nifty_settlement) {
        return 14345667;
      };
      case (#fee_accounts) {
        return 14345670;
      };
      case (#fee_schema) {
        return 14345671;
      };
    };
  };

  public func bid_feature_set_hash(a : BidFeatureKey) : Nat32 {
    switch (a) {
      case (#broker) {
        return 11311112;
      };
      case (#fee_schema) {
        return 11311114;
      };
      case (#fee_accounts) {
        return 11311115;
      };
    };
  };

  public func bid_feature_set_eq(a : BidFeatureKey, b : BidFeatureKey) : Bool {
    switch (a, b) {
      case (#broker, #broker) {
        return true;
      };
      case (#fee_schema, #fee_schema) {
        return true;
      };
      case (#fee_accounts, #fee_accounts) {
        return true;
      };
      case (_, _) {
        return false;
      };
    };
  };

  public func instant_feature_set_hash(a : InstantFeatureKey) : Nat32 {
    switch (a) {
      case (#fee_schema) {
        return 11311114;
      };
      case (#fee_accounts) {
        return 11311115;
      };
      case (#transfer) {
        return 11311116;
      };
    };
  };

  public func instant_feature_set_eq(a : InstantFeatureKey, b : InstantFeatureKey) : Bool {
    switch (a, b) {
      case (#fee_schema, #fee_schema) {
        return true;
      };
      case (#fee_accounts, #fee_accounts) {
        return true;
      };
      case (#transfer, #transfer) {
        return true;
      };
      case (_, _) {
        return false;
      };
    };
  };

  public func instantfeature_to_key(request : InstantFeature) : InstantFeatureKey {
    switch (request) {
      case (#fee_schema(e)) {
        return #fee_schema;
      };
      case (#fee_accounts(e)) {
        return #fee_accounts;
      };
      case (#transfer) {
        return #transfer;
      };
    };
  };

  public func instant_features_to_value(features : [InstantFeature]) : ICRC3.Value {
    let newMap = Buffer.Buffer<(Text, ICRC3.Value)>(1);

    for (thisItem in features.vals()) {
      switch (thisItem) {
        case (#fee_accounts(value)) {
          let feeAccounts = Buffer.Buffer<ICRC3.Value>(value.size());
          for (account in value.vals()) {
            feeAccounts.add(#Array([#Text(account)]));
          };
          newMap.add(("fee_accounts", #Array(Buffer.toArray(feeAccounts))));
        };
        case (#fee_schema(value)) newMap.add(("fee_schema", #Text(value)));
      };
    };

    return #Map(Buffer.toArray(newMap));
  };

  public func features_to_map(items : AskFeatureArray) : AskFeatureMap {
    let feature_set = Map.new<AskFeatureKey, AskFeature>();

    for (thisItem in items.vals()) {
      ignore Map.put<AskFeatureKey, AskFeature>(
        feature_set,
        ask_feature_set_tool,
        feature_to_key(thisItem),
        thisItem,
      );
    };

    return feature_set;
  };

  public func bidfeature_to_key(request : BidFeature) : BidFeatureKey {
    switch (request) {
      case (#broker(e)) {
        return #broker;
      };
      case (#fee_schema(e)) {
        return #fee_schema;
      };
      case (#fee_accounts(e)) {
        return #fee_accounts;
      };
    };
  };

  public func feature_to_key(request : AskFeature) : AskFeatureKey {

    switch (request) {
      case (#atomic) {
        return #atomic;
      };
      case (#buy_now(e)) {
        return #buy_now;
      };
      case (#wait_for_quiet(e)) {
        return #wait_for_quiet;
      };
      case (#allow_list(e)) {
        return #allow_list;
      };
      case (#notify(e)) {
        return #notify;
      };
      case (#reserve(e)) {
        return #reserve;
      };
      case (#start_date(e)) {
        return #start_date;
      };
      case (#start_price(e)) {
        return #start_price;
      };
      case (#min_increase(e)) {
        return #min_increase;
      };
      case (#ending(e)) {
        return #ending;
      };
      case (#token(e)) {
        return #token;
      };
      case (#dutch(e)) {
        return #dutch;
      };
      case (#nifty_settlement(e)) {
        return #nifty_settlement;
      };
      case (#fee_accounts(e)) {
        return #fee_accounts;
      };
      case (#fee_schema(e)) {
        return #fee_schema;
      };
    };
  };

  public let ask_feature_set_tool = (ask_feature_set_hash, ask_feature_set_eq) : Map.HashUtils<AskFeatureKey>;
  public let bid_feature_set_tool = (bid_feature_set_hash, bid_feature_set_eq) : Map.HashUtils<BidFeatureKey>;
  public let instant_feature_set_tool = (instant_feature_set_hash, instant_feature_set_eq) : Map.HashUtils<InstantFeatureKey>;

  public type PricingConfig = {
    #instant : InstantConfig; //executes an escrow recipt transfer -only available for non-marketable NFTs
    //below have not been signficantly desinged or vetted
    #auction : AuctionConfig; //depricated - use ask
    #ask : AskConfig;
    #extensible : CandyTypes.CandyShared;
  };

  public type PricingConfigShared = {
    #instant : InstantConfigShared; //executes an escrow recipt transfer -only available for non-marketable NFTs
    //below have not been signficantly desinged or vetted
    #auction : AuctionConfig; //depricated - use ask
    #ask : AskConfigShared;
    #extensible : CandyTypes.CandyShared;
  };

  public type SalesConfig = {
    escrow_receipt : ?EscrowReceipt;
    broker_id : ?Account;
    pricing : PricingConfigShared;
  };

  public type MarketTransferRequest = {
    token_id : Text;
    sales_config : SalesConfig;
  };

  public func pricing_shared_to_pricing(request : PricingConfigShared) : PricingConfig {
    switch (request) {
      case (#instant(val)) #instant(?instantfeatures_to_map(Option.get(val, []))); //executes an escrow recipt transfer -only available for non-marketable NFTs
      //below have not been signficantly desinged or vetted
      case (#auction(val)) #auction(val); //depricated - use ask
      case (#ask(val)) { #ask(?features_to_map(Option.get(val, []))) };
      case (#extensible(e)) #extensible(e);
    };
  };

  public type AuctionState = {
    config : PricingConfig;
    var current_bid_amount : Nat;
    var current_config : BidConfig;
    var current_escrow : ?EscrowRecord;
    var end_date : Int;
    var start_date : Int;
    token : TokenSpec;
    var min_next_bid : Nat;
    var wait_for_quiet_count : ?Nat;
    allow_list : ?Map.Map<Principal, Bool>; //empty set means everyone
    var participants : Map.Map<Principal, Int>;
    var status : {
      #open;
      #closed;
      #not_started;
    };
    var notify_queue : ?Deque.Deque<(Principal, ?SubscriptionID)>;
    var winner : ?Account;
  };
  public type SubscriptionID = v0_1_6.SubscriptionID;
  public type AskSubscriptionInfo = v0_1_6.AskSubscriptionInfo;
  public type AskSubscribeRequest = v0_1_6.AskSubscribeRequest;
  public type TokenSpecFilter = v0_1_6.TokenSpecFilter;
  public type ICTokenSpec = v0_1_6.ICTokenSpec;
  public type TokenSpec = v0_1_6.TokenSpec;
  public type FeeDepositTrie = Map.Map<Account, Map.Map<TokenSpec, FeeDepositDetail>>;
  public type FeeDepositDetail = {
    total_balance : Nat;
    locks : Map.Map<Text, Nat>; //locks for sale ids
  };

  public type SalesSellerTrie = Map.Map<Account, SalesBuyerTrie>;

  public type SalesBuyerTrie = Map.Map<Account, SalesTokenIDTrie>;

  public type SalesTokenIDTrie = Map.Map<Text, SalesLedgerTrie>;

  public type SalesLedgerTrie = Map.Map<TokenSpec, EscrowRecord>;

  public type EscrowBuyerTrie = Map.Map<Account, EscrowSellerTrie>;

  public type EscrowSellerTrie = Map.Map<Account, EscrowTokenIDTrie>;

  public type EscrowTokenIDTrie = Map.Map<Text, EscrowLedgerTrie>;

  public type EscrowLedgerTrie = Map.Map<TokenSpec, EscrowRecord>;
  public type EscrowRecord = v0_1_6.EscrowRecord;
  public type EscrowReceipt = {
    amount : Nat; //Nat to support cycles
    seller : Account;
    buyer : Account;
    token_id : Text;
    token : TokenSpec;
  };

  public let compare_library = v0_1_6.compare_library;

  public let library_equal : ((Text, Text), (Text, Text)) -> Bool = v0_1_6.library_equal;

  public func library_hash(x : (Text, Text)) : Nat32 {
    return Text.hash("token_id" # x.0 # "library_id" # x.1);
  };

  public let account_hash_uncompressed : (a : Account) -> Nat = v0_1_6.account_hash_uncompressed;

  public let token_hash_uncompressed : (a : TokenSpec) -> Nat = v0_1_6.token_hash_uncompressed;

  public func account_hash(a : Account) : Nat32 {
    let _a = account_to_owner_subaccount(a);
    Text.hash(AccountIdentifier.toText(AccountIdentifier.fromPrincipal(_a.owner, switch (_a.sub_account) { case (null) { null }; case (?val) { ?Blob.toArray(val) } })));
  };

  public func account_eq(a : Account, b : Account) : Bool {
    switch (a) {
      case (#principal(a_principal)) {
        switch (b) {
          case (#principal(b_principal)) {
            return a_principal == b_principal;
          };
          case (#account_id(b_account_id)) {
            return AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_principal, null)) == b_account_id;
          };
          case (#account(b_account)) {
            return AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_principal, null)) == AccountIdentifier.toText(AccountIdentifier.fromPrincipal(b_account.owner, switch (b_account.sub_account) { case (null) { null }; case (?val) { ?Blob.toArray(val) } }));
          };
          case (#extensible(b_extensible)) {
            //not implemented
            return false;
          };
        };
      };
      case (#account_id(a_account_id)) {
        switch (b) {
          case (#principal(b_principal)) {
            return a_account_id == AccountIdentifier.toText(AccountIdentifier.fromPrincipal(b_principal, null));
          };
          case (#account_id(b_account_id)) {
            return a_account_id == b_account_id;
          };
          case (#account(b_account)) {
            return a_account_id == AccountIdentifier.toText(AccountIdentifier.fromPrincipal(b_account.owner, switch (b_account.sub_account) { case (null) { null }; case (?val) { ?Blob.toArray(val) } }));
          };
          case (#extensible(b_extensible)) {
            //not implemented
            return false;
          };
        };
      };
      case (#extensible(a_extensible)) {
        switch (b) {
          case (#principal(b_principal)) {
            return false;
          };
          case (#account_id(b_account_id)) {
            return false;
          };
          case (#account(b_account_id)) {
            return false;
          };
          case (#extensible(b_extensible)) {
            //not implemented
            return false;
          };
        };
      };
      case (#account(a_account)) {
        switch (b) {
          case (#principal(b_principal)) {
            return AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_account.owner, switch (a_account.sub_account) { case (null) { null }; case (?val) { ?Blob.toArray(val) } })) == AccountIdentifier.toText(AccountIdentifier.fromPrincipal(b_principal, null));
          };
          case (#account_id(b_account_id)) {
            return AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_account.owner, switch (a_account.sub_account) { case (null) { null }; case (?val) { ?Blob.toArray(val) } })) == b_account_id;
          };
          case (#account(b_account)) {
            return a_account.owner == b_account.owner and a_account.sub_account == b_account.sub_account;
          };
          case (#extensible(b_extensible)) {
            //not implemented
            return false;
          };
        };
      };
    };
  };

  public let account_handler = (account_hash, account_eq) : Map.HashUtils<Account>;

  public func token_hash(a : TokenSpec) : Nat32 {
    switch (a) {
      case (#ic(a)) {
        Principal.hash(a.canister);
      };
      case (#extensible(a_extensible)) {
        //unimplemnted; unsafe; probably dont use
        //until a reliable valueToHash function is written
        //if any redenring of classes changes the whole hash
        //will change
        Text.hash(Conversion_lib.candySharedToText(a_extensible));
      };
    };
  };

  public func token_eq(a : TokenSpec, b : TokenSpec) : Bool {
    switch (a) {
      case (#ic(a_token)) {
        switch (b) {
          case (#ic(b_token)) {

            if (a_token.standard != b_token.standard) {
              return false;
            };
            if (a_token.canister != b_token.canister) {
              return false;
            };
            if (a_token.id != b_token.id) {
              return false;
            };
            return true;
          };
          case (#extensible(b_token)) {
            //not implemented
            return false;
          };
        };
      };
      case (#extensible(a_token)) {
        switch (b) {
          case (#ic(b_token)) {
            //not implemented
            return false;
          };
          case (#extensible(b_token)) {
            //not implemented
            return false;
          };

        };
      };
    };
  };

  public let token_handler = (token_hash, token_eq);

  public type KYCRequest = KYCTypes.KYCRequest;
  public type KYCResult = KYCTypes.KYCResult;
  public type RunKYCResult = KYCTypes.RunKYCResult;
  public type KYCTokenSpec = KYCTypes.TokenSpec;
  public type KYCCacheMap = KYCTypes.CacheMap;

  public let KYC = v0_1_6.KYC;

  public type VerifiedReciept = {
    found_asset : { token_spec : TokenSpec; escrow : EscrowRecord };
    found_asset_list : EscrowLedgerTrie;
  };

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

  public type State = {
    var collection_data : CollectionData;
    var buckets : Map.Map<Principal, BucketData>;
    var allocations : Map.Map<(Text, Text), AllocationRecord>;
    var canister_availible_space : Nat;
    var canister_allocated_storage : Nat;
    var offers : Map.Map<Account, Map.Map<Account, Int>>;
    var nft_metadata : Map.Map<Text, CandyTypes.CandyShared>;
    var escrow_balances : EscrowBuyerTrie;
    var sales_balances : SalesSellerTrie;
    var fee_deposit_balances : FeeDepositTrie;
    var nft_ledgers : Map.Map<Text, SB.StableBuffer<TransactionRecord>>;
    var master_ledger : SB.StableBuffer<TransactionRecord>;
    var nft_sales : Map.Map<Text, SaleStatus>;
    var pending_sale_notifications : Set.Set<Text>;
    var access_tokens : Map.Map<Text, HttpAccess>;
    var droute : Droute.Droute;
    var use_stableBTree : Bool;
    var icrc3_migration_state : ICRC3.State;
    var cert_store : CertTree.Store;
    var timerState : ?TimerTool.State;
  };

  // public let OGY_LEDGER_CANISTER_ID = "lkwrt-vyaaa-aaaaq-aadhq-cai"; // production
  public let OGY_LEDGER_CANISTER_ID = "j5naj-nqaaa-aaaal-ajc7q-cai"; // staging

  public let OGY = v0_1_6.OGY;
  public let MAX_NAT = v0_1_6.MAX_NAT;
};
