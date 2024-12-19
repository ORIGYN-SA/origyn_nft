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
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import TimerTool "mo:timer-tool";

import AccountIdentifier "mo:principalmo/AccountIdentifier";

import Star "mo:star/star";

import SHA256 "mo:crypto/SHA/SHA256";
import Ledger_Interface "ledger_interface";
import Metadata "metadata";
import MigrationTypes "./migrations/types";
import Migrations "migrations/types";
import Mint "mint";
import NFTUtils "utils";
import Types "types";
import Withdraw "./market/withdraw";
import Verify "./market/verify_reciept";
import FeeAccount "market/fee_account";
import PutBalance "market/put_balance";
import Royalties "market/royalties";
import ICRC2 "../external_canisters/ICRC2";

module {

  let debug_channel = {
    verify_escrow = false;
    verify_sale = false;
    ensure = false;
    invoice = false;
    end_sale = false;
    market = false;
    royalties = false;
    offers = false;
    escrow = false;
    withdraw_escrow = false;
    withdraw_sale = false;
    withdraw_reject = false;
    withdraw_deposit = false;
    withdraw_fee_deposit = false;
    notifications = false;
    dutch = false;
    bid = false;
  };

  let CandyTypes = MigrationTypes.Current.CandyTypes;
  let Conversions = MigrationTypes.Current.Conversions;
  let Properties = MigrationTypes.Current.Properties;
  let Workspace = MigrationTypes.Current.Workspace;
  let Map = MigrationTypes.Current.Map;
  let Set = MigrationTypes.Current.Set;

  let account_handler = MigrationTypes.Current.account_handler;
  let token_handler = MigrationTypes.Current.token_handler;

  type StateAccess = Types.State;

  let SB = MigrationTypes.Current.SB;

  let { ihash; nhash; thash; phash; calcHash } = Map;

  // Searches the escrow reciepts to find if the buyer/seller/token_id tuple has a balance on file
  /**
  * @param {StateAccess} state - The state access object.
  * @param {Types.Account} buyer - The buyer's account.
  * @param {Types.Account} seller - The seller's account.
  * @param {Text} token_id - The token ID.
  * @returns {Result.Result<MigrationTypes.Current.EscrowLedgerTrie, Types.OrigynError>} - Either the escrow ledger trie or an error.
  */
  public func find_escrow_reciept(
    state : StateAccess,
    buyer : Types.Account,
    seller : Types.Account,
    token_id : Text,
  ) : Result.Result<MigrationTypes.Current.EscrowLedgerTrie, Types.OrigynError> {

    //find buyer's escrows
    let ?to_list = Map.get(state.state.escrow_balances, account_handler, buyer) else {
      debug if (debug_channel.verify_escrow) D.print("didnt find asset");
      return #err(Types.errors(#no_escrow_found, "find_escrow_reciept - escrow buyer not found ", null));
    };

    debug if (debug_channel.verify_escrow) D.print("to_list is " # debug_show (Map.size(to_list)));
    //find sellers deposits
    let ?token_list = Map.get(to_list, account_handler, seller) else {
      debug if (debug_channel.verify_escrow) D.print("no escrow seller");
      return #err(Types.errors(#no_escrow_found, "find_escrow_reciept - escrow seller not found ", null));
    };

    debug if (debug_channel.verify_escrow) D.print("looking for to list");
    //find tokens deposited for both "" and provided token_id
    let asset_list = switch (Map.get(token_list, Map.thash, token_id), Map.get(token_list, Map.thash, "")) {
      case (null, null) return #err(Types.errors(#no_escrow_found, "find_escrow_reciept - escrow token_id not found ", null));
      case (null, ?generalList) return #err(Types.errors(#no_escrow_found, "find_escrow_reciept - escrow token_id found for general item but token_id is specific ", null));
      case (?asset_list, _) return #ok(asset_list);
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
    state : StateAccess,
    metadata : CandyTypes.CandyShared,
    caller : Principal,
  ) : Result.Result<Bool, Types.OrigynError> {

    debug if (debug_channel.ensure) D.print("in ensure");
    let #ok(token_id) = Metadata.get_nft_id(metadata) else return #err(Types.errors(#token_not_found, "is_token_on_sale - could not find token_id ", ?caller));

    //look for an existing sale
    debug if (debug_channel.verify_sale) D.print("geting sale");

    let sale_id = switch (Metadata.get_current_sale_id(metadata)) {
      case (#Option(null)) return #ok(false);
      case (#Text(sale_id)) sale_id;
      case (_) return #err(Types.errors(#nyi, "is_token_on_sale - imporoper candy type ", ?caller));
    };

    debug if (debug_channel.verify_sale) D.print("found sale" # sale_id);

    let ?current_sale = Map.get(state.state.nft_sales, Map.thash, sale_id) else return #err(Types.errors(#sale_not_found, "is_token_on_sale - could not find sale for token " # token_id # " " # sale_id, ?caller));

    debug if (debug_channel.verify_sale) D.print("checking state");
    let current_sale_state = switch (NFTUtils.get_auction_state_from_status(current_sale)) {
      case (#ok(val)) val;
      case (#err(err)) return #err(Types.errors(err.error, "is_token_on_sale - find sale state " # err.flag_point, ?caller));
    };

    debug if (debug_channel.verify_sale) D.print("switching config");
    switch (current_sale_state.config) {
      case (#auction(config)) {
        debug if (debug_channel.verify_sale) D.print("current config" # debug_show (config));
      };
      case (#ask(config)) {
        debug if (debug_channel.verify_sale) D.print("current config" # debug_show (config));
      };
      case (_) return #err(Types.errors(#nyi, "is_token_on_sale - sales type check not implemented", ?caller));
    };

    switch (current_sale_state.status) {
      case (#closed) return #ok(false);
      case (#open) return #ok(true);
      case (_) return #ok(true);
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
  public func open_sale_nft_origyn<system>(state : StateAccess, token_id : Text, caller : Principal) : Result.Result<Types.ManageSaleResponse, Types.OrigynError> {
    D.print("in open_sale_nft_origyn");
    let metadata = switch (Metadata.get_metadata_for_token(state, token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) return #err(Types.errors(#token_not_found, "open_sale_nft_origyn " # err.flag_point, ?caller));
      case (#ok(val)) val;
    };

    //look for an existing sale
    let current_sale = switch (Metadata.get_current_sale_id(metadata)) {
      case (#Option(null)) return #err(Types.errors(#sale_not_found, "open_sale_nft_origyn - could not find sale for token " # token_id, ?caller));
      case (#Text(val)) {
        switch (Map.get(state.state.nft_sales, Map.thash, val)) {
          case (?status) {
            status;
          };
          case (null) return #err(Types.errors(#sale_not_found, "open_sale_nft_origyn - could not find sale for token " # token_id, ?caller));
        };
      };
      case (_) return #err(Types.errors(#sale_not_found, "open_sale_nft_origyn - could not find sale for token " # token_id, ?caller));
    };

    let current_sale_state = switch (NFTUtils.get_auction_state_from_status(current_sale)) {
      case (#err(err)) return #err(Types.errors(err.error, "open_sale_nft_origyn - find state " # err.flag_point, ?caller));
      case (#ok(val)) val;
    };

    switch (current_sale_state.status) {
      case (#closed) return #err(Types.errors(#auction_ended, "open_sale_nft_origyn - auction already closed ", ?caller));
      case (#not_started) {
        let _time = state.get_time();
        if (_time >= current_sale_state.start_date and _time < current_sale_state.end_date) {
          current_sale_state.status := #open;

          let timerTool = TimerTool.TimerTool(state.state.timerState, state.canister(), { advanced = null; reportBatch = null; reportExecution = null; reportError = null; syncUnsafe = null });

          let actionRequest = {
            actionType = "close_sale_timeouted_nft_origyn";
            params = to_candid ([current_sale.sale_id]);
          };

          let actionId = timerTool.setActionASync<system>(Nat64.toNat(Nat64.fromIntWrap(current_sale_state.end_date)), actionRequest, Nat64.toNat(Nat64.fromIntWrap(3600)));

          return (#ok(#open_sale(true)));
        } else return #err(Types.errors(#auction_not_started, "open_sale_nft_origyn - auction does not need to be opened " # debug_show (current_sale_state.start_date), ?caller));
      };
      case (#open) return #err(Types.errors(#auction_not_started, "open_sale_nft_origyn - auction already open", ?caller));
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
  public func sale_status_nft_origyn(state : StateAccess, sale_id : Text, caller : Principal) : Result.Result<Types.SaleInfoResponse, Types.OrigynError> {

    //look for an existing sale
    let current_sale = switch (Map.get(state.state.nft_sales, Map.thash, sale_id)) {
      case (?status) status;
      case (null) return #ok(#status(null));
    };

    let metadata = switch (Metadata.get_metadata_for_token(state, current_sale.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) return #err(Types.errors(#token_not_found, "sale_status_nft_origyn " # err.flag_point, ?caller));
      case (#ok(val)) val;
    };

    let result = #ok(
      #status(
        ?{
          current_sale with
          sale_type = switch (current_sale.sale_type) {
            case (#auction(val)) {
              #auction(
                Types.AuctionState_stabalize_for_xfer(
                  calc_dutch_price(state, val, metadata)
                )
              );
            };
            /* case(_){
            return #err(Types.errors(  #sale_not_found, "sale_status_nft_origyn not an auction ", ?caller));
        }; */
          };
        }
      )
    );

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
  public func active_sales_nft_origyn(state : StateAccess, pages : ?(Nat, Nat), caller : Principal) : Result.Result<Types.SaleInfoResponse, Types.OrigynError> {

    var tracker = 0 : Nat;

    let (min, max) = switch (pages) {
      case (null) {
        (0, Map.size(state.state.nft_metadata));
      };
      case (?val) {
        (
          val.0,
          if (val.0 + val.1 >= Map.size(state.state.nft_metadata)) {
            Map.size(state.state.nft_metadata);
          } else {
            val.0 + val.1;
          },
        );
      };
    };

    let results = Buffer.Buffer<(Text, ?Types.SaleStatusShared)>(max - min);

    var foundTotal : Nat = 0;
    var eof : Bool = false;
    let totalSize = Map.size(state.state.nft_metadata);

    label search for (this_token in Map.entries(state.state.nft_metadata)) {
      let metadata = switch (Metadata.get_metadata_for_token(state, this_token.0, caller, null, state.state.collection_data.owner)) {
        case (#err(err)) {
          results.add("unminted", null);
          tracker += 1;
          continue search;
        };
        case (#ok(val)) val;
      };

      //look for an existing sale
      let current_sale = switch (Metadata.get_current_sale_id(metadata)) {
        case (#Option(null)) {
          //results.add(this_token.0, null);
          tracker += 1;
          continue search;
        };
        case (#Text(val)) {
          switch (Map.get(state.state.nft_sales, Map.thash, val)) {
            case (?status) status;
            case (null) {
              //results.add(this_token.0, null);
              tracker += 1;
              continue search;
            };
          };
        };
        case (_) {
          //results.add(this_token.0, null);
          tracker += 1;
          continue search;
        };
      };

      let current_sale_state = switch (NFTUtils.get_auction_state_from_status(current_sale)) {
        case (#ok(val)) val;
        case (#err(err)) {
          //results.add(this_token.0, null);
          tracker += 1;
          continue search;
        };
      };

      switch (current_sale_state.config) {
        case (#auction(config)) {
          if (current_sale_state.status == #open or current_sale_state.status == #not_started) {

            if (tracker > max) {} else if (tracker >= min) {

              results.add(
                this_token.0,
                ?{
                  current_sale with
                  sale_type = switch (current_sale.sale_type) {
                    case (#auction(val)) {
                      #auction(Types.AuctionState_stabalize_for_xfer(val));
                    };
                  };
                },
              );

              if (tracker + 1 == totalSize) {
                eof := true;
              };
            } else {};

            foundTotal += 1;
          };
        };

        case (#ask(config)) {

          if (current_sale_state.status == #open or current_sale_state.status == #not_started) {

            if (tracker > max) {} else if (tracker >= min) {

              results.add(
                this_token.0,
                ?{
                  current_sale with
                  sale_type = switch (current_sale.sale_type) {
                    case (#auction(val)) {
                      #auction(
                        Types.AuctionState_stabalize_for_xfer(
                          calc_dutch_price(state, val, metadata)
                        )
                      );
                    };
                  };
                },
              );

              if (tracker + 1 == totalSize) {
                eof := true;
              };
            } else {};

            foundTotal += 1;
          };
        };
        case (_) {
          //results.add(this_token.0, null);
          tracker += 1;
          continue search;
        };
      };

      tracker += 1;
    };

    return #ok(#active({ records = Buffer.toArray(results); eof = eof; count = foundTotal }));
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
  public func history_sales_nft_origyn(state : StateAccess, pages : ?(Nat, Nat), caller : Principal) : Result.Result<Types.SaleInfoResponse, Types.OrigynError> {

    var tracker = 0 : Nat;
    let (min, max, total, eof) = switch (pages) {
      case (null) {
        (0, Map.size(state.state.nft_sales), Map.size(state.state.nft_sales), true);
      };
      case (?val) {
        (
          val.0,
          if (val.0 + val.1 >= Map.size(state.state.nft_sales)) {
            Map.size(state.state.nft_sales);
          } else {
            val.0 + val.1;
          },
          Map.size(state.state.nft_sales),
          if (val.0 + val.1 >= Map.size(state.state.nft_sales)) {
            true;
          } else {
            false;
          },
        );
      };
    };

    let results = Buffer.Buffer<?Types.SaleStatusShared>(max - min);

    label search for (thisSale in Map.entries(state.state.nft_sales)) {
      if (tracker > max) { break search };
      if (tracker >= min) {

        let current_sale_state = switch (NFTUtils.get_auction_state_from_status(thisSale.1)) {
          case (#ok(val)) { val };
          case (#err(err)) {
            //results.add(null);
            tracker += 1;
            continue search;
          };
        };

        switch (current_sale_state.config) {
          case (#auction(config)) {

            results.add(
              ?{
                thisSale.1 with
                sale_type = switch (thisSale.1.sale_type) {
                  case (#auction(val)) {
                    #auction(Types.AuctionState_stabalize_for_xfer(val));
                  };
                };
              }
            );
          };
          case (#ask(config)) {
            let metadata = switch (Metadata.get_metadata_for_token(state, thisSale.1.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
              case (#err(err)) return #err(Types.errors(#token_not_found, "history_sales_nft_origyn " # err.flag_point, ?caller));
              case (#ok(val)) val;
            };

            results.add(
              ?{
                thisSale.1 with
                sale_type = switch (thisSale.1.sale_type) {
                  case (#auction(val)) {
                    #auction(
                      Types.AuctionState_stabalize_for_xfer(
                        calc_dutch_price(state, val, metadata)
                      )
                    );
                  };
                };
              }
            );
          };
          case (_) {
            //nyi: handle other sales types
            //results.add( null);
            tracker += 1;
            continue search;
          };
        };
      };
      tracker += 1;
    };

    return #ok(#history({ records = Buffer.toArray(results); eof = eof; count = total }));
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
  public func deposit_info_nft_origyn(state : StateAccess, request : ?Types.Account, caller : Principal) : Result.Result<Types.SaleInfoResponse, Types.OrigynError> {

    debug if (debug_channel.invoice) D.print("in deposit info nft origyn.");

    let account = switch (request) {
      case (null) #principal(caller);
      case (?val) val;
    };

    debug if (debug_channel.invoice) D.print("getting info for " # debug_show (account));
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
  public func escrow_info_nft_origyn(state : StateAccess, request : Types.EscrowReceipt, caller : Principal) : Result.Result<Types.SaleInfoResponse, Types.OrigynError> {

    debug if (debug_channel.invoice) D.print("in escrow info nft origyn.");

    debug if (debug_channel.invoice) D.print("getting info for " # debug_show (request));
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
  public func fee_deposit_info_nft_origyn(state : StateAccess, request : ?Types.Account, caller : Principal) : Result.Result<Types.SaleInfoResponse, Types.OrigynError> {

    debug if (debug_channel.invoice) D.print("in fee deposit info nft origyn.");

    let account = switch (request) {
      case (null) #principal(caller);
      case (?val) val;
    };

    debug if (debug_channel.invoice) D.print("getting info for " # debug_show (request));
    return #ok(#fee_deposit_info(NFTUtils.get_fee_deposit_account_info(account, state.canister())));
  };

  /**
  * callback function for end_sale_nft_origyn
  * unlocks the fee account for the seller and bidder
  *
  * @param {StateAccess} state - StateAccess object for accessing the canister's state.
  * @param {CandyTypes.CandyShared} metadata - CandyShared object containing the metadata for the sale.
  * @param {Types.TokenSpec} request.token - TokenSpec object containing the token information for the sale.
  * @param {Text} request.sale_id - Text object containing the sale ID for the sale.
  * @param {?MigrationTypes.Current.FeeAccountsParams} request.seller_fee_accounts - Optional FeeAccountsParams object containing the seller fee accounts for the sale.
  * @param {?MigrationTypes.Current.FeeAccountsParams} request.bidder_fee_accounts - Optional FeeAccountsParams object containing the bidder fee accounts for the sale.
  * @param {?Text} request.fee_schema - Optional Text object containing the fee schema for the sale.
  * @param {MigrationTypes.Current.Account} request.owner - Account object containing the owner of the sale.
  * @param {Star.Star<Types.ManageSaleResponse, Types.OrigynError>} ret - Star.Star object containing the result of the callback.
  * @returns {Star.Star<Types.ManageSaleResponse, Types.OrigynError>} - Star.Star object containing the result of the callback.
  */
  private func end_sale_unlock_fee_account_callback(
    state : StateAccess,
    metadata : CandyTypes.CandyShared,
    request : {
      token : Types.TokenSpec;
      sale_id : Text;
      seller_fee_accounts : ?MigrationTypes.Current.FeeAccountsParams;
      bidder_fee_accounts : ?MigrationTypes.Current.FeeAccountsParams;
      fee_schema : ?Text;
      owner : MigrationTypes.Current.Account;
    },
    ret : Star.Star<Types.ManageSaleResponse, Types.OrigynError>,
  ) : Star.Star<Types.ManageSaleResponse, Types.OrigynError> {

    switch (
      _unlock_fee_accounts_according_to_fee_schema(
        state,
        metadata,
        {
          token = request.token;
          sale_id = request.sale_id;
          fee_accounts = request.seller_fee_accounts;
          fee_schema = request.fee_schema;
          owner = request.owner;
        },
      )
    ) {
      case (#ok()) {};
      case (#err(e)) { return #err(#trappable(e)) };
    };

    switch (
      _unlock_fee_accounts_according_to_fee_schema(
        state,
        metadata,
        {
          token = request.token;
          sale_id = request.sale_id;
          fee_accounts = request.bidder_fee_accounts;
          fee_schema = request.fee_schema;
          owner = request.owner;
        },
      )
    ) {
      case (#ok()) {};
      case (#err(e)) { return #err(#trappable(e)) };
    };

    return ret;
  };

  /**
  * ends a sale if it is past the date or a buy it now has occured
  *
  * @param {StateAccess} state - StateAccess object for accessing the canister's state.
  * @param {Text} token_id - Text object containing the token ID for the sale.
  * @param {Principal} caller - Principal object containing the caller of the function.
  * @returns {Star.Star<Types.ManageSaleResponse, Types.OrigynError>} - Star.Star object containing the result of the function.
  */
  public func end_sale_nft_origyn(state : StateAccess, token_id : Text, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {
    debug if (debug_channel.end_sale) D.print("in end_sale_nft_origyn");

    var metadata = switch (Metadata.get_metadata_for_token(state, token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) {
        return #err(#trappable(Types.errors(#token_not_found, "end_sale_nft_origyn " # err.flag_point, ?caller)));
      };
      case (#ok(val)) val;
    };

    debug if (debug_channel.end_sale) D.print("have metadata");

    let owner = switch (Metadata.get_nft_owner(metadata)) {
      case (#err(err)) return #err(#trappable(Types.errors(err.error, "end_sale_nft_origyn " # err.flag_point, ?caller)));
      case (#ok(val)) val;
    };

    debug if (debug_channel.end_sale) D.print("have owner");

    //look for an existing sale
    let current_sale = switch (Metadata.get_current_sale_id(metadata)) {
      case (#Option(null)) {
        debug if (debug_channel.end_sale) D.print("option null for sale id");
        return #err(#trappable(Types.errors(#sale_not_found, "end_sale_nft_origyn - could not find sale for token " # token_id, ?caller)));
      };
      case (#Text(val)) {
        debug if (debug_channel.end_sale) D.print("have text sale id" # val);
        switch (Map.get(state.state.nft_sales, Map.thash, val)) {
          case (?status) {
            status;
          };
          case (null) return #err(#trappable(Types.errors(#sale_not_found, "end_sale_nft_origyn - could not find sale for token " # token_id, ?caller)));
        };
      };
      case (_) {
        debug if (debug_channel.end_sale) D.print("other type");
        return #err(#trappable(Types.errors(#sale_not_found, "end_sale_nft_origyn - could not find sale for token " # token_id, ?caller)));
      };
    };

    let current_sale_state = switch (NFTUtils.get_auction_state_from_status(current_sale)) {
      case (#ok(val)) val;
      case (#err(err)) return #err(#trappable(Types.errors(err.error, "end_sale_nft_origyn - find state " # err.flag_point, ?caller)));
    };

    //debug if(debug_channel.end_sale) D.print("current sale state " # debug_show(current_sale_state));

    let { buy_now_price; start_date; seller_fee_accounts; fee_schema : ?Text } = switch (current_sale_state.config) {
      case (#auction(config)) {
        {
          buy_now_price = config.buy_now;
          start_date = config.start_date;
          seller_fee_accounts = null;
          fee_schema = null;
        };
      };
      case (#ask(config)) {
        let buy_now : ?Nat = MigrationTypes.Current.load_buy_now_ask_feature(config);
        let dutch : ?MigrationTypes.Current.DutchParams = MigrationTypes.Current.load_dutch_ask_feature(config);
        let seller_fee_accounts : ?MigrationTypes.Current.FeeAccountsParams = MigrationTypes.Current.load_fee_accounts_ask_feature(config);
        let fee_schema : ?Text = MigrationTypes.Current.load_fee_schema_ask_feature(config);
        let start_date : ?Int = MigrationTypes.Current.load_start_date_ask_feature(config);
        {
          buy_now_price = switch (buy_now, dutch) {
            case (?buy_now, null) {
              ?buy_now;
            };
            case (null, ?dutch) {
              let current_state = calc_dutch_price(state, current_sale_state, metadata);
              ?current_state.min_next_bid;
            };
            case (_, _) {
              null;
            };
          };
          start_date = start_date;
          seller_fee_accounts = seller_fee_accounts;
          fee_schema = fee_schema;
        };
      };
      case (_) return #err(#trappable(Types.errors(#sale_not_found, "end_sale_nft_origyn - not an auction type ", ?caller)));
    };

    debug if (debug_channel.end_sale) D.print("current_sale_state " # debug_show (current_sale_state));

    let bidder_fee_accounts : ?MigrationTypes.Current.FeeAccountsParams = MigrationTypes.Current.load_fee_accounts_bid_feature(current_sale_state.current_config);
    let current_broker_id : ?MigrationTypes.Current.Account = MigrationTypes.Current.load_broker_bid_feature(current_sale_state.current_config);

    let buy_now = switch (buy_now_price) {
      case (null) { false };
      case (?val) {
        if (val <= current_sale_state.current_bid_amount) {
          true;
        } else {
          false;
        };
      };
    };

    debug if (debug_channel.end_sale) D.print("past buy now " # debug_show (buy_now));

    debug if (debug_channel.end_sale) D.print("have buy now" # debug_show (buy_now, buy_now_price, current_sale_state.current_bid_amount));

    switch (current_sale_state.status) {
      case (#closed) {
        //we will close later after we try to refund a valid bid
        return #err(#trappable(Types.errors(#auction_ended, "end_sale_nft_origyn - auction already closed ", ?caller)));
      };
      case (#not_started) {
        debug if (debug_channel.end_sale) D.print("wasnt started");

        if (state.get_time() >= current_sale_state.start_date and state.get_time() < current_sale_state.end_date) {
          current_sale_state.status := #open;
        };
      };
      case (_) {};
    };

    debug if (debug_channel.end_sale) D.print("handled current status" # debug_show (buy_now, buy_now_price, current_sale_state.current_bid_amount));

    //make sure auction is still over
    if (state.get_time() < current_sale_state.end_date) {
      debug if (debug_channel.end_sale) D.print("current time is less tha end date" # debug_show (buy_now, buy_now_price, current_sale_state.end_date));
      if (buy_now == true and caller == state.canister()) {
        //only the canister can end a buy now
      } else {

        if ((Types.account_eq(#principal(caller), owner) == true or caller == state.canister()) and current_sale_state.current_escrow == null) {
          //an owner can cancel an auction that has no bids yet.
          //useful for buy it now sales with a long out end date.

          debug if (debug_channel.end_sale) D.print("closing the sale via the owner" # debug_show (buy_now, buy_now_price, current_sale_state.end_date));

          current_sale_state.status := #closed;

          switch (
            Metadata.add_transaction_record<system>(
              state,
              {
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
              },
              caller,
            )
          ) {
            case (#ok(new_trx)) return end_sale_unlock_fee_account_callback(
              state,
              metadata,
              {
                token = current_sale_state.token;
                sale_id = current_sale.sale_id;
                seller_fee_accounts = seller_fee_accounts;
                bidder_fee_accounts = bidder_fee_accounts;
                fee_schema = fee_schema;
                owner = owner;
              },
              #trappable(#end_sale(new_trx)),
            );
            case (#err(err)) return #err(#trappable(err));
          };
        };

        return #err(#trappable(Types.errors(#sale_not_over, "end_sale_nft_origyn - auction still running ", ?caller)));
      };
    };

    //check reserve MKT0038
    let reserve = switch (current_sale_state.config) {
      case (#auction(config)) { config.reserve };
      case (#ask(config)) {
        MigrationTypes.Current.load_reserve_ask_feature(config);
      };
      case (_) { null };
    };

    debug if (debug_channel.end_sale) D.print("checking reserve" # debug_show (reserve));

    switch (reserve) {
      case (?reserve) {
        if (current_sale_state.current_bid_amount < reserve) {
          //end sale but don't move NFT
          debug if (debug_channel.end_sale) D.print("ending the sale but not moving the nft" # debug_show (buy_now, buy_now_price, current_sale_state.end_date));
          current_sale_state.status := #closed;

          switch (
            Metadata.add_transaction_record<system>(
              state,
              {
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
              },
              caller,
            )
          ) {
            case (#ok(new_trx)) return end_sale_unlock_fee_account_callback(
              state,
              metadata,
              {
                token = current_sale_state.token;
                sale_id = current_sale.sale_id;
                seller_fee_accounts = seller_fee_accounts;
                bidder_fee_accounts = bidder_fee_accounts;
                fee_schema = fee_schema;
                owner = owner;
              },
              #trappable(#end_sale(new_trx)),
            );
            case (#err(err)) return #err(#trappable(err));
          };
        };
      };
      case (null) {};
    };

    let _fee_schema : Text = Option.get<Text>(fee_schema, Types.metadata.__system_secondary_royalty);

    let royalty = switch (Properties.getClassPropertyShared(metadata, Types.metadata.__system)) {
      case (null) { [] };
      case (?val) {
        Royalties.royalty_to_array(val.value, _fee_schema);
      };
    };

    // make sur royalties definition didnt changed and no error can occured after transfering nft and funds.
    for (this_item in royalty.vals()) {
      let loaded_royalty = switch (Royalties._load_royalty(_fee_schema, this_item)) {
        case (#ok(val)) { val };
        case (#err(err)) {
          return #err(#awaited(Types.errors(#malformed_metadata, "end_sale_nft_origyn - error _load_royalty ", ?caller)));
        };
      };
    };

    debug if (debug_channel.end_sale) D.print("checking escrow" # debug_show (current_sale_state.current_escrow));

    switch (current_sale_state.current_escrow) {
      case (null) {
        //end sale but don't move NFT
        current_sale_state.status := #closed;
        debug if (debug_channel.end_sale) D.print("closed" # debug_show (current_sale_state.status));

        switch (
          Metadata.add_transaction_record<system>(
            state,
            {
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
            },
            caller,
          )
        ) {
          case (#ok(new_trx)) return end_sale_unlock_fee_account_callback(
            state,
            metadata,
            {
              token = current_sale_state.token;
              sale_id = current_sale.sale_id;
              seller_fee_accounts = seller_fee_accounts;
              bidder_fee_accounts = bidder_fee_accounts;
              fee_schema = fee_schema;
              owner = owner;
            },
            #trappable(#end_sale(new_trx)),
          );
          case (#err(err)) return #err(#trappable(err));
        };

      };
      case (?winning_escrow) {
        debug if (debug_channel.end_sale) D.print("verifying escrow");
        debug if (debug_channel.end_sale) D.print(debug_show (winning_escrow));
        let verified = switch (Verify.verify_escrow_receipt(state, winning_escrow, ?owner, ?current_sale.sale_id)) {
          case (#err(err)) return #err(#trappable(Types.errors(err.error, "end_sale_nft_origyn verifying escrow " # err.flag_point, ?caller)));
          case (#ok(res)) res;
        };

        debug if (debug_channel.end_sale) D.print("verified is  " # debug_show (verified.found_asset));
        //reentrancy risk so remove the escrow
        debug if (debug_channel.end_sale) D.print("putting escrow balance");
        debug if (debug_channel.end_sale) D.print(debug_show (winning_escrow));

        if (verified.found_asset.escrow.amount < winning_escrow.amount) {
          return #err(#trappable(Types.errors(#no_escrow_found, "end_sale_nft_origyn - error finding escrow, now less than bid " # debug_show (winning_escrow), ?caller)));
        } else {
          if (verified.found_asset.escrow.amount > winning_escrow.amount) {
            let total_amount = Nat.sub(verified.found_asset.escrow.amount, winning_escrow.amount);
            Map.set(
              verified.found_asset_list,
              token_handler,
              verified.found_asset.token_spec,
              {
                amount = total_amount;
                seller = verified.found_asset.escrow.seller;
                balances = null;
                buyer = verified.found_asset.escrow.buyer;
                token_id = verified.found_asset.escrow.token_id;
                token = verified.found_asset.escrow.token;
                sale_id = verified.found_asset.escrow.sale_id; //should be null
                lock_to_date = verified.found_asset.escrow.lock_to_date;
                account_hash = verified.found_asset.escrow.account_hash;
              },
            );
          } else {
            Map.delete(verified.found_asset_list, token_handler, verified.found_asset.token_spec);
          };
        };

        //reentancy risk so change the owner to inflight
        metadata := switch (Metadata.set_nft_owner(state, token_id, #extensible(#Text("trx in flight")), caller)) {
          case (#err(err)) return #err(#trappable(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller)));
          case (#ok(new_metadata)) new_metadata;
        };

        //move the payment to the sale revenue account
        //nyi: use transfer batch to split across royalties

        let (trx_id : ?Types.TransactionID, account_hash : ?Blob, fee : ?Nat) = switch (winning_escrow.token) {
          case (#ic(token)) {
            switch (token.standard) {
              case (#Ledger or #ICRC1) {
                if (winning_escrow.amount > Option.get<Nat>(token.fee, 0)) {
                  debug if (debug_channel.end_sale) D.print("found ledger");
                  let checker = Ledger_Interface.Ledger_Interface();
                  try {
                    switch (Star.toResult(await* checker.transfer_sale(state.canister(), winning_escrow, token_id, caller))) {
                      case (#ok(val)) {
                        (?val.0, ?val.1.account.sub_account, token.fee);
                      };
                      case (#err(err)) {
                        //put the escrow back because the payment failed
                        switch (Verify.verify_escrow_receipt(state, winning_escrow, ?owner, null)) {
                          case (#ok(reverify)) {
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
                          case (#err(err)) {
                            let target_escrow = {
                              account_hash = verified.found_asset.escrow.account_hash;
                              amount = winning_escrow.amount;
                              buyer = verified.found_asset.escrow.buyer;
                              seller = verified.found_asset.escrow.seller;
                              token_id = verified.found_asset.escrow.token_id;
                              token = verified.found_asset.escrow.token;
                              sale_id = verified.found_asset.escrow.sale_id;
                              lock_to_date = verified.found_asset.escrow.lock_to_date;
                            };
                            Map.set(verified.found_asset_list, token_handler, verified.found_asset.token_spec, target_escrow);
                          };
                        };

                        //put the owner back if the transaction fails
                        metadata := switch (Metadata.set_nft_owner(state, token_id, owner, caller)) {
                          case (#err(err)) return #err(#awaited(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller)));
                          case (#ok(new_metadata)) new_metadata;
                        };

                        return #err(#awaited(Types.errors(err.error, "end_sale_nft_origyn " # err.flag_point, ?caller)));
                      };
                    };
                  } catch (e) {
                    //put the escrow back because the payment failed
                    switch (Verify.verify_escrow_receipt(state, winning_escrow, ?owner, null)) {
                      case (#ok(reverify)) {
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
                      case (#err(err)) {
                        let target_escrow = {
                          account_hash = verified.found_asset.escrow.account_hash;
                          amount = winning_escrow.amount;
                          buyer = verified.found_asset.escrow.buyer;
                          seller = verified.found_asset.escrow.seller;
                          token_id = verified.found_asset.escrow.token_id;
                          token = verified.found_asset.escrow.token;
                          sale_id = verified.found_asset.escrow.sale_id;
                          lock_to_date = verified.found_asset.escrow.lock_to_date;
                        };
                        Map.set(verified.found_asset_list, token_handler, verified.found_asset.token_spec, target_escrow);
                      };
                    };

                    //put the owner back if the transaction fails
                    metadata := switch (Metadata.set_nft_owner(state, token_id, owner, caller)) {
                      case (#err(err)) return #err(#awaited(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller)));
                      case (#ok(new_metadata)) new_metadata;
                    };

                    return #err(#awaited(Types.errors(#unauthorized_access, "end_sale_nft_origyn catch branch" # Error.message(e), ?caller)));
                  };

                } else if (_fee_schema == Types.metadata.__system_fixed_royalty) {
                  (null, null, null);
                } else {
                  return #err(#awaited(Types.errors(#nyi, "end_sale_nft_origyn - price bellow token fee. only possible with fixed fees schema", ?caller)));
                };
              };
              case (_) return #err(#awaited(Types.errors(#nyi, "end_sale_nft_origyn - non ic type nyi - " # debug_show (token), ?caller)));
            };
          };
          case (#extensible(val)) return #err(#awaited(Types.errors(#nyi, "end_sale_nft_origyn - extensible token nyi - " # debug_show (val), ?caller)));
        };

        //change owner
        var new_metadata : CandyTypes.CandyShared = switch (Metadata.set_nft_owner(state, token_id, winning_escrow.buyer, caller)) {
          case (#ok(new_metadata)) { new_metadata };
          case (#err(err)) {
            //changing owner failed but the tokens are already gone....what to do...leave up to governance
            return #err(#awaited(Types.errors(#update_class_error, "end_sale_nft_origyn - error setting owner " # token_id, ?caller)));

          };
        };

        debug if (debug_channel.end_sale) D.print("updating metadata");

        //clear shared wallets
        new_metadata := Metadata.set_system_var(new_metadata, Types.metadata.__system_wallet_shares, #Option(null));
        Map.set(state.state.nft_metadata, Map.thash, token_id, new_metadata);

        current_sale_state.end_date := state.get_time();
        current_sale_state.status := #closed;
        current_sale_state.winner := ?winning_escrow.buyer;

        //log royalties
        //currently for auctions there are only secondary royalties

        debug if (debug_channel.market) D.print("fee_schema is " # debug_show (_fee_schema));
        debug if (debug_channel.market) D.print("royalty is " # debug_show (royalty));
        debug if (debug_channel.market) D.print("bidder_fee_accounts is " # debug_show (bidder_fee_accounts));
        debug if (debug_channel.market) D.print("seller_fee_accounts is " # debug_show (seller_fee_accounts));

        var fee_accounts_with_owner = Buffer.Buffer<(MigrationTypes.Current.FeeName, MigrationTypes.Current.Account)>(5);
        let _bidder_fee_accounts = Option.get(bidder_fee_accounts, []);
        let _seller_fee_accounts = Option.get(seller_fee_accounts, []);

        for (royalties_name in Royalties.royalties_names.vals()) {
          switch (Array.find<MigrationTypes.Current.FeeName>(_bidder_fee_accounts, func x = x == royalties_name)) {
            case (?val) {
              debug if (debug_channel.market) D.print("check if seller also provided a fee_schema for this royalty.");
              switch (Array.find<MigrationTypes.Current.FeeName>(_seller_fee_accounts, func x = x == royalties_name)) {
                case (?val) {
                  debug if (debug_channel.market) D.print("Free seller_fee_account fee_account : " #debug_show (val));
                  switch (
                    _unlock_fee_accounts_according_to_fee_schema(
                      state,
                      metadata,
                      {
                        token = current_sale_state.token;
                        sale_id = current_sale.sale_id;
                        fee_accounts = ?[val];
                        fee_schema = ?_fee_schema;
                        owner = owner;
                      },
                    )
                  ) {
                    case (#ok()) {};
                    case (#err(e)) {
                      /* Error here but we can not return error. Create garbage collector to get back this unlocked tokens.*/
                    };
                  };
                };
                case (_) {};
              };

              debug if (debug_channel.market) D.print("(_bidder_fee_account, winning_escrow.buyer) " # debug_show ((val, winning_escrow.buyer)));
              let _ = fee_accounts_with_owner.add((val, winning_escrow.buyer));
            };
            case (null) {
              switch (Array.find<MigrationTypes.Current.FeeName>(_seller_fee_accounts, func x = x == royalties_name)) {
                case (?val) {
                  debug if (debug_channel.market) D.print("(_seller_fee_account, owner) " # debug_show ((val, owner)));
                  let _ = fee_accounts_with_owner.add((val, owner));
                };
                case (null) {};
              };
            };
          };
        };

        let fee_ : Nat = Option.get(fee, 0);
        let total = Nat.sub(winning_escrow.amount, fee_);
        var fee_accounts_with_owner_array = Buffer.toArray(fee_accounts_with_owner);

        debug if (debug_channel.market) D.print("fee_accounts is " # debug_show (fee_accounts_with_owner_array));

        var remaning_fee : Nat = 0;
        for (this_item in royalty.vals()) {
          let loaded_royalty = switch (Royalties._load_royalty(_fee_schema, this_item)) {
            case (#ok(val)) { val };
            // case (#err(err)) {
            // Impossible
            // };
          };

          let tag = switch (loaded_royalty) {
            case (#fixed(val)) { val.tag };
            case (#dynamic(val)) { val.tag };
          };

          debug if (debug_channel.market) D.print("remaning_fee " #debug_show (remaning_fee) # " _fee_accounts is " # debug_show (fee_accounts_with_owner_array));
          switch (Array.find<(MigrationTypes.Current.FeeName, MigrationTypes.Current.Account)>(fee_accounts_with_owner_array, func((fee_name, acc)) { return fee_name == tag })) {
            case (?val) {
              //this fees will be paid by a specific account
              debug if (debug_channel.market) D.print("royalty matched in provided _fee_accounts. will use this account to pay royalties instead of winning escrow");
            };
            case (null) {
              //this fees will be paid by winning_escrow directly
              let total_royalty = switch (loaded_royalty) {
                case (#fixed(val)) {
                  Int.abs(Float.toInt(Float.ceil(val.fixedXDR)));
                };
                case (#dynamic(val)) {
                  (total * Int.abs(Float.toInt(val.rate * 1_000_000))) / 1_000_000;
                };
              };
              remaning_fee += total_royalty;
            };
          };
        };

        debug if (debug_channel.royalties) D.print("winning_escrow.amount is " # debug_show (winning_escrow.amount));
        debug if (debug_channel.royalties) D.print("remaning_fee is " # debug_show (remaning_fee));

        //let royaltyList = Buffer.Buffer<(Types.Account, Nat)>(royalty.size() + 1);
        if (winning_escrow.amount >= remaning_fee) {
          var remaining = Nat.sub(winning_escrow.amount, fee_);
          //if the fee is bigger than the amount we aren't going to pay anything
          //this should really be prevented elsewhere

          let royalty_result = Royalties._process_royalties(
            state,
            {
              name = _fee_schema;
              var remaining = remaining;
              total = total;
              fee = fee_;
              escrow = winning_escrow;
              royalty = royalty;
              broker_id = current_broker_id;
              original_broker_id = current_sale.original_broker_id;
              sale_id = ?current_sale.sale_id;
              account_hash = account_hash;
              metadata = metadata;
              token_id = ?token_id;
              token = winning_escrow.token;
              fee_accounts_with_owner = fee_accounts_with_owner_array;
              fee_schema = _fee_schema;
            },
            caller,
          );

          remaining := royalty_result.0;

          debug if (debug_channel.royalties) D.print("royalties paid is " # debug_show (remaining));
          //D.print("putting Sales balance");
          //D.print(debug_show(winning_escrow));

          let new_sale_balance = PutBalance.put_sales_balance(
            state,
            {
              winning_escrow with
              amount = remaining;
              sale_id = ?current_sale.sale_id;
              lock_to_date = null;
              account_hash = account_hash;
            },
            true,
          );

          let service : Types.Service = actor ((Principal.toText(state.canister())));
          let request_buffer = Buffer.Buffer<Types.ManageSaleRequest>(royalty_result.1.size() + 1);

          request_buffer.add(#withdraw(#sale({ new_sale_balance with
          withdraw_to = new_sale_balance.seller })));
          for ((thisRoyalty, is_fee_account) in royalty_result.1.vals()) {
            if (is_fee_account) {
              request_buffer.add(#withdraw(#fee_deposit({ account = thisRoyalty.buyer; token = thisRoyalty.token; amount = thisRoyalty.amount; withdraw_to = thisRoyalty.seller; status = #locked({ sale_id = current_sale.sale_id; token_id = token_id }) })));
            } else {
              request_buffer.add(#withdraw(#sale({ thisRoyalty with
              withdraw_to = thisRoyalty.seller })));
            };
          };
          debug if (debug_channel.royalties) D.print("attempt to distribute royalties request auction" # debug_show (Buffer.toArray(request_buffer)));
          //do not await
          let future = service.sale_batch_nft_origyn(Buffer.toArray(request_buffer));
          //debug if(debug_channel.royalties) D.print("attempt to distribute royalties auction" # debug_show(future));
        };

        switch (
          Metadata.add_transaction_record<system>(
            state,
            {
              token_id = token_id;
              index = 0;
              txn_type = #sale_ended {
                winning_escrow with
                sale_id = ?current_sale.sale_id;
                extensible = #Option(null);
              };
              timestamp = state.get_time();
            },
            caller,
          )
        ) {
          case (#ok(new_trx)) return #awaited(#end_sale(new_trx));
          case (#err(err)) return #err(#awaited(err));
        };
      };
    };
    return #err(#awaited(Types.errors(#nyi, "end_sale_nft_origyn - nyi - ", ?caller)));
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
  public func distribute_sale(state : StateAccess, request : Types.DistributeSaleRequest, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {
    if (NFTUtils.is_owner_network(state, caller) == false) return #err(#trappable(Types.errors(#unauthorized_access, "distribute_sale - not a canister owner or network", ?caller)));

    let request_buffer : Buffer.Buffer<Types.ManageSaleRequest> = Buffer.Buffer<Types.ManageSaleRequest>(1);

    label sellerSearch for (this_seller in Map.entries(state.state.sales_balances)) {
      switch (request.seller) {
        case (null) {};
        case (?seller) {
          if (Types.account_eq(this_seller.0, seller) == false) {
            continue sellerSearch;
          };
        };
      };
      for (this_buyer in Map.entries(this_seller.1)) {
        for (this_token in Map.entries(this_buyer.1)) {
          for (this_token in Map.entries(this_token.1)) {
            request_buffer.add(#withdraw(#sale({ this_token.1 with
            withdraw_to = this_token.1.seller })));
          };
        };
      };
    };

    let service : Types.Service = actor ((Principal.toText(state.canister())));
    let future = try {
      await service.sale_batch_nft_origyn(Buffer.toArray(request_buffer));
    } catch (e) {
      return #err(#awaited(Types.errors(#improper_interface, "distribute_sale - error with self call" # Error.message(e), ?caller)));
    };
    return #awaited(#distribute_sale(future));
  };

  /**
  * callback for market_transfer_nft_origyn_async
  * @param {StateAccess} state - StateAccess object for accessing the canister's state.
  * @param {CandyTypes.CandyShared} object containing the metadata for the token
  * @param {Types.TokenSpec} object containing the details of the transfer
  * @param {Text} object containing the sale_id
  * @param {?MigrationTypes.Current.FeeAccountsParams} object containing the fee_accounts
  * @param {?Text} object containing the fee_schema
  * @param {MigrationTypes.Current.Account} object containing the owner
  * @param {Result.Result<Types.MarketTransferRequestReponse, Types.OrigynError>} object containing the result of the transfer operation
  *
  * @returns {Result.Result<Types.MarketTransferRequestReponse, Types.OrigynError>} Result object representing the result of the transfer operation
  */
  private func async_market_transfer_unlock_fee_account_callback(
    state : StateAccess,
    metadata : CandyTypes.CandyShared,
    request : {
      token : Types.TokenSpec;
      sale_id : Text;
      fee_accounts : ?MigrationTypes.Current.FeeAccountsParams;
      fee_schema : ?Text;
      owner : MigrationTypes.Current.Account;
    },
    ret : Result.Result<Types.MarketTransferRequestReponse, Types.OrigynError>,
  ) : Result.Result<Types.MarketTransferRequestReponse, Types.OrigynError> {
    switch (
      _unlock_fee_accounts_according_to_fee_schema(
        state,
        metadata,
        {
          token = request.token;
          sale_id = request.sale_id;
          fee_accounts = request.fee_accounts;
          fee_schema = request.fee_schema;
          owner = request.owner;
        },
      )
    ) {
      case (#ok()) {};
      case (#err(e)) { return #err(e) };
    };

    return ret;
  };

  //handles async market transfer operations like instant where interaction with other canisters is required
  /**
    * Handles async market transfer operations like instant where interaction with other canisters is required
    * @param {StateAccess} state - StateAccess instance representing the state of the canister
    * @param {Types.MarketTransferRequest} request - MarketTransferRequest object containing the details of the transfer
    * @param {Principal} caller - Principal object representing the caller
    * @param {Bool} canister_call - Bool object representing whether the transfer is being done in a canister call
    *
    * @returns {Result.Result<Types.MarketTransferRequestReponse, Types.OrigynError>} Result object representing the result of the transfer operation
    */
  public func market_transfer_nft_origyn_async(state : StateAccess, request : Types.MarketTransferRequest, caller : Principal, canister_call : Bool) : async* Result.Result<Types.MarketTransferRequestReponse, Types.OrigynError> {

    debug if (debug_channel.market) D.print("in market_transfer_nft_origyn");
    var metadata = switch (Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) return #err(Types.errors(#token_not_found, "market_transfer_nft_origyn " # err.flag_point, ?caller));
      case (#ok(val)) val;
    };

    debug if (debug_channel.market) D.print("have metadata" # debug_show (metadata));

    let owner = switch (
      Metadata.get_nft_owner(metadata)
    ) {
      case (#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn " # err.flag_point, ?caller));
      case (#ok(val)) val;
    };

    debug if (debug_channel.market) D.print("have owner " # debug_show (owner));
    debug if (debug_channel.market) D.print("the caller" # debug_show (caller));

    //check to see if there is a current sale going on MKT0018
    let this_is_minted = Metadata.is_minted(metadata);

    debug if (debug_channel.market) D.print(request.token_id # " isminted" # debug_show (this_is_minted));
    if (this_is_minted) {
      //can't start auction if token is soulbound
      if (Metadata.is_soulbound(metadata)) return #err(Types.errors(#token_non_transferable, "market_transfer_nft_origyn ", ?caller));

      //this is a minted NFT - only the nft owner
      switch (Metadata.is_nft_owner(metadata, #principal(caller))) {
        case (#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn - not an owner of the NFT - minted sale" # err.flag_point, ?caller));
        case (#ok(val)) {
          if (val == false) {
            return #err(Types.errors(#unauthorized_access, "market_transfer_nft_origyn - not an owner of the NFT - minted sale", ?caller));
          };
        };
      };
    } else {
      //this is a staged NFT it can be sold by the canister owner or the canister manager
      switch (owner) {
        case (#extensible(ex)) {
          if (Conversions.candySharedToText(ex) == "trx in flight") {
            return #err(Types.errors(#unauthorized_access, "market_transfer_nft_origyn - not an owner of the canister - staged sale - trx in flight", ?caller));
          };
        };
        case (_) {};
      };

    };

    debug if (debug_channel.market) D.print("have minted " # debug_show (this_is_minted));

    //look for an existing sale
    switch (is_token_on_sale(state, metadata, caller)) {
      case (#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn ensure_no_sale " # err.flag_point, ?caller));
      case (#ok(val)) {
        if (val == true) {
          return #err(Types.errors(#existing_sale_found, "market_transfer_nft_origyn - sale exists " # request.token_id, ?caller));
        };
      };
    };

    let h = SHA256.New();
    h.write(Conversions.candySharedToBytes(#Text("com.origyn.nft.sale-id")));
    h.write(Conversions.candySharedToBytes(#Text("token-id")));
    h.write(Conversions.candySharedToBytes(#Text(request.token_id)));
    h.write(Conversions.candySharedToBytes(#Text("seller")));
    h.write(Conversions.candySharedToBytes(#Nat(MigrationTypes.Current.account_hash_uncompressed(owner))));
    h.write(Conversions.candySharedToBytes(#Text("timestamp")));
    h.write(Conversions.candySharedToBytes(#Int(state.get_time())));
    let internal_sale_id : Text = Conversions.candySharedToText(#Bytes(h.sum([])));

    debug if (debug_channel.market) D.print("checking pricing");

    switch (request.sales_config.pricing) {
      case (#instant(instant_config)) {
        D.print("instant_config");
        let {
          fee_schema : ?Text;
          fee_accounts : ?MigrationTypes.Current.FeeAccountsParams;
          transfer : Bool;
          config_map : MigrationTypes.Current.InstantConfig;
        } = switch (instant_config) {
          case (?config) {
            let config_map = MigrationTypes.Current.instantfeatures_to_map(config);

            {
              fee_schema = MigrationTypes.Current.load_fee_schema_instant_feature(?config_map);
              fee_accounts = MigrationTypes.Current.load_fee_accounts_instant_feature(?config_map);
              transfer = MigrationTypes.Current.load_transfer_instant_feature(?config_map);
              config_map = ?config_map;
            };
          };
          case (null) {
            {
              fee_schema = null;
              fee_accounts = null;
              transfer = false;
              config_map = null;
            };
          };
        };

        D.print("transfer " # debug_show (transfer));

        let _fee_schema : Text = if (this_is_minted == false) {
          Types.metadata.__system_primary_royalty;
        } else {
          switch (fee_schema) {
            case (?val) { val };
            case (null) { Types.metadata.__system_secondary_royalty };
          };
        };

        //the nft or staged nft is being instant transfered

        //if this is a marketable NFT, we need to create a waiver period

        //if this is not a marketable NFT we can insta trade

        //since this is a stage we need to call mint and it will do this for us
        //set new owner
        debug if (debug_channel.market) D.print("in market transfer");
        let escrow = switch (request.sales_config.escrow_receipt) {
          case (null) {
            //we can't insta transfer because no instructions are given
            //D.print("no escrow set");
            return #err(Types.errors(#improper_interface, "market_transfer_nft_origyn verifying escrow - not included ", ?caller));
          };
          case (?escrow) escrow;
        };

        //we should verify the escrow
        if (this_is_minted) {
          if (escrow.token_id == "") {
            //can't escrow to general for minted item
            return #err(Types.errors(#no_escrow_found, "market_transfer_nft_origyn can't find specific escrow for minted item", ?caller));
          };
        };

        debug if (debug_channel.market) D.print("current escrow is");
        //verify the specific escrow

        debug if (debug_channel.market) D.print(debug_show (escrow.seller));
        debug if (debug_channel.market) D.print(debug_show (escrow.buyer));
        debug if (debug_channel.market) D.print(escrow.token_id);
        debug if (debug_channel.market) D.print(debug_show (Types.token_hash(escrow.token)));
        debug if (debug_channel.market) D.print(debug_show (escrow.amount));

        var verified = switch (Verify.verify_escrow_receipt(state, escrow, ?owner, null)) {
          case (#err(err)) {
            //at this point the escrow isn't here, so we're going to try to recognize it.
            if (canister_call == false) {
              switch (
                Star.toResult(
                  await* recognize_escrow_nft_origyn(
                    state,
                    {
                      deposit = {
                        escrow with
                        sale_id = null;
                        trx_id = null;
                      };
                      lock_to_date = null;
                      token_id = escrow.token_id;
                    },
                    MigrationTypes.Current.account_to_principal(escrow.buyer),
                  )
                )
              ) {
                case (#ok(val)) {
                  return await* market_transfer_nft_origyn_async(state, request, caller, true);
                };
                case (#err(err)) {
                  return #err(Types.errors(err.error, "market_transfer_nft_origyn auto try escrow failed after recheck" # err.flag_point, ?caller));
                };
              };
            } else {
              return #err(Types.errors(err.error, "market_transfer_nft_origyn auto try escrow failed in a canister call " # err.flag_point, ?caller));
            };
          };
          case (#ok(res)) res;
        };

        verified := switch (Verify.verify_escrow_receipt(state, escrow, ?owner, null)) {
          case (#err(err)) {
            //we can't inline here becase the buyer isn't the caller and a malicious collection owner could sell a depositor something they did not want.
            return #err(Types.errors(err.error, "market_transfer_nft_origyn auto try escrow failed revalidate  " # err.flag_point, ?caller));
          };
          case (#ok(res)) res;
        };

        //reentrancy risk so we remove the credit from the escrow
        debug if (debug_channel.market) D.print("updating the asset list");
        debug if (debug_channel.market) D.print(debug_show (Map.size(verified.found_asset_list)));
        debug if (debug_channel.market) D.print(debug_show (Iter.toArray(Map.entries(verified.found_asset_list))));

        if (verified.found_asset.escrow.amount > escrow.amount) {
          debug if (debug_channel.market) D.print("should be overwriting escrow" # debug_show ((verified.found_asset.escrow.amount, escrow.amount)));
          Map.set(
            verified.found_asset_list,
            token_handler,
            verified.found_asset.token_spec,
            {
              verified.found_asset.escrow with
              amount = Nat.sub(verified.found_asset.escrow.amount, escrow.amount);
              balances = null;
            },
          );
        } else {
          debug if (debug_channel.market) D.print("should be deleting escrow" # debug_show ((verified.found_asset.token_spec)));
          Map.delete(verified.found_asset_list, token_handler, verified.found_asset.token_spec);
        };

        debug if (debug_channel.market) D.print(debug_show (Map.size(verified.found_asset_list)));
        debug if (debug_channel.market) D.print(debug_show (Iter.toArray(Map.entries(verified.found_asset_list))));

        switch (fee_accounts) {
          case (?fee_accounts) {
            debug if (debug_channel.market) D.print("fee_accounts is set !");
            if (_fee_schema != Types.metadata.__system_fixed_royalty) {
              debug if (debug_channel.market) D.print("but __system_fixed_royalty bad value, only com.origyn.royalties.fixed can be used -> error");
              return #err(Types.errors(#malformed_metadata, "market_transfer_nft_origyn fee_accounts need fixed fee_schema. Not compatible yet others royalties schema.", ?caller));
            };

            let broker_set = false;
            switch (
              _lock_fee_accounts_according_to_fee_schema(
                state,
                metadata,
                escrow.token,
                owner,
                internal_sale_id,
                broker_set,
                _fee_schema,
                fee_accounts,
              )
            ) {
              case (#ok()) {};
              case (#err(e)) { return #err(e) };
            };
          };
          case (null) {};
        };

        //reentrancy risk so set the owner to a black hole while transaction is in flight
        metadata := switch (Metadata.set_nft_owner(state, request.token_id, #extensible(#Text("trx in flight")), caller)) {
          case (#err(err)) return async_market_transfer_unlock_fee_account_callback(
            state,
            metadata,
            {
              token = escrow.token;
              sale_id = internal_sale_id;
              fee_accounts = fee_accounts;
              fee_schema = ?_fee_schema;
              owner = owner;
            },
            #err(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller)),
          );
          case (#ok(new_metadata)) new_metadata;
        };

        let (trx_id : ?Types.TransactionID, account_hash : ?Blob, fee : ?Nat) = switch (escrow.token) {
          case (#ic(token)) {
            switch (token.standard) {
              case (#Ledger or #ICRC1) {
                if (escrow.amount > Option.get<Nat>(token.fee, 0)) {
                  debug if (debug_channel.market) D.print("found ledger and sending sale " # debug_show (escrow));
                  let checker = Ledger_Interface.Ledger_Interface();
                  try {
                    switch (Star.toResult(await* checker.transfer_sale(state.canister(), escrow, request.token_id, caller))) {
                      case (#ok(val)) {
                        (?val.0, ?val.1.account.sub_account, ?val.2);
                      };
                      case (#err(err)) {
                        //put the escrow back because the payment failed
                        Verify.handle_escrow_update_error(state, escrow, ?owner, verified.found_asset, verified.found_asset_list);

                        //put the owner back if the transaction fails
                        metadata := switch (Metadata.set_nft_owner(state, request.token_id, owner, caller)) {
                          case (#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller));
                          case (#ok(new_metadata)) new_metadata;
                        };

                        return async_market_transfer_unlock_fee_account_callback(
                          state,
                          metadata,
                          {
                            token = escrow.token;
                            sale_id = internal_sale_id;
                            fee_accounts = fee_accounts;
                            fee_schema = ?_fee_schema;
                            owner = owner;
                          },
                          #err(Types.errors(err.error, "market_transfer_nft_origyn instant " # err.flag_point, ?caller)),
                        );
                      };
                    };
                  } catch (e) {
                    //put the escrow back because payment failed
                    Verify.handle_escrow_update_error(state, escrow, ?owner, verified.found_asset, verified.found_asset_list);

                    //put the owner back if the transaction fails
                    metadata := switch (Metadata.set_nft_owner(state, request.token_id, owner, caller)) {
                      case (#err(err)) {
                        return async_market_transfer_unlock_fee_account_callback(
                          state,
                          metadata,
                          {
                            token = escrow.token;
                            sale_id = internal_sale_id;
                            fee_accounts = fee_accounts;
                            fee_schema = ?_fee_schema;
                            owner = owner;
                          },
                          #err(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller)),
                        );
                      };
                      case (#ok(new_metadata)) new_metadata;
                    };

                    return async_market_transfer_unlock_fee_account_callback(
                      state,
                      metadata,
                      {
                        token = escrow.token;
                        sale_id = internal_sale_id;
                        fee_accounts = fee_accounts;
                        fee_schema = ?_fee_schema;
                        owner = owner;
                      },
                      #err(Types.errors(#unauthorized_access, "market_transfer_nft_origyn instant catch branch" # Error.message(e), ?caller)),
                    );
                  };
                } else if (_fee_schema == Types.metadata.__system_fixed_royalty) {
                  (null, null, null);
                } else {
                  return async_market_transfer_unlock_fee_account_callback(
                    state,
                    metadata,
                    {
                      token = escrow.token;
                      sale_id = internal_sale_id;
                      fee_accounts = fee_accounts;
                      fee_schema = ?_fee_schema;
                      owner = owner;
                    },
                    #err(Types.errors(#nyi, "market_transfer_nft_origyn - price bellow token fee. only possible with fixed fees schema", ?caller)),
                  );
                };
              };
              case (_) {
                //put the owner back if the transaction fails
                metadata := switch (Metadata.set_nft_owner(state, request.token_id, owner, caller)) {
                  case (#err(err)) {
                    return async_market_transfer_unlock_fee_account_callback(
                      state,
                      metadata,
                      {
                        token = escrow.token;
                        sale_id = internal_sale_id;
                        fee_accounts = fee_accounts;
                        fee_schema = ?_fee_schema;
                        owner = owner;
                      },
                      #err(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller)),
                    );
                  };
                  case (#ok(new_metadata)) new_metadata;
                };

                return async_market_transfer_unlock_fee_account_callback(
                  state,
                  metadata,
                  {
                    token = escrow.token;
                    sale_id = internal_sale_id;
                    fee_accounts = fee_accounts;
                    fee_schema = ?_fee_schema;
                    owner = owner;
                  },
                  #err(Types.errors(#nyi, "market_transfer_nft_origyn - ic type nyi - " # debug_show (token), ?caller)),
                );
              };
            };
          };

          case (#extensible(val)) {
            //put the owner back if the transaction fails
            metadata := switch (Metadata.set_nft_owner(state, request.token_id, owner, caller)) {
              case (#err(err)) {
                return async_market_transfer_unlock_fee_account_callback(
                  state,
                  metadata,
                  {
                    token = escrow.token;
                    sale_id = internal_sale_id;
                    fee_accounts = fee_accounts;
                    fee_schema = ?_fee_schema;
                    owner = owner;
                  },
                  #err(Types.errors(err.error, "market_transfer_nft_origyn can't set inflight owner " # err.flag_point, ?caller)),
                );
              };
              case (#ok(new_metadata)) new_metadata;
            };

            return async_market_transfer_unlock_fee_account_callback(
              state,
              metadata,
              {
                token = escrow.token;
                sale_id = internal_sale_id;
                fee_accounts = fee_accounts;
                fee_schema = ?_fee_schema;
                owner = owner;
              },
              #err(Types.errors(#nyi, "market_transfer_nft_origyn - extensible token nyi - " # debug_show (val), ?caller)),
            );
          };
        };

        debug if (debug_channel.market) D.print("transfered to account hash " # debug_show (account_hash));

        var b_freshmint = false;

        let txn_record = if (this_is_minted == false) {
          debug if (debug_channel.market) D.print("this_is_minted == false");
          //execute mint should add mint transaction
          b_freshmint := true;
          let rec = switch (Mint.execute_mint(state, request.token_id, escrow.buyer, ?escrow, caller)) {
            case (#err(err)) {
              //put the escrow back because the minting failed
              Verify.handle_escrow_update_error(state, escrow, ?owner, verified.found_asset, verified.found_asset_list);

              return async_market_transfer_unlock_fee_account_callback(
                state,
                metadata,
                {
                  token = escrow.token;
                  sale_id = internal_sale_id;
                  fee_accounts = fee_accounts;
                  fee_schema = ?_fee_schema;
                  owner = owner;
                },
                #err(Types.errors(err.error, "market_transfer_nft_origyn mint attempt" # err.flag_point, ?caller)),
              );
            };
            case (#ok(val)) {
              debug if (debug_channel.market) D.print("updating metadata after mint");
              metadata := val.1;
              val.2;
            };
          };
        } else {
          debug if (debug_channel.market) D.print("updating nft owner : " # debug_show (escrow.buyer));
          metadata := switch (Metadata.set_nft_owner(state, request.token_id, escrow.buyer, caller)) {
            case (#err(err)) {
              //ownership change failed, but we already have tokens...what to do...leave in flight and let governance fix
              /* switch(verify_escrow_reciept(state, escrow, ?owner, null)){
                    case(#ok(reverify)){
                        let target_escrow = {
                            account_hash = reverify.found_asset.escrow.account_hash;
                            amount       = Nat.add(reverify.found_asset.escrow.amount, escrow.amount);
                            buyer        = reverify.found_asset.escrow.buyer;
                            seller       = reverify.found_asset.escrow.seller;
                            token_id     = reverify.found_asset.escrow.token_id;
                            token        = reverify.found_asset.escrow.token;
                            sale_id      = reverify.found_asset.escrow.sale_id;
                            lock_to_date = reverify.found_asset.escrow.lock_to_date;
                        };
                        Map.set(reverify.found_asset_list, token_handler, verified.found_asset.token_spec, target_escrow);
                    };

                    //D.print("updating metadata");
                  Map.set(state.state.nft_metadata, Map.thash, escrow.token_id, new_metadata);
                  metadata := new_metadata;
                    //no need to mint
                  switch(Metadata.add_transaction_record<system>(state,{
                    token_id = request.token_id;
                    index    = 0;                 //mint should always be 0
                    txn_type = #sale_ended({
                      escrow with
                      seller     = owner;
                      sale_id    = null;
                      extensible = #Option(null);
                    });
                    timestamp = Time.now();
                  }, caller)){
                    case(#err(err)) return #err(Types.errors(  err.error, "market_transfer_nft_origyn adding transaction" # err.flag_point, ?caller));
                    case(#ok(val)) val;
                  };
                };
              case(#err(err)){
                let target_escrow = {
                    account_hash = verified.found_asset.escrow.account_hash;
                    amount       = escrow.amount;
                    buyer        = verified.found_asset.escrow.buyer;
                    seller       = verified.found_asset.escrow.seller;
                    token_id     = verified.found_asset.escrow.token_id;
                    token        = verified.found_asset.escrow.token;
                    sale_id      = verified.found_asset.escrow.sale_id;
                    lock_to_date = verified.found_asset.escrow.lock_to_date;
                };
                Map.set(verified.found_asset_list, token_handler, verified.found_asset.token_spec, target_escrow);
                };
              }; */

              return async_market_transfer_unlock_fee_account_callback(
                state,
                metadata,
                {
                  token = escrow.token;
                  sale_id = internal_sale_id;
                  fee_accounts = fee_accounts;
                  fee_schema = ?_fee_schema;
                  owner = owner;
                },
                #err(Types.errors(#update_class_error, "Market transfer Origyn - error setting owner item is now in limbo, use governance to fix" # escrow.token_id, ?caller)),
              );
            };

            case (#ok(new_metadata)) new_metadata;
          };

          //reset the system wallet shares
          metadata := Metadata.set_system_var(metadata, Types.metadata.__system_wallet_shares, #Option(null));

          //D.print("updating metadata");
          Map.set(state.state.nft_metadata, Map.thash, escrow.token_id, metadata);
          //no need to mint

          D.print("adding record : ");
          D.print("transfer is " # debug_show (transfer));
          if (transfer == true) {
            D.print("add owner_transfer");
            switch (
              Metadata.add_transaction_record<system>(
                state,
                {
                  token_id = request.token_id;
                  index = 0; //mint should always be 0
                  txn_type = #owner_transfer({
                    from = owner;
                    to = escrow.buyer;
                    extensible = #Option(null);
                  });
                  timestamp = Time.now();
                },
                caller,
              )
            ) {
              case (#err(err)) {
                return async_market_transfer_unlock_fee_account_callback(
                  state,
                  metadata,
                  {
                    token = escrow.token;
                    sale_id = internal_sale_id;
                    fee_accounts = fee_accounts;
                    fee_schema = ?_fee_schema;
                    owner = owner;
                  },
                  #err(Types.errors(err.error, "market_transfer_nft_origyn adding transaction" # err.flag_point, ?caller)),
                );
              };
              case (#ok(val)) { val };
            };
          } else {
            D.print("add sale_ended");
            switch (
              Metadata.add_transaction_record<system>(
                state,
                {
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
                },
                caller,
              )
            ) {
              case (#err(err)) {
                return async_market_transfer_unlock_fee_account_callback(
                  state,
                  metadata,
                  {
                    token = escrow.token;
                    sale_id = internal_sale_id;
                    fee_accounts = fee_accounts;
                    fee_schema = ?_fee_schema;
                    owner = owner;
                  },
                  #err(Types.errors(err.error, "market_transfer_nft_origyn adding transaction" # err.flag_point, ?caller)),
                );
              };
              case (#ok(val)) { val };
            };
          };
        };
        D.print("done");
        D.print("txn_record is " # debug_show (txn_record));

        Map.set(state.state.nft_metadata, Map.thash, escrow.token_id, metadata);

        let royalty = switch (Properties.getClassPropertyShared(metadata, Types.metadata.__system)) {
          case (null) { [] };
          case (?val) {
            debug if (debug_channel.market) D.print("found metadata" # debug_show (val.value));
            Royalties.royalty_to_array(val.value, _fee_schema);
          };
        };

        // make sur royalties definition didnt changed and no error can occured after transfering nft and funds.
        for (this_item in royalty.vals()) {
          let loaded_royalty = switch (Royalties._load_royalty(_fee_schema, this_item)) {
            case (#ok(val)) { val };
            case (#err(err)) {
              return #err(Types.errors(#malformed_metadata, "end_sale_nft_origyn - error _load_royalty ", ?caller));
            };
          };
        };

        //escrow already invalidated
        //calculate royalties
        debug if (debug_channel.market) D.print("trying to invalidate asset");
        debug if (debug_channel.market) D.print(debug_show (verified.found_asset));

        debug if (debug_channel.market) D.print("calculating royalty" # debug_show (metadata));
        debug if (debug_channel.market) D.print("royalty is " # debug_show (royalty));
        //note: this code path is always taken since checker.transferSale requires it or errors
        //we have included it here so that we can use Nat.sub without fear of underflow

        var fee_accounts_with_owner = Buffer.Buffer<(MigrationTypes.Current.FeeName, MigrationTypes.Current.Account)>(5);
        for (royalties_name in Option.get(fee_accounts, []).vals()) {
          let _ = fee_accounts_with_owner.add((royalties_name, owner));
        };

        let fee_ : Nat = Option.get(fee, 0);
        let total = Nat.sub(escrow.amount, fee_);
        var fee_accounts_with_owner_array = Buffer.toArray(fee_accounts_with_owner);

        debug if (debug_channel.market) D.print("fee_accounts is " # debug_show (fee_accounts_with_owner_array));

        var remaning_fee : Nat = 0;
        for (this_item in royalty.vals()) {
          let loaded_royalty = switch (Royalties._load_royalty(_fee_schema, this_item)) {
            case (#ok(val)) { val };
            // TODO: cover here more errors
            // case (#err(err)) {
            // Impossible
            // };
          };

          let tag = switch (loaded_royalty) {
            case (#fixed(val)) { val.tag };
            case (#dynamic(val)) { val.tag };
          };

          debug if (debug_channel.market) D.print("remaning_fee " #debug_show (remaning_fee) # " _fee_accounts is " # debug_show (fee_accounts_with_owner_array));
          switch (Array.find<(MigrationTypes.Current.FeeName, MigrationTypes.Current.Account)>(fee_accounts_with_owner_array, func((fee_name, acc)) { return fee_name == tag })) {
            case (?val) {
              //this fees will be paid by a specific account
              debug if (debug_channel.market) D.print("royalty matched in provided _fee_accounts. will use this account to pay royalties instead of winning escrow");
            };
            case (null) {
              //this fees will be paid by escrow directly
              let total_royalty = switch (loaded_royalty) {
                case (#fixed(val)) {
                  Int.abs(Float.toInt(Float.ceil(val.fixedXDR)));
                };
                case (#dynamic(val)) {
                  (total * Int.abs(Float.toInt(val.rate * 1_000_000))) / 1_000_000;
                };
              };
              remaning_fee += total_royalty;
            };
          };
        };

        if (escrow.amount >= remaning_fee) {
          var remaining = Nat.sub(escrow.amount, fee_);

          debug if (debug_channel.royalties) D.print("calling process royalty" # debug_show ((total, remaining)));

          let royalty_result = Royalties._process_royalties(
            state,
            {
              name = _fee_schema;
              var remaining = remaining;
              total = total;
              fee = fee_;
              escrow = escrow;
              royalty = royalty;
              sale_id = null;
              broker_id = request.sales_config.broker_id;
              original_broker_id = null;
              account_hash = account_hash;
              metadata = metadata;
              token_id = ?request.token_id;
              token = escrow.token;
              fee_accounts_with_owner = fee_accounts_with_owner_array;
              fee_schema = _fee_schema;
              owner = owner;
            },
            caller,
          );

          remaining := royalty_result.0;

          debug if (debug_channel.royalties) D.print("done with royalty" # debug_show ((total, remaining)));

          let new_sale_balance = PutBalance.put_sales_balance(
            state,
            {
              verified.found_asset.escrow with
              amount = remaining;
              sale_id = null;
              lock_to_date = null;
              account_hash = account_hash;
            },
            true,
          );

          let service : Types.Service = actor ((Principal.toText(state.canister())));
          let request_buffer = Buffer.Buffer<Types.ManageSaleRequest>(royalty_result.1.size() + 1);

          request_buffer.add(#withdraw(#sale({ new_sale_balance with
          withdraw_to = new_sale_balance.seller })));

          for ((thisRoyalty, is_fee_account) in royalty_result.1.vals()) {
            if (is_fee_account) {
              request_buffer.add(#withdraw(#fee_deposit({ account = thisRoyalty.buyer; token = thisRoyalty.token; amount = thisRoyalty.amount; withdraw_to = thisRoyalty.seller; status = #locked({ sale_id = internal_sale_id; token_id = request.token_id }) })));
            } else {
              request_buffer.add(#withdraw(#sale({ thisRoyalty with
              withdraw_to = thisRoyalty.seller })));
            };
          };
          debug if (debug_channel.royalties) D.print("attempt to distribute royalties request instant" # debug_show (Buffer.toArray(request_buffer)));

          let future = service.sale_batch_nft_origyn(Buffer.toArray(request_buffer));
          //debug if(debug_channel.royalties) D.print("attempt to distribute royalties instant" # debug_show(future));
        };

        return #ok(txn_record);
      };

      case (_) return #err(Types.errors(#nyi, "market_transfer_nft_origyn nyi pricing type async", ?caller));
    };
  };

  /**
  * callback for market_transfer_nft_origyn
  * @param {StateAccess} state - StateAccess object for accessing the canister's state.
  * @param {CandyTypes.CandyShared} object containing the metadata for the token
  * @param {Types.TokenSpec} object containing the details of the transfer
  * @param {Text} object containing the sale_id
  * @param {?MigrationTypes.Current.FeeAccountsParams} object containing the fee_accounts
  * @param {?Text} object containing the fee_schema
  * @param {MigrationTypes.Current.Account} object containing the owner
  *
  * @returns {Result.Result<Types.MarketTransferRequestReponse, Types.OrigynError>} Result object representing the result of the transfer operation
  */
  private func market_transfer_unlock_fee_account_callback(
    state : StateAccess,
    metadata : CandyTypes.CandyShared,
    request : {
      token : Types.TokenSpec;
      sale_id : Text;
      fee_accounts : ?MigrationTypes.Current.FeeAccountsParams;
      fee_schema : ?Text;
      owner : MigrationTypes.Current.Account;
    },
    ret : Result.Result<Types.MarketTransferRequestReponse, Types.OrigynError>,
  ) : Result.Result<Types.MarketTransferRequestReponse, Types.OrigynError> {
    switch (
      _unlock_fee_accounts_according_to_fee_schema(
        state,
        metadata,
        {
          token = request.token;
          sale_id = request.sale_id;
          fee_accounts = request.fee_accounts;
          fee_schema = request.fee_schema;
          owner = request.owner;
        },
      )
    ) {
      case (#ok()) {};
      case (#err(e)) { return #err(e) };
    };

    return ret;
  };

  //handles non-async market functions like starting an auction
  /**
    * Processes royalties for a given escrow transaction and updates state accordingly.
    * @param {StateAccess} state - StateAccess object for accessing the canister's state.
    * @param {Types.MarketTransferRequest} request - An object containing the necessary information for royalty processing.
    * @param {Principal} caller - Principal object containing the caller of the function.
    *
    * @returns {Result.Result<Types.MarketTransferRequestReponse, Types.OrigynError>} Result object representing the result of the transfer operation
    */
  public func market_transfer_nft_origyn(state : StateAccess, request : Types.MarketTransferRequest, caller : Principal) : async* Result.Result<Types.MarketTransferRequestReponse, Types.OrigynError> {

    debug if (debug_channel.market) D.print("in market_transfer_nft_origyn");
    var metadata = switch (Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) {
        return #err(Types.errors(#token_not_found, "market_transfer_nft_origyn " # err.flag_point, ?caller));
      };
      case (#ok(val)) {
        val;
      };
    };

    debug if (debug_channel.market) D.print("have metadata");

    //can't start auction if token is a phisycal object unless in escrow with a node
    if (Metadata.is_physical(metadata)) {
      if (Metadata.is_in_physical_escrow(metadata) == false) {
        return #err(Types.errors(#token_non_transferable, "market_transfer_nft_origyn physical token must be escrowed", ?caller));
      };
    };

    let owner = switch (
      Metadata.get_nft_owner(metadata)
    ) {
      case (#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn " # err.flag_point, ?caller));
      case (#ok(val)) val;
    };

    debug if (debug_channel.market) D.print("have owner " # debug_show (owner));
    debug if (debug_channel.market) D.print("the caller" # debug_show (caller));

    //check to see if there is a current sale going on MKT0018

    let this_is_minted = Metadata.is_minted(metadata);

    debug if (debug_channel.market) D.print(request.token_id # " isminted" # debug_show (this_is_minted));
    if (this_is_minted) {
      //can't start auction if token is soulbound
      if (Metadata.is_soulbound(metadata)) return #err(Types.errors(#token_non_transferable, "market_transfer_nft_origyn ", ?caller));

      //this is a minted NFT - only the nft owner or nft manager can sell it
      switch (Metadata.is_nft_owner(metadata, #principal(caller))) {
        case (#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn - not an owner of the NFT - minted sale" # err.flag_point, ?caller));
        case (#ok(val)) {
          if (val == false) return #err(Types.errors(#unauthorized_access, "market_transfer_nft_origyn - not an owner of the NFT - minted sale", ?caller));
        };
      };
    } else {
      //this is a staged NFT it can be sold by the canister owner or the canister manager
      if (NFTUtils.is_owner_manager_network(state, caller) == false) return #err(Types.errors(#unauthorized_access, "market_transfer_nft_origyn - not an owner of the canister - staged sale ", ?caller));
    };

    debug if (debug_channel.market) D.print("have minted " # debug_show (this_is_minted));

    //look for an existing sale
    switch (is_token_on_sale(state, metadata, caller)) {
      case (#err(err)) return #err(Types.errors(err.error, "market_transfer_nft_origyn ensure_no_sale " # err.flag_point, ?caller));
      case (#ok(val)) {
        if (val == true) return #err(Types.errors(#existing_sale_found, "market_transfer_nft_origyn - sale exists " # request.token_id, ?caller));
      };
    };

    debug if (debug_channel.market) D.print("checking pricing");

    //what does an escrow reciept do for an auction? Place a bid?
    //for now fail if provided
    switch (request.sales_config.escrow_receipt) {
      case (?val) return #err(Types.errors(#nyi, "market_transfer_nft_origyn - handling escrow for auctions NYI", ?caller));
      case (_) {};
    };

    if (this_is_minted == false) {
      return #err(Types.errors(#nyi, "cannot auction off a unminted item", ?caller));
    };

    let _time = state.get_time();

    let h = SHA256.New();
    h.write(Conversions.candySharedToBytes(#Text("com.origyn.nft.sale-id")));
    h.write(Conversions.candySharedToBytes(#Text("token-id")));
    h.write(Conversions.candySharedToBytes(#Text(request.token_id)));
    h.write(Conversions.candySharedToBytes(#Text("seller")));
    h.write(Conversions.candySharedToBytes(#Nat(MigrationTypes.Current.account_hash_uncompressed(owner))));
    h.write(Conversions.candySharedToBytes(#Text("timestamp")));
    h.write(Conversions.candySharedToBytes(#Int(_time)));
    let sale_id : Text = Conversions.candySharedToText(#Bytes(h.sum([])));

    let {
      reserve : ?Nat;
      buy_now : ?Nat;
      token : MigrationTypes.Current.TokenSpec;
      start_date : Int;
      start_price : Nat;
      end_date : Int;
      dutch : ?MigrationTypes.Current.DutchParams;
      allow_list : ?Map.Map<Principal, Bool>;
      notify : [Principal];
      fee_accounts : ?MigrationTypes.Current.FeeAccountsParams;
      fee_schema : ?Text;
    } = switch (request.sales_config.pricing) {
      case (#ask(null)) {
        {
          reserve = null;
          buy_now = null;
          token : MigrationTypes.Current.TokenSpec = MigrationTypes.Current.OGY();
          start_date : Int = _time;
          start_price : Nat = 1;
          end_date : Int = _time + NFTUtils.MINUTE_LENGTH;
          allow_list = null;
          dutch = null;
          notify = [];
          fee_accounts = null;
          fee_schema = null;
        };
      };
      case (#ask(?val)) {
        debug if (debug_channel.market) D.print("load ask detail");
        let ret = switch (_get_ask_sale_detail(state, val, caller, metadata)) {
          case (#ok(val)) val;
          case (#err(err)) return #err(err);
        };

        debug if (debug_channel.market) D.print("checking fee_accounts parameters");
        switch (ret.fee_accounts) {
          case (?fee_accounts) {
            debug if (debug_channel.market) D.print("fee_accounts is set !");
            let fee_schema : Text = switch (ret.fee_schema) {
              case (?val) {
                if (val != Types.metadata.__system_fixed_royalty) {
                  debug if (debug_channel.market) D.print("but __system_fixed_royalty bad value, only com.origyn.royalties.fixed can be used -> error");
                  return #err(Types.errors(#malformed_metadata, "market_transfer_nft_origyn fee_accounts need fixed fee_schema. Not compatible yet others royalties schema.", ?caller));
                };
                val;
              };
              case (null) {
                debug if (debug_channel.market) D.print("but __system_fixed_royalty is not set -> error");
                return #err(Types.errors(#malformed_metadata, "market_transfer_nft_origyn fee_accounts need fixed fee_schema. Not compatible yet others royalties schema.", ?caller));
              };
            };

            let broker_set = if (request.sales_config.broker_id == null) {
              false;
            } else {
              true;
            };

            switch (
              _lock_fee_accounts_according_to_fee_schema(
                state,
                metadata,
                ret.token,
                #account({ owner = caller; sub_account = null }),
                sale_id,
                broker_set,
                fee_schema,
                fee_accounts,
              )
            ) {
              case (#ok()) { ret };
              case (#err(e)) { return #err(e) };
            };
          };
          case (null) { ret };
        };
      };

      case (_) return #err(Types.errors(#nyi, "market_transfer_nft_origyn nyi pricing type", ?caller));
    };

    var participants = Map.new<Principal, Int>();
    Map.set<Principal, Int>(participants, Map.phash, caller, _time);

    let new_auction : MigrationTypes.Current.AuctionState = {
      config = MigrationTypes.Current.pricing_shared_to_pricing(request.sales_config.pricing);
      var current_bid_amount = 0;
      var current_broker_id = request.sales_config.broker_id;
      var end_date = end_date;
      var start_date : Int = start_date;
      var min_next_bid = start_price;
      var current_escrow = null;
      var current_config = null;
      var wait_for_quiet_count = ?0;
      seller = owner;
      token = token;
      var notify_queue = if (notify.size() == 0) {
        null;
      } else {
        var newQueue = Deque.empty<(Principal, ?MigrationTypes.Current.SubscriptionID)>();

        ignore Array.map<Principal, (Principal, ?MigrationTypes.Current.SubscriptionID)>(
          notify,
          func(x : Principal) {
            newQueue := Deque.pushBack<(Principal, ?MigrationTypes.Current.SubscriptionID)>(newQueue, (x, null));
            (x, null);
          },
        );

        ?newQueue;
      };

      var status = if (_time >= start_date) {
        #open;
      } else {
        #not_started;
      };
      var winner = null;
      allow_list = allow_list;
      var participants = participants;
    };

    Map.set<Text, Types.SaleStatus>(
      state.state.nft_sales,
      Map.thash,
      sale_id,
      {
        sale_id = sale_id;
        original_broker_id = switch (request.sales_config.broker_id) {
          case (?_broker_id) {
            ?MigrationTypes.Current.account_to_principal(_broker_id);
          };
          case (null) { null };
        };
        broker_id = null; //currently the broker id for a auction doesn't do much. perhaps it should split the broker reward?
        token_id = request.token_id;
        sale_type = #auction(new_auction);
      },
    );

    debug if (debug_channel.market) D.print("Setting sale id");
    metadata := Metadata.set_system_var(metadata, Types.metadata.__system_current_sale_id, #Text(sale_id));

    Map.set(state.state.nft_metadata, Map.thash, request.token_id, metadata);

    let txn = Metadata.add_transaction_record<system>(
      state,
      {
        token_id = request.token_id;
        index = 0;
        timestamp = _time;
        txn_type = #sale_opened({
          sale_id = sale_id;
          pricing = request.sales_config.pricing;
          extensible = #Option(null);
        });
      },
      caller

    );

    //set timer for notify
    if (notify.size() > 0) {
      //handle notify
      Set.add<Text>(state.state.pending_sale_notifications, thash, sale_id);
      if (state.notify_timer.get() == null) {
        state.notify_timer.set(?Timer.setTimer(#nanoseconds(1), state.handle_notify));
      };
    };

    //set timer for dutch
    switch (dutch) {
      case (?dutch) {
        debug if (debug_channel.dutch) D.print("dutch auction was submitted");
      };
      case (null) {};
    };

    if (new_auction.status == #open) {
      let timerTool = state.timertool;

      let actionRequest = {
        actionType = "close_sale_timeouted_nft_origyn";
        params = to_candid (sale_id);
      };

      let actionId = timerTool.setActionASync<system>(Nat64.toNat(Nat64.fromIntWrap(end_date)), actionRequest, Nat64.toNat(Nat64.fromIntWrap(NFTUtils.HOUR_LENGTH)));
    } else if (new_auction.status == #not_started) {
      // TODO
      // let timerTool = state.timertool;

      // let actionRequest = {
      //   actionType = "open_sale_nft_origyn";
      //   params = Blob.fromArray([]); // todo add param
      // };

      // let actionId = timerTool.setActionASync<system>(Nat64.toNat(Nat64.fromIntWrap(_time - start_date)), actionRequest, Nat64.toNat(Nat64.fromIntWrap(3600)));
    };

    return txn;
  };

  /**
  * _get_ask_sale_detail
  * @param {StateAccess} state - StateAccess object for accessing the canister's state.
  * @param {[Types.AskFeature]} val - Array of ask features to be used to determine the sale details.
  * @param {Principal} caller - Principal of the caller making the request.
  * @param {CandyTypes.CandyShared} metadata - CandyShared object containing the metadata for the token.
  * @returns {Result.Result<{ reserve : ?Nat; buy_now : ?Nat; token : MigrationTypes.Current.TokenSpec; start_date : Int; start_price : Nat; end_date : Int; dutch : ?MigrationTypes.Current.DutchParams; allow_list : ?Map.Map<Principal, Bool>; notify : [Principal]; fee_accounts : ?MigrationTypes.Current.FeeAccountsParams; fee_schema : ?Text }, Types.OrigynError>} - Result object containing the sale details.
  */
  private func _get_ask_sale_detail(state : StateAccess, val : [Types.AskFeature], caller : Principal, metadata : CandyTypes.CandyShared) : Result.Result<{ reserve : ?Nat; buy_now : ?Nat; token : MigrationTypes.Current.TokenSpec; start_date : Int; start_price : Nat; end_date : Int; dutch : ?MigrationTypes.Current.DutchParams; allow_list : ?Map.Map<Principal, Bool>; notify : [Principal]; fee_accounts : ?MigrationTypes.Current.FeeAccountsParams; fee_schema : ?Text }, Types.OrigynError> {
    //what does an escrow reciept do for an auction? Place a bid?
    //for now ignore
    let ask_details = MigrationTypes.Current.features_to_map(val);

    let start_date : Int = switch (Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #start_date)) {
      case (?#start_date(val)) val;
      case (_) state.get_time();
    };

    let dutch : ?MigrationTypes.Current.DutchParams = MigrationTypes.Current.load_dutch_ask_feature(?ask_details);
    let fee_accounts : ?MigrationTypes.Current.FeeAccountsParams = MigrationTypes.Current.load_fee_accounts_ask_feature(?ask_details);
    let fee_schema : ?Text = MigrationTypes.Current.load_fee_schema_ask_feature(?ask_details);

    let _fee_schema : Text = switch (fee_schema) {
      case (?val) {
        if (val != Types.metadata.__system_fixed_royalty) {
          val;
        } else {
          Types.metadata.__system_fixed_royalty;
        };
      };
      case (null) { Types.metadata.__system_secondary_royalty };
    };

    let royalty = switch (Properties.getClassPropertyShared(metadata, Types.metadata.__system)) {
      case (null) { [] };
      case (?val) {
        Royalties.royalty_to_array(val.value, _fee_schema);
      };
    };

    let start_price : Nat = switch (Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #start_price)) {
      case (?#start_price(_start_price)) {
        var remaning_fee : Nat = 0;

        for (this_item in royalty.vals()) {
          let loaded_royalty = switch (Royalties._load_royalty(_fee_schema, this_item)) {
            case (#ok(val)) { val };
            case (#err(err)) {
              return #err(Types.errors(#malformed_metadata, "end_sale_nft_origyn - error _load_royalty ", ?caller));
            };
          };

          let tag = switch (loaded_royalty) {
            case (#fixed(val)) { val.tag };
            case (#dynamic(val)) { val.tag };
          };

          switch (fee_accounts) {
            case (?_fee_accounts) {
              debug if (debug_channel.market) D.print("remaning_fee _fee_accounts is " # debug_show (_fee_accounts));
              switch (Array.find<Text>(_fee_accounts, func(val) { return val == tag })) {
                case (?val) {
                  //this fees will be paid by specific fee_account directly
                  debug if (debug_channel.market) D.print("royalty matched in provided _fee_accounts. will use this account to pay royalties instead of winning escrow");
                };
                case (null) {
                  //this fees will be paid by winning_escrow directly
                  let total_royalty = switch (loaded_royalty) {
                    case (#fixed(val)) {
                      Int.abs(Float.toInt(Float.ceil(val.fixedXDR)));
                    };
                    case (#dynamic(val)) {
                      // use minimal start price provided to calculate minimal price to pay
                      (_start_price * Int.abs(Float.toInt(val.rate * 1_000_000))) / 1_000_000;
                    };
                  };
                  remaning_fee += total_royalty;
                };
              };
            };
            case (null) {
              //this fees will be paid by winning_escrow directly
              let total_royalty = switch (loaded_royalty) {
                case (#fixed(val)) {
                  Int.abs(Float.toInt(Float.ceil(val.fixedXDR)));
                };
                case (#dynamic(val)) {
                  // use minimal start price provided to calculate minimal price to pay
                  (_start_price * Int.abs(Float.toInt(val.rate * 1_000_000))) / 1_000_000;
                };
              };
              remaning_fee += total_royalty;
            };
          };
        };

        if (_start_price < remaning_fee) {
          return #err(Types.errors(#improper_interface, "market_transfer_nft_origyn - start price cannot be less than mininal fee", ?caller));
        };

        _start_price;
      };
      case (_) {
        switch (dutch) {
          case (null) {
            var remaning_fee : Nat = 0;

            for (this_item in royalty.vals()) {
              let loaded_royalty = switch (Royalties._load_royalty(_fee_schema, this_item)) {
                case (#ok(val)) { val };
                case (#err(err)) {
                  return #err(Types.errors(#malformed_metadata, "end_sale_nft_origyn - error _load_royalty ", ?caller));
                };
              };

              let tag = switch (loaded_royalty) {
                case (#fixed(val)) { val.tag };
                case (#dynamic(val)) { val.tag };
              };

              switch (fee_accounts) {
                case (?_fee_accounts) {
                  debug if (debug_channel.market) D.print("remaning_fee _fee_accounts is " # debug_show (_fee_accounts));
                  switch (Array.find<Text>(_fee_accounts, func(val) { return val == tag })) {
                    case (?val) {
                      //this fees will be paid by specific fee_account directly
                      debug if (debug_channel.market) D.print("royalty matched in provided _fee_accounts. will use this account to pay royalties instead of winning escrow");
                    };
                    case (null) {
                      //this fees will be paid by winning_escrow directly
                      let total_royalty = switch (loaded_royalty) {
                        case (#fixed(val)) {
                          Int.abs(Float.toInt(Float.ceil(val.fixedXDR)));
                        };
                        case (#dynamic(val)) {
                          // use minimal start price provided to calculate minimal price to pay
                          (1 * Int.abs(Float.toInt(val.rate * 1_000_000))) / 1_000_000;
                        };
                      };
                      remaning_fee += total_royalty;
                    };
                  };
                };
                case (null) {
                  //this fees will be paid by winning_escrow directly
                  let total_royalty = switch (loaded_royalty) {
                    case (#fixed(val)) {
                      Int.abs(Float.toInt(Float.ceil(val.fixedXDR)));
                    };
                    case (#dynamic(val)) {
                      // use minimal start price provided to calculate minimal price to pay
                      (1 * Int.abs(Float.toInt(val.rate * 1_000_000))) / 1_000_000;
                    };
                  };
                  remaning_fee += total_royalty;
                };
              };
            };
            remaning_fee;
          };
          case (?val) {
            return #err(Types.errors(#improper_interface, "market_transfer_nft_origyn - dutch auctions require a start price", ?caller));
          };
        };
      };
    };

    let end_date : Int = switch (Map.get<MigrationTypes.Current.AskFeatureKey, MigrationTypes.Current.AskFeature>(ask_details, MigrationTypes.Current.ask_feature_set_tool, #ending)) {
      case (?#ending(val)) {
        switch (val) {
          case (#date(val)) {
            if (val <= start_date) return #err(Types.errors(#improper_interface, "market_transfer_nft_origyn - end date cannot be before start date", ?caller));
            val : Int;
          };
          case (#timeout(val)) {
            let target_end_date : Int = state.get_time() + val;
            if (target_end_date <= start_date) return #err(Types.errors(#improper_interface, "market_transfer_nft_origyn - end date cannot be before start date", ?caller));
            target_end_date;
          };
        };
      };
      case (_) {
        //default length of an sale is one minute
        (state.get_time() + NFTUtils.MINUTE_LENGTH) : Int;
      };
    };

    let buy_now = switch (Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #buy_now)) {
      case (?#buy_now(val)) {
        if (val < start_price) return #err(Types.errors(#improper_interface, "market_transfer_nft_origyn - buy now cannot be less than start price", ?caller));
        ?val;
      };
      case (_) { null };
    };

    let reserve : ?Nat = MigrationTypes.Current.load_reserve_ask_feature(?ask_details);
    let token : MigrationTypes.Current.TokenSpec = MigrationTypes.Current.load_token_ask_feature(?ask_details);
    let notify : [Principal] = MigrationTypes.Current.load_notify_ask_feature(?ask_details);

    switch (buy_now, reserve) {
      case (?buy_now, ?reserve) {
        if (buy_now < reserve) return #err(Types.errors(#improper_interface, "market_transfer_nft_origyn - buy now cannot be less than reserve", ?caller));
      };
      case (_) {};
    };

    let allow_list : Map.Map<Principal, Bool> = Map.new<Principal, Bool>();

    switch (Map.get(ask_details, MigrationTypes.Current.ask_feature_set_tool, #allow_list)) {
      case (?#allow_list(val)) {
        for (thisitem in val.vals()) {
          Map.set<Principal, Bool>(allow_list, Map.phash, thisitem, true);
        };
      };
      case (_) {};
    };

    #ok({
      reserve = reserve;
      buy_now = buy_now;
      token : MigrationTypes.Current.TokenSpec = token;
      start_date : Int = start_date;
      start_price : Nat = start_price;
      end_date : Int = end_date;
      dutch = dutch;
      fee_accounts = fee_accounts;
      fee_schema = fee_schema;
      allow_list = if (Map.size(allow_list) == 0) {
        null;
      } else {
        ?allow_list;
      };
      notify = notify;
    });
  };

  /**
  * handle_notify
  * @param {StateAccess} state - StateAccess object for accessing the canister's state.
  * @returns {async *}
  */
  public func handle_notify(state : StateAccess) : async () {

    debug if (debug_channel.notifications) D.print("in handle_notify");

    //let this be scheduled again;
    state.notify_timer.set(null);

    label search for (thisItem in Set.keys(state.state.pending_sale_notifications)) {
      debug if (debug_channel.notifications) D.print("in loop " # thisItem);
      let { notify; sale; notify_queue } = switch (Map.get<Text, Types.SaleStatus>(state.state.nft_sales, thash, thisItem)) {
        case (null) {
          //should be unreachable, but lets remove it from the map anyway;
          ignore Set.remove<Text>(state.state.pending_sale_notifications, thash, thisItem);
          continue search;
        };
        case (?sale) {
          let (#auction(sale_type)) = sale.sale_type else continue search;
          //make sure the sale is still open
          if (sale_type.status == #closed) {
            debug if (debug_channel.notifications) D.print("removing because the sale is closed " # thisItem);
            ignore Set.remove(state.state.pending_sale_notifications, thash, thisItem);
            continue search;
          };

          let ?notify_queue = sale_type.notify_queue else {
            //should be unreachable, but lets remove it from the map anyway;
            ignore Set.remove<Text>(state.state.pending_sale_notifications, thash, thisItem);
            continue search;
          };

          if (Deque.isEmpty<(Principal, ?MigrationTypes.Current.SubscriptionID)>(notify_queue)) {
            ignore Set.remove<Text>(state.state.pending_sale_notifications, Map.thash, thisItem);
            continue search;
          };

          debug if (debug_channel.notifications) D.print("popping the notify que:" # debug_show (notify_queue));

          let ?item = Deque.popFront<(Principal, ?MigrationTypes.Current.SubscriptionID)>(notify_queue) else {
            //should be unreachable, but lets remove it from the map anyway;
            ignore Set.remove<Text>(state.state.pending_sale_notifications, Map.thash, thisItem);
            continue search;
          };

          sale_type.notify_queue := ?item.1;

          debug if (debug_channel.notifications) D.print("after the pop:" # debug_show (sale_type.notify_queue));

          {
            notify = item.0;
            sale = sale;
            notify_queue = item.1;
          };
        };
      };

      let #ok(sale_state) = NFTUtils.get_auction_state_from_status(sale) else {
        //should be unreachable, but lets remove it from the map anyway;
        ignore Set.remove<Text>(state.state.pending_sale_notifications, thash, thisItem);
        continue search;
      };

      let #ok(owner) = Metadata.get_nft_owner_by_id(state, sale.token_id) else {
        ignore Set.remove<Text>(state.state.pending_sale_notifications, thash, thisItem);
        continue search;
      };

      let remote : Types.Subscriber = actor (Principal.toText(notify.0));
      debug if (debug_channel.notifications) D.print("about to send");
      remote.notify_sale_nft_origyn({
        escrow_info = NFTUtils.get_escrow_account_info(
          {
            amount = sale_state.min_next_bid;
            seller = owner;
            buyer = #principal(notify.0);
            token_id = sale.token_id;
            token = sale_state.token;
          },
          state.canister(),
        );
        sale = {
          sale with
          sale_type = switch (sale.sale_type) {
            case (#auction(val)) {
              #auction(Types.AuctionState_stabalize_for_xfer(val));
            };
            /* case(_){
                  return #err(Types.errors(  #sale_not_found, "sale_status_nft_origyn not an auction ", ?caller));
              }; */
          };
        };
        seller = owner;
        token_id = sale.token_id;
        collection = state.canister();
      });

      if (Deque.isEmpty<(Principal, ?MigrationTypes.Current.SubscriptionID)>(notify_queue)) {
        debug if (debug_channel.notifications) D.print("finished with this sale:" # thisItem);
        ignore Set.remove<Text>(state.state.pending_sale_notifications, thash, thisItem);
      } else {
        debug if (debug_channel.notifications) D.print("this sale is not finished:" # debug_show (notify_queue));
      };

      continue search;
    };

    if (Set.size(state.state.pending_sale_notifications) > 0) {
      //set the timer to run again in 1 second;
      debug if (debug_channel.notifications) D.print("resetting the timer left:" # debug_show (Set.size(state.state.pending_sale_notifications)));
      state.notify_timer.set(?Timer.setTimer(#nanoseconds(1000000000), state.handle_notify));
    };

  };

  /**
  * calc_dutch_price
  * @param {StateAccess} state - StateAccess object for accessing the canister's state.
  * @param {Types.AuctionState} auction - AuctionState object containing the auction details.
  * @param {CandyTypes.CandyShared} metadata - CandyShared object containing the metadata for the sale.
  * @returns {Types.AuctionState} - AuctionState object containing the updated auction details.
  */
  public func calc_dutch_price(state : StateAccess, auction : Types.AuctionState, metadata : CandyTypes.CandyShared) : Types.AuctionState {
    //make sure the sale is still open
    if (auction.status == #closed) {
      debug if (debug_channel.dutch) D.print("sale is closed. returning final price ");
      return auction;
    };

    let config = switch (auction.config) {
      case (#ask(?val)) {

        switch (_get_ask_sale_detail(state, Iter.toArray<MigrationTypes.Current.AskFeature>(Map.vals<MigrationTypes.Current.AskFeatureKey, MigrationTypes.Current.AskFeature>(val)), state.canister(), metadata)) {
          case (#ok(val)) val;
          case (#err(err)) {
            //should be unreachable;
            debug if (debug_channel.dutch) D.print("dutch price requested for non-dutch sale - error " # err.flag_point);
            return auction;
          };
        };
      };
      case (_) {
        //should be unreachable
        debug if (debug_channel.dutch) D.print("dutch price requested for non-dutch sale");
        return auction;
      };
    };

    let ?dutch = config.dutch else {
      //should be unreachable,
      debug if (debug_channel.dutch) D.print("dutch price requested but dutch not configured");
      return auction;
    };

    let start_price : Nat = config.start_price;

    debug if (debug_channel.dutch) D.print("start price is " # debug_show (start_price));

    let reserve = switch (config.reserve) {
      case (null) 1;
      case (?val) val;
    };

    debug if (debug_channel.dutch) D.print("reserve price is " # debug_show (reserve));

    if (state.get_time() < auction.start_date) {
      debug if (debug_channel.dutch) D.print("dutch price requested but auction isn't open yet");
      return auction;
    };

    let time_diff = Int.abs(state.get_time() - auction.start_date);

    debug if (debug_channel.dutch) D.print("time_diff is " # debug_show ((time_diff, NFTUtils.MINUTE_LENGTH)));

    let reduction_cycles : Nat = switch (dutch.time_unit) {
      case (#minute(val)) {
        debug if (debug_channel.dutch) D.print("minute " # debug_show (val));
        time_diff / (NFTUtils.MINUTE_LENGTH * val);
      };
      case (#hour(val)) {
        debug if (debug_channel.dutch) D.print("hour " # debug_show (val));
        time_diff / (NFTUtils.HOUR_LENGTH * val);
      };
      case (#day(val)) {
        debug if (debug_channel.dutch) D.print("day " # debug_show (val));
        time_diff / (NFTUtils.DAY_LENGTH * val);
      };
    };

    debug if (debug_channel.dutch) D.print("reduction_cycles is " # debug_show (reduction_cycles));

    let new_price : Nat = switch (dutch.decay_type) {
      case (#flat(val)) {
        debug if (debug_channel.dutch) D.print("flat price reduction " # debug_show (val));
        if (start_price > (val * reduction_cycles)) {
          (start_price - (val * reduction_cycles));
        } else {
          ///it should be the reserve price
          reserve;
        };
      };
      case (#percent(val)) {
        debug if (debug_channel.dutch) D.print("percent price reduction " # debug_show (val));
        var thisLoop = 0;
        let currentPrice : Float = Float.fromInt(start_price) * ((1 - val) ** Float.fromInt(reduction_cycles));
        Int.abs(Float.toInt(currentPrice));
      };
    };

    debug if (debug_channel.dutch) D.print("new price " # debug_show (new_price));

    //make sure price is not less than minimum valid price
    let final_price = if (new_price < reserve) {
      debug if (debug_channel.dutch) D.print("below reserve " # debug_show (reserve));
      reserve;
    } else {
      new_price;
    };

    {
      auction with
      var current_bid_amount = auction.current_bid_amount;
      var current_config : MigrationTypes.Current.BidConfig = null;
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
              };
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
  /**
  * refresh_offers_nft_origyn
  * @param {StateAccess} state - StateAccess object for accessing the canister's state.
  * @param {?Types.Account} request - Optional account information for the request.
  * @param {Principal} caller - Principal object representing the caller.
  * @returns {Types.ManageSaleResult} - A result indicating whether the offers were refreshed.
  */
  public func refresh_offers_nft_origyn(state : StateAccess, request : ?Types.Account, caller : Principal) : Types.ManageSaleResult {

    let seller = switch (request) {
      case (null) {
        #principal(caller);
      };
      case (?val) {
        if (Types.account_eq(#principal(caller), val)) { val } else {
          if (NFTUtils.is_owner_manager_network(state, caller) == false) {
            return #err(Types.errors(#unauthorized_access, "refresh_offerns_nft_origyn - not an owner", ?caller));
          };
          val;
        };
      };
    };

    let offers = Map.get<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, account_handler, seller);
    let offer_results = Buffer.Buffer<Types.EscrowRecord>(1);

    debug if (debug_channel.offers) D.print("trying refresh");

    switch (offers) {
      case (null) {};
      case (?found_offer) {

        for (this_buyer in Map.entries<Types.Account, Int>(found_offer)) {
          var b_keep = false;
          switch (Map.get<Types.Account, MigrationTypes.Current.EscrowSellerTrie>(state.state.escrow_balances, account_handler, this_buyer.0)) {
            case (null) {};
            case (?found_buyer) {
              switch (Map.get<Types.Account, MigrationTypes.Current.EscrowTokenIDTrie>(found_buyer, account_handler, seller)) {
                case (null) {};
                case (?found_seller) {
                  for (this_token in Map.entries(found_seller)) {
                    for (this_ledger in Map.entries(this_token.1)) {
                      //nyi: maybe check for a 0 balance
                      debug if (debug_channel.offers) D.print("found bkeep" # debug_show (this_ledger));
                      b_keep := true;
                      offer_results.add(this_ledger.1);
                    };
                  };
                };
              };
            };
          };
          if (b_keep == false) {
            let clean = Map.delete<Types.Account, Int>(found_offer, account_handler, this_buyer.0);
            Map.set<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, account_handler, seller, found_offer);
          };
        };
      };
    };

    if (offer_results.size() == 0) {
      Map.delete<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, account_handler, seller);
    };

    return #ok(#refresh_offers(Buffer.toArray(offer_results)));
  };

  //moves tokens from a deposit into an escrow
  /**
  * escrow_nft_origyn
  * @param {StateAccess} state - StateAccess object for accessing the canister's state.
  * @param {Types.EscrowRequest} request - EscrowRequest object containing the details of the deposit and escrow.
  * @param {Principal} caller - Principal object representing the caller.
  * @returns {Star.Star<Types.ManageSaleResponse, Types.OrigynError>} - A result indicating whether the escrow was created.
  */
  public func escrow_nft_origyn(state : StateAccess, request : Types.EscrowRequest, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {
    //can someone escrow for someone else? No. Only a buyer can create an escrow for themselves for now
    //we will also allow a canister/canister owner to create escrows for itself
    if (
      Types.account_eq(#principal(caller), request.deposit.buyer) == false and
      Types.account_eq(#principal(caller), #principal(state.canister())) == false and
      Types.account_eq(#principal(caller), #principal(state.state.collection_data.owner)) == false and
      Array.filter<Principal>(state.state.collection_data.managers, func(item : Principal) { item == caller }).size() == 0
    ) {
      return #err(#trappable(Types.errors(#unauthorized_access, "escrow_nft_origyn - escrow - buyer and caller do not match", ?caller)));
    };

    debug if (debug_channel.escrow) D.print("in escrow");
    debug if (debug_channel.escrow) D.print(debug_show (request));
    switch (request.lock_to_date) {
      case (?val) {
        if (val > state.get_time() * 10) {
          // if an extra digit is fat fingered this will trip....gives 474 years in the future as the max
          return #err(#trappable(Types.errors(#improper_interface, "escrow_nft_origyn time lock should not be that far in the future", ?caller)));
        };
      };
      case (null) {};
    };

    debug if (debug_channel.escrow) D.print(debug_show (state.canister()));

    //verify the token
    if (request.token_id != "") {
      let metadata = switch (Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
        case (#err(err)) {
          return #err(#trappable(Types.errors(#token_not_found, "escrow_nft_origyn " # err.flag_point, ?caller)));
        };
        case (#ok(val)) { val };
      };

      let this_is_minted = Metadata.is_minted(metadata);
      if (this_is_minted == false) {
        //cant escrow for an unminted item
        return #err(#trappable(Types.errors(#token_not_found, "escrow_nft_origyn ", ?caller)));
      };

      let owner = switch (Metadata.get_nft_owner(metadata)) {
        case (#err(err)) return #err(#trappable(Types.errors(err.error, "escrow_nft_origyn " # err.flag_point, ?caller)));
        case (#ok(val)) val;
      };

      //cant escrow for an owner that doesn't own the token
      debug if (debug_channel.escrow) D.print(debug_show ("owner " # debug_show (owner) # " request.deposit.seller = " # debug_show (request.deposit.seller)));
      debug if (debug_channel.escrow) D.print(debug_show ("owner account_to_owner_subaccount " # debug_show (MigrationTypes.Current.account_to_owner_subaccount(owner)) # " MigrationTypes.Current.account_to_owner_subaccount(request.deposit.seller)  = " # debug_show (MigrationTypes.Current.account_to_owner_subaccount(request.deposit.seller))));
      if (MigrationTypes.Current.compare_account(owner, request.deposit.seller) == false) return #err(#trappable(Types.errors(#escrow_owner_not_the_owner, "escrow_nft_origyn cannot create escrow for item someone does not own", ?caller)));
    };

    //move the deposit to an escrow account
    debug if (debug_channel.escrow) D.print("verifying the deposit");

    let (trx_id : Types.TransactionID, account_hash : ?Blob) = switch (request.deposit.token) {
      case (#ic(token)) {
        switch (token.standard) {
          case (#Ledger or #ICRC1) {
            debug if (debug_channel.escrow) D.print("found ledger");
            let checker = Ledger_Interface.Ledger_Interface();
            switch (await* checker.transfer_deposit(state.canister(), request, caller)) {
              case (#ok(val)) (val.transaction_id, ?val.subaccount_info.account.sub_account);
              case (#err(err)) return #err(#awaited(Types.errors(err.error, "escrow_nft_origyn " # err.flag_point, ?caller)));
            };
          };
          case (_) return #err(#awaited(Types.errors(#nyi, "escrow_nft_origyn - ic type nyi - " # debug_show (request), ?caller)));
        };
      };
      case (#extensible(val)) return #err(#trappable(Types.errors(#nyi, "escrow_nft_origyn - extensible token nyi - " # debug_show (request), ?caller)));
    };

    //put the escrow
    debug if (debug_channel.escrow) D.print("putting the escrow");
    let escrow_result = PutBalance.put_escrow_balance(
      state,
      {
        request.deposit with
        token_id = request.token_id;
        trx_id = trx_id;
        lock_to_date = request.lock_to_date;
        account_hash = account_hash;
        balances = null;
      },
      true,
    );

    debug if (debug_channel.escrow) D.print(debug_show (escrow_result));

    //add deposit transaction
    let new_trx = switch (
      Metadata.add_transaction_record<system>(
        state,
        {
          token_id = request.token_id;
          index = 0;
          txn_type = #escrow_deposit {
            request.deposit with
            token_id = request.token_id;
            trx_id = trx_id;
            extensible = #Option(null);
          };
          timestamp = state.get_time();
        },
        caller,
      )
    ) {
      case (#err(err)) {
        debug if (debug_channel.escrow) D.print("in a bad error");
        debug if (debug_channel.escrow) D.print(debug_show (err));
        //nyi: this is really bad and will mess up certificatioin later so we should really throw
        return #err(#awaited(Types.errors(#nyi, "escrow_nft_origyn - extensible token nyi - " # debug_show (request), ?caller)));
      };
      case (#ok(new_trx)) new_trx;
    };

    debug if (debug_channel.escrow) D.print("have the trx");
    debug if (debug_channel.escrow) D.print(debug_show (new_trx));
    return #awaited(#escrow_deposit({ receipt = { request.deposit with
    token_id = request.token_id }; balance = escrow_result.amount; transaction = new_trx }));
  };

  // NOTE: Transfers the OGY tokens using icrc2_transfer_from method
  /**
  * deposit_fee_nft_origyn
  * @param {StateAccess} state - StateAccess object for accessing the canister's state.
  * @param {Types.FeeDepositRequest} request - FeeDepositRequest object containing the details of the fee deposit.
  * @param {Principal} caller - Principal object representing the caller.
  * @returns {Star.Star<Types.ManageSaleResponse, Types.OrigynError>} - A result indicating whether the fee deposit was created.
  */
  // token_id : Text,
  public func deposit_fee_nft_origyn(state : StateAccess, request : Types.FeeDepositRequest, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {
    // Ensure the caller is authorized (account owner, canister, manager, collection owner)
    if (
      Types.account_eq(#principal(caller), request.account) == false and
      Types.account_eq(#principal(caller), #principal(state.canister())) == false and
      Types.account_eq(#principal(caller), #principal(state.state.collection_data.owner)) == false and
      Array.filter<Principal>(state.state.collection_data.managers, func(item : Principal) { item == caller }).size() == 0
    ) {
      return #err(#trappable(Types.errors(#unauthorized_access, "deposit_fee_nft_origyn - escrow - account and caller do not match", ?caller)));
    };

    debug if (debug_channel.escrow) D.print("in deposit_fee");

    debug if (debug_channel.escrow) D.print(debug_show (request));

    debug if (debug_channel.escrow) D.print(debug_show (state.canister()));

    debug if (debug_channel.escrow) D.print("verifying the deposit");

    // Get the fee deposit account
    let feeDepositAccount = switch (request.token) {
      case (#ic(token)) {
        switch (token.standard) {
          case (#Ledger or #ICRC1) {
            debug if (debug_channel.escrow) D.print("found ledger");
            NFTUtils.get_fee_deposit_account_info(request.account, state.canister());
          };
          case (_) return #err(#awaited(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - ic type nyi - " # debug_show (request), ?caller)));
        };
      };
      case (#extensible(val)) return #err(#trappable(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - extensible token nyi - " # debug_show (request), ?caller)));
    };

    // // Retrieve metadata
    // let metadata = switch (Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
    //   case (#ok(val)) val;
    //   case (#err(err)) D.trap("Cannot find metadata for collection " # debug_show (err));
    // };

    // Retrieve metadata only if token_id is provided
    switch (request.token_id) {
      case (?id) {
        switch (Metadata.get_metadata_for_token(state, id, caller, ?state.canister(), state.state.collection_data.owner)) {
          case (#ok(metadata)) {
            // Check current balance
            let balance : Nat = switch (request.token) {
              case (#ic(token)) {
                switch (token.standard) {
                  case (#Ledger or #ICRC1) {
                    debug if (debug_channel.escrow) D.print("found ledger");
                    let checker = Ledger_Interface.Ledger_Interface();
                    switch (await* checker.fee_deposit_balance(state.canister(), request, caller)) {
                      case (#trappable(val)) (val.balance);
                      case (#awaited(val)) (val.balance);
                      case (#err(#awaited(err))) return #err(#awaited(Types.errors(?state.canistergeekLogger, err.error, "deposit_fee_nft_origyn " # err.flag_point, ?caller)));
                      case (#err(#trappable(err))) return #err(#awaited(Types.errors(?state.canistergeekLogger, err.error, "deposit_fee_nft_origyn " # err.flag_point, ?caller)));
                    };
                  };
                  case (_) return #err(#awaited(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - ic type nyi - " # debug_show (request), ?caller)));
                };
              };
              case (#extensible(val)) return #err(#trappable(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - extensible token nyi - " # debug_show (request), ?caller)));
            };

            // Calculate the required fee deposit amount
            let _royalties_names : [Text] = Royalties.royalties_names;
            let fee_deposit_amount : Nat = Royalties.get_total_amount_fixed_royalties(_royalties_names, metadata);

            debug if (debug_channel.escrow) D.print("deposit_fee_nft_origyn : feeDepositAccount " # debug_show (feeDepositAccount));

            debug if (debug_channel.escrow) D.print("Balance is insufficient, performing transfer to top-up fee deposit account.");
            let ogy_ledger : ICRC2.Self = actor (MigrationTypes.Current.OGY_LEDGER_CANISTER_ID);
            let add_fund_to_fees_wallet = await ogy_ledger.icrc2_transfer_from({
              to = {
                owner = feeDepositAccount.account.principal;
                subaccount = ?feeDepositAccount.account.sub_account;
              };
              fee = ?200_000;
              spender_subaccount = null;
              from = {
                owner = caller;
                subaccount = null;
              };
              memo = null;
              created_at_time = null;
              amount = fee_deposit_amount;
            });

            let old_trx = switch (
              Metadata.add_transaction_record<system>(
                state,
                {
                  token_id = "";
                  index = 0;
                  txn_type = #fee_deposit {
                    request with
                    amount = balance;
                    extensible = #Option(null);
                  };
                  timestamp = state.get_time();
                },
                caller,
              )
            ) {
              case (#err(err)) {
                debug if (debug_channel.escrow) D.print("in a bad error");
                debug if (debug_channel.escrow) D.print(debug_show (err));
                //nyi: this is really bad and will mess up certificatioin later so we should really throw
                return #err(#awaited(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - extensible token nyi - " # debug_show (request), ?caller)));
              };
              case (#ok(old_trx)) old_trx;
            };

            return #awaited(#fee_deposit({ balance = balance; transaction = ?old_trx }));
          };
          case (#err(err)) D.trap("Cannot find metadata for collection " # debug_show (err));
        };
      };
      case null {
        // Token ID is not provided, skip metadata retrieval
        debug if (debug_channel.escrow) D.print("Token ID is null, skipping metadata retrieval.");

        let balance_doublecheck = switch (request.token) {
          case (#ic(token)) {
            switch (token.standard) {
              case (#Ledger or #ICRC1) {
                debug if (debug_channel.escrow) D.print("found ledger");
                let checker = Ledger_Interface.Ledger_Interface();
                switch (await* checker.fee_deposit_balance(state.canister(), request, caller)) {
                  case (#trappable(val)) (val.balance);
                  case (#awaited(val)) (val.balance);
                  case (#err(#awaited(err))) return #err(#awaited(Types.errors(?state.canistergeekLogger, err.error, "deposit_fee_nft_origyn " # err.flag_point, ?caller)));
                  case (#err(#trappable(err))) return #err(#awaited(Types.errors(?state.canistergeekLogger, err.error, "deposit_fee_nft_origyn " # err.flag_point, ?caller)));
                };
              };
              case (_) return #err(#awaited(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - ic type nyi - " # debug_show (request), ?caller)));
            };
          };
          case (#extensible(val)) return #err(#trappable(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - extensible token nyi - " # debug_show (request), ?caller)));
        };

        // put the fee into the state (there is a map here in which all such things are stored)
        debug if (debug_channel.escrow) D.print("putting the escrow");

        // Save in the state
        let deposit_result = PutBalance.put_fee_deposit_balance(state, request, balance_doublecheck);

        debug if (debug_channel.escrow) D.print(debug_show (deposit_result));

        // add fee deposit transaction
        let new_trx = switch (
          Metadata.add_transaction_record<system>(
            state,
            {
              token_id = "";
              index = 0;
              txn_type = #fee_deposit {
                request with
                amount = balance_doublecheck;
                extensible = #Option(null);
              };
              timestamp = state.get_time();
            },
            caller,
          )
        ) {
          case (#err(err)) {
            debug if (debug_channel.escrow) D.print("in a bad error");
            debug if (debug_channel.escrow) D.print(debug_show (err));
            //nyi: this is really bad and will mess up certificatioin later so we should really throw
            return #err(#awaited(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - extensible token nyi - " # debug_show (request), ?caller)));
          };
          case (#ok(new_trx)) new_trx;
        };

        return #awaited(#fee_deposit({ balance = balance_doublecheck; transaction = ?new_trx }));
      };
    };

  };

  /**
  * ask_subscribe_nft_origyn
  * @param {StateAccess} state - StateAccess object for accessing the canister's state.
  * @param {Types.AskSubscribeRequest} request - AskSubscribeRequest object containing the details of the ask subscribe.
  * @param {Principal} caller - Principal object representing the caller.
  * @returns {Star.Star<Types.ManageSaleResponse, Types.OrigynError>} - A result indicating whether the ask subscribe was created.
  */
  public func ask_subscribe_nft_origyn(state : StateAccess, request : Types.AskSubscribeRequest, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {
    return #trappable(#ask_subscribe(false));
  };

  //recognizes tokens already at an escrow address but not yet recognized as an escrow - saves one fee
  //if this fails and there is a balance, it will attempt to refund it(we can't recognize misfiled escrows or the user may get access to something unplaned)
  /**
  * recognize_escrow_nft_origyn
  * @param {StateAccess} state - StateAccess object for accessing the canister's state.
  * @param {Types.EscrowRequest} request - EscrowRequest object containing the details of the escrow.
  * @param {Principal} caller - Principal object representing the caller.
  * @returns {Star.Star<Types.ManageSaleResponse, Types.OrigynError>} - A result indicating whether the escrow was recognized.
  */
  public func recognize_escrow_nft_origyn(state : StateAccess, request : Types.EscrowRequest, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {

    //can someone escrow for someone else? No. Only a buyer can create an escrow for themselves for now
    //we will also allow a canister/canister owner to create escrows for itself
    if (
      MigrationTypes.Current.compare_account(#principal(caller), request.deposit.buyer) == false and
      Types.account_eq(#principal(caller), #principal(state.canister())) == false and
      Types.account_eq(#principal(caller), #principal(state.state.collection_data.owner)) == false and
      Array.filter<Principal>(state.state.collection_data.managers, func(item : Principal) { item == caller }).size() == 0
    ) {
      return #err(#trappable(Types.errors(#unauthorized_access, "recognize_escrow_nft_origyn - escrow - buyer and caller do not match", ?caller)));
    };

    debug if (debug_channel.escrow) D.print("in recognize");
    debug if (debug_channel.escrow) D.print(debug_show (request));
    switch (request.lock_to_date) {
      case (?val) {
        if (val > state.get_time() * 10) {
          // if an extra digit is fat fingered this will trip....gives 474 years in the future as the max
          return #err(#trappable(Types.errors(#improper_interface, "recognize_escrow_nft_origyn time lock should not be that far in the future", ?caller)));
        };
      };
      case (null) {};
    };

    debug if (debug_channel.escrow) D.print(debug_show (state.canister()));

    //verify the token
    if (request.token_id != "") {
      debug if (debug_channel.escrow) D.print(debug_show ("We have a recognize request for token " # debug_show (request.token_id)));

      let metadata = switch (Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {

        case (#err(err)) {
          debug if (debug_channel.escrow) D.print(debug_show ("No metadata " # debug_show (err)));

          return #err(#trappable(Types.errors(#token_not_found, "recognize_escrow_nft_origyn " # err.flag_point # " " # debug_show (request), ?caller)));
        };
        case (#ok(val)) { val };
      };
      let this_is_minted = Metadata.is_minted(metadata);
      if (this_is_minted == false) {
        //cant escrow for an unminted item
        debug if (debug_channel.escrow) D.print(debug_show ("Not Minted " # debug_show (this_is_minted)));

        return #err(#trappable(Types.errors(#token_not_found, "recognize_escrow_nft_origyn ", ?caller)));
      };

      let owner = switch (Metadata.get_nft_owner(metadata)) {
        case (#err(err)) return #err(#trappable(Types.errors(err.error, "recognize_escrow_nft_origyn " # err.flag_point, ?caller)));
        case (#ok(val)) val;
      };

      //cant escrow for an owner that doesn't own the token
      debug if (debug_channel.escrow) D.print(debug_show ("owner " # debug_show (owner) # " request.deposit.seller = " # debug_show (request.deposit.seller)));
      debug if (debug_channel.escrow) D.print(debug_show ("owner account_to_owner_subaccount " # debug_show (MigrationTypes.Current.account_to_owner_subaccount(owner)) # " MigrationTypes.Current.account_to_owner_subaccount(request.deposit.seller)  = " # debug_show (MigrationTypes.Current.account_to_owner_subaccount(request.deposit.seller))));
      if (MigrationTypes.Current.compare_account(owner, request.deposit.seller) == false) return #err(#trappable(Types.errors(#escrow_owner_not_the_owner, "recognize_escrow_nft_origyn cannot create escrow for item someone does not own", ?caller)));
    };

    let search = NFTUtils.find_escrow_asset_map(state, { request.deposit with token_id = request.token_id });

    //we delete the escrow if it exists to protect from any spending while we are updating
    let old_balance = switch (search.balance) {
      case (null) {
        //if it doesn't exist...this is fine.
        null;
      };
      case (?val) {

        if (val.amount >= request.deposit.amount) {
          //if an escrow already exists for more than the request we should noop
          return #trappable(#recognize_escrow({ receipt = val; balance = val.amount; transaction = null }));
        };

        debug if (debug_channel.market) D.print("should be deleting escrow" # debug_show ((val.token)));
        let ?asset_list = search.asset_list else return #err(#trappable(Types.errors(#unreachable, "retrieve escrow reached state that should be unreachable", ?caller)));
        Map.delete(asset_list, token_handler, val.token);
        ?val;
      };
    };

    //check the balance
    debug if (debug_channel.escrow) D.print("checking the balance");

    let (balance : Nat, account_hash : ?Blob) = switch (request.deposit.token) {
      case (#ic(token)) {
        switch (token.standard) {
          case (#Ledger or #ICRC1) {
            debug if (debug_channel.escrow) D.print("found ledger");
            let checker = Ledger_Interface.Ledger_Interface();
            switch (Star.toResult<{ balance : Nat; subaccount_info : Types.SubAccountInfo }, Types.OrigynError>(await* checker.escrow_balance(state.canister(), request, caller))) {
              case (#ok(val)) {
                debug if (debug_channel.escrow) D.print("found balance" # debug_show (val));
                (val.balance, ?val.subaccount_info.account.sub_account);
              };
              case (#err(err)) {
                //this has failed so put the old escrow back if it existed;
                switch (old_balance) {
                  case (null) {};
                  case (?val) {
                    let ?asset_list = search.asset_list else return #err(#awaited(Types.errors(#unreachable, "retrieve escrow reached state that should be unreachable", ?caller)));
                    ignore Map.put(asset_list, token_handler, val.token, val);
                  };
                };

                return #err(#awaited(Types.errors(err.error, "recognize_escrow_nft_origyn " # err.flag_point, ?caller)));
              };
            };
          };
          case (_) return #err(#trappable(Types.errors(#nyi, "recognize_escrow_nft_origyn - ic type nyi - " # debug_show (request), ?caller)));
        };
      };
      case (#extensible(val)) return #err(#trappable(Types.errors(#nyi, "recognize_escrow_nft_origyn - extensible token nyi - " # debug_show (request), ?caller)));
    };

    switch (old_balance) {
      case (?old_balance) {
        if (balance <= old_balance.amount and balance > 0) {
          //should result in a no-op as we already recognized a blanace with higher amount...put it back
          let ?asset_list = search.asset_list else return #err(#awaited(Types.errors(#unreachable, "retrieve escrow reached state that should be unreachable", ?caller)));
          ignore Map.put(asset_list, token_handler, old_balance.token, old_balance);
          return #err(#awaited(Types.errors(#noop, "recognize_escrow_nft_origyn the new balance is less than an existing escrow", ?caller)));
        };
      };

      case (_) {};
    };

    //put the escrow

    debug if (debug_channel.escrow) D.print("putting the escrow");
    let escrow_result = PutBalance.put_escrow_balance(
      state,
      {
        request.deposit with
        amount = balance;
        token_id = request.token_id;
        trx_id = 0;
        lock_to_date = request.lock_to_date;
        account_hash = account_hash;
        balances = null;
      },
      true,
    );

    debug if (debug_channel.escrow) D.print(debug_show (escrow_result));

    debug if (debug_channel.escrow) D.print("adding loaded from balance transaction" # debug_show (balance));
    //add deposit transaction
    let new_trx = switch (
      Metadata.add_transaction_record<system>(
        state,
        {
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
        },
        caller,
      )
    ) {
      case (#err(err)) {
        debug if (debug_channel.escrow) D.print("in a bad error");
        debug if (debug_channel.escrow) D.print(debug_show (err));
        //nyi: this is really bad and will mess up certificatioin later so we should really throw
        return #err(#awaited(Types.errors(#nyi, "recognize_escrow_nft_origyn - extensible token nyi - " # debug_show (request), ?caller)));
      };
      case (#ok(new_trx)) new_trx;
    };

    //todo: if the amount found was not large enough, should we try to refund?
    if (balance < request.deposit.amount) {
      debug if (debug_channel.escrow) D.print("balance was less than request");
      var verified = switch (
        Verify.verify_escrow_receipt(
          state,
          {
            seller = request.deposit.seller;
            buyer = request.deposit.buyer;
            amount = balance;
            token = request.deposit.token;
            token_id = request.token_id;
          },
          null,
          null,
        )
      ) {
        case (#err(err)) {

          debug if (debug_channel.escrow) D.print("verified failed" # debug_show (err));

          return #err(#awaited(Types.errors(err.error, "recognize_escrow_nft_origyn we should have found the escrow we just created, but it wasn't there" # err.flag_point, ?caller)));
        };
        case (#ok(res)) res;
      };

      debug if (debug_channel.escrow) D.print("have verified" # debug_show (verified));

      if (balance > 0) {
        debug if (debug_channel.escrow) D.print("attempthing refund because escrow is too small" # debug_show (verified));

        let refund_result = await* refund_failed_bid(
          state,
          verified,
          {
            seller = request.deposit.seller;
            buyer = request.deposit.buyer;
            amount = balance;
            token = request.deposit.token;
            token_id = request.token_id;
            sale_id = null;
            lock_to_date = null;
            account_hash = null;
          },
        );

        debug if (debug_channel.escrow) D.print("refund result" # debug_show (refund_result));

        return #err(#awaited(Types.errors(#escrow_not_large_enough, "escrow refunded because result was less than what was in the account" # debug_show (refund_result), ?caller)));
      };

      return #err(#awaited(Types.errors(#escrow_not_large_enough, "real balance (" #debug_show (balance) # ") was less than request deposit amount (" #debug_show (request.deposit.amount) # ")", ?caller)));
    };

    return #awaited(#recognize_escrow({ receipt = { request.deposit with
    token_id = request.token_id }; balance = balance; transaction = ?new_trx }));
  };

  //allows the user to withdraw tokens from an nft canister
  /**
    * Allows the user to withdraw tokens from an NFT canister.
    * @param {StateAccess} state - The StateAccess instance of the NFT canister.
    * @param {Types.WithdrawRequest} withdraw - The withdraw request details containing token information.
    * @param {Principal} caller - The Principal of the caller.
    * @returns {async* Types.ManageSaleResult} - A Result object containing either a ManageSaleResponse or an OrigynError.
    */
  public func withdraw_nft_origyn(state : StateAccess, withdraw : Types.WithdrawRequest, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {
    switch (withdraw) {
      case (#deposit(details)) {
        return await* Withdraw._withdraw_deposit(state, withdraw, details, caller);
      };
      case (#escrow(details)) {
        return await* Withdraw._withdraw_escrow(state, withdraw, details, caller);
      };
      case (#sale(details)) {
        return await* Withdraw._withdraw_sale(state, withdraw, details, caller);
      };
      case (#reject(details)) {
        return await* Withdraw._reject_offer(state, withdraw, details, caller);
      };
      case (#fee_deposit(details)) {
        return await* Withdraw._withdraw_fee_deposit(state, withdraw, details, caller);
      };
    };
    return #err(#trappable(Types.errors(#nyi, "withdraw_nft_origyn  - nyi - ", ?caller)));
  };

  /**
    * Refunds the failed bid by withdrawing the escrow amount and refunding the entire escrow to the buyer.
    *
    * @param {Types.State} state - The current state of the canister.
    * @param {MigrationTypes.Current.VerifiedReciept} verified - The verified receipt.
    * @param {MigrationTypes.Current.EscrowRecord} escrow - The escrow record.
    *
    * @returns {async* Bool} - A boolean value indicating whether the refund was successful or not.
    */
  private func refund_failed_bid(state : Types.State, verified : MigrationTypes.Current.VerifiedReciept, escrow : MigrationTypes.Current.EscrowRecord) : async* Bool {
    //we will close later after we try to refund a valid bid
    debug if (debug_channel.bid) D.print("refunding" # debug_show (verified.found_asset.escrow.amount));
    let service : Types.Service = actor ((Principal.toText(state.canister())));
    let refund_id = service.sale_nft_origyn(
      #withdraw(
        #escrow({
          escrow with
          amount = verified.found_asset.escrow.amount; //return back the whole escrow
          withdraw_to = escrow.buyer;
        })
      )
    );

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
  public func bid_nft_origyn(state : StateAccess, request : Types.BidRequest, caller : Principal, canister_call : Bool) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {

    debug if (debug_channel.bid) D.print("in bid " # debug_show ((request, canister_call)));
    D.print("ok here");

    let ?sale_id : ?Text = request.escrow_record.sale_id else return #err(#trappable(Types.errors(#sale_id_does_not_match, "bid_nft_origyn - sales id not provided. please set in escrow records", ?caller)));

    //look for an existing sale
    let ?current_sale = Map.get(state.state.nft_sales, Map.thash, sale_id) else {
      debug if (debug_channel.bid) D.print("could not find sale " # debug_show (sale_id));
      return #err(#trappable(Types.errors(#sale_id_does_not_match, "bid_nft_origyn - sales id did not match " # sale_id, ?caller)));
    };
    D.print("ok here 2");

    debug if (debug_channel.bid) D.print("found sale ");

    let current_sale_state = switch (NFTUtils.get_auction_state_from_status(current_sale)) {
      case (#ok(val)) val;
      case (#err(err)) return #err(#trappable(Types.errors(err.error, "bid_nft_origyn - find state " # err.flag_point, ?caller)));
    };

    var metadata = switch (Metadata.get_metadata_for_token(state, request.escrow_record.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) return #err(#trappable(Types.errors(#token_not_found, "bid_nft_origyn " # err.flag_point, ?caller)));
      case (#ok(val)) val;
    };

    let {
      buy_now_price;
      start_date;
      min_increase : MigrationTypes.Current.MinIncreaseType;
      dutch : Bool;
      bid_pays_fees : ?MigrationTypes.Current.BidPaysFeesParams;
      seller_fee_schema : ?Text;
      seller_fee_accounts;
    } = switch (current_sale_state.config) {
      case (#auction(config)) {
        {
          buy_now_price = config.buy_now;
          start_date = config.start_date;
          min_increase = config.min_increase;
          dutch = false;
          bid_pays_fees = null;
          seller_fee_schema = null;
          seller_fee_accounts = null;
        };
      };
      case (#ask(config)) {
        switch (config) {
          case (?config) {
            let buy_now : ?Nat = MigrationTypes.Current.load_buy_now_ask_feature(?config);
            let dutch : ?MigrationTypes.Current.DutchParams = MigrationTypes.Current.load_dutch_ask_feature(?config);
            let start_date : ?Int = MigrationTypes.Current.load_start_date_ask_feature(?config);
            let seller_fee_schema : ?Text = MigrationTypes.Current.load_fee_schema_ask_feature(?config);
            let seller_fee_accounts : ?MigrationTypes.Current.FeeAccountsParams = MigrationTypes.Current.load_fee_accounts_ask_feature(?config);
            // TODO GWOJDA
            // let bid_pays_fees : ?MigrationTypes.Current.FeeAccountsParams = MigrationTypes.Current.load_fee_accounts_ask_feature(?config);

            let min_increase : MigrationTypes.Current.MinIncreaseType = switch (Map.get<MigrationTypes.Current.AskFeatureKey, MigrationTypes.Current.AskFeature>(config, MigrationTypes.Current.ask_feature_set_tool, #min_increase)) {
              case (?#min_increase(val)) { val };
              case (_) { #percentage(0.05) };
            };

            let buy_now_price = switch (buy_now, dutch) {
              case (?buy_now, null) {
                ?buy_now;
              };
              case (null, ?dutch) {
                let current_state = calc_dutch_price(state, current_sale_state, metadata);
                ?current_state.min_next_bid;
              };
              case (_, _) {
                null;
              };
            };

            {
              buy_now_price = buy_now_price;
              start_date = start_date;
              min_increase = min_increase;
              bid_pays_fees = null; // TODO
              seller_fee_schema = seller_fee_schema;
              seller_fee_accounts = seller_fee_accounts;
              dutch = switch (dutch) {
                case (null) false;
                case (?val) true;
              };
            };
          };
          case (null) {
            {
              buy_now_price = null;
              start_date = null;
              min_increase = #percentage(0.05);
              dutch = false;
              bid_pays_fees = null;
              seller_fee_schema = null;
              seller_fee_accounts = null;
            };
          };
        };
      };
      case (_) return #err(#trappable(Types.errors(#sale_not_found, "bid_nft_origyn - not an auction type ", ?caller)));
    };

    // load new bid config :
    let {
      broker : ?Types.Account;
      _fee_schema : ?Text;
      fee_accounts : ?MigrationTypes.Current.FeeAccountsParams;
      config_map : MigrationTypes.Current.BidConfig;
    } = switch (request.config) {
      case (?config) {
        let config_map = MigrationTypes.Current.bidfeatures_to_map(config);

        {
          broker = MigrationTypes.Current.load_broker_bid_feature(?config_map);
          _fee_schema = MigrationTypes.Current.load_fee_schema_bid_feature(?config_map);
          fee_accounts = MigrationTypes.Current.load_fee_accounts_bid_feature(?config_map);
          config_map = ?config_map;
        };
      };
      case (null) {
        {
          broker = null;
          _fee_schema = null;
          fee_accounts = null;
          config_map = null;
        };
      };
    };

    let fee_schema : Text = Option.get<Text>(_fee_schema, Option.get<Text>(seller_fee_schema, Types.metadata.__system_secondary_royalty));

    switch (bid_pays_fees) {
      case (?bid_pays) {
        switch (fee_accounts) {
          case (?fee_acc) {
            for (bid_p in bid_pays.vals()) {
              if (Array.find<MigrationTypes.Current.FeeName>(fee_acc, func x = x == bid_p) == null) {
                return #err(#trappable(Types.errors(#no_fee_accounts_provided, "bid_nft_origyn - bidder as to pay fee : " # debug_show (bid_pays_fees) # " please provide fee_accounts as config parameter.", ?caller)));
              };
            };
          };
          case (null) {
            if (fee_accounts == null) {
              return #err(#trappable(Types.errors(#no_fee_accounts_provided, "bid_nft_origyn - bidder as to pay fee : " # debug_show (bid_pays_fees) # " please provide fee_accounts as config parameter.", ?caller)));
            };
          };
        };
      };
      case (null) {};
    };

    switch (current_sale_state.status) {
      case (#open) {
        if (state.get_time() >= current_sale_state.end_date) return #err(#trappable(Types.errors(#auction_ended, "bid_nft_origyn - sale is past close date " # sale_id, ?caller)));
      };
      case (#not_started) {
        if (state.get_time() >= current_sale_state.start_date and state.get_time() < current_sale_state.end_date) {
          current_sale_state.status := #open;
        };
      };
      case (_) return #err(#trappable(Types.errors(#auction_ended, "bid_nft_origyn - sale is not open " # sale_id, ?caller)));
    };

    switch (current_sale_state.allow_list) {
      case (null) {
        debug if (debug_channel.bid) D.print("allow list is null");
      };
      case (?val) {
        debug if (debug_channel.bid) D.print("allow list inst null");
        switch (Map.get<Principal, Bool>(val, Map.phash, caller)) {
          case (null) {
            return #err(#trappable(Types.errors(#unauthorized_access, "bid_nft_origyn - not on allow list ", ?caller)));
          };
          case (?val) {};
        };
      };
    };

    let owner = switch (Metadata.get_nft_owner(metadata)) {
      case (#err(err)) return #err(#trappable(Types.errors(err.error, "bid_nft_origyn " # err.flag_point, ?caller)));
      case (#ok(val)) val;
    };

    debug if (debug_channel.bid) D.print(" owner is " # debug_show (owner));

    //make sure token ids match
    if (current_sale.token_id != request.escrow_record.token_id) return #err(#trappable(Types.errors(#token_id_mismatch, "bid_nft_origyn - token id of sale does not match escrow receipt " # request.escrow_record.token_id, ?caller)));

    //make sure assets match
    debug if (debug_channel.bid) D.print("checking asset sale type " # debug_show ((_get_token_from_sales_status(current_sale), request.escrow_record.token)));
    if (Types.token_eq(_get_token_from_sales_status(current_sale), request.escrow_record.token) == false) return #err(#trappable(Types.errors(#asset_mismatch, "bid_nft_origyn - asset in sale and escrow receipt do not match " # debug_show (request.escrow_record.token) # debug_show (_get_token_from_sales_status(current_sale)), ?caller)));

    //make sure owners match
    if (Types.account_eq(owner, request.escrow_record.seller) == false) return #err(#trappable(Types.errors(#receipt_data_mismatch, "bid_nft_origyn - owner and seller do not match " # debug_show (request.escrow_record.token) # debug_show (_get_token_from_sales_status(current_sale)), ?caller)));

    //make sure buyers match
    if (Types.account_eq(#principal(caller), request.escrow_record.buyer) == false) return #err(#trappable(Types.errors(#receipt_data_mismatch, "bid_nft_origyn - caller and buyer do not match " # debug_show (request.escrow_record.token) # debug_show (_get_token_from_sales_status(current_sale)), ?caller)));

    debug if (debug_channel.bid) D.print(" about to verify escrow " # debug_show (request.escrow_record));

    //make sure the receipt is valid
    debug if (debug_channel.bid) D.print("verifying Escrow");
    var verified = switch (Verify.verify_escrow_receipt(state, request.escrow_record, null, ?sale_id)) {
      case (#err(err)) {
        //we could not verify the escrow, so we're going to try to claim it here as if escrow_nft_origyn was called first.
        //this adds an additional await to each item not already claimed, so it could get expensive in batch scenarios.
        if (canister_call == false) {

          //not a canister call... trying to recognize escrow

          debug if (debug_channel.bid) D.print("Not a canister call, trying escrow");
          // NFTUtils.logDirectly("bid_nft_origyn Not a canister call, trying recognize escrow " #debug_show ((request.escrow_record, sale_id)), #Option(null), null);
          switch (
            Star.toResult(
              await* recognize_escrow_nft_origyn(
                state,
                {
                  deposit = {
                    request.escrow_record with
                    sale_id = ?sale_id;
                    trx_id = null;
                  };
                  lock_to_date = null;
                  token_id = request.escrow_record.token_id;
                },
                caller,
              )
            )
          ) {
            case (#ok(val)) {
              // NFTUtils.logDirectly("bid_nft_origyn recognize escrow succeeded " #debug_show ((request.escrow_record, sale_id)), #Option(null), null);

              debug if (debug_channel.bid) D.print("recognizing escrow was successful, recaling bid");
              return await* bid_nft_origyn(state, request, caller, true);
            };
            case (#err(err)) {
              // NFTUtils.logDirectly("bid_nft_origyn recognize escrow failed " #debug_show ((request.escrow_record, sale_id, err.flag_point)), #Option(null), null);
              if (debug_channel.bid) D.print("recognition of escrow failed, attempting recognition of deposit");
            };
          };

          // NFTUtils.logDirectly("bid_nft_origyn attempting escrow from deposit " #debug_show ((request.escrow_record, sale_id)), #Option(null), null);

          switch (
            await* escrow_nft_origyn(
              state,
              {
                deposit = {
                  request.escrow_record with
                  sale_id = ?sale_id;
                  trx_id = null;
                };
                lock_to_date = null;
                token_id = request.escrow_record.token_id;
              },
              caller,
            )
          ) {
            //we can't just continue here because the owner may have changed out from underneath us...safer to sart from the begining
            case (#trappable(newEscrow)) return await* bid_nft_origyn(state, request, caller, true);
            case (#awaited(newEscrow)) return await* bid_nft_origyn(state, request, caller, true);
            case (#err(#trappable(err))) return #err(#awaited(Types.errors(err.error, "bid_nft_origyn auto try escrow failed " # err.flag_point, ?caller)));
            case (#err(#awaited(err))) return #err(#awaited(Types.errors(err.error, "bid_nft_origyn auto try escrow failed " # err.flag_point, ?caller)));
          };
        } else return #err(#awaited(Types.errors(err.error, "bid_nft_origyn auto try escrow failed after canister call " # err.flag_point, ?caller)));
      };
      case (#ok(res)) res;
    };

    //we can continue with trappable because the awaits above are returned.
    debug if (debug_channel.bid) D.print("verified the escorw " # debug_show (verified.found_asset));

    if (verified.found_asset.escrow.amount < request.escrow_record.amount) return #err(#trappable(Types.errors(#withdraw_too_large, "bid_nft_origyn - escrow - amount more than in escrow verified: " # Nat.toText(verified.found_asset.escrow.amount) # " request: " # Nat.toText(request.escrow_record.amount), ?caller)));

    //make sure auction is still running
    let current_time = state.get_time();
    // MKT0028
    if (state.get_time() > current_sale_state.end_date) return #err(#trappable(Types.errors(#auction_ended, "bid_nft_origyn - auction ended current_date" # debug_show (current_time) # " " # " end_time:" # debug_show (current_sale_state.end_date), ?caller)));

    switch (current_sale_state.status) {
      case (#closed) {
        //we will close later after we try to refund a valid bid
        ignore refund_failed_bid(state, verified, request.escrow_record);
        //last_withdraw_result := ?refund_id;

        //debug if(debug_channel.bid) D.print(debug_show(refund_id));
        return #err(#trappable(Types.errors(#auction_ended, "end_sale_nft_origyn - auction already closed - attempting escrow return ", ?caller)));
      };
      case (_) {};
    };

    let required_bid = if (dutch) {
      switch (buy_now_price) {
        case (null) {
          current_sale_state.min_next_bid;
        };
        case (?val) {
          val;
        };
      };
    } else {
      current_sale_state.min_next_bid;
    };

    //make sure amount is high enough
    if (request.escrow_record.amount < required_bid) {
      //if the bid is too low we should refund their escrow
      debug if (debug_channel.bid) D.print("refunding not high enough bid " # debug_show (verified.found_asset.escrow.amount));
      let service : Types.Service = actor ((Principal.toText(state.canister())));
      let refund_id = service.sale_nft_origyn(
        #withdraw(
          #escrow({
            verified.found_asset.escrow with
            withdraw_to = verified.found_asset.escrow.buyer;
          })
        )
      );
      //last_withdraw_result := ?refund_id;

      //debug if(debug_channel.bid) D.print(debug_show(refund_id));

      return #err(#trappable(Types.errors(#bid_too_low, "bid_nft_origyn - bid too low - refund issued ", ?caller)));
    };

    let buy_now = switch (buy_now_price) {
      case (null) false;
      case (?val) {
        if (val <= request.escrow_record.amount) {
          true;
        } else {
          false;
        };
      };
    };

    verified := switch (Verify.verify_escrow_record(state, request.escrow_record, null)) {
      case (#err(err)) {
        //we could not verify the escrow, so we're going to try to claim it here as if escrow_nft_origyn was called first.
        //this adds an additional await to each item not already claimed, so it could get expensive in batch scenarios.

        return #err(#awaited(Types.errors(err.error, "bid_nft_origyn revalidate failed " # err.flag_point, ?caller)));
      };
      case (#ok(res)) res;
    };

    switch (fee_accounts) {
      case (?_fee_accounts) {
        let broker_set = if (broker == null) { false } else { true };
        switch (
          _lock_fee_accounts_according_to_fee_schema(
            state,
            metadata,
            current_sale_state.token,
            #account({ owner = caller; sub_account = null }),
            sale_id,
            broker_set,
            fee_schema,
            _fee_accounts,
          )
        ) {
          case (#ok()) {};
          case (#err(err)) {
            return #err(#awaited(Types.errors(err.error, "bid_nft_origyn _lock_fee_accounts_according_to_fee_schema error " # err.flag_point, ?caller)));
          };
        };

      };
      case (null) {};
    };

    debug if (debug_channel.bid) D.print("have buy now" # debug_show (buy_now, buy_now_price, current_sale_state.current_bid_amount));

    let new_trx = Metadata.add_transaction_record<system>(
      state,
      {
        token_id = request.escrow_record.token_id;
        index = 0;
        txn_type = #auction_bid({
          request.escrow_record with
          sale_id = sale_id;
          extensible = #Option(null);
        });
        timestamp = state.get_time();
      },
      caller,
    );

    debug if (debug_channel.bid) D.print("about to try refund");

    switch (new_trx) {
      case (#ok(val)) {
        //nyi: implement wait for quiet

        debug if (debug_channel.bid) D.print("in this" # debug_show (current_sale_state.current_escrow));

        //update the sale

        let newMinBid = switch (min_increase) {
          case (#percentage(apercentage)) Int.abs(Float.toInt(Float.fromInt(request.escrow_record.amount) * apercentage)) + request.escrow_record.amount;
          case (#amount(aamount)) request.escrow_record.amount + aamount;
        };

        debug if (debug_channel.bid) D.print("have a min bid" # debug_show (newMinBid));

        switch (current_sale_state.current_escrow) {
          case (null) {

            //update state
            debug if (debug_channel.bid) D.print("updating the state" # debug_show (request));
            current_sale_state.current_bid_amount := request.escrow_record.amount;
            if (dutch == false) {
              current_sale_state.min_next_bid := newMinBid;
            };
            current_sale_state.current_escrow := ?request.escrow_record;
            current_sale_state.current_config := config_map;
            ignore Map.put<Principal, Int>(current_sale_state.participants, phash, caller, state.get_time());
          };
          case (?val) {
            switch (
              _unlock_fee_accounts_according_to_fee_schema(
                state,
                metadata,
                {
                  token = current_sale_state.token;
                  sale_id = sale_id;
                  fee_accounts = MigrationTypes.Current.load_fee_accounts_bid_feature(current_sale_state.current_config);
                  fee_schema = ?fee_schema;
                  owner = #account({ owner = caller; sub_account = null });
                },
              )
            ) {
              case (#ok()) {};
              case (#err(e)) {
                debug if (debug_channel.bid) D.print("Error unlocking last bidder token. Cron job will free those token automaticly after sale ended. // feature WIP");
              };
            };

            current_sale_state.current_config := config_map;
            //update state
            debug if (debug_channel.bid) D.print("Before" # debug_show (val.amount) # debug_show (val));
            current_sale_state.current_bid_amount := request.escrow_record.amount;
            if (dutch == false) {
              current_sale_state.min_next_bid := newMinBid;
            };
            current_sale_state.current_escrow := ?request.escrow_record;
            ignore Map.put<Principal, Int>(current_sale_state.participants, phash, caller, state.get_time());
            debug if (debug_channel.bid) D.print("After" # debug_show (val.amount) # debug_show (val));
            //refund the escrow
            //nyi: this would be better triggered by an event
            //if this fails they can still manually withdraw the escrow.
            debug if (debug_channel.bid) D.print("Trying refund escrow " # debug_show (val.amount) # debug_show (val));
            let service : Types.Service = actor ((Principal.toText(state.canister())));
            let refund_id = service.sale_nft_origyn(
              #withdraw(
                #escrow({
                  val with
                  withdraw_to = val.buyer;
                })
              )
            );

            //last_withdraw_result := ?refund_id;
            debug if (debug_channel.bid) D.print("done");
            //debug if(debug_channel.bid) D.print(debug_show(refund_id));

          };
        };

        if (buy_now or dutch) {

          debug if (debug_channel.bid) D.print("handling buy now");

          let service : Types.Service = actor ((Principal.toText(state.canister())));

          let result = await service.sale_nft_origyn(#end_sale(request.escrow_record.token_id));

          switch (result) {
            case (#ok(val)) {
              switch (val) {
                case (#end_sale(val)) return #awaited(#bid(val));
                case (_) return #err(#awaited(Types.errors(#improper_interface, "bid_nft_origyn - buy it now call to end sale had odd response " # debug_show (result), ?caller)));
              };
            };
            case (#err(err)) return #err(#awaited(err));
          };

          //call ourseves to close the auction
        };
        return #awaited(#bid(val));
      };
      case (#err(err)) return #err(#awaited(Types.errors(err.error, "bid_nft_origyn - create transaction record " # err.flag_point, ?caller)));
    };
  };

  //pulls the token out of a sale
  /**
    * Retrieves the token specification from a given sale status.
    * @private
    * @param {Types.SaleStatus} status - The sale status to retrieve the token specification from.
    * @returns {Types.TokenSpec} - The token specification retrieved from the given sale status.
    */
  private func _get_token_from_sales_status(status : Types.SaleStatus) : Types.TokenSpec {
    switch (status.sale_type) {
      case (#auction(auction_status)) {
        return auction_status.token;
      };
      case (_) {
        debug if (debug_channel.bid) D.print("getTokenfromSalesstatus not configured for type");
        assert (false);
        return #extensible(#Option(null));
      };
    };
  };

  /**
  * _lock_fee_accounts_according_to_fee_schema
  * @param {StateAccess} state - The state access object.
  * @param {CandyTypes.CandyShared} metadata - The metadata for the sale.
  * @param {MigrationTypes.Current.TokenSpec} token - The token specification for the sale.
  * @param {MigrationTypes.Current.Account} account - The account for which the fee accounts are being locked.
  * @param {Text} sale_id - The ID of the sale.
  * @param {Bool} broker_set - Whether the broker set is being used.
  * @param {Text} fee_schema - The fee schema for the sale.
  * @param {MigrationTypes.Current.FeeAccountsParams} fee_accounts - The fee accounts to be locked.
  * @returns {Result.Result<(), Types.OrigynError>} - A result indicating whether the fee accounts were locked or not.
  */
  private func _lock_fee_accounts_according_to_fee_schema(
    state : StateAccess,
    metadata : CandyTypes.CandyShared,
    token : MigrationTypes.Current.TokenSpec,
    account : MigrationTypes.Current.Account,
    sale_id : Text,
    broker_set : Bool,
    fee_schema : Text,
    fee_accounts : MigrationTypes.Current.FeeAccountsParams,
  ) : Result.Result<(), Types.OrigynError> {

    let royalties : [CandyTypes.CandyShared] = switch (Properties.getClassPropertyShared(metadata, Types.metadata.__system)) {
      case (null) { [] };
      case (?val) {
        Royalties.royalty_to_array(val.value, fee_schema);
      };
    };
    debug if (debug_channel.market) D.print("royalties = " # debug_show (royalties));

    for (royalty in royalties.vals()) {
      let loaded_royalty = switch (Royalties._load_royalty(fee_schema, royalty)) {
        case (#ok(val)) {
          switch (val) {
            case (#fixed(v)) { v };
            // case (#dynamic(v)) {v;}; TODO not available now
            case (_) {
              debug if (debug_channel.market) D.print("_lock_fee_accounts_according_to_fee_schema but __system_fixed_royalty is not set -> error");
              return #err(Types.errors(#malformed_metadata, "market_transfer_nft_origyn fee_accounts need fixed fee_schema. Not compatible yet others royalties schema.", null));
            };
          };
        };
        case (#err(err)) { return #err(err) };
      };

      let (token_spec, specific_token_set) = switch (loaded_royalty.token) {
        case (?val) {
          if (val == token) {
            D.print("token is equal");
            (val, false);
          } else {
            D.print("token NOT is equal");
            (val, true);
          };
        };
        case (_) {
          D.print("token is null");
          (token, false);
        };
      };

      let tmp_locked_fees = Buffer.Buffer<(MigrationTypes.Current.TokenSpec, Nat)>(5);
      var found = false;
      let royalties_names : [Text] = Royalties.royalties_names;
      // let account : MigrationTypes.Current.Account = #account({
      //   owner = caller;
      //   sub_account = null;
      // });

      // check if fund are provisioned by #fee_deposit
      for (royalties_name in fee_accounts.vals()) {
        switch (Array.find<Text>(royalties_names, func(val) { return val == royalties_name })) {
          case (?val) {};
          case (null) {
            debug if (debug_channel.market) D.print("bad royalty name = " # debug_show (royalties_name) # " and should be one of " # debug_show (royalties_names));
            return #err(Types.errors(#improper_interface, "market_transfer_nft_origyn bad royalty name = " # debug_show (royalties_name) # " and should be one of " # debug_show (royalties_names), null));
          };
        };
        debug if (debug_channel.market) D.print("loaded_royalty.tag = " # debug_show (loaded_royalty.tag) # " royalties_name = " # debug_show (royalties_name) # " broker_set " # debug_show (broker_set));
        if ((broker_set == true or (broker_set == false and loaded_royalty.tag != "com.origyn.royalty.broker"))) {
          if (royalties_name == loaded_royalty.tag) {
            let fees : Nat = Int.abs(Float.toInt(Float.ceil(loaded_royalty.fixedXDR)));

            debug if (debug_channel.market) D.print("royalties_name = " # debug_show (royalties_name) # " fees " # debug_show (fees));
            debug if (debug_channel.market) D.print("token_spec = " # debug_show (token_spec));
            switch (
              FeeAccount.lock_token_fee_balance(
                state,
                {
                  account = account;
                  token = token_spec;
                  token_to_lock = fees;
                  sale_id = sale_id;
                },
              )
            ) {
              case (#ok(val)) {
                tmp_locked_fees.add((token_spec, fees));
              };
              case (#err(err)) {
                for ((_token_spec, fees) in tmp_locked_fees.vals()) {
                  let _ = FeeAccount.unlock_token_fee_balance(
                    state,
                    {
                      account = account;
                      token = _token_spec;
                      sale_id = sale_id;
                      update_balance = false;
                    },
                  );
                };
                return #err(Types.errors(#low_fee_balance, "market_transfer_nft_origyn low_fee_balance " # debug_show (err) # " fee_schema : " # debug_show (fee_schema) # " loaded_royalty = " # debug_show (loaded_royalty) # " specific_token_set = " # debug_show (specific_token_set), null));
              };
            };
            found := true;
          };
        };
      };

      if ((broker_set == true or (broker_set == false and loaded_royalty.tag != "com.origyn.royalty.broker"))) {
        if (specific_token_set == true and found == false) {
          for ((_token_spec, fees) in tmp_locked_fees.vals()) {
            let _ = FeeAccount.unlock_token_fee_balance(
              state,
              {
                account = account;
                token = _token_spec;
                sale_id = sale_id;
                update_balance = false;
              },
            );
          };

          debug if (debug_channel.market) D.print("Specific token set for this royalty : " # debug_show (loaded_royalty.tag) # " but no fee_account setted to pay this royalty.");
          return #err(Types.errors(#improper_interface, "market_transfer_nft_origyn specific token set for this royalty : " # debug_show (loaded_royalty.tag) # " but no fee_account setted to pay this royalty.", null));
        };
      };
    };

    return #ok(());
  };

  /**
  * _unlock_fee_accounts_according_to_fee_schema
  * @param {StateAccess} state - The state access object.
  * @param {CandyTypes.CandyShared} metadata - The metadata for the sale.
  * @param {MigrationTypes.Current.TokenSpec} token - The token specification for the sale.
  * @param {Text} sale_id - The ID of the sale.
  * @param {MigrationTypes.Current.FeeAccountsParams} fee_accounts - The fee accounts to be unlocked.
  * @param {Text} fee_schema - The fee schema for the sale.
  * @param {MigrationTypes.Current.Account} owner - The account for which the fee accounts are being unlocked.
  * @returns {Result.Result<(), Types.OrigynError>} - A result indicating whether the fee accounts were unlocked or not.
  */
  private func _unlock_fee_accounts_according_to_fee_schema(
    state : StateAccess,
    metadata : CandyTypes.CandyShared,
    request : {
      token : Types.TokenSpec;
      sale_id : Text;
      fee_accounts : ?MigrationTypes.Current.FeeAccountsParams;
      fee_schema : ?Text;
      owner : MigrationTypes.Current.Account;
    },
  ) : Result.Result<(), Types.OrigynError> {
    debug if (debug_channel.market) D.print("checking fee_accounts parameters");
    switch (request.fee_accounts) {
      case (?fee_accounts) {
        debug if (debug_channel.market) D.print("fee_accounts is set, unlock token");
        let fee_schema : Text = Option.get<Text>(request.fee_schema, "");

        let royalties : [CandyTypes.CandyShared] = switch (Properties.getClassPropertyShared(metadata, Types.metadata.__system)) {
          case (null) { [] };
          case (?val) {
            Royalties.royalty_to_array(val.value, fee_schema);
          };
        };
        debug if (debug_channel.market) D.print("royalties = " # debug_show (royalties));

        for (royalty in royalties.vals()) {
          let loaded_royalty = switch (Royalties._load_royalty(fee_schema, royalty)) {
            case (#ok(val)) {
              switch (val) {
                case (#fixed(v)) { v };
                // case (#dynamic(v)) {v;}; TODO not available now
              };
            };
            case (#err(err)) { return #err(err) };
          };

          let token_spec = switch (loaded_royalty.token) {
            case (?val) { if (val == request.token) { val } else { val } };
            case (_) { request.token };
          };

          let royalties_names : [Text] = Royalties.royalties_names;
          let account : MigrationTypes.Current.Account = request.owner;

          for (royalties_name in fee_accounts.vals()) {
            if (royalties_name == loaded_royalty.tag) {
              switch (
                FeeAccount.unlock_token_fee_balance(
                  state,
                  {
                    account = account;
                    token = token_spec;
                    sale_id = request.sale_id;
                    update_balance = false;
                  },
                )
              ) {
                case (#ok(val)) {
                  debug if (debug_channel.market) D.print("Successfully unlocked token");
                };
                case (#err(val)) {
                  // TODO Not critical so no error reported. In futur we will add a garbage collector for this case.
                  debug if (debug_channel.market) D.print("Failed to unlock token for sale_id : " # debug_show (request.sale_id));
                };
              };
            };
          };
        };
      };
      case (null) {};
    };

    return #ok();
  };

};
