import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
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

import AccountIdentifier "mo:principalmo/AccountIdentifier";
import CandyTypes "mo:candy_0_1_10/types";
import Conversions "mo:candy_0_1_10/conversion";
import Map "mo:map_6_0_0/Map";
import Properties "mo:candy_0_1_10/properties";
import SHA256 "mo:crypto/SHA/SHA256";

import Current "migrations/v000_001_000/types";
import Ledger_Interface "ledger_interface";
import Metadata "metadata";
import MigrationTypes "./migrations/types";
import Migrations "migrations/types";
import Mint "mint";
import NFTUtils "utils";
import Types "types";


module {

    let debug_channel = {
        verify_escrow = true;
        verify_sale = false;
        ensure = false;
        invoice = false;
        end_sale = false;
        market = true;
        royalties = false;
        offers = false;
        escrow = false;
        withdraw_escrow = false;
        withdraw_sale = false;
        withdraw_reject = false;
        withdraw_deposit = false;
        bid = false;
    };

    let account_handler = Types.account_handler;
    let token_handler = Types.token_handler;

    type StateAccess = Types.State;

    let SB = MigrationTypes.Current.SB;

    let { ihash; nhash; thash; phash; calcHash } = Map;

    // Searches the escrow reciepts to find if the buyer/seller/token_id tuple has a balance on file
    public func find_escrow_reciept(
        state: StateAccess,
        buyer : Types.Account,
        seller: Types.Account,
        token_id: Text) : Result.Result<
            MigrationTypes.Current.EscrowLedgerTrie
        , Types.OrigynError> {

        var found_asset : ?(Hash.Hash, Types.EscrowRecord) = null;
        var found_asset_list : ?MigrationTypes.Current.EscrowLedgerTrie = null;
                        debug if(debug_channel.verify_escrow) D.print("found asset " # debug_show(found_asset));

        //find buyer's escrows
        let verified = switch(Map.get(state.state.escrow_balances, account_handler, buyer)){
            case(null){
                                    debug if(debug_channel.verify_escrow) D.print("didnt find asset");
                return #err(Types.errors(#no_escrow_found, "find_escrow_reciept - escrow buyer not found ", null));
            };
            case(?to_list){
                
                                    debug if(debug_channel.verify_escrow) D.print("to_list is " # debug_show(Map.size(to_list)));
                //find sellers deposits
                switch(Map.get(to_list, account_handler, seller)){
                    case(null){
                                            debug if(debug_channel.verify_escrow) D.print("no escrow seller");
                        return #err(Types.errors(#no_escrow_found, "find_escrow_reciept - escrow seller not found ", null));};
                    case(?token_list){
                                            debug if(debug_channel.verify_escrow) D.print("looking for to list");
                        //find tokens deposited for both "" and provided token_id
                        let asset_list = switch(Map.get(token_list, Map.thash, token_id), Map.get(token_list, Map.thash, "")){
                            case(null, null){
                                return #err(Types.errors(#no_escrow_found, "find_escrow_reciept - escrow token_id not found ", null));
                            };
                            case(null, ?generalList){
                                return #err(Types.errors(#no_escrow_found, "find_escrow_reciept - escrow token_id found for general item but token_id is specific ", null));
                            };
                            case(?asset_list, _ ){
                                
                                found_asset_list := ?asset_list;
                                
                            };
                        };

                    };
                };
            };
        };

        switch(found_asset_list){
            case(?found_asset_list){
                return #ok(found_asset_list);
            };
            case(null){
                 return #err(Types.errors(#no_escrow_found, "find_escrow_reciept", null));
            };
        };
    };

    //verifies that an escrow reciept exists in this NF
    public func verify_escrow_reciept(
        state: StateAccess,
        escrow : Types.EscrowReceipt, 
        owner: ?Types.Account, 
        sale_id: ?Text) : Result.Result<
        {
            found_asset : {token_spec: Types.TokenSpec; escrow: Types.EscrowRecord};
            found_asset_list : MigrationTypes.Current.EscrowLedgerTrie;
        }, Types.OrigynError> {

        var found_asset : ?{token_spec: Types.TokenSpec; escrow: Types.EscrowRecord} = null;
        var found_asset_list : ?MigrationTypes.Current.EscrowLedgerTrie = null;
                        debug if(debug_channel.verify_escrow) D.print("found asset " # debug_show(found_asset));

        let verified = switch(Map.get(state.state.escrow_balances, account_handler, escrow.buyer)){
            case(null){
                                    debug if(debug_channel.verify_escrow) D.print("didnt find asset");
                return #err(Types.errors(#no_escrow_found, "verify_escrow_reciept - escrow buyer not found " # debug_show(escrow.buyer), null));
            };
            case(?to_list){
                //only the owner can sell it
                                    debug if(debug_channel.verify_escrow) D.print("found to list" # debug_show(owner) # debug_show(escrow.seller));
                switch(owner){
                    case(null){};
                    case(?owner){
                        if(Types.account_eq(owner, escrow.seller) == false){
                            return #err(Types.errors(#unauthorized_access, "verify_escrow_reciept - escrow seller is not the owner  " # debug_show(owner) # " " # debug_show(escrow.seller), null));
                        };
                    };
                };
                                    debug if(debug_channel.verify_escrow) D.print("to_list is " # debug_show(Map.size(to_list)));
                switch(Map.get(to_list, account_handler, escrow.seller)){
                    case(null){
                                            debug if(debug_channel.verify_escrow) D.print("no escrow seller");
                        return #err(Types.errors(#no_escrow_found, "verify_escrow_reciept - escrow seller not found  " # debug_show(escrow.seller), null));};
                    case(?token_list){
                                            debug if(debug_channel.verify_escrow) D.print("looking for to list");
                        let asset_list = switch(Map.get(token_list, Map.thash, escrow.token_id), Map.get(token_list, Map.thash, "")){
                            case(null, null){
                                return #err(Types.errors(#no_escrow_found, "verify_escrow_reciept - escrow token_id not found  " # debug_show(escrow.token_id), null));
                            };
                            case(null, ?generalList){
                                return #err(Types.errors(#no_escrow_found, "verify_escrow_reciept - escrow token_id found for general item but token_id is specific  " # debug_show(escrow.token_id), null));
                            };
                            
                            
                            case(?asset_list, _ ){
                                
                                                    //debug if(debug_channel.verify_escrow) D.print("testing hash" # debug_show(assetHash) # " " # debug_show(assetHash));
                                found_asset_list := ?asset_list;
                                switch(Map.get(asset_list, token_handler, escrow.token)){

                                    case(null){return #err(Types.errors(#no_escrow_found, "verify_escrow_reciept - escrow token spec not found ", null));};
                                    case(?balance){
                                        found_asset := ?{token_spec = escrow.token; escrow = balance};
                                                            debug if(debug_channel.verify_escrow) D.print("Found an asset, checking fee");
                                                            debug if(debug_channel.verify_escrow) D.print(debug_show(found_asset));
                                                            debug if(debug_channel.verify_escrow) D.print(debug_show(escrow.amount));
                                        //check sale id
                                        switch(sale_id, balance.sale_id){
                                            case(null, null){};
                                            case(?desired_sale_id, null){
                                                return #err(Types.errors(#sale_id_does_not_match, "verify_escrow_reciept - escrow sale_id does not match  " #   debug_show(sale_id) # debug_show(balance.sale_id), null));
                                            };
                                            case(null, ?on_file_saleID){
                                                //null is passed in as a sale id if we want to do sale id verification elsewhere
                                                //return #err(Types.errors(#sale_id_does_not_match, "verify_escrow_reciept - escrow sale_id does not match ", null));
                                            };
                                            case(?desired_sale_id, ?on_file_saleID){
                                                if(desired_sale_id != on_file_saleID){
                                                    return #err(Types.errors(#sale_id_does_not_match, "verify_escrow_reciept - escrow sale_id does not match  " # debug_show(on_file_saleID)  # debug_show(desired_sale_id), null));
                                                };
                                            };
                                        }; 
                                        if(balance.amount >= escrow.amount){
                                            true;
                                        } else {return #err(Types.errors(#withdraw_too_large, "verify_escrow_reciept - escrow not large enough  " # debug_show(balance.amount) # " " # debug_show(escrow.amount), null));};
                                    };
                                };
                            };
                        }

                    };
                };
            };
        };

        switch(found_asset, found_asset_list){
            case(?found_asset, ?found_asset_list){
                return #ok({
                    found_asset = found_asset;
                    found_asset_list = found_asset_list;
                });

            };
            case(_){
                return #err(Types.errors(#nyi, "verify_escrow_reciept - should be unreachable ", null));
            };
        }


    };

    //verifies that a revenue reciept is in the NFT Canister
    public func verify_sales_reciept(
        state: StateAccess,
        escrow : Types.EscrowReceipt) : Result.Result<
        {
            found_asset : {token_spec: Types.TokenSpec; escrow: Types.EscrowRecord};
            found_asset_list : MigrationTypes.Current.EscrowLedgerTrie;
        }, Types.OrigynError> {

        var found_asset : ?{token_spec: Types.TokenSpec; escrow: Types.EscrowRecord} = null;
        var found_asset_list : ?MigrationTypes.Current.EscrowLedgerTrie = null;
        let verified = switch(Map.get<Types.Account, MigrationTypes.Current.SalesBuyerTrie>(state.state.sales_balances, account_handler, escrow.seller)){
            case(null){
                                debug if(debug_channel.verify_sale) D.print("sale seller not found");
                return #err(Types.errors(#no_escrow_found, "verify_sales_reciept - escrow seller not found ", null));
            };
            case(?to_list){
                //only the owner can sell it

                switch(Map.get(to_list, account_handler, escrow.buyer)){
                    case(null){
                                            debug if(debug_channel.verify_sale) D.print("sale byer not found");
                        return #err(Types.errors(#no_escrow_found, "verify_sales_reciept - escrow buyer not found ", null));};
                    case(?token_list){
                        switch(Map.get(token_list, Map.thash, escrow.token_id)){
                            case(null){
                                            debug if(debug_channel.verify_sale) D.print("sale token id not found");
                                return #err(Types.errors(#no_escrow_found, "verify_sales_reciept - escrow token_id not found ", null));
                            };
                            case(?asset_list){
                                
                                found_asset_list := ?asset_list;
                                switch(Map.get(asset_list, token_handler,escrow.token)){

                                    case(null){
                                                            debug if(debug_channel.verify_sale) D.print("sale token not found");
                                        return #err(Types.errors(#no_escrow_found, "verify_sales_reciept - escrow token spec not found ", null));};
                                    case(?balance){
                                        found_asset := ?{token_spec = escrow.token; escrow = balance};
                                                            debug if(debug_channel.verify_sale) D.print("issue with balances");
                                                            debug if(debug_channel.verify_sale) D.print(debug_show(balance));
                                                            debug if(debug_channel.verify_sale) D.print(debug_show(escrow));
                                        
                                        if(balance.amount >= escrow.amount){
                                            true;
                                        } else {return #err(Types.errors(#withdraw_too_large, "verify_sales_reciept - escrow not large enough", null));};
                                    };
                                };
                            };
                        }
                    };
                };
            };
        };

        switch(found_asset, found_asset_list){
            case(?found_asset, ?found_asset_list){
                return #ok({
                    found_asset = found_asset;
                    found_asset_list = found_asset_list;
                });
            };
            case(_){
                return #err(Types.errors(#nyi, "verify_sales_reciept - should be unreachable ", null));
            };
        }
    };

    //makes sure that there is not an ongoing sale for an item
    public func is_token_on_sale(
        state: StateAccess,
        metadata: CandyTypes.CandyValue, 
        caller: Principal) : Result.Result<Bool,Types.OrigynError>{

                        debug if(debug_channel.ensure) D.print("in ensure");
        let token_id = switch(Metadata.get_nft_id(metadata)){
            case(#err(err_)){return #err(Types.errors(#token_not_found, "_ensure_no_existing_sale - could not find token_id ", ?caller));};
            case(#ok(val)){val};
        };

        //look for an existing sale
                            debug if(debug_channel.verify_sale) D.print("geting sale");
        switch(Metadata.get_current_sale_id(metadata)){
            case(#Empty){return #ok(false)};
            case(#Text(sale_id)){
                            debug if(debug_channel.verify_sale) D.print("found sale" # sale_id);
                
                let current_sale = switch(Map.get(state.state.nft_sales, Map.thash, sale_id)){
                    case(?status){
                        status;
                    };
                    case(null){return #err(Types.errors(#sale_not_found, "_ensure_no_existing_sale - could not find sale for token " # token_id # " " # sale_id, ?caller));};
                };
        
                  
                            debug if(debug_channel.verify_sale) D.print("checking state");
                let current_sale_state = switch(NFTUtils.get_auction_state_from_status(current_sale)){
                    case(#ok(val)){val};
                    case(#err(err)){
                        return #err(Types.errors(err.error, "_ensure_no_existing_sale - find sale state " # err.flag_point, ?caller));
                    }
                };
                            debug if(debug_channel.verify_sale) D.print("switching config");
                switch(current_sale_state.config){
                    case(#auction(config)){
                                        debug if(debug_channel.verify_sale) D.print("current config" # debug_show(config));
                        switch(current_sale_state.status){
                            case(#closed){
                                //can continue
                                return #ok(false);
                            };
                            case(#open){
                                //can continue
                                return #ok(true);
                            };
                            case(_){
                                return #ok(true);
                            };
                        };
                    };
                    case(_){
                        return #err(Types.errors(#nyi, "_ensure_no_existing_sale - sales type check not implemented", ?caller));
                    };
                };
            };
            case(_){return #err(Types.errors(#nyi, "_ensure_no_existing_sale - sales id did not match ", ?caller));};
        };
    };

    //opens a sale if it is past the date
    public func open_sale_nft_origyn(state: StateAccess, token_id: Text, caller: Principal) : Result.Result<Types.ManageSaleResponse,Types.OrigynError> {
        //D.print("in open_sale_nft_origyn");
        let metadata = switch(Metadata.get_metadata_for_token(state,token_id, caller, ?state.canister(), state.state.collection_data.owner)){
            case(#err(err)){
                return #err(Types.errors(#token_not_found, "open_sale_nft_origyn " # err.flag_point, ?caller));
            };
            case(#ok(val)){
                val;
            };
        };

        //look for an existing sale
        //nyi: refactor this with details found in other functions
        let current_sale = switch(Metadata.get_current_sale_id(metadata)){
            case(#Empty){return #err(Types.errors(#sale_not_found, "open_sale_nft_origyn - could not find sale for token " # token_id, ?caller));};
            case(#Text(val)){
                switch(Map.get(state.state.nft_sales, Map.thash,val)){
                    case(?status){
                        status;
                    };
                    case(null){return #err(Types.errors(#sale_not_found, "open_sale_nft_origyn - could not find sale for token " # token_id, ?caller));};
                };
            };
            case(_){return #err(Types.errors(#sale_not_found, "open_sale_nft_origyn - could not find sale for token " # token_id, ?caller));};
        };

        let current_sale_state = switch(NFTUtils.get_auction_state_from_status(current_sale)){
            case(#ok(val)){val};
            case(#err(err)){
                return #err(Types.errors(err.error, "open_sale_nft_origyn - find state " # err.flag_point, ?caller));
            };
        };

        switch(current_sale_state.config){
            case(#auction(config)){
                let current_pricing = switch(current_sale_state.config){
                    case(#auction(config)){
                        config;
                    };
                    case(_){
                        return #err(Types.errors(#sale_not_found, "open_sale_nft_origyn - not an auction type ", ?caller));

                    };
                };



               

                 switch(current_sale_state.status){
                    case(#closed){
                        return #err(Types.errors(#auction_ended, "open_sale_nft_origyn - auction already closed ", ?caller));
                    };
                    case(#not_started){
                        if(state.get_time() >= current_pricing.start_date and state.get_time() < current_sale_state.end_date){
                            current_sale_state.status := #open;
                            return(#ok(#open_sale(true)));
                        } else {
                            return #err(Types.errors(#auction_not_started, "open_sale_nft_origyn - auction does not need to be opened " # debug_show(current_pricing.start_date), ?caller));
                        };
                    };
                    case(#open){
                         return #err(Types.errors(#auction_not_started, "open_sale_nft_origyn - auction already open", ?caller));
                    };
                };
            };
            case(_){
                return #err(Types.errors(#sale_not_found, "open_sale_nft_origyn - not an auction type ", ?caller));

            };
        };
    };

    //reports information about a sale
    public func sale_status_nft_origyn(state: StateAccess, sale_id: Text, caller: Principal) : Result.Result<Types.SaleInfoResponse,Types.OrigynError> {
        
        //look for an existing sale
        let current_sale =  switch(Map.get(state.state.nft_sales, Map.thash,sale_id)){
            case(?status){
                status;
            };
            case(null){return #ok(#status(null))};
        };
            

        let result = #ok(#status(?{
            sale_id = current_sale.sale_id;
            token_id = current_sale.token_id;
            original_broker_id = current_sale.original_broker_id;
            broker_id = current_sale.broker_id;
            sale_type = switch(current_sale.sale_type){
                case(#auction(val)){
                    #auction(Types.AuctionState_stabalize_for_xfer(val))
                };
                /* case(_){
                   return #err(Types.errors(#sale_not_found, "sale_status_nft_origyn not an auction ", ?caller));
            
                } */
            };
        }));

        return result;
    };

    //returns active sales on a canister
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

        let results = Buffer.Buffer<(Text, ?Types.SaleStatusStable)>(max - min);

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
              case(#ok(val)){
                  val;
              };
          };

          //look for an existing sale
          
          let current_sale = switch(Metadata.get_current_sale_id(metadata)){
              case(#Empty){
                  //results.add(this_token.0, null);
                  tracker += 1;
                  continue search;
              };
              case(#Text(val)){
                  switch(Map.get(state.state.nft_sales, Map.thash,val)){
                      case(?status){
                          status;
                      };
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
              case(#ok(val)){val};
              case(#err(err)){
                    
                  //results.add(this_token.0, null);
                  tracker += 1;
                  continue search;
                      
              };
          };

          switch(current_sale_state.config){
              case(#auction(config)){
                  let current_pricing = switch(current_sale_state.config){
                      case(#auction(config)){
                          config;
                      };
                      case(_){
                          //nyi: handle other sales types
                          //results.add(this_token.0, null);
                          tracker += 1;
                          continue search;
                      };
                  };

                  if(current_sale_state.status == #open or current_sale_state.status == #not_started){
                    
                    if(tracker > max){}
                    else if( tracker >= min ){

                      results.add(this_token.0, ?{
                          sale_id = current_sale.sale_id;
                          token_id = current_sale.token_id;
                          broker_id = current_sale.broker_id;
                          original_broker_id = current_sale.original_broker_id;
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
              case(_){
                  //results.add(this_token.0, null);
                  tracker += 1;
                  continue search;
              };
          };

            tracker += 1;
        };

        return #ok(#active({
            records = results.toArray();
            eof = eof;
            count = foundTotal;
        }));
    };


    //returns a history of sales
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

        let results = Buffer.Buffer<?Types.SaleStatusStable>(max - min);

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
                        let current_pricing = switch(current_sale_state.config){
                            case(#auction(config)){
                                config;
                            };
                            case(_){
                                //nyi: handle other sales types
                                //results.add( null);
                                tracker += 1;
                                continue search;
                            };
                        };

                        results.add(?{
                                sale_id = thisSale.1.sale_id;
                                token_id = thisSale.1.token_id;
                                broker_id = thisSale.1.broker_id;
                                original_broker_id = thisSale.1.original_broker_id;
                                sale_type = switch(thisSale.1.sale_type){
                                    case(#auction(val)){
                                        #auction(Types.AuctionState_stabalize_for_xfer(val))
                                    };
                                };
                            }
                        );

                    };
                    case(_){
                        //nyi: implement other sales types
                        //results.add(null);
                    };
                };
            };
            tracker += 1;
        };

        return #ok(#history({
            records = results.toArray();
            eof = eof;
            count = total;
        }));
    };

    //returns an invoice or details of where a user can send their depoits on a standard ledger
    public func deposit_info_nft_origyn(state: StateAccess, request: ?Types.Account, caller: Principal) : Result.Result<Types.SaleInfoResponse,Types.OrigynError> {

                            debug if(debug_channel.invoice) D.print("in deposit info nft origyn.");

        let account = switch(request){
            case(null){#principal(caller)};
            case(?val){val};
        };

                            debug if(debug_channel.invoice) D.print("getting info for " # debug_show(account));
        return #ok(#deposit_info(NFTUtils.get_deposit_info(account, state.canister())));
    };
    

    //ends a sale if it is past the date or a buy it now has occured
    public func end_sale_nft_origyn(state: StateAccess, token_id: Text, caller: Principal) : async Result.Result<Types.ManageSaleResponse,Types.OrigynError> {
                            debug if(debug_channel.end_sale) D.print("in end_sale_nft_origyn");
        var metadata = switch(Metadata.get_metadata_for_token(state,token_id, caller, ?state.canister(), state.state.collection_data.owner)){
            case(#err(err)){
                return #err(Types.errors(#token_not_found, "end_sale_nft_origyn " # err.flag_point, ?caller));
            };
            case(#ok(val)){
                val;
            };
        };

         let owner = switch(Metadata.get_nft_owner(metadata)){
            case(#err(err)){
                return #err(Types.errors(err.error, "end_sale_nft_origyn " # err.flag_point, ?caller));
            };
            case(#ok(val)){
                val;
            };
        };



        //look for an existing sale
        let current_sale = switch(Metadata.get_current_sale_id(metadata)){
            case(#Empty){return #err(Types.errors(#sale_not_found, "end_sale_nft_origyn - could not find sale for token " # token_id, ?caller));};
            case(#Text(val)){
                switch(Map.get(state.state.nft_sales, Map.thash,val)){
                    case(?status){
                        status;
                    };
                    case(null){return #err(Types.errors(#sale_not_found, "end_sale_nft_origyn - could not find sale for token " # token_id, ?caller));};
                };
            };
            case(_){return #err(Types.errors(#sale_not_found, "end_sale_nft_origyn - could not find sale for token " # token_id, ?caller));};
        };

        let current_sale_state = switch(NFTUtils.get_auction_state_from_status(current_sale)){
            case(#ok(val)){val};
            case(#err(err)){
                return #err(Types.errors(err.error, "end_sale_nft_origyn - find state " # err.flag_point, ?caller));
            };
        };

        switch(current_sale_state.config){
            case(#auction(config)){
                let current_pricing = switch(current_sale_state.config){
                    case(#auction(config)){
                        config;
                    };
                    case(_){
                        return #err(Types.errors(#sale_not_found, "end_sale_nft_origyn - not an auction type ", ?caller));

                    };
                };



                let buy_now = switch(current_pricing.buy_now){
        
                    case(null){false};
                    case(?val){
                        if(val <= current_sale_state.current_bid_amount){
                            true;
                        } else {
                            false;
                        };
                    };
                };

                                    debug if(debug_channel.end_sale) D.print("have buy now" # debug_show(buy_now, current_pricing.buy_now, current_sale_state.current_bid_amount));
                
                switch(current_sale_state.status){
                    case(#closed){
                        //we will close later after we try to refund a valid bid
                        //return #err(Types.errors(#auction_ended, "end_sale_nft_origyn - auction already closed ", ?caller));
                    };
                    case(#not_started){
                                            debug if(debug_channel.end_sale) D.print("wasnt started");
                
                        if(state.get_time() >= current_pricing.start_date and state.get_time() < current_sale_state.end_date){
                            current_sale_state.status := #open;
                        };
                    };
                    case(_){};
                };

                                        debug if(debug_channel.end_sale) D.print("handled current stauts" # debug_show(buy_now, current_pricing.buy_now, current_sale_state.current_bid_amount));
                

                //make sure auction is still over
                if(state.get_time() < current_sale_state.end_date ){
                    if( buy_now == true and caller == state.canister()){
                        //only the canister can end a buy now
                    } else {

                         if(Types.account_eq(#principal(caller), owner) == true and current_sale_state.current_escrow == null){
                            //an owner can cancel an auction that has no bids yet.
                            //useful for buy it now sales with a long out end date.
                            current_sale_state.status := #closed; 
                            

                            switch(Metadata.add_transaction_record(state,{
                                token_id = token_id;
                                index = 0;
                                txn_type = #sale_ended {
                                    seller = owner;
                                    buyer = owner;
                                    token = config.token;
                                    sale_id = ?current_sale.sale_id;
                                    amount = 0;
                                    extensible = #Text("owner canceled");
                                };
                                timestamp = state.get_time();
                            }, caller)){
                                case(#ok(new_trx)){
                                return #ok(#end_sale(new_trx));
                                };
                                case(#err(err)){
                                    return #err(err);
                                };
                            };

                         };
                        
                         return #err(Types.errors(#sale_not_over, "end_sale_nft_origyn - auction still running ", ?caller));
               
                    };
                    
                 };

                                    debug if(debug_channel.end_sale) D.print("checking reserve" # debug_show(config.reserve));
                


                //check reserve MKT0038
                switch(config.reserve){
                    case(?reserve){
                        if(current_sale_state.current_bid_amount < reserve){
                            //end sale but don't move NFT
                            current_sale_state.status := #closed; 
                            

                            switch(Metadata.add_transaction_record(state,{
                                token_id = token_id;
                                index = 0;
                                txn_type = #sale_ended {
                                    seller = owner;
                                    buyer = owner;
                                    token = config.token;
                                    sale_id = ?current_sale.sale_id;
                                    amount = 0;
                                    extensible = #Text("reserve not met");
                                };
                                timestamp = state.get_time();
                            }, caller)){
                                case(#ok(new_trx)){
                                return #ok(#end_sale(new_trx));
                                };
                                case(#err(err)){
                                    return #err(err);
                                };
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
                                token = config.token;
                                sale_id = ?current_sale.sale_id;
                                amount = 0;
                                extensible = #Text("no bids");
                            };
                            timestamp = state.get_time();
                        }, caller)){
                            case(#ok(new_trx)){
                                return #ok(#end_sale(new_trx));
                            };
                            case(#err(err)){
                                return #err(err);
                            };
                        };


                        
                        
                    };
                    case(?winning_escrow){
                                            debug if(debug_channel.end_sale) D.print("verifying escrow");
                                            debug if(debug_channel.end_sale) D.print(debug_show(winning_escrow));
                        let verified = switch(verify_escrow_reciept(state, winning_escrow, ?owner, ?current_sale.sale_id)){
                            case(#err(err)){return #err(Types.errors(err.error, "end_sale_nft_origyn verifying escrow " # err.flag_point, ?caller))};
                            case(#ok(res)){
                                res;
                            };
                        };
                                            debug if(debug_channel.end_sale) D.print("verified is  " # debug_show(verified.found_asset));

                        //reentrancy risk so remove the escrow
                                            debug if(debug_channel.end_sale) D.print("putting escrow balance");
                                            debug if(debug_channel.end_sale) D.print(debug_show(winning_escrow));
                        if(verified.found_asset.escrow.amount < winning_escrow.amount){
                            return #err(Types.errors(#no_escrow_found, "end_sale_nft_origyn - error finding escrow, now less than bid " # debug_show(winning_escrow), ?caller));
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
                          case(#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller));
                          case(#ok(new_metadata)) new_metadata;
                        };

                        //move the payment to the sale revenue account
                        //nyi: use transfer batch to split across royalties

                        let (trx_id : Types.TransactionID, account_hash : ?Blob, fee : Nat) = switch(winning_escrow.token){
                            case(#ic(token)){
                                switch(token.standard){
                                    case(#Ledger){
                                                            debug if(debug_channel.end_sale) D.print("found ledger");
                                        let checker = Ledger_Interface.Ledger_Interface();
                                        try {
                                          switch(await checker.transfer_sale(state.canister(), winning_escrow, token_id, caller)){
                                              case(#ok(val)){
                                                  (val.0,?val.1.account.sub_account, token.fee);
                                              };
                                              case(#err(err)){
                                                  //put the escrow back because the payment failed
                                                  switch(verify_escrow_reciept(state, winning_escrow, ?owner, null)){
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
                                                  case(#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller));
                                                  case(#ok(new_metadata)) new_metadata;
                                                };
                                                
                                                return #err(Types.errors(err.error, "end_sale_nft_origyn " # err.flag_point, ?caller));
                                              };
                                          };
                                        } catch(e){
                                          //put the escrow back because the payment failed
                                            switch(verify_escrow_reciept(state, winning_escrow, ?owner, null)){
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
                                            case(#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller));
                                            case(#ok(new_metadata)) new_metadata;
                                          };
                                        

                                          return #err(Types.errors(#unauthorized_access, "end_sale_nft_origyn catch branch" # Error.message(e), ?caller));
                                      };

                                    };
                                    case(_){
                                        return #err(Types.errors(#nyi, "end_sale_nft_origyn - non ic type nyi - " # debug_show(token), ?caller));
                                    };
                                };
                            };
                            case(#extensible(val)){
                                return #err(Types.errors(#nyi, "end_sale_nft_origyn - extensible token nyi - " # debug_show(val), ?caller));
                            };
                        };

      
                        //change owner
                        var new_metadata : CandyTypes.CandyValue = switch(Metadata.set_nft_owner(state, token_id, winning_escrow.buyer, caller)){
                            case(#ok(new_metadata)){new_metadata};
                            case(#err(err)){
                              //changing owner failed but the tokens are already gone....what to do...leave up to governance
                              return #err(Types.errors(#update_class_error, "end_sale_nft_origyn - error setting owner " # token_id, ?caller));
                            };
                        };

                                            debug if(debug_channel.end_sale) D.print("updating metadata");

                        //clear shared wallets
                        new_metadata := Metadata.set_system_var(new_metadata, Types.metadata.__system_wallet_shares, #Empty);
                        Map.set(state.state.nft_metadata, Map.thash, token_id, new_metadata);

                        current_sale_state.end_date := state.get_time();
                        current_sale_state.status := #closed;
                        current_sale_state.winner := ?winning_escrow.buyer;
                        

                        //log royalties
                        //currently for auctions there are only secondary royalties
                        let royalty= switch(Properties.getClassProperty(metadata, Types.metadata.__system)){
                                case(null){
                                    [];
                                };
                                case(?val){
                                    
                                    switch(Properties.getClassProperty(val.value, Types.metadata.__system_secondary_royalty)){
                                        case(null){
                                             [];
                                        };
                                        case(?list){
                                           switch(list.value){
                                                case(#Array(the_array)){
                                                    switch(the_array){
                                                        case(#thawed(val)){
                                                            val;
                                                        };
                                                        case(#frozen(val)){
                                                            val;
                                                        };
                                                    };
                                                };
                                                case(_){
                                                    [];
                                                };
                                           };
                                        };
                                    };
                                    
                                };
                            };
                        


                        //let royaltyList = Buffer.Buffer<(Types.Account, Nat)>(royalty.size() + 1);
                        if(winning_escrow.amount > fee){
                            //if the fee is bigger than the amount we aren't going to pay anything
                            //this should really be prevented elsewhere
                            let total = Nat.sub(winning_escrow.amount, fee);
                            var remaining = Nat.sub(winning_escrow.amount, fee);
                            

                            let royalty_result =  _process_royalties(state, {
                                var remaining = remaining;
                                total = total;
                                fee = fee;
                                escrow = winning_escrow;
                                royalty = royalty;
                                broker_id = current_sale_state.current_broker_id;
                                original_broker_id = current_sale.original_broker_id;
                                sale_id = ?current_sale.sale_id;
                                account_hash = account_hash;
                                metadata = metadata;
                                token_id = ?token_id
                            }, caller);

                            remaining := royalty_result.0;
                        

                            
                            //D.print("putting Sales balance");
                            //D.print(debug_show(winning_escrow));

                            let new_sale_balance = put_sales_balance(state, {
                                amount = remaining;
                                seller = winning_escrow.seller;
                            
                                buyer = winning_escrow.buyer;
                                token = winning_escrow.token;
                                token_id = winning_escrow.token_id;
                                sale_id = ?current_sale.sale_id;
                                lock_to_date = null;
                                account_hash = account_hash;
                            }, true);

                            let service : Types.Service = actor((Principal.toText(state.canister())));
                            let request_buffer = Buffer.Buffer<Types.ManageSaleRequest>(royalty_result.1.size() + 1);

                            request_buffer.add(#withdraw(#sale({
                              amount = new_sale_balance.amount;
                              buyer = new_sale_balance.buyer;
                              seller = new_sale_balance.seller;
                              token = new_sale_balance.token;
                              token_id = new_sale_balance.token_id;
                              withdraw_to = new_sale_balance.seller;}
                            )));
                            for(thisRoyalty in royalty_result.1.vals()){
                              request_buffer.add(#withdraw(#sale({
                                amount = thisRoyalty.amount;
                                buyer = thisRoyalty.buyer;
                                seller = thisRoyalty.seller;
                                token = thisRoyalty.token;
                                token_id = thisRoyalty.token_id;
                                withdraw_to = thisRoyalty.seller;})));
                            };
                            D.print("attempt to distribute royalties request auction" # debug_show(request_buffer.toArray()));
                            let future = await service.sale_batch_nft_origyn(request_buffer.toArray());
                            D.print("attempt to distribute royalties auction" # debug_show(future));
                        };

                        switch(Metadata.add_transaction_record(state,{
                            token_id = token_id;
                            index = 0;
                            txn_type = #sale_ended {
                                seller = winning_escrow.seller;
                                buyer = winning_escrow.buyer;
                                token = winning_escrow.token;
                                sale_id = ?current_sale.sale_id;
                                amount = winning_escrow.amount;
                                
                                extensible = #Empty;
                            };
                            timestamp = state.get_time();
                        }, caller)){
                                case(#ok(new_trx)){
                                    return #ok(#end_sale(new_trx));
                                };
                                case(#err(err)){
                                    return #err(err);
                                };
                            };
                    };
                };
            };
            case(_){
                return #err(Types.errors(#sale_not_found, "end_sale_nft_origyn - not an auction type ", ?caller));

            };
        };

        return #err(Types.errors(#nyi, "end_sale_nft_origyn - nyi - " , ?caller));

    };

    


    public func distribute_sale(state : StateAccess, request: Types.DistributeSaleRequest, caller: Principal) : async Result.Result<Types.ManageSaleResponse,Types.OrigynError>{
      if(NFTUtils.is_owner_network(state, caller) == false){
        return #err(Types.errors(#unauthorized_access, "distribute_sale - not a canister owner or network", ?caller));
      };

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
                    amount = this_token.1.amount;
                    buyer = this_token.1.buyer;
                    seller = this_token.1.seller;
                    token = this_token.1.token;
                    token_id = this_token.1.token_id;
                    withdraw_to = this_token.1.seller;})));
              };
            };
          };
        };

      let service : Types.Service = actor((Principal.toText(state.canister())));
      let future = await service.sale_batch_nft_origyn(request_buffer.toArray());
      return #ok(#distribute_sale(future));
    };

    //processes a change in escrow balance
    public func put_escrow_balance(
        state: StateAccess, 
        escrow: Types.EscrowRecord, 
        append: Bool): Types.EscrowRecord{
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
                if(escrow.token_id != ""){
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
            case(?val){
                val;
            };
        };

        var a_token_id = switch(Map.get<Text, MigrationTypes.Current.EscrowLedgerTrie>(a_to, Map.thash, escrow.token_id)){
            case(null){
                let new_token_id = Map.new<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>();
                Map.set<Text, MigrationTypes.Current.EscrowLedgerTrie>(a_to, Map.thash, escrow.token_id, new_token_id);
                new_token_id;
            };
            case(?val){
                val;
            };
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
                        account_hash = escrow.account_hash;
                        amount = val.amount + escrow.amount;
                        seller = escrow.seller;
                        buyer = escrow.buyer;
                        balances = null;
                        token = escrow.token;
                        token_id = escrow.token_id;
                        sale_id = escrow.sale_id; //the user has staked for a new sale and we should use the new one.
                        lock_to_date = escrow.lock_to_date;
                    };
                } else {
                     {
                        account_hash = escrow.account_hash;
                        amount = escrow.amount;
                        seller = escrow.seller;
                        buyer = escrow.buyer;
                        balances = null;
                        token = escrow.token;
                        token_id = escrow.token_id;
                        sale_id = escrow.sale_id;
                        lock_to_date = escrow.lock_to_date;
                    };
                };
                Map.set<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, escrow.token, newLedger);
                return newLedger;
            };
        };

    };

    //processes a changing sale balance
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
            case(?val){
                val;
            };
        };

        var a_from = switch(Map.get<Types.Account, MigrationTypes.Current.SalesTokenIDTrie>(a_to, account_handler, sale_balance.buyer)){
            case(null){
                let new_from = Map.new<Text,
                                Map.Map<Types.TokenSpec,Types.EscrowRecord>>();
                Map.set<Types.Account, MigrationTypes.Current.SalesTokenIDTrie>(a_to, account_handler, sale_balance.buyer, new_from);
                new_from;
            };
            case(?val){
                val;
            };
        };

        var a_token_id = switch(Map.get<Text, MigrationTypes.Current.SalesLedgerTrie>(a_from, Map.thash, sale_balance.token_id)){
            case(null){
                let new_token_id = Map.new<Types.TokenSpec,Types.EscrowRecord>();
                Map.set(a_from, Map.thash, sale_balance.token_id, new_token_id);
                new_token_id;
            };
            case(?val){
                val;
            };
        };

        switch(Map.get<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, sale_balance.token)){
            case(null){


                Map.set<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, sale_balance.token, sale_balance);
                return sale_balance;
            };
            case(?val){


                //note: sale_id will overwrite to save user clicks; alternative is to make them clear it and submit a new escrow
                //nyi: add transaction for overwriting sale id

                let newLedger = if(append == true){
                    
                    {
                        account_hash = sale_balance.account_hash;
                        
                        amount = val.amount + sale_balance.amount;
                        seller = sale_balance.seller;
                        buyer = sale_balance.buyer;
                        token = sale_balance.token;
                        token_id = sale_balance.token_id;
                        sale_id = sale_balance.sale_id;
                        lock_to_date = sale_balance.lock_to_date;
                    } //this is a more recent sales id so we use it
                } else {{
                        account_hash = sale_balance.account_hash;
                        
                        amount = sale_balance.amount;
                        seller = sale_balance.seller;
                        buyer = sale_balance.buyer;
                        token = sale_balance.token;
                        token_id = sale_balance.token_id;
                        sale_id = sale_balance.sale_id; 
                        lock_to_date = sale_balance.lock_to_date;
                    
                    }
                };
                Map.set<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, sale_balance.token, newLedger);
                return newLedger;
            };
        };

    };

    //handles async market transfer operations like instant where interaction with other canisters is required
    public func market_transfer_nft_origyn_async(state: StateAccess, request : Types.MarketTransferRequest, caller: Principal) : async Result.Result<Types.MarketTransferRequestReponse,Types.OrigynError> {
        
                             debug if(debug_channel.market) D.print("in market_transfer_nft_origyn");
        var metadata = switch(Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)){
            case(#err(err)){
                return #err(Types.errors(#token_not_found, "market_transfer_nft_origyn " # err.flag_point, ?caller));
            };
            case(#ok(val)){
                val;
            };
        };


                             debug if(debug_channel.market) D.print("have metadata" # debug_show(metadata));

        let owner = switch(
            Metadata.get_nft_owner(metadata)){
                case(#err(err)){
                    return #err(Types.errors(err.error, "market_transfer_nft_origyn " # err.flag_point, ?caller));
                };
                case(#ok(val)){
                    val;
                };
        };

                                 debug if(debug_channel.market) D.print("have owner " # debug_show(owner));
                                 debug if(debug_channel.market) D.print("the caller" # debug_show(caller));

        //check to see if there is a current sale going on MKT0018

        let this_is_minted = Metadata.is_minted(metadata);

        
                                 debug if(debug_channel.market) D.print(request.token_id # " isminted" # debug_show(this_is_minted));
        if(this_is_minted){


            //can't start auction if token is soulbound
            if (Metadata.is_soulbound(metadata)) {
                return #err(Types.errors(#token_non_transferable, "market_transfer_nft_origyn ", ?caller));
            };

            //can't start auction if token is soulbound
            if (Metadata.is_soulbound(metadata)) {
                return #err(Types.errors(#token_non_transferable, "market_transfer_nft_origyn ", ?caller));
            };

            //this is a minted NFT - only the nft owner or nft manager can sell it
            switch(Metadata.is_nft_owner(metadata, #principal(caller))){
              case(#err(err)){return #err(Types.errors(err.error, "market_transfer_nft_origyn - not an owner of the NFT - minted sale" # err.flag_point, ?caller))};
              case(#ok(val)){
                if(val == false){return #err(Types.errors(#unauthorized_access, "market_transfer_nft_origyn - not an owner of the NFT - minted sale", ?caller))};
              };
            };
        } else {
            //this is a staged NFT it can be sold by the canister owner or the canister manager
            if(NFTUtils.is_owner_manager_network(state,caller) == false){return #err(Types.errors(#unauthorized_access, "market_transfer_nft_origyn - not an owner of the canister - staged sale ", ?caller))};
            switch(owner){
              case(#extensible(ex)){
                if(Conversions.valueToText(ex) == "trx in flight"){
                  return #err(Types.errors(#unauthorized_access, "market_transfer_nft_origyn - not an owner of the canister - staged sale - trx in flight", ?caller))
                };
              };
              case(_){};
            };
        };

                             debug if(debug_channel.market) D.print("have minted " # debug_show(this_is_minted));

        //look for an existing sale
        switch(is_token_on_sale(state, metadata, caller)){
            case(#err(err)){return #err(Types.errors(err.error, "market_transfer_nft_origyn ensure_no_sale " # err.flag_point, ?caller))};
            case(#ok(val)){
                if(val == true){
                    return #err(Types.errors(#existing_sale_found, "market_transfer_nft_origyn - sale exists " # request.token_id , ?caller));
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
                switch(request.sales_config.escrow_receipt){
                    case(null){
                        //we can't insta transfer because no instructions are given
                        //D.print("no escrow set");

                        return #err(Types.errors(#improper_interface, "market_transfer_nft_origyn verifying escrow - not included ", ?caller));
                            
                    };
                    case(?escrow){
                        //we should verify the escrow
                        if(this_is_minted){
                            if(escrow.token_id == ""){
                                //can't escrow to general for minted item
                                return #err(Types.errors(#no_escrow_found, "market_transfer_nft_origyn can't find specific escrow for minted item", ?caller));
                            };
                        };
                                            debug if(debug_channel.market) D.print("current escrow is");
                                            
                        //verify the specific escrow

                                            debug if(debug_channel.market) D.print(debug_show(escrow.seller));
                                            debug if(debug_channel.market) D.print(debug_show(escrow.buyer));
                                            debug if(debug_channel.market) D.print(escrow.token_id);
                                            debug if(debug_channel.market) D.print(debug_show(Types.token_hash(escrow.token)));
                                            debug if(debug_channel.market) D.print(debug_show(escrow.amount));
                        
                        let verified = switch(verify_escrow_reciept(state, escrow, ?owner, null)){
                            case(#err(err)){
                              //we can't inline here becase the buyer isn't the caller and a malicious collection owner could sell a depositor something they did not want.
                              return #err(Types.errors(err.error, "market_transfer_nft_origyn auto try escrow failed " # err.flag_point, ?caller))
                            };
                            case(#ok(res)){
                                res;
                            };
                        };

                        

                        //reentrancy risk so we remove the credit from the escrow
                                            debug if(debug_channel.market) D.print("updating the asset list");
                                            debug if(debug_channel.market) D.print(debug_show(Map.size(verified.found_asset_list)));
                                            debug if(debug_channel.market) D.print(debug_show(Iter.toArray(Map.entries(verified.found_asset_list))));
                        if(verified.found_asset.escrow.amount > escrow.amount){
                                                debug if(debug_channel.market) D.print("should be overwriting escrow" # debug_show((verified.found_asset.escrow.amount,escrow.amount)));
                            Map.set(verified.found_asset_list, token_handler, verified.found_asset.token_spec, {
                                account_hash = verified.found_asset.escrow.account_hash;
                                amount = Nat.sub(verified.found_asset.escrow.amount,escrow.amount);
                                seller = verified.found_asset.escrow.seller;
                                balances = null;
                                buyer = verified.found_asset.escrow.buyer;
                                token_id = verified.found_asset.escrow.token_id;
                                token = verified.found_asset.escrow.token;
                                sale_id = verified.found_asset.escrow.sale_id; 
                                lock_to_date = verified.found_asset.escrow.lock_to_date;//should be null
                                });
                        } else {
                                                debug if(debug_channel.market) D.print("should be deleting escrow" # debug_show((verified.found_asset.token_spec)));
                            Map.delete(verified.found_asset_list, token_handler, verified.found_asset.token_spec);
                        };

                                                debug if(debug_channel.market) D.print(debug_show(Map.size(verified.found_asset_list)));
                                                debug if(debug_channel.market) D.print(debug_show(Iter.toArray(Map.entries(verified.found_asset_list))));
                        
                        //reentrancy risk so set the owner to a black hole while transaction is in flight
                        metadata := switch(Metadata.set_nft_owner(state, request.token_id, #extensible(#Text("trx in flight")), caller)){
                          case(#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller));
                          case(#ok(new_metadata)) new_metadata;
                        };
                        
                            

                        let (trx_id : Types.TransactionID, account_hash : ?Blob, fee : Nat) = switch(escrow.token){
                            case(#ic(token)){
                                switch(token.standard){
                                    case(#Ledger){
                                                            debug if(debug_channel.market) D.print("found ledger and sending sale " # debug_show(escrow));
                                        let checker = Ledger_Interface.Ledger_Interface();
                                        try{
                                            switch(await checker.transfer_sale(state.canister(), escrow, request.token_id, caller)){
                                                case(#ok(val)){
                                                    (val.0, ?val.1.account.sub_account, val.2);
                                                };
                                                case(#err(err)){
                                                    
                                                    
                                                    //put the escrow back because the payment failed
                                                    switch(verify_escrow_reciept(state, escrow, ?owner, null)){
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
                                                    };

                                                    //put the owner back if the transaction fails
                                                    metadata := switch(Metadata.set_nft_owner(state, request.token_id, owner, caller)){
                                                      case(#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller));
                                                      case(#ok(new_metadata)) new_metadata;
                                                    };

                                                    return #err(Types.errors(err.error, "market_transfer_nft_origyn instant " # err.flag_point, ?caller));
                                                };
                                            };
                                        } catch (e){
                                            

                                            //put the escrow back because payment failed
                                            switch(verify_escrow_reciept(state, escrow, ?owner, null)){
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
                                            };

                                            //put the owner back if the transaction fails
                                            metadata := switch(Metadata.set_nft_owner(state, request.token_id, owner, caller)){
                                              case(#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller));
                                              case(#ok(new_metadata)) new_metadata;
                                            };

                                    
                                            return #err(Types.errors(#unauthorized_access, "market_transfer_nft_origyn instant catch branch" # Error.message(e), ?caller));

                                            
                                        };

                                    };
                                    case(_){
                                        return #err(Types.errors(#nyi, "market_transfer_nft_origyn - ic type nyi - " # debug_show(token), ?caller));
                                    };
                                };
                            };
                            case(#extensible(val)){
                                return #err(Types.errors(#nyi, "market_transfer_nft_origyn - extensible token nyi - " # debug_show(val), ?caller));
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
                                  switch(verify_escrow_reciept(state, escrow, ?owner, null)){
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
                                  };

                                  //put the owner back if the transaction fails
                                  metadata := switch(Metadata.set_nft_owner(state, request.token_id, owner, caller)){
                                    case(#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller));
                                    case(#ok(new_metadata)) new_metadata;
                                  };
                                
                                    return #err(Types.errors(err.error, "market_transfer_nft_origyn mint attempt" # err.flag_point, ?caller));
                                };
                                case(#ok(val)){
                                                            debug if(debug_channel.market) D.print("updating metadata after mint");
                                    metadata := val.1;
                                    val.2;
                                };
                            };
                        } else{

                            //change owner
                            var new_metadata = switch(Metadata.set_nft_owner(state, request.token_id, escrow.buyer, caller)){
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
                                      return #err(Types.errors(#update_class_error, "Market transfer Origyn - error setting owner item is now in limbo, use governance to fix" # escrow.token_id, ?caller));
                              };

                              case(#ok(new_metadata)) new_metadata;
                            };
                            

                            metadata := Metadata.set_system_var(new_metadata, Types.metadata.__system_wallet_shares, #Empty);

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
                                    extensible = #Empty;
                                });
                                timestamp = Time.now();
                            }, caller)){
                                case(#err(err)){return #err(Types.errors(err.error, "market_transfer_nft_origyn adding transaction" # err.flag_point, ?caller));};
                                case(#ok(val)){val};
                            };
                        };

                        //escrow already invalidated
                        //calculate royalties
                                            debug if(debug_channel.market) D.print("trying to invalidate asset");
                                            debug if(debug_channel.market) D.print(debug_show(verified.found_asset));

                                            debug if(debug_channel.market) D.print("calculating royalty");
                        
                        let royalty = if(b_freshmint == false){
                            //secondary
                            switch(Properties.getClassProperty(metadata, Types.metadata.__system)){
                                case(null){
                                    D.print("no system");
                                    [];
                                };
                                case(?val){
                                    
                                    switch(Properties.getClassProperty(val.value, Types.metadata.__system_secondary_royalty)){
                                        case(null){
                                                                debug if(debug_channel.market) D.print("no secondary");
                                             [];
                                        };
                                        case(?list){
                                           switch(list.value){
                                                case(#Array(the_array)){
                                                    switch(the_array){
                                                        case(#thawed(val)){
                                                            val;
                                                        };
                                                        case(#frozen(val)){
                                                            val;
                                                        };
                                                    };
                                                };
                                                case(_){
                                                                    debug if(debug_channel.market)  D.print("no Array" # debug_show(list));
                                                    [];
                                                };
                                           };
                                        };
                                    };
                                    
                                };
                            };
                        } else {
                            //primary
                            switch(Properties.getClassProperty(metadata, Types.metadata.__system)){
                                case(null){
                                                            debug if(debug_channel.market) D.print("no system");
                                    [];
                                };
                                case(?val){
                                    switch(Properties.getClassProperty(val.value, Types.metadata.__system_primary_royalty)){
                                        case(null){
                                                                debug if(debug_channel.market) D.print("no primary" # debug_show(val.value));
                                             [];
                                        };
                                        case(?list){
                                           switch(list.value){
                                                case(#Array(the_array)){
                                                    switch(the_array){
                                                        case(#thawed(val)){
                                                            val;
                                                        };
                                                        case(#frozen(val)){
                                                            val;
                                                        };
                                                    };
                                                };
                                                case(_){
                                                                        debug if(debug_channel.market) D.print("no Array" # debug_show(list));
                                                    [];
                                                };
                                           };
                                        };
                                    };
                                    
                                };
                            };
                        };

                                                debug if(debug_channel.market) D.print("royalty is " # debug_show(royalty));
                        //note: this code path is always taken since checker.transferSale requires it or errors
                        //we have included it here so that we can use Nat.sub without fear of underflow
                        
                        if(escrow.amount > fee){
                            let total = Nat.sub(escrow.amount, fee);
                            var remaining = Nat.sub(escrow.amount, fee);
                            

                            D.print("calling process royalty" # debug_show((total,remaining)));
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
                            }, caller);

                            remaining := royalty_result.0;


                            D.print("done with royalty" # debug_show((total,remaining)));
                                
                            let new_sale_balance = put_sales_balance(state, {
                                amount = remaining;
                                seller = verified.found_asset.escrow.seller;
                            
                                buyer = verified.found_asset.escrow.buyer;
                                token = verified.found_asset.escrow.token;
                                token_id = verified.found_asset.escrow.token_id;
                                sale_id = null;
                                lock_to_date = null;
                                account_hash = account_hash;
                            }, true);

                            let service : Types.Service = actor((Principal.toText(state.canister())));
                            let request_buffer = Buffer.Buffer<Types.ManageSaleRequest>(royalty_result.1.size() + 1);

                            request_buffer.add(#withdraw(#sale({
                              amount = new_sale_balance.amount;
                              buyer = new_sale_balance.buyer;
                              seller = new_sale_balance.seller;
                              token = new_sale_balance.token;
                              token_id = new_sale_balance.token_id;
                              withdraw_to = new_sale_balance.seller;}
                            )));

                            for(thisRoyalty in royalty_result.1.vals()){
                              request_buffer.add(#withdraw(#sale({
                                amount = thisRoyalty.amount;
                                buyer = thisRoyalty.buyer;
                                seller = thisRoyalty.seller;
                                token = thisRoyalty.token;
                                token_id = thisRoyalty.token_id;
                                withdraw_to = thisRoyalty.seller;})));
                            };
                            D.print("attempt to distribute royalties request instant" # debug_show(request_buffer.toArray()));

                            let future = await service.sale_batch_nft_origyn(request_buffer.toArray());
                            D.print("attempt to distribute royalties instant" # debug_show(future));


                        };

                        return #ok(txn_record);





                    };
                };
            };
            case(_){
                return #err(Types.errors(#nyi, "market_transfer_nft_origyn nyi pricing type async", ?caller));
            };
        };

        return #err(Types.errors(#nyi, "market_transfer_nft_origyn nyi ", ?caller));
    };

    //handles royalty distribution
    private func _process_royalties(state : StateAccess, request : {
        var remaining: Nat;
        total: Nat;
        fee: Nat;
        account_hash: ?Blob;
        royalty: [CandyTypes.CandyValue];
        escrow: Types.EscrowReceipt;
        broker_id: ?Principal;
        original_broker_id: ?Principal;
        sale_id: ?Text;
        metadata : CandyTypes.CandyValue;
        token_id: ?Text
    }, caller: Principal) : (Nat, [Types.EscrowRecord]){

                            debug if(debug_channel.royalties) D.print("in process royalty" # debug_show(request));

        let results = Buffer.Buffer<Types.EscrowRecord>(1);
        for(this_item in request.royalty.vals()){
            switch(this_item){
                case(#Class(the_array)){
                                        debug if(debug_channel.royalties) D.print("getting items from class " # debug_show(this_item));
                    
                    let rate = switch(Properties.getClassProperty(this_item, "rate")){
                        case(null){0:Float};
                        case(?val){
                            switch(val.value){
                                case(#Float(val)){
                                    val;
                                };
                                case(_){0:Float};
                            };
                        };
                    };

                    let tag = switch(Properties.getClassProperty(this_item, "tag")){
                        case(null){"other"}; 
                        case(?val){
                            switch(val.value){
                                case(#Text(val)){
                                    val;
                                };
                                case(_){"other"}; 
                            };
                        };
                    };

                    let principal = switch(Properties.getClassProperty(this_item, "account")){
                        case(null){
                            if(tag == Types.metadata.royalty_network){
                                switch(state.state.collection_data.network){
                                    case(null){[Principal.fromText("yfhhd-7eebr-axyvl-35zkt-z6mp7-hnz7a-xuiux-wo5jf-rslf7-65cqd-cae")]}; //dev fund
                                    case(?val){[val]};
                                };
                            } else if(tag == Types.metadata.royalty_node){
                                let val = Metadata.get_system_var(request.metadata, Types.metadata.__system_node);
                                switch(val){
                                    case(#Empty){[Principal.fromText("yfhhd-7eebr-axyvl-35zkt-z6mp7-hnz7a-xuiux-wo5jf-rslf7-65cqd-cae")]}; //dev fund
                                    case(#Principal(val)){
                                        [val]
                                    };
                                    case(_){
                                        [Principal.fromText("yfhhd-7eebr-axyvl-35zkt-z6mp7-hnz7a-xuiux-wo5jf-rslf7-65cqd-cae")]
                                    };
                                
                                };
                            } else if(tag == Types.metadata.royalty_originator){
                                let val = Metadata.get_system_var(request.metadata, Types.metadata.__system_originator);
                                switch(val){
                                    case(#Empty){[Principal.fromText("yfhhd-7eebr-axyvl-35zkt-z6mp7-hnz7a-xuiux-wo5jf-rslf7-65cqd-cae")]}; //dev fund
                                    case(#Principal(val)){
                                        [val]
                                    };
                                    case(_){
                                        [Principal.fromText("yfhhd-7eebr-axyvl-35zkt-z6mp7-hnz7a-xuiux-wo5jf-rslf7-65cqd-cae")]
                                    };
                                };
                            } else if(tag == Types.metadata.royalty_broker){
                                switch(request.broker_id, request.original_broker_id){
                                    case(null, null){[Principal.fromText("yfhhd-7eebr-axyvl-35zkt-z6mp7-hnz7a-xuiux-wo5jf-rslf7-65cqd-cae")]}; //dev fund
                                    case(?val, null){[val]};
                                    case(null, ?val2){[val2]};
                                    case(?val, ?val2){
                                      if(val == val2){
                                        [val];
                                      } else {
                                        [val, val2]
                                      };
                                    };
                                };

                            } else { 
                                [Principal.fromText("yfhhd-7eebr-axyvl-35zkt-z6mp7-hnz7a-xuiux-wo5jf-rslf7-65cqd-cae")]; //dev fund
                            };
                        };  //dev fund
                        case(?val){
                            switch(val.value){
                                case(#Principal(val)){
                                    [val];
                                };
                                case(_){[Principal.fromText("yfhhd-7eebr-axyvl-35zkt-z6mp7-hnz7a-xuiux-wo5jf-rslf7-65cqd-cae")]}; //dev fund
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
                            let id = Metadata.add_transaction_record(state, {
                                token_id = request.escrow.token_id;
                                index = 0;
                                txn_type = #royalty_paid {
                                    seller = request.escrow.seller;
                                    buyer = request.escrow.buyer;
                                    token = request.escrow.token;
                                    sale_id = request.sale_id;
                                    amount = this_royalty;
                                    tag = tag;
                                    reciever = #principal(this_principal);
                                    extensible = switch(request.token_id){
                                      case(null){
                                        #Empty;
                                      };
                                      case(?token_id){
                                        #Text(token_id)
                                      }
                                    };
                                };
                                timestamp = state.get_time();
                            }, caller);

                                                debug if(debug_channel.royalties) D.print("added trx" # debug_show(id));
                            let new_sale_balance = put_sales_balance(state, {
                                amount = this_royalty;
                                seller = #principal(this_principal);
                                buyer = request.escrow.buyer;
                                token = request.escrow.token;
                                token_id = request.escrow.token_id;
                                sale_id = request.sale_id;
                                lock_to_date = null;
                                account_hash = request.account_hash;
                            }, true);

                            results.add(new_sale_balance);
                                                debug if(debug_channel.royalties) D.print("new_sale_balance" # debug_show(new_sale_balance));


                        } else {
                            //can't pay out if less than fee
                        };

                    };
                    
                    
                };
                case(_){};
                
            };
                
            
            
        };

        return (request.remaining, results.toArray());
    };

    //handles non-async market functions like starting an auction
    public func market_transfer_nft_origyn(state: StateAccess, request : Types.MarketTransferRequest, caller: Principal) : Result.Result<Types.MarketTransferRequestReponse,Types.OrigynError> {
        
                            debug if(debug_channel.market) D.print("in market_transfer_nft_origyn");
        var metadata = switch(Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)){
            case(#err(err)){
                return #err(Types.errors(#token_not_found, "market_transfer_nft_origyn " # err.flag_point, ?caller));
            };
            case(#ok(val)){
                val;
            };
        };
                            debug if(debug_channel.market) D.print("have metadata");

        


        //can't start auction if token is a phisycal object unless in escrow with a node
        if (Metadata.is_physical(metadata)) {
          if (Metadata.is_in_physical_escrow(metadata) == false) {
            return #err(Types.errors(#token_non_transferable, "market_transfer_nft_origyn physical token must be escrowed", ?caller));
          };
        };

        let owner = switch(
            Metadata.get_nft_owner(metadata)){
                case(#err(err)){
                    return #err(Types.errors(err.error, "market_transfer_nft_origyn " # err.flag_point, ?caller));
                };
                case(#ok(val)){
                    val;
                };
        };

                            debug if(debug_channel.market) D.print("have owner " # debug_show(owner));
                            debug if(debug_channel.market) D.print("the caller" # debug_show(caller));

        //check to see if there is a current sale going on MKT0018

        let this_is_minted = Metadata.is_minted(metadata);
                            debug if(debug_channel.market) D.print(request.token_id # " isminted" # debug_show(this_is_minted));
        if(this_is_minted){

            //can't start auction if token is soulbound
            if (Metadata.is_soulbound(metadata)) {
                return #err(Types.errors(#token_non_transferable, "market_transfer_nft_origyn ", ?caller));
            };

            //this is a minted NFT - only the nft owner or nft manager can sell it
            switch(Metadata.is_nft_owner(metadata, #principal(caller))){
              case(#err(err)){return #err(Types.errors(err.error, "market_transfer_nft_origyn - not an owner of the NFT - minted sale" # err.flag_point, ?caller))};
              case(#ok(val)){
                if(val == false){return #err(Types.errors(#unauthorized_access, "market_transfer_nft_origyn - not an owner of the NFT - minted sale", ?caller))};
              };
            };
        } else {
            //this is a staged NFT it can be sold by the canister owner or the canister manager
            if(NFTUtils.is_owner_manager_network(state,caller) == false){return #err(Types.errors(#unauthorized_access, "market_transfer_nft_origyn - not an owner of the canister - staged sale ", ?caller))};
        };

                            debug if(debug_channel.market) D.print("have minted " # debug_show(this_is_minted));

        //look for an existing sale
        switch(is_token_on_sale(state, metadata, caller)){
            case(#err(err)){return #err(Types.errors(err.error, "market_transfer_nft_origyn ensure_no_sale " # err.flag_point, ?caller))};
            case(#ok(val)){
                if(val == true){
                    return #err(Types.errors(#existing_sale_found, "market_transfer_nft_origyn - sale exists " # request.token_id , ?caller));
                };
            };
            
        };

                           debug if(debug_channel.market) D.print("checking pricing");

        switch(request.sales_config.pricing){
            case(#auction(auction_details)){
                //what does an escrow reciept do for an auction? Place a bid?
                //for now ignore
                switch(request.sales_config.escrow_receipt){
                    case(?val){
                        return #err(Types.errors(#nyi, "market_transfer_nft_origyn - handling escrow for auctions NYI", ?caller))
                    };
                    case(_){};
                };

                switch(auction_details.ending){
                  case(#date(val)){
                    if(val <= auction_details.start_date){
                      return #err(Types.errors(#improper_interface, "market_transfer_nft_origyn - end date cannot be before start date", ?caller))
                    };
                  };
                   case(#waitForQuiet(val)){
                    if(val.date <= auction_details.start_date){
                      return #err(Types.errors(#improper_interface, "market_transfer_nft_origyn - end date cannot be before start date", ?caller))
                    };
                  };
                };
                

                if(this_is_minted == false){
                    return #err(Types.errors(#nyi, "cannot auction off a unminted item", ?caller))
                    
                };

                let h = SHA256.New();
                h.write(Conversions.valueToBytes(#Text("com.origyn.nft.sale-id")));
                h.write(Conversions.valueToBytes(#Text("token-id")));
                h.write(Conversions.valueToBytes(#Text(request.token_id)));
                h.write(Conversions.valueToBytes(#Text("seller")));
                h.write(Conversions.valueToBytes(#Nat(Types.account_hash_uncompressed(owner))));
                h.write(Conversions.valueToBytes(#Text("timestamp")));
                h.write(Conversions.valueToBytes(#Int(state.get_time())));
                let sale_id = Conversions.valueToText(#Bytes(#frozen(h.sum([]))));

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

                var participants = Map.new<Principal, Int>();
                Map.set<Principal, Int>(participants, Map.phash, caller, state.get_time());

                Map.set<Text,Types.SaleStatus>(state.state.nft_sales, Map.thash, sale_id, {
                    sale_id = sale_id;
                    original_broker_id = request.sales_config.broker_id;
                    broker_id = null; //currently the broker id for a auction doesn't do much. perhaps it should split the broker reward?
                    token_id = request.token_id;
                    sale_type = #auction({
                        config = request.sales_config.pricing;
                        var current_bid_amount = 0;
                        var current_broker_id = request.sales_config.broker_id;
                        var end_date = switch(auction_details.ending){
                            case(#date(theDate)){theDate};
                            case(#waitForQuiet(details)){details.date};
                        };
                        var min_next_bid = auction_details.start_price;
                        var current_escrow = null;
                        var wait_for_quiet_count = ?0;
                        var status = if(state.get_time() >= auction_details.start_date){
                            #open;
                        } else {
                            #not_started;
                        };
                        var winner = null;
                        var allow_list = allow_list;
                        var participants = participants
                    });
                });

                //set new saleid
                                   debug if(debug_channel.market) D.print("Setting sale id");
                metadata := Metadata.set_system_var(metadata, Types.metadata.__system_current_sale_id, #Text(sale_id));

                Map.set(state.state.nft_metadata, Map.thash, request.token_id, metadata);

                let this_ledger = switch(Map.get(state.state.nft_ledgers, Map.thash, request.token_id)){
                    case(null){
                        let newBuf = SB.init<Types.TransactionRecord>();
                        Map.set(state.state.nft_ledgers, Map.thash, request.token_id, newBuf);
                        newBuf;
                    };
                    case(?val){val;};
                };

                let txn = {
                    token_id = request.token_id;
                    index = SB.size(this_ledger);
                    timestamp = state.get_time();
                    txn_type = #sale_opened({
                        sale_id = sale_id;
                        pricing = request.sales_config.pricing;
                        extensible = #Empty;});
                };
                SB.add(this_ledger, txn);

                return #ok(txn);

            };
            case(_){
                return #err(Types.errors(#nyi, "market_transfer_nft_origyn nyi pricing type", ?caller));
            };
        };

        return #err(Types.errors(#nyi, "market_transfer_nft_origyn nyi ", ?caller));
    };

    //refreshes the offers collection
    public func refresh_offers_nft_origyn(state: StateAccess, request: ?Types.Account, caller: Principal) : Result.Result<Types.ManageSaleResponse, Types.OrigynError>{
        
        let seller = switch(request){
            case(null){
                #principal(caller);
            };
            case(?val){
                if(Types.account_eq(#principal(caller), val)){
                  val;
                } else {
                    if(NFTUtils.is_owner_manager_network(state, caller) == false){return #err(Types.errors(#unauthorized_access, "refresh_offerns_nft_origyn - not an owner", ?caller))};
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

        return #ok(#refresh_offers(offer_results.toArray()));
    };

    //moves tokens from a deposit into an escrow
    public func escrow_nft_origyn(state: StateAccess, request : Types.EscrowRequest, caller: Principal) : async Result.Result<Types.ManageSaleResponse,Types.OrigynError> {
        //can someone escrow for someone else? No. Only a buyer can create an escrow for themselves for now
        //we will also allow a canister/canister owner to create escrows for itself
        if(Types.account_eq(#principal(caller), request.deposit.buyer) == false and 
            Types.account_eq(#principal(caller), #principal(state.canister())) == false and
             Types.account_eq(#principal(caller), #principal(state.state.collection_data.owner)) == false and
               Array.filter<Principal>(state.state.collection_data.managers, func(item: Principal){item == caller}).size() == 0){
            return #err(Types.errors(#unauthorized_access, "escrow_nft_origyn - escrow - buyer and caller do not match", ?caller));
        };

                            debug if(debug_channel.escrow) D.print("in escrow");
                            debug if(debug_channel.escrow) D.print(debug_show(request));
        switch(request.lock_to_date){
            case(?val){
                if(val > state.get_time() *10){ // if an extra digit is fat fingered this will trip....gives 474 years in the future as the max
                    return #err(Types.errors(#improper_interface, "escrow_nft_origyn time lock should not be that far in the future", ?caller));
                
                };
            };
            case(null){};
        };

        
                            debug if(debug_channel.escrow) D.print(debug_show(state.canister()));

        //verify the token
        if(request.token_id != ""){
            let metadata = switch(Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)){
                case(#err(err)){
                    return #err(Types.errors(#token_not_found, "escrow_nft_origyn " # err.flag_point, ?caller));
                };
                case(#ok(val)){
                    val;
                };
            };
            let this_is_minted = Metadata.is_minted(metadata);
            if(this_is_minted == false){
                //cant escrow for an unminted item
                return #err(Types.errors(#token_not_found, "escrow_nft_origyn ", ?caller));
            };

            let owner = switch(
                Metadata.get_nft_owner(metadata)){
                    case(#err(err)){
                        return #err(Types.errors(err.error, "escrow_nft_origyn " # err.flag_point, ?caller));
                    };
                    case(#ok(val)){
                        val;
                    };
            };

            if(owner != request.deposit.seller){
                //cant escrow for an owner that doesn't own the token
                return #err(Types.errors(#escrow_owner_not_the_owner, "escrow_nft_origyn cannot create escrow for item someone does not own", ?caller));
            }
        };


        
        
        //move the deposit to an escrow account
                            debug if(debug_channel.escrow) D.print("verifying the deposit");
       
        let (trx_id : Types.TransactionID, account_hash : ?Blob) = switch(request.deposit.token){
            case(#ic(token)){
                switch(token.standard){
                    case(#Ledger){
                                            debug if(debug_channel.escrow) D.print("found ledger");
                        let checker = Ledger_Interface.Ledger_Interface();
                        switch(await checker.transfer_deposit(state.canister(), request,  caller)){
                            case(#ok(val)){
                                (val.transaction_id, ?val.subaccount_info.account.sub_account);
                            };
                            case(#err(err)){
                                return #err(Types.errors(err.error, "escrow_nft_origyn " # err.flag_point, ?caller));
                            };
                        };

                    };
                    case(_){
                        return #err(Types.errors(#nyi, "escrow_nft_origyn - ic type nyi - " # debug_show(request), ?caller));
                    };
                };
            };
            case(#extensible(val)){
                return #err(Types.errors(#nyi, "escrow_nft_origyn - extensible token nyi - " # debug_show(request), ?caller));
            };
        };

        //put the escrow
                            debug if(debug_channel.escrow) D.print("putting the escrow");
        let escrow_result = put_escrow_balance(state, {
            seller = request.deposit.seller;
            buyer = request.deposit.buyer;
            token = request.deposit.token;
            token_id = request.token_id;
            amount = request.deposit.amount;
            trx_id = trx_id;
            sale_id = request.deposit.sale_id;
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
                seller = request.deposit.seller;
                buyer = request.deposit.buyer;
                token = request.deposit.token;
                token_id = request.token_id;
                amount = request.deposit.amount;
                trx_id = trx_id;
                sale_id = request.deposit.sale_id;
                extensible = #Empty;
            };
            timestamp = state.get_time();
        }, caller)) {
            case(#err(err)){
                                debug if(debug_channel.escrow) D.print("in a bad error");
                                debug if(debug_channel.escrow) D.print(debug_show(err));
                //nyi: this is really bad and will mess up certificatioin later so we should really throw
                return #err(Types.errors(#nyi, "escrow_nft_origyn - extensible token nyi - " # debug_show(request), ?caller));
            };
            case(#ok(new_trx)){new_trx};
        };

                        debug if(debug_channel.escrow) D.print("have the trx");
                        debug if(debug_channel.escrow) D.print(debug_show(new_trx));
        return #ok(#escrow_deposit({
            receipt = {
                seller = request.deposit.seller;
                buyer = request.deposit.buyer;
                token_id = request.token_id;
                token = request.deposit.token;
                amount = request.deposit.amount;
                sale_id = request.deposit.sale_id;
            };
            balance = escrow_result.amount;
            transaction = new_trx;
        }));


    };

    //allows the user to withdraw tokens from an nft canister
    public func withdraw_nft_origyn(state: StateAccess, withdraw: Types.WithdrawRequest, caller: Principal) : async Result.Result<Types.ManageSaleResponse,Types.OrigynError> {
        switch(withdraw){
          case(#deposit(details)){
            D.print("in deposit withdraw");
                                debug if(debug_channel.withdraw_deposit) D.print("an escrow withdraw");
                                debug if(debug_channel.withdraw_deposit) D.print(debug_show(withdraw));
            if(caller != state.canister() and Types.account_eq(#principal(caller), details.buyer) == false){
                //cant withdraw for someone else
                return #err(Types.errors(#unauthorized_access, "withdraw_nft_origyn - escrow - buyer and caller do not match" , ?caller));
            };

                                debug if(debug_channel.withdraw_deposit) D.print("about to verify");
            

            let deposit_account = NFTUtils.get_deposit_info(details.buyer, state.canister());


            //NFT-112
            let fee = switch(details.token){
                case(#ic(token)){

                    if(details.amount <= token.fee){
                        return #err(Types.errors(#withdraw_too_large, "withdraw_nft_origyn - escrow - withdraw fee is larger than amount" , ?caller));
                    };
                    token.fee;
                };
                case(_){return #err(Types.errors(#nyi, "withdraw_nft_origyn - escrow - extensible token nyi - " # debug_show(details), ?caller));
                                };
            };

            //attempt to send payment
                                debug if(debug_channel.withdraw_deposit) D.print("sending payment" # debug_show((details.withdraw_to, details.amount, caller)));
            var transaction_id : ?{trx_id: Types.TransactionID; fee: Nat} = null;
            
            transaction_id := switch(details.token){
                case(#ic(token)){
                    switch(token.standard){
                        case(#Ledger){
                            //D.print("found ledger");
                            let checker = Ledger_Interface.Ledger_Interface();

                                                debug if(debug_channel.withdraw_deposit) D.print("returning amount " # debug_show(details.amount, token.fee));
                            
                            try{
                                switch(await checker.send_payment_minus_fee(details.withdraw_to, token, details.amount, ?deposit_account.account.sub_account, caller)){
                                    case(#ok(val)){
                                        //D.print("Got a val and it it is");
                                        ?val;
                                    };
                                    case(#err(err)){
                                        return #err(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow - ledger payment failed err branch " # err.flag_point, ?caller));
                                    };
                                };
                            } catch (e){
                                
                                return #err(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow - ledger payment failed catch branch " # Error.message(e), ?caller));
                                    
                            };

                        };
                        case(_){
                            return #err(Types.errors(#nyi, "withdraw_nft_origyn - escrow - - ledger type nyi - " # debug_show(details), ?caller));
                        };
                    };
                };
                case(#extensible(val)){
                    return #err(Types.errors(#nyi, "withdraw_nft_origyn - escrow - -  token standard nyi - " # debug_show(details), ?caller));
                };
            };


                                debug if(debug_channel.withdraw_deposit) D.print("succesful transaction :" # debug_show(transaction_id) # debug_show(details));

            switch(transaction_id){
                case(null){
                    //really should have failed already
                    return #err(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow -  payment failed txid null" , ?caller));
                };
                case(?transaction_id){
                    switch(Metadata.add_transaction_record(state,{
                        token_id = "";
                        index = 0;
                        txn_type = #deposit_withdraw({
                            buyer = details.buyer;
                            amount = details.amount - transaction_id.fee;
                            fee = transaction_id.fee;
                            token = details.token;
                            trx_id = transaction_id.trx_id;
                            extensible = #Empty;
                        }
                        );
                        timestamp = state.get_time();
                    }, caller)) {
                        case(#ok(val)){
                            return #ok(#withdraw(val));
                        };
                        case(#err(err)){
                            return #err(Types.errors(err.error, "withdraw_nft_origyn - escrow - ledger not updated" # debug_show(transaction_id) , ?caller));
                        };
                    };



                };
            };
                
           


          };
          case(#escrow(details)){
                                  debug if(debug_channel.withdraw_escrow) D.print("an escrow withdraw");
                                  debug if(debug_channel.withdraw_escrow) D.print(debug_show(withdraw));
              if(caller != state.canister() and Types.account_eq(#principal(caller), details.buyer) == false){
                  //cant withdraw for someone else
                  return #err(Types.errors(#unauthorized_access, "withdraw_nft_origyn - escrow - buyer and caller do not match" , ?caller));
              };
                                  debug if(debug_channel.withdraw_escrow) D.print("about to verify");
              let verified = verify_escrow_reciept(state, details, null, null);
              
              
              switch(verified){
                  case(#ok(verified)){

                      let account_info = NFTUtils.get_escrow_account_info(verified.found_asset.escrow, state.canister());
                      if(verified.found_asset.escrow.amount < details.amount){
                                              debug if(debug_channel.withdraw_escrow) D.print("in check amount " # debug_show(verified.found_asset.escrow.amount) # " " # debug_show( details.amount));
                          return #err(Types.errors(#withdraw_too_large, "withdraw_nft_origyn - escrow - withdraw too large" , ?caller));
                      };

                      let a_ledger = verified.found_asset.escrow;

                      switch(a_ledger.lock_to_date){
                          case(?val){
                                                  debug if(debug_channel.withdraw_escrow) D.print("found a lock date " # debug_show((val, state.get_time())));
                              if(state.get_time() < val){
                                  return #err(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - escrow - this escrow is locked until " # debug_show(val)  , ?caller));
                              };
                          };
                          case(null){
                                                  debug if(debug_channel.withdraw_escrow) D.print("no lock date " # debug_show(( state.get_time())));
                          };
                      };

                      //NFT-112
                      let fee = switch(details.token){
                          case(#ic(token)){

                              if(a_ledger.amount <= token.fee){
                                  return #err(Types.errors(#withdraw_too_large, "withdraw_nft_origyn - escrow - withdraw fee is larger than amount" , ?caller));

                              };
                              token.fee;
                          };
                          case(_){return #err(Types.errors(#nyi, "withdraw_nft_origyn - escrow - extensible token nyi - " # debug_show(details), ?caller));
                                          };
                      };

                      //D.print("got to sale id");

                      switch(a_ledger.sale_id){
                          case(?sale_id){
                              //check that the owner isn't still the bidder in the sale
                              switch(Map.get(state.state.nft_sales, Map.thash,sale_id)){
                                  case(null){
                                      //should be an error because sale id can't be found
                                        return #err(Types.errors(#sale_not_found, "withdraw_nft_origyn - escrow - can't find sale top" # debug_show(a_ledger) #  " " # debug_show(withdraw) , ?caller));
                                  };
                                  case(?val){

                                      

                                                          debug if(debug_channel.withdraw_escrow) D.print("testing current state");

                                      let current_sale_state = switch(NFTUtils.get_auction_state_from_status(val)){
                                          case(#ok(val)){val};
                                          case(#err(err)){
                                              return #err(Types.errors(err.error, "withdraw_nft_origyn - escrow - find state " # err.flag_point, ?caller));
                                          };
                                      };

                                      switch(current_sale_state.status){
                                          case(#open){

                                              D.print(debug_show(current_sale_state));
                                              D.print(debug_show(caller));

                                              //NFT-110
                                              switch(current_sale_state.winner){
                                                  case(?val){
                                                                          debug if(debug_channel.withdraw_escrow) D.print("found a winner");
                                                      if(Types.account_eq(val, details.buyer)){
                                                                              debug if(debug_channel.withdraw_escrow) D.print("should be throwing an error");
                                                          return #err(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - escrow - you are the winner" , ?caller));
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
                                                          D.print("passed");
                                                          return #err(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - escrow - you are the current bid" , ?caller));
                                                      };
                                                  };
                                                  case(nul){
                                                                          debug if(debug_channel.withdraw_escrow) D.print("not a current escrow");
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

                                          debug if(debug_channel.withdraw_escrow) D.print("finding target escrow");
                                          debug if(debug_channel.withdraw_escrow) D.print(debug_show(a_ledger.amount));
                                          debug if(debug_channel.withdraw_escrow) D.print(debug_show(details.amount));
                      //ok...so we should be good to withdraw
                      //first update the escrow
                      if(verified.found_asset.escrow.amount < details.amount){
                          return #err(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - escrow - amount too large ", ?caller));
                      };

                      let target_escrow = {
                          account_hash = verified.found_asset.escrow.account_hash;
                          balances = null;
                          amount = Nat.sub(verified.found_asset.escrow.amount, details.amount);
                          buyer = details.buyer;
                          seller = details.seller;
                          token_id = details.token_id;
                          token = details.token;
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
                                  case(#Ledger){
                                      //D.print("found ledger");
                                      let checker = Ledger_Interface.Ledger_Interface();

                                                          debug if(debug_channel.withdraw_escrow) D.print("returning amount " # debug_show(details.amount, token.fee));
                                      
                                      try{
                                          switch(await checker.send_payment_minus_fee(details.withdraw_to, token, details.amount, ?account_info.account.sub_account, caller)){
                                              case(#ok(val)){
                                                  //D.print("Got a val and it it is");
                                                  ?val;
                                              };
                                              case(#err(err)){
                                                  switch(verify_escrow_reciept(state, details, null, null)){
                                                      case(#ok(reverify)){
                                                          let target_escrow = {
                                                              account_hash = reverify.found_asset.escrow.account_hash;
                                                              amount = Nat.add(reverify.found_asset.escrow.amount, details.amount);
                                                              buyer = reverify.found_asset.escrow.buyer;
                                                              seller = reverify.found_asset.escrow.seller;
                                                              token_id = reverify.found_asset.escrow.token_id;
                                                              token = reverify.found_asset.escrow.token;
                                                              sale_id = reverify.found_asset.escrow.sale_id;
                                                              lock_to_date = reverify.found_asset.escrow.lock_to_date;
                                                          };

                                                          
                                                          Map.set<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>(reverify.found_asset_list, token_handler, details.token, target_escrow);
                                                          

                                                      };
                                                      case(#err(err)){
                                                          let target_escrow = {
                                                              account_hash = a_ledger.account_hash;
                                                              amount =  details.amount;
                                                              buyer = a_ledger.buyer;
                                                              seller = a_ledger.seller;
                                                              token_id = a_ledger.token_id;
                                                              token = a_ledger.token;
                                                              sale_id = a_ledger.sale_id;
                                                              lock_to_date = a_ledger.lock_to_date;
                                                          };

                                                          
                                                          Map.set<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>(verified.found_asset_list, token_handler, details.token, target_escrow);
                                                      }
                                                  };
                                                  
                                                  return #err(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow - ledger payment failed err branch " # err.flag_point, ?caller));
                                              };
                                          };
                                      } catch (e){
                                          //put the escrow back because something went wrong
                                          switch(verify_escrow_reciept(state, details, null, null)){
                                              case(#ok(reverify)){
                                                  let target_escrow = {
                                                      account_hash = reverify.found_asset.escrow.account_hash;
                                                      amount = Nat.add(reverify.found_asset.escrow.amount, details.amount);
                                                      buyer = reverify.found_asset.escrow.buyer;
                                                      seller = reverify.found_asset.escrow.seller;
                                                      token_id = reverify.found_asset.escrow.token_id;
                                                      token = reverify.found_asset.escrow.token;
                                                      sale_id = reverify.found_asset.escrow.sale_id;
                                                      lock_to_date = reverify.found_asset.escrow.lock_to_date;
                                                  };

                                                  
                                                  Map.set<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>(reverify.found_asset_list, token_handler, details.token, target_escrow);
                                                          

                                              };
                                              case(#err(err)){
                                                  let target_escrow = {
                                                      account_hash = a_ledger.account_hash;
                                                      amount =  details.amount;
                                                      buyer = a_ledger.buyer;
                                                      seller = a_ledger.seller;
                                                      token_id = a_ledger.token_id;
                                                      token = a_ledger.token;
                                                      sale_id = a_ledger.sale_id;
                                                      lock_to_date = a_ledger.lock_to_date;
                                                  };

                                                  
                                                  Map.set<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>(verified.found_asset_list, token_handler, details.token, target_escrow);
                                              }
                                          };
                                          return #err(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow - ledger payment failed catch branch " # Error.message(e), ?caller));
                                              
                                      };

                                  };
                                  case(_){
                                      return #err(Types.errors(#nyi, "withdraw_nft_origyn - escrow - - ledger type nyi - " # debug_show(details), ?caller));
                                  };
                              };
                          };
                          case(#extensible(val)){
                              return #err(Types.errors(#nyi, "withdraw_nft_origyn - escrow - -  token standard nyi - " # debug_show(details), ?caller));
                          };
                      };


                                          debug if(debug_channel.withdraw_escrow) D.print("succesful transaction :" # debug_show(transaction_id) # debug_show(details));

                      switch(transaction_id){
                          case(null){
                              //really should have failed already
                              return #err(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow -  payment failed txid null" , ?caller));
                          };
                          case(?transaction_id){
                              switch(Metadata.add_transaction_record(state,{
                                  token_id = details.token_id;
                                  index = 0;
                                  txn_type = #escrow_withdraw({
                                      buyer = details.buyer;
                                      amount = details.amount - transaction_id.fee;
                                      fee = transaction_id.fee;
                                      token = details.token;
                                      seller = details.seller;
                                      token_id = details.token_id;
                                      trx_id = transaction_id.trx_id;
                                      extensible = #Empty;
                                  }
                                  );
                                  timestamp = state.get_time();
                              }, caller)) {
                                  case(#ok(val)){
                                      return #ok(#withdraw(val));
                                  };
                                  case(#err(err)){
                                      return #err(Types.errors(err.error, "withdraw_nft_origyn - escrow - ledger not updated" # debug_show(transaction_id) , ?caller));
                                  };
                              };



                          };
                      };
                      
                  };
                  case(#err(err)){
                                          debug if(debug_channel.withdraw_escrow) D.print("an error");
                                          debug if(debug_channel.withdraw_escrow) D.print(debug_show(err));
                      return #err(Types.errors(err.error, "withdraw_nft_origyn - escrow - - cannot verify escrow - " # debug_show(details), ?caller));};
                  };


          };
          case(#sale(details)){
                                  debug if(debug_channel.withdraw_sale) D.print("withdrawing a sale");
                                  debug if(debug_channel.withdraw_sale) D.print(debug_show(details));
                                  debug if(debug_channel.withdraw_sale) D.print(debug_show(caller));
              if(caller != state.canister() and Types.account_eq(#principal(caller), details.seller) == false){
                  //cant withdraw for someone else
                  //D.print("can't withdraw for someone else");
                  return #err(Types.errors(#unauthorized_access, "withdraw_nft_origyn - sales- buyer and caller do not match" # debug_show((#principal(caller), details.seller)) , ?caller));
              };

              let verified = verify_sales_reciept(state, details);

              switch(verified){
                  case(#ok(verified)){
                                          debug if(debug_channel.withdraw_sale) D.print("have verified");

                      if(verified.found_asset.escrow.amount < details.amount){
                          return #err(Types.errors(#withdraw_too_large, "withdraw_nft_origyn - sales - withdraw too large" , ?caller));
                      };
                      
                      let a_ledger = verified.found_asset.escrow;

                                          debug if(debug_channel.withdraw_sale) D.print("a_ledger" # debug_show(a_ledger));

                      let a_token_id = verified.found_asset_list;

                      //let account_info = NFTUtils.get_sale_account_info({verified.found_asset.escrow, state.canister());
                          

                      //NFT-112
                      switch(details.token){
                          case(#ic(token)){

                              if(a_ledger.amount <= token.fee){
                                                      debug if(debug_channel.withdraw_sale) D.print("withdraw fee");
                                  return #err(Types.errors(#withdraw_too_large, "withdraw_nft_origyn - sales - withdraw fee is larger than amount" , ?caller));

                              };
                          };
                          case(_){D.print("nyi err");
                              return #err(

                                  Types.errors(#nyi, "withdraw_nft_origyn - sales - extensible token nyi - " # debug_show(details), ?caller));
                            };
                      };

                      
                                      debug if(debug_channel.withdraw_sale) D.print("finding target escrow");
                                      debug if(debug_channel.withdraw_sale) D.print(debug_show(a_ledger.amount));
                                      debug if(debug_channel.withdraw_sale) D.print(debug_show(details.amount));
                      //ok...so we should be good to withdraw
                      //first update the escrow
                      if(verified.found_asset.escrow.amount < details.amount){
                          return #err(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - sale - amount too large ", ?caller));
                                              
                      };

                      
                      let target_escrow = {
                          account_hash = a_ledger.account_hash;
                          amount = Nat.sub(a_ledger.amount, details.amount);
                          buyer = a_ledger.buyer;
                          seller = a_ledger.seller;
                          token_id = a_ledger.token_id;
                          token = a_ledger.token;
                          sale_id = a_ledger.sale_id;
                          lock_to_date = a_ledger.lock_to_date;
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
                              
                                  case(#Ledger){
                                                          debug if(debug_channel.withdraw_sale) D.print("found ledger sale withdraw");
                                      let checker = Ledger_Interface.Ledger_Interface();
                                      //if this fails we need to put the escrow back
                                      try{
                                          switch(await checker.send_payment_minus_fee(details.withdraw_to, token, details.amount, a_ledger.account_hash, caller)){
                                              case(#ok(val)){
                                                  //D.print("Got a val and it it is");
                                                  ?val;
                                              };
                                              case(#err(err)){
                                                  //put the escrow back
                                                                      debug if(debug_channel.withdraw_sale) D.print("failed, putting back ledger");
                                                  switch(verify_sales_reciept(state, details)){
                                                      case(#ok(reverify)){
                                                          let target_escrow = {
                                                              account_hash = reverify.found_asset.escrow.account_hash;
                                                              amount = Nat.add(reverify.found_asset.escrow.amount, details.amount);
                                                              buyer = reverify.found_asset.escrow.buyer;
                                                              seller = reverify.found_asset.escrow.seller;
                                                              token_id = reverify.found_asset.escrow.token_id;
                                                              token = reverify.found_asset.escrow.token;
                                                              sale_id = reverify.found_asset.escrow.sale_id;
                                                              lock_to_date = reverify.found_asset.escrow.lock_to_date;
                                                          };

                                                          
                                                          Map.set(a_token_id, token_handler, details.token, target_escrow);
                                                          

                                                      };
                                                      case(#err(err)){

                                                          //put the escrow back
                                                          let target_escrow = {
                                                              account_hash = a_ledger.account_hash;
                                                              amount =  details.amount;
                                                              buyer = a_ledger.buyer;
                                                              seller = a_ledger.seller;
                                                              token_id = a_ledger.token_id;
                                                              token = a_ledger.token;
                                                              sale_id = a_ledger.sale_id;
                                                              lock_to_date = a_ledger.lock_to_date;
                                                          };

                                                          
                                                          Map.set(a_token_id, token_handler, details.token, target_escrow);
                                                      }
                                                  };
                                                  
                                                  return #err(Types.errors(#sales_withdraw_payment_failed, "withdraw_nft_origyn - sales ledger payment failed err branch" # err.flag_point, ?caller));
                                              };
                                          };
                                      } catch(e){
                                          //put the escrow back
                                          switch(verify_sales_reciept(state, details)){
                                              case(#ok(reverify)){
                                                  let target_escrow = {
                                                      account_hash = reverify.found_asset.escrow.account_hash;
                                                      amount = Nat.add(reverify.found_asset.escrow.amount, details.amount);
                                                      buyer = reverify.found_asset.escrow.buyer;
                                                      seller = reverify.found_asset.escrow.seller;
                                                      token_id = reverify.found_asset.escrow.token_id;
                                                      token = reverify.found_asset.escrow.token;
                                                      sale_id = reverify.found_asset.escrow.sale_id;
                                                      lock_to_date = reverify.found_asset.escrow.lock_to_date;
                                                  };

                                                  
                                                  Map.set(a_token_id, token_handler, details.token, target_escrow);
                                                  

                                              };
                                              case(#err(err)){
                                                  let target_escrow = {
                                                      account_hash = a_ledger.account_hash;
                                                      amount =  details.amount;
                                                      buyer = a_ledger.buyer;
                                                      seller = a_ledger.seller;
                                                      token_id = a_ledger.token_id;
                                                      token = a_ledger.token;
                                                      sale_id = a_ledger.sale_id;
                                                      lock_to_date = a_ledger.lock_to_date;
                                                  };

                                                  
                                                  Map.set(a_token_id, token_handler, details.token, target_escrow);
                                              }
                                          };
                                          
                                          return #err(Types.errors(#sales_withdraw_payment_failed, "withdraw_nft_origyn - sales ledger payment failed catch branch" # Error.message(e), ?caller));
                                      };
                                  };
                                  case(_){
                                      return #err(Types.errors(#nyi, "withdraw_nft_origyn - sales - ledger type nyi - " # debug_show(details), ?caller));
                                  };
                              };
                          };
                          case(#extensible(val)){
                              return #err(Types.errors(#nyi, "withdraw_nft_origyn - sales - extensible token nyi - " # debug_show(details), ?caller));
                          };
                      };

                      //D.print("have a transactionid and will crate a transaction");
                      switch(transaction_id){
                          case(null){
                              //really should have failed already
                              return #err(Types.errors(#sales_withdraw_payment_failed, "withdraw_nft_origyn - sales  payment failed txid null" , ?caller));
                          };
                          case(?transaction_id){
                              switch(Metadata.add_transaction_record(state,{
                                  token_id = details.token_id;
                                  index = 0;
                                  txn_type = #sale_withdraw({
                                      buyer = details.buyer;
                                      amount = details.amount - transaction_id.fee;
                                      fee = transaction_id.fee;
                                      token = details.token;
                                      seller = details.seller;
                                      token_id = details.token_id;
                                      trx_id = transaction_id.trx_id;
                                      extensible = #Empty;
                                  }
                                  );
                                  timestamp = state.get_time();
                              }, caller)) {
                                  case(#ok(val)){
                                      //D.print("we did it");
                                      //D.print(debug_show(val));
                                      return #ok(#withdraw(val));
                                  };
                                  case(#err(err)){
                                      return #err(Types.errors(err.error, "withdraw_nft_origyn - sales ledger not updated" # debug_show(transaction_id) , ?caller));
                                  };
                              };

                          };
                      };

                  };

                  case(#err(err)){
                                          debug if(debug_channel.withdraw_sale) D.print("an error");
                                          debug if(debug_channel.withdraw_sale) D.print(debug_show(err));
                      return #err(Types.errors(err.error, "withdraw_nft_origyn - sale - - cannot verify escrow - " # debug_show(details), ?caller));
                  };
            
              };

          };
          case(#reject(details)){
              // rejects and offer and sends the tokens back to the source
                                  debug if(debug_channel.withdraw_reject) D.print("an escrow reject");
              if(caller != state.canister() and Types.account_eq(#principal(caller), details.seller) == false and ?caller != state.state.collection_data.network){
                  //cant withdraw for someone else
                                      debug if(debug_channel.withdraw_reject) D.print(debug_show((caller, state.canister(), details.seller, state.state.collection_data.network)));
                  return #err(Types.errors(#unauthorized_access, "withdraw_nft_origyn - reject - unauthorized" , ?caller));
              };

                                      debug if(debug_channel.withdraw_reject) D.print("about to verify");
              let verified = verify_escrow_reciept(state, {
                  amount = 0;
                  buyer = details.buyer;
                  seller = details.seller;
                  token  = details.token;
                  token_id = details.token_id
              }, null, null);
              
              
              switch(verified){
                  case(#ok(verified)){

                      let account_info = NFTUtils.get_escrow_account_info(verified.found_asset.escrow, state.canister());

                      let a_ledger = verified.found_asset.escrow;

                      // reject ignores locked assets

                      //NFT-112
                      let fee = switch(details.token){
                          case(#ic(token)){

                              if(a_ledger.amount <= token.fee){
                                  return #err(Types.errors(#withdraw_too_large, "withdraw_nft_origyn - reject - withdraw fee is larger than amount" , ?caller));

                              };
                              token.fee;
                          };
                          case(_){return #err(Types.errors(#nyi, "withdraw_nft_origyn - reject - extensible token nyi - " # debug_show(details), ?caller));
                                          };
                      };

                                          debug if(debug_channel.withdraw_reject) D.print("got to sale id");

                      switch(a_ledger.sale_id){
                          case(?sale_id){
                              //check that the owner isn't still the bidder in the sale
                              switch(Map.get(state.state.nft_sales, Map.thash,sale_id)){
                                  case(null){
                                      //nyi: should be an error because sale id can't be found but do nothing for now
                                        return #err(Types.errors(#sale_not_found, "withdraw_nft_origyn - reject - can't find sale top" # debug_show(a_ledger) #  " " # debug_show(withdraw) , ?caller));
                                  };
                                  case(?val){

                                                          debug if(debug_channel.withdraw_reject) D.print("testing current state");

                                      let current_sale_state = switch(NFTUtils.get_auction_state_from_status(val)){
                                          case(#ok(val)){val};
                                          case(#err(err)){
                                              return #err(Types.errors(err.error, "withdraw_nft_origyn - reject - find state " # err.flag_point, ?caller));
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
                                                          return #err(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - reject - you are the winner" , ?caller));
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
                                                          return #err(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - reject - you are the current bid" , ?caller));
                                                      };
                                                  };
                                                  case(nul){
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
                                      case(#Ledger){
                                          //D.print("found ledger");
                                          let checker = Ledger_Interface.Ledger_Interface();

                                                              debug if(debug_channel.withdraw_reject) D.print("returning amount " # debug_show(verified.found_asset.escrow.amount, token.fee));
                                          
                                          switch(await checker.send_payment_minus_fee(details.buyer, token, verified.found_asset.escrow.amount, ?account_info.account.sub_account, caller)){
                                              case(#ok(val)){
                                                  //D.print("Got a val and it it is");
                                                  ?val;
                                              };
                                              case(#err(err)){
                                                  //put the escrow back
                                                  //make sure things havent changed in the mean time
                                                  //D.print("failed, putting back ledger");
                                                  switch(verify_escrow_reciept(state, a_ledger, null, null)){
                                                      case(#ok(reverify)){
                                                          let target_escrow = {
                                                              account_hash = reverify.found_asset.escrow.account_hash;
                                                              amount = Nat.add(reverify.found_asset.escrow.amount, a_ledger.amount);
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
                                                          let putback = put_escrow_balance(state, a_ledger, true);
                                                      };
                                                  };
                                                  
                                                  return #err(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - reject - ledger payment failed" # err.flag_point, ?caller));
                                              };
                                          };

                                      };
                                      case(_){
                                          return #err(Types.errors(#nyi, "withdraw_nft_origyn - reject - - ledger type nyi - " # debug_show(details), ?caller));
                                      };
                                  };
                              };
                              case(#extensible(val)){
                                  return #err(Types.errors(#nyi, "withdraw_nft_origyn - reject - -  token standard nyi - " # debug_show(details), ?caller));
                              };
                          };
                      } catch (e){
                          //something failed, put the escrow back
                          //make sure it hasn't changed in the mean time
                          //D.print("failed, putting back throw");
                          switch(verify_escrow_reciept(state, a_ledger, null, null)){
                              case(#ok(reverify)){
                                  let target_escrow = {
                                      account_hash = reverify.found_asset.escrow.account_hash;
                                      amount = Nat.add(reverify.found_asset.escrow.amount, a_ledger.amount);
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
                                  let putback = put_escrow_balance(state, a_ledger, true);
                              };
                          };
                          return #err(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - reject -  payment failed" # Error.message(e) , ?caller));
                      };

                                              debug if(debug_channel.withdraw_reject) D.print("succesful transaction :" # debug_show(transaction_id) # debug_show(details));

                      switch(transaction_id){
                          case(null){
                              //really should have failed already
                              return #err(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow -  payment failed txid null" , ?caller));
                          };
                          case(?transaction_id){
                              switch(Metadata.add_transaction_record(state,{
                                  token_id = details.token_id;
                                  index = 0;
                                  txn_type = #escrow_withdraw({
                                      buyer = details.buyer;
                                      amount = verified.found_asset.escrow.amount - transaction_id.fee;
                                      fee = transaction_id.fee;
                                      token = details.token;
                                      seller = details.seller;
                                      token_id = details.token_id;
                                      trx_id = transaction_id.trx_id;
                                      extensible = #Empty;
                                  }
                                  );
                                  timestamp = state.get_time();
                              }, caller)) {
                                  case(#ok(val)){
                                      return #ok(#withdraw(val));
                                  };
                                  case(#err(err)){
                                      return #err(Types.errors(err.error, "withdraw_nft_origyn - escrow - ledger not updated" # debug_show(transaction_id) , ?caller));
                                  };
                              };



                          };
                      };
                      
                  };
                  case(#err(err)){
                                          debug if(debug_channel.withdraw_reject) D.print("an error");
                                          debug if(debug_channel.withdraw_reject) D.print(debug_show(err));
                      return #err(Types.errors(err.error, "withdraw_nft_origyn - escrow - - cannot verify escrow - " # debug_show(details), ?caller));};
                  };


          };
      };
        return #err(Types.errors(#nyi, "withdraw_nft_origyn  - nyi - " , ?caller));
    };

    //allows bids on auctons
    public func bid_nft_origyn(state: StateAccess, request : Types.BidRequest, caller: Principal, canister_call: Bool) : async Result.Result<Types.ManageSaleResponse,Types.OrigynError> {


        //look for an existing sale
        let current_sale =
                switch(Map.get(state.state.nft_sales, Map.thash,request.sale_id)){
                    case(?status){status;};
                    case(null){return #err(Types.errors(#sale_id_does_not_match, "bid_nft_origyn - sales id did not match " # request.sale_id, ?caller));};
                };

        let current_sale_state = switch(NFTUtils.get_auction_state_from_status(current_sale)){
            case(#ok(val)){val};
            case(#err(err)){
                return #err(Types.errors(err.error, "bid_nft_origyn - find state " # err.flag_point, ?caller));
            };
        };

        let current_pricing = switch(current_sale_state.config){
            case(#auction(config)){
                config;
            };
            case(_){
                return #err(Types.errors(#sale_not_found, "bid_nft_origyn - not an auction type ", ?caller));

            };
        };

        switch(current_sale_state.status){
            case(#open){ 
                if(state.get_time() >= current_sale_state.end_date){
                    //current_sale_state.status := #closed;
                    return #err(Types.errors(#auction_ended, "bid_nft_origyn - sale is past close date " # request.sale_id, ?caller));
                };
            };
            case(#not_started){
                if(state.get_time() >= current_pricing.start_date and state.get_time() < current_sale_state.end_date){
                    current_sale_state.status := #open;
                };
            };
            case(_){return #err(Types.errors(#auction_ended, "bid_nft_origyn - sale is not open " # request.sale_id, ?caller));};
        };

        
        switch(current_sale_state.allow_list){
            case(null){
                                debug if(debug_channel.bid) D.print("allow list is null");
            };
            case(?val){
                                debug if(debug_channel.bid) D.print("allow list inst null");
                switch(Map.get<Principal, Bool>(val, Map.phash, caller)){
                    case(null){return #err(Types.errors(#unauthorized_access, "bid_nft_origyn - not on allow list ", ?caller))};
                    case(?val){}
                };
            };
        };
        
        
        var metadata = switch(Metadata.get_metadata_for_token(state,request.escrow_receipt.token_id, caller, ?state.canister(), state.state.collection_data.owner)){
            case(#err(err)){
                return #err(Types.errors(#token_not_found, "bid_nft_origyn " # err.flag_point, ?caller));
            };
            case(#ok(val)){
                val;
            };
        };

        let owner = switch(Metadata.get_nft_owner(metadata)){
            case(#err(err)){
                return #err(Types.errors(err.error, "bid_nft_origyn " # err.flag_point, ?caller));
            };
            case(#ok(val)){
                val;
            };
        };

       

        //make sure token ids match
        if(current_sale.token_id != request.escrow_receipt.token_id){
            return #err(Types.errors(#token_id_mismatch, "bid_nft_origyn - token id of sale does not match escrow receipt " # request.escrow_receipt.token_id, ?caller));
        };

        //make sure assets match
                            debug if(debug_channel.bid) D.print("checking asset sale type " # debug_show((_get_token_from_sales_status(current_sale), request.escrow_receipt.token)));
        if(Types.token_eq(_get_token_from_sales_status(current_sale), request.escrow_receipt.token) == false){
            return #err(Types.errors(#asset_mismatch, "bid_nft_origyn - asset in sale and escrow receipt do not match " # debug_show(request.escrow_receipt.token) # debug_show(_get_token_from_sales_status(current_sale)), ?caller));
        };

        //make sure owners match
        if(Types.account_eq(owner, request.escrow_receipt.seller) == false){
            return #err(Types.errors(#receipt_data_mismatch, "bid_nft_origyn - owner and seller do not match " # debug_show(request.escrow_receipt.token) # debug_show(_get_token_from_sales_status(current_sale)), ?caller));
        };

        //make sure buyers match
        if(Types.account_eq(#principal(caller), request.escrow_receipt.buyer) == false){
            return #err(Types.errors(#receipt_data_mismatch, "bid_nft_origyn - caller and buyer do not match " # debug_show(request.escrow_receipt.token) # debug_show(_get_token_from_sales_status(current_sale)), ?caller));
        };

        //make sure the receipt is valid
                            debug if(debug_channel.bid) D.print("verifying Escrow");
        let verified = switch(verify_escrow_reciept(state, request.escrow_receipt, null, ?request.sale_id)){
            case(#err(err)){
              //we could not verify the escrow, so we're going to try to claim it here as if escrow_nft_origyn was called first.
              //this adds an additional await to each item not already claimed, so it could get expensive in batch scenarios.

              if(canister_call == false){
                switch(await escrow_nft_origyn(state,
                    {deposit =
                      {
                        amount = request.escrow_receipt.amount;
                        buyer = request.escrow_receipt.buyer;
                        sale_id = ?request.sale_id;
                        seller = request.escrow_receipt.seller;
                        token = request.escrow_receipt.token;
                        trx_id = null;
                      }; 
                    lock_to_date = null; token_id = request.escrow_receipt.token_id}
                  , caller)){
                    case(#ok(newEscrow)){
                        //we can't just continue here because the owner may have changed out from underneath us...safer to sart from the begining
                        return await bid_nft_origyn(state, request, caller, true);

                    };
                    case(#err(err)){
                      return #err(Types.errors(err.error, "bid_nft_origyn auto try escrow failed " # err.flag_point, ?caller))
                    };
                  };
              } else {
                return #err(Types.errors(err.error, "bid_nft_origyn auto try escrow failed after canister call " # err.flag_point, ?caller))
              };
            };
            case(#ok(res)){
                res;
            };
        };

        if(verified.found_asset.escrow.amount < request.escrow_receipt.amount){
            //D.print("in check amount");
            return #err(Types.errors(#withdraw_too_large, "bid_nft_origyn - escrow - amount more than in escrow verified: " # Nat.toText(verified.found_asset.escrow.amount) # " request: " # Nat.toText(request.escrow_receipt.amount) , ?caller));
            
        };
    


        //make sure auction is still running
        let current_time = state.get_time();
        if(state.get_time() > current_sale_state.end_date){
            // MKT0028
            return #err(Types.errors(#auction_ended, "bid_nft_origyn - auction ended current_date" # debug_show(current_time) # " " # " end_time:" # debug_show(current_sale_state.end_date), ?caller));

        };

        switch(current_sale_state.status){
            case(#closed){
                //we will close later after we try to refund a valid bid
                                    debug if(debug_channel.bid) D.print("refunding closed "  # debug_show(verified.found_asset.escrow.amount));
                let service : Types.Service = actor((Principal.toText(state.canister())));
                let refund_id = service.sale_nft_origyn(#withdraw(
                    #escrow({
                        amount = verified.found_asset.escrow.amount; //return back the whole escrow
                        buyer = request.escrow_receipt.buyer;
                        seller = request.escrow_receipt.seller;
                        token = request.escrow_receipt.token;
                        token_id = request.escrow_receipt.token_id;
                        withdraw_to = request.escrow_receipt.buyer;}
                    )));
                //last_withdraw_result := ?refund_id;

                                    //debug if(debug_channel.bid) D.print(debug_show(refund_id));
                return #err(Types.errors(#auction_ended, "end_sale_nft_origyn - auction already closed - attempting escrow return ", ?caller));
            };
           
            case(_){};
        };

        //make sure amount is high enough
        if(request.escrow_receipt.amount < current_sale_state.min_next_bid){
            //if the bid is too low we should refund their escrow
                                debug if(debug_channel.bid) D.print("refunding not high enough bid "  # debug_show(verified.found_asset.escrow.amount));
            let service : Types.Service = actor((Principal.toText(state.canister())));
            let refund_id = service.sale_nft_origyn(#withdraw(
                #escrow({
                    amount = verified.found_asset.escrow.amount; //return back the whole escrow minus fee
                    buyer = verified.found_asset.escrow.buyer;
                    seller = verified.found_asset.escrow.seller;
                    token = verified.found_asset.escrow.token;
                    token_id = verified.found_asset.escrow.token_id;
                    withdraw_to = verified.found_asset.escrow.buyer;}
                )));
            //last_withdraw_result := ?refund_id;

                                //debug if(debug_channel.bid) D.print(debug_show(refund_id));
                   
            return #err(Types.errors(#bid_too_low, "bid_nft_origyn - bid too low - refund issued "  , ?caller));
        };

        let buy_now = switch(current_pricing.buy_now){
 
            case(null){false};
            case(?val){
                if(val <= request.escrow_receipt.amount){
                    true;
                } else {
                    false;
                };
            };
        };

                            debug if(debug_channel.bid) D.print("have buy now" # debug_show(buy_now, current_pricing.buy_now, current_sale_state.current_bid_amount));

        let new_trx = Metadata.add_transaction_record(state,{
            token_id = request.escrow_receipt.token_id;
            index = 0;
            txn_type = #auction_bid({
                buyer = request.escrow_receipt.buyer;
                amount = request.escrow_receipt.amount;
                token = request.escrow_receipt.token;
                broker_id = request.broker_id;
                sale_id = request.sale_id;
                extensible = #Empty;
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

                let newMinBid = switch(current_pricing.min_increase){
                    case(#percentage(apercentage)){

                        //request.escrow_receipt.amount * (1 + apercentage)
                        return #err(Types.errors(#nyi, "bid_nft_origyn - percentage increase not implemented " , ?caller));

                    };
                    case(#amount(aamount)){
                        request.escrow_receipt.amount + aamount;
                    };
                };


                                    debug if(debug_channel.bid) D.print("have a min bid" # debug_show(newMinBid));
                
                switch(current_sale_state.current_escrow){
                    case(null){

                        //update state
                                            debug if(debug_channel.bid) D.print("updating the state" # debug_show(request));
                        current_sale_state.current_bid_amount := request.escrow_receipt.amount;
                        current_sale_state.min_next_bid := newMinBid;
                        current_sale_state.current_escrow := ?request.escrow_receipt;
                        current_sale_state.current_broker_id := request.broker_id;
                        ignore Map.put<Principal, Int>(current_sale_state.participants, phash, caller, state.get_time());
                    };
                    case(?val){

                        //update state
                                            debug if(debug_channel.bid) D.print("Before" # debug_show(val.amount) # debug_show(val));
                        current_sale_state.current_bid_amount := request.escrow_receipt.amount;
                        current_sale_state.min_next_bid := newMinBid;
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
                                amount = val.amount;
                                buyer = val.buyer;
                                seller = val.seller;
                                token = val.token;
                                token_id = val.token_id;
                                withdraw_to = val.buyer;}
                            )
                        ));

                        //last_withdraw_result := ?refund_id;
                                            debug if(debug_channel.bid) D.print("done");
                                            //debug if(debug_channel.bid) D.print(debug_show(refund_id));

                    };
                };

                if(buy_now){

                                        debug if(debug_channel.bid) D.print("handling buy now");

                    let service : Types.Service = actor((Principal.toText(state.canister())));
                    
                    let result = await service.sale_nft_origyn(#end_sale(request.escrow_receipt.token_id));

                    switch(result){
                        case(#ok(val)){
                            switch(val){
                                case(#end_sale(val)){
                                    return #ok(#bid(val));
                                };
                                case(_){
                                    return #err(Types.errors(#improper_interface, "bid_nft_origyn - buy it now call to end sale had odd response " # debug_show(result), ?caller ));
                                };
                            };
                        };
                        case(#err(err)){
                            return #err(err);
                        };
                    };

                    //call ourseves to close the auction
                };
                return #ok(#bid(val));
            };
            case(#err(err)){
                return #err(Types.errors(err.error, "bid_nft_origyn - create transaction record " # err.flag_point, ?caller));
            };
        };
        

    };


    //pulls the token out of a sale
    private func _get_token_from_sales_status(status: Types.SaleStatus) : Types.TokenSpec{
        switch(status.sale_type){
            case(#auction(auction_status)){
                return switch(auction_status.config){
                    case(#auction(auction_config)){
                        return auction_config.token;
                    };
                    case(_){
                                        debug if(debug_channel.bid) D.print("getTokenfromSalesstatus not configured for type");
                        assert(false);
                        return #extensible(#Empty);
                    };
                };
            };
            /* case(_){
                                debug if(debug_channel.bid) D.print("getTokenfromSalesstatus not configured for type");
                assert(false);
                return #extensible(#Empty);
            }; */
        };

    };


}