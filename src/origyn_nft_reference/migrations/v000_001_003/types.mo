import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 
import Map_lib "mo:map_7_0_0/Map"; 
import CandyTypes_lib "mo:candy_0_1_11/types"; 
import Conversion_lib "mo:candy_0_1_11/conversion"; 
import v0_1_0 "../v000_001_000/types";
import MapUtils "mo:map_7_0_0/utils";
import AccountIdentifier "mo:principalmo/AccountIdentifier";
import hex "mo:encoding/Hex";


import Blob "mo:base/Blob";
import D "mo:base/Debug";
import Nat32 "mo:base/Nat32";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead


module {
  
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  

  public let SB = SB_lib;
  public let Map = Map_lib;
  public let CandyTypes = CandyTypes_lib;

    public type CollectionData = v0_1_0.CollectionData;

    public type BucketData = {  
        principal : Principal;
        var allocated_space: Nat;
        var available_space: Nat;
        date_added: Int;
        b_gateway: Bool;
        var version: (Nat, Nat, Nat);
        var allocations: Map.Map<(Text,Text), Int>; // (token_id, library_id), Timestamp
    };

    public type AllocationRecord = v0_1_0.AllocationRecord;

    public type LogEntry = v0_1_0.LogEntry;

    public type SalesSellerTrie = Map.Map<Account, 
                                    Map.Map<Account,
                                        Map.Map<Text,
                                            Map.Map<TokenSpec,EscrowRecord>>>>;
                                        

    public type SalesBuyerTrie = Map.Map<Account,
                                Map.Map<Text,
                                    Map.Map<TokenSpec,EscrowRecord>>>;

    public type SalesTokenIDTrie = Map.Map<Text,
                                        Map.Map<TokenSpec,EscrowRecord>>;

    public type SalesLedgerTrie = Map.Map<TokenSpec,EscrowRecord>;

    public type EscrowBuyerTrie = Map.Map<Account, 
                                    Map.Map<Account,
                                        Map.Map<Text,
                                            Map.Map<TokenSpec,EscrowRecord>>>>;

    public type EscrowSellerTrie = Map.Map<Account,
                                    Map.Map<Text,
                                        Map.Map<TokenSpec,EscrowRecord>>>;
    
    public type EscrowTokenIDTrie = Map.Map<Text,
                                        Map.Map<TokenSpec,EscrowRecord>>;

    public type EscrowLedgerTrie = Map.Map<TokenSpec,EscrowRecord>;

    public type Account = v0_1_0.Account;

    public type EscrowRecord = v0_1_0.EscrowRecord;

    public type TokenSpec = v0_1_0.TokenSpec;

    public type ICTokenSpec = v0_1_0.ICTokenSpec;

    public type PricingConfig = v0_1_0.PricingConfig;

    public type AuctionConfig = v0_1_0.AuctionConfig;

    public type TransactionRecord = v0_1_0.TransactionRecord;

    //used to identify the transaction in a remote ledger; usually a nat on the IC
    public type TransactionID = v0_1_0.TransactionID;

    public type SaleStatus = v0_1_0.SaleStatus;

    public type EscrowReceipt = v0_1_0.EscrowReceipt;

    public type AuctionState = v0_1_0.AuctionState;

    public func compare_library(x : (Text, Text), y: (Text, Text)) : Order.Order {
        let a = Text.compare(x.0, y.0);
        switch(a){
            case(#equal){
                return  Text.compare(x.1,y.1);
            };
            case(_){
                return a;
            };
        };
    };

    public func library_equal(x : (Text, Text), y: (Text, Text)) : Bool {
        
        switch(compare_library(x, y)){
            case(#equal){
                return  true;
            };
            case(_){
                return false;
            };
        };
    };

    public func library_hash(x : (Text, Text)) : Nat {
        return Nat32.toNat(Text.hash("token_id" # x.0 # "library_id" # x.1));
        
    };

    public func account_eq(a : Account, b : Account) : Bool{
        switch(a){
            case(#principal(a_principal)){
                switch(b){
                    case(#principal(b_principal)){
                        return a_principal == b_principal;
                    };
                    case(#account_id(b_account_id)){
                        return AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_principal, null)) == b_account_id;
                    };
                    case(#account(b_account)){
                        return AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_principal, null)) == AccountIdentifier.toText(AccountIdentifier.fromPrincipal(b_account.owner, switch(b_account.sub_account){case(null){null}; case(?val){?Blob.toArray(val)}})) ;
                    };
                    case(#extensible(b_extensible)){
                        //not implemented
                        return false;
                    };
                };
            };
            case(#account_id(a_account_id)){
                switch(b){
                    case(#principal(b_principal)){
                        return a_account_id == AccountIdentifier.toText(AccountIdentifier.fromPrincipal(b_principal,null));
                    };
                    case(#account_id(b_account_id)){
                        return a_account_id == b_account_id;
                    };
                    case(#account(b_account)){
                        return a_account_id == AccountIdentifier.toText(AccountIdentifier.fromPrincipal(b_account.owner, switch(b_account.sub_account){case(null){null}; case(?val){?Blob.toArray(val)}})) ;
                    };
                    case(#extensible(b_extensible)){
                        //not implemented
                        return false;
                    }
                }
            };
            case(#extensible(a_extensible)){
                switch(b){
                    case(#principal(b_principal)){
                        return false;
                    };
                    case(#account_id(b_account_id)){
                        return false;
                    };
                    case(#account(b_account_id)){
                        return false;
                    };
                    case(#extensible(b_extensible)){
                        //not implemented
                        return false;
                    }
                };
            };
            case(#account(a_account)){
                switch(b){
                    case(#principal(b_principal)){
                        return  AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_account.owner, switch(a_account.sub_account){case(null){null}; case(?val){?Blob.toArray(val)}})) == AccountIdentifier.toText(AccountIdentifier.fromPrincipal(b_principal, null)) ;
                    };
                    case(#account_id(b_account_id)){
                        return AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_account.owner, switch(a_account.sub_account){case(null){null}; case(?val){?Blob.toArray(val)}})) == b_account_id;
                    };
                     case(#account(b_account)){
                        return a_account.owner == b_account.owner and a_account.sub_account == b_account.sub_account;
                    };
                    case(#extensible(b_extensible)){
                        //not implemented
                        return false;
                    };
                };
            }
        };
    };

    

    public func token_compare (a : TokenSpec, b : TokenSpec) : Order.Order{
        /* #ic: {
            canister: Principal;
            standard: {
                #DIP20;
                #Ledger;
                #ICRC1;
                #EXTFungible;
            }
        };
        #extensible : CandyTypes.CandyValue; //#Class*/
        switch(a, b){
            case(#ic(a_token), #ic(b_token)){
                return Principal.compare(a_token.canister, b_token.canister);
            };
            case(#extensible(a_token), #ic(b_token)){
               return Text.compare(Conversion_lib.valueToText(a_token), Principal.toText(b_token.canister));
            };
            case(#ic(a_token), #extensible(b_token)){
               return  Text.compare(Principal.toText(a_token.canister),Conversion_lib.valueToText(b_token));
            };
            case(#extensible(a_token), #extensible(b_token)){
               return Text.compare(Conversion_lib.valueToText(a_token), Conversion_lib.valueToText(b_token));
            };
        };
    };

    public func token_eq(a : TokenSpec, b : TokenSpec) : Bool{
        /* #ic: {
            canister: Principal;
            standard: {
                #DIP20;
                #Ledger;
                #EXTFungible;
                #ICRC1;
            }
        };
        #extensible : CandyTypes.CandyValue; //#Class*/
        switch(a){
            case(#ic(a_token)){
                switch(b){
                    case(#ic(b_token)){
                        
                        if(a_token.standard != b_token.standard){
                            return false;
                        };
                        if(a_token.canister != b_token.canister){
                            return false;
                        };
                        return true;
                    };
                    case(#extensible(b_token)){
                        //not implemented
                        return false;
                    };
                };
            };
            case(#extensible(a_token)){
                switch(b){
                    case(#ic(b_token)){
                        //not implemented
                        return false;
                    };
                    case(#extensible(b_token)){
                        //not implemented
                        return false;
                    };
                    
                }
            };
        };
    };

    public func account_hash(a : Account) : Nat{
        switch(a){
            case(#principal(a_principal)){
                Nat32.toNat(Principal.hash(a_principal));
            };
            case(#account_id(a_account_id)){
                Nat32.toNat(Text.hash(a_account_id));

            };
            case(#account(a_account)){
                Nat32.toNat(Text.hash(AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_account.owner, switch(a_account.sub_account){case(null){null}; case(?val){?Blob.toArray(val)}})) ));

            };
            case(#extensible(a_extensible)){
                //unimplemnted; unsafe; probably dont use
                //until a reliable valueToHash function is written
                //if any redenring of classes changes the whole hash
                //will change
                Nat32.toNat(Text.hash(Conversion_lib.valueToText(a_extensible)));

            };
        };
    };

    public func account_hash_uncompressed(a : Account) : Nat{
                switch(a){
             case(#principal(a_principal)){
                MapUtils.hashBlob(Principal.toBlob(a_principal));
             };
             case(#account_id(a_account_id)){

                let accountBlob = switch(hex.decode(a_account_id)){
                  case(#ok(item)){Blob.fromArray(item)};
                  case(#err(err)){
                    D.trap("Not a valid hex");
                  };
                };
                MapUtils.hashBlob(accountBlob);
             };
             case(#account(a_account)){
                let account_id = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_account.owner, switch(a_account.sub_account){case(null){null}; case(?val){?Blob.toArray(val)}}));
                let accountBlob = switch(hex.decode(account_id)){
                  case(#ok(item)){Blob.fromArray(item)};
                  case(#err(err)){
                    D.trap("Not a valid hex");
                  };
                };
                MapUtils.hashBlob(accountBlob);
             };
             case(#extensible(a_extensible)){
                 //unimplemnted; unsafe; probably dont use
                 //until a reliable valueToHash function is written
                 //if any redenring of classes changes the whole hash
                 //will change
                MapUtils.hashBlob(Conversion_lib.valueToBlob(#Text(Conversion_lib.valueToText(a_extensible))));
             };
         };
     };


    public func token_hash(a : TokenSpec) : Nat {
        switch(a){
            case(#ic(a)){
              Nat32.toNat(Principal.hash(a.canister));

            };
            case(#extensible(a_extensible)){
                 //unimplemnted; unsafe; probably dont use
                //until a reliable valueToHash function is written
                //if any redenring of classes changes the whole hash
                //will change
                Nat32.toNat(Text.hash(Conversion_lib.valueToText(a_extensible)));
            };
        };
        
    };

    public func token_hash_uncompressed(a : TokenSpec) : Nat {
        switch(a){
            case(#ic(a)){
                MapUtils.hashBlob(Principal.toBlob(a.canister));


            };
            case(#extensible(a_extensible)){
                 //unimplemnted; unsafe; probably dont use
                //until a reliable valueToHash function is written
                //if any redenring of classes changes the whole hash
                //will change
                MapUtils.hashBlob(Conversion_lib.valueToBlob(a_extensible));

            };
        };
        
    };

    public let account_handler = (account_hash, account_eq);

    public let token_handler = (token_hash, token_eq);

  public type State = {
    // this is the data you previously had as stable variables inside your actor class
    var collection_data : CollectionData;
    var buckets : Map.Map<Principal, BucketData>;
    var allocations : Map.Map<(Text, Text), AllocationRecord>;
    var canister_availible_space : Nat;
    var canister_allocated_storage : Nat;
    var log : SB.StableBuffer<LogEntry>;
    var log_history : SB.StableBuffer<[LogEntry]>;
    var log_harvester :  Principal;
    var offers : Map.Map<Account, Map.Map<Account, Int>>;
    var nft_metadata : Map.Map<Text,CandyTypes.CandyValue>;
    var escrow_balances : EscrowBuyerTrie;
    var sales_balances : SalesSellerTrie;
    var nft_ledgers : Map.Map<Text, SB.StableBuffer<TransactionRecord>>;
    var nft_sales : Map.Map<Text, SaleStatus>;
  };
};