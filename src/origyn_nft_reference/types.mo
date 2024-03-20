import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";

import AccountIdentifier "mo:principalmo/AccountIdentifier";

import Map "mo:map/Map";
import MapUtils "mo:map/utils";
import StableBTreeTypes "mo:stableBTree/types";
import hex "mo:encoding/Hex";

import DIP721 "DIP721";
import MigrationTypes "./migrations/types";
import StorageMigrationTypes "./migrations_storage/types";
import DROUTE "mo:droute_client/Droute";
import KYC "mo:icrc17_kyc";
import CanistergeekTypes "mo:canistergeek/canistergeek";
import http "mo:http/Http";

import Star "mo:star/star";

module {

  let CandyTypes = MigrationTypes.Current.CandyTypes;
  let Conversions = MigrationTypes.Current.Conversions;
  let SB = MigrationTypes.Current.SB;
  //let Properties = MigrationTypes.Current.Properties;
  //let Workspace = MigrationTypes.Current.Workspace;

  public func __candid_keys() : [Text] {
    [
      //InitArgs
      "owner",
      "storage_space",

      //StorageInitArgs
      "gateway_canister",
      "network",
      "storage_space",

      //StorageMigrationArgs
      "gateway_canister",
      "network",
      "storage_space",
      "caller",

      //ManageCollectionCommand
      "UpdateManagers",
      "UpdateOwner",
      "UpdateNetwork",
      "UpdateAnnounceCanister",
      "UpdateLogo",
      "UpdateName",
      "UpdateSymbol",
      "UpdateMetadata",

      //...etc
    ];
  };

  public type StorageInitArgs = {
    gateway_canister : Principal;
    network : ?Principal;
    storage_space : ?Nat;
  };

  public type StorageMigrationArgs = {
    gateway_canister : Principal;
    network : ?Principal;
    storage_space : ?Nat;
    caller : Principal;
  };

  public type ManageCollectionCommand = {
    #UpdateManagers : [Principal];
    #UpdateOwner : Principal;
    #UpdateNetwork : ?Principal;
    #UpdateAnnounceCanister : ?Principal;
    #UpdateLogo : ?Text;
    #UpdateName : ?Text;
    #UpdateSymbol : ?Text;
    #UpdateMetadata : (Text, ?CandyTypes.CandyShared, Bool);
  };

  // RawData type is a tuple of Timestamp, Data, and Principal
  public type RawData = (Int, Blob, Principal);

  public type HttpRequest = {
    body : Blob;
    headers : [http.HeaderField];
    method : Text;
    url : Text;
  };

  public type StreamingCallbackToken = {
    content_encoding : Text;
    index : Nat;
    key : Text;
    //sha256: ?Blob;
  };
  public type StreamingCallbackHttpResponse = {
    body : Blob;
    token : ?StreamingCallbackToken;
  };
  public type ChunkId = Nat;
  public type SetAssetContentArguments = {
    chunk_ids : [ChunkId];
    content_encoding : Text;
    key : Key;
    sha256 : ?Blob;
  };
  public type Path = Text;
  public type Key = Text;

  public type HttpResponse = {
    body : Blob;
    headers : [http.HeaderField];
    status_code : Nat16;
    streaming_strategy : ?StreamingStrategy;
  };

  public type StreamingStrategy = {
    #Callback : {
      callback : shared () -> async ();
      token : StreamingCallbackToken;
    };
  };

  public type canister_id = Principal;

  public type definite_canister_settings = {
    freezing_threshold : Nat;
    controllers : ?[Principal];
    memory_allocation : Nat;
    compute_allocation : Nat;
  };

  public type canister_status = {
    status : { #stopped; #stopping; #running };
    memory_size : Nat;
    cycles : Nat;
    settings : definite_canister_settings;
    module_hash : ?[Nat8];
  };

  public type IC = actor {
    canister_status : { canister_id : canister_id } -> async canister_status;
  };

  public type Subscriber = actor {
    notify_sale_nft_origyn : shared (SubscriberNotification) -> ();
  };

  public type SubscriberNotification = {
    escrow_info : SubAccountInfo;
    sale : SaleStatusShared;
    seller : Account;
    collection : Principal;
  };

  public type StageChunkArg = {
    token_id : Text;
    library_id : Text;
    filedata : CandyTypes.CandyShared; //may need to be nullable
    chunk : Nat; //2MB Chunks
    content : Blob;
  };

  public type ChunkRequest = {
    token_id : Text;
    library_id : Text;
    chunk : ?Nat;
  };

  public type ChunkContent = {
    #remote : {
      canister : Principal;
      args : ChunkRequest;
    };
    #chunk : {
      content : Blob;
      total_chunks : Nat;
      current_chunk : ?Nat;
      storage_allocation : AllocationRecordStable;
    };
  };

  public type MarketTransferRequest = MigrationTypes.Current.MarketTransferRequest;

  public type OwnerTransferResponse = {
    transaction : TransactionRecord;
    assets : [CandyTypes.CandyShared];
  };

  public type ShareWalletRequest = {
    token_id : Text;
    from : Account;
    to : Account;
  };

  public type SalesConfig = MigrationTypes.Current.SalesConfig;

  public type ICTokenSpec = {
    canister : Principal;
    fee : ?Nat;
    symbol : Text;
    decimals : Nat;
    id : ?Nat;
    standard : {
      #DIP20;
      #Ledger;
      #EXTFungible;
      #ICRC1; //use #Ledger instead
      #Other : CandyTypes.CandyShared;
    };
  };

  public type TokenSpec = {
    #ic : ICTokenSpec;
    #extensible : CandyTypes.CandyShared; //#Class
  };

  public let TokenSpecDefault = #extensible(#Option(null));
  public let Canistergeek = CanistergeekTypes;

  //nyi: anywhere a deposit address is used, check blob for size in inspect message
  public type SubAccountInfo = {
    principal : Principal;
    account_id : Blob;
    account_id_text : Text;
    account : {
      principal : Principal;
      sub_account : Blob;
    };
  };

  public type EscrowReceipt = MigrationTypes.Current.EscrowReceipt;

  public type EscrowRequest = {
    token_id : Text; //empty string for general escrow
    deposit : DepositDetail;
    lock_to_date : ?Int; //timestamp to lock escrow until.
  };

  public type FeeDepositRequest = {
    account : Account;
    token : TokenSpec;
  };

  public type DepositDetail = {
    token : TokenSpec;
    seller : Account;
    buyer : Account;
    amount : Nat; //Nat to support cycles;
    sale_id : ?Text;
    trx_id : ?TransactionID; //null for account based ledgers
  };

  //used to identify the transaction in a remote ledger; usually a nat on the IC
  public type TransactionID = {
    #nat : Nat;
    #text : Text;
    #extensible : CandyTypes.CandyShared;
  };

  public type EscrowResponse = {
    receipt : EscrowReceipt;
    balance : Nat;
    transaction : TransactionRecord;
  };

  public type FeeDepositResponse = {
    balance : Nat;
    transaction : TransactionRecord;
  };

  public type RecognizeEscrowResponse = {
    receipt : EscrowReceipt;
    balance : Nat;
    transaction : ?TransactionRecord;
  };

  public type BidRequest = {
    escrow_receipt : EscrowReceipt;
    sale_id : Text;
    broker_id : ?Principal;
  };

  public type DistributeSaleRequest = {
    seller : ?Account;
  };

  public type DistributeSaleResponse = [Result.Result<ManageSaleResponse, OrigynError>];

  public type AskSubscribeResponse = Bool;

  public type BidResponse = TransactionRecord;

  public type PricingConfig = MigrationTypes.Current.PricingConfig;

  public type PricingConfigShared = MigrationTypes.Current.PricingConfigShared;

  public type AskConfig = ?[AskFeature];
  public type AskConfigShared = MigrationTypes.Current.AskConfigShared;
  public type DutchParams = MigrationTypes.Current.DutchParams;

  public type AskFeature = MigrationTypes.Current.AskFeature;

  public type NiftyConfig = {
    duration : ?Int;
    expiration : ?Int;
    fixed : Bool;
    lenderOffer : Bool;
    amount : Nat;
    interestRatePerSecond : Float;
    token : TokenSpec;
  };

  public type AuctionConfig = MigrationTypes.Current.AuctionConfig;

  public let AuctionConfigDefault = {
    reserve = null;
    token = TokenSpecDefault;
    buy_now = null;
    start_price = 0;
    start_date = 0;
    ending = #date(0);
    min_increase = #amount(0);
  };

  public type NFTInfoStable = {
    current_sale : ?SaleStatusShared;
    metadata : CandyTypes.CandyShared;
  };

  public type AuctionStateShared = {
    config : PricingConfigShared;
    current_bid_amount : Nat;
    current_broker_id : ?Principal;
    end_date : Int;
    start_date : Int;
    min_next_bid : Nat;
    token : TokenSpec;
    current_escrow : ?EscrowReceipt;
    wait_for_quiet_count : ?Nat;
    allow_list : ?[(Principal, Bool)]; // user, tree
    participants : [(Principal, Int)]; //user, timestamp of last access
    status : {
      #open;
      #closed;
      #not_started;
    };
    winner : ?Account;
  };

  public func AuctionState_stabalize_for_xfer(val : AuctionState) : AuctionStateShared {
    {
      config = switch (val.config) {
        case (#instant) #instant;
        case (#auction(e)) #auction(e);
        case (#ask(e)) {
          switch (e) {
            case (null) #ask(null);
            case (?items) {
              #ask(?(Iter.toArray<AskFeature>(Map.vals(items))));
            };
          };
        };
        case (#extensible(e)) #extensible(e);
      };
      current_bid_amount = val.current_bid_amount;
      current_broker_id = val.current_broker_id;
      end_date = val.end_date;
      start_date = val.start_date;
      token = val.token;
      min_next_bid = val.min_next_bid;
      current_escrow = val.current_escrow;
      wait_for_quiet_count = val.wait_for_quiet_count;
      allow_list = do ? {
        Iter.toArray(Map.entries<Principal, Bool>(val.allow_list!));
      };
      participants = Iter.toArray(Map.entries<Principal, Int>(val.participants));
      status = val.status;
      winner = val.winner;
    };
  };

  public type SaleStatusShared = {
    sale_id : Text; //sha256?;
    original_broker_id : ?Principal;
    broker_id : ?Principal;
    token_id : Text;
    sale_type : {
      #auction : AuctionStateShared;
    };
  };

  public func SalesStatus_stabalize_for_xfer(item : SaleStatus) : SaleStatusShared {
    {
      sale_id = item.sale_id;
      token_id = item.token_id;
      broker_id = item.broker_id;
      original_broker_id = item.original_broker_id;
      sale_type = switch (item.sale_type) {
        case (#auction(val)) {
          #auction(AuctionState_stabalize_for_xfer(val));
        };
      };
    };
  };

  public type MarketTransferRequestReponse = TransactionRecord;

  public type Account = MigrationTypes.Current.Account;

  /*
    public type Stable_Memory = {
      _1 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
      _4 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
      _16 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
      _64 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
      _256 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
      _1024 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
      //_2048 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
    };
    */

  public type State = State_v0_1_6;

  public type State_v0_1_6 = {
    state : GatewayState;
    canister : () -> Principal;
    get_time : () -> Int;
    nft_library : TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>>;
    refresh_state : () -> State;
    droute_client : DROUTE.Droute;
    kyc_client : KYC.kyc;
    canistergeekLogger : Canistergeek.Logger;
    handle_notify : () -> async ();
    notify_timer : {
      get : () -> ?Nat;
      set : (?Nat) -> ();
    };
    //btreemap : Stable_Memory;
  };

  public type BucketDat = {
    principal : Principal;
    allocated_space : Nat;
    available_space : Nat;
    date_added : Int;
    b_gateway : Bool;
    version : (Nat, Nat, Nat);
    // allocations: [((Text, Text), Int)]
    allocations : Map.Map<(Text, Text), Int>;
  };

  public type StableCollectionData = {
    logo : ?Text;
    name : ?Text;
    symbol : ?Text;
    metadata : ?CandyTypes.CandyShared;
    owner : Principal;
    managers : [Principal];
    network : ?Principal;
    allocated_storage : Nat;
    available_space : Nat;
    active_bucket : ?Principal;
  };

  public func stabilize_collection_data(item : CollectionData) : StableCollectionData {
    {
      logo = item.logo;
      name = item.name;
      symbol = item.symbol;
      metadata = item.metadata;
      owner = item.owner;
      managers = item.managers;
      network = item.network;
      allocated_storage = item.allocated_storage;
      available_space = item.available_space;
      active_bucket = item.active_bucket;
    };
  };

  public type StableBucketData = {
    principal : Principal;
    allocated_space : Nat;
    available_space : Nat;
    date_added : Int;
    b_gateway : Bool;
    version : (Nat, Nat, Nat);
    allocations : [((Text, Text), Int)];
  };

  public func stabilize_bucket_data(item : BucketData) : StableBucketData {
    {
      principal = item.principal;
      allocated_space = item.allocated_space;
      available_space = item.available_space;
      date_added = item.date_added;
      b_gateway = item.b_gateway;
      version = item.version;
      allocations = Iter.toArray(Map.entries<(Text, Text), Int>(item.allocations));
    };
  };

  public type StableEscrowBalances = [(Account, Account, Text, EscrowRecord)];
  public type StableSalesBalances = [(Account, Account, Text, EscrowRecord)];
  public type StableOffers = [(Account, Account, Int)];
  public type StableNftLedger = [(Text, TransactionRecord)];
  public type StableNftSales = [(Text, SaleStatusShared)];

  public type NFTBackupChunk = {
    canister : Principal;
    collection_data : StableCollectionData;
    buckets : [(Principal, StableBucketData)];
    allocations : [((Text, Text), AllocationRecordStable)];
    escrow_balances : StableEscrowBalances;
    sales_balances : StableSalesBalances;
    offers : StableOffers;
    nft_ledgers : StableNftLedger;
    nft_sales : [(Text, SaleStatusShared)];
  };

  public type StateSize = {
    buckets : Nat;
    allocations : Nat;
    escrow_balances : Nat;
    sales_balances : Nat;
    offers : Nat;
    nft_ledgers : Nat;
    nft_sales : Nat;
  };

  public type GatewayState = GatewayState_v0_1_6;

  public type StorageState = StorageState_v_0_1_5;

  public type StorageState_v_0_1_5 = {
    var state : StorageMigrationTypes.Current.State;
    canister : () -> Principal;
    get_time : () -> Int;
    var nft_library : TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>>;
    refresh_state : () -> StorageState_v_0_1_5;
    //btreemap_storage : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
    use_stable_storage : Bool;
  };

  public type StorageMetrics = {
    allocated_storage : Nat;
    available_space : Nat;
    allocations : [AllocationRecordStable];
    gateway : Principal;

  };

  public type BucketData = {
    principal : Principal;
    var allocated_space : Nat;
    var available_space : Nat;
    date_added : Int;
    b_gateway : Bool;
    var version : (Nat, Nat, Nat);
    var allocations : Map.Map<(Text, Text), Int>; // (token_id, library_id), Timestamp
  };

  public type AllocationRecord = {
    canister : Principal;
    allocated_space : Nat;
    var available_space : Nat;
    var chunks : SB.StableBuffer<Nat>;
    token_id : Text;
    library_id : Text;
  };

  public type AllocationRecordStable = {
    canister : Principal;
    allocated_space : Nat;
    available_space : Nat;
    chunks : [Nat];
    token_id : Text;
    library_id : Text;
  };

  public func allocation_record_stabalize(item : AllocationRecord) : AllocationRecordStable {
    {
      canister = item.canister;
      allocated_space = item.allocated_space;
      available_space = item.available_space;
      chunks = SB.toArray<Nat>(item.chunks);
      token_id = item.token_id;
      library_id = item.library_id;
    };
  };

  public type TransactionRecord = MigrationTypes.Current.TransactionRecord;

  public type NFTUpdateRequest = {
    #replace : {
      token_id : Text;
      data : CandyTypes.CandyShared;
    };
    #update : {
      token_id : Text;
      app_id : Text;
      update : CandyTypes.UpdateRequestShared;

    };
  };

  public type NFTUpdateResponse = Bool;

  public type EndSaleResponse = TransactionRecord;

  public type EscrowRecord = {
    amount : Nat;
    buyer : Account;
    seller : Account;
    token_id : Text;
    token : TokenSpec;
    sale_id : ?Text; //locks the escrow to a specific sale
    lock_to_date : ?Int; //locks the escrow to a timestamp
    account_hash : ?Blob; //sub account the host holds the funds in
  };

  public type ManageSaleRequest = {
    #end_sale : Text; //token_id
    #open_sale : Text; //token_id;
    #escrow_deposit : EscrowRequest;
    #fee_deposit : FeeDepositRequest;
    #recognize_escrow : EscrowRequest;
    #refresh_offers : ?Account;
    #bid : BidRequest;
    #withdraw : WithdrawRequest;
    #distribute_sale : DistributeSaleRequest;
    #ask_subscribe : AskSubscribeRequest;
  };

  public type AskSubscribeRequest = {
    #subscribe : {
      filter : ?{
        token_ids : ?[TokenIDFilter];
        tokens : ?[TokenSpecFilter];
      };
      stake : (Principal, Nat);
    };
    #unsubscribe : (Principal, Nat);
  };

  public type TokenIDFilter = {
    token_id : Text;
    tokens : [{
      min_amount : ?Nat;
      max_amount : ?Nat;
      token : TokenSpec;
    }];
    filter_type : {
      #allow;
      #block;
    };
  };

  public type TokenSpecFilter = {
    token : TokenSpec;
    filter_type : {
      #allow;
      #block;
    };
  };

  public type ManageSaleResponse = {
    #end_sale : EndSaleResponse; //trx record if succesful
    #open_sale : Bool; //true if opened, false if not;
    #escrow_deposit : EscrowResponse;
    #fee_deposit : FeeDepositResponse;
    #recognize_escrow : RecognizeEscrowResponse;
    #refresh_offers : [EscrowRecord];
    #bid : BidResponse;
    #withdraw : WithdrawResponse;
    #distribute_sale : DistributeSaleResponse;
    #ask_subscribe : AskSubscribeResponse;
  };

  public type SaleInfoRequest = {
    #active : ?(Nat, Nat); //get al list of active sales
    #history : ?(Nat, Nat); //skip, take
    #status : Text; //saleID
    #escrow_info : EscrowReceipt;
    #fee_deposit_info : ?Account;
    #deposit_info : ?Account;
  };

  public type SaleInfoResponse = {
    #active : {
      records : [(Text, ?SaleStatusShared)];
      eof : Bool;
      count : Nat;
    };
    #history : {
      records : [?SaleStatusShared];
      eof : Bool;
      count : Nat;
    };
    #status : ?SaleStatusShared;
    #deposit_info : SubAccountInfo;
    #escrow_info : SubAccountInfo;
    #fee_deposit_info : SubAccountInfo;
  };

  public type GovernanceRequest = {
    #clear_shared_wallets : Text; //token_id of shared wallets to clear
    #update_system_var : {
      token_id : Text;
      key : Text;
      val : CandyTypes.CandyShared;
    };
  };

  public type GovernanceResponse = {
    #clear_shared_wallets : Bool; //result
    #update_system_var : Bool; //result

  };

  public type StakeRecord = {
    amount : Nat;
    staker : Account;
    token_id : Text;
  };

  public type BalanceResponse = {
    multi_canister : ?[Principal];
    nfts : [Text];
    escrow : [EscrowRecord];
    sales : [EscrowRecord];
    stake : [StakeRecord];
    offers : [EscrowRecord];
  };

  public type LocalStageLibraryResponse = {
    #stage_remote : {
      allocation : AllocationRecord;
      metadata : CandyTypes.CandyShared;
    };
    #staged : Principal;
  };

  public type StageLibraryResponse = {
    canister : Principal;
  };

  public type WithdrawDescription = {
    buyer : Account;
    seller : Account;
    token_id : Text;
    token : TokenSpec;
    amount : Nat;
    withdraw_to : Account;
  };

  public type DepositWithdrawDescription = {
    buyer : Account;
    token : TokenSpec;
    amount : Nat;
    withdraw_to : Account;
  };

  public type FeeDepositWithdrawDescription = {
    account : Account;
    token : TokenSpec;
    amount : Nat;
    withdraw_to : Account;
    status : {
      #unlocked;
      #locked : {
        sale_id : Text;
      };
    };
  };

  public type RejectDescription = {
    buyer : Account;
    seller : Account;
    token_id : Text;
    token : TokenSpec;
  };

  public type WithdrawRequest = {
    #escrow : WithdrawDescription;
    #sale : WithdrawDescription;
    #reject : RejectDescription;
    #deposit : DepositWithdrawDescription;
    #fee_deposit : FeeDepositWithdrawDescription;
  };

  public type WithdrawResponse = TransactionRecord;

  public type CollectionInfo = {
    fields : ?[(Text, ?Nat, ?Nat)];
    logo : ?Text;
    name : ?Text;
    symbol : ?Text;
    total_supply : ?Nat;
    owner : ?Principal;
    managers : ?[Principal];
    network : ?Principal;
    token_ids : ?[Text];
    token_ids_count : ?Nat;
    multi_canister : ?[Principal];
    multi_canister_count : ?Nat;
    metadata : ?CandyTypes.CandyShared;
    allocated_storage : ?Nat;
    available_space : ?Nat;
    created_at : ?Nat64;
    upgraded_at : ?Nat64;
    unique_holders : ?Nat;
    transaction_count : ?Nat;
  };

  public type CollectionData = {
    var logo : ?Text;
    var name : ?Text;
    var symbol : ?Text;
    var metadata : ?CandyTypes.CandyShared;
    var owner : Principal;
    var managers : [Principal];
    var network : ?Principal;
    var allocated_storage : Nat;
    var available_space : Nat;
    var active_bucket : ?Principal;
  };

  public type CollectionDataForStorage = {

    var owner : Principal;
    var managers : [Principal];
    var network : ?Principal;

  };

  public type ManageStorageRequest = {
    #add_storage_canisters : [(Principal, Nat, (Nat, Nat, Nat))];
    #configure_storage : {
      #heap : ?Nat;
      #stableBtree : ?Nat;
    };
  };

  public type ManageStorageResponse = {
    #add_storage_canisters : (Nat, Nat); //space allocated, space available
    #configure_storage : (Nat, Nat); //space allocated, space available
  };

  public type LogEntry = {
    event : Text;
    timestamp : Int;
    data : CandyTypes.CandyShared;
    caller : ?Principal;
  };

  public type OrigynError = {
    number : Nat32;
    text : Text;
    error : Errors;
    flag_point : Text;
  };

  public type UpdateAppResponse = Result.Result<NFTUpdateResponse, OrigynError>;

  public type Errors = {
    #app_id_not_found;
    #asset_mismatch;
    #attempt_to_stage_system_data;
    #auction_ended;
    #auction_not_started;
    #bid_too_low;
    #cannot_find_status_in_metadata;
    #cannot_restage_minted_token;
    #content_not_deserializable;
    #content_not_found;
    #deposit_burned;
    #escrow_cannot_be_removed;
    #escrow_owner_not_the_owner;
    #escrow_withdraw_payment_failed;
    #escrow_not_large_enough;
    #existing_sale_found;
    #id_not_found_in_metadata;
    #improper_interface;
    #item_already_minted;
    #item_not_owned;
    #library_not_found;
    #malformed_metadata;
    #no_escrow_found;
    #not_enough_storage;
    #out_of_range;
    #owner_not_found;
    #property_not_found;
    #receipt_data_mismatch;
    #sale_not_found;
    #sale_not_over;
    #sale_id_does_not_match;
    #sales_withdraw_payment_failed;
    #storage_configuration_error;
    #token_not_found;
    #token_id_mismatch;
    #token_non_transferable;
    #unauthorized_access;
    #unreachable;
    #update_class_error;
    #validate_deposit_failed;
    #validate_deposit_wrong_amount;
    #validate_deposit_wrong_buyer;
    #validate_trx_wrong_host;
    #withdraw_too_large;
    #nyi;
    #noop;
    #kyc_error;
    #kyc_fail;
    #low_fee_balance;
  };

  public func errors(logger : ?Canistergeek.Logger, the_error : Errors, flag_point : Text, caller : ?Principal) : OrigynError {

    switch (logger) {
      case (null) {};
      case (?logger) {
        let log_data = "Type : error, flag_point :  " # flag_point # debug_show ((the_error, caller));
        logger.logMessage("Error", #Text(log_data), caller);
      };
    };

    switch (the_error) {
      case (#id_not_found_in_metadata) {
        return {
          number = 1;
          text = "id was not found in the metadata. id is required.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;

        };
      };
      case (#attempt_to_stage_system_data) {
        return {
          number = 2;
          text = "user attempted to set the __system metadata during staging.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#cannot_find_status_in_metadata) {
        return {
          number = 3;
          text = "Cannot find __system.status in metadata. It was expected to be there.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#token_not_found) {
        return {
          number = 4;
          text = "Cannot find token.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#library_not_found) {
        return {
          number = 5;
          text = "Cannot find library.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };

      case (#content_not_found) {
        return {
          number = 6;
          text = "Cannot find chunk.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#content_not_deserializable) {
        return {
          number = 7;
          text = "Cannot deserialize chunk.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#cannot_restage_minted_token) {
        return {
          number = 8;
          text = "Cannot restage minted token.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#owner_not_found) {
        return {
          number = 9;
          text = "Cannot find owner.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#item_already_minted) {
        return {
          number = 10;
          text = "Already minted.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#item_not_owned) {
        return {
          number = 11;
          text = "Account does not own this item.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#app_id_not_found) {
        return {
          number = 12;
          text = "App id not found in app node.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#existing_sale_found) {
        return {
          number = 13;
          text = "A sale for this item is already underway.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#out_of_range) {
        return {
          number = 14;
          text = "out of rang.";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#property_not_found) {
        return {
          number = 15;
          text = "property not found";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };

      //1000s - Error with underlying system
      case (#update_class_error) {
        return {
          number = 1000;
          text = "class could not be updated";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      //
      case (#nyi) {
        return {
          number = 1999;
          text = "not yet implemented";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#noop) {
        return {
          number = 1997;
          text = "not yet implemented";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };

      case (#unreachable) {
        return {
          number = 1998;
          text = "no op";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#not_enough_storage) {
        return {
          number = 1001;
          text = "not enough storage";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#malformed_metadata) {
        return {
          number = 1002;
          text = "malformed metadata";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };

      };
      case (#storage_configuration_error) {
        return {
          number = 1003;
          text = "storage configuration error";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      //2000s - access
      case (#unauthorized_access) {
        return {
          number = 2000;
          text = "unauthorized access";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      //3000 - escrow erros
      case (#no_escrow_found) {
        return {
          number = 3000;
          text = "no escrow found";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };

      case (#deposit_burned) {
        return {
          number = 3001;
          text = "deposit has already been burned";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };

      case (#escrow_owner_not_the_owner) {
        return {
          number = 3002;
          text = "the owner in the escrow request does not own the item";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };

      case (#validate_deposit_failed) {
        return {
          number = 3003;
          text = "validate deposit failed";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#validate_trx_wrong_host) {
        return {
          number = 3004;
          text = "validate deposit failed - wrong host";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#validate_deposit_wrong_amount) {
        return {
          number = 3005;
          text = "validate deposit failed - wrong amount";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#validate_deposit_wrong_buyer) {
        return {
          number = 3006;
          text = "validate deposit failed - wrong buyer";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#withdraw_too_large) {
        return {
          number = 3007;
          text = "withdraw too large";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#escrow_cannot_be_removed) {
        return {
          number = 3008;
          text = "escrow  cannot be removed";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#escrow_withdraw_payment_failed) {
        return {
          number = 3009;
          text = "could not pay the escrow";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#sales_withdraw_payment_failed) {
        return {
          number = 3010;
          text = "could not pay the sales withdraw";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#escrow_not_large_enough) {
        return {
          number = 3011;
          text = "the balance in the escrow is not large enough for the escrow required";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };

      case (#improper_interface) {
        return {
          number = 3800;
          text = "improper interface";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };

      //auction errors
      case (#sale_not_found) {
        return {
          number = 4000;
          text = "sale not found";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#receipt_data_mismatch) {
        return {
          number = 4001;
          text = "receipt_data_mismatch";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#asset_mismatch) {
        return {
          number = 4002;
          text = "asset mismatch";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#token_id_mismatch) {
        return {
          number = 4003;
          text = "token ids do not match";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#bid_too_low) {
        return {
          number = 4004;
          text = "bid too low";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#sale_id_does_not_match) {
        return {
          number = 4005;
          text = "sale not found";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#auction_ended) {
        return {
          number = 4006;
          text = "auction has ended";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#sale_not_over) {
        return {
          number = 4007;
          text = "sale not over";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#auction_not_started) {
        return {
          number = 4008;
          text = "sale not started";
          error = the_error;
          flag_point = flag_point;
          caller = caller;
        };
      };
      case (#token_non_transferable) {
        return {
          number = 4009;
          text = "token is non-transferable";
          error = the_error;
          flag_point = flag_point;
        };
      };
      case (#kyc_error) {
        return {
          number = 4010;
          text = "kyc error";
          error = the_error;
          flag_point = flag_point;
        };
      };
      case (#kyc_fail) {
        return {
          number = 4011;
          text = "kyc fail";
          error = the_error;
          flag_point = flag_point;
        };
      };
      case (#low_fee_balance) {
        return {
          number = 4012;
          text = "low_fee_balance";
          error = the_error;
          flag_point = flag_point;
        };
      };
    };
  };

  public let nft_status_staged = "staged";
  public let nft_status_minted = "minted";

  public let metadata : {
    __system : Text;
    __system_status : Text;
    __system_secondary_royalty : Text;
    __system_primary_royalty : Text;
    __system_fixed_royalty : Text;
    __system_node : Text;
    __system_originator : Text;
    __system_wallet_shares : Text;
    __system_physical : Text;
    __system_escrowed : Text;
    __apps : Text;
    broker_royalty_dev_fund_override : Text;
    collection_kyc_canister_buyer : Text;
    collection_kyc_canister_seller : Text;
    library : Text;
    library_id : Text;
    library_size : Text;
    library_location_type : Text;
    owner : Text;
    id : Text;
    kyc_collection : Text;
    primary_asset : Text;
    preview_asset : Text;
    experience_asset : Text;
    hidden_asset : Text;
    is_soulbound : Text;
    immutable_library : Text;
    physical : Text;
    primary_host : Text;
    primary_port : Text;
    primary_protocol : Text;
    primary_royalties_default : Text;
    fixed_royalties_default : Text;

    originator_override : Text;
    royalty_broker : Text;
    royalty_node : Text;
    royalty_originator : Text;
    royalty_network : Text;
    royalty_custom : Text;
    secondary_royalties_default : Text;
    icrc7_description : Text;

    __apps_app_id : Text;
    __system_current_sale_id : Text;
  } = {
    __system = "__system";
    __system_status = "status";
    __system_secondary_royalty = "com.origyn.royalties.secondary";
    __system_primary_royalty = "com.origyn.royalties.primary";
    __system_fixed_royalty = "com.origyn.royalties.fixed";
    __system_node = "com.origyn.node";
    __system_originator = "com.origyn.originator";
    __system_wallet_shares = "com.origyn.wallet_shares";
    __system_physical = "com.origyn.physical";
    __system_escrowed = "com.origyn.escrow_node";
    __apps = "__apps";
    broker_royalty_dev_fund_override = "com.origyn.royalties.broker_dev_fund_override";
    collection_kyc_canister_buyer = "com.origyn.kyc_canister_buyer";
    collection_kyc_canister_seller = "com.origyn.kyc_canister_seller";
    library = "library";
    library_id = "library_id";
    library_size = "size";
    library_location_type = "location_type";
    owner = "owner";
    id = "id";
    immutable_library = "com.origyn.immutable_library";
    kyc_collection = "com.origyn.settings.collection.kyc_canister";
    physical = "com.origyn.physical";
    primary_asset = "primary_asset";
    preview_asset = "preview_asset";
    primary_royalties_default = "com.origyn.royalties.primary.default";
    secondary_royalties_default = "com.origyn.royalties.secondary.default";
    fixed_royalties_default = "com.origyn.royalties.fixed.default";
    hidden_asset = "hidden_asset";
    is_soulbound = "is_soulbound";
    primary_host = "primary_host";
    primary_port = "primary_port";
    primary_protocol = "primary_protocol";
    originator_override = "com.origyn.originator.override";
    royalty_broker = "com.origyn.royalty.broker";
    royalty_node = "com.origyn.royalty.node";
    royalty_originator = "com.origyn.royalty.originator";
    royalty_network = "com.origyn.royalty.network";
    royalty_custom = "com.origyn.royalty.custom";
    experience_asset = "experience_asset";
    icrc7_description = "com.origyn.icrc7.description";
    __apps_app_id = "app_id";
    __system_current_sale_id = "current_sale_id";
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

  public func token_compare(a : TokenSpec, b : TokenSpec) : Order.Order {
    /* #ic: {
            canister: Principal;
            standard: {
                #DIP20;
                #Ledger;
                #ICRC1;
                #EXTFungible;
            };
        };
        #extensible : CandyTypes.CandyShared; //#Class*/
    switch (a, b) {
      case (#ic(a_token), #ic(b_token)) {
        return Principal.compare(a_token.canister, b_token.canister);
      };
      case (#extensible(a_token), #ic(b_token)) {
        return Text.compare(Conversions.candySharedToText(a_token), Principal.toText(b_token.canister));
      };
      case (#ic(a_token), #extensible(b_token)) {
        return Text.compare(Principal.toText(a_token.canister), Conversions.candySharedToText(b_token));
      };
      case (#extensible(a_token), #extensible(b_token)) {
        return Text.compare(Conversions.candySharedToText(a_token), Conversions.candySharedToText(b_token));
      };
    };
  };

  public func token_eq(a : TokenSpec, b : TokenSpec) : Bool {
    /* #ic: {
            canister: Principal;
            standard: {
                #DIP20;
                #Ledger;
                #EXTFungible;
                #ICRC1;
            };
        };
        #extensible : CandyTypes.CandyShared; //#Class*/
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

  public func account_hash(a : Account) : Nat {
    switch (a) {
      case (#principal(a_principal)) {
        Nat32.toNat(Principal.hash(a_principal));
      };
      case (#account_id(a_account_id)) {
        Nat32.toNat(Text.hash(a_account_id));

      };
      case (#account(a_account)) {
        Nat32.toNat(Text.hash(AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_account.owner, switch (a_account.sub_account) { case (null) { null }; case (?val) { ?Blob.toArray(val) } }))));

      };
      case (#extensible(a_extensible)) {
        //unimplemnted; unsafe; probably dont use
        //until a reliable valueToHash function is written
        //if any redenring of classes changes the whole hash
        //will change
        Nat32.toNat(Text.hash(Conversions.candySharedToText(a_extensible)));

      };
    };
  };

  public func account_hash_uncompressed(a : Account) : Nat {
    switch (a) {
      case (#principal(a_principal)) {
        MapUtils.hashBlob(Principal.toBlob(a_principal));
      };
      case (#account_id(a_account_id)) {

        let accountBlob = switch (hex.decode(a_account_id)) {
          case (#ok(item)) { Blob.fromArray(item) };
          case (#err(err)) {
            D.trap("Not a valid hex");
          };
        };
        MapUtils.hashBlob(accountBlob);
      };
      case (#account(a_account)) {
        let account_id = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_account.owner, switch (a_account.sub_account) { case (null) { null }; case (?val) { ?Blob.toArray(val) } }));
        let accountBlob = switch (hex.decode(account_id)) {
          case (#ok(item)) { Blob.fromArray(item) };
          case (#err(err)) {
            D.trap("Not a valid hex");
          };
        };
        MapUtils.hashBlob(accountBlob);
      };
      case (#extensible(a_extensible)) {
        //unimplemnted; unsafe; probably dont use
        //until a reliable valueToHash function is written
        //if any redenring of classes changes the whole hash
        //will change
        MapUtils.hashBlob(Conversions.candySharedToBlob(#Text(Conversions.candySharedToText(a_extensible))));
      };
    };
  };

  public func token_hash(a : TokenSpec) : Nat {
    switch (a) {
      case (#ic(a)) {
        var hash = Nat32.toNat(Principal.hash(a.canister));
        switch (a.id) {
          case (?val) {
            hash += val;
          };
          case (null) {};
        };
        hash;
      };
      case (#extensible(a_extensible)) {
        //unimplemnted; unsafe; probably dont use
        //until a reliable valueToHash function is written
        //if any redenring of classes changes the whole hash
        //will change
        Nat32.toNat(Text.hash(Conversions.candySharedToText(a_extensible)));
      };
    };

  };

  public func token_hash_uncompressed(a : TokenSpec) : Nat {
    switch (a) {
      case (#ic(a)) {
        var hash = MapUtils.hashBlob(Principal.toBlob(a.canister));
        switch (a.id) {
          case (?val) {
            hash += MapUtils.hashBlob(Conversions.candySharedToBlob(#Nat(val)));
          };
          case (null) {};
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

  public type EXTTokensResponse = (Nat32, ?{ locked : ?Int; seller : Principal; price : Nat64 }, ?[Nat8]);

  // Converts a token id into a reversable ext token id
  public func _getEXTTokenIdentifier(token_id : Text, canister : Principal) : Text {
    let tds : [Nat8] = [10, 116, 105, 100]; //b"\x0Atid"
    let theID = Array.append<Nat8>(
      Array.append<Nat8>(tds, Blob.toArray(Principal.toBlob(canister))),
      Conversions.candySharedToBytes(#Nat32(Text.hash(token_id))),
    );

    return Principal.toText(Principal.fromBlob(Blob.fromArray(theID)));
  };

  public let account_handler = (account_hash, account_eq);

  public let token_handler = (token_hash, token_eq);

  public type HTTPResponse = {
    body : Blob;
    headers : [http.HeaderField];
    status_code : Nat16;
    streaming_strategy : ?StreamingStrategy;
  };

  public type StreamingCallback = query (StreamingCallbackToken) -> async (StreamingCallbackResponse);

  public type StreamingCallbackResponse = {
    body : Blob;
    token : ?StreamingCallbackToken;
  };

  public type StorageService = actor {
    stage_library_nft_origyn : shared (StageChunkArg, AllocationRecordStable, CandyTypes.CandyShared) -> async Result.Result<StageLibraryResponse, OrigynError>;
    storage_info_nft_origyn : shared query () -> async Result.Result<StorageMetrics, OrigynError>;
    chunk_nft_origyn : shared query ChunkRequest -> async Result.Result<ChunkContent, OrigynError>;
    refresh_metadata_nft_origyn : (token_id : Text, metadata : CandyTypes.CandyShared) -> async Result.Result<Bool, OrigynError>;
  };

  public func force_account_to_account_id(request : Account) : Result.Result<Account, OrigynError> {
    switch (request) {
      case (#principal(principal)) #ok(#account_id(AccountIdentifier.toText(AccountIdentifier.fromPrincipal(principal, null))));
      case (#account(account)) #ok(#account_id(AccountIdentifier.toText(AccountIdentifier.fromPrincipal(account.owner, null))));
      case (#account_id(account_id)) #ok(request);
      case (#extensible(ex)) return #err(errors(null, #nyi, "force_account_to_account_id", null));
    };
  };

  //the following types are included to provde stable .did creations. Please do not remove them even if they
  //seem like they ocould be refactored.

  public type EXTAccountIdentifier = Text;
  public type EXTBalance = Nat;
  public type EXTTokenIdentifier = Text;
  public type EXTCommonError = {
    #InvalidToken : EXTTokenIdentifier;
    #Other : Text;
  };
  public type EXTBalanceResult = Result.Result<EXTBalance, EXTCommonError>;
  public type EXTBalanceRequest = {
    user : EXTUser;
    token : EXTTokenIdentifier;
  };
  public type EXTUser = {
    #address : Text; //No notification
    #principal : Principal; //defaults to sub account 0
  };
  public type EXTMemo = Blob;
  public type EXTSubAccount = [Nat8];
  public type EXTTransferRequest = {
    from : EXTUser;
    to : EXTUser;
    token : EXTTokenIdentifier;
    amount : EXTBalance;
    memo : EXTMemo;
    notify : Bool;
    subaccount : ?EXTSubAccount;
  };
  public type EXTTransferResponse = Result.Result<EXTBalance, { #Unauthorized : EXTAccountIdentifier; #InsufficientBalance; #Rejected; /* Rejected by canister */
  #InvalidToken : EXTTokenIdentifier; #CannotNotify : EXTAccountIdentifier; #Other : Text }>;

  public type EXTMetadata = {
    #fungible : {
      name : Text;
      symbol : Text;
      decimals : Nat8;
      metadata : ?Blob;
    };
    #nonfungible : {
      metadata : ?Blob;
    };
  };
  public type EXTMetadataResult = Result.Result<EXTMetadata, EXTCommonError>;
  public type EXTTokensResult = Result.Result<[EXTTokensResponse], EXTCommonError>;

  public type BalanceResult = Result.Result<BalanceResponse, OrigynError>;
  public type BearerResult = Result.Result<Account, OrigynError>;
  public type EXTBearerResult = Result.Result<EXTAccountIdentifier, EXTCommonError>;
  public type ChunkResult = Result.Result<ChunkContent, OrigynError>;
  public type CollectionResult = Result.Result<CollectionInfo, OrigynError>;
  public type OrigynBoolResult = Result.Result<Bool, OrigynError>;
  public type OrigynTextResult = Result.Result<Text, OrigynError>;
  public type GovernanceResult = Result.Result<GovernanceResponse, OrigynError>;
  public type HistoryResult = Result.Result<[TransactionRecord], OrigynError>;
  public type ManageStorageResult = Result.Result<ManageStorageResponse, OrigynError>;
  public type MarketTransferResult = Result.Result<MarketTransferRequestReponse, OrigynError>;
  public type NFTInfoResult = Result.Result<NFTInfoStable, OrigynError>;
  public type NFTUpdateResult = Result.Result<NFTUpdateResponse, OrigynError>;
  public type OwnerUpdateResult = Result.Result<OwnerTransferResponse, OrigynError>;
  public type ManageSaleResult = Result.Result<ManageSaleResponse, OrigynError>;
  public type ManageSaleStar = Star.Star<ManageSaleResponse, OrigynError>;
  public type SaleInfoResult = Result.Result<SaleInfoResponse, OrigynError>;
  public type StorageMetricsResult = Result.Result<StorageMetrics, OrigynError>;
  public type StageLibraryResult = Result.Result<StageLibraryResponse, OrigynError>;
  public type LocalStageLibraryResult = Result.Result<LocalStageLibraryResponse, OrigynError>;

  public type Service = actor {
    __advance_time : shared Int -> async Int;
    __set_time_mode : shared { #test; #standard } -> async Bool;
    balance : shared query EXTBalanceRequest -> async EXTBalanceResult;
    balanceEXT : shared query EXTBalanceRequest -> async EXTBalanceResult;
    balanceOfDip721 : shared query Principal -> async Nat;
    balance_of_nft_origyn : shared query Account -> async BalanceResult;
    balance_of_secure_nft_origyn : shared (account : Account) -> async BalanceResult;
    bearer : shared query EXTTokenIdentifier -> async EXTBearerResult;
    bearerEXT : shared query EXTTokenIdentifier -> async EXTBearerResult;
    bearer_nft_origyn : shared query Text -> async BearerResult;
    bearer_batch_nft_origyn : shared query (tokens : [Text]) -> async [BearerResult];
    bearer_secure_nft_origyn : shared (token_id : Text) -> async BearerResult;
    bearer_batch_secure_nft_origyn : shared [Text] -> async [BearerResult];

    canister_status : shared {
      canister_id : canister_id;
    } -> async canister_status;
    chunk_nft_origyn : shared query ChunkRequest -> async ChunkResult;
    chunk_secure_nft_origyn : shared (request : ChunkRequest) -> async ChunkResult;
    collection_nft_origyn : shared query (fields : ?[(Text, ?Nat, ?Nat)]) -> async CollectionResult;
    collection_secure_nft_origyn : shared (fields : ?[(Text, ?Nat, ?Nat)]) -> async CollectionResult;
    collection_update_nft_origyn : (ManageCollectionCommand) -> async OrigynBoolResult;
    collection_update_batch_nft_origyn : ([ManageCollectionCommand]) -> async [OrigynBoolResult];
    cycles : shared query () -> async Nat;
    get_access_key : shared () -> async OrigynTextResult;
    getEXTTokenIdentifier : shared query Text -> async Text;
    get_nat_as_token_id : shared query Nat -> async Text;
    get_token_id_as_nat : shared query Text -> async Nat;
    governance_nft_origyn : shared (request : GovernanceRequest) -> async GovernanceResult;
    history_nft_origyn : shared query (Text, ?Nat, ?Nat) -> async HistoryResult;
    history_batch_nft_origyn : shared query (tokens : [(token_id : Text, start : ?Nat, end : ?Nat)]) -> async [HistoryResult];
    history_batch_secure_nft_origyn : shared (tokens : [(token_id : Text, start : ?Nat, end : ?Nat)]) -> async [HistoryResult];
    history_secure_nft_origyn : shared (token_id : Text, start : ?Nat, end : ?Nat) -> async HistoryResult;
    http_access_key : shared () -> async OrigynTextResult;
    http_request : shared query HttpRequest -> async HTTPResponse;
    http_request_streaming_callback : shared query StreamingCallbackToken -> async StreamingCallbackResponse;
    manage_storage_nft_origyn : shared ManageStorageRequest -> async ManageStorageResult;
    market_transfer_nft_origyn : shared MarketTransferRequest -> async MarketTransferResult;
    market_transfer_batch_nft_origyn : shared [MarketTransferRequest] -> async [MarketTransferResult];
    metadata : shared query () -> async DIP721.DIP721Metadata;
    metadataExt : shared query (EXTTokenIdentifier) -> async EXTMetadataResult;
    mint_nft_origyn : shared (Text, Account) -> async OrigynTextResult;
    mint_batch_nft_origyn : shared (tokens : [(Text, Account)]) -> async [OrigynTextResult];
    nftStreamingCallback : shared query StreamingCallbackToken -> async StreamingCallbackResponse;
    nft_origyn : shared query Text -> async NFTInfoResult;
    nft_batch_origyn : shared query (token_ids : [Text]) -> async [NFTInfoResult];
    nft_batch_secure_origyn : shared (token_ids : [Text]) -> async [NFTInfoResult];
    nft_secure_origyn : shared (token_id : Text) -> async NFTInfoResult;
    update_app_nft_origyn : shared NFTUpdateRequest -> async NFTUpdateResult;
    ownerOf : shared query Nat -> async DIP721.OwnerOfResponse;
    ownerOfDIP721 : shared query Nat -> async DIP721.OwnerOfResponse;
    share_wallet_nft_origyn : shared ShareWalletRequest -> async OwnerUpdateResult;
    sale_nft_origyn : shared ManageSaleRequest -> async ManageSaleResult;
    sale_batch_nft_origyn : shared (requests : [ManageSaleRequest]) -> async [ManageSaleResult];
    sale_info_nft_origyn : shared SaleInfoRequest -> async SaleInfoResult;
    sale_info_secure_nft_origyn : shared (request : SaleInfoRequest) -> async SaleInfoResult;
    sale_info_batch_nft_origyn : shared query (requests : [SaleInfoRequest]) -> async [SaleInfoResult];
    sale_info_batch_secure_nft_origyn : shared (requests : [SaleInfoRequest]) -> async [SaleInfoResult];
    stage_library_nft_origyn : shared StageChunkArg -> async StageLibraryResult;
    stage_library_batch_nft_origyn : shared (chunks : [StageChunkArg]) -> async [StageLibraryResult];
    stage_nft_origyn : shared { metadata : CandyTypes.CandyShared } -> async OrigynTextResult;
    stage_batch_nft_origyn : shared (request : [{ metadata : CandyTypes.CandyShared }]) -> async [OrigynTextResult];
    storage_info_nft_origyn : shared query () -> async StorageMetricsResult;
    storage_info_secure_nft_origyn : shared () -> async StorageMetricsResult;
    transfer : shared EXTTransferRequest -> async EXTTransferResponse;
    transferEXT : shared EXTTransferRequest -> async EXTTransferResponse;
    transferFrom : shared (Principal, Principal, Nat) -> async DIP721.DIP721NatResult;
    transferFromDip721 : shared (Principal, Principal, Nat) -> async DIP721.DIP721NatResult;
    whoami : shared query () -> async Principal;
  };

  public type AuctionState = MigrationTypes.Current.AuctionState;
  public type SaleStatus = MigrationTypes.Current.SaleStatus;
  public type GatewayState_v0_1_6 = MigrationTypes.Current.State;

};
