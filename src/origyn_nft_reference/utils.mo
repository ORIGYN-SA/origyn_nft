
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
import Hex "mo:encoding/Hex";
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
            account_id_text = Hex.encode(to);
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
                h.write(buffer.toArray());
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
                h.write(buffer.toArray());
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

        public func get_logger_candy_sale_nft_origyn(request: Types.ManageSaleRequest) : async CandyTypes.CandyValue {

       
        switch (request) {
            case (#end_sale(val)) {
                return #Class([
                    {name = "variant"; value=#Text("end_sale"); immutable= true},
                    {name = "token_id"; value=#Text(val); immutable= true},
                ]);
                
            };
            case (#open_sale(val)) {
                return #Class([
                    {name = "variant"; value=#Text("open_sale"); immutable= true},
                    {name = "token_id"; value=#Text(val); immutable= true},
                ]);
                
            };
            case (#escrow_deposit(val)) {
           
            var escrow_deposit_token : Text = "";
            var escrow_deposit_token_fee : Nat = 0;
            var escrow_deposit_token_symbol : Text = "";
            var escrow_deposit_token_decimals : Nat = 0;
            var escrow_deposit_token_canister : Text = "";
            var escrow_deposit_token_standard : Text = "";
            var escrow_deposit_seller:  Text = "";
            var escrow_deposit_buyer:  Text = "";
            var escrow_deposit_trx_id:  Text = "";
            var escrow_deposit_trx_id_nat: (Nat) = (0);
            var escrow_deposit_sale_id: Text = "";
            

            switch(val.deposit.token){
                    case(#ic(t)){
                    escrow_deposit_token #=  "ic";
                    escrow_deposit_token_fee := t.fee;
                    escrow_deposit_token_symbol := t.symbol;
                    escrow_deposit_token_decimals := t.decimals;
                    escrow_deposit_token_canister := Principal.toText(t.canister);

                        switch(t.standard){
                            case(#DIP20){
                                escrow_deposit_token_standard #= "#DIP20";
                            };
                            case(#Ledger){
                                escrow_deposit_token_standard #= "#Ledger";
                            };
                            case(#EXTFungible){
                                escrow_deposit_token_standard #= "#EXTFungible";
                            };
                            case(#ICRC1){
                                escrow_deposit_token_standard #= "#ICRC1";
                            };
                        };                   
                    };
                    case(#extensible(t)){
                        escrow_deposit_token #= "extensbible";
                         D.print("Txt : " # debug_show(t)); 
                    };
            };
            switch(val.deposit.seller) {
                case(#principal(v)) { 
                    escrow_deposit_seller #= Principal.toText(v);
                 };
                case(#account(v)) { 
                    escrow_deposit_seller #= Principal.toText(v.owner);
                };
                case(#account_id(v)) { 
                    escrow_deposit_seller #= v;
                };
                case(#extensible(v)) { 
                    // Need to pass a candy class - just a string for the moment
                    escrow_deposit_seller #= "extensible";
                };
            };

            switch(val.deposit.buyer) {
                case(#principal(v)) { 
                    escrow_deposit_buyer #= Principal.toText(v);
                 };
                case(#account(v)) { 
                    escrow_deposit_buyer #= Principal.toText(v.owner);
                };
                case(#account_id(v)) { 
                    escrow_deposit_buyer #= v;
                };
                case(#extensible(v)) { 
                    // Need to pass a candy class - just a string for the moment
                    escrow_deposit_buyer #= "extensible";
                };
            };

            switch(val.deposit.sale_id) {
                case(?val) { escrow_deposit_sale_id #= val; };
                case(null) { escrow_deposit_sale_id #= "null"; };
            };

            switch(val.deposit.trx_id) {
                case(?v) {  
                    switch(v) { 
                        case(#nat(val)) { escrow_deposit_trx_id #= Nat.toText(val); };
                        case(#text(val)) { escrow_deposit_trx_id #= val; };
                        case(#extensible(val)) { escrow_deposit_trx_id #= "extensible"; }
                     };
                    
                };
                case(null) { escrow_deposit_trx_id #= "null"; };
            };
                
              return #Class([
                    {name = "variant"; value=#Text("escrow_deposit"); immutable= true},
                    {name = "escrow_token_id"; value=#Text(val.token_id); immutable= true},
                    {name = "escrow_lock_to_date"; value=#Int(switch(val.lock_to_date){case(?v){v};case(_){0}}); immutable= true},
                    {name = "escrow_deposit_token"; value=#Text(escrow_deposit_token); immutable= true},
                    {name = "escrow_deposit_token_fee"; value=#Nat(escrow_deposit_token_fee); immutable= true},
                    {name = "escrow_deposit_token_symbol"; value=#Text(escrow_deposit_token_symbol); immutable= true},
                    {name = "escrow_deposit_token_decimals"; value=#Nat(escrow_deposit_token_decimals); immutable= true},
                    {name = "escrow_deposit_token_canister"; value=#Text(escrow_deposit_token_canister); immutable= true},
                    {name = "escrow_deposit_token_standard"; value=#Text(escrow_deposit_token_standard); immutable= true},
                    {name = "escrow_deposit_seller"; value=#Text(escrow_deposit_seller); immutable= true},
                    {name = "escrow_deposit_buyer"; value=#Text(escrow_deposit_buyer); immutable= true},
                    {name = "escrow_deposit_sale_id"; value=#Text(escrow_deposit_sale_id); immutable= true},
                    {name = "escrow_deposit_trx_id"; value=#Text(escrow_deposit_trx_id); immutable= true},
                   
                ]);
                
            };
            case (#refresh_offers(val)) {
                var refresh_offers_account: Text = "";
                switch(val){
                    case(?val){ 
                         switch(val) {
                            case(#principal(v)) { 
                                refresh_offers_account #= Principal.toText(v);
                            };
                            case(#account(v)) { 
                                refresh_offers_account #= Principal.toText(v.owner);
                            };
                            case(#account_id(v)) { 
                                refresh_offers_account #= v;
                            };
                            case(#extensible(v)) { 
                                // Need to pass a candy class - just a string for the moment
                                refresh_offers_account #= "extensible";
                            };
                        };
                    };
                    case(null){
                        refresh_offers_account #= "null";
                    };
                };
                return #Class([
                    {name = "variant"; value=#Text("#refresh_offers"); immutable= true},
                    {name = "refresh_offers_account"; value=#Text(refresh_offers_account); immutable= true},
                ]);
            };
            case (#bid(val)) {

               var bid_sale_id : Text = "";
               var bid_broker_id : Text = "";
               var bid_escrow_receipt_amount : Nat = 0;
               var bid_escrow_receipt_seller : Text = "";
               var bid_escrow_receipt_buyer : Text = "";
               
               
               switch(val.broker_id){
                case(?v){ bid_broker_id #= Principal.toText(v) };
                case(null) { bid_broker_id #= "null"; }
               };

               switch(val.escrow_receipt.seller) {
                    case(#principal(v)) { 
                        bid_escrow_receipt_seller #= Principal.toText(v);
                    };
                    case(#account(v)) { 
                        bid_escrow_receipt_seller #= Principal.toText(v.owner);
                    };
                    case(#account_id(v)) { 
                        bid_escrow_receipt_seller #= v;
                    };
                    case(#extensible(v)) { 
                        // Need to pass a candy class - just a string for the moment
                        bid_escrow_receipt_seller #= "extensible";
                    };
                };

                switch(val.escrow_receipt.buyer) {
                    case(#principal(v)) { 
                        bid_escrow_receipt_buyer #= Principal.toText(v);
                    };
                    case(#account(v)) { 
                        bid_escrow_receipt_buyer #= Principal.toText(v.owner);
                    };
                    case(#account_id(v)) { 
                        bid_escrow_receipt_buyer #= v;
                    };
                    case(#extensible(v)) { 
                        // Need to pass a candy class - just a string for the moment
                        bid_escrow_receipt_buyer #= "extensible";
                    };
                };

                var bid_escrow_receipt_token : Text = "";
                var bid_escrow_receipt_token_fee : Nat = 0;
                var bid_escrow_receipt_token_symbol : Text = "";
                var bid_escrow_receipt_token_decimals : Nat = 0;
                var bid_escrow_receipt_token_canister : Text = "";
                var bid_escrow_receipt_token_standard : Text = "";

                switch(val.escrow_receipt.token){
                    case(#ic(t)){
                    bid_escrow_receipt_token #=  "ic";
                    bid_escrow_receipt_token_fee := t.fee;
                    bid_escrow_receipt_token_symbol := t.symbol;
                    bid_escrow_receipt_token_decimals := t.decimals;
                    bid_escrow_receipt_token_canister := Principal.toText(t.canister);

                        switch(t.standard){
                            case(#DIP20){
                                bid_escrow_receipt_token_standard #= "#DIP20";
                            };
                            case(#Ledger){
                                bid_escrow_receipt_token_standard #= "#Ledger";
                            };
                            case(#EXTFungible){
                                bid_escrow_receipt_token_standard #= "#EXTFungible";
                            };
                            case(#ICRC1){
                                bid_escrow_receipt_token_standard #= "#ICRC1";
                            };
                        };                   
                    };
                    case(#extensible(t)){
                        bid_escrow_receipt_token #= "extensbible";
                        //  D.print("Txt : " # debug_show(t)); 
                    };
                };

               return #Class([
                    {name = "variant"; value=#Text("#bid"); immutable= true},
                    {name = "bid_sale_id"; value=#Text(val.sale_id); immutable= true},
                    {name = "bid_broker_id"; value=#Text(bid_broker_id); immutable= true},
                    {name = "bid_escrow_receipt_token_id"; value=#Text(val.escrow_receipt.token_id); immutable= true},
                    {name = "bid_escrow_receipt_seller"; value=#Text(bid_escrow_receipt_seller); immutable= true},
                    {name = "bid_escrow_receipt_buyer"; value=#Text(bid_escrow_receipt_buyer); immutable= true},
                    {name = "bid_escrow_receipt_token"; value=#Text(bid_escrow_receipt_token); immutable= true},
                    {name = "bid_escrow_receipt_token_fee"; value=#Nat(bid_escrow_receipt_token_fee); immutable= true},
                    {name = "bid_escrow_receipt_token_symbol"; value=#Text(bid_escrow_receipt_token_symbol); immutable= true},
                    {name = "bid_escrow_receipt_token_decimals"; value=#Nat(bid_escrow_receipt_token_decimals); immutable= true},
                    {name = "bid_escrow_receipt_token_canister"; value=#Text(bid_escrow_receipt_token_canister); immutable= true},
                    {name = "bid_escrow_receipt_token_standard"; value=#Text(bid_escrow_receipt_token_standard); immutable= true},
                ]);
            };
            case (#withdraw(val)) {                
                switch(val){
                    case(#escrow(v)){
                        var withdraw_escrow_seller : Text = "";
                        var withdraw_escrow_buyer : Text = "";
                        var withdraw_escrow_withdraw_to : Text = "";

                        switch(v.seller) {
                            case(#principal(v)) { 
                                withdraw_escrow_seller #= Principal.toText(v);
                            };
                            case(#account(v)) { 
                                withdraw_escrow_seller #= Principal.toText(v.owner);
                            };
                            case(#account_id(v)) { 
                                withdraw_escrow_seller #= v;
                            };
                            case(#extensible(v)) { 
                                // Need to pass a candy class - just a string for the moment
                                withdraw_escrow_seller #= "extensible";
                            };
                        };

                        switch(v.buyer) {
                            case(#principal(v)) { 
                                withdraw_escrow_buyer #= Principal.toText(v);
                            };
                            case(#account(v)) { 
                                withdraw_escrow_buyer #= Principal.toText(v.owner);
                            };
                            case(#account_id(v)) { 
                                withdraw_escrow_buyer #= v;
                            };
                            case(#extensible(v)) { 
                                // Need to pass a candy class - just a string for the moment
                                withdraw_escrow_buyer #= "extensible";
                            };
                        };

                        switch(v.withdraw_to) {
                            case(#principal(v)) { 
                                withdraw_escrow_withdraw_to #= Principal.toText(v);
                            };
                            case(#account(v)) { 
                                withdraw_escrow_withdraw_to #= Principal.toText(v.owner);
                            };
                            case(#account_id(v)) { 
                                withdraw_escrow_withdraw_to #= v;
                            };
                            case(#extensible(v)) { 
                                // Need to pass a candy class - just a string for the moment
                                withdraw_escrow_withdraw_to #= "extensible";
                            };
                        };

                        var withdraw_escrow_token : Text = "";
                        var withdraw_escrow_token_fee : Nat = 0;
                        var withdraw_escrow_token_symbol : Text = "";
                        var withdraw_escrow_token_decimals : Nat = 0;
                        var withdraw_escrow_token_canister : Text = "";
                        var withdraw_escrow_token_standard : Text = "";

                        switch(v.token){
                            case(#ic(t)){
                            withdraw_escrow_token #=  "ic";
                            withdraw_escrow_token_fee := t.fee;
                            withdraw_escrow_token_symbol := t.symbol;
                            withdraw_escrow_token_decimals := t.decimals;
                            withdraw_escrow_token_canister := Principal.toText(t.canister);

                                switch(t.standard){
                                    case(#DIP20){
                                        withdraw_escrow_token_standard #= "#DIP20";
                                    };
                                    case(#Ledger){
                                        withdraw_escrow_token_standard #= "#Ledger";
                                    };
                                    case(#EXTFungible){
                                        withdraw_escrow_token_standard #= "#EXTFungible";
                                    };
                                    case(#ICRC1){
                                        withdraw_escrow_token_standard #= "#ICRC1";
                                    };
                                };                   
                            };
                            case(#extensible(t)){
                                withdraw_escrow_token #= "extensbible";
                                //  D.print("Txt : " # debug_show(t)); 
                            };
                        };

                        return #Class([
                            {name = "variant"; value=#Text("#withdraw_#escrow"); immutable= true},
                            {name = "withdraw_escrow_token_id"; value=#Text(v.token_id); immutable= true},
                            {name = "withdraw_escrow_amount"; value=#Nat(v.amount); immutable= true},
                            {name = "withdraw_escrow_seller"; value=#Text(withdraw_escrow_seller); immutable= true},
                            {name = "withdraw_escrow_buyer"; value=#Text(withdraw_escrow_buyer); immutable= true},
                            {name = "withdraw_escrow_withdraw_to"; value=#Text(withdraw_escrow_withdraw_to); immutable= true},
                            {name = "withdraw_escrow_token"; value=#Text(withdraw_escrow_token); immutable= true},
                            {name = "withdraw_escrow_token_fee"; value=#Nat(withdraw_escrow_token_fee); immutable= true},
                            {name = "withdraw_escrow_token_symbol"; value=#Text(withdraw_escrow_token_symbol); immutable= true},
                            {name = "withdraw_escrow_token_decimals"; value=#Nat(withdraw_escrow_token_decimals); immutable= true},
                            {name = "withdraw_escrow_token_canister"; value=#Text(withdraw_escrow_token_canister); immutable= true},
                            {name = "withdraw_escrow_token_standard"; value=#Text(withdraw_escrow_token_standard); immutable= true},
                        
                        ]);
                    };
                    case(#sale(v)){
                        var withdraw_sale_seller : Text = "";
                        var withdraw_sale_buyer : Text = "";
                        var withdraw_sale_withdraw_to : Text = "";

                        switch(v.seller) {
                            case(#principal(v)) { 
                                withdraw_sale_seller #= Principal.toText(v);
                            };
                            case(#account(v)) { 
                                withdraw_sale_seller #= Principal.toText(v.owner);
                            };
                            case(#account_id(v)) { 
                                withdraw_sale_seller #= v;
                            };
                            case(#extensible(v)) { 
                                // Need to pass a candy class - just a string for the moment
                                withdraw_sale_seller #= "extensible";
                            };
                        };

                        switch(v.buyer) {
                            case(#principal(v)) { 
                                withdraw_sale_buyer #= Principal.toText(v);
                            };
                            case(#account(v)) { 
                                withdraw_sale_buyer #= Principal.toText(v.owner);
                            };
                            case(#account_id(v)) { 
                                withdraw_sale_buyer #= v;
                            };
                            case(#extensible(v)) { 
                                // Need to pass a candy class - just a string for the moment
                                withdraw_sale_buyer #= "extensible";
                            };
                        };

                        switch(v.withdraw_to) {
                            case(#principal(v)) { 
                                withdraw_sale_withdraw_to #= Principal.toText(v);
                            };
                            case(#account(v)) { 
                                withdraw_sale_withdraw_to #= Principal.toText(v.owner);
                            };
                            case(#account_id(v)) { 
                                withdraw_sale_withdraw_to #= v;
                            };
                            case(#extensible(v)) { 
                                // Need to pass a candy class - just a string for the moment
                                withdraw_sale_withdraw_to #= "extensible";
                            };
                        };

                        var withdraw_sale_token : Text = "";
                        var withdraw_sale_token_fee : Nat = 0;
                        var withdraw_sale_token_symbol : Text = "";
                        var withdraw_sale_token_decimals : Nat = 0;
                        var withdraw_sale_token_canister : Text = "";
                        var withdraw_sale_token_standard : Text = "";

                        switch(v.token){
                            case(#ic(t)){
                            withdraw_sale_token #=  "ic";
                            withdraw_sale_token_fee := t.fee;
                            withdraw_sale_token_symbol := t.symbol;
                            withdraw_sale_token_decimals := t.decimals;
                            withdraw_sale_token_canister := Principal.toText(t.canister);

                                switch(t.standard){
                                    case(#DIP20){
                                        withdraw_sale_token_standard #= "#DIP20";
                                    };
                                    case(#Ledger){
                                        withdraw_sale_token_standard #= "#Ledger";
                                    };
                                    case(#EXTFungible){
                                        withdraw_sale_token_standard #= "#EXTFungible";
                                    };
                                    case(#ICRC1){
                                        withdraw_sale_token_standard #= "#ICRC1";
                                    };
                                };                   
                            };
                            case(#extensible(t)){
                                withdraw_sale_token #= "extensbible";
                                //  D.print("Txt : " # debug_show(t)); 
                            };
                        };

                        return #Class([
                            {name = "variant"; value=#Text("#withdraw_#sale"); immutable= true},
                            {name = "withdraw_sale_token_id"; value=#Text(v.token_id); immutable= true},
                            {name = "withdraw_sale_amount"; value=#Nat(v.amount); immutable= true},
                            {name = "withdraw_sale_seller"; value=#Text(withdraw_sale_seller); immutable= true},
                            {name = "withdraw_sale_buyer"; value=#Text(withdraw_sale_buyer); immutable= true},
                            {name = "withdraw_sale_withdraw_to"; value=#Text(withdraw_sale_withdraw_to); immutable= true},
                            {name = "withdraw_sale_token"; value=#Text(withdraw_sale_token); immutable= true},
                            {name = "withdraw_sale_token_fee"; value=#Nat(withdraw_sale_token_fee); immutable= true},
                            {name = "withdraw_sale_token_symbol"; value=#Text(withdraw_sale_token_symbol); immutable= true},
                            {name = "withdraw_sale_token_decimals"; value=#Nat(withdraw_sale_token_decimals); immutable= true},
                            {name = "withdraw_sale_token_canister"; value=#Text(withdraw_sale_token_canister); immutable= true},
                            {name = "withdraw_sale_token_standard"; value=#Text(withdraw_sale_token_standard); immutable= true},
                        
                        ]);
                    };
                    case(#reject(v)){
                        var withdraw_reject_seller : Text = "";
                        var withdraw_reject_buyer : Text = "";
                        

                        switch(v.seller) {
                            case(#principal(v)) { 
                                withdraw_reject_seller #= Principal.toText(v);
                            };
                            case(#account(v)) { 
                                withdraw_reject_seller #= Principal.toText(v.owner);
                            };
                            case(#account_id(v)) { 
                                withdraw_reject_seller #= v;
                            };
                            case(#extensible(v)) { 
                                // Need to pass a candy class - just a string for the moment
                                withdraw_reject_seller #= "extensible";
                            };
                        };

                        switch(v.buyer) {
                            case(#principal(v)) { 
                                withdraw_reject_buyer #= Principal.toText(v);
                            };
                            case(#account(v)) { 
                                withdraw_reject_buyer #= Principal.toText(v.owner);
                            };
                            case(#account_id(v)) { 
                                withdraw_reject_buyer #= v;
                            };
                            case(#extensible(v)) { 
                                // Need to pass a candy class - just a string for the moment
                                withdraw_reject_buyer #= "extensible";
                            };
                        };

                        var withdraw_reject_token : Text = "";
                        var withdraw_reject_token_fee : Nat = 0;
                        var withdraw_reject_token_symbol : Text = "";
                        var withdraw_reject_token_decimals : Nat = 0;
                        var withdraw_reject_token_canister : Text = "";
                        var withdraw_reject_token_standard : Text = "";

                        switch(v.token){
                            case(#ic(t)){
                            withdraw_reject_token #=  "ic";
                            withdraw_reject_token_fee := t.fee;
                            withdraw_reject_token_symbol := t.symbol;
                            withdraw_reject_token_decimals := t.decimals;
                            withdraw_reject_token_canister := Principal.toText(t.canister);

                                switch(t.standard){
                                    case(#DIP20){
                                        withdraw_reject_token_standard #= "#DIP20";
                                    };
                                    case(#Ledger){
                                        withdraw_reject_token_standard #= "#Ledger";
                                    };
                                    case(#EXTFungible){
                                        withdraw_reject_token_standard #= "#EXTFungible";
                                    };
                                    case(#ICRC1){
                                        withdraw_reject_token_standard #= "#ICRC1";
                                    };
                                };                   
                            };
                            case(#extensible(t)){
                                withdraw_reject_token #= "extensbible";
                                //  D.print("Txt : " # debug_show(t)); 
                            };
                        };

                        return #Class([
                            {name = "variant"; value=#Text("#withdraw_#reject"); immutable= true},
                            {name = "withdraw_reject_token_id"; value=#Text(v.token_id); immutable= true},
                            {name = "withdraw_reject_seller"; value=#Text(withdraw_reject_seller); immutable= true},
                            {name = "withdraw_reject_buyer"; value=#Text(withdraw_reject_buyer); immutable= true},
                            {name = "withdraw_reject_token"; value=#Text(withdraw_reject_token); immutable= true},
                            {name = "withdraw_reject_token_fee"; value=#Nat(withdraw_reject_token_fee); immutable= true},
                            {name = "withdraw_reject_token_symbol"; value=#Text(withdraw_reject_token_symbol); immutable= true},
                            {name = "withdraw_reject_token_decimals"; value=#Nat(withdraw_reject_token_decimals); immutable= true},
                            {name = "withdraw_reject_token_canister"; value=#Text(withdraw_reject_token_canister); immutable= true},
                            {name = "withdraw_reject_token_standard"; value=#Text(withdraw_reject_token_standard); immutable= true},
                        
                        ]);
                    };
                    case(#deposit(v)){
                        
                        var withdraw_escrow_buyer : Text = "";
                        var withdraw_escrow_withdraw_to : Text = "";

                        

                        switch(v.buyer) {
                            case(#principal(v)) { 
                                withdraw_escrow_buyer #= Principal.toText(v);
                            };
                            case(#account(v)) { 
                                withdraw_escrow_buyer #= Principal.toText(v.owner);
                            };
                            case(#account_id(v)) { 
                                withdraw_escrow_buyer #= v;
                            };
                            case(#extensible(v)) { 
                                // Need to pass a candy class - just a string for the moment
                                withdraw_escrow_buyer #= "extensible";
                            };
                        };

                        switch(v.withdraw_to) {
                            case(#principal(v)) { 
                                withdraw_escrow_withdraw_to #= Principal.toText(v);
                            };
                            case(#account(v)) { 
                                withdraw_escrow_withdraw_to #= Principal.toText(v.owner);
                            };
                            case(#account_id(v)) { 
                                withdraw_escrow_withdraw_to #= v;
                            };
                            case(#extensible(v)) { 
                                // Need to pass a candy class - just a string for the moment
                                withdraw_escrow_withdraw_to #= "extensible";
                            };
                        };

                        var withdraw_escrow_token : Text = "";
                        var withdraw_escrow_token_fee : Nat = 0;
                        var withdraw_escrow_token_symbol : Text = "";
                        var withdraw_escrow_token_decimals : Nat = 0;
                        var withdraw_escrow_token_canister : Text = "";
                        var withdraw_escrow_token_standard : Text = "";

                        switch(v.token){
                            case(#ic(t)){
                            withdraw_escrow_token #=  "ic";
                            withdraw_escrow_token_fee := t.fee;
                            withdraw_escrow_token_symbol := t.symbol;
                            withdraw_escrow_token_decimals := t.decimals;
                            withdraw_escrow_token_canister := Principal.toText(t.canister);

                                switch(t.standard){
                                    case(#DIP20){
                                        withdraw_escrow_token_standard #= "#DIP20";
                                    };
                                    case(#Ledger){
                                        withdraw_escrow_token_standard #= "#Ledger";
                                    };
                                    case(#EXTFungible){
                                        withdraw_escrow_token_standard #= "#EXTFungible";
                                    };
                                    case(#ICRC1){
                                        withdraw_escrow_token_standard #= "#ICRC1";
                                    };
                                };                   
                            };
                            case(#extensible(t)){
                                withdraw_escrow_token #= "extensbible";
                                //  D.print("Txt : " # debug_show(t)); 
                            };
                        };

                        return #Class([
                            {name = "variant"; value=#Text("#withdraw_#escrow"); immutable= true},
                            {name = "withdraw_escrow_amount"; value=#Nat(v.amount); immutable= true},
                            {name = "withdraw_escrow_buyer"; value=#Text(withdraw_escrow_buyer); immutable= true},
                            {name = "withdraw_escrow_withdraw_to"; value=#Text(withdraw_escrow_withdraw_to); immutable= true},
                            {name = "withdraw_escrow_token"; value=#Text(withdraw_escrow_token); immutable= true},
                            {name = "withdraw_escrow_token_fee"; value=#Nat(withdraw_escrow_token_fee); immutable= true},
                            {name = "withdraw_escrow_token_symbol"; value=#Text(withdraw_escrow_token_symbol); immutable= true},
                            {name = "withdraw_escrow_token_decimals"; value=#Nat(withdraw_escrow_token_decimals); immutable= true},
                            {name = "withdraw_escrow_token_canister"; value=#Text(withdraw_escrow_token_canister); immutable= true},
                            {name = "withdraw_escrow_token_standard"; value=#Text(withdraw_escrow_token_standard); immutable= true},
                        
                        ]);
                    };
                };
               
               
            };
        };
       
    };

}