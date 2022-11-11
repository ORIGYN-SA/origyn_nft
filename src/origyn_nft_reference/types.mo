
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Nat32 "mo:base/Nat32";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import AccountIdentifier "mo:principalmo/AccountIdentifier";
import Candy "mo:candy_0_1_10/types";
import CandyTypes "mo:candy_0_1_10/types";
import Conversions "mo:candy_0_1_10/conversion";
import EXT "mo:ext/Core";
import EXTCommon "mo:ext/Common";
import Map "mo:map_6_0_0/Map";
import NFTUtils "mo:map_6_0_0/utils";
import SB "mo:stablebuffer_0_2_0/StableBuffer";
import hex "mo:encoding/Hex";
import CandyTypes_lib "mo:candy_0_1_10/types"; 
import DIP721 "DIP721";
import MigrationTypes "./migrations/types";
import StorageMigrationTypes "./migrations_storage/types";

module {
    
    public type InitArgs = {
        owner: Principal.Principal;
        storage_space: ?Nat;
    };

    public type StorageInitArgs = {
        gateway_canister: Principal;
        network: ?Principal;
        storage_space: ?Nat;
    };

    public type StorageMigrationArgs = {
        gateway_canister: Principal;
        network: ?Principal;
        storage_space: ?Nat;
        caller: Principal;
    };

    public type ManageCollectionCommand = {
        #UpdateManagers : [Principal];
        #UpdateOwner : Principal;
        #UpdateNetwork : ?Principal;
        #UpdateLogo : ?Text;
        #UpdateName : ?Text;
        #UpdateSymbol : ?Text;
        #UpdateMetadata: (Text, ?CandyTypes.CandyValue, Bool);
    };

    // RawData type is a tuple of Timestamp, Data, and Principal
    public type RawData = (Int, Blob, Principal);

    public type HttpRequest = {
        body: Blob;
        headers: [HeaderField];
        method: Text;
        url: Text;
    };

    public type StreamingCallbackToken =  {
        content_encoding: Text;
        index: Nat;
        key: Text;
        //sha256: ?Blob;
    };
    public type StreamingCallbackHttpResponse = {
        body: Blob;
        token: ?StreamingCallbackToken;
    };
    public type ChunkId = Nat;
    public type SetAssetContentArguments = {
        chunk_ids: [ChunkId];
        content_encoding: Text;
        key: Key;
        sha256: ?Blob;
    };
    public type Path = Text;
    public type Key = Text;

    public type HttpResponse = {
        body: Blob;
        headers: [HeaderField];
        status_code: Nat16;
        streaming_strategy: ?StreamingStrategy;
    };

    public type StreamingStrategy = {
       #Callback: {
          callback: shared () -> async ();
          token: StreamingCallbackToken;
        };
    };

    public type HeaderField = (Text, Text);

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

    public type StageChunkArg = {
        token_id: Text;
        library_id: Text;
        filedata: CandyTypes.CandyValue;//may need to be nullable
        chunk: Nat; //2MB Chunks
        content: Blob;
    };


    public type ChunkRequest = {
        token_id: Text;
        library_id: Text;
        chunk: ?Nat;
    };

    public type ChunkContent = {
        #remote : {
            canister: Principal;
            args: ChunkRequest;
        };
        #chunk : {
            content: Blob;
            total_chunks: Nat; 
            current_chunk: ?Nat;
            storage_allocation: AllocationRecordStable;
        };
    };

    public type MarketTransferRequest = {
        token_id: Text;
        sales_config: SalesConfig;
    };

    public type OwnerTransferResponse = {
        transaction: TransactionRecord;
        assets: [CandyTypes.CandyValue];
    };

    public type ShareWalletRequest = {
        token_id: Text;
        from: Account;
        to: Account;
    };

    public type SalesConfig = {
        escrow_receipt : ?EscrowReceipt;
        broker_id : ?Principal;
        pricing: PricingConfig;
    };

    public type ICTokenSpec = MigrationTypes.Current.ICTokenSpec;

    public type TokenSpec = MigrationTypes.Current.TokenSpec;

    public let TokenSpecDefault = #extensible(#Empty);


    //nyi: anywhere a deposit address is used, check blob for size in inspect message
    public type SubAccountInfo = {
        principal : Principal;
        account_id : Blob;
        account_id_text: Text;
        account: {
            principal: Principal;
            sub_account: Blob;
        };
    };

    public type EscrowReceipt = MigrationTypes.Current.EscrowReceipt;

    public type EscrowRequest = {
        token_id : Text; //empty string for general escrow
        deposit : DepositDetail;
        lock_to_date: ?Int; //timestamp to lock escrow until.
    };

    public type DepositDetail = {
        token : TokenSpec;
        seller: Account;
        buyer : Account;
        amount: Nat; //Nat to support cycles; 
        sale_id: ?Text;
        trx_id : ?TransactionID; //null for account based ledgers
    };

    //used to identify the transaction in a remote ledger; usually a nat on the IC
    public type TransactionID = MigrationTypes.Current.TransactionID;

    public type EscrowResponse = {
        receipt: EscrowReceipt;
        balance: Nat;
        transaction: TransactionRecord;
    };

    public type BidRequest = {
        escrow_receipt: EscrowReceipt;
        sale_id: Text;
        broker_id: ?Principal;
    };

    public type BidResponse = TransactionRecord;

    public type PricingConfig = MigrationTypes.Current.PricingConfig;

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
        current_sale : ?SaleStatusStable;
        metadata : CandyTypes.CandyValue;
    };

    public type AuctionState = MigrationTypes.Current.AuctionState;

    public type AuctionStateStable = {
                config: PricingConfig;
                current_bid_amount: Nat;
                current_broker_id: ?Principal;
                end_date: Int;
                min_next_bid: Nat;
                current_escrow: ?EscrowReceipt;
                wait_for_quiet_count: ?Nat;
                allow_list: ?[(Principal,Bool)]; // user, tree
                participants: [(Principal,Int)]; //user, timestamp of last access
                status: {
                    #open;
                    #closed;
                    #not_started;
                };
                winner: ?Account;
            };

    public func AuctionState_stabalize_for_xfer(val : AuctionState) : AuctionStateStable{
        {
            config = val.config;
            current_bid_amount = val.current_bid_amount;
            current_broker_id = val.current_broker_id;
            end_date = val.end_date;
            min_next_bid = val.min_next_bid;
            current_escrow = val.current_escrow;
            wait_for_quiet_count = val.wait_for_quiet_count;
            allow_list = do ? {Iter.toArray(Map.entries<Principal, Bool>(val.allow_list!))};
            participants = Iter.toArray(Map.entries<Principal, Int>(val.participants));
            status = val.status;
            winner = val.winner;
        };
    };

    public type SaleStatus = MigrationTypes.Current.SaleStatus;

    public type SaleStatusStable = {
        sale_id: Text; //sha256?;
        original_broker_id: ?Principal;
        broker_id: ?Principal;
        token_id: Text;
        sale_type: {
            #auction: AuctionStateStable;
        };
    };


    public func SalesStatus_stabalize_for_xfer( item : SaleStatus) : SaleStatusStable {
        {
            sale_id = item.sale_id;
            token_id = item.token_id;
            broker_id = item.broker_id;
            original_broker_id = item.original_broker_id;
            sale_type = switch(item.sale_type){
                case(#auction(val)){
                    #auction(AuctionState_stabalize_for_xfer(val));
                }
            };
        }
    };

    public type MarketTransferRequestReponse = TransactionRecord;
    
    public type Account = MigrationTypes.Current.Account;

    public type HttpAccess= {
        identity: Principal;
        expires: Time.Time;
    };

    public type State = State_v0_1_0;

    public type State_v0_1_0 = {
        state : GatewayState_v0_1_0;
        canister : () -> Principal;
        get_time: () -> Int;
        nft_library : TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>>;
        access_tokens : TrieMap.TrieMap<Text, HttpAccess>;
        refresh_state: () -> State;
    };

    // public type BucketData = {  
    //     principal : Principal;
    //     allocated_space: Nat;
    //     available_space: Nat;
    //     date_added: Int;
    //     b_gateway: Bool;
    //     version: (Nat, Nat, Nat);
    //     allocations: [[(Text,Text,Int)]]; 
    // };
    public type Test = {
        hello: Text;
        var allocated_space: Nat;
        var available_space: Nat;
    };
    public type TestStable = {
        hello: Text;       
        allocated_space: Nat;
        available_space: Nat;
    };

    public func stabilize_test (item : Test) : TestStable {
        {
            hello = item.hello;
            allocated_space = item.allocated_space;
            available_space = item.available_space;
        }
    }; 
    

    public type BucketDat = {
        principal : Principal;
        allocated_space: Nat;
        available_space: Nat;
        date_added: Int;
        b_gateway: Bool;
        version: (Nat, Nat, Nat);
        // allocations: [((Text, Text), Int)]
        allocations: Map.Map<(Text,Text), Int>;
    };

    public type StableCollectionData = {
        logo: ?Text;
        name: ?Text;
        symbol: ?Text;
        metadata: ?CandyTypes.CandyValue;
        owner : Principal;
        managers: [Principal];
        network: ?Principal;
        allocated_storage: Nat;
        available_space : Nat;
        active_bucket: ?Principal;
    };

    public func stabilize_collection_data (item : CollectionData) : StableCollectionData {
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
        }
    };
    
    public type StableBucketData = {
        principal : Principal;
        allocated_space: Nat;
        available_space: Nat;
        date_added: Int;
        b_gateway: Bool;
        version: (Nat, Nat, Nat);
        allocations: [((Text,Text),Int)];
    };
    
    public func stabilize_bucket_data (item : BucketData) : StableBucketData {
        {
            principal = item.principal;
            allocated_space = item.allocated_space;
            available_space = item.available_space;
            date_added = item.date_added;
            b_gateway = item.b_gateway;
            version = item.version;
            allocations = Iter.toArray(Map.entries<(Text,Text), Int>(item.allocations)); 
        }
    };

    public type StableEscrowBalances = [(Account,Account,Text,EscrowRecord)];
    public type StableSalesBalances = [(Account,Account,Text,EscrowRecord)];
    public type StableOffers = [(Account,Account,Int)];
    public type StableNftLedger = [(Text,TransactionRecord)];
    public type StableNftSales = [(Text,SaleStatusStable)];

    public type BackupResponse = {
        canister : Principal; 
        access_tokens : [(Text, HttpAccess)]; 
        nft_library : [(Text,[(Text,CandyTypes.AddressedChunkArray)])]; 
        collection_data : StableCollectionData;
        buckets : [(Principal,StableBucketData)];
        allocations: [((Text,Text), AllocationRecordStable)];
        escrow_balances : StableEscrowBalances;
        sales_balances : StableSalesBalances;
        offers : StableOffers;
        nft_ledgers : StableNftLedger;
        nft_sales : [(Text,SaleStatusStable)]; 

    };

    public type StateSize = {
        access_tokens: Nat;
        nft_library: Nat;
        buckets: Nat;
        allocations: Nat;
        escrow_balances: Nat;
        sales_balances : Nat;
        offers: Nat;
        nft_ledgers: Nat;
        nft_sales: Nat;
    };

    public type GatewayState = GatewayState_v0_1_0;

    public type GatewayState_v0_1_0 = MigrationTypes.Current.State;

    public type StorageState = StorageState_v_0_1_0;

    public type StorageState_v_0_1_0 ={

        var state : StorageMigrationTypes.Current.State;
        canister : () -> Principal;
        get_time: () -> Int;
        var nft_library : TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>>;
        tokens : TrieMap.TrieMap<Text, HttpAccess>;

        refresh_state: () -> StorageState_v_0_1_0;
    };

    public type StorageMetrics = {
        allocated_storage: Nat;
        available_space: Nat;
        allocations: [AllocationRecordStable];
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

    public type AllocationRecordStable = {
        canister : Principal;
        allocated_space: Nat;
        available_space: Nat;
        chunks: [Nat];
        token_id: Text;
        library_id: Text;
    };

    public func allocation_record_stabalize(item:AllocationRecord) : AllocationRecordStable{
        {canister = item.canister;
        allocated_space = item.allocated_space;
        available_space = item.available_space;
        chunks = SB.toArray<Nat>(item.chunks);
        token_id = item.token_id;
        library_id = item. library_id;}
    };

    public type TransactionRecord = MigrationTypes.Current.TransactionRecord;

    public type NFTUpdateRequest ={
        #replace:{
            token_id: Text;
            data: CandyTypes.CandyValue;
        };
        #update:{
            token_id: Text;
            app_id: Text;
            update: CandyTypes.UpdateRequest;

        }
    };

    public type NFTUpdateResponse = Bool;

    public type EndSaleResponse = TransactionRecord;

    public type EscrowRecord = MigrationTypes.Current.EscrowRecord;

    public type ManageSaleRequest = {
        #end_sale : Text; //token_id
        #open_sale: Text; //token_id;
        #escrow_deposit: EscrowRequest;
        #refresh_offers: ?Account;
        #bid: BidRequest;
        #withdraw: WithdrawRequest;
    };

    public type ManageSaleResponse = {
        #end_sale : EndSaleResponse; //trx record if succesful
        #open_sale: Bool; //true if opened, false if not;
        #escrow_deposit: EscrowResponse;
        #refresh_offers: [EscrowRecord];
        #bid: BidResponse;
        #withdraw: WithdrawResponse;
    };

    public type SaleInfoRequest = {
        #active : ?(Nat, Nat); //get al list of active sales
        #history : ?(Nat, Nat); //skip, take
        #status : Text; //saleID
        #deposit_info : ?Account;
    };

    public type SaleInfoResponse = {
       #active: {
            records: [(Text, ?SaleStatusStable)];
            eof: Bool;
            count: Nat};
        #history : {
            records: [?SaleStatusStable];
            eof: Bool;
            count : Nat};
        #status: ?SaleStatusStable;
        #deposit_info: SubAccountInfo; 
    };


    public type GovernanceRequest = {
        #clear_shared_wallets : Text; //token_id of shared wallets to clear
        
    };

    public type GovernanceResponse = {
        #clear_shared_wallets : Bool; //result
        
    };

    

    public type StakeRecord = {amount: Nat; staker: Account; token_id: Text;};

    public type BalanceResponse = {
        multi_canister: ?[Principal];
        nfts: [Text];
        escrow: [EscrowRecord];
        sales: [EscrowRecord];
        stake: [StakeRecord];
        offers: [EscrowRecord];
    };

    public type LocalStageLibraryResponse = {
        #stage_remote : {
            allocation :AllocationRecord;
            metadata: CandyTypes.CandyValue;
        };
        #staged : Principal;
    };

    public type StageLibraryResponse = {
        canister: Principal;
    };

    public type WithdrawDescription = {
        buyer: Account;
        seller: Account;
        token_id: Text;
        token: TokenSpec;
        amount: Nat;
        withdraw_to : Account;
    };


    public type DepositWithdrawDescription = {
        buyer: Account;
        token: TokenSpec;
        amount: Nat;
        withdraw_to : Account;
    };

     public type RejectDescription = {
        buyer: Account;
        seller: Account;
        token_id: Text;
        token: TokenSpec;
    };

    public type WithdrawRequest = { 
        #escrow: WithdrawDescription;
        #sale: WithdrawDescription;
        #reject:RejectDescription;
        #deposit: DepositWithdrawDescription;
    };
    

    public type WithdrawResponse = TransactionRecord;

    public type CollectionInfo = {
        fields: ?[(Text, ?Nat, ?Nat)];
        logo: ?Text;
        name: ?Text;
        symbol: ?Text;
        total_supply: ?Nat;
        owner: ?Principal;
        managers: ?[Principal];
        network: ?Principal;
        token_ids: ?[Text];
        token_ids_count: ?Nat;
        multi_canister: ?[Principal];
        multi_canister_count: ?Nat;
        metadata: ?CandyTypes.CandyValue;
        allocated_storage : ?Nat;
        available_space : ?Nat;
    };

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

    public type CollectionDataForStorage = {

        var owner : Principal;
        var managers: [Principal];
        var network: ?Principal;

    };

    public type ManageStorageRequest = {
        #add_storage_canisters : [(Principal, Nat, (Nat, Nat, Nat))];
    };

    public type ManageStorageResponse = {
        #add_storage_canisters : (Nat,Nat);//space allocated, space available
    };

    public type LogEntry = {
        event : Text;
        timestamp: Int;
        data: CandyTypes.CandyValue;
        caller: ?Principal;
    };

    public type OrigynError = {number : Nat32; text: Text; error: Errors; flag_point: Text;};

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

    };

    public func errors(the_error : Errors, flag_point: Text, caller: ?Principal) : OrigynError {
        switch(the_error){
            case(#id_not_found_in_metadata){
                return {
                    number = 1; 
                    text = "id was not found in the metadata. id is required.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;

                    }
            };
             case(#attempt_to_stage_system_data){
                return {
                    number = 2; 
                    text = "user attempted to set the __system metadata during staging.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#cannot_find_status_in_metadata){
                return {
                    number = 3; 
                    text = "Cannot find __system.status in metadata. It was expected to be there.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#token_not_found){
                return {
                    number = 4; 
                    text = "Cannot find token.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#library_not_found){
                return {
                    number = 5; 
                    text = "Cannot find library.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            
            case(#content_not_found){
                return {
                    number = 6; 
                    text = "Cannot find chunk.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#content_not_deserializable){
                return {
                    number = 7; 
                    text = "Cannot deserialize chunk.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#cannot_restage_minted_token){
                return {
                    number = 8; 
                    text = "Cannot restage minted token.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#owner_not_found){
                return {
                    number = 9; 
                    text = "Cannot find owner.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#item_already_minted){
                return {
                    number = 10; 
                    text = "Already minted.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#item_not_owned){
                return {
                    number = 11; 
                    text = "Account does not own this item.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#app_id_not_found){
                return {
                    number = 12; 
                    text = "App id not found in app node.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#existing_sale_found){
                return {
                    number = 13; 
                    text = "A sale for this item is already underway.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#out_of_range){
                return {
                    number = 14; 
                    text = "out of rang.";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#property_not_found){
                return {
                    number = 15; 
                    text = "property not found";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            
            //1000s - Error with underlying system
            case(#update_class_error){
                return {
                    number = 1000; 
                    text = "class could not be updated";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            //
            case(#nyi){
                return {
                    number = 1999; 
                    text = "not yet implemented";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };

             case(#unreachable){
                return {
                    number = 1998; 
                    text = "unreachable";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#not_enough_storage){
                return {
                    number = 1001;
                    text = "not enough storage";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;
                }
            };
            case(#malformed_metadata){
                return {
                    number = 1002;
                    text = "malformed metadata";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;
                }

            };
            case(#storage_configuration_error){
                return {
                    number = 1003;
                    text = "storage configuration error";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;
                }
            };
            //2000s - access
            case(#unauthorized_access){
                return {
                    number = 2000; 
                    text = "unauthorized access";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            //3000 - escrow erros
            case(#no_escrow_found){
                return {
                    number = 3000; 
                    text = "no escrow found";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            
            case(#deposit_burned){
                return {
                    number = 3001; 
                    text = "deposit has already been burned";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };

            case(#escrow_owner_not_the_owner){
                return {
                    number = 3002; 
                    text = "the owner in the escrow request does not own the item";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#validate_deposit_failed){
                return {
                    number = 3003; 
                    text = "validate deposit failed";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#validate_trx_wrong_host){
                return {
                    number = 3004; 
                    text = "validate deposit failed - wrong host";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#validate_deposit_wrong_amount){
                return {
                    number = 3005; 
                    text = "validate deposit failed - wrong amount";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#validate_deposit_wrong_buyer){
                return {
                    number = 3006; 
                    text = "validate deposit failed - wrong buyer";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#withdraw_too_large){
                return {
                    number = 3007; 
                    text = "withdraw too large";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#escrow_cannot_be_removed){
                return {
                    number = 3008; 
                    text = "escrow  cannot be removed";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#escrow_withdraw_payment_failed){
                return {
                    number = 3009; 
                    text = "could not pay the escrow";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#sales_withdraw_payment_failed){
                return {
                    number = 3010; 
                    text = "could not pay the sales withdraw";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            
            
            case(#improper_interface){
                return {
                    number = 3800; 
                    text = "improper interface";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };

            //auction errors
             case(#sale_not_found){
                return {
                    number = 4000; 
                    text = "sale not found";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#receipt_data_mismatch){
                return {
                    number = 4001; 
                    text = "receipt_data_mismatch";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#asset_mismatch){
                return {
                    number = 4002; 
                    text = "asset mismatch";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#token_id_mismatch){
                return {
                    number = 4003; 
                    text = "token ids do not match";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#bid_too_low){
                return {
                    number = 4004; 
                    text = "bid too low";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#sale_id_does_not_match){
                return {
                    number = 4005; 
                    text = "sale not found";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
             case(#auction_ended){
                return {
                    number = 4006; 
                    text = "auction has ended";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#sale_not_over){
                return {
                    number = 4007; 
                    text = "sale not over";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#auction_not_started){
                return {
                    number = 4008; 
                    text = "sale not started";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller;}
            };
            case(#token_non_transferable){
                return {
                    number = 4009; 
                    text = "token is soulbound";
                    error = the_error;
                    flag_point = flag_point;}
            };                
        };
    };

    public let nft_status_staged = "staged";
    public let nft_status_minted = "minted";

    public let metadata :{
        __system : Text;
        __system_status : Text;
        __system_secondary_royalty : Text;
        __system_primary_royalty : Text;
        __system_node : Text;
        __system_originator : Text;
        __system_wallet_shares : Text;
        __apps :Text;
        library : Text;
        library_id : Text;
        library_size : Text;
        library_location_type: Text;
        owner : Text;
        id: Text;
        primary_asset: Text;
        preview_asset: Text;
        experience_asset: Text;
        hidden_asset: Text;
        is_soulbound: Text;
        primary_host: Text;
        primary_port: Text;
        primary_protcol: Text;
        primary_royalties_default : Text;
        royalty_broker : Text;
        royalty_node : Text;
        royalty_originator : Text;
        royalty_network : Text;
        royalty_custom : Text;
        secondary_royalties_default : Text;
        __apps_app_id : Text;
        __system_current_sale_id : Text
    } = {
        __system = "__system";
        __system_status = "status";
        __system_secondary_royalty = "com.origyn.royalties.secondary";
        __system_primary_royalty = "com.origyn.royalties.primary";
        __system_node = "com.origyn.node";
        __system_originator = "com.origyn.originator";
        __system_wallet_shares = "com.origyn.wallet_shares";
        __apps = "__apps";
        library = "library";
        library_id = "library_id";
        library_size = "size";
        library_location_type = "location_type";
        owner = "owner";
        id = "id";
        primary_asset = "primary_asset";
        preview_asset = "preview_asset";
        primary_royalties_default = "com.origyn.royalties.primary.default";
        secondary_royalties_default = "com.origyn.royalties.secondary.default";
        hidden_asset = "hidden_asset";
        is_soulbound = "is_soulbound";
        primary_host = "primary_host";
        primary_port = "primary_port";
        primary_protcol = "primary_protcol";
        royalty_broker = "com.origyn.royalty.broker";
        royalty_node = "com.origyn.royalty.node";
        royalty_originator = "com.origyn.royalty.originator";
        royalty_network = "com.origyn.royalty.network";
        royalty_custom = "com.origyn.royalty.custom";
        experience_asset = "experience_asset";
        __apps_app_id = "app_id";
        __system_current_sale_id = "current_sale_id";
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
               return Text.compare(Conversions.valueToText(a_token), Principal.toText(b_token.canister));
            };
            case(#ic(a_token), #extensible(b_token)){
               return  Text.compare(Principal.toText(a_token.canister),Conversions.valueToText(b_token));
            };
            case(#extensible(a_token), #extensible(b_token)){
               return Text.compare(Conversions.valueToText(a_token), Conversions.valueToText(b_token));
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
                Nat32.toNat(Text.hash(Conversions.valueToText(a_extensible)));

            };
        };
    };

    public func account_hash_uncompressed(a : Account) : Nat{
                switch(a){
             case(#principal(a_principal)){
                NFTUtils.hashBlob(Principal.toBlob(a_principal));
             };
             case(#account_id(a_account_id)){

                let accountBlob = switch(hex.decode(a_account_id)){
                  case(#ok(item)){Blob.fromArray(item)};
                  case(#err(err)){
                    D.trap("Not a valid hex");
                  };
                };
                NFTUtils.hashBlob(accountBlob);
             };
             case(#account(a_account)){
                let account_id = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(a_account.owner, switch(a_account.sub_account){case(null){null}; case(?val){?Blob.toArray(val)}}));
                let accountBlob = switch(hex.decode(account_id)){
                  case(#ok(item)){Blob.fromArray(item)};
                  case(#err(err)){
                    D.trap("Not a valid hex");
                  };
                };
                NFTUtils.hashBlob(accountBlob);
             };
             case(#extensible(a_extensible)){
                 //unimplemnted; unsafe; probably dont use
                 //until a reliable valueToHash function is written
                 //if any redenring of classes changes the whole hash
                 //will change
                NFTUtils.hashBlob(Conversions.valueToBlob(#Text(Conversions.valueToText(a_extensible))));
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
                Nat32.toNat(Text.hash(Conversions.valueToText(a_extensible)));
            };
        };
        
    };

    public func token_hash_uncompressed(a : TokenSpec) : Nat {
        switch(a){
            case(#ic(a)){
                NFTUtils.hashBlob(Principal.toBlob(a.canister));


            };
            case(#extensible(a_extensible)){
                 //unimplemnted; unsafe; probably dont use
                //until a reliable valueToHash function is written
                //if any redenring of classes changes the whole hash
                //will change
                NFTUtils.hashBlob(Conversions.valueToBlob(a_extensible));

            };
        };
        
    };

    public let account_handler = (account_hash, account_eq);

    public let token_handler = (token_hash, token_eq);

    public type HTTPResponse = {
        body               : Blob;
        headers            : [HeaderField];
        status_code        : Nat16;
        streaming_strategy : ?StreamingStrategy;
    };

    

    public type StreamingCallback = query (StreamingCallbackToken) -> async (StreamingCallbackResponse);

    

    public type StreamingCallbackResponse = {
        body  : Blob;
        token : ?StreamingCallbackToken;
    };

    public type StorageService = actor{
        stage_library_nft_origyn : shared (StageChunkArg, AllocationRecordStable, CandyTypes.CandyValue) -> async Result.Result<StageLibraryResponse,OrigynError>;
        storage_info_nft_origyn : shared query () -> async Result.Result<StorageMetrics, OrigynError>;
        chunk_nft_origyn : shared query ChunkRequest -> async Result.Result<ChunkContent, OrigynError>;
        refresh_metadata_nft_origyn : (token_id: Text, metadata: CandyTypes.CandyValue) -> async Result.Result<Bool, OrigynError>
    };

    public type Service = actor {
        __advance_time : shared Int -> async Int;
        __set_time_mode : shared { #test; #standard } -> async Bool;
        balance : shared query EXT.BalanceRequest -> async BalanceResponse;
        balanceEXT : shared query EXT.BalanceRequest -> async BalanceResponse;
        balanceOfDip721 : shared query Principal -> async Nat;
        balance_of_nft_origyn : shared query Account -> async Result.Result<BalanceResponse, OrigynError>;
        bearer : shared query EXT.TokenIdentifier -> async Result.Result<Account, OrigynError>;
        bearerEXT : shared query EXT.TokenIdentifier -> async Result.Result<Account, OrigynError>;
        bearer_nft_origyn : shared query Text -> async Result.Result<Account, OrigynError>;
        bearer_batch_nft_origyn : shared query [Text] -> async [Result.Result<Account, OrigynError>];
        bearer_secure_nft_origyn : shared Text -> async Result.Result<Account, OrigynError>;
        bearer_batch_secure_nft_origyn : shared [Text] -> async [Result.Result<Account, OrigynError>];
        canister_status : shared {
            canister_id : canister_id;
        } -> async canister_status;
        collection_nft_origyn : (fields : ?[(Text, ?Nat, ?Nat)]) -> async Result.Result<CollectionInfo, OrigynError>;
        collection_update_nft_origyn : (ManageCollectionCommand) -> async Result.Result<Bool, OrigynError>;
        collection_update_batch_nft_origyn : ([ManageCollectionCommand]) -> async [Result.Result<Bool, OrigynError>];
        cycles : shared query () -> async Nat;
        getEXTTokenIdentifier : shared query Text -> async Text;
        get_nat_as_token_id : shared query Nat -> async Text;
        get_token_id_as_nat : shared query Text -> async Nat;
        http_request : shared query HttpRequest -> async HTTPResponse;
        http_request_streaming_callback : shared query StreamingCallbackToken -> async StreamingCallbackResponse;
        manage_storage_nft_origyn : shared ManageStorageRequest -> async Result.Result<ManageStorageResponse, OrigynError>;
        market_transfer_nft_origyn : shared MarketTransferRequest -> async Result.Result<MarketTransferRequestReponse,OrigynError>;
        market_transfer_batch_nft_origyn : shared [MarketTransferRequest] -> async [Result.Result<MarketTransferRequestReponse,OrigynError>];
        mint_nft_origyn : shared (Text, Account) -> async Result.Result<Text,OrigynError>;
        nftStreamingCallback : shared query StreamingCallbackToken -> async StreamingCallbackResponse;
        chunk_nft_origyn : shared query ChunkRequest -> async Result.Result<ChunkContent, OrigynError>;
        history_nft_origyn : shared query (Text, ?Nat, ?Nat) -> async Result.Result<[TransactionRecord],OrigynError>;
        nft_origyn : shared query Text -> async Result.Result<NFTInfoStable, OrigynError>;
        update_app_nft_origyn : shared NFTUpdateRequest -> async Result.Result<NFTUpdateResponse, OrigynError>;
        ownerOf : shared query Nat -> async DIP721.OwnerOfResponse;
        ownerOfDIP721 : shared query Nat -> async DIP721.OwnerOfResponse;
        share_wallet_nft_origyn : shared ShareWalletRequest -> async Result.Result<OwnerTransferResponse,OrigynError>;
        sale_nft_origyn : shared ManageSaleRequest -> async Result.Result<ManageSaleResponse,OrigynError>;
        sale_info_nft_origyn : shared SaleInfoRequest -> async Result.Result<SaleInfoResponse,OrigynError>;
        stage_library_nft_origyn : shared StageChunkArg -> async Result.Result<StageLibraryResponse,OrigynError>;
        stage_nft_origyn : shared { metadata : CandyTypes.CandyValue } -> async Result.Result<Text, OrigynError>;
        storage_info_nft_origyn : shared query () -> async Result.Result<StorageMetrics, OrigynError>;
        transfer : shared EXT.TransferRequest -> async EXT.TransferResponse;
        transferEXT : shared EXT.TransferRequest -> async EXT.TransferResponse;
        transferFrom : shared (Principal, Principal, Nat) -> async DIP721.Result;
        transferFromDip721 : shared (Principal, Principal, Nat) -> async DIP721.Result;
        whoami : shared query () -> async Principal;
    };


}