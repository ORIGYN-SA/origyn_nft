// This is an experimental feature to generate Rust binding from Candid.
// You may want to manually adjust some of the types.
#![allow(dead_code, unused_imports)]
use candid::{ self, CandidType, Deserialize, Principal };
use ic_cdk::api::call::CallResult as Result;

#[derive(CandidType, Deserialize)]
pub enum AuctionStateSharedStatus {
  #[serde(rename = "closed")]
  Closed,
  #[serde(rename = "open")]
  Open,
  #[serde(rename = "not_started")]
  NotStarted,
}
#[derive(CandidType, Deserialize)]
pub struct PropertyShared {
  pub value: Box<CandyShared>,
  pub name: String,
  pub immutable: bool,
}
#[derive(CandidType, Deserialize)]
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
#[derive(CandidType, Deserialize)]
pub enum IcTokenSpec1Standard {
  #[serde(rename = "ICRC1")]
  Icrc1,
  #[serde(rename = "EXTFungible")]
  ExtFungible,
  #[serde(rename = "DIP20")]
  Dip20,
  Other(Box<CandyShared>),
  Ledger,
}
#[derive(CandidType, Deserialize)]
pub struct IcTokenSpec1 {
  pub id: Option<candid::Nat>,
  pub fee: Option<candid::Nat>,
  pub decimals: candid::Nat,
  pub canister: Principal,
  pub standard: IcTokenSpec1Standard,
  pub symbol: String,
}
#[derive(CandidType, Deserialize)]
pub enum TokenSpec1 {
  #[serde(rename = "ic")] Ic(IcTokenSpec1),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
}
#[derive(CandidType, Deserialize)]
pub enum Account1 {
  #[serde(rename = "account_id")] AccountId(String),
  #[serde(rename = "principal")] Principal_(Principal),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
  #[serde(rename = "account")] Account {
    owner: Principal,
    sub_account: Option<serde_bytes::ByteBuf>,
  },
}
#[derive(CandidType, Deserialize)]
pub enum Account {
  #[serde(rename = "account_id")] AccountId(String),
  #[serde(rename = "principal")] Principal_(Principal),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
  #[serde(rename = "account")] Account {
    owner: Principal,
    sub_account: Option<serde_bytes::ByteBuf>,
  },
}
pub type FeeName = String;
pub type FeeAccountsParams = Vec<FeeName>;
#[derive(CandidType, Deserialize)]
pub enum BidFeature {
  #[serde(rename = "fee_schema")] FeeSchema(String),
  #[serde(rename = "broker")] Broker(Account),
  #[serde(rename = "fee_accounts")] FeeAccounts(FeeAccountsParams),
}
pub type BidConfigShared = Option<Vec<BidFeature>>;
#[derive(CandidType, Deserialize)]
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
#[derive(CandidType, Deserialize)]
pub struct IcTokenSpec {
  pub id: Option<candid::Nat>,
  pub fee: Option<candid::Nat>,
  pub decimals: candid::Nat,
  pub canister: Principal,
  pub standard: IcTokenSpecStandard,
  pub symbol: String,
}
#[derive(CandidType, Deserialize)]
pub enum TokenSpec {
  #[serde(rename = "ic")] Ic(IcTokenSpec),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
}
#[derive(CandidType, Deserialize)]
pub struct EscrowReceipt {
  pub token: TokenSpec,
  pub token_id: String,
  pub seller: Account,
  pub buyer: Account,
  pub amount: candid::Nat,
}
#[derive(CandidType, Deserialize)]
pub struct WaitForQuietType {
  pub max: candid::Nat,
  pub fade: f64,
  pub extension: u64,
}
#[derive(CandidType, Deserialize)]
pub enum MinIncreaseType {
  #[serde(rename = "amount")] Amount(candid::Nat),
  #[serde(rename = "percentage")] Percentage(f64),
}
#[derive(CandidType, Deserialize)]
pub struct NiftySettlementType {
  pub fixed: bool,
  pub interestRatePerSecond: f64,
  pub duration: Option<candid::Int>,
  pub expiration: Option<candid::Int>,
  pub lenderOffer: bool,
}
#[derive(CandidType, Deserialize)]
pub enum DutchParamsTimeUnit {
  #[serde(rename = "day")] Day(candid::Nat),
  #[serde(rename = "hour")] Hour(candid::Nat),
  #[serde(rename = "minute")] Minute(candid::Nat),
}
#[derive(CandidType, Deserialize)]
pub enum DutchParamsDecayType {
  #[serde(rename = "flat")] Flat(candid::Nat),
  #[serde(rename = "percent")] Percent(f64),
}
#[derive(CandidType, Deserialize)]
pub struct DutchParams {
  pub time_unit: DutchParamsTimeUnit,
  pub decay_type: DutchParamsDecayType,
}
#[derive(CandidType, Deserialize)]
pub enum EndingType {
  #[serde(rename = "date")] Date(candid::Int),
  #[serde(rename = "timeout")] Timeout(candid::Nat),
}
#[derive(CandidType, Deserialize)]
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
#[derive(CandidType, Deserialize)]
pub enum InstantFeature {
  #[serde(rename = "fee_schema")] FeeSchema(String),
  #[serde(rename = "fee_accounts")] FeeAccounts(FeeAccountsParams),
}
pub type InstantConfigShared = Option<Vec<InstantFeature>>;
#[derive(CandidType, Deserialize)]
pub enum AuctionConfigEnding {
  #[serde(rename = "date")] Date(candid::Int),
  #[serde(rename = "wait_for_quiet")] WaitForQuiet {
    max: candid::Nat,
    date: candid::Int,
    fade: f64,
    extension: u64,
  },
}
#[derive(CandidType, Deserialize)]
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
#[derive(CandidType, Deserialize)]
pub enum PricingConfigShared {
  #[serde(rename = "ask")] Ask(AskConfigShared),
  #[serde(rename = "extensible")] Extensible(Box<CandyShared>),
  #[serde(rename = "instant")] Instant(InstantConfigShared),
  #[serde(rename = "auction")] Auction(AuctionConfig),
}
#[derive(CandidType, Deserialize)]
pub struct AuctionStateShared {
  pub status: AuctionStateSharedStatus,
  pub participants: Vec<(Principal, candid::Int)>,
  pub token: TokenSpec1,
  pub current_bid_amount: candid::Nat,
  pub winner: Option<Account1>,
  pub end_date: candid::Int,
  pub current_config: BidConfigShared,
  pub start_date: candid::Int,
  pub wait_for_quiet_count: Option<candid::Nat>,
  pub current_escrow: Option<EscrowReceipt>,
  pub allow_list: Option<Vec<(Principal, bool)>>,
  pub min_next_bid: candid::Nat,
  pub config: PricingConfigShared,
}
#[derive(CandidType, Deserialize)]
pub enum SaleStatusSharedSaleType {
  #[serde(rename = "auction")] Auction(AuctionStateShared),
}
#[derive(CandidType, Deserialize)]
pub struct SaleStatusShared {
  pub token_id: String,
  pub sale_type: SaleStatusSharedSaleType,
  pub broker_id: Option<Principal>,
  pub original_broker_id: Option<Principal>,
  pub sale_id: String,
}
#[derive(CandidType, Deserialize)]
pub struct SubAccountInfoAccount {
  pub principal: Principal,
  pub sub_account: serde_bytes::ByteBuf,
}
#[derive(CandidType, Deserialize)]
pub struct SubAccountInfo {
  pub account_id: serde_bytes::ByteBuf,
  pub principal: Principal,
  pub account_id_text: String,
  pub account: SubAccountInfoAccount,
}
#[derive(CandidType, Deserialize)]
pub struct SubscriberNotification {
  pub collection: Principal,
  pub sale: SaleStatusShared,
  pub seller: Account1,
  pub escrow_info: SubAccountInfo,
}
candid::define_service!(pub TestWallet : {
  "notify_sale_nft_origyn" : candid::func!(
    (SubscriberNotification) -> () oneway
  );
});

pub struct Service(pub Principal);
impl Service {
  pub async fn notify_sale_nft_origyn(&self, arg0: SubscriberNotification) -> Result<()> {
    ic_cdk::call(self.0, "notify_sale_nft_origyn", (arg0,)).await
  }
}
