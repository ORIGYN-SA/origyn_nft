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

import Star "mo:star/star";

import SHA256 "mo:crypto/SHA/SHA256";
import Ledger_Interface "../ledger_interface";
import Metadata "../metadata";
import MigrationTypes "../migrations/types";
import Migrations "../migrations/types";
import NFTUtils "../utils";
import Types "../types";
import FeeAccount "./fee_account";
import Verify "./verify_reciept";

module {
  let debug_channel = {
    royalties = true;
  };

  type StateAccess = Types.State;

  let account_handler = MigrationTypes.Current.account_handler;
  let token_handler = MigrationTypes.Current.token_handler;
  let Map = MigrationTypes.Current.Map;

  /**
    * Processes a change in fee_deposit balance.
    *
    * @param {StateAccess} state - The state access object.
    * @param {Types.FeeDepositRequest} FeeDepositRequest - The request record to be processed.
    * @returns {Types.EscrowRecord} - The updated escrow record.
    */
  public func put_fee_deposit_balance(
    state : StateAccess,
    request : Types.FeeDepositRequest,
    balance : Nat,
  ) : Result.Result<Nat, Types.OrigynError> {
    //add the escrow

    if (balance > 0) {
      var a_from = switch (Map.get<Types.Account, Map.Map<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>>(state.state.fee_deposit_balances, account_handler, request.account)) {
        case (null) {
          let new_from = Map.new<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>();

          Map.set<Types.Account, Map.Map<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>>(state.state.fee_deposit_balances, account_handler, request.account, new_from);
          new_from;
        };
        case (?val) {
          val;
        };
      };

      var a_token = switch (Map.get<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>(a_from, token_handler, request.token)) {
        case (null) {
          let new_token = {
            total_balance = balance;
            locks = Map.new<Text, Nat>();
          };

          Map.set<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>(a_from, token_handler, request.token, new_token);
          new_token;
        };
        case (?val) {
          val;
        };
      };

      // Make sure balance hasn't gone below locks
      var total_locked = 0;
      for (lock_value in Map.vals(a_token.locks)) {
        total_locked += lock_value;
      };

      if (balance < total_locked) {
        return #err(Types.errors(#low_fee_balance, "put_fee_deposit_balance new balance value is below tokens locks value. total_locked : " # debug_show (total_locked), null));
      };

      Map.set(a_from, token_handler, request.token, { total_balance = balance; locks = a_token.locks });
    } else {

      var a_from = switch (Map.get<Types.Account, Map.Map<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>>(state.state.fee_deposit_balances, account_handler, request.account)) {
        case (null) {
          return #ok(0);
        };
        case (?val) {
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
    state : StateAccess,
    escrow : Types.EscrowRecord,
    append : Bool,
  ) : Types.EscrowRecord {
    //add the escrow

    var a_from = switch (Map.get<Types.Account, MigrationTypes.Current.EscrowSellerTrie>(state.state.escrow_balances, account_handler, escrow.buyer)) {
      case (null) {
        let new_from = Map.new<Types.Account, Map.Map<Text, Map.Map<Types.TokenSpec, Types.EscrowRecord>>>();
        Map.set<Types.Account, MigrationTypes.Current.EscrowSellerTrie>(state.state.escrow_balances, account_handler, escrow.buyer, new_from);
        new_from;
      };
      case (?val) {
        val;
      };
    };

    var a_to = switch (Map.get<Types.Account, MigrationTypes.Current.EscrowTokenIDTrie>(a_from, account_handler, escrow.seller)) {
      case (null) {
        let newTo = Map.new<Text, Map.Map<Types.TokenSpec, Types.EscrowRecord>>();
        Map.set<Types.Account, MigrationTypes.Current.EscrowTokenIDTrie>(a_from, account_handler, escrow.seller, newTo);

        //add this item to the offer index
        if (escrow.token_id != "" and escrow.sale_id == null) {
          switch (Map.get<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, account_handler, escrow.seller)) {
            case (null) {
              var aTree = Map.new<Types.Account, Int>();
              Map.set<Types.Account, Int>(aTree, account_handler, escrow.buyer, state.get_time());
              Map.set<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, account_handler, escrow.seller, aTree);
            };
            case (?val) {
              Map.set<Types.Account, Int>(val, account_handler, escrow.buyer, state.get_time());
              Map.set<Types.Account, Map.Map<Types.Account, Int>>(state.state.offers, account_handler, escrow.seller, val);
            };
          };
        };
        newTo;
      };
      case (?val) val;
    };

    var a_token_id = switch (Map.get<Text, MigrationTypes.Current.EscrowLedgerTrie>(a_to, Map.thash, escrow.token_id)) {
      case (null) {
        let new_token_id = Map.new<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>();
        Map.set<Text, MigrationTypes.Current.EscrowLedgerTrie>(a_to, Map.thash, escrow.token_id, new_token_id);
        new_token_id;
      };
      case (?val) val;
    };

    switch (Map.get<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, escrow.token)) {
      case (null) {
        Map.set<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, escrow.token, escrow);
        return escrow;
      };
      case (?val) {

        //note: sale_id will overwrite to save user clicks; alternative is to make them clear it and submit a new escrow
        //nyi: add transaction for overwriting sale id
        let newLedger = if (append == true) {
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
  public func put_sales_balance(state : StateAccess, sale_balance : Types.EscrowRecord, append : Bool) : Types.EscrowRecord {
    //add the sale
    var a_to = switch (Map.get<Types.Account, MigrationTypes.Current.SalesBuyerTrie>(state.state.sales_balances, account_handler, sale_balance.seller)) {
      case (null) {
        let newTo = Map.new<Types.Account, Map.Map<Text, Map.Map<Types.TokenSpec, Types.EscrowRecord>>>();
        Map.set<Types.Account, MigrationTypes.Current.SalesBuyerTrie>(state.state.sales_balances, account_handler, sale_balance.seller, newTo);
        newTo;
      };
      case (?val) val;
    };

    var a_from = switch (Map.get<Types.Account, MigrationTypes.Current.SalesTokenIDTrie>(a_to, account_handler, sale_balance.buyer)) {
      case (null) {
        let new_from = Map.new<Text, Map.Map<Types.TokenSpec, Types.EscrowRecord>>();
        Map.set<Types.Account, MigrationTypes.Current.SalesTokenIDTrie>(a_to, account_handler, sale_balance.buyer, new_from);
        new_from;
      };
      case (?val) val;
    };

    var a_token_id = switch (Map.get<Text, MigrationTypes.Current.SalesLedgerTrie>(a_from, Map.thash, sale_balance.token_id)) {
      case (null) {
        let new_token_id = Map.new<Types.TokenSpec, Types.EscrowRecord>();
        Map.set(a_from, Map.thash, sale_balance.token_id, new_token_id);
        new_token_id;
      };
      case (?val) val;
    };

    switch (Map.get<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, sale_balance.token)) {
      case (null) {
        debug if (debug_channel.royalties) D.print("putting sale balance in escrow, existing record was null" # debug_show ((sale_balance)));
        Map.set<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, sale_balance.token, sale_balance);
        return sale_balance;
      };
      case (?val) {
        //note: sale_id will overwrite to save user clicks; alternative is to make them clear it and submit a new escrow
        //nyi: add transaction for overwriting sale id
        debug if (debug_channel.royalties) D.print("putting sale balance in escrow, existing record found " # debug_show ((val, sale_balance)));

        let newLedger = if (append == true) {
          {
            sale_balance with
            amount = val.amount + sale_balance.amount;
          } //this is a more recent sales id so we use it
        } else { sale_balance };
        Map.set<Types.TokenSpec, Migrations.Current.EscrowRecord>(a_token_id, token_handler, sale_balance.token, newLedger);

        debug if (debug_channel.royalties) D.print("have a new ledger " # debug_show ((newLedger)));

        return newLedger;
      };
    };
  };
};
