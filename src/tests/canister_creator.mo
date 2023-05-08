
import C "mo:matchers/Canister";
import M "mo:matchers/Matchers";
import T "mo:matchers/Testable";
import D "mo:base/Debug";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import DFXTypes "../origyn_nft_reference/dfxtypes";
import AccountIdentifier "mo:principalmo/AccountIdentifier";
import NFTCanisterDef "../origyn_nft_reference/main";

shared (deployer) actor class canister_creator() = this {

    public shared func create(data: {owner : Principal; storage_space: ?Nat}) : async Principal {
       D.print("in create nft");
       let a = await NFTCanisterDef.Nft_Canister(data);
       let result = await add_controller(Principal.fromActor(a));
       debug { D.print("should have it....returning" # debug_show(data)) };
       return Principal.fromActor(a);
    };

    func add_controller(canister : Principal) : async Bool {

      D.print("in add controller in canister creator");
      type canister_settings = {
        freezing_threshold : ?Nat;
        controllers : ?[Principal];
        memory_allocation : ?Nat;
        compute_allocation : ?Nat;
      };

      
      type service = actor {
        update_settings : shared {
        canister_id : Principal;
        settings : canister_settings;
          } -> async ();
       
      };

      let ic = actor "aaaaa-aa" : service;
      
      let result = await ic.update_settings({
        canister_id = canister;
        settings = {
          freezing_threshold = null;
          controllers = ?[Principal.fromActor(this), deployer.caller];
          memory_allocation = null;
          compute_allocation = null;
        };
      });

      D.print(debug_show(result));

      return true;
    };

};