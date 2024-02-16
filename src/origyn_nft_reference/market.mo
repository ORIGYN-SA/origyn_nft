import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Deque "mo:base/Deque";
import Error "mo:base/Error";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";

import AccountIdentifier "mo:principalmo/AccountIdentifier";

import Map "mo:map/Map";
import Set "mo:map/Set";
import MapUtil "mo:map/utils";

import Star "mo:star/star";

import SHA256 "mo:crypto/SHA/SHA256";
import Ledger_Interface "ledger_interface";
import Metadata "metadata";
import MigrationTypes "./migrations/types";
import Migrations "migrations/types";
import Mint "mint";
import KYC "kyc";
import NFTUtils "utils";
import Types "types";


module {

  let debug_channel = {
      verify_escrow = true;
      verify_sale = false;
      ensure = false;
      invoice = false;
      end_sale = false;
      market = false;
      royalties = true;
      offers = false;
      escrow = true;
      withdraw_escrow = true;
      withdraw_sale = false;
      withdraw_reject = false;
      withdraw_deposit = false;
      notifications = true;
      dutch = false;
      bid = true;
      kyc = false;
  };

  let CandyTypes = MigrationTypes.Current.CandyTypes;
  let Conversions = MigrationTypes.Current.Conversions;
  let Properties = MigrationTypes.Current.Properties;
  let Workspace = MigrationTypes.Current.Workspace;


  let account_handler = MigrationTypes.Current.account_handler;
  let token_handler = MigrationTypes.Current.token_handler;

  type StateAccess = Types.State;

  let SB = MigrationTypes.Current.SB;

  let { ihash; nhash; thash; phash; calcHash } = Map;

  // Searches the escrow reciepts to find if the buyer/seller/token_id tuple has a balance on file
  /**
  * Searches the escrow receipts to find if the buyer/seller/token_id tuple has a balance on file.
  * @param {StateAccess} state - The state access object.
  * @param {Types.Account} buyer - The buyer's account.
  * @param {Types.Account} seller - The seller's account.
  * @param {Text} token_id - The token ID.
  * @returns {Result.Result<MigrationTypes.Current.EscrowLedgerTrie, Types.OrigynError>} - Either the escrow ledger trie or an error.
  */
  public func find_escrow_reciept(
    state: StateAccess,
    buyer : Types.Account,
    seller: Types.Account,
    token_id: Text) : Result.Result<
        MigrationTypes.Current.EscrowLedgerTrie
    , Types.OrigynError> {

    //find buyer's escrows
    let ?to_list = Map.get(state.state.escrow_balances, account_handler, buyer) else {
        debug if(debug_channel.verify_escrow) D.print("didnt find asset");
        return #err(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "find_escrow_reciept - escrow buyer not found ", null));
      };

    debug if(debug_channel.verify_escrow) D.print("to_list is " # debug_show(Map.size(to_list)));
            //find sellers deposits
    let ?token_list = Map.get(to_list, account_handler, seller) else {
        debug if(debug_channel.verify_escrow) D.print("no escrow seller");
        return #err(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "find_escrow_reciept - escrow seller not found ", null));
    };
    
    debug if(debug_channel.verify_escrow) D.print("looking for to list");
    //find tokens deposited for both "" and provided token_id
    let asset_list = switch(Map.get(token_list, Map.thash, token_id), Map.get(token_list, Map.thash, "")){
      case(null, null) return #err(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "find_escrow_reciept - escrow token_id not found ", null));
      case(null, ?generalList) return #err(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "find_escrow_reciept - escrow token_id found for general item but token_id is specific ", null));
      case(?asset_list, _ ) return #ok(asset_list);
    };
  };

  public func find_escrow_asset_map(
    state: StateAccess,
    escrow : Types.EscrowReceipt) : {
      to_list : ?MigrationTypes.Current.EscrowSellerTrie;
      token_list : ?MigrationTypes.Current.EscrowTokenIDTrie;
      asset_list : ?MigrationTypes.Current.EscrowLedgerTrie;
      balance : ?MigrationTypes.Current.EscrowRecord;

    } {

      let ?to_list = Map.get(state.state.escrow_balances, account_handler, escrow.buyer) else {
        debug if(debug_channel.verify_escrow) D.print("didnt find asset");
        return {
          to_list = null;
          token_list = null;
          asset_list = null;
          balance = null;
        };
      };

      let ?token_list = Map.get(to_list, account_handler, escrow.seller) else {
        debug if(debug_channel.verify_escrow) D.print("no escrow seller");
        return return {
          to_list = ?to_list;
          token_list = null;
          asset_list = null;
          balance = null;
        };
      };

      let asset_list = switch(Map.get(token_list, Map.thash, escrow.token_id), Map.get(token_list, Map.thash, "")){
        case(null, null) return {
          to_list = ?to_list;
          token_list = ?token_list;
          asset_list = null;
          balance = null;
        };
        case(null, ?generalList) return {
          to_list = ?to_list;
          token_list = ?token_list;
          asset_list = null;
          balance = null;
        };
        case(?asset_list, _ ) asset_list;
      };

      let ?balance = Map.get(asset_list, token_handler, escrow.token) else return {
        to_list = ?to_list;
        token_list = ?token_list;
        asset_list = ?asset_list;
        balance = null;
      };

      return {
        to_list = ?to_list;
        token_list = ?token_list;
        asset_list = ?asset_list;
        balance = ?balance;
      };


    };

  //verifies that an escrow reciept exists in this NFT
  /**
  * Verifies an escrow receipt to determine whether a buyer/seller/token_id tuple has a balance on file.
  * @param {StateAccess} state - The state access object.
  * @param {Types.EscrowReceipt} escrow - The escrow receipt to verify.
  * @param {?Types.Account} owner - The owner of the asset.
  * @param {?Text} sale_id - The sale id.
  * @returns {Result.Result<MigrationTypes.Current.VerifiedReciept, Types.OrigynError>} Returns a Result object that contains a MigrationTypes.Current.VerifiedReciept object if successful, otherwise it contains a Types.OrigynError object.
  */
  public func verify_escrow_receipt(
    state: StateAccess,
    escrow : Types.EscrowReceipt, 
    owner: ?Types.Account, 
    sale_id: ?Text) : Result.Result<MigrationTypes.Current.VerifiedReciept, Types.OrigynError> {


    //only the owner can sell it
    debug if(debug_channel.verify_escrow) D.print("found to list" # debug_show(owner) # debug_show(escrow.seller));
    
    switch(owner){
      case(null){};
      case(?owner){
        if(Types.account_eq(owner, escrow.seller) == false) return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "verify_escrow_receipt - escrow seller is not the owner  " # debug_show(owner) # " " # debug_show(escrow.seller), null));
      };
    };

    let search = find_escrow_asset_map(state, escrow);

    let ?to_list = search.to_list else {
        debug if(debug_channel.verify_escrow) D.print("didnt find asset");
        return #err(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "verify_escrow_receipt - escrow buyer not found " # debug_show(escrow.buyer), null));
    };

    debug if(debug_channel.verify_escrow) D.print("to_list is " # debug_show(Map.size(to_list)));

    let ?token_list = search.token_list else {
        debug if(debug_channel.verify_escrow) D.print("no escrow seller");

        return #err(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "verify_escrow_receipt - escrow seller not found  " # debug_show(escrow.seller), null));
    };

    debug if(debug_channel.verify_escrow) D.print("looking for to list");
    let ?asset_list = search.asset_list else return #err(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "verify_escrow_receipt - escrow token_id not found  " # debug_show(escrow.token_id), null));
            
    let ?balance = search.balance else return #err(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "verify_escrow_receipt - escrow token spec not found ", null));

    let found_asset = ?{token_spec = escrow.token; escrow = balance};

    debug if(debug_channel.verify_escrow) D.print("Found an asset, checking fee");
    debug if(debug_channel.verify_escrow) D.print(debug_show(found_asset));
    debug if(debug_channel.verify_escrow) D.print(debug_show(escrow.amount));

    //check sale id
    switch(sale_id, balance.sale_id){
      case(null, null){};
      case(?desired_sale_id, null) return #err(Types.errors(?state.canistergeekLogger,  #sale_id_does_not_match, "verify_escrow_receipt - escrow sale_id does not match  " #   debug_show(sale_id) # debug_show(balance.sale_id), null));
      case(null, ?on_file_saleID){
        //null is passed in as a sale id if we want to do sale id verification elsewhere
        //return #err(Types.errors(?state.canistergeekLogger,  #sale_id_does_not_match, "verify_escrow_receipt - escrow sale_id does not match ", null));
      };
      case(?desired_sale_id, ?on_file_saleID){
        if(desired_sale_id != on_file_saleID){
          return #err(Types.errors(?state.canistergeekLogger,  #sale_id_does_not_match, "verify_escrow_receipt - escrow sale_id does not match  " # debug_show(on_file_saleID)  # debug_show(desired_sale_id), null));
        };
      };
    }; 

    if(balance.amount < escrow.amount) return #err(Types.errors(?state.canistergeekLogger,  #withdraw_too_large, "verify_escrow_receipt - escrow not large enough  " # debug_show(balance.amount) # " " # debug_show(escrow.amount), null));

    switch(found_asset, ?asset_list){
      case(?found_asset, ?asset_list){
        return #ok({
          found_asset = found_asset;
          found_asset_list = asset_list;
        });
      };
      case(_) return #err(Types.errors(?state.canistergeekLogger,  #nyi, "verify_escrow_receipt - should be unreachable ", null));
    };
  };

  //verifies that a revenue reciept is in the NFT Canister
  /**
  * Verifies that a revenue receipt is in the NFT Canister.
  * @param {StateAccess} state - State access object.
  * @param {Types.EscrowReceipt} escrow - The revenue receipt to verify.
  * @returns {Result.Result<MigrationTypes.Current.VerifiedReceipt, Types.OrigynError>} - A Result type containing either a verified receipt or an error.
  */
  public func verify_sales_reciept(
    state: StateAccess,
    escrow : Types.EscrowReceipt) : Result.Result<MigrationTypes.Current.VerifiedReciept, Types.OrigynError> {

    let ?to_list = Map.get<Types.Account, MigrationTypes.Current.SalesBuyerTrie>(state.state.sales_balances, account_handler, escrow.seller) else {
        debug if(debug_channel.verify_sale) D.print("sale seller not found");
        return #err(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "verify_sales_reciept - escrow seller not found ", null));
      };

            //only the owner can sell it

    let ?token_list = Map.get(to_list, account_handler, escrow.buyer) else {
        debug if(debug_channel.verify_sale) D.print("sale byer not found");
        return #err(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "verify_sales_reciept - escrow buyer not found ", null));
    };

    let ?asset_list = Map.get(token_list, Map.thash, escrow.token_id) else {
        debug if(debug_channel.verify_sale) D.print("sale token id not found");
        return #err(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "verify_sales_reciept - escrow token_id not found ", null));
      };
            
    let ?balance = Map.get(asset_list, token_handler,escrow.token) else {
        debug if(debug_channel.verify_sale) D.print("sale token not found");
        return #err(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "verify_sales_reciept - escrow token spec not found ", null));};
      

    let found_asset = ?{token_spec = escrow.token; escrow = balance};
    debug if(debug_channel.verify_sale) D.print("issue with balances");
    debug if(debug_channel.verify_sale) D.print(debug_show(balance));
    debug if(debug_channel.verify_sale) D.print(debug_show(escrow));
    
    if(balance.amount < escrow.amount) return #err(Types.errors(?state.canistergeekLogger,  #withdraw_too_large, "verify_sales_reciept - escrow not large enough", null));

    switch(found_asset, ?asset_list){
      case(?found_asset, ?asset_list){
        return #ok({
          found_asset = found_asset;
          found_asset_list = asset_list;
        });
      };
      case(_)return #err(Types.errors(?state.canistergeekLogger,  #nyi, "verify_sales_reciept - should be unreachable ", null));
    };
  };

  //makes sure that there is not an ongoing sale for an item
  /**
  * Checks if a token is currently on sale.
  * @param {StateAccess} state - State access object.
  * @param {CandyTypes.CandyShared} metadata - The metadata for the token.
  * @param {Principal} caller - The caller of the function.
  * @returns {Types.OrigynBoolResult} - A Result type containing either a boolean indicating whether the token is on sale or an error.
  */
  public func is_token_on_sale(
    state: StateAccess,
    metadata: CandyTypes.CandyShared, 
    caller: Principal) : Result.Result<Bool,Types.OrigynError>{

      debug if(debug_channel.ensure) D.print("in ensure");
    let #ok(token_id) =Metadata.get_nft_id(metadata) else  return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "is_token_on_sale - could not find token_id ", ?caller));

    //look for an existing sale
    debug if(debug_channel.verify_sale) D.print("geting sale");
    
    let sale_id = switch(Metadata.get_current_sale_id(metadata)){
        case(#Option(null)) return #ok(false);
        case(#Text(sale_id)) sale_id;
        case(_) return #err(Types.errors(?state.canistergeekLogger,  #nyi, "is_token_on_sale - imporoper candy type ", ?caller));
    };
                        
    debug if(debug_channel.verify_sale) D.print("found sale" # sale_id);
            
    let ?current_sale = Map.get(state.state.nft_sales, Map.thash, sale_id) else return #err(Types.errors(?state.canistergeekLogger,  #sale_not_found, "is_token_on_sale - could not find sale for token " # token_id # " " # sale_id, ?caller));

    debug if(debug_channel.verify_sale) D.print("checking state");
    let current_sale_state = switch(NFTUtils.get_auction_state_from_status(current_sale)){
        case(#ok(val)) val;
        case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  err.error, "is_token_on_sale - find sale state " # err.flag_point, ?caller));
    };
    
    debug if(debug_channel.verify_sale) D.print("switching config");
    switch(current_sale_state.config){
      case(#auction(config)) {debug if(debug_channel.verify_sale) D.print("current config" # debug_show(config));};
      case(#ask(config)) {debug if(debug_channel.verify_sale) D.print("current config" # debug_show(config));};
      case(_)return #err(Types.errors(?state.canistergeekLogger,  #nyi, "is_token_on_sale - sales type check not implemented", ?caller));
    };

    switch(current_sale_state.status){
      case(#closed) return #ok(false);
      case(#open) return #ok(true);
      case(_) return #ok(true);
    };
  };

  //opens a sale if it is past the date
  /**
  * Opens a sale for an NFT if it is past the date.
  * @param {StateAccess} state - The state of the contract.
  * @param {Text} token_id - The ID of the NFT.
  * @param {Principal} caller - The caller principal.
  * @returns {Result.Result<Types.ManageSaleResponse,Types.OrigynError>} - A `Result` object that either contains a `Types.ManageSaleResponse` object or a `Types.OrigynError` object.
  */
  public func open_sale_nft_origyn(state: StateAccess, token_id: Text, caller: Principal) : Result.Result<Types.ManageSaleResponse,Types.OrigynError> {
    //D.print("in open_sale_nft_origyn");
    let metadata = switch(Metadata.get_metadata_for_token(state,token_id, caller, ?state.canister(), state.state.collection_data.owner)){
       case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "open_sale_nft_origyn " # err.flag_point, ?caller));
       case(#ok(val)) val;
    };

    //look for an existing sale
    let current_sale = switch(Metadata.get_current_sale_id(metadata)){
      case(#Option(null)) return #err(Types.errors(?state.canistergeekLogger,  #sale_not_found, "open_sale_nft_origyn - could not find sale for token " # token_id, ?caller));
      case(#Text(val)){
        switch(Map.get(state.state.nft_sales, Map.thash,val)){
          case(?status){
            status;
          };
          case(null) return #err(Types.errors(?state.canistergeekLogger,  #sale_not_found, "open_sale_nft_origyn - could not find sale for token " # token_id, ?caller));
        };
      };
      case(_) return #err(Types.errors(?state.canistergeekLogger,  #sale_not_found, "open_sale_nft_origyn - could not find sale for token " # token_id, ?caller));
    };

    let current_sale_state = switch(NFTUtils.get_auction_state_from_status(current_sale)){
      case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  err.error, "open_sale_nft_origyn - find state " # err.flag_point, ?caller));
      case(#ok(val)) val;
    };


    switch(current_sale_state.status){
      case(#closed) return #err(Types.errors(?state.canistergeekLogger,  #auction_ended, "open_sale_nft_origyn - auction already closed ", ?caller));
      case(#not_started){
        if(state.get_time() >= current_sale_state.start_date and state.get_time() < current_sale_state.end_date){
          current_sale_state.status := #open;
          return(#ok(#open_sale(true)));
        } else return #err(Types.errors(?state.canistergeekLogger,  #auction_not_started, "open_sale_nft_origyn - auction does not need to be opened " # debug_show(current_sale_state.start_date), ?caller));
      };
      case(#open)  return #err(Types.errors(?state.canistergeekLogger,  #auction_not_started, "open_sale_nft_origyn - auction already open", ?caller));
    };
     
    
  };

  

  //reports information about a sale
  /**
  * Reports information about a sale.
  * @param {StateAccess} state - The state of the contract.
  * @param {Text} sale_id - The ID of the sale.
  * @param {Principal} caller - The caller principal.
  * @returns {Result.Result<Types.SaleInfoResponse,Types.OrigynError>} - A `Result` object that either contains a `Types.SaleInfoResponse` object or a `Types.OrigynError` object.
  */
  public func sale_status_nft_origyn(state: StateAccess, sale_id: Text, caller: Principal) : Result.Result<Types.SaleInfoResponse,Types.OrigynError> {

    //look for an existing sale
    let current_sale =  switch(Map.get(state.state.nft_sales, Map.thash,sale_id)){
      case(?status) status;
      case(null) return #ok(#status(null));
    };

    let result = #ok(#status(?{
      current_sale with
      sale_type = switch(current_sale.sale_type){
        case(#auction(val)){
            #auction(Types.AuctionState_stabalize_for_xfer(
              calc_dutch_price(state, val)));
        };
        /* case(_){
            return #err(Types.errors(?state.canistergeekLogger,  #sale_not_found, "sale_status_nft_origyn not an auction ", ?caller));
        }; */
      };
    }));

    return result;
  };

  //returns active sales on a canister
  /**
  * Returns active sales on a canister
  * 
  * @param {StateAccess} state - The state of the canister
  * @param {Array.<number>} pages - Optional tuple of start page and page size.
  * @param {Principal} caller - The principal of the caller.
  * @returns {Result.Result.<Types.SaleInfoResponse,Types.OrigynError>} - A `Result` object that either contains the sale information as a `Types.SaleInfoResponse` object or an error as a `Types.OrigynError` object.
  */
  public func active_sales_nft_origyn(state: StateAccess, pages: ?(Nat, Nat), caller: Principal) : Result.Result<Types.SaleInfoResponse,Types.OrigynError> {
      
    var tracker = 0 : Nat;

    let (min, max) = switch(pages){
      case(null){
        (0, Map.size(state.state.nft_metadata));
      };
      case(?val){
        (val.0, 
          if(val.0 + val.1 >= Map.size(state.state.nft_metadata)){
            Map.size(state.state.nft_metadata)
          } else {
            val.0 + val.1;
          }
        );
      };
    };

    let results = Buffer.Buffer<(Text, ?Types.SaleStatusShared)>(max - min);

    var foundTotal : Nat = 0;
    var eof : Bool = false;
    let totalSize = Map.size(state.state.nft_metadata);

    label search for(this_token in Map.entries(state.state.nft_metadata)){
      let metadata = switch(Metadata.get_metadata_for_token(state, this_token.0, caller, null, state.state.collection_data.owner)){
        case(#err(err)){
          results.add("unminted", null);
          tracker += 1;
          continue search;
        };
        case(#ok(val)) val;
      };

      //look for an existing sale
      let current_sale = switch(Metadata.get_current_sale_id(metadata)){
        case(#Option(null)){
          //results.add(this_token.0, null);
          tracker += 1;
          continue search;
        };
        case(#Text(val)){
          switch(Map.get(state.state.nft_sales, Map.thash,val)){
            case(?status) status;
            case(null){
              //results.add(this_token.0, null);
              tracker += 1;
              continue search;
            };
          };
        };
        case(_){
          //results.add(this_token.0, null);
          tracker += 1;
          continue search;
        };
      };

      let current_sale_state = switch(NFTUtils.get_auction_state_from_status(current_sale)){
        case(#ok(val)) val;
        case(#err(err)){
          //results.add(this_token.0, null);
          tracker += 1;
          continue search;
        };
      };

      switch(current_sale_state.config){
        case(#auction(config)){
          if(current_sale_state.status == #open or current_sale_state.status == #not_started){
            
            if(tracker > max){}
            else if( tracker >= min ){

              results.add(this_token.0, ?{
                current_sale with
                sale_type = switch(current_sale.sale_type){
                  case(#auction(val)){
                    #auction(Types.AuctionState_stabalize_for_xfer(val))
                  };
                };
              });

              if(tracker + 1 == totalSize){
                eof := true;
              };
            } else {};

            foundTotal += 1;
          };
        };

        case(#ask(config)){
          
          if(current_sale_state.status == #open or current_sale_state.status == #not_started){
            
            if(tracker > max){}
            else if( tracker >= min ){

              results.add(this_token.0, ?{
                current_sale with
                sale_type = switch(current_sale.sale_type){
                  case(#auction(val)){
                    #auction(Types.AuctionState_stabalize_for_xfer(
                      calc_dutch_price(state, val)
                    ));
                  };
                };
              });

              if(tracker + 1 == totalSize){
                eof := true;
              };
            } else {};

            foundTotal += 1;
          };
        };
        case(_){
            //results.add(this_token.0, null);
            tracker += 1;
            continue search;
        };
      };

      tracker += 1;
    };

    return #ok(#active({
        records = Buffer.toArray(results);
        eof = eof;
        count = foundTotal;
    }));
  };


    //returns a history of sales
    /**
    * Returns a history of sales.
    * 
    * @param {StateAccess} state - StateAccess object for accessing the canister's state.
    * @param {?(Nat, Nat)} pages - Optional tuple of pagination information in the form (start index, page size).
    * @param {Principal} caller - Principal of the caller making the request.
    * @returns {Result.Result<Types.SaleInfoResponse,Types.OrigynError>} - A result containing a history of sales.
    */
    public func history_sales_nft_origyn(state: StateAccess, pages: ?(Nat, Nat), caller: Principal) : Result.Result<Types.SaleInfoResponse,Types.OrigynError> {
        
        var tracker = 0 : Nat;
        let (min, max, total, eof) = switch(pages){
          case(null){
            (0, Map.size(state.state.nft_sales), Map.size(state.state.nft_sales), true);
          };
          case(?val){
            (val.0, 
              if(val.0 + val.1 >= Map.size(state.state.nft_sales)){
                Map.size(state.state.nft_sales)
              } else {
                val.0 + val.1;
              }, 
              Map.size(state.state.nft_sales),
              if(val.0 + val.1 >= Map.size(state.state.nft_sales)){
                true;
              } else {
                false;
              }, 
            );
          };
        };

        let results = Buffer.Buffer<?Types.SaleStatusShared>(max - min);

        label search for(thisSale in Map.entries(state.state.nft_sales)){
          if(tracker > max){break search;};
          if(tracker >= min){

            let current_sale_state = switch(NFTUtils.get_auction_state_from_status(thisSale.1)){
              case(#ok(val)){val};
              case(#err(err)){
                //results.add(null);
                tracker += 1;
                continue search;
              };
            };

            switch(current_sale_state.config){
              case(#auction(config)){

                results.add(?{
                  thisSale.1 with
                  sale_type = switch(thisSale.1.sale_type){
                      case(#auction(val)){
                          #auction(Types.AuctionState_stabalize_for_xfer(val))
                      };
                  };
                });
              };
              case(#ask(config)){
               

                results.add(?{
                  thisSale.1 with
                  sale_type = switch(thisSale.1.sale_type){
                      case(#auction(val)){
                          #auction(Types.AuctionState_stabalize_for_xfer(
                            calc_dutch_price(state, val)
                          ));
                      };
                  };
                });
              };
              case(_){
                  //nyi: handle other sales types
                  //results.add( null);
                  tracker += 1;
                  continue search;
              };
            };
          };
          tracker += 1;
        };

        return #ok(#history({
          records = Buffer.toArray(results);
          eof = eof;
          count = total;
        }));
    };

    //returns an invoice or details of where a user can send their depoits on a standard ledger
    /**
    * Returns an invoice or details of where a user can send their deposits on a standard ledger.
    * 
    * @param {StateAccess} state - StateAccess object for accessing the canister's state.
    * @param {?Types.Account} request - Optional account information for the request.
    * @param {Principal} caller - Principal of the caller making the request.
    * @returns {Result.Result<Types.SaleInfoResponse,Types.OrigynError>} - A result containing the invoice or deposit information.
    */
    public func deposit_info_nft_origyn(state: StateAccess, request: ?Types.Account, caller: Principal) : Result.Result<Types.SaleInfoResponse,Types.OrigynError> {

      debug if(debug_channel.invoice) D.print("in deposit info nft origyn.");

      let account = switch(request){
        case(null) #principal(caller);
        case(?val) val;
      };

      debug if(debug_channel.invoice) D.print("getting info for " # debug_show(account));
      return #ok(#deposit_info(NFTUtils.get_deposit_info(account, state.canister())));
    };

    //returns an invoice or details of where a user can send their escrows on a standard ledger
    /**
    * Returns an invoice or details of where a user can send their escrow on a standard ledger.
    * 
    * @param {StateAccess} state - StateAccess object for accessing the canister's state.
    * @param {Types.EscrowRecord} request - Escrow Info to use to derive the account.
    * @param {Principal} caller - Principal of the caller making the request.
    * @returns {Result.Result<Types.SaleInfoResponse,Types.OrigynError>} - A result containing the invoice or deposit information.
    */
    public func escrow_info_nft_origyn(state: StateAccess, request: Types.EscrowReceipt, caller: Principal) : Result.Result<Types.SaleInfoResponse,Types.OrigynError> {

      debug if(debug_channel.invoice) D.print("in escrow info nft origyn.");


      debug if(debug_channel.invoice) D.print("getting info for " # debug_show(request));
      return #ok(#escrow_info(NFTUtils.get_escrow_account_info(request, state.canister())));
    };

  
    /**
    * returns an account that a seller can deposit tokens into for fees
    * 
    * @param {StateAccess} state - StateAccess object for accessing the canister's state.
    * @param {Types.Account} request - Account Info to use to derive the account.
    * @param {Principal} caller - Principal of the caller making the request.
    * @returns {Result.Result<Types.FeeDepositInfoResponse,Types.OrigynError>} - A result containing the deposit information.
    */
    public func fee_deposit_info_nft_origyn(state: StateAccess, request: ?Types.Account, caller: Principal) : Result.Result<Types.SaleInfoResponse,Types.OrigynError> {

      debug if(debug_channel.invoice) D.print("in fee deposit info nft origyn.");

      let account = switch(request){
        case(null) #principal(caller);
        case(?val) val;
      };

      debug if(debug_channel.invoice) D.print("getting info for " # debug_show(request));
      return #ok(#fee_deposit_info(NFTUtils.get_fee_deposit_account_info(account, state.canister())));
    };

    //ends a sale if it is past the date or a buy it now has occured
    public func end_sale_nft_origyn(state: StateAccess, token_id: Text, caller: Principal) : async* Star.Star<Types.ManageSaleResponse,Types.OrigynError> {
        debug if(debug_channel.end_sale) D.print("in end_sale_nft_origyn");

        var metadata = switch(Metadata.get_metadata_for_token(state,token_id, caller, ?state.canister(), state.state.collection_data.owner)){
          case(#err(err)){ return #err(#trappable(Types.errors(?state.canistergeekLogger,  #token_not_found, "end_sale_nft_origyn " # err.flag_point, ?caller)));
          };
          case(#ok(val)) val;
        };

        debug if(debug_channel.end_sale) D.print("have metadata");

        let owner = switch(Metadata.get_nft_owner(metadata)){
          case(#err(err)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  err.error, "end_sale_nft_origyn " # err.flag_point, ?caller)));
          case(#ok(val))val;
        };

        debug if(debug_channel.end_sale) D.print("have owner");

        //look for an existing sale
        let current_sale = switch(Metadata.get_current_sale_id(metadata)){
          case(#Option(null)) {
            debug if(debug_channel.end_sale) D.print("option null for sale id");
            return #err(#trappable(Types.errors(?state.canistergeekLogger,  #sale_not_found, "end_sale_nft_origyn - could not find sale for token " # token_id, ?caller)));
          };
          case(#Text(val)){
            debug if(debug_channel.end_sale) D.print("have text sale id" # val);
            switch(Map.get(state.state.nft_sales, Map.thash,val)){
              case(?status){
                status;
              };
              case(null) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #sale_not_found, "end_sale_nft_origyn - could not find sale for token " # token_id, ?caller)));
            };
          };
          case(_){
            debug if(debug_channel.end_sale) D.print("other type");
            return #err(#trappable(Types.errors(?state.canistergeekLogger,  #sale_not_found, "end_sale_nft_origyn - could not find sale for token " # token_id, ?caller)))
          };
        };

        
        let current_sale_state = switch(NFTUtils.get_auction_state_from_status(current_sale)){
          case(#ok(val)) val;
          case(#err(err)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  err.error, "end_sale_nft_origyn - find state " # err.flag_point, ?caller)));
        };


        //debug if(debug_channel.end_sale) D.print("current sale state " # debug_show(current_sale_state));

        let {buy_now_price; start_date; fee_accounts; fee_schema;} = switch(current_sale_state.config){
          case(#auction(config)){
            {
              buy_now_price = config.buy_now;
              start_date = config.start_date;
              fee_accounts = null;
              fee_schema = null;
            };
          };
          case(#ask(config)){
            let buy_now = switch(config){
              case(null) null;
              case(?config){
                switch(Map.get(config, MigrationTypes.Current.ask_feature_set_tool, #buy_now)){
                  case(?#buy_now(val)){
                    ?val;
                  };
                  case(_){null};
                };
              };
            };
            let dutch = switch(config){
              case(null) null;
              case(?config){
                switch(Map.get(config, MigrationTypes.Current.ask_feature_set_tool, #dutch)){
                  case(?#dutch(val)){
                    ?val;
                  };
                  case(_){null};
                };
              };
            };
            let fee_accounts = switch(config){
              case(null) null;
              case(?config){
                switch(Map.get(config, MigrationTypes.Current.ask_feature_set_tool, #fee_accounts)){
                  case(?#fee_accounts(val)){
                    ?val;
                  };
                  case(_){null};
                };
              };
            };
            let fee_schema = switch(config){
              case(null) null;
              case(?config){
                switch(Map.get(config, MigrationTypes.Current.ask_feature_set_tool, #fee_schema)){
                  case(?#fee_schema(val)){
                    ?val;
                  };
                  case(_){null};
                };
              };
            };
            let start_date = switch(config){
              case(null) null;
              case(?config){
                switch(Map.get(config, MigrationTypes.Current.ask_feature_set_tool, #start_date)){
                  case(?#buy_now(val)){
                    ?val;
                  };
                  case(_){null};
                };
              };
            };
            {buy_now_price = switch(buy_now, dutch){
              case(?buy_now, null){
                ?buy_now;
              };
              case(null, ?dutch){
                let current_state = calc_dutch_price(state, current_sale_state);
                ?current_state.min_next_bid;
              };
              case(_,_){
                null;
              }
            };
            start_date = start_date;
            fee_accounts = fee_accounts;
            fee_schema = fee_schema;
            };
          };
          case(_) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #sale_not_found, "end_sale_nft_origyn - not an auction type ", ?caller)));
        };

        let buy_now = switch(buy_now_price){
          case(null){false};
          case(?val){
            if(val <= current_sale_state.current_bid_amount){
              true;
            } else {
              false;
            };
          };
        };

        debug if(debug_channel.end_sale) D.print("past buy now " # debug_show(buy_now));


        debug if(debug_channel.end_sale) D.print("have buy now" # debug_show(buy_now, buy_now_price, current_sale_state.current_bid_amount));
        
        switch(current_sale_state.status){
          case(#closed){
            //we will close later after we try to refund a valid bid
            return #err(#trappable(Types.errors(?state.canistergeekLogger,  #auction_ended, "end_sale_nft_origyn - auction already closed ", ?caller)));
          };
          case(#not_started){
            debug if(debug_channel.end_sale) D.print("wasnt started");
    
            if(state.get_time() >= current_sale_state.start_date and state.get_time() < current_sale_state.end_date){
              current_sale_state.status := #open;
            };
          };
          case(_){};
        };

        debug if(debug_channel.end_sale) D.print("handled current stauts" # debug_show(buy_now, buy_now_price, current_sale_state.current_bid_amount));

        //make sure auction is still over
        if(state.get_time() < current_sale_state.end_date ){
           debug if(debug_channel.end_sale) D.print("current time is less tha end date" # debug_show(buy_now, buy_now_price, current_sale_state.end_date));
          if( buy_now == true and caller == state.canister()){
            //only the canister can end a buy now
          } else {

            if(Types.account_eq(#principal(caller), owner) == true and current_sale_state.current_escrow == null){
              //an owner can cancel an auction that has no bids yet.
              //useful for buy it now sales with a long out end date.

              debug if(debug_channel.end_sale) D.print("closing the sale via the owner" # debug_show(buy_now, buy_now_price, current_sale_state.end_date));


              current_sale_state.status := #closed; 

              switch(Metadata.add_transaction_record(state,{
                token_id = token_id;
                index = 0;
                txn_type = #sale_ended {
                    seller = owner;
                    buyer = owner;
                    token = current_sale_state.token;
                    sale_id = ?current_sale.sale_id;
                    amount = 0;
                    extensible = #Text("owner canceled");
                };
                timestamp = state.get_time();
              }, caller)){
                case(#ok(new_trx)) return #trappable(#end_sale(new_trx));
                case(#err(err)) return #err(#trappable(err));
              };
            };

            return #err(#trappable(Types.errors(?state.canistergeekLogger,  #sale_not_over, "end_sale_nft_origyn - auction still running ", ?caller)));
          };
        };

        //check reserve MKT0038
        let reserve = switch(current_sale_state.config){
          case(#auction(config)){
            config.reserve
          };
          case(#ask(?config)){
            switch(Map.get(config, MigrationTypes.Current.ask_feature_set_tool, #reserve)){
              case(?(#reserve(val))) ?val;
              case(_) null;
            };
          };
          case(_){
            null;
          };
        };

        debug if(debug_channel.end_sale) D.print("checking reserve" # debug_show(reserve)); 

        switch(reserve){
          case(?reserve){
            if(current_sale_state.current_bid_amount < reserve){
              //end sale but don't move NFT
              debug if(debug_channel.end_sale) D.print("ending the sale but not moving the nft" # debug_show(buy_now, buy_now_price, current_sale_state.end_date));
              current_sale_state.status := #closed; 
              
              switch(Metadata.add_transaction_record(state,{
                token_id = token_id;
                index = 0;
                txn_type = #sale_ended {
                  seller = owner;
                  buyer = owner;
                  token = current_sale_state.token;
                  sale_id = ?current_sale.sale_id;
                  amount = 0;
                  extensible = #Text("reserve not met");
                };
                timestamp = state.get_time();
              }, caller)){
                case(#ok(new_trx))  return #trappable(#end_sale(new_trx));
                case(#err(err)) return #err(#trappable(err));
              };
            };
          };
          case(null){};
        };

        debug if(debug_channel.end_sale) D.print("checking escrow" # debug_show(current_sale_state.current_escrow));

        switch(current_sale_state.current_escrow){
          case(null){
            //end sale but don't move NFT
            current_sale_state.status := #closed;

            switch(Metadata.add_transaction_record(state,{
              token_id = token_id;
              index = 0;
              txn_type = #sale_ended {
                seller = owner;
                buyer = owner;
                token = current_sale_state.token;
                sale_id = ?current_sale.sale_id;
                amount = 0;
                extensible = #Text("no bids");
              };
              timestamp = state.get_time();
            }, caller)){
              case(#ok(new_trx)) return #trappable(#end_sale(new_trx));
              case(#err(err)) return #err(#trappable(err));
            };
              
          };
          case(?winning_escrow){
              debug if(debug_channel.end_sale) D.print("verifying escrow");
              debug if(debug_channel.end_sale) D.print(debug_show(winning_escrow));
              let verified = switch(verify_escrow_receipt(state, winning_escrow, ?owner, ?current_sale.sale_id)){
                case(#err(err)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  err.error, "end_sale_nft_origyn verifying escrow " # err.flag_point, ?caller)));
                case(#ok(res)) res;
              };

              debug if(debug_channel.end_sale) D.print("verified is  " # debug_show(verified.found_asset));
              //reentrancy risk so remove the escrow
              debug if(debug_channel.end_sale) D.print("putting escrow balance");
              debug if(debug_channel.end_sale) D.print(debug_show(winning_escrow));

              if(verified.found_asset.escrow.amount < winning_escrow.amount){
                  return #err(#trappable(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "end_sale_nft_origyn - error finding escrow, now less than bid " # debug_show(winning_escrow), ?caller)));
              } else {
                  if(verified.found_asset.escrow.amount > winning_escrow.amount ){
                      let total_amount = Nat.sub(verified.found_asset.escrow.amount, winning_escrow.amount);
                      Map.set(verified.found_asset_list, token_handler, verified.found_asset.token_spec, {
                          amount = total_amount;
                          seller = verified.found_asset.escrow.seller;
                          balances = null;
                          buyer = verified.found_asset.escrow.buyer;
                          token_id = verified.found_asset.escrow.token_id;
                          token = verified.found_asset.escrow.token;
                          sale_id = verified.found_asset.escrow.sale_id; //should be null
                          lock_to_date = verified.found_asset.escrow.lock_to_date;
                          account_hash = verified.found_asset.escrow.account_hash;
                          });
                  } else {
                      Map.delete(verified.found_asset_list, token_handler,verified.found_asset.token_spec);
                  };
              };


              //reentancy risk so change the owner to inflight
              metadata := switch(Metadata.set_nft_owner(state, token_id, #extensible(#Text("trx in flight")), caller)){
                case(#err(err)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller)));
                case(#ok(new_metadata)) new_metadata;
              };

              //move the payment to the sale revenue account
              //nyi: use transfer batch to split across royalties

              let (trx_id : Types.TransactionID, account_hash : ?Blob, fee : ?Nat) = switch(winning_escrow.token){
                case(#ic(token)){
                  switch(token.standard){
                    case(#Ledger or #ICRC1){
                      debug if(debug_channel.end_sale) D.print("found ledger");
                      let checker = Ledger_Interface.Ledger_Interface();
                                                              try {
                      switch(await* checker.transfer_sale(state.canister(), winning_escrow, token_id, caller)){
                          case(#ok(val)){
                              (val.0,?val.1.account.sub_account, token.fee);
                          };
                          case(#err(err)){
                              //put the escrow back because the payment failed
                              switch(verify_escrow_receipt(state, winning_escrow, ?owner, null)){
                                case(#ok(reverify)){
                                    let target_escrow = {
                                        account_hash = reverify.found_asset.escrow.account_hash;
                                        amount = Nat.add(reverify.found_asset.escrow.amount, winning_escrow.amount);
                                        buyer = reverify.found_asset.escrow.buyer;
                                        seller = reverify.found_asset.escrow.seller;
                                        token_id = reverify.found_asset.escrow.token_id;
                                        token = reverify.found_asset.escrow.token;
                                        sale_id = reverify.found_asset.escrow.sale_id;
                                        lock_to_date = reverify.found_asset.escrow.lock_to_date;
                                    };

                                    
                                    Map.set(reverify.found_asset_list, token_handler, verified.found_asset.token_spec, target_escrow);
                                    

                                };
                                case(#err(err)){
                                    let target_escrow = {
                                        account_hash = verified.found_asset.escrow.account_hash;
                                        amount =  winning_escrow.amount;
                                        buyer = verified.found_asset.escrow.buyer;
                                        seller = verified.found_asset.escrow.seller;
                                        token_id = verified.found_asset.escrow.token_id;
                                        token = verified.found_asset.escrow.token;
                                        sale_id = verified.found_asset.escrow.sale_id;
                                        lock_to_date = verified.found_asset.escrow.lock_to_date;
                                    };
                                    Map.set(verified.found_asset_list, token_handler, verified.found_asset.token_spec, target_escrow);
                                }
                            };

                            //put the owner back if the transaction fails
                            metadata := switch(Metadata.set_nft_owner(state, token_id, owner, caller)){
                              case(#err(err)) return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller)));
                              case(#ok(new_metadata)) new_metadata;
                            };

                            return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "end_sale_nft_origyn " # err.flag_point, ?caller)));
                          };
                      };
                    } catch(e){
                      //put the escrow back because the payment failed
                        switch(verify_escrow_receipt(state, winning_escrow, ?owner, null)){
                          case(#ok(reverify)){
                              let target_escrow = {
                                  account_hash = reverify.found_asset.escrow.account_hash;
                                  amount = Nat.add(reverify.found_asset.escrow.amount, winning_escrow.amount);
                                  buyer = reverify.found_asset.escrow.buyer;
                                  seller = reverify.found_asset.escrow.seller;
                                  token_id = reverify.found_asset.escrow.token_id;
                                  token = reverify.found_asset.escrow.token;
                                  sale_id = reverify.found_asset.escrow.sale_id;
                                  lock_to_date = reverify.found_asset.escrow.lock_to_date;
                              };

                              
                              Map.set(reverify.found_asset_list, token_handler, verified.found_asset.token_spec, target_escrow);
                              

                          };
                          case(#err(err)){
                              let target_escrow = {
                                  account_hash = verified.found_asset.escrow.account_hash;
                                  amount =  winning_escrow.amount;
                                  buyer = verified.found_asset.escrow.buyer;
                                  seller = verified.found_asset.escrow.seller;
                                  token_id = verified.found_asset.escrow.token_id;
                                  token = verified.found_asset.escrow.token;
                                  sale_id = verified.found_asset.escrow.sale_id;
                                  lock_to_date = verified.found_asset.escrow.lock_to_date;
                              };
                              Map.set(verified.found_asset_list, token_handler, verified.found_asset.token_spec, target_escrow);
                          }
                      };

                      //put the owner back if the transaction fails
                      metadata := switch(Metadata.set_nft_owner(state, token_id, owner, caller)){
                        case(#err(err)) return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller)));
                        case(#ok(new_metadata)) new_metadata;
                      };
                    

                      return #err(#awaited(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "end_sale_nft_origyn catch branch" # Error.message(e), ?caller)));
                    };


                    };
                    case(_)  return #err(#awaited(Types.errors(?state.canistergeekLogger,  #nyi, "end_sale_nft_origyn - non ic type nyi - " # debug_show(token), ?caller)));
                  };
                };
                case(#extensible(val)) return #err(#awaited(Types.errors(?state.canistergeekLogger,  #nyi, "end_sale_nft_origyn - extensible token nyi - " # debug_show(val), ?caller)));
              };

              //change owner
              var new_metadata : CandyTypes.CandyShared = switch(Metadata.set_nft_owner(state, token_id, winning_escrow.buyer, caller)){
                case(#ok(new_metadata)){new_metadata};
                case(#err(err)) {
                                                //changing owner failed but the tokens are already gone....what to do...leave up to governance
                              return #err(#awaited(Types.errors(?state.canistergeekLogger,  #update_class_error, "end_sale_nft_origyn - error setting owner " # token_id, ?caller)));

                };
              };

              debug if(debug_channel.end_sale) D.print("updating metadata");

              //clear shared wallets
              new_metadata := Metadata.set_system_var(new_metadata, Types.metadata.__system_wallet_shares, #Option(null));
              Map.set(state.state.nft_metadata, Map.thash, token_id, new_metadata);

              current_sale_state.end_date := state.get_time();
              current_sale_state.status := #closed;
              current_sale_state.winner := ?winning_escrow.buyer;


              debug if(debug_channel.kyc) D.print("about to notify of kyc");
              await* KYC.notify_kyc(state, verified.found_asset.escrow, caller);
              debug if(debug_channel.end_sale) D.print("kyc notify done");

              //log royalties
              //currently for auctions there are only secondary royalties

              let royalty_fee_schema = switch (fee_schema) {
                case (?val) {
                  if (val == Types.metadata.__system_primary_royalty or val == Types.metadata.__system_secondary_royalty or val == Types.metadata.__system_ogy_fixed_royalty) {
                    val;
                  } else {
                    Types.metadata.__system_secondary_royalty;
                  };
                };
                case (null) {
                  Types.metadata.__system_secondary_royalty;
                };
              };

              let royalty = switch(Properties.getClassPropertyShared(metadata, Types.metadata.__system)){
                case(null){[];};
                case(?val){
                  royalty_to_array(val.value, royalty_fee_schema);
                };
              };

              debug if(debug_channel.market) D.print("royalty is " # debug_show(royalty));
              
              //let royaltyList = Buffer.Buffer<(Types.Account, Nat)>(royalty.size() + 1);
              let fee_ = Option.get(fee, 0);
              if(winning_escrow.amount > fee_){
                //if the fee is bigger than the amount we aren't going to pay anything
                //this should really be prevented elsewhere
                let total = Nat.sub(winning_escrow.amount, fee_);
                var remaining = Nat.sub(winning_escrow.amount, fee_);

                let royalty_result =  _process_royalties(state, {
                  var remaining = remaining;
                  total = total;
                  fee = fee_;
                  escrow = winning_escrow;
                  royalty = royalty;
                  broker_id = current_sale_state.current_broker_id;
                  original_broker_id = current_sale.original_broker_id;
                  sale_id = ?current_sale.sale_id;
                  account_hash = account_hash;
                  metadata = metadata;
                  token_id = ?token_id;
                  token = winning_escrow.token;
                  fee_accounts = fee_accounts;
                }, caller);

                remaining := royalty_result.0;

                //D.print("putting Sales balance");
                //D.print(debug_show(winning_escrow));

                let new_sale_balance = put_sales_balance(state, {
                    winning_escrow with
                    amount = remaining;
                    sale_id = ?current_sale.sale_id;
                    lock_to_date = null;
                    account_hash = account_hash;
                }, true);

                let service : Types.Service = actor((Principal.toText(state.canister())));
                let request_buffer = Buffer.Buffer<Types.ManageSaleRequest>(royalty_result.1.size() + 1);

                request_buffer.add(#withdraw(#sale({
                  new_sale_balance with 
                  withdraw_to = new_sale_balance.seller;}
                )));
                for(thisRoyalty in royalty_result.1.vals()){
                  request_buffer.add(#withdraw(#sale({
                    thisRoyalty with
                    withdraw_to = thisRoyalty.seller;})));
                };
                debug if(debug_channel.royalties) D.print("attempt to distribute royalties request auction" # debug_show(Buffer.toArray(request_buffer)));
                //do not await
                let future = service.sale_batch_nft_origyn(Buffer.toArray(request_buffer));
                //debug if(debug_channel.royalties) D.print("attempt to distribute royalties auction" # debug_show(future));
              };

              switch(Metadata.add_transaction_record(state,{
                token_id = token_id;
                index = 0;
                txn_type = #sale_ended {
                  winning_escrow with
                  sale_id = ?current_sale.sale_id;
                  extensible = #Option(null);
                };
                timestamp = state.get_time();
              }, caller)){
                case(#ok(new_trx)) return #awaited(#end_sale(new_trx));
                case(#err(err)) return #err(#awaited(err));
              };
          };
        };
        return #err(#awaited(Types.errors(?state.canistergeekLogger,  #nyi, "end_sale_nft_origyn - nyi - " , ?caller)));
    };

    /**
    * Distributes a sale to the appropriate buyers by adding withdrawal requests to a buffer. 
    * 
    * @param {StateAccess} state - The state access object.
    * @param {Types.DistributeSaleRequest} request - The request containing the seller information.
    * @param {Principal} caller - The caller principal.
    * 
    * @returns {async* Types.ManageSaleResult} - The result of the sale distribution.
    */
    public func distribute_sale(state : StateAccess, request: Types.DistributeSaleRequest, caller: Principal) : async* Star.Star<Types.ManageSaleResponse,Types.OrigynError>{
      if(NFTUtils.is_owner_network(state, caller) == false) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "distribute_sale - not a canister owner or network", ?caller)));

      let request_buffer : Buffer.Buffer<Types.ManageSaleRequest> = Buffer.Buffer<Types.ManageSaleRequest>(1);

      label sellerSearch for(this_seller in Map.entries(state.state.sales_balances)){
        switch(request.seller){
          case(null){};
          case(?seller){
            if(Types.account_eq(this_seller.0, seller) == false){
              continue sellerSearch;
            };
          };
        };
        for(this_buyer in Map.entries(this_seller.1)){
          for(this_token in Map.entries(this_buyer.1)){
            for(this_token in Map.entries(this_token.1)){
              request_buffer.add(#withdraw(#sale({
                this_token.1 with
                withdraw_to = this_token.1.seller;})));
            };
          };
        };
      };

      let service : Types.Service = actor((Principal.toText(state.canister())));
      let future = try{
        await service.sale_batch_nft_origyn(Buffer.toArray(request_buffer));
      } catch(e){
        return #err(#awaited(Types.errors(?state.canistergeekLogger,  #improper_interface, "distribute_sale - error with self call" # Error.message(e), ?caller)));
      };
      return #awaited(#distribute_sale(future));
    };

    /**
    * @param {StateAccess} state - The state access object.
    * @param {Types.FeeDepositRequest} FeeDepositRequest - The request record to be processed.
    * @returns {Nat} - The amount of free tokens available for fees. Returns 0 if the calculated free amount is negative or if no balance is found.
    */
    private func lock_token_fee_balance(
      state: StateAccess, 
      request:  {
        account : Types.Account; 
        token : Types.TokenSpec;
        token_to_lock : Nat;
        sale_id : Text;
    }) : Result.Result<Nat, Types.OrigynError> {
        return switch(Map.get<Types.Account, Map.Map<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>>(state.state.fee_deposit_balances, account_handler, request.account)){
          case(null){
            return #err(Types.errors(?state.canistergeekLogger,  #content_not_found, "lock_token_fee_balance - account not found  " # debug_show(request.account), null));
          };
          case(?val){
            switch (Map.get<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>(val, token_handler, request.token)) {
              case(null){
                return #err(Types.errors(?state.canistergeekLogger,  #content_not_found, "lock_token_fee_balance - token not found  " # debug_show(request.token), null));
              };
              case(?token) {
                var all_locked_value : Nat = 0;
                for(lock_value in Map.vals(token.locks)){
                  all_locked_value += lock_value;
                };

                if (token.total_balance - all_locked_value > request.token_to_lock) {
                  let _ = Map.put<Text, Nat>(token.locks, Map.thash, request.sale_id, request.token_to_lock);

                  return #ok(token.total_balance - (all_locked_value + request.token_to_lock));
                } else {
                  return #err(Types.errors(?state.canistergeekLogger,  #low_fee_balance, "lock_token_fee_balance - low_fee_balance  ", null));
                }
              };
            };
          };
      }
    };

    /**
    * @param {StateAccess} state - The state access object.
    * @param {Types.FeeDepositRequest} FeeDepositRequest - The request record to be processed.
    * @returns {Nat} - The amount of free tokens available for fees. Returns 0 if the calculated free amount is negative or if no balance is found.
    */
    private func unlock_token_fee_balance(
      state: StateAccess, 
      request:  {
        account : Types.Account; 
        token : Types.TokenSpec;
        sale_id : Text;
    }) : Nat {
        return switch(Map.get<Types.Account, Map.Map<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>>(state.state.fee_deposit_balances, account_handler, request.account)){
          case(null){
            0;
          };
          case(?val){
            switch (Map.get<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>(val, token_handler, request.token)) {
              case(null){
                0;
              };
              case(?token) {
                let previous_balance : Nat = switch(Map.get<Text, Nat>(token.locks, Map.thash, request.sale_id)) {
                  case(?val) {val};
                  case(null) {
                    // TODO RAISE ERROR
                    0;
                  };
                };
                // let new_balance : Nat = token.total_balance - previous_balance;
                let _ = Map.remove<Text, Nat>(token.locks, Map.thash, request.sale_id);

                // let _ = Map.put<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>(val, token_handler, 
                // request.token,
                // {
                //   total_balance = new_balance;
                //   locks = token.locks;
                // });

                return 0;
              };
            };
          };
      }
    };

    //processes a change in fee deposit balance
    /**
    * Processes a change in fee_deposit balance.
    * 
    * @param {StateAccess} state - The state access object.
    * @param {Types.FeeDepositRequest} FeeDepositRequest - The request record to be processed.
    * @returns {Types.EscrowRecord} - The updated escrow record.
    */
    public func put_fee_deposit_balance(
      state: StateAccess, 
      request: Types.FeeDepositRequest,
      balance: Nat): Result.Result<Nat, Types.OrigynError>  {
      //add the escrow

      if(balance > 0){
        var a_from = switch(Map.get<Types.Account, Map.Map<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>>(state.state.fee_deposit_balances, account_handler, request.account)){
          case(null){
            let new_from = Map.new<Types.TokenSpec,MigrationTypes.Current.FeeDepositDetail>();

            Map.set<Types.Account, Map.Map<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>>(state.state.fee_deposit_balances, account_handler, request.account, new_from);
            new_from;
          };
          case(?val){
            val;
          };
        };

        var a_token = switch(Map.get<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>(a_from, token_handler, request.token)){
          case(null){
            let new_token = {
              total_balance= balance;
              locks = Map.new<Text, Nat>();
            };

            Map.set<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>(a_from, token_handler, request.token, new_token);
            new_token;
          };
          case(?val){
            val;
          };
        };

        // Make sure balance hasn't gone below locks
        var total_locked = 0;
        for (lock_value in Map.vals(a_token.locks)){
          total_locked += lock_value;
        };
        
        if (balance < total_locked) {
          return #err(Types.errors(?state.canistergeekLogger,  #low_fee_balance, "put_fee_deposit_balance new balance value is below tokens locks value. total_locked : " # debug_show(total_locked), null));
        };

        Map.set(a_from, token_handler, request.token, {total_balance= balance; locks = a_token.locks});
      } else {

        var a_from = switch(Map.get<Types.Account, Map.Map<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>>(state.state.fee_deposit_balances, account_handler, request.account)){
          case(null){
            return #ok(0);
          };
          case(?val){
            Map.remove(val, token_handler, request.token);
          };
        };
      };

      return #ok(balance);
    };


    //processes a change in escrow balance
    /**
    * Processes a change in escrow balance.
    * 
    * @param {StateAccess} state - The state access object.
    * @param {Types.EscrowRecord} escrow - The escrow record to be processed.
    * @param {Bool} append - Determines whether to append the balance to the ledger or not.
    * 
    * @returns {Types.EscrowRecord} - The updated escrow record.
    */
    public func put_escrow_balance(
      state: StateAccess, 
      escrow: Types.EscrowRecord, 
      append: Bool): Types.EscrowRecord {
      //add the escrow

      var a_from = switch(Map.get<Types.Account, MigrationTypes.Current.EscrowSellerTrie>(state.state.escrow_balances, account_handler, escrow.buyer)){
        case(null){
          let new_from = Map.new<Types.Account,
            Map.Map<Text,
              Map.Map<Types.TokenSpec,Types.EscrowRecord>>>();
          Map.set<Types.Account, MigrationTypes.Current.EscrowSellerTrie>(state.state.escrow_balances, account_handler, escrow.buyer, new_from);
          new_from;
        };
        case(?val){
          val;
        };
      };

      var a_to = switch(Map.get<Types.Account, MigrationTypes.Current.EscrowTokenIDTrie>(a_from, account_handler, escrow.seller)){
        case(null){
          let newTo = Map.new<Text,
                          Map.Map<Types.TokenSpec,Types.EscrowRecord>>();
          Map.set<Types.Account, MigrationTypes.Current.EscrowTokenIDTrie>(a_from, account_handler, escrow.seller, newTo);

          //add this item to the offer index
          if(escrow.token_id != "" and escrow.sale_id == null){
            switch(Map.get<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, account_handler, escrow.seller)){
              case(null){
                var aTree = Map.new<Types.Account,Int>();
                Map.set<Types.Account, Int>(aTree, account_handler, escrow.buyer, state.get_time());
                Map.set<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, account_handler, escrow.seller, aTree);
              };
              case(?val){
                Map.set<Types.Account, Int>(val, account_handler, escrow.buyer, state.get_time());
                Map.set<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, account_handler, escrow.seller, val);
              };
            };
          };
          newTo;
        };
        case(?val) val;
      };

      var a_token_id = switch(Map.get<Text, MigrationTypes.Current.EscrowLedgerTrie>(a_to, Map.thash, escrow.token_id)){
        case(null){
          let new_token_id = Map.new<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>();
          Map.set<Text, MigrationTypes.Current.EscrowLedgerTrie>(a_to, Map.thash, escrow.token_id, new_token_id);
          new_token_id;
        };
        case(?val) val;
      };

      switch(Map.get<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, escrow.token)){
        case(null){
          Map.set<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id,token_handler,escrow.token, escrow);
          return escrow;
        };
        case(?val){

          //note: sale_id will overwrite to save user clicks; alternative is to make them clear it and submit a new escrow
          //nyi: add transaction for overwriting sale id
          let newLedger = if(append == true){
            {
              escrow with 
              amount = val.amount + escrow.amount;
              balances = null;
            };
          } else {
            {
              escrow with 
              balances = null;
            };
          };
          Map.set<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, escrow.token, newLedger);
          return newLedger;
        };
      };
    };

    //processes a changing sale balance
    /**
    * Processes a changing sale balance.
    * 
    * @param {StateAccess} state - The state access object.
    * @param {Types.EscrowRecord} sale_balance - The sale balance to be processed.
    * @param {Bool} append - Determines whether to append the balance to the ledger or not.
    * 
    * @returns {Types.EscrowRecord} - The updated sale balance.
    */
    public func put_sales_balance(state: StateAccess, sale_balance: Types.EscrowRecord, append: Bool): Types.EscrowRecord {
      //add the sale
      var a_to = switch(Map.get<Types.Account, MigrationTypes.Current.SalesBuyerTrie>(state.state.sales_balances, account_handler, sale_balance.seller)){
        case(null){
          let newTo = Map.new<Types.Account,
            Map.Map<Text,
              Map.Map<Types.TokenSpec,Types.EscrowRecord>>>();
          Map.set<Types.Account, MigrationTypes.Current.SalesBuyerTrie>(state.state.sales_balances, account_handler, sale_balance.seller, newTo);
          newTo;
        };
        case(?val) val;
      };

      var a_from = switch(Map.get<Types.Account, MigrationTypes.Current.SalesTokenIDTrie>(a_to, account_handler, sale_balance.buyer)){
        case(null){
          let new_from = Map.new<Text,
            Map.Map<Types.TokenSpec,Types.EscrowRecord>>();
          Map.set<Types.Account, MigrationTypes.Current.SalesTokenIDTrie>(a_to, account_handler, sale_balance.buyer, new_from);
          new_from;
        };
        case(?val) val;
      };

      var a_token_id = switch(Map.get<Text, MigrationTypes.Current.SalesLedgerTrie>(a_from, Map.thash, sale_balance.token_id)){
        case(null){
          let new_token_id = Map.new<Types.TokenSpec,Types.EscrowRecord>();
          Map.set(a_from, Map.thash, sale_balance.token_id, new_token_id);
          new_token_id;
        };
        case(?val) val;
      };

      switch(Map.get<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, sale_balance.token)){
        case(null){
          debug if(debug_channel.royalties) D.print("putting sale balance in escrow, existing record was null" # debug_show((sale_balance)));
          Map.set<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, sale_balance.token, sale_balance);
          return sale_balance;
        };
        case(?val){
          //note: sale_id will overwrite to save user clicks; alternative is to make them clear it and submit a new escrow
          //nyi: add transaction for overwriting sale id
          debug if(debug_channel.royalties) D.print("putting sale balance in escrow, existing record found " # debug_show((val, sale_balance)));

          let newLedger = if(append == true){
            {
              sale_balance with 
              amount = val.amount + sale_balance.amount;
            } //this is a more recent sales id so we use it
          } else {sale_balance};
          Map.set<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, sale_balance.token, newLedger);

          debug if(debug_channel.royalties) D.print("have a new ledger " # debug_show((newLedger)));


          return newLedger;
        };
      };
    };

    /**
    * Handles an error encountered while updating an escrow balance.
    * 
    * @param {StateAccess} state - The current state of the canister.
    * @param {Types.EscrowReceipt} escrow - The receipt of the escrow transaction.
    * @param {Types.Account} owner - The account owner.
    * @param {Object} found_asset - An object containing the found asset and its token specifications.
    * @param {MigrationTypes.Current.EscrowLedgerTrie} found_asset_list - The list of found assets.
    * 
    * @returns {void}
    */
    private func handle_escrow_update_error(
      state: StateAccess, 
      escrow: Types.EscrowReceipt,
      owner: ?Types.Account, 
      found_asset: {token_spec: Types.TokenSpec; escrow: Types.EscrowRecord},
      found_asset_list : MigrationTypes.Current.EscrowLedgerTrie) : () {

      switch(verify_escrow_receipt(state, escrow, owner, null)){
        case(#ok(reverify)){
          let target_escrow = { reverify.found_asset.escrow with
            amount = Nat.add(reverify.found_asset.escrow.amount, escrow.amount);
          };
          Map.set(reverify.found_asset_list, token_handler, found_asset.token_spec, target_escrow);
        };
        case(#err(err)){
          let target_escrow = { found_asset.escrow with
            amount =  escrow.amount;
          };
          Map.set(found_asset_list, token_handler, found_asset.token_spec, target_escrow);
        }
      };
    };

    /**
    * Handles an error encountered while updating a sale balance.
    * 
    * @param {StateAccess} state - The current state of the canister.
    * @param {Types.EscrowReceipt} escrow - The receipt of the escrow transaction.
    * @param {Types.Account} owner - The account owner.
    * @param {Object} found_asset - An object containing the found asset and its token specifications.
    * @param {MigrationTypes.Current.EscrowLedgerTrie} found_asset_list - The list of found assets.
    * 
    * @returns {void}
    */
    private func handle_sale_update_error(
      state: StateAccess, 
      escrow: Types.EscrowReceipt,
      owner: ?Types.Account, 
      found_asset: {token_spec: Types.TokenSpec; escrow: Types.EscrowRecord},
      found_asset_list : MigrationTypes.Current.EscrowLedgerTrie) : () {

      switch(verify_sales_reciept(state, escrow)){
        case(#ok(reverify)){
          let target_escrow = {
            reverify.found_asset.escrow with 
            amount = Nat.add(reverify.found_asset.escrow.amount, escrow.amount);
          };
          Map.set(reverify.found_asset_list, token_handler, found_asset.token_spec, target_escrow);
        };
        case(#err(err)){
          let target_escrow = { found_asset.escrow with
            amount =  escrow.amount;
          };
          Map.set(found_asset_list, token_handler, found_asset.token_spec, target_escrow);
        };
      };
    };

    /**
    * Converts the properties and collection of a Candy NFT to an array.
    * 
    * @param {CandyTypes.CandyShared} properties - The properties of the Candy NFT.
    * @param {Text} collection - The collection of the Candy NFT.
    * 
    * @returns {Array} - An array of Candy NFT properties.
    */
    public func royalty_to_array(properties: CandyTypes.CandyShared, collection: Text) : [CandyTypes.CandyShared]{
      debug if(debug_channel.royalties) D.print("In royalty to array" # debug_show((properties, collection)));
      switch(Properties.getClassPropertyShared(properties, collection)){
        case(null) [];
        case(?list){
          debug if(debug_channel.royalties) D.print("found list" # debug_show(list));
          switch(list.value){
            case(#Array(the_array)){
              debug if(debug_channel.royalties) D.print("found array");
              the_array;
            };
            case(_) [];
          };
        };
      };
    };

    

    //handles async market transfer operations like instant where interaction with other canisters is required
    /**
    * Handles async market transfer operations like instant where interaction with other canisters is required
    * @param {StateAccess} state - StateAccess instance representing the state of the canister
    * @param {Types.MarketTransferRequest} request - MarketTransferRequest object containing the details of the transfer
    * @param {Principal} caller - Principal object representing the caller
    * @returns {AsyncGenerator<Types.MarketTransferResult>} An async generator that yields a Result object representing the result of the transfer operation
    */
    public func market_transfer_nft_origyn_async(state: StateAccess, request : Types.MarketTransferRequest, caller: Principal, canister_call: Bool) : async* Result.Result<Types.MarketTransferRequestReponse,Types.OrigynError> {
        
      debug if(debug_channel.market) D.print("in market_transfer_nft_origyn");
      var metadata = switch(Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)){
        case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "market_transfer_nft_origyn " # err.flag_point, ?caller));
        case(#ok(val)) val;
      };

      debug if(debug_channel.market) D.print("have metadata" # debug_show(metadata));

      let owner = switch(
        Metadata.get_nft_owner(metadata)){
          case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn " # err.flag_point, ?caller));
          case(#ok(val)) val;
      };

      debug if(debug_channel.market) D.print("have owner " # debug_show(owner));
      debug if(debug_channel.market) D.print("the caller" # debug_show(caller));

      //check to see if there is a current sale going on MKT0018
      let this_is_minted = Metadata.is_minted(metadata);

      debug if(debug_channel.market) D.print(request.token_id # " isminted" # debug_show(this_is_minted));
      if(this_is_minted){
        //can't start auction if token is soulbound
        if (Metadata.is_soulbound(metadata)) return #err(Types.errors(?state.canistergeekLogger,  #token_non_transferable, "market_transfer_nft_origyn ", ?caller));

        //this is a minted NFT - only the nft owner
        switch(Metadata.is_nft_owner(metadata, #principal(caller))){
          case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn - not an owner of the NFT - minted sale" # err.flag_point, ?caller));
          case(#ok(val)){
            if(val == false){return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "market_transfer_nft_origyn - not an owner of the NFT - minted sale", ?caller))};
          };
        };
      } else {
        //this is a staged NFT it can be sold by the canister owner or the canister manager
        switch(owner){
          case(#extensible(ex)){
            if(Conversions.candySharedToText(ex) == "trx in flight"){
              return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "market_transfer_nft_origyn - not an owner of the canister - staged sale - trx in flight", ?caller))
            };
          };
          case(_){};
        };

      };

      debug if(debug_channel.market) D.print("have minted " # debug_show(this_is_minted));

      //look for an existing sale
      switch(is_token_on_sale(state, metadata, caller)){
          case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn ensure_no_sale " # err.flag_point, ?caller));
          case(#ok(val)){
              if(val == true){
                  return #err(Types.errors(?state.canistergeekLogger,  #existing_sale_found, "market_transfer_nft_origyn - sale exists " # request.token_id , ?caller));
              };
          };
      };

      debug if(debug_channel.market) D.print("checking pricing");

      switch(request.sales_config.pricing){
        case(#instant){
          //the nft or staged nft is being instant transfered

          //if this is a marketable NFT, we need to create a waiver period

          //if this is not a marketable NFT we can insta trade

          //since this is a stage we need to call mint and it will do this for us
          //set new owner
          debug if(debug_channel.market) D.print("in market transfer");
          let escrow = switch(request.sales_config.escrow_receipt){
            case(null){
              //we can't insta transfer because no instructions are given
              //D.print("no escrow set");
              return #err(Types.errors(?state.canistergeekLogger,  #improper_interface, "market_transfer_nft_origyn verifying escrow - not included ", ?caller));
            };
            case(?escrow) escrow;
          };

          //we should verify the escrow
          if(this_is_minted){
              if(escrow.token_id == ""){
                  //can't escrow to general for minted item
                  return #err(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "market_transfer_nft_origyn can't find specific escrow for minted item", ?caller));
              };
          };

          debug if(debug_channel.market) D.print("current escrow is");
          //verify the specific escrow

          debug if(debug_channel.market) D.print(debug_show(escrow.seller));
          debug if(debug_channel.market) D.print(debug_show(escrow.buyer));
          debug if(debug_channel.market) D.print(escrow.token_id);
          debug if(debug_channel.market) D.print(debug_show(Types.token_hash(escrow.token)));
          debug if(debug_channel.market) D.print(debug_show(escrow.amount));
          
          var verified = switch(verify_escrow_receipt(state, escrow, ?owner, null)){
            case(#err(err)){
              //at this point the escrow isn't here, so we're going to try to recognize it.
              if(canister_call == false){
                switch(Star.toResult(await* recognize_escrow_nft_origyn(state, { 
                  deposit = {escrow with
                    sale_id = null;
                    trx_id = null;
                  };
                  lock_to_date = null;
                  token_id = escrow.token_id;
                  }, 
                  caller))){
                    case(#ok(val)){
                      return await* market_transfer_nft_origyn_async(state, request, caller, true);
                    };
                    case(#err(err)){
                      return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn auto try escrow failed after recheck" # err.flag_point, ?caller))
                    };
                  };
                } else {
                  return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn auto try escrow failed in a canister call " # err.flag_point, ?caller))
                };
            };
            case(#ok(res)) res;
          };

          var bRevalidate = false;

          //kyc seller
          let kyc_result_seller = try{
            await* KYC.pass_kyc_seller(state, verified.found_asset.escrow, caller);
          } catch(e){
            debug if(debug_channel.kyc) D.print("KYC error seller on await* " # Error.message(e));
            return #err(Types.errors(?state.canistergeekLogger,  #kyc_error, "market_transfer_nft_origyn auto try kyc failed seller " # Error.message(e), ?caller))
          };

          switch(kyc_result_seller){
            case(#ok(val)){

              if(val.result.kyc == #Fail or val.result.aml == #Fail){
                //returns the failed escrow to the user
                //ignore refund_failed_bid(state, verified, escrow);
                return #err(Types.errors(?state.canistergeekLogger,  #kyc_fail, "market_transfer_nft_origyn kyc or aml failed seller " # debug_show(val), ?caller));
              };
              
              //amount is ignored for seller

              if(val.did_async){
                bRevalidate := true;
              };

            };
            case(#err(err)){
              //ignore refund_failed_bid(state, verified, escrow);
              debug if(debug_channel.kyc) D.print("KYC error on reading return " # debug_show(err));
              return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn auto try kyc failed " # err.flag_point, ?caller))
            };
          };

          //kyc buyer

          let kyc_result = try{
            await* KYC.pass_kyc_buyer(state, verified.found_asset.escrow, caller);
          } catch(e){
            debug if(debug_channel.kyc) D.print("KYC error on await* " # Error.message(e));
            return #err(Types.errors(?state.canistergeekLogger,  #kyc_error, "market_transfer_nft_origyn auto try kyc failed " # Error.message(e), ?caller))
          };

          switch(kyc_result){
            case(#ok(val)){

              if(val.result.kyc == #Fail or val.result.aml == #Fail){
                //returns the failed escrow to the user
                //ignore refund_failed_bid(state, verified, escrow);
                return #err(Types.errors(?state.canistergeekLogger,  #kyc_fail, "market_transfer_nft_origyn kyc or aml failed buyer " # debug_show(val), ?caller));
              };
              let kycamount = Option.get(val.result.amount, 0);

              if((kycamount > 0) and (escrow.amount > kycamount)){
                //ignore refund_failed_bid(state, verified, escrow);
                return #err(Types.errors(?state.canistergeekLogger,  #kyc_fail, "market_transfer_nft_origyn kyc or aml amount too large buyer " # debug_show((val, kycamount, escrow)), ?caller))
              };

              if(val.did_async){
                bRevalidate := true;
              };

            };
            case(#err(err)){
              //ignore refund_failed_bid(state, verified, escrow);
              debug if(debug_channel.kyc) D.print("KYC error on reading return " # debug_show(err));
              return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn auto try kyc failed buyer " # err.flag_point, ?caller))
            };
          };

          //re verify if we did async
          if(bRevalidate){
            verified := switch(verify_escrow_receipt(state, escrow, ?owner, null)){
              case(#err(err)){
                //we can't inline here becase the buyer isn't the caller and a malicious collection owner could sell a depositor something they did not want.
                return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn auto try escrow failed revalidate  " # err.flag_point, ?caller))
              };
              case(#ok(res)) res;
            };
          };

          //reentrancy risk so we remove the credit from the escrow
          debug if(debug_channel.market) D.print("updating the asset list");
          debug if(debug_channel.market) D.print(debug_show(Map.size(verified.found_asset_list)));
          debug if(debug_channel.market) D.print(debug_show(Iter.toArray(Map.entries(verified.found_asset_list))));

          if(verified.found_asset.escrow.amount > escrow.amount){
            debug if(debug_channel.market) D.print("should be overwriting escrow" # debug_show((verified.found_asset.escrow.amount,escrow.amount)));
            Map.set(verified.found_asset_list, token_handler, verified.found_asset.token_spec, {
              verified.found_asset.escrow with 
                amount = Nat.sub(verified.found_asset.escrow.amount, escrow.amount);
                balances = null;
              });
          } else {
            debug if(debug_channel.market) D.print("should be deleting escrow" # debug_show((verified.found_asset.token_spec)));
            Map.delete(verified.found_asset_list, token_handler, verified.found_asset.token_spec);
          };

          debug if(debug_channel.market) D.print(debug_show(Map.size(verified.found_asset_list)));
          debug if(debug_channel.market) D.print(debug_show(Iter.toArray(Map.entries(verified.found_asset_list))));

          //reentrancy risk so set the owner to a black hole while transaction is in flight
          metadata := switch(Metadata.set_nft_owner(state, request.token_id, #extensible(#Text("trx in flight")), caller)){
            case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller));
            case(#ok(new_metadata)) new_metadata;
          };

          let (trx_id : Types.TransactionID, account_hash : ?Blob, fee : Nat) = switch(escrow.token){
            case(#ic(token)){
              switch(token.standard){
                case(#Ledger or #ICRC1){
                  debug if(debug_channel.market) D.print("found ledger and sending sale " # debug_show(escrow));
                  let checker = Ledger_Interface.Ledger_Interface();
                  try{
                    switch(await* checker.transfer_sale(state.canister(), escrow, request.token_id, caller)){
                      case(#ok(val)){
                        (val.0, ?val.1.account.sub_account, val.2);
                      };
                      case(#err(err)){
                        //put the escrow back because the payment failed
                        handle_escrow_update_error(state, escrow, ?owner, verified.found_asset, verified.found_asset_list);

                        //put the owner back if the transaction fails
                        metadata := switch(Metadata.set_nft_owner(state, request.token_id, owner, caller)){
                          case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller));
                          case(#ok(new_metadata)) new_metadata;
                        };

                        return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn instant " # err.flag_point, ?caller));
                      };
                    };
                  } catch (e){
                    //put the escrow back because payment failed
                    handle_escrow_update_error(state, escrow, ?owner, verified.found_asset, verified.found_asset_list);

                    //put the owner back if the transaction fails
                    metadata := switch(Metadata.set_nft_owner(state, request.token_id, owner, caller)){
                      case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller));
                      case(#ok(new_metadata)) new_metadata;
                    };

                    return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "market_transfer_nft_origyn instant catch branch" # Error.message(e), ?caller));
                  };
                };
                case(_) {
                  //put the owner back if the transaction fails
                  metadata := switch(Metadata.set_nft_owner(state, request.token_id, owner, caller)){
                    case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller));
                    case(#ok(new_metadata)) new_metadata;
                  };

                  return #err(Types.errors(?state.canistergeekLogger,  #nyi, "market_transfer_nft_origyn - ic type nyi - " # debug_show(token), ?caller));
                };
              };
            };
              
            case(#extensible(val)){
              //put the owner back if the transaction fails
              metadata := switch(Metadata.set_nft_owner(state, request.token_id, owner, caller)){
                case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller));
                case(#ok(new_metadata)) new_metadata;
              };

              return #err(Types.errors(?state.canistergeekLogger,  #nyi, "market_transfer_nft_origyn - extensible token nyi - " # debug_show(val), ?caller));
            };
          };

          debug if(debug_channel.market) D.print("transfered to account hash " # debug_show(account_hash));

          var b_freshmint = false;

          let txn_record = if(this_is_minted == false){
            //execute mint should add mint transaction
            b_freshmint := true;
            let rec = switch(Mint.execute_mint(state, request.token_id, escrow.buyer, ?escrow, caller )){
              case(#err(err)){
                //put the escrow back because the minting failed
                handle_escrow_update_error(state, escrow, ?owner, verified.found_asset, verified.found_asset_list);
                return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn mint attempt" # err.flag_point, ?caller));
              };
              case(#ok(val)){
                debug if(debug_channel.market) D.print("updating metadata after mint");
                metadata := val.1;
                val.2;
              };
            };
          } else {

            metadata := switch(Metadata.set_nft_owner(state, request.token_id, escrow.buyer, caller)){
                case(#err(err)) {
                  //ownership change failed, but we already have tokens...what to do...leave in flight and let governance fix
                  /* switch(verify_escrow_reciept(state, escrow, ?owner, null)){
                    case(#ok(reverify)){
                        let target_escrow = {
                            account_hash = reverify.found_asset.escrow.account_hash;
                            amount = Nat.add(reverify.found_asset.escrow.amount, escrow.amount);
                            buyer = reverify.found_asset.escrow.buyer;
                            seller = reverify.found_asset.escrow.seller;
                            token_id = reverify.found_asset.escrow.token_id;
                            token = reverify.found_asset.escrow.token;
                            sale_id = reverify.found_asset.escrow.sale_id;
                            lock_to_date = reverify.found_asset.escrow.lock_to_date;
                        };
                        Map.set(reverify.found_asset_list, token_handler, verified.found_asset.token_spec, target_escrow);
                    };

                  //D.print("updating metadata");
                  Map.set(state.state.nft_metadata, Map.thash, escrow.token_id, new_metadata);
                  metadata := new_metadata;
                  //no need to mint
                  switch(Metadata.add_transaction_record(state,{
                    token_id = request.token_id;
                    index = 0; //mint should always be 0
                    txn_type = #sale_ended({
                      escrow with
                      seller = owner;
                      sale_id = null;
                      extensible = #Option(null);
                    });
                    timestamp = Time.now();
                  }, caller)){
                    case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn adding transaction" # err.flag_point, ?caller));
                    case(#ok(val)) val;
                  };
                };
              case(#err(err)){
                let target_escrow = {
                    account_hash = verified.found_asset.escrow.account_hash;
                    amount =  escrow.amount;
                    buyer = verified.found_asset.escrow.buyer;
                    seller = verified.found_asset.escrow.seller;
                    token_id = verified.found_asset.escrow.token_id;
                    token = verified.found_asset.escrow.token;
                    sale_id = verified.found_asset.escrow.sale_id;
                    lock_to_date = verified.found_asset.escrow.lock_to_date;
                };
                Map.set(verified.found_asset_list, token_handler, verified.found_asset.token_spec, target_escrow);
                }
              }; */
                    return #err(Types.errors(?state.canistergeekLogger,  #update_class_error, "Market transfer Origyn - error setting owner item is now in limbo, use governance to fix" # escrow.token_id, ?caller));
              };

              case(#ok(new_metadata)) new_metadata;
            };

            //reset the system wallet shares
            metadata := Metadata.set_system_var(metadata, Types.metadata.__system_wallet_shares, #Option(null));
          

            //D.print("updating metadata");
            Map.set(state.state.nft_metadata, Map.thash, escrow.token_id, metadata);
            //no need to mint
            switch(Metadata.add_transaction_record(state,{
                token_id = request.token_id;
                index = 0; //mint should always be 0
                txn_type = #sale_ended({
                    seller = owner;
                    buyer = escrow.buyer;
                    token = escrow.token;
                    amount = escrow.amount;
                    sale_id = null;
                    extensible = #Option(null);
                });
                timestamp = Time.now();
            }, caller)){
                case(#err(err)){return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn adding transaction" # err.flag_point, ?caller));};
                case(#ok(val)){val};
            };


          };

         Map.set(state.state.nft_metadata, Map.thash, escrow.token_id, metadata);

          //escrow already invalidated
          //calculate royalties
          debug if(debug_channel.market) D.print("trying to invalidate asset");
          debug if(debug_channel.market) D.print(debug_show(verified.found_asset));

          debug if(debug_channel.market) D.print("calculating royalty" # debug_show(metadata));

          let royalty = if(b_freshmint == false){
            //secondary
            switch(Properties.getClassPropertyShared(metadata, Types.metadata.__system)){
              case(null){[];};
              case(?val){
                debug if(debug_channel.market) D.print("found metadata" # debug_show(val.value));
                royalty_to_array(val.value, Types.metadata.__system_secondary_royalty);
              };
            };
          } else {
            //primary
            switch(Properties.getClassPropertyShared(metadata, Types.metadata.__system)){
              case(null){[];};
              case(?val){
                debug if(debug_channel.market) D.print("found metadata" # debug_show(val.value));
                royalty_to_array(val.value, Types.metadata.__system_primary_royalty);
              };
            };
          };

          debug if(debug_channel.market) D.print("royalty is " # debug_show(royalty));
          //note: this code path is always taken since checker.transferSale requires it or errors
          //we have included it here so that we can use Nat.sub without fear of underflow
          
          if(escrow.amount > fee){
            let total = Nat.sub(escrow.amount, fee);
            var remaining = Nat.sub(escrow.amount, fee);

            debug if(debug_channel.royalties) D.print("calling process royalty" # debug_show((total,remaining)));
            let royalty_result = _process_royalties(state, {
                var remaining = remaining;
                total = total;
                fee = fee;
                escrow = escrow;
                royalty = royalty;
                sale_id = null;
                broker_id = request.sales_config.broker_id;
                original_broker_id = null;
                account_hash = account_hash;
                metadata = metadata;
                token_id = ?request.token_id;
                token = escrow.token;
                fee_accounts = null; // not sure here 
            }, caller);

            remaining := royalty_result.0;

            debug if(debug_channel.royalties) D.print("done with royalty" # debug_show((total,remaining)));
                
            let new_sale_balance = put_sales_balance(state, {
              verified.found_asset.escrow with
              amount = remaining;
              sale_id = null;
              lock_to_date = null;
              account_hash = account_hash;
            }, true);

            let service : Types.Service = actor((Principal.toText(state.canister())));
            let request_buffer = Buffer.Buffer<Types.ManageSaleRequest>(royalty_result.1.size() + 1);

            request_buffer.add(#withdraw(#sale({
              new_sale_balance with
              withdraw_to = new_sale_balance.seller;}
            )));

            for(thisRoyalty in royalty_result.1.vals()){
              request_buffer.add(#withdraw(#sale({
                thisRoyalty with
                withdraw_to = thisRoyalty.seller;})));
            };
            debug if(debug_channel.royalties) D.print("attempt to distribute royalties request instant" # debug_show(Buffer.toArray(request_buffer)));

            let future = service.sale_batch_nft_origyn(Buffer.toArray(request_buffer));
            //debug if(debug_channel.royalties) D.print("attempt to distribute royalties instant" # debug_show(future));
          };

          return #ok(txn_record);
        };

        case(_) return #err(Types.errors(?state.canistergeekLogger,  #nyi, "market_transfer_nft_origyn nyi pricing type async", ?caller));
      };
    };

    /**
    * Calculates the network royalty account for a given principal.
    * 
    * @param {Principal} principal - The principal for which to calculate the network royalty account.
    * 
    * @returns {Array<Nat8>} An array of 8-bit natural numbers representing the calculated network royalty account.
    */
    public func get_network_royalty_account(principal : Principal, ledger_token_id: ?Nat) : [Nat8]{
      let h = SHA256.New();
      h.write(Conversions.candySharedToBytes(#Text("com.origyn.network_royalty")));
      h.write(Conversions.candySharedToBytes(#Text("canister-id")));
      h.write(Conversions.candySharedToBytes(#Text(Principal.toText(principal))));
       switch(ledger_token_id){
        case(?val) {
          h.write(Conversions.candySharedToBytes(#Text("token-id")));
          h.write(Conversions.candySharedToBytes(#Nat(val)));
        };
        case(null) {};
      };
      h.sum([]);
    };

    //handles royalty distribution
    private func _process_royalties(state : StateAccess, request : {
        var remaining: Nat;
        total: Nat;
        fee: Nat;
        account_hash: ?Blob;
        royalty: [CandyTypes.CandyShared];
        escrow: Types.EscrowReceipt;
        broker_id: ?Principal;
        original_broker_id: ?Principal;
        sale_id: ?Text;
        metadata : CandyTypes.CandyShared;
        token_id: ?Text;
        token: Types.TokenSpec;
        fee_accounts: ?MigrationTypes.Current.FeeAccountsParams;
    }, caller: Principal) : (Nat, [Types.EscrowRecord]){

      let dev_fund : {owner: Principal; sub_account: ?Blob;} = {owner = Principal.fromText("a3lu7-uiaaa-aaaaj-aadnq-cai"); sub_account = ?Blob.fromArray([90,139,65,137,126,28,225,88,245,212,115,206,119,123,54,216,86,30,91,21,25,35,79,182,234,229,219,103,248,132,25,79])};

      debug if(debug_channel.royalties) D.print("in process royalty" # debug_show(request));

      let results = Buffer.Buffer<Types.EscrowRecord>(1);

      label royaltyLoop for(this_item in request.royalty.vals()){
        let the_array = switch(this_item){
          case(#Class(the_array)) the_array;
          case(_){ continue royaltyLoop;};
        };

        debug if(debug_channel.royalties) D.print("getting items from class " # debug_show(this_item));
              
        let rate = switch(Properties.getClassPropertyShared(this_item, "rate")){
          case(null){0:Float};
          case(?val){
            switch(val.value){
              case(#Float(val)) val;
              case(_) 0:Float;
            };
          };
        };

        let tag = switch(Properties.getClassPropertyShared(this_item, "tag")){
          case(null){"other"}; 
          case(?val){
              switch(val.value){
                case(#Text(val)) val;
                case(_) "other"; 
              };
          };
        };

        let fee_accounts : MigrationTypes.Current.FeeAccountsParams = switch (request.fee_accounts) {
            case(?val) val;
            case(null) [];
        };

        let tmp_principal : [{owner: Principal; sub_account: ?Blob;}] = if (fee_accounts.size() > 0) {
              switch (Array.find<(Text, MigrationTypes.Current.Account)>(fee_accounts, func (val) { return val.0 == tag; })) {
                case(?val) {
                  switch (val.1){
                    case(#account(x)) {[x];};
                    case(_) {[];}; // TODO CHECK WITH AUSTIN 
                  };
                };
                case(null){[]}; 
              };
            } else {
              [];
            };

        var principal : [{owner: Principal; sub_account: ?Blob;}] = 
          if (tmp_principal.size() > 0) {
            tmp_principal;
          } else {
            switch(Properties.getClassPropertyShared(this_item, "account")){
                case(null){
                  let #ic(tokenSpec) = request.token else {
                    debug if(debug_channel.royalties) D.print("not an IC token spec so continuing " # debug_show(request.token));
                    continue royaltyLoop;
                  }; //we only support ic token specs for royalties
                  if(tag == Types.metadata.royalty_network){
                    debug if(debug_channel.royalties) D.print("found the network" # debug_show(get_network_royalty_account(tokenSpec.canister, tokenSpec.id)));
                    switch(state.state.collection_data.network){
                      case(null) [dev_fund] ; //dev fund
                      case(?val) [{owner = val; sub_account = ?Blob.fromArray(get_network_royalty_account(tokenSpec.canister,tokenSpec.id))}] ;
                    };
                  } else if(tag == Types.metadata.royalty_node){
                    let val = Metadata.get_system_var(request.metadata, Types.metadata.__system_node);
                    switch(val){
                      case(#Option(null)) [dev_fund] ; //dev fund
                      case(#Principal(val)) [{owner = val; sub_account = null;}];
                      case(_) [dev_fund];
                    };
                  } else if(tag == Types.metadata.royalty_originator){
                    let val = Metadata.get_system_var(request.metadata, Types.metadata.__system_originator);
                    switch(val){
                      case(#Option(null)) [dev_fund]; //dev fund
                      case(#Principal(val)) [{owner = val; sub_account = null;}];
                      case(_) [dev_fund] ;
                    };
                  } else if(tag == Types.metadata.royalty_broker){
                    switch(request.broker_id, request.original_broker_id){
                      case(null, null){ 
                        let ?collection = Map.get(state.state.nft_metadata, Map.thash,"") else {
                          state.canistergeekLogger.logMessage("process royalties cannot find collection metatdata. this should not happene" # debug_show(request.token_id), #Bool(false), null);
                          D.trap("process royalties cannot find collection metatdata. this should not happen");
                        };

                        let override = switch(Metadata.get_nft_bool_property(collection, Types.metadata.broker_royalty_dev_fund_override)){
                          case(#ok(val)) val;
                          case(_) {
                            state.canistergeekLogger.logMessage("_process_royalties overriding error candy type" # debug_show(collection) # debug_show(request.token_id), #Bool(false), null);
                            false};
                        };

                        

                        if(override){
                          state.canistergeekLogger.logMessage("_process_royalties overriding " # debug_show(request.token_id), #Bool(override), null);
                          continue royaltyLoop;
                        };

                        state.canistergeekLogger.logMessage("_process_royalties override result using dev fund" # debug_show(request.token_id), #Bool(override), null);
                        
                        [dev_fund]
                      }; //dev fund
                      case(?val, null) [{owner = val; sub_account = null;}];
                      case(null, ?val2) [{owner = val2; sub_account = null;}];
                      case(?val, ?val2){
                        if(val == val2) [{owner = val; sub_account = null;}]
                        else [{owner = val; sub_account = null;}, {owner = val2; sub_account = null;}];
                      };
                    };
                  } else { 
                    [dev_fund]; //dev fund
                  };
                };  //dev fund
                case(?val){
                  switch(val.value){
                      case(#Principal(val)) [{owner = val; sub_account = null;}];
                      case(_) [dev_fund]; //dev fund
                  };
                };
            };
          };

        debug if(debug_channel.royalties) D.print("have vals" # debug_show((rate, tag, principal)));

        let total_royalty = (request.total * Int.abs(Float.toInt(rate * 1_000_000)))/1_000_000;

        debug if(debug_channel.royalties) D.print("test royalty" # debug_show((total_royalty, principal)));
        for(this_principal in principal.vals()){
          let this_royalty = (total_royalty / principal.size());

          if(this_royalty > request.fee){
            request.remaining -= this_royalty;
            //royaltyList.add(#principal(principal), this_royalty);

            let send_account : {owner: Principal; sub_account: ?Blob} = if(Principal.fromText("yfhhd-7eebr-axyvl-35zkt-z6mp7-hnz7a-xuiux-wo5jf-rslf7-65cqd-cae") == this_principal.owner){
              {owner = Principal.fromText("a3lu7-uiaaa-aaaaj-aadnq-cai"); sub_account = ?Blob.fromArray([90,139,65,137,126,28,225,88,245,212,115,206,119,123,54,216,86,30,91,21,25,35,79,182,234,229,219,103,248,132,25,79])
              };
            } else {
              this_principal
            };

            let id = Metadata.add_transaction_record(state, {
              token_id = request.escrow.token_id;
              index = 0;
              txn_type = #royalty_paid {
                request.escrow with 
                amount = this_royalty;
                tag = tag;
                receiver = #account({ owner = send_account.owner;
                sub_account = switch(send_account.sub_account){
                    case(null) null;
                    case(?val) ?val;
                  }
                });
                sale_id = request.sale_id;
                extensible = switch(request.token_id){
                  case(null) #Option(null): CandyTypes.CandyShared;
                  case(?token_id) #Text(token_id) : CandyTypes.CandyShared;
                };
              };
              timestamp = state.get_time();
            }, caller);

            debug if(debug_channel.royalties) D.print("added trx" # debug_show(id));

            let newReciept = {
              request.escrow with 
              amount = this_royalty;
              seller = #account(
                { owner = send_account.owner;
                  sub_account = switch(send_account.sub_account){
                    case(null) null;
                    case(?val) ?val;
                  };
                });
              sale_id = request.sale_id;
              lock_to_date = null;
              account_hash = request.account_hash;
            };

            //note, if a sale ledger already exists this will add the value, but we need to keep the original amount so we don't double request the same amount.
            let new_sale_balance = put_sales_balance(state, newReciept, true);

            results.add(newReciept);
            debug if(debug_channel.royalties) D.print("new_sale_balance" # debug_show(newReciept));
          } else {
              //can't pay out if less than fee
          };
        };
      };
      return (request.remaining, Buffer.toArray(results));
    };

    //handles non-async market functions like starting an auction
    /**
    * Processes royalties for a given escrow transaction and updates state accordingly.
    * @param {StateAccess} state - The current state of the application.
    * @param {Object} request - An object containing the necessary information for royalty processing.
    * @param {Nat} request.remaining - The amount of remaining royalty to be paid.
    * @param {Nat} request.total - The total amount of royalty to be paid.
    * @param {Nat} request.fee - The fee to be paid for processing royalty.
    * @param {?Blob} request.account_hash - An optional hash of the account for which royalty is being paid.
    * @param {[CandyTypes.CandyShared]} request.royalty - The array of royalty being paid.
    * @param {Types.EscrowReceipt} request.escrow - The escrow receipt associated with the transaction.
    * @param {?Principal} request.broker_id - The broker ID associated with the transaction.
    * @param {?Principal} request.original_broker_id - The original broker ID associated with the transaction.
    * @param {?Text} request.sale_id - The sale ID associated with the transaction.
    * @param {CandyTypes.CandyShared} request.metadata - The metadata associated with the transaction.
    * @param {?Text} request.token_id - The token ID associated with the transaction.
    * @param {Types.TokenSpec} request.token - The token specification associated with the transaction.
    * @param {Principal} caller - The principal that initiated the transaction.
    * @returns {[Nat, [Types.EscrowRecord]]} A tuple containing the remaining royalty amount and an array of EscrowRecords.
    */
    public func market_transfer_nft_origyn(state: StateAccess, request : Types.MarketTransferRequest, caller: Principal) : async* Result.Result<Types.MarketTransferRequestReponse,Types.OrigynError> {
        
        debug if(debug_channel.market) D.print("in market_transfer_nft_origyn");
        var metadata = switch(Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)){
            case(#err(err)){
                return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "market_transfer_nft_origyn " # err.flag_point, ?caller));
            };
            case(#ok(val)){
                val;
            };
        };
        
        debug if(debug_channel.market) D.print("have metadata");

        //can't start auction if token is a phisycal object unless in escrow with a node
        if (Metadata.is_physical(metadata)) {
          if (Metadata.is_in_physical_escrow(metadata) == false) {
            return #err(Types.errors(?state.canistergeekLogger,  #token_non_transferable, "market_transfer_nft_origyn physical token must be escrowed", ?caller));
          };
        };

        let owner = switch(
          Metadata.get_nft_owner(metadata)){
            case(#err(err))return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn " # err.flag_point, ?caller));
            case(#ok(val)) val;
        };

        debug if(debug_channel.market) D.print("have owner " # debug_show(owner));
        debug if(debug_channel.market) D.print("the caller" # debug_show(caller));

        //check to see if there is a current sale going on MKT0018

        let this_is_minted = Metadata.is_minted(metadata);
        
        debug if(debug_channel.market) D.print(request.token_id # " isminted" # debug_show(this_is_minted));
        if(this_is_minted){
          //can't start auction if token is soulbound
          if (Metadata.is_soulbound(metadata)) return #err(Types.errors(?state.canistergeekLogger,  #token_non_transferable, "market_transfer_nft_origyn ", ?caller));

          //this is a minted NFT - only the nft owner or nft manager can sell it
          switch(Metadata.is_nft_owner(metadata, #principal(caller))){
            case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn - not an owner of the NFT - minted sale" # err.flag_point, ?caller));
            case(#ok(val)){
              if(val == false) return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "market_transfer_nft_origyn - not an owner of the NFT - minted sale", ?caller));
            };
          };
        } else {
          //this is a staged NFT it can be sold by the canister owner or the canister manager
          if(NFTUtils.is_owner_manager_network(state,caller) == false) return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "market_transfer_nft_origyn - not an owner of the canister - staged sale ", ?caller));
        };

        debug if(debug_channel.market) D.print("have minted " # debug_show(this_is_minted));

        //look for an existing sale
        switch(is_token_on_sale(state, metadata, caller)){
          case(#err(err)) return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn ensure_no_sale " # err.flag_point, ?caller));
          case(#ok(val)){
              if(val == true) return #err(Types.errors(?state.canistergeekLogger,  #existing_sale_found, "market_transfer_nft_origyn - sale exists " # request.token_id , ?caller));
          };
        };

        debug if(debug_channel.market) D.print("checking pricing");

        //what does an escrow reciept do for an auction? Place a bid?
        //for now fail if provided
        switch(request.sales_config.escrow_receipt){
          case(?val) return #err(Types.errors(?state.canistergeekLogger,  #nyi, "market_transfer_nft_origyn - handling escrow for auctions NYI", ?caller));
          case(_){};
        };

        if(this_is_minted == false){
          return #err(Types.errors(?state.canistergeekLogger,  #nyi, "cannot auction off a unminted item", ?caller))
        };

        let h = SHA256.New();
        h.write(Conversions.candySharedToBytes(#Text("com.origyn.nft.sale-id")));
        h.write(Conversions.candySharedToBytes(#Text("token-id")));
        h.write(Conversions.candySharedToBytes(#Text(request.token_id)));
        h.write(Conversions.candySharedToBytes(#Text("seller")));
        h.write(Conversions.candySharedToBytes(#Nat(MigrationTypes.Current.account_hash_uncompressed(owner))));
        h.write(Conversions.candySharedToBytes(#Text("timestamp")));
        h.write(Conversions.candySharedToBytes(#Int(state.get_time())));
        let sale_id : Text = Conversions.candySharedToText(#Bytes(h.sum([])));

        let {
          reserve : ?Nat; 
          buy_now : ?Nat; 
          token : MigrationTypes.Current.TokenSpec;
          start_date: Int;
          start_price: Nat;
          end_date: Int;
          dutch : ?MigrationTypes.Current.DutchParams;
          allow_list : ?Map.Map<Principal, Bool>;
          notify : [Principal];
          fee_accounts: ?MigrationTypes.Current.FeeAccountsParams;
          fee_schema: Text;
        } = switch(request.sales_config.pricing){
          case(#auction(auction_details)){
            
            let start_date : Int = if(auction_details.start_date > 0) {
                auction_details.start_date;
              } else {
                state.get_time();
              };

            switch(auction_details.ending){
              case(#date(val)){
                if(val <= auction_details.start_date) return #err(Types.errors(?state.canistergeekLogger,  #improper_interface, "market_transfer_nft_origyn - end date cannot be before start date", ?caller));
              };
                case(#wait_for_quiet(val)){
                if(val.date <= auction_details.start_date) return #err(Types.errors(?state.canistergeekLogger,  #improper_interface, "market_transfer_nft_origyn - end date cannot be before start date", ?caller));
              };
            };

            let start_price : Nat = if(auction_details.start_price == 0){
              1;
            } else {
              auction_details.start_price
            };

            switch(auction_details.buy_now){
              case(?buy_now){
                if(buy_now < start_price) return #err(Types.errors(?state.canistergeekLogger,  #improper_interface, "market_transfer_nft_origyn - buy now cannot be less than start price", ?caller));
              };
              case(_){};
            };

            switch(auction_details.buy_now, auction_details.reserve){
              case(?buy_now, ?reserve){
                if(buy_now < reserve) return #err(Types.errors(?state.canistergeekLogger,  #improper_interface, "market_transfer_nft_origyn - buy now cannot be less than reserve", ?caller));
              };
              case(_){};
            };

            var allow_list : ?Map.Map<Principal, Bool> = null;
            switch(auction_details.allow_list) {
              case(null){};
              case(?val){
                var new_list = Map.new<Principal, Bool>();
                
                for(thisitem in val.vals()){
                  Map.set<Principal, Bool>(new_list, Map.phash, thisitem, true);
                };
                allow_list := ?new_list;
              };
            };

            {
              reserve = auction_details.reserve; 
              buy_now = auction_details.buy_now; 
              token : MigrationTypes.Current.TokenSpec = auction_details.token;
              start_date : Int = start_date;
              start_price : Nat = start_price;
              end_date : Int  = switch(auction_details.ending){
                  case(#date(theDate)){theDate : Int};
                  case(#wait_for_quiet(details)){details.date : Int};
                };
              allow_list = allow_list;
              dutch = null;
              notify = [];
              fee_accounts = null;
              fee_schema = Types.metadata.__system_secondary_royalty;
            }
          };
          case(#ask(null)){
            {
              reserve = null; 
              buy_now = null; 
              token : MigrationTypes.Current.TokenSpec = NFTUtils.OGY();
              start_date : Int = state.get_time();
              start_price : Nat = 1;
              end_date : Int  = state.get_time() + NFTUtils.MINUTE_LENGTH;
              allow_list = null;
              dutch = null;
              notify = [];
              fee_accounts = null;
              fee_schema = Types.metadata.__system_secondary_royalty;
            }
          };
          case(#ask(?val)){
            //todo: This would be a good place to check the state.fee_deposit_balances for any fee_accounts that might be expected to make sure the seller still has the fees listed. We may wan to have some escape hatch such that if the amount is not there then the auction ends with the last highest bid or is cancled if no bid.  It will be easier for fixed auctions for us keep track of this.  We don't want to create a situation where a user creates an auction, we check for an expected fee and it is there, but then they with draw their fee_deposit and users are stuck bidding on an auction that can never settle.
            //I guess I need to lock their fee deposit from being withdrawn if they have any open auctions.
            //Rate will be interesting...we will likely have to calculate the max price they could sell for and force the buy_now to top out at that amount.

            let ret = switch(_get_ask_sale_detail(state, val, caller)){
              case(#ok(val)) val;
              case(#err(err)) return #err(err);
            };

            switch (ret.fee_accounts) {
              case (?fee_accounts) {
                let token_spec = if (fee_schema == Types.metadata.__system_ogy_fixed_royalty) {
                  NFTUtils.OGY();
                } else {
                  ret.token;
                };
                let fee_schema = ret.fee_schema;

                let tmp_locked_fees = Buffer.Buffer<(MigrationTypes.Current.Account, MigrationTypes.Current.TokenSpec, Nat)>(5);
                // check if fund are provisioned by #fee_deposit
                for ((royalties_name, account) in fee_accounts.vals()) {
                  switch (lock_token_fee_balance(state, {
                    account = account; 
                    token = token_spec;
                    token_to_lock = 0; //TODO need fixed fees here, this feature is not available for no-fixed fees
                    sale_id = sale_id;
                  })) {
                    case (#ok(val)) {
                      tmp_locked_fees.add(account, token_spec, fees);
                    };
                    case (#err(err)) {
                      for ((_account, _token_spec, fees) in tmp_locked_fees.vals()) {
                        let _ = unlock_token_fee_balance(state, {
                          account = _account; 
                          token = _token_spec;
                          sale_id = sale_id;
                        });
                      };
                      return #err(Types.errors(?state.canistergeekLogger,  #low_fee_balance, "market_transfer_nft_origyn low_fee_balance", ?caller));
                    };
                  };
                };
                ret;
              };
              case (null) {ret};
            };
          };
          
          case(_) return #err(Types.errors(?state.canistergeekLogger,  #nyi, "market_transfer_nft_origyn nyi pricing type", ?caller));
        };

        let kyc_result = try{
          await* KYC.pass_kyc_seller(state, {
            seller = owner;
            buyer = #extensible(#Option(null));
            amount = 0;
            account_hash = null;
            token_id = request.token_id;
            lock_to_date = null;
            sale_id = null;
            token = token;
          }, caller);
        } catch(e){
          return #err(Types.errors(?state.canistergeekLogger,  #kyc_error, "market_transfer_nft_origyn seller kyc failed " # Error.message(e), ?caller))
        };

        switch(kyc_result){
          case(#ok(val)){

            if(val.result.kyc == #Fail or val.result.aml == #Fail){
              
              return #err(Types.errors(?state.canistergeekLogger,  #kyc_fail, "market_transfer_nft_origyn kyc or aml failed " # debug_show(val), ?caller));
            };
            
            //amount doesn't matter for seller
            

          };
          case(#err(err)){
            return #err(Types.errors(?state.canistergeekLogger,  err.error, "market_transfer_nft_origyn auto try kyc failed " # err.flag_point, ?caller))
          };
        };        

        var participants = Map.new<Principal, Int>();
        Map.set<Principal, Int>(participants, Map.phash, caller, state.get_time());

        let new_auction : MigrationTypes.Current.AuctionState = {
            config = MigrationTypes.Current.pricing_shared_to_pricing(request.sales_config.pricing);
            var current_bid_amount = 0;
            var current_broker_id = request.sales_config.broker_id;
            var end_date = end_date;
            var start_date : Int = start_date;
            var min_next_bid = start_price;
            var current_escrow = null;
            var wait_for_quiet_count = ?0;
            seller = owner;
            token = token;
            var notify_queue = if(notify.size() ==0){
              null;
            } else {
              var newQueue = Deque.empty<(Principal, ?MigrationTypes.Current.SubscriptionID)>();

              ignore Array.map<Principal, (Principal, ?MigrationTypes.Current.SubscriptionID)>(notify, func(x : Principal){
                newQueue := Deque.pushBack<(Principal, ?MigrationTypes.Current.SubscriptionID)>(newQueue, (x,null));
                (x,null);
              });

              ?newQueue;
            };
            var status = if(state.get_time() >= start_date){
                #open;
            } else {
                #not_started;
            };
            var winner = null;
            allow_list = allow_list;
            var participants = participants
          };

        Map.set<Text,Types.SaleStatus>(state.state.nft_sales, Map.thash, sale_id, {
          sale_id = sale_id;
          original_broker_id = request.sales_config.broker_id;
          broker_id = null; //currently the broker id for a auction doesn't do much. perhaps it should split the broker reward?
          token_id = request.token_id;
          sale_type = #auction(new_auction)
        });

        
        debug if(debug_channel.market) D.print("Setting sale id");
        metadata := Metadata.set_system_var(metadata, Types.metadata.__system_current_sale_id, #Text(sale_id));

        Map.set(state.state.nft_metadata, Map.thash, request.token_id, metadata);


        let txn = Metadata.add_transaction_record(state, {
            token_id = request.token_id;
            index = 0;
            timestamp = state.get_time();
            txn_type = #sale_opened({
                sale_id = sale_id;
                pricing = request.sales_config.pricing;
                extensible = #Option(null);});
        }, caller

        );

        


        //set timer for notify
        if(notify.size() > 0){
          //handle notify
          Set.add(state.state.pending_sale_notifications, thash, sale_id);
          if(state.notify_timer.get() == null){
            state.notify_timer.set(?Timer.setTimer(#nanoseconds(1), state.handle_notify ));
          }
        };

        //set timer for dutch
        switch(dutch){
          case(?dutch){
            debug if(debug_channel.dutch) D.print("dutch auction was submitted");
          };
          case(null){};
        };

        return txn;
    };

    private func _get_ask_sale_detail(state: StateAccess, val: [Types.AskFeature], caller: Principal) : Result.Result<{
          reserve : ?Nat; 
          buy_now : ?Nat; 
          token : MigrationTypes.Current.TokenSpec;
          start_date: Int;
          start_price: Nat;
          end_date: Int;
          dutch : ?MigrationTypes.Current.DutchParams;
          allow_list : ?Map.Map<Principal, Bool>;
          notify : [Principal];
          fee_accounts: ?MigrationTypes.Current.FeeAccountsParams;
          fee_schema : Text;
        }, Types.OrigynError>{
      //what does an escrow reciept do for an auction? Place a bid?
            //for now ignore

            let ask_details = MigrationTypes.Current.features_to_map(val);
            
            let start_date : Int = switch(Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #start_date)){
              case(?#start_date(val)) val;
              case(_) state.get_time();
            };

            let dutch = switch(Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #dutch)){
              case(?#dutch(val)){
                ?val;
              };
              case(_){null};
            };

            let start_price : Nat = switch(Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #start_price)){
              case(?#start_price(val)) val;
              case(_) {
                switch(dutch){
                  case(null) 1;
                  case(?val){
                    return #err(Types.errors(?state.canistergeekLogger,  #improper_interface, "market_transfer_nft_origyn - dutch auctions require a start price", ?caller));
                  };
                };
              }; //todo: calculate the minimum price for the token
            };

            let end_date : Int = switch(Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #ending)){
              case(?#ending(val)){
                switch(val){
                  case(#date(val)){
                    if(val <= start_date) return #err(Types.errors(?state.canistergeekLogger,  #improper_interface, "market_transfer_nft_origyn - end date cannot be before start date", ?caller));
                    val : Int;
                  };
                  case(#timeout(val)){
                    let target_end_date : Int = state.get_time() + val;
                    if(target_end_date <= start_date) return #err(Types.errors(?state.canistergeekLogger,  #improper_interface, "market_transfer_nft_origyn - end date cannot be before start date", ?caller));
                    target_end_date;
                  };
                };
              };
              case(_){
                //default length of an sale is one minute
                (state.get_time() + NFTUtils.MINUTE_LENGTH) : Int;
              };
            };

            let buy_now = switch(Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #buy_now)){
              case(?#buy_now(val)){
                if(val < start_price) return #err(Types.errors(?state.canistergeekLogger,  #improper_interface, "market_transfer_nft_origyn - buy now cannot be less than start price", ?caller));
                ?val;
              };
              case(_){null};
            };

            let reserve = switch(Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #reserve)){
              case(?#reserve(val)){
                ?val;
              };
              case(_){null};
            };

            let fee_accounts = switch(Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #fee_accounts)){
              case(?#fee_accounts(val)){
                ?val;
              };
              case(_){null};
            }; 

            let fee_schema : Text = switch(Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #fee_schema)){
              case(?#fee_schema(val)){
                val;
              };
              case(_){ Types.metadata.__system_secondary_royalty };
            }; 

            let token : MigrationTypes.Current.TokenSpec= switch(Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #token)){
              case(?#token(val)){
                val;
              };
              case(_){
                NFTUtils.OGY();
              };
            };

            let notify : [Principal]= switch(Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #notify)){
              case(?#notify(val)){
                val;
              };
              case(_){
                [];
              };
            };

            switch(buy_now, reserve){
              case(?buy_now, ?reserve){
                if(buy_now < reserve) return #err(Types.errors(?state.canistergeekLogger,  #improper_interface, "market_transfer_nft_origyn - buy now cannot be less than reserve", ?caller));
              };
              case(_){};
            };

            let allow_list : Map.Map<Principal, Bool> = Map.new<Principal, Bool>();

            switch(Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #allow_list)){
              case(?#allow_list(val)){
                for(thisitem in val.vals()){
                  Map.set<Principal, Bool>(allow_list, Map.phash, thisitem, true);
                };
              };
              case(_){};
            };

            #ok({
              reserve = reserve; 
              buy_now = buy_now; 
              token : MigrationTypes.Current.TokenSpec = token;
              start_date : Int = start_date;
              start_price : Nat = start_price;
              end_date : Int  = end_date;
              dutch = dutch;
              fee_accounts = fee_accounts;
              fee_schema = fee_schema;
              allow_list = if(Map.size(allow_list) == 0){
                null;
              } else {
                ?allow_list;
              };
              notify = notify;
            });
    };

    public func handle_notify(state: StateAccess) : async (){ 

      debug if(debug_channel.notifications) D.print("in handle_notify");

      //let this be scheduled again;
      state.notify_timer.set(null);

      label search for(thisItem in Set.keys(state.state.pending_sale_notifications)){
        debug if(debug_channel.notifications) D.print("in loop " # thisItem);
        let {notify; sale; notify_queue;} = switch(Map.get<Text, Types.SaleStatus>(state.state.nft_sales, thash, thisItem)){
          case(null){
            //should be unreachable, but lets remove it from the map anyway;
            ignore Set.remove(state.state.pending_sale_notifications,thash, thisItem);
            continue search;
          };
          case(?sale){
            let (#auction(sale_type)) = sale.sale_type else continue search;
            //make sure the sale is still open
            if(sale_type.status == #closed){
              debug if(debug_channel.notifications) D.print("removing because the sale is closed " # thisItem);
              ignore Set.remove(state.state.pending_sale_notifications,thash, thisItem);
                  continue search;
            };


            let ?notify_queue = sale_type.notify_queue else{
              //should be unreachable, but lets remove it from the map anyway;
              ignore Set.remove(state.state.pending_sale_notifications,thash, thisItem);
              continue search;
            } ;

            if(Deque.isEmpty<(Principal, ?MigrationTypes.Current.SubscriptionID)>(notify_queue)){
              ignore Set.remove<Text>(state.state.pending_sale_notifications, MapUtil.thash, thisItem);
              continue search;
            };

            debug if(debug_channel.notifications) D.print("popping the notify que:" # debug_show(notify_queue));

            let ?item = Deque.popFront<(Principal, ?MigrationTypes.Current.SubscriptionID)>(notify_queue) else{
              //should be unreachable, but lets remove it from the map anyway;
              ignore Set.remove<Text>(state.state.pending_sale_notifications, MapUtil.thash, thisItem);
              continue search;
            };

            sale_type.notify_queue := ?item.1;

            debug if(debug_channel.notifications) D.print("after the pop:" # debug_show(sale_type.notify_queue));

            {
              notify =  item.0;
              sale = sale;
              notify_queue = item.1;
            };
          };
        };

        let #ok(sale_state) = NFTUtils.get_auction_state_from_status(sale) else{
              //should be unreachable, but lets remove it from the map anyway;
              ignore Set.remove(state.state.pending_sale_notifications,thash, thisItem);
              continue search;
            };

        let #ok(owner) = Metadata.get_nft_owner_by_id(state, sale.token_id) else {
          ignore Set.remove(state.state.pending_sale_notifications,thash, thisItem);
              continue search;
        };

        let remote : Types.Subscriber = actor(Principal.toText(notify.0));
        debug if(debug_channel.notifications) D.print("about to send");
        remote.notify_sale_nft_origyn({
          escrow_info = NFTUtils.get_escrow_account_info({
            amount = sale_state.min_next_bid;
            seller = owner;
            buyer = #principal(notify.0);
            token_id = sale.token_id;
            token = sale_state.token;
          }, state.canister());
          sale = {sale with
            sale_type = switch(sale.sale_type){
              case(#auction(val)){
                  #auction(Types.AuctionState_stabalize_for_xfer(val))
              };
              /* case(_){
                  return #err(Types.errors(?state.canistergeekLogger,  #sale_not_found, "sale_status_nft_origyn not an auction ", ?caller));
              }; */
            };
          };
          seller = owner;
          token_id = sale.token_id;
          collection = state.canister();
        });

        

        if(Deque.isEmpty<(Principal, ?MigrationTypes.Current.SubscriptionID)>(notify_queue)){
          debug if(debug_channel.notifications) D.print("finished with this sale:" # thisItem);
          ignore Set.remove(state.state.pending_sale_notifications,thash, thisItem);
        } else {
          debug if(debug_channel.notifications) D.print("this sale is not finished:" # debug_show(notify_queue));
        };

        continue search;
      };

      if(Set.size(state.state.pending_sale_notifications) > 0){
        //set the timer to run again in 1 second;
        debug if(debug_channel.notifications) D.print("resetting the timer left:" # debug_show(Set.size(state.state.pending_sale_notifications)));
        state.notify_timer.set(?Timer.setTimer(#nanoseconds(1000000000), state.handle_notify));
      };

    };

    public func calc_dutch_price(state: StateAccess, auction: Types.AuctionState) : Types.AuctionState{
      //make sure the sale is still open
      if(auction.status == #closed){
        debug if(debug_channel.dutch) D.print("sale is closed. returning final price ");
        return auction;
      };

      let config = switch(auction.config){
        case(#ask(?val)){

            switch(_get_ask_sale_detail(state, Iter.toArray<MigrationTypes.Current.AskFeature>(Map.vals<MigrationTypes.Current.AskFeatureKey, MigrationTypes.Current.AskFeature>(val)), state.canister())){
              case(#ok(val)) val;
              case(#err(err)) {
                //should be unreachable;
                debug if(debug_channel.dutch) D.print("dutch price requested for non-dutch sale - error " # err.flag_point);
                return auction;
              };
            };
        };
        case(_) {
          //should be unreachable
          debug if(debug_channel.dutch) D.print("dutch price requested for non-dutch sale");
          return auction;
        }
      };

      let ?dutch = config.dutch else {
        //should be unreachable, 
        debug if(debug_channel.dutch) D.print("dutch price requested but dutch not configured");
        return auction;
      };

      let start_price : Nat = config.start_price;
      
      debug if(debug_channel.dutch) D.print("start price is " # debug_show(start_price));

      let reserve = switch(config.reserve){
        case(null) 1;
        case(?val) val;
      };

      debug if(debug_channel.dutch) D.print("reserve price is " # debug_show(reserve));

      if(state.get_time() < auction.start_date){
        debug if(debug_channel.dutch) D.print("dutch price requested but auction isn't open yet");
        return auction;
      };

      let time_diff = Int.abs(state.get_time() - auction.start_date);

      debug if(debug_channel.dutch) D.print("time_diff is " # debug_show((time_diff,NFTUtils.MINUTE_LENGTH )));

      let reduction_cycles : Nat = switch(dutch.time_unit){
        case(#minute(val)){
          debug if(debug_channel.dutch) D.print("minute " # debug_show(val));
          time_diff / (NFTUtils.MINUTE_LENGTH * val);
        };
        case(#hour(val)){
          debug if(debug_channel.dutch) D.print("hour " # debug_show(val));
          time_diff / (NFTUtils.HOUR_LENGTH * val);
        };
        case(#day(val)){
          debug if(debug_channel.dutch) D.print("day " # debug_show(val));
          time_diff / (NFTUtils.DAY_LENGTH * val);
        };
      };

      debug if(debug_channel.dutch) D.print("reduction_cycles is " # debug_show(reduction_cycles));

      let new_price : Nat = switch(dutch.decay_type){
        case(#flat(val)){
          debug if(debug_channel.dutch) D.print("flat price reduction " # debug_show(val));
          if(start_price > (val * reduction_cycles)){
            (start_price - (val * reduction_cycles));
          } else {
            ///it should be the reserve price
            reserve;
          };
        };
        case(#percent(val)){
          debug if(debug_channel.dutch) D.print("percent price reduction " # debug_show(val));
          var thisLoop = 0;
          let currentPrice : Float = Float.fromInt(start_price) * ((1 - val) ** Float.fromInt(reduction_cycles));
          Int.abs(Float.toInt(currentPrice));
        };
      };

      debug if(debug_channel.dutch) D.print("new price " # debug_show(new_price));

      //make sure price is not less than minimum valid price
      let final_price = if(new_price < reserve){
        debug if(debug_channel.dutch) D.print("below reserve " # debug_show(reserve));
        reserve;
      } else {
        new_price;
      };

      {
        auction with
        var current_bid_amount = auction.current_bid_amount;
        var current_broker_id = auction.current_broker_id;
        var end_date = auction.end_date;
        var start_date = auction.start_date;
        var min_next_bid = final_price;
        var current_escrow = auction.current_escrow;
        var wait_for_quiet_count = auction.wait_for_quiet_count;
        var participants = auction.participants;
        var status = auction.status;
        var winner = auction.winner;
        var notify_queue = auction.notify_queue;
      };
    };

    /* public func handle_dutch(state: StateAccess) : async (){ 

      debug if(debug_channel.dutch) D.print("in handle_dutch");

      //let this be scheduled again;

      var min_diff : Int = 0;

      label search for(thisItem in Set.keys(state.state.pending_sale_dutch)){
        switch(Map.get<Text, Types.SaleStatus>(state.state.nft_sales, thash, thisItem)){
          case(null){
            //should be unreachable, but lets remove it from the map anyway;
            ignore Set.remove(state.state.pending_sale_notifications,thash, thisItem);
            continue search;
          };
          case(?sale){
            let (#auction(sale_type)) = sale.sale_type else continue search;
            //make sure the sale is still open
            if(sale_type.status == #closed){
              debug if(debug_channel.dutch) D.print("sale is closed. will be removed " # thisItem);
              ignore Set.remove(state.state.pending_sale_notifications,thash, thisItem);
                  continue search;
            };

            //we should set the new price
            debug if(debug_channel.dutch) D.print("updateing the price");
            sale_type.min_next_bid := next_dutch_timer.0;

            let config = switch(sale_type.config){
              case(#ask(?val)){
                  switch(_get_ask_sale_detail(state, Iter.toArray<MigrationTypes.Current.AskFeature>(Map.vals<MigrationTypes.Current.AskFeatureKey, MigrationTypes.Current.AskFeature>(val)), state.canister())){
                    case(#ok(val)) val;
                    case(#err(err)) {
                      //should be unreachable, but lets remove it from the map anyway;
                      ignore Set.remove(state.state.pending_sale_notifications,thash, thisItem);
                      continue search;
                    };
                  };
              };
              case(_) {
                //should be unreachable, but lets remove it from the map anyway;
                ignore Set.remove(state.state.pending_sale_notifications,thash, thisItem);
                continue search;
              }
            };

            

            let ?dutch = config.dutch else {
              //should be unreachable, but lets remove it from the map anyway;
              ignore Set.remove(state.state.pending_sale_notifications,thash, thisItem);
              continue search;
            };
       
            let next_timer_set = switch(dutch.time_unit){
              case(#minute(val)){
                val * NFTUtils.MINUTE_LENGTH
              };
              case(#hour(val)){
                val * NFTUtils.HOUR_LENGTH
              };
              case(#day(val)){
                val * NFTUtils.DAY_LENGTH
              };
            };

            let reduction_amount = switch(dutch.decay_type){
              case(#flat(val))val;
              case(#percent(val)){
                 Int.abs(Float.toInt((Float.fromInt(sale_type.min_next_bid) * val)));
              };
            };

            let next_price = 
                if(sale_type.min_next_bid > reduction_amount){
                  Nat.sub(sale_type.min_next_bid, reduction_amount);
                } else {
                  switch(config.reserve){
                    case(null) 1;
                    case(?val) val;
                  };
                };
          };
        };
        continue search;
      };

      if(Set.size(state.state.pending_sale_dutch) > 0){
        //set the timer to run again in the min diff
        debug if(debug_channel.notifications) D.print("resetting the timer left:" # debug_show(Set.size(state.state.pending_sale_notifications)));
        state.dutch_timer.set(?(Timer.setTimer(#nanoseconds(Int.abs(min_diff)), state.handle_dutch), state.get_time() + min_diff));
      };
    }; */

    //refreshes the offers collection
    public func refresh_offers_nft_origyn(state: StateAccess, request: ?Types.Account, caller: Principal) : Types.ManageSaleResult{
        
      let seller = switch(request){
          case(null){
              #principal(caller);
          };
          case(?val){
              if(Types.account_eq(#principal(caller), val)){val;} 
              else {
                  if(NFTUtils.is_owner_manager_network(state, caller) == false){return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "refresh_offerns_nft_origyn - not an owner", ?caller))};
                  val;
              };
          }
      };

      let offers = Map.get<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, account_handler, seller);
      let offer_results = Buffer.Buffer<Types.EscrowRecord>(1);

      
      debug if(debug_channel.offers) D.print("trying refresh");
      
      switch(offers){
        case(null){};
        case(?found_offer){
            
          for(this_buyer in Map.entries<Types.Account, Int>(found_offer)){
            var b_keep = false;
            switch(Map.get<Types.Account, MigrationTypes.Current.EscrowSellerTrie>(state.state.escrow_balances, account_handler,this_buyer.0)){
              case(null){};
              case(?found_buyer){
                switch(Map.get<Types.Account, MigrationTypes.Current.EscrowTokenIDTrie>(found_buyer, account_handler, seller)){
                  case(null){};
                  case(?found_seller){
                    for(this_token in Map.entries(found_seller)){
                      for(this_ledger in Map.entries(this_token.1)){
                        //nyi: maybe check for a 0 balance
                        debug if(debug_channel.offers) D.print("found bkeep" # debug_show(this_ledger));
                        b_keep := true;
                        offer_results.add(this_ledger.1);
                      };
                    };
                  };
                };
              };
            };
            if(b_keep == false){
                let clean = Map.delete<Types.Account, Int>(found_offer, account_handler, this_buyer.0);
                Map.set<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, account_handler, seller, found_offer);
            };
          };
        };
      };

      if(offer_results.size() == 0){
        Map.delete<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, account_handler, seller);
      };

      return #ok(#refresh_offers(Buffer.toArray(offer_results)));
    };

    //moves tokens from a deposit into an escrow
    public func escrow_nft_origyn(state: StateAccess, request : Types.EscrowRequest, caller: Principal) : async* Star.Star<Types.ManageSaleResponse,Types.OrigynError> {
        //can someone escrow for someone else? No. Only a buyer can create an escrow for themselves for now
        //we will also allow a canister/canister owner to create escrows for itself
        if(Types.account_eq(#principal(caller), request.deposit.buyer) == false and 
            Types.account_eq(#principal(caller), #principal(state.canister())) == false and
             Types.account_eq(#principal(caller), #principal(state.state.collection_data.owner)) == false and
               Array.filter<Principal>(state.state.collection_data.managers, func(item: Principal){item == caller}).size() == 0){
            return #err(#trappable(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "escrow_nft_origyn - escrow - buyer and caller do not match", ?caller)));
        };

        debug if(debug_channel.escrow) D.print("in escrow");
        debug if(debug_channel.escrow) D.print(debug_show(request));
        switch(request.lock_to_date){
            case(?val){
                if(val > state.get_time() *10){ // if an extra digit is fat fingered this will trip....gives 474 years in the future as the max
                    return #err(#trappable(Types.errors(?state.canistergeekLogger,  #improper_interface, "escrow_nft_origyn time lock should not be that far in the future", ?caller)));
                };
            };
            case(null){};
        };

        
        debug if(debug_channel.escrow) D.print(debug_show(state.canister()));

        //verify the token
        if(request.token_id != ""){
          let metadata = switch(Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)){
              case(#err(err)){
                  return #err(#trappable(Types.errors(?state.canistergeekLogger,  #token_not_found, "escrow_nft_origyn " # err.flag_point, ?caller)));
              };
              case(#ok(val)){val;};
          };

          let this_is_minted = Metadata.is_minted(metadata);
          if(this_is_minted == false){
              //cant escrow for an unminted item
              return #err(#trappable(Types.errors(?state.canistergeekLogger,  #token_not_found, "escrow_nft_origyn ", ?caller)));
          };

          let owner = switch(Metadata.get_nft_owner(metadata)){
            case(#err(err)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  err.error, "escrow_nft_origyn " # err.flag_point, ?caller)));
            case(#ok(val)) val;
          };

          //cant escrow for an owner that doesn't own the token
          if(owner != request.deposit.seller)
            return #err(#trappable(Types.errors(?state.canistergeekLogger,  #escrow_owner_not_the_owner, "escrow_nft_origyn cannot create escrow for item someone does not own", ?caller)));
        };

        //move the deposit to an escrow account
        debug if(debug_channel.escrow) D.print("verifying the deposit");
       
        let (trx_id : Types.TransactionID, account_hash : ?Blob) = switch(request.deposit.token){
          case(#ic(token)){
            switch(token.standard){
              case(#Ledger or #ICRC1){
                debug if(debug_channel.escrow) D.print("found ledger");
                let checker = Ledger_Interface.Ledger_Interface();
                switch(await* checker.transfer_deposit(state.canister(), request,  caller)){
                  case(#ok(val)) (val.transaction_id, ?val.subaccount_info.account.sub_account);
                  case(#err(err)) return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "escrow_nft_origyn " # err.flag_point, ?caller)));
                };
              };
              case(_) return #err(#awaited(Types.errors(?state.canistergeekLogger,  #nyi, "escrow_nft_origyn - ic type nyi - " # debug_show(request), ?caller)));
            };
          };
          case(#extensible(val)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "escrow_nft_origyn - extensible token nyi - " # debug_show(request), ?caller)));
        };

        //put the escrow
        debug if(debug_channel.escrow) D.print("putting the escrow");
        let escrow_result = put_escrow_balance(state, {
          request.deposit with
          token_id = request.token_id;
          trx_id = trx_id;
          lock_to_date = request.lock_to_date;
          account_hash = account_hash;
          balances = null;
          }, true);

        debug if(debug_channel.escrow) D.print(debug_show(escrow_result));
        

        //add deposit transaction
        let new_trx = switch(Metadata.add_transaction_record(state,{
          token_id = request.token_id;
          index = 0;
          txn_type = #escrow_deposit {
            request.deposit with 
            token_id = request.token_id;
            trx_id = trx_id;
            extensible = #Option(null);
          };
          timestamp = state.get_time();
        }, caller)) {
          case(#err(err)){
            debug if(debug_channel.escrow) D.print("in a bad error");
            debug if(debug_channel.escrow) D.print(debug_show(err));
            //nyi: this is really bad and will mess up certificatioin later so we should really throw
            return #err(#awaited(Types.errors(?state.canistergeekLogger,  #nyi, "escrow_nft_origyn - extensible token nyi - " # debug_show(request), ?caller)));
          };
          case(#ok(new_trx)) new_trx;
        };

        debug if(debug_channel.escrow) D.print("have the trx");
        debug if(debug_channel.escrow) D.print(debug_show(new_trx));
        return #awaited(#escrow_deposit({
          receipt = {
            request.deposit with 
            token_id = request.token_id;
          };
          balance = escrow_result.amount;
          transaction = new_trx;
        }));
    };

    //recognizes tokens sent to a fee_deposit account
    public func deposit_fee_nft_origyn(state: StateAccess, request : Types.FeeDepositRequest, caller: Principal) : async* Star.Star<Types.ManageSaleResponse,Types.OrigynError> {
        //account owner, canister, manager, collection owner can all call this
        if(Types.account_eq(#principal(caller), request.account) == false and 
            Types.account_eq(#principal(caller), #principal(state.canister())) == false and
             Types.account_eq(#principal(caller), #principal(state.state.collection_data.owner)) == false and
               Array.filter<Principal>(state.state.collection_data.managers, func(item: Principal){item == caller}).size() == 0){
            return #err(#trappable(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "deposit_fee_nft_origyn - escrow - account and caller do not match", ?caller)));
        };

        debug if(debug_channel.escrow) D.print("in deposit_fee");
        debug if(debug_channel.escrow) D.print(debug_show(request));

        debug if(debug_channel.escrow) D.print(debug_show(state.canister()));

  
        debug if(debug_channel.escrow) D.print("verifying the deposit");
       
        let balance = switch(request.token){
          case(#ic(token)){
            switch(token.standard){
              case(#Ledger or #ICRC1){
                debug if(debug_channel.escrow) D.print("found ledger");
                let checker = Ledger_Interface.Ledger_Interface();
                switch(await* checker.fee_deposit_balance(state.canister(), request,  caller)){
                  case(#trappable(val)) (val.balance);
                  case(#awaited(val)) (val.balance);
                  case(#err(#awaited(err))) return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "deposit_fee_nft_origyn " # err.flag_point, ?caller)));
                  case(#err(#trappable(err))) return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "deposit_fee_nft_origyn " # err.flag_point, ?caller)));
                };
              };
              case(_) return #err(#awaited(Types.errors(?state.canistergeekLogger,  #nyi, "deposit_fee_nft_origyn - ic type nyi - " # debug_show(request), ?caller)));
            };
          };
          case(#extensible(val)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "deposit_fee_nft_origyn - extensible token nyi - " # debug_show(request), ?caller)));
        };

        //put the fee
        debug if(debug_channel.escrow) D.print("putting the escrow");

        let deposit_result = put_fee_deposit_balance(state, request, balance);

        debug if(debug_channel.escrow) D.print(debug_show(deposit_result));
        

        //add fee deposit transaction
        let new_trx = switch(Metadata.add_transaction_record(state,{
          token_id = "";
          index = 0;
          txn_type = #fee_deposit {
            request with 
            amount = balance;
            extensible = #Option(null);
          };
          timestamp = state.get_time();
        }, caller)) {
          case(#err(err)){
            debug if(debug_channel.escrow) D.print("in a bad error");
            debug if(debug_channel.escrow) D.print(debug_show(err));
            //nyi: this is really bad and will mess up certificatioin later so we should really throw
            return #err(#awaited(Types.errors(?state.canistergeekLogger,  #nyi, "deposit_fee_nft_origyn - extensible token nyi - " # debug_show(request), ?caller)));
          };
          case(#ok(new_trx)) new_trx;
        };

        return #awaited(#fee_deposit({
          balance = balance;
          transaction = new_trx;
        }));
    };

    public func ask_subscribe_nft_origyn(state: StateAccess, request: Types.AskSubscribeRequest, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {
      return #trappable(#ask_subscribe(false));
    };

    //recognizes tokens already at an escrow address but not yet recognized as an escrow - saves one fee
    //if this fails and there is a balance, it will attempt to refund it(we can't recognize misfiled escrows or the user may get access to something unplaned)
    public func recognize_escrow_nft_origyn(state: StateAccess, request : Types.EscrowRequest, caller: Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {

        //can someone escrow for someone else? No. Only a buyer can create an escrow for themselves for now
        //we will also allow a canister/canister owner to create escrows for itself
        if(Types.account_eq(#principal(caller), request.deposit.buyer) == false and 
            Types.account_eq(#principal(caller), #principal(state.canister())) == false and
             Types.account_eq(#principal(caller), #principal(state.state.collection_data.owner)) == false and
               Array.filter<Principal>(state.state.collection_data.managers, func(item: Principal){item == caller}).size() == 0){
            return #err(#trappable(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "recognize_escrow_nft_origyn - escrow - buyer and caller do not match", ?caller)));
        };

        debug if(debug_channel.escrow) D.print("in recognize");
        debug if(debug_channel.escrow) D.print(debug_show(request));
        switch(request.lock_to_date){
            case(?val){
                if(val > state.get_time() *10){ // if an extra digit is fat fingered this will trip....gives 474 years in the future as the max
                    return #err(#trappable(Types.errors(?state.canistergeekLogger,  #improper_interface, "recognize_escrow_nft_origyn time lock should not be that far in the future", ?caller)));
                };
            };
            case(null){};
        };

        
        debug if(debug_channel.escrow) D.print(debug_show(state.canister()));

        //verify the token
        if(request.token_id != ""){
          debug if(debug_channel.escrow) D.print(debug_show("We have a recognize request for token " # debug_show(request.token_id)));

          let metadata = switch(Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)){

              

              case(#err(err)){
                  debug if(debug_channel.escrow) D.print(debug_show("No metadata " # debug_show(err)));

                  return #err(#trappable(Types.errors(?state.canistergeekLogger,  #token_not_found, "recognize_escrow_nft_origyn " # err.flag_point # " " # debug_show(request), ?caller)));
              };
              case(#ok(val)){val;};
          };
          let this_is_minted = Metadata.is_minted(metadata);
          if(this_is_minted == false){
              //cant escrow for an unminted item
              debug if(debug_channel.escrow) D.print(debug_show("Not Minted " # debug_show(this_is_minted)));

              return #err(#trappable(Types.errors(?state.canistergeekLogger,  #token_not_found, "recognize_escrow_nft_origyn ", ?caller)));
          };

          let owner = switch(Metadata.get_nft_owner(metadata)){
            case(#err(err)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  err.error, "recognize_escrow_nft_origyn " # err.flag_point, ?caller)));
            case(#ok(val)) val;
          };

          //cant escrow for an owner that doesn't own the token
          if(owner != request.deposit.seller)
            return #err(#trappable(Types.errors(?state.canistergeekLogger,  #escrow_owner_not_the_owner, "recognize_escrow_nft_origyn cannot create escrow for item someone does not own", ?caller)));
        };

        let search = find_escrow_asset_map(state, {request.deposit with token_id = request.token_id});

        //we delete the escrow if it exists to protect from any spending while we are updating
        let old_balance = switch(search.balance){
              case(null){
               //if it doesn't exist...this is fine.
               null;
              };
              case(?val){
                
                if(val.amount >= request.deposit.amount){
                  //if an escrow already exists for more than the request we should noop
                  return #trappable(#recognize_escrow({
                    receipt = val;
                    balance = val.amount;
                    transaction = null;
                  })); 
                };

                debug if(debug_channel.market) D.print("should be deleting escrow" # debug_show((val.token)));
                let ?asset_list = search.asset_list else return #err(#trappable(Types.errors(?state.canistergeekLogger,  #unreachable, "retrieve escrow reached state that should be unreachable", ?caller))); 
                Map.delete(asset_list, token_handler, val.token);
                ?val;
              };
            };



        //check the balance
        debug if(debug_channel.escrow) D.print("checking the balance");
       
        let (balance : Nat, account_hash : ?Blob) = switch(request.deposit.token){
          case(#ic(token)){
            switch(token.standard){
              case(#Ledger or #ICRC1){
                debug if(debug_channel.escrow) D.print("found ledger");
                let checker = Ledger_Interface.Ledger_Interface();
                switch(Star.toResult<{balance: Nat; subaccount_info: Types.SubAccountInfo}, Types.OrigynError>(await* checker.escrow_balance(state.canister(), request,  caller))){
                  case(#ok(val)){
                     debug if(debug_channel.escrow) D.print("found balance" # debug_show(val));
                    (val.balance, ?val.subaccount_info.account.sub_account);
                  }; 
                  case(#err(err)) {
                    //this has failed so put the old escrow back if it existed;
                    switch(old_balance){
                      case(null){};
                      case(?val){
                        let ?asset_list = search.asset_list else return #err(#awaited(Types.errors(?state.canistergeekLogger,  #unreachable, "retrieve escrow reached state that should be unreachable", ?caller))); 
                        ignore Map.put(asset_list, token_handler, val.token, val);
                      };
                    };
                    
                    return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "recognize_escrow_nft_origyn " # err.flag_point, ?caller)))};
                };
              };
              case(_) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "recognize_escrow_nft_origyn - ic type nyi - " # debug_show(request), ?caller)));
            };
          };
          case(#extensible(val)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "recognize_escrow_nft_origyn - extensible token nyi - " # debug_show(request), ?caller)));
        };

        switch(old_balance){
          case(?old_balance){
            if(balance >= old_balance.amount and balance > 0){
              //should result in a no-op as we already recognized a blanace with higher amount...put it back
              let ?asset_list = search.asset_list else return #err(#awaited(Types.errors(?state.canistergeekLogger,  #unreachable, "retrieve escrow reached state that should be unreachable", ?caller))); 
              ignore Map.put(asset_list, token_handler, old_balance.token, old_balance);
              return #err(#awaited(Types.errors(?state.canistergeekLogger,  #noop, "recognize_escrow_nft_origyn the new balance is less than an existing escrow", ?caller)))
            };
          };
  
          case(_){};
        };

        //put the escrow

        let new_trx = if(balance > 0){
          debug if(debug_channel.escrow) D.print("putting the escrow");
          let escrow_result = put_escrow_balance(state, {
            request.deposit with
            amount = balance;
            token_id = request.token_id;
            trx_id = 0;
            lock_to_date = request.lock_to_date;
            account_hash = account_hash;
            balances = null;
            }, true);

          debug if(debug_channel.escrow) D.print(debug_show(escrow_result));
          
          debug if(debug_channel.escrow) D.print("adding loaded from balance transaction" # debug_show(balance));
          //add deposit transaction
          switch(Metadata.add_transaction_record(state,{
            token_id = request.token_id;
            index = 0;
            txn_type = #escrow_deposit {
              buyer = request.deposit.buyer;
              seller = request.deposit.seller;
              token = request.deposit.token;
              amount = balance;
              token_id = request.token_id;
              trx_id = #extensible(#Text("loaded from balance"));
              extensible = #Option(null);
            };
            timestamp = state.get_time();
          }, caller)) {
            case(#err(err)){
              debug if(debug_channel.escrow) D.print("in a bad error");
              debug if(debug_channel.escrow) D.print(debug_show(err));
              //nyi: this is really bad and will mess up certificatioin later so we should really throw
              return #err(#awaited(Types.errors(?state.canistergeekLogger,  #nyi, "recognize_escrow_nft_origyn - extensible token nyi - " # debug_show(request), ?caller)));
            };
            case(#ok(new_trx)) new_trx;
          };
        } else {
          return #err(#awaited(Types.errors(?state.canistergeekLogger,  #no_escrow_found, "recognize_escrow_nft_origyn - balance doesn't exist in account- " # debug_show(request), ?caller)));
        };

        //todo: if the amount found was not large enough, should we try to refund?
        if(balance < request.deposit.amount){
          debug if(debug_channel.escrow) D.print("balance was less than request");
          var verified = switch(verify_escrow_receipt(state, {
              seller = request.deposit.seller;
              buyer = request.deposit.buyer;
              amount = balance;
              token = request.deposit.token;
              token_id = request.token_id;
            }, null, null)){
            case(#err(err)){
    

              debug if(debug_channel.escrow) D.print("verified failed" # debug_show(err));

              return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "recognize_escrow_nft_origyn we should have found the escrow we just created, but it wasn't there" # err.flag_point, ?caller)));
            };
            case(#ok(res)) res;
          };

          debug if(debug_channel.escrow) D.print("have verified" # debug_show(verified));

          if(balance > 0){
            debug if(debug_channel.escrow) D.print("attempthing refund because escrow is too small" # debug_show(verified));

            let refund_result =  await* refund_failed_bid(state, verified,  {
                seller = request.deposit.seller;
                buyer = request.deposit.buyer;
                amount = balance;
                token = request.deposit.token;
                token_id = request.token_id;
              },);

            debug if(debug_channel.escrow) D.print("refund result" # debug_show(refund_result));

            return #err(#awaited(Types.errors(?state.canistergeekLogger,  #escrow_not_large_enough, "escrow refunded because result was less than what was in the account" # debug_show(refund_result), ?caller)));
          };
        };

        return #awaited(#recognize_escrow({
          receipt = {
            request.deposit with 
            token_id = request.token_id;
          };
          balance = balance;
          transaction = ?new_trx;
        }));
    };

    /**
    * Withdraw or deposit funds to a specified account using the specified details.
    * @param {StateAccess} state - The state of the canister.
    * @param {Types.DepositWithdrawDescription} details - The details of the withdrawal or deposit.
    * @param {Principal} caller - The caller of the function.
    * @returns {async* Result.Result<Types.ManageSaleResponse,Types.OrigynError>} - The result of the operation which may contain an error.
    */
    private func _withdraw_deposit(state: StateAccess, withdraw: Types.WithdrawRequest, details: Types.DepositWithdrawDescription, caller : Principal) : async* Star.Star<Types.ManageSaleResponse,Types.OrigynError>{
      debug if(debug_channel.withdraw_deposit) D.print("in deposit withdraw");
      debug if(debug_channel.withdraw_deposit) D.print("an deposit withdraw");
      debug if(debug_channel.withdraw_deposit) D.print(debug_show(withdraw));
      if(caller != state.canister() and Types.account_eq(#principal(caller), details.buyer) == false){
        //cant withdraw for someone else
        return #err(#trappable(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "withdraw_nft_origyn - deposit - buyer and caller do not match" , ?caller)));
      };

      debug if(debug_channel.withdraw_deposit) D.print("about to verify");

      let deposit_account = NFTUtils.get_deposit_info(details.buyer, state.canister());

      //NFT-112
      let fee = switch(details.token){
        case(#ic(token)){
          let token_fee = Option.get(token.fee, 0);
          if(details.amount <= token_fee) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #withdraw_too_large, "withdraw_nft_origyn - deposit - withdraw fee is larger than amount" , ?caller)));
          token_fee;
        };
        case(_) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - deposit - extensible token nyi - " # debug_show(details), ?caller)));
      };

      //attempt to send payment
                          debug if(debug_channel.withdraw_deposit) D.print("sending payment" # debug_show((details.withdraw_to, details.amount, caller)));
      var transaction_id : ?{trx_id: Types.TransactionID; fee: Nat} = null;
      
      transaction_id := switch(details.token){
        case(#ic(token)){
          switch(token.standard){
            case(#Ledger or #ICRC1){
              //D.print("found ledger");
              let checker = Ledger_Interface.Ledger_Interface();

              debug if(debug_channel.withdraw_deposit) D.print("returning amount " # debug_show(details.amount, token.fee));
              
              try{
                switch(await* checker.send_payment_minus_fee(details.withdraw_to, token, details.amount, ?deposit_account.account.sub_account, caller)){
                  case(#ok(val)) ?val;
                  case(#err(err)) return #err(#awaited(Types.errors(?state.canistergeekLogger,  #escrow_withdraw_payment_failed, "withdraw_nft_origyn - deposit - ledger payment failed err branch " # err.flag_point # " " # debug_show((details.withdraw_to, token, details.amount, ?deposit_account.account.sub_account, caller)), ?caller)));

                };
              } catch (e){
                return #err(#awaited(Types.errors(?state.canistergeekLogger,  #escrow_withdraw_payment_failed, "withdraw_nft_origyn - deposit - ledger payment failed catch branch " # Error.message(e), ?caller)));
              };
            };
            case(_) return #err(#awaited(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - deposit - - ledger type nyi - " # debug_show(details), ?caller)));
          };
        };
        case(#extensible(val)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - deposit - -  token standard nyi - " # debug_show(details), ?caller)));
      };

      debug if(debug_channel.withdraw_deposit) D.print("succesful transaction :" # debug_show(transaction_id) # debug_show(details));

      switch(transaction_id){
        case(null) return #err(#awaited(Types.errors(?state.canistergeekLogger,  #escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow -  payment failed txid null" , ?caller)));
        case(?transaction_id){
          switch(Metadata.add_transaction_record(state,{
            token_id = "";
            index = 0;
            txn_type = #deposit_withdraw({
              details with 
              amount = Nat.sub(details.amount, transaction_id.fee);
              fee = transaction_id.fee;
              trx_id = transaction_id.trx_id;
              extensible = #Option(null);
            }
            );
            timestamp = state.get_time();
          }, caller)) {
            case(#ok(val)) return #awaited(#withdraw(val));
            case(#err(err))  return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "withdraw_nft_origyn - escrow - ledger not updated" # debug_show(transaction_id) , ?caller)));
          };
        };
      };

    };

    /**
    * Withdraw fee deposit funds to a specified account using the specified details.
    * @param {StateAccess} state - The state of the canister.
    * @param {Types.DepositWithdrawDescription} details - The details of the withdrawal or deposit.
    * @param {Principal} caller - The caller of the function.
    * @returns {async* Result.Result<Types.ManageSaleResponse,Types.OrigynError>} - The result of the operation which may contain an error.
    */
    private func _withdraw_fee_deposit(state: StateAccess, withdraw: Types.WithdrawRequest, details: Types.FeeDepositWithdrawDescription, caller : Principal) : async* Star.Star<Types.ManageSaleResponse,Types.OrigynError>{
      debug if(debug_channel.withdraw_deposit) D.print("in deposit withdraw");
      debug if(debug_channel.withdraw_deposit) D.print("an deposit withdraw");
      debug if(debug_channel.withdraw_deposit) D.print(debug_show(withdraw));
      if(caller != state.canister() and Types.account_eq(#principal(caller), details.account) == false){
        //cant withdraw for someone else
        return #err(#trappable(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "withdraw_nft_origyn - deposit - buyer and caller do not match" , ?caller)));
      };

      debug if(debug_channel.withdraw_deposit) D.print("about to verify");

      let deposit_account = NFTUtils.get_deposit_info(details.account, state.canister());

      //NFT-112
      let fee = switch(details.token){
        case(#ic(token)){
          let token_fee = Option.get(token.fee, 0);
          if(details.amount <= token_fee) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #withdraw_too_large, "withdraw_nft_origyn - deposit - withdraw fee is larger than amount" , ?caller)));
          token_fee;
        };
        case(_) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - deposit - extensible token nyi - " # debug_show(details), ?caller)));
      };

      //todo: check locks and makes sure that we are not transfering out a locked amount

      //attempt to send payment
                          debug if(debug_channel.withdraw_deposit) D.print("sending payment" # debug_show((details.withdraw_to, details.amount, caller)));
      var transaction_id : ?{trx_id: Types.TransactionID; fee: Nat} = null;
      
      transaction_id := switch(details.token){
        case(#ic(token)){
          switch(token.standard){
            case(#Ledger or #ICRC1){
              //D.print("found ledger");
              let checker = Ledger_Interface.Ledger_Interface();

              debug if(debug_channel.withdraw_deposit) D.print("returning amount " # debug_show(details.amount, token.fee));
              
              try{
                switch(await* checker.send_payment_minus_fee(details.withdraw_to, token, details.amount, ?deposit_account.account.sub_account, caller)){
                  case(#ok(val)) ?val;
                  case(#err(err)) return #err(#awaited(Types.errors(?state.canistergeekLogger,  #escrow_withdraw_payment_failed, "withdraw_nft_origyn - deposit - ledger payment failed err branch " # err.flag_point # " " # debug_show((details.withdraw_to, token, details.amount, ?deposit_account.account.sub_account, caller)), ?caller)));

                };
              } catch (e){
                return #err(#awaited(Types.errors(?state.canistergeekLogger,  #escrow_withdraw_payment_failed, "withdraw_nft_origyn - deposit - ledger payment failed catch branch " # Error.message(e), ?caller)));
              };
            };
            case(_) return #err(#awaited(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - deposit - - ledger type nyi - " # debug_show(details), ?caller)));
          };
        };
        case(#extensible(val)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - deposit - -  token standard nyi - " # debug_show(details), ?caller)));
      };

      debug if(debug_channel.withdraw_deposit) D.print("succesful transaction :" # debug_show(transaction_id) # debug_show(details));

      switch(transaction_id){
        case(null) return #err(#awaited(Types.errors(?state.canistergeekLogger,  #escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow -  payment failed txid null" , ?caller)));
        case(?transaction_id){
          switch(Metadata.add_transaction_record(state,{
            token_id = "";
            index = 0;
            txn_type = #fee_deposit_withdraw({
              details with 
              amount = Nat.sub(details.amount, transaction_id.fee);
              fee = transaction_id.fee;
              trx_id = transaction_id.trx_id;
              extensible = #Option(null);
            }
            );
            timestamp = state.get_time();
          }, caller)) {
            case(#ok(val)) return #awaited(#withdraw(val));
            case(#err(err))  return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "withdraw_nft_origyn - escrow - ledger not updated" # debug_show(transaction_id) , ?caller)));
          };
        };
      };

    };


    /**
    * Withdraws an asset from an escrow account and sends payment to the designated recipient.
    * @param {StateAccess} state - the state access object
    * @param {Types.WithdrawRequest} withdraw - the withdraw request object containing information about the asset being withdrawn
    * @param {Types.WithdrawDescription} details - the description of the withdrawal
    * @param {Principal} caller - the caller of the function
    * @returns {async* Result.Result<Types.ManageSaleResponse,Types.OrigynError>} - the result of the function execution
    */
    private func _withdraw_escrow(state: StateAccess, withdraw: Types.WithdrawRequest, details: Types.WithdrawDescription, caller : Principal) : async* Star.Star<Types.ManageSaleResponse,Types.OrigynError>{

      debug if(debug_channel.withdraw_escrow) D.print("an escrow withdraw");
      debug if(debug_channel.withdraw_escrow) D.print(debug_show(withdraw));
      if(caller != state.canister() and Types.account_eq(#principal(caller), details.buyer) == false) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "withdraw_nft_origyn - escrow - buyer and caller do not match" , ?caller)));

      debug if(debug_channel.withdraw_escrow) D.print("about to verify");
      
      let verified = switch(verify_escrow_receipt(state, details, null, null)){
        case(#err(err)){
          debug if(debug_channel.withdraw_escrow) D.print("an error");
          debug if(debug_channel.withdraw_escrow) D.print(debug_show(err));
          return #err(#trappable(Types.errors(?state.canistergeekLogger,  err.error, "withdraw_nft_origyn - escrow - - cannot verify escrow - " # debug_show(details), ?caller)));
        };
        case(#ok(verified)) verified;
      };

      let account_info = NFTUtils.get_escrow_account_info(verified.found_asset.escrow, state.canister());
      if(verified.found_asset.escrow.amount < details.amount){
        debug if(debug_channel.withdraw_escrow) D.print("in check amount " # debug_show(verified.found_asset.escrow.amount) # " " # debug_show( details.amount));
        return #err(#trappable(Types.errors(?state.canistergeekLogger,  #withdraw_too_large, "withdraw_nft_origyn - escrow - withdraw too large" , ?caller)));
      };

      let a_ledger = verified.found_asset.escrow;

      switch(a_ledger.lock_to_date){
        case(?val){
          debug if(debug_channel.withdraw_escrow) D.print("found a lock date " # debug_show((val, state.get_time())));
          if(state.get_time() < val) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #escrow_cannot_be_removed, "withdraw_nft_origyn - escrow - this escrow is locked until " # debug_show(val)  , ?caller)));
        };
        case(null){
          debug if(debug_channel.withdraw_escrow) D.print("no lock date " # debug_show(( state.get_time())));
        };
      };

      //NFT-112
      let fee = switch(details.token){
        case(#ic(token)){
            let token_fee = Option.get(token.fee, 0);
            if(a_ledger.amount <= token_fee) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #withdraw_too_large, "withdraw_nft_origyn - escrow - withdraw fee is larger than amount" , ?caller)));
            token_fee;
        };
        case(_) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - escrow - extensible token nyi - " # debug_show(details), ?caller)));
      };

      //D.print("got to sale id");

      switch(a_ledger.sale_id){
        case(?sale_id){
          //check that the owner isn't still the bidder in the sale
          let sale = switch(Map.get(state.state.nft_sales, Map.thash,sale_id)){
              case(null) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #sale_not_found, "withdraw_nft_origyn - escrow - can't find sale top" # debug_show(a_ledger) #  " " # debug_show(withdraw) , ?caller)));
              case(?sale) sale;
          };

          debug if(debug_channel.withdraw_escrow) D.print("testing current state");

          let current_sale_state = switch(NFTUtils.get_auction_state_from_status(sale)){
            case(#ok(val)) val;
            case(#err(err)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  err.error, "withdraw_nft_origyn - escrow - find state " # err.flag_point, ?caller)));
          };

          switch(current_sale_state.status){
            case(#open){

              debug if(debug_channel.withdraw_escrow) D.print(debug_show(current_sale_state));
              debug if(debug_channel.withdraw_escrow) D.print(debug_show(caller));

              //NFT-110
              switch(current_sale_state.winner){
                case(?val){
                  debug if(debug_channel.withdraw_escrow) D.print("found a winner");
                  if(Types.account_eq(val, details.buyer)){
                    debug if(debug_channel.withdraw_escrow) D.print("should be throwing an error");
                    return #err(#trappable(Types.errors(?state.canistergeekLogger,  #escrow_cannot_be_removed, "withdraw_nft_origyn - escrow - you are the winner" , ?caller)));
                  };
                };
                case(null){
                  debug if(debug_channel.withdraw_escrow) D.print("not a winner");
                };
              };

              //NFT-76
              switch(current_sale_state.current_escrow){
                case(?val){
                  debug if(debug_channel.withdraw_escrow) D.print("testing current escorw");
                  debug if(debug_channel.withdraw_escrow) D.print(debug_show(val.buyer));
                  if(Types.account_eq(val.buyer, details.buyer)){
                    debug if(debug_channel.withdraw_escrow) D.print("passed");
                    return #err(#trappable(Types.errors(?state.canistergeekLogger,  #escrow_cannot_be_removed, "withdraw_nft_origyn - escrow - you are the current bid" , ?caller)));
                  };
                };
                case(null){
                  debug if(debug_channel.withdraw_escrow) D.print("not a current escrow");
                };
              };
            };
            case(_){
                //it isn't open so we don't need to check
            };
          };
        };
        case(null){};
      };

      debug if(debug_channel.withdraw_escrow) D.print("finding target escrow");
      debug if(debug_channel.withdraw_escrow) D.print(debug_show(a_ledger.amount));
      debug if(debug_channel.withdraw_escrow) D.print(debug_show(details.amount));
      //ok...so we should be good to withdraw
      //first update the escrow
      if(verified.found_asset.escrow.amount < details.amount) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #escrow_cannot_be_removed, "withdraw_nft_origyn - escrow - amount too large ", ?caller)));
      
      let target_escrow = {
        details with 
        account_hash = verified.found_asset.escrow.account_hash;
        balances = null;
        amount = Nat.sub(verified.found_asset.escrow.amount, details.amount);
        sale_id = a_ledger.sale_id;
        lock_to_date = a_ledger.lock_to_date;
      };

      if(target_escrow.amount > 0){
        Map.set<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>(verified.found_asset_list, token_handler, details.token, target_escrow);
      } else {
        Map.delete<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>(verified.found_asset_list, token_handler, details.token);
      };

      //send payment
      //reentrancy risk so we remove the escrow value above before calling
      debug if(debug_channel.withdraw_escrow) D.print("sending payment" # debug_show((details.withdraw_to, details.amount, caller)));
      var transaction_id : ?{trx_id: Types.TransactionID; fee: Nat} = null;
      
      transaction_id := switch(details.token){
        case(#ic(token)){
          switch(token.standard){
            case(#Ledger or #ICRC1){
              //D.print("found ledger");
              let checker = Ledger_Interface.Ledger_Interface();

              debug if(debug_channel.withdraw_escrow) D.print("returning amount " # debug_show(details.amount, token.fee));
              
              try{
                switch(await* checker.send_payment_minus_fee(details.withdraw_to, token, details.amount, ?account_info.account.sub_account, caller)){
                  case(#ok(val)) ?val;
                  case(#err(err)){
                    handle_escrow_update_error(state, a_ledger, null, verified.found_asset, verified.found_asset_list);
                    return #err(#awaited(Types.errors(?state.canistergeekLogger,  #escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow - ledger payment failed err branch " # err.flag_point, ?caller)));
                  };
                };
              } catch (e){
                //put the escrow back because something went wrong
                handle_escrow_update_error(state, a_ledger, null, verified.found_asset, verified.found_asset_list);
                return #err(#awaited(Types.errors(?state.canistergeekLogger,  #escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow - ledger payment failed catch branch " # Error.message(e), ?caller)));
              };

            };
            case(_) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - escrow - - ledger type nyi - " # debug_show(details), ?caller)));
          };
        };
        case(#extensible(val)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - escrow - -  token standard nyi - " # debug_show(details), ?caller)));
      };

      debug if(debug_channel.withdraw_escrow) D.print("succesful transaction :" # debug_show(transaction_id) # debug_show(details));

      switch(transaction_id){
        case(null) return #err(#awaited(Types.errors(?state.canistergeekLogger,  #escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow -  payment failed txid null" , ?caller)));
        case(?transaction_id){
          switch(Metadata.add_transaction_record(state,{
            token_id = details.token_id;
            index = 0;
            txn_type = #escrow_withdraw({
              details with 
              amount = Nat.sub(details.amount,transaction_id.fee);
              fee = transaction_id.fee;
              trx_id = transaction_id.trx_id;
              extensible = #Option(null);
            }
            );
            timestamp = state.get_time();
          }, caller)) {
            case(#ok(val)) return #awaited(#withdraw(val));
            case(#err(err))  return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "withdraw_nft_origyn - escrow - ledger not updated" # debug_show(transaction_id) , ?caller)));
          };
        };
      };
    };



    /**
    * Withdraws a sale for a given token from the escrow and sends payment to the specified recipient.
    *
    * @param {StateAccess} state - The state access object.
    * @param {Types.WithdrawRequest} withdraw - The withdrawal request object.
    * @param {Types.WithdrawDescription} details - The withdrawal details object.
    * @param {Principal} caller - The caller of the function.
    * @returns {Types.ManageSaleResult} - A Result object that either contains a ManageSaleResponse or an OrigynError if the withdrawal failed.
    */
    private func _withdraw_sale(state: StateAccess, withdraw: Types.WithdrawRequest, details: Types.WithdrawDescription, caller : Principal) : async* Star.Star<Types.ManageSaleResponse,Types.OrigynError>{
      debug if(debug_channel.withdraw_sale) D.print("withdrawing a sale");
      debug if(debug_channel.withdraw_sale) D.print(debug_show(details));
      debug if(debug_channel.withdraw_sale) D.print(debug_show(caller));
      if(caller != state.canister() and Types.account_eq(#principal(caller), details.seller) == false) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "withdraw_nft_origyn - sales- buyer and caller do not match" # debug_show((#principal(caller), details.seller)) , ?caller)));

      let verified = switch(verify_sales_reciept(state, details)){
          case(#ok(verified)) verified;
          case(#err(err)){
                                  debug if(debug_channel.withdraw_sale) D.print("an error");
                                  debug if(debug_channel.withdraw_sale) D.print(debug_show(err));
              return #err(#trappable(Types.errors(?state.canistergeekLogger,  err.error, "withdraw_nft_origyn - sale - - cannot verify escrow - " # debug_show(details), ?caller)));
          };
      };
          
      debug if(debug_channel.withdraw_sale) D.print("have verified");

      if(verified.found_asset.escrow.amount < details.amount) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #withdraw_too_large, "withdraw_nft_origyn - sales - withdraw too large" , ?caller)));

      let a_ledger = verified.found_asset.escrow;

      debug if(debug_channel.withdraw_sale) D.print("a_ledger" # debug_show(a_ledger));

      let a_token_id = verified.found_asset_list;

      //NFT-112
      switch(details.token){
        case(#ic(token)){
            let token_fee = Option.get(token.fee, 0);
            if(a_ledger.amount <= token_fee){
              debug if(debug_channel.withdraw_sale) D.print("withdraw fee");
              return #err(#trappable(Types.errors(?state.canistergeekLogger,  #withdraw_too_large, "withdraw_nft_origyn - sales - withdraw fee is larger than amount" , ?caller)));
            };
        };
        case(_){
          debug if(debug_channel.withdraw_sale) D.print("nyi err");
          return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - sales - extensible token nyi - " # debug_show(details), ?caller)));
        };
      };

      
      debug if(debug_channel.withdraw_sale) D.print("finding target escrow");
      debug if(debug_channel.withdraw_sale) D.print(debug_show(a_ledger.amount));
      debug if(debug_channel.withdraw_sale) D.print(debug_show(details.amount));
      //ok...so we should be good to withdraw
      //first update the escrow
      if(verified.found_asset.escrow.amount < details.amount)return #err(#trappable(Types.errors(?state.canistergeekLogger,  #escrow_cannot_be_removed, "withdraw_nft_origyn - sale - amount too large ", ?caller)));

      let target_escrow = {
        a_ledger with 
        amount = Nat.sub(a_ledger.amount, details.amount);
      };

      if(target_escrow.amount > 0){
        Map.set<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>(a_token_id, token_handler, details.token, target_escrow);
      } else {
        Map.delete<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>(a_token_id, token_handler, details.token);
      };


      //send payment
      debug if(debug_channel.withdraw_sale) D.print("sending payment");
      var transaction_id : ?{trx_id: Types.TransactionID; fee: Nat} = null;
  
      transaction_id := switch(details.token){
        case(#ic(token)){
          switch(token.standard){
            case(#Ledger or #ICRC1){
                debug if(debug_channel.withdraw_sale) D.print("found ledger sale withdraw");
                let checker = Ledger_Interface.Ledger_Interface();
                //if this fails we need to put the escrow back
                try{
                  switch(await* checker.send_payment_minus_fee(details.withdraw_to, token, details.amount, a_ledger.account_hash, caller)){
                    case(#ok(val)) ?val;
                    case(#err(err)){
                        //put the escrow back
                        debug if(debug_channel.withdraw_sale) D.print("failed, putting back ledger");
                        
                        handle_sale_update_error(state, details, null, verified.found_asset, verified.found_asset_list);
                        return #err(#awaited(Types.errors(?state.canistergeekLogger,  #sales_withdraw_payment_failed, "withdraw_nft_origyn - sales ledger payment failed err branch" # err.flag_point, ?caller)));
                    };
                  };
                } catch(e){
                  //put the escrow back
                  handle_sale_update_error(state, details, null, verified.found_asset, verified.found_asset_list);
                  return #err(#awaited(Types.errors(?state.canistergeekLogger,  #sales_withdraw_payment_failed, "withdraw_nft_origyn - sales ledger payment failed catch branch" # Error.message(e), ?caller)));
                };
            };
            case(_){
              return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - sales - ledger type nyi - " # debug_show(details), ?caller)));
            };
          };
        };
        case(#extensible(val)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - sales - extensible token nyi - " # debug_show(details), ?caller)));
      };

      //D.print("have a transactionid and will crate a transaction");
      switch(transaction_id){
        case(null)return #err(#awaited(Types.errors(?state.canistergeekLogger,  #sales_withdraw_payment_failed, "withdraw_nft_origyn - sales  payment failed txid null" , ?caller)));
        case(?transaction_id){
            switch(Metadata.add_transaction_record(state,{
              token_id = details.token_id;
              index = 0;
              txn_type = #sale_withdraw({
                details with 
                amount = Nat.sub(details.amount, transaction_id.fee);
                fee = transaction_id.fee;
                trx_id = transaction_id.trx_id;
                extensible = #Option(null);
              }
              );
              timestamp = state.get_time();
            }, caller)) {
              case(#ok(val)) return #awaited(#withdraw(val));
              case(#err(err)) return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "withdraw_nft_origyn - sales ledger not updated" # debug_show(transaction_id) , ?caller)));
            };
        };
      };

    };

    /**
    * Rejects an offer and sends the tokens back to the source.
    * @param {StateAccess} state - The state access object.
    * @param {Types.WithdrawRequest} withdraw - The withdraw request object.
    * @param {Types.RejectDescription} details - The reject description object.
    * @param {Principal} caller - The caller principal.
    * @returns {async* Result.Result<Types.ManageSaleResponse,Types.OrigynError>} A Result type containing either a Types.ManageSaleResponse object or a Types.OrigynError object.
    */
    private func _reject_offer(state: StateAccess, withdraw: Types.WithdrawRequest, details: Types.RejectDescription, caller : Principal) : async* Star.Star<Types.ManageSaleResponse,Types.OrigynError>{
      // rejects and offer and sends the tokens back to the source
      debug if(debug_channel.withdraw_reject) D.print("an escrow reject");
      if(caller != state.canister() and Types.account_eq(#principal(caller), details.seller) == false and ?caller != state.state.collection_data.network){
        //cant withdraw for someone else
        debug if(debug_channel.withdraw_reject) D.print(debug_show((caller, state.canister(), details.seller, state.state.collection_data.network)));
        return #err(#trappable(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "withdraw_nft_origyn - reject - unauthorized" , ?caller)));
      };

      debug if(debug_channel.withdraw_reject) D.print("about to verify");

      let verified = switch(verify_escrow_receipt(state, {
          amount = 0;
          buyer = details.buyer;
          seller = details.seller;
          token  = details.token;
          token_id = details.token_id
      }, null, null)){
        case(#ok(verified)) verified;
        case(#err(err)){
          debug if(debug_channel.withdraw_reject) D.print("an error");
          debug if(debug_channel.withdraw_reject) D.print(debug_show(err));
          return #err(#trappable(Types.errors(?state.canistergeekLogger,  err.error, "withdraw_nft_origyn - escrow - - cannot verify escrow - " # debug_show(details), ?caller)));
        };
      };
        
      let account_info = NFTUtils.get_escrow_account_info(verified.found_asset.escrow, state.canister());

      let a_ledger = verified.found_asset.escrow;

      

      // reject ignores locked assets
      //NFT-112
      let fee = switch(details.token){
        case(#ic(token)){
          let token_fee = Option.get(token.fee, 0);
          if(a_ledger.amount <= token_fee) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #withdraw_too_large, "withdraw_nft_origyn - reject - withdraw fee is larger than amount" , ?caller)));
          token_fee;
        };
        case(_)return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - reject - extensible token nyi - " # debug_show(details), ?caller)));
      };

      debug if(debug_channel.withdraw_reject) D.print("got to sale id");

      switch(a_ledger.sale_id){
        case(?sale_id){
            //check that the owner isn't still the bidder in the sale
          switch(Map.get(state.state.nft_sales, Map.thash,sale_id)){
            case(null) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #sale_not_found, "withdraw_nft_origyn - reject - can't find sale top" # debug_show(a_ledger) #  " " # debug_show(withdraw) , ?caller)));
            case(?val){

              debug if(debug_channel.withdraw_reject) D.print("testing current state");

              let current_sale_state = switch(NFTUtils.get_auction_state_from_status(val)){
                  case(#ok(val)){val};
                  case(#err(err)){
                    return #err(#trappable(Types.errors(?state.canistergeekLogger,  err.error, "withdraw_nft_origyn - reject - find state " # err.flag_point, ?caller)));
                  };
              };

              switch(current_sale_state.status){
                case(#open){

                  debug if(debug_channel.withdraw_reject) D.print(debug_show(current_sale_state));
                  debug if(debug_channel.withdraw_reject) D.print(debug_show(caller));

                  //NFT-110
                  switch(current_sale_state.winner){
                    case(?val){
                      debug if(debug_channel.withdraw_reject) D.print("found a winner");
                      if(Types.account_eq(val, details.buyer)){
                        debug if(debug_channel.withdraw_reject) D.print("should be throwing an error");
                        return #err(#trappable(Types.errors(?state.canistergeekLogger,  #escrow_cannot_be_removed, "withdraw_nft_origyn - reject - you are the winner" , ?caller)));
                      };
                    };
                    case(null){
                      debug if(debug_channel.withdraw_reject) D.print("not a winner");
                    };
                  };

                  //NFT-76
                  switch(current_sale_state.current_escrow){
                    case(?val){
                      debug if(debug_channel.withdraw_reject) D.print("testing current escorw");
                      debug if(debug_channel.withdraw_reject) D.print(debug_show(val.buyer));
                      if(Types.account_eq(val.buyer, details.buyer)){
                        debug if(debug_channel.withdraw_reject)  D.print("passed");
                        return #err(#trappable(Types.errors(?state.canistergeekLogger,  #escrow_cannot_be_removed, "withdraw_nft_origyn - reject - you are the current bid" , ?caller)));
                      };
                    };
                    case(null){
                      debug if(debug_channel.withdraw_reject) D.print("not a current escrow");
                    };
                  };
                };
                case(_){
                    //it isn't open so we don't need to check
                };
              };
            };
          };
        };
        case(null){

        };
      };

      debug if(debug_channel.withdraw_reject) D.print("finding target escrow");
      debug if(debug_channel.withdraw_reject) D.print(debug_show(a_ledger.amount));
      
      //ok...so we should be good to withdraw
      //first update the escrow
      
      //deleteing the asset
      Map.delete(verified.found_asset_list, token_handler, details.token);

      //send payment
                          
      var transaction_id : ?{trx_id: Types.TransactionID; fee: Nat} = null;
      try{
        transaction_id := switch(details.token){
          case(#ic(token)){
            switch(token.standard){
              case(#Ledger or #ICRC1){
                //D.print("found ledger");
                let checker = Ledger_Interface.Ledger_Interface();

                debug if(debug_channel.withdraw_reject) D.print("returning amount " # debug_show(verified.found_asset.escrow.amount, token.fee));
                
                switch(await* checker.send_payment_minus_fee(details.buyer, token, verified.found_asset.escrow.amount, ?account_info.account.sub_account, caller)){
                  case(#ok(val)) ?val;
                  case(#err(err)){
                    //put the escrow back
                    //make sure things havent changed in the mean time
                    //D.print("failed, putting back ledger");
                    handle_escrow_update_error(state, a_ledger, null, verified.found_asset, verified.found_asset_list);
                    return #err(#awaited(Types.errors(?state.canistergeekLogger,  #escrow_withdraw_payment_failed, "withdraw_nft_origyn - reject - ledger payment failed" # err.flag_point, ?caller)));
                  };
                };

              };
              case(_){
                return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - reject - - ledger type nyi - " # debug_show(details), ?caller)));
              };
            };
          };
          case(#extensible(val)){
            return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn - reject - -  token standard nyi - " # debug_show(details), ?caller)));
          };
        };
      } catch (e){
        //something failed, put the escrow back
        //make sure it hasn't changed in the mean time
        //D.print("failed, putting back throw");
        handle_escrow_update_error(state, a_ledger, null, verified.found_asset, verified.found_asset_list);

        return #err(#awaited(Types.errors(?state.canistergeekLogger,  #escrow_withdraw_payment_failed, "withdraw_nft_origyn - reject -  payment failed" # Error.message(e) , ?caller)));
      };

      debug if(debug_channel.withdraw_reject) D.print("succesful transaction :" # debug_show(transaction_id) # debug_show(details));

      switch(transaction_id){
        case(null){
          //really should have failed already
          return #err(#awaited(Types.errors(?state.canistergeekLogger,  #escrow_withdraw_payment_failed, "withdraw_nft_origyn - transaction -  payment failed txid null" , ?caller)));
        };
        case(?transaction_id){
          switch(Metadata.add_transaction_record(state,{
            token_id = details.token_id;
            index = 0;
            txn_type = #escrow_withdraw({
              details with 
                amount = Nat.sub(verified.found_asset.escrow.amount,transaction_id.fee);
                fee = transaction_id.fee;
                trx_id = transaction_id.trx_id;
                extensible = #Option(null);
            }
            );
            timestamp = state.get_time();
          }, caller)) {
            case(#ok(val)){
              return #awaited(#withdraw(val));
            };
            case(#err(err)){
              return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "withdraw_nft_origyn - transaction - ledger not updated" # debug_show(transaction_id) , ?caller)));
            };
          };
        };
      };
    };


    //allows the user to withdraw tokens from an nft canister
    /**
    * Allows the user to withdraw tokens from an NFT canister.
    * @param {StateAccess} state - The StateAccess instance of the NFT canister.
    * @param {Types.WithdrawRequest} withdraw - The withdraw request details containing token information.
    * @param {Principal} caller - The Principal of the caller.
    * @returns {async* Types.ManageSaleResult} - A Result object containing either a ManageSaleResponse or an OrigynError.
    */
    public func withdraw_nft_origyn(state: StateAccess, withdraw: Types.WithdrawRequest, caller: Principal) : async* Star.Star<Types.ManageSaleResponse,Types.OrigynError> {
      switch(withdraw){
        case(#deposit(details)){
          return await* _withdraw_deposit(state, withdraw, details, caller);
        };
        case(#escrow(details)){
          return await* _withdraw_escrow(state, withdraw, details, caller);
        };
        case(#sale(details)){
          return await* _withdraw_sale(state, withdraw, details, caller);
        };
        case(#reject(details)){
          return await* _reject_offer(state, withdraw, details, caller);
        };
        case (#fee_deposit(details)) {
          return await* _withdraw_fee_deposit(state, withdraw, details, caller);
        };
      };
      return #err(#trappable(Types.errors(?state.canistergeekLogger,  #nyi, "withdraw_nft_origyn  - nyi - " , ?caller)));
    };


    /**
    * Refunds the failed bid by withdrawing the escrow amount and refunding the entire escrow to the buyer. 
    * 
    * @param {Types.State} state - The current state of the canister.
    * @param {MigrationTypes.Current.VerifiedReciept} verified - The verified receipt.
    * @param {MigrationTypes.Current.EscrowReceipt} escrow - The escrow receipt.
    * 
    * @returns {async* Bool} - A boolean value indicating whether the refund was successful or not.
    */
    private func refund_failed_bid(state : Types.State, verified: MigrationTypes.Current.VerifiedReciept, escrow: MigrationTypes.Current.EscrowReceipt) : async* Bool{
       //we will close later after we try to refund a valid bid
      debug if(debug_channel.bid) D.print("refunding"  # debug_show(verified.found_asset.escrow.amount));
      let service : Types.Service = actor((Principal.toText(state.canister())));
      let refund_id = service.sale_nft_origyn(#withdraw(
        #escrow({
          escrow with
          amount = verified.found_asset.escrow.amount; //return back the whole escrow
          withdraw_to = escrow.buyer;}
        )));

      return true;
    };

    //allows bids on auctons
    /**
    * Allows bids on auctions. Verifies auction status, seller, buyer, token ownership, and bid amount before allowing a bid. 
    * If the bid is too low, it will refund the escrow. If the auction is already closed, it will attempt to refund the bid.
    * If the escrow cannot be verified, it will try to claim it first. 
    * 
    * @param {StateAccess} state - The state of the canister.
    * @param {Types.BidRequest} request - The bid request containing the token id and escrow receipt.
    * @param {Principal} caller - The principal of the caller.
    * @param {Bool} canister_call - Determines if the function is being called from another function within the canister.
    * @returns {Types.ManageSaleResult} A result indicating either a successful bid or an error message.
    */
    public func bid_nft_origyn(state: StateAccess, request : Types.BidRequest, caller: Principal, canister_call: Bool) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {

      debug if(debug_channel.bid) D.print("in bid " # debug_show((request, canister_call)));
      D.print("ok here");
      //look for an existing sale
      let ?current_sale = Map.get(state.state.nft_sales, Map.thash,request.sale_id) else {
        debug if(debug_channel.bid) D.print("could not find sale " # debug_show(request.sale_id));
        return #err(#trappable(Types.errors(?state.canistergeekLogger, #sale_id_does_not_match, "bid_nft_origyn - sales id did not match " # request.sale_id, ?caller)));
      };
      D.print("ok here 2");

      debug if(debug_channel.bid) D.print("found sale ");
      
      let current_sale_state = switch(NFTUtils.get_auction_state_from_status(current_sale)){
        case(#ok(val)) val;
        case(#err(err)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  err.error, "bid_nft_origyn - find state " # err.flag_point, ?caller)));
      };

      let {buy_now_price; start_date; min_increase; dutch} = switch(current_sale_state.config){
          case(#auction(config)){
            {
              buy_now_price = config.buy_now;
              start_date = config.start_date;
              min_increase = config.min_increase;
              dutch = false;
            };
          };
          case(#ask(config)){
            let buy_now = switch(config){
              case(null) null;
              case(?config){
                switch(Map.get(config, MigrationTypes.Current.ask_feature_set_tool, #buy_now)){
                  case(?#buy_now(val)){
                    ?val;
                  };
                  case(_){null};
                };
              };
            };
            let dutch = switch(config){
              case(null) null;
              case(?config){
                switch(Map.get(config, MigrationTypes.Current.ask_feature_set_tool, #dutch)){
                  case(?#dutch(val)){
                    ?val;
                  };
                  case(_){null};
                };
              };
            };
            let start_date = switch(config){
              case(null) null;
              case(?config){
                switch(Map.get(config, MigrationTypes.Current.ask_feature_set_tool, #start_date)){
                  case(?#start_date(val)){
                    ?val;
                  };
                  case(_){null};
                };
              };
            };
            let min_increase = switch(config){
              case(null) #percentage(0.05);
              case(?config){
                switch(Map.get(config, MigrationTypes.Current.ask_feature_set_tool, #min_increase)){
                  case(?#min_increase(val)){
                    val;
                  };
                  case(_){#percentage(0.05)};
                };
              };
            };
            {
              buy_now_price = switch(buy_now, dutch){
                case(?buy_now, null){
                  ?buy_now;
                };
                case(null, ?dutch){
                  let current_state = calc_dutch_price(state, current_sale_state);
                  ?current_state.min_next_bid;
                };
                case(_,_){
                  null;
                }
              };
          
              start_date = start_date;
              min_increase = min_increase;
              dutch = switch(dutch){
                case(null) false;
                case(?val) true;
              };
            };
          };
          case(_) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #sale_not_found, "bid_nft_origyn - not an auction type ", ?caller)));
        };

      switch(current_sale_state.status){
        case(#open){ 
          if(state.get_time() >= current_sale_state.end_date) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #auction_ended, "bid_nft_origyn - sale is past close date " # request.sale_id, ?caller)));
        };
        case(#not_started){
          if(state.get_time() >= current_sale_state.start_date and state.get_time() < current_sale_state.end_date){
            current_sale_state.status := #open;
          };
        };
        case(_) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #auction_ended, "bid_nft_origyn - sale is not open " # request.sale_id, ?caller)));
      };

      switch(current_sale_state.allow_list){
        case(null){
          debug if(debug_channel.bid) D.print("allow list is null");
        };
        case(?val){
          debug if(debug_channel.bid) D.print("allow list inst null");
          switch(Map.get<Principal, Bool>(val, Map.phash, caller)){
              case(null){return #err(#trappable(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "bid_nft_origyn - not on allow list ", ?caller)))};
              case(?val){}
          };
        };
      };
      
      var metadata = switch(Metadata.get_metadata_for_token(state,request.escrow_receipt.token_id, caller, ?state.canister(), state.state.collection_data.owner)){
        case(#err(err)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #token_not_found, "bid_nft_origyn " # err.flag_point, ?caller)));
        case(#ok(val)) val;
      };

      let owner = switch(Metadata.get_nft_owner(metadata)){
          case(#err(err)) return #err(#trappable(Types.errors(?state.canistergeekLogger,  err.error, "bid_nft_origyn " # err.flag_point, ?caller)));
         case(#ok(val)) val;
      };

      debug if(debug_channel.bid) D.print(" owner is " # debug_show(owner));

      //make sure token ids match
      if(current_sale.token_id != request.escrow_receipt.token_id) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #token_id_mismatch, "bid_nft_origyn - token id of sale does not match escrow receipt " # request.escrow_receipt.token_id, ?caller)));

      //make sure assets match
      debug if(debug_channel.bid) D.print("checking asset sale type " # debug_show((_get_token_from_sales_status(current_sale), request.escrow_receipt.token)));
      if(Types.token_eq(_get_token_from_sales_status(current_sale), request.escrow_receipt.token) == false) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #asset_mismatch, "bid_nft_origyn - asset in sale and escrow receipt do not match " # debug_show(request.escrow_receipt.token) # debug_show(_get_token_from_sales_status(current_sale)), ?caller)));
     
      //make sure owners match
      if(Types.account_eq(owner, request.escrow_receipt.seller) == false) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #receipt_data_mismatch, "bid_nft_origyn - owner and seller do not match " # debug_show(request.escrow_receipt.token) # debug_show(_get_token_from_sales_status(current_sale)), ?caller)));

      //make sure buyers match
      if(Types.account_eq(#principal(caller), request.escrow_receipt.buyer) == false) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #receipt_data_mismatch, "bid_nft_origyn - caller and buyer do not match " # debug_show(request.escrow_receipt.token) # debug_show(_get_token_from_sales_status(current_sale)), ?caller)));

      debug if(debug_channel.bid) D.print(" about to verify escrow " # debug_show(request.escrow_receipt));

      //make sure the receipt is valid
      debug if(debug_channel.bid) D.print("verifying Escrow");
      var verified = switch(verify_escrow_receipt(state, request.escrow_receipt, null, ?request.sale_id)){
          case(#err(err)){
            //we could not verify the escrow, so we're going to try to claim it here as if escrow_nft_origyn was called first.
            //this adds an additional await to each item not already claimed, so it could get expensive in batch scenarios.
            if(canister_call == false){

              //not a canister call... trying to recognize escrow
              
              debug if(debug_channel.bid) D.print("Not a canister call, trying escrow");
              state.canistergeekLogger.logMessage("bid_nft_origyn Not a canister call, trying recognize escrow " #debug_show((request.escrow_receipt, request.sale_id)) , #Option(null), null);
              switch(Star.toResult(await* recognize_escrow_nft_origyn(state, { 
              deposit = {request.escrow_receipt with
                sale_id = ?request.sale_id;
                trx_id = null;
              };
              lock_to_date = null;
              token_id = request.escrow_receipt.token_id;
              }, 
              caller))){
                case(#ok(val)){
                  state.canistergeekLogger.logMessage("bid_nft_origyn recognize escrow succeeded " #debug_show((request.escrow_receipt, request.sale_id)) , #Option(null), null);

                  debug if(debug_channel.bid) D.print("recognizing escrow was successful, recaling bid");
                  return await* bid_nft_origyn(state, request, caller, true);
                };
                case(#err(err)){
                  state.canistergeekLogger.logMessage("bid_nft_origyn recognize escrow failed " #debug_show((request.escrow_receipt, request.sale_id, err.flag_point)) , #Option(null), null);
                  if(debug_channel.bid) D.print("recognition of escrow failed, attempting recognition of deposit");
                };
              };

              state.canistergeekLogger.logMessage("bid_nft_origyn attempting escrow from deposit " #debug_show((request.escrow_receipt, request.sale_id)) , #Option(null), null);

              switch(await* escrow_nft_origyn(state,
                  {deposit =
                    {
                      request.escrow_receipt with 
                      sale_id = ?request.sale_id;
                      trx_id = null;
                    }; 
                  lock_to_date = null; token_id = request.escrow_receipt.token_id}
                , caller)){
                  //we can't just continue here because the owner may have changed out from underneath us...safer to sart from the begining
                  case(#trappable(newEscrow)) return await* bid_nft_origyn(state, request, caller, true);
                  case(#awaited(newEscrow)) return await* bid_nft_origyn(state, request, caller, true);
                  case(#err(#trappable(err))) return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "bid_nft_origyn auto try escrow failed " # err.flag_point, ?caller)));
                  case(#err(#awaited(err))) return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "bid_nft_origyn auto try escrow failed " # err.flag_point, ?caller)));
                };
            } else return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "bid_nft_origyn auto try escrow failed after canister call " # err.flag_point, ?caller)))
          };
          case(#ok(res)) res;
      };

      //we can continue with trappable because the awaits above are returned.
      debug if(debug_channel.bid) D.print("verified the escorw "  # debug_show(verified.found_asset));

      if(verified.found_asset.escrow.amount < request.escrow_receipt.amount) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #withdraw_too_large, "bid_nft_origyn - escrow - amount more than in escrow verified: " # Nat.toText(verified.found_asset.escrow.amount) # " request: " # Nat.toText(request.escrow_receipt.amount) , ?caller)));

      //make sure auction is still running
      let current_time = state.get_time();
      // MKT0028
      if(state.get_time() > current_sale_state.end_date) return #err(#trappable(Types.errors(?state.canistergeekLogger,  #auction_ended, "bid_nft_origyn - auction ended current_date" # debug_show(current_time) # " " # " end_time:" # debug_show(current_sale_state.end_date), ?caller)));

      switch(current_sale_state.status){
        case(#closed){
          //we will close later after we try to refund a valid bid
          ignore refund_failed_bid(state, verified, request.escrow_receipt);
          //last_withdraw_result := ?refund_id;

          //debug if(debug_channel.bid) D.print(debug_show(refund_id));
          return #err(#trappable(Types.errors(?state.canistergeekLogger,  #auction_ended, "end_sale_nft_origyn - auction already closed - attempting escrow return ", ?caller)));
        };
        case(_){};
      };

      let required_bid = if(dutch){
        switch(buy_now_price){
          case(null){
            current_sale_state.min_next_bid;
          };
          case(?val){
            val;
          };
        };
      } else {
        current_sale_state.min_next_bid;
      };

      //make sure amount is high enough
      if(request.escrow_receipt.amount < required_bid){
        //if the bid is too low we should refund their escrow
        debug if(debug_channel.bid) D.print("refunding not high enough bid "  # debug_show(verified.found_asset.escrow.amount));
        let service : Types.Service = actor((Principal.toText(state.canister())));
        let refund_id = service.sale_nft_origyn(#withdraw(
          #escrow({
            verified.found_asset.escrow with 
            withdraw_to = verified.found_asset.escrow.buyer;}
          )));
        //last_withdraw_result := ?refund_id;

        //debug if(debug_channel.bid) D.print(debug_show(refund_id));
                
        return #err(#trappable(Types.errors(?state.canistergeekLogger,  #bid_too_low, "bid_nft_origyn - bid too low - refund issued "  , ?caller)));
      };

      let buy_now = switch(buy_now_price){
        case(null) false ;
        case(?val){
          if(val <= request.escrow_receipt.amount){
            true;
          } else {
            false;
          };
        };
      };

      //todo: This would be a good place to check the state.fee_deposit_balances for any fee_accounts that might be expected to make sure the seller still has the fees listed. We may wan to have some escape hatch such that if the amount is not there then the auction ends with the last highest bid or is cancled if no bid.  It will be easier for fixed auctions for us keep track of this.  We don't want to create a situation where a user creates an auction, we check for an expected fee and it is there, but then they with draw their fee_deposit and users are stuck bidding on an auction that can never settle.
      //I guess I need to lock their fee deposit from being withdrawn if they have any open auctions.
      //Rate will be interesting...we will likely have to calculate the max price they could sell for and force the buy_now to top out at that amount.

      //kyc
      debug if(debug_channel.bid) D.print("trying kyc" # debug_show("")); 

      var bRevalidate = false;

      let kyc_result = try{
        await* KYC.pass_kyc_buyer(state, verified.found_asset.escrow, caller);
      } catch(e){
        return #err(#awaited(Types.errors(?state.canistergeekLogger,  #kyc_error, "bid_nft_origyn auto try escrow failed " # Error.message(e), ?caller)))
      };

      switch(kyc_result){
        case(#ok(val)){

          if(val.result.kyc == #Fail or val.result.aml == #Fail){
            debug if(debug_channel.bid) D.print("faild...returning bid" # debug_show(val));
            
            ignore refund_failed_bid(state, verified, request.escrow_receipt);
            //last_withdraw_result := ?refund_id;

            
            return #err(#awaited(Types.errors(?state.canistergeekLogger,  #kyc_fail, "bid_nft_origyn kyc or aml failed " # debug_show(val), ?caller)));
          };
          let kycamount = Option.get(val.result.amount, 0);

          if((kycamount > 0) and (request.escrow_receipt.amount > kycamount)){
            ignore refund_failed_bid(state, verified, request.escrow_receipt);

            return #err(#awaited(Types.errors(?state.canistergeekLogger,  #kyc_fail, "bid_nft_origyn kyc or aml amount too large " # debug_show((val, kycamount, request.escrow_receipt)), ?caller)))
          };

          if(val.did_async){
            bRevalidate := true;
          }

        };
        case(#err(err)){
          ignore refund_failed_bid(state, verified, request.escrow_receipt);
          
          return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "bid_nft_origyn auto try kyc failed " # err.flag_point, ?caller)))
        };
      };

      if(bRevalidate){
        verified := switch(verify_escrow_receipt(state, request.escrow_receipt, null, ?request.sale_id)){
            case(#err(err)){
              //we could not verify the escrow, so we're going to try to claim it here as if escrow_nft_origyn was called first.
              //this adds an additional await to each item not already claimed, so it could get expensive in batch scenarios.

              return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "bid_nft_origyn revalidate failed " # err.flag_point, ?caller)))
            };
            case(#ok(res)) res;
        };
      };

      debug if(debug_channel.bid) D.print("have buy now" # debug_show(buy_now, buy_now_price, current_sale_state.current_bid_amount));

      let new_trx = Metadata.add_transaction_record(state,{
          token_id = request.escrow_receipt.token_id;
          index = 0;
          txn_type = #auction_bid({
            request.escrow_receipt with 
              broker_id = request.broker_id;
              sale_id = request.sale_id;
              extensible = #Option(null);
          }
          );
          timestamp = state.get_time();
      }, caller);
      

      debug if(debug_channel.bid) D.print("about to try refund");

      switch(new_trx){
        case(#ok(val)){
          //nyi: implement wait for quiet

          debug if(debug_channel.bid) D.print("in this" # debug_show(current_sale_state.current_escrow));

          //update the sale

          let newMinBid = switch(min_increase){
            case(#percentage(apercentage)) Int.abs(Float.toInt(Float.fromInt(request.escrow_receipt.amount) * apercentage)) + request.escrow_receipt.amount;
            case(#amount(aamount)) request.escrow_receipt.amount + aamount;
          };


          debug if(debug_channel.bid) D.print("have a min bid" # debug_show(newMinBid));
          
          switch(current_sale_state.current_escrow){
            case(null){

              //update state
              debug if(debug_channel.bid) D.print("updating the state" # debug_show(request));
              current_sale_state.current_bid_amount := request.escrow_receipt.amount;
              if(dutch == false){
                current_sale_state.min_next_bid := newMinBid;
              };
              current_sale_state.current_escrow := ?request.escrow_receipt;
              current_sale_state.current_broker_id := request.broker_id;
              ignore Map.put<Principal, Int>(current_sale_state.participants, phash, caller, state.get_time());
            };
            case(?val){

              //update state
              debug if(debug_channel.bid) D.print("Before" # debug_show(val.amount) # debug_show(val));
              current_sale_state.current_bid_amount := request.escrow_receipt.amount;
              if(dutch == false){
                current_sale_state.min_next_bid := newMinBid;
              };
              current_sale_state.current_escrow := ?request.escrow_receipt;
              current_sale_state.current_broker_id := request.broker_id;
              ignore Map.put<Principal, Int>(current_sale_state.participants, phash, caller, state.get_time());
              debug if(debug_channel.bid) D.print("After" # debug_show(val.amount) # debug_show(val));
              //refund the escrow
              //nyi: this would be better triggered by an event
              //if this fails they can still manually withdraw the escrow.
              debug if(debug_channel.bid) D.print("Trying refund escrow " # debug_show(val.amount) # debug_show(val));
              let service : Types.Service = actor((Principal.toText(state.canister())));
              let refund_id =  service.sale_nft_origyn(#withdraw(
                #escrow({
                  val with 
                  withdraw_to = val.buyer;}
                )
              ));

              //last_withdraw_result := ?refund_id;
              debug if(debug_channel.bid) D.print("done");
              //debug if(debug_channel.bid) D.print(debug_show(refund_id));

            };
          };

          if(buy_now or dutch){

            debug if(debug_channel.bid) D.print("handling buy now");

            let service : Types.Service = actor((Principal.toText(state.canister())));
            
            let result = await service.sale_nft_origyn(#end_sale(request.escrow_receipt.token_id));

            switch(result){
              case(#ok(val)){
                switch(val){
                  case(#end_sale(val)) return #awaited(#bid(val));
                  case(_)return #err(#awaited(Types.errors(?state.canistergeekLogger,  #improper_interface, "bid_nft_origyn - buy it now call to end sale had odd response " # debug_show(result), ?caller )));
                };
              };
              case(#err(err)) return #err(#awaited(err));
            };

            //call ourseves to close the auction
          };
          return #awaited(#bid(val));
        };
        case(#err(err)) return #err(#awaited(Types.errors(?state.canistergeekLogger,  err.error, "bid_nft_origyn - create transaction record " # err.flag_point, ?caller)));
      };
    };


    //pulls the token out of a sale
    /**
    * Retrieves the token specification from a given sale status.
    * @private
    * @param {Types.SaleStatus} status - The sale status to retrieve the token specification from.
    * @returns {Types.TokenSpec} - The token specification retrieved from the given sale status.
    */
    private func _get_token_from_sales_status(status: Types.SaleStatus) : Types.TokenSpec{
      switch(status.sale_type){
        case(#auction(auction_status)){
          return switch(auction_status.config){
            case(#auction(auction_config)) return auction_config.token;
            case(#ask(?auction_config)) {
              let ?(#token(spec)) = Map.get<MigrationTypes.Current.AskFeatureKey, MigrationTypes.Current.AskFeature>(auction_config, MigrationTypes.Current.ask_feature_set_tool, #token) else {
                debug if(debug_channel.bid) D.print("strange askconfig");
                D.trap("unreachable");
              };
              return spec;
            };
            case(_){
              debug if(debug_channel.bid) D.print("getTokenfromSalesstatus not configured for type");
              assert(false);
              return #extensible(#Option(null));
            };
          };
        };
        case(_){
            debug if(debug_channel.bid) D.print("getTokenfromSalesstatus not configured for type");
            assert(false);
            return #extensible(#Option(null));
        };
      };
    };
}