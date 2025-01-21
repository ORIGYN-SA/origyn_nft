// This is an experimental feature to generate Rust binding from Candid.
// You may want to manually adjust some of the types.
#![allow(dead_code, unused_imports)]
use candid::{ self, CandidType, Deserialize, Principal };
use ic_cdk::api::call::CallResult as Result;

#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum NftCanisterSetTimeModeArg {
  #[serde(rename = "test")]
  Test,
  #[serde(rename = "standard")]
  Standard,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct PropertyShared {
  pub value: Box<CandyShared>,
  pub name: String,
  pub immutable: bool,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum CandyShared {
  Int(candid::Int),
  Map(Vec<(Box<CandyShared>, Box<CandyShared>)>),
  Nat(candid::Nat),
  Set(Vec<Box<CandyShared>>),
  Nat16(u16),
  Nat32(u32),
  Nat64(u64),
  Blob(serde_bytes::ByteBuf),
  Bool(bool),
  Int8(i8),
  Ints(Vec<candid::Int>),
  Nat8(u8),
  Nats(Vec<candid::Nat>),
  Text(String),
  Bytes(serde_bytes::ByteBuf),
  Int16(i16),
  Int32(i32),
  Int64(i64),
  Option(Option<Box<CandyShared>>),
  Floats(Vec<f64>),
  Float(f64),
  #[serde(rename = "Principal")] Principal_(Principal),
  Array(Vec<Box<CandyShared>>),
  Class(Vec<PropertyShared>),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct EscrowRecord1 {
  pub token: TokenSpec,
  pub token_id: String,
  pub seller: Account,
  pub lock_to_date: Option<candid::Int>,
  pub buyer: Account,
  pub amount: candid::Nat,
  pub sale_id: Option<String>,
  pub account_hash: Option<serde_bytes::ByteBuf>,
}
pub type StableSalesBalances = Vec<(Account, Account, String, EscrowRecord1)>;
pub type StableOffers = Vec<(Account, Account, candid::Int)>;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct StableCollectionData {
  pub active_bucket: Option<Principal>,
  pub managers: Vec<Principal>,
  pub owner: Principal,
  pub metadata: Option<Box<CandyShared>>,
  pub logo: Option<String>,
  pub name: Option<String>,
  pub network: Option<Principal>,
  pub available_space: candid::Nat,
  pub symbol: Option<String>,
  pub allocated_storage: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum IcTokenSpecStandard {
  #[serde(rename = "ICRC1")]
  Icrc1,
  #[serde(rename = "EXTFungible")]
  ExtFungible,
  #[serde(rename = "DIP20")]
  Dip20,
  Other(Box<CandyShared>),
  Ledger,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct IcTokenSpec {
  pub id: Option<candid::Nat>,
  pub fee: Option<candid::Nat>,
  pub decimals: candid::Nat,
  pub canister: Principal,
  pub standard: IcTokenSpecStandard,
  pub symbol: String,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum TokenSpec {
  #[serde(rename = "ic")] Ic(IcTokenSpec),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum TransactionId {
  #[serde(rename = "nat")] Nat(candid::Nat),
  #[serde(rename = "text")] Text(String),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct TransactionRecordTxnTypeMintSaleInner {
  pub token: TokenSpec,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct WaitForQuietType {
  pub max: candid::Nat,
  pub fade: f64,
  pub extension: u64,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum MinIncreaseType {
  #[serde(rename = "amount")] Amount(candid::Nat),
  #[serde(rename = "percentage")] Percentage(f64),
}
pub type FeeName = String;
pub type FeeAccountsParams = Vec<FeeName>;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct NiftySettlementType {
  pub fixed: bool,
  pub interestRatePerSecond: f64,
  pub duration: Option<candid::Int>,
  pub expiration: Option<candid::Int>,
  pub lenderOffer: bool,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum DutchParamsTimeUnit {
  #[serde(rename = "day")] Day(candid::Nat),
  #[serde(rename = "hour")] Hour(candid::Nat),
  #[serde(rename = "minute")] Minute(candid::Nat),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum DutchParamsDecayType {
  #[serde(rename = "flat")] Flat(candid::Nat),
  #[serde(rename = "percent")] Percent(f64),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct DutchParams {
  pub time_unit: DutchParamsTimeUnit,
  pub decay_type: DutchParamsDecayType,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum EndingType {
  #[serde(rename = "date")] Date(candid::Int),
  #[serde(rename = "timeout")] Timeout(candid::Nat),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum AskFeature {
  #[serde(rename = "start_price")] StartPrice(candid::Nat),
  #[serde(rename = "token")] Token(TokenSpec),
  #[serde(rename = "fee_schema")] FeeSchema(String),
  #[serde(rename = "notify")] Notify(Vec<Principal>),
  #[serde(rename = "wait_for_quiet")] WaitForQuiet(WaitForQuietType),
  #[serde(rename = "reserve")] Reserve(candid::Nat),
  #[serde(rename = "start_date")] StartDate(candid::Int),
  #[serde(rename = "min_increase")] MinIncrease(MinIncreaseType),
  #[serde(rename = "allow_list")] AllowList(Vec<Principal>),
  #[serde(rename = "buy_now")] BuyNow(candid::Nat),
  #[serde(rename = "fee_accounts")] FeeAccounts(FeeAccountsParams),
  #[serde(rename = "nifty_settlement")] NiftySettlement(NiftySettlementType),
  #[serde(rename = "atomic")]
  Atomic,
  #[serde(rename = "dutch")] Dutch(DutchParams),
  #[serde(rename = "ending")] Ending(EndingType),
}
pub type AskFeatureArray = Vec<AskFeature>;
pub type AskConfigShared = Option<AskFeatureArray>;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum InstantFeature {
  #[serde(rename = "fee_schema")] FeeSchema(String),
  #[serde(rename = "fee_accounts")] FeeAccounts(FeeAccountsParams),
  #[serde(rename = "transfer")]
  Transfer,
}
pub type InstantConfigShared = Option<Vec<InstantFeature>>;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum PricingConfigShared {
  #[serde(rename = "ask")] Ask(AskConfigShared),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
  #[serde(rename = "instant")] Instant(InstantConfigShared),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum TransactionRecordTxnType {
  #[serde(rename = "escrow_deposit")] EscrowDeposit {
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "fee_deposit")] FeeDeposit {
    token: TokenSpec,
    extensible: Box<CandyShared>,
    account: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "canister_network_updated")] CanisterNetworkUpdated {
    network: Principal,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "escrow_withdraw")] EscrowWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "canister_managers_updated")] CanisterManagersUpdated {
    managers: Vec<Principal>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "auction_bid")] AuctionBid {
    token: TokenSpec,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    sale_id: String,
  },
  #[serde(rename = "burn")] Burn {
    from: Option<Account>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "data")] Data {
    hash: Option<serde_bytes::ByteBuf>,
    extensible: Box<CandyShared>,
    data_dapp: Option<String>,
    data_path: Option<String>,
  },
  #[serde(rename = "sale_ended")] SaleEnded {
    token: TokenSpec,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    sale_id: Option<String>,
  },
  #[serde(rename = "mint")] Mint {
    to: Account,
    from: Account,
    sale: Option<TransactionRecordTxnTypeMintSaleInner>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "royalty_paid")] RoyaltyPaid {
    tag: String,
    token: TokenSpec,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    receiver: Account,
    sale_id: Option<String>,
  },
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
  #[serde(rename = "fee_deposit_withdraw")] FeeDepositWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    trx_id: TransactionId,
    extensible: Box<CandyShared>,
    account: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "owner_transfer")] OwnerTransfer {
    to: Account,
    from: Account,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "sale_opened")] SaleOpened {
    pricing: PricingConfigShared,
    extensible: Box<CandyShared>,
    sale_id: String,
  },
  #[serde(rename = "canister_owner_updated")] CanisterOwnerUpdated {
    owner: Principal,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "sale_withdraw")] SaleWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "deposit_withdraw")] DepositWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    trx_id: TransactionId,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct TransactionRecord {
  pub token_id: String,
  pub txn_type: TransactionRecordTxnType,
  pub timestamp: candid::Int,
  pub index: candid::Nat,
}
pub type StableNftLedger = Vec<(String, TransactionRecord)>;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct AllocationRecordStable {
  pub allocated_space: candid::Nat,
  pub token_id: String,
  pub available_space: candid::Nat,
  pub canister: Principal,
  pub chunks: Vec<candid::Nat>,
  pub library_id: String,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum AuctionStateSharedStatus {
  #[serde(rename = "closed")]
  Closed,
  #[serde(rename = "open")]
  Open,
  #[serde(rename = "not_started")]
  NotStarted,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum BidFeature {
  #[serde(rename = "fee_schema")] FeeSchema(String),
  #[serde(rename = "broker")] Broker(Account),
  #[serde(rename = "fee_accounts")] FeeAccounts(FeeAccountsParams),
}
pub type BidConfigShared = Option<Vec<BidFeature>>;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct EscrowReceipt {
  pub token: TokenSpec,
  pub token_id: String,
  pub seller: Account,
  pub buyer: Account,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum PricingConfigShared1 {
  #[serde(rename = "ask")] Ask(AskConfigShared),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
  #[serde(rename = "instant")] Instant(InstantConfigShared),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct AuctionStateShared {
  pub status: AuctionStateSharedStatus,
  pub participants: Vec<(Principal, candid::Int)>,
  pub token: TokenSpec,
  pub current_bid_amount: candid::Nat,
  pub winner: Option<Account>,
  pub end_date: candid::Int,
  pub current_config: BidConfigShared,
  pub start_date: candid::Int,
  pub wait_for_quiet_count: Option<candid::Nat>,
  pub current_escrow: Option<EscrowReceipt>,
  pub allow_list: Option<Vec<(Principal, bool)>>,
  pub min_next_bid: candid::Nat,
  pub config: PricingConfigShared1,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum SaleStatusSharedSaleType {
  #[serde(rename = "auction")] Auction(AuctionStateShared),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct SaleStatusShared {
  pub token_id: String,
  pub sale_type: SaleStatusSharedSaleType,
  pub broker_id: Option<Principal>,
  pub original_broker_id: Option<Principal>,
  pub sale_id: String,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct StableBucketData {
  pub principal: Principal,
  pub allocated_space: candid::Nat,
  pub date_added: candid::Int,
  pub version: (candid::Nat, candid::Nat, candid::Nat),
  pub b_gateway: bool,
  pub available_space: candid::Nat,
  pub allocations: Vec<((String, String), candid::Int)>,
}
pub type StableEscrowBalances = Vec<(Account, Account, String, EscrowRecord1)>;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct NftBackupChunk {
  pub sales_balances: StableSalesBalances,
  pub offers: StableOffers,
  pub collection_data: StableCollectionData,
  pub nft_ledgers: StableNftLedger,
  pub canister: Principal,
  pub allocations: Vec<((String, String), AllocationRecordStable)>,
  pub nft_sales: Vec<(String, SaleStatusShared)>,
  pub buckets: Vec<(Principal, StableBucketData)>,
  pub escrow_balances: StableEscrowBalances,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum NftCanisterBackUpRet {
  #[serde(rename = "eof")] Eof(NftBackupChunk),
  #[serde(rename = "data")] Data(NftBackupChunk),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct StakeRecord {
  pub staker: Account,
  pub token_id: String,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct BalanceResponse {
  pub nfts: Vec<String>,
  pub offers: Vec<EscrowRecord1>,
  pub sales: Vec<EscrowRecord1>,
  pub stake: Vec<StakeRecord>,
  pub multi_canister: Option<Vec<Principal>>,
  pub escrow: Vec<EscrowRecord1>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum Errors {
  #[serde(rename = "nyi")]
  Nyi,
  #[serde(rename = "storage_configuration_error")]
  StorageConfigurationError,
  #[serde(rename = "escrow_withdraw_payment_failed")]
  EscrowWithdrawPaymentFailed,
  #[serde(rename = "token_not_found")]
  TokenNotFound,
  #[serde(rename = "owner_not_found")]
  OwnerNotFound,
  #[serde(rename = "content_not_found")]
  ContentNotFound,
  #[serde(rename = "auction_ended")]
  AuctionEnded,
  #[serde(rename = "out_of_range")]
  OutOfRange,
  #[serde(rename = "sale_id_does_not_match")]
  SaleIdDoesNotMatch,
  #[serde(rename = "sale_not_found")]
  SaleNotFound,
  #[serde(rename = "item_not_owned")]
  ItemNotOwned,
  #[serde(rename = "property_not_found")]
  PropertyNotFound,
  #[serde(rename = "validate_trx_wrong_host")]
  ValidateTrxWrongHost,
  #[serde(rename = "withdraw_too_large")]
  WithdrawTooLarge,
  #[serde(rename = "content_not_deserializable")]
  ContentNotDeserializable,
  #[serde(rename = "bid_too_low")]
  BidTooLow,
  #[serde(rename = "validate_deposit_wrong_amount")]
  ValidateDepositWrongAmount,
  #[serde(rename = "existing_sale_found")]
  ExistingSaleFound,
  #[serde(rename = "noop")]
  Noop,
  #[serde(rename = "asset_mismatch")]
  AssetMismatch,
  #[serde(rename = "escrow_cannot_be_removed")]
  EscrowCannotBeRemoved,
  #[serde(rename = "deposit_burned")]
  DepositBurned,
  #[serde(rename = "cannot_restage_minted_token")]
  CannotRestageMintedToken,
  #[serde(rename = "cannot_find_status_in_metadata")]
  CannotFindStatusInMetadata,
  #[serde(rename = "receipt_data_mismatch")]
  ReceiptDataMismatch,
  #[serde(rename = "validate_deposit_failed")]
  ValidateDepositFailed,
  #[serde(rename = "unreachable")]
  Unreachable,
  #[serde(rename = "unauthorized_access")]
  UnauthorizedAccess,
  #[serde(rename = "item_already_minted")]
  ItemAlreadyMinted,
  #[serde(rename = "no_escrow_found")]
  NoEscrowFound,
  #[serde(rename = "escrow_owner_not_the_owner")]
  EscrowOwnerNotTheOwner,
  #[serde(rename = "improper_interface")]
  ImproperInterface,
  #[serde(rename = "app_id_not_found")]
  AppIdNotFound,
  #[serde(rename = "token_non_transferable")]
  TokenNonTransferable,
  #[serde(rename = "sale_not_over")]
  SaleNotOver,
  #[serde(rename = "escrow_not_large_enough")]
  EscrowNotLargeEnough,
  #[serde(rename = "update_class_error")]
  UpdateClassError,
  #[serde(rename = "malformed_metadata")]
  MalformedMetadata,
  #[serde(rename = "token_id_mismatch")]
  TokenIdMismatch,
  #[serde(rename = "id_not_found_in_metadata")]
  IdNotFoundInMetadata,
  #[serde(rename = "auction_not_started")]
  AuctionNotStarted,
  #[serde(rename = "low_fee_balance")]
  LowFeeBalance,
  #[serde(rename = "library_not_found")]
  LibraryNotFound,
  #[serde(rename = "attempt_to_stage_system_data")]
  AttemptToStageSystemData,
  #[serde(rename = "no_fee_accounts_provided")]
  NoFeeAccountsProvided,
  #[serde(rename = "validate_deposit_wrong_buyer")]
  ValidateDepositWrongBuyer,
  #[serde(rename = "not_enough_storage")]
  NotEnoughStorage,
  #[serde(rename = "sales_withdraw_payment_failed")]
  SalesWithdrawPaymentFailed,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct OrigynError {
  pub text: String,
  pub error: Errors,
  pub number: u32,
  pub flag_point: String,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum BalanceResult {
  #[serde(rename = "ok")] Ok(BalanceResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum BearerResult {
  #[serde(rename = "ok")] Ok(Account),
  #[serde(rename = "err")] Err(OrigynError),
}
pub type CanisterId = Principal;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct NftCanisterCanisterStatusArg {
  pub canister_id: CanisterId,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum CanisterStatusStatus {
  #[serde(rename = "stopped")]
  Stopped,
  #[serde(rename = "stopping")]
  Stopping,
  #[serde(rename = "running")]
  Running,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct DefiniteCanisterSettings {
  pub freezing_threshold: candid::Nat,
  pub controllers: Option<Vec<Principal>>,
  pub memory_allocation: candid::Nat,
  pub compute_allocation: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct CanisterStatus {
  pub status: CanisterStatusStatus,
  pub memory_size: candid::Nat,
  pub cycles: candid::Nat,
  pub settings: DefiniteCanisterSettings,
  pub module_hash: Option<serde_bytes::ByteBuf>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct ChunkRequest {
  pub token_id: String,
  pub chunk: Option<candid::Nat>,
  pub library_id: String,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum ChunkContent {
  #[serde(rename = "remote")] Remote {
    args: ChunkRequest,
    canister: Principal,
  },
  #[serde(rename = "chunk")] Chunk {
    total_chunks: candid::Nat,
    content: serde_bytes::ByteBuf,
    storage_allocation: AllocationRecordStable,
    current_chunk: Option<candid::Nat>,
  },
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum ChunkResult {
  #[serde(rename = "ok")] Ok(ChunkContent),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct CollectionInfo {
  pub multi_canister_count: Option<candid::Nat>,
  pub managers: Option<Vec<Principal>>,
  pub owner: Option<Principal>,
  pub metadata: Option<Box<CandyShared>>,
  pub logo: Option<String>,
  pub name: Option<String>,
  pub network: Option<Principal>,
  pub created_at: Option<u64>,
  pub fields: Option<Vec<(String, Option<candid::Nat>, Option<candid::Nat>)>>,
  pub upgraded_at: Option<u64>,
  pub token_ids_count: Option<candid::Nat>,
  pub available_space: Option<candid::Nat>,
  pub multi_canister: Option<Vec<Principal>>,
  pub token_ids: Option<Vec<String>>,
  pub transaction_count: Option<candid::Nat>,
  pub unique_holders: Option<candid::Nat>,
  pub total_supply: Option<candid::Nat>,
  pub symbol: Option<String>,
  pub allocated_storage: Option<candid::Nat>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum CollectionResult {
  #[serde(rename = "ok")] Ok(CollectionInfo),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum ManageCollectionCommand {
  UpdateOwner(Principal),
  UpdateManagers(Vec<Principal>),
  UpdateMetadata(String, Option<Box<CandyShared>>, bool),
  UpdateAnnounceCanister(Option<Principal>),
  UpdateNetwork(Option<Principal>),
  UpdateSymbol(Option<String>),
  UpdateLogo(Option<String>),
  UpdateName(Option<String>),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum OrigynBoolResult {
  #[serde(rename = "ok")] Ok(bool),
  #[serde(rename = "err")] Err(OrigynError),
}
pub type Subaccount = serde_bytes::ByteBuf;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct Account {
  pub owner: Principal,
  pub subaccount: Option<Subaccount>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum OrigynTextResult {
  #[serde(rename = "ok")] Ok(String),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct Tip {
  pub last_block_index: serde_bytes::ByteBuf,
  pub hash_tree: serde_bytes::ByteBuf,
  pub last_block_hash: serde_bytes::ByteBuf,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum GovernanceRequest {
  #[serde(rename = "update_system_var")] UpdateSystemVar {
    key: String,
    val: Box<CandyShared>,
    token_id: String,
  },
  #[serde(rename = "clear_shared_wallets")] ClearSharedWallets(String),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum GovernanceResponse {
  #[serde(rename = "update_system_var")] UpdateSystemVar(bool),
  #[serde(rename = "clear_shared_wallets")] ClearSharedWallets(bool),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum GovernanceResult {
  #[serde(rename = "ok")] Ok(GovernanceResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum HistoryResult {
  #[serde(rename = "ok")] Ok(Vec<TransactionRecord>),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct HeaderField(pub String, pub String);
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct HttpRequest {
  pub url: String,
  pub method: String,
  pub body: serde_bytes::ByteBuf,
  pub headers: Vec<HeaderField>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct StreamingCallbackToken {
  pub key: String,
  pub index: candid::Nat,
  pub content_encoding: String,
}
candid::define_function!(pub StreamingStrategyCallbackCallback : () -> ());
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum StreamingStrategy {
  Callback {
    token: StreamingCallbackToken,
    callback: StreamingStrategyCallbackCallback,
  },
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct HttpResponse {
  pub body: serde_bytes::ByteBuf,
  pub headers: Vec<HeaderField>,
  pub streaming_strategy: Option<StreamingStrategy>,
  pub status_code: u16,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct StreamingCallbackResponse {
  pub token: Option<StreamingCallbackToken>,
  pub body: serde_bytes::ByteBuf,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct GetArchivesArgs {
  pub from: Option<Principal>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct GetArchivesResultItem {
  pub end: candid::Nat,
  pub canister_id: Principal,
  pub start: candid::Nat,
}
pub type GetArchivesResult = Vec<GetArchivesResultItem>;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct TransactionRange {
  pub start: candid::Nat,
  pub length: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum Value1 {
  Int(candid::Int),
  Map(Vec<(String, Box<Value1>)>),
  Nat(candid::Nat),
  Blob(serde_bytes::ByteBuf),
  Text(String),
  Array(Vec<Box<Value1>>),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct GetTransactionsResultBlocksItem {
  pub id: candid::Nat,
  pub block: Box<Value1>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct TransactionRange1 {
  pub start: candid::Nat,
  pub length: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct GetTransactionsResult1BlocksItem {
  pub id: candid::Nat,
  pub block: Box<Value1>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct GetTransactionsResult1 {
  pub log_length: candid::Nat,
  pub blocks: Vec<GetTransactionsResult1BlocksItem>,
  pub archived_blocks: Vec<Box<ArchivedTransactionResponse>>,
}
candid::define_function!(pub GetTransactionsFn : (Vec<TransactionRange1>) -> (
    GetTransactionsResult1,
  ) query);
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct ArchivedTransactionResponse {
  pub args: Vec<TransactionRange1>,
  pub callback: GetTransactionsFn,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct GetTransactionsResult {
  pub log_length: candid::Nat,
  pub blocks: Vec<GetTransactionsResultBlocksItem>,
  pub archived_blocks: Vec<Box<ArchivedTransactionResponse>>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct DataCertificate {
  pub certificate: serde_bytes::ByteBuf,
  pub hash_tree: serde_bytes::ByteBuf,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct BlockType {
  pub url: String,
  pub block_type: String,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct ApprovalArgs {
  pub memo: Option<serde_bytes::ByteBuf>,
  pub from_subaccount: Option<serde_bytes::ByteBuf>,
  pub created_at_time: Option<u64>,
  pub expires_at: Option<u64>,
  pub spender: Account,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum ApprovalError {
  GenericError {
    message: String,
    error_code: candid::Nat,
  },
  CreatexInFuture {
    ledger_time: u64,
  },
  NonExistingTokenId,
  Unauthorized,
  TooOld,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum ApprovalResultItemApprovalResult {
  Ok(candid::Nat),
  Err(ApprovalError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct ApprovalResultItem {
  pub token_id: candid::Nat,
  pub approval_result: ApprovalResultItemApprovalResult,
}
pub type ApprovalResult = Vec<ApprovalResultItem>;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum Value {
  Int(candid::Int),
  Map(Vec<(String, Box<Value>)>),
  Nat(candid::Nat),
  Blob(serde_bytes::ByteBuf),
  Text(String),
  Array(Vec<Box<Value>>),
}
pub type CollectionMetadata = Vec<(String, Box<Value>)>;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct SupportedStandard {
  pub url: String,
  pub name: String,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct TransferArgs {
  pub to: Account,
  pub token_id: candid::Nat,
  pub memo: Option<serde_bytes::ByteBuf>,
  pub from_subaccount: Option<serde_bytes::ByteBuf>,
  pub created_at_time: Option<u64>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum TransferError {
  GenericError {
    message: String,
    error_code: candid::Nat,
  },
  Duplicate {
    duplicate_of: candid::Nat,
  },
  NonExistingTokenId,
  Unauthorized,
  CreatedInFuture {
    ledger_time: u64,
  },
  TooOld,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum TransferResultItemTransferResult {
  Ok(candid::Nat),
  Err(TransferError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct TransferResultItem {
  pub token_id: candid::Nat,
  pub transfer_result: TransferResultItemTransferResult,
}
pub type TransferResult = Vec<Option<TransferResultItem>>;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum ManageStorageRequestConfigureStorage {
  #[serde(rename = "stableBtree")] StableBtree(Option<candid::Nat>),
  #[serde(rename = "heap")] Heap(Option<candid::Nat>),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum ManageStorageRequest {
  #[serde(rename = "add_storage_canisters")] AddStorageCanisters(
    Vec<(Principal, candid::Nat, (candid::Nat, candid::Nat, candid::Nat))>,
  ),
  #[serde(rename = "configure_storage")] ConfigureStorage(ManageStorageRequestConfigureStorage),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum ManageStorageResponse {
  #[serde(rename = "add_storage_canisters")] AddStorageCanisters(candid::Nat, candid::Nat),
  #[serde(rename = "configure_storage")] ConfigureStorage(candid::Nat, candid::Nat),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum ManageStorageResult {
  #[serde(rename = "ok")] Ok(ManageStorageResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct EscrowReceipt1 {
  pub token: TokenSpec,
  pub token_id: String,
  pub seller: Account,
  pub buyer: Account,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct SalesConfig {
  pub broker_id: Option<Account>,
  pub pricing: PricingConfigShared,
  pub escrow_receipt: Option<EscrowReceipt1>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct MarketTransferRequest {
  pub token_id: String,
  pub sales_config: SalesConfig,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct MarketTransferRequestReponseTxnTypeMintSaleInner {
  pub token: TokenSpec,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum MarketTransferRequestReponseTxnType {
  #[serde(rename = "escrow_deposit")] EscrowDeposit {
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "fee_deposit")] FeeDeposit {
    token: TokenSpec,
    extensible: Box<CandyShared>,
    account: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "canister_network_updated")] CanisterNetworkUpdated {
    network: Principal,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "escrow_withdraw")] EscrowWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "canister_managers_updated")] CanisterManagersUpdated {
    managers: Vec<Principal>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "auction_bid")] AuctionBid {
    token: TokenSpec,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    sale_id: String,
  },
  #[serde(rename = "burn")] Burn {
    from: Option<Account>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "data")] Data {
    hash: Option<serde_bytes::ByteBuf>,
    extensible: Box<CandyShared>,
    data_dapp: Option<String>,
    data_path: Option<String>,
  },
  #[serde(rename = "sale_ended")] SaleEnded {
    token: TokenSpec,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    sale_id: Option<String>,
  },
  #[serde(rename = "mint")] Mint {
    to: Account,
    from: Account,
    sale: Option<MarketTransferRequestReponseTxnTypeMintSaleInner>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "royalty_paid")] RoyaltyPaid {
    tag: String,
    token: TokenSpec,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    receiver: Account,
    sale_id: Option<String>,
  },
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
  #[serde(rename = "fee_deposit_withdraw")] FeeDepositWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    trx_id: TransactionId,
    extensible: Box<CandyShared>,
    account: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "owner_transfer")] OwnerTransfer {
    to: Account,
    from: Account,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "sale_opened")] SaleOpened {
    pricing: PricingConfigShared,
    extensible: Box<CandyShared>,
    sale_id: String,
  },
  #[serde(rename = "canister_owner_updated")] CanisterOwnerUpdated {
    owner: Principal,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "sale_withdraw")] SaleWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "deposit_withdraw")] DepositWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    trx_id: TransactionId,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct MarketTransferRequestReponse {
  pub token_id: String,
  pub txn_type: MarketTransferRequestReponseTxnType,
  pub timestamp: candid::Int,
  pub index: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum MarketTransferResult {
  #[serde(rename = "ok")] Ok(MarketTransferRequestReponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct NftInfoStable {
  pub metadata: Box<CandyShared>,
  pub current_sale: Option<SaleStatusShared>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum NftInfoResult {
  #[serde(rename = "ok")] Ok(NftInfoStable),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct EscrowRecord {
  pub token: TokenSpec,
  pub token_id: String,
  pub seller: Account,
  pub lock_to_date: Option<candid::Int>,
  pub buyer: Account,
  pub amount: candid::Nat,
  pub sale_id: Option<String>,
  pub account_hash: Option<serde_bytes::ByteBuf>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct BidRequest {
  pub config: BidConfigShared,
  pub escrow_record: EscrowRecord,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum TransactionId1 {
  #[serde(rename = "nat")] Nat(candid::Nat),
  #[serde(rename = "text")] Text(String),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct DepositDetail {
  pub token: TokenSpec,
  pub trx_id: Option<TransactionId1>,
  pub seller: Account,
  pub buyer: Account,
  pub amount: candid::Nat,
  pub sale_id: Option<String>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct EscrowRequest {
  pub token_id: String,
  pub deposit: DepositDetail,
  pub lock_to_date: Option<candid::Int>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct FeeDepositRequest {
  pub token: TokenSpec,
  pub account: Account,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct RejectDescription {
  pub token: TokenSpec,
  pub token_id: String,
  pub seller: Account,
  pub buyer: Account,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum FeeDepositWithdrawDescriptionStatus {
  #[serde(rename = "locked")] Locked {
    token_id: String,
    sale_id: String,
  },
  #[serde(rename = "unlocked")]
  Unlocked,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct FeeDepositWithdrawDescription {
  pub status: FeeDepositWithdrawDescriptionStatus,
  pub token: TokenSpec,
  pub withdraw_to: Account,
  pub account: Account,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct WithdrawDescription {
  pub token: TokenSpec,
  pub token_id: String,
  pub seller: Account,
  pub withdraw_to: Account,
  pub buyer: Account,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct DepositWithdrawDescription {
  pub token: TokenSpec,
  pub withdraw_to: Account,
  pub buyer: Account,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum WithdrawRequest {
  #[serde(rename = "reject")] Reject(RejectDescription),
  #[serde(rename = "fee_deposit")] FeeDeposit(FeeDepositWithdrawDescription),
  #[serde(rename = "sale")] Sale(WithdrawDescription),
  #[serde(rename = "deposit")] Deposit(DepositWithdrawDescription),
  #[serde(rename = "escrow")] Escrow(WithdrawDescription),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum TokenSpecFilterFilterType {
  #[serde(rename = "allow")]
  Allow,
  #[serde(rename = "block")]
  Block,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct TokenSpecFilter {
  pub token: TokenSpec,
  pub filter_type: TokenSpecFilterFilterType,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum TokenIdFilterFilterType {
  #[serde(rename = "allow")]
  Allow,
  #[serde(rename = "block")]
  Block,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct TokenIdFilterTokensItem {
  pub token: TokenSpec,
  pub min_amount: Option<candid::Nat>,
  pub max_amount: Option<candid::Nat>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct TokenIdFilter {
  pub filter_type: TokenIdFilterFilterType,
  pub token_id: String,
  pub tokens: Vec<TokenIdFilterTokensItem>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct AskSubscribeRequestSubscribeFilterInner {
  pub tokens: Option<Vec<TokenSpecFilter>>,
  pub token_ids: Option<Vec<TokenIdFilter>>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum AskSubscribeRequest {
  #[serde(rename = "subscribe")] Subscribe {
    stake: (Principal, candid::Nat),
    filter: Option<AskSubscribeRequestSubscribeFilterInner>,
  },
  #[serde(rename = "unsubscribe")] Unsubscribe(Principal, candid::Nat),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct DistributeSaleRequest {
  pub seller: Option<Account>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum ManageSaleRequest {
  #[serde(rename = "bid")] Bid(BidRequest),
  #[serde(rename = "escrow_deposit")] EscrowDeposit(EscrowRequest),
  #[serde(rename = "fee_deposit")] FeeDeposit(FeeDepositRequest),
  #[serde(rename = "recognize_escrow")] RecognizeEscrow(EscrowRequest),
  #[serde(rename = "withdraw")] Withdraw(WithdrawRequest),
  #[serde(rename = "ask_subscribe")] AskSubscribe(AskSubscribeRequest),
  #[serde(rename = "end_sale")] EndSale(String),
  #[serde(rename = "refresh_offers")] RefreshOffers(Option<Account>),
  #[serde(rename = "distribute_sale")] DistributeSale(DistributeSaleRequest),
  #[serde(rename = "open_sale")] OpenSale(String),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct BidResponseTxnTypeMintSaleInner {
  pub token: TokenSpec,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum BidResponseTxnType {
  #[serde(rename = "escrow_deposit")] EscrowDeposit {
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "fee_deposit")] FeeDeposit {
    token: TokenSpec,
    extensible: Box<CandyShared>,
    account: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "canister_network_updated")] CanisterNetworkUpdated {
    network: Principal,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "escrow_withdraw")] EscrowWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "canister_managers_updated")] CanisterManagersUpdated {
    managers: Vec<Principal>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "auction_bid")] AuctionBid {
    token: TokenSpec,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    sale_id: String,
  },
  #[serde(rename = "burn")] Burn {
    from: Option<Account>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "data")] Data {
    hash: Option<serde_bytes::ByteBuf>,
    extensible: Box<CandyShared>,
    data_dapp: Option<String>,
    data_path: Option<String>,
  },
  #[serde(rename = "sale_ended")] SaleEnded {
    token: TokenSpec,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    sale_id: Option<String>,
  },
  #[serde(rename = "mint")] Mint {
    to: Account,
    from: Account,
    sale: Option<BidResponseTxnTypeMintSaleInner>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "royalty_paid")] RoyaltyPaid {
    tag: String,
    token: TokenSpec,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    receiver: Account,
    sale_id: Option<String>,
  },
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
  #[serde(rename = "fee_deposit_withdraw")] FeeDepositWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    trx_id: TransactionId,
    extensible: Box<CandyShared>,
    account: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "owner_transfer")] OwnerTransfer {
    to: Account,
    from: Account,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "sale_opened")] SaleOpened {
    pricing: PricingConfigShared,
    extensible: Box<CandyShared>,
    sale_id: String,
  },
  #[serde(rename = "canister_owner_updated")] CanisterOwnerUpdated {
    owner: Principal,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "sale_withdraw")] SaleWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "deposit_withdraw")] DepositWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    trx_id: TransactionId,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct BidResponse {
  pub token_id: String,
  pub txn_type: BidResponseTxnType,
  pub timestamp: candid::Int,
  pub index: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct EscrowResponse {
  pub balance: candid::Nat,
  pub receipt: EscrowReceipt,
  pub transaction: TransactionRecord,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct FeeDepositResponse {
  pub balance: candid::Nat,
  pub transaction: TransactionRecord,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct RecognizeEscrowResponse {
  pub balance: candid::Nat,
  pub receipt: EscrowReceipt,
  pub transaction: Option<TransactionRecord>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct WithdrawResponseTxnTypeMintSaleInner {
  pub token: TokenSpec,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum WithdrawResponseTxnType {
  #[serde(rename = "escrow_deposit")] EscrowDeposit {
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "fee_deposit")] FeeDeposit {
    token: TokenSpec,
    extensible: Box<CandyShared>,
    account: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "canister_network_updated")] CanisterNetworkUpdated {
    network: Principal,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "escrow_withdraw")] EscrowWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "canister_managers_updated")] CanisterManagersUpdated {
    managers: Vec<Principal>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "auction_bid")] AuctionBid {
    token: TokenSpec,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    sale_id: String,
  },
  #[serde(rename = "burn")] Burn {
    from: Option<Account>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "data")] Data {
    hash: Option<serde_bytes::ByteBuf>,
    extensible: Box<CandyShared>,
    data_dapp: Option<String>,
    data_path: Option<String>,
  },
  #[serde(rename = "sale_ended")] SaleEnded {
    token: TokenSpec,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    sale_id: Option<String>,
  },
  #[serde(rename = "mint")] Mint {
    to: Account,
    from: Account,
    sale: Option<WithdrawResponseTxnTypeMintSaleInner>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "royalty_paid")] RoyaltyPaid {
    tag: String,
    token: TokenSpec,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    receiver: Account,
    sale_id: Option<String>,
  },
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
  #[serde(rename = "fee_deposit_withdraw")] FeeDepositWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    trx_id: TransactionId,
    extensible: Box<CandyShared>,
    account: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "owner_transfer")] OwnerTransfer {
    to: Account,
    from: Account,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "sale_opened")] SaleOpened {
    pricing: PricingConfigShared,
    extensible: Box<CandyShared>,
    sale_id: String,
  },
  #[serde(rename = "canister_owner_updated")] CanisterOwnerUpdated {
    owner: Principal,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "sale_withdraw")] SaleWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "deposit_withdraw")] DepositWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    trx_id: TransactionId,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct WithdrawResponse {
  pub token_id: String,
  pub txn_type: WithdrawResponseTxnType,
  pub timestamp: candid::Int,
  pub index: candid::Nat,
}
pub type AskSubscribeResponse = bool;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct EndSaleResponseTxnTypeMintSaleInner {
  pub token: TokenSpec,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum EndSaleResponseTxnType {
  #[serde(rename = "escrow_deposit")] EscrowDeposit {
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "fee_deposit")] FeeDeposit {
    token: TokenSpec,
    extensible: Box<CandyShared>,
    account: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "canister_network_updated")] CanisterNetworkUpdated {
    network: Principal,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "escrow_withdraw")] EscrowWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "canister_managers_updated")] CanisterManagersUpdated {
    managers: Vec<Principal>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "auction_bid")] AuctionBid {
    token: TokenSpec,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    sale_id: String,
  },
  #[serde(rename = "burn")] Burn {
    from: Option<Account>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "data")] Data {
    hash: Option<serde_bytes::ByteBuf>,
    extensible: Box<CandyShared>,
    data_dapp: Option<String>,
    data_path: Option<String>,
  },
  #[serde(rename = "sale_ended")] SaleEnded {
    token: TokenSpec,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    sale_id: Option<String>,
  },
  #[serde(rename = "mint")] Mint {
    to: Account,
    from: Account,
    sale: Option<EndSaleResponseTxnTypeMintSaleInner>,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "royalty_paid")] RoyaltyPaid {
    tag: String,
    token: TokenSpec,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
    receiver: Account,
    sale_id: Option<String>,
  },
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
  #[serde(rename = "fee_deposit_withdraw")] FeeDepositWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    trx_id: TransactionId,
    extensible: Box<CandyShared>,
    account: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "owner_transfer")] OwnerTransfer {
    to: Account,
    from: Account,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "sale_opened")] SaleOpened {
    pricing: PricingConfigShared,
    extensible: Box<CandyShared>,
    sale_id: String,
  },
  #[serde(rename = "canister_owner_updated")] CanisterOwnerUpdated {
    owner: Principal,
    extensible: Box<CandyShared>,
  },
  #[serde(rename = "sale_withdraw")] SaleWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    token_id: String,
    trx_id: TransactionId,
    seller: Account,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
  #[serde(rename = "deposit_withdraw")] DepositWithdraw {
    fee: candid::Nat,
    token: TokenSpec,
    trx_id: TransactionId,
    extensible: Box<CandyShared>,
    buyer: Account,
    amount: candid::Nat,
  },
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct EndSaleResponse {
  pub token_id: String,
  pub txn_type: EndSaleResponseTxnType,
  pub timestamp: candid::Int,
  pub index: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum Result_ {
  #[serde(rename = "ok")] Ok(Box<ManageSaleResponse>),
  #[serde(rename = "err")] Err(OrigynError),
}
pub type DistributeSaleResponse = Vec<Result_>;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum ManageSaleResponse {
  #[serde(rename = "bid")] Bid(BidResponse),
  #[serde(rename = "escrow_deposit")] EscrowDeposit(EscrowResponse),
  #[serde(rename = "fee_deposit")] FeeDeposit(FeeDepositResponse),
  #[serde(rename = "recognize_escrow")] RecognizeEscrow(RecognizeEscrowResponse),
  #[serde(rename = "withdraw")] Withdraw(WithdrawResponse),
  #[serde(rename = "ask_subscribe")] AskSubscribe(AskSubscribeResponse),
  #[serde(rename = "end_sale")] EndSale(EndSaleResponse),
  #[serde(rename = "refresh_offers")] RefreshOffers(Vec<EscrowRecord1>),
  #[serde(rename = "distribute_sale")] DistributeSale(DistributeSaleResponse),
  #[serde(rename = "open_sale")] OpenSale(bool),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum ManageSaleResult {
  #[serde(rename = "ok")] Ok(Box<ManageSaleResponse>),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum SaleInfoRequest {
  #[serde(rename = "status")] Status(String),
  #[serde(rename = "fee_deposit_info")] FeeDepositInfo(Option<Account>),
  #[serde(rename = "active")] Active(Option<(candid::Nat, candid::Nat)>),
  #[serde(rename = "deposit_info")] DepositInfo(Option<Account>),
  #[serde(rename = "history")] History(Option<(candid::Nat, candid::Nat)>),
  #[serde(rename = "escrow_info")] EscrowInfo(EscrowReceipt),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum SaleInfoResponse {
  #[serde(rename = "status")] Status(Option<SaleStatusShared>),
  #[serde(rename = "fee_deposit_info")] FeeDepositInfo(Account),
  #[serde(rename = "active")] Active {
    eof: bool,
    records: Vec<(String, Option<SaleStatusShared>)>,
    count: candid::Nat,
  },
  #[serde(rename = "deposit_info")] DepositInfo(Account),
  #[serde(rename = "history")] History {
    eof: bool,
    records: Vec<Option<SaleStatusShared>>,
    count: candid::Nat,
  },
  #[serde(rename = "escrow_info")] EscrowInfo(Account),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum SaleInfoResult {
  #[serde(rename = "ok")] Ok(SaleInfoResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct ShareWalletRequest {
  pub to: Account,
  pub token_id: String,
  pub from: Account,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct OwnerTransferResponse {
  pub transaction: TransactionRecord,
  pub assets: Vec<Box<CandyShared>>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum OwnerUpdateResult {
  #[serde(rename = "ok")] Ok(OwnerTransferResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct NftCanisterStageBatchNftOrigynArgItem {
  pub metadata: Box<CandyShared>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct StageChunkArg {
  pub content: serde_bytes::ByteBuf,
  pub token_id: String,
  pub chunk: candid::Nat,
  pub filedata: Box<CandyShared>,
  pub library_id: String,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct StageLibraryResponse {
  pub canister: Principal,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum StageLibraryResult {
  #[serde(rename = "ok")] Ok(StageLibraryResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct NftCanisterStageNftOrigynArg {
  pub metadata: Box<CandyShared>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct StateSize {
  pub sales_balances: candid::Nat,
  pub offers: candid::Nat,
  pub nft_ledgers: candid::Nat,
  pub allocations: candid::Nat,
  pub nft_sales: candid::Nat,
  pub buckets: candid::Nat,
  pub escrow_balances: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct StorageMetrics {
  pub gateway: Principal,
  pub available_space: candid::Nat,
  pub allocations: Vec<AllocationRecordStable>,
  pub allocated_storage: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum StorageMetricsResult {
  #[serde(rename = "ok")] Ok(StorageMetrics),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum UpdateModeShared {
  Set(Box<CandyShared>),
  Lock(Box<CandyShared>),
  Next(Vec<Box<UpdateShared>>),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct UpdateShared {
  pub mode: UpdateModeShared,
  pub name: String,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct UpdateRequestShared {
  pub id: String,
  pub update: Vec<Box<UpdateShared>>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum NftUpdateRequest {
  #[serde(rename = "update")] Update {
    token_id: String,
    update: UpdateRequestShared,
    app_id: String,
  },
  #[serde(rename = "replace")] Replace {
    token_id: String,
    data: Box<CandyShared>,
  },
}
pub type NftUpdateResponse = bool;
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum NftUpdateResult {
  #[serde(rename = "ok")] Ok(NftUpdateResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum IndexType {
  Stable,
  StableTyped,
  Managed,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum UpdateSetting {
  #[serde(rename = "maxRecordsToArchive")] MaxRecordsToArchive(candid::Nat),
  #[serde(rename = "archiveIndexType")] ArchiveIndexType(IndexType),
  #[serde(rename = "maxArchivePages")] MaxArchivePages(candid::Nat),
  #[serde(rename = "settleToRecords")] SettleToRecords(candid::Nat),
  #[serde(rename = "archiveCycles")] ArchiveCycles(candid::Nat),
  #[serde(rename = "maxActiveRecords")] MaxActiveRecords(candid::Nat),
  #[serde(rename = "maxRecordsInArchiveInstance")] MaxRecordsInArchiveInstance(candid::Nat),
  #[serde(rename = "archiveControllers")] ArchiveControllers(Option<Option<Vec<Principal>>>),
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct NftUpdateMetadataNode {
  pub token_id: String,
  pub value: Box<CandyShared>,
  pub _system: bool,
  pub field_id: String,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub struct NftUpdateMetadataNodeResponse {
  pub property_new: PropertyShared,
  pub property_old: Option<PropertyShared>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq, Clone)]
pub enum NftUpdateAppResult {
  #[serde(rename = "ok")] Ok(NftUpdateMetadataNodeResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
candid::define_service!(pub NftCanister : {
  "__advance_time" : candid::func!((candid::Int) -> (candid::Int));
  "__set_time_mode" : candid::func!((NftCanisterSetTimeModeArg) -> (bool));
  "__version" : candid::func!(() -> (String) query);
  "back_up" : candid::func!((candid::Nat) -> (NftCanisterBackUpRet) query);
  "balance_of_batch_nft_origyn" : candid::func!(
    (Vec<Account>) -> (Vec<BalanceResult>) query
  );
  "balance_of_nft_origyn" : candid::func!((Account) -> (BalanceResult) query);
  "balance_of_secure_batch_nft_origyn" : candid::func!(
    (Vec<Account>) -> (Vec<BalanceResult>)
  );
  "balance_of_secure_nft_origyn" : candid::func!((Account) -> (BalanceResult));
  "bearer_batch_nft_origyn" : candid::func!(
    (Vec<String>) -> (Vec<BearerResult>) query
  );
  "bearer_batch_secure_nft_origyn" : candid::func!(
    (Vec<String>) -> (Vec<BearerResult>)
  );
  "bearer_nft_origyn" : candid::func!((String) -> (BearerResult) query);
  "bearer_secure_nft_origyn" : candid::func!((String) -> (BearerResult));
  "canister_status" : candid::func!(
    (NftCanisterCanisterStatusArg) -> (CanisterStatus)
  );
  "chunk_nft_origyn" : candid::func!((ChunkRequest) -> (ChunkResult) query);
  "chunk_secure_nft_origyn" : candid::func!((ChunkRequest) -> (ChunkResult));
  "collection_nft_origyn" : candid::func!(
    (Option<Vec<(String,Option<candid::Nat>,Option<candid::Nat>,)>>) -> (
        CollectionResult,
      ) query
  );
  "collection_secure_nft_origyn" : candid::func!(
    (Option<Vec<(String,Option<candid::Nat>,Option<candid::Nat>,)>>) -> (
        CollectionResult,
      )
  );
  "collection_update_batch_nft_origyn" : candid::func!(
    (Vec<ManageCollectionCommand>) -> (Vec<OrigynBoolResult>)
  );
  "collection_update_nft_origyn" : candid::func!(
    (ManageCollectionCommand) -> (OrigynBoolResult)
  );
  "count_unlisted_tokens_of" : candid::func!((Account) -> (candid::Nat) query);
  "cycles" : candid::func!(() -> (candid::Nat) query);
  "get_access_key" : candid::func!(() -> (OrigynTextResult) query);
  "get_halt" : candid::func!(() -> (bool) query);
  "get_nat_as_token_id_origyn" : candid::func!((candid::Nat) -> (String) query);
  "get_tip" : candid::func!(() -> (Tip) query);
  "get_token_id_as_nat" : candid::func!((String) -> (candid::Nat) query);
  "governance_batch_nft_origyn" : candid::func!(
    (Vec<GovernanceRequest>) -> (Vec<GovernanceResult>)
  );
  "governance_nft_origyn" : candid::func!(
    (GovernanceRequest) -> (GovernanceResult)
  );
  "history_batch_nft_origyn" : candid::func!(
    (Vec<(String,Option<candid::Nat>,Option<candid::Nat>,)>) -> (
        Vec<HistoryResult>,
      ) query
  );
  "history_batch_secure_nft_origyn" : candid::func!(
    (Vec<(String,Option<candid::Nat>,Option<candid::Nat>,)>) -> (
        Vec<HistoryResult>,
      )
  );
  "history_nft_origyn" : candid::func!(
    (String, Option<candid::Nat>, Option<candid::Nat>) -> (HistoryResult) query
  );
  "history_secure_nft_origyn" : candid::func!(
    (String, Option<candid::Nat>, Option<candid::Nat>) -> (HistoryResult)
  );
  "http_access_key" : candid::func!(() -> (OrigynTextResult));
  "http_request" : candid::func!((HttpRequest) -> (HttpResponse) query);
  "http_request_streaming_callback" : candid::func!(
    (StreamingCallbackToken) -> (StreamingCallbackResponse) query
  );
  "icrc3_get_archives" : candid::func!(
    (GetArchivesArgs) -> (GetArchivesResult) query
  );
  "icrc3_get_blocks" : candid::func!(
    (Vec<TransactionRange>) -> (GetTransactionsResult) query
  );
  "icrc3_get_tip_certificate" : candid::func!(
    () -> (Option<DataCertificate>) query
  );
  "icrc3_supported_block_types" : candid::func!(() -> (Vec<BlockType>) query);
  "icrc7_approve" : candid::func!((ApprovalArgs) -> (ApprovalResult));
  "icrc7_atomic_batch_transfers" : candid::func!(() -> (Option<bool>) query);
  "icrc7_balance_of" : candid::func!(
    (Vec<Account>) -> (Vec<candid::Nat>) query
  );
  "icrc7_collection_metadata" : candid::func!(() -> (CollectionMetadata) query);
  "icrc7_default_take_value" : candid::func!(() -> (Option<candid::Nat>) query);
  "icrc7_description" : candid::func!(() -> (Option<String>) query);
  "icrc7_logo" : candid::func!(() -> (Option<String>) query);
  "icrc7_max_approvals_per_token_or_collection" : candid::func!(
    () -> (Option<candid::Nat>) query
  );
  "icrc7_max_memo_size" : candid::func!(() -> (Option<candid::Nat>) query);
  "icrc7_max_query_batch_size" : candid::func!(
    () -> (Option<candid::Nat>) query
  );
  "icrc7_max_revoke_approvals" : candid::func!(
    () -> (Option<candid::Nat>) query
  );
  "icrc7_max_take_value" : candid::func!(() -> (Option<candid::Nat>) query);
  "icrc7_max_update_batch_size" : candid::func!(
    () -> (Option<candid::Nat>) query
  );
  "icrc7_name" : candid::func!(() -> (String) query);
  "icrc7_owner_of" : candid::func!(
    (Vec<candid::Nat>) -> (Vec<Option<Account>>) query
  );
  "icrc7_permitted_drift" : candid::func!(() -> (Option<candid::Nat>) query);
  "icrc7_supply_cap" : candid::func!(() -> (Option<candid::Nat>) query);
  "icrc7_supported_standards" : candid::func!(
    () -> (Vec<SupportedStandard>) query
  );
  "icrc7_symbol" : candid::func!(() -> (String) query);
  "icrc7_token_metadata" : candid::func!(
    (Vec<candid::Nat>) -> (Vec<Option<Vec<(String,Value,)>>>) query
  );
  "icrc7_tokens" : candid::func!(
    (Option<candid::Nat>, Option<u32>) -> (Vec<candid::Nat>) query
  );
  "icrc7_tokens_of" : candid::func!(
    (Account, Option<candid::Nat>, Option<u32>) -> (Vec<candid::Nat>) query
  );
  "icrc7_total_supply" : candid::func!(() -> (candid::Nat) query);
  "icrc7_transfer" : candid::func!((Vec<TransferArgs>) -> (TransferResult));
  "icrc7_transfer_fee" : candid::func!(
    (candid::Nat) -> (Option<candid::Nat>) query
  );
  "icrc7_tx_window" : candid::func!(() -> (Option<candid::Nat>) query);
  "manage_storage_nft_origyn" : candid::func!(
    (ManageStorageRequest) -> (ManageStorageResult)
  );
  "market_transfer_batch_nft_origyn" : candid::func!(
    (Vec<MarketTransferRequest>) -> (Vec<MarketTransferResult>)
  );
  "market_transfer_nft_origyn" : candid::func!(
    (MarketTransferRequest) -> (MarketTransferResult)
  );
  "mint_batch_nft_origyn" : candid::func!(
    (Vec<(String,Account,)>) -> (Vec<OrigynTextResult>)
  );
  "mint_nft_origyn" : candid::func!((String, Account) -> (OrigynTextResult));
  "nftStreamingCallback" : candid::func!(
    (StreamingCallbackToken) -> (StreamingCallbackResponse) query
  );
  "nft_batch_origyn" : candid::func!(
    (Vec<String>) -> (Vec<NftInfoResult>) query
  );
  "nft_batch_secure_origyn" : candid::func!(
    (Vec<String>) -> (Vec<NftInfoResult>)
  );
  "nft_origyn" : candid::func!((String) -> (NftInfoResult) query);
  "nft_secure_origyn" : candid::func!((String) -> (NftInfoResult));
  "sale_batch_nft_origyn" : candid::func!(
    (Vec<ManageSaleRequest>) -> (Vec<ManageSaleResult>)
  );
  "sale_info_batch_nft_origyn" : candid::func!(
    (Vec<SaleInfoRequest>) -> (Vec<SaleInfoResult>) query
  );
  "sale_info_batch_secure_nft_origyn" : candid::func!(
    (Vec<SaleInfoRequest>) -> (Vec<SaleInfoResult>)
  );
  "sale_info_nft_origyn" : candid::func!(
    (SaleInfoRequest) -> (SaleInfoResult) query
  );
  "sale_info_secure_nft_origyn" : candid::func!(
    (SaleInfoRequest) -> (SaleInfoResult)
  );
  "sale_nft_origyn" : candid::func!((ManageSaleRequest) -> (ManageSaleResult));
  "set_data_harvester" : candid::func!((candid::Nat) -> ());
  "set_halt" : candid::func!((bool) -> ());
  "share_wallet_nft_origyn" : candid::func!(
    (ShareWalletRequest) -> (OwnerUpdateResult)
  );
  "stage_batch_nft_origyn" : candid::func!(
    (Vec<NftCanisterStageBatchNftOrigynArgItem>) -> (Vec<OrigynTextResult>)
  );
  "stage_library_batch_nft_origyn" : candid::func!(
    (Vec<StageChunkArg>) -> (Vec<StageLibraryResult>)
  );
  "stage_library_nft_origyn" : candid::func!(
    (StageChunkArg) -> (StageLibraryResult)
  );
  "stage_nft_origyn" : candid::func!(
    (NftCanisterStageNftOrigynArg) -> (OrigynTextResult)
  );
  "state_size" : candid::func!(() -> (StateSize) query);
  "storage_info_nft_origyn" : candid::func!(() -> (StorageMetricsResult) query);
  "storage_info_secure_nft_origyn" : candid::func!(
    () -> (StorageMetricsResult)
  );
  "unlisted_tokens_of" : candid::func!(
    (Account, Option<candid::Nat>, Option<u32>) -> (Vec<candid::Nat>) query
  );
  "update_app_nft_origyn" : candid::func!(
    (NftUpdateRequest) -> (NftUpdateResult)
  );
  "update_icrc3" : candid::func!((Vec<UpdateSetting>) -> (Vec<bool>));
  "update_metadata_node" : candid::func!(
    (NftUpdateMetadataNode) -> (NftUpdateAppResult)
  );
  "wallet_receive" : candid::func!(() -> (candid::Nat));
  "whoami" : candid::func!(() -> (Principal) query);
});

pub struct Service(pub Principal);
impl Service {
  pub async fn advance_time(&self, arg0: candid::Int) -> Result<(candid::Int,)> {
    ic_cdk::call(self.0, "__advance_time", (arg0,)).await
  }
  pub async fn set_time_mode(&self, arg0: NftCanisterSetTimeModeArg) -> Result<(bool,)> {
    ic_cdk::call(self.0, "__set_time_mode", (arg0,)).await
  }
  pub async fn version(&self) -> Result<(String,)> {
    ic_cdk::call(self.0, "__version", ()).await
  }
  pub async fn back_up(&self, arg0: candid::Nat) -> Result<(NftCanisterBackUpRet,)> {
    ic_cdk::call(self.0, "back_up", (arg0,)).await
  }
  pub async fn balance_of_batch_nft_origyn(
    &self,
    arg0: Vec<Account>
  ) -> Result<(Vec<BalanceResult>,)> {
    ic_cdk::call(self.0, "balance_of_batch_nft_origyn", (arg0,)).await
  }
  pub async fn balance_of_nft_origyn(&self, arg0: Account) -> Result<(BalanceResult,)> {
    ic_cdk::call(self.0, "balance_of_nft_origyn", (arg0,)).await
  }
  pub async fn balance_of_secure_batch_nft_origyn(
    &self,
    arg0: Vec<Account>
  ) -> Result<(Vec<BalanceResult>,)> {
    ic_cdk::call(self.0, "balance_of_secure_batch_nft_origyn", (arg0,)).await
  }
  pub async fn balance_of_secure_nft_origyn(&self, arg0: Account) -> Result<(BalanceResult,)> {
    ic_cdk::call(self.0, "balance_of_secure_nft_origyn", (arg0,)).await
  }
  pub async fn bearer_batch_nft_origyn(&self, arg0: Vec<String>) -> Result<(Vec<BearerResult>,)> {
    ic_cdk::call(self.0, "bearer_batch_nft_origyn", (arg0,)).await
  }
  pub async fn bearer_batch_secure_nft_origyn(
    &self,
    arg0: Vec<String>
  ) -> Result<(Vec<BearerResult>,)> {
    ic_cdk::call(self.0, "bearer_batch_secure_nft_origyn", (arg0,)).await
  }
  pub async fn bearer_nft_origyn(&self, arg0: String) -> Result<(BearerResult,)> {
    ic_cdk::call(self.0, "bearer_nft_origyn", (arg0,)).await
  }
  pub async fn bearer_secure_nft_origyn(&self, arg0: String) -> Result<(BearerResult,)> {
    ic_cdk::call(self.0, "bearer_secure_nft_origyn", (arg0,)).await
  }
  pub async fn canister_status(
    &self,
    arg0: NftCanisterCanisterStatusArg
  ) -> Result<(CanisterStatus,)> {
    ic_cdk::call(self.0, "canister_status", (arg0,)).await
  }
  pub async fn chunk_nft_origyn(&self, arg0: ChunkRequest) -> Result<(ChunkResult,)> {
    ic_cdk::call(self.0, "chunk_nft_origyn", (arg0,)).await
  }
  pub async fn chunk_secure_nft_origyn(&self, arg0: ChunkRequest) -> Result<(ChunkResult,)> {
    ic_cdk::call(self.0, "chunk_secure_nft_origyn", (arg0,)).await
  }
  pub async fn collection_nft_origyn(
    &self,
    arg0: Option<Vec<(String, Option<candid::Nat>, Option<candid::Nat>)>>
  ) -> Result<(CollectionResult,)> {
    ic_cdk::call(self.0, "collection_nft_origyn", (arg0,)).await
  }
  pub async fn collection_secure_nft_origyn(
    &self,
    arg0: Option<Vec<(String, Option<candid::Nat>, Option<candid::Nat>)>>
  ) -> Result<(CollectionResult,)> {
    ic_cdk::call(self.0, "collection_secure_nft_origyn", (arg0,)).await
  }
  pub async fn collection_update_batch_nft_origyn(
    &self,
    arg0: Vec<ManageCollectionCommand>
  ) -> Result<(Vec<OrigynBoolResult>,)> {
    ic_cdk::call(self.0, "collection_update_batch_nft_origyn", (arg0,)).await
  }
  pub async fn collection_update_nft_origyn(
    &self,
    arg0: ManageCollectionCommand
  ) -> Result<(OrigynBoolResult,)> {
    ic_cdk::call(self.0, "collection_update_nft_origyn", (arg0,)).await
  }
  pub async fn count_unlisted_tokens_of(&self, arg0: Account) -> Result<(candid::Nat,)> {
    ic_cdk::call(self.0, "count_unlisted_tokens_of", (arg0,)).await
  }
  pub async fn cycles(&self) -> Result<(candid::Nat,)> {
    ic_cdk::call(self.0, "cycles", ()).await
  }
  pub async fn get_access_key(&self) -> Result<(OrigynTextResult,)> {
    ic_cdk::call(self.0, "get_access_key", ()).await
  }
  pub async fn get_halt(&self) -> Result<(bool,)> {
    ic_cdk::call(self.0, "get_halt", ()).await
  }
  pub async fn get_nat_as_token_id_origyn(&self, arg0: candid::Nat) -> Result<(String,)> {
    ic_cdk::call(self.0, "get_nat_as_token_id_origyn", (arg0,)).await
  }
  pub async fn get_tip(&self) -> Result<(Tip,)> {
    ic_cdk::call(self.0, "get_tip", ()).await
  }
  pub async fn get_token_id_as_nat(&self, arg0: String) -> Result<(candid::Nat,)> {
    ic_cdk::call(self.0, "get_token_id_as_nat", (arg0,)).await
  }
  pub async fn governance_batch_nft_origyn(
    &self,
    arg0: Vec<GovernanceRequest>
  ) -> Result<(Vec<GovernanceResult>,)> {
    ic_cdk::call(self.0, "governance_batch_nft_origyn", (arg0,)).await
  }
  pub async fn governance_nft_origyn(
    &self,
    arg0: GovernanceRequest
  ) -> Result<(GovernanceResult,)> {
    ic_cdk::call(self.0, "governance_nft_origyn", (arg0,)).await
  }
  pub async fn history_batch_nft_origyn(
    &self,
    arg0: Vec<(String, Option<candid::Nat>, Option<candid::Nat>)>
  ) -> Result<(Vec<HistoryResult>,)> {
    ic_cdk::call(self.0, "history_batch_nft_origyn", (arg0,)).await
  }
  pub async fn history_batch_secure_nft_origyn(
    &self,
    arg0: Vec<(String, Option<candid::Nat>, Option<candid::Nat>)>
  ) -> Result<(Vec<HistoryResult>,)> {
    ic_cdk::call(self.0, "history_batch_secure_nft_origyn", (arg0,)).await
  }
  pub async fn history_nft_origyn(
    &self,
    arg0: String,
    arg1: Option<candid::Nat>,
    arg2: Option<candid::Nat>
  ) -> Result<(HistoryResult,)> {
    ic_cdk::call(self.0, "history_nft_origyn", (arg0, arg1, arg2)).await
  }
  pub async fn history_secure_nft_origyn(
    &self,
    arg0: String,
    arg1: Option<candid::Nat>,
    arg2: Option<candid::Nat>
  ) -> Result<(HistoryResult,)> {
    ic_cdk::call(self.0, "history_secure_nft_origyn", (arg0, arg1, arg2)).await
  }
  pub async fn http_access_key(&self) -> Result<(OrigynTextResult,)> {
    ic_cdk::call(self.0, "http_access_key", ()).await
  }
  pub async fn http_request(&self, arg0: HttpRequest) -> Result<(HttpResponse,)> {
    ic_cdk::call(self.0, "http_request", (arg0,)).await
  }
  pub async fn http_request_streaming_callback(
    &self,
    arg0: StreamingCallbackToken
  ) -> Result<(StreamingCallbackResponse,)> {
    ic_cdk::call(self.0, "http_request_streaming_callback", (arg0,)).await
  }
  pub async fn icrc_3_get_archives(&self, arg0: GetArchivesArgs) -> Result<(GetArchivesResult,)> {
    ic_cdk::call(self.0, "icrc3_get_archives", (arg0,)).await
  }
  pub async fn icrc_3_get_blocks(
    &self,
    arg0: Vec<TransactionRange>
  ) -> Result<(GetTransactionsResult,)> {
    ic_cdk::call(self.0, "icrc3_get_blocks", (arg0,)).await
  }
  pub async fn icrc_3_get_tip_certificate(&self) -> Result<(Option<DataCertificate>,)> {
    ic_cdk::call(self.0, "icrc3_get_tip_certificate", ()).await
  }
  pub async fn icrc_3_supported_block_types(&self) -> Result<(Vec<BlockType>,)> {
    ic_cdk::call(self.0, "icrc3_supported_block_types", ()).await
  }
  pub async fn icrc_7_approve(&self, arg0: ApprovalArgs) -> Result<(ApprovalResult,)> {
    ic_cdk::call(self.0, "icrc7_approve", (arg0,)).await
  }
  pub async fn icrc_7_atomic_batch_transfers(&self) -> Result<(Option<bool>,)> {
    ic_cdk::call(self.0, "icrc7_atomic_batch_transfers", ()).await
  }
  pub async fn icrc_7_balance_of(&self, arg0: Vec<Account>) -> Result<(Vec<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_balance_of", (arg0,)).await
  }
  pub async fn icrc_7_collection_metadata(&self) -> Result<(CollectionMetadata,)> {
    ic_cdk::call(self.0, "icrc7_collection_metadata", ()).await
  }
  pub async fn icrc_7_default_take_value(&self) -> Result<(Option<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_default_take_value", ()).await
  }
  pub async fn icrc_7_description(&self) -> Result<(Option<String>,)> {
    ic_cdk::call(self.0, "icrc7_description", ()).await
  }
  pub async fn icrc_7_logo(&self) -> Result<(Option<String>,)> {
    ic_cdk::call(self.0, "icrc7_logo", ()).await
  }
  pub async fn icrc_7_max_approvals_per_token_or_collection(
    &self
  ) -> Result<(Option<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_max_approvals_per_token_or_collection", ()).await
  }
  pub async fn icrc_7_max_memo_size(&self) -> Result<(Option<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_max_memo_size", ()).await
  }
  pub async fn icrc_7_max_query_batch_size(&self) -> Result<(Option<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_max_query_batch_size", ()).await
  }
  pub async fn icrc_7_max_revoke_approvals(&self) -> Result<(Option<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_max_revoke_approvals", ()).await
  }
  pub async fn icrc_7_max_take_value(&self) -> Result<(Option<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_max_take_value", ()).await
  }
  pub async fn icrc_7_max_update_batch_size(&self) -> Result<(Option<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_max_update_batch_size", ()).await
  }
  pub async fn icrc_7_name(&self) -> Result<(String,)> {
    ic_cdk::call(self.0, "icrc7_name", ()).await
  }
  pub async fn icrc_7_owner_of(&self, arg0: Vec<candid::Nat>) -> Result<(Vec<Option<Account>>,)> {
    ic_cdk::call(self.0, "icrc7_owner_of", (arg0,)).await
  }
  pub async fn icrc_7_permitted_drift(&self) -> Result<(Option<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_permitted_drift", ()).await
  }
  pub async fn icrc_7_supply_cap(&self) -> Result<(Option<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_supply_cap", ()).await
  }
  pub async fn icrc_7_supported_standards(&self) -> Result<(Vec<SupportedStandard>,)> {
    ic_cdk::call(self.0, "icrc7_supported_standards", ()).await
  }
  pub async fn icrc_7_symbol(&self) -> Result<(String,)> {
    ic_cdk::call(self.0, "icrc7_symbol", ()).await
  }
  pub async fn icrc_7_token_metadata(
    &self,
    arg0: Vec<candid::Nat>
  ) -> Result<(Vec<Option<Vec<(String, Value)>>>,)> {
    ic_cdk::call(self.0, "icrc7_token_metadata", (arg0,)).await
  }
  pub async fn icrc_7_tokens(
    &self,
    arg0: Option<candid::Nat>,
    arg1: Option<u32>
  ) -> Result<(Vec<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_tokens", (arg0, arg1)).await
  }
  pub async fn icrc_7_tokens_of(
    &self,
    arg0: Account,
    arg1: Option<candid::Nat>,
    arg2: Option<u32>
  ) -> Result<(Vec<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_tokens_of", (arg0, arg1, arg2)).await
  }
  pub async fn icrc_7_total_supply(&self) -> Result<(candid::Nat,)> {
    ic_cdk::call(self.0, "icrc7_total_supply", ()).await
  }
  pub async fn icrc_7_transfer(&self, arg0: Vec<TransferArgs>) -> Result<(TransferResult,)> {
    ic_cdk::call(self.0, "icrc7_transfer", (arg0,)).await
  }
  pub async fn icrc_7_transfer_fee(&self, arg0: candid::Nat) -> Result<(Option<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_transfer_fee", (arg0,)).await
  }
  pub async fn icrc_7_tx_window(&self) -> Result<(Option<candid::Nat>,)> {
    ic_cdk::call(self.0, "icrc7_tx_window", ()).await
  }
  pub async fn manage_storage_nft_origyn(
    &self,
    arg0: ManageStorageRequest
  ) -> Result<(ManageStorageResult,)> {
    ic_cdk::call(self.0, "manage_storage_nft_origyn", (arg0,)).await
  }
  pub async fn market_transfer_batch_nft_origyn(
    &self,
    arg0: Vec<MarketTransferRequest>
  ) -> Result<(Vec<MarketTransferResult>,)> {
    ic_cdk::call(self.0, "market_transfer_batch_nft_origyn", (arg0,)).await
  }
  pub async fn market_transfer_nft_origyn(
    &self,
    arg0: MarketTransferRequest
  ) -> Result<(MarketTransferResult,)> {
    ic_cdk::call(self.0, "market_transfer_nft_origyn", (arg0,)).await
  }
  pub async fn mint_batch_nft_origyn(
    &self,
    arg0: Vec<(String, Account)>
  ) -> Result<(Vec<OrigynTextResult>,)> {
    ic_cdk::call(self.0, "mint_batch_nft_origyn", (arg0,)).await
  }
  pub async fn mint_nft_origyn(&self, arg0: String, arg1: Account) -> Result<(OrigynTextResult,)> {
    ic_cdk::call(self.0, "mint_nft_origyn", (arg0, arg1)).await
  }
  pub async fn nft_streaming_callback(
    &self,
    arg0: StreamingCallbackToken
  ) -> Result<(StreamingCallbackResponse,)> {
    ic_cdk::call(self.0, "nftStreamingCallback", (arg0,)).await
  }
  pub async fn nft_batch_origyn(&self, arg0: Vec<String>) -> Result<(Vec<NftInfoResult>,)> {
    ic_cdk::call(self.0, "nft_batch_origyn", (arg0,)).await
  }
  pub async fn nft_batch_secure_origyn(&self, arg0: Vec<String>) -> Result<(Vec<NftInfoResult>,)> {
    ic_cdk::call(self.0, "nft_batch_secure_origyn", (arg0,)).await
  }
  pub async fn nft_origyn(&self, arg0: String) -> Result<(NftInfoResult,)> {
    ic_cdk::call(self.0, "nft_origyn", (arg0,)).await
  }
  pub async fn nft_secure_origyn(&self, arg0: String) -> Result<(NftInfoResult,)> {
    ic_cdk::call(self.0, "nft_secure_origyn", (arg0,)).await
  }
  pub async fn sale_batch_nft_origyn(
    &self,
    arg0: Vec<ManageSaleRequest>
  ) -> Result<(Vec<ManageSaleResult>,)> {
    ic_cdk::call(self.0, "sale_batch_nft_origyn", (arg0,)).await
  }
  pub async fn sale_info_batch_nft_origyn(
    &self,
    arg0: Vec<SaleInfoRequest>
  ) -> Result<(Vec<SaleInfoResult>,)> {
    ic_cdk::call(self.0, "sale_info_batch_nft_origyn", (arg0,)).await
  }
  pub async fn sale_info_batch_secure_nft_origyn(
    &self,
    arg0: Vec<SaleInfoRequest>
  ) -> Result<(Vec<SaleInfoResult>,)> {
    ic_cdk::call(self.0, "sale_info_batch_secure_nft_origyn", (arg0,)).await
  }
  pub async fn sale_info_nft_origyn(&self, arg0: SaleInfoRequest) -> Result<(SaleInfoResult,)> {
    ic_cdk::call(self.0, "sale_info_nft_origyn", (arg0,)).await
  }
  pub async fn sale_info_secure_nft_origyn(
    &self,
    arg0: SaleInfoRequest
  ) -> Result<(SaleInfoResult,)> {
    ic_cdk::call(self.0, "sale_info_secure_nft_origyn", (arg0,)).await
  }
  pub async fn sale_nft_origyn(&self, arg0: ManageSaleRequest) -> Result<(ManageSaleResult,)> {
    ic_cdk::call(self.0, "sale_nft_origyn", (arg0,)).await
  }
  pub async fn set_data_harvester(&self, arg0: candid::Nat) -> Result<()> {
    ic_cdk::call(self.0, "set_data_harvester", (arg0,)).await
  }
  pub async fn set_halt(&self, arg0: bool) -> Result<()> {
    ic_cdk::call(self.0, "set_halt", (arg0,)).await
  }
  pub async fn share_wallet_nft_origyn(
    &self,
    arg0: ShareWalletRequest
  ) -> Result<(OwnerUpdateResult,)> {
    ic_cdk::call(self.0, "share_wallet_nft_origyn", (arg0,)).await
  }
  pub async fn stage_batch_nft_origyn(
    &self,
    arg0: Vec<NftCanisterStageBatchNftOrigynArgItem>
  ) -> Result<(Vec<OrigynTextResult>,)> {
    ic_cdk::call(self.0, "stage_batch_nft_origyn", (arg0,)).await
  }
  pub async fn stage_library_batch_nft_origyn(
    &self,
    arg0: Vec<StageChunkArg>
  ) -> Result<(Vec<StageLibraryResult>,)> {
    ic_cdk::call(self.0, "stage_library_batch_nft_origyn", (arg0,)).await
  }
  pub async fn stage_library_nft_origyn(
    &self,
    arg0: StageChunkArg
  ) -> Result<(StageLibraryResult,)> {
    ic_cdk::call(self.0, "stage_library_nft_origyn", (arg0,)).await
  }
  pub async fn stage_nft_origyn(
    &self,
    arg0: NftCanisterStageNftOrigynArg
  ) -> Result<(OrigynTextResult,)> {
    ic_cdk::call(self.0, "stage_nft_origyn", (arg0,)).await
  }
  pub async fn state_size(&self) -> Result<(StateSize,)> {
    ic_cdk::call(self.0, "state_size", ()).await
  }
  pub async fn storage_info_nft_origyn(&self) -> Result<(StorageMetricsResult,)> {
    ic_cdk::call(self.0, "storage_info_nft_origyn", ()).await
  }
  pub async fn storage_info_secure_nft_origyn(&self) -> Result<(StorageMetricsResult,)> {
    ic_cdk::call(self.0, "storage_info_secure_nft_origyn", ()).await
  }
  pub async fn unlisted_tokens_of(
    &self,
    arg0: Account,
    arg1: Option<candid::Nat>,
    arg2: Option<u32>
  ) -> Result<(Vec<candid::Nat>,)> {
    ic_cdk::call(self.0, "unlisted_tokens_of", (arg0, arg1, arg2)).await
  }
  pub async fn update_app_nft_origyn(&self, arg0: NftUpdateRequest) -> Result<(NftUpdateResult,)> {
    ic_cdk::call(self.0, "update_app_nft_origyn", (arg0,)).await
  }
  pub async fn update_icrc_3(&self, arg0: Vec<UpdateSetting>) -> Result<(Vec<bool>,)> {
    ic_cdk::call(self.0, "update_icrc3", (arg0,)).await
  }
  pub async fn update_metadata_node(
    &self,
    arg0: NftUpdateMetadataNode
  ) -> Result<(NftUpdateAppResult,)> {
    ic_cdk::call(self.0, "update_metadata_node", (arg0,)).await
  }
  pub async fn wallet_receive(&self) -> Result<(candid::Nat,)> {
    ic_cdk::call(self.0, "wallet_receive", ()).await
  }
  pub async fn whoami(&self) -> Result<(Principal,)> {
    ic_cdk::call(self.0, "whoami", ()).await
  }
}
