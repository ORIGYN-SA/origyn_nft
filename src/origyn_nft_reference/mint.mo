import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";

import CandyTypes "mo:candy/types";
import Conversions "mo:candy/conversion";
import Map "mo:map/Map";
import Properties "mo:candy/properties";
import SB "mo:stablebuffer/StableBuffer";
import Workspace "mo:candy/workspace";

import Metadata "metadata";
import NFTUtils "utils";
import Types "types";

module {

    //lets user turn debug messages on and off for local replica
    let debug_channel = {
        function_announce = false;
        storage = false;
        library = false;
        stage = true;
        mint = false;
        remote = false;
    };

    //adds a library to the nft
    private func handle_library(state : Types.State, token_id : Text, found_metadata : CandyTypes.CandyValue, caller : Principal) : Result.Result<Text, Types.OrigynError> {
        //prep the library
        debug if (debug_channel.library) D.print("in handle library");
        switch (Metadata.get_nft_library(found_metadata, ?caller)) {
            case (#err(err)) {}; //fine for now...library isn't required
            case (#ok(library)) {
                switch (library) {
                    case (#Array(item)) {
                        switch (item) {
                            case (#thawed(classes)) {
                                debug if (debug_channel.library) D.print("handling library in nft stage");
                                for (this_item in classes.vals()) {
                                    debug if (debug_channel.library) D.print("handling an item " # debug_show (this_item));
                                    //handle each library
                                    let library_id = switch(Metadata.get_nft_text_property(this_item, Types.metadata.library_id)){
                                        case(#err(err)){return #err(Types.errors(?state.canistergeekLogger,  #malformed_metadata, "handle_library - library needs library_id", ?caller))};
                                        case(#ok(val)){val};
                                    };

                                    let library_size = switch(Metadata.get_nft_nat_property(this_item, Types.metadata.library_size)){
                                        case(#err(err)){return #err(Types.errors(?state.canistergeekLogger,  #malformed_metadata, "handle_library - library needs size", ?caller))};
                                        case(#ok(val)){val};
                                    };

                                    let library_type = switch(Metadata.get_nft_text_property(this_item, Types.metadata.library_location_type)){
                                        case(#err(err)){return #err(Types.errors(?state.canistergeekLogger,  #malformed_metadata, "handle_library - library needs type", ?caller))};
                                        case(#ok(val)){val};
                                    };

                                                    debug if(debug_channel.library) D.print("handling " # debug_show(library_id, library_size, library_type));

                                    //this item is stored on this canister
                                    if (library_type == "canister") {
                                        //find our current bucket
                                        debug if (debug_channel.library) D.print("in a canister branch");

                                        //todo: review what happens if storage = 0
                                        let active_bucket = switch (state.state.collection_data.active_bucket) {
                                            case (null) {
                                                debug if (debug_channel.library) D.print("thie active bucket was null and we are checking that the current canister has space so we can set it");
                                                if (state.state.canister_availible_space > 0) {
                                                    state.state.collection_data.active_bucket := ?state.canister();
                                                    state.canister();
                                                } else {
                                                    return #err(Types.errors(?state.canistergeekLogger,  #not_enough_storage, "handle_library - need to initialize storage for collections where gateway has no storage", ?caller));
                                                }
                                            };
                                            case (?val) { val };
                                        };

                                        //D.print("active bucket is " # debug_show((active_bucket, state.canister(), state.state.buckets)));

                                        var canister_bucket = switch (Map.get<Principal, Types.BucketData>(state.state.buckets, Map.phash, active_bucket)) {
                                            case (null) {
                                                //only happens once on first library addition
                                                debug if (debug_channel.library) D.print("setting up the bucket for the first time through" # debug_show (state.state.canister_availible_space));
                                                let a_bucket = {
                                                    principal = state.canister();
                                                    var allocated_space = state.state.canister_availible_space;
                                                    var available_space = state.state.canister_availible_space; //should still be the maximum amount
                                                    date_added = Time.now();
                                                    b_gateway = true;
                                                    var version = (0, 0, 1);
                                                    var allocations = Map.new<(Text, Text), Int>();
                                                };
                                                //D.print("original bucket set uup " # debug_show(a_bucket));
                                                Map.set<Principal, Types.BucketData>(state.state.buckets, Map.phash, state.canister(), a_bucket);
                                                a_bucket;
                                            };
                                            case (?a_bucket) {
                                                //D.print("was already in the bucket");
                                                if (a_bucket.available_space >= library_size) {
                                                    //D.print("bucket still has space");
                                                    a_bucket;
                                                } else {
                                                    //D.print("need a bucket");
                                                    //need a new active bucket
                                                    var b_found = false;
                                                    var newItem = a_bucket;

                                                    //search for an available bucket where this library will fit
                                                    label find for (this_item in Map.entries<Principal, Types.BucketData>(state.state.buckets)) {
                                                        //D.print("testing bucket " # debug_show(this_item));
                                                        if (this_item.1.available_space >= library_size) {
                                                            //D.print("updating the active bucket " # debug_show((this_item.0, token_id, library_id)));
                                                            b_found := true;
                                                            newItem := this_item.1;
                                                            state.state.collection_data.active_bucket := ?this_item.0;
                                                            break find;
                                                        };
                                                    };

                                                    if (b_found == true) {
                                                        debug if (debug_channel.library) D.print("found a bucket" # debug_show (newItem));
                                                        newItem;
                                                    } else {
                                                        debug if (debug_channel.library) D.print("erroring because " # debug_show ((a_bucket.available_space, library_size)));
                                                        //make sure that size isn't bigger than biggest possible size
                                                        return #err(Types.errors(?state.canistergeekLogger,  #not_enough_storage, "stage_nft_origyn - need to initialize storage out side of this function, dynamic creation is nyi", ?caller));
                                                    };
                                                };
                                            };
                                        };

                                        debug if (debug_channel.library) D.print("have bucket is " # debug_show ((canister_bucket, state.canister(), token_id, library_id)));

                                        //make sure that there is space or create a new bucket
                                        let allocation = switch (Map.get<(Text, Text), Types.AllocationRecord>(state.state.allocations, (NFTUtils.library_hash, NFTUtils.library_equal), (token_id, library_id))) {
                                            case (null) {
                                                //there is no allocation for this library yet, lets create it
                                                debug if (debug_channel.library) D.print("no allocation for this library....creating");
                                                let a_allocation = {
                                                    canister = canister_bucket.principal;
                                                    allocated_space = library_size;
                                                    var available_space = library_size;
                                                    var chunks = SB.initPresized<Nat>(1);
                                                    token_id = token_id;
                                                    library_id = library_id;
                                                    timestamp = state.get_time();
                                                };
                                                debug if (debug_channel.library) D.print("ceating this allocation fresh " # debug_show ((a_allocation, token_id, library_id)));
                                                Map.set<(Text, Text), Types.AllocationRecord>(state.state.allocations, (NFTUtils.library_hash, NFTUtils.library_equal), (token_id, library_id), a_allocation);
                                                //D.print("testing allocation " # debug_show(canister_bucket.available_space, library_size));
                                                Map.set<(Text,Text), Int>(canister_bucket.allocations, (NFTUtils.library_hash, NFTUtils.library_equal), (token_id, library_id), state.get_time());
                                                if(canister_bucket.available_space >= library_size){
                                                  canister_bucket.available_space -= library_size;
                                                } else {
                                                  return #err(Types.errors(?state.canistergeekLogger,  #storage_configuration_error, "stage_nft_origyn - canister_bucket.available_space >= library_size " # debug_show((canister_bucket.available_space,library_size) ), ?caller));
                                                };
                                                if(state.state.collection_data.available_space >= library_size){
                                                  state.state.collection_data.available_space -= library_size;
                                                } else {
                                                  return #err(Types.errors(?state.canistergeekLogger,  #storage_configuration_error, "stage_nft_origyn - state.state.collection_data.available_space >= library_size " # debug_show((state.state.collection_data.available_space,library_size) ), ?caller));
                                                };
                                                if(state.canister() == canister_bucket.principal){
                                                    if(state.state.canister_availible_space >= library_size){
                                                      state.state.canister_availible_space -= library_size;
                                                    } else {
                                                      return #err(Types.errors(?state.canistergeekLogger,  #storage_configuration_error, "stage_nft_origyn - state.state.canister_availible_space >= library_size " # debug_show((state.state.canister_availible_space,library_size) ), ?caller));
                                                    }
                                                };
                                                a_allocation;
                                            };
                                            case (?val) {

                                                //this allocation already exists....did it change?  If so, what do we do?
                                                //NYI: erase the file and reset the allocation
                                                debug if (debug_channel.library) D.print("this allocation is already here" # debug_show (val));

                                                if (val.allocated_space == library_size) {
                                                    //do nothing
                                                    val;
                                                } else if (val.allocated_space < library_size) {

                                                    let a_allocation = {
                                                        canister = val.canister;
                                                        allocated_space = library_size;
                                                        //nyi: more to think through here
                                                        var available_space = val.available_space + (Nat.sub(library_size, val.allocated_space));
                                                        var chunks = val.chunks;
                                                        token_id = token_id;
                                                        library_id = library_id;
                                                        timestamp = state.get_time();
                                                    };
                                                    Map.set<(Text, Text), Types.AllocationRecord>(state.state.allocations, (NFTUtils.library_hash, NFTUtils.library_equal), (token_id, library_id), a_allocation);
                                                    //canister_bucket.allocations := Map.set<(Text,Text), Int>(canister_bucket.allocations,( NFTUtils.library_hash,  NFTUtils.library_equal), (token_id, library_id), state.get_time());
                                                                    debug if(debug_channel.library) D.print("testing allocation " # debug_show(canister_bucket.available_space, library_size));
                                                    if(canister_bucket.available_space >= Nat.sub(library_size ,val.allocated_space)){
                                                      canister_bucket.available_space -= (library_size - val.allocated_space);
                                                    } else {
                                                      return #err(Types.errors(?state.canistergeekLogger,  #storage_configuration_error, "stage_library_nft_origyn - canister - canister_bucket.available_space >= (library_size - val.allocated_space) " # debug_show((canister_bucket.available_space,library_size, val.allocated_space)), ?caller));
                                                    };

                                                    if(state.state.collection_data.available_space >= Nat.sub(library_size, val.allocated_space)){
                                                      state.state.collection_data.available_space -= Nat.sub(library_size, val.allocated_space);
                                                    } else {
                                                      return #err(Types.errors(?state.canistergeekLogger,  #storage_configuration_error, "stage_library_nft_origyn - canister - state.state.collection_data.available_space -= (library_size - val.allocated_space) " # debug_show((state.state.collection_data.available_space,library_size, val.allocated_space)), ?caller));
                                                    };
                                                    
                                                    a_allocation;
                                                } else {
                                                    //nyi: here we would give some back, but we don't support shrining right now.
                                                    val;
                                                };
                                            };
                                        };

                                        debug if (debug_channel.library) D.print("ok allocation");
                                    };
                                    //nyi: if it is collection, should we check that it exists?
                                };
                            };
                            case(_){return #err(Types.errors(?state.canistergeekLogger,  #malformed_metadata, "stage_nft_origyn - library should be thawed", ?caller));};
                        };
                    };
                    case(_){return #err(Types.errors(?state.canistergeekLogger,  #malformed_metadata, "stage_nft_origyn - library should be an array", ?caller));};
                };

            };
        };

        return #ok("ok");

    };

    //mints an NFT
    public func mint_nft_origyn(state : Types.State, token_id : Text, new_owner : Types.Account, caller : Principal) : async* Result.Result<Text,Types.OrigynError> {
        if(NFTUtils.is_owner_manager_network(state, caller) == false){return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "mint_nft_origyn - not an owner", ?caller))};

        let result = execute_mint(state, token_id, new_owner, null, caller);

        //notify library canisters of metadata
        //warning: nyi: this needs to be moved to an async work flow as too many library canistes will overflow the cycle limit

        debug if (debug_channel.storage) D.print("mint done...handling library" # debug_show ((result)));
        switch (result) {
            case (#ok(data)) {
                debug if (debug_channel.storage) D.print("have data " # debug_show (data));
                let library = Metadata.get_nft_library_array(data.1, ?caller);
                switch (library) {
                    case (#err(err)) {};
                    case (#ok(library)) {
                        debug if (debug_channel.storage) D.print(debug_show (Iter.toArray(library.vals())));
                        for (this_library in library.vals()) {
                            //we look at each library and if it is on another server we need
                            //to let that server know about the new metadata for the NFT
                            let found = Map.new<Principal, Bool>();
                            debug if (debug_channel.storage) D.print("processing a library" # debug_show ((this_library, state.state.allocations)));
                            switch (Properties.getClassProperty(this_library, Types.metadata.library_id)) {
                                case (null) {
                                    //shouldnt be here
                                    debug if (debug_channel.storage) D.print("shouldnt be here");
                                };
                                case (?library_id) {
                                    debug if (debug_channel.storage) D.print(Conversions.valueToText(library_id.value));
                                    switch (Map.get(state.state.allocations, (NFTUtils.library_hash, NFTUtils.library_equal), (token_id, Conversions.valueToText(library_id.value)))) {
                                        case (null) {
                                            //shouldn't be here but won't fail
                                            debug if (debug_channel.storage) D.print("shouldnt be here null get");
                                        };
                                        case (?val) {
                                            if (val.canister != state.canister()) {
                                                debug if (debug_channel.storage) D.print("updating metadata for storage " # debug_show (val.canister) # debug_show (data.1));
                                                if (Map.get(found, Map.phash, val.canister) == null) {
                                                    let storage_actor : Types.StorageService = actor (Principal.toText(val.canister));
                                                    let storage_future = storage_actor.refresh_metadata_nft_origyn(token_id, data.1);
                                                    Map.set(found, Map.phash, val.canister, true);
                                                };
                                            } else {
                                                debug if (debug_channel.storage) D.print("didnt update storage" # debug_show ((val.canister, state.canister())));
                                            };
                                        };
                                    };
                                };
                            };

                        };
                    };
                };
                return #ok(data.0);
            };
            case (#err(err)) {
                return #err(err);
            };
        };
    };

    //stages the metadata of an nft
    //
    // Only owners, managers, or networks can stage
    //
    // Required Fields:
    // id - the id of the nft - a text field. We highly suggest a human readable token id in the form com.your_org.your_project.version or similar
    // primary_asset - a pointer to a library_id that is the default asset you would like to show when a user navigates to you nft
    //
    // Suggested Fields:
    // preview_asset - a pointer to a library_id that is the asset you would like gallaries, wallets, and marketplaces to show in a list.  For performance reasons you should keep this file small - defaults to the primary asset
    // experience_asset - a pointer to a library_id that is the asset you would like for the user to navigate to to best experience your NFT.usually an html page - defaults to the primary asset
    // hidden_asset - a pointer to a library_id that is the asset you want shown to non-owners before the item is minted = ie a radomizer gif.
    //
    // Illegal fields
    // __system - only the canister itself can manipulate the __system data node. An attempt to inject this should throw
    public func stage_nft_origyn(
        state : Types.State,
        metadata : CandyTypes.CandyValue,
        caller : Principal,
    ) : Result.Result<Text, Types.OrigynError> {
        debug if (debug_channel.stage) D.print("in stage");
        //only an owner can stage
        if(NFTUtils.is_owner_manager_network(state,caller) == false){return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "stage_nft_origyn - not an owner", ?caller))};

        //ensure id is in the class
        debug if (debug_channel.stage) D.print("looking for id");
        let id_val = Conversions.valueToText(
            switch(Properties.getClassProperty(metadata, "id")){
                case(null){
                    return #err(Types.errors(?state.canistergeekLogger,  #id_not_found_in_metadata, "stage_nft_origyn - find id", ?caller));
                };
                case (?found) {
                    found.value;
                };
            },
        );

        debug if (debug_channel.stage) D.print("id is " # id_val);

        debug if (debug_channel.stage) D.print("looking for system");
        //if this exists we should throw
        let found_system = switch(Properties.getClassProperty(metadata, Types.metadata.__system)){
            case(null){};
            case(?found){
                return #err(Types.errors(?state.canistergeekLogger,  #attempt_to_stage_system_data, "stage_nft_origyn - find system", ?caller));
            }
        };

        var found_metadata : CandyTypes.CandyValue = #Empty;
        //try to find existing metadata
        switch (Map.get(state.state.nft_metadata, Map.thash, id_val)) {
            case (null) {
                //D.print("Does not exist yet");
                //does not exist yet;
                //add status "staged"
                found_metadata := #Class(switch(Properties.updateProperties(Conversions.valueToProperties(metadata), [{name = Types.metadata.__system; mode=#Set(#Class([{name=Types.metadata.__system_status; value=#Text(Types.nft_status_staged); immutable = false}]))}])){
                    case(#err(errType)){
                        return #err(Types.errors(?state.canistergeekLogger,  #update_class_error, "stage_nft_origyn - set staged status", ?caller));
                    };
                    case(#ok(result)){
                        result;
                    }
                });
                                debug if(debug_channel.stage) D.print("we should have status now");
                                debug if(debug_channel.stage) D.print(debug_show(found_metadata));
                
                //adds and allocaates all the libray items
                switch (handle_library(state, id_val, found_metadata, caller)) {
                    case (#err(err)) {
                        return #err(err);
                    };
                    case (#ok(ok)) {};
                };

                Map.set(state.state.nft_metadata, Map.thash, id_val, found_metadata);
            };
            case (?this_metadata) {
                //exists
                debug if (debug_channel.stage) D.print("exists");
                //check to see if it is minted yet.Array
                let system_node : CandyTypes.CandyValue = switch(Properties.getClassProperty(this_metadata, Types.metadata.__system)){
                    case(null){return #err(Types.errors(?state.canistergeekLogger,  #cannot_find_status_in_metadata, "stage_nft_origyn - find system", ?caller));};
                    case(?found){found.value};
                };

                let status : Text = Conversions.valueToText(
                    switch(Properties.getClassProperty(system_node, Types.metadata.__system_status)){
                        case(null){return #err(Types.errors(?state.canistergeekLogger,  #cannot_find_status_in_metadata, "stage_nft_origyn - cannot find status", ?caller));};
                        case(?found){found.value};
                    });


                //nyi: limit to immutable items after mint
                if (Metadata.is_minted(this_metadata) == false) {
                    //this replaces the existing metadata with the new data.  It is not incremental

                    //pull __system vars
                    debug if (debug_channel.stage) D.print("dealing with 1==1");
                    switch (Properties.getClassProperty(this_metadata, Types.metadata.__system)) {
                        case (null) {
                            //this branch may be an error
                            return #err(Types.errors(?state.canistergeekLogger,  #improper_interface, "stage_nft_origyn - __system node not found", ?caller));
                        };
                        case (?found) {
                            //injects the existing __system vars into new metadata
                                            debug if(debug_channel.stage) D.print("updating metadata to include system");
                            found_metadata := #Class(switch(Properties.updateProperties(Conversions.valueToProperties(metadata), [{name = Types.metadata.__system; mode=#Set(found.value)}])){
                                case(#err(errType)){
                                    return #err(Types.errors(?state.canistergeekLogger,  #update_class_error, "stage_nft_origyn - set staged status", ?caller));
                                };
                                case(#ok(result)){
                                    result;
                                }
                            });
                        };
                    };

                    switch (handle_library(state, id_val, found_metadata, caller)) {
                        case (#err(err)) {
                            return #err(err);
                        };
                        case (#ok(ok)) {};
                    };

                    //swap metadata
                    Map.set(state.state.nft_metadata, Map.thash, id_val, found_metadata);
                    return #ok(id_val);
                } else {

                  //only an owner can stage
                  if(NFTUtils.is_owner_network(state,caller) == false){return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "stage_nft_origyn - not an owner", ?caller))};


                  //check to see if it is minted yet.Array
                  switch(Properties.getClassProperty(metadata, Types.metadata.__system)){
                      case(?found){return #err(Types.errors(?state.canistergeekLogger,  #malformed_metadata, "stage_nft_origyn - cannot stage system node", ?caller));};
                      case(null){};
                  };

                  switch(Properties.getClassProperty(metadata, Types.metadata.owner)){
                      case(?found){return #err(Types.errors(?state.canistergeekLogger,  #malformed_metadata, "stage_nft_origyn - cannot stage owner node after mint", ?caller));};
                      case(null){};
                  };

                  switch(Properties.getClassProperty(metadata, Types.metadata.library)){
                      case(?found){return #err(Types.errors(?state.canistergeekLogger,  #malformed_metadata, "stage_nft_origyn - cannot stage library node after mint, use stage_library_nft_origyn", ?caller));};
                      case(null){};
                  };

                  switch(Properties.getClassProperty(metadata, Types.metadata.__apps)){
                      case(?found){return #err(Types.errors(?state.canistergeekLogger,  #malformed_metadata, "stage_nft_origyn - cannot stage dapps after mint, use update_app_nft_origyn", ?caller));};
                      case(null){};
                  };

                  var new_metadata = this_metadata;

                  label update for(this_item in Conversions.valueToProperties(metadata).vals()){

                    if(this_item.name == Types.metadata.id){
                      continue update;
                    };
                    new_metadata := 
                      switch(
                        if(this_item.immutable == true){
                        Properties.updateProperties(Conversions.valueToProperties(new_metadata), [
                          {
                            name = this_item.name;
                            mode = #Lock(this_item.value);
                          }
                        ]);
                      } else {
                        Properties.updateProperties(Conversions.valueToProperties(new_metadata), [
                          {
                            name = this_item.name;
                            mode = #Set(this_item.value);
                          }
                        ]);
                      }
                      ){
                        case(#ok(props)){
                          #Class(props);
                        };
                        case(#err(err)){
                          return #err(Types.errors(?state.canistergeekLogger,  #update_class_error, "stage_nft_origyn - bad update " # this_item.name # " " #debug_show(err), ?caller));
                        }
                      };
                  };

                  Map.set(state.state.nft_metadata, Map.thash, id_val, new_metadata);
                };
            };
        };
        return #ok(id_val);
    };

    //stages a chunk of a library
    // limited to 2MB in size.
    //
    public func stage_library_nft_origyn(
        state : Types.State,
        chunk : Types.StageChunkArg,
        caller : Principal,
    ) : Result.Result<Types.LocalStageLibraryResponse, Types.OrigynError> {

        //todo: add ability for nfto owner to upload files to an nft.
        if(NFTUtils.is_owner_manager_network(state,caller) == false){return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "stage_library_nft_origyn - not an owner", ?caller))};
                        debug if(debug_channel.stage) D.print("in stage_library_nft_origyn" # debug_show(chunk));
        var b_updated_meta = false;
        let content_size = chunk.content.size();
        var metadata = switch(Metadata.get_metadata_for_token(state, chunk.token_id, caller, ?state.canister(), state.state.collection_data.owner)){
            case(#err(err)){
                return #err(Types.errors(?state.canistergeekLogger,  err.error, "stage_library_nft_origyn " # err.flag_point, ?caller));
            };
            case (#ok(val)) {
                val;
            };
        };

        let library_meta = switch (Metadata.get_library_meta(metadata, chunk.library_id)) {
            case (#ok(found)) {
                found;
            };
            case (#err(err)) {
                chunk.filedata;
            };
        };
                        debug if(debug_channel.stage) D.print("found library meta" # debug_show(library_meta));
        

        let system_node : CandyTypes.CandyValue = switch(Properties.getClassProperty(metadata, Types.metadata.__system)){
                    case(null){return #err(Types.errors(?state.canistergeekLogger,  #cannot_find_status_in_metadata, "stage_nft_origyn - find system", ?caller));};
                    case(?found){found.value};
                };


        debug if(debug_channel.stage) D.print("looking for  status " # debug_show(system_node));
        

        let status : Text = Conversions.valueToText(
            switch (Properties.getClassProperty(system_node, Types.metadata.__system_status)) {
                case (null) { #Text("staged") }; //default
                case (?found) { found.value };
            },
        );

        debug if (debug_channel.stage) D.print("found status " # debug_show (status));

        let immutable_library_metadata = switch (Properties.getClassProperty(library_meta, Types.metadata.immutable_library)) {
            case (null) { false };
            case (?val) {
                switch (val.value) {
                    case (#Bool(id)) {
                        id;
                    };
                    case (_) {
                        false;
                    };
                };
            };
        };

        debug if (debug_channel.stage) D.print("found immutable_library_metadata " # debug_show (immutable_library_metadata));

        let bDelete : Bool = switch (chunk.filedata) {
            case (#Bool(val)) {
                if (val == false) {
                    true;
                } else {
                    false;
                };
            };
            case(_){
              false;
            };
        };

        let bUpdate : CandyTypes.Properties = switch(chunk.filedata){
            case(#Class(val)){
              val;
            };
            case(_){
              [];
            };
        };

        if(bUpdate.size() > 0 or bDelete){
                              debug if(debug_channel.stage) D.print("checking filedata" # debug_show(chunk.filedata));
          //update this library's metadata
          //confirm library_id
          let library_id = switch(Properties.getClassProperty(chunk.filedata, Types.metadata.library_id)){
              case(null){
                  if(bUpdate.size() > 0){
                                      debug if(debug_channel.stage) D.print("library not found");
                    return #err(Types.errors(?state.canistergeekLogger,  #library_not_found, "stage_nft_origyn - provided filedata must be a class with library_id attribute", ?caller));
                  } else {
                    chunk.library_id;
                  };
              };
              case(?id){
                  switch(id.value){
                      case(#Text(id)){

                          if(id != chunk.library_id){
                            return #err(Types.errors(?state.canistergeekLogger,  #malformed_metadata, "stage_nft_origyn - library_id in metadata does not match chunk", ?caller));
                          };
                          id;
                      };
                      case(_){
                          return #err(Types.errors(?state.canistergeekLogger,  #library_not_found, "stage_library_nft_origyn - provided filedata must be a claass with library_id as #Text attribute", ?caller));
                      
                      };
                  }
              };
          };

          let new_library = Buffer.Buffer<CandyTypes.CandyValue>(1);
          var b_found = false;

                              debug if(debug_channel.stage) D.print("rebuilding" # debug_show(Metadata.get_nft_library(metadata, ?caller)));

          let library = switch(Metadata.get_nft_library(metadata, ?caller)){
              case(#err(err)){
                  //nyi: add libraries after minting
                  return #err(Types.errors(?state.canistergeekLogger,  #library_not_found, "stage_library_nft_origyn - cannot find library"  # err.flag_point, ?caller));
                      
              };
              case(#ok(val)){val};
          };

                              debug if(debug_channel.stage) D.print("current library " # debug_show(library));

          
          label rebuild for(this_item in Conversions.valueToValueArray(library).vals()){
                                  debug if(debug_channel.stage) D.print("handling rebuild for " # debug_show(this_item));
              switch(Properties.getClassProperty(this_item, Types.metadata.library_id)){
                  case(null){
                      //shouldn't be here
                      //D.print("shouldnt be here");
                  };
                  case(?id){

                      

                                      debug if(debug_channel.stage) D.print(debug_show((id, library_id)));
                      if(Conversions.valueToText(id.value) == library_id){
                        if(immutable_library_metadata == true and status == "minted"){
                          return #err(Types.errors(?state.canistergeekLogger,  #update_class_error, "stage_library_nft_origyn - cannot update immutable library", ?caller));
                        };
                          
                                          debug if(debug_channel.stage) D.print("replaceing with filechunk");
                        if(bDelete == true){

                        } else {
                          new_library.add(chunk.filedata);
                        };
                          b_found := true;
                          

                          //break rebuild;
                      }else{
                                          debug if(debug_channel.stage) D.print("keeping library");
                          new_library.add(this_item);
                      };
                  };
                  
              };
          };

                          debug if(debug_channel.stage) D.print("did we find it?" # debug_show(b_found));

          if(b_found == false){
              new_library.add(chunk.filedata);
          };


          var found_metadata = #Class(switch(Properties.updateProperties(Conversions.valueToProperties(metadata), [{name = Types.metadata.library; mode=#Set(#Array(#thawed(Buffer.toArray(new_library))))}])){
              case(#err(errType)){
                  switch(errType){
                      case(_){
                          return #err(Types.errors(?state.canistergeekLogger,  #update_class_error, "stage_library_nft_origyn - cannot update" # debug_show(errType), ?caller));
                      };
                  };
              };
              case(#ok(result)){
                  result;
              };
          });

                          debug if(debug_channel.stage) D.print("new metadata is " # debug_show(found_metadata));

          metadata := found_metadata;

                          debug if(debug_channel.stage) D.print("handling library");
          switch(handle_library(state, chunk.token_id , metadata, caller)){
              case(#err(err)){
                  return #err(err);
              };
              case(#ok(ok)){};
          };

          b_updated_meta := true;
        };

        debug if (debug_channel.stage) D.print("checking allocation" # debug_show ((chunk.token_id, chunk.library_id)));

        //swap metadata
        debug if (debug_channel.stage) D.print("is metadata updated " # debug_show (b_updated_meta));
        if (b_updated_meta) {
            Map.set(state.state.nft_metadata, Map.thash, chunk.token_id, metadata);
        };

        if(chunk.content.size() > 0){

          //make sure we have an allocation space for this chunk
          let allocation = switch(Map.get<(Text, Text), Types.AllocationRecord>(state.state.allocations, (NFTUtils.library_hash, NFTUtils.library_equal), (chunk.token_id, chunk.library_id))){
              case(null){return #err(Types.errors(?state.canistergeekLogger,  #not_enough_storage, "stage_library_nft_origyn - allocation not found for " # chunk.token_id # " " # chunk.library_id, ?caller));};
              case(?val)(val);
          };

          
              

                                  debug if(debug_channel.stage) D.print("found allocation " # debug_show(allocation));

          if( allocation.canister == state.canister()){
              //the chunk goes on this canister

                              debug if(debug_channel.stage) D.print("looking for workspace");
              var found_workspace : CandyTypes.Workspace =
                  switch(state.nft_library.get(chunk.token_id)){
                      case(null){
                          if(bDelete == true or content_size == 0){
                            //this was never allocated; return;
                            return #ok(#staged(state.canister()));
                          };
                          //chunk doesn't exist;
                                          debug if(debug_channel.stage) D.print("does not exist");
                          let new_workspace = Workspace.initWorkspace(2);
                                          debug if(debug_channel.stage) D.print("puting Zone");
                                          debug if(debug_channel.stage) D.print(debug_show(chunk.filedata));
                          
                          if(content_size > allocation.available_space){
                                                  debug if(debug_channel.stage) D.print("not enough storage in allocation null library " # debug_show(chunk.token_id, chunk.library_id, content_size,allocation.available_space));
                              return #err(Types.errors(?state.canistergeekLogger,  #not_enough_storage, "stage_library_nft_origyn - chunk bigger than available" # chunk.token_id # " " # chunk.library_id, ?caller));
                          };
                          
                          new_workspace.add(Workspace.initDataZone(CandyTypes.destabalizeValue(chunk.filedata)));

                                          debug if(debug_channel.stage) D.print("put the zone");
                          let new_library = TrieMap.TrieMap<Text, CandyTypes.Workspace>(Text.equal,Text.hash);
                                          debug if(debug_channel.stage) D.print("putting workspace");
                          new_library.put(chunk.library_id, new_workspace);
                                          debug if(debug_channel.stage) D.print("putting library");
                          state.nft_library.put(chunk.token_id, new_library);
                          new_workspace;
                      };
                      case(?library){
                          
                          switch(library.get(chunk.library_id)){
                              case(null){
                                  if(bDelete == true or content_size == 0){
                                    //this was never allocated; return;
                                    return #ok(#staged(state.canister()));
                                  };
                                                  debug if(debug_channel.stage) D.print("nft exists but not file");
                                  //nft exists but this file librry entry doesnt exist
                                  //nftdoesn't exist;
                                  if(content_size > allocation.available_space){
                                                          debug if(debug_channel.stage) D.print("not enough storage in allocation not null" # debug_show(chunk.token_id, chunk.library_id, content_size,allocation.available_space));
                                      return #err(Types.errors(?state.canistergeekLogger,  #not_enough_storage, "stage_library_nft_origyn - chunk bigger than available" # chunk.token_id # " " # chunk.library_id, ?caller));
                                  };
                                  let new_workspace = Workspace.initWorkspace(2);

                                  new_workspace.add(Workspace.initDataZone(CandyTypes.destabalizeValue(chunk.filedata)));


                                  library.put(chunk.library_id, new_workspace);
                                  new_workspace;
                              };
                              case(?workspace){
                                  if(bDelete == true){
                                    library.delete(chunk.library_id);
                                  };
                                                  debug if(debug_channel.stage) D.print("found workspace");
                                  workspace;
                              };
                          };
                          

                      };
                  };


              if(bDelete == true){

                //give all the space back
                state.state.canister_availible_space += allocation.allocated_space;
                allocation.available_space += allocation.allocated_space;
                state.state.collection_data.available_space += allocation.allocated_space;
                
                Map.delete<(Text, Text), Types.AllocationRecord>(state.state.allocations, (NFTUtils.library_hash, NFTUtils.library_equal), (chunk.token_id, chunk.library_id));
                //Map.delete<(Text, Text), Types.AllocationRecord>(state.state.allocations, (NFTUtils.library_hash, NFTUtils.library_equal), (chunk.token_id, chunk.library_id));
                return #ok(#staged(state.canister()));
              } else {
                //file the chunk
                if(chunk.content.size() > 0){
                  debug if(debug_channel.stage) D.print("filing the chunk");
                  let file_chunks = switch(found_workspace.getOpt(1)){
                      case(null){
                          if(found_workspace.size()==0){
                              //nyi: should be an error because no filedata
                              found_workspace.add(Workspace.initDataZone(#Empty));
                          };
                          if(found_workspace.size()==1){
                              found_workspace.add(Buffer.Buffer<CandyTypes.DataChunk>(0));
                          };
                          found_workspace.get(1);
                      };
                      case(?dz){
                          dz;
                      };
                  };

                  debug if(debug_channel.stage) D.print("have the chunks zone");

                  let size_chunks = switch(found_workspace.getOpt(2)){
                      case(null){
                          if(found_workspace.size()==0){
                              //nyi: should be an error because no filedata
                              found_workspace.add(Workspace.initDataZone(#Empty));
                          };
                          if(found_workspace.size()==1){
                              found_workspace.add(Buffer.Buffer<CandyTypes.DataChunk>(0));
                          };
                          if(found_workspace.size()==2){
                              found_workspace.add(Buffer.Buffer<CandyTypes.DataChunk>(0));
                          };
                          found_workspace.get(2);
                      };
                      case(?dz){
                          dz;
                      };
                  };

                  debug if(debug_channel.stage) D.print("have the size zone");

                  debug if(debug_channel.stage) D.print("do we have chunks");
                  if(chunk.chunk + 1 <= SB.size<Nat>(allocation.chunks)){
                      //this chunk already exists in the allocation
                      //see what size it is
                                      debug if(debug_channel.stage) D.print("branch a");
                      let current_size = SB.get<Nat>(allocation.chunks,chunk.chunk);
                      if(content_size > current_size){
                          //allocate more space
                                          debug if(debug_channel.stage) D.print("allocate more");
                          SB.put<Nat>(allocation.chunks, chunk.chunk, content_size);
                          if(allocation.available_space >= Nat.sub(content_size, current_size)){
                            allocation.available_space -= Nat.sub(content_size, current_size);
                          } else {
                            return #err(Types.errors(?state.canistergeekLogger,  #storage_configuration_error, "stage_library_nft_origyn - already exists - allocation.available_space >= (content_size - current_size)" # debug_show((allocation.available_space, content_size, current_size)), ?caller));
                          };
                      } else if (content_size >= current_size){
                          //give space back
                                              debug if(debug_channel.stage) D.print("give space back");
                          SB.put<Nat>(allocation.chunks, chunk.chunk, content_size);
                          allocation.available_space += (current_size - content_size);
                      } else {};
                  } else {
                      //D.print("branch b ");
                      for(this_index in Iter.range(SB.size<Nat>(allocation.chunks), chunk.chunk)){
                          //D.print(debug_show(this_index));
                          if(this_index == chunk.chunk){
                              if(content_size > allocation.available_space){
                                                      debug if(debug_channel.stage) D.print("not enough storage in allocation not branch b" # debug_show(chunk.token_id, chunk.library_id, content_size,allocation.available_space));
                                          
                                  return #err(Types.errors(?state.canistergeekLogger,  #not_enough_storage, "stage_library_nft_origyn - chunk bigger than available past workspace" # chunk.token_id # " " # chunk.library_id, ?caller));
                              };
                              
                                                  debug if(debug_channel.stage) D.print("branch c" # debug_show(allocation, content_size));
                              SB.add<Nat>(allocation.chunks, content_size);

                              if(allocation.available_space >= content_size){
                                allocation.available_space -= content_size;
                              } else {
                                return #err(Types.errors(?state.canistergeekLogger,  #storage_configuration_error, "stage_library_nft_origyn - allocation loop - allocation.available_space >= content_size" # debug_show((allocation.available_space, content_size)), ?caller));
                              };
                              
                          } else {
                              //D.print("brac d");
                              SB.add<Nat>(allocation.chunks, 0);
                          }
                      };
                  };

                  // We need the following code to create unique keys for stablebtree
                        var tokenId = "";
                        var lib = "";

                        if (chunk.token_id == "") {
                            tokenId #= "none";
                        } else {
                            tokenId #= chunk.token_id;
                        };
                        if (chunk.library_id == "") {
                            lib #= "none";
                        } else {
                            lib #= chunk.library_id;
                        };
                        /////////////////////////////////////////////

                        D.print("putting the chunk");
                        if (chunk.chunk + 1 <= file_chunks.size()) {
                            if (state.state.use_stableBTree) {
                                 D.print("token:" # tokenId # "/library:" # lib # "/index:none"  # "/chunk:" # Nat.toText(chunk.chunk));
                                let btreeKey = Text.hash("token:" # tokenId # "/library:" # lib # "/index:none" # "/chunk:" # Nat.toText(chunk.chunk));
                                 D.print(debug_show(btreeKey));
                                let insertBtree = NFTUtils.getMemoryBySize(chunk.content.size(), state.btreemap).insert(btreeKey, Blob.toArray(chunk.content));
                                file_chunks.add(#Nat32(btreeKey));
                                size_chunks.add(#Nat(chunk.content.size()))
                            } else {
                                file_chunks.put(chunk.chunk, #Blob(chunk.content));
                                size_chunks.add(#Nat(chunk.content.size()))
                            };

                        } else {
                            debug if (debug_channel.stage) D.print("in putting the chunk iter");
                            debug if (debug_channel.stage) D.print(debug_show (chunk.chunk));
                            //D.print(debug_show(file_chunks.size()));

                            for (this_index in Iter.range(file_chunks.size(), chunk.chunk)) {
                                D.print(debug_show(this_index));
                                let btreeKey = Text.hash("token:" # tokenId # "/library:" # lib # "/index:" # Nat.toText(this_index) # "/chunk:" # Nat.toText(chunk.chunk));

                                if (this_index == chunk.chunk) {
                                    D.print("index was chunk" # debug_show(this_index));

                                    // If flag use_stable is true we insert Blobs into stablebtree
                                    if (state.state.use_stableBTree) {
                                        // D.print("#level 1");
                                        // D.print("token:" # tokenId # "/library:" # lib # "/index:" # Nat.toText(this_index) # "/chunk:" # Nat.toText(chunk.chunk));
                                        // D.print(debug_show(btreeKey));
                                        let insertBtree = NFTUtils.getMemoryBySize(chunk.content.size(), state.btreemap).insert(btreeKey, Blob.toArray(chunk.content));
                                        file_chunks.add(#Nat32(btreeKey));
                                        size_chunks.add(#Nat(chunk.content.size()))
                                    } else {
                                        file_chunks.add(#Blob(chunk.content));
                                        size_chunks.add(#Nat(chunk.content.size()))
                                    };
                                } else {
                                    D.print("index wasnt chunk" # debug_show(this_index));
                                    if (state.state.use_stableBTree) {
                                        D.print("#level 2");
                                        D.print("token:" # tokenId # "/library:" # lib # "/index:" # Nat.toText(this_index) # "/chunk:" # Nat.toText(chunk.chunk));
                                        let insertBtree = NFTUtils.getMemoryBySize(0, state.btreemap).insert(btreeKey, []);
                                        
                                        file_chunks.add(#Nat32(btreeKey));
                                        size_chunks.add(#Nat(chunk.content.size()))
                                    } else {
                                        file_chunks.add(#Blob(Blob.fromArray([])));
                                        size_chunks.add(#Nat(0))
                                    };
                                };
                            };

                        };
                    };

                    //D.print("returning");
                    return #ok(#staged(state.canister()));
                };

            } else {
                //we need to send this chunk to storage
                //D.print("This needs to be filed elsewhere " # debug_show(allocation));
                if (bDelete == true) {
                    switch (Map.get<Principal, Types.BucketData>(state.state.buckets, Map.phash, allocation.canister)) {
                        case (?aBucket) {
                            aBucket.available_space += allocation.allocated_space;
                            //aBucket.allocated_space -= allocation.allocated_space;
                        };
                        case (null) {};
                    };
                    Map.delete<(Text, Text), Types.AllocationRecord>(state.state.allocations, (NFTUtils.library_hash, NFTUtils.library_equal), (chunk.token_id, chunk.library_id));
                    switch (state.nft_library.get(chunk.token_id)) {
                        case (null) {};
                        case (?library) {
                            library.delete(chunk.library_id);
                        };
                    };

                };
                return #ok(#stage_remote({ allocation = allocation; metadata = metadata }));
            };
        } else {
            return #ok(#staged(state.canister()));
        };

    };

    //sends the file chunk to remote storage
    public func stage_library_nft_origyn_remote(
        state : Types.State,
        chunk : Types.StageChunkArg,
        allocation : Types.AllocationRecord,
        metadata : CandyTypes.CandyValue,
        caller : Principal,
    ) : async* Result.Result<Types.StageLibraryResponse, Types.OrigynError> {

        debug if (debug_channel.remote) D.print("we have an allocationin the remote" # debug_show ((allocation, metadata)));

        //we shouldn't need to pre remove the space because the allocation was already made
        let content_size = chunk.content.size();
        let storage_actor : Types.StorageService = actor (Principal.toText(allocation.canister));
        let response = await storage_actor.stage_library_nft_origyn(chunk, Types.allocation_record_stabalize(allocation), (if (chunk.chunk == 0) { metadata } else { #Empty }));

        debug if (debug_channel.remote) D.print("allocation to remot result" # debug_show (response));

        switch (response) {
            case (#ok(result)) {
                //update the allocation
                //keep in mind the allocation passed to us is no longer the correct one.Buffer
                let refresh_state = state.refresh_state();

                var fresh_allocation = switch(Map.get<(Text, Text), Types.AllocationRecord>(refresh_state.state.allocations, (NFTUtils.library_hash, NFTUtils.library_equal), (chunk.token_id, chunk.library_id))){
                    case(null){return #err(Types.errors(?state.canistergeekLogger,  #not_enough_storage, "stage_library_nft_origyn_remote - allocation not found for " # chunk.token_id # " " # chunk.library_id, ?caller));};
                    case(?val)(val);
                };

                //make sure we have an allocation for space for this chunk

                if (chunk.chunk + 1 <= SB.size<Nat>(fresh_allocation.chunks)) {
                    //this chunk already exists in the allocation
                    //see what size it is
                    let current_size = SB.get<Nat>(allocation.chunks, chunk.chunk);
                    if (content_size > current_size) {
                        //allocate more space

                        SB.put<Nat>(fresh_allocation.chunks, chunk.chunk, content_size);
                        fresh_allocation.available_space += (content_size - current_size);
                    } else if (content_size != current_size) {
                        //give space back
                        SB.put<Nat>(fresh_allocation.chunks, chunk.chunk, content_size);
                        if (fresh_allocation.available_space >= Nat.sub(current_size, content_size)) {
                            fresh_allocation.available_space -= Nat.sub(current_size, content_size);
                        } else {
                            return #err(Types.errors(?state.canistergeekLogger, #storage_configuration_error, "stage_library_nft_origyn - gateway - fresh_allocation.available_space -= (current_size - content_size)" # debug_show ((fresh_allocation.available_space, current_size, content_size)), ?caller));
                        };

                    } else {};
                } else {
                    for (this_index in Iter.range(SB.size<Nat>(fresh_allocation.chunks), chunk.chunk)) {
                        if (this_index == chunk.chunk) {
                            SB.add<Nat>(fresh_allocation.chunks, content_size);
                            fresh_allocation.available_space += content_size;
                        } else {
                            SB.add<Nat>(fresh_allocation.chunks, 0);
                        };
                    };
                };
            };
            case (#err(err)) {
                return #err(err);
            };
        };
        return response;

    };

    //executes the mint and gives owner ship to the specified user
    public func execute_mint(state : Types.State, token_id : Text, newOwner : Types.Account, escrow : ?Types.EscrowReceipt, caller : Principal) : Result.Result<(Text, CandyTypes.CandyValue, Types.TransactionRecord), Types.OrigynError> {
        debug if (debug_channel.mint) D.print("in mint");
        var metadata = switch (Metadata.get_metadata_for_token(state, token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
            case (#err(err)) {
                return #err(Types.errors(?state.canistergeekLogger, #token_not_found, "execute_mint " # err.flag_point, ?caller));
            };
            case (#ok(val)) {
                val;
            };
        };

        let owner : Types.Account = switch (Metadata.get_nft_owner(metadata)) {
            case (#err(err)) {
                //default is the canister
                #principal(state.canister());
            };
            case (#ok(val)) {
                val;
            };
        };

        //cant mint if already minted
        if (Metadata.is_minted(metadata)) {
            return #err(Types.errors(?state.canistergeekLogger, #item_already_minted, "execute_mint - already minted", ?caller));
        };
        metadata := Metadata.set_system_var(metadata, Types.metadata.__system_status, #Text("minted"));

        D.print("should have set metadata to minted");

        //copy physical value to system
        switch (Metadata.get_nft_bool_property(metadata, Types.metadata.physical)) {
            case (#err(err)) {
                //no physical value...do nothing
            };
            case (#ok(p)) {
                if (p == true) {
                    //physical items cannot currently participate in markets unless they are escrowed with a node
                    metadata := Metadata.set_system_var(metadata, Types.metadata.__system_physical, #Bool(true));
                } else {
                    //do nothing
                };
            };
        };

        //get the royalties
        //nyi: should ask the network for the network royalty and node royalty

        var collection = switch (Metadata.get_metadata_for_token(state, "", caller, ?state.canister(), state.state.collection_data.owner)) {
            case (#err(err)) {
                #Class([]);
            };
            case (#ok(val)) {
                val;
            };
        };

        var primary_royalties = switch (Properties.getClassProperty(collection, Types.metadata.primary_royalties_default)) {
            case (null) #Array(#frozen([]));
            case (?val) val.value;
        };

        metadata := Metadata.set_system_var(metadata, Types.metadata.__system_primary_royalty, primary_royalties);

        var secondary_royalties = switch (Properties.getClassProperty(collection, Types.metadata.secondary_royalties_default)) {
            case (null) #Array(#frozen([]));
            case (?val) val.value;
        };

        metadata := Metadata.set_system_var(metadata, Types.metadata.__system_secondary_royalty, secondary_royalties);

        var node_principal = switch (Properties.getClassProperty(collection, Types.metadata.__system_node)) {
            case (null) {
                #Principal(Principal.fromText("yfhhd-7eebr-axyvl-35zkt-z6mp7-hnz7a-xuiux-wo5jf-rslf7-65cqd-cae")); //dev fund
            };
            case (?val) {
                val.value;
            };
        };

        metadata := Metadata.set_system_var(metadata, Types.metadata.__system_node, node_principal);

        var originator_principal = switch (Properties.getClassProperty(metadata, Types.metadata.originator_override)) {
            case (null) {
                switch (Properties.getClassProperty(collection, Types.metadata.__system_originator)) {
                    case (null) {
                        #Principal(Principal.fromText("yfhhd-7eebr-axyvl-35zkt-z6mp7-hnz7a-xuiux-wo5jf-rslf7-65cqd-cae")); //dev fund
                    };
                    case (?val) {
                        val.value;
                    };
                };
            };
            case (?val) val.value;
        };

        metadata := Metadata.set_system_var(metadata, Types.metadata.__system_originator, originator_principal);

        //set new owner
        metadata := switch (
            Properties.updateProperties(
                Conversions.valueToProperties(metadata),
                [
                    {
                        name = Types.metadata.owner;
                        mode = #Set(
                            switch (newOwner) {
                                case (#principal(newOwner)) {
                                    #Principal(newOwner);
                                };
                                case (#account_id(newOwner)) { #Text(newOwner) };
                                case (#extensible(newOwner)) { newOwner };
                                case (#account(buyer)) {
                                    #Array(#frozen([#Principal(buyer.owner), #Option(switch (buyer.sub_account) { case (null) { null }; case (?val) { ?#Blob(val) } })]));
                                };
                            },
                        );
                    },
                ],
            ),
        ) {
            case (#ok(props)) {
                #Class(props);
            };
            case (#err(err)) {
                //maybe the owner is immutable
                switch(Metadata.is_nft_owner(metadata, newOwner)){
                    case(#err(err)){
                        return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "mint_nft_origyn retrieve owner " # err.flag_point, ?caller));
                    };
                    case (#ok(val)) {

                        if (val == false) {
                            //tried to set an immutable owner;
                            return #err(Types.errors(?state.canistergeekLogger,  #update_class_error, "mint_nft_origyn - error setting owner " # token_id, ?caller));
                        };
                        //owner will be left the same as the immutable
                        metadata;
                    };
                };
            };
        };

        //need to add the mint transaction record here
        let txn_record = switch (
            Metadata.add_transaction_record(
                state,
                {
                    token_id = token_id;
                    index = 0; //mint should always be 0
                    txn_type = #mint({
                        from = owner;
                        to = newOwner;
                        sale = switch (escrow) {
                            case (null) { null };
                            case (?val) {

                                ?{
                                    token = val.token;
                                    amount = val.amount;
                                }

                            };
                        };
                        extensible = #Class([{
                            name = "caller";
                            value = #Principal(caller);
                            immutable = true;
                        }]);
                    });
                    timestamp = Time.now();
                    chain_hash = [];
                },
                caller,
            ),
        ) {
            case (#err(err)) {
                //potentially big error once certified data is in place...may need to throw
                return #err(Types.errors(?state.canistergeekLogger,  err.error, "mint_nft_origyn add_transaction_record" # err.flag_point, ?caller));
            };
            case (#ok(val)) { val };
        };

        Map.set(state.state.nft_metadata, Map.thash, token_id, metadata);

        return #ok((token_id, metadata, txn_record));
    };

};
