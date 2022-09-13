
import C "mo:matchers/Canister";
import M "mo:matchers/Matchers";
import T "mo:matchers/Testable";
import D "mo:base/Debug";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import DFXTypes "../origyn_nft_reference/dfxtypes";
import AccountIdentifier "mo:principalmo/AccountIdentifier";
import StorageCanisterDef "../origyn_nft_reference/storage_canister";

shared (deployer) actor class storage_creator() = this {
    public shared func create(data : {owner : Principal; storage_space: ?Nat}) : async Principal {
        D.print("in create storage");
       let a = await StorageCanisterDef.Storage_Canister({gateway_canister = data.owner; storage_space = data.storage_space; network = null});
       debug { D.print("should have it....returning" # debug_show(data)) };
       
       return Principal.fromActor(a);
    };
};