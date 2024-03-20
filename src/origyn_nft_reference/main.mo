/// The entry point for an ORIGYN NFT actor
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Cycles "mo:base/ExperimentalCycles";
import D "mo:base/Debug";
import Error "mo:base/Error";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import TrieMap "mo:base/TrieMap";

import BytesConverter "mo:stableBTree/bytesConverter";

import Canistergeek "mo:canistergeek/canistergeek";
import CanistergeekOld "mo:canistergeekold/canistergeek";
import CandyUpgrade "mo:candy_0_2_0/upgrade";

import Droute "mo:droute_client/Droute";
import EXT "mo:ext/Core";
import EXTCommon "mo:ext/Common";
import ICRC7 "ICRC7";

import Map "mo:map/Map";
import Set "mo:map/Set";

import Star "mo:star/star";

//todo: remove in 0.1.5
import CandyTypesOld "mo:candy_0_1_12/types";

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

import StableBTree "mo:stableBTree/btreemap";
import MemoryManager "mo:stableBTree/memoryManager";
import Memory "mo:stableBTree/memory";
import TypesModule "mo:canistergeekold/typesModule";

shared (deployer) actor class Nft_Canister() = this {

  // Lets user turn debug messages on and off for local replica
  let debug_channel = {
    instantiation = false;
    upgrade = false;
    function_announce = false;
    storage = false;
    streaming = false;
    manage_storage = false;
    calcs = true;
  };

  let CandyTypes = MigrationTypes.Current.CandyTypes;
  let Conversions = MigrationTypes.Current.Conversions;
  let Properties = MigrationTypes.Current.Properties;
  let Workspace = MigrationTypes.Current.Workspace;
  let JSON = MigrationTypes.Current.JSON;

  debug if (debug_channel.instantiation) D.print("creating a canister");

  let { ihash; nhash; thash; phash; calcHash } = Map;

  // A standard file chunk size.  The IC limits intercanister messages to ~2MB+ so we set that here
  stable var SIZE_CHUNK = 2048000; //max message size
  stable let created_at = Nat64.fromNat(Int.abs(Time.now()));
  stable var upgraded_at = Nat64.fromNat(Int.abs(Time.now()));

  let OneDay = 60 * 60 * 24 * 1000000000;

  // *************************
  // ***** CANISTER GEEK *****
  // *************************

  // Metrics
  //todo: remove old version in 0.1.5 - rewrite upgrader
  stable var _canistergeekMonitorUD : ?CanistergeekOld.UpgradeData = null;
  stable var _canistergeekMonitorUD_0_1_4 : ?Canistergeek.UpgradeData = null;
  private let canistergeekMonitor = Canistergeek.Monitor();

  // Logs
  //todo: remove old version in 0.1.5 - rewrite upgrader
  stable var _canistergeekLoggerUD : ?CanistergeekOld.LoggerUpgradeData = null;
  stable var _canistergeekLoggerUD_0_1_4 : ?Canistergeek.LoggerUpgradeData = null;
  private let canistergeekLogger = Canistergeek.Logger();

  // *************************
  // *** END CANISTER GEEK ***
  // *************************

  ///for migration information and pattern see
  //https://github.com/ZhenyaUsenko/motoko-migrations
  let StateTypes = MigrationTypes.Current;
  let SB = StateTypes.SB;

  debug if (debug_channel.instantiation) D.print("setting migration type to 0");

  stable var migration_state : MigrationTypes.State = #v0_0_0(#data);
  // For backups
  stable var halt : Bool = false;
  stable var data_harvester_page_size : Nat = 100;

  debug if (debug_channel.instantiation) D.print("migrating");

  // Do not forget to change #v0_1_0 when you are adding a new migration
  // If you use one previous state in place of #v0_1_0 it will run downgrade methods instead

  migration_state := Migrations.migrate(migration_state, #v0_1_6(#id), { owner = deployer.caller; storage_space = 0 });

  // Do not forget to change #v0_1_0 when you are adding a new migration
  let #v0_1_6(#data(state_current)) = migration_state;

  debug if (debug_channel.instantiation) D.print("finished migration");

  let kyc_client = MigrationTypes.Current.KYC.kyc({
    time = null;
    timeout = ?OneDay;
    cache = ?state_current.kyc_cache;
  });

  let memory_manager = MemoryManager.init(Memory.STABLE_MEMORY);

  debug if (debug_channel.instantiation) D.print("have memory_manager");

  /*
    var btreemap_ = {
        _1 = StableBTree.init<Nat32, [Nat8]>(memory_manager.get(0), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(1000));
        _4 = StableBTree.init<Nat32, [Nat8]>(memory_manager.get(1), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(4000));
        _16 = StableBTree.init<Nat32, [Nat8]>(memory_manager.get(2), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(16000));
        _64 = StableBTree.init<Nat32, [Nat8]>(memory_manager.get(3), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(64000));
        _256 = StableBTree.init<Nat32, [Nat8]>(memory_manager.get(4), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(256000));
        _1024 = StableBTree.init<Nat32, [Nat8]>(memory_manager.get(5), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(1024000));
        _2048 = StableBTree.init<Nat32, [Nat8]>(memory_manager.get(6), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(2048000));
      };
      */

  debug if (debug_channel.instantiation) D.print("done initing migration_state" # debug_show (state_current.collection_data.owner) # " " # debug_show (deployer.caller));
  debug if (debug_channel.instantiation) D.print("initializing from " # debug_show ((deployer)));

  // Used to get status of the canister and report it
  stable var ic : Types.IC = actor ("aaaaa-aa");

  // Upgrade storage for non-stable types
  //todo: remove nft_library_stable in 0.1.5 - consider moving into migration
  stable var nft_library_stable : [(Text, [(Text, CandyTypesOld.AddressedChunkArray)])] = [];
  stable var nft_library_stable_2 : [(Text, [(Text, CandyTypes.AddressedChunkArray)])] = [];

  // Stores data for a library - unstable because it uses Candy Workspaces to hold active and maleable bits of data that can be manipulated in real time
  private var nft_library : TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>> = if (nft_library_stable.size() > 0) {
    NFTUtils.build_library(nft_library_stable);
  } else {
    NFTUtils.build_library_new(nft_library_stable_2);
  };

  // Let us get the principal of the host gateway canister
  private var canister_principal : ?Principal = null;
  private func get_canister() : Principal {
    switch (canister_principal) {
      case (null) {
        canister_principal := ?Principal.fromActor(this);
        Principal.fromActor(this);
      };
      case (?val) {
        val;
      };
    };
  };

  ///DROUTE

  ignore Timer.setTimer(
    #seconds(0),
    func() : async () {
      await* Droute.init(state_current.droute);

      //ignore await* Droute.registerPublication(state_current.droute,"com.origyn.nft.event.auction_bid", null);
      //ignore await* Droute.registerPublication(state_current.droute,"com.origyn.nft.event.mint", null);
      //ignore await* Droute.registerPublication(state_current.droute,"com.origyn.nft.event.sale_ended", null);
    },
  );

  var notify_timer : ?Nat = null;

  // Let us access state and pass it to other modules
  let get_state : () -> Types.State = func() {
    {
      state = state_current;
      canister = get_canister;
      get_time = get_time;
      nft_library = nft_library;
      refresh_state = get_state;
      //btreemap = btreemap_;
      droute_client = state_current.droute;
      canistergeekLogger = canistergeekLogger;
      kyc_client = kyc_client;
      handle_notify = handle_notify;
      notify_timer = {
        get = get_notify_timer;
        set = set_notify_timer;
      };
    };
  };

  // Used for debugging
  stable var __time_mode : { #test; #standard } = #standard;
  private var __test_time : Int = 0;
  private func get_time() : Int {
    switch (__time_mode) {
      case (#standard) { return Time.now() };
      case (#test) { return __test_time };
    };

  };

  private func get_notify_timer() : ?Nat {
    notify_timer;
  };

  private func set_notify_timer(val : ?Nat) : () {
    notify_timer := val;
  };

  func handle_notify() : async () {
    let state = get_state();

    await Market.handle_notify(get_state());
  };

  // set the `data_havester`
  public shared (msg) func set_data_harvester(_page_size : Nat) : async () {
    if (NFTUtils.is_owner_manager_network(get_state(), msg.caller) == false) {
      throw Error.reject("Not the admin");
    };

    data_harvester_page_size := _page_size;
  };

  // set the `halt`
  public shared (msg) func set_halt(bHalt : Bool) : async () {

    if (NFTUtils.is_owner_network(get_state(), msg.caller) == false) {
      throw Error.reject("not the admin");
    };

    halt := bHalt;
  };

  public query (msg) func get_halt() : async Bool {
    halt;
  };

  // maintenance function for updating ledgers
  private func __implement_master_ledger() : Bool {

    let master_ledger = Buffer.Buffer<MigrationTypes.Current.TransactionRecord>(1);

    for (thisBuffer in Map.entries<Text, SB.StableBuffer<MigrationTypes.Current.TransactionRecord>>(state_current.nft_ledgers)) {
      for (thisItem in SB.vals<MigrationTypes.Current.TransactionRecord>(thisBuffer.1)) {
        master_ledger.add(thisItem);
      };
    };

    master_ledger.sort(
      func(pair1, pair2) {
        if (pair1.timestamp < pair2.timestamp) {
          #less;
        } else if (pair1.timestamp == pair2.timestamp) {
          if (pair1.index < pair2.index) {
            #less;
          } else if (pair1.index == pair2.index) {
            if (pair1.token_id < pair2.token_id) {
              #less;
            } else if (pair1.token_id == pair2.token_id) {
              #equal;
            } else {
              #greater;
            };
          } else {
            #greater;
          };
        } else {
          #greater;
        };
      }
    );

    state_current.master_ledger := SB.fromArray<MigrationTypes.Current.TransactionRecord>(Buffer.toArray(master_ledger));

    return true;
  };

  /**
    * Updates the entire API nodes with the given NFT update request data.
    *
    * @param {Types.NFTUpdateRequest} request - The request data for the NFT update.
    * @returns {Promise<Types.NFTUpdateResult>} - A promise that resolves to a Result object containing either the NFT update response or an OrigynError.
    * @throws {Error} - Throws an error if the canister is in maintenance mode.
    */
  public shared (msg) func update_app_nft_origyn(request : Types.NFTUpdateRequest) : async Types.NFTUpdateResult {
    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    switch (request) {
      case (#replace(val)) {
        var log_data = val.data;
        canistergeekLogger.logMessage("update_app_nft_origyn", log_data, ?msg.caller);
      };
      case (#update(val)) {
        var update_data = val.token_id;
        // canistergeekLogger.logMessage("update_app_nft_origyn",update_data,?msg.caller);
      };
    };

    canistergeekMonitor.collectMetrics();
    return data.update_app_nft_origyn(request, get_state(), msg.caller);
  };

  /**
    * Stages an NFT for origyn verification.
    *
    * @param {Record{metadata: CandyTypes.CandyShared}} request - The metadata for the NFT being staged.
    * @returns {async Types.OrigynTextResult} - The result of the staging operation.
    */
  public shared (msg) func stage_nft_origyn({
    metadata : CandyTypes.CandyShared;
  }) : async Types.OrigynTextResult {
    //nyi:  if we run out of space, start putting data into child canisters
    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    canistergeekLogger.logMessage("stage_nft_origyn", metadata, ?msg.caller);
    canistergeekMonitor.collectMetrics();
    debug if (debug_channel.function_announce) D.print("in stage");
    return Mint.stage_nft_origyn(get_state(), metadata, msg.caller);
  };

  // Allows staging multiple NFTs at the same time
  /**
    * Stages multiple NFTs for origyn verification.
    *
    * @param {Array<Record{metadata: CandyTypes.CandyShared}>} request - The metadata for the NFTs being staged.
    * @returns {async Array<Types.OrigynTextResult>} - An array containing the results of the staging operations.
    */
  public shared (msg) func stage_batch_nft_origyn(request : [{ metadata : CandyTypes.CandyShared }]) : async [Types.OrigynTextResult] {
    if (halt == true) { throw Error.reject("canister is in maintenance mode") };
    debug if (debug_channel.function_announce) D.print("in stage batch");
    if (NFTUtils.is_owner_manager_network(get_state(), msg.caller) == false) {
      return [#err(Types.errors(?get_state().canistergeekLogger, #unauthorized_access, "stage_batch_nft_origyn - not an owner, manager, or network", ?msg.caller))];
    };

    let results = Buffer.Buffer<Types.OrigynTextResult>(request.size());
    for (this_item in request.vals()) {
      // Logs
      canistergeekLogger.logMessage("stage_batch_nft_origyn", this_item.metadata, ?msg.caller);
      //nyi: should probably check for some spammy things and bail if too many errors
      results.add(Mint.stage_nft_origyn(get_state(), this_item.metadata, msg.caller));
    };
    canistergeekMonitor.collectMetrics();
    return Buffer.toArray(results);

  };

  // Stages a library. If the gateway is out of space a new bucket will be requested
  // And the remote stage call will be made to send the chunk to the proper canister.Array
  // Creators can also send library metadata to update library info without the data

  public shared (msg) func stage_library_nft_origyn(chunk : Types.StageChunkArg) : async Types.StageLibraryResult {
    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    let log_data : Text = "Chunk number : " # Nat.toText(chunk.chunk) # " - Library id : " # chunk.library_id;
    canistergeekLogger.logMessage("stage_library_nft_origyn", #Text(log_data), ?msg.caller);
    canistergeekMonitor.collectMetrics();
    debug if (debug_channel.function_announce) D.print("in stage library");
    switch (
      Mint.stage_library_nft_origyn(
        get_state(),
        chunk,
        msg.caller,
      )
    ) {
      case (#ok(stage_result)) {
        switch (stage_result) {
          case (#staged(canister)) {
            return #ok({ canister = canister });
          };
          case (#stage_remote(data)) {
            debug if (debug_channel.storage) D.print("minting remote");
            return await* Mint.stage_library_nft_origyn_remote(
              get_state(),
              chunk,
              data.allocation,
              data.metadata,
              msg.caller,
            );
          };
        };
      };
      case (#err(err)) {
        return #err(err);
      };
    };
  };

  // Allows for batch library staging but this should only be used for collection or web based
  // libraries that do not have actual file data.  If a remote call is made then the cycle limit
  // will be hit after a few cross canister calls
  /**
    * Stages a library NFT chunk for Origyn.
    *
    * @param {Types.StageChunkArg} chunk - The chunk to stage.
    * @returns {async Types.StageLibraryResult} The result of the staging operation.
    * @throws Will throw an error if the canister is in maintenance mode.
    */
  public shared (msg) func stage_library_batch_nft_origyn(chunks : [Types.StageChunkArg]) : async [Types.StageLibraryResult] {
    //nyi: this needs to be gated to make sure the chunks don't contain file data. This should only be used for collection asset adding

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    debug if (debug_channel.function_announce) D.print("in stage library batch");
    let results = Buffer.Buffer<Result.Result<Types.StageLibraryResponse, Types.OrigynError>>(chunks.size());
    for (this_item in chunks.vals()) {
      // Logs
      var log_data : Text = "Chunk number : " # Nat.toText(this_item.chunk) # " - Library id : " # this_item.library_id;
      canistergeekLogger.logMessage("stage_library_batch_nft_origyn", #Text(log_data), ?msg.caller);
      switch (
        Mint.stage_library_nft_origyn(
          get_state(),
          this_item,
          msg.caller,
        )
      ) {
        case (#ok(stage_result)) {
          switch (stage_result) {
            case (#staged(canister)) {
              results.add(#ok({ canister = canister }));
            };
            case (#stage_remote(data)) {
              debug if (debug_channel.storage) D.print("minting remote from batch. You are going to run out of cycles");
              results.add(
                await* Mint.stage_library_nft_origyn_remote(
                  get_state(),
                  this_item,
                  data.allocation,
                  data.metadata,
                  msg.caller,
                )
              );
            };
          };
        };
        case (#err(err)) {
          results.add(#err(err));
        };
      };
    };

    canistergeekMonitor.collectMetrics();

    return Buffer.toArray(results);
  };

  // Mints a NFT and assigns it to the new owner
  /**
    * Mints a new NFT token and assigns it to the specified owner.
    *
    * @param {Text} token_id - The ID of the new NFT token.
    * @param {Types.Account} new_owner - The new owner of the NFT token.
    * @param {msg} msg - The message context.
    * @returns {Types.OrigynTextResult} A Result indicating success or failure, with the new token ID on success.
    * @throws {Error} Throws an error if the canister is in maintenance mode.
    */
  public shared (msg) func mint_nft_origyn(token_id : Text, new_owner : Types.Account) : async Types.OrigynTextResult {
    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    switch (new_owner) {
      case (#account(val)) {
        let a = Principal.toText(val.owner);
        canistergeekLogger.logMessage("mint_nft_origyn", #Text(token_id # " new owner : " # a), ?msg.caller);
      };
      case (#account_id(val)) {
        canistergeekLogger.logMessage("mint_nft_origyn", #Text(token_id # " new owner : " # val), ?msg.caller);
      };
      case (#extensible(val)) {
        canistergeekLogger.logMessage("mint_nft_origyn", val, ?msg.caller);
      };
      case (#principal(val)) {
        let p = Principal.toText(val);
        canistergeekLogger.logMessage("mint_nft_origyn", #Text(token_id # " new owner : " # p), ?msg.caller);
      };
    };

    canistergeekMonitor.collectMetrics();

    debug if (debug_channel.function_announce) D.print("in mint");
    return await* Mint.mint_nft_origyn(get_state(), token_id, new_owner, msg.caller);

  };

  // Allows minting of multiple items
  /**
    * Allows minting of multiple items
    * @param {Array.<[Text, Types.Account]>} tokens - An array of tuples, each containing the token ID and the account of the new owner for each item to be minted.
    * @returns {Array.<Types.OrigynTextResult>} An array of results for each item in the batch, indicating success or failure with a resulting error message if applicable.
    */
  public shared (msg) func mint_batch_nft_origyn(tokens : [(Text, Types.Account)]) : async [Types.OrigynTextResult] {
    // This involves an inter canister call and will not work well for multi canister collections. Test to figure out how many you can mint at a time;

    if (halt == true) { throw Error.reject("canister is in maintenance mode") };
    if (NFTUtils.is_owner_manager_network(get_state(), msg.caller) == false) {
      return [#err(Types.errors(?get_state().canistergeekLogger, #unauthorized_access, "mint_nft_origyn - not an owner", ?msg.caller))];
    };
    debug if (debug_channel.function_announce) D.print("in mint batch");
    let results = Buffer.Buffer<Result.Result<Text, Types.OrigynError>>(tokens.size());
    let result_buffer = Buffer.Buffer<async* Result.Result<Text, Types.OrigynError>>(tokens.size());

    label search for (thisitem in tokens.vals()) {
      // Logs
      let log_data = thisitem;
      canistergeekLogger.logMessage("mint_batch_nft_origyn", #Text(log_data.0), ?msg.caller);
      result_buffer.add(Mint.mint_nft_origyn(get_state(), thisitem.0, thisitem.1, msg.caller));

      if (result_buffer.size() > 9) {
        for (thisItem in result_buffer.vals()) {
          results.add(await* thisItem);
        };
        result_buffer.clear();
      };
    };
    for (thisItem in result_buffer.vals()) {
      results.add(await* thisItem);
    };
    canistergeekMonitor.collectMetrics();
    return Buffer.toArray(results);
  };

  /**
    * Allows an owner to transfer a NFT from one of their wallets to another.
    * Warning: this feature will be updated in the future to give both wallets access to the NFT
    * for some set period of time including access to assets beyond just the NFT ownership. It should not
    * be used with a wallet that you do not 100% trust to not take the NFT back. It is meant for
    * internal accounting only. Use market_transfer_nft_origyn instead
    *
    * @param {Types.ShareWalletRequest} request - The request to share the NFT wallet.
    * @param {msg} msg - The message object that contains the caller of the function.
    * @returns {async Types.OwnerUpdateResult} - The response containing the status of the operation.
    */
  public shared (msg) func share_wallet_nft_origyn(request : Types.ShareWalletRequest) : async Types.OwnerUpdateResult {
    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    canistergeekLogger.logMessage("share_wallet_nft_origyn", #Text(request.token_id), ?msg.caller);
    canistergeekMonitor.collectMetrics();
    debug if (debug_channel.function_announce) D.print("in share wallet");
    return Owner.share_wallet_nft_origyn(get_state(), request, msg.caller);
  };

  /**
    * Used by the network to perform governance actions that have been voted on by OGY token holders
    * For non OGY NFTs you will need to call this function from the principal set as your 'network'
    *
    * @param {Types.GovernanceRequest} request - The governance request object
    * @param {Principal} msg.caller - The principal of the caller
    *
    * @returns {async Types.GovernanceResult} The result of the governance operation
    *
    * @throws {Error} Throws an error if the canister is in maintenance mode
    */
  public shared (msg) func governance_nft_origyn(request : Types.GovernanceRequest) : async Types.GovernanceResult {
    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    switch (request) {
      case (#clear_shared_wallets(val)) {
        canistergeekLogger.logMessage("governance_nft_origyn - clear_shared_wallets", #Text(val), ?msg.caller);
      };
      case (#update_system_var(val)) {
        canistergeekLogger.logMessage("governance_nft_origyn - update_system_var", #Text(debug_show (val)), ?msg.caller);
      };
    };
    canistergeekMonitor.collectMetrics();
    debug if (debug_channel.function_announce) D.print("in owner governance");
    return await* Governance.governance_nft_origyn(get_state(), request, msg.caller);
  };

  public shared (msg) func governance_batch_nft_origyn(requests : [Types.GovernanceRequest]) : async [Types.GovernanceResult] {

    if (halt == true) { throw Error.reject("canister is in maintenance mode") };
    if (NFTUtils.is_network(get_state(), msg.caller) == false) {
      return [#err(Types.errors(?get_state().canistergeekLogger, #unauthorized_access, "governance_batch_nft_origyn - not the network", ?msg.caller))];
    };
    debug if (debug_channel.function_announce) D.print("in govrnance batch batch");
    let results = Buffer.Buffer<Types.GovernanceResult>(requests.size());
    let result_buffer = Buffer.Buffer<async* Types.GovernanceResult>(requests.size());

    label search for (request in requests.vals()) {
      switch (request) {
        case (#clear_shared_wallets(val)) {
          canistergeekLogger.logMessage("governance_nft_origyn - clear_shared_wallets", #Text(val), ?msg.caller);
        };
        case (#update_system_var(val)) {
          canistergeekLogger.logMessage("governance_nft_origyn - update_system_var", #Text(debug_show (val)), ?msg.caller);
        };
      };
      result_buffer.add(Governance.governance_nft_origyn(get_state(), request, msg.caller));

      if (result_buffer.size() > 9) {
        for (thisItem in result_buffer.vals()) {
          results.add(await* thisItem);
        };
        result_buffer.clear();
      };
    };
    for (thisItem in result_buffer.vals()) {
      results.add(await* thisItem);
    };
    canistergeekMonitor.collectMetrics();
    return Buffer.toArray(results);
  };

  /**
    * Dip721 transferFrom - must have a valid escrow
    *
    * @param {Principal} from - The principal to transfer the token from
    * @param {Principal} to - The principal to transfer the token to
    * @param {Nat} tokenAsNat - The token to be transferred
    *
    * @return {DIP721.Result} A result object indicating success or failure
    *
    * @throws {Error} Throws an error if the canister is in maintenance mode
    */
  public shared (msg) func transferFromDip721(from : Principal, to : Principal, tokenAsNat : Nat) : async DIP721.DIP721NatResult {

    return #Err(#Other("transferFrom is not supported by origyn_nft.  Create a market ask using market_transfer_nft_origyn(#ask(X)) instead."));
    /* if (halt == true) {
            throw Error.reject("canister is in maintenance mode");
        };
        D.trap("transferFrom not supported in origyn_nft.  Use market_transfer_nft_origyn(#auction(X)).");
        let log_data : Text = "From : " # Principal.toText(from) # " to " # Principal.toText(to) # " - Token : " # Nat.toText(tokenAsNat);
        canistergeekLogger.logMessage("transferFromDip721", #Text(log_data), ?msg.caller);
        canistergeekMonitor.collectMetrics();
        debug if (debug_channel.function_announce) D.print("in transferFromDip721");
        // Existing escrow acts as approval
        if (msg.caller != to) {
            return #Err(#UnauthorizedOperator);
        };
        return await* Owner.transferDip721(get_state(), from, to, tokenAsNat, msg.caller); */
  };

  /**
    * Transfers the specified token from the caller to the given principal using DIP-721 standard.
    *
    * @param {Principal} caller - The caller principal initiating the transfer.
    * @param {Principal} to - The principal to transfer the token to.
    * @param {Nat} tokenAsNat - The token to transfer represented as a Nat.
    * @returns {async DIP721.Result} - Result of the transfer operation.
    */
  private func _dip_721_transfer(caller : Principal, to : Principal, tokenAsNat : Nat) : async* DIP721.DIP721NatResult {

    let log_data : Text = "To :" # Principal.toText(to) # " - Token : " # Nat.toText(tokenAsNat);
    canistergeekLogger.logMessage("transferDip721", #Text("transferDip721"), ?caller);
    canistergeekMonitor.collectMetrics();
    debug if (debug_channel.function_announce) D.print("in transferFromDip721");
    // Existing escrow acts as approval
    return await* Owner.transferDip721(get_state(), caller, to, tokenAsNat, caller);
  };

  /**
    * Transfers a Dip721 token to another account.
    *
    * @param {Principal} to - The principal of the account to transfer the token to.
    * @param {Nat} tokenAsNat - The ID of the token to transfer.
    * @returns {Promise<DIP721.Result>} - The result of the transfer operation.
    * @throws {Error} - If the canister is in maintenance mode.
    */
  public shared (msg) func transferDip721(to : Principal, tokenAsNat : Nat) : async DIP721.DIP721NatResult {
    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    await* _dip_721_transfer(msg.caller, to, tokenAsNat);
  };

  /**
    * Transfer a DIP-721 token to a specified principal. Escrow must exist.
    * @param {Principal} to - The principal to transfer the token to.
    * @param {Nat} tokenAsNat - The token identifier as a natural number.
    * @returns {DIP721.Result} A result indicating whether the transfer was successful or not.
    * @throws {Error} If the canister is in maintenance mode.
    */
  public shared (msg) func dip721_transfer(to : Principal, tokenAsNat : Nat) : async DIP721.DIP721NatResult {
    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    await* _dip_721_transfer(msg.caller, to, tokenAsNat);
  };

  /**
    * Transfers a DIP721 token from a specified owner to another account, if the transfer is authorized by the owner or the operator.
    * @param {Principal} caller - The principal that is calling this function.
    * @param {Principal} from - The principal of the token's current owner.
    * @param {Principal} to - The principal of the account that will receive the token.
    * @param {Nat} tokenAsNat - The ID of the token to be transferred, represented as a natural number.
    * @returns {async DIP721.Result} - Result indicating if the transfer was successful or not.
    */
  private func _dip_721_transferFrom(caller : Principal, from : Principal, to : Principal, tokenAsNat : Nat) : async* DIP721.DIP721NatResult {
    return #Err(#Other("transferFrom is not supported by origyn_nft.  Create a market ask using market_transfer_nft_origyn(#ask(X)) instead."));
    /*  let log_data : Text = "From : " # Principal.toText(from) # " to " # Principal.toText(to) # " - Token : " # Nat.toText(tokenAsNat);
        canistergeekLogger.logMessage("transferFrom", #Text("transferFrom"), ?caller);
        canistergeekMonitor.collectMetrics();
        debug if (debug_channel.function_announce) D.print("in transferFrom");
        if (caller != to) {
            return #Err(#UnauthorizedOperator);
        };
        // Existing escrow acts as approval
        return await* Owner.transferDip721(get_state(), from, to, tokenAsNat, caller); */
  };

  /**
    * Performs a Dip721 transferFrom of a token from one wallet to another.
    * @param {Principal} from - The wallet address to transfer from.
    * @param {Principal} to - The wallet address to transfer to.
    * @param {Nat} tokenAsNat - The token to be transferred represented as a natural number.
    * @returns {Promise<DIP721.Result>} - Result of the transfer operation.
    * @throws {Error} - Throws an error if the canister is in maintenance mode.
    */
  public shared (msg) func transferFrom(from : Principal, to : Principal, tokenAsNat : Nat) : async DIP721.DIP721NatResult {
    return #Err(#Other("transferFrom is not supported by origyn_nft.  Create a market ask using market_transfer_nft_origyn(#ask(X)) instead."));
    /* if (halt == true) {
            throw Error.reject("canister is in maintenance mode");
        };
        await* _dip_721_transferFrom(msg.caller, from, to, tokenAsNat); */
  };

  /**
    * Performs a transfer of a DIP-721 token from one account to another, provided that the `from` account has previously granted permission to the `caller` account to perform this transfer.
    *
    * @param {Principal} from - The account that currently owns the token being transferred.
    * @param {Principal} to - The account to which the token is being transferred.
    * @param {Nat} tokenAsNat - The token ID being transferred.
    *
    * @returns {async DIP721.Result} - The result of the transfer operation, which could be an error or success.
    *
    * @throws {Error} - If the canister is currently in maintenance mode.
    */
  public shared (msg) func dip721_transfer_from(from : Principal, to : Principal, tokenAsNat : Nat) : async DIP721.DIP721NatResult {
    return #Err(#Other("transferFrom is not supported by origyn_nft.  Create a market ask using market_transfer_nft_origyn(#ask(X)) instead.")); /*
        if (halt == true) {
            throw Error.reject("canister is in maintenance mode");
        };
        return await* _dip_721_transferFrom(msg.caller, from, to, tokenAsNat); */
  };

  /**
    * Transfer an external token from one account to another, must have a valid escrow.
    * @param request - The transfer request object containing the token and recipient details
    * @returns The transfer response object containing the transaction status and details
    * @throws {Error} Throws an error if the canister is in maintenance mode
    */
  public shared (msg) func transferEXT(request : Types.EXTTransferRequest) : async Types.EXTTransferResponse {
    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    canistergeekLogger.logMessage("transferEXT", #Text("transferEXT"), ?msg.caller);
    canistergeekMonitor.collectMetrics();
    debug if (debug_channel.function_announce) D.print("in transfer ext");
    // Existing escrow is approval
    return await* Owner.transferExt(get_state(), request, msg.caller);
  };

  /**
    * Performs a legacy EXT transfer, which requires a valid escrow.
    *
    * @param {object} request - The transfer request object.
    * @param {Nat} request.amount - The amount of the transfer.
    * @param {Text} request.token_id - The ID of the token to transfer.
    * @param {Principal} request.to - The principal to transfer the token to.
    * @param {Principal} request.from - The principal initiating the transfer.
    * @param {Nat} request.fee - The fee for the transfer.
    *
    * @returns {Promise<Types.EXTTransferResponse>} A promise that resolves to an EXT transfer response object.
    * @throws Will throw an error if the canister is in maintenance mode.
    */
  public shared (msg) func transfer(request : Types.EXTTransferRequest) : async Types.EXTTransferResponse {
    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    canistergeekLogger.logMessage("transfer", #Text("transfer"), ?msg.caller);
    canistergeekMonitor.collectMetrics();
    debug if (debug_channel.function_announce) D.print("in transfer");
    // Existing escrow is approval
    return await* Owner.transferExt(get_state(), request, msg.caller);
  };

  /**
    * Allows the market based transfer of NFTs
    * @param {Object} request - The market transfer request object.
    * @param {Text} request.token_id - The token ID.
    * @param {Types.SalesConfig} request.sales_config - The sales configuration object.
    * @param {Principal} request.seller - The seller's principal ID.
    * @param {Principal} request.buyer - The buyer's principal ID.
    * @returns {async Types.MarketTransferResult} A Result object that either contains the MarketTransferRequestReponse or an OrigynError.
    */
  public shared (msg) func market_transfer_nft_origyn(request : Types.MarketTransferRequest) : async Types.MarketTransferResult {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    let log_data : Text = "Token : " # request.token_id # (
      switch (request.sales_config.pricing) {
        case (#instant) {
          ", type : instant " # debug_show (request);
        };

        case (#auction(val)) {
          ", type : auction, start price : " # Nat.toText(val.start_price) # debug_show (request);
        };

        case (#ask(val)) {
          ", type : ask " # debug_show (request);
        };

        case (#extensible(val)) {
          ", type : extensible " # debug_show (request);
        };
      }
    );

    canistergeekLogger.logMessage("market_transfer_nft_origyn", #Text(log_data), ?msg.caller);
    canistergeekMonitor.collectMetrics();
    debug if (debug_channel.function_announce) D.print("in market transfer");

    return switch (request.sales_config.pricing) {
      case (#instant(item)) {
        //instant transfers involve the movement of tokens on remote servers so the call must be async
        return await* Market.market_transfer_nft_origyn_async(get_state(), request, msg.caller, false);
      };
      case (_) {
        //handles #auction types
        return await* Market.market_transfer_nft_origyn(get_state(), request, msg.caller);
      };
    };
  };

  /**
    * Start a large number of sales/market transfers. Currently limited to owners, managers, or the network
    * @param {Array<Types.MarketTransferRequest>} request - An array of market transfer requests
    * @returns {Array<Types.MarketTransferResult>} - An array of results for each market transfer request
    */
  public shared (msg) func market_transfer_batch_nft_origyn(request : [Types.MarketTransferRequest]) : async [Types.MarketTransferResult] {

    if (halt == true) { throw Error.reject("canister is in maintenance mode") };
    debug if (debug_channel.function_announce) D.print("in market transfer batch");

    let results = Buffer.Buffer<Types.MarketTransferResult>(request.size());
    let result_buffer = Buffer.Buffer<async* Types.MarketTransferResult>(1);

    for (this_item in request.vals()) {
      // Logs
      // var first_item = request[0];
      var log_data : Text = "Token : " # this_item.token_id # (
        switch (this_item.sales_config.pricing) {
          case (#instant) {
            ", type : instant " # debug_show (request);
          };

          case (#auction(val)) {
            ", type : auction, start price : " # Nat.toText(val.start_price) # debug_show (request);
          };
          case (#ask(val)) {
            ", type : ask, start price : " # debug_show (request);
          };

          case (#extensible(val)) {
            ", type : extensible " # debug_show (request);
          };
        }
      );
      canistergeekLogger.logMessage("market_transfer_batch_nft_origyn", #Text(log_data), ?msg.caller);
      // nyi: should probably check for some spammy things and bail if too many errors

      switch (this_item.sales_config.pricing) {
        case (#instant(item)) {
          result_buffer.add(Market.market_transfer_nft_origyn_async(get_state(), this_item, msg.caller, false));
        };
        case (_) {
          result_buffer.add(Market.market_transfer_nft_origyn(get_state(), this_item, msg.caller));
        };
      };

      if (result_buffer.size() > 9) {
        for (thisItem in result_buffer.vals()) {
          results.add(await* thisItem);
        };
        result_buffer.clear();
      };
    };

    for (thisItem in result_buffer.vals()) {
      results.add(await* thisItem);
    };
    //D.print("made it");
    canistergeekMonitor.collectMetrics();
    return Buffer.toArray(results);
  };

  /**
    * Start a large number of sales/market transfers. Currently limited to owners, managers, or the network
    * @param {Array<Types.MarketTransferRequest>} request - An array of market transfer requests
    * @returns {Array<Types.MarketTransferResult>} - An array of results for each market transfer request
    */
  private func _sale_nft_origyn(request : Types.ManageSaleRequest, caller : Principal) : async* Types.ManageSaleStar {

    var log_data : Text = "";
    canistergeekMonitor.collectMetrics();
    debug if (debug_channel.function_announce) D.print("in sale_nft_origyn");

    return switch (request) {
      case (#end_sale(val)) {
        let log_data = "Type : end sale, token id : " # debug_show (val);
        canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?caller);
        await* Market.end_sale_nft_origyn(get_state(), val, caller);
      };
      case (#open_sale(val)) {
        let log_data = "Type : open sale, token id : " # debug_show (val);
        canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?caller);
        switch (Market.open_sale_nft_origyn(get_state(), val, caller)) {
          case (#ok(val)) #trappable(val);
          case (#err(err)) #err(#trappable(err));
        };
      };
      case (#escrow_deposit(val)) {
        let log_data = "Type : escrow deposit, token id : " # debug_show (val);
        canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?caller);
        await* Market.escrow_nft_origyn(get_state(), val, caller);
      };
      case (#fee_deposit(val)) {
        let log_data = "Type : fee deposit, token id : " # debug_show (val);
        canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?caller);
        await* Market.deposit_fee_nft_origyn(get_state(), val, caller);
      };
      case (#recognize_escrow(val)) {
        let log_data = "Type : recognize escrow, token id : " # debug_show (val);
        canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?caller);
        await* Market.recognize_escrow_nft_origyn(get_state(), val, caller);
      };
      case (#ask_subscribe(val)) {
        let log_data = "Type : ask subscribe " # debug_show (val);
        canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?caller);
        await* Market.ask_subscribe_nft_origyn(get_state(), val, caller);
      };
      case (#refresh_offers(val)) {
        let log_data = "Type : refresh offers " # debug_show (val);
        canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?caller);
        switch (Market.refresh_offers_nft_origyn(get_state(), val, caller)) {
          case (#ok(val)) #trappable(val);
          case (#err(err)) #err(#trappable(err));
        };
      };
      case (#bid(val)) {
        let log_data = "Type : bid " # debug_show (val);
        canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?caller);
        await* Market.bid_nft_origyn(get_state(), val, caller, false);

      };
      case (#distribute_sale(val)) {
        let log_data = "Type : distribute sale " # debug_show (val);
        canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?caller);
        await* Market.distribute_sale(get_state(), val, caller);
      };
      case (#withdraw(val)) {
        let log_data = switch (val) {
          case (#escrow(v)) {
            "Type : withdraw with escrow  " # debug_show (val);
          };
          case (#sale(v)) {
            "Type : withdraw with sale " # debug_show (val);
          };
          case (#reject(v)) {
            "Type : withdraw with reject " # debug_show (val);
          };
          case (#deposit(v)) {
            "Type : withdraw with deposit " # debug_show (val);
          };
          case (#fee_deposit(v)) {
            "Type : withdraw with fee deposit  " # debug_show (val);
          };
        };
        canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?caller);
        // D.print("in withdrawl");
        await* Market.withdraw_nft_origyn(get_state(), val, caller);
      };
    };
  };

  /**
    * Allows a user to manage a NFT sale, including ending a sale, opening a sale, depositing an escrow, refreshing offers, bidding in an auction, withdrawing funds from an escrow or sale.
    * @param {Types.ManageSaleRequest} request - The request object containing the action to perform and relevant parameters.
    * @returns {Promise<Types.ManageSaleResult>} - Returns a promise that resolves to a result object containing a response object or an Origyn error.
    */
  public shared (msg) func sale_nft_origyn(request : Types.ManageSaleRequest) : async Types.ManageSaleResult {
    if (halt == true) { throw Error.reject("canister is in maintenance mode") };
    return Star.toResult<Types.ManageSaleResponse, Types.OrigynError>(await* _sale_nft_origyn(request, msg.caller));
  };

  /**
    * Allows batch operations for managing NFT sales, including ending a sale, opening a sale, depositing an escrow, refreshing offers, bidding in an auction, withdrawing funds from an escrow or sale.
    * @param {Array<Types.ManageSaleRequest>} requests - An array of ManageSaleRequest objects, each representing a different sale management operation.
    * @returns {Array<Types.ManageSaleResult>} - An array of Result objects, each representing the result of the corresponding operation in the input array.
    * @throws {Error} If the canister is in maintenance mode or the caller is not an owner, manager, or network.
    */
  public shared (msg) func sale_batch_nft_origyn(requests : [Types.ManageSaleRequest]) : async [Types.ManageSaleResult] {

    if (halt == true) { throw Error.reject("canister is in maintenance mode") };
    debug if (debug_channel.function_announce) D.print("in sale_nft_origyn batch");
    if (NFTUtils.is_owner_manager_network(get_state(), msg.caller) == false and msg.caller != get_state().canister()) {
      if (requests.size() > 20) {
        return [#err(Types.errors(?get_state().canistergeekLogger, #unauthorized_access, "sale_batch_nft_origyn - not an owner, manager, or network - batch limited to 20 items", ?msg.caller))];
      };
    };

    let result = Buffer.Buffer<Types.ManageSaleResult>(requests.size());
    let result_buffer = Buffer.Buffer<async* Types.ManageSaleStar>(requests.size());
    for (this_item in requests.vals()) {
      var log_data : Text = "";
      switch (this_item) {
        //NOTE: this causes a commit and could over run the cycle limit. We may need to refactor to
        // an end and then distribute pattern...or collect needed transfers and batch them.
        case (#end_sale(val)) {
          let log_data = "Type : end sale, token id :  " # debug_show (val);
          canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?msg.caller);
          result_buffer.add(Market.end_sale_nft_origyn(get_state(), val, msg.caller));
        };
        case (#open_sale(val)) {
          let log_data = "Type : open sale, token id :  " # debug_show (val);
          canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?msg.caller);
          result.add(Market.open_sale_nft_origyn(get_state(), val, msg.caller));
        };
        case (#escrow_deposit(val)) {
          let log_data = "Type : escrow deposit, token id :  " # debug_show (val);
          canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?msg.caller);
          result_buffer.add(Market.escrow_nft_origyn(get_state(), val, msg.caller));
        };
        case (#refresh_offers(val)) {
          let log_data = "Type : refresh offers " # debug_show (val);
          canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?msg.caller);
          result.add(Market.refresh_offers_nft_origyn(get_state(), val, msg.caller));
        };
        case (#bid(val)) {
          let log_data = "Type : bid " # debug_show (val);
          canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?msg.caller);
          result_buffer.add(Market.bid_nft_origyn(get_state(), val, msg.caller, false));

        };
        case (#distribute_sale(val)) {
          let log_data = "Type : distribute_sale " # debug_show (val);
          canistergeekLogger.logMessage("sale_nft_origyn", # Text(log_data), ?msg.caller);
          result_buffer.add(Market.distribute_sale(get_state(), val, msg.caller));

        };
        case (#ask_subscribe(val)) {
          let log_data = "Type : ask subscribe " # debug_show (val);
          canistergeekLogger.logMessage("sale_nft_origyn", # Text(log_data), ?msg.caller);
          result_buffer.add(Market.ask_subscribe_nft_origyn(get_state(), val, msg.caller));
        };
        case (#recognize_escrow(val)) {
          let log_data = "Type : recognize escreow " # debug_show (val);
          canistergeekLogger.logMessage("sale_nft_origyn", # Text(log_data), ?msg.caller);
          result_buffer.add(Market.recognize_escrow_nft_origyn(get_state(), val, msg.caller));
        };
        case (#withdraw(val)) {
          let log_data = switch (val) {
            case (#escrow(v)) {
              "Type : withdraw with escrow " # debug_show (v);
            };
            case (#sale(v)) {
              "Type : withdraw with sale" # debug_show (v);
            };
            case (#reject(v)) {
              "Type : withdraw with reject" # debug_show (v);
            };
            case (#deposit(v)) {
              "Type : withdraw with deposit" # debug_show (v);
            };
            case (#fee_deposit(v)) {
              "Type : withdraw with fee deposit" # debug_show (v);
            };
          };
          canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?msg.caller);
          result_buffer.add(Market.withdraw_nft_origyn(get_state(), val, msg.caller));
        };
        case (#fee_deposit(val)) {
          let log_data = "Type : fee_deposit :  " # debug_show (val);
          canistergeekLogger.logMessage("sale_nft_origyn", #Text(log_data), ?msg.caller);
          result_buffer.add(Market.deposit_fee_nft_origyn(get_state(), val, msg.caller));
        };
      };

      if (result_buffer.size() > 9) {
        for (thisItem in result_buffer.vals()) {
          result.add(Star.toResult<Types.ManageSaleResponse, Types.OrigynError>(await* thisItem));
        };
        result_buffer.clear();
      };
    };
    for (thisItem in result_buffer.vals()) {
      result.add(Star.toResult<Types.ManageSaleResponse, Types.OrigynError>(await* thisItem));
    };
    canistergeekMonitor.collectMetrics();
    return Buffer.toArray(result);
  };

  //passthrough function
  private func _sale_info_nft_origyn(request : Types.SaleInfoRequest, caller : Principal) : Types.SaleInfoResult {
    return switch (request) {
      case (#status(val)) {
        Market.sale_status_nft_origyn(get_state(), val, caller);
      };
      case (#active(val)) {
        Market.active_sales_nft_origyn(get_state(), val, caller);
      };
      case (#history(val)) {
        Market.history_sales_nft_origyn(get_state(), val, caller);
      };
      case (#deposit_info(val)) {
        Market.deposit_info_nft_origyn(get_state(), val, caller);
      };
      case (#escrow_info(val)) {
        Market.escrow_info_nft_origyn(get_state(), val, caller);
      };
      case (#fee_deposit_info(val)) {
        Market.fee_deposit_info_nft_origyn(get_state(), val, caller);
      };
    };
  };

  /**
    * Retrieves sale information for a single NFT in a secure manner.
    * @param {Types.SaleInfoRequest} request - The request object containing information about the type of sale information to retrieve.
    * @param {Principal} msg.caller - The caller principal.
    * @returns {Promise<Types.SaleInfoResult>} - The result of the operation, containing either the sale information or an error.
    */
  public query (msg) func sale_info_nft_origyn(request : Types.SaleInfoRequest) : async Types.SaleInfoResult {
    debug if (debug_channel.function_announce) D.print("in sale_info_nft_origyn");
    return _sale_info_nft_origyn(request, msg.caller);
  };

  /**
    * Retrieves sale information for a single NFT in a secure manner.
    * @param {Types.SaleInfoRequest} request - The request object containing information about the type of sale information to retrieve.
    * @param {Principal} msg.caller - The caller principal.
    * @returns {Promise<Types.SaleInfoResult>} - The result of the operation, containing either the sale information or an error.
    * @throws {Error} - Throws an error if the canister is in maintenance mode.
    */
  public shared (msg) func sale_info_secure_nft_origyn(request : Types.SaleInfoRequest) : async Types.SaleInfoResult {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    let log_data : Text = switch (request) {
      case (#active(val)) { "Type : active " # debug_show (val) };
      case (#history(val)) { "Type : history " # debug_show (val) };
      case (#status(val)) { "Type : status " # debug_show (val) };
      case (#deposit_info(val)) { "Type : deposit info " # debug_show (val) };
      case (#escrow_info(val)) { "Type : escrow info " # debug_show (val) };
      case (#fee_deposit_info(val)) {
        "Type : fee deposit info " # debug_show (val);
      };
    };
    canistergeekLogger.logMessage("sale_info_secure_nft_origyn", #Text(log_data), ?msg.caller);
    canistergeekMonitor.collectMetrics();
    debug if (debug_channel.function_announce) D.print("in sale info secure");
    return _sale_info_nft_origyn(request, msg.caller);
  };

  /**
    * Retrieves sale information for a batch of NFTs.
    * @param {Types.SaleInfoRequest[]} requests - The array of request objects containing information about the type of sale information to retrieve.
    * @param {Principal} msg.caller - The caller principal.
    * @returns {Promise<Types.SaleInfoResult[]>} - An array of results of the operation, each containing either the sale information or an error.
    */
  public query (msg) func sale_info_batch_nft_origyn(requests : [Types.SaleInfoRequest]) : async [Types.SaleInfoResult] {
    debug if (debug_channel.function_announce) D.print("in sale info batch");
    let result = Buffer.Buffer<Types.SaleInfoResult>(requests.size());
    for (this_item in requests.vals()) {
      result.add(_sale_info_nft_origyn(this_item, msg.caller));
    };
    return Buffer.toArray(result);

  };

  // Batch info secure
  public shared (msg) func sale_info_batch_secure_nft_origyn(requests : [Types.SaleInfoRequest]) : async [Types.SaleInfoResult] {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    debug if (debug_channel.function_announce) D.print("in sale info batch secure");
    let result = Buffer.Buffer<Types.SaleInfoResult>(requests.size());
    for (this_item in requests.vals()) {
      let log_data : Text = switch (this_item) {
        case (#active(val)) { "Type : active " # debug_show (val) };
        case (#history(val)) { "Type : history " # debug_show (val) };
        case (#status(val)) { "Type : status " # debug_show (val) };
        case (#deposit_info(val)) {
          "Type : deposit info" # debug_show (val);
        };
        case (#escrow_info(val)) {
          "Type : escrow info " # debug_show (val);
        };
      };
      canistergeekLogger.logMessage("sale_info_batch_secure_nft_origyn", #Text(log_data), ?msg.caller);
      result.add(_sale_info_nft_origyn(this_item, msg.caller));
    };
    return Buffer.toArray(result);
  };

  /**
    * Get sale information for multiple sales in a secure manner.
    * @param {Array<Types.SaleInfoRequest>} requests - An array of sale info requests.
    * @returns {Array<Types.SaleInfoResult>} An array of sale info responses.
    * @throws {Error} Throws an error if the canister is in maintenance mode.
    */
  public shared (msg) func collection_update_nft_origyn(request : Types.ManageCollectionCommand) : async Types.OrigynBoolResult {

    if (halt == true) { throw Error.reject("canister is in maintenance mode") };
    let log_data : Text = switch (request) {
      case (#UpdateManagers(val)) {
        "Type : UpdateManagers " # debug_show (val);
      };
      case (#UpdateOwner(val)) { "Type : UpdateOwner " # debug_show (val) };
      case (#UpdateNetwork(val)) { "Type : UpdateNetwork " # debug_show (val) };
      case (#UpdateLogo(val)) { "Type : UpdateLogo " };
      case (#UpdateName(val)) { "Type : UpdateName " # debug_show (val) };
      case (#UpdateSymbol(val)) { "Type : UpdateSymbol " # debug_show (val) };
      case (#UpdateMetadata(val)) { "Type : UpdateMetadata" };
      case (#UpdateAnnounceCanister(val)) { "Type : UpdateAnnounceCanister" };
    };
    canistergeekLogger.logMessage("collection_update_nft_origyn", #Text(log_data), ?msg.caller);
    canistergeekMonitor.collectMetrics();
    debug if (debug_channel.function_announce) D.print("in collection_update_nft_origyn");
    return Metadata.collection_update_nft_origyn(get_state(), request, msg.caller);
  };

  /**
    * Allows batch operations to update collection properties such as managers, owners, and the network
    * @param {Array<Types.ManageCollectionCommand>} requests - The array of requests for batch processing
    * @returns {Array<Types.OrigynBoolResult>} - The results of the batch processing
    * @throws Throws an error if the canister is in maintenance mode or if the caller is not a canister owner or network
    */
  public shared (msg) func collection_update_batch_nft_origyn(requests : [Types.ManageCollectionCommand]) : async [Types.OrigynBoolResult] {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    debug if (debug_channel.function_announce) D.print("in collection_update_batch_nft_origyn");
    // We do a first check of caller to avoid cycle drain
    if (NFTUtils.is_owner_network(get_state(), msg.caller) == false) {
      return [#err(Types.errors(?get_state().canistergeekLogger, #unauthorized_access, "collection_update_batch_nft_ - not a canister owner or network", ?msg.caller))];
    };

    let results = Buffer.Buffer<Types.OrigynBoolResult>(requests.size());
    for (this_item in requests.vals()) {
      let log_data : Text = switch (this_item) {
        case (#UpdateManagers(val)) {
          "Type : UpdateManagers " # debug_show (val);
        };
        case (#UpdateOwner(val)) {
          "Type : UpdateOwner " # debug_show (val);
        };
        case (#UpdateNetwork(val)) {
          "Type : UpdateNetwork " # debug_show (val);
        };
        case (#UpdateLogo(val)) { "Type : UpdateLogo" };
        case (#UpdateName(val)) {
          "Type : UpdateName " # debug_show (val);
        };
        case (#UpdateSymbol(val)) {
          "Type : UpdateSymbol " # debug_show (val);
        };
        case (#UpdateMetadata(val)) { "Type : UpdateMetadata" };
        case (#UpdateAnnounceCanister(val)) { "Type : UpdateAnnounceCanister" };
      };
      canistergeekLogger.logMessage("collection_update_batch_nft_origyn", #Text(log_data), ?msg.caller);
      results.add(Metadata.collection_update_nft_origyn(get_state(), this_item, msg.caller));
    };

    return Buffer.toArray(results);
  };

  // Debug function
  public shared (msg) func __advance_time(new_time : Int) : async Int {
    // nyi: Maybe only the network should be able to do this
    if (msg.caller != state_current.collection_data.owner) {
      throw Error.reject("not owner");
    };
    __test_time := new_time;
    return __test_time;

  };

  // Debug function
  public shared (msg) func __set_time_mode(newMode : { #test; #standard }) : async Bool {
    // nyi: Maybe only the network should be able to do this
    if (msg.caller != state_current.collection_data.owner) {
      throw Error.reject("not owner");
    };
    __time_mode := newMode;
    return true;
  };

  /**
    * Allows the owner to manage the storage on their NFT
    *
    * @param {Types.ManageStorageRequest} request - the request for the management of storage
    * @returns {async Types.ManageStorageResult} Returns a result indicating whether the storage management was successful or an error occurred
    * @throws Throws an error if the canister is in maintenance mode or if the caller is not the owner or network
    */
  public shared (msg) func manage_storage_nft_origyn(request : Types.ManageStorageRequest) : async Types.ManageStorageResult {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    if (NFTUtils.is_owner_network(get_state(), msg.caller) == false) {
      throw Error.reject("not owner or network " # debug_show (msg.caller));
    };
    debug if (debug_channel.function_announce) D.print("in collection_update_batch_nft_origyn");

    canistergeekLogger.logMessage("manage_storage_nft_origyn", #Text("#add_storage_canisters " # debug_show (request)), ?msg.caller);
    canistergeekMonitor.collectMetrics();

    let state = get_state();

    switch (request) {
      case (#configure_storage(val)) {

        debug if (debug_channel.manage_storage) D.print("configuring storage: " # debug_show (val));

        let amount = switch (val) {
          case (#heap(val)) {
            switch (val) {
              case (null) {
                return #err(Types.errors(?state.canistergeekLogger, #storage_configuration_error, "manage_storage_nft_origyn - allocation can't be empty " # debug_show (request), ?msg.caller));
              };
              case (?val) val;
            };
          };
          case (#stableBtree(val)) {
            switch (val) {
              case (null) {
                return #err(Types.errors(?state.canistergeekLogger, #storage_configuration_error, "manage_storage_nft_origyn - allocation can't be empty " # debug_show (request), ?msg.caller));
              };
              case (?val) val;
            };
          };
        };

        debug if (debug_channel.manage_storage) D.print("configuring storage current allocated: " # debug_show (state.state.collection_data.allocated_storage));
        if (state.state.collection_data.allocated_storage > 0) {
          return #err(Types.errors(?state.canistergeekLogger, #storage_configuration_error, "manage_storage_nft_origyn - allocation has already been made  " # debug_show (state.state.collection_data.allocated_storage), ?msg.caller));
        };
        debug if (debug_channel.manage_storage) D.print("configuring storage setting allocation: " # debug_show (state.state.collection_data.allocated_storage));

        switch (val) {
          case (#heap(val)) {
            state.state.use_stableBTree := false;
          };
          case (#stableBtree(val)) {
            state.state.use_stableBTree := true;
          };
        };
        state.state.collection_data.allocated_storage := amount;
        state.state.collection_data.available_space := amount;
        state.state.canister_availible_space := amount;
        state.state.canister_allocated_storage := amount;

        debug if (debug_channel.manage_storage) D.print("after config current allocated: " # debug_show (state.state.collection_data.allocated_storage));
        debug if (debug_channel.manage_storage) D.print("after config current allocated: " # debug_show (state.state.canister_allocated_storage));
        return #ok(
          #configure_storage(
            state.state.collection_data.allocated_storage,
            state.state.collection_data.available_space,
          )
        );
      };
      case (#add_storage_canisters(request)) {
        for (this_item in request.vals()) {
          //make sure that if this exists we re allocate or error
          switch (Map.get(state.state.buckets, Map.phash, this_item.0)) {
            case (null) {};
            case (?val) {
              //eventually we can accomidate reallocation, but fail for now
              return #err(Types.errors(?state.canistergeekLogger, #storage_configuration_error, "manage_storage_nft_origyn - principal already exists in buckets  " # debug_show (this_item), ?msg.caller));

            };
          };

          Map.set<Principal, Types.BucketData>(
            state.state.buckets,
            Map.phash,
            this_item.0,
            {
              principal = this_item.0;
              var allocated_space = this_item.1;
              var available_space = this_item.1;
              date_added = get_time();
              b_gateway = false;
              var version = this_item.2;
              var allocations = Map.new<(Text, Text), Int>();

            },
          );
          state.state.collection_data.allocated_storage += this_item.1;
          state.state.collection_data.available_space += this_item.1;
        };
        return #ok(
          #add_storage_canisters(
            state.state.collection_data.allocated_storage,
            state.state.collection_data.available_space,
          )
        );
      };
    };

    return #err(Types.errors(?get_state().canistergeekLogger, #nyi, "manage_storage_nft_origyn nyi ", ?msg.caller));

  };

  private func _collection_nft_origyn(fields : ?[(Text, ?Nat, ?Nat)], caller : Principal) : Types.CollectionResult {
    // Warning: this function does not use msg.caller, if you add it you need to fix the secure query
    debug if (debug_channel.function_announce) D.print("in collection_nft_origyn");

    let state = get_state();
    let keys = if (NFTUtils.is_owner_manager_network(state, caller) == true) {
      Iter.filter<Text>(Map.keys(state.state.nft_metadata), func(x : Text) { x != "" }); // Should always have the "" item and need to remove it
    } else {
      Iter.filter<Text>(Map.keys(state.state.nft_ledgers), func(x : Text) { x != "" }); // Should always have the "" item and need to remove it
    };

    let ownerSet = Set.new<MigrationTypes.Current.Account>();
    let keysBuffer = Buffer.Buffer<Text>(Map.size(state.state.nft_metadata));
    for (thisItem in keys) {
      keysBuffer.add(thisItem);
      let entry = switch (Map.get<Text, CandyTypes.CandyShared>(state.state.nft_metadata, thash, thisItem)) {
        case (?val) val;
        case (null) #Option(null);
      };

      switch (Metadata.get_nft_owner(entry)) {
        case (#ok(account)) {
          Set.add<MigrationTypes.Current.Account>(ownerSet, (MigrationTypes.Current.account_hash, MigrationTypes.Current.account_eq), account);
        };
        case (#err(err)) {};
      };
    };

    let vals = Map.vals(state.state.nft_ledgers);
    var transaction_count = SB.size(state.state.master_ledger);

    let multi_canister = Iter.toArray<Principal>(Map.keys<Principal, Types.BucketData>(state.state.buckets));

    let keysArray = Buffer.toArray(keysBuffer);

    return #ok({
      fields = fields;
      logo = state.state.collection_data.logo;
      name = state.state.collection_data.name;
      symbol = state.state.collection_data.symbol;
      total_supply = ?keysArray.size();
      owner = ?get_state().state.collection_data.owner;
      managers = ?get_state().state.collection_data.managers;
      network = state.state.collection_data.network;
      token_ids = ?keysArray;
      token_ids_count = ?keysArray.size();
      multi_canister = ?multi_canister;
      multi_canister_count = ?multi_canister.size();
      metadata = Map.get(state.state.nft_metadata, Map.thash, "");
      allocated_storage = ?get_state().state.collection_data.allocated_storage;
      available_space = ?get_state().state.collection_data.available_space;
      created_at = ?created_at;
      upgraded_at = ?upgraded_at;
      unique_holders = ?Set.size(ownerSet);
      transaction_count = ?transaction_count;
    });
  };

  /**
    * Returns information about the collection.
    * @param {Array} fields - An optional array of tuples representing the fields to be returned and the range of items to be returned.
    * @param {Text} fields[0] - The name of the field to be returned.
    * @param {Nat} fields[1] - Optional. The index of the first item to be returned.
    * @param {Nat} fields[2] - Optional. The number of items to be returned.
    * @returns {Promise<Types.CollectionResult>} - A promise that resolves to a Result object containing the CollectionInfo or an error message.
    */
  public query (msg) func collection_nft_origyn(fields : ?[(Text, ?Nat, ?Nat)]) : async Types.CollectionResult {
    return _collection_nft_origyn(fields, msg.caller);
  };

  /**
    * Secure access to collection information
    *
    * @param {Record} msg - A record containing the caller of the function
    * @param {Array} fields - An optional array of tuples representing the fields to be returned and the range of items to be returned.
    * @param {Text} fields[0] - The name of the field to be returned.
    * @param {Nat} fields[1] - Optional. The index of the first item to be returned.
    * @param {Nat} fields[2] - Optional. The number of items to be returned.
    * @returns {Promise<Types.CollectionResult>} - A promise that resolves to a Result object containing the CollectionInfo or an error message.
    */
  public shared (msg) func collection_secure_nft_origyn(fields : ?[(Text, ?Nat, ?Nat)]) : async Types.CollectionResult {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    canistergeekLogger.logMessage("collection_secure_nft_origyn", #Text("collection_secure_nft_origyn " # debug_show (fields)), ?msg.caller);
    canistergeekMonitor.collectMetrics();
    debug if (debug_channel.function_announce) D.print("in collection_secure_nft_origyn");

    return await collection_nft_origyn(fields);
  };

  /**
    * Retrieves the transaction history of a specific NFT token in the collection.
    * @param {Text} token_id - The ID of the NFT token.
    * @param {Nat} [start] - Optional. The starting index of the transaction record to retrieve.
    * @param {Nat} [end] - Optional. The ending index of the transaction record to retrieve.
    * @param {Principal} caller - The principal of the caller.
    * @returns {Result.Result<Array<MigrationTypes.Current.TransactionRecord>, Types.OrigynError>} - A Result object containing an array of transaction records or an error message.
    */

  private func _history_nft_origyn(token_id : Text, start : ?Nat, end : ?Nat, caller : Principal) : Types.HistoryResult {
    let find_ledger = if (token_id == "") {
      ?state_current.master_ledger;
    } else {
      Map.get(state_current.nft_ledgers, Map.thash, token_id);
    };
    let ledger = switch (find_ledger) {
      case (null) {
        return #ok([]);
      };
      case (?val) {
        var thisStart = 0;
        var thisEnd = Nat.sub(SB.size(val), 1);
        switch (start, end) {
          case (?start, ?end) {
            thisStart := start;
            thisEnd := end;
          };
          case (?start, null) {
            thisStart := start;
          };
          case (null, ?end) {
            thisEnd := end;
          };
          case (null, null) {};
        };

        if (thisEnd >= thisStart) {

          let result = Buffer.Buffer<MigrationTypes.Current.TransactionRecord>((thisEnd + 1) - thisStart);
          for (this_item in Iter.range(thisStart, thisEnd)) {
            result.add(
              switch (SB.getOpt(val, this_item)) {
                case (?item) { item };
                case (null) {
                  return #err(Types.errors(?get_state().canistergeekLogger, #asset_mismatch, "history_nft_origyn - index out of range  " # debug_show (this_item) # " " # debug_show (SB.size(val)), ?caller));

                };
              }
            );
          };

          return #ok(Buffer.toArray(result));
        } else {
          // Enable revrange
          return #err(Types.errors(?get_state().canistergeekLogger, #nyi, "history_nft_origyn - rev range nyi  " # debug_show (thisStart) # " " # debug_show (thisEnd), ?caller));
        };
      };
    };
  };

  /**
    * Allows users to see token information - ledger and history
    * @param {Text} token_id - The ID of the token to retrieve information for.
    * @param {Nat} [start] - Optional. The starting index of the transaction history to retrieve.
    * @param {Nat} [end] - Optional. The ending index of the transaction history to retrieve.
    * @returns {Promise<Result.Result<Array<MigrationTypes.Current.TransactionRecord>, Types.OrigynError>>} - A promise that resolves to a Result object containing the array of transaction records or an error message.
    */
  public query (msg) func history_nft_origyn(token_id : Text, start : ?Nat, end : ?Nat) : async Types.HistoryResult {
    // Warning: this func does not use msg.caller. If you decide to use it, fix the secure caller
    debug if (debug_channel.function_announce) D.print("in collection_secure_nft_origyn");
    return _history_nft_origyn(token_id, start, end, msg.caller);
  };

  /**
    * Secure access to token history
    * @param {Record<string, *>} msg - The request message.
    * @param {Text} msg.caller - The principal ID of the caller.
    * @param {Text} token_id - The ID of the token.
    * @param {Nat} [start] - The starting index (inclusive) of the token history to return.
    * @param {Nat} [end] - The ending index (inclusive) of the token history to return.
    * @returns {Promise<Result.Result<Array<MigrationTypes.Current.TransactionRecord>, Types.OrigynError>>} - A promise that resolves to a Result object containing an array of TransactionRecord objects or an error message.
    */
  public shared (msg) func history_secure_nft_origyn(token_id : Text, start : ?Nat, end : ?Nat) : async Types.HistoryResult {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    var log_data : Text = "Token id : " # token_id # " " # debug_show (start) # " " # debug_show (end);
    canistergeekLogger.logMessage("history_secure_nft_origyn", #Text(log_data), ?msg.caller);
    canistergeekMonitor.collectMetrics();

    debug if (debug_channel.function_announce) D.print("in history_secure_nft_origyn");

    return _history_nft_origyn(token_id, start, end, msg.caller);
  };

  /**
    * Provides access to searching a large number of histories.
    * @param {Array.<{token_id: string, start: ?number, end: ?number}>} tokens - An array of objects representing the token IDs and range of transaction records to be returned.
    * @param {string} tokens.token_id - The ID of the token.
    * @param {number} [tokens.start] - Optional. The index of the first transaction record to be returned.
    * @param {number} [tokens.end] - Optional. The index of the last transaction record to be returned.
    * @returns {Array.<Promise<Result.Result<Array.<MigrationTypes.Current.TransactionRecord>, Types.OrigynError>>>} - An array of promises that resolve to Result objects containing the transaction records or an error message for each token ID.
    */
  public query (msg) func history_batch_nft_origyn(tokens : [(token_id : Text, start : ?Nat, end : ?Nat)]) : async [Types.HistoryResult] {
    debug if (debug_channel.function_announce) D.print("in history_batch_nft_origyn");
    let results = Buffer.Buffer<Types.HistoryResult>(tokens.size());
    label search for (thisitem in tokens.vals()) {
      results.add(_history_nft_origyn(thisitem.0, thisitem.1, thisitem.2, msg.caller));
    };
    return Buffer.toArray(results);
  };

  /**
    * Provides secure access to history batch.
    * @param {Array} tokens - An array of tuples representing the tokens and their history.
    * @param {Text} tokens[n][0] - The token id to retrieve history from.
    * @param {Nat} tokens[n][1] - Optional. The index of the first item to be returned.
    * @param {Nat} tokens[n][2] - Optional. The number of items to be returned.
    * @returns {Promise<Array<Types.HistoryResult>>} - A promise that resolves to an array of Result objects containing the TransactionRecords or an error message.
    */
  public shared (msg) func history_batch_secure_nft_origyn(tokens : [(token_id : Text, start : ?Nat, end : ?Nat)]) : async [Types.HistoryResult] {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    debug if (debug_channel.function_announce) D.print("in history_batch_secure_nft_origyn");
    let results = Buffer.Buffer<Types.HistoryResult>(tokens.size());
    label search for (thisitem in tokens.vals()) {
      results.add(_history_nft_origyn(thisitem.0, thisitem.1, thisitem.2, msg.caller));

    };
    return Buffer.toArray(results);
  };

  /**
    * Returns the balance of a Dip721 token for a given user.
    * @param {Object} request - Therequest.
    * @returns {Nat} -  Dip721 balance for the user.
    */
  public query (msg) func dip721_balance_of(user : Principal) : async Nat {

    debug if (debug_channel.function_announce) D.print("in balanceOfDip721");
    return (Metadata.get_NFTs_for_user(get_state(), #principal(user))).size();
  };

  /**
    * Returns the balance of a Dip721 token for a given user.
    * @param {Object} request - Therequest.
    * @returns {Types.EXTBalanceResult} -  Dip721 balance for the user.
    */
  public query (msg) func balance(request : Types.EXTBalanceRequest) : async Types.EXTBalanceResult {
    //legacy ext

    debug if (debug_channel.function_announce) D.print("in balance");
    return _getEXTBalance(request);
  };

  /**
    * Provides the external balance of a given token holder.
    * @param {Object} request - The request object containing the parameters for the balance request.
    */
  public query (msg) func balanceEXT(request : Types.EXTBalanceRequest) : async Types.EXTBalanceResult {

    debug if (debug_channel.function_announce) D.print("in balanceEXT");
    return _getEXTBalance(request);
  };

  /**
    * Queries the tokens for a given request.
    * @param {Text} request - The request for which to retrieve the tokens.
    * @returns {Promise<Result.Result<[Types.EXTTokensResult], Types.EXTCommonError>>} The tokens result or an error.
    */
  public query (msg) func tokens_ext(request : Text) : async Types.EXTTokensResult {

    debug if (debug_channel.function_announce) D.print("in tokens_ext");
    let state = get_state();

    let request_account = #account_id(request);

    let result = Buffer.Buffer<Types.EXTTokensResponse>(0);

    // nyi: check the mint status and compare to msg.caller
    // nyi: indexing of NFTs, Escrows, Sales, Offers if this is a performance drain
    label search for (this_nft in Map.entries(state.state.nft_metadata)) {

      if (this_nft.0 == "") continue search;

      let owner = switch (Metadata.get_nft_owner(this_nft.1)) {
        case (#err(err)) { #account_id("00") };
        case (#ok(val)) val;
      };
      let force_account_id = switch (Types.force_account_to_account_id(owner)) {
        case (#ok(val)) val;
        case (_) { continue search };
      };
      if (Types.account_eq(request_account, force_account_id)) {
        result.add((Text.hash(this_nft.0), null, null));
      };
    };
    return #ok(Buffer.toArray(result));
  };

  /**
    * Gets the EXT balance for a given request.
    * @param {Types.EXTBalanceRequest} request - The request for which to retrieve the balance.
    * @returns {Types.EXTBalanceResult} The balance response.
    */
  private func _getEXTBalance(request : Types.EXTBalanceRequest) : Types.EXTBalanceResult {
    let thisCollection = Metadata.get_NFTs_for_user(
      get_state(),
      switch (request.user) {
        case (#address(data)) {
          #account_id(data);
        };
        case (#principal(data)) {
          #principal(data);
        };
      },
    );
    for (this_item in thisCollection.vals()) {
      if (Types._getEXTTokenIdentifier(this_item, Principal.fromActor(this)) == request.token) {

        return #ok(1 : Nat);
      };
    };
    return #ok(0 : Nat);
  };

  /**
    * Retrieves the EXT token identifier for a given token ID.
    * @param {Text} token_id - The ID of the token to retrieve the EXT token identifier for.
    * @returns {Promise<Text>} The EXT token identifier for the given token ID.
    */
  public query (msg) func getEXTTokenIdentifier(token_id : Text) : async Text {
    debug if (debug_channel.function_announce) D.print("in getEXTTokenIdentifier");
    return Types._getEXTTokenIdentifier(token_id, Principal.fromActor(this));

  };

  let account_handler = MigrationTypes.Current.account_handler;

  /**
    * Builds the balance object showing what resources an account holds on the server.
    * @param {Types.Account} account - The account to retrieve the balance for.
    * @param {Principal} caller - The principal making the request.
    * @returns {Types.BalanceResult} The balance response or an error.
    */
  private func _balance_of_nft_origyn(account : Types.Account, caller : Principal) : Types.BalanceResult {

    debug if (debug_channel.function_announce) D.print("in balance_of_nft_origyn");
    let state = get_state();

    // Get escrows
    let escrows = Map.get(state_current.escrow_balances, account_handler, account);
    let escrowResults = Buffer.Buffer<Types.EscrowRecord>(1);

    let sales = Map.get(state_current.sales_balances, account_handler, account);
    let salesResults = Buffer.Buffer<Types.EscrowRecord>(1);

    let nft_results = Buffer.Buffer<Text>(1);

    let offers = Map.get<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, account_handler, account);
    let offer_results = Buffer.Buffer<Types.EscrowRecord>(1);

    // nyi: check the mint status and compare to msg.caller
    // nyi: indexing of NFTs, Escrows, Sales, Offers if this is a performance drain
    for (this_nft in Map.entries(state.state.nft_metadata)) {
      switch (Metadata.is_nft_owner(this_nft.1, account)) {
        case (#ok(val)) {
          if (val == true and this_nft.0 != "") {
            nft_results.add(this_nft.0);
          };
        };
        case (_) {};
      };

    };

    switch (escrows) {
      case (null) {};
      case (?this_buyer) {
        Iter.iterate<MigrationTypes.Current.EscrowTokenIDTrie>(
          Map.vals(this_buyer),
          func(thisSeller, x) {
            Iter.iterate<MigrationTypes.Current.EscrowLedgerTrie>(
              Map.vals(thisSeller),
              func(this_token_id, x) {
                Iter.iterate<MigrationTypes.Current.EscrowRecord>(
                  Map.vals(this_token_id),
                  func(this_ledger, x) {
                    escrowResults.add(this_ledger);
                  },
                );
              },
            );
          },
        );
      };
    };

    switch (sales) {
      case (null) {};
      case (?thisSeller) {
        Iter.iterate<MigrationTypes.Current.EscrowTokenIDTrie>(
          Map.vals(thisSeller),
          func(this_buyer, x) {
            Iter.iterate<MigrationTypes.Current.EscrowLedgerTrie>(
              Map.vals(this_buyer),
              func(this_token_id, x) {
                Iter.iterate<MigrationTypes.Current.EscrowRecord>(
                  Map.vals(this_token_id),
                  func(this_ledger, x) {
                    salesResults.add(this_ledger);
                  },
                );
              },
            );
          },
        );
      };
    };

    switch (offers) {
      case (null) {};
      case (?found_offer) {
        for (this_buyer in Map.entries<Types.Account, Int>(found_offer)) {
          switch (Map.get<Types.Account, MigrationTypes.Current.EscrowSellerTrie>(state_current.escrow_balances, account_handler, this_buyer.0)) {
            case (null) {};
            case (?found_buyer) {
              switch (Map.get(found_buyer, account_handler, account)) {
                case (null) {};
                case (?found_seller) {
                  for (this_token in Map.entries(found_seller)) {
                    for (this_ledger in Map.entries(this_token.1)) {
                      if (this_ledger.1.sale_id == null) {
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
    };

    return #ok {
      multi_canister = null; //nyi
      nfts = Buffer.toArray(nft_results);
      escrow = Buffer.toArray(escrowResults);
      sales = Buffer.toArray(salesResults);
      stake = [];
      offers = Buffer.toArray(offer_results);
    };
  };

  /**
    * Retrieves the balance for a given account in the Origyn NFT.
    * @param {Types.Account} account - The account to retrieve the balance for.
    * @returns {Promise<Types.BalanceResult>} The balance response or an error.
    */
  public query (msg) func balance_of_nft_origyn(account : Types.Account) : async Types.BalanceResult {
    return _balance_of_nft_origyn(account, msg.caller);
  };

  /**
    * Retrieves the balance for a batch of accounts in the Origyn server.
    * @param {Types.Account[]} requests - The accounts to retrieve the balances for.
    * @returns {Promise<Types.BalanceResult[]>} The balance responses or errors for the given accounts.
    */
  public query (msg) func balance_of_batch_nft_origyn(requests : [Types.Account]) : async [Types.BalanceResult] {

    let results = Buffer.Buffer<Types.BalanceResult>(requests.size());
    for (thisItem in requests.vals()) {
      results.add(_balance_of_nft_origyn(thisItem, msg.caller));
    };
    return Buffer.toArray(results);
  };

  /**
    * Allows secure access to the balance of an account in the Origyn server.
    * @param {Types.Account} account - The account to retrieve the balance for.
    * @returns {Promise<Types.BalanceResult>} The balance response or an error.
    */
  public shared (msg) func balance_of_secure_nft_origyn(account : Types.Account) : async Types.BalanceResult {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    switch (account) {
      case (#account(val)) {
        let a = Principal.toText(val.owner);
        canistergeekLogger.logMessage("balance_of_secure_nft_origyn", #Text("Type - account : " # a), ?msg.caller);
      };
      case (#account_id(val)) {
        canistergeekLogger.logMessage("balance_of_secure_nft_origyn", #Text("Type - account id : " # val), ?msg.caller);
      };
      case (#extensible(val)) {
        canistergeekLogger.logMessage("balance_of_secure_nft_origyn", #Text("Type - extensible"), ?msg.caller);
      };
      case (#principal(val)) {
        let p = Principal.toText(val);
        canistergeekLogger.logMessage("balance_of_secure_nft_origyn", #Text("Type - principal : " # p), ?msg.caller);
      };
    };

    canistergeekMonitor.collectMetrics();
    return _balance_of_nft_origyn(account, msg.caller);
  };

  /**
    * Allows secure access to the balances of a batch of accounts in the Origyn server.
    * @param {Types.Account[]} requests - The accounts to retrieve the balances for.
    * @returns {Promise<Types.BalanceResult[]>} The balance responses or errors for the given accounts.
    */
  public shared (msg) func balance_of_secure_batch_nft_origyn(requests : [Types.Account]) : async [Types.BalanceResult] {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };

    canistergeekLogger.logMessage("balance_of_secure_batch_nft_origyn", #Text("Size : " # debug_show (requests.size())), ?msg.caller);

    let results = Buffer.Buffer<Types.BalanceResult>(requests.size());
    for (thisItem in requests.vals()) {
      results.add(_balance_of_nft_origyn(thisItem, msg.caller));
    };
    return Buffer.toArray(results);
  };

  /**
    * Retrieves the account that currently owns an NFT with the given token ID in the Origyn server.
    * @param {Text} token_id - The ID of the NFT to retrieve the owner for.
    * @param {Principal} caller - The principal making the request.
    * @returns {Types.BearerResult} The account that owns the NFT or an error.
    */
  private func _bearer_of_nft_origyn(token_id : Text, caller : Principal) : Types.BearerResult {
    let foundVal = switch (
      Metadata.get_nft_owner(
        switch (Metadata.get_metadata_for_token(get_state(), token_id, caller, null, state_current.collection_data.owner)) {
          case (#err(err)) {
            return #err(Types.errors(?get_state().canistergeekLogger, #token_not_found, "bearer_nft_origyn " # err.flag_point, ?caller));
          };
          case (#ok(val)) {
            val;
          };
        }
      )
    ) {
      case (#err(err)) {
        return #err(Types.errors(?get_state().canistergeekLogger, err.error, "bearer_nft_origyn " # err.flag_point, ?caller));
      };
      case (#ok(val)) {
        return #ok(val);
      };
    };
  };

  /**
    * Retrieves the account that currently owns an NFT with the given token ID in the Origyn server.
    * @param {Text} token_id - The ID of the NFT to retrieve the owner for.
    * @returns {Promise<Types.BearerResult>} The account that owns the NFT or an error.
    */
  public query (msg) func bearer_nft_origyn(token_id : Text) : async Types.BearerResult {

    debug if (debug_channel.function_announce) D.print("in bearer_nft_origyn");
    return _bearer_of_nft_origyn(token_id, msg.caller);

  };

  /**
    * Allows secure access to the account that currently owns an NFT with the given token ID in the Origyn server.
    * @param {Text} token_id - The ID of the NFT to retrieve the owner for.
    * @returns {Promise<Types.BearerResult>} The account that owns the NFT or an error.
    */
  public shared (msg) func bearer_secure_nft_origyn(token_id : Text) : async Types.BearerResult {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    debug if (debug_channel.function_announce) D.print("in bearer_secure_nft_origyn");
    return _bearer_of_nft_origyn(token_id, msg.caller);
  };

  /**
    * Provides access to searching a large number of NFT bearers at once in the Origyn server.
    * @param {Array<Text>} tokens - The array of token IDs of the NFTs to retrieve the owners for.
    * @returns {Promise<Array<Types.BearerResult>>} An array of results where each element corresponds to the account that owns the corresponding token in the input array or an error.
    */
  public query (msg) func bearer_batch_nft_origyn(tokens : [Text]) : async [Types.BearerResult] {

    debug if (debug_channel.function_announce) D.print("in bearer_secure_nft_origyn");
    let results = Buffer.Buffer<Types.BearerResult>(tokens.size());
    label search for (thisitem in tokens.vals()) {
      results.add(_bearer_of_nft_origyn(thisitem, msg.caller));
    };
    return Buffer.toArray(results);
  };

  /**
    * Provides secure access to searching a large number of bearers at one time.
    * @param {Array<Text>} tokens - An array of token IDs to search for.
    * @returns {Array<Promise<Types.BearerResult>>} - An array of promises, each resolving to a Result object containing either the owner account or an OrigynError.
    */
  public shared (msg) func bearer_batch_secure_nft_origyn(tokens : [Text]) : async [Types.BearerResult] {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    debug if (debug_channel.function_announce) D.print("in bearer_batch_secure_nft_origyn");
    let results = Buffer.Buffer<Types.BearerResult>(tokens.size());
    label search for (thisitem in tokens.vals()) {
      results.add(_bearer_of_nft_origyn(thisitem, msg.caller));

    };
    return Buffer.toArray(results);
  };

  /**
    * Converts a token ID to a Nat for use in dip721.
    * @param {Text} token_id - The token ID to be converted.
    * @returns {Nat} The converted token ID as a Nat.
    * @throws Will throw an error if the canister is in maintenance mode.
    */
  public query (msg) func get_token_id_as_nat_origyn(token_id : Text) : async Nat {

    debug if (debug_channel.function_announce) D.print("in get_token_id_as_nat_origyn");
    return NFTUtils.get_token_id_as_nat(token_id);
  };

  /**
    * Converts a Nat to a token_id for Nat.
    *
    * @param {Nat} tokenAsNat - The Nat to be converted.
    * @returns {Text} The token_id corresponding to the given Nat.
    */
  public query (msg) func get_nat_as_token_id_origyn(tokenAsNat : Nat) : async Text {

    debug if (debug_channel.function_announce) D.print("in get_nat_as_token_id_origyn");

    NFTUtils.get_nat_as_token_id(tokenAsNat);
  };

  /**
    * Returns the owner of a DIP721 token.
    * @param {Nat} tokenAsNat - The DIP721 token as a Nat.
    * @param {Principal} caller - The caller Principal.
    * @returns {DIP721.OwnerOfResponse} - The owner of the DIP721 token.
    */
  private func _ownerOfDip721(tokenAsNat : Nat, caller : Principal) : DIP721.OwnerOfResponse {
    let foundVal = switch (
      Metadata.get_nft_owner(
        switch (
          Metadata.get_metadata_for_token(
            get_state(),
            NFTUtils.get_nat_as_token_id(tokenAsNat),
            caller,
            null,
            state_current.collection_data.owner,
          )
        ) {
          case (#err(err)) {
            return #Err(#TokenNotFound);
          };
          case (#ok(val)) {
            val;
          };
        }
      )
    ) {
      case (#err(err)) {
        return #Err(#Other("ownerOf " # err.flag_point));
      };
      case (#ok(val)) {
        switch (val) {
          case (#principal(data)) {
            return #Ok(?data);
          };
          case (_) {
            return #Err(#Other("ownerOf unsupported owner type by DIP721" # debug_show (val)));
          };
        };
      };
    };
  };

  /**
    * Returns the owner of the DIP721 token indicated by tokenAsNat.
    * @param {Nat} tokenAsNat - The token identifier as a Nat.
    * @returns {async DIP721.OwnerOfResponse} The owner of the DIP721 token.
    */
  public query (msg) func dip721_owner_of(tokenAsNat : Nat) : async DIP721.OwnerOfResponse {

    debug if (debug_channel.function_announce) D.print("in ownerOfDIP721");
    return _ownerOfDip721(tokenAsNat, msg.caller);
  };

  /**
    * For dip721 legacy
    * @param {Nat} tokenAsNat - The token ID as a Nat.
    * @returns {Promise<DIP721.OwnerOfResponse>} The owner of the DIP721 token.
    */
  public query (msg) func ownerOf(tokenAsNat : Nat) : async DIP721.OwnerOfResponse {
    debug if (debug_channel.function_announce) D.print("in ownerOf");
    return _ownerOfDip721(tokenAsNat, msg.caller);
  };

  /**
    * Supports EXT Bearer
    * @param {Types.EXTTokenIdentifier} tokenIdentifier - The token identifier.
    * @returns {Promise<Types.EXTBearerResult>} The bearer account identifier.
    */
  public query (msg) func bearerEXT(tokenIdentifier : Types.EXTTokenIdentifier) : async Types.EXTBearerResult {

    debug if (debug_channel.function_announce) D.print("in bearerEXT");
    return Owner.bearerEXT(get_state(), tokenIdentifier, msg.caller);
  };

  /**
    * Supports EXT Bearer legacy
    * @param {Types.EXTTokenIdentifier} tokenIdentifier - The token identifier.
    * @returns {Promise<Types.EXTBearerResult>} The bearer account identifier.
    */
  public query (msg) func bearer(tokenIdentifier : Types.EXTTokenIdentifier) : async Types.EXTBearerResult {

    debug if (debug_channel.function_announce) D.print("in bearer");
    return Owner.bearerEXT(get_state(), tokenIdentifier, msg.caller);
  };

  /**
    * Returns metadata about an NFT
    * @param {Text} token_id - The id of the NFT to retrieve metadata for
    * @param {Principal} caller - the identity asking for metadata
    * @returns {async Types.NFTInfoResult} - The NFT metadata, or an error if it does not exist or could not be retrieved
    */
  private func _nft_origyn(token_id : Text, caller : Principal) : Types.NFTInfoResult {
    //D.print("Calling NFT_Origyn");

    let this_state = get_state();

    var metadata = switch (Metadata.get_metadata_for_token(this_state, token_id, caller, null, state_current.collection_data.owner)) {
      case (#err(err)) {
        return #err(err);
      };
      case (#ok(val)) {
        val;
      };
    };

    let final_object = Metadata.get_clean_metadata(metadata, caller);

    // Identify a current sale
    let current_sale : ?Types.SaleStatusShared = switch (Metadata.get_current_sale_id(metadata)) {
      case (#Option(null)) { null };
      case (#Text(val)) {
        do ? {
          let sale = Map.get(state_current.nft_sales, Map.thash, val)!;

          Types.SalesStatus_stabalize_for_xfer({
            sale with
            sale_type = switch (sale.sale_type) {
              case (#auction(val)) {
                #auction(Market.calc_dutch_price(this_state, val, metadata));
              };
            };
          });
        };
      };
      case (_) {
        //should be an error
        null;
      };
    };
    return (#ok({ current_sale = current_sale; metadata = final_object }));

    return #ok({ current_sale = null; metadata = #Option(null) });
  };

  /**
    * Returns metadata about an NFT
    * @param {Text} token_id - The id of the NFT to retrieve metadata for
    * @returns {async Types.NFTInfoResult} - The NFT metadata, or an error if it does not exist or could not be retrieved
    */
  public query (msg) func nft_origyn(token_id : Text) : async Types.NFTInfoResult {

    debug if (debug_channel.function_announce) D.print("in nft_origyn");

    return _nft_origyn(token_id, msg.caller);
  };

  /**
    * Secure access to nft_origyn
    * @param {Text} token_id - The id of the NFT to retrieve metadata for
    * @returns {async Types.NFTInfoResult} - The NFT metadata, or an error if it does not exist or could not be retrieved
    */
  public shared (msg) func nft_secure_origyn(token_id : Text) : async Types.NFTInfoResult {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    debug if (debug_channel.function_announce) D.print("in nft_secure_origyn");
    return _nft_origyn(token_id, msg.caller);
  };

  /**
    * Batch access to nft metadata
    * @param {Text[]} token_ids - An array of NFT ids to retrieve metadata for
    * @returns {async [Types.NFTInfoResult]} - An array of NFT metadata or errors for each provided token id
    */
  public query (msg) func nft_batch_origyn(token_ids : [Text]) : async [Types.NFTInfoResult] {

    if (halt == true) { throw Error.reject("canister is in maintenance mode") };
    debug if (debug_channel.function_announce) D.print("in nft_batch_origyn");
    let results = Buffer.Buffer<Types.NFTInfoResult>(token_ids.size());
    label search for (thisitem in token_ids.vals()) {
      results.add(_nft_origyn(thisitem, msg.caller));
    };

    return Buffer.toArray(results);
  };

  /**
    * Secure batch access to nft metadata
    * @param {Text[]} token_ids - An array of NFT ids to retrieve metadata for
    * @returns {async [Types.NFTInfoResult]} - An array of NFT metadata or errors for each provided token id
    */
  public shared (msg) func nft_batch_secure_origyn(token_ids : [Text]) : async [Types.NFTInfoResult] {

    if (halt == true) { throw Error.reject("canister is in maintenance mode") };
    debug if (debug_channel.function_announce) D.print("in nft_batch_secure_origyn");
    let results = Buffer.Buffer<Types.NFTInfoResult>(token_ids.size());
    label search for (thisitem in token_ids.vals()) {
      results.add(_nft_origyn(thisitem, msg.caller));
    };

    return Buffer.toArray(results);
  };

  /**
    * Retrieves the DIP721 metadata for a given token ID
    * @param {Principal} caller - The principal of the caller
    * @param {Nat} token_id - The token ID as a Nat
    * @returns {async} Result.Result<DIP721.Metadata_3, Types.OrigynError>
    */
  private func _dip_721_metadata(caller : Principal, token_id : Nat) : DIP721.DIP721TokenMetadata {

    let token_id_raw = NFTUtils.get_nat_as_token_id(token_id);

    let nft = switch (_nft_origyn(token_id_raw, caller)) {
      case (#ok(nft)) nft;
      case (#err(e)) return #Err(#TokenNotFound);
    };

    let state = get_state();

    let owner = switch (Metadata.get_nft_owner(nft.metadata)) {
      case (#ok(owner)) {
        switch (owner) {
          case (#principal(p)) ?p;
          case (#account_id(a)) null;
          case (#account(a)) ?a.owner;
          case (#extensible(e)) null;
        };
      };
      case (#err(e)) null;
    };

    return #Ok({
      transferred_at = null;
      transferred_by = null;
      owner = owner;
      operator = owner;
      approved_at = null;
      approved_by = null;
      properties = [
        ("location", #TextContent("https://" # Principal.toText(state.canister()) # ".raw.icp0.io/-/" # token_id_raw)),
        ("thumbnail", #TextContent("https://" # Principal.toText(state.canister()) # ".raw.icp0.io/-/" # token_id_raw # "/preview")),
        ("com.origyn.data", #TextContent(JSON.value_to_json(nft.metadata))),
      ];
      is_burned = false;
      token_identifier = token_id;
      burned_at = null;
      burned_by = null;
      minted_at = 0;
      minted_by = state.state.collection_data.owner;
    });
  };

  /**
    * Retrieves the DIP721 metadata for a given principal
    * @param {Principal} caller - The principal of the caller
    * @param {Principal} principal - The principal for which to retrieve metadata
    * @returns {async} Result.Result<Array<DIP721.Metadata_2>, Types.OrigynError>
    */
  private func _dip_721_metadata_for_principal(caller : Principal, principal : Principal) : DIP721.DIP721TokensMetadata {
    // D.print("nft origyn :" # debug_show(token_id));

    debug if (debug_channel.function_announce) D.print("in nft_origyn");
    let resultBuffer = Buffer.Buffer<DIP721.TokenMetadata>(1);
    let state = get_state();

    for (this_nft in Map.entries(state.state.nft_metadata)) {
      switch (Metadata.is_nft_owner(this_nft.1, #principal(principal))) {
        case (#ok(val)) {
          if (val == true and this_nft.0 != "") {
            let thismetadata = _dip_721_metadata(caller, NFTUtils.get_token_id_as_nat(this_nft.0));
            switch (thismetadata) {
              case (#Ok(data)) { resultBuffer.add(data) };
              case (#Err(err)) { return #Err(err) };
            };
          };
        };
        case (#err(err)) {

        };
      };
    };

    return #Ok(Buffer.toArray(resultBuffer));
  };

  /**
    * Returns the metadata of all tokens owned by a given owner.
    * @param {Principal} owner - The principal of the owner whose tokens' metadata will be returned.
    * @returns {DIP721.Metadata_2} The metadata of all tokens owned by the specified owner.
    */
  public query (msg) func dip721_owner_token_metadata(owner : Principal) : async DIP721.DIP721TokensMetadata {

    _dip_721_metadata_for_principal(msg.caller, owner);
  };

  /**
    * Returns the metadata of all tokens for which a given principal is the operator.
    * @param {Principal} operator - The principal of the operator whose tokens' metadata will be returned.
    * @returns {DIP721.Metadata_2} The metadata of all tokens for which the specified principal is the operator.
    */
  public query (msg) func dip721_operator_token_metadata(operator : Principal) : async DIP721.DIP721TokensMetadata {

    _dip_721_metadata_for_principal(msg.caller, operator);
  };

  /**
    * Returns the metadata of all tokens owned by a given owner.
    * @param {Principal} owner - The principal of the owner whose tokens' metadata will be returned.
    * @returns {DIP721.Metadata_2} The metadata of all tokens owned by the specified owner.
    */
  public query (msg) func ownerTokenMetadata(owner : Principal) : async DIP721.DIP721TokensMetadata {

    _dip_721_metadata_for_principal(msg.caller, owner);
  };

  /**
    * Returns the metadata of all tokens for which a given principal is the operator.
    * @param {Principal} operator - The principal of the operator whose tokens' metadata will be returned.
    * @returns {DIP721.Metadata_2} The metadata of all tokens for which the specified principal is the operator.
    */
  public query (msg) func operaterTokenMetadata(operator : Principal) : async DIP721.DIP721TokensMetadata {

    _dip_721_metadata_for_principal(msg.caller, operator);
  };

  /**
    * Returns the metadata of a given token.
    * @param {Nat} token_id - The id of the token whose metadata will be returned.
    * @returns {DIP721.Metadata_3} The metadata of the specified token.
    */
  public query (msg) func dip721_token_metadata(token_id : Nat) : async DIP721.DIP721TokenMetadata {

    _dip_721_metadata(msg.caller, token_id);
  };

  /**
    * Determines if a given operator is approved for all tokens owned by a given owner.
    * @param {Principal} owner - The principal of the owner of the tokens.
    * @param {Principal} operator - The principal of the operator to be checked.
    * @returns {DIP721.Result_1} A result indicating whether the operator is approved for all tokens.
    */
  public query (msg) func dip721_is_approved_for_all(owner : Principal, operator : Principal) : async DIP721.DIP721BoolResult {
    return (#Ok(false));
  };

  private func _dip_721_get_tokens(caller : Principal, owner : Principal) : DIP721.DIP721TokensListMetadata {
    let nft_results = Buffer.Buffer<Text>(1);
    let state = get_state();

    // nyi: check the mint status and compare to msg.caller
    // nyi: indexing of NFTs, Escrows, Sales, Offers if this is a performance drain
    for (this_nft in Map.entries(state.state.nft_metadata)) {
      switch (Metadata.is_nft_owner(this_nft.1, #principal(owner))) {
        case (#ok(val)) {
          if (val == true and this_nft.0 != "") {
            nft_results.add(this_nft.0);
          };
        };
        case (_) {};
      };

    };

    #Ok(Iter.toArray<Nat>(Iter.map<Text, Nat>(nft_results.vals(), func(x) { NFTUtils.get_token_id_as_nat(x) })));
  };

  /**
    * Returns the token identifiers of all tokens owned by a given owner.
    * @param {Principal} owner - The principal of the owner whose token identifiers will be returned.
    * @returns {DIP721.Metadata_1} The token identifiers of all tokens owned by the specified owner.
    */
  public query (msg) func dip721_owner_token_identifiers(owner : Principal) : async DIP721.DIP721TokensListMetadata {
    _dip_721_get_tokens(msg.caller, owner);
  };

  /**
    * Returns the token identifiers of all tokens for which a given principal is the operator.
    * @param {Principal} operator - The principal of the operator whose token identifiers will be returned.
    * @returns {DIP721.Metadata_1} The token identifiers of all tokens for which the specified principal is the operator.
    */
  public query (msg) func dip721_operator_token_identifiers(operator : Principal) : async DIP721.DIP721TokensListMetadata {
    _dip_721_get_tokens(msg.caller, operator);
  };

  // Pull a chunk of a nft library
  // The IC can only pull back ~2MB per request. This allows reading an entire library file by a user or canister
  /**
    * Pulls a chunk of an NFT library.
    *
    * @param {Types.ChunkRequest} request - The chunk request object.
    * @returns {async Types.ChunkResult} - The chunk content or an error.
    */
  public query (msg) func chunk_nft_origyn(request : Types.ChunkRequest) : async Types.ChunkResult {
    //D.print("looking for a chunk" # debug_show(request));
    //check mint property

    debug if (debug_channel.function_announce) D.print("in chunk_nft_origyn");
    return Metadata.chunk_nft_origyn(get_state(), request, ?msg.caller);
  };

  /**
    * Secure access to chunks of an NFT library.
    *
    * @param {Types.ChunkRequest} request - The chunk request object.
    * @returns {async Types.ChunkResult} - The chunk content or an error.
    */
  public shared (msg) func chunk_secure_nft_origyn(request : Types.ChunkRequest) : async Types.ChunkResult {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    debug if (debug_channel.function_announce) D.print("in chunk_secure_nft_origyn");
    return Metadata.chunk_nft_origyn(get_state(), request, ?msg.caller);
  };

  // Cleans access keys
  /**
    * Cleans expired access keys.
    *
    * @param {Types.State} state - The state object.
    * @returns {void}
    */
  private func clearAccessKeysExpired(state : Types.State) {
    let max_size = 20000;
    if (Map.size(state.state.access_tokens) > max_size) {
      Iter.iterate<Text>(
        Map.keys(state.state.access_tokens),
        func(key, _index) {
          switch (Map.get<Text, MigrationTypes.Current.HttpAccess>(state.state.access_tokens, thash, key)) {
            case (null) {};
            case (?item) {
              if (item.expires < get_time()) {
                Map.delete(state.state.access_tokens, thash, key);
              };
            };
          };
        },
      );
    };
  };

  let access_expiration = (1000 * 360 * (1_000_000)); //360s

  // Registers a principal with a access key so a user can use that key to make http queries
  /**
    * Generates an HTTP access key for a user, and stores it in the canister's state.
    * @returns {Types.OrigynTextResult} A `Result` object containing the generated access key, or an error message.
    */
  public shared (msg) func http_access_key() : async Types.OrigynTextResult {

    if (halt == true) { throw Error.reject("canister is in maintenance mode") };
    debug if (debug_channel.function_announce) D.print("in http_access_key");
    // nyi: spam prevention
    if (Principal.isAnonymous(msg.caller)) {
      return #err(Types.errors(?get_state().canistergeekLogger, #unauthorized_access, "http_access_key - anon not allowed", ?msg.caller));
    };
    let state = get_state();
    clearAccessKeysExpired(state);

    let access_key = (await* http.gen_access_key()) # Nat32.toText(Text.hash(debug_show (msg.caller, Time.now())));

    ignore Map.put<Text, MigrationTypes.Current.HttpAccess>(
      state.state.access_tokens,
      thash,
      access_key,
      {
        identity = msg.caller;
        expires = state.get_time() + access_expiration;
      },
    );

    #ok(access_key);
  };

  // Gets an access key for a user
  /**
    * Retrieves the HTTP access key associated with the caller's identity, if it exists.
    * @returns {Types.OrigynTextResult} A `Result` object containing the access key, or an error message if it was not found.
    */
  public query (msg) func get_access_key() : async Types.OrigynTextResult {
    debug if (debug_channel.function_announce) D.print("in get_access_key");
    //optimization: use a Map
    let state = get_state();
    for ((key, info) in Map.entries(state.state.access_tokens)) {
      if (Principal.equal(info.identity, msg.caller)) {
        return #ok(key);
      };
    };

    #err(Types.errors(?get_state().canistergeekLogger, #property_not_found, "access key not found by caller", ?msg.caller));
  };

  // Handles http request
  /**
    * Handles an HTTP request.
    * @param {Types.HttpRequest} rawReq - The HTTP request to handle.
    * @returns {http.HTTPResponse} An `HTTPResponse` object containing the response data for the request.
    */
  public query (msg) func http_request(rawReq : Types.HttpRequest) : async (http.HTTPResponse) {

    debug if (debug_channel.function_announce) D.print("in http_request");
    return http.http_request(get_state(), rawReq, msg.caller);
  };

  // A streaming callback based on NFTs. Returns {[], null} if the token can not be found.
  // Expects a key of the following pattern: "nft/{key}".
  /**
    * A streaming callback based on NFTs. Returns {[], null} if the token can not be found.
    * Expects a key of the following pattern: "nft/{key}".
    * @param tk - The streaming callback token
    * @returns The streaming callback response
    */
  public query func nftStreamingCallback(tk : http.StreamingCallbackToken) : async http.StreamingCallbackResponse {

    debug if (debug_channel.streaming) D.print("The nftstreamingCallback " # debug_show (debug_show (tk)));
    debug if (debug_channel.function_announce) D.print("in chunk_nft_origyn");

    return http.nftStreamingCallback(tk, get_state());
  };

  // Handles streaming
  /**
    * Handles streaming requests
    * @param tk - The streaming callback token
    * @returns The streaming callback response
    */
  public query func http_request_streaming_callback(tk : http.StreamingCallbackToken) : async http.StreamingCallbackResponse {
    return http.http_request_streaming_callback(tk, get_state());
  };

  /**
    * Returns the caller's Principal ID
    * @returns The caller's Principal ID
    */
  public query (msg) func whoami() : async (Principal) { msg.caller };

  // Returns the status of the gateway canister
  /**
    * Returns the status of the gateway canister
    * @param request - The canister ID of the gateway
    * @returns The status of the gateway canister
    */
  public shared func canister_status(request : { canister_id : Types.canister_id }) : async Types.canister_status {
    await ic.canister_status(request);
  };

  // Reports cylces
  /**
    * Reports the cycles available for this canister
    * @returns The available cycles
    */
  public query func cycles() : async Nat {
    Cycles.balance();
  };

  // Returns storage metrics for this server
  /**
    * Returns storage metrics for this server
    * @returns The storage metrics for this server
    */
  public query func storage_info_nft_origyn() : async Types.StorageMetricsResult {
    // Warning: this func does not use msg.caller. If that changes, fix secure query

    debug if (debug_channel.function_announce) D.print("in storage_info_nft_origyn");

    let state = get_state();
    return #ok({
      allocated_storage = state.state.canister_allocated_storage;
      available_space = state.state.canister_availible_space;
      gateway = state.canister();
      allocations = Iter.toArray<Types.AllocationRecordStable>(Iter.map<Types.AllocationRecord, Types.AllocationRecordStable>(Map.vals<(Text, Text), Types.AllocationRecord>(state.state.allocations), Types.allocation_record_stabalize));
    });
  };

  // Secure access to storage info
  /**
    * Secure access to storage metrics for this server
    * @returns The storage metrics for this server
    */
  public shared (msg) func storage_info_secure_nft_origyn() : async Types.StorageMetricsResult {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    debug if (debug_channel.function_announce) D.print("in storage_info_secure_nft_origyn");
    return await storage_info_nft_origyn();
  };

  /**
    * Returns metadata for ext
    * @param token - The token identifier
    * @returns The metadata for ext
    */
  public query func metadataExt(token : Types.EXTTokenIdentifier) : async Types.EXTMetadataResult {

    debug if (debug_channel.function_announce) D.print("in metadata");

    let token_id = switch (Owner.getNFTForTokenIdentifier(get_state(), token)) {
      case (#ok(data)) {
        data;
      };
      case (#err(err)) {
        return #err(#InvalidToken(token));
      };
    };

    return #ok(#nonfungible({ metadata = ?Text.encodeUtf8("https://prptl.io/-/" # Principal.toText(get_canister()) # "/-/" # token_id) }));
  };
  /*
    return #ok({
                fields = fields;
                logo = state.state.collection_data.logo;
                name =
                symbol = state.state.collection_data.symbol;
                total_supply = ?keys.size();
                owner = ?get_state().state.collection_data.owner;
                managers = ?get_state().state.collection_data.managers;
                network = state.state.collection_data.network;
                token_ids = ?keys;
                token_ids_count = ?keys.size();
                multi_canister = ?multi_canister;
                multi_canister_count = ?multi_canister.size();
                metadata = Map.get(state.state.nft_metadata, Map.thash, "");
                allocated_storage = ?get_state().state.collection_data.allocated_storage;
                available_space = ?get_state().state.collection_data.available_space;
            }
        );
*/

  //metadata for DIP721

  /**
    * Returns the name of the DIP721 collection.
    * @returns {?Text} The name of the DIP721 collection.
    */
  public query func dip721_name() : async ?Text {
    return get_state().state.collection_data.name;
  };

  /**
    * Returns the logo of the DIP721 collection.
    * @returns {?Text} The logo of the DIP721 collection.
    */
  public query func dip721_logo() : async ?Text {
    return get_state().state.collection_data.logo;
  };

  /**
    * Returns the symbol of the DIP721 collection.
    * @returns {?Text} The symbol of the DIP721 collection.
    */
  public query func dip721_symbol() : async ?Text {
    return get_state().state.collection_data.symbol;
  };

  /**
    * Returns the list of custodians for the DIP721 collection.
    * @returns {[Principal]} The list of custodians for the DIP721 collection.
    */
  public query func dip721_custodians() : async [Principal] {
    return get_state().state.collection_data.managers;
  };

  /**
    * Returns the metadata of the DIP721 collection.
    * @returns {DIP721.Metadata} The metadata of the DIP721 collection.
    */
  public query func metadata() : async DIP721.DIP721Metadata {
    let state = get_state();
    return {
      logo = state.state.collection_data.logo;
      name = state.state.collection_data.name;
      created_at = created_at;
      upgraded_at = upgraded_at;
      custodians = state.state.collection_data.managers;
      symbol = state.state.collection_data.symbol;
    };
  };

  /**
    * Returns the metadata of the DIP721 collection.
    * @returns {DIP721.Metadata} The metadata of the DIP721 collection.
    */
  public query func dip721_metadata() : async DIP721.DIP721Metadata {
    let state = get_state();
    return {
      logo = state.state.collection_data.logo;
      name = state.state.collection_data.name;
      created_at = created_at;
      upgraded_at = upgraded_at;
      custodians = state.state.collection_data.managers;
      symbol = state.state.collection_data.symbol;
    };
  };

  /**
    * Returns the total supply of the DIP721 collection.
    * @returns {Nat} The total supply of the DIP721 collection.
    */
  public query (msg) func dip721_total_supply() : async Nat {

    let state = get_state();
    let keys = if (NFTUtils.is_owner_manager_network(get_state(), msg.caller) == true) {
      Iter.toArray<Text>(Iter.filter<Text>(Map.keys(state.state.nft_metadata), func(x : Text) { x != "" })); // Should always have the "" item and need to remove it
    } else {
      Iter.toArray<Text>(Iter.filter<Text>(Map.keys(state.state.nft_ledgers), func(x : Text) { x != "" })); // Should always have the "" item and need to remove it
    };
    return keys.size();
  };

  /**
    * Returns the total number of transactions of the DIP721 collection.
    * @returns {Nat} The total number of transactions of the DIP721 collection.
    */
  public query (msg) func dip721_total_transactions() : async Nat {
    let state = get_state();
    let count = SB.size(state_current.master_ledger);
    return count;
  };

  /**
    * Returns the statistics of the DIP721 collection.
    * @returns {DIP721.Stats} The statistics of the DIP721 collection.
    */
  public query (msg) func dip721_stats() : async DIP721.DIP721Stats {

    debug if (debug_channel.function_announce) D.print("in collection_nft_origyn");

    let state = get_state();
    let keys = if (NFTUtils.is_owner_manager_network(state, msg.caller) == true) {
      Iter.filter<Text>(Map.keys(state.state.nft_metadata), func(x : Text) { x != "" }); // Should always have the "" item and need to remove it
    } else {
      Iter.filter<Text>(Map.keys(state.state.nft_ledgers), func(x : Text) { x != "" }); // Should always have the "" item and need to remove it
    };

    let ownerSet = Set.new<MigrationTypes.Current.Account>();
    let keysBuffer = Buffer.Buffer<Text>(Map.size(state.state.nft_metadata));
    for (thisItem in keys) {
      keysBuffer.add(thisItem);
      let entry = switch (Map.get<Text, CandyTypes.CandyShared>(state.state.nft_metadata, thash, thisItem)) {
        case (?val) val;
        case (null) #Option(null);
      };

      switch (Metadata.get_nft_owner(entry)) {
        case (#ok(account)) {
          Set.add<MigrationTypes.Current.Account>(ownerSet, (MigrationTypes.Current.account_hash, MigrationTypes.Current.account_eq), account);
        };
        case (#err(err)) {};
      };
    };

    let keysArray = Buffer.toArray(keysBuffer);

    return {
      cycles = Cycles.balance();
      total_supply = keysArray.size();
      total_unique_holders = Set.size(ownerSet);
      total_transactions = SB.size(state.state.master_ledger);
    };
  };

  /**
    * Returns the list of supported interfaces for the DIP721 collection.
    * @returns {[DIP721.SupportedInterface]} The list of supported interfaces for the DIP721 collection.
    */
  public query (msg) func dip721_supported_interfaces() : async [DIP721.DIP721SupportedInterface] {
    return [#TransactionHistory];
  };

  // *************************
  // ***** ICRC7 *****
  // *************************

  public query (msg) func icrc7_collection_metadata() : async ICRC7.CollectionMetadata {

    let state = get_state();

    let aBuf = Buffer.Buffer<(Text, ICRC7.Value)>(1);

    let metadata = switch (Metadata.get_metadata_for_token(state, "", msg.caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#ok(val)) val;
      case (#err(err)) D.trap("Cannot find metadata for collection " # debug_show (err));
    };

    let description : Text = switch (Properties.getClassPropertyShared(metadata, Types.metadata.icrc7_description)) {
      case (null) { "N/A" };
      case (?val) {
        switch (val.value) {
          case (#Text(val)) val;
          case (_) "Misconfigured";
        };
      };
    };

    aBuf.add(("icrc7:description", #Text(description)));

    let keys = if (NFTUtils.is_owner_manager_network(state, msg.caller) == true) {
      Iter.filter<Text>(Map.keys(state.state.nft_metadata), func(x : Text) { x != "" }); // Should always have the "" item and need to remove it
    } else {
      Iter.filter<Text>(Map.keys(state.state.nft_ledgers), func(x : Text) { x != "" }); // Should always have the "" item and need to remove it
    };

    let name = Option.get<Text>(state.state.collection_data.name, Principal.toText(state.canister()));

    let symbol = Option.get<Text>(state.state.collection_data.symbol, Principal.toText(state.canister()));
    let logo = Option.get<Text>(state.state.collection_data.logo, "");

    aBuf.add(("icrc7:name", #Text(name)));
    aBuf.add(("icrc7:symbol", #Text(symbol)));
    aBuf.add(("icrc7:total_supply", #Nat(Iter.size(keys))));
    aBuf.add(("icrc7:logo", #Text(logo)));

    return Buffer.toArray(aBuf);
  };

  public query (msg) func icrc7_name() : async Text {

    let state = get_state();
    Option.get<Text>(state.state.collection_data.name, Principal.toText(state.canister()));
  };

  public query (msg) func icrc7_symbol() : async Text {

    let state = get_state();
    Option.get<Text>(state.state.collection_data.symbol, Principal.toText(state.canister()));
  };

  /* public query(msg) func icrc7_royalty() : async ?Nat16{

      let state = get_state();

      let #ok(metadata) = Metadata.get_metadata_for_token(state, "", state.canister(), ?state.canister(), state.state.collection_data.owner) else D.trap("Cannot find metadata for collection");

      let royalty : Nat16 = switch(Properties.getClassPropertyShared(metadata, Types.metadata.__system)){
        case(null){0;};
        case(?val){
          let thearray = Market.royalty_to_array(val.value, Types.metadata.__system_secondary_royalty);

          var sum_rate : Float = 0;
          label royaltyLoop for(thisItem in thearray.vals()){
            let #Class(items) = thisItem else continue royaltyLoop;

            let rate = switch(Properties.getClassPropertyShared(thisItem, "rate")){
              case(null){0:Float};
              case(?val){
                switch(val.value){
                  case(#Float(val)) val;
                  case(_) 0:Float;
                };
              };
            };


            sum_rate += rate;
            debug if (debug_channel.calcs) D.print(debug_show((rate,sum_rate)));
          };


          debug if (debug_channel.calcs) D.print(debug_show((sum_rate)));

          Nat16.fromNat(Int.abs(Float.toInt(sum_rate * 10000)));
        };
      };

      ?royalty;
    };

    public query(msg) func icrc7_royalty_recipient() : async ?ICRC7.Account{
      //construct a recieving account for royalties...this should not be used, but should be reserved for identifying interface non-compliance
      let state = get_state();

      let royalty_account = NFTUtils.get_icrc7_royalty_account(state.canister()).account;

      ?{
        owner = royalty_account.principal;
        subaccount = ?royalty_account.sub_account;
      };
    }; */

  public query (msg) func icrc7_description() : async ?Text {
    let state = get_state();

    let metadata = switch (Metadata.get_metadata_for_token(state, "", msg.caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#ok(val)) val;
      case (#err(err)) D.trap("Cannot find metadata for collection " # debug_show (err));
    };

    let description : Text = switch (Properties.getClassPropertyShared(metadata, Types.metadata.icrc7_description)) {
      case (null) { "N/A" };
      case (?val) {
        switch (val.value) {
          case (#Text(val)) val;
          case (_) "Misconfigured";
        };
      };
    };

    ?description;
  };

  public query (msg) func icrc7_logo() : async ?Text {
    let state = get_state();
    state.state.collection_data.logo;
  };

  public query (msg) func icrc7_total_supply() : async Nat {

    let state = get_state();

    let keys = if (NFTUtils.is_owner_manager_network(state, msg.caller) == true) {
      Iter.filter<Text>(Map.keys(state.state.nft_metadata), func(x : Text) { x != "" }); // Should always have the "" item and need to remove it
    } else {
      Iter.filter<Text>(Map.keys(state.state.nft_ledgers), func(x : Text) { x != "" }); // Should always have the "" item and need to remove it
    };

    Iter.size(keys);
  };

  public query (msg) func icrc7_supply_cap() : async ?Nat {
    null;
  };
  public query (msg) func icrc7_max_approvals_per_token_or_collection() : async ?Nat {
    null;
  };
  public query (msg) func icrc7_max_query_batch_size() : async ?Nat {
    null;
  };
  public query (msg) func icrc7_max_update_batch_size() : async ?Nat {
    null;
  };
  public query (msg) func icrc7_default_take_value() : async ?Nat {
    null;
  };
  public query (msg) func icrc7_max_take_value() : async ?Nat {
    null;
  };
  public query (msg) func icrc7_max_revoke_approvals() : async ?Nat {
    null;
  };
  public query (msg) func icrc7_max_memo_size() : async ?Nat {
    null;
  };

  public query (msg) func icrc7_token_metadata(token_ids : [Nat]) : async [(Nat, ?(Text, ICRC7.Value))] {

    let state = get_state();

    let aBuf = Buffer.Buffer<(Nat, ?(Text, ICRC7.Value))>(token_ids.size());

    for (token_id in token_ids.vals()) {

      switch (Metadata.get_metadata_for_token(state, NFTUtils.get_nat_as_token_id(token_id), state.canister(), ?state.canister(), state.state.collection_data.owner)) {
        case (#ok(metadata)) {
          let json = JSON.value_to_json(Metadata.get_clean_metadata(metadata, msg.caller));

          aBuf.add((token_id), ?("com.origyn.nft.metadata.json", #Text(json)));
        };
        case (_) {
          aBuf.add((token_id), null);
        };
      };
    };

    return Buffer.toArray<(Nat, ?(Text, ICRC7.Value))>(aBuf);
  };

  public query (msg) func icrc7_owner_of(token_ids : [Nat]) : async [{
    token_id : Nat;
    account : ?ICRC7.Account;
  }] {

    let state = get_state();

    let aBuf = Buffer.Buffer<{ token_id : Nat; account : ?ICRC7.Account }>(token_ids.size());

    for (token_id in token_ids.vals()) {

      switch (Metadata.get_metadata_for_token(state, NFTUtils.get_nat_as_token_id(token_id), msg.caller, ?state.canister(), state.state.collection_data.owner)) {
        case (#ok(metadata)) {
          switch (
            Metadata.get_nft_owner(metadata)
          ) {
            case (#err(err)) {
              aBuf.add({ token_id = token_id; account = null });
            };
            case (#ok(val)) {
              switch (val) {
                case (#principal(data)) {
                  aBuf.add({
                    token_id = token_id;
                    account = ?{
                      owner = data;
                      subaccount = null;
                    };
                  });
                };
                case (#account(data)) {
                  aBuf.add({
                    token_id = token_id;
                    account = ?{
                      owner = data.owner;
                      subaccount = data.sub_account;
                    };
                  });
                };
                case (_) {
                  aBuf.add({ token_id = token_id; account = null });
                };
              };
            };
          };
        };
        case (_) {
          aBuf.add({ token_id = token_id; account = null });
        };
      };
    };

    return Buffer.toArray(aBuf);

  };

  public query (msg) func icrc7_balance_of(account : ICRC7.Account) : async Nat {

    let state = get_state();

    Metadata.get_NFTs_for_user(get_state(), #account({ owner = account.owner; sub_account = account.subaccount })).size();
  };

  public query (msg) func icrc7_tokens(prev : ?Nat, take : ?Nat32) : async [Nat] {
    //prev and take are unimplemented
    let state = get_state();

    let keys = if (NFTUtils.is_owner_manager_network(state, msg.caller) == true) {
      Iter.filter<Text>(Map.keys(state.state.nft_metadata), func(x : Text) { x != "" }); // Should always have the "" item and need to remove it
    } else {
      Iter.filter<Text>(Map.keys(state.state.nft_ledgers), func(x : Text) { x != "" }); // Should always have the "" item and need to remove it
    };

    let result = Iter.map<Text, Nat>(keys, NFTUtils.get_token_id_as_nat);

    return Iter.toArray<Nat>(result);
  };

  public query (msg) func icrc7_tokens_of(account : ICRC7.Account, prev : ?Nat, take : ?Nat32) : async [Nat] {
    //prev and take are unimplemented
    let state = get_state();

    let list = Metadata.get_NFTs_for_user(get_state(), #account({ owner = account.owner; sub_account = account.subaccount }));

    let result = Array.map<Text, Nat>(list, NFTUtils.get_token_id_as_nat);

    return result;
  };

  public shared (msg) func icrc7_transfer(request : ICRC7.TransferArgs) : async ICRC7.TransferResult {

    if (request.token_ids.size() != 1) {
      return D.trap("origyn_nft does not support batch transactions through ICRC7. use market_transfer_batch_nft_origyn");
    };

    let log_data : Text = "To :" # debug_show (request.to) # " - Token : " # Nat.toText(request.token_ids[0]);
    canistergeekLogger.logMessage("transferICRC7", #Text("transferICRC7"), ?msg.caller);
    canistergeekMonitor.collectMetrics();
    debug if (debug_channel.function_announce) D.print("in transferICRC7");
    // Existing escrow acts as approval
    let result = await* Owner.transferICRC7(get_state(), request.from, request.to, request.token_ids[0], msg.caller);

    return [result];
  };

  public shared (msg) func icrc7_approve(request : ICRC7.ApprovalArgs) : async ICRC7.ApprovalResult {

    D.trap("origyn_nft does not support approvals through ICRC7. Approval is provided by precense of an escrow deposit. Use sale_info_nft_origyn(#escrow) to retrieve deposit info");

  };

  public query (msg) func icrc7_supported_standards() : async [ICRC7.SupportedStandard] {

    [
      { name = "ICRC-7"; url = "https://github.com/dfinity/ICRC/ICRCs/ICRC-7" },
      { name = "origyn_nft"; url = "https://github.com/origyn_sa/origyn_nft" },
    ];
  };

  // *************************
  // ******** BACKUP *********
  // *************************

  /**
    * Get the size of the state in terms of the number of elements in various maps.
    *
    * @param {Record<string,unknown>} msg - The request message.
    * @returns {Promise<Types.StateSize>} The size of the state.
    */
  public query (msg) func state_size() : async Types.StateSize {
    let state = get_state();

    return {
      buckets = Map.size(state.state.buckets);
      allocations = Map.size(state.state.allocations);
      escrow_balances = Map.size(state.state.escrow_balances);
      sales_balances = Map.size(state.state.sales_balances);
      offers = Map.size(state.state.offers);
      nft_ledgers = Map.size(state.state.nft_ledgers);
      nft_sales = Map.size(state.state.nft_sales);
    };
  };

  /**
    * Get a backup chunk of the NFT data for a specified page.
    *
    * @param {number} page - The page to get the backup chunk for.
    * @param {Record<string,unknown>} msg - The request message.
    * @returns {Promise<{ eof: Types.NFTBackupChunk, data: Types.NFTBackupChunk }>} The backup chunk, which can be either the data or the end-of-file (EOF) marker.
    */
  public query (msg) func back_up(page : Nat) : async {
    #eof : Types.NFTBackupChunk;
    #data : Types.NFTBackupChunk;
  } {
    if (NFTUtils.is_owner_manager_network(get_state(), msg.caller) == false) {
      throw Error.reject("Not the admin");
    };

    let targetStart = page * data_harvester_page_size;
    let targetEnd = targetStart + data_harvester_page_size;
    var globalTracker = 0;

    let state = get_state();
    let owner = state.state.collection_data.owner;

    // *** Buckets ***
    var buckets : [(Principal, Types.StableBucketData)] = [];
    let buckets_size = Map.size(state.state.buckets);
    let buckets_buffer = Buffer.Buffer<(Principal, Types.StableBucketData)>(buckets_size);
    if (targetStart < globalTracker + buckets_size and targetEnd > globalTracker) {
      for ((key, value) in Map.entries(state.state.buckets)) {
        if (globalTracker >= targetStart and targetEnd > globalTracker) {
          var val = Types.stabilize_bucket_data(value);
          var e = (key, val);
          buckets_buffer.add(e);
          // buckets := Array.append<(Principal, Types.StableBucketData)>(buckets,[e]);
        };
        globalTracker += 1;
      };
      buckets := Buffer.toArray(buckets_buffer);
    } else {
      globalTracker += buckets_size;
    };

    // *** Allocations ***
    var allocations : [((Text, Text), Types.AllocationRecordStable)] = [];
    let allocations_size = Map.size(state.state.allocations);
    let allocations_buffer = Buffer.Buffer<((Text, Text), Types.AllocationRecordStable)>(allocations_size);
    if (targetStart < globalTracker + allocations_size and targetEnd > globalTracker) {
      for ((key, value) in Map.entries(state.state.allocations)) {
        if (globalTracker >= targetStart and targetEnd > globalTracker) {
          var val = Types.allocation_record_stabalize(value);
          var e = (key, val);
          // allocations := Array.append<((Text,Text), Types.AllocationRecordStable)>(allocations,[e]);
          allocations_buffer.add(e);
        };
        globalTracker += 1;
      };
      allocations := Buffer.toArray(allocations_buffer);
    } else {
      globalTracker += allocations_size;
    };

    // *** Escrow Balances ***
    var escrows : Types.StableEscrowBalances = [];
    let escrows_size = Map.size(state.state.escrow_balances);
    let escrows_buffer = Buffer.Buffer<(Types.Account, Types.Account, Text, Types.EscrowRecord)>(escrows_size);
    if (targetStart < globalTracker + escrows_size and targetEnd > globalTracker) {
      for ((acc_top_key, acc_top_val) in Map.entries(state.state.escrow_balances)) {
        if (globalTracker >= targetStart and targetEnd > globalTracker) {
          for ((acc_mid_key, acc_mid_val) in Map.entries(acc_top_val)) {
            for ((tok_id_key, tok_id_val) in Map.entries(acc_mid_val)) {
              for ((token_spec_key, token_spec_val) in Map.entries(tok_id_val)) {
                // Get escrow record
                // escrows := Array.append<(Types.Account,Types.Account,Text,Types.EscrowRecord)>(escrows, [(acc_top_key, acc_mid_key,tok_id_key,token_spec_val)]);
                escrows_buffer.add((acc_top_key, acc_mid_key, tok_id_key, token_spec_val));
              };
            };
          };
        };

        globalTracker += 1;
      };
      escrows := Buffer.toArray(escrows_buffer);
    } else {
      globalTracker += escrows_size;
    };

    // *** Sales Balances ***
    var sales : Types.StableSalesBalances = [];
    let sales_size = Map.size(state.state.sales_balances);
    let sales_buffer = Buffer.Buffer<(Types.Account, Types.Account, Text, Types.EscrowRecord)>(sales_size);
    if (targetStart < globalTracker + sales_size and targetEnd > globalTracker) {
      for ((acc_top_key, acc_top_val) in Map.entries(state.state.sales_balances)) {
        if (globalTracker >= targetStart and targetEnd > globalTracker) {
          for ((acc_mid_key, acc_mid_val) in Map.entries(acc_top_val)) {
            for ((tok_id_key, tok_id_val) in Map.entries(acc_mid_val)) {
              for ((token_spec_key, token_spec_val) in Map.entries(tok_id_val)) {
                // Get escrow record
                // sales := Array.append<(Types.Account,Types.Account,Text,Types.EscrowRecord)>(sales, [(acc_top_key,acc_mid_key,tok_id_key,token_spec_val)]);
                sales_buffer.add((acc_top_key, acc_mid_key, tok_id_key, token_spec_val));
              };
            };
          };
        };
        globalTracker += 1;
      };
      sales := Buffer.toArray(sales_buffer);
    } else {
      globalTracker += sales_size;
    };

    // *** Offers ***
    var offers : Types.StableOffers = [];
    let offers_size = Map.size(state.state.offers);
    let offers_buffer = Buffer.Buffer<(Types.Account, Types.Account, Int)>(offers_size);
    if (targetStart < globalTracker + offers_size and targetEnd > globalTracker) {
      for ((acc_top_key, acc_top_val) in Map.entries(state.state.offers)) {
        if (globalTracker >= targetStart and targetEnd > globalTracker) {
          for ((acc_mid_key, acc_mid_val) in Map.entries(acc_top_val)) {
            // offers := Array.append<(Types.Account,Types.Account,Int)>(offers, [(acc_top_key,acc_mid_key,acc_mid_val)]);
            offers_buffer.add((acc_top_key, acc_mid_key, acc_mid_val));
          };
        };
        globalTracker += 1;
      };
      offers := Buffer.toArray(offers_buffer);
    } else {
      globalTracker += offers_size;
    };

    // *** NFT ledgers ***
    var nft_ledgers : Types.StableNftLedger = [];
    let nft_ledgers_size = Map.size(state.state.nft_ledgers);
    let nft_ledgers_buffer = Buffer.Buffer<(Text, MigrationTypes.Current.TransactionRecord)>(nft_ledgers_size);
    if (targetStart < globalTracker + nft_ledgers_size and targetEnd > globalTracker) {
      for ((tok_key, tok_val) in Map.entries(state.state.nft_ledgers)) {
        if (globalTracker >= targetStart and targetEnd > globalTracker) {
          let recordsArr = SB.toArray(tok_val);
          for (this_item in recordsArr.vals()) {
            // nft_ledgers := Array.append<(Text, MigrationTypes.Current.TransactionRecord)>(nft_ledgers, [(tok_key,this_item)]);
            nft_ledgers_buffer.add((tok_key, this_item));
          };
        };
        globalTracker += 1;
      };
      nft_ledgers := Buffer.toArray(nft_ledgers_buffer);
    } else {
      globalTracker += nft_ledgers_size;
    };

    // *** NFT Sales ***
    var nft_sales : Types.StableNftSales = [];
    let nft_sales_size = Map.size(state.state.nft_sales);
    let nft_sales_buffer = Buffer.Buffer<(Text, Types.SaleStatusShared)>(nft_sales_size);
    if (targetStart < globalTracker + nft_sales_size and targetEnd > globalTracker) {
      for ((key, val) in Map.entries(state.state.nft_sales)) {
        if (globalTracker >= targetStart and targetEnd > globalTracker) {
          let stableSale = Types.SalesStatus_stabalize_for_xfer(val);
          // nft_sales := Array.append<(Text, Types.SaleStatusShared)>(nft_sales, [(key,stableSale)]);
          nft_sales_buffer.add((key, stableSale));
        };
        globalTracker += 1;
      };
      nft_sales := Buffer.toArray(nft_sales_buffer);
    } else {
      globalTracker += nft_sales_size;
    };

    if (globalTracker > targetStart and globalTracker <= targetEnd) {
      //we have reached the eof.
      return #eof({
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

    return #data({
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

  /**
    * Returns an array of tuples representing supported interfaces.
    * @returns {Array<[Text, Text]>} - An array of tuples representing supported interfaces.
    */
  public query func __supports() : async [(Text, Text)] {
    [
      ("nft_origyn", "v0.1.0"),
      ("data_nft_origyn", "v0.1.0"),
      ("collection_nft_origyn", "v0.1.0"),
      ("mint_nft_origyn", "v0.1.0"),
      ("owner_nft_origyn", "v0.1.0"),
      ("market_nft_origyn", "v0.1.0"),
    ];
  };

  public query func __version() : async Text {
    "0.1.5";
  };

  /**
    * Lets the NFT accept cycles.
    * @returns {Nat} - The amount of cycles accepted.
    */
  public func wallet_receive() : async Nat {
    let amount = Cycles.available();
    let accepted = amount;
    let deposit = Cycles.accept(accepted);
    accepted;
  };

  // *************************
  // ***** CANISTER GEEK *****
  // *************************

  // METRICS

  /**
    * Returns canister metrics.
    * @param {Canistergeek.GetMetricsParameters} parameters - Parameters for getting canister metrics.
    * @returns {?Canistergeek.CanisterMetrics} - Canister metrics or null if not found.
    */
  public query (msg) func getCanisterMetrics(parameters : Types.Canistergeek.GetMetricsParameters) : async ?Types.Canistergeek.CanisterMetrics {

    canistergeekMonitor.getMetrics(parameters);
  };

  /**
    * Collects canister metrics.
    * @returns {null}
    */
  public query (msg) func collectCanisterMetrics() : async () {
    canistergeekMonitor.collectMetrics();
  };

  // LOGGER
  /**
    * Returns canister log.
    * @param {?Canistergeek.CanisterLogRequest} request - A request object for getting canister log.
    * @returns {?Canistergeek.CanisterLogResponse} - Canister log or null if not found.
    */
  public query func getCanisterLog(request : ?Types.Canistergeek.CanisterLogRequest) : async ?Types.Canistergeek.CanisterLogResponse {

    canistergeekLogger.getLog(request);
  };

  // *************************
  // *** END CANISTER GEEK ***
  // *************************

  /**
    * Returns an array of tuples representing the nft library.
    * @returns {Future<Array<[Text, Array<[Text, CandyTypes.AddressedChunkArray]>]>>} - A promise that resolves to an array of tuples representing the nft library.
    */
  /*
    public query func show_nft_library_array() : async  [(Text, [(Text, CandyTypes.AddressedChunkArray)])] {
        let nft_library_stable_buffer = Buffer.Buffer<(Text, [(Text, CandyTypes.AddressedChunkArray)])>(nft_library.size());
        for(thisKey in nft_library.entries()){
            let thisLibrary_buffer : Buffer.Buffer<(Text, CandyTypes.AddressedChunkArray)> = Buffer.Buffer<(Text, CandyTypes.AddressedChunkArray)>(thisKey.1.size());
            for(thisItem in thisKey.1.entries()){
                thisLibrary_buffer.add((thisItem.0, Workspace.workspaceToAddressedChunkArray(thisItem.1)) );
            };
            nft_library_stable_buffer.add((thisKey.0, thisLibrary_buffer.toArray()));
        };
        Buffer.toArray(nft_library_stable_buffer);
    };
    */

  system func preupgrade() {

    //todo: significant maitenance needed in 0.1.5- consider moving into migration

    // Canistergeek
    _canistergeekMonitorUD_0_1_4 := ?canistergeekMonitor.preupgrade();
    _canistergeekLoggerUD_0_1_4 := ?canistergeekLogger.preupgrade();
    // End Canistergeek

    let nft_library_stable_buffer = Buffer.Buffer<(Text, [(Text, CandyTypes.AddressedChunkArray)])>(nft_library.size());

    for (thisKey in nft_library.entries()) {
      let this_library_buffer : Buffer.Buffer<(Text, CandyTypes.AddressedChunkArray)> = Buffer.Buffer<(Text, CandyTypes.AddressedChunkArray)>(thisKey.1.size());
      for (this_item in thisKey.1.entries()) {
        this_library_buffer.add((this_item.0, Workspace.workspaceToAddressedChunkArray(this_item.1)));
      };
      nft_library_stable_buffer.add((thisKey.0, Buffer.toArray(this_library_buffer)));
    };

    nft_library_stable_2 := Buffer.toArray(nft_library_stable_buffer);

  };

  system func postupgrade() {
    nft_library_stable := [];
    nft_library_stable_2 := [];

    // Canistergeek

    canistergeekMonitor.postupgrade(_canistergeekMonitorUD);
    _canistergeekMonitorUD := null;
    //upgrade canister geek data

    if (_canistergeekLoggerUD != null) {
      let newData = switch (_canistergeekLoggerUD) {
        case (null) {
          null;
        };
        case (?upgradeData) {
          switch (upgradeData) {
            case (#v1(data)) {
              let newLogBuffer = Buffer.Buffer<{ timeNanos : Nat64; message : Text; data : CandyTypes.CandyShared; caller : ?Principal }>(data.queue.size());

              for (thisItem in data.queue.vals()) {
                newLogBuffer.add({
                  timeNanos = thisItem.timeNanos;
                  message = thisItem.message;
                  caller = thisItem.caller;
                  data = CandyUpgrade.upgradeCandyShared(thisItem.data);
                });
              };

              ? #v1({
                queue = Buffer.toArray(newLogBuffer);
                maxCount = data.maxCount;
                next = data.next;
                full = data.full;
              });
            };
          };
        };
      };

      canistergeekLogger.postupgrade(newData);
      _canistergeekLoggerUD := null;
    } else {
      canistergeekLogger.postupgrade(_canistergeekLoggerUD_0_1_4);
      _canistergeekLoggerUD_0_1_4 := null;
    };

    //Optional: override default number of log messages to your value
    canistergeekLogger.setMaxMessagesCount(3000);

    upgraded_at := Nat64.fromNat(Int.abs(Time.now()));

    notify_timer := ?Timer.setTimer(#nanoseconds(1), handle_notify);

    // End Canistergeek

    if (SB.size(state_current.master_ledger) == 0) {
      ignore __implement_master_ledger();
    };
  };
};
