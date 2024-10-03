import v0_1_5 "../v000_001_005/types";

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

  public type TransactionRecord = {
    token_id : Text;
    index : Nat;
    txn_type : {
      #auction_bid : {
        buyer : Account;
        amount : Nat;
        token : TokenSpec;
        sale_id : Text;
        extensible : CandyTypes.CandyShared;
      };
      #mint : {
        from : Account;
        to : Account;
        //nyi: metadata hash
        sale : ?{
          token : TokenSpec;
          amount : Nat; //Nat to support cycles
        };
        extensible : CandyTypes.CandyShared;
      };
      #sale_ended : {
        seller : Account;
        buyer : Account;

        token : TokenSpec;
        sale_id : ?Text;
        amount : Nat; //Nat to support cycles
        extensible : CandyTypes.CandyShared;
      };
      #royalty_paid : {
        seller : Account;
        buyer : Account;
        receiver : Account;
        tag : Text;
        token : TokenSpec;
        sale_id : ?Text;
        amount : Nat; //Nat to support cycles
        extensible : CandyTypes.CandyShared;
      };
      #sale_opened : {
        pricing : PricingConfigShared;
        sale_id : Text;
        extensible : CandyTypes.CandyShared;
      };
      #owner_transfer : {
        from : Account;
        to : Account;
        extensible : CandyTypes.CandyShared;
      };
      #escrow_deposit : {
        seller : Account;
        buyer : Account;
        token : TokenSpec;
        token_id : Text;
        amount : Nat; //Nat to support cycles
        trx_id : TransactionID;
        extensible : CandyTypes.CandyShared;
      };
      #escrow_withdraw : {
        seller : Account;
        buyer : Account;
        token : TokenSpec;
        token_id : Text;
        amount : Nat; //Nat to support cycles
        fee : Nat;
        trx_id : TransactionID;
        extensible : CandyTypes.CandyShared;
      };
      #deposit_withdraw : {
        buyer : Account;
        token : TokenSpec;
        amount : Nat; //Nat to support cycles
        fee : Nat;
        trx_id : TransactionID;
        extensible : CandyTypes.CandyShared;
      };
      #fee_deposit : {
        amount : Nat;
        account : Account;
        extensible : CandyTypes.CandyShared;
        token : TokenSpec;
      };
      #fee_deposit_withdraw : {
        amount : Nat;
        account : Account;
        extensible : CandyTypes.CandyShared;
        fee : Nat;
        token : TokenSpec;
        trx_id : TransactionID;
      };
      #sale_withdraw : {
        seller : Account;
        buyer : Account;
        token : TokenSpec;
        token_id : Text;
        amount : Nat; //Nat to support cycles
        fee : Nat;
        trx_id : TransactionID;
        extensible : CandyTypes.CandyShared;
      };
      #canister_owner_updated : {
        owner : Principal;
        extensible : CandyTypes.CandyShared;
      };
      #canister_managers_updated : {
        managers : [Principal];
        extensible : CandyTypes.CandyShared;
      };
      #canister_network_updated : {
        network : Principal;
        extensible : CandyTypes.CandyShared;
      };
      #data : {
        data_dapp : ?Text;
        data_path : ?Text;
        hash : ?[Nat8];
        extensible : CandyTypes.CandyShared;
      }; //nyi
      #burn : {
        from : ?Account;
        extensible : CandyTypes.CandyShared;
      };
      #extensible : CandyTypes.CandyShared;

    };
    timestamp : Int;
  };

  public type SaleStatus = {
    sale_id : Text; //sha256?;
    original_broker_id : ?Principal;
    broker_id : ?Principal;
    token_id : Text;
    sale_type : {
      #auction : AuctionState;
    };
  };

  public type HttpAccess = v0_1_5.HttpAccess;

  public type Account = {
    #principal : Principal;
    #account : { owner : Principal; sub_account : ?Blob };
    #account_id : Text;
    #extensible : CandyTypes.CandyShared;
  };

  public func account_to_principal(account : Account) : Principal {
    switch (account) {
      case (#principal(val)) { val };
      case (#account(val)) { val.owner };
      case (#account_id(val)) { Principal.fromText(val) };
      case (#extensible(val)) { Conversions.candySharedToPrincipal(val) };
    };
  };

  public func account_to_owner_subaccount(account : Account) : {
    owner : Principal;
    sub_account : ?Blob;
  } {
    switch (account) {
      case (#principal(val)) { { owner = val; sub_account = null } };
      case (#account(val)) { val };
      case (#account_id(val)) {
        { owner = Principal.fromText(val); sub_account = null };
      };
      case (#extensible(val)) {
        { owner = Conversions.candySharedToPrincipal(val); sub_account = null };
      };
    };
  };

  public func compare_account(account1 : Account, account2 : Account) : Bool {
    let a = account_to_owner_subaccount(account1);
    let b = account_to_owner_subaccount(account2);

    return a == b;
  };

  public type TransactionID = v0_1_5.TransactionID;

  public type AuctionConfig = {
    reserve : ?Nat;
    token : TokenSpec;
    buy_now : ?Nat;
    start_price : Nat;
    start_date : Int;
    ending : {
      #date : Int;
      #wait_for_quiet : {
        date : Int;
        extension : Nat64;
        fade : Float;
        max : Nat;
      };
    };
    min_increase : MinIncreaseType;
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
    #fee_accounts;
    #fee_schema;
  };
  public type DutchParams = v0_1_5.DutchParams;

  public type FeeAccountsParams = [FeeName];

  public type BidPaysFeesParams = [FeeName];

  private type WaitForQuietType = {
    extension : Nat64;
    fade : Float;
    max : Nat;
  };

  public type MinIncreaseType = {
    #percentage : Float;
    #amount : Nat;
  };

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
    #kyc : Principal;
    #nifty_settlement : NiftySettlementType;
    #fee_accounts : FeeAccountsParams;
    #fee_schema : Text;
  };

  public type AskFeatureMap = Map.Map<AskFeatureKey, AskFeature>;
  public type AskFeatureArray = [AskFeature];

  public type AskConfig = ?AskFeatureMap;

  public type AskConfigShared = ?AskFeatureArray;

  public type FeeName = Text;

  public type BidFeatureKey = {
    #broker;
    #fee_schema;
    #fee_accounts;
    // #amm;
  };

  public type BidFeatureMap = Map.Map<BidFeatureKey, BidFeature>;
  public type BidConfig = ?BidFeatureMap;

  public type BidConfigShared = ?[BidFeature];

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

  public type BidRequest = {
    escrow_record : EscrowRecord;
    config : BidConfigShared;
  };

  public type Royalty = {
    #fixed : {
      tag : Text;
      fixedXDR : Float;
      token : ?TokenSpec;
    };
    #dynamic : {
      tag : Text;
      rate : Float;
    };
  };

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
      case (#kyc, #kyc) {
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

  public func load_kyc_ask_feature(_config : AskConfig) : ?Principal {
    let config = switch (_config) {
      case (?config) (config);
      case (_) (return null);
    };

    let ?(#kyc(kyc)) = Map.get<AskFeatureKey, AskFeature>(config, ask_feature_set_tool, #kyc) else {
      return null;
    };
    return ?kyc;
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

  public func ask_feature_set_hash(a : AskFeatureKey) : Nat {

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
      case (#kyc) {
        return 13345466;
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

  public func bid_feature_set_hash(a : BidFeatureKey) : Nat {
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

  public func instant_feature_set_hash(a : InstantFeatureKey) : Nat {
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
      case (#kyc(e)) {
        return #kyc;
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

  //public let ask_feature_set_tool = (ask_feature_set_hash, ask_feature_set_eq, func() = #atomic) : MapUtils.HashUtils<AskFeatureKey>;
  public let ask_feature_set_tool = (ask_feature_set_hash, ask_feature_set_eq) : MapUtils.HashUtils<AskFeatureKey>;

  public let bid_feature_set_tool = (bid_feature_set_hash, bid_feature_set_eq) : MapUtils.HashUtils<BidFeatureKey>;

  public let instant_feature_set_tool = (instant_feature_set_hash, instant_feature_set_eq) : MapUtils.HashUtils<InstantFeatureKey>;

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

  public type FeeDepositTrie = Map.Map<Account, Map.Map<TokenSpec, FeeDepositDetail>>;

  public type FeeDepositDetail = {
    total_balance : Nat;
    locks : Map.Map<Text, Nat>; //locks for sale ids
  };

  public type EscrowBuyerTrie = v0_1_5.EscrowBuyerTrie;

  public type EscrowSellerTrie = v0_1_5.EscrowSellerTrie;

  public type EscrowTokenIDTrie = v0_1_5.EscrowTokenIDTrie;

  public type EscrowLedgerTrie = v0_1_5.EscrowLedgerTrie;

  public type EscrowRecord = v0_1_5.EscrowRecord;

  public type EscrowReceipt = {
    amount : Nat; //Nat to support cycles
    seller : Account;
    buyer : Account;
    token_id : Text;
    token : TokenSpec;
  };

  public let compare_library = v0_1_5.compare_library;

  public let library_equal : ((Text, Text), (Text, Text)) -> Bool = v0_1_5.library_equal;

  public let library_hash : ((Text, Text)) -> Nat = v0_1_5.library_hash;

  public let account_hash_uncompressed : (a : Account) -> Nat = v0_1_5.account_hash_uncompressed;

  public let token_hash_uncompressed : (a : TokenSpec) -> Nat = v0_1_5.token_hash_uncompressed;

  public func account_hash(a : Account) : Nat {
    let _a = account_to_owner_subaccount(a);
    Nat32.toNat(Text.hash(AccountIdentifier.toText(AccountIdentifier.fromPrincipal(_a.owner, switch (_a.sub_account) { case (null) { null }; case (?val) { ?Blob.toArray(val) } }))));
  };

  public let account_eq : (a : Account, b : Account) -> Bool = v0_1_5.account_eq;

  public let account_handler = (account_hash, account_eq);

  public let token_hash : (a : TokenSpec) -> Nat = v0_1_5.token_hash;

  public let token_eq : (a : TokenSpec, b : TokenSpec) -> Bool = v0_1_5.token_eq;

  public let token_handler = v0_1_5.token_handler;

  public type KYCRequest = KYCTypes.KYCRequest;
  public type KYCResult = KYCTypes.KYCResult;
  public type RunKYCResult = KYCTypes.RunKYCResult;
  public type KYCTokenSpec = KYCTypes.TokenSpec;
  public type KYCCacheMap = KYCTypes.CacheMap;

  public let KYC = v0_1_5.KYC;

  public type VerifiedReciept = v0_1_5.VerifiedReciept;

  public func account_to_value(account : Account) : ICRC3.Value {
    switch (account) {
      case (#principal(value)) return #Array([#Blob(Principal.toBlob(value))]);
      case (#account(value)) return #Array([
        #Blob(Principal.toBlob(value.owner)),
        switch (value.sub_account) {
          case (null) return #Blob("" : Blob);
          case (?subaccount) return #Blob(subaccount);
        },
      ]);
      case (#account_id(value)) return #Text(value);
      case (#extensible(value)) return candySharedToValue(value);
    };
  };

  public func tokenspec_to_value(token : TokenSpec) : ICRC3.Value {
    //todo: extensible values should be checked for size
    switch (token) {
      case (#ic(value)) {
        let newMap = Buffer.Buffer<(Text, ICRC3.Value)>(1);
        newMap.add(("canister", #Blob(Principal.toBlob(value.canister))));
        newMap.add("symbol", #Text(value.symbol));
        newMap.add(("decimals", #Nat(value.decimals)));

        switch (value.fee) {
          case (null) {};
          case (?fee) newMap.add(("fee", #Nat(fee)));
        };

        switch (value.id) {
          case (null) {};
          case (?id) newMap.add(("id", #Nat(id)));
        };

        newMap.add((
          "standard",
          switch (value.standard) {
            case (#DIP20) #Text("DIP20");
            case (#Ledger) #Text("Ledger");
            case (#EXTFungible) #Text("EXTFungible");
            case (#ICRC1) #Text("ICRC1");
            case (#Other(val)) candySharedToValue(val);
          },
        ));

        return #Map(Buffer.toArray(newMap));
      };
      case (#extensible(value)) return candySharedToValue(value);
    };

  };

  public func dutchparams_to_value(value : DutchParams) : ICRC3.Value {
    let newMap = Buffer.Buffer<(Text, ICRC3.Value)>(1);

    switch (value.time_unit) {
      case (#hour(hours)) {
        newMap.add(("time_unit", #Text("hours")));
        newMap.add(("time_amount", #Nat(hours)));
      };
      case (#day(day)) {
        newMap.add(("time_unit", #Text("day")));
        newMap.add(("time_amount", #Nat(day)));
      };
      case (#minute(minutes)) {
        newMap.add(("time_unit", #Text("minute")));
        newMap.add(("time_amount", #Nat(minutes)));
      };
    };

    switch (value.decay_type) {
      case (#flat(flat)) {
        newMap.add(("decay_type", #Text("flat")));
        newMap.add(("decay_amount", #Nat(flat)));
      };
      case (#percent(percent)) {
        newMap.add(("decay_type", #Text("percent")));
        newMap.add(("decay_amount", #Text(Float.format(#exact, percent))));
      };
    };

    return #Map(Buffer.toArray(newMap));
  };

  public func ask_features_to_value(features : [AskFeature]) : ICRC3.Value {
    let newMap = Buffer.Buffer<(Text, ICRC3.Value)>(1);

    for (thisItem in features.vals()) {
      switch (thisItem) {
        case (#atomic) newMap.add(("atomic", #Text("atomic")));
        case (#buy_now(value)) newMap.add(("buy_now", #Text("buy_now")));
        case (#wait_for_quiet(value)) {
          newMap.add(("wait_for_quiet_extension", #Nat(Nat64.toNat(value.extension))));
          newMap.add(("wait_for_quiet_fade", #Text(Float.format(#exact, value.fade))));
          newMap.add(("wait_for_quiet_max", #Nat(value.max)));
        };
        case (#allow_list(value)) {
          let list = Buffer.Buffer<ICRC3.Value>(value.size());
          for (principal in value.vals()) {
            list.add(#Blob(Principal.toBlob(principal)));
          };
          newMap.add(("allow_list", #Array(Buffer.toArray(list))));
        };
        case (#notify(value)) {
          let notifyList = Buffer.Buffer<ICRC3.Value>(value.size());
          for (principal in value.vals()) {
            notifyList.add(#Blob(Principal.toBlob(principal)));
          };
          newMap.add(("notify", #Array(Buffer.toArray(notifyList))));
        };
        case (#reserve(value)) newMap.add(("reserve", #Nat(value)));
        case (#start_date(value)) newMap.add(("start_date", #Nat(Int.abs(value))));
        case (#start_price(value)) newMap.add(("start_price", #Nat(value)));
        case (#min_increase(#percentage(value))) {
          newMap.add(("min_increase_float", #Text(Float.format(#exact, value))));
        };
        case (#min_increase(#amount(value))) {
          newMap.add(("min_increase_amount", #Nat(value)));
        };
        case (#ending(#date(value))) {

          newMap.add(("ending_date", #Nat(Int.abs(value))));
        };
        case (#ending(#timeout(value))) {
          newMap.add(("ending_timeout", #Nat(Int.abs(value))));
        };
        case (#token(value)) newMap.add(("token", tokenspec_to_value(value)));
        case (#dutch(value)) newMap.add(("dutch", dutchparams_to_value(value)));
        case (#kyc(value)) newMap.add(("kyc", #Blob(Principal.toBlob(value))));
        case (#nifty_settlement(value)) {

          switch (value.duration) {
            case (null) {};
            case (?duration) newMap.add(("nifty_settlement_duration", #Nat(Int.abs(duration))));
          };
          switch (value.expiration) {
            case (null) {};
            case (?expiration) newMap.add(("nifty_settlment_expiration", #Nat(Int.abs(expiration))));
          };
          newMap.add(("nifty_settlement_fixed", #Text(Bool.toText(value.fixed))));
          newMap.add(("nifty_settlement_lenderOffer", #Text(Bool.toText(value.lenderOffer))));
          newMap.add(("nifty_settlement_interestRatePerSecond", #Text(Float.format(#exact, value.interestRatePerSecond))));
        };
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

  public func pricing_config_to_value(config : PricingConfigShared) : ICRC3.Value {
    //todo: extensible values should be checked for size
    switch (config) {
      case (#instant(?value)) {
        return (instant_features_to_value(Iter.toArray(value.vals())));
      };
      case (#instant(null)) { #Text("Instant") };
      case (#auction(value)) {
        let newMap = Buffer.Buffer<(Text, ICRC3.Value)>(1);

        switch (value.reserve) {
          case (null) {};
          case (?reserve) newMap.add(("reserve", #Nat(reserve)));
        };
        switch (value.buy_now) {
          case (null) {};
          case (?buy_now) newMap.add(("buy_now", #Nat(buy_now)));
        };

        newMap.add(("token", tokenspec_to_value(value.token)));

        newMap.add(("start_price", #Nat(value.start_price)));
        newMap.add(("start_date", #Nat(Int.abs(value.start_date))));
        newMap.add((
          "ending",
          switch (value.ending) {
            case (#date(val)) #Nat(Int.abs(val));
            case (#wait_for_quiet(val)) #Map([
              ("date", #Nat(Int.abs(val.date))),
              ("extension", #Nat(Nat64.toNat(val.extension))),
              ("fade", #Text(Float.format(#exact, val.fade))),
              ("max", #Nat(val.max)),
            ]);
          },
        ));

        newMap.add((
          "min_increase",
          switch (value.min_increase) {
            case (#percentage(val)) #Text(Float.format(#exact, val));
            case (#amount(val)) #Nat(val);
          },
        ));

        switch (value.allow_list) {
          case (null) {};
          case (
            ?allow
          ) {
            let newAllow = Buffer.Buffer<ICRC3.Value>(allow.size());
            for (thisAllow in allow.vals()) {
              newAllow.add(#Blob(Principal.toBlob(thisAllow)));
            };
            newMap.add(("allow_list", #Array(Buffer.toArray(newAllow))));
          };
        };

        return #Map(Buffer.toArray(newMap));

      };

      case (#ask(?value)) {
        return (ask_features_to_value(Iter.toArray(value.vals())));
      };
      case (#ask(null)) { #Text("Ask") };
      case (#extensible(value)) return candySharedToValue(value);
    };
  };

  ///refactor the below away when whe get Candy 3.0 because it is the default there:

  public type ValueShared = {
    #Int : Int;
    #Nat : Nat;
    #Text : Text;
    #Blob : Blob;
    #Array : [ValueShared];
    #Map : [(Text, ValueShared)];
  };

  ///converts a candyshared value to the reduced set of ValueShared used in many places like ICRC3.  Some types not recoverable
  public func candySharedToValue(x : CandyTypes.CandyShared) : ValueShared {
    switch (x) {
      case (#Text(x)) #Text(x);
      case (#Map(x)) {
        let buf = Buffer.Buffer<(Text, ValueShared)>(1);
        for (thisItem in x.vals()) {
          switch (thisItem.0) {
            case (#Text(x)) buf.add((x, candySharedToValue(thisItem.1)));
            case (_) {};
          };
        };
        #Map(Buffer.toArray(buf));
      };
      case (#Class(x)) {
        let buf = Buffer.Buffer<(Text, ValueShared)>(1);
        for (thisItem in x.vals()) {
          buf.add((thisItem.name, candySharedToValue(thisItem.value)));
        };
        #Map(Buffer.toArray(buf));
      };
      case (#Int(x)) #Int(x);
      case (#Int8(x)) #Int(Int8.toInt(x));
      case (#Int16(x)) #Int(Int16.toInt(x));
      case (#Int32(x)) #Int(Int32.toInt(x));
      case (#Int64(x)) #Int(Int64.toInt(x));
      case (#Ints(x)) {
        #Array(Array.map<Int, ValueShared>(x, func(x : Int) : ValueShared { #Int(x) }));
      };
      case (#Nat(x)) #Nat(x);
      case (#Nat8(x)) #Nat(Nat8.toNat(x));
      case (#Nat16(x)) #Nat(Nat16.toNat(x));
      case (#Nat32(x)) #Nat(Nat32.toNat(x));
      case (#Nat64(x)) #Nat(Nat64.toNat(x));
      case (#Nats(x)) {
        #Array(Array.map<Nat, ValueShared>(x, func(x : Nat) : ValueShared { #Nat(x) }));
      };
      case (#Bytes(x)) {
        #Blob(Blob.fromArray(x));
      };
      case (#Array(x)) {
        #Array(Array.map<CandyTypes.CandyShared, ValueShared>(x, candySharedToValue));
      };
      case (#Blob(x)) #Blob(x);
      case (#Bool(x)) #Blob(Blob.fromArray([if (x == true) { 1 : Nat8 } else { 0 : Nat8 }]));
      case (#Float(x)) { #Text(Float.format(#exact, x)) };
      case (#Floats(x)) {
        #Array(Array.map<Float, ValueShared>(x, func(x : Float) : ValueShared { candySharedToValue(#Float(x)) }));
      };
      case (#Option(x)) {
        //empty array is null
        switch (x) {
          case (null) #Array([]);
          case (?x) #Array([candySharedToValue(x)]);
        };
      };
      case (#Principal(x)) {
        #Blob(Principal.toBlob(x));
      };
      case (#Set(x)) {
        #Array(
          Array.map<CandyTypes.CandyShared, ValueShared>(x, func(x : CandyTypes.CandyShared) : ValueShared { candySharedToValue(x) })
        );
      };
      /* case(#ValueMap(x)) {
        #Array(Array.map<(CandyShared,CandyShared),ValueShared>(x, func(x: (CandyShared,CandyShared)) : ValueShared { #Array([candySharedToValue(x.0), candySharedToValue(x.1)])}));
      }; */
      //case(_){assert(false);/*unreachable*/#Nat(0);};
    };

  };

  public let defaultICRC3Config = func(caller : Principal) : ICRC3.InitArgs {
    ?{
      maxActiveRecords = 4000;
      settleToRecords = 2000;
      maxRecordsInArchiveInstance = 1_000_000;
      maxArchivePages = 62500; //allows up to 993 bytes per record
      archiveIndexType = #Stable;
      maxRecordsToArchive = 10_000;
      archiveCycles = 6_000_000_000_000; //six trillion
      archiveControllers = ??[
        caller,
        Principal.fromText("5vdms-kaaaa-aaaap-aa3uq-cai"), //blackhole for cycleops
      ];
      supportedBlocks = [];
    };
  };

  public type State = {
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
    var fee_deposit_balances : FeeDepositTrie;
    var nft_ledgers : Map.Map<Text, SB.StableBuffer<TransactionRecord>>;
    var master_ledger : SB.StableBuffer<TransactionRecord>;
    var nft_sales : Map.Map<Text, SaleStatus>;
    var pending_sale_notifications : Set.Set<Text>;
    var access_tokens : Map.Map<Text, HttpAccess>;
    var droute : Droute.Droute;
    var kyc_cache : Map.Map<KYCTypes.KYCRequest, KYCTypes.KYCResultFuture>;
    var use_stableBTree : Bool;
    var icrc3_migration_state : ICRC3.State;
    var cert_store : CertTree.Store;
    var timerState : ?TimerTool.State;
    //add certification type here

  };

  public let OGY_LEDGER_CANISTER_ID = "lkwrt-vyaaa-aaaaq-aadhq-cai"; // production
  // public let OGY_LEDGER_CANISTER_ID = "j5naj-nqaaa-aaaal-ajc7q-cai"; // staging

  public func OGY() : TokenSpec {
    #ic({
      canister = Principal.fromText(OGY_LEDGER_CANISTER_ID);
      fee = ?200_000;
      symbol = "OGY";
      decimals = 8;
      id = null;
      standard = #Ledger;
    });
  };

  public func MAX_NAT() : Nat {
    return Nat.bitshiftLeft(1, 1024);
  };
};
