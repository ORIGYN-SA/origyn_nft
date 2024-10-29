# origyn_nft_reference/types

## Function `__candid_keys`
``` motoko no-repl
func __candid_keys() : [Text]
```


## Type `StorageInitArgs`
``` motoko no-repl
type StorageInitArgs = { gateway_canister : Principal; network : ?Principal; storage_space : ?Nat }
```


## Type `StorageMigrationArgs`
``` motoko no-repl
type StorageMigrationArgs = { gateway_canister : Principal; network : ?Principal; storage_space : ?Nat; caller : Principal }
```


## Type `ManageCollectionCommand`
``` motoko no-repl
type ManageCollectionCommand = {#UpdateManagers : [Principal]; #UpdateOwner : Principal; #UpdateNetwork : ?Principal; #UpdateAnnounceCanister : ?Principal; #UpdateLogo : ?Text; #UpdateName : ?Text; #UpdateSymbol : ?Text; #UpdateMetadata : (Text, ?CandyTypes.CandyShared, Bool)}
```


## Type `RawData`
``` motoko no-repl
type RawData = (Int, Blob, Principal)
```


## Type `HttpRequest`
``` motoko no-repl
type HttpRequest = { body : Blob; headers : [http.HeaderField]; method : Text; url : Text }
```


## Type `StreamingCallbackToken`
``` motoko no-repl
type StreamingCallbackToken = { content_encoding : Text; index : Nat; key : Text }
```


## Type `StreamingCallbackHttpResponse`
``` motoko no-repl
type StreamingCallbackHttpResponse = { body : Blob; token : ?StreamingCallbackToken }
```


## Type `ChunkId`
``` motoko no-repl
type ChunkId = Nat
```


## Type `SetAssetContentArguments`
``` motoko no-repl
type SetAssetContentArguments = { chunk_ids : [ChunkId]; content_encoding : Text; key : Key; sha256 : ?Blob }
```


## Type `Path`
``` motoko no-repl
type Path = Text
```


## Type `Key`
``` motoko no-repl
type Key = Text
```


## Type `HttpResponse`
``` motoko no-repl
type HttpResponse = { body : Blob; headers : [http.HeaderField]; status_code : Nat16; streaming_strategy : ?StreamingStrategy }
```


## Type `StreamingStrategy`
``` motoko no-repl
type StreamingStrategy = {#Callback : { callback : shared () -> async (); token : StreamingCallbackToken }}
```


## Type `canister_id`
``` motoko no-repl
type canister_id = Principal
```


## Type `definite_canister_settings`
``` motoko no-repl
type definite_canister_settings = { freezing_threshold : Nat; controllers : ?[Principal]; memory_allocation : Nat; compute_allocation : Nat }
```


## Type `canister_status`
``` motoko no-repl
type canister_status = { status : {#stopped; #stopping; #running}; memory_size : Nat; cycles : Nat; settings : definite_canister_settings; module_hash : ?[Nat8] }
```


## Type `IC`
``` motoko no-repl
type IC = actor { canister_status : shared { canister_id : canister_id } -> async canister_status }
```


## Type `Subscriber`
``` motoko no-repl
type Subscriber = actor { notify_sale_nft_origyn : shared (SubscriberNotification) -> () }
```


## Type `SubscriberNotification`
``` motoko no-repl
type SubscriberNotification = { escrow_info : SubAccountInfo; sale : SaleStatusShared; seller : Account; collection : Principal }
```


## Type `StageChunkArg`
``` motoko no-repl
type StageChunkArg = { token_id : Text; library_id : Text; filedata : CandyTypes.CandyShared; chunk : Nat; content : Blob }
```


## Type `ChunkRequest`
``` motoko no-repl
type ChunkRequest = { token_id : Text; library_id : Text; chunk : ?Nat }
```


## Type `ChunkContent`
``` motoko no-repl
type ChunkContent = {#remote : { canister : Principal; args : ChunkRequest }; #chunk : { content : Blob; total_chunks : Nat; current_chunk : ?Nat; storage_allocation : AllocationRecordStable }}
```


## Type `MarketTransferRequest`
``` motoko no-repl
type MarketTransferRequest = MigrationTypes.Current.MarketTransferRequest
```


## Type `OwnerTransferResponse`
``` motoko no-repl
type OwnerTransferResponse = { transaction : TransactionRecord; assets : [CandyTypes.CandyShared] }
```


## Type `ShareWalletRequest`
``` motoko no-repl
type ShareWalletRequest = { token_id : Text; from : Account; to : Account }
```


## Type `SalesConfig`
``` motoko no-repl
type SalesConfig = MigrationTypes.Current.SalesConfig
```


## Type `ICTokenSpec`
``` motoko no-repl
type ICTokenSpec = { canister : Principal; fee : ?Nat; symbol : Text; decimals : Nat; id : ?Nat; standard : {#DIP20; #Ledger; #EXTFungible; #ICRC1; #Other : CandyTypes.CandyShared} }
```


## Type `TokenSpec`
``` motoko no-repl
type TokenSpec = {#ic : ICTokenSpec; #extensible : CandyTypes.CandyShared}
```


## Value `TokenSpecDefault`
``` motoko no-repl
let TokenSpecDefault
```


## Type `SubAccountInfo`
``` motoko no-repl
type SubAccountInfo = { principal : Principal; account_id : Blob; account_id_text : Text; account : { principal : Principal; sub_account : Blob } }
```


## Type `EscrowReceipt`
``` motoko no-repl
type EscrowReceipt = MigrationTypes.Current.EscrowReceipt
```


## Type `EscrowRequest`
``` motoko no-repl
type EscrowRequest = { token_id : Text; deposit : DepositDetail; lock_to_date : ?Int }
```


## Type `FeeDepositRequest`
``` motoko no-repl
type FeeDepositRequest = { account : Account; token : TokenSpec }
```


## Type `DepositDetail`
``` motoko no-repl
type DepositDetail = { token : TokenSpec; seller : Account; buyer : Account; amount : Nat; sale_id : ?Text; trx_id : ?TransactionID }
```


## Type `TransactionID`
``` motoko no-repl
type TransactionID = {#nat : Nat; #text : Text; #extensible : CandyTypes.CandyShared}
```


## Type `EscrowResponse`
``` motoko no-repl
type EscrowResponse = { receipt : EscrowReceipt; balance : Nat; transaction : TransactionRecord }
```


## Type `FeeDepositResponse`
``` motoko no-repl
type FeeDepositResponse = { balance : Nat; transaction : TransactionRecord }
```


## Type `RecognizeEscrowResponse`
``` motoko no-repl
type RecognizeEscrowResponse = { receipt : EscrowReceipt; balance : Nat; transaction : ?TransactionRecord }
```


## Type `BidRequest`
``` motoko no-repl
type BidRequest = MigrationTypes.Current.BidRequest
```


## Type `ManageSaleRequest`
``` motoko no-repl
type ManageSaleRequest = {#end_sale : Text; #open_sale : Text; #escrow_deposit : EscrowRequest; #fee_deposit : FeeDepositRequest; #recognize_escrow : EscrowRequest; #refresh_offers : ?Account; #bid : BidRequest; #withdraw : WithdrawRequest; #distribute_sale : DistributeSaleRequest; #ask_subscribe : AskSubscribeRequest}
```


## Type `DistributeSaleRequest`
``` motoko no-repl
type DistributeSaleRequest = { seller : ?Account }
```


## Type `DistributeSaleResponse`
``` motoko no-repl
type DistributeSaleResponse = [Result.Result<ManageSaleResponse, OrigynError>]
```


## Type `AskSubscribeResponse`
``` motoko no-repl
type AskSubscribeResponse = Bool
```


## Type `BidResponse`
``` motoko no-repl
type BidResponse = TransactionRecord
```


## Type `PricingConfig`
``` motoko no-repl
type PricingConfig = MigrationTypes.Current.PricingConfig
```


## Type `PricingConfigShared`
``` motoko no-repl
type PricingConfigShared = MigrationTypes.Current.PricingConfigShared
```


## Type `AskConfigShared`
``` motoko no-repl
type AskConfigShared = MigrationTypes.Current.AskConfigShared
```


## Type `DutchParams`
``` motoko no-repl
type DutchParams = MigrationTypes.Current.DutchParams
```


## Type `AskFeature`
``` motoko no-repl
type AskFeature = MigrationTypes.Current.AskFeature
```


## Type `InstantFeature`
``` motoko no-repl
type InstantFeature = MigrationTypes.Current.InstantFeature
```


## Type `NiftyConfig`
``` motoko no-repl
type NiftyConfig = { duration : ?Int; expiration : ?Int; fixed : Bool; lenderOffer : Bool; amount : Nat; interestRatePerSecond : Float; token : TokenSpec }
```


## Type `AuctionConfig`
``` motoko no-repl
type AuctionConfig = MigrationTypes.Current.AuctionConfig
```


## Value `AuctionConfigDefault`
``` motoko no-repl
let AuctionConfigDefault
```


## Type `NFTInfoStable`
``` motoko no-repl
type NFTInfoStable = { current_sale : ?SaleStatusShared; metadata : CandyTypes.CandyShared }
```


## Type `AuctionStateShared`
``` motoko no-repl
type AuctionStateShared = { config : PricingConfigShared; current_bid_amount : Nat; current_config : MigrationTypes.Current.BidConfigShared; end_date : Int; start_date : Int; min_next_bid : Nat; token : TokenSpec; current_escrow : ?EscrowReceipt; wait_for_quiet_count : ?Nat; allow_list : ?[(Principal, Bool)]; participants : [(Principal, Int)]; status : {#open; #closed; #not_started}; winner : ?Account }
```


## Function `AuctionState_stabalize_for_xfer`
``` motoko no-repl
func AuctionState_stabalize_for_xfer(val : AuctionState) : AuctionStateShared
```


## Type `SaleStatusShared`
``` motoko no-repl
type SaleStatusShared = { sale_id : Text; original_broker_id : ?Principal; broker_id : ?Principal; token_id : Text; sale_type : {#auction : AuctionStateShared} }
```


## Function `SalesStatus_stabalize_for_xfer`
``` motoko no-repl
func SalesStatus_stabalize_for_xfer(item : SaleStatus) : SaleStatusShared
```


## Type `MarketTransferRequestReponse`
``` motoko no-repl
type MarketTransferRequestReponse = TransactionRecord
```


## Type `Account`
``` motoko no-repl
type Account = MigrationTypes.Current.Account
```


## Type `State`
``` motoko no-repl
type State = State_v0_1_6
```

public type Stable_Memory = {
      _1 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
      _4 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
      _16 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
      _64 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
      _256 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
      _1024 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
      //_2048 : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>;
    };

## Type `State_v0_1_6`
``` motoko no-repl
type State_v0_1_6 = { state : GatewayState; canister : () -> Principal; get_time : () -> Int; nft_library : TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>>; refresh_state : () -> State; droute_client : DROUTE.Droute; kyc_client : KYC.kyc; handle_notify : () -> async (); icrc3 : ICRC3.ICRC3; notify_timer : { get : () -> ?Nat; set : (?Nat) -> () } }
```


## Type `BucketDat`
``` motoko no-repl
type BucketDat = { principal : Principal; allocated_space : Nat; available_space : Nat; date_added : Int; b_gateway : Bool; version : (Nat, Nat, Nat); allocations : Map.Map<(Text, Text), Int> }
```


## Type `StableCollectionData`
``` motoko no-repl
type StableCollectionData = { logo : ?Text; name : ?Text; symbol : ?Text; metadata : ?CandyTypes.CandyShared; owner : Principal; managers : [Principal]; network : ?Principal; allocated_storage : Nat; available_space : Nat; active_bucket : ?Principal }
```


## Function `stabilize_collection_data`
``` motoko no-repl
func stabilize_collection_data(item : CollectionData) : StableCollectionData
```


## Type `StableBucketData`
``` motoko no-repl
type StableBucketData = { principal : Principal; allocated_space : Nat; available_space : Nat; date_added : Int; b_gateway : Bool; version : (Nat, Nat, Nat); allocations : [((Text, Text), Int)] }
```


## Function `stabilize_bucket_data`
``` motoko no-repl
func stabilize_bucket_data(item : BucketData) : StableBucketData
```


## Type `StableEscrowBalances`
``` motoko no-repl
type StableEscrowBalances = [(Account, Account, Text, EscrowRecord)]
```


## Type `StableSalesBalances`
``` motoko no-repl
type StableSalesBalances = [(Account, Account, Text, EscrowRecord)]
```


## Type `StableOffers`
``` motoko no-repl
type StableOffers = [(Account, Account, Int)]
```


## Type `StableNftLedger`
``` motoko no-repl
type StableNftLedger = [(Text, TransactionRecord)]
```


## Type `StableNftSales`
``` motoko no-repl
type StableNftSales = [(Text, SaleStatusShared)]
```


## Type `NFTBackupChunk`
``` motoko no-repl
type NFTBackupChunk = { canister : Principal; collection_data : StableCollectionData; buckets : [(Principal, StableBucketData)]; allocations : [((Text, Text), AllocationRecordStable)]; escrow_balances : StableEscrowBalances; sales_balances : StableSalesBalances; offers : StableOffers; nft_ledgers : StableNftLedger; nft_sales : [(Text, SaleStatusShared)] }
```


## Type `StateSize`
``` motoko no-repl
type StateSize = { buckets : Nat; allocations : Nat; escrow_balances : Nat; sales_balances : Nat; offers : Nat; nft_ledgers : Nat; nft_sales : Nat }
```


## Type `GatewayState`
``` motoko no-repl
type GatewayState = GatewayState_v0_1_6
```


## Type `StorageState`
``` motoko no-repl
type StorageState = StorageState_v_0_1_5
```


## Type `StorageState_v_0_1_5`
``` motoko no-repl
type StorageState_v_0_1_5 = { var state : StorageMigrationTypes.Current.State; canister : () -> Principal; get_time : () -> Int; var nft_library : TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>>; refresh_state : () -> StorageState_v_0_1_5; use_stable_storage : Bool }
```


## Type `StorageMetrics`
``` motoko no-repl
type StorageMetrics = { allocated_storage : Nat; available_space : Nat; allocations : [AllocationRecordStable]; gateway : Principal }
```


## Type `BucketData`
``` motoko no-repl
type BucketData = { principal : Principal; var allocated_space : Nat; var available_space : Nat; date_added : Int; b_gateway : Bool; var version : (Nat, Nat, Nat); var allocations : Map.Map<(Text, Text), Int> }
```


## Type `AllocationRecord`
``` motoko no-repl
type AllocationRecord = { canister : Principal; allocated_space : Nat; var available_space : Nat; var chunks : SB.StableBuffer<Nat>; token_id : Text; library_id : Text }
```


## Type `AllocationRecordStable`
``` motoko no-repl
type AllocationRecordStable = { canister : Principal; allocated_space : Nat; available_space : Nat; chunks : [Nat]; token_id : Text; library_id : Text }
```


## Function `allocation_record_stabalize`
``` motoko no-repl
func allocation_record_stabalize(item : AllocationRecord) : AllocationRecordStable
```


## Type `TransactionRecord`
``` motoko no-repl
type TransactionRecord = MigrationTypes.Current.TransactionRecord
```


## Type `NFTUpdateRequest`
``` motoko no-repl
type NFTUpdateRequest = {#replace : { token_id : Text; data : CandyTypes.CandyShared }; #update : { token_id : Text; app_id : Text; update : CandyTypes.UpdateRequestShared }}
```


## Type `NFTUpdateResponse`
``` motoko no-repl
type NFTUpdateResponse = Bool
```


## Type `EndSaleResponse`
``` motoko no-repl
type EndSaleResponse = TransactionRecord
```


## Type `EscrowRecord`
``` motoko no-repl
type EscrowRecord = { amount : Nat; buyer : Account; seller : Account; token_id : Text; token : TokenSpec; sale_id : ?Text; lock_to_date : ?Int; account_hash : ?Blob }
```


## Type `AskSubscribeRequest`
``` motoko no-repl
type AskSubscribeRequest = {#subscribe : { filter : ?{ token_ids : ?[TokenIDFilter]; tokens : ?[TokenSpecFilter] }; stake : (Principal, Nat) }; #unsubscribe : (Principal, Nat)}
```


## Type `TokenIDFilter`
``` motoko no-repl
type TokenIDFilter = { token_id : Text; tokens : [{ min_amount : ?Nat; max_amount : ?Nat; token : TokenSpec }]; filter_type : {#allow; #block} }
```


## Type `TokenSpecFilter`
``` motoko no-repl
type TokenSpecFilter = { token : TokenSpec; filter_type : {#allow; #block} }
```


## Type `ManageSaleResponse`
``` motoko no-repl
type ManageSaleResponse = {#end_sale : EndSaleResponse; #open_sale : Bool; #escrow_deposit : EscrowResponse; #fee_deposit : FeeDepositResponse; #recognize_escrow : RecognizeEscrowResponse; #refresh_offers : [EscrowRecord]; #bid : BidResponse; #withdraw : WithdrawResponse; #distribute_sale : DistributeSaleResponse; #ask_subscribe : AskSubscribeResponse}
```


## Type `SaleInfoRequest`
``` motoko no-repl
type SaleInfoRequest = {#active : ?(Nat, Nat); #history : ?(Nat, Nat); #status : Text; #escrow_info : EscrowReceipt; #fee_deposit_info : ?Account; #deposit_info : ?Account}
```


## Type `SaleInfoResponse`
``` motoko no-repl
type SaleInfoResponse = {#active : { records : [(Text, ?SaleStatusShared)]; eof : Bool; count : Nat }; #history : { records : [?SaleStatusShared]; eof : Bool; count : Nat }; #status : ?SaleStatusShared; #deposit_info : SubAccountInfo; #escrow_info : SubAccountInfo; #fee_deposit_info : SubAccountInfo}
```


## Type `GovernanceRequest`
``` motoko no-repl
type GovernanceRequest = {#clear_shared_wallets : Text; #update_system_var : { token_id : Text; key : Text; val : CandyTypes.CandyShared }}
```


## Type `GovernanceResponse`
``` motoko no-repl
type GovernanceResponse = {#clear_shared_wallets : Bool; #update_system_var : Bool}
```


## Type `StakeRecord`
``` motoko no-repl
type StakeRecord = { amount : Nat; staker : Account; token_id : Text }
```


## Type `BalanceResponse`
``` motoko no-repl
type BalanceResponse = { multi_canister : ?[Principal]; nfts : [Text]; escrow : [EscrowRecord]; sales : [EscrowRecord]; stake : [StakeRecord]; offers : [EscrowRecord] }
```


## Type `LocalStageLibraryResponse`
``` motoko no-repl
type LocalStageLibraryResponse = {#stage_remote : { allocation : AllocationRecord; metadata : CandyTypes.CandyShared }; #staged : Principal}
```


## Type `StageLibraryResponse`
``` motoko no-repl
type StageLibraryResponse = { canister : Principal }
```


## Type `WithdrawDescription`
``` motoko no-repl
type WithdrawDescription = { buyer : Account; seller : Account; token_id : Text; token : TokenSpec; amount : Nat; withdraw_to : Account }
```


## Type `DepositWithdrawDescription`
``` motoko no-repl
type DepositWithdrawDescription = { buyer : Account; token : TokenSpec; amount : Nat; withdraw_to : Account }
```


## Type `FeeDepositWithdrawDescription`
``` motoko no-repl
type FeeDepositWithdrawDescription = { account : Account; token : TokenSpec; amount : Nat; withdraw_to : Account; status : {#unlocked; #locked : { sale_id : Text }} }
```


## Type `RejectDescription`
``` motoko no-repl
type RejectDescription = { buyer : Account; seller : Account; token_id : Text; token : TokenSpec }
```


## Type `WithdrawRequest`
``` motoko no-repl
type WithdrawRequest = {#escrow : WithdrawDescription; #sale : WithdrawDescription; #reject : RejectDescription; #deposit : DepositWithdrawDescription; #fee_deposit : FeeDepositWithdrawDescription}
```


## Type `WithdrawResponse`
``` motoko no-repl
type WithdrawResponse = TransactionRecord
```


## Type `CollectionInfo`
``` motoko no-repl
type CollectionInfo = { fields : ?[(Text, ?Nat, ?Nat)]; logo : ?Text; name : ?Text; symbol : ?Text; total_supply : ?Nat; owner : ?Principal; managers : ?[Principal]; network : ?Principal; token_ids : ?[Text]; token_ids_count : ?Nat; multi_canister : ?[Principal]; multi_canister_count : ?Nat; metadata : ?CandyTypes.CandyShared; allocated_storage : ?Nat; available_space : ?Nat; created_at : ?Nat64; upgraded_at : ?Nat64; unique_holders : ?Nat; transaction_count : ?Nat }
```


## Type `CollectionData`
``` motoko no-repl
type CollectionData = { var logo : ?Text; var name : ?Text; var symbol : ?Text; var metadata : ?CandyTypes.CandyShared; var owner : Principal; var managers : [Principal]; var network : ?Principal; var allocated_storage : Nat; var available_space : Nat; var active_bucket : ?Principal }
```


## Type `CollectionDataForStorage`
``` motoko no-repl
type CollectionDataForStorage = { var owner : Principal; var managers : [Principal]; var network : ?Principal }
```


## Type `ManageStorageRequest`
``` motoko no-repl
type ManageStorageRequest = {#add_storage_canisters : [(Principal, Nat, (Nat, Nat, Nat))]; #configure_storage : {#heap : ?Nat; #stableBtree : ?Nat}}
```


## Type `ManageStorageResponse`
``` motoko no-repl
type ManageStorageResponse = {#add_storage_canisters : (Nat, Nat); #configure_storage : (Nat, Nat)}
```


## Type `LogEntry`
``` motoko no-repl
type LogEntry = { event : Text; timestamp : Int; data : CandyTypes.CandyShared; caller : ?Principal }
```


## Type `OrigynError`
``` motoko no-repl
type OrigynError = { number : Nat32; text : Text; error : Errors; flag_point : Text }
```


## Type `UpdateAppResponse`
``` motoko no-repl
type UpdateAppResponse = Result.Result<NFTUpdateResponse, OrigynError>
```


## Type `Errors`
``` motoko no-repl
type Errors = {#app_id_not_found; #asset_mismatch; #attempt_to_stage_system_data; #auction_ended; #auction_not_started; #bid_too_low; #cannot_find_status_in_metadata; #cannot_restage_minted_token; #content_not_deserializable; #content_not_found; #deposit_burned; #escrow_cannot_be_removed; #escrow_owner_not_the_owner; #escrow_withdraw_payment_failed; #escrow_not_large_enough; #existing_sale_found; #id_not_found_in_metadata; #improper_interface; #item_already_minted; #item_not_owned; #library_not_found; #malformed_metadata; #no_escrow_found; #not_enough_storage; #out_of_range; #owner_not_found; #property_not_found; #receipt_data_mismatch; #sale_not_found; #sale_not_over; #sale_id_does_not_match; #sales_withdraw_payment_failed; #storage_configuration_error; #token_not_found; #token_id_mismatch; #token_non_transferable; #unauthorized_access; #unreachable; #update_class_error; #validate_deposit_failed; #validate_deposit_wrong_amount; #validate_deposit_wrong_buyer; #validate_trx_wrong_host; #withdraw_too_large; #nyi; #noop; #kyc_error; #kyc_fail; #low_fee_balance; #no_fee_accounts_provided}
```


## Function `errors`
``` motoko no-repl
func errors( the_error : Errors, flag_point : Text, caller : ?Principal) : OrigynError
```


## Value `nft_status_staged`
``` motoko no-repl
let nft_status_staged
```


## Value `nft_status_minted`
``` motoko no-repl
let nft_status_minted
```


## Value `metadata`
``` motoko no-repl
let metadata : { __system : Text; __system_status : Text; __system_secondary_royalty : Text; __system_primary_royalty : Text; __system_fixed_royalty : Text; __system_node : Text; __system_originator : Text; __system_wallet_shares : Text; __system_physical : Text; __system_escrowed : Text; __apps : Text; broker_royalty_dev_fund_override : Text; collection_kyc_canister_buyer : Text; collection_kyc_canister_seller : Text; library : Text; library_id : Text; library_size : Text; library_location_type : Text; owner : Text; id : Text; kyc_collection : Text; primary_asset : Text; preview_asset : Text; experience_asset : Text; hidden_asset : Text; is_soulbound : Text; immutable_library : Text; physical : Text; primary_host : Text; primary_port : Text; primary_protocol : Text; primary_royalties_default : Text; fixed_royalties_default : Text; originator_override : Text; royalty_broker : Text; royalty_node : Text; royalty_originator : Text; royalty_network : Text; royalty_custom : Text; secondary_royalties_default : Text; icrc7_description : Text; __apps_app_id : Text; __system_current_sale_id : Text }
```


## Function `account_eq`
``` motoko no-repl
func account_eq(a : Account, b : Account) : Bool
```


## Function `token_compare`
``` motoko no-repl
func token_compare(a : TokenSpec, b : TokenSpec) : Order.Order
```


## Function `token_eq`
``` motoko no-repl
func token_eq(a : TokenSpec, b : TokenSpec) : Bool
```


## Function `account_hash`
``` motoko no-repl
func account_hash(a : Account) : Nat
```


## Function `account_hash_uncompressed`
``` motoko no-repl
func account_hash_uncompressed(a : Account) : Nat
```


## Function `token_hash`
``` motoko no-repl
func token_hash(a : TokenSpec) : Nat
```


## Function `token_hash_uncompressed`
``` motoko no-repl
func token_hash_uncompressed(a : TokenSpec) : Nat
```


## Type `EXTTokensResponse`
``` motoko no-repl
type EXTTokensResponse = (Nat32, ?{ locked : ?Int; seller : Principal; price : Nat64 }, ?[Nat8])
```


## Function `_getEXTTokenIdentifier`
``` motoko no-repl
func _getEXTTokenIdentifier(token_id : Text, canister : Principal) : Text
```


## Value `account_handler`
``` motoko no-repl
let account_handler
```


## Value `token_handler`
``` motoko no-repl
let token_handler
```


## Type `HTTPResponse`
``` motoko no-repl
type HTTPResponse = { body : Blob; headers : [http.HeaderField]; status_code : Nat16; streaming_strategy : ?StreamingStrategy }
```


## Type `StreamingCallback`
``` motoko no-repl
type StreamingCallback = shared query (StreamingCallbackToken) -> async (StreamingCallbackResponse)
```


## Type `StreamingCallbackResponse`
``` motoko no-repl
type StreamingCallbackResponse = { body : Blob; token : ?StreamingCallbackToken }
```


## Type `StorageService`
``` motoko no-repl
type StorageService = actor { stage_library_nft_origyn : shared (StageChunkArg, AllocationRecordStable, CandyTypes.CandyShared) -> async Result.Result<StageLibraryResponse, OrigynError>; storage_info_nft_origyn : shared query () -> async Result.Result<StorageMetrics, OrigynError>; chunk_nft_origyn : shared query ChunkRequest -> async Result.Result<ChunkContent, OrigynError>; refresh_metadata_nft_origyn : shared (token_id : Text, metadata : CandyTypes.CandyShared) -> async Result.Result<Bool, OrigynError> }
```


## Function `force_account_to_account_id`
``` motoko no-repl
func force_account_to_account_id(request : Account) : Result.Result<Account, OrigynError>
```


## Type `EXTAccountIdentifier`
``` motoko no-repl
type EXTAccountIdentifier = Text
```


## Type `EXTBalance`
``` motoko no-repl
type EXTBalance = Nat
```


## Type `EXTTokenIdentifier`
``` motoko no-repl
type EXTTokenIdentifier = Text
```


## Type `EXTCommonError`
``` motoko no-repl
type EXTCommonError = {#InvalidToken : EXTTokenIdentifier; #Other : Text}
```


## Type `EXTBalanceResult`
``` motoko no-repl
type EXTBalanceResult = Result.Result<EXTBalance, EXTCommonError>
```


## Type `EXTBalanceRequest`
``` motoko no-repl
type EXTBalanceRequest = { user : EXTUser; token : EXTTokenIdentifier }
```


## Type `EXTUser`
``` motoko no-repl
type EXTUser = {#address : Text; #principal : Principal}
```


## Type `EXTMemo`
``` motoko no-repl
type EXTMemo = Blob
```


## Type `EXTSubAccount`
``` motoko no-repl
type EXTSubAccount = [Nat8]
```


## Type `EXTTransferRequest`
``` motoko no-repl
type EXTTransferRequest = { from : EXTUser; to : EXTUser; token : EXTTokenIdentifier; amount : EXTBalance; memo : EXTMemo; notify : Bool; subaccount : ?EXTSubAccount }
```


## Type `EXTTransferResponse`
``` motoko no-repl
type EXTTransferResponse = Result.Result<EXTBalance, {#Unauthorized : EXTAccountIdentifier; #InsufficientBalance; #Rejected; #InvalidToken : EXTTokenIdentifier; #CannotNotify : EXTAccountIdentifier; #Other : Text}>
```


## Type `EXTMetadata`
``` motoko no-repl
type EXTMetadata = {#fungible : { name : Text; symbol : Text; decimals : Nat8; metadata : ?Blob }; #nonfungible : { metadata : ?Blob }}
```


## Type `EXTMetadataResult`
``` motoko no-repl
type EXTMetadataResult = Result.Result<EXTMetadata, EXTCommonError>
```


## Type `EXTTokensResult`
``` motoko no-repl
type EXTTokensResult = Result.Result<[EXTTokensResponse], EXTCommonError>
```


## Type `BalanceResult`
``` motoko no-repl
type BalanceResult = Result.Result<BalanceResponse, OrigynError>
```


## Type `BearerResult`
``` motoko no-repl
type BearerResult = Result.Result<Account, OrigynError>
```


## Type `EXTBearerResult`
``` motoko no-repl
type EXTBearerResult = Result.Result<EXTAccountIdentifier, EXTCommonError>
```


## Type `ChunkResult`
``` motoko no-repl
type ChunkResult = Result.Result<ChunkContent, OrigynError>
```


## Type `CollectionResult`
``` motoko no-repl
type CollectionResult = Result.Result<CollectionInfo, OrigynError>
```


## Type `OrigynBoolResult`
``` motoko no-repl
type OrigynBoolResult = Result.Result<Bool, OrigynError>
```


## Type `OrigynTextResult`
``` motoko no-repl
type OrigynTextResult = Result.Result<Text, OrigynError>
```


## Type `GovernanceResult`
``` motoko no-repl
type GovernanceResult = Result.Result<GovernanceResponse, OrigynError>
```


## Type `HistoryResult`
``` motoko no-repl
type HistoryResult = Result.Result<[TransactionRecord], OrigynError>
```


## Type `ManageStorageResult`
``` motoko no-repl
type ManageStorageResult = Result.Result<ManageStorageResponse, OrigynError>
```


## Type `MarketTransferResult`
``` motoko no-repl
type MarketTransferResult = Result.Result<MarketTransferRequestReponse, OrigynError>
```


## Type `NFTInfoResult`
``` motoko no-repl
type NFTInfoResult = Result.Result<NFTInfoStable, OrigynError>
```


## Type `NFTUpdateResult`
``` motoko no-repl
type NFTUpdateResult = Result.Result<NFTUpdateResponse, OrigynError>
```


## Type `OwnerUpdateResult`
``` motoko no-repl
type OwnerUpdateResult = Result.Result<OwnerTransferResponse, OrigynError>
```


## Type `ManageSaleResult`
``` motoko no-repl
type ManageSaleResult = Result.Result<ManageSaleResponse, OrigynError>
```


## Type `ManageSaleStar`
``` motoko no-repl
type ManageSaleStar = Star.Star<ManageSaleResponse, OrigynError>
```


## Type `SaleInfoResult`
``` motoko no-repl
type SaleInfoResult = Result.Result<SaleInfoResponse, OrigynError>
```


## Type `StorageMetricsResult`
``` motoko no-repl
type StorageMetricsResult = Result.Result<StorageMetrics, OrigynError>
```


## Type `StageLibraryResult`
``` motoko no-repl
type StageLibraryResult = Result.Result<StageLibraryResponse, OrigynError>
```


## Type `LocalStageLibraryResult`
``` motoko no-repl
type LocalStageLibraryResult = Result.Result<LocalStageLibraryResponse, OrigynError>
```


## Type `Service`
``` motoko no-repl
type Service = actor { __advance_time : shared Int -> async Int; __set_time_mode : shared {#test; #standard} -> async Bool; balance : shared query EXTBalanceRequest -> async EXTBalanceResult; balanceEXT : shared query EXTBalanceRequest -> async EXTBalanceResult; balanceOfDip721 : shared query Principal -> async Nat; balance_of_nft_origyn : shared query Account -> async BalanceResult; balance_of_secure_nft_origyn : shared (account : Account) -> async BalanceResult; bearer : shared query EXTTokenIdentifier -> async EXTBearerResult; bearerEXT : shared query EXTTokenIdentifier -> async EXTBearerResult; bearer_nft_origyn : shared query Text -> async BearerResult; bearer_batch_nft_origyn : shared query (tokens : [Text]) -> async [BearerResult]; bearer_secure_nft_origyn : shared (token_id : Text) -> async BearerResult; bearer_batch_secure_nft_origyn : shared [Text] -> async [BearerResult]; canister_status : shared { canister_id : canister_id } -> async canister_status; chunk_nft_origyn : shared query ChunkRequest -> async ChunkResult; chunk_secure_nft_origyn : shared (request : ChunkRequest) -> async ChunkResult; collection_nft_origyn : shared query (fields : ?[(Text, ?Nat, ?Nat)]) -> async CollectionResult; collection_secure_nft_origyn : shared (fields : ?[(Text, ?Nat, ?Nat)]) -> async CollectionResult; collection_update_nft_origyn : shared (ManageCollectionCommand) -> async OrigynBoolResult; collection_update_batch_nft_origyn : shared ([ManageCollectionCommand]) -> async [OrigynBoolResult]; cycles : shared query () -> async Nat; get_access_key : shared () -> async OrigynTextResult; getEXTTokenIdentifier : shared query Text -> async Text; get_nat_as_token_id : shared query Nat -> async Text; get_token_id_as_nat : shared query Text -> async Nat; governance_nft_origyn : shared (request : GovernanceRequest) -> async GovernanceResult; history_nft_origyn : shared query (Text, ?Nat, ?Nat) -> async HistoryResult; history_batch_nft_origyn : shared query (tokens : [(token_id : Text, start : ?Nat, end : ?Nat)]) -> async [HistoryResult]; history_batch_secure_nft_origyn : shared (tokens : [(token_id : Text, start : ?Nat, end : ?Nat)]) -> async [HistoryResult]; history_secure_nft_origyn : shared (token_id : Text, start : ?Nat, end : ?Nat) -> async HistoryResult; http_access_key : shared () -> async OrigynTextResult; http_request : shared query HttpRequest -> async HTTPResponse; http_request_streaming_callback : shared query StreamingCallbackToken -> async StreamingCallbackResponse; manage_storage_nft_origyn : shared ManageStorageRequest -> async ManageStorageResult; market_transfer_nft_origyn : shared MarketTransferRequest -> async MarketTransferResult; market_transfer_batch_nft_origyn : shared [MarketTransferRequest] -> async [MarketTransferResult]; metadata : shared query () -> async DIP721.DIP721Metadata; metadataExt : shared query (EXTTokenIdentifier) -> async EXTMetadataResult; mint_nft_origyn : shared (Text, Account) -> async OrigynTextResult; mint_batch_nft_origyn : shared (tokens : [(Text, Account)]) -> async [OrigynTextResult]; nftStreamingCallback : shared query StreamingCallbackToken -> async StreamingCallbackResponse; nft_origyn : shared query Text -> async NFTInfoResult; nft_batch_origyn : shared query (token_ids : [Text]) -> async [NFTInfoResult]; nft_batch_secure_origyn : shared (token_ids : [Text]) -> async [NFTInfoResult]; nft_secure_origyn : shared (token_id : Text) -> async NFTInfoResult; update_app_nft_origyn : shared NFTUpdateRequest -> async NFTUpdateResult; ownerOf : shared query Nat -> async DIP721.OwnerOfResponse; ownerOfDIP721 : shared query Nat -> async DIP721.OwnerOfResponse; share_wallet_nft_origyn : shared ShareWalletRequest -> async OwnerUpdateResult; sale_nft_origyn : shared ManageSaleRequest -> async ManageSaleResult; sale_batch_nft_origyn : shared (requests : [ManageSaleRequest]) -> async [ManageSaleResult]; sale_info_nft_origyn : shared SaleInfoRequest -> async SaleInfoResult; sale_info_secure_nft_origyn : shared (request : SaleInfoRequest) -> async SaleInfoResult; sale_info_batch_nft_origyn : shared query (requests : [SaleInfoRequest]) -> async [SaleInfoResult]; sale_info_batch_secure_nft_origyn : shared (requests : [SaleInfoRequest]) -> async [SaleInfoResult]; stage_library_nft_origyn : shared StageChunkArg -> async StageLibraryResult; stage_library_batch_nft_origyn : shared (chunks : [StageChunkArg]) -> async [StageLibraryResult]; stage_nft_origyn : shared { metadata : CandyTypes.CandyShared } -> async OrigynTextResult; stage_batch_nft_origyn : shared (request : [{ metadata : CandyTypes.CandyShared }]) -> async [OrigynTextResult]; storage_info_nft_origyn : shared query () -> async StorageMetricsResult; storage_info_secure_nft_origyn : shared () -> async StorageMetricsResult; transfer : shared EXTTransferRequest -> async EXTTransferResponse; transferEXT : shared EXTTransferRequest -> async EXTTransferResponse; transferFrom : shared (Principal, Principal, Nat) -> async DIP721.DIP721NatResult; transferFromDip721 : shared (Principal, Principal, Nat) -> async DIP721.DIP721NatResult; whoami : shared query () -> async Principal }
```


## Type `AuctionState`
``` motoko no-repl
type AuctionState = MigrationTypes.Current.AuctionState
```


## Type `SaleStatus`
``` motoko no-repl
type SaleStatus = MigrationTypes.Current.SaleStatus
```


## Type `GatewayState_v0_1_6`
``` motoko no-repl
type GatewayState_v0_1_6 = MigrationTypes.Current.State
```

