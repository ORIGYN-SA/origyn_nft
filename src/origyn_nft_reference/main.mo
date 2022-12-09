import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import D "mo:base/Debug";
import Error "mo:base/Error";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import CandyTypes "mo:candy_0_1_10/types";
import Conversions "mo:candy_0_1_10/conversion";
import EXT "mo:ext/Core";
import EXTCommon "mo:ext/Common";
import Map "mo:map_6_0_0/Map";
import Properties "mo:candy_0_1_10/properties";
import Workspace "mo:candy_0_1_10/workspace";
import Current "migrations/v000_001_000/types";
import DIP721 "DIP721";
import Governance "governance";
import Market "market";
import Metadata "metadata";
import MigrationTypes "./migrations/types";
import Migrations "./migrations";
import Mint "mint";
import NFTUtils "utils";
import Owner "owner";
import Types "./types";
import data "data";
import http "http";
import Char "mo:base/Char";
import Canistergeek "mo:canistergeek/canistergeek";



shared (deployer) actor class Nft_Canister(__initargs : Types.InitArgs) = this {

    // Lets user turn debug messages on and off for local replica
    let debug_channel = {
        instantiation = true;
        upgrade = false;
        function_announce = true;
        storage = false;
        streaming = false;
    };

    debug if(debug_channel.instantiation) D.print("creating a canister");
                            
    // A standard file chunk size.  The IC limits intercanister messages to ~2MB+ so we set that here
    stable var SIZE_CHUNK = 2048000; //max message size

    // Canisters can support multiple storage nodes
    // If you have a small collection you don't need to use a storage collection
    // And can have this gateway canister act as your storage.
    let initial_storage = switch(__initargs.storage_space){
        case(null){
            SIZE_CHUNK * 500; //default is 1GB
        };
        case(?val){
            if(val > SIZE_CHUNK * 1000){ //only 2GB useable in a canister - hopefully this changes in the future
                assert(false);
            };
            val;
        }
    };

    // *************************
    // ***** CANISTER GEEK *****
    // *************************

    // Metrics
    stable var _canistergeekMonitorUD: ? Canistergeek.UpgradeData = null;
    private let canistergeekMonitor = Canistergeek.Monitor();
    // Logs
    stable var _canistergeekLoggerUD: ? Canistergeek.LoggerUpgradeData = null;
    private let canistergeekLogger = Canistergeek.Logger();

    // *************************
    // *** END CANISTER GEEK ***
    // *************************
       
    ///for migration information and pattern see
    //https://github.com/ZhenyaUsenko/motoko-migrations
    let StateTypes = MigrationTypes.Current;
    let SB = StateTypes.SB;

    debug if(debug_channel.instantiation) D.print("setting migration type to 0");
                            

    stable var migration_state: MigrationTypes.State = #v0_0_0(#data);
    // For backups
    stable var halt : Bool = false;
    stable var data_harvester_page_size : Nat = 100;

    debug if(debug_channel.instantiation) D.print("migrating");

    // Do not forget to change #v0_1_0 when you are adding a new migration
    // If you use one previous state in place of #v0_1_0 it will run downgrade methods instead
    migration_state := Migrations.migrate(migration_state, #v0_1_0(#id), {owner = __initargs.owner; storage_space = initial_storage});

    /* 
    example migration

    switch(migration_state){
        case(#v0_1_1(val)){
            migration_state := Migrations.migrate(migration_state, #v0_1_0(#id), { owner = deployer.caller; storage_space = initial_storage });
        };
        case(_){};
    };
    
    */

    // Do not forget to change #v0_1_0 when you are adding a new migration
    let #v0_1_0(#data(state_current)) = migration_state;
                        
    debug if(debug_channel.instantiation) D.print("done initing migration_state" # debug_show(state_current.collection_data.owner) # " " # debug_show(deployer.caller));
    debug if(debug_channel.instantiation) D.print("initializing from " # debug_show((deployer, __initargs)) );
    
    // Used to get status of the canister and report it
    stable var ic : Types.IC = actor("aaaaa-aa");

    // Upgrade storage for non-stable types
    stable var nft_library_stable : [(Text,[(Text,CandyTypes.AddressedChunkArray)])] = [];
    stable var access_tokens_stable : [(Text, Types.HttpAccess)] = [];
    
    // Stores data for a library - unstable because it uses Candy Workspaces to hold active and maleable bits of data that can be manipulated in real time
    private var nft_library : TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>> = NFTUtils.build_library(nft_library_stable);
    
    // Store access tokens for owner assets to owner specific data
    private var access_tokens : TrieMap.TrieMap<Text, Types.HttpAccess> = TrieMap.fromEntries<Text, Types.HttpAccess>(access_tokens_stable.vals(), Text.equal, Text.hash);

    // Let us get the principal of the host gateway canister
    private var canister_principal : ?Principal = null;
    private func get_canister(): Principal {
        switch(canister_principal){
            case(null){
                canister_principal := ?Principal.fromActor(this);
                Principal.fromActor(this);
            };
            case(?val){
                val;
            }
        }
    };

    // Let us access state and pass it to other modules
    let get_state : () -> Types.State  = func (){
        {
            state = state_current;
            canister = get_canister;
            get_time = get_time;
            nft_library = nft_library;
            refresh_state = get_state;
            access_tokens = access_tokens;
        };
    };

    // Used for debugging
    stable var __time_mode : {#test; #standard;} = #standard;
    private var __test_time : Int = 0;
    private func get_time() : Int{
        switch(__time_mode){
            case(#standard){return Time.now();};
            case(#test){return __test_time;};
        };

    };

    // set the `data_havester`
    public shared (msg) func set_data_harvester(_page_size: Nat): async () {
        if(NFTUtils.is_owner_manager_network(get_state(),msg.caller) == false){
        throw Error.reject("not the admin");
        };

        data_harvester_page_size := _page_size
    };

    // set the `halt`
    public shared (msg) func set_halt(bHalt: Bool): async () {
        if(NFTUtils.is_owner_network(get_state(),msg.caller) == false){
        throw Error.reject("not the admin");
        };
  
        halt := bHalt;
    };

    public query (msg) func get_halt() : async Bool {
        halt
    };

    // Data api - currently entire api nodes must be updated at one time
    // In future releases more granular updates will be possible
    public shared (msg) func update_app_nft_origyn(request: Types.NFTUpdateRequest): async Result.Result<Types.NFTUpdateResponse, Types.OrigynError>{
         if(halt == true){throw Error.reject("canister is in maintenance mode");};
         switch(request){
            case(#replace(val)){
             var log_data = val.data;
             canistergeekLogger.logMessage("update_app_nft_origyn",log_data,?msg.caller);
            };
            case(#update(val)){
                var update_data = val.token_id;
                // canistergeekLogger.logMessage("update_app_nft_origyn",update_data,?msg.caller);
            };
            
        };

        canistergeekMonitor.collectMetrics();
        return data.update_app_nft_origyn(request, get_state(), msg.caller);
    };

    // Stages metadata for an NFT
    public shared (msg) func stage_nft_origyn({metadata : CandyTypes.CandyValue}): async Result.Result<Text, Types.OrigynError>{
        //nyi:  if we run out of space, start putting data into child canisters
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        canistergeekLogger.logMessage("stage_nft_origyn",metadata,?msg.caller);
        canistergeekMonitor.collectMetrics();
        debug if(debug_channel.function_announce) D.print("in stage");
        return Mint.stage_nft_origyn(get_state(), metadata, msg.caller);
    };

    // Allows staging multiple NFTs at the same time
    public shared (msg) func stage_batch_nft_origyn(request : [{metadata: CandyTypes.CandyValue}]): async [Result.Result<Text, Types.OrigynError>]{
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in stage batch");
        if( NFTUtils.is_owner_manager_network(get_state(), msg.caller) == false){
            return [#err(Types.errors(#unauthorized_access, "stage_batch_nft_origyn - not an owner, manager, or network", ?msg.caller))];
        };


        let results = Buffer.Buffer<Result.Result<Text,Types.OrigynError>>(request.size());
        for(this_item in request.vals()){
            // Logs
            canistergeekLogger.logMessage("stage_batch_nft_origyn",this_item.metadata,?msg.caller);
            //nyi: should probably check for some spammy things and bail if too many errors
            results.add(Mint.stage_nft_origyn(get_state(), this_item.metadata, msg.caller));
        };
        canistergeekMonitor.collectMetrics();
        return results.toArray();

    };

    // Stages a library. If the gateway is out of space a new bucket will be requested
    // And the remote stage call will be made to send the chunk to the proper canister.Array
    // Creators can also send library metadata to update library info without the data
    public shared (msg) func stage_library_nft_origyn(chunk : Types.StageChunkArg) : async Result.Result<Types.StageLibraryResponse,Types.OrigynError> {
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        let log_data : Text = "Chunk number : " # Nat.toText(chunk.chunk) # " - Library id : " # chunk.library_id ;
        canistergeekLogger.logMessage("stage_library_nft_origyn",#Text(log_data),?msg.caller);
        canistergeekMonitor.collectMetrics();
        debug if(debug_channel.function_announce) D.print("in stage library");
        switch(Mint.stage_library_nft_origyn(
            get_state(),
            chunk,
             msg.caller)){
                 case(#ok(stage_result)){
                    switch(stage_result){
                        case(#staged(canister)){
                            return #ok({canister = canister});
                        };
                        case(#stage_remote(data)){
                            debug if(debug_channel.storage) D.print("minting remote");
                            return await Mint.stage_library_nft_origyn_remote(
                                get_state(),
                                chunk,
                                data.allocation,
                                data.metadata,
                                msg.caller);
                        };
                    };
                 };
                 case(#err(err)){
                     return #err(err);
                 };
            };
    };

    // Allows for batch library staging but this should only be used for collection or web based
    // libraries that do not have actual file data.  If a remote call is made then the cycle limit
    // will be hit after a few cross canister calls
    public shared (msg) func stage_library_batch_nft_origyn(chunks : [Types.StageChunkArg]) : async [Result.Result<Types.StageLibraryResponse,Types.OrigynError>] {
        //nyi: this needs to be gated to make sure the chunks don't contain file data. This should only be used for collection asset adding
        
        
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in stage library batch");
        let results = Buffer.Buffer<Result.Result<Types.StageLibraryResponse,Types.OrigynError>>(chunks.size());
        for(this_item in chunks.vals()){
            // Logs
            var log_data : Text = "Chunk number : " # Nat.toText(this_item.chunk) # " - Library id : " # this_item.library_id ;
            canistergeekLogger.logMessage("stage_library_batch_nft_origyn",#Text(log_data),?msg.caller);
            switch(Mint.stage_library_nft_origyn(
                get_state(),
                this_item,
                msg.caller)){
                    case(#ok(stage_result)){
                        switch(stage_result){
                            case(#staged(canister)){
                                results.add( #ok({canister = canister}));
                            };
                            case(#stage_remote(data)){
                                debug if(debug_channel.storage) D.print("minting remote from batch. You are going to run out of cycles");
                                results.add( await Mint.stage_library_nft_origyn_remote(
                                    get_state(),
                                    this_item,
                                    data.allocation,
                                    data.metadata,
                                    msg.caller)
                                );
                            };
                        };
                    };
                    case(#err(err)){
                        results.add(#err(err));
                    };
                };
        };
        
        canistergeekMonitor.collectMetrics();

        return results.toArray();
    };

    // Mints a NFT and assigns it to the new owner
    public shared (msg) func mint_nft_origyn(token_id : Text, new_owner : Types.Account) : async Result.Result<Text,Types.OrigynError> {
        if(halt == true){throw Error.reject("canister is in maintenance mode");}; 
        switch(new_owner){
            case(#account(val)){
                let a = Principal.toText(val.owner);
                canistergeekLogger.logMessage("mint_nft_origyn",#Text(token_id # " new owner : " # a),?msg.caller);
            };
            case(#account_id(val)){
                canistergeekLogger.logMessage("mint_nft_origyn",#Text(token_id # " new owner : " # val),?msg.caller);
            };
            case(#extensible(val)){
                canistergeekLogger.logMessage("mint_nft_origyn",val,?msg.caller);
            };
            case(#principal(val)){
                let p = Principal.toText(val);
                canistergeekLogger.logMessage("mint_nft_origyn",#Text(token_id # " new owner : " # p),?msg.caller);
            };
        };       
        
        canistergeekMonitor.collectMetrics();

        debug if(debug_channel.function_announce) D.print("in mint");
        return await Mint.mint_nft_origyn(get_state(), token_id, new_owner, msg.caller);
        
    };

    // Allows minting of multiple items
    public shared (msg) func mint_batch_nft_origyn(tokens: [(Text, Types.Account)]) : async [Result.Result<Text,Types.OrigynError>] {
        // This involves an inter canister call and will not work well for multi canister collections. Test to figure out how many you can mint at a time;

        
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        if(NFTUtils.is_owner_manager_network(get_state(),msg.caller) == false){
        return [#err(Types.errors(#unauthorized_access, "mint_nft_origyn - not an owner", ?msg.caller))]
        };
        debug if(debug_channel.function_announce) D.print("in mint batch");
        let results = Buffer.Buffer<Result.Result<Text,Types.OrigynError>>(tokens.size());
        let result_buffer = Buffer.Buffer<async Result.Result<Text,Types.OrigynError>>(tokens.size());

        label search for(thisitem in tokens.vals()){
            // Logs
            let log_data = thisitem;
            canistergeekLogger.logMessage("mint_batch_nft_origyn",#Text(log_data.0),?msg.caller);
            result_buffer.add(Mint.mint_nft_origyn(get_state(), thisitem.0, thisitem.1, msg.caller));

            if(result_buffer.size() > 9){
              for(thisItem in result_buffer.vals()){
                results.add(await thisItem);
              };
              result_buffer.clear();
            };
        };
        for(thisItem in result_buffer.vals()){
          results.add(await thisItem);
        };
        canistergeekMonitor.collectMetrics();
        return results.toArray();
    };

    // Allows an owner to transfer a NFT from one of their wallets to another
    // Warning: this feature will be updated in the future to give both wallets access to the NFT
    // for some set period of time including access to assets beyond just the NFT ownership. It should not
    // be used with a wallet that you do not 100% trust to not take the NFT back. It is meant for 
    // internal accounting only. Use market_transfer_nft_origyn instead
    public shared (msg) func share_wallet_nft_origyn(request : Types.ShareWalletRequest) : async Result.Result<Types.OwnerTransferResponse,Types.OrigynError> {
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        canistergeekLogger.logMessage("share_wallet_nft_origyn",#Text(request.token_id),?msg.caller);
        canistergeekMonitor.collectMetrics();
        debug if(debug_channel.function_announce) D.print("in share wallet");
        return Owner.share_wallet_nft_origyn(get_state(), request, msg.caller);
    };


    // Used by the network to perform governance actions that have been voted on by OGY token holders
    // For non OGY NFTs you will need to call this function from the principal set as your 'network'
    public shared (msg) func governance_nft_origyn(request : Types.GovernanceRequest) : async Result.Result<Types.GovernanceResponse,Types.OrigynError> {
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        switch (request){
            case(#clear_shared_wallets(val)){
                canistergeekLogger.logMessage("governance_nft_origyn",#Text(val),?msg.caller);
            };
        };
        canistergeekMonitor.collectMetrics();
        debug if(debug_channel.function_announce) D.print("in owner governance");
        return Governance.governance_nft_origyn(get_state(), request, msg.caller);
    };

    // Dip721 transferFrom - must have a valid escrow
    public shared (msg) func transferFromDip721(from: Principal, to: Principal, tokenAsNat: Nat) : async DIP721.Result{
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        let log_data : Text = "From : " # Principal.toText(from) # " to " # Principal.toText(to) # " - Token : " # Nat.toText(tokenAsNat); 
        canistergeekLogger.logMessage("transferFromDip721",#Text(log_data),?msg.caller);
        canistergeekMonitor.collectMetrics();
        debug if(debug_channel.function_announce) D.print("in transferFromDip721");
        // Existing escrow acts as approval
        if(msg.caller != to){
            return #Err(#UnauthorizedOperator);
        };
        return await Owner.transferDip721(get_state(),from, to, tokenAsNat, msg.caller);
    };

    // Dip721 transfer - must have a valid escrow
    public shared (msg) func transferDip721(to: Principal, tokenAsNat: Nat) : async DIP721.Result{
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        let log_data : Text = "To :" # Principal.toText(to) # " - Token : " # Nat.toText(tokenAsNat); 
        canistergeekLogger.logMessage("transferDip721",#Text("transferDip721"),?msg.caller);
        canistergeekMonitor.collectMetrics();
        debug if(debug_channel.function_announce) D.print("in transferFromDip721");
        // Existing escrow acts as approval
        return await Owner.transferDip721(get_state(),msg.caller, to, tokenAsNat, msg.caller);
    };

    // Dip721 transferFrom "v2" downgrade - must have a valid escrow
    public shared (msg) func transferFrom(from: Principal, to: Principal, tokenAsNat: Nat) : async DIP721.Result{
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        let log_data : Text = "From : " # Principal.toText(from) # " to " # Principal.toText(to) # " - Token : " # Nat.toText(tokenAsNat); 
        canistergeekLogger.logMessage("transferFrom",#Text("transferFrom"),?msg.caller);
        canistergeekMonitor.collectMetrics();
        debug if(debug_channel.function_announce) D.print("in transferFrom");
        if(msg.caller != to){
            return #Err(#UnauthorizedOperator);
        };
        // Existing escrow acts as approval
        return await Owner.transferDip721(get_state(),from, to, tokenAsNat, msg.caller);
    };


    // EXT transferFrom - must have a valid escrow
    public shared (msg) func transferEXT(request: EXT.TransferRequest) : async EXT.TransferResponse{
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        canistergeekLogger.logMessage("transferEXT",#Text("transferEXT"),?msg.caller);
        canistergeekMonitor.collectMetrics();
        debug if(debug_channel.function_announce) D.print("in transfer ext");
        // Existing escrow is approval
        return await Owner.transferExt(get_state(), request, msg.caller);
    };

    // EXT transferFrom legacy - must have a valid escrow
    public shared (msg) func transfer(request: EXT.TransferRequest) : async EXT.TransferResponse{
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        canistergeekLogger.logMessage("transfer",#Text("transfer"),?msg.caller);
        canistergeekMonitor.collectMetrics();
        debug if(debug_channel.function_announce) D.print("in transfer");
        // Existing escrow is approval
        return await Owner.transferExt(get_state(), request, msg.caller);
    };


    // Allows the market based transfer of NFTs
    public shared (msg) func market_transfer_nft_origyn(request : Types.MarketTransferRequest) : async Result.Result<Types.MarketTransferRequestReponse,Types.OrigynError> {
        
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        var log_data : Text = "Token : " # request.token_id;
        switch(request.sales_config.pricing){
            case(#instant){
                log_data #= ", type : instant";
            };
            case(#flat(val)){
                log_data #= ", type : flat, amount : " # Nat.toText(val.amount);
            };
            case(#auction(val)){
                log_data #= ", type : auction, start price : " # Nat.toText(val.start_price);
            };
            case(#dutch(val)){
                log_data #= ", type : dutch, start price : " # Nat.toText(val.start_price);
            };
            case(#extensible(val)){
                log_data #= ", type : extensible";
            };
        };

        canistergeekLogger.logMessage("market_transfer_nft_origyn",#Text(log_data),?msg.caller);
        canistergeekMonitor.collectMetrics();
        debug if(debug_channel.function_announce) D.print("in market transfer");
        
        return switch(request.sales_config.pricing){
            case(#instant(item)){
                //instant transfers involve the movement of tokens on remote servers so the call must be async
                return await Market.market_transfer_nft_origyn_async(get_state(), request, msg.caller);
            };
            case(_){
                //handles #auction types
                return Market.market_transfer_nft_origyn(get_state(), request, msg.caller);
            }
        };
    };

    // Start a large number of sales/market transfers. Currently limited to owners, managers, or the network
    public shared (msg) func market_transfer_batch_nft_origyn(request : [Types.MarketTransferRequest]) : async [Result.Result<Types.MarketTransferRequestReponse,Types.OrigynError>] {
        // nyi: for now limit this to managers
        
               
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in market transfer batch");
        if( NFTUtils.is_owner_manager_network(get_state(), msg.caller) == false){
            return [#err(Types.errors(#unauthorized_access, "market_transfer_batch_nft_origyn - not an owner, manager, or network", ?msg.caller))];
        };

        let results = Buffer.Buffer<Result.Result<Types.MarketTransferRequestReponse,Types.OrigynError>>(request.size());
        let result_buffer = Buffer.Buffer<async Result.Result<Types.MarketTransferRequestReponse, Types.OrigynError>>(1);

        for(this_item in request.vals()){
            // Logs
            // var first_item = request[0];
            var log_data : Text = "Token : " # this_item.token_id;
            switch(this_item.sales_config.pricing){
                case(#instant){
                    log_data #= ", type : instant";
                };
                case(#flat(val)){
                    log_data #= ", type : flat, amount : " # Nat.toText(val.amount);
                };
                case(#auction(val)){
                    log_data #= ", type : auction, start price : " # Nat.toText(val.start_price);
                };
                case(#dutch(val)){
                    log_data #= ", type : dutch, start price : " # Nat.toText(val.start_price);
                };
                case(#extensible(val)){
                    log_data #= ", type : extensible";
                };
            };
            canistergeekLogger.logMessage("market_transfer_batch_nft_origyn",#Text(log_data),?msg.caller);
            // nyi: should probably check for some spammy things and bail if too many errors
            
            switch(this_item.sales_config.pricing){
                case(#instant(item)){
                    result_buffer.add(Market.market_transfer_nft_origyn_async(get_state(), this_item, msg.caller));
                };
                case(_){
                    results.add(Market.market_transfer_nft_origyn(get_state(), this_item, msg.caller));
                };
            };

            if(result_buffer.size() > 9){
              for(thisItem in result_buffer.vals()){
                results.add(await thisItem);
              };
              result_buffer.clear();
            };
        };

        for(thisItem in result_buffer.vals()){
          results.add(await thisItem);
        };
        //D.print("made it");
        canistergeekMonitor.collectMetrics();
        return results.toArray();
    };


    // Allows a user to do a number of functions around a NFT sale including ending a sale, opening a sale, depositing an escrow
    // refresh_offers, bidding in an auction, withdrawing funds from an escrow or sale
    public shared (msg) func sale_nft_origyn(request: Types.ManageSaleRequest) : async Result.Result<Types.ManageSaleResponse, Types.OrigynError>{
        
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        var log_data : Text = "";                
        canistergeekMonitor.collectMetrics();
        debug if (debug_channel.function_announce) D.print("in sale_nft_origyn");

        return switch (request) {
            case (#end_sale(val)) {
                log_data #= "Type : end sale, token id : " # val;
                canistergeekLogger.logMessage("sale_nft_origyn",#Text(log_data),?msg.caller);
                await Market.end_sale_nft_origyn(get_state(), val, msg.caller);
            };
            case (#open_sale(val)) {
                log_data #= "Type : open sale, token id : " # val;
                canistergeekLogger.logMessage("sale_nft_origyn",#Text(log_data),?msg.caller);
                Market.open_sale_nft_origyn(get_state(), val, msg.caller);
            };
            case (#escrow_deposit(val)) {
                log_data #= "Type : escrow deposit, token id : " # val.token_id;
                canistergeekLogger.logMessage("sale_nft_origyn",#Text(log_data),?msg.caller);
                return await Market.escrow_nft_origyn(get_state(), val, msg.caller);
            };
            case (#refresh_offers(val)) {
                log_data #= "Type : refresh offers";
                canistergeekLogger.logMessage("sale_nft_origyn",#Text(log_data),?msg.caller);
                Market.refresh_offers_nft_origyn(get_state(), val, msg.caller);
            };
            case (#bid(val)) {
                log_data #= "Type : bid";
                canistergeekLogger.logMessage("sale_nft_origyn",#Text(log_data),?msg.caller);
                await Market.bid_nft_origyn(get_state(), val, msg.caller);

            };
            case (#withdraw(val)) {                
                switch(val){
                    case(#escrow(v)){
                        log_data #= "Type : withdraw with escrow";
                    };
                    case(#sale(v)){
                        log_data #= "Type : withdraw with sale";
                    };
                    case(#reject(v)){
                        log_data #= "Type : withdraw with reject";
                    };
                    case(#deposit(v)){
                        log_data #= "Type : withdraw with deposit";
                    };
                };
                canistergeekLogger.logMessage("sale_nft_origyn",#Text(log_data),?msg.caller);
                // D.print("in withdrawl");
                await Market.withdraw_nft_origyn(get_state(), val, msg.caller);
            };
        };

    };

    // Allows batch operations
    public shared (msg) func sale_batch_nft_origyn(requests: [Types.ManageSaleRequest]) : async [Result.Result<Types.ManageSaleResponse, Types.OrigynError>]{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in sale_nft_origyn batch");
        if( NFTUtils.is_owner_manager_network(get_state(), msg.caller) == false and msg.caller != get_state().canister()){
            return [#err(Types.errors(#unauthorized_access, "sale_batch_nft_origyn - not an owner, manager, or network - batch not supported", ?msg.caller))];
        };        
        
        let result = Buffer.Buffer<Result.Result<Types.ManageSaleResponse, Types.OrigynError>>(requests.size());
        let result_buffer = Buffer.Buffer<async Result.Result<Types.ManageSaleResponse, Types.OrigynError>>(requests.size());
        for(this_item in requests.vals()){
            var log_data : Text = "";
            switch(this_item){
                //NOTE: this causes a commit and could over run the cycle limit. We may need to refactor to
                // an end and then distribute pattern...or collect needed transfers and batch them.
                case(#end_sale(val)){
                    log_data #= "Type : end sale, token id : " # val;
                    canistergeekLogger.logMessage("sale_nft_origyn",#Text(log_data),?msg.caller);
                    result_buffer.add(Market.end_sale_nft_origyn(get_state(), val, msg.caller));
                };
                case(#open_sale(val)){
                    log_data #= "Type : open sale, token id : " # val;
                    canistergeekLogger.logMessage("sale_nft_origyn",#Text(log_data),?msg.caller);
                    result.add(Market.open_sale_nft_origyn(get_state(), val, msg.caller));
                };
                case(#escrow_deposit(val)){ 
                    log_data #= "Type : escrow deposit, token id : " # val.token_id;
                    canistergeekLogger.logMessage("sale_nft_origyn",#Text(log_data),?msg.caller);
                    result_buffer.add(Market.escrow_nft_origyn(get_state(), val, msg.caller));
                };
                case(#refresh_offers(val)){
                    log_data #= "Type : refresh offers";
                    canistergeekLogger.logMessage("sale_nft_origyn",#Text(log_data),?msg.caller);
                    result.add(Market.refresh_offers_nft_origyn(get_state(), val, msg.caller));
                };
                case(#bid(val)){
                    log_data #= "Type : bid";
                    canistergeekLogger.logMessage("sale_nft_origyn",#Text(log_data),?msg.caller);
                    result_buffer.add(Market.bid_nft_origyn(get_state(), val, msg.caller));
                    
                };
                 case(#withdraw(val)){
                    switch(val){
                        case(#escrow(v)){
                            log_data #= "Type : withdraw with escrow";
                        };
                        case(#sale(v)){
                            log_data #= "Type : withdraw with sale";
                        };
                        case(#reject(v)){
                            log_data #= "Type : withdraw with reject";
                        };
                        case(#deposit(v)){
                            log_data #= "Type : withdraw with deposit";
                        };
                    };
                    canistergeekLogger.logMessage("sale_nft_origyn",#Text(log_data),?msg.caller);
                    result_buffer.add(Market.withdraw_nft_origyn(get_state(), val, msg.caller));
                };
            };

            if(result_buffer.size() > 9){
              for(thisItem in result_buffer.vals()){
                result.add(await thisItem);
              };
              result_buffer.clear();
            };
        };
        for(thisItem in result_buffer.vals()){
          result.add(await thisItem);
        };
        canistergeekMonitor.collectMetrics();
        return result.toArray();
    };


    private func _sale_info_nft_origyn(request: Types.SaleInfoRequest, caller: Principal) : Result.Result<Types.SaleInfoResponse, Types.OrigynError>{

        return switch(request){
            case(#status(val)){Market.sale_status_nft_origyn(get_state(), val, caller)};
            case(#active(val)){Market.active_sales_nft_origyn(get_state(), val, caller)};
            case(#history(val)){Market.history_sales_nft_origyn(get_state(), val, caller)};
            case(#deposit_info(val)){Market.deposit_info_nft_origyn(get_state(), val, caller)};
        };
    };


    // Allows for the retrieving of sale info
    public query (msg) func sale_info_nft_origyn(request: Types.SaleInfoRequest) : async Result.Result<Types.SaleInfoResponse, Types.OrigynError>{
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce)D.print("in sale_info_nft_origyn");
        return _sale_info_nft_origyn(request, msg.caller);
        
    };

    // Get sale info in a secure manner
    public shared(msg) func sale_info_secure_nft_origyn(request: Types.SaleInfoRequest) : async Result.Result<Types.SaleInfoResponse, Types.OrigynError>{

        if(halt == true){throw Error.reject("canister is in maintenance mode");}; 
        var log_data : Text = "";
        switch(request){
            case(#active(val)){ log_data #= "Type : active" };
            case(#history(val)){ log_data #= "Type : history" };
            case(#status(val)){ log_data #= "Type : status" };
            case(#deposit_info(val)){ log_data #= "Type : deposit" };
        };
        canistergeekLogger.logMessage("sale_info_secure_nft_origyn",#Text(log_data),?msg.caller);
        canistergeekMonitor.collectMetrics();
        debug if(debug_channel.function_announce) D.print("in sale info secure");
        return _sale_info_nft_origyn(request, msg.caller);
    };

    // Batch info
    public query (msg) func sale_info_batch_nft_origyn(requests: [Types.SaleInfoRequest]) : async [Result.Result<Types.SaleInfoResponse, Types.OrigynError>]{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in sale info batch");
        let result = Buffer.Buffer<Result.Result<Types.SaleInfoResponse, Types.OrigynError>>(requests.size());
        for(this_item in requests.vals()){
            result.add(_sale_info_nft_origyn(this_item, msg.caller));
        };
        return result.toArray();

    };

    // Batch info secure
    public shared (msg) func sale_info_batch_secure_nft_origyn(requests: [Types.SaleInfoRequest]) : async [Result.Result<Types.SaleInfoResponse, Types.OrigynError>]{
        
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in sale info batch secure");
        let result = Buffer.Buffer<Result.Result<Types.SaleInfoResponse, Types.OrigynError>>(requests.size());
        for(this_item in requests.vals()){
            var log_data : Text = "";
            switch(this_item){
                case(#active(val)){ log_data #= "Type : active" };
                case(#history(val)){ log_data #= "Type : history" };
                case(#status(val)){ log_data #= "Type : status" };
                case(#deposit_info(val)){ log_data #= "Type : deposit" };
            };
            canistergeekLogger.logMessage("sale_info_batch_secure_nft_origyn",#Text(log_data),?msg.caller);   
            result.add(_sale_info_nft_origyn(this_item, msg.caller));
        };
        return result.toArray();
    };

    // Allows an owner to update information about a collection
    public shared (msg) func collection_update_nft_origyn(request : Types.ManageCollectionCommand) : async Result.Result<Bool, Types.OrigynError>{
        
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        var log_data : Text = "";
        switch(request){
            case(#UpdateManagers(val)){ log_data #= "Type : UpdateManagers" };
            case(#UpdateOwner(val)){ log_data #= "Type : UpdateOwner" };
            case(#UpdateNetwork(val)){ log_data #= "Type : UpdateNetwork" };
            case(#UpdateLogo(val)){ log_data #= "Type : UpdateLogo" };
            case(#UpdateName(val)){ log_data #= "Type : UpdateName" };
            case(#UpdateSymbol(val)){ log_data #= "Type : UpdateSymbol" };
            case(#UpdateMetadata(val)){ log_data #= "Type : UpdateMetadata" };
        };
        canistergeekLogger.logMessage("collection_update_nft_origyn",#Text(log_data),?msg.caller);
        canistergeekMonitor.collectMetrics();
        debug if(debug_channel.function_announce) D.print("in collection_update_nft_origyn");
        return Metadata.collection_update_nft_origyn(get_state(), request, msg.caller);
    };


    // Batch access
    public shared (msg) func collection_update_batch_nft_origyn(requests : [Types.ManageCollectionCommand]) : async [Result.Result<Bool, Types.OrigynError>]{
        
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in collection_update_batch_nft_origyn");
        // We do a first check of caller to avoid cycle drain
        if(NFTUtils.is_owner_network(get_state(), msg.caller) == false){
            return [#err(Types.errors(#unauthorized_access, "collection_update_batch_nft_ - not a canister owner or network", ?msg.caller))];
        };

        let results = Buffer.Buffer<Result.Result<Bool, Types.OrigynError>>(requests.size());
        for(this_item in requests.vals()){
             var log_data : Text = "";
            switch(this_item){
                case(#UpdateManagers(val)){ log_data #= "Type : UpdateManagers" };
                case(#UpdateOwner(val)){ log_data #= "Type : UpdateOwner" };
                case(#UpdateNetwork(val)){ log_data #= "Type : UpdateNetwork" };
                case(#UpdateLogo(val)){ log_data #= "Type : UpdateLogo" };
                case(#UpdateName(val)){ log_data #= "Type : UpdateName" };
                case(#UpdateSymbol(val)){ log_data #= "Type : UpdateSymbol" };
                case(#UpdateMetadata(val)){ log_data #= "Type : UpdateMetadata" };
            };
            canistergeekLogger.logMessage("collection_update_batch_nft_origyn",#Text(log_data),?msg.caller);
            results.add(Metadata.collection_update_nft_origyn(get_state(), this_item, msg.caller));
        };

        return results.toArray();
    };

    
    // Debug function
    public shared (msg) func __advance_time(new_time: Int) : async Int {
        // nyi: Maybe only the network should be able to do this
        if(msg.caller != state_current.collection_data.owner){
            throw Error.reject("not owner");
        };
        __test_time := new_time;
        return __test_time;

    };

    // Debug function
    public shared (msg) func __set_time_mode(newMode: {#test; #standard;}) : async Bool {
         // nyi: Maybe only the network should be able to do this
        if(msg.caller != state_current.collection_data.owner){
            throw Error.reject("not owner");
        };
        __time_mode := newMode;
        return true;
    };

    // Allows the owner to manage the storage on their NFT
    public shared (msg) func manage_storage_nft_origyn(request : Types.ManageStorageRequest) : async Result.Result<Types.ManageStorageResponse, Types.OrigynError>{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        if(NFTUtils.is_owner_network(get_state(), msg.caller) == false){
            throw Error.reject("not owner or network");
        };
        debug if(debug_channel.function_announce) D.print("in collection_update_batch_nft_origyn");
        
        canistergeekLogger.logMessage("manage_storage_nft_origyn",#Text("#add_storage_canisters"),?msg.caller);
        canistergeekMonitor.collectMetrics();

        let state = get_state();

        switch(request){
            case(#add_storage_canisters(request)){
                for(this_item in request.vals()){
                    //make sure that if this exists we re allocate or error
                    switch(Map.get(state.state.buckets, Map.phash, this_item.0)){
                        case(null){};
                        case(?val){
                            //eventually we can accomidate reallocation, but fail for now
                            return #err(Types.errors(#storage_configuration_error, "manage_storage_nft_origyn - principal already exists in buckets  " # debug_show(this_item), ?msg.caller));

                        };
                    };

                    Map.set<Principal, Types.BucketData>(state.state.buckets, Map.phash, this_item.0, {
                        principal = this_item.0;
                        var allocated_space = this_item.1;
                        var available_space = this_item.1;
                        date_added = get_time();
                        b_gateway = false;
                        var version = this_item.2;
                        var allocations = Map.new<(Text,Text), Int>();

                    });
                    state.state.collection_data.allocated_storage += this_item.1;
                    state.state.collection_data.available_space += this_item.1;
                };
                return #ok(#add_storage_canisters(state.state.collection_data.allocated_storage,
                     state.state.collection_data.available_space));
            };
        };

        return #err(Types.errors(#nyi, "manage_storage_nft_origyn nyi ", ?msg.caller));

    };

    

    // [Text, ?Nat, ?Nat] for pagination
    // Returns information about the collection
    public query (msg) func collection_nft_origyn(fields : ?[(Text,?Nat, ?Nat)]) : async Result.Result<Types.CollectionInfo, Types.OrigynError>{
        // Warning: this function does not use msg.caller, if you add it you need to fix the secure query
        
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        canistergeekLogger.logMessage("collection_nft_origyn",#Text("collection_nft_origyn"),?msg.caller);
        canistergeekMonitor.collectMetrics();

        debug if(debug_channel.function_announce) D.print("in collection_nft_origyn");        

        let state = get_state();
        let keys = if(NFTUtils.is_owner_manager_network(get_state(), msg.caller) == true){
          Iter.toArray<Text>(Iter.filter<Text>(Map.keys(state.state.nft_metadata), func (x : Text){ x != ""})); // Should always have the "" item and need to remove it
        } else {
          Iter.toArray<Text>(Iter.filter<Text>(Map.keys(state.state.nft_ledgers), func (x : Text){ x != ""})); // Should always have the "" item and need to remove it
        };
        let multi_canister = Iter.toArray<Principal>(Map.keys<Principal, Types.BucketData>(state.state.buckets));

        
        return #ok({
                fields = fields;
                logo = state.state.collection_data.logo;
                name = state.state.collection_data.name;
                symbol = state.state.collection_data.symbol;
                total_supply = ?keys.size();
                owner = ?state.state.collection_data.owner;
                managers = ?state.state.collection_data.managers;
                network = state.state.collection_data.network;
                token_ids = ?keys;
                token_ids_count = ?keys.size();
                multi_canister = ?multi_canister;
                multi_canister_count = ?multi_canister.size();
                metadata = Map.get(state.state.nft_metadata, Map.thash, "");
                allocated_storage = ?state.state.collection_data.allocated_storage;
                available_space = ?state.state.collection_data.available_space;
            }
        );


    };

    // Secure access to collection information
    public shared (msg) func collection_secure_nft_origyn(fields : ?[(Text,?Nat, ?Nat)]) : async Result.Result<Types.CollectionInfo, Types.OrigynError>{
        
       if(halt == true){throw Error.reject("canister is in maintenance mode");};  
       canistergeekLogger.logMessage("collection_secure_nft_origyn",#Text("collection_secure_nft_origyn"),?msg.caller);
       canistergeekMonitor.collectMetrics();
       debug if(debug_channel.function_announce) D.print("in collection_secure_nft_origyn");
        
        return await collection_nft_origyn(fields);
    };

    private func _history_nft_origyn(token_id : Text, start: ?Nat, end: ?Nat, caller : Principal) : Result.Result<[Types.TransactionRecord],Types.OrigynError>{
      let ledger = switch(Map.get(state_current.nft_ledgers, Map.thash, token_id)){
        case(null){
            return #ok([]);
        };
        case(?val){
            var thisStart = 0;
            var thisEnd = Nat.sub(SB.size(val),1);
            switch(start, end){
                case(?start, ?end){
                    thisStart := start;
                    thisEnd := end;
                };
                case(?start, null){
                    thisStart := start;
                };
                case(null, ?end){
                    thisEnd := end;
                };
                case(null, null){};
            };

            if(thisEnd >= thisStart){

                let result = Buffer.Buffer<Types.TransactionRecord>((thisEnd + 1) - thisStart);
                for(this_item in Iter.range(thisStart, thisEnd)){
                    result.add(switch(SB.getOpt(val, this_item)){case(?item){item};case(null){
                        return #err(Types.errors(#asset_mismatch, "history_nft_origyn - index out of range  " # debug_show(this_item) # " " # debug_show(SB.size(val)), ?caller));

                    }});
                };

                return #ok(result.toArray());
            } else {
                // Enable revrange
                return #err(Types.errors(#nyi, "history_nft_origyn - rev range nyi  " # debug_show(thisStart) # " " # debug_show(thisEnd), ?caller));
            };
        };
      };
    };

    // Allows users to see token information - ledger and history
    public query (msg) func history_nft_origyn(token_id : Text, start: ?Nat, end: ?Nat) : async Result.Result<[Types.TransactionRecord],Types.OrigynError> {
        // Warning: this func does not use msg.caller. If you decide to use it, fix the secure caller

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in collection_secure_nft_origyn");
        return _history_nft_origyn(token_id, start, end, msg.caller);
    };

    // Secure access to token history
    public shared (msg) func history_secure_nft_origyn(token_id : Text, start: ?Nat, end: ?Nat) : async Result.Result<[Types.TransactionRecord],Types.OrigynError> {
       
       if(halt == true){throw Error.reject("canister is in maintenance mode");};
       var log_data : Text = "Token id : " # token_id;
       canistergeekLogger.logMessage("history_secure_nft_origyn",#Text(log_data),?msg.caller);
       canistergeekMonitor.collectMetrics();

       debug if(debug_channel.function_announce) D.print("in history_secure_nft_origyn");
        
       return _history_nft_origyn(token_id, start,end,msg.caller);
    };

    // Provides access to searching a large number of histories
    public query (msg) func history_batch_nft_origyn(tokens : [(token_id : Text, start: ?Nat, end: ?Nat)]) : async [Result.Result<[Types.TransactionRecord], Types.OrigynError>]{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in history_batch_nft_origyn");        
        let results = Buffer.Buffer<Result.Result<[Types.TransactionRecord], Types.OrigynError>>(tokens.size());
        label search for(thisitem in tokens.vals()){
            results.add( _history_nft_origyn(thisitem.0, thisitem.1, thisitem.2, msg.caller));
           
        };
        return results.toArray();
    };

    // Secure access to history batch
    public shared (msg) func history_batch_secure_nft_origyn(tokens : [(token_id : Text, start: ?Nat, end: ?Nat)]) : async [Result.Result<[Types.TransactionRecord], Types.OrigynError>]{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in history_batch_secure_nft_origyn");        
        let results = Buffer.Buffer<Result.Result<[Types.TransactionRecord], Types.OrigynError>>(tokens.size());
        label search for(thisitem in tokens.vals()){
            results.add( _history_nft_origyn(thisitem.0, thisitem.1, thisitem.2,msg.caller));
           
        };
        return results.toArray();
    };



    
    // Dip721 balance
    public query(msg) func balanceOfDip721(user: Principal) : async Nat{
       
       debug if(debug_channel.function_announce) D.print("in balanceOfDip721");
       return (Metadata.get_NFTs_for_user(get_state(), #principal(user))).size();
    };

    // Dip721 balance
    public query(msg) func balance(request: EXT.BalanceRequest) : async EXT.BalanceResponse{ //legacy ext
        
        debug if(debug_channel.function_announce) D.print("in balance");
        return _getEXTBalance(request);
    };

    // Ext balance
    public query(msg) func balanceEXT(request: EXT.BalanceRequest) : async EXT.BalanceResponse {
        
        debug if(debug_channel.function_announce) D.print("in balanceEXT");
        return  _getEXTBalance(request);
    };

    private func _getEXTBalance(request: EXT.BalanceRequest) : EXT.BalanceResponse{
        let thisCollection = Metadata.get_NFTs_for_user(get_state(), switch(request.user){
            case(#address(data)){
                #account_id(data);
            };
            case(#principal(data)){
                #principal(data);
            };
        }
        );
        for(this_item in thisCollection.vals()){
            if(_getEXTTokenIdentifier(this_item) == request.token){
                return #ok(1: Nat);
            }
        };
        return #ok(0: Nat);
    };

    // Converts a token id into a reversable ext token id
    private func _getEXTTokenIdentifier(token_id: Text) : Text{
        let tds : [Nat8] = [10, 116, 105, 100]; //b"\x0Atid"
        let theID = Array.append<Nat8>(
            Array.append<Nat8>(tds, Blob.toArray(Principal.toBlob(Principal.fromActor(this)))),
            Conversions.valueToBytes(#Nat32(Text.hash(token_id))));

        return Principal.toText(Principal.fromBlob(Blob.fromArray(theID)));
    };

    // Lets users query for a token id
    public query(msg) func getEXTTokenIdentifier(token_id: Text) : async Text{
       debug if(debug_channel.function_announce) D.print("in getEXTTokenIdentifier");
        return _getEXTTokenIdentifier(token_id);
    };
    
    // Builds the balance object showing what resources an account holds on the server.
    private func _balance_of_nft_origyn(account: Types.Account, caller: Principal) : Result.Result<Types.BalanceResponse, Types.OrigynError> {

        
        debug if(debug_channel.function_announce) D.print("in balance_of_nft_origyn");
        let state = get_state();
        
        // Get escrows
        let escrows = Map.get(state_current.escrow_balances, Types.account_handler, account);
        let escrowResults = Buffer.Buffer<Types.EscrowRecord>(1);

        let sales = Map.get(state_current.sales_balances, Types.account_handler, account);
        let salesResults = Buffer.Buffer<Types.EscrowRecord>(1);

        let nft_results = Buffer.Buffer<Text>(1);

        let offers = Map.get<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, Types.account_handler, account);
        let offer_results = Buffer.Buffer<Types.EscrowRecord>(1);

        // nyi: check the mint status and compare to msg.caller
        // nyi: indexing of NFTs, Escrows, Sales, Offers if this is a performance drain
        for(this_nft in Map.entries(state.state.nft_metadata)){
            switch(Metadata.is_nft_owner(this_nft.1, account)){
                case(#ok(val)){
                    if(val == true and this_nft.0 != ""){
                        nft_results.add(this_nft.0);
                    };
                };
                case(_){};
            };

        };


        switch(escrows)
        {
            case(null){};
            case(?this_buyer){
                Iter.iterate<MigrationTypes.Current.EscrowTokenIDTrie>(Map.vals(this_buyer), func(thisSeller, x){
                    Iter.iterate<MigrationTypes.Current.EscrowLedgerTrie>(Map.vals(thisSeller), func(this_token_id, x){
                        Iter.iterate<MigrationTypes.Current.EscrowRecord>(Map.vals(this_token_id), func(this_ledger, x){
                            escrowResults.add(this_ledger);
                        });
                    });
                });
            };
        };

        switch(sales)
        {
            case(null){};
            case(?thisSeller){
                Iter.iterate<MigrationTypes.Current.EscrowTokenIDTrie>(Map.vals(thisSeller), func(this_buyer, x){
                    Iter.iterate<MigrationTypes.Current.EscrowLedgerTrie>(Map.vals(this_buyer), func(this_token_id, x){
                        Iter.iterate<MigrationTypes.Current.EscrowRecord>(Map.vals(this_token_id), func(this_ledger, x){
                            salesResults.add(this_ledger);
                        });
                    });
                });
            };
        };


        switch(offers){
            case(null){};
            case(?found_offer){
                for(this_buyer in Map.entries<Types.Account, Int>(found_offer)){
                    switch(Map.get<Types.Account, MigrationTypes.Current.EscrowSellerTrie>(state_current.escrow_balances, Types.account_handler, this_buyer.0)){
                        case(null){};
                        case(?found_buyer){
                            switch(Map.get(found_buyer, Types.account_handler, account)){
                                case(null){};
                                case(?found_seller){
                                     for(this_token in Map.entries(found_seller)){
                                         for(this_ledger in Map.entries(this_token.1)){
                                             offer_results.add(this_ledger.1);
                                         };
                                     };
                                };
                            };
                        };
                    };
                };
            };
        };

        return #ok{
            multi_canister = null; //nyi
            nfts = nft_results.toArray();
            escrow = escrowResults.toArray();
            sales = salesResults.toArray();
            stake = [];
            offers = offer_results.toArray();
        };
    };


    // Lets a user query the balances for their nfts, escrows, sales, offers, and stakes
    public query(msg) func balance_of_nft_origyn(account: Types.Account) : async Result.Result<Types.BalanceResponse, Types.OrigynError>{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        switch(account){
            case(#account(val)){
                let a = Principal.toText(val.owner);
                canistergeekLogger.logMessage("balance_of_nft_origyn",#Text("Type - account : " # a),?msg.caller);
            };
            case(#account_id(val)){
                canistergeekLogger.logMessage("balance_of_nft_origyn",#Text("Type - account id : " # val),?msg.caller);
            };
            case(#extensible(val)){
                canistergeekLogger.logMessage("balance_of_nft_origyn",#Text("Type - extensible"),?msg.caller);
            };
            case(#principal(val)){
                let p = Principal.toText(val);
                canistergeekLogger.logMessage("balance_of_nft_origyn",#Text("Type - principal : " # p),?msg.caller);
            };
        };
        
        canistergeekMonitor.collectMetrics();
        return _balance_of_nft_origyn(account, msg.caller);
    };



    // Allows secure access to balance
    public shared(msg) func balance_of_secure_nft_origyn(account: Types.Account) : async Result.Result<Types.BalanceResponse, Types.OrigynError>{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        switch(account){
            case(#account(val)){
                let a = Principal.toText(val.owner);
                canistergeekLogger.logMessage("balance_of_secure_nft_origyn",#Text("Type - account : " # a),?msg.caller);
            };
            case(#account_id(val)){
                canistergeekLogger.logMessage("balance_of_secure_nft_origyn",#Text("Type - account id : " # val),?msg.caller);
            };
            case(#extensible(val)){
                canistergeekLogger.logMessage("balance_of_secure_nft_origyn",#Text("Type - extensible"),?msg.caller);
            };
            case(#principal(val)){
                let p = Principal.toText(val);
                canistergeekLogger.logMessage("balance_of_secure_nft_origyn",#Text("Type - principal : " # p),?msg.caller);
            };
        };
        
        canistergeekMonitor.collectMetrics();
        return _balance_of_nft_origyn(account, msg.caller);
    };


    private func _bearer_of_nft_origyn(token_id : Text, caller: Principal) : Result.Result<Types.Account, Types.OrigynError>{
         let foundVal = switch(
            Metadata.get_nft_owner(
                switch(Metadata.get_metadata_for_token(get_state(),token_id, caller, null, state_current.collection_data.owner)){
                    case(#err(err)){
                        return #err(Types.errors(#token_not_found, "bearer_nft_origyn " # err.flag_point, ?caller));
                    };
                    case(#ok(val)){
                        val;
                    };
                })){
                case(#err(err)){
                    return #err(Types.errors(err.error, "bearer_nft_origyn " # err.flag_point, ?caller));
                };
                case(#ok(val)){
                    return #ok(val);
                };
        };
    };

    // Returns the owner of the NFT indicated by token_id
    public query (msg) func bearer_nft_origyn(token_id : Text) : async Result.Result<Types.Account, Types.OrigynError>{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in bearer_nft_origyn");
        return _bearer_of_nft_origyn(token_id, msg.caller);
       
    };

    // Secure access to bearer
    public shared (msg) func bearer_secure_nft_origyn(token_id : Text) : async Result.Result<Types.Account, Types.OrigynError>{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in bearer_secure_nft_origyn");        
        return _bearer_of_nft_origyn(token_id, msg.caller);
    };

    // Provides access to searching a large number of bearers at one time
    // nyi: could expose items not minted. add mint/owner check
    public query (msg) func bearer_batch_nft_origyn(tokens : [Text]) : async [Result.Result<Types.Account, Types.OrigynError>]{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in bearer_secure_nft_origyn");
        let results = Buffer.Buffer<Result.Result<Types.Account, Types.OrigynError>>(tokens.size());
        label search for(thisitem in tokens.vals()){
            results.add( _bearer_of_nft_origyn(thisitem, msg.caller));
           
        };
        return results.toArray();
    };

    // Secure access to bearer batch
    public shared (msg) func bearer_batch_secure_nft_origyn(tokens : [Text]) : async [Result.Result<Types.Account, Types.OrigynError>]{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in bearer_batch_secure_nft_origyn");        
        let results = Buffer.Buffer<Result.Result<Types.Account, Types.OrigynError>>(tokens.size());
        label search for(thisitem in tokens.vals()){
            results.add( _bearer_of_nft_origyn(thisitem, msg.caller));
           
        };
        return results.toArray();
    };

    // Conversts a token id to a Nat for use in dip721
    public query(msg) func get_token_id_as_nat_origyn(token_id : Text) : async Nat {

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in get_token_id_as_nat_origyn");
        return NFTUtils.get_token_id_as_nat(token_id);
    };

    // Converts a nat to an token_id for Nat
    public query(msg) func get_nat_as_token_id_origyn(tokenAsNat : Nat) : async Text {

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in get_nat_as_token_id_origyn");
       
       NFTUtils.get_nat_as_token_id(tokenAsNat)
    };

    private func _ownerOfDip721 (tokenAsNat: Nat, caller: Principal) :  DIP721.OwnerOfResponse{
        let foundVal = switch(
            Metadata.get_nft_owner(
                switch(Metadata.get_metadata_for_token(get_state(),
                        NFTUtils.get_nat_as_token_id(tokenAsNat)
                    , caller, null, state_current.collection_data.owner)){
                    case(#err(err)){
                        return #Err(#TokenNotFound);
                    };
                    case(#ok(val)){
                        val;
                    };
                })){
                case(#err(err)){
                    return #Err(#Other("ownerOf " # err.flag_point));
                };
                case(#ok(val)){
                    switch(val){
                        case(#principal(data)){
                            return #Ok(?data);
                        };
                        case(_){
                            return #Err(#Other("ownerOf unsupported owner type by DIP721" # debug_show(val)));
                        }
                    }
                };
        };
    };

    // Owner of dip721
    public query(msg) func ownerOfDIP721(tokenAsNat: Nat) : async DIP721.OwnerOfResponse{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in ownerOfDIP721");        
        return _ownerOfDip721(tokenAsNat, msg.caller);
    };

    // For dip721 "v2" downgrade in usability
    public query(msg) func ownerOf(tokenAsNat: Nat) : async DIP721.OwnerOfResponse{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in ownerOf");
        return _ownerOfDip721(tokenAsNat, msg.caller);
    };

    // Supports EXT Bearer
    public query(msg) func bearerEXT(tokenIdentifier: EXT.TokenIdentifier) : async Result.Result<EXT.AccountIdentifier, EXT.CommonError>{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in bearerEXT");
        return Owner.bearerEXT(get_state(), tokenIdentifier, msg.caller);
    };

    // Supports EXT Bearer legacy
    public query(msg) func bearer(tokenIdentifier: EXT.TokenIdentifier) : async Result.Result<EXT.AccountIdentifier, EXT.CommonError>{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in bearer");        
        return Owner.bearerEXT(get_state(), tokenIdentifier, msg.caller);
    };

    private func _nft_origyn(token_id : Text, caller: Principal) : Result.Result<Types.NFTInfoStable, Types.OrigynError>{
        //D.print("Calling NFT_Origyn");

        var metadata = switch(Metadata.get_metadata_for_token(get_state(),token_id, caller, null, state_current.collection_data.owner)){
            case(#err(err)){
                return #err(err);
            };
            case(#ok(val)){
                val;
            };
        };

        let final_object = Metadata.get_clean_metadata(metadata, caller);

        // Identify a current sale
        let current_sale : ?Types.SaleStatusStable = switch(Metadata.get_current_sale_id(metadata)){
            case(#Empty){null};
            case(#Text(val)){
                do ? {Types.SalesStatus_stabalize_for_xfer(Map.get(state_current.nft_sales, Map.thash,val)!)};
            };
            case(_){
                //should be an error
                null};
        };
        return(#ok({
            current_sale = current_sale;
            metadata= final_object;}
        ));

        return #ok({current_sale= null; metadata = #Empty;});
    };  


    // Returns metadata about an NFT
    public query (msg) func nft_origyn(token_id : Text) : async Result.Result<Types.NFTInfoStable, Types.OrigynError>{

        // D.print("nft origyn :" # debug_show(token_id));
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in nft_origyn");
        
        return _nft_origyn(token_id, msg.caller);
    };

    // Secure access to nft_origyn
    public shared (msg) func nft_secure_origyn(token_id : Text) : async Result.Result<Types.NFTInfoStable, Types.OrigynError>{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in nft_secure_origyn");        
        return _nft_origyn(token_id, msg.caller);
    };

    // Batch access to nft metadata
    public query (msg) func nft_batch_origyn(token_ids : [Text]) : async [Result.Result<Types.NFTInfoStable, Types.OrigynError>]{


        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in nft_batch_origyn");        
        let results = Buffer.Buffer<Result.Result<Types.NFTInfoStable, Types.OrigynError>>(token_ids.size());
        label search for(thisitem in token_ids.vals()){            
            results.add(_nft_origyn(thisitem, msg.caller));
        };

        return results.toArray();
    };

    public shared (msg) func nft_batch_secure_origyn(token_ids : [Text]) : async [Result.Result<Types.NFTInfoStable, Types.OrigynError>]{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in nft_batch_secure_origyn");        
        let results = Buffer.Buffer<Result.Result<Types.NFTInfoStable, Types.OrigynError>>(token_ids.size());
        label search for(thisitem in token_ids.vals()){            
            results.add( _nft_origyn(thisitem, msg.caller));
        };

        return results.toArray();
    };


    // Pull a chunk of a nft library
    // The IC can only pull back ~2MB per request. This allows reading an entire library file by a user or canister
    public query (msg) func chunk_nft_origyn(request : Types.ChunkRequest) : async Result.Result<Types.ChunkContent, Types.OrigynError>{
        //D.print("looking for a chunk" # debug_show(request));
        //check mint property
        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in chunk_nft_origyn");        
        return Metadata.chunk_nft_origyn(get_state(), request, ?msg.caller);
    };

    // Secure access to chunks
    public shared (msg) func chunk_secure_nft_origyn(request : Types.ChunkRequest) : async Result.Result<Types.ChunkContent, Types.OrigynError>{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in chunk_secure_nft_origyn");        
        return Metadata.chunk_nft_origyn(get_state(), request, ?msg.caller);
    };

    // Cleans access keys
    private func clearAccessKeysExpired() {
        let max_size = 20000;
        if(access_tokens.size() > max_size) {
            Iter.iterate<Text>(access_tokens.keys(), func(key, _index) {
                switch(access_tokens.get(key)){
                  case(null){};
                  case(?item){
                    if(item.expires < get_time()){
                        access_tokens.delete(key);
                    }
                  }
                }
            });
        };
    };

    let access_expiration = (1000 * 360 * (1_000_000)); //360s

    // Registers a principal with a access key so a user can use that key to make http queries
    public shared(msg) func http_access_key(): async Result.Result<Text, Types.OrigynError> {

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in http_access_key");        
        // nyi: spam prevention
        if(Principal.isAnonymous(msg.caller) ){return #err(Types.errors(#unauthorized_access, "http_access_key - anon not allowed", ?msg.caller))};
                            
        clearAccessKeysExpired();

        let access_key = (await http.gen_access_key()) # Nat32.toText(Text.hash(debug_show(msg.caller, Time.now())));

        access_tokens.put(access_key, {
            identity = msg.caller;
            expires = Time.now() + access_expiration; 
        });

        #ok(access_key);
    };

    // Gets an access key for a user
    public query(msg) func get_access_key(): async Result.Result<Text, Types.OrigynError> {
        debug if(debug_channel.function_announce) D.print("in get_access_key");
        //optimization: use a Map
        for((key, info) in access_tokens.entries()){
          if(Principal.equal(info.identity, msg.caller)) {
            return #ok(key);
          };
        };

        #err(Types.errors(#property_not_found, "access key not found by caller", ?msg.caller));
    };

    // Handles http request
    public query(msg) func http_request(rawReq: Types.HttpRequest): async (http.HTTPResponse) {

        debug if(debug_channel.function_announce) D.print("in http_request");
        return http.http_request(get_state(), rawReq, msg.caller);
    };

    // A streaming callback based on NFTs. Returns {[], null} if the token can not be found.
    // Expects a key of the following pattern: "nft/{key}".
    public query func nftStreamingCallback(tk : http.StreamingCallbackToken) : async http.StreamingCallbackResponse {
       debug if(debug_channel.streaming) D.print("The nftstreamingCallback " # debug_show(debug_show(tk)));
       debug if(debug_channel.function_announce) D.print("in chunk_nft_origyn");
        

        return http.nftStreamingCallback(tk, get_state());
    };

    // Handles streaming
    public query func http_request_streaming_callback(
        tk : http.StreamingCallbackToken
    ) : async http.StreamingCallbackResponse {
        return http.http_request_streaming_callback(tk, get_state());
    };

    // Lets a user see who they are
    public query (msg) func whoami(): async (Principal) { msg.caller };

    // Returns the status of the gateway canister
    public shared func canister_status(request: { canister_id: Types.canister_id }): async Types.canister_status {
        await ic.canister_status(request)
    };

    // Reports cylces
    public query func cycles(): async Nat {
        Cycles.balance()
    };

    // Returns storage metrics for this server
    public query func storage_info_nft_origyn() : async Result.Result<Types.StorageMetrics, Types.OrigynError>{
        // Warning: this func does not use msg.caller. If that changes, fix secure query

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in storage_info_nft_origyn");
        
        let state = get_state();
        return #ok({
            allocated_storage = state.state.canister_allocated_storage;
            available_space = state.state.canister_availible_space;
            allocations = Iter.toArray<Types.AllocationRecordStable>(Iter.map<Types.AllocationRecord,Types.AllocationRecordStable>(Map.vals<(Text,Text),Types.AllocationRecord>(state.state.allocations),Types.allocation_record_stabalize));
        });
    };

    // Secure access to storage info
    public shared(msg) func storage_info_secure_nft_origyn() : async Result.Result<Types.StorageMetrics, Types.OrigynError>{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in storage_info_secure_nft_origyn");
        return await storage_info_nft_origyn();
    };
     

    // Metadata for ext
    public query func metadata(token : EXT.TokenIdentifier) : async Result.Result<EXTCommon.Metadata,EXT.CommonError>{

        if(halt == true){throw Error.reject("canister is in maintenance mode");};
        debug if(debug_channel.function_announce) D.print("in metadata");
      
        let token_id = switch(Owner.getNFTForTokenIdentifier(get_state(), token)){
            case(#ok(data)){
                 data
            };
            case(#err(err)){
                return #err(#InvalidToken(token));
            };
        };

        return #ok(#nonfungible({
                metadata = ?Text.encodeUtf8("https://prptl.io/-/" # Principal.toText(get_canister()) # "/-/" # token_id)
            }));
    };


    // Set the `log_harvester`
    public shared (msg) func set_log_harvester_id(_id: Principal): async () {

        
        let state = get_state();
        if(msg.caller !=  state.state.collection_data.owner) { throw Error.reject("not owner")};

        NFTUtils.add_log(get_state(), {
            event = "set_log_harvester_id";
            timestamp = get_time();
            data =  #Principal(_id);
            caller = ?msg.caller;
        });
         state.state.log_harvester := _id;
    };

    // Get the last pages number of logs and burns them
    public shared(msg) func harvest_log(pages : Nat) : async [[Types.LogEntry]]{
        assert(pages > 0);
        let state = get_state();
        if(msg.caller !=  state.state.log_harvester) {
        throw Error.reject("not the log harvester");
        };
        let result = Buffer.Buffer<[Types.LogEntry]>(pages);
        for(thisRound in Iter.range(0, pages-1)){
            let chunk = SB.removeLast(state.state.log_history);
            switch(chunk){
                case(null){};
                case(?v){
                result.add(v);
                };
            };
        };
        return result.toArray();
    };

    // Destroys the log
    public shared(msg) func nuke_log() : async (){
        let state = get_state();
        if(msg.caller != state.state.log_harvester) {
        throw Error.reject("not the log harvester");
        };
         state.state.log_history := SB.initPresized<[Types.LogEntry]>(1);
    };

    // Log history info
    public query(msg) func log_history_size() : async Nat{
        let state = get_state();
        if(msg.caller !=  state.state.collection_data.owner and msg.caller != state.state.log_harvester ) {
            throw Error.reject("no log rights");
        };
        return SB.size( state.state.log_history);
    };

    // Look a specific page of log history
    public query(msg) func log_history_page(i : Nat) : async [Types.LogEntry]{
        let state = get_state();
        if(msg.caller !=  state.state.collection_data.owner and msg.caller != state.state.log_harvester ) {
            throw Error.reject("no log rights");
        };
        return SB.get( state.state.log_history, i);
    };

    // Look a chunk by page if over 2MB
    public query(msg) func log_history_page_chunk(i : Nat, start: Nat, end: Nat) : async [Types.LogEntry]{
        let state = get_state();
        if(msg.caller !=  state.state.collection_data.owner and msg.caller != state.state.log_harvester) {
            throw Error.reject("no log rights");
        };
        let thisChunk = SB.get(state.state.log_history, i);
        let result = Buffer.Buffer<Types.LogEntry>(end - start + 1);
        Iter.iterate<Types.LogEntry>(thisChunk.vals(), func(a: Types.LogEntry, index: Nat){
            if(index >= start and index <= end){
            result.add(a);
            };
        });
        return result.toArray();
    };

    // Gets the current log page
    public query(msg) func current_log() : async [Types.LogEntry]{
        let state = get_state();
        if(msg.caller !=  state.state.collection_data.owner and msg.caller != state.state.log_harvester) {
            throw Error.reject("no log rights");
        };
        return SB.toArray(state.state.log);
    };

    // *************************
    // * CANDID SERIALIZATION **
    // *************************

    public func text_from_blob(blob : Blob) : async Text {
        Text.join(",", Iter.map<Nat8, Text>(blob.vals(), Nat8.toText));
    };
  
    public func blob_from_text(t : Text) : async Blob {
        
        // textToNat8
        // turns "123" into 123
        func textToNat8(txt : Text) : Nat8 {
        var num : Nat32 = 0;
        for (v in txt.chars()) {
            // Debug.print(debug_show(v));
            num := num * 10 + (Char.toNat32(v) - 48);  // 0 in ASCII is 48
            // Debug.print(debug_show(num));
        };
        Nat8.fromNat(Nat32.toNat(num));
        };

        let ts = Text.split(t, #char(','));
        let bytes = Array.map<Text, Nat8>(Iter.toArray(ts), textToNat8);
        Blob.fromArray(bytes);
    };
   

    // public func test_candid_serialization() : async () {
    //     let state = get_state();

    //     // let u : Types.BackupBuckets = state.state.buckets;

    //     // let u : Types.BackupCollectionData = {
    //     //         logo = state.state.collection_data.logo;
    //     //         name = state.state.collection_data.name;
    //     //         symbol = state.state.collection_data.symbol;
    //     //         metadata = state.state.collection_data.metadata;
    //     //         owner  = state.state.collection_data.owner;
    //     //         managers = state.state.collection_data.managers;
    //     //         network = state.state.collection_data.network;
    //     //         allocated_storage = state.state.collection_data.allocated_storage;
    //     //         available_space  = state.state.collection_data.available_space;
    //     //         active_bucket = state.state.collection_data.active_bucket;
    //     // };
    //     let u : Types.TestStable = Types.stabilize_test({hello = "hey"; var allocated_space = 1024;
    //         var available_space =2048;});
    //     // [Nat8] to text
    //     var txt: Text = await text_from_blob(to_candid(u));
    //     D.print("Txt : " # debug_show(txt)); 
    //     // text to blob
    //     let v : ?Types.TestStable = from_candid(await blob_from_text(txt));
    //     D.print(debug_show(v)); 
    // };

    // *************************
    // **** END SERIALIZATION **
    // *************************

    // *************************
    // ******** BACKUP *********
    // *************************

    public query(msg) func state_size() : async Types.StateSize {
        let state = get_state();
        
        return {
            buckets= Map.size(state.state.buckets);
            allocations= Map.size(state.state.allocations);
            escrow_balances= Map.size(state.state.escrow_balances);
            sales_balances = Map.size(state.state.sales_balances);
            offers= Map.size(state.state.offers);
            nft_ledgers= Map.size(state.state.nft_ledgers);
            nft_sales= Map.size(state.state.nft_sales);
        }
    };

    public query(msg) func back_up(page : Nat) : async {#eof : Types.NFTBackupChunk; #data : Types.NFTBackupChunk} {
        if(NFTUtils.is_owner_manager_network(get_state(),msg.caller) == false){
            throw Error.reject("not the admin");
        };
        
        let targetStart = page * data_harvester_page_size;
        let targetEnd = targetStart + data_harvester_page_size;
        var globalTracker = 0;

        let state = get_state();        
        let owner = state.state.collection_data.owner;
       

        // *** Buckets ***
        var buckets : [(Principal, Types.StableBucketData)] = [];
        let buckets_size = Map.size(state.state.buckets);
        if(targetStart < globalTracker + buckets_size and targetEnd > globalTracker){
             for ((key, value) in Map.entries(state.state.buckets)){
                if(globalTracker >= targetStart and targetEnd > globalTracker){
                    var val = Types.stabilize_bucket_data(value);
                    var e = (key, val);
                    buckets := Array.append<(Principal, Types.StableBucketData)>(buckets,[e]);
                };
                globalTracker += 1;
            };
        } else {
            globalTracker += buckets_size;
        };
       

        // *** Allocations ***
        var allocations : [((Text,Text), Types.AllocationRecordStable)] = [];
        let allocations_size = Map.size(state.state.allocations);
        if(targetStart < globalTracker + allocations_size and targetEnd > globalTracker){
             for ((key, value) in Map.entries(state.state.allocations)){
                if(globalTracker >= targetStart and targetEnd > globalTracker){
                   var val = Types.allocation_record_stabalize(value);
                    var e = (key, val);
                    allocations := Array.append<((Text,Text), Types.AllocationRecordStable)>(allocations,[e]);
                };
                globalTracker += 1;
            };
        } else {
            globalTracker += allocations_size;
        };
        

        // *** Escrow Balances ***
        var escrows : Types.StableEscrowBalances = [];
        let escrows_size = Map.size(state.state.escrow_balances);
        if(targetStart < globalTracker + escrows_size and targetEnd > globalTracker){
            for((acc_top_key,acc_top_val) in Map.entries(state.state.escrow_balances)){
                    if(globalTracker >= targetStart and targetEnd > globalTracker){
                        for((acc_mid_key,acc_mid_val)in Map.entries(acc_top_val)){
                            for((tok_id_key, tok_id_val) in Map.entries(acc_mid_val)){
                                for((token_spec_key,token_spec_val) in Map.entries(tok_id_val)){
                                    // Get escrow record
                                    escrows := Array.append<(Types.Account,Types.Account,Text,Types.EscrowRecord)>(escrows, [(acc_top_key, acc_mid_key,tok_id_key,token_spec_val)]);
                                };
                            };
                        };
                    };
                
                globalTracker += 1;
            };
        }else{
            globalTracker += escrows_size;
        };
        

        // *** Sales Balances ***
        var sales : Types.StableSalesBalances = [];
        let sales_size = Map.size(state.state.sales_balances);
        if(targetStart < globalTracker + sales_size and targetEnd > globalTracker){
            for((acc_top_key,acc_top_val) in Map.entries(state.state.sales_balances)){
                if(globalTracker >= targetStart and targetEnd > globalTracker){
                    for((acc_mid_key,acc_mid_val) in Map.entries(acc_top_val)){
                        for((tok_id_key,tok_id_val) in Map.entries(acc_mid_val)){
                            for((token_spec_key,token_spec_val) in Map.entries(tok_id_val)){
                                // Get escrow record
                                sales := Array.append<(Types.Account,Types.Account,Text,Types.EscrowRecord)>(sales, [(acc_top_key,acc_mid_key,tok_id_key,token_spec_val)]);
                            };
                        };
                    };
                };
                globalTracker += 1;
            };
        } else { 
            globalTracker += sales_size;
        };
        

       // *** Offers ***       
       var offers : Types.StableOffers = [];
       let offers_size = Map.size(state.state.offers);
       if(targetStart < globalTracker + offers_size and targetEnd > globalTracker){
            for((acc_top_key,acc_top_val) in Map.entries(state.state.offers)){
                if(globalTracker >= targetStart and targetEnd > globalTracker){
                    for((acc_mid_key,acc_mid_val) in Map.entries(acc_top_val)){
                        offers := Array.append<(Types.Account,Types.Account,Int)>(offers, [(acc_top_key,acc_mid_key,acc_mid_val)]);
                    };
                };
                globalTracker += 1;
            };
       } else {
             globalTracker += offers_size;
       };
       

       // *** NFT ledgers ***
       var nft_ledgers : Types.StableNftLedger = [];
       let nft_ledgers_size = Map.size(state.state.nft_ledgers);
       if(targetStart < globalTracker + nft_ledgers_size and targetEnd > globalTracker){
            for((tok_key,tok_val) in Map.entries(state.state.nft_ledgers)){
                if(globalTracker >= targetStart and targetEnd > globalTracker){
                    let recordsArr = SB.toArray(tok_val);
                    for(this_item in recordsArr.vals()){
                        nft_ledgers := Array.append<(Text, Types.TransactionRecord)>(nft_ledgers, [(tok_key,this_item)]);
                    };
                };
                globalTracker += 1;
            };
       } else {
            globalTracker +=nft_ledgers_size;
       };
       

       // *** NFT Sales ***
       var nft_sales : Types.StableNftSales = [];
       let nft_sales_size = Map.size(state.state.nft_sales);
       if(targetStart < globalTracker + nft_sales_size and targetEnd > globalTracker){
            for((key,val) in Map.entries(state.state.nft_sales)){
                if(globalTracker >= targetStart and targetEnd > globalTracker){
                    let stableSale = Types.SalesStatus_stabalize_for_xfer(val);
                    nft_sales := Array.append<(Text, Types.SaleStatusStable)>(nft_sales, [(key,stableSale)]);
                };
                globalTracker += 1;
            };
       } else {
            globalTracker +=nft_sales_size;
       };
       
       if(globalTracker > targetStart and globalTracker <= targetEnd){
            //we have reached the eof.
            return  #eof({
                canister = state.canister();
                collection_data = Types.stabilize_collection_data(state.state.collection_data);
                buckets = buckets;
                allocations = allocations;
                escrow_balances = escrows;
                sales_balances = sales;
                offers = offers;
                nft_ledgers = nft_ledgers;
                nft_sales = nft_sales;
            });
       };

        return  #data({
            canister = state.canister();
            collection_data = Types.stabilize_collection_data(state.state.collection_data);
            buckets = buckets;
            allocations = allocations;
            escrow_balances = escrows;
            sales_balances = sales;
            offers = offers;
            nft_ledgers = nft_ledgers;
            nft_sales = nft_sales;
        });
    };

    // *************************
    // ****** END BACKUP *******
    // *************************

    // Announces support of interfaces
    public query func __supports() : async [(Text,Text)]{
        [
            ("nft_origyn","v0.1.0"),
            ("data_nft_origyn","v0.1.0"),
            ("collection_nft_origyn","v0.1.0"),
            ("mint_nft_origyn","v0.1.0"),
            ("owner_nft_origyn","v0.1.0"),
            ("market_nft_origyn","v0.1.0")
        ]
    };

    // Lets the NFT accept cycles
    public func wallet_receive() : async  Nat  {
      let amount = Cycles.available();
      let accepted = amount;
      let deposit = Cycles.accept(accepted);
      accepted;
    };

     // *************************
    // ***** CANISTER GEEK *****
    // *************************

    // METRICS
    public query (msg) func getCanisterMetrics(parameters: Canistergeek.GetMetricsParameters): async ?Canistergeek.CanisterMetrics {
       
        canistergeekMonitor.getMetrics(parameters);
    };

    public query (msg) func collectCanisterMetrics(): async () {
        canistergeekMonitor.collectMetrics();
    };

    // LOGGER

    public query func getCanisterLog(request: ?Canistergeek.CanisterLogRequest) : async ?Canistergeek.CanisterLogResponse {
       
        canistergeekLogger.getLog(request);
    };
    
    // public shared (msg) func doThis( e : Text ): async () {
    //     canistergeekLogger.logMessage(
    //         e,
    //         #Class([
    //                 {name = "library_id"; value=#Text("page"); immutable= true},
    //                 {name = "title"; value=#Text("page"); immutable= true},
    //                 {name = "location_type"; value=#Text("canister"); immutable= true},// ipfs, arweave, portal
    //                 {name = "location"; value=#Text("http://localhost:8000/-/1/-/page?canisterId=biwac-oicms-frnxv-3mcgb-lhfwa-rjl3d-azusa-bb3n6-pihxk-whkya-uae"); immutable= true},
    //                 {name = "content_type"; value=#Text("text/html; charset=UTF-8"); immutable= true},
    //                 {name = "content_hash"; value=#Bytes(#frozen([0,0,0,0])); immutable= true},
    //                 {name = "size"; value=#Nat(10); immutable= true},
    //                 {name = "sort"; value=#Nat(0); immutable= true},
    //                 {name = "read"; value=#Text("public"); immutable=false;},
    //             ]),
    //             ?msg.caller    
    //         );
    //     // rest part of the your method...
    // };
    
    // public shared (msg) func doThat( e : Text ): async () {
    //     canistergeekLogger.logMessage(e, #Class([
    //                 {name = "library_id"; value=#Text("page"); immutable= true},
    //                 {name = "title"; value=#Text("page"); immutable= true},
    //                 {name = "location_type"; value=#Text("canister"); immutable= true},// ipfs, arweave, portal
    //                 {name = "location"; value=#Text("http://localhost:8000/-/1/-/page?canisterId=biwac-oicms-frnxv-3mcgb-lhfwa-rjl3d-azusa-bb3n6-pihxk-whkya-uae"); immutable= true},
    //                 {name = "content_type"; value=#Text("text/html; charset=UTF-8"); immutable= true},
    //                 {name = "content_hash"; value=#Bytes(#frozen([0,0,0,0])); immutable= true},
    //                 {name = "size"; value=#Nat(10); immutable= true},
    //                 {name = "sort"; value=#Nat(0); immutable= true},
    //                 {name = "read"; value=#Text("public"); immutable=false;},
    //             ]),
    //             ?msg.caller
    //             );
    //     // rest part of the your method...
    // };

    // *************************
    // *** END CANISTER GEEK ***
    // *************************



    system func preupgrade() {
        
        // Canistergeek
        _canistergeekMonitorUD := ? canistergeekMonitor.preupgrade();
        _canistergeekLoggerUD := ? canistergeekLogger.preupgrade();
        // End Canistergeek

        access_tokens_stable := Iter.toArray(access_tokens.entries());

        let nft_library_stable_buffer = Buffer.Buffer<(Text, [(Text, CandyTypes.AddressedChunkArray)])>(nft_library.size());
        for(thisKey in nft_library.entries()){
            let this_library_buffer : Buffer.Buffer<(Text, CandyTypes.AddressedChunkArray)> = Buffer.Buffer<(Text, CandyTypes.AddressedChunkArray)>(thisKey.1.size());
            for(this_item in thisKey.1.entries()){
                this_library_buffer.add((this_item.0, Workspace.workspaceToAddressedChunkArray(this_item.1)) );
            };
            nft_library_stable_buffer.add((thisKey.0, this_library_buffer.toArray()));
        };

        nft_library_stable := nft_library_stable_buffer.toArray();

    };

    system func postupgrade() {
        nft_library_stable := [];
        access_tokens_stable := [];

        // Canistergeek

        canistergeekMonitor.postupgrade(_canistergeekMonitorUD);
        _canistergeekMonitorUD := null;
         canistergeekLogger.postupgrade(_canistergeekLoggerUD);
        _canistergeekLoggerUD := null;
        
        //Optional: override default number of log messages to your value
        canistergeekLogger.setMaxMessagesCount(3000);

        // End Canistergeek
    };
};