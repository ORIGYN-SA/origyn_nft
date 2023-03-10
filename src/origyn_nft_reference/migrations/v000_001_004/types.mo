import CandyTypes_lib "mo:candy/types"; 
import v0_1_3 "../v000_001_003/types";

import Order "mo:base/Order";
import Text "mo:base/Text";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";

import KYC "mo:icrc17_kyc/types";
// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead


module {
  
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  

  public let SB = v0_1_3.SB;
  public let Map = v0_1_3.Map;
  public let CandyTypes = v0_1_3.CandyTypes;

  public type CollectionData = v0_1_3.CollectionData;

  public type AllocationRecord = v0_1_3.AllocationRecord;

  public type BucketData = v0_1_3.BucketData;

  public type EscrowBuyerTrie = v0_1_3.EscrowBuyerTrie;
  public type EscrowSellerTrie = v0_1_3.EscrowSellerTrie;
  public type EscrowLedgerTrie = v0_1_3.EscrowLedgerTrie;
  public type EscrowTokenIDTrie = v0_1_3.EscrowTokenIDTrie;
  public type SalesSellerTrie = v0_1_3.SalesSellerTrie;
  public type SalesBuyerTrie = v0_1_3.SalesBuyerTrie;
  public type SalesTokenIDTrie = v0_1_3.SalesTokenIDTrie;
  public type SalesLedgerTrie = v0_1_3.SalesLedgerTrie;

  public type TransactionRecord = v0_1_3.TransactionRecord;

  public type ICTokenSpec = v0_1_3.ICTokenSpec;
  public type TokenSpec = v0_1_3.TokenSpec;

  public type EscrowReceipt = v0_1_3.EscrowReceipt;

  public type SaleStatus = v0_1_3.SaleStatus;

  public type HttpAccess= v0_1_3.HttpAccess;

  public type Account = v0_1_3.Account;

  public type TransactionID = v0_1_3.TransactionID;
  public type PricingConfig = v0_1_3.PricingConfig;
  public type AuctionConfig = v0_1_3.AuctionConfig;
  public type AuctionState = v0_1_3.AuctionState;

  public type EscrowRecord = v0_1_3.EscrowRecord;

  public let compare_library = v0_1_3.compare_library;

  public let library_equal : ((Text, Text), (Text, Text)) -> Bool = v0_1_3.library_equal;

  public let library_hash : ((Text, Text)) -> Nat = v0_1_3.library_hash;

  public let account_hash_uncompressed = v0_1_3.account_hash_uncompressed;
  public let token_hash_uncompressed = v0_1_3.token_hash_uncompressed;
  public let account_handler = v0_1_3.account_handler;
  public let account_hash = v0_1_3.account_hash;
  public let account_eq = v0_1_3.account_eq;
  public let token_hash = v0_1_3.token_hash;
  public let token_eq = v0_1_3.token_eq;


  public let token_handler = v0_1_3.token_handler;

  public let Conversions = v0_1_3.Conversions;
  public let Properties = v0_1_3.Properties;

  public type State  = {
    // this is the data you previously had as stable variables inside your actor class
    var collection_data : CollectionData;
    var buckets : Map.Map<Principal, BucketData>;
    var allocations : Map.Map<(Text, Text), AllocationRecord>;
    var canister_availible_space : Nat;
    var canister_allocated_storage : Nat;
    var offers : Map.Map<Account, Map.Map<Account, Int>>;
    var nft_metadata : Map.Map<Text, CandyTypes.CandyValue>;
    var escrow_balances : EscrowBuyerTrie;
    var sales_balances : SalesSellerTrie;
    var nft_ledgers : Map.Map<Text, SB.StableBuffer<TransactionRecord>>;
    var nft_sales : Map.Map<Text, SaleStatus>;
    var access_tokens : Map.Map<Text, HttpAccess>;
    var kyc_cache : Map.Map<KYC.KYCRequest,KYC.KYCResultFuture>;
  };
};