import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import TrieSet "mo:base/TrieSet";
import TrieMap "mo:base/TrieMap";
import Cycles "mo:base/ExperimentalCycles";
import Prim "mo:⛔";
import Buffer "mo:base/Buffer";
import { endsWith; size } "mo:base/Text";
import { trap } "mo:base/Debug";

import CyclesManager "mo:cycles-manager/CyclesManager";

import Types "types";

shared (installer) actor class CanistersManager() = this {

  type Error = Types.Error;
  type Canister = Types.Canister;
  type CanisterStatus = Types.CanisterStatus;
  type Status = Types.Status;
  type Record = Types.Record;
  type CanisterId = Types.CanisterId;
  type WasmModule = Types.WasmModule;
  type Management = Types.Management;
  type Ledger = Types.Ledger;
  type DeployArgs = Types.DeployArgs;
  type CycleInterface = Types.CycleInterface;
  type UpdateSettingsArgs = Types.UpdateSettingsArgs;
  type InstallArgs = Types.InstallArgs;

  stable var owners : TrieSet.Set<Principal> = TrieSet.fromArray<Principal>([installer.caller], Principal.hash, Principal.equal);
  stable var cycle_wasm : WasmModule = [];
  stable var canisters_entries : [(Principal, Canister)] = [];
  stable var record_entries : [(Principal, [Record])] = [];

// TODO: those consts could be needed if the canister would manage the cycles by itself (not using the CycleOps)
  let CYCLE_MINTING_CANISTER = Principal.fromText("rkp4c-7iaaa-aaaaa-aaaca-cai");
  let ICP_LEDGER : Ledger = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai");
  let management : Management = actor ("aaaaa-aa");
  let CURRENT_VERSION : Nat = 5;

  var canisters : TrieMap.TrieMap<Principal, Canister> = TrieMap.fromEntries(canisters_entries.vals(), Principal.equal, Principal.hash);

  var records : TrieMap.TrieMap<Principal, [Record]> = TrieMap.fromEntries(record_entries.vals(), Principal.equal, Principal.hash);

  public query ({ caller }) func isOwner() : async Bool {
    TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal);
  };

  public query ({ caller }) func getRecords(p : Principal) : async Result.Result<[Record], Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    switch (records.get(p)) {
      case null { #err(#No_Record) };
      case (?r) {
        #ok(r);
      };
    };

  };

  public shared ({ caller }) func putRecords(p : Principal) : async Result.Result<(), Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    let record = {
      caller = caller;
      canister_id = p;
      method = #updateSettings;
      amount = 0;
      times = Time.now();
    };
    switch (records.get(record.canister_id)) {
      case (null) { records.put(record.canister_id, [record]) };
      case (?r) {
        let buffer = Buffer.fromArray<Record>(r);
        buffer.add(record);
        records.put(record.canister_id, Buffer.toArray(buffer));
      };
    };
    #ok(());
  };

  public query func getVersion() : async Nat {
    CURRENT_VERSION;
  };

  public query func getOwners() : async [Principal] {
    TrieSet.toArray<Principal>(owners);
  };

  public query ({ caller }) func getStatus() : async Result.Result<Status, Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    #ok({
      cycle_balance = Cycles.balance();
      memory = Prim.rts_memory_size();
    });
  };

  public query ({ caller }) func getCanisters() : async Result.Result<[Canister], Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    var res = Array.init<Canister>(
      canisters.size(),
      {
        name = "";
        description = "";
        canister_id = Principal.fromActor(this);
        wasm = null;
      },
    );
    var index = 0;
    for (c in canisters.vals()) {
      res[index] := {
        name = c.name;
        description = c.description;
        canister_id = c.canister_id;
        wasm = null;
      };
      index := index + 1;
    };
    #ok(Array.freeze<Canister>(res));
  };

  public query ({ caller }) func getWasm(canister_id : CanisterId) : async Result.Result<[Nat8], Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    switch (canisters.get(canister_id)) {
      case null { #ok([]) };
      case (?c) {
        switch (c.wasm) {
          case null { #err(#No_Wasm) };
          case (?wasm) { #ok(wasm) };
        };
      };
    };
  };

  public shared ({ caller }) func canisterStatus(id : Principal) : async Result.Result<CanisterStatus, Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    #ok(await management.canister_status({ canister_id = id }));
  };

  // put & change
  public shared ({ caller }) func putCanister(c : Canister) : async Result.Result<(), Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    // inspect if canister manager canister is one of the controllers
    ignore await management.canister_status({ canister_id = c.canister_id });
    canisters.put(c.canister_id, c);
    #ok(());
  };

  public shared ({ caller }) func deployCanister(
    args : DeployArgs
  ) : async Result.Result<Principal, Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };

    // 100 000 000 000 Cycle (0.1 T) is used to keep canister manager available
    if (args.cycle_amount + 100_000_000_000 >= Cycles.balance() or args.cycle_amount < 200_000_000_000) {
      return #err(#Insufficient_Cycles);
    };
        Cycles.add<system>( 1_000_000_000_000);

        let _canister_id = try {
            (await management.create_canister({settings = null})).canister_id;
        } catch (_) {            
            return #err(#Insufficient_Cycles);            
        };


    canisters.put(
      _canister_id,
      {
        name = args.name;
        description = args.description;
        canister_id = _canister_id;
        wasm = if (args.preserve_wasm) { args.wasm } else { null };
      },
    );
    ignore do ? {
      if (args.wasm!.size() != 0) {
        switch (args.deploy_arguments) {
          case null {
            ignore management.install_code({
              arg = [];
              wasm_module = args.wasm!;
              mode = #install;
              canister_id = _canister_id;
            });
          };
          case (?_arg) {
            ignore management.install_code({
              arg = _arg;
              wasm_module = args.wasm!;
              mode = #install;
              canister_id = _canister_id;
            });
          };
        };
      };
    };
    let record = {
      caller = caller;
      canister_id = _canister_id;
      method = #deploy;
      amount = args.cycle_amount;
      times = Time.now();
    };
    switch (records.get(record.canister_id)) {
      case (null) { records.put(record.canister_id, [record]) };
      case (?r) {
                let buffer = Buffer.fromArray<Record>(r);
        buffer.add(record);
        records.put(record.canister_id, Buffer.toArray(buffer));
      };
    };

    #ok(_canister_id);
  };

  public shared ({ caller }) func installWasm(args : InstallArgs) : async Result.Result<(), Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    ignore management.install_code(args);
    let record = {
      caller = caller;
      canister_id = args.canister_id;
      method = args.mode;
      amount = 0;
      times = Time.now();
    };
    switch (records.get(record.canister_id)) {
      case (null) { records.put(record.canister_id, [record]) };
      case (?r) {
        let buffer = Buffer.fromArray<Record>(r);
        buffer.add(record);
        records.put(record.canister_id, Buffer.toArray(buffer));
      };
    };
    #ok(());
  };

  public shared ({ caller }) func updateCanisterSettings(args : UpdateSettingsArgs) : async Result.Result<(), Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    ignore management.update_settings({
      canister_id = args.canister_id;
      settings = args.settings;
    });
    let record = {
      caller = caller;
      canister_id = args.canister_id;
      method = #updateSettings;
      amount = 0;
      times = Time.now();
    };
    switch (records.get(record.canister_id)) {
      case (null) { records.put(record.canister_id, [record]) };
      case (?r) {
        let buffer = Buffer.fromArray<Record>(r);
        buffer.add(record);
        records.put(record.canister_id, Buffer.toArray(buffer));
      };
    };
    #ok(());
  };

  public shared ({ caller }) func startCanister(principal : Principal) : async Result.Result<(), Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    ignore management.start_canister({ canister_id = principal });
    let record = {
      caller = caller;
      canister_id = principal;
      method = #start;
      amount = 0;
      times = Time.now();
    };
    switch (records.get(record.canister_id)) {
      case (null) { records.put(record.canister_id, [record]) };
      case (?r) {
        let buffer = Buffer.fromArray<Record>(r);
        buffer.add(record);
        records.put(record.canister_id, Buffer.toArray(buffer));
      };
    };
    #ok(());
  };

  public shared ({ caller }) func stopCanister(principal : Principal) : async Result.Result<(), Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    ignore management.stop_canister({ canister_id = principal });
    let record = {
      caller = caller;
      canister_id = principal;
      method = #stop;
      amount = 0;
      times = Time.now();
    };
    switch (records.get(record.canister_id)) {
      case (null) { records.put(record.canister_id, [record]) };
      case (?r) {
        let buffer = Buffer.fromArray<Record>(r);
        buffer.add(record);
        records.put(record.canister_id, Buffer.toArray(buffer));
      };
    };
    #ok(());
  };

  public shared ({ caller }) func depositCycles(
    id : Principal,
    cycle_amount : Nat,
  ) : async Result.Result<(), Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    if (cycle_amount + 100_000_000_000 >= Cycles.balance()) {
      return #err(#Insufficient_Cycles);
    };
    Cycles.add<system>(cycle_amount);
    ignore management.deposit_cycles({ canister_id = id });
    let record = {
      caller = caller;
      canister_id = id;
      method = #deposit;
      amount = cycle_amount;
      times = Time.now();
    };
    switch (records.get(record.canister_id)) {
      case (null) { records.put(record.canister_id, [record]) };
      case (?r) {
        let buffer = Buffer.fromArray<Record>(r);
        buffer.add(record);
        records.put(record.canister_id, Buffer.toArray(buffer));
      };
    };
    #ok(());
  };

  public shared ({ caller }) func delCanister(
    id : Principal
  ) : async Result.Result<(), Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    if ((await management.canister_status({ canister_id = id })).cycles > 10_000_000_000) {
      await management.start_canister({ canister_id = id });
      await management.install_code({
        arg = [];
        wasm_module = cycle_wasm;
        mode = #reinstall;
        canister_id = id;
      });
      let from : CycleInterface = actor (Principal.toText(id));
      await from.withdraw_cycles({ canister_id = caller });
    };
    await management.stop_canister({ canister_id = id });
    ignore management.delete_canister({ canister_id = id });
    canisters.delete(id);
    let record = {
      caller = caller;
      canister_id = id;
      method = #delete;
      amount = 0;
      times = Time.now();
    };
    switch (records.get(record.canister_id)) {
      case (null) { records.put(record.canister_id, [record]) };
      case (?r) {
        let buffer = Buffer.fromArray<Record>(r);
        buffer.add(record);
        records.put(record.canister_id, Buffer.toArray(buffer));
      };
    };
    #ok(());
  };

  public shared ({ caller }) func installCycleWasm(wasm : WasmModule) : async Result.Result<(), Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    cycle_wasm := wasm;
    #ok(());
  };

  public shared ({ caller }) func changeOwner(newOwners : [Principal]) : async Result.Result<(), Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    owners := TrieSet.fromArray<Principal>(newOwners, Principal.hash, Principal.equal);
    // let record = {
    //     caller = caller;
    //     canister_id = currentid;
    //     method = #changeOwner;
    //     amount = 0;
    //     times = Time.now();
    // };
    // switch(records.get(record.canister_id)){
    //     case(null) {records.put(record.canister_id,[record])};
    //     case(?r){
    //         let p = Array.append(r,[record]);
    //         records.put(record.canister_id,p);
    //     }
    // };
    #ok(());
  };
  public shared ({ caller }) func addOwner(nas : Principal) : async Result.Result<(), Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    owners := TrieSet.put<Principal>(owners, nas, Principal.hash(nas), Principal.equal);
    // let record = {
    //     caller = caller;
    //     canister_id = currentid;
    //     method = #addOwner;
    //     amount = 0;
    //     times = Time.now();
    // };
    // switch(records.get(record.canister_id)){
    //     case(null) {records.put(record.canister_id,[record])};
    //     case(?r){
    //         let p = Array.append(r,[record]);
    //         records.put(record.canister_id,p);
    //     }
    // };
    #ok(());
  };

  public shared ({ caller }) func deleteOwner(nas : Principal) : async Result.Result<(), Error> {
    if (not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)) {
      return #err(#Invalid_Caller);
    };
    owners := TrieSet.delete<Principal>(owners, nas, Principal.hash(nas), Principal.equal);
    // let record = {
    //     caller = caller;
    //     canister_id = currentid;
    //     method = #deleteOwner;
    //     amount = 0;
    //     times = Time.now();
    // };
    // switch(records.get(record.canister_id)){
    //     case(null) {records.put(record.canister_id,[record])};
    //     case(?r){
    //         let p = Array.append(r,[record]);
    //         records.put(record.canister_id,p);
    //     }
    // };
    #ok(());
  };

  public shared ({ caller }) func init(owner : Principal, _cycle_wasm : WasmModule) : async () {
    assert (TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal));
    owners := TrieSet.fromArray<Principal>([owner], Principal.hash, Principal.equal);
    cycle_wasm := _cycle_wasm;
  };

  public func wallet_receive() : async () {
    ignore Cycles.accept<system>(Cycles.available());
    //record
  };

  system func preupgrade() {
    canisters_entries := Iter.toArray(canisters.entries());
    record_entries := Iter.toArray(records.entries());
  };

  system func postupgrade() {
    canisters_entries := [];
    record_entries := [];
  };

// *****************************************************************
// ** Cycles Management Section **
// This section handles monitoring and topping up cycles for 
// target canisters. It ensures canisters maintain a sufficient 
// cycle balance to perform their operations.
// *****************************************************************

  // Initializes a cycles manager
  stable let cyclesManager = CyclesManager.init({
    // By default, with each transfer request 500 billion cycles will be transferred
    // to the requesting canister, provided they are permitted to request cycles
    //
    // This means that if a canister is added with no quota, it will default to the quota of #fixedAmount(500)
    defaultCyclesSettings = {
      quota = #fixedAmount(500_000_000_000);
    };
    // In total 10 trillion cycles are allowed to be transferred every 24 hours 
    aggregateSettings = {
      quota = #rate({
        maxAmount = 10_000_000_000_000;
        durationInSeconds = 24 * 60 * 60;
      });
    };
    // 50 billion is a good default minimum for most low use canisters
    minCyclesPerTopup = ?50_000_000_000;
  });

  // @required - IMPORTANT!!!
  // Allows canisters to request cycles from this "battery canister" that implements
  // the cycles manager
  public shared ({ caller }) func requestCycles(
    cyclesRequested: Nat
  ): async CyclesManager.TransferCyclesResult {
    if (not isCanister(caller)) trap("Calling principal must be a canister");
    
    let result = await* CyclesManager.transferCycles({
      cyclesManager;
      canister = caller;
      cyclesRequested;
    });
    result;
  };

    // @required - IMPORTANT!!!
  // Allows canisters to send cycles from this "battery canister" that implements
  // the cycles manager
  public shared func transferCycles(canisterToTopUp: CanisterId,
    cyclesToTransfer: Nat
  ): async CyclesManager.TransferCyclesResult {
    
    let result = await* CyclesManager.transferCycles({
      cyclesManager;
      canister = canisterToTopUp;
      cyclesRequested = cyclesToTransfer;
    });
    result;
  };

  // A very basic example of adding a canister to the cycles manager
  // This adds a canister with a 1 trillion cycles allowed per 24 hours cycles quota
  //
  // IMPORTANT: Add authoriation for production implementation so that not just any canister
  // can add themself
  public shared func addCanisterWith1TrillionPer24HoursLimit(canisterId: Principal) {
    CyclesManager.addChildCanister(cyclesManager, canisterId, {
      // This topup rule all1 Trillion every 24 hours
      quota = ?(#rate({
        maxAmount = 1_000_000_000_000;
        durationInSeconds = 24 * 60 * 60;
      }));
    })
  };

  func isCanister(p : Principal) : Bool {
    let principal_text = Principal.toText(p);
    // Canister principals have 27 characters
    size(principal_text) == 27
    and
    // Canister principals end with "-cai"
    endsWith(principal_text, #text "-cai");
  };

};
