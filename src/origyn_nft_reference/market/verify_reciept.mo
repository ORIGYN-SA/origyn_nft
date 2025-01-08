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

import Set "mo:map/Set";

import Star "mo:star/star";

import SHA256 "mo:crypto/SHA/SHA256";
import Metadata "../metadata";
import MigrationTypes "../migrations/types";
import NFTUtils "../utils";
import Types "../types";
import FeeAccount "./fee_account";

module {
  let debug_channel = {
    verify_escrow = false;
    verify_sale = false;
  };

  type StateAccess = Types.State;

  let account_handler = MigrationTypes.Current.account_handler;
  let token_handler = MigrationTypes.Current.token_handler;
  let Map = MigrationTypes.Current.Map;

  public func verify_escrow_record(
    state : StateAccess,
    escrow : Types.EscrowRecord,
    owner : ?Types.Account,
  ) : Result.Result<MigrationTypes.Current.VerifiedReciept, Types.OrigynError> {
    return verify_escrow_receipt(
      state,
      {
        amount = escrow.amount;
        buyer = escrow.buyer;
        seller = escrow.seller;
        token_id = escrow.token_id;
        token = escrow.token;
      },
      owner,
      escrow.sale_id,
    );
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
    state : StateAccess,
    escrow : Types.EscrowReceipt,
    owner : ?Types.Account,
    sale_id : ?Text,
  ) : Result.Result<MigrationTypes.Current.VerifiedReciept, Types.OrigynError> {

    //only the owner can sell it
    debug if (debug_channel.verify_escrow) D.print("found to list" # debug_show (owner) # debug_show (escrow.seller));

    switch (owner) {
      case (null) {};
      case (?owner) {
        if (Types.account_eq(owner, escrow.seller) == false) return #err(Types.errors(?state.canistergeekLogger, #unauthorized_access, "verify_escrow_receipt - escrow seller is not the owner  " # debug_show (owner) # " " # debug_show (escrow.seller), null));
      };
    };

    let search = NFTUtils.find_escrow_asset_map(state, escrow);

    let ?to_list = search.to_list else {
      debug if (debug_channel.verify_escrow) D.print("didnt find asset");
      return #err(Types.errors(?state.canistergeekLogger, #no_escrow_found, "verify_escrow_receipt - escrow buyer not found " # debug_show (escrow.buyer), null));
    };

    debug if (debug_channel.verify_escrow) D.print("to_list is " # debug_show (Map.size(to_list)));

    let ?token_list = search.token_list else {
      debug if (debug_channel.verify_escrow) D.print("no escrow seller");

      return #err(Types.errors(?state.canistergeekLogger, #no_escrow_found, "verify_escrow_receipt - escrow seller not found  " # debug_show (escrow.seller), null));
    };

    debug if (debug_channel.verify_escrow) D.print("looking for to list");
    let ?asset_list = search.asset_list else return #err(Types.errors(?state.canistergeekLogger, #no_escrow_found, "verify_escrow_receipt - escrow token_id not found  " # debug_show (escrow.token_id), null));

    let ?balance = search.balance else return #err(Types.errors(?state.canistergeekLogger, #no_escrow_found, "verify_escrow_receipt - escrow token spec not found ", null));

    let found_asset = ?{ token_spec = escrow.token; escrow = balance };

    debug if (debug_channel.verify_escrow) D.print("Found an asset, checking fee");
    debug if (debug_channel.verify_escrow) D.print(debug_show (found_asset));
    debug if (debug_channel.verify_escrow) D.print(debug_show (escrow.amount));

    //check sale id
    switch (sale_id, balance.sale_id) {
      case (null, null) {};
      case (?desired_sale_id, null) return #err(Types.errors(?state.canistergeekLogger, #sale_id_does_not_match, "verify_escrow_receipt - escrow sale_id does not match  " # debug_show (sale_id) # debug_show (balance.sale_id), null));
      case (null, ?on_file_saleID) {
        //null is passed in as a sale id if we want to do sale id verification elsewhere
        //return #err(Types.errors(?state.canistergeekLogger,  #sale_id_does_not_match, "verify_escrow_receipt - escrow sale_id does not match ", null));
      };
      case (?desired_sale_id, ?on_file_saleID) {
        if (desired_sale_id != on_file_saleID) {
          return #err(Types.errors(?state.canistergeekLogger, #sale_id_does_not_match, "verify_escrow_receipt - escrow sale_id does not match  " # debug_show (on_file_saleID) # debug_show (desired_sale_id), null));
        };
      };
    };

    if (balance.amount < escrow.amount) return #err(Types.errors(?state.canistergeekLogger, #withdraw_too_large, "verify_escrow_receipt - escrow not large enough  " # debug_show (balance.amount) # " " # debug_show (escrow.amount), null));

    switch (found_asset, ?asset_list) {
      case (?found_asset, ?asset_list) {
        return #ok({
          found_asset = found_asset;
          found_asset_list = asset_list;
        });
      };
      case (_) return #err(Types.errors(?state.canistergeekLogger, #nyi, "verify_escrow_receipt - should be unreachable ", null));
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
    state : StateAccess,
    escrow : Types.EscrowReceipt,
  ) : Result.Result<MigrationTypes.Current.VerifiedReciept, Types.OrigynError> {

    let ?to_list = Map.get<Types.Account, MigrationTypes.Current.SalesBuyerTrie>(state.state.sales_balances, account_handler, escrow.seller) else {
      debug if (debug_channel.verify_sale) D.print("sale seller not found");
      return #err(Types.errors(?state.canistergeekLogger, #no_escrow_found, "verify_sales_reciept - escrow seller not found ", null));
    };

    //only the owner can sell it

    let ?token_list = Map.get<MigrationTypes.Current.Account, MigrationTypes.Current.SalesTokenIDTrie>(to_list, account_handler, escrow.buyer) else {
      debug if (debug_channel.verify_sale) D.print("sale byer not found");
      return #err(Types.errors(?state.canistergeekLogger, #no_escrow_found, "verify_sales_reciept - escrow buyer not found ", null));
    };

    let ?asset_list = Map.get<Text, MigrationTypes.Current.SalesLedgerTrie>(token_list, Map.thash, escrow.token_id) else {
      debug if (debug_channel.verify_sale) D.print("sale token id not found");
      return #err(Types.errors(?state.canistergeekLogger, #no_escrow_found, "verify_sales_reciept - escrow token_id not found ", null));
    };

    let ?balance = Map.get<MigrationTypes.Current.TokenSpec, MigrationTypes.Current.EscrowRecord>(asset_list, token_handler, escrow.token) else {
      debug if (debug_channel.verify_sale) D.print("sale token not found");
      return #err(Types.errors(?state.canistergeekLogger, #no_escrow_found, "verify_sales_reciept - escrow token spec not found ", null));
    };

    let found_asset = ?{ token_spec = escrow.token; escrow = balance };
    debug if (debug_channel.verify_sale) D.print("issue with balances");
    debug if (debug_channel.verify_sale) D.print(debug_show (balance));
    debug if (debug_channel.verify_sale) D.print(debug_show (escrow));

    if (balance.amount < escrow.amount) return #err(Types.errors(?state.canistergeekLogger, #withdraw_too_large, "verify_sales_reciept - escrow not large enough", null));

    switch (found_asset, ?asset_list) {
      case (?found_asset, ?asset_list) {
        return #ok({
          found_asset = found_asset;
          found_asset_list = asset_list;
        });
      };
      case (_) return #err(Types.errors(?state.canistergeekLogger, #nyi, "verify_sales_reciept - should be unreachable ", null));
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
  public func handle_escrow_update_error(
    state : StateAccess,
    escrow : Types.EscrowReceipt,
    owner : ?Types.Account,
    found_asset : {
      token_spec : Types.TokenSpec;
      escrow : Types.EscrowRecord;
    },
    found_asset_list : MigrationTypes.Current.EscrowLedgerTrie,
  ) : () {

    switch (verify_escrow_receipt(state, escrow, owner, null)) {
      case (#ok(reverify)) {
        let target_escrow = {
          reverify.found_asset.escrow with
          amount = Nat.add(reverify.found_asset.escrow.amount, escrow.amount);
        };
        Map.set<MigrationTypes.Current.TokenSpec, MigrationTypes.Current.EscrowRecord>(reverify.found_asset_list, token_handler, found_asset.token_spec, target_escrow);
      };
      case (#err(err)) {
        let target_escrow = {
          found_asset.escrow with
          amount = escrow.amount;
        };
        Map.set<MigrationTypes.Current.TokenSpec, MigrationTypes.Current.EscrowRecord>(found_asset_list, token_handler, found_asset.token_spec, target_escrow);
      };
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
  public func handle_sale_update_error(
    state : StateAccess,
    escrow : Types.EscrowReceipt,
    owner : ?Types.Account,
    found_asset : {
      token_spec : Types.TokenSpec;
      escrow : Types.EscrowRecord;
    },
    found_asset_list : MigrationTypes.Current.EscrowLedgerTrie,
  ) : () {

    switch (verify_sales_reciept(state, escrow)) {
      case (#ok(reverify)) {
        let target_escrow = {
          reverify.found_asset.escrow with
          amount = Nat.add(reverify.found_asset.escrow.amount, escrow.amount);
        };
        Map.set<MigrationTypes.Current.TokenSpec, MigrationTypes.Current.EscrowRecord>(reverify.found_asset_list, token_handler, found_asset.token_spec, target_escrow);
      };
      case (#err(err)) {
        let target_escrow = {
          found_asset.escrow with
          amount = escrow.amount;
        };
        Map.set<MigrationTypes.Current.TokenSpec, MigrationTypes.Current.EscrowRecord>(found_asset_list, token_handler, found_asset.token_spec, target_escrow);
      };
    };
  };

};
