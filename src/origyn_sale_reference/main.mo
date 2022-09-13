import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import CandyTypes "mo:candy_0_1_10/types";
import D "mo:base/Debug";
import Deque "mo:base/Deque";
import Error "mo:base/Error";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Map "mo:map_6_0_0/Map";
import NFTTypes "../origyn_nft_reference/types";
import NFTUtils "../origyn_nft_reference/utils";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import RBU "mo:base/RBTree";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Types "types";


//this is an alpha canister provided as an example of how one could
//run a sale using the NFT SaleCanister
//comments and documentation are pending

shared (deployer) actor class SaleCanister(__initargs : Types.InitArgs) = this {


    stable var __time_mode : {#test; #standard;} = #standard;
    private var __test_time : Int = 0;

    private func get_time() : Int{
        switch(__time_mode){
            case(#standard){return Time.now();};
            case(#test){return __test_time;};
        };

    };

    //D.print("instantiating sales canister");

    
    stable var state : Types.State = {
        var owner : Principal = __initargs.owner;
        var manager : ?Principal = null;
        var nft_inventory : Types.NFTInventory = Map.new<Text, Types.NFTInventoryItem>();
        var nft_group : Types.Groups = Map.new<Text, Types.Group>();
        var nft_group_size : Nat = 0;
        var nft_reservation : Types.Reservations = Map.new<Text, Types.Reservation>();
        var nft_reservation_size : Nat = 0;
        var user_allocations : Types.Allocations = Map.new<Principal, Types.Allocation>();
        var user_registrations : Types.Registrations = Map.new<Principal, Types.Registration>();
        var user_purchases: Types.Purchases = Map.new<Principal, Map.Map<Text,NFTTypes.TransactionRecord>>();
        var allocation_expiration : Int = __initargs.allocation_expiration;
        var nft_gateway : ?Principal = __initargs.nft_gateway;
        var sale_open_date = __initargs.sale_open_date;
        var registration_date = __initargs.registration_date;
        var end_date = __initargs.end_date;
        var required_lock_date = __initargs.required_lock_date;
        var allocation_queue : Deque.Deque<(Principal, Int)> = Deque.empty<(Principal, Int)>();
    };

   
    // var nft_group : Types.Groups = Map.new<Text, Types.Group>();
    // var nft_group_size : Nat = 0; 
   
    private var DAY_LENGTH = 60 * 60 * 24 * 10 ** 9;

    let ledger_principal : Principal = Principal.fromText("dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe");
    
    let alice_seller : Principal = Principal.fromText("u74sm-wx4yh-capur-xnz4w-orbcn-l3jlc-m65rb-ue5ah-mqyvz-fmvvc-tae");

    let jess_buyer : Principal = Principal.fromText("3j2qa-oveg3-2agc5-735se-zsxjj-4n65k-qmnse-byzkf-4xhw5-mzjxe-pae");

    let timestamp = Time.now();

    let one_month_nanos : Int= 2628000000000000;
    let max_time_nanos : Int = 18653431178000000000;

    public shared(msg) func manage_sale_nft_origyn(command : Types.ManageCommand) : async Result.Result<Bool, Types.OrigynError>{
        switch(command){
            case(#UpdateOwner(val)){
                if(msg.caller ==  state.owner){
                    state.owner := val;
                    return #ok(true);
                } else {
                    return #err(Types.errors(#unauthorized_access, "manage_sale_nft_origyn only owner can manage sale canister", ?msg.caller))
                };
            };
            case(#UpdateAllocationExpiration(val)){
                if(msg.caller ==  state.owner){
                    if(val > one_month_nanos){
                        return #err(Types.errors(#bad_date, "manage_sale_nft_origyn cannot hold deposit for more than one month", ?msg.caller))
                    };
                    state.allocation_expiration := val;
                    return #ok(true);
                } else {
                    return #err(Types.errors(#unauthorized_access, "manage_sale_nft_origyn only owner can manage sale canister", ?msg.caller))
                };
            };
            case(#UpdateNFTGateway(val)){
                if(msg.caller ==  state.owner){
                    state.nft_gateway := val;
                    return #ok(true);
                } else {
                    return #err(Types.errors(#unauthorized_access, "manage_sale_nft_origyn only owner can manage sale canister", ?msg.caller))
                };
            };
            case(#UpdateSaleOpenDate(val)){
                if(msg.caller ==  state.owner){
                    switch(val){
                        case(?val){
                            if(val > max_time_nanos  or  val < get_time() - one_month_nanos){
                                return #err(Types.errors(#bad_date, "manage_sale_nft_origyn sale open date not in a viable range", ?msg.caller))
                            };
                        };
                        case(null){};
                    };
                    state.sale_open_date := val;
                    return #ok(true);
                } else {
                    return #err(Types.errors(#unauthorized_access, "manage_sale_nft_origyn only owner can manage sale canister", ?msg.caller))
                };
            };
            case(#UpdateRegistrationDate(val)){
                if(msg.caller ==  state.owner){
                    switch(val){
                        case(?val){
                            if(val > max_time_nanos  or  val < get_time() - one_month_nanos){
                                return #err(Types.errors(#bad_date, "manage_sale_nft_origyn sale open date not in a viable range", ?msg.caller))
                            };
                        };
                        case(null){};
                    };
                    state.registration_date := val;
                    return #ok(true);
                } else {
                    return #err(Types.errors(#unauthorized_access, "manage_sale_nft_origyn only owner can manage sale canister", ?msg.caller))
                };
            };
            case(#UpdateEndDate(val)){
                if(msg.caller ==  state.owner){
                    switch(val){
                        case(?val){
                            if(val > max_time_nanos  or  val < get_time() - one_month_nanos){
                                return #err(Types.errors(#bad_date, "manage_sale_nft_origyn sale open date not in a viable range", ?msg.caller))
                            };
                        };
                        case(null){};
                    };
                    state.end_date := val;
                    return #ok(true);
                } else {
                    return #err(Types.errors(#unauthorized_access, "manage_sale_nft_origyn only owner can manage sale canister", ?msg.caller))
                };
            };
            case(#UpdateLockDate(val)){
                if(msg.caller ==  state.owner){
                    switch(val){
                        case(?val){
                            if(val > max_time_nanos  or  val < get_time() - one_month_nanos){
                                return #err(Types.errors(#bad_date, "manage_sale_nft_origyn sale open date not in a viable range", ?msg.caller))
                            };
                        };
                        case(null){};
                    };
                    state.required_lock_date := val;
                    return #ok(true);
                } else {
                    return #err(Types.errors(#unauthorized_access, "manage_sale_nft_origyn only owner can manage sale canister", ?msg.caller))
                };
            }

        }
    };


    public query(msg) func get_metrics_sale_nft_origyn() : async Result.Result<Types.SaleMetrics, Types.OrigynError>{
        return #ok{
            owner = state.owner;
            allocation_expiration = state.allocation_expiration;
            nft_gateway = state.nft_gateway;
            sale_open_date = state.sale_open_date;
            registration_date = state.registration_date;
            end_date = state.end_date;
        };

    };


    
    // Retrieves a list of groups for a particular user or address
    public query(msg) func get_groups() : async Result.Result<Types.GetGroupResponse, Types.OrigynError>{
       // ToDo:
       // Are the amounts in cycles?   
       return #ok([
            {
            namespace = "alpha";
            pricing = ?[
                #cost_per({
                    amount = 100_000_000;
                    token = #ic({
                        canister = ledger_principal;
                        fee = 200000;
                        symbol =  "DIP";
                        decimals = 8;
                        standard = #DIP20;
                        });
                })
            ];
            allowed_amount = ?5;
        }
        ]);
        // return #err(Types.errors(#nyi, "manage_nfts nyi", ?msg.caller));
    };

    // We probably don't need this
    public shared(msg) func get_escrow() : async Result.Result<Types.GetEscrowResponse, Types.OrigynError>{
        // ToDo:
        // Need to add more realistic data, the first goal was to spill the correct structure 
        // Are we using the correct txn #escrow_deposit?
        // Find out the how to hardcode candytype and uncomment from here and from types nft_reference

       

        return #ok({
            receipt = {
                amount = 100_000_000; 
                seller = #principal(alice_seller);
                buyer = #principal(jess_buyer);
                token_id = "OG1";
                token = #ic({
                        canister = ledger_principal;
                        fee = 200000;
                        symbol =  "DIP";
                        decimals = 8;
                        standard = #DIP20;
                        });
                
            };
            balance = 100_000_000_000;
            transaction = {
                token_id = "OG1";
                index = 2;
                txn_type = #escrow_deposit({
                seller = #principal(alice_seller);
                buyer = #principal(jess_buyer);
                token =  #ic({
                        canister = ledger_principal;
                        fee = 200000;
                        symbol =  "DIP";
                        decimals = 8;
                        standard = #DIP20;
                        });
                token_id = "OG1";
                amount = 100_000_000;
                trx_id = #nat(10000000);
                extensible = #Bool(false);
            });
            timestamp = timestamp;
            };
        });
        // return #err(Types.errors(#nyi, "manage_nfts nyi", ?msg.caller));
    };
    
    // Allows the adding/removing of inventory items
    //made this a batch process so that adding NFT items doesn't take all day //need to test max add
    public shared(msg) func manage_nfts_sale_nft_origyn(request: [Types.ManageNFTRequest]) : async Result.Result<Types.ManageNFTResponse, Types.OrigynError>{
       
       // ToDo:
       // Need to add better error catching here - trying to get something workable

       //D.print("in manage nft " # debug_show(msg.caller, state.owner));

       if(msg.caller != state.owner){
           return #err(Types.errors(#unauthorized_access, "manage_nfts only owner can manage nfts", ?msg.caller))
       };
       let results = Buffer.Buffer<Types.ManageNFTItemResponse>(request.size());
       for(this_request in request.vals()){
            switch(this_request){         

                case(#add(val)){
                    //search for existing
                    switch(Map.get<Text, Types.NFTInventoryItem>(state.nft_inventory, Map.thash, val.token_id)){
                        case(null){
                            
                            Map.set<Text, Types.NFTInventoryItem>(state.nft_inventory, Map.thash, val.token_id, {
                                canister = val.canister;
                                token_id = val.token_id;
                                var available = true;
                                var sale_block = null;
                                var allocation = null;
                                var reservations = Map.new<Text, Int>(); //<type, timestamp>
                            });
                            results.add(#add(val.token_id));
                        };
                        case(?val){
                            results.add(#err(val.token_id, Types.errors(#inventory_item_exists, "token exists in sales canister " # val.token_id, ?msg.caller)));
                        };
                    };
                    
                };
                case(#remove(val)){
                    //search for existing
                    switch(Map.get<Text,Types.NFTInventoryItem>(state.nft_inventory, Map.thash, val)){
                        case(null){
                            results.add(#err(val, Types.errors(#inventory_item_does_not_exists, "token does not exists in sales canister " # val, ?msg.caller)));
                        };
                        case(?val){
                            
                            Map.delete<Text, Types.NFTInventoryItem>(state.nft_inventory, Map.thash, val.token_id);
                            results.add(#remove(val.token_id));
                        };
                    };
                };
            };
       };

       return #ok({
           total_size = Map.size(state.nft_inventory);
           items = results.toArray()
        });
    };

   
    // Allows the creator to create and manage groups. These groups can be allocated a certain number of NFTs
    // and/or have special pricing based on the number of nfts they buy
    public shared(msg) func manage_group_sale_nft_origyn(request: Types.ManageGroupRequest) : async Types.ManageGroupResponse{

        // ToDo:
      // Add redemptions_size
      // How to add allowed_amount without error from each case
      // Could not add members: SB.StableBuffer ( had an error )
      // Test from test_runner_sale
      
       if(msg.caller != state.owner){
           return [
               #err(Types.errors(#unauthorized_access, "manage_group_sale_nft_origyn only owner can manage groups", ?msg.caller))];
       };

       let results = Buffer.Buffer<Types.ManageGroupResult>(request.size());
       
       for(this_item in request.vals()){
        // redemptions_size : Nat;
        
        
       
            switch(this_item){
                case(#update(val)){
                        //D.print("manage_group_sale_nft_origyn" # "\n" #"add : " #  debug_show(val.namespace) );
                        switch(Map.get<Text, Types.Group>(state.nft_group, Map.thash, val.namespace)){
                            case(null){
                                let thisGroup = {
                                    namespace = val.namespace;
                                    var members = switch(val.members){
                                        case(null){Map.new<Principal, Int>()};
                                        case(?members){
                                            var tree = Map.new<Principal, Int>();
                                            for(this_item in members.vals()){
                                                Map.set<Principal, Int>(tree, Map.phash, this_item, get_time());
                                            };
                                            tree
                                        }
                                    };
                                    var redemptions = Map.new<Principal, Nat>();
                                    var pricing = switch(val.pricing){
                                        case(null){[]};
                                        case(?pricing){pricing};
                                    };
                                    var allowed_amount = val.allowed_amount; 
                                    var tier = val.tier;
                                    var additive = val.additive;
                                };
                                state.nft_group_size += 1;
                                Map.set<Text, Types.Group>(state.nft_group, Map.thash, val.namespace, thisGroup);
                                results.add(#update(#ok(Types.group_stabalize(thisGroup))));
                            };
                            case(?found){

                                switch(val.pricing){
                                    case(null){};
                                    case(?pricing){found.pricing := pricing};
                                };
                                found.allowed_amount := val.allowed_amount;
                                found.additive := val.additive;
                                found.tier := val.tier;
                                switch(val.members){ //if provided replaces the members
                                    case(null){};
                                    case(?members){  
                                        var tree = Map.new<Principal, Int>();
                                        for(this_item in members.vals()){
                                            Map.set<Principal, Int>(tree, Map.phash, this_item, get_time());
                                        };
                                        found.members := tree;
                                    };
                                };

                                results.add(#update(#ok(Types.group_stabalize(found))));
                            };
                        };
                };
                case(#remove(val)){
                    //D.print("manage_group_sale_nft_origyn" # "\n" # "remove : " #  debug_show(val.namespace));
                    switch(Map.get<Text, Types.Group>(state.nft_group, Map.thash, val.namespace)){
                                case(null){
                                    results.add(#remove(#err(Types.errors(#group_item_does_not_exists, "does not exists in sales canister " # val.namespace, ?msg.caller))));                            
                                };
                                case(?val){
                                    state.nft_group_size -= 1;
                                    Map.delete<Text, Types.Group>(state.nft_group, Map.thash, val.namespace);
                                    results.add(#remove(#ok(val.namespace)));
                                };
                        };
                    
                };
                case(#addMembers(val)){
                    //D.print("manage_group_sale_nft_origyn" # "\n" # "addMembers : " #  debug_show(val.namespace));
                    
                    let res = Map.get<Text, Types.Group>(state.nft_group, Map.thash, val.namespace);
                    switch(res){
                        case(null){
                            results.add(#addMembers(#err(Types.errors(#group_item_does_not_exists, "does not exists in sales canister " # val.namespace, ?msg.caller))));
                        };
                        case(?v){ 
                            //let membersToBe = Buffer.Buffer<Principal>(0);
                            for (i in val.members.vals()){
                                Map.set<Principal, Int>(v.members, Map.phash, i, get_time());
                            };
                        

                            /* D.print("manage_group_sale_nft_origyn" # "\n" #
                            "addMembers : " #  debug_show(val.namespace) # "\n\n" #
                            "res  : " #  debug_show(res) # "\n\n" #
                            "val.members  : " #  debug_show(val.members) # "\n\n" #
                            "res.members  : " #  debug_show(v.members) # "\n\n"  #
                            //"MEMBERS TO BE  : " #  debug_show(membersToBe.toArray()) # "\n\n" #
                            "state.nft_group  : " #  debug_show(state.nft_group) # "\n\n" 
                            ); */
                            results.add(#addMembers(#ok((val.members.size(), Map.size(v.members)))));
                        };
                    };
                    
                };
                case(#removeMembers(val)){
                    let res = Map.get<Text, Types.Group>(state.nft_group, Map.thash, val.namespace);
                    switch(res){
                        case(null){
                            results.add(#removeMembers(#err(Types.errors(#group_item_does_not_exists, "does not exists in sales canister " # val.namespace, ?msg.caller))));
                        };
                        case(?v){ 
                            //let membersToBe = Buffer.Buffer<Principal>(0);
                            for (i in val.members.vals()){
                                Map.delete<Principal, Int>(v.members, Map.phash, i);
                            };
                        

                            /* D.print("manage_group_sale_nft_origyn" # "\n" #
                            "addMembers : " #  debug_show(val.namespace) # "\n\n" #
                            "res  : " #  debug_show(res) # "\n\n" #
                            "val.members  : " #  debug_show(val.members) # "\n\n" #
                            "res.members  : " #  debug_show(v.members) # "\n\n"  #
                            //"MEMBERS TO BE  : " #  debug_show(membersToBe.toArray()) # "\n\n" #
                            "state.nft_group  : " #  debug_show(state.nft_group) # "\n\n" 
                            ); */
                            results.add(#removeMembers(#ok((val.members.size(), Map.size(v.members)))));
                        };
                    
                    }; 

                };
            };
        };

        

        return results.toArray();
        // return #err(Types.errors(#nyi, "manage_group_sale_nft_origyn nyi", ?msg.caller));
    };

    // Allows a creator to associate a set of nfts with a particular group or address
    public shared(msg) func manage_reservation_sale_nft_origyn(request: [Types.ManageReservationRequest]) : async Result.Result<Types.ManageReservationResponse, Types.OrigynError>{

        //todo: we really need to moniter the ingress size here and put some limits in...inspect message would be awesome
       if(msg.caller != state.owner){
           return #err(Types.errors(#unauthorized_access, "manage_reservation only owner can manage reservations", ?msg.caller))
       };

       var namespace : Text = "";
       var reservation_type : Types.ReservationType = #Principal(jess_buyer);
       var exclusive : Bool = false;
       var nfts_size : Nat = 0;

       let results = Buffer.Buffer<Types.ManageReservationItemResponse>(request.size());

       for(this_item in request.vals()){
            switch(this_item){
                case(#add(val)){
                    //D.print("manage_reservation" # "\n" #"add : " #  debug_show(val.namespace));
                    switch(Map.get<Text, Types.Reservation>(state.nft_reservation, Map.thash, val.namespace)){
                            case(null){
                                state.nft_reservation_size += 1;
                                Map.set<Text, Types.Reservation>(state.nft_reservation, Map.thash, val.namespace, val);
                                namespace := val.namespace;
                                reservation_type :=  val.reservation_type;
                                exclusive := val.exclusive;
                                nfts_size := val.nfts.size();
                                results.add(#add(val.namespace));
                            };
                            case(?val){
                                return #err(Types.errors(#reservation_item_exists, "group exists in sales canister " # val.namespace, ?msg.caller));
                            };
                        };
                };
                case(#remove(val)){
                    //D.print("manage_reservation" # "\n" # "remove : " #  debug_show(val.namespace));
                    switch(Map.get<Text, Types.Reservation>(state.nft_reservation, Map.thash, val.namespace)){
                                case(null){
                                    return #err(Types.errors(#reservation_item_does_not_exists, "does not exists in sales canister " # val.namespace, ?msg.caller));                            
                                };
                                case(?val){
                                    state.nft_reservation_size -= 1;
                                    Map.delete<Text, Types.Reservation>(state.nft_reservation, Map.thash, val.namespace);
                                    namespace := "removed -> " # val.namespace;
                                    results.add(#add(val.namespace));
                                };
                        };
                };
                case(#addNFTs(val)){
                    //D.print("manage_reservation" # "\n" #"addNFTs : " #  debug_show(val.namespace));

                    let res = Map.get<Text, Types.Reservation>(state.nft_reservation, Map.thash, val.namespace);
                    switch(res){
                        case(null){
                            return #err(Types.errors(#reservation_item_does_not_exists, "does not exists in sales canister " # val.namespace, ?msg.caller));
                        };
                        case(?v){                    
                            
                            let nftsToBe = Buffer.Buffer<Text>(0);
                            for (i in v.nfts.vals()){
                                nftsToBe.add(i);
                            };
                            for(this_item in val.nfts.vals()){
                                var add = true;
                                label search for(thatItem in v.nfts.vals()){
                                    if(this_item == thatItem){
                                        add := false;
                                        break search;
                                    };                            
                                };
                                if(add == true){
                                    nftsToBe.add(this_item);
                                };
                            };
                            let nftsArray =  nftsToBe.toArray();

                            let insert  = {                        
                                namespace = v.namespace;
                                reservation_type =  v.reservation_type;
                                exclusive = v.exclusive;
                                nfts = nftsArray;                         
                            };
                            Map.set<Text, Types.Reservation>(
                                state.nft_reservation, 
                                Map.thash, 
                                val.namespace, 
                                insert
                            );
                            namespace := v.namespace;
                            reservation_type :=  v.reservation_type;
                            exclusive := v.exclusive;
                            nfts_size := nftsArray.size();

                            results.add(#addNFTs(nfts_size));

                            /* D.print("manage_reservation" # "\n" #
                            "addNFTs : " #  debug_show(val.namespace) # "\n\n" #
                            "res  : " #  debug_show(res) # "\n\n" #
                            "val.nfts  : " #  debug_show(val.nfts) # "\n\n" #
                            "res.nfts  : " #  debug_show(v.nfts) # "\n\n"  #
                            "NFTs to be  : " #  debug_show(nftsToBe.toArray()) # "\n\n" #
                            "state.nft_reservation  : " #  debug_show(state.nft_reservation) # "\n\n" 
                            ); */
                        };
                    };
                };
                case(#removeNFTs(val)){
                    //D.print("manage_reservation" # "\n" #"removeNFTs : " #  debug_show(val.namespace));

                    let res = Map.get<Text, Types.Reservation>(state.nft_reservation, Map.thash, val.namespace);
                    switch(res){
                        case(null){
                            return #err(Types.errors(#reservation_item_does_not_exists, "does not exists in sales canister " # val.namespace, ?msg.caller));
                        };
                        case(?v){
                            let nftsToBe = Buffer.Buffer<Text>(0);
                            
                            for(this_item in v.nfts.vals()){
                                var add = true;
                                label search for(thatItem in val.nfts.vals()){
                                    if(this_item == thatItem){
                                        add := false;
                                        break search;
                                    };
                                };
                                if(add == true){
                                    nftsToBe.add(this_item);
                                };
                            };

                            let nftsArray =  nftsToBe.toArray();
                            let insert  = {                        
                                    namespace = v.namespace;
                                    reservation_type =  v.reservation_type;
                                    exclusive = v.exclusive;
                                    nfts = nftsArray;                         
                                };
                                Map.set<Text, Types.Reservation>(
                                    state.nft_reservation, 
                                    Map.thash, 
                                    val.namespace, 
                                    insert
                                );
                                namespace := v.namespace;
                                reservation_type :=  v.reservation_type;
                                exclusive := v.exclusive;
                                nfts_size := nftsArray.size();
                                results.add(#removeNFTs(nfts_size));

                                /* D.print("manage_reservation" # "\n" #
                                "removeNFTs : " #  debug_show(val.namespace) # "\n\n" #
                                "res  : " #  debug_show(res) # "\n\n" #
                                "val.nfts  : " #  debug_show(val.nfts) # "\n\n" #
                                "res.nfts  : " #  debug_show(v.nfts) # "\n\n"  #
                                "NFTs to be  : " #  debug_show(nftsToBe.toArray()) # "\n\n" #
                                "state.nft_reservation  : " #  debug_show(state.nft_reservation) # "\n\n" 
                                ); */
                        };
                    }; 
                };
                case(#update_type(val)){
                    //D.print("manage_reservation" # "\n" #"update_type : " #  debug_show(val.namespace));
                    let res = Map.get<Text, Types.Reservation>(state.nft_reservation, Map.thash, val.namespace);

                    switch(res){
                        case(null){
                            return #err(Types.errors(#reservation_item_does_not_exists, "does not exists in sales canister " # val.namespace, ?msg.caller));
                        };
                        case(?v){
                            let insert  = {                        
                                    namespace = v.namespace;
                                    reservation_type =  val.reservation_type;
                                    exclusive = v.exclusive;
                                    nfts = v.nfts;                         
                                };
                                Map.set<Text, Types.Reservation>(
                                    state.nft_reservation, 
                                    Map.thash, 
                                    val.namespace, 
                                    insert
                                );
                                namespace := v.namespace;
                                reservation_type :=  val.reservation_type;
                                exclusive := v.exclusive;
                                nfts_size := v.nfts.size();
                                
                                results.add(#update_type(namespace));

                                /* D.print("manage_reservation" # "\n" #
                                "update_type : " #  debug_show(val.namespace) # "\n\n" #
                                "res  : " #  debug_show(res) # "\n\n" #
                                "state.nft_reservation  : " #  debug_show(state.nft_reservation) # "\n\n" 
                                ); */
                        };
                    };

                };

            };
       };

       return #ok({
           total_size = results.size();
           items = results.toArray();
       }); 
    //    return #err(Types.errors(#nyi, "manage_reservation nyi", ?msg.caller));
    };

    private func get_groups_for_user(user: Principal, groups : Types.Groups) : [Types.Group]{
        //D.print("in get groups" # debug_show(groups));
        var results = RBU.RBTree<Text, Types.Group>(Text.compare);

        for(thisGroup in Map.entries<Text, Types.Group>(groups)){
            //D.print("looking for " # debug_show(user, thisGroup.1.members) # " in " # thisGroup.1.namespace);
            if(thisGroup.1.namespace == "" and Map.size<Principal,Int>(thisGroup.1.members) == 0){
                results.put(thisGroup.1.namespace, thisGroup.1);
            } else {
                switch(Map.get(thisGroup.1.members, Map.phash, user)){
                    case(?val){

                        results.put(thisGroup.1.namespace, thisGroup.1);
                    };
                    case(null){};
                }
            };
        };

        //D.print("d " # debug_show(Iter.size(results.entries())));

        return Iter.toArray<Types.Group>(Iter.map<(Text,Types.Group),Types.Group>(results.entries(), func(item){item.1}));
    };

    private func intersect_user_groups_reservations(user : Principal, groups: Types.Groups, reservations: Types.Reservations) : { 
        groups: [Types.Group]; 
        group_reservations: [Types.Reservation];
        personal_reservations: [Types.Reservation]
        }{
        //D.print("in intersect");
        let user_groups = get_groups_for_user(user, groups);
        //D.print("have user groups" # debug_show(user_groups));
        

        //todo: look through reservations
        let personal_reservations = Buffer.Buffer<Types.Reservation>(1);
        let group_reservations = Buffer.Buffer<Types.Reservation>(1);

        //D.print("testing reservations" # debug_show(reservations));
        for(thisRes in Map.vals<Text, Types.Reservation>(reservations)){
            switch(thisRes.reservation_type){
                case(#Principal(a_user)){
                    //D.print("testing principal");
                    if(a_user == user){
                        personal_reservations.add(thisRes);
                    }
                };
                case(#Groups(a_group)){
                    //D.print("testing Group");
                    for(thisGroup in a_group.vals()){
                        let search = Array.filter<Types.Group>(user_groups, func(a){a.namespace == thisGroup});
                        if(search.size() > 0){
                            group_reservations.add(thisRes);
                        }
                    };
                }
            };
        };

        return{
            groups = user_groups;
            personal_reservations = personal_reservations.toArray();
            group_reservations = group_reservations.toArray();
        };
    };


    private func calc_user_purchase_graph(user : Principal, groups: Types.Groups, reservations: Types.Reservations, inventory: Types.NFTInventory, purchases : Types.Purchases) : {
        prices: [(?Types.TokenSpec, ?Nat, [(Nat, ?Nat)])]; //token, max_allowed, (amount, number)
        personal_reservations: ([Types.Reservation], Nat, Nat);
        group_reservations: ([Types.Reservation], Nat, Nat);
        purchases: [(Text, NFTTypes.TransactionRecord)];
    }{
        //D.print("creating graph for " #debug_show(user, groups, reservations, inventory, purchases));

        //D.print("reservation deatil " #debug_show(reservations));
        let user_info = intersect_user_groups_reservations(user, groups, reservations);
        //D.print("have info for " #debug_show(user_info));

        //this collection keeps track of the max allwed for the user and the breakup of prices if they get a price break
        // ie Max allowed: 4; pricies [(20OGY, 2 items),(30OGY, 2 items)]
        type tracker = {
            var max_allowed : ?Nat;
            var prices: Map.Map<Nat, ?Nat>; //price amount , number, can be null
        };

        var token_map = Map.new<?Types.TokenSpec, tracker>();


        //D.print("at token map");

        //lets you do a comparison with null tokens because null token means free
        let hash_null_token : ((?Types.TokenSpec) -> Nat, (?Types.TokenSpec, ?Types.TokenSpec) -> Bool) = (
            func(a : ?Types.TokenSpec) : Nat {
                switch(a){
                    case(null){
                        return 0;
                    };
                    case(?val){
                        return NFTTypes.token_hash(val);
                    };
                }
            }
            , 
            func(a : ?Types.TokenSpec,b: ?Types.TokenSpec) : Bool {
                switch(a,b){
                    case(null,null){
                        return true;
                    };
                    
                    case(?val, ?val2){
                        return  NFTTypes.token_compare(val,val2) == #equal;
                    };
                    case(_){
                        return false;
                    }
                };

            });

        let compare_null_tokens = func(a : ?Types.TokenSpec,b: ?Types.TokenSpec) : Order.Order {
                switch(a,b){
                    case(null,null){
                        return #equal;
                    };
                    case(null, ?val){
                        return #less;
                    };
                    case(?val, null){
                        return #greater;
                    };
                    case(?val, ?val2){
                        return NFTTypes.token_compare(val,val2);
                    };
                };

            };

        //adds the pricing to the colletion
        let addPricing = func(aGroup : Types.Group){
            //D.print("adding Pricing" # debug_show(aGroup));

            for(thisPricing in aGroup.pricing.vals()){
                //D.print("looking at pricing");
                let thisPricingToken : ?Types.TokenSpec = switch(thisPricing){
                    case(#free){null};
                    case(#cost_per(data)){?data.token};
                };
                switch(Map.get<?Types.TokenSpec, tracker>(token_map, hash_null_token, thisPricingToken)){
                    case(null){
                        //we don't have this pricing yet
                        //D.print("not in map");
                        let this_tracker = {
                            var max_allowed : ?Nat = aGroup.allowed_amount;
                            var prices = Map.new<Nat, ?Nat>();
                        };
                        switch(thisPricing){
                            case(#free){
                                Map.set(this_tracker.prices, Map.nhash, 0, aGroup.allowed_amount);
                            };
                            case(#cost_per(detail)){
                                Map.set(this_tracker.prices, Map.nhash, detail.amount, aGroup.allowed_amount);
                            }
                        };
                        Map.set<?Types.TokenSpec, tracker>(token_map, hash_null_token, thisPricingToken, this_tracker);
                    };
                    case(?existing_map){
                        //D.print("exists");
                        let existing_allowed_amount = existing_map.max_allowed;
                        switch(existing_allowed_amount, aGroup.allowed_amount){
                            case(null, null){
                                existing_map.max_allowed := null;
                                 switch(thisPricing){
                                    case(#free){
                                        Map.set<Nat, ?Nat>(existing_map.prices, Map.nhash, 0, null);
                                    };
                                    case(#cost_per(detail)){
                                        Map.set<Nat, ?Nat>(existing_map.prices, Map.nhash, detail.amount, null);
                                    };
                                 };
                            };
                            case(?new, null){
                                existing_map.max_allowed := null;
                                 switch(thisPricing){
                                    case(#free){
                                        Map.set<Nat, ?Nat>(existing_map.prices, Map.nhash, 0, null);
                                    };
                                    case(#cost_per(detail)){
                                        Map.set<Nat, ?Nat>(existing_map.prices, Map.nhash, detail.amount, null);
                                    };
                                 };
                            };
                            case(null, ?old){
                                existing_map.max_allowed := null;
                                 switch(thisPricing){
                                    case(#free){
                                        Map.set<Nat, ?Nat>(existing_map.prices, Map.nhash, 0, null);
                                    };
                                    case(#cost_per(detail)){
                                        Map.set<Nat, ?Nat>(existing_map.prices, Map.nhash, detail.amount, null);
                                    };
                                 };
                            };
                            case(?new, ?old){
                                let thisPricingAmount = switch(thisPricing){case(#free){0};case(#cost_per(detail)){detail.amount}};
                                existing_map.max_allowed := if(aGroup.additive == true){
                                    switch(Map.get<Nat, ?Nat>(existing_map.prices, Map.nhash, thisPricingAmount)){
                                        case(null){
                                            Map.set<Nat, ?Nat>(existing_map.prices, Map.nhash, thisPricingAmount, aGroup.allowed_amount);
                                        };
                                        case(?val){
                                            //price already exists and additive
                                            Map.set<Nat, ?Nat>(existing_map.prices, Map.nhash, thisPricingAmount, ?(old + new));
                                        }
                                    };
                                    ?(new + old);
                                } else {
                                    if(new > old){
                                        Map.set<Nat, ?Nat>(existing_map.prices, Map.nhash, thisPricingAmount, ?new);
                                        ?new;
                                    } else {
                                        Map.set<Nat, ?Nat>(existing_map.prices, Map.nhash, thisPricingAmount, ?old);
                                        ?old;
                                    };
                                };
                                 switch(thisPricing){
                                    case(#free){
                                        Map.set<Nat, ?Nat>(existing_map.prices, Map.nhash, 0, 
                                        if(aGroup.additive == true){
                                            ?(new + old);
                                        } else {
                                            if(new > old){
                                                ?new;
                                            } else {
                                                ?old;
                                            };
                                        });
                                    };
                                    case(#cost_per(detail)){
                                        Map.set<Nat, ?Nat>(existing_map.prices, Map.nhash, detail.amount, if(aGroup.additive == true){
                                            ?(new + old);
                                        } else {
                                            if(new > old){
                                                ?new;
                                            } else {
                                                ?old;
                                            };
                                        });
                                    };
                                 };
                                
                            };
                        };
                        
                        
                    };
                };
            };
        };

        //D.print("chekcing groups" # debug_show(Iter.toArray(user_info.groups.vals())));

        //todo...may need to sort these so that all the non-additive ones are first

        for(thisGroup in user_info.groups.vals()){
            if(thisGroup.namespace == ""){
                //this is the default group and eveyone gets to participate in it unless there are members
                //D.print("found default group");
                if(Map.size(thisGroup.members) == 0){
                    
                        addPricing(thisGroup);
                } else {
                    
                    if(Option.isSome(Map.get<Principal, Int>(thisGroup.members, Map.phash, user))){
                        //we are a part of this group
                        addPricing(thisGroup);
                    };
                  
                }
            } else {
                //D.print("found a group");
                addPricing(thisGroup);
            }
        };


        //D.print("returning pricing " # debug_show(token_map));


        return {
            prices : [(?Types.TokenSpec, ?Nat, [(Nat, ?Nat)])] = Iter.toArray<(?Types.TokenSpec, ?Nat, [(Nat, ?Nat)])>(
                        Iter.map<(?Types.TokenSpec,tracker), (?Types.TokenSpec, ?Nat, [(Nat, ?Nat)])>(
                            Map.entries<?Types.TokenSpec, tracker>(token_map), 
                            func(item){
                                (item.0, 
                                    item.1.max_allowed, 
                                    Iter.toArray<(Nat,?Nat)>(Map.entries<Nat,?Nat>(item.1.prices)))}));
            personal_reservations = (user_info.personal_reservations, 0, 0);
            group_reservations  = (user_info.group_reservations,0, 0);
            purchases : [(Text, NFTTypes.TransactionRecord)] = switch(Map.get<Principal, Map.Map<Text,NFTTypes.TransactionRecord>>(state.user_purchases, Map.phash, user)){
              case(null){[]};
              case(?val){Iter.toArray(Map.entries(val))};
            };
        }
    };

    // deposit an escrow
    // allocate a set of nfts for payment
    public shared(msg) func allocate_sale_nft_origyn(request: Types.AllocationRequest) : async Result.Result<Types.AllocationResponse, Types.OrigynError>{
        //check to see if the max allocation is hit
        //see of the principal had an old allocation, if so, make it available
        //search for a random qualifying item, make available = false


        //make sure that the caller is the principal
        if(msg.caller != request.principal and msg.caller != state.owner and Option.make(msg.caller) != state.manager){
            return #err(Types.errors(#unauthorized_access, "allocate_sale_nft_origyn - must be the caller ", ?msg.caller));
        };

        D.print("in allocate");
        if(request.number_to_allocate  == 0){
            return #err(Types.errors(#improper_allocation, "allocate_sale_nft_origyn - cannot allocate 0 items ", ?msg.caller));
        };

        //clear out expired allocations
        D.print("cleaning");
        let clean_result = expire_allocations();
        if(clean_result == false){
            //todo: the queue has gotten too full and we should really clear it out
            //do a one shot call to self and return an error
        };

        //there has to e some kind of max allocation here
        if(request.number_to_allocate  > 50){ //temporary...only allow purchasing 50 at a time
            return #err(Types.errors(#improper_allocation, "allocate_sale_nft_origyn - cannot allocate more than items...geez, you greedy gus ", ?msg.caller));
        };

        //see how many the user can buy and at what price

        let {user_info = user_info; allocation_size =  allocation_size} = get_possible_purchases(request.principal, request.token, request.number_to_allocate);

        
        //todo: check if they arleady have an allocation...need to put those items back
        let current_allocation = switch(Map.get<Principal, Types.Allocation>(state.user_allocations, Map.phash, request.principal)){
            case(null){
                //reserve the nfts
                let new_allocation = {
                    principal = request.principal;
                    var token  = request.token;
                    var nfts : [Text]=  [];
                    var expiration = get_time() + state.allocation_expiration;
                };
                Map.set<Principal, Types.Allocation>(state.user_allocations, Map.phash, request.principal, new_allocation);
                new_allocation;
            };
            case(?val){
                //release the old nfts
                for(this_item in val.nfts.vals()){
                    switch(Map.get<Text,Types.NFTInventoryItem>(state.nft_inventory, Map.thash, this_item)){
                        case(null){
                            //should be unreachable
                        };
                        case(?nft){
                            if(nft.available == false){
                                nft.available := true;
                                nft.allocation := null;
                            };
                        };
                    };

                };
                //set the token to the new requested token
                val.token := request.token; //is this the best place to do this?
                val;
            };
        };

        //D.print("current_allocation" # debug_show(current_allocation));

        //Adjust allocation size by existing purchases
        let purchases = Map.get<Principal, Map.Map<Text,NFTTypes.TransactionRecord>>(state.user_purchases, Map.phash, request.principal);


        let reserved = RBU.RBTree<Text,?Nat>(Text.compare); // token_id, group_id, ?price
        //let group_count = RBU.RBTree<Text, Nat>(Text.compare);
        //cycle through resevations and see if the user has some of these reseved
        //we need to find the cheapest reservations first

        //todo: in the future we'll want to find the full graph of possibilites and then 
        //do some randomization...for now keep it simpler
        //find some available and allocate them
        label searchPersonal for(thisReservation in user_info.personal_reservations.0.vals()){
            if(Iter.size(reserved.entries()) == allocation_size){
                break searchPersonal;
            };
            for(this_nft in thisReservation.nfts.vals()){
                if(Iter.size(reserved.entries()) == allocation_size){
                    break searchPersonal;
                };
                //check to see if it is available
                switch(Map.get<Text,Types.NFTInventoryItem>(state.nft_inventory, Map.thash, this_nft)){
                    case(null){
                        //should be unreachable
                    };
                    case(?nft){
                        if(nft.available == true){
                            nft.available := false;
                            nft.allocation := ?request.principal;
                            reserved.put(this_nft, null);
                            if(Iter.size(reserved.entries())== allocation_size){
                                break searchPersonal;
                            };
                        };
                    };
                };
            };
        };

        //D.print("personal done" # debug_show(Iter.toArray(reserved.entries())));


        label searchGroup for(thisReservation in user_info.group_reservations.0.vals()){
            if(Iter.size(reserved.entries()) == allocation_size){
                break searchGroup;
            };
            for(this_nft in thisReservation.nfts.vals()){
                if(Iter.size(reserved.entries()) == allocation_size){
                    break searchGroup;
                };
                //check to see if it is available
                switch(Map.get<Text,Types.NFTInventoryItem>(state.nft_inventory, Map.thash, this_nft)){
                    case(null){
                        //should be unreachable
                    };
                    case(?nft){
                        if(nft.available == true){
                            nft.available := false;
                            nft.allocation := ?request.principal;
                            //todo: check the group for pricing
                            reserved.put(this_nft, null);
                
                            if(Iter.size(reserved.entries()) == allocation_size){
                                break searchGroup;
                            };
                        };
                    };
                };
            };
        };

        //D.print("group done" # debug_show(Iter.toArray(reserved.entries())));


        //todo: we should check to see if this user actually has that balance(maybe need to request subaccount here?)
        current_allocation.nfts := Iter.toArray<Text>(Iter.map<(Text, ?Nat), Text>(reserved.entries(), func(item){item.0}));
        state.allocation_queue := Deque.pushBack<(Principal, Int)>(state.allocation_queue, (current_allocation.principal, current_allocation.expiration));

        if(current_allocation.nfts.size() == 0){
            return #err(Types.errors(#inventory_empty, "allocate_sale_nft_origyn - inventory is empty ", ?msg.caller));
        };

        return #ok({
            allocation_size = current_allocation.nfts.size();
            token = request.token;
            principal = request.principal;
            expiration = current_allocation.expiration;
        });
        // return #err(Types.errors(#nyi, "allocate_nfts nyi", ?msg.caller));
    };


    
    // takeas an escrow receipt and attempts the instant transfer of the allocation
    // creator will need to set a redeem_at_a_time variable that dictates the number of xcanister calls that can       
    // happen at once. Should use a batch market transfer function
   
    public shared(msg) func redeem_allocation_sale_nft_origyn(request: Types.RedeemAllocationRequest) : async Result.Result<Types.RedeemAllocationResponse, Types.OrigynError>{

        D.print("in redeem=");
         // ToDo:
         // Need to validate the allocation has not expired
         // redeem_allocation is the actual sale, once that function has validated the allocation has not expired it should call market_transfer_nft_origyn on the nft canister with #instant and provide the escrow receipt.
        
        let found_allocation = switch(Map.get<Principal, Types.Allocation>(state.user_allocations, Map.phash, msg.caller)){
            case(null){
                return #err(Types.errors(#allocation_does_not_exist, "redeem_allocation_sale_nft_origyn - cant find allocation for " # debug_show(msg.caller), ?msg.caller));
            };
            case(?found){
                if(found.expiration < get_time()){
                    return #err(Types.errors(#allocation_does_not_exist, "redeem_allocation_sale_nft_origyn - expired allocation for " # debug_show(msg.caller), ?msg.caller));
                };
                if(found.nfts.size() == 0){
                    return #err(Types.errors(#allocation_does_not_exist, "redeem_allocation_sale_nft_origyn - found allocation but it was empty " # debug_show(msg.caller), ?msg.caller));
                
                };
                found;
            };
        };

        D.print("found_allocation" # debug_show(found_allocation));

        //validate the escrow
        let nft_gateway : NFTTypes.Service = switch(state.nft_gateway){
            case(null){return #err(Types.errors(#bad_config, "redeem_allocation_sale_nft_origyn - bad gateway config null", ?msg.caller));};
            case(?val){actor(Principal.toText(val));}
        };
        D.print("gateway os " # debug_show(state.nft_gateway));

        //get the allocations and build the transfers by price
        var transfers = Buffer.Buffer<NFTTypes.MarketTransferRequest>(found_allocation.nfts.size());

        D.print("getting user info");
        let user_info = calc_user_purchase_graph(msg.caller, state.nft_group, state.nft_reservation, state.nft_inventory, state.user_purchases);
        D.print("getting user info" # debug_show(user_info));

        //todo: advance the allocation past the number of purchases so we don't over allocate the second time through.
        let remove_specs = Array.filter<(?Types.TokenSpec, ?Nat, [(Nat, ?Nat)])>(user_info.prices, func(item){
            switch(item.0){
                case(null){true};//free
                case(?val){NFTTypes.token_eq(val, request.escrow_receipt.token)};
            };
        });

        let flat_price = do{
            let result = Buffer.Buffer<(Nat,?Nat)>(1);
            for(this_item in remove_specs.vals()){   
                for(thisDetail in this_item.2.vals()){
                    result.add(thisDetail);
                };
            };

            Array.sort<(Nat,?Nat)>(result.toArray(), func(a : (Nat, ?Nat),b:(Nat, ?Nat)) : Order.Order{ return Nat.compare(a.0,b.0)});
        };

        D.print("have flat price" # debug_show(flat_price));

        //prices: [(?Types.TokenSpec, ?Nat, [(Nat, ?Nat)])];

        var balance_remaining = request.escrow_receipt.amount;
        D.print("balance_remaining" # debug_show(balance_remaining));
        let bought_list = Buffer.Buffer<(Text,Nat)>(1);
        var available_nfts = List.fromArray<Text>(found_allocation.nfts);
        for(this_item in flat_price.vals()){
            D.print("testing " # debug_show(this_item));
            let this_price = this_item.0;
            D.print("have price" # debug_show(this_price));
            let this_number = switch(this_item.1){
                case(null){ //this means the user has reached a price where they can allocate up to as many as they want
                    D.print("unlimited allocation at " # debug_show((this_price, bought_list.size(), available_nfts)));
                    var tracker = 0;
                    label builder while(balance_remaining >= this_price and bought_list.size() < found_allocation.nfts.size()){
                        let anNFT = List.pop<Text>(available_nfts);
                        available_nfts := anNFT.1;
                        switch(anNFT.0){
                            case(null){break builder};
                            case(?anNFT){
                                bought_list.add(anNFT, this_price);
                                balance_remaining -= this_price;
                            };
                        };
                        
                        if(tracker > 1000){break builder};
                        tracker += 1;
                    };
                };
                case(?val){
                    //there are a set number at this price...try to fill until you get to the end
                    //D.print("have a set number " # debug_show(val));
                    label builder for(this_item in Iter.range(1, val)){
                        //D.print("running iter" # debug_show(this_item, balance_remaining, this_price, bought_list.size(), found_allocation));
                        if(balance_remaining < this_price or bought_list.size() >= found_allocation.nfts.size()){
                            D.print("breaking builder 1");
                            break builder;
                        };

                        //D.print("poping builder");

                        let anNFT = List.pop<Text>(available_nfts);
                        available_nfts := anNFT.1;
                        switch(anNFT.0){
                            case(null){
                                D.print("breaking builde 2r");
                                break builder};
                            case(?anNFT){
                                bought_list.add(anNFT, this_price);
                                balance_remaining -= this_price;
                                D.print("balance_remaining loop" # debug_show(balance_remaining));
                            };
                        };
                        
                        
                    };
                };
            }
        };

        if(bought_list.size() == 0){
            D.print("nothing int he list");
            return #err(Types.errors(#improper_escrow, "redeem_allocation_sale_nft_origyn - improper_escrow - not large enough for one purchase " # debug_show(request.escrow_receipt), ?msg.caller));
        };

        for(this_item in bought_list.vals()){
            transfers.add({
                token_id = this_item.0;
                sales_config = {
                    escrow_receipt = ?{
                        amount = this_item.1;
                        seller = request.escrow_receipt.seller;
                        buyer = request.escrow_receipt.buyer;
                        token_id = request.escrow_receipt.token_id;
                        token = request.escrow_receipt.token;
                    };
                    broker_id = null;
                    pricing = #instant;
                };
            })
        };

        //try the purchase
        D.print("about to send transfer" # debug_show(transfers.toArray()));
        let transfer_result = await nft_gateway.market_transfer_batch_nft_origyn(transfers.toArray());
        D.print("result was" # debug_show(transfer_result));

        //process the results

        let results = Buffer.Buffer<{token_id: Text; transaction: Result.Result<NFTTypes.TransactionRecord, Types.OrigynError>}>(1);
        var tracker = 0;
        D.print("the inventory " # debug_show(Iter.toArray(Map.entries(state.nft_inventory))));
        for(thisResponse in transfer_result.vals()){
            switch(thisResponse){
                case(#ok(trx)){
                    let token_id = trx.token_id;
                    D.print("the inventory " # debug_show(Iter.toArray(Map.entries(state.nft_inventory))));
                    let inventory = switch(Map.get<Text,Types.NFTInventoryItem>(state.nft_inventory, Map.thash, token_id)){
                        case(null){
                            results.add({
                                token_id = token_id;
                                transaction = #err(Types.errors(#bad_canister_trx, "redeem_allocation_sale_nft_origyn - a transaction was returned for an item that is not in inventory " # debug_show(trx), ?msg.caller));
                            });
                        };
                        case(?item){
                            found_allocation.nfts := Array.filter<Text>(found_allocation.nfts, func(anitem: Text){ anitem != token_id});
                            item.sale_block := ?trx.index;
                            item.allocation := null;
                            results.add({
                                token_id = token_id;
                                transaction = #ok(trx);
                            });
                        };
                    };
                };
                case(#err(err)){
                    
                    results.add({
                        token_id = bought_list.get(tracker).0;
                        transaction = #err(Types.errors(#bad_canister_trx, "redeem_allocation_sale_nft_origyn - tranasaction returned an error  " # debug_show(bought_list.get(tracker).0, err), ?msg.caller));
                    });
                        
                }
            };
            tracker += 1;
        };

        return #ok({
            nfts = results.toArray();
        });
        
        // return #err(Types.errors(#nyi, "redeem_allocation nyi", ?msg.caller));
    };

    private func get_possible_purchases(caller : Principal, token : ?NFTTypes.TokenSpec, number_to_allocate: Nat) : {user_info:
        {
            prices: [(?Types.TokenSpec, ?Nat, [(Nat, ?Nat)])]; //token, max_allowed, (amount, number)
            personal_reservations: ([Types.Reservation], Nat, Nat);
            group_reservations: ([Types.Reservation], Nat, Nat);
            purchases: [(Text, NFTTypes.TransactionRecord)];
        }; allocation_size: Nat}{

        //check to see if the user has any groups and reservations.
        //D.print("getting user info");
        let user_info = calc_user_purchase_graph(caller, state.nft_group, state.nft_reservation, state.nft_inventory, state.user_purchases);
        //D.print("getting user info" # debug_show(user_info));

        
        
        
        var highest_found : ?Nat = ?0;
        label search for(thisPricing in user_info.prices.vals()){
            switch(thisPricing.0, token){
                case(null, null){
                    //free item can pass
                };
                case(?thisPricing, null){
                    //user has requested only free items, skip
                    continue search;
                
                };
                case(?thisPricing, ?requestedPricing){
                    if(NFTTypes.token_eq(thisPricing, requestedPricing) == false){
                        continue search;
                    };
                };
                case(null, ?requestedPricing){
                    //free item can pass
                };
            };
            
            switch(thisPricing.1, highest_found){
                case(null, ?current){
                    highest_found := null;
                    break search;
                };
                case(?val, ?current){
                    if(val > current){
                        highest_found := ?val
                    };
                };
                case(_,_){
                    //should be unreachable
                };
            };
        };
        //D.print("highest found" # debug_show(highest_found));

        let allocation_size = switch(highest_found){
            case(null){number_to_allocate};
            case(?val){
                if(val > number_to_allocate){
                    number_to_allocate;
                } else {
                    val;
                }};
        };

        return {user_info = user_info; allocation_size = allocation_size};
    };

    //deposit
    //now if the mint is delayed we'll need to talk about what happens then.
    public shared(msg) func register_escrow_sale_nft_origyn(request: Types.RegisterEscrowRequest) : async Result.Result<Types.RegisterEscrowResponse, Types.OrigynError>{

        D.print("In register escrow " # debug_show(request));
        //check the max requested has a positive amount
        if(request.max_desired == 0){
            return #err(Types.errors(#improper_escrow, "register_escrow_sale_nft_origyn - max_requested must be greater than 0 " # debug_show(request), ?msg.caller));
        };

        
        switch(request.escrow_receipt){
            case(null){};
            case(?val){
                //validate the escrow
                if(val.amount == 0){
                    return #err(Types.errors(#improper_escrow, "register_escrow_sale_nft_origyn - amount must be greater than 0 " # debug_show(request), ?msg.caller));
                };

                if(NFTTypes.account_eq(val.buyer, #principal(msg.caller))){//todo: allow manager
                    return #err(Types.errors(#improper_escrow, "register_escrow_sale_nft_origyn - buyer must be sender " # debug_show(request), ?msg.caller));
                };

                //validate the token used in in the pricing
            };
        };

        D.print("script reciept validated " # debug_show(true));


        let {user_info = user_info; allocation_size = allocation_size} = get_possible_purchases(msg.caller, switch(request.escrow_receipt){case(null){null;};case(?val){?val.token;}}, request.max_desired);
       
        D.print("have usr info " # debug_show(user_info, allocation_size));


        if(allocation_size ==0){
            return #err(Types.errors(#improper_allocation, "register_escrow_sale_nft_origyn - no valid allocation found " # debug_show(request), ?msg.caller));
        };

        let current_reg = switch(request.escrow_receipt){
            case(null){
                //only put in if the user qualifed for some free items
                D.print("handling fee items " # debug_show(true));
                //add the registrations
                switch(Map.get<Principal, Types.Registration>(state.user_registrations, Map.phash, request.principal)){
                    case(null){
                        let new_reg = {
                            principal = request.principal;
                            var max_desired= request.max_desired;
                            var escrow_receipt = request.escrow_receipt;
                            var allocation_size = allocation_size;
                            var allocation = Map.new<Text, Types.RegistrationClaim>();
                        };
                        Map.set<Principal, Types.Registration>(state.user_registrations, Map.phash, request.principal, new_reg );
                        new_reg;
                    };
                    case(?val){
                        //this already exists
                        val.max_desired := request.max_desired;
                        val.escrow_receipt := request.escrow_receipt;
                        val.allocation_size := allocation_size;
                        val;
                    }
                };
            };
            case(?val){
                //check that the escrow is valid

                D.print("found items " # debug_show(val));

                let nft_canister : NFTTypes.Service = switch(state.nft_gateway){
                    case(null){return #err(Types.errors(#bad_config, "register_escrow_sale_nft_origyn - no gateway ", ?msg.caller));};
                    case(?val){actor(Principal.toText(val))};
                };

                //are there enough free items to cover the amount allocated?

                let balance = switch(await nft_canister.balance_of_nft_origyn(#principal(msg.caller))){
                    case(#err(err)){return #err(Types.errors(#improper_escrow, "register_escrow_sale_nft_origyn - error checking balance " # debug_show(request, err), ?msg.caller))};
                    case(#ok(val)){val};
                };

                D.print("have balance " # debug_show(balance));

                var found : Bool = false;
                label search for(this_item in balance.escrow.vals()){
                    if(
                        val.seller == this_item.seller and
                        val.buyer == this_item.buyer and
                    
                        val.token_id == this_item.token_id and 
                        null == this_item.sale_id and
                        this_item.lock_to_date == state.required_lock_date and
                        val.amount  <= this_item.amount and
                        NFTTypes.token_eq(val.token, this_item.token)
                    ){
                        found :=true;
                        break search;
                    };
                };

                if(found == false){
                    return #err(Types.errors(#improper_escrow, "register_escrow_sale_nft_origyn - cannot find escrow " # debug_show(request), ?msg.caller));
                };

                //add the registrations
                switch(Map.get<Principal, Types.Registration>(state.user_registrations, Map.phash, request.principal)){
                    case(null){
                        let new_reg = {
                            principal = request.principal;
                            var max_desired= request.max_desired;
                            var escrow_receipt = request.escrow_receipt;
                            var allocation_size = allocation_size;
                            var allocation = Map.new<Text, Types.RegistrationClaim>();
                        };
                        Map.set<Principal, Types.Registration>(state.user_registrations, Map.phash, request.principal, new_reg );
                        new_reg;
                    };
                    case(?val){
                        //this already exists
                        val.max_desired := request.max_desired;
                        val.escrow_receipt := request.escrow_receipt;
                        val.allocation_size := allocation_size;
                        val;
                    }
                };
                
            };
        };

        

        D.print("about to iter");
        
        let iter1 = Map.entries<Text, Types.RegistrationClaim>(current_reg.allocation);
        let iter2 = Iter.map<(Text, Types.RegistrationClaim), Types.RegisterEscrowAllocationDetail>(iter1, Types.stabalize_xfer_RegisterAllocation);
        return (#ok({
            
            allocation = Iter.toArray<Types.RegisterEscrowAllocationDetail>(iter2);
            max_desired = current_reg.max_desired;
            escrow_receipt = request.escrow_receipt;
            allocation_size = current_reg.allocation_size;
            principal = current_reg.principal;
        }));
     
        // return #err(Types.errors(#nyi, "register_escrow nyi", ?msg.caller));
    };

    public shared(msg) func execute_claim_sale_nft_origyn(token_id : Text) : async Result.Result<NFTTypes.TransactionRecord, Types.OrigynError>{

        return #err(Types.errors(#nyi, "not implemented", ?msg.caller));
    };

    // Helper functions 

    public query(msg) func get_total_inventory_tree() : async Result.Result<[Types.NFTInventoryItemDetail], Types.OrigynError>{
        let iter1 = Map.entries<Text, Types.NFTInventoryItem>(state.nft_inventory);
        let iter2 = Iter.map<(Text, Types.NFTInventoryItem), Types.NFTInventoryItemDetail>(iter1, Types.stabalize_xfer_NFTInventoryItem);
        return #ok(Iter.toArray(iter2));
    };

    // Add to inventory
    public shared(msg) func add_inventory_item(request: Types.NFTInventoryItemRequest) : async Result.Result<Text, Types.OrigynError>{


          if(msg.caller !=  state.owner){
                  return #err(Types.errors(#unauthorized_access, "add_inventory_item only owner can manage sale canister", ?msg.caller))
              };



          Map.set<Text, Types.NFTInventoryItem>(state.nft_inventory, Map.thash, request.token_id, {
              canister = request.canister;
              token_id = request.token_id;
              var available = true;
              var sale_block = null;
              var allocation = null;
              var reservations = Map.new<Text, Int>(); //<type, timestamp>
          });
        //   //D.print("nft_inventory.put : " # "\n" #
        //   "result :" # debug_show(result)
        //   );      
          return #ok("success");
    };
    // Get inventory
    public query(msg) func get_inventory_item_sale_nft_origyn(key: Text) : async Result.Result<Types.NFTInventoryItemDetail, Types.OrigynError> {

        // ToDo: Need to find the right type to return #ok(item)
        let item = Map.get<Text, Types.NFTInventoryItem>(state.nft_inventory, Map.thash, key);
        switch(item){
            case(?val){
                return #ok(Types.stabalize_xfer_NFTInventoryItem((val.token_id, val)));
            };
            case(null){
                return #err(Types.errors(#inventory_item_does_not_exists, "get_inventory_item_sale_nft_origyn - cant find token_id in inventory", ?msg.caller));
            };
        };
        
    };

    // Get inventory size
    public query func get_inventory_size_sale_nft_origyn() : async Result.Result<Nat, Types.OrigynError> {
       
       let s = Map.size(state.nft_inventory);

        return #ok(s);
    };

    //get inventory
    public query func get_inventory_sale_nft_origyn(start: ?Nat, size: ?Nat) : async Result.Result<Types.GetInventoryResponse, Types.OrigynError>{

        var size_requested = switch(size){case(null){Map.size(state.nft_inventory)}; case(?val){val}};
        if(size_requested > 10000){
            size_requested := 10000
        };
        let results = Buffer.Buffer<Types.NFTInventoryItemDetail>(size_requested);

        var this_start = switch(start){
            case(null){0};
            case(?val){val};
        };

        var tracker : Nat = 0;
        label search for(this_item in Map.vals(state.nft_inventory)){

            if(tracker >= this_start){
                results.add(Types.stabalize_xfer_NFTInventoryItem((this_item.token_id, this_item)));
            };
            tracker += 1;
            if(results.size() >= size_requested){break search};
        };

        return #ok({
            total_size = Map.size(state.nft_inventory);
            items = results.toArray();
            start = this_start;
        });
    };

    // Groups

    // public shared(msg) func add_group_item(request: Types.AddGroupRequest) : async Result.Result<Text, Types.OrigynError>{

       
    //     nft_group := Map.set<Text, Types.Group>(nft_group ,Text.compare, request.key, request.item);
    //     //   //D.print("nft_inventory.put : " # "\n" #
    //     //   "result :" # debug_show(result)
    //     //   );      
    //       return #ok("success");
    // };
    
    // // Get group size
    public query func get_group_size() : async Result.Result<Nat, Types.OrigynError> {
       
       let s = state.nft_group_size;

       return #ok(s);
    };


    // Reservations
    public query(msg) func get_total_reservations_tree() : async Result.Result<[(Text, Types.Reservation)], Types.OrigynError>{
        
        return #ok(Iter.toArray(Map.entries<Text, Types.Reservation>(state.nft_reservation)));
    };

    public shared (msg) func __advance_time(new_time: Int) : async Int {
        
        if(msg.caller != state.owner){
            throw Error.reject("not owner");
        };
        __test_time := new_time;
        return __test_time;

    };

    public shared (msg) func __set_time_mode(newMode: {#test; #standard;}) : async Bool {
        if(msg.caller != state.owner){
            throw Error.reject("not owner");
        };
        __time_mode := newMode;
        return true;
    };

    private func expire_allocations (): Bool{
        var tracker = 0;
        label clean while(1==1){
            switch(Deque.peekFront<(Principal,Int)>(state.allocation_queue)){
                case(null){};
                case(?val){
                    //D.print("found item at the front" # debug_show(val.1, get_time()));
                    if(val.1 < get_time()){
                        //D.print("cleaning");
                        
                            let result = Deque.popFront<(Principal,Int)>(state.allocation_queue);
                            switch(result){
                                case(null){};//unreachable
                                case(?existing){
                                    state.allocation_queue := existing.1;
                                    switch(Map.get<Principal,Types.Allocation>(state.user_allocations, Map.phash, existing.0.0)){
                                        case(null){}; //already cleared
                                        case(?found){
                                            //release the old nfts
                                            for(this_item in found.nfts.vals()){
                                                switch(Map.get<Text,Types.NFTInventoryItem>(state.nft_inventory, Map.thash, this_item)){
                                                    case(null){
                                                        //should be unreachable
                                                    };
                                                    case(?nft){
                                                        //D.print("returning to pool " # this_item);
                                                        if(nft.available == false){
                                                            nft.available := true;
                                                            nft.allocation := null;
                                                        };
                                                    };
                                                };

                                            };
                                        };
                                    };
                                };
                            };
                    } else {
                        return true;
                    };
                };
            };
            if(tracker > 10000){
                return false; //returing false shoul lead to a one shot call to self
            };
            tracker +=1;
        };
        return true;
    };



    //query allocation

    public query (msg) func get_allocation_sale_nft_origyn(principal: Principal) : async Result.Result<Types.AllocationResponse, Types.OrigynError>{

        //todo:  Secure so only msg.caller or owner/manager can call this

        switch( Map.get<Principal, Types.Allocation>(state.user_allocations, Map.phash, principal)){
            case(?val){
                if(get_time() > val.expiration){
                    //item is expired...pretend it doesn't exist
                    return #err(Types.errors(#allocation_does_not_exist, "get_allocation_sale_nft_origyn - cant find allocation expired", ?msg.caller));
                };
                if(val.nfts.size() == 0){
                    return #err(Types.errors(#allocation_does_not_exist, "get_allocation_sale_nft_origyn - zero items allocated", ?msg.caller));
                };
                return (#ok({
                    allocation_size = val.nfts.size();
                    token = val.token;
                    principal = val.principal;
                    expiration = val.expiration;
                }))
            };
            case(null){
                return #err(Types.errors(#allocation_does_not_exist, "get_allocation_sale_nft_origyn - cant find principal in allocations", ?msg.caller));
            };
        };

    };

    //query groups
    //query reservations
    //query registrations

    public query (msg) func get_registration_sale_nft_origyn(principal : Principal) : async Result.Result<Types.RegisterEscrowResponse, Types.OrigynError>{

        //todo:  Secure so only msg.caller or owner/manager can call this
        D.print("geting reg balance" # debug_show(principal));

        switch( Map.get<Principal, Types.Registration>(state.user_registrations, Map.phash, principal)){
            case(?val){
                 
                let iter1 = Map.entries<Text, Types.RegistrationClaim>(val.allocation);
                let iter2 = Iter.map<(Text, Types.RegistrationClaim), Types.RegisterEscrowAllocationDetail>(iter1, Types.stabalize_xfer_RegisterAllocation);
                return (#ok({
                    
                    allocation = Iter.toArray<Types.RegisterEscrowAllocationDetail>(iter2);
                    max_desired = val.max_desired;
                    escrow_receipt = val.escrow_receipt;
                    allocation_size = val.allocation_size;
                    principal = val.principal;
                }));
            };
            case(null){
                return (#ok({
                    
                    allocation = [];
                    max_desired = 0;
                    escrow_receipt = null;
                    allocation_size = 0;
                    principal = principal;
                }));
            };
        };

    }





}