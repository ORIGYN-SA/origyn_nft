
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
import Timer "mo:base/Timer";
import TrieMap "mo:base/TrieMap";
import Droute "mo:droute_client/Droute";

import SB "mo:stablebuffer/StableBuffer";
import MigrationTypes "./migrations/types";
import NFTUtils "utils";
import Types "types";
import StableBuffer "mo:stablebuffer/StableBuffer";


module {

  let SB = MigrationTypes.Current.SB;
  let Map = MigrationTypes.Current.Map;

  let CandyTypes = MigrationTypes.Current.CandyTypes;
  let Conversions = MigrationTypes.Current.Conversions;
  let Properties = MigrationTypes.Current.Properties;
  let Workspace = MigrationTypes.Current.Workspace;

  let debug_channel = {
    function_announce = false;
    update_metadata = false;
  };

  //builds a library from a stable type
  /**
  * Builds a library from a stable type.
  * @param items - an array of tuples containing the name of the library and an array of tuples of the workspace name and the addressed chunk array.
  * @returns a TrieMap containing the workspace name and the workspace itself.
  */
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
  /**
  * Confirms whether a library exists.
  * @param metaData - the metadata for the token.
  * @param library_id - the id of the library.
  * @returns a boolean indicating whether the library exists.
  */
  public func library_exists(metaData: CandyTypes.CandyShared, library_id : Text) : Bool {
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
  /**
  * Confirms whether a token is soulbound.
  * @param metadata - the metadata for the token.
  * @returns a boolean indicating whether the token is soulbound.
  */
  public func is_soulbound(metadata: CandyTypes.CandyShared) : Bool 
  {
    let property = Properties.getClassPropertyShared(metadata, Types.metadata.is_soulbound);

    switch (property) {
      case(null) {return false};
      case(?p) {return Conversions.candySharedToBool(p.value)};
    };
  };  

  //confirms if a token is a physical item
  /**
  * Confirms whether a token is a physical item.
  * @param metadata - the metadata for the token.
  * @returns a boolean indicating whether the token is a physical item.
  */
  public func is_physical(metadata: CandyTypes.CandyShared) : Bool 
  {
    let property = get_system_var(metadata, Types.metadata.__system_physical);

    switch (property) {
      case(#Option(null)) {return false};
      case(_) {return Conversions.candySharedToBool(property)};
    };
  };


  //confirms if a token is a physical escrow
  /**
  * Confirms whether a token is in physical escrow.
  * @param metadata - the metadata for the token.
  * @returns a boolean indicating whether the token is in physical escrow.
  */
  public func is_in_physical_escrow(metadata: CandyTypes.CandyShared) : Bool 
  {
    let property = get_system_var(metadata, Types.metadata.__system_escrowed);

    switch (property) {
      case(#Option(null)) {return false};
      case(_) {return Conversions.candySharedToBool(property)};
    };
  };  

  //sets a system variable in the metadata
  /**
  * Confirms whether a token is in physical escrow.
  * @param metadata - the metadata for the token.
  * @returns a boolean indicating whether the token is in physical escrow.
  */
  public func set_system_var(metaData: CandyTypes.CandyShared, name: Text, value: CandyTypes.CandyShared) : CandyTypes.CandyShared {
    var this_metadata = metaData;
    //D.print("Setting System");
    switch(Properties.getClassPropertyShared(metaData, Types.metadata.__system)){
      case(null){
        let newProp : CandyTypes.CandyShared = #Class([
          {name = name;
          value = value;
          immutable = false;}
        ]);
        this_metadata := switch(Properties.updatePropertiesShared(Conversions.candySharedToProperties(this_metadata), [
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
            #Option(null); //unreachable
          };
        };
        //D.print("set metadata in the new branch");
        //D.print(debug_show(this_metadata));
        return this_metadata
      };
      case(?val){
        this_metadata := switch(Properties.updatePropertiesShared(Conversions.candySharedToProperties(this_metadata), [
          {
            name = Types.metadata.__system;
            mode = #Set(
              switch(Properties.updatePropertiesShared(Conversions.candySharedToProperties(val.value), [
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
                  #Option(null); //unreachable
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
            #Option(null); //unreachable
          };
        };
        //D.print("set metadata in the add on branch");
        //D.print(debug_show(this_metadata));
        return this_metadata;
      };
    };
  };

  //checks if an account owns an nft
  /**
  * checks if an account owns an nft
  * @param {CandyTypes.CandyShared} metaData - the metadata of the NFT
  * @param {Types.Account} account - the account to check if they own the NFT
  * @return {Boolean} - true if the account owns the NFT, false otherwise
  */
  public func is_owner(metaData: CandyTypes.CandyShared, account: Types.Account) : Bool{
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
  /**
  * gets all the NFTs for a user
  * @param {Types.State} state - the state of the NFTs
  * @param {Types.Account} account - the account to retrieve the NFTs for
  * @return {Array<Text>} - an array of NFTs owned by the user
  */
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
  /**
  * gets a system variable out of the system class
  * @param {CandyTypes.CandyShared} metaData - the metadata to retrieve the system variable from
  * @param {Text} name - the name of the system variable to retrieve
  * @return {CandyTypes.CandyShared} - the value of the requested system variable
  */
  public func get_system_var(metaData: CandyTypes.CandyShared, name: Text) : CandyTypes.CandyShared {
    var this_metadata = metaData;
    //D.print("Setting System");
    switch(Properties.getClassPropertyShared(metaData, Types.metadata.__system)){
      case(null){
        return #Option(null);
      };
      case(?val){
        switch(Properties.getClassPropertyShared(val.value, name)){
          case(null){
            return #Option(null);
          };
          case(?val){
            return val.value;
          };
        };
      };
    };
  };

  
  //gets the metadata for a particular library
  /**
  * gets the metadata for a particular library
  * @param {CandyTypes.CandyShared} metadata - the metadata of the NFT
  * @param {Text} library_id - the id of the library to retrieve the metadata for
  * @return {Result.Result<CandyTypes.CandyShared, Types.OrigynError>} - a result containing the metadata for the library or an error
  */
  public func get_library_meta(metadata: CandyTypes.CandyShared, library_id : Text) : Result.Result<CandyTypes.CandyShared, Types.OrigynError>{
    switch(Properties.getClassPropertyShared(metadata, Types.metadata.library)){
      case(null){
        return #err(Types.errors(null,  #library_not_found, "get_library_meta - cannot find library in metadata", null));
      };
      case(?val){
        for(this_item in Conversions.candySharedToValueArray(val.value).vals()){
          switch(Properties.getClassPropertyShared(this_item, Types.metadata.library_id)){
            case(null){
              
            };
            case(?id){
              if(Conversions.candySharedToText(id.value) == library_id){
                return #ok(this_item);
              };
            };
          };
        };
        return #err(Types.errors(null,  #property_not_found, "get_library_meta - cannot find library id in library", null));
      };
    };
  };


  //gets a text property out of the metadata
  /**
  * gets a text property out of the metadata of an NFT
  * @param {CandyTypes.CandyShared} metadata - the metadata of the NFT
  * @param {Text} prop - the property to retrieve from the metadata
  * @return {Types.OrigynTextResult} - a result containing the requested text property or an error
  */
  public func get_nft_text_property(metadata: CandyTypes.CandyShared, prop: Text) : Types.OrigynTextResult{
    switch(Properties.getClassPropertyShared(metadata, prop)){
      case(null){
        return #err(Types.errors(null,  #property_not_found, "getNFTProperty - cannot find " # prop # " in metadata", null));
      };
      case(?val){
         return #ok(
           switch(val.value){
             case(#Text(val)){return #ok(val)};
             case(_){
               return #err(Types.errors(null,  #property_not_found, "getNFTProperty - unknown " # prop # " type", null));
             }
           });
      };
    };
  };

  //gets a text property out of the metadata
  /**
  * gets a principal property out of the metadata of an NFT
  * @param {CandyTypes.CandyShared} metadata - the metadata of the NFT
  * @param {Text} prop - the property to retrieve from the metadata
  * @return {Result.Result<Principal, Types.OrigynError>} - a result containing the requested principal property or an error
  */
  public func get_nft_principal_property(metadata: CandyTypes.CandyShared, prop: Text) : Result.Result<Principal, Types.OrigynError>{
    switch(Properties.getClassPropertyShared(metadata, prop)){
      case(null){
        return #err(Types.errors(null,  #property_not_found, "getNFTProperty - cannot find " # prop # " in metadata", null));
      };
      case(?val){
         return #ok(
           switch(val.value){
             case(#Principal(val)){return #ok(val)};
             case(_){
               return #err(Types.errors(null,  #property_not_found, "getNFTProperty - unknown " # prop # " type", null));
             }
           });
      };
    };
  };

  //gets a bool property out of the metadata
  /**
  * Gets a bool property out of the metadata.
  *
  * @param {CandyTypes.CandyShared} metadata - The metadata of the NFT.
  * @param {Text} prop - The name of the property to get.
  * @returns {Types.OrigynBoolResult} A result containing either the bool property or an error.
  */
  public func get_nft_bool_property(metadata: CandyTypes.CandyShared, prop: Text) : Types.OrigynBoolResult{
    switch(Properties.getClassPropertyShared(metadata, prop)){
      case(null){
        return #err(Types.errors(null,  #property_not_found, "getNFTProperty - cannot find " # prop # " in metadata", null));
      };
      case(?val){
         return #ok(
           switch(val.value){
             case(#Bool(val)){return #ok(val)};
             case(_){
               return #err(Types.errors(null,  #property_not_found, "getNFTProperty - unknown " # prop # " type", null));
             }
           });
      };
    };
  };

  //gets a Nat property out of the metadata
  /**
  * Gets a Nat property out of the metadata.
  *
  * @param {CandyTypes.CandyShared} metadata - The metadata of the NFT.
  * @param {Text} prop - The name of the property to get.
  * @returns {Result.Result<Nat, Types.OrigynError>} A result containing either the Nat property or an error.
  */
   public func get_nft_nat_property(metadata: CandyTypes.CandyShared, prop: Text) : Result.Result<Nat, Types.OrigynError>{
    switch(Properties.getClassPropertyShared(metadata, prop)){
      case(null){
        return #err(Types.errors(null,  #property_not_found, "get_nft_nat_property - cannot find " # prop # " in metadata", null));
      };
      case(?val){
         return #ok(
           switch(val.value){
             case(#Nat(val)){return #ok(val)};
             case(_){
               return #err(Types.errors(null,  #property_not_found, "get_nft_nat_property - unknown " # prop # " type", null));
             }
           });
      };
    };
  };

  //checks if an item is minted
  /**
  * Checks if an item is minted.
  *
  * @param {CandyTypes.CandyShared} metaData - The metadata of the NFT.
  * @returns {Bool} True if the NFT is minted, otherwise false.
  */
  public func is_minted(metaData: CandyTypes.CandyShared) : Bool{
    switch(Properties.getClassPropertyShared(metaData, Types.metadata.__system)){
      case(null){
        //D.print("not minted, didn't find system");
        return false;
      };
      case(?val){
         switch(Properties.getClassPropertyShared(val.value, Types.metadata.__system_status)){
          case(null){
            //D.print("not minted, didn't find status");
            return false};
          case(?status){
            if(Conversions.candySharedToText(status.value) == Types.nft_status_minted){
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
  /**
  * Gets the id of an NFT.
  *
  * @param {CandyTypes.CandyShared} metadata - The metadata of the NFT.
  * @returns {Types.OrigynTextResult} A result containing either the id or an error.
  */
  public func get_nft_id(metadata: CandyTypes.CandyShared) : Types.OrigynTextResult{
    switch(get_nft_text_property(metadata, Types.metadata.id)){
      case(#err(err)){return #err(err)};
      case(#ok(val)){return #ok(val)};
    };
  };

  //gets the primary asset for an nft
  /**
  * Gets the primary asset for an NFT.
  *
  * @param {CandyTypes.CandyShared} metadata - The metadata of the NFT.
  * @returns {Types.OrigynTextResult} A result containing either the primary asset or an error.
  */
  public func get_nft_primary_asset(metadata: CandyTypes.CandyShared) : Types.OrigynTextResult{
    switch(get_nft_text_property(metadata, Types.metadata.primary_asset)){
      case(#err(err)){return #err(err);};
      case(#ok(val)){return #ok(val)};
    };
  };

  //gets the preview asset for an nft
  /**
  * Gets the preview asset for an NFT.
  *
  * @param {CandyTypes.CandyShared} metadata - The metadata of the NFT.
  * @returns {Types.OrigynTextResult} A result containing either the preview asset or an error.
  */
  public func get_nft_preview_asset(metadata: CandyTypes.CandyShared) : Types.OrigynTextResult{
    switch(get_nft_text_property(metadata, Types.metadata.preview_asset)){
      case(#err(err)){return #err(err);};
      case(#ok(val)){return #ok(val)};
    };
  };

  //gets the experience asset
  /**
  * Gets the experience asset for an NFT.
  *
  * @param {CandyTypes.CandyShared} metadata - The metadata of the NFT.
  * @returns {Types.OrigynTextResult} A result containing either the experience asset or an error.
  */
  public func get_nft_experience_asset(metadata: CandyTypes.CandyShared) : Types.OrigynTextResult{
    switch(get_nft_text_property(metadata, Types.metadata.experience_asset)){
      case(#err(err)){return #err(err);};
      case(#ok(val)){return #ok(val)};
    };
  };

  //gets a libary item
  /**
  * Gets a library item from the store.
  *
  * @param {TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>>} store - The store containing the library items.
  * @param {Text} token_id - The id of the token.
  * @param {Text} library_id - The id of the library.
  * @returns {Result.Result<CandyTypes.Workspace, Types.OrigynError>} A result containing either the library item or an error.
  */
  public func get_library_item_from_store(store : TrieMap.TrieMap<Text, TrieMap.TrieMap<Text, CandyTypes.Workspace>>, token_id: Text,library_id: Text) : Result.Result<CandyTypes.Workspace, Types.OrigynError>{
    //D.print("get_library_item_from_store");
    switch(store.get(token_id)){
      case(null){
        //no library exists
        if(debug_channel.update_metadata) D.print("token id empty");
        return #err(Types.errors(null,  #library_not_found, "getLibraryStore - cannot find token_id in library store", null));
      };
      case(?token){
        if(debug_channel.update_metadata) D.print("looking for token" # debug_show(Iter.toArray<Text>(token.keys())));
        switch(token.get(library_id)){
          case(null){
            //no libaray exists
            if(debug_channel.update_metadata) D.print("no libaray exists");
            return #err(Types.errors(null,  #library_not_found, "getLibraryStore - cannot find library_id in library store", null));
          };
          case(?item){
            //if(debug_channel.update_metadata) D.print("ok..found item" # debug_show(item));
            return #ok(item);
          };
        };
      };
    };
  };

  /**
  * Converts an account value to a CandyShared.
  * @param {Types.Account} val - The account value to convert.
  * @returns {CandyTypes.CandyShared} The converted CandyShared.
  */
  public func account_to_candy(val : Types.Account) : CandyTypes.CandyShared{
    switch(val){
          case(#principal(newOwner)){#Principal(newOwner);};
          case(#account_id(newOwner)){#Text(newOwner);};
          case(#extensible(newOwner)){newOwner;};
          case(#account(buyer)){#Array([#Principal(buyer.owner), switch(buyer.sub_account){
              case(null){#Option(null)};
              case(?val){#Option(?#Blob(val))}
          }])};
      }
  };

  /**
  * Converts a token specification to a CandyShared.
  * @param {Types.TokenSpec} val - The token specification to convert.
  * @returns {CandyTypes.CandyShared} The converted CandyShared.
  */
  public func token_spec_to_candy(val : Types.TokenSpec) : CandyTypes.CandyShared{
    switch(val){
          case(#ic(val)){#Class([
            {name="type"; value=#Text("IC"); immutable = true;},
            {name="data"; value=#Class([
              {name="canister"; value=#Principal(val.canister); immutable = true;},
              {name="fee"; value=switch(val.fee){
                case(null) #Option(null);
                case(?val) #Nat(val);
              }; immutable = true;},
              {name="symbol"; value=#Text(val.symbol); immutable = true;},
              {name="decimals"; value=#Nat(val.decimals); immutable = true;},
              {name="standard"; value= switch(val.standard){
                case(#DIP20){#Text("DIP20")};
                case(#Ledger){#Text("Ledger")};
                case(#EXTFungible){#Text("EXTFungible")};
                case(#ICRC1){#Text("Ledger")};
                case(#Other(val)){val};
              }; immutable = true;}
            ]); immutable = true;},
          ]);};
          case(#extensible(val)){#Class([
            {name="type"; value=#Text("extensible"); immutable = true;},
            {name="data"; value=val; immutable = true;},
          ]);};
      }
  };

  /**
  * Converts a pricing configuration to a CandyShared.
  * @param {Types.PricingConfig} val - The pricing configuration to convert.
  * @returns {CandyTypes.CandyShared} The converted CandyShared.
  */
  public func pricing_to_candy(val : MigrationTypes.Current.PricingConfig) : CandyTypes.CandyShared{
    switch(val){
          case(#instant(val)){#Text("instant");};
          case(#ask(val)){ask_config_to_candy(val)};
          case(#auction(val)){auction_config_to_candy(val)};
          case(_){#Text("NYI")};
    };
  };

  /**
  * Converts a pricing configuration sared to a CandyShared.
  * @param {Types.PricingConfigShared} val - The pricing configuration to convert.
  * @returns {CandyTypes.CandyShared} The converted CandyShared.
  */
  public func pricing_shared_to_candy(val : MigrationTypes.Current.PricingConfigShared) : CandyTypes.CandyShared{
    switch(val){
          case(#instant(val)){#Text("instant");};
          case(#ask(val)){ask_config_shared_to_candy(val)};
          case(#auction(val)){auction_config_to_candy(val)};
          case(_){#Text("NYI")};
    };
  };

  /**
  * Converts an auction configuration to a CandyShared.
  * @param {Types.AuctionConfig} val - The auction configuration to convert.
  * @returns {CandyTypes.CandyShared} The converted CandyShared.
  */
  public func auction_config_to_candy(val : Types.AuctionConfig) : CandyTypes.CandyShared{

    #Class([
      {name="reserve"; value=switch(val.reserve){
                  case(null){#Option(null);};
                  case(?val){#Nat(val)};
                  
        }; immutable = true;},
      {name="token"; value=token_spec_to_candy(val.token); immutable = true;},
      {name="buy_now"; value=switch(val.buy_now){
                  case(null){#Option(null);};
                  case(?val){#Nat(val)};
                  
        }; immutable = true;},
      {name="start_price"; value=#Nat(val.start_price); immutable = true;},
      {name="start_date"; value=#Int(val.start_date); immutable = true;},
      {name="ending"; value=switch(val.ending){
                  case(#date(val)){#Int(val);};
                  case(#wait_for_quiet(val)){#Class([
                    {name="date"; value=#Int(val.date); immutable = true;},
                    {name="extension"; value=#Nat64(val.extension); immutable = true;},
                    {name="fade"; value=#Float(val.fade); immutable = true;},
                    {name="max"; value=#Nat(val.max); immutable = true;},
                  ])};
                  
        }; immutable = true;},
        {name="min_increase"; value=switch(val.min_increase){
                  case(#percentage(val)){#Float(val);};
                  case(#amount(val)){#Nat(val)};
        }; immutable = true;},
      {name="allow_list"; value=switch(val.allow_list){
                  case(null){#Option(null);};
                  case(?val){#Array(Array.map<Principal, CandyTypes.CandyShared>(val, func(x:Principal){#Principal(x)}))};
        }; immutable = true;},

    ]);
    
  };

  /**
  * Converts an ask configuration to a CandyShared.
  * @param {Types.AskConfig} val - The ask configuration to convert.
  * @returns {CandyTypes.CandyShared} The converted CandyShared.
  */
  public func ask_config_to_candy(val : MigrationTypes.Current.AskConfig) : CandyTypes.CandyShared{

    let candy_buffer = Buffer.Buffer<CandyTypes.PropertyShared>(1);

    let items : Map.Map<MigrationTypes.Current.AskFeatureKey, MigrationTypes.Current.AskFeature> = switch(val){
      case(?val) val;
      case(null) Map.new<MigrationTypes.Current.AskFeatureKey, MigrationTypes.Current.AskFeature>();
    };

    for(thisItem in Map.vals<MigrationTypes.Current.AskFeatureKey, MigrationTypes.Current.AskFeature>(items)){
      switch(thisItem){
        case(#atomic){
          candy_buffer.add(
            {name="atomic"; value=#Bool(true); immutable = true;});
        };
        case(#buy_now(e)){
          candy_buffer.add(
            {name="buy_now"; value=#Nat(e); immutable = true;});
        };
        case(#wait_for_quiet(e)){
          candy_buffer.add({name="wait_for_quiet"; value=#Class([
                    
                    {name="extension"; value=#Nat64(e.extension); immutable = true;},
                    {name="fade"; value=#Float(e.fade); immutable = true;},
                    {name="max"; value=#Nat(e.max); immutable = true;},
                  ]); immutable = true;});
        };
        case(#allow_list(e)){
            candy_buffer.add({name="allow_list"; value=#Array(Array.map<Principal, CandyTypes.CandyShared>(e, func(x:Principal){#Principal(x)})); immutable = true;});
        };
        case(#notify(e)){
          candy_buffer.add({name="notify"; value=#Array(Array.map<Principal, CandyTypes.CandyShared>(e, func(x:Principal){#Principal(x)})); immutable = true;});
        };
        case(#reserve(e)){
          candy_buffer.add(
            {name="reserve"; value=#Nat(e); immutable = true;});
        };
        case(#start_date(e)){
          candy_buffer.add(
            {name="start_date"; value=#Int(e); immutable = true;});
        };
        case(#start_price(e)){
          candy_buffer.add(
            {name="start_price"; value=#Nat(e); immutable = true;});
        };
        case(#min_increase(e)){
         candy_buffer.add(
            
            switch(e){
                  case(#percentage(val)){{name="min_increase_percent"; value=#Float(val); immutable = true;}};
                  case(#amount(val)){{name="min_increase_amount"; value=#Nat(val); immutable = true;}};
            });
        };
        case(#ending(e)){
          candy_buffer.add(
            switch(e){
                  case(#date(val)){{name="ending_date"; value=#Int(val); immutable = true;}};
                  case(#timeout(val)){{name="ending_timeout"; value=#Nat(val); immutable = true;}};
            });
        };
        case(#token(e)){
          candy_buffer.add(
            {name="token"; value=token_spec_to_candy(e); immutable = true;});
          
        };
        case(#dutch(e)){
          candy_buffer.add({name="dutch"; value=#Map([
            (#Text("time_unit"),switch(e.time_unit){
                          
                          case(#hour(val)){#Text("hour")};
                          case(#minute(val)){#Text("minute")};
                          case(#day(val)){#Text("day")};
            }),
            (#Text("time_value"),switch(e.time_unit){
                          
                          case(#hour(val)){#Nat(val)};
                          case(#minute(val)){#Nat(val)};
                          case(#day(val)){#Nat(val)};
            }),
            (#Text("decay_type"),switch(e.decay_type){
                          case(#flat(val)){#Text("flat")};
                          case(#percent(val)){#Text("percent")};
            }),
            (#Text("decay_value"),switch(e.decay_type){
                          case(#flat(val)){#Nat(val)};
                          case(#percent(val)){#Float(val)};
            }),
          
          ]); immutable = true;});
        };
        case(#kyc(e)){
          candy_buffer.add(
            {name="kyc"; value=#Principal(e); immutable = true;});
        };
        case(#nifty_settlement(e)){
          candy_buffer.add({name="nifty_settlement"; value=#Map([
            (#Text("duration"),switch(e.duration){
                          case(?val){#Int(val)};
                          case(null){#Option(null)};
            }),
            (#Text("expiration"),switch(e.expiration){
                          case(?val){#Int(val)};
                          case(null){#Option(null)};
            }),
            (#Text("fixed"),#Bool(e.fixed)),
            (#Text("lenderOffer"),#Bool(e.lenderOffer)),
            (#Text("interestRatePerSecond"),#Float(e.interestRatePerSecond))
          
          ]); immutable = true;});
        };
      };

    };

    #Class(Buffer.toArray(candy_buffer));
    
  };

  /**
  * Converts an ask configuration to a CandyShared.
  * @param {Types.AskConfigShared} val - The ask configuration to convert.
  * @returns {CandyTypes.CandyShared} The converted CandyShared.
  */
  public func ask_config_shared_to_candy(val : MigrationTypes.Current.AskConfigShared) : CandyTypes.CandyShared{

    let candy_buffer = Buffer.Buffer<CandyTypes.PropertyShared>(1);

    let items : [MigrationTypes.Current.AskFeature] = switch(val){
      case(?val) val;
      case(null) [];
    };

    for(thisItem in items.vals()){
      switch(thisItem){
        case(#atomic){
          candy_buffer.add(
            {name="atomic"; value=#Bool(true); immutable = true;});
        };
        case(#buy_now(e)){
          candy_buffer.add(
            {name="buy_now"; value=#Nat(e); immutable = true;});
        };
        case(#wait_for_quiet(e)){
          candy_buffer.add({name="wait_for_quiet"; value=#Class([
                    
                    {name="extension"; value=#Nat64(e.extension); immutable = true;},
                    {name="fade"; value=#Float(e.fade); immutable = true;},
                    {name="max"; value=#Nat(e.max); immutable = true;},
                  ]); immutable = true;});
        };
        case(#allow_list(e)){
            candy_buffer.add({name="allow_list"; value=#Array(Array.map<Principal, CandyTypes.CandyShared>(e, func(x:Principal){#Principal(x)})); immutable = true;});
        };
        case(#notify(e)){
          candy_buffer.add({name="notify"; value=#Array(Array.map<Principal, CandyTypes.CandyShared>(e, func(x:Principal){#Principal(x)})); immutable = true;});
        };
        case(#reserve(e)){
          candy_buffer.add(
            {name="reserve"; value=#Nat(e); immutable = true;});
        };
        case(#start_date(e)){
          candy_buffer.add(
            {name="start_date"; value=#Int(e); immutable = true;});
        };
        case(#start_price(e)){
          candy_buffer.add(
            {name="start_price"; value=#Nat(e); immutable = true;});
        };
        case(#min_increase(e)){
         candy_buffer.add(
            
            switch(e){
                  case(#percentage(val)){{name="min_increase_percent"; value=#Float(val); immutable = true;}};
                  case(#amount(val)){{name="min_increase_amount"; value=#Nat(val); immutable = true;}};
            });
        };
        case(#ending(e)){
          candy_buffer.add(
            switch(e){
                  case(#date(val)){{name="ending_date"; value=#Int(val); immutable = true;}};
                  case(#timeout(val)){{name="ending_timeout"; value=#Nat(val); immutable = true;}};
            });
        };
        case(#token(e)){
          candy_buffer.add(
            {name="token"; value=token_spec_to_candy(e); immutable = true;});
          
        };
        case(#dutch(e)){
          candy_buffer.add({name="dutch"; value=#Map([
            (#Text("time_unit"),switch(e.time_unit){
                          
                          case(#hour(val)){#Text("hour")};
                          case(#minute(val)){#Text("minute")};
                          case(#day(val)){#Text("day")};
            }),
            (#Text("time_value"),switch(e.time_unit){
                          
                          case(#hour(val)){#Nat(val)};
                          case(#minute(val)){#Nat(val)};
                          case(#day(val)){#Nat(val)};
            }),
            (#Text("decay_type"),switch(e.decay_type){
                          case(#flat(val)){#Text("flat")};
                          case(#percent(val)){#Text("percent")};
            }),
            (#Text("decay_value"),switch(e.decay_type){
                          case(#flat(val)){#Nat(val)};
                          case(#percent(val)){#Float(val)};
            }),
          
          ]); immutable = true;});
        };
        case(#kyc(e)){
          candy_buffer.add(
            {name="kyc"; value=#Principal(e); immutable = true;});
        };
        case(#nifty_settlement(e)){
          candy_buffer.add({name="nifty_settlement"; value=#Map([
            (#Text("duration"),switch(e.duration){
                          case(?val){#Int(val)};
                          case(null){#Option(null)};
            }),
            (#Text("expiration"),switch(e.expiration){
                          case(?val){#Int(val)};
                          case(null){#Option(null)};
            }),
            (#Text("fixed"),#Bool(e.fixed)),
            (#Text("lenderOffer"),#Bool(e.lenderOffer)),
            (#Text("interestRatePerSecond"),#Float(e.interestRatePerSecond))
          
          ]); immutable = true;});
        };
      };

    };

    #Class(Buffer.toArray(candy_buffer));
    
  };

  /**
  * Converts a CandyShared to an account value.
  * @param {CandyTypes.CandyShared} val - The CandyShared to convert.
  * @returns {Types.BearerResult} The converted account value.
  */
  public func candy_to_account(val : CandyTypes.CandyShared) :Types.BearerResult {
    switch(val){
      case(#Principal(val)){#ok(#principal(val))};
      case(#Text(val)){#ok(#account_id(val))};
      case(#Class(val)){#ok(#extensible(#Class(val)))};
      case(#Array(items)){
        if(items.size() > 0){
          #ok(#account({
            owner = switch(items[0]){
              case(#Principal(val)){val;};
              case(_){
                return #err(Types.errors(null,  #improper_interface, "candy_to_account -  improper interface, not a principal at 0 ", null));
              };
            };
            sub_account =  if(items.size() > 1){
                switch(items[1]){
                  case(#Blob(val)){?val;};
                  case(_){
                    return #err(Types.errors(null,  #improper_interface, "candy_to_account -  improper interface, not a blob at 1 ", null));
                  };
                };
              }
              else {
                null;
              }
            }));
          } else {
            return #err(Types.errors(null,  #improper_interface, "candy_to_account -  improper interface, not enough items " # debug_show(items), null));
          };
    };
    case(_){return #err(Types.errors(null,  #improper_interface, "candy_to_account - send payment - improper interface, not an array " , null));};
    };
  };

  
  //returns the owner of an NFT in the owner field
  //this is not the only entity that has rights.  use is_nft_owner to determine ownership rights
  /**
  * Gets the owner of an NFT in the owner field.
  * @param {CandyTypes.CandyShared} metadata - The metadata of the NFT.
  * @returns {Types.BearerResult} The owner of the NFT.
  */
  public func get_nft_owner(metadata: CandyTypes.CandyShared) : Types.BearerResult {
    switch(Properties.getClassPropertyShared(metadata, Types.metadata.owner)){
      case(null){
        return #err(Types.errors(null,  #owner_not_found, "get_nft_owner - cannot find owner id in metadata", null));
      };
      case(?val){
         return candy_to_account(val.value)
      };
    };
  };

  //returns the owner of an NFT in the owner field
  //this is not the only entity that has rights.  use is_nft_owner to determine ownership rights
  /**
  * Gets the owner of an NFT in the owner field.
  * @param {Text} token_id - The id of the NFT.
  * @returns {Types.BearerResult} The owner of the NFT.
  */
  public func get_nft_owner_by_id(state: Types.State, token_id: Text) : Types.BearerResult {

    let metadata = switch(get_metadata_for_token(state,token_id, state.canister(), ?state.canister(), state.state.collection_data.owner)){
       case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "get_nft_owner_by_id " # err.flag_point, ?state.canister()));
       case(#ok(val)) val;
    };

    switch(Properties.getClassPropertyShared(metadata, Types.metadata.owner)){
      case(null){
        return #err(Types.errors(null,  #owner_not_found, "get_nft_owner_by_id - cannot find owner id in metadata", null));
      };
      case(?val){
         return candy_to_account(val.value)
      };
    };
  };

    //sets the owner on the nft
  //this is not the only entity that has rights.  use is_nft_owner to determine ownership rights
  /**
  * Sets the owner of an NFT.
  * @param {Types.State} state - The state of the contract.
  * @param {Text} token_id - The ID of the token to update.
  * @param {Types.Account} new_owner - The new owner of the token.
  * @param {Principal} caller - The principal of the caller.
  * @returns {Result.Result<CandyTypes.CandyShared, Types.OrigynError>} The updated metadata of the NFT.
  */
  public func set_nft_owner(state: Types.State, token_id: Text, new_owner: Types.Account, caller: Principal) : Result.Result<CandyTypes.CandyShared, Types.OrigynError>{


    let current_state = state.refresh_state();

    //make sure we always have fresh meta data incase something has changed
    var fresh_metadata = switch(get_metadata_for_token(current_state, token_id, caller, ?state.canister(), state.state.collection_data.owner)){
        case(#err(err)){
            return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "set_nft_owner can't get metadata " # err.flag_point, ?caller));
        };
        case(#ok(val)){
            val;
        };
    };

    var temp_metadata : CandyTypes.CandyShared = switch(Properties.updatePropertiesShared(Conversions.candySharedToProperties(fresh_metadata), [
          {
              name = Types.metadata.owner;
              mode = #Set(switch(new_owner){
                  case(#principal(buyer)){#Principal(buyer);};
                  case(#account_id(buyer)){#Text(buyer);};
                  case(#extensible(buyer)){buyer;};
                  case(#account(buyer)){#Array([#Principal(buyer.owner), #Option(switch(buyer.sub_account){case(null){null}; case(?val){?#Blob(val);}})])};
              });
          }
      ])){
          case(#ok(props)){
              #Class(props);
          };
          case(#err(err)){
              return #err(Types.errors(?state.canistergeekLogger,  #update_class_error, "set_nft_owner - error setting owner " # debug_show((token_id, new_owner, fresh_metadata)), ?caller));

          };
      };

      Map.set(current_state.state.nft_metadata, Map.thash, token_id, temp_metadata);

      #ok(temp_metadata);
  };



  let account_handler = MigrationTypes.Current.account_handler;

  /**
  * Checks if the provided account is the owner of the specified NFT.
  *
  * @param {CandyTypes.CandyShared} metadata - Metadata of the NFT
  * @param {Types.Account} anAccount - The account to check if it's the owner
  * @returns {Types.OrigynBoolResult} - Result object containing a boolean indicating whether or not the provided account is the owner of the NFT
  */
  public func is_nft_owner(metadata: CandyTypes.CandyShared, anAccount : Types.Account) : Types.OrigynBoolResult{
    
    let owner = switch(get_nft_owner(metadata)){
      case(#err(err)){
        return #err(Types.errors(null,  err.error, "is_nft_owner check owner" # err.flag_point, null));
      };
      case(#ok(val)){
        switch(val){
          case(#extensible(ex)){
            if(Conversions.candySharedToText(ex) == "trx in flight"){
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
            case(#Option(null)){
                Map.new<Types.Account, Bool>();
            };
            case(#Array(val)){
              let result = Map.new<Types.Account, Bool>();
              for(thisItem in val.vals()){
                let anAccount = switch(candy_to_account(thisItem)){
                  case(#ok(val)){val};
                  case(#err(err)){
                    return #err(Types.errors(null,  err.error, "is_nft_owner thawed array account interface " # err.flag_point, null));
            
                  };
                };
                Map.set<Types.Account, Bool>(result, account_handler, anAccount, true);
              };
              result;
            };
            case(_){
                return #err(Types.errors(null,  #improper_interface, "share_nft_origyn - wallet_share not an array", null));
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
  /**
  * Gets the current sale (or last finished sale) for the specified NFT.
  *
  * @param {CandyTypes.CandyShared} metaData - Metadata of the NFT
  * @returns {CandyTypes.CandyShared} - The current sale ID (or empty if no sale exists)
  */
  public func get_current_sale_id(metaData: CandyTypes.CandyShared) : CandyTypes.CandyShared{
    //D.print("in getCurrentsaleid " # " " # debug_show(Types.metadata.__system) # " " # debug_show(metaData));
    switch(Properties.getClassPropertyShared(metaData, Types.metadata.__system)){
      case(null){
        //D.print("null");
        return #Option(null);
      };
      case(?val){
        //D.print("val");
         switch(Properties.getClassPropertyShared(val.value, Types.metadata.__system_current_sale_id)){
          case(null){return #Option(null)};
          case(?status){
            status.value;
          };
        };
        
      };
    };
  };

  //gets the primary host of an NFT - used for testing redirects locally
  /**
  * Gets the primary host of the specified NFT. Used for testing redirects locally.
  *
  * @param {Types.State} state - The current state of the system
  * @param {Text} token_id - The ID of the NFT
  * @param {Principal} caller - The caller's principal ID
  * @returns {Types.OrigynTextResult} - Result object containing a string of the primary host of the NFT, or an error if it couldn't be found
  */
  public func get_primary_host(state : Types.State, token_id: Text, caller : Principal) : Types.OrigynTextResult{
    let metadata = switch(get_metadata_for_token(state, token_id, caller, ?state.canister(), state.state.collection_data.owner)){
      case(#err(err)){return #err(Types.errors(?state.canistergeekLogger,  err.error, "get_primary_host - cannot find token_id id in metadata "  # err.flag_point, ?caller))};
      case(#ok(val)){val};
    };
    switch(Properties.getClassPropertyShared(metadata, Types.metadata.primary_host)){
      case(null){
        return #err(Types.errors(?state.canistergeekLogger,  #owner_not_found, "get_primary_host - cannot find token_id id in metadata", null));
      };
      case(?val){
         return #ok(
           switch(val.value){
             
             case(#Text(val)){val};
             
             case(_){
               return #err(Types.errors(?state.canistergeekLogger,  #owner_not_found, "get_primary_host - unknown host type", null));
             }
           });
      };
    };
  };

  //gets the primary ports of an NFT - used for testing redirects locally
  /**
  * Gets the primary port of the specified NFT. Used for testing redirects locally.
  *
  * @param {Types.State} state - The current state of the system
  * @param {Text} token_id - The ID of the NFT
  * @param {Principal} caller - The caller's principal ID
  * @returns {Types.OrigynTextResult} - Result object containing a string of the primary port of the NFT, or an error if it couldn't be found
  */
  public func get_primary_port(state : Types.State, token_id: Text, caller : Principal) : Types.OrigynTextResult{
    let metadata = switch(get_metadata_for_token(state, token_id, caller, ?state.canister(), state.state.collection_data.owner)){
      case(#err(err)){return #err(Types.errors(?state.canistergeekLogger,  err.error, "get_primary_port - cannot find token_id id in metadata "  # err.flag_point, ?caller))};
      case(#ok(val)){val};
    };
    switch(Properties.getClassPropertyShared(metadata, Types.metadata.primary_port)){
      case(null){
        return #err(Types.errors(?state.canistergeekLogger,  #owner_not_found, "get_primary_port - cannot find token_id id in metadata", null));
      };
      case(?val){
         return #ok(
           switch(val.value){
             
             case(#Text(val)){val};
             
             case(_){
               return #err(Types.errors(?state.canistergeekLogger,  #owner_not_found, "get_primary_port - unknown host type", null));
             }
           });
      };
    };
  };

  //gets the primary protocol of an NFT - used for testing redirects locally
  /**
  * Gets the primary protocol of the specified NFT. Used for testing redirects locally.
  *
  * @param {Types.State} state - The current state of the system
  * @param {Text} token_id - The ID of the NFT
  * @param {Principal} caller - The caller's principal ID
  * @returns {Types.OrigynTextResult} - Result object containing a string of the primary protocol of the NFT, or an error if it couldn't be found
  */
  public func get_primary_protocol(state : Types.State, token_id : Text, caller : Principal) : Types.OrigynTextResult{
    
    let metadata = switch(get_metadata_for_token(state, token_id, caller, ?state.canister(), state.state.collection_data.owner)){
      case(#err(err)){return #err(Types.errors(?state.canistergeekLogger,  err.error, "get_primary_protocol - cannot find token_id id in metadata "  # err.flag_point, ?caller))};
      case(#ok(val)){val};
    };
    //D.print("have meta protocol");
    switch(Properties.getClassPropertyShared(metadata, Types.metadata.primary_protocol)){
      case(null){
         if(debug_channel.update_metadata) D.print("have err1 protocol");
        return #err(Types.errors(?state.canistergeekLogger,  #owner_not_found, "get_primary_protocol - cannot find primaryProtocol id in metadata", null));
      };
      case(?val){
         if(debug_channel.update_metadata) D.print("have meta protocol23");
         return #ok(
           switch(val.value){

             
             case(#Text(val)){val};
             
             case(_){
                if(debug_channel.update_metadata) D.print("err 45 meta protocol");
               return #err(Types.errors(?state.canistergeekLogger,  #owner_not_found, "get_primary_protocol - unknown host type", null));
             }
           });
      };
    };
  };

  //cleans metadat according to permissions
  /**
  * Cleans metadata according to permissions.
  *
  * @param {CandyTypes.CandyShared} metadata - The metadata to clean
  * @param {Principal} caller - The caller's principal ID
  * @returns {CandyTypes.CandyShared} - The cleaned metadata
  */
  public func get_clean_metadata(metadata : CandyTypes.CandyShared, caller : Principal) : CandyTypes.CandyShared{

    let owner : ?Types.Account = switch(get_nft_owner(metadata)){
      case(#err(err)){
        null;
      };
      case(#ok(val)){
        ?val;
      };
    };

    let final_object : Buffer.Buffer<CandyTypes.PropertyShared> =  Buffer.Buffer<CandyTypes.PropertyShared>(16);
    for(this_entry in Conversions.candySharedToProperties(metadata).vals()){
      if(this_entry.name == Types.metadata.__system){
        //nyi: what system properties methods need to be hidden
        final_object.add(this_entry);
      } else if(this_entry.name == Types.metadata.__apps or this_entry.name == Types.metadata.library){
        //do we let apps publish to the main query
        //D.print("Adding an app node");
        
        let app_nodes = Buffer.Buffer<CandyTypes.CandyShared>(1);
        switch(this_entry.value){
          case(#Array(item)){
            
                for(this_item in item.vals()){
                  //D.print("processing an item");
                  //D.print(debug_show(this_item));
                  let clean = (clean_node(metadata, this_item, owner, caller));
                  //D.print(debug_show(clean));
                  switch(clean){
                    case(#Option(null)){
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

          };
        };
        if(app_nodes.size() > 0){
          final_object.add({name=this_entry.name; value=#Array(Buffer.toArray(app_nodes)); immutable=false});
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
  /**
  * Cleans a node in metadata based on permissions
  * @param {CandyTypes.CandyShared} a_class - the node to clean
  * @param {?Types.Account} owner - the account that owns the node, if any
  * @param {Principal} caller - the principal making the request
  * @returns {CandyTypes.CandyShared} the cleaned node
  */
  public func clean_node(root_class: CandyTypes.CandyShared, a_class : CandyTypes.CandyShared, owner : ?Types.Account, caller: Principal) : CandyTypes.CandyShared{
    switch(a_class){
      case(#Class(item)){
        let app_node = Properties.getClassPropertyShared(a_class, Types.metadata.__apps_app_id);
        let library_node = Properties.getClassPropertyShared(a_class, Types.metadata.library_id);
        let read_node = Properties.getClassPropertyShared(a_class, "read");
        let write_node = Properties.getClassPropertyShared(a_class, "write");
        let permissions_node = Properties.getClassPropertyShared(a_class, "permissions");
        let data_node = Properties.getClassPropertyShared(a_class, "data");
        switch(library_node, app_node, read_node, write_node, data_node, permissions_node){
          case(null, ?app_node, ?read_node, ?write_node, ?data_node, _){
            //D.print("cleaning an app node " # debug_show(app_node.value));
            switch(read_node.value){
              case(#Text(read_detail)){
                if(read_detail == "public"){
                  //D.print("cleaning a public node");
                  //D.print(debug_show(data_node.value));
                  let cleaned_node = clean_node(root_class, data_node.value, owner, caller);
                  switch(cleaned_node){
                    case(#Option(null)){
                      //D.print("recieved a cleaned node that was empty");
                      //D.print(debug_show(data_node.value));
                      //D.print(debug_show(caller));
                      return #Option(null);
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
                } else if (read_detail == "nft_owner"){
                  switch(owner){
                    case(null){return #Option(null)};
                    case(?owner){
                      if(switch(is_nft_owner(root_class, #principal(caller))){
                        case(#ok(result)) result;
                        case(#err(err)) false;
                      }){
                        //D.print("cleaning an owner node");
                        //D.print(debug_show(data_node.value));
                        let cleaned_node = clean_node(root_class, data_node.value, ?owner, caller);
                        switch(cleaned_node){
                          case(#Option(null)){
                            //D.print("recieved a cleaned node that was empty");
                            //D.print(debug_show(data_node.value));
                            //D.print(debug_show(caller));
                            return #Option(null);
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
                        return #Option(null);
                      };
                    };
                  };
                  
                } else {
                  return #Option(null);
                };
              };
              case(#Class(read_detail)){
                switch(Properties.getClassPropertyShared(read_node.value, "type")){
                  case(?read_type){
                    switch(read_type.value){
                      case(#Text(read_type_detail)){
                        if(read_type_detail == "allow"){
                          switch(Properties.getClassPropertyShared(read_node.value,"list")){
                            case(?allow_list){
                              for(this_principal in Conversions.candySharedToValueArray(allow_list.value).vals()){
                                if(caller == Conversions.candySharedToPrincipal(this_principal)){
                                  //D.print("cleaning an allow node");
                                  //D.print(debug_show(data_node.value));
                                  let cleaned_node = clean_node(root_class, data_node.value, owner, caller);
                                  switch(cleaned_node){
                                    case(#Option(null)){
                                      //D.print("recieved a cleaned node that was empty");
                                      //D.print(debug_show(data_node.value));
                                      //D.print(debug_show(caller));
                                      return #Option(null);
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
                              return #Option(null);
                            };
                            case(null){
                              //D.print("returning empty because allow_list is null");
                              return #Option(null);
                            }
                          };
                        } else {//nyi: implement block list; roles based security
                          //D.print("returning empty because read type detail is not allow");
                          return #Option(null);
                        };
                      };
                    
                      case(_){
                        //D.print("returning empty because read_type.value is not text of class");
                        return #Option(null);
                      };
                    };
                  };
                  case(_){
                    //D.print("returning empty because read type is null");
                    return #Option(null);
                  };
                };
              };
              case(_){
                //D.print("returning empty because read node is not text of class");
                return #Option(null);
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
                  
                } else if (read_detail == "nft_owner"){
                  switch(owner){
                    case(null){return #Option(null)};
                    case(?owner){
                      if(switch(is_nft_owner(root_class, #principal(caller))){
                        case(#ok(result)) result;
                        case(#err(err)) false;
                      }){
                        //D.print("cleaning an owner node");
                        return a_class;
                      } else {
                        return #Option(null);
                      };
                    };
                  };
                  
                } else {
                  return #Option(null);
                };
              };
              case(#Class(read_detail)){
                switch(Properties.getClassPropertyShared(read_node.value, "type")){
                  case(?read_type){
                    switch(read_type.value){
                      case(#Text(read_type_detail)){
                        if(read_type_detail == "allow"){
                          switch(Properties.getClassPropertyShared(read_node.value,"list")){
                            case(?allow_list){
                              for(this_principal in Conversions.candySharedToValueArray(allow_list.value).vals()){
                                if(caller == Conversions.candySharedToPrincipal(this_principal)){
                                  return a_class;
                                };
                              };
                              //we didnt find the principal
                              //D.print("returning empty because we didnt find the principal");
                              return #Option(null);
                            };
                            case(null){
                              //D.print("returning empty because allow_list is null");
                              return #Option(null);
                            }
                          };
                        } else {//nyi: implement block list; roles based security
                          //D.print("returning empty because read type detail is not allow");
                          return #Option(null);
                        };
                      };
                    
                      case(_){
                        //D.print("returning empty because read_type.value is not text of class");
                        return #Option(null);
                      };
                    };
                  };
                  case(_){
                    //D.print("returning empty because read type is null");
                    return #Option(null);
                  };
                };
              };
              case(_){
                //D.print("returning empty because read node is not text of class");
                return #Option(null);
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
                  let cleaned_node = clean_node(root_class, data_node.value, owner, caller);
                  switch(cleaned_node){
                    case(#Option(null)){
                      //D.print("recieved a cleaned node that was empty");
                      //D.print(debug_show(data_node.value));
                      //D.print(debug_show(caller));
                      return #Option(null);
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
                  return #Option(null);
                };
              };
              case(#Class(read_detail)){
                switch(Properties.getClassPropertyShared(read_node.value, "type")){
                  case(?read_type){
                    switch(read_type.value){
                      case(#Text(read_type_detail)){
                        if(read_type_detail == "allow"){
                          switch(Properties.getClassPropertyShared(read_node.value,"list")){
                            case(?allow_list){
                              for(this_principal in Conversions.candySharedToValueArray(allow_list.value).vals()){
                                if(caller == Conversions.candySharedToPrincipal(this_principal)){
                                  //D.print("cleaning an allow node");
                                  //D.print(debug_show(data_node.value));
                                  let cleaned_node = clean_node(root_class, data_node.value, owner, caller);
                                  switch(cleaned_node){
                                    case(#Option(null)){
                                      //D.print("recieved a cleaned node that was empty");
                                      //D.print(debug_show(data_node.value));
                                      //D.print(debug_show(caller));
                                      return #Option(null);
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
                              return #Option(null);
                            };
                            case(null){
                              return #Option(null);
                            }
                          };
                        } else {//nyi: implement block list; roles based security
                          return #Option(null);
                        };
                      };
                    
                      case(_){
                        return #Option(null);
                      };
                    };
                  };
                  case(_){
                    return #Option(null);
                  };
                };
              };
              case(_){
                return #Option(null);
              };
            };
          };
          case(null, null, null, null, _, _){
            //D.print("cleaning a non-permissioned node");
            let collection = Buffer.Buffer<CandyTypes.PropertyShared>(item.size());
            //D.print("processing" # debug_show(item.size()));
            for(this_item in item.vals()){
              let cleaned_node = clean_node(root_class, this_item.value, owner, caller);
              switch(cleaned_node){
                case(#Option(null)){
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
              return #Option(null);
            };
            
          };
          case(_,_,_,_,_, _){
            return #Option(null);
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
  /**
  * Retrieves the metadata for a token
  * @param {Types.State} state - the current state of the canister
  * @param {Text} token_id - the ID of the token to retrieve metadata for
  * @param {Principal} caller - the caller of the function
  * @param {Principal|null} canister - the ID of the canister to retrieve metadata for
  * @param {Principal} canister_owner - the owner of the canister
  * @returns {Result.Result<CandyTypes.CandyShared, Types.OrigynError>} - the result of the metadata retrieval attempt
  */
  public func get_metadata_for_token(
    state: Types.State, 
    token_id : Text, 
    caller : Principal, canister : ?Principal, canister_owner: Principal) : Result.Result<CandyTypes.CandyShared, Types.OrigynError>{
    switch(Map.get(state.state.nft_metadata, Map.thash,token_id)){
      case(null){
        //nft metadata doesn't exist
        return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "get_metadata_for_token - cannot find token id in metadata- " # token_id, ?caller));
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
                return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "get_metadata_for_token - cannot find token id in metadata - owners not equal" # token_id, ?caller));
              };
            };
            case(#err(err)){
              if(token_id != ""){
                return #err(Types.errors(?state.canistergeekLogger,  err.error, "get_metadata_for_token - cannot find token id in metadata - error getting owner" # token_id # err.flag_point, ?caller));
              };
            };
          };
        };

        return #ok(val);
      };
    };
  };

  //adds a transaction record to the ledger
  /**
  * Adds a transaction record to the ledger
  * @param {Types.State} state - the current state of the canister
  * @param {MigrationTypes.Current.TransactionRecord} rec - the transaction record to add
  * @param {Principal} caller - the caller of the function
  * @returns {Result.Result<MigrationTypes.Current.TransactionRecord, Types.OrigynError>} - the result of the transaction record addition attempt
  */
  public func add_transaction_record(state : Types.State, rec: MigrationTypes.Current.TransactionRecord, caller: Principal) : Result.Result<MigrationTypes.Current.TransactionRecord, Types.OrigynError>{
    //nyi: add indexes
    //only allow transactions for existing tokens
    let metadata = if(rec.token_id == ""){
      #Option(null);
    } else {switch(get_metadata_for_token(state, rec.token_id, caller, ?state.canister(), state.state.collection_data.owner)){
      case(#err(err)){
        return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "add_transaction_record " # err.flag_point, ?caller));
      };
      case(#ok(val)){
        val;
      };
      };
    };

    let ledger = switch(Map.get<Text, SB.StableBuffer<MigrationTypes.Current.TransactionRecord>>(state.state.nft_ledgers, Map.thash, rec.token_id)){
      case(null){
        let newLedger = SB.init<MigrationTypes.Current.TransactionRecord>();
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

    //Announce Trx
    let announce = announceTransaction(state, rec, caller, newTrx);

    return #ok(newTrx);
  };

  /**
  * Announces a transaction
  * @param {Types.State} state - the current state of the canister
  * @param {MigrationTypes.Current.TransactionRecord} rec - the transaction record being announced
  * @param {Principal} caller - the caller of the function
  * @param {MigrationTypes.Current.TransactionRecord} newTrx - the newly added transaction record
  * @returns {void}
  */
  public func announceTransaction(state : Types.State, rec : MigrationTypes.Current.TransactionRecord, caller : Principal, newTrx : MigrationTypes.Current.TransactionRecord) : () {


        if(state.state.collection_data.announce_canister == null){return;};
        
        let eventNamespace = "com.origyn.nft.event";
        let (eventType, payload) = switch (rec.txn_type) {
          case (#auction_bid(data)) { ("auction_bid", #Class([
            {name="token_id"; value = #Text(rec.token_id); immutable=true;},
            {name="canister"; value = #Principal(state.canister());immutable=true;},
            {name="sale_id"; value = #Text(data.sale_id); immutable=true;}
          ]) )};
          case (#mint _) { ("mint", #Text("mint")) };
          case (#sale_ended _) {( "sale_ended", #Text("sale_ended")) };
        };

        let eventName = eventNamespace # "." # eventType;

        ignore Timer.setTimer(#seconds(0), func () : async () {
          let event = await* Droute.publish(state.state.droute, eventName, payload);
        });

    };


  /**
  * Retrieves the library metadata for an NFT
  * @param {CandyTypes.CandyShared} metadata - the metadata for the NFT
  * @param {Principal} [caller=null] - the caller of the function
  * @returns {Result.Result<CandyTypes.CandyShared, Types.OrigynError>} - the result of the metadata retrieval attempt
  */
  public func get_nft_library(metadata: CandyTypes.CandyShared, caller: ?Principal) : Result.Result<CandyTypes.CandyShared, Types.OrigynError>{
    switch(Properties.getClassPropertyShared(metadata, Types.metadata.library)){
      case(null){
        return #err(Types.errors(null,  #library_not_found, "get_library_meta - cannot find library in metadata", caller));
      };
      case(?val){
        return #ok(val.value);
      };
    };
  };

  /**
  * Retrieves an array of the library metadata for an NFT
  * @param {CandyTypes.CandyShared} metadata - the metadata for the NFT
  * @param {Principal} [caller=null] - the caller of the function
  * @returns {Result.Result<[CandyTypes.CandyShared], Types.OrigynError>} - the result of the metadata retrieval attempt
  */
  public func get_nft_library_array(metadata: CandyTypes.CandyShared, caller: ?Principal) : Result.Result<[CandyTypes.CandyShared], Types.OrigynError>{
    switch(Properties.getClassPropertyShared(metadata, Types.metadata.library)){
      case(null){
        return #err(Types.errors(null,  #library_not_found, "get_nft_library_array - cannot find library in metadata", caller));
      };
      case(?val){
        switch(val.value){
          case(#Array(val)){
            
            return #ok(val);
              
          };
          case(_){
            return #err(Types.errors(null,  #library_not_found, "get_nft_library_array - cannot find library in metadata not array", caller));
       
          };
        };
        
      };
    };
  };

  //gets a specific chunk out of the library storage
  /**
  * Gets a specific chunk out of the library storage
  *
  * @param {Types.State} state - the current state of the canister
  * @param {Types.ChunkRequest} request - the request for the chunk content
  * @param {?Principal} caller - the principal making the request
  * @returns {Types.ChunkResult} - a Result type containing either the chunk content or an error message
  */
  public func chunk_nft_origyn(state: Types.State, request : Types.ChunkRequest, caller: ?Principal) : Types.ChunkResult{
    //D.print("looking for a chunk" # debug_show(request));
    //check mint property
              debug if(debug_channel.function_announce) D.print("in chunk_nft_origyn");

    let metadata = switch(Map.get(state.state.nft_metadata, Map.thash, request.token_id)){
      case(null){
        //nft metadata doesn't exist
        return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "chunk_nft_origyn - cannot find token id in metadata- " # request.token_id, caller));
      };
      case(?val){
        if(is_minted(val) == false){
          if(caller != ?state.state.collection_data.owner){
            return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "chunk_nft_origyn - cannot find token id in metadata - " # request.token_id, caller));
          };
        };
        val;

      };
    };

    let library = switch(get_library_meta(metadata, request.library_id)){
      case(#err(err)){
        return #err(Types.errors(?state.canistergeekLogger,  err.error, "chunk_nft_origyn - cannot find library id in metadata - " # request.token_id # " " # request.library_id # " " # err.flag_point, caller));
      };
      case(#ok(val)){
        val;
      };
    };

    let library_type = switch(get_nft_text_property(library, Types.metadata.library_location_type)){
      case(#err(err)){
        return #err(Types.errors(?state.canistergeekLogger,  err.error, "chunk_nft_origyn - cannot find library type in metadata - " # request.token_id # " " # request.library_id # " " # err.flag_point, caller));
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
      return #err(Types.errors(?state.canistergeekLogger,  #library_not_found, "chunk_nft_origyn - library hosted off chain - " # request.token_id # " " # request.library_id  # " " # library_type, caller));
    };


    let allocation = switch(Map.get<(Text, Text), Types.AllocationRecord>(state.state.allocations, (NFTUtils.library_hash,NFTUtils.library_equal), (use_token_id, request.library_id))){
      case(null){
        return #err(Types.errors(?state.canistergeekLogger,  #library_not_found, "chunk_nft_origyn - allocatio for token, library - " # use_token_id # " " # request.library_id, caller));
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
        return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "chunk_nft_origyn - cannot find token id - " # allocation.token_id, caller));
      };
      case(?token){
        switch(token.get(allocation.library_id)){
          case(null){
            //D.print("library was null when we wanted one " # request.library_id);
            for(this_item in token.entries()){
              //D.print(this_item.0);
            };
            return #err(Types.errors(?state.canistergeekLogger,  #library_not_found, "chunk_nft_origyn - cannot find library id: token_id - " # allocation.token_id  # " library_id - " # allocation.library_id, caller));
          };
          case(?item){
            switch(SB.getOpt(item,1)){
              case(null){
                //nofiledata
                return #err(Types.errors(?state.canistergeekLogger,  #library_not_found, "chunk_nft_origyn - chunk was empty: token_id - " # allocation.token_id  # " library_id - " # allocation.library_id # " chunk - " # debug_show(request.chunk), caller));
              };
              case(?zone){
                //D.print("size of zone");
                //D.print(debug_show(SB.size(zone)));

                let requested_chunk = switch(request.chunk){
                  case(null){
                    //just want the allocation
                    return #ok(#chunk({
                        content = Blob.fromArray([]);
                        total_chunks = SB.size(zone);
                        current_chunk = request.chunk;
                        storage_allocation = Types.allocation_record_stabalize(allocation);
                      }));

                  };
                  case(?val){val};
                };
                switch(SB.getOpt(zone,requested_chunk)){
                  case(null){
                    return #err(Types.errors(?state.canistergeekLogger,  #library_not_found, "chunk_nft_origyn - cannot find chunk id: token_id - " # request.token_id  # " library_id - " # request.library_id # " chunk - " # debug_show(request.chunk), caller));
                  };
                  case(?chunk){
                    switch(chunk){
                      case(#Bytes(wval)){
                        return #ok(#chunk({
                          content = Blob.fromArray(SB.toArray(wval));
                          total_chunks = SB.size(zone);
                          current_chunk = request.chunk;
                          storage_allocation = Types.allocation_record_stabalize(allocation);
                        }));
                      };
                      case(#Blob(wval)){
                        
                        return #ok(#chunk({
                          content = wval;
                          total_chunks = SB.size(zone);
                          current_chunk = request.chunk;
                          storage_allocation = Types.allocation_record_stabalize(allocation);
                        }));
                          
                      };
                      case (#Nat32(wval)) {
                        /*
                          let sizeZone = switch(item.getOpt(2)){
                            case(null){
                              return #err(Types.errors(?state.canistergeekLogger,  #content_not_deserializable, "chunk_nft_origyn - could not find size zone - " # allocation.token_id  # " library_id - " # allocation.library_id # " chunk - " # debug_show(request.chunk), caller));};
                            case(?val) val;
                          };

                          let size = switch(sizeZone.get(requested_chunk)){
                            case(#Nat(val)) val;
                            case(_){
                              return #err(Types.errors(?state.canistergeekLogger,  #content_not_deserializable, "chunk_nft_origyn - improper size interface - " # allocation.token_id  # " library_id - " # allocation.library_id # " chunk - " # debug_show(request.chunk), caller));
                            };
                          };

                          let result = NFTUtils.getMemoryBySize(size, state.btreemap).get(wval);
                          switch (result) {
                              case null {
                                  D.print("Metadata option #Nat32 could not find a stablebtree key");
                              };
                              case (?val) {
                                  // D.print(debug_show(Blob.fromArray(val)));
                                  // return Blob.fromArray(val)
                                  return #ok(#chunk({ content = Blob.fromArray(val); total_chunks = SB.size(zone); current_chunk = request.chunk; storage_allocation = Types.allocation_record_stabalize(allocation) }));
                              };
                          };
                          */
                      };
                      case(_){
                        return #err(Types.errors(?state.canistergeekLogger,  #content_not_deserializable, "chunk_nft_origyn - chunk did not deserialize: token_id - " # allocation.token_id  # " library_id - " # allocation.library_id # " chunk - " # debug_show(request.chunk), caller));
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
    return #err(Types.errors(?state.canistergeekLogger,  #nyi, "chunk_nft_origyn - nyi", caller));
  };

  //updates collection data
  /**
  * Updates collection data
  * @param {Types.State} state - The state of the collection
  * @param {Types.ManageCollectionCommand} request - The collection data to be updated
  * @param {Principal} caller - The principal of the caller
  * @returns {Types.OrigynBoolResult} - A Result object containing a boolean indicating the success or failure of the update and an OrigynError in case of failure
  */
  public func collection_update_nft_origyn(state : Types.State, request: Types.ManageCollectionCommand, caller : Principal) : Types.OrigynBoolResult{
    
    if(NFTUtils.is_owner_network(state,caller) == false){return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "collection_update_origyn - not a canister owner or network", ?caller))};
    
    
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

        debug if(debug_channel.update_metadata) D.print("updating metadata" # debug_show(key, val, immutable));

        if( key == "id"
          or key == "library"
          or key == "__system"
          or key == "__apps"
          or key == "owner"){
            return #err(Types.errors(?state.canistergeekLogger,  #malformed_metadata, "collection_update_origyn - bad key " # key, ?caller));
          };



        let current_metadata = switch(Map.get(state.state.nft_metadata, Map.thash, "")){
            case(null){
              #Class([]);
            };
            case(?val){
              val;
            };
        };

        debug if(debug_channel.update_metadata) D.print("current meta" # debug_show(current_metadata));

        let clean_val = switch(val){
          case(null){
            #Option(null);
              };
          case(?val){
            val;
            };
        };

          
        let insert_result = 
          if(immutable == true){
            Properties.updatePropertiesShared(Conversions.candySharedToProperties(current_metadata), [
              {
                name = key;
                mode = #Lock(clean_val);
              }
            ]);
          } else {
            Properties.updatePropertiesShared(Conversions.candySharedToProperties(current_metadata), [
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
            return #err(Types.errors(?state.canistergeekLogger,  #property_not_found, "collection_update_origyn - bad update " # key # " " #debug_show(err), ?caller));
        
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


      case(#UpdateAnnounceCanister(data)){
        
        state.state.collection_data.announce_canister := data;

        let droute_client = Droute.new(?{
          mainId = data;
          publishersIndexId= null;
          subscribersIndexId= null;
        });
        return #ok(true);
      };
    
    };
    return #ok(true);
  };


  /**
  * Converts a ledger of transaction records to an array of CandyShareds
  * @param {SB.StableBuffer<MigrationTypes.Current.TransactionRecord>} ledger - The ledger to convert
  * @param {Nat} page - The page number of results to return
  * @param {Nat} size - The number of results to return per page
  * @returns {[CandyTypes.CandyShared]} - An array of CandyShareds
  */
  public func ledger_to_candy(ledger : SB.StableBuffer<MigrationTypes.Current.TransactionRecord>, page: Nat, size: Nat) : [CandyTypes.CandyShared]{

    var tracker = 0;

    let results  = Buffer.Buffer<CandyTypes.CandyShared>(1);

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
                    case(null){#Option(null)};
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
                    case(null){#Option(null)};
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
                  {name="receiver"; value=account_to_candy(val.receiver); immutable = true;},
                  {name="tag"; value=#Text(val.tag); immutable = true;},
                  
                  {name="token"; value=token_spec_to_candy(val.token); immutable = true;},
                
                  { name="sale_id"; value=switch(val.sale_id){
                    case(null){#Option(null)};
                    case(?val){#Text(val)};
                    
                    };  immutable = true;},
                  {name="amount"; value=#Nat(val.amount); immutable = true;},
                  
                  {name="extensible"; value=val.extensible; immutable = true;},
              ])
            };
            case(#sale_opened(val)){
              #Class([
                  {name="type"; value=#Text("sale_opened"); immutable = true;},
                  {name="pricing"; value=pricing_shared_to_candy(val.pricing); immutable = true;},

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
                {name="managers"; value=#Array( Array.map<Principal, CandyTypes.CandyShared>(val.managers, func(x:Principal){#Principal(x)})); immutable=true;},
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
            case(#data(data)){
              #Text("data");
            };
            case(#burn(data)){
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
