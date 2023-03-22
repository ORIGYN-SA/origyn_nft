
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
       let a = await NFTCanisterDef.Nft_Canister();
       await a.collection_update_nft_origyn(#UpdateOwner(data.owner));
       await a.manage_storage_nft_origyn(#configure_storage(#stableBtree(data.storage_space)));
       debug { D.print("should have it....returning" # debug_show(data)) };
       return Principal.fromActor(a);
    };
};