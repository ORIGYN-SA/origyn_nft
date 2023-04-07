
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import D "mo:base/Debug";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Hex "mo:encoding/Hex";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";

import AccountIdentifier "mo:principalmo/AccountIdentifier";
import Candy "mo:candy/types";
import CandyTypes "mo:candy/types";
import Conversions "mo:candy/conversion";
import Properties "mo:candy/properties";
import SB "mo:stablebuffer/StableBuffer";
import SHA256 "mo:crypto/SHA/SHA256";
import Workspace "mo:candy/workspace";

import Types "types";

import MigrationTypes "./migrations/types";

import StableBTreeTypes "mo:stableBTree/types";


module {

    let debug_channel = {
        announce = false;
    };


    public func get_nat_as_token_id(tokenNat : Nat) : Text {
        debug if (debug_channel.announce) D.print("nat as token");
        debug if (debug_channel.announce) D.print(debug_show(Conversions.natToBytes(tokenNat)));
        
        var staged = Conversions.natToBytes(tokenNat);
        let stagedBuffer = CandyTypes.toBuffer<Nat8>(staged);
        let prefixBuffer = if(staged.size() % 4 == 0){CandyTypes.toBuffer<Nat8>([])}
        else if(staged.size() % 4 == 1){CandyTypes.toBuffer<Nat8>([0,0,0])}
        else if(staged.size() % 4 == 2){CandyTypes.toBuffer<Nat8>([0,0])}
        else {CandyTypes.toBuffer<Nat8>([0])};
        
        prefixBuffer.append(stagedBuffer);
         return Conversions.bytesToText((Buffer.toArray(prefixBuffer)));
    };

    public func get_token_id_as_nat(token_id : Text) : Nat{
        debug if (debug_channel.announce) D.print("token as nat:" # token_id);
        debug if (debug_channel.announce) D.print(debug_show(Conversions.textToBytes(token_id)));
        Conversions.bytesToNat(Conversions.textToBytes(token_id));
    };

    public func is_owner_manager_network(state :Types.State, caller: Principal) : Bool{

        debug if (debug_channel.announce) debug {D.print("checking if " # Principal.toText(caller) # " is network:" # debug_show(state.state.collection_data.network) # " owner: " # debug_show(state.state.collection_data.owner) # " manager: " # debug_show(state.state.collection_data.managers))};
        if(caller == state.state.collection_data.owner){return true;};
        if(Array.filter<Principal>(state.state.collection_data.managers, func(item : Principal){item == caller}).size() > 0){return true;};
        if(Option.make(caller) == state.state.collection_data.network){return true;};

        return false;
    };

    public func is_owner_network(state :Types.State, caller: Principal) : Bool{
        debug if (debug_channel.announce) D.print("testing is_owner_network owner:" # debug_show(state.state.collection_data.owner) # " network:" # debug_show(state.state.collection_data.network) # " caller: " # debug_show(caller));
        if(caller == state.state.collection_data.owner){return true;};
        if(Option.make(caller) == state.state.collection_data.network){return true;};
        return false;
    };

    public func is_network(state :Types.State, caller: Principal) : Bool{
        debug if (debug_channel.announce) D.print("testing is_network network:" # debug_show(state.state.collection_data.network) # " caller: " # debug_show(caller));
        if(Option.make(caller) == state.state.collection_data.network){return true;};
        return false;
    };

    public func get_auction_state_from_status(current_sale : Types.SaleStatus ) : Result.Result<Types.AuctionState, Types.OrigynError> {

        switch(current_sale.sale_type) {
            case(#auction(state)){
                #ok(state);
            };
            /* case(_){
                return #err(Types.errors(#nyi, "bid_nft_origyn - sales state not implemented " # current_sale.sale_id, null));
            }; */
        };
    };

    public func get_auction_state_from_statusStable(current_sale : Types.SaleStatusStable ) : Result.Result<Types.AuctionStateStable, Types.OrigynError> {

        switch(current_sale.sale_type) {
            case(#auction(state)){
                #ok(state);
            };
            /* case(_){
                return #err(Types.errors(#nyi, "bid_nft_origyn - sales state not implemented " # current_sale.sale_id, null));
            }; */
        };
    };

    public func build_library(items: [(Text,[(Text,CandyTypes.AddressedChunkArray)])]) : TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>>{
        
        let aMap = TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>>(Text.equal,Text.hash);
        for(this_item in items.vals()){
            let bMap = TrieMap.TrieMap<Text, CandyTypes.Workspace>(Text.equal,Text.hash);
            for(thatItem in this_item.1.vals()){
                bMap.put(thatItem.0, Workspace.fromAddressedChunks(thatItem.1));
            };
            aMap.put(this_item.0, bMap);
        };

        return aMap;
    };

    public let compare_library  = MigrationTypes.Current.compare_library;

    public let library_equal = MigrationTypes.Current.library_equal;

    public let library_hash = MigrationTypes.Current.library_hash;

    public func get_deposit_info(depositor_account : Types.Account, host: Principal) : Types.SubAccountInfo{
        debug if (debug_channel.announce) D.print("getting deposit info");
        get_subaccount_info("com.origyn.nft.deposit", depositor_account, host);
    };


    public func get_escrow_account_info(request : Types.EscrowReceipt, host: Principal) : Types.SubAccountInfo{
        
        debug if (debug_channel.announce) D.print("Getting escrow account");
        let h = SHA256.New();
        h.write(Conversions.valueToBytes(#Text("com.origyn.nft.escrow")));
        h.write(Conversions.valueToBytes(#Text("buyer")));
        h.write(Conversions.valueToBytes(#Nat(MigrationTypes.Current.account_hash_uncompressed(request.buyer))));
        h.write(Conversions.valueToBytes(#Text("seller")));
        h.write(Conversions.valueToBytes(#Nat(MigrationTypes.Current.account_hash_uncompressed(request.seller))));
        h.write(Conversions.valueToBytes(#Text(("tokenid"))));
        h.write(Conversions.valueToBytes(#Text(request.token_id)));
        h.write(Conversions.valueToBytes(#Text("ledger")));
        h.write(Conversions.valueToBytes(#Nat(MigrationTypes.Current.token_hash_uncompressed(request.token))));
        let sub_hash =h.sum([]);

        let to = AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(host, ?sub_hash));
                   
        return {
            principal = host;
            account_id_text = Hex.encode(to);
            account_id = Blob.fromArray(to);
            account = {
                principal = host;
                sub_account = (Blob.fromArray(sub_hash));
            }
        };
    };

    public func hash_blob(item: Blob) : Nat{
      let h = SHA256.New();
        h.write(Blob.toArray(item));
        let sub_hash =h.sum([]);
        return Conversions.valueToNat(#Bytes(#frozen(sub_hash)));
    };

    public func get_sale_account_info(request : Types.EscrowReceipt, host: Principal) : Types.SubAccountInfo{
        
        let h = SHA256.New();
        h.write(Conversions.valueToBytes(#Nat32(Text.hash("com.origyn.nft.sale"))));
        h.write(Conversions.valueToBytes(#Nat32(Text.hash("buyer"))));
        h.write(Conversions.valueToBytes(#Nat(MigrationTypes.Current.account_hash_uncompressed(request.buyer))));
        h.write(Conversions.valueToBytes(#Nat32(Text.hash("seller"))));
        h.write(Conversions.valueToBytes(#Nat(MigrationTypes.Current.account_hash_uncompressed(request.seller))));
        h.write(Conversions.valueToBytes(#Nat32(Text.hash("tokenid"))));
        h.write(Conversions.valueToBytes(#Text(request.token_id)));
        h.write(Conversions.valueToBytes(#Nat32(Text.hash("ledger"))));
        h.write(Conversions.valueToBytes(#Nat(MigrationTypes.Current.token_hash_uncompressed(request.token))));
        let sub_hash =h.sum([]);

        let to = AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(host, ?sub_hash));
                

        return {
            principal = host;
            account_id_text = Hex.encode(to);
            account_id = Blob.fromArray(to);
            account = {
                principal = host;
                sub_account =(Blob.fromArray(sub_hash));
            }
        };
    };

    /*
    public func getMemoryBySize(size : Nat, memory : Types.Stable_Memory) : StableBTreeTypes.IBTreeMap<Nat32, [Nat8]>{
      if(size <= 1000){
        return memory._1;
      } else if(size <= 4000){
        return memory._4;
      } else if(size <= 16000){
        return memory._16;
      } else if(size <= 64000){
        return memory._64;
      } else if(size <= 256000){
        return memory._256;
      } else if(size <= 1024000){
        return memory._1024;
      } else {
        return memory._1024;
      };
    };
    */

    private func get_subaccount_info(prefix: Text, account : Types.Account, host: Principal) : Types.SubAccountInfo{
        debug if (debug_channel.announce) D.print("in get subaccount");
        switch(account){
            case(#principal(principal)){
                let buffer = CandyTypes.toBuffer<Nat8>(Blob.toArray(Text.encodeUtf8(prefix # ".principal"))); 
                buffer.append(CandyTypes.toBuffer<Nat8>(Blob.toArray(Principal.toBlob(principal))));

                let h = SHA256.New();
                h.write(Buffer.toArray(buffer));
                let sha = h.sum([]);

                
                let to = AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(host, ?sha));
         
         
                return {
                    principal = host;
                    account_id_text = Hex.encode(to);
                    account_id = Blob.fromArray(to);
                    account = {
                        principal = host;
                        sub_account = Blob.fromArray(sha);
                    }
                };
            };
            case(#account(account)){
                let buffer = CandyTypes.toBuffer<Nat8>(Blob.toArray(Text.encodeUtf8(prefix # ".account"))); 
                buffer.append(CandyTypes.toBuffer<Nat8>(Blob.toArray(Principal.toBlob(account.owner))));
                switch(account.sub_account){
                    case(null){};
                    case(?val){
                        buffer.append(CandyTypes.toBuffer<Nat8>(Blob.toArray(val)));

                    }
                };
                
                let h = SHA256.New();
                h.write(Buffer.toArray(buffer));
                let sha = h.sum([]);

                
                let to = AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(host, ?sha));
         
                return {
                    principal = host;
                    account_id_text = Hex.encode(to);
                    account_id = Blob.fromArray(to);
                    account = {
                        principal = host;
                        sub_account = Blob.fromArray(sha);
                    }
                };
            };
            case(#account_id(account_id)){
                let buffer = CandyTypes.toBuffer<Nat8>(Blob.toArray(Text.encodeUtf8(prefix # ".accountid")));
                switch(AccountIdentifier.fromText(account_id)){
                    case(#ok(accountblob)){
                        buffer.append(CandyTypes.toBuffer<Nat8>((AccountIdentifier.addHash(accountblob))));

                    };
                    case(#err(err)){

                    };
                };
                
                let h = SHA256.New();
                h.write(Buffer.toArray(buffer));
                let sha = h.sum([]);

                
                let to = AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(host, ?sha));
         
                    
                return {
                    principal = host;
                    account_id_text = Hex.encode(to);
                    account_id = Blob.fromArray(to);
                    account = {
                        principal = host;
                        sub_account = Blob.fromArray(sha);
                    }
                };
            };
            case(#extensible(data)){
                return Prelude.nyi(); //cant implement until candy has stable hash
            }
        };
    };

}