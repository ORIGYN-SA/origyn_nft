// This is an experimental feature to generate Rust binding from Candid.
// You may want to manually adjust some of the types.
#![allow(dead_code, unused_imports)]
use candid::{ self, CandidType, Deserialize, Principal };
use ic_cdk::api::call::CallResult as Result;

#[derive(CandidType, Deserialize, Debug)]
pub enum NftCanisterSetTimeModeArg {
  #[serde(rename = "test")]
  Test,
  #[serde(rename = "standard")]
  Standard,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct PropertyShared {
  pub value: Box<CandyShared>,
  pub name: String,
  pub immutable: bool,
}
#[derive(CandidType, Deserialize, Debug)]
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
pub type StableSalesBalances = Vec<(Account, Account, String, EscrowRecord)>;
pub type StableOffers = Vec<(Account, Account, candid::Int)>;
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub struct IcTokenSpec {
  pub id: Option<candid::Nat>,
  pub fee: Option<candid::Nat>,
  pub decimals: candid::Nat,
  pub canister: Principal,
  pub standard: IcTokenSpecStandard,
  pub symbol: String,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum TokenSpec {
  #[serde(rename = "ic")] Ic(IcTokenSpec),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum TransactionId {
  #[serde(rename = "nat")] Nat(candid::Nat),
  #[serde(rename = "text")] Text(String),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct TransactionRecordTxnTypeMintSaleInner {
  pub token: TokenSpec,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct WaitForQuietType {
  pub max: candid::Nat,
  pub fade: f64,
  pub extension: u64,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum MinIncreaseType {
  #[serde(rename = "amount")] Amount(candid::Nat),
  #[serde(rename = "percentage")] Percentage(f64),
}
pub type FeeName = String;
pub type FeeAccountsParams = Vec<FeeName>;
#[derive(CandidType, Deserialize, Debug)]
pub struct NiftySettlementType {
  pub fixed: bool,
  pub interestRatePerSecond: f64,
  pub duration: Option<candid::Int>,
  pub expiration: Option<candid::Int>,
  pub lenderOffer: bool,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum DutchParamsTimeUnit {
  #[serde(rename = "day")] Day(candid::Nat),
  #[serde(rename = "hour")] Hour(candid::Nat),
  #[serde(rename = "minute")] Minute(candid::Nat),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum DutchParamsDecayType {
  #[serde(rename = "flat")] Flat(candid::Nat),
  #[serde(rename = "percent")] Percent(f64),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct DutchParams {
  pub time_unit: DutchParamsTimeUnit,
  pub decay_type: DutchParamsDecayType,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum EndingType {
  #[serde(rename = "date")] Date(candid::Int),
  #[serde(rename = "timeout")] Timeout(candid::Nat),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum AskFeature {
  #[serde(rename = "kyc")] Kyc(Principal),
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
#[derive(CandidType, Deserialize, Debug)]
pub enum InstantFeature {
  #[serde(rename = "fee_schema")] FeeSchema(String),
  #[serde(rename = "fee_accounts")] FeeAccounts(FeeAccountsParams),
}
pub type InstantConfigShared = Option<Vec<InstantFeature>>;
#[derive(CandidType, Deserialize, Debug)]
pub enum AuctionConfigEnding {
  #[serde(rename = "date")] Date(candid::Int),
  #[serde(rename = "wait_for_quiet")] WaitForQuiet {
    max: candid::Nat,
    date: candid::Int,
    fade: f64,
    extension: u64,
  },
}
#[derive(CandidType, Deserialize, Debug)]
pub struct AuctionConfig {
  pub start_price: candid::Nat,
  pub token: TokenSpec,
  pub reserve: Option<candid::Nat>,
  pub start_date: candid::Int,
  pub min_increase: MinIncreaseType,
  pub allow_list: Option<Vec<Principal>>,
  pub buy_now: Option<candid::Nat>,
  pub ending: AuctionConfigEnding,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum PricingConfigShared {
  #[serde(rename = "ask")] Ask(AskConfigShared),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
  #[serde(rename = "instant")] Instant(InstantConfigShared),
  #[serde(rename = "auction")] Auction(AuctionConfig),
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub struct TransactionRecord {
  pub token_id: String,
  pub txn_type: TransactionRecordTxnType,
  pub timestamp: candid::Int,
  pub index: candid::Nat,
}
pub type StableNftLedger = Vec<(String, TransactionRecord)>;
#[derive(CandidType, Deserialize, Debug)]
pub struct AllocationRecordStable {
  pub allocated_space: candid::Nat,
  pub token_id: String,
  pub available_space: candid::Nat,
  pub canister: Principal,
  pub chunks: Vec<candid::Nat>,
  pub library_id: String,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum AuctionStateSharedStatus {
  #[serde(rename = "closed")]
  Closed,
  #[serde(rename = "open")]
  Open,
  #[serde(rename = "not_started")]
  NotStarted,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum BidFeature {
  #[serde(rename = "fee_schema")] FeeSchema(String),
  #[serde(rename = "broker")] Broker(Account),
  #[serde(rename = "fee_accounts")] FeeAccounts(FeeAccountsParams),
}
pub type BidConfigShared = Option<Vec<BidFeature>>;
#[derive(CandidType, Deserialize, Debug)]
pub struct EscrowReceipt {
  pub token: TokenSpec,
  pub token_id: String,
  pub seller: Account,
  pub buyer: Account,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
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
  pub config: PricingConfigShared,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum SaleStatusSharedSaleType {
  #[serde(rename = "auction")] Auction(AuctionStateShared),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct SaleStatusShared {
  pub token_id: String,
  pub sale_type: SaleStatusSharedSaleType,
  pub broker_id: Option<Principal>,
  pub original_broker_id: Option<Principal>,
  pub sale_id: String,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct StableBucketData {
  pub principal: Principal,
  pub allocated_space: candid::Nat,
  pub date_added: candid::Int,
  pub version: (candid::Nat, candid::Nat, candid::Nat),
  pub b_gateway: bool,
  pub available_space: candid::Nat,
  pub allocations: Vec<((String, String), candid::Int)>,
}
pub type StableEscrowBalances = Vec<(Account, Account, String, EscrowRecord)>;
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub enum NftCanisterBackUpRet {
  #[serde(rename = "eof")] Eof(NftBackupChunk),
  #[serde(rename = "data")] Data(NftBackupChunk),
}
pub type ExtTokenIdentifier = String;
#[derive(CandidType, Deserialize, Debug)]
pub enum ExtUser {
  #[serde(rename = "principal")] Principal_(Principal),
  #[serde(rename = "address")] Address(String),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct ExtBalanceRequest {
  pub token: ExtTokenIdentifier,
  pub user: ExtUser,
}
pub type ExtBalance = candid::Nat;
#[derive(CandidType, Deserialize, Debug)]
pub enum ExtCommonError {
  InvalidToken(ExtTokenIdentifier),
  Other(String),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum ExtBalanceResult {
  #[serde(rename = "ok")] Ok(ExtBalance),
  #[serde(rename = "err")] Err(ExtCommonError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct StakeRecord {
  pub staker: Account,
  pub token_id: String,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct BalanceResponse {
  pub nfts: Vec<String>,
  pub offers: Vec<EscrowRecord>,
  pub sales: Vec<EscrowRecord>,
  pub stake: Vec<StakeRecord>,
  pub multi_canister: Option<Vec<Principal>>,
  pub escrow: Vec<EscrowRecord>,
}
#[derive(CandidType, Deserialize, Debug, PartialEq)]
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
  #[serde(rename = "kyc_fail")]
  KycFail,
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
  #[serde(rename = "kyc_error")]
  KycError,
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
#[derive(CandidType, Deserialize, Debug)]
pub struct OrigynError {
  pub text: String,
  pub error: Errors,
  pub number: u32,
  pub flag_point: String,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum BalanceResult {
  #[serde(rename = "ok")] Ok(BalanceResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
pub type ExtAccountIdentifier = String;
#[derive(CandidType, Deserialize, Debug)]
pub enum ExtBearerResult {
  #[serde(rename = "ok")] Ok(ExtAccountIdentifier),
  #[serde(rename = "err")] Err(ExtCommonError),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum BearerResult {
  #[serde(rename = "ok")] Ok(Account),
  #[serde(rename = "err")] Err(OrigynError),
}
pub type CanisterId = Principal;
#[derive(CandidType, Deserialize, Debug)]
pub struct NftCanisterCanisterStatusArg {
  pub canister_id: CanisterId,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum CanisterStatusStatus {
  #[serde(rename = "stopped")]
  Stopped,
  #[serde(rename = "stopping")]
  Stopping,
  #[serde(rename = "running")]
  Running,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct DefiniteCanisterSettings {
  pub freezing_threshold: candid::Nat,
  pub controllers: Option<Vec<Principal>>,
  pub memory_allocation: candid::Nat,
  pub compute_allocation: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct CanisterStatus {
  pub status: CanisterStatusStatus,
  pub memory_size: candid::Nat,
  pub cycles: candid::Nat,
  pub settings: DefiniteCanisterSettings,
  pub module_hash: Option<serde_bytes::ByteBuf>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct ChunkRequest {
  pub token_id: String,
  pub chunk: Option<candid::Nat>,
  pub library_id: String,
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub enum ChunkResult {
  #[serde(rename = "ok")] Ok(ChunkContent),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub enum CollectionResult {
  #[serde(rename = "ok")] Ok(CollectionInfo),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub enum OrigynBoolResult {
  #[serde(rename = "ok")] Ok(bool),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum NftError {
  UnauthorizedOperator,
  SelfTransfer,
  TokenNotFound,
  UnauthorizedOwner,
  TxNotFound,
  SelfApprove,
  OperatorNotFound,
  #[serde(rename = "ExistedNFT")]
  ExistedNft,
  OwnerNotFound,
  Other(String),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum Dip721BoolResult {
  Ok(bool),
  Err(NftError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct Dip721Metadata {
  pub logo: Option<String>,
  pub name: Option<String>,
  pub created_at: u64,
  pub upgraded_at: u64,
  pub custodians: Vec<Principal>,
  pub symbol: Option<String>,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum Dip721TokensListMetadata {
  Ok(Vec<candid::Nat>),
  Err(NftError),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum VecItem1 {
  Nat64Content(u64),
  Nat32Content(u32),
  BoolContent(bool),
  Nat8Content(u8),
  Int64Content(i64),
  IntContent(candid::Int),
  NatContent(candid::Nat),
  Nat16Content(u16),
  Int32Content(i32),
  Int8Content(i8),
  FloatContent(f64),
  Int16Content(i16),
  BlobContent(serde_bytes::ByteBuf),
  NestedContent(Box<Vec<GenericValue>>),
  #[serde(rename = "Principal")] Principal_(Principal),
  TextContent(String),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum GenericValue {
  Nat64Content(u64),
  Nat32Content(u32),
  BoolContent(bool),
  Nat8Content(u8),
  Int64Content(i64),
  IntContent(candid::Int),
  NatContent(candid::Nat),
  Nat16Content(u16),
  Int32Content(i32),
  Int8Content(i8),
  FloatContent(f64),
  Int16Content(i16),
  BlobContent(serde_bytes::ByteBuf),
  NestedContent(Box<Vec<GenericValue>>),
  #[serde(rename = "Principal")] Principal_(Principal),
  TextContent(String),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct TokenMetadata {
  pub transferred_at: Option<u64>,
  pub transferred_by: Option<Principal>,
  pub owner: Option<Principal>,
  pub operator: Option<Principal>,
  pub approved_at: Option<u64>,
  pub approved_by: Option<Principal>,
  pub properties: Vec<(String, GenericValue)>,
  pub is_burned: bool,
  pub token_identifier: candid::Nat,
  pub burned_at: Option<u64>,
  pub burned_by: Option<Principal>,
  pub minted_at: u64,
  pub minted_by: Principal,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum Dip721TokensMetadata {
  Ok(Vec<TokenMetadata>),
  Err(NftError),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum OwnerOfResponse {
  Ok(Option<Principal>),
  Err(NftError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct Dip721Stats {
  pub cycles: candid::Nat,
  pub total_transactions: candid::Nat,
  pub total_unique_holders: candid::Nat,
  pub total_supply: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum Dip721SupportedInterface {
  Burn,
  Mint,
  Approval,
  TransactionHistory,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum Dip721TokenMetadata {
  Ok(TokenMetadata),
  Err(NftError),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum Dip721NatResult {
  Ok(candid::Nat),
  Err(NftError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct GetLogMessagesFilter {
  pub analyzeCount: u32,
  pub messageRegex: Option<String>,
  pub messageContains: Option<String>,
}
pub type Nanos = u64;
#[derive(CandidType, Deserialize, Debug)]
pub struct GetLogMessagesParameters {
  pub count: u32,
  pub filter: Option<GetLogMessagesFilter>,
  pub fromTimeNanos: Option<Nanos>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct GetLatestLogMessagesParameters {
  pub upToTimeNanos: Option<Nanos>,
  pub count: u32,
  pub filter: Option<GetLogMessagesFilter>,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum CanisterLogRequest {
  #[serde(rename = "getMessagesInfo")]
  GetMessagesInfo,
  #[serde(rename = "getMessages")] GetMessages(GetLogMessagesParameters),
  #[serde(rename = "getLatestMessages")] GetLatestMessages(GetLatestLogMessagesParameters),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum CanisterLogFeature {
  #[serde(rename = "filterMessageByContains")]
  FilterMessageByContains,
  #[serde(rename = "filterMessageByRegex")]
  FilterMessageByRegex,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct CanisterLogMessagesInfo {
  pub features: Vec<Option<CanisterLogFeature>>,
  pub lastTimeNanos: Option<Nanos>,
  pub count: u32,
  pub firstTimeNanos: Option<Nanos>,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum Data {
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
pub type Caller = Option<Principal>;
#[derive(CandidType, Deserialize, Debug)]
pub struct LogMessagesData {
  pub data: Data,
  pub timeNanos: Nanos,
  pub message: String,
  pub caller: Caller,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct CanisterLogMessages {
  pub data: Vec<LogMessagesData>,
  pub lastAnalyzedMessageTimeNanos: Option<Nanos>,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum CanisterLogResponse {
  #[serde(rename = "messagesInfo")] MessagesInfo(CanisterLogMessagesInfo),
  #[serde(rename = "messages")] Messages(CanisterLogMessages),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum MetricsGranularity {
  #[serde(rename = "hourly")]
  Hourly,
  #[serde(rename = "daily")]
  Daily,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct GetMetricsParameters {
  pub dateToMillis: candid::Nat,
  pub granularity: MetricsGranularity,
  pub dateFromMillis: candid::Nat,
}
pub type UpdateCallsAggregatedData = Vec<u64>;
pub type CanisterHeapMemoryAggregatedData = Vec<u64>;
pub type CanisterCyclesAggregatedData = Vec<u64>;
pub type CanisterMemoryAggregatedData = Vec<u64>;
#[derive(CandidType, Deserialize, Debug)]
pub struct HourlyMetricsData {
  pub updateCalls: UpdateCallsAggregatedData,
  pub canisterHeapMemorySize: CanisterHeapMemoryAggregatedData,
  pub canisterCycles: CanisterCyclesAggregatedData,
  pub canisterMemorySize: CanisterMemoryAggregatedData,
  pub timeMillis: candid::Int,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct NumericEntity {
  pub avg: u64,
  pub max: u64,
  pub min: u64,
  pub first: u64,
  pub last: u64,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct DailyMetricsData {
  pub updateCalls: u64,
  pub canisterHeapMemorySize: NumericEntity,
  pub canisterCycles: NumericEntity,
  pub canisterMemorySize: NumericEntity,
  pub timeMillis: candid::Int,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum CanisterMetricsData {
  #[serde(rename = "hourly")] Hourly(Vec<HourlyMetricsData>),
  #[serde(rename = "daily")] Daily(Vec<DailyMetricsData>),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct CanisterMetrics {
  pub data: CanisterMetricsData,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum OrigynTextResult {
  #[serde(rename = "ok")] Ok(String),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct Tip {
  pub last_block_index: serde_bytes::ByteBuf,
  pub hash_tree: serde_bytes::ByteBuf,
  pub last_block_hash: serde_bytes::ByteBuf,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum GovernanceRequest {
  #[serde(rename = "update_system_var")] UpdateSystemVar {
    key: String,
    val: Box<CandyShared>,
    token_id: String,
  },
  #[serde(rename = "clear_shared_wallets")] ClearSharedWallets(String),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum GovernanceResponse {
  #[serde(rename = "update_system_var")] UpdateSystemVar(bool),
  #[serde(rename = "clear_shared_wallets")] ClearSharedWallets(bool),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum GovernanceResult {
  #[serde(rename = "ok")] Ok(GovernanceResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum HistoryResult {
  #[serde(rename = "ok")] Ok(Vec<TransactionRecord>),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct HeaderField(pub String, pub String);
#[derive(CandidType, Deserialize, Debug)]
pub struct HttpRequest {
  pub url: String,
  pub method: String,
  pub body: serde_bytes::ByteBuf,
  pub headers: Vec<HeaderField>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct StreamingCallbackToken {
  pub key: String,
  pub index: candid::Nat,
  pub content_encoding: String,
}
candid::define_function!(pub StreamingStrategyCallbackCallback : () -> ());
#[derive(CandidType, Deserialize, Debug)]
pub enum StreamingStrategy {
  Callback {
    token: StreamingCallbackToken,
    callback: StreamingStrategyCallbackCallback,
  },
}
#[derive(CandidType, Deserialize, Debug)]
pub struct HttpResponse {
  pub body: serde_bytes::ByteBuf,
  pub headers: Vec<HeaderField>,
  pub streaming_strategy: Option<StreamingStrategy>,
  pub status_code: u16,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct StreamingCallbackResponse {
  pub token: Option<StreamingCallbackToken>,
  pub body: serde_bytes::ByteBuf,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct GetArchivesArgs {
  pub from: Option<Principal>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct GetArchivesResultItem {
  pub end: candid::Nat,
  pub canister_id: Principal,
  pub start: candid::Nat,
}
pub type GetArchivesResult = Vec<GetArchivesResultItem>;
#[derive(CandidType, Deserialize, Debug)]
pub struct TransactionRange {
  pub start: candid::Nat,
  pub length: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct GetTransactionsResultBlocksItem {
  pub id: candid::Nat,
  pub block: Box<Value>,
}
candid::define_function!(pub GetTransactionsFn : (Vec<TransactionRange>) -> (
    GetTransactionsResult,
  ) query);
#[derive(CandidType, Deserialize, Debug)]
pub struct ArchivedTransactionResponse {
  pub args: Vec<TransactionRange>,
  pub callback: GetTransactionsFn,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct GetTransactionsResult {
  pub log_length: candid::Nat,
  pub blocks: Vec<GetTransactionsResultBlocksItem>,
  pub archived_blocks: Vec<Box<ArchivedTransactionResponse>>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct DataCertificate {
  pub certificate: serde_bytes::ByteBuf,
  pub hash_tree: serde_bytes::ByteBuf,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct BlockType {
  pub url: String,
  pub block_type: String,
}
pub type Subaccount = serde_bytes::ByteBuf;
#[derive(CandidType, Deserialize, Clone, Debug)]
pub struct Account3 {
  pub owner: Principal,
  pub subaccount: Option<Subaccount>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct ApprovalArgs {
  pub memo: Option<serde_bytes::ByteBuf>,
  pub from_subaccount: Option<serde_bytes::ByteBuf>,
  pub created_at_time: Option<u64>,
  pub expires_at: Option<u64>,
  pub spender: Account3,
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub enum ApprovalResultItemApprovalResult {
  Ok(candid::Nat),
  Err(ApprovalError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct ApprovalResultItem {
  pub token_id: candid::Nat,
  pub approval_result: ApprovalResultItemApprovalResult,
}
pub type ApprovalResult = Vec<ApprovalResultItem>;
#[derive(CandidType, Deserialize, Debug)]
pub enum Value {
  Int(candid::Int),
  Map(Vec<(String, Box<Value>)>),
  Nat(candid::Nat),
  Blob(serde_bytes::ByteBuf),
  Text(String),
  Array(Vec<Box<Value>>),
}
pub type CollectionMetadata = Vec<(String, Box<Value>)>;
#[derive(CandidType, Deserialize, Debug)]
pub struct SupportedStandard {
  pub url: String,
  pub name: String,
}
#[derive(CandidType, Deserialize, Clone)]
pub struct TransferArgs {
  pub to: Account3,
  pub token_id: candid::Nat,
  pub memo: Option<serde_bytes::ByteBuf>,
  pub from_subaccount: Option<serde_bytes::ByteBuf>,
  pub created_at_time: Option<u64>,
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub enum TransferResultItemTransferResult {
  Ok(candid::Nat),
  Err(TransferError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct TransferResultItem {
  pub token_id: candid::Nat,
  pub transfer_result: TransferResultItemTransferResult,
}
pub type TransferResult = Vec<Option<TransferResultItem>>;
#[derive(CandidType, Deserialize, Debug)]
pub struct InitFractionalizeRequest {
  pub token_id: String,
}
#[derive(CandidType, Deserialize)]
pub enum InitFractionalizeResponse {
  #[serde(rename = "ok")]
  Ok,
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum ManageStorageRequestConfigureStorage {
  #[serde(rename = "stableBtree")] StableBtree(Option<candid::Nat>),
  #[serde(rename = "heap")] Heap(Option<candid::Nat>),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum ManageStorageRequest {
  #[serde(rename = "add_storage_canisters")] AddStorageCanisters(
    Vec<(Principal, candid::Nat, (candid::Nat, candid::Nat, candid::Nat))>,
  ),
  #[serde(rename = "configure_storage")] ConfigureStorage(ManageStorageRequestConfigureStorage),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum ManageStorageResponse {
  #[serde(rename = "add_storage_canisters")] AddStorageCanisters(candid::Nat, candid::Nat),
  #[serde(rename = "configure_storage")] ConfigureStorage(candid::Nat, candid::Nat),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum ManageStorageResult {
  #[serde(rename = "ok")] Ok(ManageStorageResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct SalesConfig {
  pub broker_id: Option<Account>,
  pub pricing: PricingConfigShared,
  pub escrow_receipt: Option<EscrowReceipt>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct MarketTransferRequest {
  pub token_id: String,
  pub sales_config: SalesConfig,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct MarketTransferRequestReponseTxnTypeMintSaleInner {
  pub token: TokenSpec,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub struct MarketTransferRequestReponse {
  pub token_id: String,
  pub txn_type: MarketTransferRequestReponseTxnType,
  pub timestamp: candid::Int,
  pub index: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum MarketTransferResult {
  #[serde(rename = "ok")] Ok(MarketTransferRequestReponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum ExtMetadata {
  #[serde(rename = "fungible")] Fungible {
    decimals: u8,
    metadata: Option<serde_bytes::ByteBuf>,
    name: String,
    symbol: String,
  },
  #[serde(rename = "nonfungible")] Nonfungible {
    metadata: Option<serde_bytes::ByteBuf>,
  },
}
#[derive(CandidType, Deserialize, Debug)]
pub enum ExtMetadataResult {
  #[serde(rename = "ok")] Ok(ExtMetadata),
  #[serde(rename = "err")] Err(ExtCommonError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct NftInfoStable {
  pub metadata: Box<CandyShared>,
  pub current_sale: Option<SaleStatusShared>,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum NftInfoResult {
  #[serde(rename = "ok")] Ok(NftInfoStable),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum Account {
  #[serde(rename = "account_id")] AccountId(String),
  #[serde(rename = "principal")] Principal_(Principal),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
  #[serde(rename = "account")] Account {
    owner: Principal,
    sub_account: Option<serde_bytes::ByteBuf>,
  },
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub struct BidRequest {
  pub config: BidConfigShared,
  pub escrow_record: EscrowRecord,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct DepositDetail {
  pub token: TokenSpec,
  pub trx_id: Option<TransactionId>,
  pub seller: Account,
  pub buyer: Account,
  pub amount: candid::Nat,
  pub sale_id: Option<String>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct EscrowRequest {
  pub token_id: String,
  pub deposit: DepositDetail,
  pub lock_to_date: Option<candid::Int>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct FeeDepositRequest {
  pub token: TokenSpec,
  pub account: Account,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct RejectDescription {
  pub token: TokenSpec,
  pub token_id: String,
  pub seller: Account,
  pub buyer: Account,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum FeeDepositWithdrawDescriptionStatus {
  #[serde(rename = "locked")] Locked {
    sale_id: String,
  },
  #[serde(rename = "unlocked")]
  Unlocked,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct FeeDepositWithdrawDescription {
  pub status: FeeDepositWithdrawDescriptionStatus,
  pub token: TokenSpec,
  pub withdraw_to: Account,
  pub account: Account,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct WithdrawDescription {
  pub token: TokenSpec,
  pub token_id: String,
  pub seller: Account,
  pub withdraw_to: Account,
  pub buyer: Account,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct DepositWithdrawDescription {
  pub token: TokenSpec,
  pub withdraw_to: Account,
  pub buyer: Account,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum WithdrawRequest {
  #[serde(rename = "reject")] Reject(RejectDescription),
  #[serde(rename = "fee_deposit")] FeeDeposit(FeeDepositWithdrawDescription),
  #[serde(rename = "sale")] Sale(WithdrawDescription),
  #[serde(rename = "deposit")] Deposit(DepositWithdrawDescription),
  #[serde(rename = "escrow")] Escrow(WithdrawDescription),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum TokenSpecFilterFilterType {
  #[serde(rename = "allow")]
  Allow,
  #[serde(rename = "block")]
  Block,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct TokenSpecFilter {
  pub token: TokenSpec,
  pub filter_type: TokenSpecFilterFilterType,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum TokenIdFilterFilterType {
  #[serde(rename = "allow")]
  Allow,
  #[serde(rename = "block")]
  Block,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct TokenIdFilterTokensItem {
  pub token: TokenSpec,
  pub min_amount: Option<candid::Nat>,
  pub max_amount: Option<candid::Nat>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct TokenIdFilter {
  pub filter_type: TokenIdFilterFilterType,
  pub token_id: String,
  pub tokens: Vec<TokenIdFilterTokensItem>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct AskSubscribeRequestSubscribeFilterInner {
  pub tokens: Option<Vec<TokenSpecFilter>>,
  pub token_ids: Option<Vec<TokenIdFilter>>,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum AskSubscribeRequest {
  #[serde(rename = "subscribe")] Subscribe {
    stake: (Principal, candid::Nat),
    filter: Option<AskSubscribeRequestSubscribeFilterInner>,
  },
  #[serde(rename = "unsubscribe")] Unsubscribe(Principal, candid::Nat),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct DistributeSaleRequest {
  pub seller: Option<Account>,
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub struct BidResponseTxnTypeMintSaleInner {
  pub token: TokenSpec,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub struct BidResponse {
  pub token_id: String,
  pub txn_type: BidResponseTxnType,
  pub timestamp: candid::Int,
  pub index: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct EscrowResponse {
  pub balance: candid::Nat,
  pub receipt: EscrowReceipt,
  pub transaction: TransactionRecord,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct FeeDepositResponse {
  pub balance: candid::Nat,
  pub transaction: TransactionRecord,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct RecognizeEscrowResponse {
  pub balance: candid::Nat,
  pub receipt: EscrowReceipt,
  pub transaction: Option<TransactionRecord>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct WithdrawResponseTxnTypeMintSaleInner {
  pub token: TokenSpec,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub struct WithdrawResponse {
  pub token_id: String,
  pub txn_type: WithdrawResponseTxnType,
  pub timestamp: candid::Int,
  pub index: candid::Nat,
}
pub type AskSubscribeResponse = bool;
#[derive(CandidType, Deserialize, Debug)]
pub struct EndSaleResponseTxnTypeMintSaleInner {
  pub token: TokenSpec,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub struct EndSaleResponse {
  pub token_id: String,
  pub txn_type: EndSaleResponseTxnType,
  pub timestamp: candid::Int,
  pub index: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum Result_ {
  #[serde(rename = "ok")] Ok(Box<ManageSaleResponse>),
  #[serde(rename = "err")] Err(OrigynError),
}
pub type DistributeSaleResponse = Vec<Result_>;
#[derive(CandidType, Deserialize, Debug)]
pub enum ManageSaleResponse {
  #[serde(rename = "bid")] Bid(BidResponse),
  #[serde(rename = "escrow_deposit")] EscrowDeposit(EscrowResponse),
  #[serde(rename = "fee_deposit")] FeeDeposit(FeeDepositResponse),
  #[serde(rename = "recognize_escrow")] RecognizeEscrow(RecognizeEscrowResponse),
  #[serde(rename = "withdraw")] Withdraw(WithdrawResponse),
  #[serde(rename = "ask_subscribe")] AskSubscribe(AskSubscribeResponse),
  #[serde(rename = "end_sale")] EndSale(EndSaleResponse),
  #[serde(rename = "refresh_offers")] RefreshOffers(Vec<EscrowRecord>),
  #[serde(rename = "distribute_sale")] DistributeSale(DistributeSaleResponse),
  #[serde(rename = "open_sale")] OpenSale(bool),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum ManageSaleResult {
  #[serde(rename = "ok")] Ok(Box<ManageSaleResponse>),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum SaleInfoRequest {
  #[serde(rename = "status")] Status(String),
  #[serde(rename = "fee_deposit_info")] FeeDepositInfo(Option<Account>),
  #[serde(rename = "active")] Active(Option<(candid::Nat, candid::Nat)>),
  #[serde(rename = "deposit_info")] DepositInfo(Option<Account>),
  #[serde(rename = "history")] History(Option<(candid::Nat, candid::Nat)>),
  #[serde(rename = "escrow_info")] EscrowInfo(EscrowReceipt),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct SubAccountInfoAccount {
  pub principal: Principal,
  pub sub_account: serde_bytes::ByteBuf,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct SubAccountInfo {
  pub account_id: serde_bytes::ByteBuf,
  pub principal: Principal,
  pub account_id_text: String,
  pub account: SubAccountInfoAccount,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum SaleInfoResponse {
  #[serde(rename = "status")] Status(Option<SaleStatusShared>),
  #[serde(rename = "fee_deposit_info")] FeeDepositInfo(SubAccountInfo),
  #[serde(rename = "active")] Active {
    eof: bool,
    records: Vec<(String, Option<SaleStatusShared>)>,
    count: candid::Nat,
  },
  #[serde(rename = "deposit_info")] DepositInfo(SubAccountInfo),
  #[serde(rename = "history")] History {
    eof: bool,
    records: Vec<Option<SaleStatusShared>>,
    count: candid::Nat,
  },
  #[serde(rename = "escrow_info")] EscrowInfo(SubAccountInfo),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum SaleInfoResult {
  #[serde(rename = "ok")] Ok(SaleInfoResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct ShareWalletRequest {
  pub to: Account,
  pub token_id: String,
  pub from: Account,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct OwnerTransferResponse {
  pub transaction: TransactionRecord,
  pub assets: Vec<Box<CandyShared>>,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum OwnerUpdateResult {
  #[serde(rename = "ok")] Ok(OwnerTransferResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct NftCanisterStageBatchNftOrigynArgItem {
  pub metadata: Box<CandyShared>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct StageChunkArg {
  pub content: serde_bytes::ByteBuf,
  pub token_id: String,
  pub chunk: candid::Nat,
  pub filedata: Box<CandyShared>,
  pub library_id: String,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct StageLibraryResponse {
  pub canister: Principal,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum StageLibraryResult {
  #[serde(rename = "ok")] Ok(StageLibraryResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct NftCanisterStageNftOrigynArg {
  pub metadata: Box<CandyShared>,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct StateSize {
  pub sales_balances: candid::Nat,
  pub offers: candid::Nat,
  pub nft_ledgers: candid::Nat,
  pub allocations: candid::Nat,
  pub nft_sales: candid::Nat,
  pub buckets: candid::Nat,
  pub escrow_balances: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct StorageMetrics {
  pub gateway: Principal,
  pub available_space: candid::Nat,
  pub allocations: Vec<AllocationRecordStable>,
  pub allocated_storage: candid::Nat,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum StorageMetricsResult {
  #[serde(rename = "ok")] Ok(StorageMetrics),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct ExtTokensResponse1Inner {
  pub locked: Option<candid::Int>,
  pub seller: Principal,
  pub price: u64,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct ExtTokensResponse(
  pub u32,
  pub Option<ExtTokensResponse1Inner>,
  pub Option<serde_bytes::ByteBuf>,
);
#[derive(CandidType, Deserialize, Debug)]
pub enum ExtTokensResult {
  #[serde(rename = "ok")] Ok(Vec<ExtTokensResponse>),
  #[serde(rename = "err")] Err(ExtCommonError),
}
pub type ExtMemo = serde_bytes::ByteBuf;
pub type ExtSubAccount = serde_bytes::ByteBuf;
#[derive(CandidType, Deserialize, Debug)]
pub struct ExtTransferRequest {
  pub to: ExtUser,
  pub token: ExtTokenIdentifier,
  pub notify: bool,
  pub from: ExtUser,
  pub memo: ExtMemo,
  pub subaccount: Option<ExtSubAccount>,
  pub amount: ExtBalance,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum ExtTransferResponseErr {
  CannotNotify(ExtAccountIdentifier),
  InsufficientBalance,
  InvalidToken(ExtTokenIdentifier),
  Rejected,
  Unauthorized(ExtAccountIdentifier),
  Other(String),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum ExtTransferResponse {
  #[serde(rename = "ok")] Ok(ExtBalance),
  #[serde(rename = "err")] Err(ExtTransferResponseErr),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum UpdateModeShared {
  Set(Box<CandyShared>),
  Lock(Box<CandyShared>),
  Next(Vec<Box<UpdateShared>>),
}
#[derive(CandidType, Deserialize, Debug)]
pub struct UpdateShared {
  pub mode: UpdateModeShared,
  pub name: String,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct UpdateRequestShared {
  pub id: String,
  pub update: Vec<Box<UpdateShared>>,
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize, Debug)]
pub enum NftUpdateResult {
  #[serde(rename = "ok")] Ok(NftUpdateResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
#[derive(CandidType, Deserialize, Debug)]
pub enum IndexType {
  Stable,
  StableTyped,
  Managed,
}
#[derive(CandidType, Deserialize, Debug)]
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
#[derive(CandidType, Deserialize)]
pub struct NftUpdateMetadataNode {
  pub token_id: String,
  pub value: Box<CandyShared>,
  pub _system: bool,
  pub field_id: String,
}
#[derive(CandidType, Deserialize, Debug)]
pub struct NftUpdateMetadataNodeResponse {
  pub property_new: PropertyShared,
  pub property_old: Option<PropertyShared>,
}
#[derive(CandidType, Deserialize, Debug)]
pub enum NftUpdateAppResult {
  #[serde(rename = "ok")] Ok(NftUpdateMetadataNodeResponse),
  #[serde(rename = "err")] Err(OrigynError),
}
candid::define_service!(pub NftCanister : {
  "__advance_time" : candid::func!((candid::Int) -> (candid::Int));
  "__set_time_mode" : candid::func!((NftCanisterSetTimeModeArg) -> (bool));
  "__supports" : candid::func!(() -> (Vec<(String,String,)>) query);
  "__version" : candid::func!(() -> (String) query);
  "back_up" : candid::func!((candid::Nat) -> (NftCanisterBackUpRet) query);
  "balance" : candid::func!((ExtBalanceRequest) -> (ExtBalanceResult) query);
  "balanceEXT" : candid::func!((ExtBalanceRequest) -> (ExtBalanceResult) query);
  "balance_of_batch_nft_origyn" : candid::func!(
    (Vec<Account>) -> (Vec<BalanceResult>) query
  );
  "balance_of_nft_origyn" : candid::func!((Account) -> (BalanceResult) query);
  "balance_of_secure_batch_nft_origyn" : candid::func!(
    (Vec<Account>) -> (Vec<BalanceResult>)
  );
  "balance_of_secure_nft_origyn" : candid::func!((Account) -> (BalanceResult));
  "bearer" : candid::func!((ExtTokenIdentifier) -> (ExtBearerResult) query);
  "bearerEXT" : candid::func!((ExtTokenIdentifier) -> (ExtBearerResult) query);
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
  "collectCanisterMetrics" : candid::func!(() -> () query);
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
  "cycles" : candid::func!(() -> (candid::Nat) query);
  "dip721_balance_of" : candid::func!((Principal) -> (candid::Nat) query);
  "dip721_custodians" : candid::func!(() -> (Vec<Principal>) query);
  "dip721_is_approved_for_all" : candid::func!(
    (Principal, Principal) -> (Dip721BoolResult) query
  );
  "dip721_logo" : candid::func!(() -> (Option<String>) query);
  "dip721_metadata" : candid::func!(() -> (Dip721Metadata) query);
  "dip721_name" : candid::func!(() -> (Option<String>) query);
  "dip721_operator_token_identifiers" : candid::func!(
    (Principal) -> (Dip721TokensListMetadata) query
  );
  "dip721_operator_token_metadata" : candid::func!(
    (Principal) -> (Dip721TokensMetadata) query
  );
  "dip721_owner_of" : candid::func!((candid::Nat) -> (OwnerOfResponse) query);
  "dip721_owner_token_identifiers" : candid::func!(
    (Principal) -> (Dip721TokensListMetadata) query
  );
  "dip721_owner_token_metadata" : candid::func!(
    (Principal) -> (Dip721TokensMetadata) query
  );
  "dip721_stats" : candid::func!(() -> (Dip721Stats) query);
  "dip721_supported_interfaces" : candid::func!(
    () -> (Vec<Dip721SupportedInterface>) query
  );
  "dip721_symbol" : candid::func!(() -> (Option<String>) query);
  "dip721_token_metadata" : candid::func!(
    (candid::Nat) -> (Dip721TokenMetadata) query
  );
  "dip721_total_supply" : candid::func!(() -> (candid::Nat) query);
  "dip721_total_transactions" : candid::func!(() -> (candid::Nat) query);
  "dip721_transfer" : candid::func!(
    (Principal, candid::Nat) -> (Dip721NatResult)
  );
  "dip721_transfer_from" : candid::func!(
    (Principal, Principal, candid::Nat) -> (Dip721NatResult)
  );
  "getCanisterLog" : candid::func!(
    (Option<CanisterLogRequest>) -> (Option<CanisterLogResponse>) query
  );
  "getCanisterMetrics" : candid::func!(
    (GetMetricsParameters) -> (Option<CanisterMetrics>) query
  );
  "getEXTTokenIdentifier" : candid::func!((String) -> (String) query);
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
    (Vec<Account3>) -> (Vec<candid::Nat>) query
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
    (Vec<candid::Nat>) -> (Vec<Option<Account3>>) query
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
    (Account3, Option<candid::Nat>, Option<u32>) -> (Vec<candid::Nat>) query
  );
  "icrc7_total_supply" : candid::func!(() -> (candid::Nat) query);
  "icrc7_transfer" : candid::func!((Vec<TransferArgs>) -> (TransferResult));
  "icrc7_transfer_fee" : candid::func!(
    (candid::Nat) -> (Option<candid::Nat>) query
  );
  "icrc7_tx_window" : candid::func!(() -> (Option<candid::Nat>) query);
  "init_fractionalization" : candid::func!(
    (InitFractionalizeRequest) -> (InitFractionalizeResponse)
  );
  "manage_storage_nft_origyn" : candid::func!(
    (ManageStorageRequest) -> (ManageStorageResult)
  );
  "market_transfer_batch_nft_origyn" : candid::func!(
    (Vec<MarketTransferRequest>) -> (Vec<MarketTransferResult>)
  );
  "market_transfer_nft_origyn" : candid::func!(
    (MarketTransferRequest) -> (MarketTransferResult)
  );
  "metadata" : candid::func!(() -> (Dip721Metadata) query);
  "metadataExt" : candid::func!(
    (ExtTokenIdentifier) -> (ExtMetadataResult) query
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
  "operaterTokenMetadata" : candid::func!(
    (Principal) -> (Dip721TokensMetadata) query
  );
  "ownerOf" : candid::func!((candid::Nat) -> (OwnerOfResponse) query);
  "ownerTokenMetadata" : candid::func!(
    (Principal) -> (Dip721TokensMetadata) query
  );
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
  "tokens_ext" : candid::func!((String) -> (ExtTokensResult) query);
  "transfer" : candid::func!((ExtTransferRequest) -> (ExtTransferResponse));
  "transferDip721" : candid::func!(
    (Principal, candid::Nat) -> (Dip721NatResult)
  );
  "transferEXT" : candid::func!((ExtTransferRequest) -> (ExtTransferResponse));
  "transferFrom" : candid::func!(
    (Principal, Principal, candid::Nat) -> (Dip721NatResult)
  );
  "transferFromDip721" : candid::func!(
    (Principal, Principal, candid::Nat) -> (Dip721NatResult)
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

#[derive(Clone, Debug)]
pub struct Service(pub Principal);
impl Service {
  pub async fn advance_time(&self, arg0: candid::Int) -> Result<(candid::Int,)> {
    ic_cdk::call(self.0, "__advance_time", (arg0,)).await
  }
  pub async fn set_time_mode(&self, arg0: NftCanisterSetTimeModeArg) -> Result<(bool,)> {
    ic_cdk::call(self.0, "__set_time_mode", (arg0,)).await
  }
  pub async fn supports(&self) -> Result<(Vec<(String, String)>,)> {
    ic_cdk::call(self.0, "__supports", ()).await
  }
  pub async fn version(&self) -> Result<(String,)> {
    ic_cdk::call(self.0, "__version", ()).await
  }
  pub async fn back_up(&self, arg0: candid::Nat) -> Result<(NftCanisterBackUpRet,)> {
    ic_cdk::call(self.0, "back_up", (arg0,)).await
  }
  pub async fn balance(&self, arg0: ExtBalanceRequest) -> Result<(ExtBalanceResult,)> {
    ic_cdk::call(self.0, "balance", (arg0,)).await
  }
  pub async fn balance_ext(&self, arg0: ExtBalanceRequest) -> Result<(ExtBalanceResult,)> {
    ic_cdk::call(self.0, "balanceEXT", (arg0,)).await
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
  pub async fn bearer(&self, arg0: ExtTokenIdentifier) -> Result<(ExtBearerResult,)> {
    ic_cdk::call(self.0, "bearer", (arg0,)).await
  }
  pub async fn bearer_ext(&self, arg0: ExtTokenIdentifier) -> Result<(ExtBearerResult,)> {
    ic_cdk::call(self.0, "bearerEXT", (arg0,)).await
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
  pub async fn collect_canister_metrics(&self) -> Result<()> {
    ic_cdk::call(self.0, "collectCanisterMetrics", ()).await
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
  pub async fn cycles(&self) -> Result<(candid::Nat,)> {
    ic_cdk::call(self.0, "cycles", ()).await
  }
  pub async fn dip_721_balance_of(&self, arg0: Principal) -> Result<(candid::Nat,)> {
    ic_cdk::call(self.0, "dip721_balance_of", (arg0,)).await
  }
  pub async fn dip_721_custodians(&self) -> Result<(Vec<Principal>,)> {
    ic_cdk::call(self.0, "dip721_custodians", ()).await
  }
  pub async fn dip_721_is_approved_for_all(
    &self,
    arg0: Principal,
    arg1: Principal
  ) -> Result<(Dip721BoolResult,)> {
    ic_cdk::call(self.0, "dip721_is_approved_for_all", (arg0, arg1)).await
  }
  pub async fn dip_721_logo(&self) -> Result<(Option<String>,)> {
    ic_cdk::call(self.0, "dip721_logo", ()).await
  }
  pub async fn dip_721_metadata(&self) -> Result<(Dip721Metadata,)> {
    ic_cdk::call(self.0, "dip721_metadata", ()).await
  }
  pub async fn dip_721_name(&self) -> Result<(Option<String>,)> {
    ic_cdk::call(self.0, "dip721_name", ()).await
  }
  pub async fn dip_721_operator_token_identifiers(
    &self,
    arg0: Principal
  ) -> Result<(Dip721TokensListMetadata,)> {
    ic_cdk::call(self.0, "dip721_operator_token_identifiers", (arg0,)).await
  }
  pub async fn dip_721_operator_token_metadata(
    &self,
    arg0: Principal
  ) -> Result<(Dip721TokensMetadata,)> {
    ic_cdk::call(self.0, "dip721_operator_token_metadata", (arg0,)).await
  }
  pub async fn dip_721_owner_of(&self, arg0: candid::Nat) -> Result<(OwnerOfResponse,)> {
    ic_cdk::call(self.0, "dip721_owner_of", (arg0,)).await
  }
  pub async fn dip_721_owner_token_identifiers(
    &self,
    arg0: Principal
  ) -> Result<(Dip721TokensListMetadata,)> {
    ic_cdk::call(self.0, "dip721_owner_token_identifiers", (arg0,)).await
  }
  pub async fn dip_721_owner_token_metadata(
    &self,
    arg0: Principal
  ) -> Result<(Dip721TokensMetadata,)> {
    ic_cdk::call(self.0, "dip721_owner_token_metadata", (arg0,)).await
  }
  pub async fn dip_721_stats(&self) -> Result<(Dip721Stats,)> {
    ic_cdk::call(self.0, "dip721_stats", ()).await
  }
  pub async fn dip_721_supported_interfaces(&self) -> Result<(Vec<Dip721SupportedInterface>,)> {
    ic_cdk::call(self.0, "dip721_supported_interfaces", ()).await
  }
  pub async fn dip_721_symbol(&self) -> Result<(Option<String>,)> {
    ic_cdk::call(self.0, "dip721_symbol", ()).await
  }
  pub async fn dip_721_token_metadata(&self, arg0: candid::Nat) -> Result<(Dip721TokenMetadata,)> {
    ic_cdk::call(self.0, "dip721_token_metadata", (arg0,)).await
  }
  pub async fn dip_721_total_supply(&self) -> Result<(candid::Nat,)> {
    ic_cdk::call(self.0, "dip721_total_supply", ()).await
  }
  pub async fn dip_721_total_transactions(&self) -> Result<(candid::Nat,)> {
    ic_cdk::call(self.0, "dip721_total_transactions", ()).await
  }
  pub async fn dip_721_transfer(
    &self,
    arg0: Principal,
    arg1: candid::Nat
  ) -> Result<(Dip721NatResult,)> {
    ic_cdk::call(self.0, "dip721_transfer", (arg0, arg1)).await
  }
  pub async fn dip_721_transfer_from(
    &self,
    arg0: Principal,
    arg1: Principal,
    arg2: candid::Nat
  ) -> Result<(Dip721NatResult,)> {
    ic_cdk::call(self.0, "dip721_transfer_from", (arg0, arg1, arg2)).await
  }
  pub async fn get_canister_log(
    &self,
    arg0: Option<CanisterLogRequest>
  ) -> Result<(Option<CanisterLogResponse>,)> {
    ic_cdk::call(self.0, "getCanisterLog", (arg0,)).await
  }
  pub async fn get_canister_metrics(
    &self,
    arg0: GetMetricsParameters
  ) -> Result<(Option<CanisterMetrics>,)> {
    ic_cdk::call(self.0, "getCanisterMetrics", (arg0,)).await
  }
  pub async fn get_ext_token_identifier(&self, arg0: String) -> Result<(String,)> {
    ic_cdk::call(self.0, "getEXTTokenIdentifier", (arg0,)).await
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
  pub async fn icrc_7_balance_of(&self, arg0: Vec<Account3>) -> Result<(Vec<candid::Nat>,)> {
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
  pub async fn icrc_7_owner_of(&self, arg0: Vec<candid::Nat>) -> Result<(Vec<Option<Account3>>,)> {
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
    arg0: Account3,
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
  pub async fn init_fractionalization(
    &self,
    arg0: InitFractionalizeRequest
  ) -> Result<(InitFractionalizeResponse,)> {
    ic_cdk::call(self.0, "init_fractionalization", (arg0,)).await
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
  pub async fn metadata(&self) -> Result<(Dip721Metadata,)> {
    ic_cdk::call(self.0, "metadata", ()).await
  }
  pub async fn metadata_ext(&self, arg0: ExtTokenIdentifier) -> Result<(ExtMetadataResult,)> {
    ic_cdk::call(self.0, "metadataExt", (arg0,)).await
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
  pub async fn operater_token_metadata(&self, arg0: Principal) -> Result<(Dip721TokensMetadata,)> {
    ic_cdk::call(self.0, "operaterTokenMetadata", (arg0,)).await
  }
  pub async fn owner_of(&self, arg0: candid::Nat) -> Result<(OwnerOfResponse,)> {
    ic_cdk::call(self.0, "ownerOf", (arg0,)).await
  }
  pub async fn owner_token_metadata(&self, arg0: Principal) -> Result<(Dip721TokensMetadata,)> {
    ic_cdk::call(self.0, "ownerTokenMetadata", (arg0,)).await
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
  pub async fn tokens_ext(&self, arg0: String) -> Result<(ExtTokensResult,)> {
    ic_cdk::call(self.0, "tokens_ext", (arg0,)).await
  }
  pub async fn transfer(&self, arg0: ExtTransferRequest) -> Result<(ExtTransferResponse,)> {
    ic_cdk::call(self.0, "transfer", (arg0,)).await
  }
  pub async fn transfer_dip_721(
    &self,
    arg0: Principal,
    arg1: candid::Nat
  ) -> Result<(Dip721NatResult,)> {
    ic_cdk::call(self.0, "transferDip721", (arg0, arg1)).await
  }
  pub async fn transfer_ext(&self, arg0: ExtTransferRequest) -> Result<(ExtTransferResponse,)> {
    ic_cdk::call(self.0, "transferEXT", (arg0,)).await
  }
  pub async fn transfer_from(
    &self,
    arg0: Principal,
    arg1: Principal,
    arg2: candid::Nat
  ) -> Result<(Dip721NatResult,)> {
    ic_cdk::call(self.0, "transferFrom", (arg0, arg1, arg2)).await
  }
  pub async fn transfer_from_dip_721(
    &self,
    arg0: Principal,
    arg1: Principal,
    arg2: candid::Nat
  ) -> Result<(Dip721NatResult,)> {
    ic_cdk::call(self.0, "transferFromDip721", (arg0, arg1, arg2)).await
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
