
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";

import CandyTypes "mo:candy/types";
import Conversions "mo:candy/conversion";

import Properties "mo:candy/properties";
import SB "mo:stablebuffer/StableBuffer";
import Workspace "mo:candy/workspace";

import MigrationTypes "./migrations/types";
import NFTUtils "utils";
import Types "types";

module {

  let SB = MigrationTypes.Current.SB;
  let Map = MigrationTypes.Current.Map;

  let debug_channel = {
    function_announce = false;
  };

  //builds a library from a stable type
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

  //confirms if a library exists
  public func library_exists(metaData: CandyTypes.CandyValue, library_id : Text) : Bool {
    //D.print("in library_exists");
    switch(get_library_meta(metaData, library_id)){
      case(#err(err)){
        return false;
      };
      case(#ok(val)){
        return true;
      };
    };
    return false;
  };

  //confirms if a token is soulbound
  public func is_soulbound(metadata: CandyTypes.CandyValue) : Bool 
  {
    let property = Properties.getClassProperty(metadata, Types.metadata.is_soulbound);

    switch (property) {
      case(null) {return false};
      case(?p) {return Conversions.valueToBool(p.value)};
    };
  };  

  //confirms if a token is a physical item
  public func is_physical(metadata: CandyTypes.CandyValue) : Bool 
  {
    let property = get_system_var(metadata, Types.metadata.__system_physical);

    switch (property) {
      case(#Empty) {return false};
      case(_) {return Conversions.valueToBool(property)};
    };
  };


  //confirms if a token is a physical item
  public func is_in_physical_escrow(metadata: CandyTypes.CandyValue) : Bool 
  {
    let property = get_system_var(metadata, Types.metadata.__system_escrowed);

    switch (property) {
      case(#Empty) {return false};
      case(_) {return Conversions.valueToBool(property)};
    };
  };  

  //sets a system variable in the metadata
  public func set_system_var(metaData: CandyTypes.CandyValue, name: Text, value: CandyTypes.CandyValue) : CandyTypes.CandyValue {
    var this_metadata = metaData;
    //D.print("Setting System");
    switch(Properties.getClassProperty(metaData, Types.metadata.__system)){
      case(null){
        let newProp : CandyTypes.CandyValue = #Class([
          {name = name;
          value = value;
          immutable = false;}
        ]);
        this_metadata := switch(Properties.updateProperties(Conversions.valueToProperties(this_metadata), [
          {
            name = Types.metadata.__system;
            mode = #Set(newProp);
          }
        ])){
          case(#ok(props)){
            #Class(props);
          };
          case(#err(err)){
            //error shouldn't happen
            assert(false);
            #Empty; //unreachable
          };
        };
        //D.print("set metadata in the new branch");
        //D.print(debug_show(this_metadata));
        return this_metadata
      };
      case(?val){
        this_metadata := switch(Properties.updateProperties(Conversions.valueToProperties(this_metadata), [
          {
            name = Types.metadata.__system;
            mode = #Set(
              switch(Properties.updateProperties(Conversions.valueToProperties(val.value), [
                {
                  name = name;
                  mode = #Set(value);
                }
              ])){
                case(#ok(props)){
                  #Class(props);
                };
                case(#err(err)){
                  //error shouldn't happen
                  assert(false);
                  #Empty; //unreachable
                };
              }
            );
          }
        ])){
          case(#ok(props)){
            #Class(props);
          };
          case(#err(err)){
            //error shouldn't happen
            assert(false);
            #Empty; //unreachable
          };
        };
        //D.print("set metadata in the add on branch");
        //D.print(debug_show(this_metadata));
        return this_metadata;
      };
    };
  };

  //checks if an account owns an nft
  public func is_owner(metaData: CandyTypes.CandyValue, account: Types.Account) : Bool{
    switch(get_nft_owner(metaData)){
        case(#ok(data)){
          //D.print(debug_show(data));
          if(Types.account_eq(data, account) ){
            return true
          };
          return false;
        };
        case(_){ return false};
      };
  };

  //gets all the nfts for a user
  public func get_NFTs_for_user(state: Types.State, account: Types.Account) : [Text] {
    let nft_results = Buffer.Buffer<Text>(1);

    //D.print("testing balance");
    //D.print(debug_show(account));
    for(this_nft in Map.entries(state.state.nft_metadata)){
      //D.print(this_nft.0);
      switch(get_nft_owner(this_nft.1)){
        case(#ok(data)){
          //D.print(debug_show(data));
          if(Types.account_eq(data, account) ){
            nft_results.add(this_nft.0);
          };
        };
        case(_){};
      };

    };
    return Buffer.toArray(nft_results);
  };


  //gets a system var out of the system class
  public func get_system_var(metaData: CandyTypes.CandyValue, name: Text) : CandyTypes.CandyValue {
    var this_metadata = metaData;
    //D.print("Setting System");
    switch(Properties.getClassProperty(metaData, Types.metadata.__system)){
      case(null){
        return #Empty;
      };
      case(?val){
        switch(Properties.getClassProperty(val.value, name)){
          case(null){
            return #Empty;
          };
          case(?val){
            return val.value;
          };
        };
      };
    };
  };

  
  //gets the metadata for a particular library
  public func get_library_meta(metadata: CandyTypes.CandyValue, library_id : Text) : Result.Result<CandyTypes.CandyValue, Types.OrigynError>{
    switch(Properties.getClassProperty(metadata, Types.metadata.library)){
      case(null){
        return #err(Types.errors(#library_not_found, "get_library_meta - cannot find library in metadata", null));
      };
      case(?val){
        for(this_item in Conversions.valueToValueArray(val.value).vals()){
          switch(Properties.getClassProperty(this_item, Types.metadata.library_id)){
            case(null){
              
            };
            case(?id){
              if(Conversions.valueToText(id.value) == library_id){
                return #ok(this_item);
              };
            };
          };
        };
        return #err(Types.errors(#property_not_found, "get_library_meta - cannot find library id in library", null));
      };
    };
  };


  //gets a text property out of the metadata
  public func get_nft_text_property(metadata: CandyTypes.CandyValue, prop: Text) : Result.Result<Text, Types.OrigynError>{
    switch(Properties.getClassProperty(metadata, prop)){
      case(null){
        return #err(Types.errors(#property_not_found, "getNFTProperty - cannot find " # prop # " in metadata", null));
      };
      case(?val){
         return #ok(
           switch(val.value){
             case(#Text(val)){return #ok(val)};
             case(_){
               return #err(Types.errors(#property_not_found, "getNFTProperty - unknown " # prop # " type", null));
             }
           });
      };
    };
  };

  //gets a text property out of the metadata
  public func get_nft_principal_property(metadata: CandyTypes.CandyValue, prop: Text) : Result.Result<Principal, Types.OrigynError>{
    switch(Properties.getClassProperty(metadata, prop)){
      case(null){
        return #err(Types.errors(#property_not_found, "getNFTProperty - cannot find " # prop # " in metadata", null));
      };
      case(?val){
         return #ok(
           switch(val.value){
             case(#Principal(val)){return #ok(val)};
             case(_){
               return #err(Types.errors(#property_not_found, "getNFTProperty - unknown " # prop # " type", null));
             }
           });
      };
    };
  };

  //gets a bool property out of the metadata
  public func get_nft_bool_property(metadata: CandyTypes.CandyValue, prop: Text) : Result.Result<Bool, Types.OrigynError>{
    switch(Properties.getClassProperty(metadata, prop)){
      case(null){
        return #err(Types.errors(#property_not_found, "getNFTProperty - cannot find " # prop # " in metadata", null));
      };
      case(?val){
         return #ok(
           switch(val.value){
             case(#Bool(val)){return #ok(val)};
             case(_){
               return #err(Types.errors(#property_not_found, "getNFTProperty - unknown " # prop # " type", null));
             }
           });
      };
    };
  };

  //gets a Nat property out of the metadata
   public func get_nft_nat_property(metadata: CandyTypes.CandyValue, prop: Text) : Result.Result<Nat, Types.OrigynError>{
    switch(Properties.getClassProperty(metadata, prop)){
      case(null){
        return #err(Types.errors(#property_not_found, "get_nft_nat_property - cannot find " # prop # " in metadata", null));
      };
      case(?val){
         return #ok(
           switch(val.value){
             case(#Nat(val)){return #ok(val)};
             case(_){
               return #err(Types.errors(#property_not_found, "get_nft_nat_property - unknown " # prop # " type", null));
             }
           });
      };
    };
  };

  //checks if an item is minted
  public func is_minted(metaData: CandyTypes.CandyValue) : Bool{
    switch(Properties.getClassProperty(metaData, Types.metadata.__system)){
      case(null){
        //D.print("not minted, didn't find system");
        return false;
      };
      case(?val){
         switch(Properties.getClassProperty(val.value, Types.metadata.__system_status)){
          case(null){
            //D.print("not minted, didn't find status");
            return false};
          case(?status){
            if(Conversions.valueToText(status.value) == Types.nft_status_minted){
              return true;
            } else{
              //D.print("not minted, didn't find minted");
              return false;
            };
          };
        };
        
      };
    };
  };

  //gets the id of an nft
  public func get_nft_id(metadata: CandyTypes.CandyValue) : Result.Result<Text, Types.OrigynError>{
    switch(get_nft_text_property(metadata, Types.metadata.id)){
      case(#err(err)){return #err(err)};
      case(#ok(val)){return #ok(val)};
    };
  };

  //gets the primary asset for an nft
  public func get_nft_primary_asset(metadata: CandyTypes.CandyValue) : Result.Result<Text, Types.OrigynError>{
    switch(get_nft_text_property(metadata, Types.metadata.primary_asset)){
      case(#err(err)){return #err(err);};
      case(#ok(val)){return #ok(val)};
    };
  };

  //gets the preview asset for an nft
  public func get_nft_preview_asset(metadata: CandyTypes.CandyValue) : Result.Result<Text, Types.OrigynError>{
    switch(get_nft_text_property(metadata, Types.metadata.preview_asset)){
      case(#err(err)){return #err(err);};
      case(#ok(val)){return #ok(val)};
    };
  };

  //gets the experience asset
  public func get_nft_experience_asset(metadata: CandyTypes.CandyValue) : Result.Result<Text, Types.OrigynError>{
    switch(get_nft_text_property(metadata, Types.metadata.experience_asset)){
      case(#err(err)){return #err(err);};
      case(#ok(val)){return #ok(val)};
    };
  };

  //gets a libary item
  public func get_library_item_from_store(store : TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>>, token_id: Text,library_id: Text) : Result.Result<CandyTypes.Workspace, Types.OrigynError>{
    switch(store.get(token_id)){
      case(null){
        //no library exists
        D.print("token id empty");
        return #err(Types.errors(#library_not_found, "getLibraryStore - cannot find token_id in library store", null));
      };
      case(?token){
        D.print("looking for token" # debug_show(Iter.toArray<Text>(token.keys())));
        switch(token.get(library_id)){
          case(null){
            //no libaray exists
            return #err(Types.errors(#library_not_found, "getLibraryStore - cannot find library_id in library store", null));
          };
          case(?item){
            return #ok(item);
          };
        };
      };
    };
  };

  public func account_to_candy(val : Types.Account) : CandyTypes.CandyValue{
    switch(val){
          case(#principal(newOwner)){#Principal(newOwner);};
          case(#account_id(newOwner)){#Text(newOwner);};
          case(#extensible(newOwner)){newOwner;};
          case(#account(buyer)){#Array(#frozen([#Principal(buyer.owner), switch(buyer.sub_account){
              case(null){#Option(null)};
              case(?val){#Option(?#Blob(val))}
          }]))};
      }
  };

  public func token_spec_to_candy(val : Types.TokenSpec) : CandyTypes.CandyValue{
    switch(val){
          case(#ic(val)){#Class([
            {name="type"; value=#Text("IC"); immutable = true;},
            {name="data"; value=#Class([
              {name="canister"; value=#Principal(val.canister); immutable = true;},
              {name="fee"; value=#Nat(val.fee); immutable = true;},
              {name="symbol"; value=#Text(val.symbol); immutable = true;},
              {name="decimals"; value=#Nat(val.decimals); immutable = true;},
              {name="standard"; value= switch(val.standard){
                case(#DIP20){#Text("DIP20")};
                case(#Ledger){#Text("Ledger")};
                case(#EXTFungible){#Text("EXTFungible")};
                case(#ICRC1){#Text("Ledger")};
              }; immutable = true;}
            ]); immutable = true;},
          ]);};
          case(#extensible(val)){#Class([
            {name="type"; value=#Text("extensible"); immutable = true;},
            {name="data"; value=val; immutable = true;},
          ]);};
      }
  };

  public func pricing_to_candy(val : Types.PricingConfig) : CandyTypes.CandyValue{
    switch(val){
          case(#instant(val)){#Text("instant");};
          case(#flat(val)){#Class([
            {name="token"; value=token_spec_to_candy(val.token); immutable = true;},
            {name="amount"; value=#Nat(val.amount); immutable = true;},
          ])};
          case(#auction(val)){auction_config_to_candy(val)};
          case(_){#Text("NYI")};
    };
  };

  public func auction_config_to_candy(val : Types.AuctionConfig) : CandyTypes.CandyValue{

    #Class([
      {name="reserve"; value=switch(val.reserve){
                  case(null){#Empty;};
                  case(?val){#Nat(val)};
                  
        }; immutable = true;},
      {name="token"; value=token_spec_to_candy(val.token); immutable = true;},
      {name="buy_now"; value=switch(val.buy_now){
                  case(null){#Empty;};
                  case(?val){#Nat(val)};
                  
        }; immutable = true;},
      {name="start_price"; value=#Nat(val.start_price); immutable = true;},
      {name="start_date"; value=#Int(val.start_date); immutable = true;},
      {name="ending"; value=switch(val.ending){
                  case(#date(val)){#Int(val);};
                  case(#waitForQuiet(val)){#Class([
                    {name="date"; value=#Int(val.date); immutable = true;},
                    {name="extention"; value=#Nat64(val.extention); immutable = true;},
                    {name="fade"; value=#Float(val.fade); immutable = true;},
                    {name="max"; value=#Nat(val.max); immutable = true;},
                  ])};
                  
        }; immutable = true;},
        {name="min_increase"; value=switch(val.min_increase){
                  case(#percentage(val)){#Float(val);};
                  case(#amount(val)){#Nat(val)};
        }; immutable = true;},
      {name="allow_list"; value=switch(val.allow_list){
                  case(null){#Empty;};
                  case(?val){#Array(#frozen( Array.map<Principal, CandyTypes.CandyValue>(val, func(x:Principal){#Principal(x)})))};
        }; immutable = true;},

    ]);
    
  };

  public func candy_to_account(val : CandyTypes.CandyValue) :Result.Result<Types.Account, Types.OrigynError> {
    switch(val){
      case(#Principal(val)){#ok(#principal(val))};
      case(#Text(val)){#ok(#account_id(val))};
      case(#Class(val)){#ok(#extensible(#Class(val)))};
      case(#Array(ary)){
      switch(ary){
        case(#frozen(items)){
          if(items.size() > 0){
            #ok(#account({
              owner = switch(items[0]){
                case(#Principal(val)){val;};
                case(_){
                  return #err(Types.errors(#improper_interface, "candy_to_account -  improper interface, not a principal at 0 ", null));
                };
              };
              sub_account =  if(items.size() > 1){
                  switch(items[1]){
                    case(#Blob(val)){?val;};
                    case(_){
                      return #err(Types.errors(#improper_interface, "candy_to_account -  improper interface, not a blob at 1 ", null));
                    };
                  };
                }
                else {
                  null;
                }
              }));
          } else {
            return #err(Types.errors(#improper_interface, "candy_to_account -  improper interface, not enough items " # debug_show(ary), null));
          };
        };
        case(_){return #err(Types.errors(#improper_interface, "candy_to_account - send payment - improper interface, not frozen " # debug_show(ary), null));};
      };
    };
    case(_){return #err(Types.errors(#improper_interface, "candy_to_account - send payment - improper interface, not an array " , null));};
    };
  };

  
  //returns the owner of an NFT in the owner field
  //this is not the only entity that has rights.  use is_nft_owner to determine ownership rights
  public func get_nft_owner(metadata: CandyTypes.CandyValue) : Result.Result<Types.Account, Types.OrigynError>{
    switch(Properties.getClassProperty(metadata, Types.metadata.owner)){
      case(null){
        return #err(Types.errors(#owner_not_found, "get_nft_owner - cannot find owner id in metadata", null));
      };
      case(?val){
         return candy_to_account(val.value)
      };
    };
  };

    //sets the owner on the nft
  //this is not the only entity that has rights.  use is_nft_owner to determine ownership rights
  public func set_nft_owner(state: Types.State, token_id: Text, new_owner: Types.Account, caller: Principal) : Result.Result<CandyTypes.CandyValue, Types.OrigynError>{


    let current_state = state.refresh_state();

    //make sure we always have fresh meta data incase something has changed
    var fresh_metadata = switch(get_metadata_for_token(current_state, token_id, caller, ?state.canister(), state.state.collection_data.owner)){
        case(#err(err)){
            return #err(Types.errors(#token_not_found, "set_nft_owner can't get metadata " # err.flag_point, ?caller));
        };
        case(#ok(val)){
            val;
        };
    };

    var temp_metadata : CandyTypes.CandyValue = switch(Properties.updateProperties(Conversions.valueToProperties(fresh_metadata), [
          {
              name = Types.metadata.owner;
              mode = #Set(switch(new_owner){
                  case(#principal(buyer)){#Principal(buyer);};
                  case(#account_id(buyer)){#Text(buyer);};
                  case(#extensible(buyer)){buyer;};
                  case(#account(buyer)){#Array(#frozen([#Principal(buyer.owner), #Option(switch(buyer.sub_account){case(null){null}; case(?val){?#Blob(val);}})]))};
              });
          }
      ])){
          case(#ok(props)){
              #Class(props);
          };
          case(#err(err)){
              return #err(Types.errors(#update_class_error, "set_nft_owner - error setting owner " # debug_show((token_id, new_owner, fresh_metadata)), ?caller));

          };
      };

      Map.set(current_state.state.nft_metadata, Map.thash, token_id, temp_metadata);

      #ok(temp_metadata);
  };



  let account_handler = MigrationTypes.Current.account_handler;

  public func is_nft_owner(metadata: CandyTypes.CandyValue, anAccount : Types.Account) : Result.Result<Bool, Types.OrigynError>{
    
    let owner = switch(get_nft_owner(metadata)){
      case(#err(err)){
        return #err(Types.errors(err.error, "is_nft_owner check owner" # err.flag_point, null));
      };
      case(#ok(val)){
        switch(val){
          case(#extensible(ex)){
            if(Conversions.valueToText(ex) == "trx in flight"){
              return(#ok(false));
            }
          };
          case(_){};
        };
        val;

      };
    };

    if(Types.account_eq(owner, anAccount) == true){return #ok(true);};

    let wallet_shares = switch(get_system_var(metadata, Types.metadata.__system_wallet_shares)){
            case(#Empty){
                Map.new<Types.Account, Bool>();
            };
            case(#Array(#thawed(val))){
              let result = Map.new<Types.Account, Bool>();
              for(thisItem in val.vals()){
                let anAccount = switch(candy_to_account(thisItem)){
                  case(#ok(val)){val};
                  case(#err(err)){
                    return #err(Types.errors(err.error, "is_nft_owner thawed array account interface " # err.flag_point, null));
            
                  };
                };
                Map.set<Types.Account, Bool>(result, account_handler, anAccount, true);
              };
              result;
            };
            case(#Array(#frozen(val))){
              let result = Map.new<Types.Account, Bool>();
              for(thisItem in val.vals()){
                let anAccount = switch(candy_to_account(thisItem)){
                  case(#ok(val)){val};
                  case(#err(err)){
                    return #err(Types.errors(err.error, "is_nft_owner thawed array account interface " # err.flag_point, null));
            
                  };
                };

                Map.set<Types.Account, Bool>(result, account_handler, anAccount, true);
              };
              result;
            };
            case(_){
                return #err(Types.errors(#improper_interface, "share_nft_origyn - wallet_share not an array", null));
            };
        };

      let foundOwner = switch(Map.get<Types.Account, Bool>(wallet_shares, account_handler, anAccount)){
        case(?val){
          return#ok(val);
        };
        case(null){
          return #ok(false);
        };
      };



  };

  //gets the current sale(or last finished sale) for an NFT
  public func get_current_sale_id(metaData: CandyTypes.CandyValue) : CandyTypes.CandyValue{
    //D.print("in getCurrentsaleid " # " " # debug_show(Types.metadata.__system) # " " # debug_show(metaData));
    switch(Properties.getClassProperty(metaData, Types.metadata.__system)){
      case(null){
        //D.print("null");
        return #Empty;
      };
      case(?val){
        //D.print("val");
         switch(Properties.getClassProperty(val.value, Types.metadata.__system_current_sale_id)){
          case(null){return #Empty};
          case(?status){
            status.value;
          };
        };
        
      };
    };
  };

  //gets the primary host of an NFT - used for testing redirects locally
  public func get_primary_host(state : Types.State, token_id: Text, caller : Principal) : Result.Result<Text, Types.OrigynError>{
    let metadata = switch(get_metadata_for_token(state, token_id, caller, ?state.canister(), state.state.collection_data.owner)){
      case(#err(err)){return #err(Types.errors(err.error, "get_primary_host - cannot find token_id id in metadata "  # err.flag_point, ?caller))};
      case(#ok(val)){val};
    };
    switch(Properties.getClassProperty(metadata, Types.metadata.primary_host)){
      case(null){
        return #err(Types.errors(#owner_not_found, "get_primary_host - cannot find token_id id in metadata", null));
      };
      case(?val){
         return #ok(
           switch(val.value){
             
             case(#Text(val)){val};
             
             case(_){
               return #err(Types.errors(#owner_not_found, "get_primary_host - unknown host type", null));
             }
           });
      };
    };
  };

  //gets the primary ports of an NFT - used for testing redirects locally
  public func get_primary_port(state : Types.State, token_id: Text, caller : Principal) : Result.Result<Text, Types.OrigynError>{
    let metadata = switch(get_metadata_for_token(state, token_id, caller, ?state.canister(), state.state.collection_data.owner)){
      case(#err(err)){return #err(Types.errors(err.error, "get_primary_port - cannot find token_id id in metadata "  # err.flag_point, ?caller))};
      case(#ok(val)){val};
    };
    switch(Properties.getClassProperty(metadata, Types.metadata.primary_port)){
      case(null){
        return #err(Types.errors(#owner_not_found, "get_primary_port - cannot find token_id id in metadata", null));
      };
      case(?val){
         return #ok(
           switch(val.value){
             
             case(#Text(val)){val};
             
             case(_){
               return #err(Types.errors(#owner_not_found, "get_primary_port - unknown host type", null));
             }
           });
      };
    };
  };

  //gets the primary protocol of an NFT - used for testing redirects locally
  public func get_primary_protocol(state : Types.State, token_id : Text, caller : Principal) : Result.Result<Text, Types.OrigynError>{
    
    let metadata = switch(get_metadata_for_token(state, token_id, caller, ?state.canister(), state.state.collection_data.owner)){
      case(#err(err)){return #err(Types.errors(err.error, "get_primary_protocol - cannot find token_id id in metadata "  # err.flag_point, ?caller))};
      case(#ok(val)){val};
    };
    //D.print("have meta protocol");
    switch(Properties.getClassProperty(metadata, Types.metadata.primary_protocol)){
      case(null){
         D.print("have err1 protocol");
        return #err(Types.errors(#owner_not_found, "get_primary_protocol - cannot find primaryProtocol id in metadata", null));
      };
      case(?val){
         D.print("have meta protocol23");
         return #ok(
           switch(val.value){

             
             case(#Text(val)){val};
             
             case(_){
                D.print("err 45 meta protocol");
               return #err(Types.errors(#owner_not_found, "get_primary_protocol - unknown host type", null));
             }
           });
      };
    };
  };

  //cleans metadat according to permissions
  public func get_clean_metadata(metadata : CandyTypes.CandyValue, caller : Principal) : CandyTypes.CandyValue{

    let owner : ?Types.Account = switch(get_nft_owner(metadata)){
      case(#err(err)){
        null;
      };
      case(#ok(val)){
        ?val;
      };
    };

    let final_object : Buffer.Buffer<CandyTypes.Property> =  Buffer.Buffer<CandyTypes.Property>(16);
    for(this_entry in Conversions.valueToProperties(metadata).vals()){
      if(this_entry.name == Types.metadata.__system){
        //nyi: what system properties methods need to be hidden
        final_object.add(this_entry);
      } else if(this_entry.name == Types.metadata.__apps or this_entry.name == Types.metadata.library){
        //do we let apps publish to the main query
        //D.print("Adding an app node");
        
        let app_nodes = Buffer.Buffer<CandyTypes.CandyValue>(1);
        switch(this_entry.value){
          case(#Array(item)){
            switch(item){
              case(#thawed(classes)){
                for(this_item in classes.vals()){
                  //D.print("processing an item");
                  //D.print(debug_show(this_item));
                  let clean = (clean_node(this_item, owner, caller));
                  //D.print(debug_show(clean));
                  switch(clean){
                    case(#Empty){
                      //do nothing
                    };
                    case(#Class(theresult)){
                      

                      app_nodes.add(clean);
                    };
                    case(_){
                      //do nothing
                    };
                  };
                };
              };
              case(_){

              }
            };
          };
          case(_){

          };
        };
        if(app_nodes.size() > 0){
          final_object.add({name=this_entry.name; value=#Array(#thawed(Buffer.toArray(app_nodes))); immutable=false});
        };
      } 
      
      else {
        final_object.add(this_entry);
      };
    };

    return #Class(
      Buffer.toArray(final_object)
       );
  };

  //cleans a node in metadata
  public func clean_node(a_class : CandyTypes.CandyValue, owner : ?Types.Account, caller: Principal) : CandyTypes.CandyValue{
    switch(a_class){
      case(#Class(item)){
        let app_node = Properties.getClassProperty(a_class, Types.metadata.__apps_app_id);
        let library_node = Properties.getClassProperty(a_class, Types.metadata.library_id);
        let read_node = Properties.getClassProperty(a_class, "read");
        let write_node = Properties.getClassProperty(a_class, "write");
        let permissions_node = Properties.getClassProperty(a_class, "permissions");
        let data_node = Properties.getClassProperty(a_class, "data");
        switch(library_node, app_node, read_node, write_node, data_node, permissions_node){
          case(null, ?app_node, ?read_node, ?write_node, ?data_node, _){
            //D.print("cleaning an app node " # debug_show(app_node.value));
            switch(read_node.value){
              case(#Text(read_detail)){
                if(read_detail == "public"){
                  //D.print("cleaning a public node");
                  //D.print(debug_show(data_node.value));
                  let cleaned_node = clean_node(data_node.value, owner, caller);
                  switch(cleaned_node){
                    case(#Empty){
                      //D.print("recieved a cleaned node that was empty");
                      //D.print(debug_show(data_node.value));
                      //D.print(debug_show(caller));
                      return #Empty;
                    };
                    case(_){
                      //D.print("recieved a cleaned node that was not empty");
                      //D.print(debug_show(cleaned_node));
                      //D.print(debug_show(caller));
                      switch(permissions_node){
                        case(?permissions_node){
                          return #Class([
                            app_node,
                            read_node,
                            write_node,
                            permissions_node,
                            {name="data"; value=cleaned_node; immutable=false;}

                          ]);
                        };
                        case(null){
                          return #Class([
                            app_node,
                            read_node,
                            write_node,
                            {name="data"; value=cleaned_node; immutable=false;}
                          ]);
                        };
                      };
                    };
                  };
                } else if (read_detail == "owner"){
                  switch(owner){
                    case(null){return #Empty};
                    case(?owner){
                      if(Types.account_eq(owner,#principal(caller))){
                        //D.print("cleaning an owner node");
                        //D.print(debug_show(data_node.value));
                        let cleaned_node = clean_node(data_node.value, ?owner, caller);
                        switch(cleaned_node){
                          case(#Empty){
                            //D.print("recieved a cleaned node that was empty");
                            //D.print(debug_show(data_node.value));
                            //D.print(debug_show(caller));
                            return #Empty;
                          };
                          case(_){
                            //D.print("recieved a cleaned node that was not empty");
                            //D.print(debug_show(cleaned_node));
                            //D.print(debug_show(caller));
                            switch(permissions_node){
                              case(?permissions_node){
                                return #Class([
                                  app_node,
                                  read_node,
                                  write_node,
                                  permissions_node,
                                  {name="data"; value=cleaned_node; immutable=false;}

                                ]);
                              };
                              case(null){
                                return #Class([
                                  app_node,
                                  read_node,
                                  write_node,
                                  {name="data"; value=cleaned_node; immutable=false;}
                                ]);
                              };
                            };
                          };
                        };
                      } else {
                        return #Empty;
                      };
                    };
                  };
                  
                } else {
                  return #Empty
                };
              };
              case(#Class(read_detail)){
                switch(Properties.getClassProperty(read_node.value, "type")){
                  case(?read_type){
                    switch(read_type.value){
                      case(#Text(read_type_detail)){
                        if(read_type_detail == "allow"){
                          switch(Properties.getClassProperty(read_node.value,"list")){
                            case(?allow_list){
                              for(this_principal in Conversions.valueToValueArray(allow_list.value).vals()){
                                if(caller == Conversions.valueToPrincipal(this_principal)){
                                  //D.print("cleaning an allow node");
                                  //D.print(debug_show(data_node.value));
                                  let cleaned_node = clean_node(data_node.value, owner, caller);
                                  switch(cleaned_node){
                                    case(#Empty){
                                      //D.print("recieved a cleaned node that was empty");
                                      //D.print(debug_show(data_node.value));
                                      //D.print(debug_show(caller));
                                      return #Empty;
                                    };
                                    case(_){
                                      //D.print("recieved a cleaned node that was not ");
                                      //D.print(debug_show(cleaned_node));
                                      //D.print(debug_show(caller));
                                      switch(permissions_node){
                                        case(?permissions_node){
                                          return #Class([
                                            app_node,
                                            read_node,
                                            write_node,
                                            permissions_node,
                                            {name="data"; value=cleaned_node; immutable=false;}

                                          ]);
                                        };
                                        case(null){
                                          return #Class([
                                            app_node,
                                            read_node,
                                            write_node,
                                            {name="data"; value=cleaned_node; immutable=false;}
                                          ]);
                                        };
                                      };
                                    };
                                  };
                                    
                                  
                                };
                              };
                              //we didnt find the principal
                              //D.print("returning empty because we didnt find the principal");
                              return #Empty;
                            };
                            case(null){
                              //D.print("returning empty because allow_list is null");
                              return #Empty;
                            }
                          };
                        } else {//nyi: implement block list; roles based security
                          //D.print("returning empty because read type detail is not allow");
                          return #Empty;
                        };
                      };
                    
                      case(_){
                        //D.print("returning empty because read_type.value is not text of class");
                        return #Empty;
                      };
                    };
                  };
                  case(_){
                    //D.print("returning empty because read type is null");
                    return #Empty;
                  };
                };
              };
              case(_){
                //D.print("returning empty because read node is not text of class");
                return #Empty;
              };
            };
          };
          case(?library_node, null, ?read_node, _, _, _){
            //D.print("cleaning an library node " # debug_show(library_node.value));
            switch(read_node.value){
              case(#Text(read_detail)){
                if(read_detail == "public"){
                  //D.print("cleaning a public node");
                  return a_class;
                  
                } else if (read_detail == "owner"){
                  switch(owner){
                    case(null){return #Empty};
                    case(?owner){
                      if(Types.account_eq(owner,#principal(caller))){
                        //D.print("cleaning an owner node");
                        return a_class;
                      } else {
                        return #Empty;
                      };
                    };
                  };
                  
                } else {
                  return #Empty
                };
              };
              case(#Class(read_detail)){
                switch(Properties.getClassProperty(read_node.value, "type")){
                  case(?read_type){
                    switch(read_type.value){
                      case(#Text(read_type_detail)){
                        if(read_type_detail == "allow"){
                          switch(Properties.getClassProperty(read_node.value,"list")){
                            case(?allow_list){
                              for(this_principal in Conversions.valueToValueArray(allow_list.value).vals()){
                                if(caller == Conversions.valueToPrincipal(this_principal)){
                                  return a_class;
                                };
                              };
                              //we didnt find the principal
                              //D.print("returning empty because we didnt find the principal");
                              return #Empty;
                            };
                            case(null){
                              //D.print("returning empty because allow_list is null");
                              return #Empty;
                            }
                          };
                        } else {//nyi: implement block list; roles based security
                          //D.print("returning empty because read type detail is not allow");
                          return #Empty;
                        };
                      };
                    
                      case(_){
                        //D.print("returning empty because read_type.value is not text of class");
                        return #Empty;
                      };
                    };
                  };
                  case(_){
                    //D.print("returning empty because read type is null");
                    return #Empty;
                  };
                };
              };
              case(_){
                //D.print("returning empty because read node is not text of class");
                return #Empty;
              };
            };
          };
          case(null, null, ?read_node, ?write_node, ?data_node,_){
            //D.print("cleaning a permissioned node");
            switch(read_node.value){
              case(#Text(read_detail)){
                if(read_detail == "public"){
                  //D.print("cleaning a public node");
                  //D.print(debug_show(data_node.value));
                  let cleaned_node = clean_node(data_node.value, owner, caller);
                  switch(cleaned_node){
                    case(#Empty){
                      //D.print("recieved a cleaned node that was empty");
                      //D.print(debug_show(data_node.value));
                      //D.print(debug_show(caller));
                      return #Empty;
                    };
                    case(_){
                      //D.print("recieved a cleaned node that was not ");
                      //D.print(debug_show(cleaned_node));
                      //D.print(debug_show(caller));
                      switch(permissions_node){
                        case(?permissions_node){
                          return #Class([
                            read_node,
                            write_node,
                            permissions_node,
                            {name="data"; value=cleaned_node; immutable=false;}

                          ]);
                        };
                        case(null){
                          return #Class([
                            read_node,
                            write_node,
                            {name="data"; value=cleaned_node; immutable=false;}
                          ]);
                        };
                      };
                    };
                  };
                } else {
                  return #Empty
                };
              };
              case(#Class(read_detail)){
                switch(Properties.getClassProperty(read_node.value, "type")){
                  case(?read_type){
                    switch(read_type.value){
                      case(#Text(read_type_detail)){
                        if(read_type_detail == "allow"){
                          switch(Properties.getClassProperty(read_node.value,"list")){
                            case(?allow_list){
                              for(this_principal in Conversions.valueToValueArray(allow_list.value).vals()){
                                if(caller == Conversions.valueToPrincipal(this_principal)){
                                  //D.print("cleaning an allow node");
                                  //D.print(debug_show(data_node.value));
                                  let cleaned_node = clean_node(data_node.value, owner, caller);
                                  switch(cleaned_node){
                                    case(#Empty){
                                      //D.print("recieved a cleaned node that was empty");
                                      //D.print(debug_show(data_node.value));
                                      //D.print(debug_show(caller));
                                      return #Empty;
                                    };
                                    case(_){
                                      //D.print("recieved a cleaned node that was not ");
                                      //D.print(debug_show(cleaned_node));
                                      //D.print(debug_show(caller));
                                      switch(permissions_node){
                                        case(?permissions_node){
                                          return #Class([
                                            read_node,
                                            write_node,
                                            permissions_node,
                                            {name="data"; value=cleaned_node; immutable=false;}

                                          ]);
                                        };
                                        case(null){
                                          return #Class([
                                            read_node,
                                            write_node,
                                            {name="data"; value=cleaned_node; immutable=false;}
                                          ]);
                                        };
                                      };
                                    };
                                  };
                                    
                                  
                                };
                              };
                              //we didnt find the principal
                              return #Empty;
                            };
                            case(null){
                              return #Empty;
                            }
                          };
                        } else {//nyi: implement block list; roles based security
                          return #Empty;
                        };
                      };
                    
                      case(_){
                        return #Empty;
                      };
                    };
                  };
                  case(_){
                    return #Empty;
                  };
                };
              };
              case(_){
                return #Empty;
              };
            };
          };
          case(null, null, null, null, _, _){
            //D.print("cleaning a non-permissioned node");
            let collection = Buffer.Buffer<CandyTypes.Property>(item.size());
            //D.print("processing" # debug_show(item.size()));
            for(this_item in item.vals()){
              let cleaned_node = clean_node(this_item.value, owner, caller);
              switch(cleaned_node){
                case(#Empty){
                  //D.print("skipping " # this_item.name # " because empty");
                };
                case(_){
                  //D.print("processing " # this_item.name # " because not empty");
                  collection.add({name=this_item.name; value=cleaned_node; immutable=false;})
            
                }
              }
            };
            if(collection.size() > 0){
              //D.print("returning a class because we found child public nodes");
              return #Class(Buffer.toArray(collection));
            } else {
              //D.print("returning a empty because there were no public child nodes");
              return #Empty;
            };
            
          };
          case(_,_,_,_,_, _){
            return #Empty;
          }
        };
      };
      case(_){
        //shouldnt be here
        return a_class;
      };
    };
  };

  //if this function is being called for public informational purposes, the canister should be null. If you need the meta data pass in the canister id and it will be compared to the caller
  public func get_metadata_for_token(
    state: Types.State, 
    token_id : Text, 
    caller : Principal, canister : ?Principal, canister_owner: Principal) : Result.Result<CandyTypes.CandyValue, Types.OrigynError>{
    switch(Map.get(state.state.nft_metadata, Map.thash,token_id)){
      case(null){
        //nft metadata doesn't exist
        return #err(Types.errors(#token_not_found, "get_metadata_for_token - cannot find token id in metadata- " # token_id, ?caller));
      };
      case(?val){
        if(is_minted(val) == false and caller != canister_owner){
          switch(get_nft_owner(val)){
            case(#ok(val)){
              //D.print("owner compare");
              //D.print(debug_show(val));
              //D.print(debug_show(caller));
              //D.print(debug_show(canister));
              if(Types.account_eq(#principal(caller), val) == false and (canister == null or Types.account_eq(#principal(Option.get(canister, Principal.fromText("2vxsx-fae"))), #principal(caller))) and NFTUtils.is_owner_manager_network(state, caller) == false){
                return #err(Types.errors(#token_not_found, "get_metadata_for_token - cannot find token id in metadata - owners not equal" # token_id, ?caller));
              };
            };
            case(#err(err)){
              if(token_id != ""){
                return #err(Types.errors(err.error, "get_metadata_for_token - cannot find token id in metadata - error getting owner" # token_id # err.flag_point, ?caller));
              };
            };
          };
        };

        return #ok(val);
      };
    };
  };

  //adds a transaction record to the ledger
  public func add_transaction_record(state : Types.State, rec: Types.TransactionRecord, caller: Principal) : Result.Result<Types.TransactionRecord, Types.OrigynError>{
    //nyi: add indexes
    //only allow transactions for existing tokens
    let metadata = if(rec.token_id == ""){
      #Empty;
    } else {switch(get_metadata_for_token(state, rec.token_id, caller, ?state.canister(), state.state.collection_data.owner)){
      case(#err(err)){
        return #err(Types.errors(#token_not_found, "add_transaction_record " # err.flag_point, ?caller));
      };
      case(#ok(val)){
        val;
      };
      };
    };

    let ledger = switch(Map.get(state.state.nft_ledgers, Map.thash, rec.token_id)){
      case(null){
        let newLedger = SB.init<Types.TransactionRecord>();
        Map.set(state.state.nft_ledgers, Map.thash, rec.token_id, newLedger);
        newLedger;
      };
      case(?val){val};
    };

    let newTrx = {
      token_id = rec.token_id;
      index = SB.size(ledger);
      txn_type = rec.txn_type;
      timestamp = rec.timestamp;
    };

    SB.add(ledger, newTrx);

    return #ok(newTrx);
  };

  public func get_nft_library(metadata: CandyTypes.CandyValue, caller: ?Principal) : Result.Result<CandyTypes.CandyValue, Types.OrigynError>{
    switch(Properties.getClassProperty(metadata, Types.metadata.library)){
      case(null){
        return #err(Types.errors(#library_not_found, "get_library_meta - cannot find library in metadata", caller));
      };
      case(?val){
        return #ok(val.value);
      };
    };
  };

  public func get_nft_library_array(metadata: CandyTypes.CandyValue, caller: ?Principal) : Result.Result<[CandyTypes.CandyValue], Types.OrigynError>{
    switch(Properties.getClassProperty(metadata, Types.metadata.library)){
      case(null){
        return #err(Types.errors(#library_not_found, "get_nft_library_array - cannot find library in metadata", caller));
      };
      case(?val){
        switch(val.value){
          case(#Array(val)){
            switch(val){
              case(#thawed(val)){
                return #ok(val);
              };
              case(_){
                return #err(Types.errors(#library_not_found, "get_nft_library_array - cannot find library in metadata not thawed", caller));
       
              };
            }
          };
          case(_){
            return #err(Types.errors(#library_not_found, "get_nft_library_array - cannot find library in metadata not array", caller));
       
          };
        };
        
      };
    };
  };

  //gets a specific chunk out of the library storage
  public func chunk_nft_origyn(state: Types.State, request : Types.ChunkRequest, caller: ?Principal) : Result.Result<Types.ChunkContent, Types.OrigynError>{
    //D.print("looking for a chunk" # debug_show(request));
    //check mint property
              debug if(debug_channel.function_announce) D.print("in chunk_nft_origyn");

    let metadata = switch(Map.get(state.state.nft_metadata, Map.thash, request.token_id)){
      case(null){
        //nft metadata doesn't exist
        return #err(Types.errors(#token_not_found, "chunk_nft_origyn - cannot find token id in metadata- " # request.token_id, caller));
      };
      case(?val){
        if(is_minted(val) == false){
          if(caller != ?state.state.collection_data.owner){
            return #err(Types.errors(#token_not_found, "chunk_nft_origyn - cannot find token id in metadata - " # request.token_id, caller));
          };
        };
        val;

      };
    };

    let library = switch(get_library_meta(metadata, request.library_id)){
      case(#err(err)){
        return #err(Types.errors(err.error, "chunk_nft_origyn - cannot find library id in metadata - " # request.token_id # " " # request.library_id # " " # err.flag_point, caller));
      };
      case(#ok(val)){
        val;
      };
    };

    let library_type = switch(get_nft_text_property(library, Types.metadata.library_location_type)){
      case(#err(err)){
        return #err(Types.errors(err.error, "chunk_nft_origyn - cannot find library type in metadata - " # request.token_id # " " # request.library_id # " " # err.flag_point, caller));
      };
      case(#ok(val)){
        val;
      };
    };

    let use_token_id = if(library_type == "canister"){
      request.token_id;
    } else if(library_type == "collection"){
      "";
    } else {
      return #err(Types.errors(#library_not_found, "chunk_nft_origyn - library hosted off chain - " # request.token_id # " " # request.library_id  # " " # library_type, caller));
    };


    let allocation = switch(Map.get<(Text, Text), Types.AllocationRecord>(state.state.allocations, (NFTUtils.library_hash,NFTUtils.library_equal), (use_token_id, request.library_id))){
      case(null){
        return #err(Types.errors(#library_not_found, "chunk_nft_origyn - allocatio for token, library - " # use_token_id # " " # request.library_id, caller));
      };
      case(?val){val};
    };

    if(allocation.canister != state.canister()){
      //chunk isn't here....go look somewhere else
      return #ok(#remote({
          canister = allocation.canister;
          args = {
            chunk = request.chunk;
            library_id = request.library_id;
            token_id = use_token_id;
          };
        }));

    };

    //nyi: we need to check to make sure the chunk is public or caller has rights

    switch(state.nft_library.get(allocation.token_id)){
      case(null){
        return #err(Types.errors(#token_not_found, "chunk_nft_origyn - cannot find token id - " # allocation.token_id, caller));
      };
      case(?token){
        switch(token.get(allocation.library_id)){
          case(null){
            //D.print("library was null when we wanted one " # request.library_id);
            for(this_item in token.entries()){
              //D.print(this_item.0);
            };
            return #err(Types.errors(#library_not_found, "chunk_nft_origyn - cannot find library id: token_id - " # allocation.token_id  # " library_id - " # allocation.library_id, caller));
          };
          case(?item){
            switch(item.getOpt(1)){
              case(null){
                //nofiledata
                return #err(Types.errors(#library_not_found, "chunk_nft_origyn - chunk was empty: token_id - " # allocation.token_id  # " library_id - " # allocation.library_id # " chunk - " # debug_show(request.chunk), caller));
              };
              case(?zone){
                //D.print("size of zone");
                //D.print(debug_show(zone.size()));

                let requested_chunk = switch(request.chunk){
                  case(null){
                    //just want the allocation
                    return #ok(#chunk({
                        content = Blob.fromArray([]);
                        total_chunks = zone.size();
                        current_chunk = request.chunk;
                        storage_allocation = Types.allocation_record_stabalize(allocation);
                      }));

                  };
                  case(?val){val};
                };
                switch(zone.getOpt(requested_chunk)){
                  case(null){
                    return #err(Types.errors(#library_not_found, "chunk_nft_origyn - cannot find chunk id: token_id - " # request.token_id  # " library_id - " # request.library_id # " chunk - " # debug_show(request.chunk), caller));
                  };
                  case(?chunk){
                    switch(chunk){
                      case(#Bytes(wval)){
                        switch(wval){
                          case(#thawed(val)){
                            return #ok(#chunk({
                              content = Blob.fromArray(Buffer.toArray(val));
                              total_chunks = zone.size();
                              current_chunk = request.chunk;
                              storage_allocation = Types.allocation_record_stabalize(allocation);
                            }));
                          };
                          case(#frozen(val)){
                            return #ok(#chunk({
                              content = Blob.fromArray(val);
                              total_chunks = zone.size();
                              current_chunk = request.chunk;
                              storage_allocation = Types.allocation_record_stabalize(allocation);
                            }));
                          }
                        };
                      };
                      case(#Blob(wval)){
                        
                        return #ok(#chunk({
                          content = wval;
                          total_chunks = zone.size();
                          current_chunk = request.chunk;
                          storage_allocation = Types.allocation_record_stabalize(allocation);
                        }));
                          
                      };
                      case(_){
                        return #err(Types.errors(#content_not_deserializable, "chunk_nft_origyn - chunk did not deserialize: token_id - " # allocation.token_id  # " library_id - " # allocation.library_id # " chunk - " # debug_show(request.chunk), caller));
                      };
                    }
                  };
                };
              };
            };
          };

        };

      };
    };
    return #err(Types.errors(#nyi, "chunk_nft_origyn - nyi", caller));
  };

  //updates collection data
  public func collection_update_nft_origyn(state : Types.State, request: Types.ManageCollectionCommand, caller : Principal) : Result.Result<Bool, Types.OrigynError>{
    
    if(NFTUtils.is_owner_network(state,caller) == false){return #err(Types.errors(#unauthorized_access, "collection_update_origyn - not a canister owner or network", ?caller))};
    
    
    switch(request){
    
      case(#UpdateLogo(val)){
        state.state.collection_data.logo := val;
      };
      case(#UpdateName(val)){
        state.state.collection_data.name := val;
      };
      case(#UpdateSymbol(val)){
        state.state.collection_data.symbol := val;
      };
       

      case(#UpdateMetadata(key, val, immutable)){

        if( key == "id"
          or key == "library"
          or key == "__system"
          or key == "__apps"
          or key == "owner"){
            return #err(Types.errors(#malformed_metadata, "collection_update_origyn - bad key " # key, ?caller));
          };

        let current_metadata = switch(Map.get(state.state.nft_metadata,Map.thash, "")){
            case(null){
              #Class([]);
            };
            case(?val){
              val;
            };
        };

        let clean_val = switch(val){
          case(null){
            #Empty;
              };
          case(?val){
            val;
            };
        };

          
        let insert_result = 
          if(immutable == true){
            Properties.updateProperties(Conversions.valueToProperties(current_metadata), [
              {
                name = key;
                mode = #Lock(clean_val);
              }
            ]);
          } else {
            Properties.updateProperties(Conversions.valueToProperties(#Class([])), [
              {
                name = key;
                mode = #Set(clean_val);
              }
            ]);
          };
        
      
        
        switch(insert_result){
          case(#ok(props)){
            Map.set(state.state.nft_metadata, Map.thash, "",#Class(props));
          };
          case(#err(err)){
            return #err(Types.errors(#property_not_found, "collection_update_origyn - bad update " # key # " " #debug_show(err), ?caller));
        
          }
        }
          
      
        
      };
      case(#UpdateManagers(data)){
        //D.print("updateing manager" # debug_show(data));
        
        state.state.collection_data.managers := data;
        return #ok(true);
      };
      case(#UpdateOwner(data)){
        
        state.state.collection_data.owner := data;
        return #ok(true);
      };
      case(#UpdateNetwork(data)){
        
         state.state.collection_data.network := data;
        return #ok(true);
      };
    
    };
    return #ok(true);
  };


  public func ledger_to_candy(ledger : SB.StableBuffer<Types.TransactionRecord>, page: Nat, size: Nat) : [CandyTypes.CandyValue]{

    var tracker = 0;

    let results  = Buffer.Buffer<CandyTypes.CandyValue>(1);

    label search for(thisItem in SB.vals(ledger)){
      if(tracker < page * size){
        tracker += 1;
        continue search;
      };

      results.add(
        #Class([
          {name="token_id"; value=#Text(thisItem.token_id); immutable = true;},
          {name="index"; value=#Nat(thisItem.index); immutable = true;},
          {name="timestamp"; value=#Int(thisItem.timestamp); immutable = true;},
          {name="txn_type"; value=switch(thisItem.txn_type){
            case(#auction_bid(val)){
              #Class([
                  {name="type"; value=#Text("auction_bid"); immutable = true;},
                  {name="buyer"; value=account_to_candy(val.buyer); immutable = true;},
                  {name="amount"; value=#Nat(val.amount); immutable = true;},
                  
                  {name="token"; value=token_spec_to_candy(val.token); immutable = true;},
                
                  {name="sale_id"; value=#Text(val.sale_id); immutable = true;},
                  {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };
            case(#mint(val)){
              #Class([
                  {name="type"; value=#Text("mint"); immutable = true;},
                  {name="from"; value=account_to_candy(val.from); immutable = true;},
                  {name="to"; value=account_to_candy(val.to); immutable = true;},
                  {name="sale"; value=switch(val.sale){
                    case(null){#Empty};
                    case(?val){#Class([
                      {name="token"; value=token_spec_to_candy(val.token); immutable = true;},
                      {name="amount"; value=#Nat(val.amount); immutable = true;},
                      ])
                    }
                    };  immutable = true;},
                  {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };
            case(#sale_ended(val)){
              #Class([
                  {name="type"; value=#Text("sale_ended"); immutable = true;},
                  {name="buyer"; value=account_to_candy(val.buyer); immutable = true;},
                  {name="seller"; value=account_to_candy(val.seller); immutable = true;},
                  
                  {name="token"; value=token_spec_to_candy(val.token); immutable = true;},
                
                  { name="sale_id"; value=switch(val.sale_id){
                    case(null){#Empty};
                    case(?val){#Text(val)};
                    
                    };  immutable = true;},
                  {name="amount"; value=#Nat(val.amount); immutable = true;},
                  
                  {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };
            case(#royalty_paid(val)){
              #Class([
                  {name="type"; value=#Text("royalty_paid"); immutable = true;},
                  {name="buyer"; value=account_to_candy(val.buyer); immutable = true;},
                  {name="seller"; value=account_to_candy(val.seller); immutable = true;},
                  {name="reciever"; value=account_to_candy(val.reciever); immutable = true;},
                  {name="tag"; value=#Text(val.tag); immutable = true;},
                  
                  {name="token"; value=token_spec_to_candy(val.token); immutable = true;},
                
                  { name="sale_id"; value=switch(val.sale_id){
                    case(null){#Empty};
                    case(?val){#Text(val)};
                    
                    };  immutable = true;},
                  {name="amount"; value=#Nat(val.amount); immutable = true;},
                  
                  {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };
            case(#sale_opened(val)){
              #Class([
                  {name="type"; value=#Text("sale_opened"); immutable = true;},
                  {name="pricing"; value=pricing_to_candy(val.pricing); immutable = true;},

                  { name="sale_id"; value=#Text(val.sale_id);immutable = true;},
                  
                  {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };
            case(#owner_transfer(val)){
              #Class([
                {name="type"; value=#Text("owner_transfer"); immutable = true;},
                {name="from"; value=account_to_candy(val.from); immutable = true;},
                {name="to"; value=account_to_candy(val.to); immutable = true;},
                {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };
            case(#escrow_deposit(val)){
              #Class([
                {name="type"; value=#Text("escrow_deposit"); immutable = true;},
                {name="seller"; value=account_to_candy(val.seller); immutable = true;},
                {name="buyer"; value=account_to_candy(val.buyer); immutable = true;},
                {name="token"; value=token_spec_to_candy(val.token); immutable = true;},
                {name="token_id"; value=#Text(val.token_id); immutable = true;},
                {name="amount"; value=#Nat(val.amount); immutable = true;},
                {name="trx_id"; value=switch(val.trx_id){
                    case(#nat(val)){#Nat(val)};
                    case(#text(val)){#Text(val)};
                    case(#extensible(val)){val};
                    
                    }; immutable = true;},
                
                {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };
            case(#escrow_withdraw(val)){
              #Class([
                {name="type"; value=#Text("escrow_withdraw"); immutable = true;},
                {name="seller"; value=account_to_candy(val.seller); immutable = true;},
                {name="buyer"; value=account_to_candy(val.buyer); immutable = true;},
                {name="token"; value=token_spec_to_candy(val.token); immutable = true;},
                {name="token_id"; value=#Text(val.token_id); immutable = true;},
                {name="amount"; value=#Nat(val.amount); immutable = true;},
                {name="fee"; value=#Nat(val.fee); immutable = true;},
                {name="trx_id"; value=switch(val.trx_id){
                    case(#nat(val)){#Nat(val)};
                    case(#text(val)){#Text(val)};
                    case(#extensible(val)){val};
                    
                    }; immutable = true;},
                
                {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };

            case(#deposit_withdraw(val)){
              #Class([

                {name="type"; value=#Text("deposit_withdraw"); immutable = true;},
                {name="buyer"; value=account_to_candy(val.buyer); immutable = true;},
                {name="token"; value=token_spec_to_candy(val.token); immutable = true;},
                
                {name="amount"; value=#Nat(val.amount); immutable = true;},
                {name="fee"; value=#Nat(val.fee); immutable = true;},
                {name="trx_id"; value=switch(val.trx_id){
                    case(#nat(val)){#Nat(val)};
                    case(#text(val)){#Text(val)};
                    case(#extensible(val)){val};
                    
                    }; immutable = true;},
                
                {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };
            case(#sale_withdraw(val)){
              #Class([
                {name="type"; value=#Text("sale_withdraw"); immutable = true;},
                {name="seller"; value=account_to_candy(val.seller); immutable = true;},
                {name="buyer"; value=account_to_candy(val.buyer); immutable = true;},
                {name="token"; value=token_spec_to_candy(val.token); immutable = true;},
                {name="token_id"; value=#Text(val.token_id); immutable = true;},
                {name="amount"; value=#Nat(val.amount); immutable = true;},
                {name="fee"; value=#Nat(val.fee); immutable = true;},
                {name="trx_id"; value=switch(val.trx_id){
                    case(#nat(val)){#Nat(val)};
                    case(#text(val)){#Text(val)};
                    case(#extensible(val)){val};
                    
                    }; immutable = true;},
                
                {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };
            case(#canister_owner_updated(val)){
              #Class([
                {name="type"; value=#Text("canister_owner_updated"); immutable = true;},
                {name="owner"; value=#Principal(val.owner); immutable = true;},
                {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };
            case(#canister_managers_updated(val)){
              #Class([
                {name="type"; value=#Text("canister_managers_updated"); immutable = true;},
                {name="managers"; value=#Array(#frozen( Array.map<Principal, CandyTypes.CandyValue>(val.managers, func(x:Principal){#Principal(x)}))); immutable=true;},
                {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };
            case(#canister_network_updated(val)){
              #Class([
                {name="type"; value=#Text("canister_network_updated"); immutable = true;},
                {name="network"; value=#Principal(val.network); immutable = true;},
                {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };
            case(#data){
              #Text("data");
            };
            case(#burn){
              #Text("burn");
            };
            case(#extensible(val)){#Class([
              {name="type"; value=#Text("extensible"); immutable = true;},
              {name="data"; value=val; immutable = true;},
            ])};
              
          }; immutable=true;},
        ]));
      
      tracker += 1;
      if(tracker >= (page * size) + size){break search};
    };

    Buffer.toArray(results);
  };

  

}
