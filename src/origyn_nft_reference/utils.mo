
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import D "mo:base/Debug";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
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
import Candy "mo:candy_0_1_10/types";
import CandyTypes "mo:candy_0_1_10/types";
import Conversions "mo:candy_0_1_10/conversion";
import Properties "mo:candy_0_1_10/properties";
import SB "mo:stablebuffer_0_2_0/StableBuffer";
import SHA256 "mo:crypto/SHA/SHA256";
import Workspace "mo:candy_0_1_10/workspace";

import Types "types";


module {


    public func get_nat_as_token_id(tokenNat : Nat) : Text {
        D.print("nat as token");
        D.print(debug_show(Conversions.natToBytes(tokenNat)));
        
        var staged = Conversions.natToBytes(tokenNat);
        let stagedBuffer = CandyTypes.toBuffer<Nat8>(staged);
        let prefixBuffer = if(staged.size() % 4 == 0){CandyTypes.toBuffer<Nat8>([])}
        else if(staged.size() % 4 == 1){CandyTypes.toBuffer<Nat8>([0,0,0])}
        else if(staged.size() % 4 == 2){CandyTypes.toBuffer<Nat8>([0,0])}
        else {CandyTypes.toBuffer<Nat8>([0])};
        
        prefixBuffer.append(stagedBuffer);
         return Conversions.bytesToText((prefixBuffer.toArray()));
    };

    public func get_token_id_as_nat(token_id : Text) : Nat{
        D.print("token as nat:" # token_id);
        D.print(debug_show(Conversions.textToBytes(token_id)));
        Conversions.bytesToNat(Conversions.textToBytes(token_id));
    };

    public func is_owner_manager_network(state :Types.State, caller: Principal) : Bool{

        //debug {D.print("checking if " # Principal.toText(caller) # " is network:" # debug_show(state.state.collection_data.network) # " owner: " # debug_show(state.state.collection_data.owner) # " manager: " # debug_show(state.state.collection_data.managers))};
        if(caller == state.state.collection_data.owner){return true;};
        if(Array.filter<Principal>(state.state.collection_data.managers, func(item : Principal){item == caller}).size() > 0){return true;};
        if(Option.make(caller) == state.state.collection_data.network){return true;};

        return false;
    };

    public func is_owner_network(state :Types.State, caller: Principal) : Bool{
        if(caller == state.state.collection_data.owner){return true;};
        if(Option.make(caller) == state.state.collection_data.network){return true;};
        return false;
    };

    public func add_log(state: Types.State, entry : Types.LogEntry){
        if(SB.size(state.state.log) >= 1000){
            SB.add<[Types.LogEntry]>(state.state.log_history, SB.toArray(state.state.log));
            state.state.log := SB.initPresized<Types.LogEntry>(1000);
        };
        SB.add<Types.LogEntry>(state.state.log, entry);
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

    public func compare_library(x : (Text, Text), y: (Text, Text)) : Order.Order {
        let a = Text.compare(x.0, y.0);
        switch(a){
            case(#equal){
                return  Text.compare(x.1,y.1);
            };
            case(_){
                return a;
            };
        };
    };

    public func library_equal(x : (Text, Text), y: (Text, Text)) : Bool {
        
        switch(compare_library(x, y)){
            case(#equal){
                return  true;
            };
            case(_){
                return false;
            };
        };
    };

    public func library_hash(x : (Text, Text)) : Nat {
        return Nat32.toNat(Text.hash("token_id" # x.0 # "library_id" # x.1));
        
    };

    public func get_deposit_info(depositor_account : Types.Account, host: Principal) : Types.SubAccountInfo{
        D.print("getting deposit info");
        get_subaccount_info("com.origyn.nft.deposit", depositor_account, host);
    };


    public func get_escrow_account_info(request : Types.EscrowReceipt, host: Principal) : Types.SubAccountInfo{
        
        D.print("Getting escrow account");
        let h = SHA256.New();
        h.write(Conversions.valueToBytes(#Text("com.origyn.nft.escrow")));
        h.write(Conversions.valueToBytes(#Text("buyer")));
        h.write(Conversions.valueToBytes(#Nat(Types.account_hash_uncompressed(request.buyer))));
        h.write(Conversions.valueToBytes(#Text("seller")));
        h.write(Conversions.valueToBytes(#Nat(Types.account_hash_uncompressed(request.seller))));
        h.write(Conversions.valueToBytes(#Text(("tokenid"))));
        h.write(Conversions.valueToBytes(#Text(request.token_id)));
        h.write(Conversions.valueToBytes(#Text("ledger")));
        h.write(Conversions.valueToBytes(#Nat(Types.token_hash_uncompressed(request.token))));
        let sub_hash =h.sum([]);

        let to = AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(host, ?sub_hash));
                   
        return {
            principal = host;
            account_id_text = AccountIdentifier.toText(to);
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
        h.write(Conversions.valueToBytes(#Nat(Types.account_hash_uncompressed(request.buyer))));
        h.write(Conversions.valueToBytes(#Nat32(Text.hash("seller"))));
        h.write(Conversions.valueToBytes(#Nat(Types.account_hash_uncompressed(request.seller))));
        h.write(Conversions.valueToBytes(#Nat32(Text.hash("tokenid"))));
        h.write(Conversions.valueToBytes(#Text(request.token_id)));
        h.write(Conversions.valueToBytes(#Nat32(Text.hash("ledger"))));
        h.write(Conversions.valueToBytes(#Nat(Types.token_hash_uncompressed(request.token))));
        let sub_hash =h.sum([]);

        let to = AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(host, ?sub_hash));
                

        return {
            principal = host;
            account_id_text = AccountIdentifier.toText(to);
            account_id = Blob.fromArray(to);
            account = {
                principal = host;
                sub_account =(Blob.fromArray(sub_hash));
            }
        };
    };

    private func get_subaccount_info(prefix: Text, account : Types.Account, host: Principal) : Types.SubAccountInfo{
        D.print("in get subaccount");
        switch(account){
            case(#principal(principal)){
                let buffer = CandyTypes.toBuffer<Nat8>(Blob.toArray(Text.encodeUtf8(prefix # ".principal"))); 
                buffer.append(CandyTypes.toBuffer<Nat8>(Blob.toArray(Principal.toBlob(principal))));

                let h = SHA256.New();
                h.write(buffer.toArray());
                let sha = h.sum([]);

                
                let to = AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(host, ?sha));
         
         
                return {
                    principal = host;
                    account_id_text = AccountIdentifier.toText(to);
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
                h.write(buffer.toArray());
                let sha = h.sum([]);

                
                let to = AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(host, ?sha));
         
                return {
                    principal = host;
                    account_id_text = AccountIdentifier.toText(to);
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
                h.write(buffer.toArray());
                let sha = h.sum([]);

                
                let to = AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(host, ?sha));
         
                    
                return {
                    principal = host;
                    account_id_text = AccountIdentifier.toText(to);
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