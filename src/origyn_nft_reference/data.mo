import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Array "mo:base/Array";

import Metadata "metadata";
import MigrationTypes "./migrations/types";
import Types "types";

import Market "market";
import NFTUtils "utils";

module {
  let Map = MigrationTypes.Current.Map;
  let Conversions = MigrationTypes.Current.Conversions;
  let Properties = MigrationTypes.Current.Properties;
  let CandyTypes = MigrationTypes.Current.CandyTypes;

  let debug_channel = {
    function_announce = false;
    data_access = false;
  };

  //gets a text attribute out of a class - maybe refactor with Metadata.get_nft_text_property
  private func _get_text_attribute_from_class(this_item : CandyTypes.CandyShared, name : Text) : ?Text {
    return switch (Properties.getClassPropertyShared(this_item, name)) {
      case (null) {
        return null;
      };
      case (?val) {
        return ?Conversions.propertySharedToText(val);
      };
    };
  };

  public func update_metadata_node(state : Types.State, request : Types.NFTUpdateMetadataNode, caller : Principal) : async* Types.NFTUpdateAppResult {
    let _critical_fields = [
      Types.metadata.__system_physical,
      Types.metadata.__system_escrowed,
    ];

    let _updatable_fields = [
      Types.metadata.__system_physical,
      Types.metadata.__system_escrowed,
    ];

    var collection = switch (Metadata.get_metadata_for_token(state, "", caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) {
        return #err(Types.errors(#content_not_found, "update_metadata_node - failed to load collection metadata", ?caller));
      };
      case (#ok(val)) {
        val;
      };
    };

    let node_principal = switch (Properties.getClassPropertyShared(collection, Types.metadata.__system_node)) {
      case (null) {
        return #err(Types.errors(#content_not_found, "update_metadata_node - failed to load collection metadata", ?caller));
      };
      case (?val) {
        switch (val.value) {
          case (#Principal(val)) {
            val;
          };
          case (_) {
            return #err(Types.errors(#content_not_found, "update_metadata_node - failed to load collection metadata", ?caller));
          };
        };
      };
    };

    D.print("node_principal " # debug_show (node_principal));

    if (caller != node_principal) {
      return #err(Types.errors(#content_not_found, "update_metadata_node - only node principal can call this method", ?caller));
    };

    if (Array.find<Text>(_updatable_fields, func x = x == request.field_id) == null) {
      return #err(Types.errors(#content_not_found, "update_metadata_node - field not updatable. You can update : " #debug_show (_updatable_fields), ?caller));
    };

    var token_metadata = switch (Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) {
        return #err(Types.errors(#content_not_found, "update_metadata_node - failed to load token metadata", ?caller));
      };
      case (#ok(val)) {
        val;
      };
    };

    var obj_loaded = if (request._system == true) {
      Properties.getClassPropertyShared(token_metadata, Types.metadata.__system);
    } else {
      Properties.getClassPropertyShared(token_metadata, Types.metadata.__apps);
    };

    var obj = switch (obj_loaded) {
      case (null) {
        return #err(Types.errors(#content_not_found, "update_metadata_node - failed to load metadata node", ?caller));
      };
      case (?val) {
        val;
      };
    };

    if (Array.find<Text>(_critical_fields, func x = x == request.field_id) != null) {
      switch (await* Market.end_sale_nft_origyn(state, request.token_id, state.canister())) {
        case (#trappable(_)) {
          //do nothing
        };
        case (#awaited(_)) {
          //do nothing
        };
        case (#err(#trappable({ error = #sale_not_over }))) {
          return #err(Types.errors(#sale_not_over, "update_metadata_node - open sale pending for this nft, and field is critical", ?caller));
        };
        case (#err(#trappable({ error = #sale_not_found }))) {
          //do nothing
        };
        case (#err(#trappable({ error = #auction_ended }))) {
          //do nothing
        };
        case (#err(#trappable(err))) {
          return #err(Types.errors(err.error, "update_metadata_node - trappable unknown error -" # debug_show (err), ?caller));
        };
        case (#err(#awaited(err))) {
          return #err(Types.errors(err.error, "update_metadata_node - awaited unknown error -" # debug_show (err), ?caller));
        };
      };
    };

    let field : ?CandyTypes.PropertyShared = switch (Properties.getClassPropertyShared(obj.value, request.field_id)) {
      case (null) { null };
      case (?val) {
        if (val.immutable == true) {
          return #err(Types.errors(#content_not_found, "update_metadata_node - field is immutable", ?caller));
        };
        ?val;
      };
    };

    D.print("request.value " # debug_show (request.value));

    let new_metadata = if (request._system == true) {
      Metadata.set_system_var(token_metadata, request.field_id, request.value);
    } else {
      Metadata.set_apps_var(token_metadata, request.field_id, request.value);
    };

    Map.set(state.state.nft_metadata, Map.thash, request.token_id, new_metadata);

    // update fields

    return (
      #ok({
        property_old = field;
        property_new = {
          name = request.field_id;
          value = request.value;
          immutable = false;
        };
      })
    );
  };

  //   public func update_collection_origyn(request : Types.CollectionUpdateRequest, state : Types.State, caller : Principal) : Types.UpdateCollectionResponse {
  //     if (state.state.collection_data.owner != caller) {
  //       return #err(Types.errors( #unauthorized_access, "update_app_collection_origyn - must own this collection", ?caller));
  //     };

  //     switch (state.state.collection_data.metadata) {
  //       case (?metadata) {
  //         let ?found = Properties.getClassPropertyShared(metadata, request.data.name);

  //         if (found != null and request.erase == false) {
  //           return #err(Types.errors( #content_not_found, "update_app_collection_origyn - value is present but erase set to false", ?caller));
  //         };

  //         let insert_result = Map.set(state.state.collection_data.metadata, Map.thash, token_id, request.data);

  //       };
  //       case (null) {
  //         return #err(Types.errors( #content_not_found, "update_collection_origyn - failed to load collection metadata", ?caller));
  //       };
  //     };
  //   };

  //   found_metadata := #Class(
  //     switch (Properties.updatePropertiesShared(Conversions.candySharedToProperties(collection), [{ name = details.app_id; mode = #Set(details.data) }])) {
  //       case (#err(errType)) {
  //         return #err(Types.errors( #update_class_error, "update_app_nft_origyn - set metadata status" # debug_show (errType), ?caller));
  //       };
  //       case (#ok(result)) { result };
  //     }
  //   );

  //   //swap metadata
  //   let insert_result = Map.set(state.state.collection_data, Map.thash, token_id, found_metadata);

  // };

  //ORIGYN NFTs have a simple database inside of them.  Apps can store data in a
  //reserved space that can have flexible permissions.  The apps can make it so
  //that only they can read the data and/or only they can write the data. They
  //can also grant write permissions to certain other principals via an allow list.
  //Currnelty the implementation is more like a structured notepad where you have to
  //write out the enter note each time.  Future versions will add granular access to
  //data per app.
  /**
  *  Updates an NFT's metadata with information about the app it belongs to.
  *  @param {Types.NFTUpdateRequest} request - The update request object containing the token ID and app ID to be updated.
  *  @param {Types.State} state - The current state of the Origyn canister.
  *  @param {Principal} caller - The principal of the caller making the update request.
  *  @returns {Types.NFTUpdateResult} - Returns a Result object containing either a Types.NFTUpdateResponse object or a Types.OrigynError object if an error occurs during the update process.
  *  @throws {Types.OrigynError} Throws an OrigynError if an error occurs during the update process.
  */
  public func update_app_nft_origyn(request : Types.NFTUpdateRequest, state : Types.State, caller : Principal) : Types.UpdateAppResponse {

    let (token_id, app_id) = switch (request) {
      case (#replace(details)) {
        //D.print(debug_show(details.data));
        //(details.token_id, Option.getMapped<CandyTypes.Property, Text>(Properties.getClassPropertyShared(details.data, "app_id"), propertyToText, return #err(Types.errors(  #app_id_not_found, "update_app_nft_origyn - cannnot find app id ", ? caller)) ))};
        let ?app_id = _get_text_attribute_from_class(details.data, Types.metadata.__apps_app_id) else {
          return #err(Types.errors(#token_not_found, "update_app_nft_origyn - cannnot find app_id", ?caller));
        };

        (details.token_id, app_id);
      };
      case (#update(details)) { (details.token_id, details.app_id) };
    };

    debug if (debug_channel.data_access) D.print("found token and app " # token_id # " " # app_id);

    var found_metadata : CandyTypes.CandyShared = #Option(null);

    //try to find existing metadata
    let ?this_metadata = Map.get(state.state.nft_metadata, Map.thash, token_id) else {
      return #err(Types.errors(#token_not_found, "update_app_nft_origyn - cannnot find token", ?caller));
    };

    //exists
    debug if (debug_channel.data_access) D.print("exists");

    //find the app
    let ?found = Properties.getClassPropertyShared(this_metadata, Types.metadata.__apps) else {
      return #err(Types.errors(#content_not_found, "update_app_nft_origyn - __apps node not found", ?caller));
    };

    debug if (debug_channel.data_access) D.print("found apps");

    let found_array = Conversions.candySharedToValueArray(found.value);
    let new_list = Buffer.Buffer<CandyTypes.CandyShared>(found_array.size());

    //this is currently a very ineffcient way of doing this. Once candy adds dicitionaries we should switch to that
    //currently we are rewriting the entire __apps section each time.

    var bFoundApp = false;
    for (this_item in found_array.vals()) {
      if (?app_id == _get_text_attribute_from_class(this_item, Types.metadata.__apps_app_id)) {
        debug if (debug_channel.data_access) D.print("got the app");
        bFoundApp := true;
        switch (request) {
          case (#replace(detail)) {
            debug if (debug_channel.data_access) D.print("this is replace");
            //we check to see if we have write rights
            let write_node = switch (Properties.getClassPropertyShared(this_item, "write")) {
              //nyi: create user story and test for missing read/write

              case (null) {
                return #err(Types.errors(#content_not_found, "update_app_nft_origyn - write node not found", ?caller));
              };
              case (?write_node) { write_node };
            };

            debug if (debug_channel.data_access) D.print("have the write node");

            switch (write_node.value) {
              case (#Text(write_detail)) {
                if (write_detail == "public") {
                  //nyi: anyone can write. Maybe an error?
                  return #err(Types.errors(#improper_interface, "update_app_nft_origyn - write node cannot be public - this isn't a bathroom stall", ?caller));
                } else if (write_detail == "nft_owner") {
                  if (Metadata.is_owner(this_metadata, #principal(caller)) == false) return #err(Types.errors(#unauthorized_access, "update_app_nft_origyn - write is nft_owner - must own this NFT", ?caller));
                } else if (write_detail == "collection_owner") {
                  if (state.state.collection_data.owner != caller) return #err(Types.errors(#unauthorized_access, "update_app_nft_origyn - write is nft_owner - must own this NFT", ?caller));
                } else {
                  return #err(Types.errors(#nyi, "update_app_nft_origyn - write node mal formed", ?caller));
                };
                new_list.add(detail.data);
              };
              case (#Class(write_detail)) {
                debug if (debug_channel.data_access) D.print("have write detail");
                let ?write_type = Properties.getClassPropertyShared(write_node.value, "type") else {
                  return #err(Types.errors(#nyi, "update_app_nft_origyn - type is null for write type", ?caller));
                };

                debug if (debug_channel.data_access) D.print("have write type");
                let #Text(write_type_detail) = write_type.value else {
                  return #err(Types.errors(#nyi, "update_app_nft_origyn - not in proper type of write type", ?caller));
                };

                debug if (debug_channel.data_access) D.print("have write type detial");
                if (write_type_detail != "allow") {
                  return #err(Types.errors(#nyi, "update_app_nft_origyn - only allow list and public implemented", ?caller));
                };

                let ?allow_list = Properties.getClassPropertyShared(write_node.value, "list") else {
                  return #err(Types.errors(#unauthorized_access, "update_app_nft_origyn - empty allow list", ?caller));
                };

                //debug if(debug_channel.data_access)D.print("have allow list");
                //debug if(debug_channel.data_access) D.print(debug_show(Conversion.candySharedToValueArray(allow_list.value)));

                var b_found = false;
                label search for (this_principal in Conversions.candySharedToValueArray(allow_list.value).vals()) {
                  //debug if(debug_channel.data_access) D.print(Principal.toText( caller));
                  if (caller == Conversions.candySharedToPrincipal(this_principal)) {
                    //we are allowed
                    debug if (debug_channel.data_access) D.print("found a match");
                    b_found := true;
                    break search;

                  };
                };

                // backup, collection owner always have access to the data
                if (state.state.collection_data.owner == caller) {
                  b_found := true;
                };

                if (b_found == false) {
                  return #err(Types.errors(#unauthorized_access, "update_app_nft_origyn - not in allow list", ?caller));
                };

                //do the replace
                new_list.add(detail.data);
              };
              case (_) {
                return #err(Types.errors(#nyi, "update_app_nft_origyn - not a class", ?caller));
              };
            };
          };
          case (#update(detail)) {
            return #err(Types.errors(#nyi, "update_app_nft_origyn - update not implemented", ?caller));
          };
        };
      } else {
        //not in the app yet
        new_list.add(this_item);
      };
    };

    if (bFoundApp == false) {

      //only the network, or collection owner can add a data node.
      if (
        NFTUtils.is_owner_network(state, caller) == false
        /* and (switch(Metadata.is_nft_owner(found_metadata, #Principal(caller))){
            case(#ok(val)) val;
            case(#err(err)) false;
        }) == false */
      ) {
        return #err(Types.errors(#unauthorized_access, "update_app_nft_origyn - only  network or collection owner can add a data dapp", ?caller));
      };

      switch (request) {
        case (#replace(detail)) {
          //this is a new item and needs to be added;

          //validate the data
          debug if (debug_channel.data_access) D.print("this is a new node");
          //we check to see if we have write rights
          let write_node = switch (Properties.getClassPropertyShared(detail.data, "write")) {
            //nyi: create user story and test for missing read/write

            case (null) {
              return #err(Types.errors(#content_not_found, "update_app_nft_origyn - write node not found", ?caller));
            };
            case (?write_node) { write_node };
          };

          let read_node = switch (Properties.getClassPropertyShared(detail.data, "read")) {
            //nyi: create user story and test for missing read/write

            case (null) {
              return #err(Types.errors(#content_not_found, "update_app_nft_origyn - read node not found", ?caller));
            };
            case (?write_node) { write_node };
          };

          let permission_node = switch (Properties.getClassPropertyShared(detail.data, "permissions")) {
            //nyi: create user story and test for missing read/write

            case (null) {
              return #err(Types.errors(#content_not_found, "update_app_nft_origyn - permissions node not found", ?caller));
            };
            case (?write_node) { write_node };
          };

          debug if (debug_channel.data_access) D.print("have the write node");

          switch (write_node.value) {
            case (#Text(write_detail)) {
              if (write_detail == "public") {
                //nyi: anyone can write. Maybe an error?
                return #err(Types.errors(#improper_interface, "update_app_nft_origyn - write node cannot be public - this isn't a bathroom stall", ?caller));
              } else if (write_detail == "nft_owner") {

              } else if (write_detail == "collection_owner") {

              } else {
                return #err(Types.errors(#nyi, "update_app_nft_origyn - write node mal formed", ?caller));
              };
              new_list.add(detail.data);
            };
            case (#Class(write_detail)) {
              debug if (debug_channel.data_access) D.print("have write detail");
              let ?write_type = Properties.getClassPropertyShared(write_node.value, "type") else {
                return #err(Types.errors(#nyi, "update_app_nft_origyn - type is null for write type", ?caller));
              };
              debug if (debug_channel.data_access) D.print("have write type");
              let #Text(write_type_detail) = write_type.value else {
                return #err(Types.errors(#nyi, "update_app_nft_origyn - not in proper type of write type", ?caller));
              };

              debug if (debug_channel.data_access) D.print("have write type detial");
              if (write_type_detail != "allow") {
                return #err(Types.errors(#nyi, "update_app_nft_origyn - only allow list and public implemented", ?caller));
              };
            };
            case (_) {
              return #err(Types.errors(#nyi, "update_app_nft_origyn - write node mal formed", ?caller));
            };
          };

          switch (read_node.value) {
            case (#Text(write_detail)) {
              if (write_detail == "public") {

              } else if (write_detail == "nft_owner") {

              } else if (write_detail == "collection_owner") {

              } else {
                return #err(Types.errors(#nyi, "update_app_nft_origyn - read node mal formed", ?caller));
              };
              new_list.add(detail.data);
            };
            case (#Class(write_detail)) {
              debug if (debug_channel.data_access) D.print("have read detail");
              let ?write_type = Properties.getClassPropertyShared(write_node.value, "type") else {
                return #err(Types.errors(#nyi, "update_app_nft_origyn - type is null for write type", ?caller));
              };
              debug if (debug_channel.data_access) D.print("have write type");
              let #Text(write_type_detail) = write_type.value else {
                return #err(Types.errors(#nyi, "update_app_nft_origyn - not in proper type of write type", ?caller));
              };

              debug if (debug_channel.data_access) D.print("have write type detial");
              if (write_type_detail != "allow") {
                return #err(Types.errors(#nyi, "update_app_nft_origyn - only allow list and public implemented", ?caller));
              };
            };
            case (_) {
              return #err(Types.errors(#nyi, "update_app_nft_origyn - read node mal formed", ?caller));
            };
          };

          switch (permission_node.value) {

            case (#Class(write_detail)) {
              debug if (debug_channel.data_access) D.print("have read detail");
              let ?write_type = Properties.getClassPropertyShared(write_node.value, "type") else {
                return #err(Types.errors(#nyi, "update_app_nft_origyn - type is null for write type", ?caller));
              };
              debug if (debug_channel.data_access) D.print("have write type");
              let #Text(write_type_detail) = write_type.value else {
                return #err(Types.errors(#nyi, "update_app_nft_origyn - not in proper type of write type", ?caller));
              };

              debug if (debug_channel.data_access) D.print("have write type detial");
              if (write_type_detail != "allow") {
                return #err(Types.errors(#nyi, "update_app_nft_origyn - only allow list and public implemented", ?caller));
              };
            };
            case (_) {
              return #err(Types.errors(#nyi, "update_app_nft_origyn - permission node mal formed", ?caller));
            };
          };

          new_list.add(detail.data);
        };
        case (_) {
          return #err(Types.errors(#nyi, "update_app_nft_origyn - only replace can add a node - mal formed", ?caller));
        };
      };

    };

    found_metadata := #Class(
      switch (Properties.updatePropertiesShared(Conversions.candySharedToProperties(this_metadata), [{ name = Types.metadata.__apps; mode = #Set(#Array(Buffer.toArray(new_list))) }])) {
        case (#err(errType)) {
          return #err(Types.errors(#update_class_error, "update_app_nft_origyn - set metadata status" # debug_show (errType), ?caller));
        };
        case (#ok(result)) { result };
      }
    );

    //swap metadata
    let insert_result = Map.set(state.state.nft_metadata, Map.thash, token_id, found_metadata);
    return #ok(true);
  };
};
