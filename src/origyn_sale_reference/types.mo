import Buffer "mo:base/Buffer";
import Deque "mo:base/Deque";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import StableBuffer "mo:base/Buffer";

import AccountIdentifier "mo:principalmo/AccountIdentifier";
import CandyTypes "mo:candy_0_1_10/types";
import EXT "mo:ext/Core";
import Map "mo:map_6_0_0/Map";
import SB "mo:stablebuffer_0_2_0/StableBuffer";

import NFTTypes "../origyn_nft_reference/types";

module {


    public type OrigynError = {number : Nat32; text: Text; error: Errors; flag_point: Text;};

    public type InitArgs = {
        owner: Principal;                    //owner of the canister
        allocation_expiration: Int;          //amount of time to keep an allocation for 900000000000 = 15 minutes
        nft_gateway: ?Principal;             //the nft gateway canister this sales canister will sell NFTs for
        sale_open_date : ?Int;              //date that the NFTs in the registration shold be minted/allocated
        registration_date: ?Int;              //date that registations open up
        end_date: ?Int;                      //date that the canister closes its sale
        required_lock_date: ?Int             //date that users must lock their tokens until to qualify for reservations
    };

    public type ManageCommand = {
        #UpdateOwner : Principal;
        #UpdateAllocationExpiration : Int;
        #UpdateNFTGateway: ?Principal;
        #UpdateSaleOpenDate: ?Int;
        #UpdateRegistrationDate: ?Int;
        #UpdateEndDate: ?Int;
        #UpdateLockDate: ?Int;
    };

    public type NFTInventoryItem = {
        canister: Principal;                // principal that the nft is on
        token_id: Text;                     // unique namespace of the item
        var available: Bool;                    // if the item is available
        var sale_block: ?Nat;                   // transaction id used to sell the item
        var allocation : ?Principal;
        var reservations : Map.Map<Text,Int>;
        
    };

    public type NFTInventoryItemDetail = {
        canister: Principal;                // principal that the nft is on
        token_id: Text;                     // unique namespace of the item
        available: Bool;                    // if the item is available
        sale_block: ?Nat;                   // transaction id used to sell the item
        allocation : ?Principal;
        reservations : [(Text,Int)];
    };

    public func stabalize_xfer_NFTInventoryItem(item : (Text, NFTInventoryItem)) : NFTInventoryItemDetail {
            {
                canister = item.1.canister;
                token_id = item.1.token_id;
                available = item.1.available;
                sale_block = item.1.sale_block;
                allocation = item.1.allocation;
                reservations = Iter.toArray<(Text,Int)>(Map.entries<Text,Int>(item.1.reservations));
            }
        };

    public type NFTInventoryItemRequest = {
        canister: Principal;                // principal that the nft is on
        token_id: Text;                     // unique namespace of the item
    };
    
    // Is Text our best option for the key?
    public type NFTInventory = Map.Map<Text,NFTInventoryItem>;
     


    public type GetInventoryItemResponse = NFTInventoryItem;

    public type GetInventoryResponse = {
        total_size : Nat;
        items : [NFTInventoryItemDetail];
        start : Nat;
    };

    public type Allocation = {
        principal: Principal;
        var token: ?TokenSpec;
        var nfts: [Text];
        var expiration: Int;
    };

    public type Allocations = Map.Map<Principal, Allocation>;

    

    // public type ReservationStable = {
    //     namespace: Text;
    //     reservation_type : {
    //         #Groups : [Text] ;
    //         #Principal : Principal;
    //     };
    //     exclusive: Bool;
    //     nfts: [NFTInventoryItem];
    // };

    

    public type Purchases = Map.Map<Principal, Map.Map<Text, NFTTypes.TransactionRecord>>;

    
    
    // Which is the right group??
    public type Groups = Map.Map<Text,Group>; 

    public type Group = {
        namespace: Text;
        var members: Map.Map<Principal, Int>; //<user, timestamp added>
        var redemptions: Map.Map<Principal, Nat>; //<users, number redeemed>
        var pricing: Pricing;
        var allowed_amount: ?AllowedAmount;
        var additive: Bool;
        var tier: Nat;
    };

    public type GroupStable = {
        namespace: Text;
        members: [(Principal, Int)]; //<user, timestamp added>
        redemptions: [(Principal, Nat)]; //<users, number redeemed>
        pricing: Pricing;
        allowed_amount: ?AllowedAmount;
        additive: Bool;
        tier: Nat;
    };

    public func group_stabalize(item : Group) : GroupStable {

        return {
            namespace = item.namespace;
            members = Iter.toArray(Map.entries<Principal, Int>(item.members)); //<user, timestamp added>
            redemptions =  Iter.toArray(Map.entries<Principal, Nat>(item.redemptions));//<users, number redeemed>
            pricing = item.pricing;
            allowed_amount = item.allowed_amount;
            additive = item.additive;
            tier = item.tier;
        };
    };





    public type AddGroupRequest = {
        key: Text;
        item: {
            #add: {
                namespace: Text;
                members: [Principal];
                pricing: ?Pricing;
                allowed_amount: ?AllowedAmount;
                tier: Nat;
                additive: Bool;
            };
        };
    };    
    // public type GroupsStable = [(Text,GroupStable)];

    // public type GroupStable = {
    //     namespace: Text;
    //     members: [Principal];
    //     redemptions:[(Principal, Nat)];
    //     pricing: ?Pricing;
    //     allowed_amount: ?AllowedAmount;
    // };
    public type GetGroupResponse = [{
        namespace: Text;
        pricing: ?Pricing;
        allowed_amount: ?AllowedAmount;
    }];
    public type GetEscrowResponse = {
        receipt: NFTTypes.EscrowReceipt;
        balance: Nat;
        transaction: NFTTypes.TransactionRecord;
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
        };
    };

    // ToDo: Need to add opt : #cost_per & #free - I keep having an error when add those options
    public type Pricing = [{
        #cost_per: {
            amount: Nat;
            token: TokenSpec;
        };
        #free
    }];

    public type State = {
        var owner : Principal;
        var manager : ?Principal;
        var nft_inventory : NFTInventory;
        var nft_group : Groups;
        var nft_group_size : Nat;
        var nft_reservation : Reservations;
        var nft_reservation_size : Nat;
        var user_allocations : Allocations;
        var user_registrations : Registrations;
        var user_purchases: Purchases;
        var allocation_expiration : Int;
        var nft_gateway : ?Principal;
        var sale_open_date : ?Int;
        var registration_date : ?Int;
        var end_date : ?Int;
        var required_lock_date : ?Int;
        var allocation_queue : Deque.Deque<(Principal, Int)>;
    };

    public type SaleMetrics = {
        owner : Principal;
        allocation_expiration : Int;
        nft_gateway : ?Principal;
        sale_open_date : ?Int;
        registration_date : ?Int;
        end_date : ?Int;
        //feel free to add liberally
    };
   
    public type AllowedAmount = Nat;

    public type ManageNFTRequest = {
        #add: NFTInventoryItemRequest;
        #remove: Text; //token_id should be unique
    };

    public type ManageNFTItemResponse = {
        #add: Text;
        #remove: Text;
        #err: (Text, OrigynError);
    };

    public type ManageNFTResponse = {
        total_size: Nat;
        items: [ManageNFTItemResponse];
    };

    public type ManageGroupRequest = [{
        #update: {
            namespace: Text;
            members: ?[Principal];
            pricing: ?Pricing;
            allowed_amount: ?AllowedAmount;
            tier: Nat;
            additive: Bool;
        };
        #remove: {
            namespace: Text;
        };
        #addMembers: {
            namespace: Text;
            members: [Principal];
        };
        #removeMembers: {
            namespace: Text;
            members: [Principal];
        };
    }];

    public type ManageGroupResult = {
            #update: Result.Result<GroupStable, OrigynError>;
            #remove: Result.Result<Text, OrigynError>;//namespace removed
            #addMembers: Result.Result<(Nat, Nat), OrigynError>;//number added, number total
            #removeMembers: Result.Result<(Nat,Nat), OrigynError>;//number added, number total
            #err: OrigynError;
        };

    public type ManageGroupResponse = [ManageGroupResult];

    public type Reservations = Map.Map<Text,Reservation>;

    public type Reservation = {
        namespace: Text;
        reservation_type : ReservationType;
        exclusive: Bool; //this means that these nfts only can be in this reservation
        nfts: [Text];
    };
    public type ReservationType = {
            #Groups : [Text];
            #Principal : Principal;
    };

    public type ManageReservationRequest = {
        #add: {
            namespace: Text;
            reservation_type : {
                #Groups : [Text] ;
                #Principal : Principal;
            };
            exclusive: Bool;
            nfts: [Text];
        };
        #remove: {
            namespace: Text;
        };
        #addNFTs: {
            namespace: Text;
            nfts: [Text];
        };
        #removeNFTs: {
            namespace: Text;
            nfts: [Text];
        };
        #update_type: {
            namespace: Text;
            reservation_type : {
                #Groups : [Text] ;
                #Principal : Principal;
            };
        };
    };

    public type ManageReservationItemResponse = {
        #add: Text;
        #remove: Text;
        #addNFTs: Nat;
        #removeNFTs: Nat;
        #update_type : Text;
        #err: (Text, OrigynError);
    };

    public type ManageReservationResponse = {
        total_size: Nat;
        items: [ManageReservationItemResponse];
    };

    public type AllocationRequest = {
        principal : Principal;
        number_to_allocate: Nat; //creator can set a max
        token: ?TokenSpec; //null if only claiming free items
    };

    public type AllocationResponse = {
        allocation_size: Nat;
        token: ?TokenSpec;
        principal: Principal;
        expiration: Int;
    };

    public type RedeemAllocationRequest = {
        escrow_receipt: NFTTypes.EscrowReceipt; //creator can set a max
    };

    public type RedeemAllocationResponse = {
        nfts: [{token_id:Text; transaction: Result.Result< NFTTypes.TransactionRecord, OrigynError>}];
    };

    //users can only have one registration so we want to be careful about overwriting
    //data about allocations.
    public type Registration = {
        principal: Principal;
        var max_desired: Nat;
        var escrow_receipt: ?NFTTypes.EscrowReceipt;
        var allocation_size : Nat;
        var allocation: Map.Map<Text,RegistrationClaim>;
    };

    public type RegistrationClaim = {
        var claimed : Bool;
        var trx : ?NFTTypes.TransactionRecord;
    };

    public type Registrations = Map.Map<Principal,Registration>;

    public type RegisterEscrowRequest = {
        principal: Principal;
        max_desired: Nat;
        escrow_receipt: ?NFTTypes.EscrowReceipt; //creator can set a max
    };

    public type RegisterEscrowAllocationDetail = {
            token_id: Text;
            claimed: Bool;
            trx: ?NFTTypes.TransactionRecord;
        };
    

    public func stabalize_xfer_RegisterAllocation(item: (Text, RegistrationClaim)) : RegisterEscrowAllocationDetail{
    return {
        token_id = item.0;
        claimed = item.1.claimed;
        trx = item.1.trx;
    }};

    public type RegisterEscrowResponse = {
        max_desired: Nat;
        principal: Principal;
        escrow_receipt: ?NFTTypes.EscrowReceipt; //creator can set a max
        allocation : [RegisterEscrowAllocationDetail];
        allocation_size: Nat;
    };
  
    public type TestRequest = {
        account_id: NFTTypes.Account;
        standard: {
            #DIP20;
            #Ledger;
            #EXTFungible;
        };
    };

    public type Errors = {
        #bad_date;
        #bad_canister_trx;
        #reservation_item_exists;
        #reservation_item_does_not_exists;
        #group_item_exists;
        #group_item_does_not_exists;
        #inventory_item_exists;
        #inventory_item_does_not_exists;
        #improper_allocation;
        #improper_escrow;
        #improper_lock;
        #inventory_empty;
        #registartion_not_open;
        #allocation_does_not_exist;
        #bad_config;
        #nyi;
        #ijn;
        #nti;
        #unauthorized_access
    };

    public func errors(the_error : Errors, flag_point: Text, caller: ?Principal) : OrigynError {


        switch(the_error){
            case(#bad_date){
                return {
                    number = 16; 
                    text = "bad date";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
            case(#bad_config){
                return {
                    number = 32; 
                    text = "bad config";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
            
            case(#bad_canister_trx){
                return {
                    number = 64; 
                    text = "bad canister trx";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };



            case(#unauthorized_access){
                return {
                    number = 2000; 
                    text = "unauthorized access";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };

            //inventory 4000s
            case(#inventory_item_exists){
                return {
                    number = 4000; 
                    text = "inventory item exists";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
            case(#inventory_item_does_not_exists){
                return {
                    number = 4001; 
                    text = "inventory item does not exists";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };

            case(#group_item_exists){
                return {
                    number = 4002; 
                    text = "group item exists";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
            case(#group_item_does_not_exists){
                return {
                    number = 4003; 
                    text = "group item does not exists";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
            case(#reservation_item_exists){
                return {
                    number = 4004; 
                    text = "reservation item exists";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
            case(#reservation_item_does_not_exists){
                return {
                    number = 4005; 
                    text = "reservation item does not exists";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };

            //allocations 5000
            case(#improper_allocation){
                return {
                    number = 5000; 
                    text = "improper allocation";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
            case(#allocation_does_not_exist){
                return {
                    number = 5001; 
                    text = "allocation does not exist";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
            case(#improper_lock){
                return {
                    number = 5002; 
                    text = "improper escrow lock";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
             case(#improper_escrow){
                return {
                    number = 5003; 
                    text = "ecrow not valid";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
            case(#inventory_empty){
                return {
                    number = 5004; 
                    text = "inventory empty";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
            case(#registartion_not_open){
                return {
                    number = 5005; 
                    text = "registration not open";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };

            


            //
            case(#nyi){
                return {
                    number = 1999; 
                    text = "not yet implemented";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
            case(#ijn){
                return {
                    number = 001; 
                    text = "implemented just now";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
            case(#nti){
                return {
                    number = 002; 
                    text = "No token ids";
                    error = the_error;
                    flag_point = flag_point;
                    caller = caller}
            };
            

            
            
        };
    };


    public type Service = actor {
        manage_nfts_sale_nft_origyn : ([ManageNFTRequest]) -> async Result.Result<ManageNFTResponse, OrigynError>;
        allocate_sale_nft_origyn:  (AllocationRequest) -> async Result.Result<AllocationResponse, OrigynError>;
        redeem_allocation_sale_nft_origyn: (RedeemAllocationRequest) -> async Result.Result<RedeemAllocationResponse, OrigynError>;
        register_escrow_sale_nft_origyn: (RegisterEscrowRequest) -> async Result.Result<RegisterEscrowResponse, OrigynError>;
        execute_claim_sale_nft_origyn: (Text) -> async Result.Result<NFTTypes.TransactionRecord, OrigynError>;
        manage_reservation_sale_nft_origyn: ([ManageReservationRequest]) -> async Result.Result<ManageReservationResponse, OrigynError>;
    };

}