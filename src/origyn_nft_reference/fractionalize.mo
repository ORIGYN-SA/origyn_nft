import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Deque "mo:base/Deque";
import Error "mo:base/Error";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import TimerTool "mo:timer-tool";

import AccountIdentifier "mo:principalmo/AccountIdentifier";

import Map "mo:map/Map";
import Set "mo:map/Set";
import MapUtil "mo:map/utils";

import Star "mo:star/star";

import SHA256 "mo:crypto/SHA/SHA256";
import Metadata "metadata";
import Market "market";
import Cycles "mo:base/ExperimentalCycles";
import Interface "interface/ic-management-interface";
import Types "types";
import MigrationTypes "./migrations/types";
import NFTUtils "utils";

module {
  let debug_channel = {
    fractionalize = false;
  };

  let CandyTypes = MigrationTypes.Current.CandyTypes;
  let Conversions = MigrationTypes.Current.Conversions;
  let Properties = MigrationTypes.Current.Properties;
  let Workspace = MigrationTypes.Current.Workspace;

  let account_handler = MigrationTypes.Current.account_handler;
  let token_handler = MigrationTypes.Current.token_handler;

  type StateAccess = Types.State;

  let SB = MigrationTypes.Current.SB;

  let tmp_wasm_blob = "\00\00\00\ff" : Blob;

  let IC = "aaaaa-aa";
  let ic_management_canister = actor (IC) : Interface.Self;

  public type InitFractionalizeRequest = {
    token_id : Text;
  };

  public type InitFractionalizeResponse = Result.Result<(), Types.OrigynError>;

  public type AuthorizeFractionalizeRequest = {
    token_id : Text;
  };

  public type AuthorizeFractionalizeResponse = Result.Result<(), Types.OrigynError>;

  type CreateSubNftsRequest = {
    token_id : Text;
  };

  type CreateSubNftsResponse = Result.Result<(), Types.OrigynError>;

  type FinishFractionalizeRequest = {
    token_id : Text;
  };

  type FinishFractionalizeResponse = Result.Result<(), Types.OrigynError>;

  // Define the enum-like structure for fractionalization status
  public type FractionalizationStatus = {
    #NotFractionalized;
    #FractionalizationInitialized;
    #CreatingSubNfts;
    #FractionalizationCompleted;
    #NonFractionalizable;
  };

  private func fractionalizationStatusEqual(a : FractionalizationStatus, b : FractionalizationStatus) : Bool {
    switch (a, b) {
      case (#NotFractionalized, #NotFractionalized) true;
      case (#FractionalizationInitialized, #FractionalizationInitialized) true;
      case (#CreatingSubNfts, #CreatingSubNfts) true;
      case (#FractionalizationCompleted, #FractionalizationCompleted) true;
      case (#NonFractionalizable, #NonFractionalizable) true;
      case (_, _) false;
    };
  };

  // Function to convert status to text
  private func statusToText(status : FractionalizationStatus) : Text {
    switch (status) {
      case (#NotFractionalized) "not_fractionalized";
      case (#FractionalizationInitialized) "fractionalization_initialized";
      case (#CreatingSubNfts) "creating_sub_nfts";
      case (#FractionalizationCompleted) "fractionalization_completed";
      case (#NonFractionalizable) "non_fractionalizable";
    };
  };

  // Function to convert text to status
  private func textToStatus(text : Text) : ?FractionalizationStatus {
    switch (text) {
      case ("not_fractionalized") ? #NotFractionalized;
      case ("fractionalization_initialized") ? #FractionalizationInitialized;
      case ("creating_sub_nfts") ? #CreatingSubNfts;
      case ("fractionalization_completed") ? #FractionalizationCompleted;
      case ("non_fractionalizable") ? #NonFractionalizable;
      case (_) null;
    };
  };

  // State machine method to change the fractionalization status
  private func change_fractionalization_status(state : StateAccess, nft_metadata : CandyTypes.CandyShared, token_id : Text, new_status : FractionalizationStatus) : Result.Result<FractionalizationStatus, Text> {
    var system_node : CandyTypes.CandyShared = switch (Properties.getClassPropertyShared(nft_metadata, Types.metadata.__system)) {
      case (null) {
        // TODO ADD LOGS
        return #err("System node not found");
      };
      case (?found) { found.value };
    };

    let current_status : Text = Conversions.candySharedToText(
      switch (Properties.getClassPropertyShared(system_node, Types.metadata.__system_fractionalization_status)) {
        case (null) { #Option(null) };
        case (?found) { found.value };
      }
    );

    let current_status_variant = switch (textToStatus(current_status)) {
      case (?s) s;
      case (null) return #err("Not allowed to fractionalize this NFT");
    };

    // Define valid state transitions
    let valid_transitions : [(FractionalizationStatus, [FractionalizationStatus])] = [
      (#NotFractionalized, [#FractionalizationInitialized, #NonFractionalizable]),
      (#FractionalizationInitialized, [#CreatingSubNfts]),
      (#CreatingSubNfts, [#FractionalizationCompleted]),
      (#FractionalizationCompleted, []),
      (#NonFractionalizable, []),
    ];

    let is_valid_transition = switch (
      Array.find(
        valid_transitions,
        func((from : FractionalizationStatus, to : [FractionalizationStatus])) : Bool {
          from == current_status_variant and Array.indexOf<FractionalizationStatus>(new_status, to, fractionalizationStatusEqual) != null
        },
      )
    ) {
      case (?_) true;
      case (null) false;
    };

    if (is_valid_transition) {
      // Update the status in the metadata
      let new_nft_metadata = Metadata.set_system_var(nft_metadata, Types.metadata.__system_fractionalization_status, #Text(statusToText(new_status)));

      Map.set<Text, CandyTypes.CandyShared>(state.state.nft_metadata, Map.thash, token_id, new_nft_metadata);

      return #ok(new_status);
    } else {
      return #err("Invalid state transition");
    };
  };

  /**
  * Initialize the fractionalization process.
  */
  public func init_fractionalization(state : StateAccess, request : InitFractionalizeRequest, caller : Principal) : async InitFractionalizeResponse {
    let this_nft = switch (Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) {
        return #err(Types.errors(?state.canistergeekLogger, #token_not_found, "init_fractionalization token not found" # err.flag_point, ?caller));
      };
      case (#ok(val)) {
        val;
      };
    };

    switch (Metadata.is_nft_owner(this_nft, #principal(caller))) {
      case (#err(err)) {
        return #err(Types.errors(?state.canistergeekLogger, #unauthorized_access, "init_fractionalization : Error checking NFT ownership", ?caller));
      };
      case (#ok(false)) {
        return #err(Types.errors(?state.canistergeekLogger, #unauthorized_access, "init_fractionalization : Caller is not the owner of the NFT", ?caller));
      };
      case (#ok(true)) {};
    };

    switch (Market.is_token_on_sale(state, this_nft, caller)) {
      case (#err(err)) {
        return #err(Types.errors(?state.canistergeekLogger, err.error, "init_fractionalization ensure_no_sale " # err.flag_point, ?caller));
      };
      case (#ok(val)) {
        if (val == true) {
          return #err(Types.errors(?state.canistergeekLogger, #existing_sale_found, "init_fractionalization - Nft is on sale. Please close current sale before trying to fractionnalize nft. " # request.token_id, ?caller));
        };
      };
    };

    switch (change_fractionalization_status(state, this_nft, request.token_id, #FractionalizationInitialized)) {
      case (#ok(_)) {};
      case (#err(err)) {
        return #err(Types.errors(?state.canistergeekLogger, #malformed_metadata, "init_fractionalization : " # debug_show (err), ?caller));
      };
    };

    // others check to do ?

    // set nft as no - tradable

    let newCanister = await ic_management_canister.create_canister({
      settings = null;
    });
    let canister_principal = Principal.toText(newCanister.canister_id);

    let settings : Interface.canister_settings = {
      controllers = ?[state.canister() /*, TODO add network canister id*/];
      compute_allocation = null;
      memory_allocation = null;
      freezing_threshold = ?(60 * 60 * 24 * 7);
    };

    await ic_management_canister.update_settings({
      canister_id = newCanister.canister_id;
      settings;
    });

    let install_return = await ic_management_canister.install_code({
      arg = [/*TODO WASM CODE*/];
      wasm_module = Blob.toArray(tmp_wasm_blob);
      mode = #install;
      canister_id = newCanister.canister_id;
    });

    D.print("install_return" # debug_show (install_return));

    return #ok(());

    // create new governance canister

    // add network canister as controller

    // add canister id as reference in the master nft metadata

    // in case of error -> put back the nft as tradable, cleanup the governance canister, remove the reference in the master nft metadata
  };

  /**
  * Create sub-portions of NFTs.
  */
  public func create_sub_nfts(state : StateAccess, request : CreateSubNftsRequest, caller : Principal) : async CreateSubNftsResponse {
    let this_nft = switch (Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) {
        return #err(Types.errors(?state.canistergeekLogger, #token_not_found, "create_sub_nfts token not found" # err.flag_point, ?caller));
      };
      case (#ok(val)) {
        val;
      };
    };

    switch (Metadata.is_nft_owner(this_nft, #principal(caller))) {
      case (#err(err)) {
        return #err(Types.errors(?state.canistergeekLogger, #unauthorized_access, "create_sub_nfts : Error checking NFT ownership", ?caller));
      };
      case (#ok(false)) {
        return #err(Types.errors(?state.canistergeekLogger, #unauthorized_access, "create_sub_nfts : Caller is not the owner of the NFT", ?caller));
      };
      case (#ok(true)) {};
    };

    switch (change_fractionalization_status(state, this_nft, request.token_id, #CreatingSubNfts)) {
      case (#ok(_)) {};
      case (#err(err)) {
        return #err(Types.errors(?state.canistergeekLogger, #malformed_metadata, "create_sub_nfts : " # debug_show (err), ?caller));
      };

    };

    // check if nft has a governance canister referenced

    // call stage_nft_origyn with the nft metadata design, derivated from the master nft design
    // nft is marketed as no-tradable for now

    // call stage_library_nft_origyn to upload/connect the nft with the right master library (we share the same preview?)

    // call mint_nft_origyn to mint the nft -> to the master nft owner canister directly ?

    // call governance canister to register the new nft
    return #ok(());
  };

  /**
  * Finish the fractionalization process.
  */
  public func finish_fractionalization(state : StateAccess, request : FinishFractionalizeRequest, caller : Principal) : async FinishFractionalizeResponse {
    let this_nft = switch (Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) {
        return #err(Types.errors(?state.canistergeekLogger, #token_not_found, "create_sub_nfts token not found" # err.flag_point, ?caller));
      };
      case (#ok(val)) {
        val;
      };
    };

    switch (Metadata.is_nft_owner(this_nft, #principal(caller))) {
      case (#err(err)) {
        return #err(Types.errors(?state.canistergeekLogger, #unauthorized_access, "finish_fractionalization : Error checking NFT ownership", ?caller));
      };
      case (#ok(false)) {
        return #err(Types.errors(?state.canistergeekLogger, #unauthorized_access, "finish_fractionalization : Caller is not the owner of the NFT", ?caller));
      };
      case (#ok(true)) {};
    };

    switch (change_fractionalization_status(state, this_nft, request.token_id, #FractionalizationCompleted)) {
      case (#ok(_)) {};
      case (#err(err)) {
        return #err(Types.errors(?state.canistergeekLogger, #malformed_metadata, "create_sub_nfts : " # debug_show (err), ?caller));
      };
    };

    // master nft is now own by the governance canister
    // sub nfts are marked as tradable tokens
    // ...implementation...

    return #ok(());
  };

  // Function to authorize fractionalization of an NFT
  public func authorize_fractionalization(state : StateAccess, request : AuthorizeFractionalizeRequest, caller : Principal) : async AuthorizeFractionalizeResponse {
    D.print("authorize_fractionalization" # debug_show (state.state.collection_data.owner));
    var this_nft = switch (Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) {
        return #err(Types.errors(?state.canistergeekLogger, #token_not_found, "authorize_fractionalization token not found" # err.flag_point, ?caller));
      };
      case (#ok(val)) {
        val;
      };
    };

    if (NFTUtils.is_owner_network(state, caller) == false) {
      return #err(Types.errors(?state.canistergeekLogger, #unauthorized_access, "authorize_fractionalization - unauthorized access - only network or collection owner can authorize fractionalization on an nft", ?caller));
    };

    switch (Properties.getClassPropertyShared(this_nft, Types.metadata.__system_fractionalization_status)) {
      case (null) {
        this_nft := Metadata.set_system_var(this_nft, Types.metadata.__system_fractionalization_status, #Text("not_fractionalized"));

        Map.set<Text, CandyTypes.CandyShared>(state.state.nft_metadata, Map.thash, request.token_id, this_nft);

        return #ok(());
      };
      case (?found) {
        return #err(Types.errors(?state.canistergeekLogger, #malformed_metadata, "authorize_fractionalization : Fractionalization already authorized", ?caller));
      };
    };
  };
};
