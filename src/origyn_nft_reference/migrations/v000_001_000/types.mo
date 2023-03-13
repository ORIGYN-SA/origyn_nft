import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 
import Map_lib "mo:map_6_0_0/Map"; 
import CandyTypes_lib "mo:candy_0_1_10/types"; 
// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead


module {
  
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  

  public let SB = SB_lib;
  public let Map = Map_lib;
  public let CandyTypes = CandyTypes_lib;

    public type CollectionData = {
        var logo: ?Text;
        var name: ?Text;
        var symbol: ?Text;
        var metadata: ?CandyTypes.CandyValue;
        var owner : Principal;
        var managers: [Principal];
        var network: ?Principal;
        var allocated_storage: Nat;
        var available_space : Nat;
        var active_bucket: ?Principal;
    };

    public type BucketData = {  
        principal : Principal;
        var allocated_space: Nat;
        var available_space: Nat;
        date_added: Int;
        b_gateway: Bool;
        var version: (Nat, Nat, Nat);
        var allocations: Map.Map<(Text,Text), Int>; // (token_id, library_id), Timestamp
    };

    public type AllocationRecord = {
        canister : Principal;
        allocated_space: Nat;
        var available_space: Nat;
        var chunks: SB.StableBuffer<Nat>;
        token_id: Text;
        library_id: Text;
    };

    public type LogEntry = {
        event : Text;
        timestamp: Int;
        data: CandyTypes.CandyValue;
        caller: ?Principal;
    };

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

    public type Account = {
        #principal : Principal;
        #account : {owner: Principal; sub_account: ?Blob};
        #account_id : Text;
        #extensible : CandyTypes.CandyValue;
    };

    public type EscrowRecord = {
        amount: Nat;
        buyer: Account; 
        seller:Account; 
        token_id: Text; 
        token: TokenSpec;
        sale_id: ?Text; //locks the escrow to a specific sale
        lock_to_date: ?Int; //locks the escrow to a timestamp
        account_hash: ?Blob; //sub account the host holds the funds in
    };

    public type TokenSpec = {
        #ic: ICTokenSpec;
        #extensible : CandyTypes.CandyValue; //#Class
    };

    public type ICTokenSpec = {
        canister: Principal;
        fee: Nat;
        symbol: Text;
        decimals: Nat;
        standard: {
            #DIP20;
            #Ledger;
            #EXTFungible;
            #ICRC1; //use #Ledger instead
        };
    };

    public type PricingConfig = {
        #instant; //executes an escrow recipt transfer -only available for non-marketable NFTs
        #flat: {
            token: TokenSpec;
            amount: Nat; //Nat to support cycles
        };
        //below have not been signficantly desinged or vetted
        #dutch: {
            start_price: Nat;
            decay_per_hour: Float;
            reserve: ?Nat;
        };
        #auction: AuctionConfig;
        #extensible:{
            #candyClass
        }
    };

    public type AuctionConfig = {
            reserve: ?Nat;
            token: TokenSpec;
            buy_now: ?Nat;
            start_price: Nat;
            start_date: Int;
            ending: {
                #date: Int;
                #waitForQuiet: {
                    date: Int;
                    extention: Nat64;
                    fade: Float;
                    max: Nat
                };
            };
            min_increase: {
                #percentage: Float;
                #amount: Nat;
            };
            allow_list : ?[Principal];
        };

    public type TransactionRecord = {
        token_id: Text;
        index: Nat;
        txn_type: {
            #auction_bid : {
                buyer: Account;
                amount: Nat;
                token: TokenSpec;
                sale_id: Text;
                extensible: CandyTypes.CandyValue;
            };
            #mint : {
                from: Account;
                to: Account;
                //nyi: metadata hash
                sale: ?{token: TokenSpec;
                    amount: Nat; //Nat to support cycles
                    };
                extensible: CandyTypes.CandyValue;
            };
            #sale_ended : {
                seller: Account;
                buyer: Account;
               
                token: TokenSpec;
                sale_id: ?Text;
                amount: Nat;//Nat to support cycles
                extensible: CandyTypes.CandyValue;
            };
            #royalty_paid : {
                seller: Account;
                buyer: Account;
                 reciever: Account;
                tag: Text;
                token: TokenSpec;
                sale_id: ?Text;
                amount: Nat;//Nat to support cycles
                extensible: CandyTypes.CandyValue;
            };
            #sale_opened : {
                pricing: PricingConfig;
                sale_id: Text;
                extensible: CandyTypes.CandyValue;
            };
            #owner_transfer : {
                from: Account;
                to: Account;
                extensible: CandyTypes.CandyValue;
            }; 
            #escrow_deposit : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat;//Nat to support cycles
                trx_id: TransactionID;
                extensible: CandyTypes.CandyValue;
            };
            #escrow_withdraw : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat;//Nat to support cycles
                fee: Nat;
                trx_id: TransactionID;
                extensible: CandyTypes.CandyValue;
            };
            #deposit_withdraw : {
                buyer: Account;
                token: TokenSpec;
                amount: Nat;//Nat to support cycles
                fee: Nat;
                trx_id: TransactionID;
                extensible: CandyTypes.CandyValue;
            };
            #sale_withdraw : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat; //Nat to support cycles
                fee: Nat;
                trx_id: TransactionID;
                extensible: CandyTypes.CandyValue;
            };
            #canister_owner_updated : {
                owner: Principal;
                extensible: CandyTypes.CandyValue;
            };
            #canister_managers_updated : {
                managers: [Principal];
                extensible: CandyTypes.CandyValue;
            };
            #canister_network_updated : {
                network: Principal;
                extensible: CandyTypes.CandyValue;
            };
            #data; //nyi
            #burn;
            #extensible : CandyTypes.CandyValue;

        };
        timestamp: Int;
    };

    //used to identify the transaction in a remote ledger; usually a nat on the IC
    public type TransactionID = {
        #nat : Nat;
        #text : Text;
        #extensible : CandyTypes.CandyValue
    };

    public type SaleStatus = {
        sale_id: Text; //sha256?;
        original_broker_id: ?Principal;
        broker_id: ?Principal;
        token_id: Text;
        sale_type: {
            #auction: AuctionState;
        };
    };

    public type EscrowReceipt = {
        amount: Nat; //Nat to support cycles
        seller: Account;
        buyer: Account;
        token_id: Text;
        token: TokenSpec;
        
    };

    public type AuctionState = {
                config: PricingConfig;
                var current_bid_amount: Nat;
                var current_broker_id: ?Principal;
                var end_date: Int;
                var min_next_bid: Nat;
                var current_escrow: ?EscrowReceipt;
                var wait_for_quiet_count: ?Nat;
                var allow_list: ?Map.Map<Principal,Bool>; //empty set means everyone
                var participants: Map.Map<Principal,Int>;
                var status: {
                    #open;
                    #closed;
                    #not_started;
                };
                var winner: ?Account;
            };

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