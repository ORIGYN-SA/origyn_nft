/// The entry point for an ORIGYN NFT actor
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import D "mo:base/Debug";
import Error "mo:base/Error";
import Int "mo:base/Int";
import List "mo:base/List";
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

import BytesConverter "mo:stableBTree/bytesConverter";

import CandyUpgrade "mo:candy_0_2_0/upgrade";

import Droute "mo:droute_client/Droute";
import ICRC7 "ICRC7";

import Map "mo:map9/Map";
import Set "mo:map9/Set";

import Star "mo:star/star";

//todo: remove in 0.1.5
import CandyTypesOld "mo:candy_0_1_12/types";

import Governance "governance";
import Market "market";
// import Fractionalize "fractionalize";
import Royalties "market/royalties";
import Metadata "metadata";
import MigrationTypes "./migrations/types";
import Migrations "./migrations";
import Mint "mint";
import NFTUtils "utils";
import Owner "owner";
import Types "./types";
import data "data";
import http "http";
import BlockTypes "ledger/block_types";

import StableBTree "mo:stableBTree/btreemap";
import MemoryManager "mo:stableBTree/memoryManager";
import Memory "mo:stableBTree/memory";

import ICRC3 "mo:icrc3-mo";
import CertifiedData "mo:base/CertifiedData";

import CertTree "mo:cert/CertTree";

shared (deployer) actor class Nft_Canister() = this {

  // Lets user turn debug messages on and off for local replica
  let debug_channel = {
    instantiation = false;
    upgrade = false;
    function_announce = false;
    storage = false;
    streaming = false;
    manage_storage = false;
    calcs = false;
    icrc7 = false;
  };

  let CandyTypes = MigrationTypes.Current.CandyTypes;

  let Properties = MigrationTypes.Current.Properties;
  let Workspace = MigrationTypes.Current.Workspace;
  let JSON = MigrationTypes.Current.JSON;
  let account_handler = MigrationTypes.Current.account_handler;

  debug if (debug_channel.instantiation) D.print("creating a canister");

  let { thash } = Map;

  // A standard file chunk size.  The IC limits intercanister messages to ~2MB+ so we set that here
  stable var SIZE_CHUNK = 2048000; //max message size
  stable let created_at = Nat64.fromNat(Int.abs(Time.now()));
  stable var upgraded_at = Nat64.fromNat(Int.abs(Time.now()));

  let OneDay = 60 * 60 * 24 * 1000000000;

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

  migration_state := Migrations.migrate(migration_state, #v0_1_7(#id), { owner = deployer.caller; storage_space = 0 }, deployer.caller);

  // Do not forget to change #v0_1_0 when you are adding a new migration
  let #v0_1_7(#data(state_current)) = migration_state;

  debug if (debug_channel.instantiation) D.print("finished migration");

  //let memory_manager = MemoryManager.init(Memory.STABLE_MEMORY);

  debug if (debug_channel.instantiation) D.print("have memory_manager");

  /**
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
  stable var nft_library_stable_2 : [(Text, [(Text, CandyTypes.AddressedChunkArray)])] = [];

  // Stores data for a library - unstable because it uses Candy Workspaces to hold active and maleable bits of data that can be manipulated in real time
  stable var nft_library : Map.Map<Text, Map.Map<Text, CandyTypes.Workspace>> = NFTUtils.build_library_new(nft_library_stable_2);

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

  var timertool : ?TimerTool.TimerTool = null;

  private func init_timertools() : TimerTool.TimerTool {
    switch (timertool) {
      case (?val) {
        val;
      };
      case (null) {
        let _timertool = TimerTool.TimerTool(state_current.timerState, Principal.fromActor(this), { advanced = null; reportExecution = null; reportError = null; syncUnsafe = null; reportBatch = null });
        _timertool.registerExecutionListenerAsync(?"close_sale_timeouted_nft_origyn", close_sale_timeouted_nft_origyn : TimerTool.ExecutionAsyncHandler);
        timertool := ?_timertool;

        _timertool;
      };
    };
  };

  // Let us access state and pass it to other modules
  let get_state : () -> Types.State = func() {
    let _timertool = init_timertools();

    {
      state = state_current;
      canister = get_canister;
      get_time = get_time;
      nft_library = nft_library;
      refresh_state = get_state;
      //btreemap = btreemap_;
      droute_client = state_current.droute;
      handle_notify = handle_notify;
      icrc3 = icrc3();
      notify_timer = {
        get = get_notify_timer;
        set = set_notify_timer;
      };
      timertool = _timertool;
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

  private var _icrc3 : ?ICRC3.ICRC3 = null;

  private func get_certificate_store() : CertTree.Store {
    return state_current.cert_store;
  };

  let ct = CertTree.Ops(state_current.cert_store);

  private func updated_certification(cert : Blob, lastIndex : Nat) : Bool {

    ct.setCertifiedData();

    return true;
  };

  private func get_icrc3_environment() : ICRC3.Environment {
    ?{
      updated_certification = ?updated_certification;
      get_certificate_store = ?get_certificate_store;
    };
  };

  func ensure_block_types(icrc3Class : ICRC3.ICRC3) : () {
    D.print("in ensure_block_types: ");
    let supportedBlocks = Buffer.fromIter<ICRC3.BlockType>(icrc3Class.supported_block_types().vals());

    let blockequal = func(a : { block_type : Text }, b : { block_type : Text }) : Bool {
      a.block_type == b.block_type;
    };

    for (thisItem in BlockTypes.supported_blocktypes().vals()) {
      if (Buffer.indexOf<ICRC3.BlockType>({ block_type = thisItem.0; url = thisItem.1 }, supportedBlocks, blockequal) == null) {
        supportedBlocks.add({ block_type = thisItem.0; url = thisItem.1 });
      };
    };

    icrc3Class.update_supported_blocks(Buffer.toArray(supportedBlocks));
  };

  func icrc3() : ICRC3.ICRC3 {
    switch (_icrc3) {
      case (null) {
        let initclass : ICRC3.ICRC3 = ICRC3.ICRC3(?state_current.icrc3_migration_state, Principal.fromActor(this), get_icrc3_environment());

        _icrc3 := ?initclass;
        ensure_block_types(initclass);

        initclass;
      };
      case (?val) val;
    };
  };

  private func get_notify_timer() : ?Nat {
    notify_timer;
  };

  private func set_notify_timer(val : ?Nat) : () {
    notify_timer := val;
  };

  func handle_notify() : async () {
    await Market.handle_notify(get_state());
  };

  // set the `data_havester`
  public shared (msg) func set_data_harvester(_page_size : Nat) : async () {
    if (NFTUtils.is_owner_manager_network(get_state(), msg.caller) == false) {
      throw Error.reject("Not the admin");
    };

    data_harvester_page_size := _page_size;
  };

  // set the `data_havester`
  public shared (msg) func update_icrc3(settings : [ICRC3.UpdateSetting]) : async [Bool] {
    if (NFTUtils.is_owner_network(get_state(), msg.caller) == false) {
      throw Error.reject("Not the admin");
    };

    return icrc3().update_settings(settings);
  };

  // set the `halt`
  public shared (msg) func set_halt(bHalt : Bool) : async () {

    if (NFTUtils.is_owner_network(get_state(), msg.caller) == false) {
      throw Error.reject("not the admin");
    };

    halt := bHalt;
  };

  public query func get_halt() : async Bool {
    halt;
  };

  // maintenance function for updating ledgers
  /* private func __implement_master_ledger() : Bool {

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
      };
    );

    state_current.master_ledger := SB.fromArray<MigrationTypes.Current.TransactionRecord>(Buffer.toArray(master_ledger));

    return true;
  }; */

  private func __implement_icrc3<system>() : Bool {

    if (icrc3().stats().lastIndex > 0) return false;

    var last_phash : ?Blob = null;
    for (thisItem in SB.vals(state_current.master_ledger)) {

      let block = BlockTypes.upgrade_block_to_icrc3(thisItem, last_phash);
      let newIndex = icrc3().add_record<system>(block.0, block.1);
      last_phash := icrc3().get_state().latest_hash;
    };

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
        // NFTUtils.logDirectly("update_app_nft_origyn", log_data, ?msg.caller);
      };
      case (#update(val)) {
        var update_data = val.token_id;
        // NFTUtils.logDirectly("update_app_nft_origyn", update_data, ?msg.caller);
      };
    };

    return data.update_app_nft_origyn(request, get_state(), msg.caller);
  };

  /**
    * Updates the entire API nodes with the given NFT update request data.
    *
    * @param {Types.NFTUpdateRequest} request - The request data for the NFT update.
    * @returns {Promise<Types.NFTUpdateResult>} - A promise that resolves to a Result object containing either the NFT update response or an OrigynError.
    * @throws {Error} - Throws an error if the canister is in maintenance mode.
    */
  public shared (msg) func update_metadata_node(request : Types.NFTUpdateMetadataNode) : async Types.NFTUpdateAppResult {
    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    return await* data.update_metadata_node(get_state(), request, msg.caller);
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
    // NFTUtils.logDirectly("stage_nft_origyn", metadata, ?msg.caller);

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
      return [#err(Types.errors(#unauthorized_access, "stage_batch_nft_origyn - not an owner, manager, or network", ?msg.caller))];
    };

    let results = Buffer.Buffer<Types.OrigynTextResult>(request.size());
    for (this_item in request.vals()) {
      // Logs
      // NFTUtils.logDirectly("stage_batch_nft_origyn", this_item.metadata, ?msg.caller);
      //nyi: should probably check for some spammy things and bail if too many errors
      results.add(Mint.stage_nft_origyn(get_state(), this_item.metadata, msg.caller));
    };

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
    NFTUtils.logDirectly("stage_library_nft_origyn", #Text(log_data), ?msg.caller);

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
      NFTUtils.logDirectly("stage_library_batch_nft_origyn", #Text(log_data), ?msg.caller);
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

    let a = Principal.toText(new_owner.owner);
    NFTUtils.logDirectly("mint_nft_origyn", #Text(token_id # " new owner : " # a), ?msg.caller);

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
      return [#err(Types.errors(#unauthorized_access, "mint_nft_origyn - not an owner", ?msg.caller))];
    };
    debug if (debug_channel.function_announce) D.print("in mint batch");
    let results = Buffer.Buffer<Result.Result<Text, Types.OrigynError>>(tokens.size());
    let result_buffer = Buffer.Buffer<async* Result.Result<Text, Types.OrigynError>>(tokens.size());

    label search for (thisitem in tokens.vals()) {
      // Logs
      let log_data = thisitem;
      NFTUtils.logDirectly("mint_batch_nft_origyn", #Text(log_data.0), ?msg.caller);
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
    NFTUtils.logDirectly("share_wallet_nft_origyn", #Text(request.token_id), ?msg.caller);

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
        NFTUtils.logDirectly("governance_nft_origyn - clear_shared_wallets", #Text(val), ?msg.caller);
      };
      case (#update_system_var(val)) {
        NFTUtils.logDirectly("governance_nft_origyn - update_system_var", #Text(debug_show (val)), ?msg.caller);
      };
    };

    debug if (debug_channel.function_announce) D.print("in owner governance");
    return await* Governance.governance_nft_origyn(get_state(), request, msg.caller);
  };

  public shared (msg) func governance_batch_nft_origyn(requests : [Types.GovernanceRequest]) : async [Types.GovernanceResult] {

    if (halt == true) { throw Error.reject("canister is in maintenance mode") };
    if (NFTUtils.is_network(get_state(), msg.caller) == false) {
      return [#err(Types.errors(#unauthorized_access, "governance_batch_nft_origyn - not the network", ?msg.caller))];
    };
    debug if (debug_channel.function_announce) D.print("in govrnance batch batch");
    let results = Buffer.Buffer<Types.GovernanceResult>(requests.size());
    let result_buffer = Buffer.Buffer<async* Types.GovernanceResult>(requests.size());

    label search for (request in requests.vals()) {
      switch (request) {
        case (#clear_shared_wallets(val)) {
          NFTUtils.logDirectly("governance_nft_origyn - clear_shared_wallets", #Text(val), ?msg.caller);
        };
        case (#update_system_var(val)) {
          NFTUtils.logDirectly("governance_nft_origyn - update_system_var", #Text(debug_show (val)), ?msg.caller);
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

    return Buffer.toArray(results);
  };

  public shared query (msg) func unlisted_tokens_of(account : ICRC7.Account, prev : ?Nat, take : ?Nat32) : async [Nat] {
    let list = Metadata.get_NFTs_for_user(get_state(), { owner = account.owner; subaccount = account.subaccount });
    let start : Nat = Option.get<Nat>(prev, 0);
    var limit : Nat = Nat32.toNat(Option.get<Nat32>(take, 100)); // Default limit to 100 if not provided
    if (limit > 1000) {
      limit := 1000;
    };
    var count = 0;
    let results = Buffer.Buffer<Nat>(1);
    let state = get_state();

    label search for (nft_id in list.vals()) {
      if (count < start) {
        count += 1;
        continue search;
      };
      if (results.size() >= limit) {
        break search;
      };
      var metadata = switch (Metadata.get_metadata_for_token(state, nft_id, msg.caller, ?state.canister(), state.state.collection_data.owner)) {
        case (#err(err)) { continue search };
        case (#ok(val)) val;
      };
      switch (Market.is_token_on_sale(state, metadata, msg.caller)) {
        case (#ok(val)) {
          if (val == false) {
            results.add(NFTUtils.get_token_id_as_nat(nft_id));
          };
        };
        case (#err(err)) {};
      };
      count += 1;
    };

    return Buffer.toArray(results);
  };

  public shared query (msg) func count_unlisted_tokens_of(account : ICRC7.Account) : async Nat {
    let state = get_state();
    let list = Metadata.get_NFTs_for_user(state, { owner = account.owner; subaccount = account.subaccount });
    var count = 0;

    label search for (nft_id in list.vals()) {
      var metadata = switch (Metadata.get_metadata_for_token(state, nft_id, msg.caller, ?state.canister(), state.state.collection_data.owner)) {
        case (#err(err)) { continue search };
        case (#ok(val)) val;
      };
      switch (Market.is_token_on_sale(state, metadata, msg.caller)) {
        case (#ok(val)) {
          if (val == false) {
            count += 1;
          };
        };
        case (#err(err)) {};
      };
    };

    return count;
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
        case (#instant(item)) {
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

    NFTUtils.logDirectly("market_transfer_nft_origyn", #Text(log_data), ?msg.caller);

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
          case (#instant(val)) {
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
      NFTUtils.logDirectly("market_transfer_batch_nft_origyn", #Text(log_data), ?msg.caller);
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

    return Buffer.toArray(results);
  };

  /**
    * Start a large number of sales/market transfers. Currently limited to owners, managers, or the network
    * @param {Array<Types.MarketTransferRequest>} request - An array of market transfer requests
    * @returns {Array<Types.MarketTransferResult>} - An array of results for each market transfer request
    */
  private func _sale_nft_origyn(request : Types.ManageSaleRequest, caller : Principal) : async* Types.ManageSaleStar {

    var log_data : Text = "";

    debug if (debug_channel.function_announce) D.print("in sale_nft_origyn");

    return switch (request) {
      case (#end_sale(val)) {
        let log_data = "Type : end sale, token id : " # debug_show (val);
        NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?caller);
        await* Market.end_sale_nft_origyn(get_state(), val, caller);
      };
      case (#open_sale(val)) {
        let log_data = "Type : open sale, token id : " # debug_show (val);
        NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?caller);
        switch (Market.open_sale_nft_origyn(get_state(), val, caller)) {
          case (#ok(val)) #trappable(val);
          case (#err(err)) #err(#trappable(err));
        };
      };
      case (#escrow_deposit(val)) {
        let log_data = "Type : escrow deposit, token id : " # debug_show (val);
        NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?caller);
        await* Market.escrow_nft_origyn(get_state(), val, caller);
      };
      case (#fee_deposit(val)) {
        let log_data = "Type : fee deposit, token id : " # debug_show (val);
        NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?caller);
        await* Market.deposit_fee_nft_origyn(get_state(), val, caller);
      };
      case (#recognize_escrow(val)) {
        let log_data = "Type : recognize escrow, token id : " # debug_show (val);
        NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?caller);
        await* Market.recognize_escrow_nft_origyn(get_state(), val, caller);
      };
      case (#ask_subscribe(val)) {
        let log_data = "Type : ask subscribe " # debug_show (val);
        NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?caller);
        await* Market.ask_subscribe_nft_origyn(get_state(), val, caller);
      };
      case (#refresh_offers(val)) {
        let log_data = "Type : refresh offers " # debug_show (val);
        NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?caller);
        switch (Market.refresh_offers_nft_origyn(get_state(), val, caller)) {
          case (#ok(val)) #trappable(val);
          case (#err(err)) #err(#trappable(err));
        };
      };
      case (#bid(val)) {
        let log_data = "Type : bid " # debug_show (val);
        NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?caller);
        await* Market.bid_nft_origyn(get_state(), val, caller, false);

      };
      case (#distribute_sale(val)) {
        let log_data = "Type : distribute sale " # debug_show (val);
        NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?caller);
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
        NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?caller);
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
        return [#err(Types.errors(#unauthorized_access, "sale_batch_nft_origyn - not an owner, manager, or network - batch limited to 20 items", ?msg.caller))];
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
          NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?msg.caller);
          result_buffer.add(Market.end_sale_nft_origyn(get_state(), val, msg.caller));
        };
        case (#open_sale(val)) {
          let log_data = "Type : open sale, token id :  " # debug_show (val);
          NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?msg.caller);
          result.add(Market.open_sale_nft_origyn(get_state(), val, msg.caller));
        };
        case (#escrow_deposit(val)) {
          let log_data = "Type : escrow deposit, token id :  " # debug_show (val);
          NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?msg.caller);
          result_buffer.add(Market.escrow_nft_origyn(get_state(), val, msg.caller));
        };
        case (#refresh_offers(val)) {
          let log_data = "Type : refresh offers " # debug_show (val);
          NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?msg.caller);
          result.add(Market.refresh_offers_nft_origyn(get_state(), val, msg.caller));
        };
        case (#bid(val)) {
          let log_data = "Type : bid " # debug_show (val);
          NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?msg.caller);
          result_buffer.add(Market.bid_nft_origyn(get_state(), val, msg.caller, false));

        };
        case (#distribute_sale(val)) {
          let log_data = "Type : distribute_sale " # debug_show (val);
          NFTUtils.logDirectly("sale_nft_origyn", # Text(log_data), ?msg.caller);
          result_buffer.add(Market.distribute_sale(get_state(), val, msg.caller));

        };
        case (#ask_subscribe(val)) {
          let log_data = "Type : ask subscribe " # debug_show (val);
          NFTUtils.logDirectly("sale_nft_origyn", # Text(log_data), ?msg.caller);
          result_buffer.add(Market.ask_subscribe_nft_origyn(get_state(), val, msg.caller));
        };
        case (#recognize_escrow(val)) {
          let log_data = "Type : recognize escreow " # debug_show (val);
          NFTUtils.logDirectly("sale_nft_origyn", # Text(log_data), ?msg.caller);
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
          NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?msg.caller);
          result_buffer.add(Market.withdraw_nft_origyn(get_state(), val, msg.caller));
        };
        case (#fee_deposit(val)) {
          let log_data = "Type : fee_deposit :  " # debug_show (val);
          NFTUtils.logDirectly("sale_nft_origyn", #Text(log_data), ?msg.caller);
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
    NFTUtils.logDirectly("sale_info_secure_nft_origyn", #Text(log_data), ?msg.caller);

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
      NFTUtils.logDirectly("sale_info_batch_secure_nft_origyn", #Text(log_data), ?msg.caller);
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
    NFTUtils.logDirectly("collection_update_nft_origyn", #Text(log_data), ?msg.caller);

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
      return [#err(Types.errors(#unauthorized_access, "collection_update_batch_nft_ - not a canister owner or network", ?msg.caller))];
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
      NFTUtils.logDirectly("collection_update_batch_nft_origyn", #Text(log_data), ?msg.caller);
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

    NFTUtils.logDirectly("manage_storage_nft_origyn", #Text("#add_storage_canisters " # debug_show (request)), ?msg.caller);

    let state = get_state();

    switch (request) {
      case (#configure_storage(val)) {

        debug if (debug_channel.manage_storage) D.print("configuring storage: " # debug_show (val));

        let amount = switch (val) {
          case (#heap(val)) {
            switch (val) {
              case (null) {
                return #err(Types.errors(#storage_configuration_error, "manage_storage_nft_origyn - allocation can't be empty " # debug_show (request), ?msg.caller));
              };
              case (?val) val;
            };
          };
          case (#stableBtree(val)) {
            switch (val) {
              case (null) {
                return #err(Types.errors(#storage_configuration_error, "manage_storage_nft_origyn - allocation can't be empty " # debug_show (request), ?msg.caller));
              };
              case (?val) val;
            };
          };
        };

        debug if (debug_channel.manage_storage) D.print("configuring storage current allocated: " # debug_show (state.state.collection_data.allocated_storage));
        if (state.state.collection_data.allocated_storage > 0) {
          return #err(Types.errors(#storage_configuration_error, "manage_storage_nft_origyn - allocation has already been made  " # debug_show (state.state.collection_data.allocated_storage), ?msg.caller));
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
              return #err(Types.errors(#storage_configuration_error, "manage_storage_nft_origyn - principal already exists in buckets  " # debug_show (this_item), ?msg.caller));

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

    return #err(Types.errors(#nyi, "manage_storage_nft_origyn nyi ", ?msg.caller));

  };

  private func _collection_nft_origyn(fields : ?[(Text, ?Nat, ?Nat)], caller : Principal) : Types.CollectionResult {
    // Warning: this function does not use msg.caller, if you add it you need to fix the secure query
    debug if (debug_channel.function_announce) D.print("in collection_nft_origyn");

    let state = get_state();
    let keys = if (NFTUtils.is_owner_manager_network(state, caller) == true) {
      Iter.filter<Text>(
        Map.keys(state.state.nft_metadata),
        func(key : Text) : Bool {
          Metadata.filter_keys_owner((key, state));
        },
      ); // Should always have the "" item and need to remove it
    } else {
      Iter.filter<Text>(
        Map.keys(state.state.nft_ledgers),
        func(key : Text) : Bool {
          Metadata.filter_keys_owner((key, state));
        },
      ); // Should always have the "" item and need to remove it
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
    NFTUtils.logDirectly("collection_secure_nft_origyn", #Text("collection_secure_nft_origyn " # debug_show (fields)), ?msg.caller);

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
                  return #err(Types.errors(#asset_mismatch, "history_nft_origyn - index out of range  " # debug_show (this_item) # " " # debug_show (SB.size(val)), ?caller));

                };
              }
            );
          };

          return #ok(Buffer.toArray(result));
        } else {
          // Enable revrange
          return #err(Types.errors(#nyi, "history_nft_origyn - rev range nyi  " # debug_show (thisStart) # " " # debug_show (thisEnd), ?caller));
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
    NFTUtils.logDirectly("history_secure_nft_origyn", #Text(log_data), ?msg.caller);

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

    let a = Principal.toText(account.owner);
    NFTUtils.logDirectly("balance_of_secure_nft_origyn", #Text("Type - account : " # a), ?msg.caller);

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

    NFTUtils.logDirectly("balance_of_secure_batch_nft_origyn", #Text("Size : " # debug_show (requests.size())), ?msg.caller);

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
            return #err(Types.errors(#token_not_found, "bearer_nft_origyn " # err.flag_point, ?caller));
          };
          case (#ok(val)) {
            val;
          };
        }
      )
    ) {
      case (#err(err)) {
        return #err(Types.errors(err.error, "bearer_nft_origyn " # err.flag_point, ?caller));
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
  public query (msg) func get_token_id_as_nat(token_id : Text) : async Nat {

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

    let token_id = switch (NFTUtils.get_nat_as_token_id(tokenAsNat)) {
      case (#ok(val)) val;
      case (#err(err)) return "not found";
    };

    return token_id;
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
      return #err(Types.errors(#unauthorized_access, "http_access_key - anon not allowed", ?msg.caller));
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

    #err(Types.errors(#property_not_found, "access key not found by caller", ?msg.caller));
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
  public shared func storage_info_secure_nft_origyn() : async Types.StorageMetricsResult {

    if (halt == true) {
      throw Error.reject("canister is in maintenance mode");
    };
    debug if (debug_channel.function_announce) D.print("in storage_info_secure_nft_origyn");
    return await storage_info_nft_origyn();
  };

  /// *************************
  /// ***** ICRC3 *****
  /// *************************

  public query func icrc3_get_blocks(args : [ICRC3.TransactionRange]) : async ICRC3.GetTransactionsResult {
    return icrc3().get_blocks(args);
  };

  public query func icrc3_get_archives(args : ICRC3.GetArchivesArgs) : async ICRC3.GetArchivesResult {
    return icrc3().get_archives(args);
  };

  public query func icrc3_supported_block_types() : async [ICRC3.BlockType] {
    return icrc3().supported_block_types();
  };

  public query func icrc3_get_tip_certificate() : async ?ICRC3.DataCertificate {
    return icrc3().get_tip_certificate();
  };

  public query func get_tip() : async ICRC3.Tip {
    return icrc3().get_tip();
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
      Iter.filter<Text>(
        Map.keys(state.state.nft_metadata),
        func(key : Text) : Bool {
          Metadata.filter_keys_owner((key, state));
        },
      ); // Should always have the "" item and need to remove it
    } else {
      Iter.filter<Text>(
        Map.keys(state.state.nft_ledgers),
        func(key : Text) : Bool {
          Metadata.filter_keys_owner((key, state));
        },
      ); // Should always have the "" item and need to remove it
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

  public query (msg) func icrc7_transfer_fee(token_ids : Nat) : async ?Nat {
    let state = get_state();

    let token_id = switch (NFTUtils.get_nat_as_token_id(token_ids)) {
      case (#ok(val)) val;
      case (#err(err)) return null;
    };

    let metadata = switch (Metadata.get_metadata_for_token(state, token_id, msg.caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) { return null };
      case (#ok(val)) { val };
    };

    let _royalties_names = Array.filter<Text>(Royalties.royalties_names, func x = x != "com.origyn.royalty.broker");
    debug if (debug_channel.icrc7) D.print("_royalties_names " # debug_show (_royalties_names));

    return ?Royalties.get_total_amount_fixed_royalties(_royalties_names, metadata);
  };

  public query (msg) func icrc7_name() : async Text {

    let state = get_state();
    Option.get<Text>(state.state.collection_data.name, Principal.toText(state.canister()));
  };

  public query func icrc7_symbol() : async Text {

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

  public query func icrc7_logo() : async ?Text {
    let state = get_state();
    state.state.collection_data.logo;
  };

  public query (msg) func icrc7_total_supply() : async Nat {

    let state = get_state();
    D.print("icrc7_total_supply");

    let keys = if (NFTUtils.is_owner_manager_network(state, msg.caller) == true) {
      Iter.filter<Text>(
        Map.keys(state.state.nft_metadata),
        func(key : Text) : Bool {
          let ret = Metadata.filter_keys_owner((key, state));
          D.print("key " # debug_show (key) # " ret " # debug_show (ret));
          ret;
        },
      ); // Should always have the " " item and need to remove it
    } else {
      Iter.filter<Text>(
        Map.keys(state.state.nft_ledgers),
        func(key : Text) : Bool {
          let ret = Metadata.filter_keys_owner((key, state));
          D.print("key " # debug_show (key) # " ret " # debug_show (ret));
          ret;
        },
      ); // Should always have the " " item and need to remove it
    };

    Iter.size(keys);
  };

  public query func icrc7_supply_cap() : async ?Nat {
    null;
  };
  public query func icrc7_max_approvals_per_token_or_collection() : async ?Nat {
    null;
  };
  public query (msg) func icrc7_max_query_batch_size() : async ?Nat {
    ?100;
  };
  public query (msg) func icrc7_max_update_batch_size() : async ?Nat {
    ?1;
  };
  public query (msg) func icrc7_default_take_value() : async ?Nat {
    ?100;
  };
  public query (msg) func icrc7_max_take_value() : async ?Nat {
    ?100;
  };

  public query func icrc7_max_revoke_approvals() : async ?Nat {
    null;
  };

  public query (msg) func icrc7_max_memo_size() : async ?Nat {
    ?32;
  };

  public query (msg) func icrc7_atomic_batch_transfers() : async ?Bool {
    ?false;
  };
  public query (msg) func icrc7_tx_window() : async ?Nat {
    let _tmp : Nat = 24 * 60 * 60;
    return ?_tmp;
  };
  public query (msg) func icrc7_permitted_drift() : async ?Nat {
    ?120;
  };

  public query (msg) func icrc7_token_metadata(token_ids : [Nat]) : async [?[(Text, ICRC7.Value)]] {

    let state = get_state();

    let aBuf = Buffer.Buffer<?[(Text, ICRC7.Value)]>(token_ids.size());

    label iter for (token_id in token_ids.vals()) {
      let nat_token_id = switch (NFTUtils.get_nat_as_token_id(token_id)) {
        case (#ok(val)) val;
        case (#err(err)) {
          aBuf.add(null);
          continue iter;
        };
      };

      switch (Metadata.get_metadata_for_token(state, nat_token_id, state.canister(), ?state.canister(), state.state.collection_data.owner)) {
        case (#ok(metadata)) {
          let json = JSON.value_to_json(Metadata.get_clean_metadata(metadata, msg.caller));

          aBuf.add(?[("com.origyn.nft.metadata.json ", #Text(json))]);
        };
        case (_) {
          aBuf.add(null);
        };
      };
    };

    return Buffer.toArray<?[(Text, ICRC7.Value)]>(aBuf);
  };

  public query (msg) func icrc7_owner_of(token_ids : [Nat]) : async [?ICRC7.Account] {

    let state = get_state();

    let aBuf = Buffer.Buffer<?ICRC7.Account>(token_ids.size());

    label iter for (token_id in token_ids.vals()) {
      let nat_token_id = switch (NFTUtils.get_nat_as_token_id(token_id)) {
        case (#ok(val)) val;
        case (#err(err)) {
          aBuf.add(null);
          continue iter;
        };
      };
      switch (Metadata.get_metadata_for_token(state, nat_token_id, msg.caller, ?state.canister(), state.state.collection_data.owner)) {
        case (#ok(metadata)) {
          switch (
            Metadata.get_nft_owner(metadata)
          ) {
            case (#err(err)) {
              debug if (debug_channel.icrc7) D.print("icrc7_owner_of : err " # debug_show (err));

              aBuf.add(null);
            };
            case (#ok(val)) {
              aBuf.add(
                ?{
                  owner = val.owner;
                  subaccount = val.subaccount;
                }
              );
            };
          };
        };
        case (_) {
          debug if (debug_channel.icrc7) D.print("icrc7_owner_of : no metadata ");

          aBuf.add(null);
        };
      };
    };

    return Buffer.toArray(aBuf);

  };

  public query func icrc7_balance_of(items : [ICRC7.Account]) : async [Nat] {

    let state = get_state();
    let aBuf = Buffer.Buffer<Nat>(items.size());
    for (thisItem in items.vals()) {
      let balance : Nat = Metadata.get_NFTs_for_user(get_state(), { owner = thisItem.owner; subaccount = thisItem.subaccount }).size();
      aBuf.add(balance);
    };

    return Buffer.toArray<Nat>(aBuf);

  };

  public query (msg) func icrc7_tokens(prev : ?Nat, take : ?Nat32) : async [Nat] {
    //prev and take are unimplemented
    let state = get_state();

    let keys = if (NFTUtils.is_owner_manager_network(state, msg.caller) == true) {
      Iter.filter<Text>(
        Map.keys(state.state.nft_metadata),
        func(key : Text) : Bool {
          Metadata.filter_keys_owner((key, state));
        },
      ); // Should always have the " " item and need to remove it
    } else {
      Iter.filter<Text>(
        Map.keys(state.state.nft_ledgers),
        func(key : Text) : Bool {
          Metadata.filter_keys_owner((key, state));
        },
      ); // Should always have the " " item and need to remove it
    };

    let result = Iter.map<Text, Nat>(keys, NFTUtils.get_token_id_as_nat);

    return Iter.toArray<Nat>(result);
  };

  public query func icrc7_tokens_of(account : ICRC7.Account, prev : ?Nat, take : ?Nat32) : async [Nat] {
    let start = Option.get<Nat>(prev, 0);
    var limit = Nat32.toNat(Option.get<Nat32>(take, 100)); // Default limit to 100 if not provided
    if (limit > 1000) {
      limit := 1000;
    };

    let list = Metadata.get_NFTs_for_user(get_state(), { owner = account.owner; subaccount = account.subaccount });

    var count = 0;
    let results = Buffer.Buffer<Nat>(1);

    label search for (nft_id in list.vals()) {
      if (count < start) {
        count += 1;
        continue search;
      };
      if (results.size() >= limit) {
        break search;
      };
      results.add(NFTUtils.get_token_id_as_nat(nft_id));
      count += 1;
    };

    return Buffer.toArray(results);
  };

  public shared (msg) func icrc7_transfer(requests : [ICRC7.TransferArgs]) : async ICRC7.TransferResult {
    var _prepare_results = Buffer.Buffer<?ICRC7.TransferResultItem>(3);
    var results = Buffer.Buffer<?ICRC7.TransferResultItem>(3);

    for (request in requests.vals()) {
      let result = await* Owner._prepare_transferICRC7(get_state(), { owner = msg.caller; subaccount = request.from_subaccount }, request.to, request.token_id, msg.caller);
      _prepare_results.add(?result);
    };

    var i : Nat = 0;
    for (request in requests.vals()) {
      let result = _prepare_results.get(i);

      switch (result) {
        case (?_result) {
          switch (_result.transfer_result) {
            case (#Ok(data)) {
              let result = await* Owner.transferICRC7(get_state(), { owner = msg.caller; subaccount = request.from_subaccount }, request.to, request.token_id, msg.caller);
              results.add(?result);
            };
            case (#Err(err)) {
              results.add(
                ?{
                  token_id = _result.token_id;
                  transfer_result = #Err(err);
                }
              );
            };
          };
        };
        case (null) {
          results.add(
            ?{
              token_id = request.token_id;
              transfer_result = #Err(#GenericError({ message = "transferICRC7 : _prepare transfer return null "; error_code = 1 }));
            }
          );
        };
      };

      i += 1;
    };

    var j = 0;
    debug if (debug_channel.icrc7) {
      for (result in results.vals()) {
        j += 1;
      };
    };
    return Buffer.toArray<?ICRC7.TransferResultItem>(results);
  };

  public shared func icrc7_approve(request : ICRC7.ApprovalArgs) : async ICRC7.ApprovalResult {

    D.trap("origyn_nft does not support approvals through ICRC7.Approval is provided by precense of an escrow deposit.Use sale_info_nft_origyn(#escrow) to retrieve deposit info ");

  };

  public query func icrc7_supported_standards() : async [ICRC7.SupportedStandard] {

    [
      {
        name = "ICRC -7 ";
        url = " https : //github.com/dfinity/ICRC/ICRCs/ICRC-7";
      },
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

  public query func __version() : async Text {
    "0.1.7";
  };

  /**
    * Lets the NFT accept cycles.
    * @returns {Nat} - The amount of cycles accepted.
    */
  public func wallet_receive<system>() : async Nat {
    let amount = Cycles.available();
    let accepted = amount;
    ignore Cycles.accept(accepted);
    accepted;
  };

  // **********************************
  // ***** FRACTIONALIZATION PART *****
  // **********************************

  // public shared (msg) func init_fractionalization(request : Fractionalize.InitFractionalizeRequest) : async Fractionalize.InitFractionalizeResponse {
  //   let state = get_state();
  //   let caller = msg.caller;

  //   return await Fractionalize.init_fractionalization(state, request, caller);
  // };

  // public shared (msg) func authorize_fractionalization(request : Fractionalize.AuthorizeFractionalizeRequest) : async Fractionalize.AuthorizeFractionalizeResponse {
  //   let state = get_state();
  //   let caller = msg.caller;

  //   return await Fractionalize.authorize_fractionalization(state, request, caller);
  // };

  // **********************************
  // ***** END FRACTIONALIZATION  *****
  // **********************************

  /**
    * Returns an array of tuples representing the nft library.
    * @returns {Future<Array<[Text, Array<[Text, CandyTypes.AddressedChunkArray]>]>>} - A promise that resolves to an array of tuples representing the nft library.
    */
  /**
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

  };

  system func postupgrade() {
    nft_library_stable_2 := [];

    upgraded_at := Nat64.fromNat(Int.abs(Time.now()));

    notify_timer := ?Timer.setTimer(#nanoseconds(1), handle_notify);

    if (icrc3().stats().lastIndex == 0) {
      ignore __implement_icrc3();
    };
  };

  private func close_sale_timeouted_nft_origyn(id : TimerTool.ActionId, action : TimerTool.Action) : async* Star.Star<TimerTool.ActionId, TimerTool.Error> {
    let candidParsed : ?Text = from_candid (action.params);
    let ?sale_id = candidParsed else { D.trap("unexpected type") };

    let state = get_state();

    switch (Map.get(state.state.nft_sales, Map.thash, sale_id)) {
      case (?status) {
        switch (NFTUtils.get_auction_state_from_status(status)) {
          case (#ok(val)) {
            if (val.status == #open) {
              let owner = switch (Map.get(state.state.nft_metadata, Map.thash, status.token_id)) {
                case (?val) {
                  switch (Metadata.get_nft_owner(val)) {
                    case (#ok(val)) {
                      val;
                    };
                    case (#err(err)) {
                      return #err(#trappable({ error_code = 1; message = "close_sale_timeouted_nft_origyn - couldnt get nft owner " # status.token_id }));
                    };
                  };
                };
                case (null) {
                  return #err(#trappable({ error_code = 2; message = "close_sale_timeouted_nft_origyn - couldnt get nft owner " # status.token_id }));
                };
              };

              let ret = await* Market.end_sale_nft_origyn(get_state(), status.token_id, owner.owner);
              switch (ret) {
                case (#err(err)) {
                  return #err(#trappable({ error_code = 3; message = "close_sale_timeouted_nft_origyn - could not end sale " # status.token_id }));
                };
                case (_) { return #awaited(id) };
              };
            };
          };
          case (#err(val)) {
            return #err(#trappable({ error_code = 4; message = "close_sale_timeouted_nft_origyn - could not find sale for token " }));
          };
        };
        return #err(#trappable({ error_code = 5; message = "close_sale_timeouted_nft_origyn - could not find sale for token " }));
      };
      case (null) {
        return #err(#trappable({ error_code = 6; message = "close_sale_timeouted_nft_origyn - could not find sale for token " }));
      };
    };
  };
};
