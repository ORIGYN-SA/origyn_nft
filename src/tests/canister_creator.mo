
import C "mo:matchers/Canister";
import M "mo:matchers/Matchers";
import T "mo:matchers/Testable";
import D "mo:base/Debug";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import DFXTypes "../origyn_nft_reference/dfxtypes";
import AccountIdentifier "mo:principalmo/AccountIdentifier";
import NFTCanisterDef "../origyn_nft_reference/main";

shared (deployer) actor class canister_creator() = this {

    public shared func create(data: {owner : Principal; storage_space: ?Nat}) : async Principal {
       D.print("in create nft");
       
       let a = try{
        await NFTCanisterDef.Nft_Canister();
       } catch (e){
        D.print("creation error " # Error.message(e));
        D.trap(Error.message(e));
       };

       let b = try{
        await a.manage_storage_nft_origyn(#configure_storage(#heap(switch(data.storage_space){
            case(null){?500000000};
            case(?val) ?val;
          })
        ));
       } catch (e){
        D.print("creation error " # Error.message(e));
        D.trap(Error.message(e));
       };
       D.print("storage set " # debug_show(b));


       D.print("have NFT. make owner: " # debug_show(data.owner) # " current owner should be: " # debug_show(Principal.fromActor(this)));
       let c = try{
        ignore await a.collection_update_nft_origyn(#UpdateOwner(data.owner));
       } catch (e){
        D.print("creation error " # Error.message(e));
        D.trap(Error.message(e));
       };
       D.print("owner updated" # debug_show(c));
       
       debug { D.print("should have it....returning" # debug_show(data)) };
       return Principal.fromActor(a);
    };
};