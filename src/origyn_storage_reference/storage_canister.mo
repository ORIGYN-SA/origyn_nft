import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Candy "mo:candy/types";
import CandyTypes "mo:candy/types";
import Conversions "mo:candy/conversion";
import Cycles "mo:base/ExperimentalCycles";
import D "mo:base/Debug";
import DIP721 "../origyn_nft_reference/DIP721";
import EXT "mo:ext/Core";
import Error "mo:base/Error";
import Iter "mo:base/Iter";
import Metadata "../origyn_nft_reference/metadata";
import Mint "../origyn_nft_reference/mint";
import NFTUtils "../origyn_nft_reference/utils";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Map "mo:map/Map";
import Result "mo:base/Result";
import Storage_Store "../origyn_nft_reference/storage_store";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import Types "../origyn_nft_reference/types";
import Workspace "mo:candy/workspace";
import http "../origyn_nft_reference/storage_http";
import Migrations "../origyn_nft_reference/migrations_storage";
import MigrationTypes "../origyn_nft_reference/migrations_storage/types";


shared (deployer) actor class Storage_Canister(__initargs : Types.StorageInitArgs) = this {
    stable var SIZE_CHUNK = 2048000; //max message size

    stable var ic : Types.IC = actor("aaaaa-aa");

    let debug_channel = {
        refresh = false;
    };

    
    stable var nft_library_stable : [(Text,[(Text,CandyTypes.AddressedChunkArray)])] = [];
    stable var tokens_stable : [(Text, MigrationTypes.Current.HttpAccess)] = [];

    let initial_storage = switch(__initargs.storage_space){
            case(null){
                SIZE_CHUNK * 500; //default is 1GB
            };
            case(?val){
                if(val > SIZE_CHUNK * 1000){ //only 2GB useable in a canister
                    assert(false);
                };
                val;
            }
        };

    //initialize types and stable storage
    let StateTypes = MigrationTypes.Current;
    let SB = StateTypes.SB;

    stable var migrationState : MigrationTypes.State = #v0_0_0(#data);

    migrationState := Migrations.migrate(migrationState, #v0_1_0(#id), { 
        owner = deployer.caller;
        network = __initargs.network;
        storage_space = initial_storage; 
        gateway_canister = __initargs.gateway_canister;
        caller = deployer.caller ;});

    // do not forget to change #state002 when you are adding a new migration
    let #v0_1_3(#data(state_current)) = migrationState;

    //the library needs to stay unstable for maleable access to the Buffers that make up the file chunks
    private var nft_library : TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>> = NFTUtils.build_library(nft_library_stable);
    //store access tokens for owner assets to owner specific data
    private var tokens : TrieMap.TrieMap<Text, MigrationTypes.Current.HttpAccess> = TrieMap.fromEntries<Text, MigrationTypes.Current.HttpAccess>(tokens_stable.vals(), Text.equal, Text.hash);

    private var canister_principal : ?Principal = null;


    // returns the canister principal
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

    
    //builds the state for passing to child modules
    let get_state : () -> Types.StorageState  = func (){
        {
            var state = state_current;
            var nft_library = nft_library;
            get_time = get_time;
            canister = get_canister;
            refresh_state = get_state;
            tokens = tokens;
        };
    };

    
    //used for testing
    stable var __time_mode : {#test; #standard;} = #standard;
    private var __test_time : Int = 0;

    private func get_time() : Int{
        switch(__time_mode){
            case(#standard){return Time.now();};
            case(#test){return __test_time;};
        };

    };

    // get current owner of the nft
    public query func get_collection_owner_nft_origyn(): async Principal.Principal {
        state_current.collection_data.owner;
    };

    // get current manager of the nft
    public query func get_collection_managers_nft_origyn(): async [Principal.Principal] {
        state_current.collection_data.managers;
    };

    // get current network of the nft
    public query func get_collection_network_nft_origynt(): async ?Principal.Principal {
        state_current.collection_data.network;
    };

    //stores the chunk for a library
    public shared (msg) func stage_library_nft_origyn(chunk : Types.StageChunkArg, allocation: Types.AllocationRecordStable, metadata : CandyTypes.CandyValue) : async Result.Result<Types.StageLibraryResponse,Types.OrigynError> {

        return await* Storage_Store.stage_library_nft_origyn(
            get_state(),
            chunk,
            allocation,
            metadata,
            msg.caller);
    };

    //when meta data is updated on the gateway it will call this function to make sure the
    //the storage contatiner has the same info
    public shared (msg) func refresh_metadata_nft_origyn(token_id: Text, metadata: CandyTypes.CandyValue) : async Result.Result<Bool, Types.OrigynError>{

                            debug if(debug_channel.refresh) D.print("in metadata refresh");
        if(state_current.collection_data.owner != msg.caller){return #err(Types.errors(#unauthorized_access, "refresh_metadata_nft_origyn - storage - not an owner", ?msg.caller))};

        switch(Map.get<Text, Candy.CandyValue>(state_current.nft_metadata, Map.thash, token_id)){
            case(null){
                D.print("error");
                return #err(Types.errors(#token_not_found, "refresh_metadata_nft_origyn - storage - cannot find metadata to replace - " # token_id, ?msg.caller));
          
            };
            case(_){};
        };

                            debug if(debug_channel.refresh) D.print("in metadata refresh");
                            debug if(debug_channel.refresh) D.print("in metadata refresh");
        D.print("putting metadata" # debug_show(metadata));
        Map.set<Text, Candy.CandyValue>(state_current.nft_metadata, Map.thash, token_id, metadata);

        return #ok(true);
    };

    //used for testing
    public shared (msg) func __advance_time(new_time: Int) : async Int {
        
        if(msg.caller != state_current.collection_data.owner){
            throw Error.reject("not owner");
        };
        __test_time := new_time;
        return __test_time;

    };

    //used for testing
    public shared (msg) func __set_time_mode(newMode: {#test; #standard;}) : async Bool {
        if(msg.caller != state_current.collection_data.owner){
            throw Error.reject("not owner");
        };
        __time_mode := newMode;
        return true;
    };

    //get storage info from the container
    public query func storage_info_nft_origyn() : async Result.Result<Types.StorageMetrics, Types.OrigynError>{
        return #ok({
            allocated_storage = state_current.canister_allocated_storage;
            available_space = state_current.canister_availible_space;
            gateway = state_current.collection_data.owner  ;

            allocations = Iter.toArray<Types.AllocationRecordStable>(Iter.map<Types.AllocationRecord,Types.AllocationRecordStable>(Map.vals<(Text,Text),Types.AllocationRecord>(state_current.allocations),Types.allocation_record_stabalize));
        });
    };

    //secure storage info from the container
    public func storage_info_secure_nft_origyn() : async Result.Result<Types.StorageMetrics, Types.OrigynError>{
        return #ok({
            allocated_storage = state_current.canister_allocated_storage;
            available_space = state_current.canister_availible_space;
            gateway = state_current.collection_data.owner  ;

            allocations = Iter.toArray<Types.AllocationRecordStable>(Iter.map<Types.AllocationRecord,Types.AllocationRecordStable>(Map.vals<(Text,Text),Types.AllocationRecord>(state_current.allocations),Types.allocation_record_stabalize));
        });
    };

    

    private func _chunk_nft_origyn(request : Types.ChunkRequest, caller: Principal) : Result.Result<Types.ChunkContent, Types.OrigynError>{
        //nyi: we need to check to make sure the chunk is public or caller has rights

        let allocation = switch(Map.get<(Text, Text), Types.AllocationRecord>(state_current.allocations,( NFTUtils.library_hash,  NFTUtils.library_equal), (request.token_id, request.library_id))){
            case(null){
                return #err(Types.errors(#library_not_found, "chunk_nft_origyn - allocatio for token, library - " # request.token_id # " " # request.token_id, ?caller));
            };
            case(?val){val};
        };

        switch(nft_library.get(request.token_id)){
            case(null){
                return #err(Types.errors(#token_not_found, "chunk_nft_origyn - cannot find token id - " # request.token_id, ?caller));
            };
            case(?token){
                switch(token.get(request.library_id)){
                    case(null){
                        return #err(Types.errors(#library_not_found, "chunk_nft_origyn - cannot find library id: token_id - " # request.token_id  # " library_id - " # request.library_id, ?caller));
                    };
                    case(?item){
                        switch(item.getOpt(1)){
                            case(null){
                                //nofiledata
                                return #err(Types.errors(#library_not_found, "chunk_nft_origyn - chunk was empty: token_id - " # request.token_id  # " library_id - " # request.library_id # " chunk - " # debug_show(request.chunk), ?caller));
                            };
                            case(?zone){
                                //D.print("size of zone");
                                //D.print(debug_show(zone.size()));
                                let requested_chunk = switch(request.chunk){
                                    case(null){
                                        //just want the allocation
                                        return #ok(#chunk({
                                                content = Blob.fromArray([]);
                                                total_chunks = zone.size();
                                                current_chunk = request.chunk;
                                                storage_allocation = Types.allocation_record_stabalize(allocation);
                                            }));
                                        
                                    };
                                    case(?val){val};
                                };
                                switch(zone.getOpt(requested_chunk)){
                                    case(null){
                                        return #err(Types.errors(#library_not_found, "chunk_nft_origyn - cannot find chunk id: token_id - " # request.token_id  # " library_id - " # request.library_id # " chunk - " # debug_show(request.chunk), ?caller));
                                    };
                                    case(?chunk){
                                        switch(chunk){
                                            case(#Bytes(wval)){
                                                switch(wval){
                                                    case(#thawed(val)){
                                                        return #ok(#chunk({
                                                            content = Blob.fromArray(val.toArray());
                                                            total_chunks = zone.size();
                                                            current_chunk = request.chunk;
                                                            storage_allocation = Types.allocation_record_stabalize(allocation);
                                                        }));
                                                    };
                                                    case(#frozen(val)){
                                                        return #ok(#chunk({
                                                            content = Blob.fromArray(val);
                                                            total_chunks = zone.size();
                                                            current_chunk = request.chunk;
                                                            storage_allocation = Types.allocation_record_stabalize(allocation);
                                                        }));
                                                    }
                                                };
                                            };

                                            case(#Blob(wval)){
                                                
                                                return #ok(#chunk({
                                                    content = wval;
                                                    total_chunks = zone.size();
                                                    current_chunk = request.chunk;
                                                    storage_allocation = Types.allocation_record_stabalize(allocation);
                                                }));
                                                   
                                            };
                                            case(_){
                                                return #err(Types.errors(#content_not_deserializable, "chunk_nft_origyn - chunk did not deserialize: token_id - " # request.token_id  # " library_id - " # request.library_id # " chunk - " # debug_show(request.chunk), ?caller));
                                            };
                                        }
                                    };
                                };
                            };
                        };
                    };

                };

            };
        };
        return #err(Types.errors(#nyi, "chunk_nft_origyn - nyi", ?caller));
    };

    //gets a chunk for a library
    public query (msg) func chunk_nft_origyn(request : Types.ChunkRequest) : async Result.Result<Types.ChunkContent, Types.OrigynError>{

        return _chunk_nft_origyn(request, msg.caller);
    };

    //gets a chunk for a library
    public shared (msg) func chunk_secure_nft_origyn(request : Types.ChunkRequest) : async Result.Result<Types.ChunkContent, Types.OrigynError>{
        //warning:  test this, it may change the caller to the local canister
        return  _chunk_nft_origyn(request, msg.caller);
    };

    public query(msg) func http_request(rawReq: Types.HttpRequest): async (http.HTTPResponse) {
        return http.http_request(get_state(), rawReq, msg.caller);
    };

    // A streaming callback based on NFTs. Returns {[], null} if the token can not be found.
    // Expects a key of the following pattern: "nft/{key}".
    public query func nftStreamingCallback(tk : http.StreamingCallbackToken) : async http.StreamingCallbackResponse {
        //D.print("The nftstreamingCallback");
        //D.print(debug_show(tk));

        return http.nftStreamingCallback(tk, get_state());
    };

    public query func http_request_streaming_callback(
        tk : http.StreamingCallbackToken
    ) : async http.StreamingCallbackResponse {
        return http.http_request_streaming_callback(tk, get_state());
    };

    public query (msg) func whoami(): async (Principal) { msg.caller };

    public shared func canister_status(request: { canister_id: Types.canister_id }): async Types.canister_status {
        await ic.canister_status(request)
    };

    public query func cycles(): async Nat {
        Cycles.balance()
    };

    system func preupgrade() {


        tokens_stable := Iter.toArray(tokens.entries());

        let nft_library_stable_buffer = Buffer.Buffer<(Text, [(Text, CandyTypes.AddressedChunkArray)])>(nft_library.size());
        for(thisKey in nft_library.entries()){
            let thisLibrary_buffer : Buffer.Buffer<(Text, CandyTypes.AddressedChunkArray)> = Buffer.Buffer<(Text, CandyTypes.AddressedChunkArray)>(thisKey.1.size());
            for(thisItem in thisKey.1.entries()){
                thisLibrary_buffer.add((thisItem.0, Workspace.workspaceToAddressedChunkArray(thisItem.1)) );
            };
            nft_library_stable_buffer.add((thisKey.0, thisLibrary_buffer.toArray()));
        };

        nft_library_stable := nft_library_stable_buffer.toArray();

    };

    system func postupgrade() {
        nft_library_stable := [];
        tokens_stable := [];
     };
};
