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
import NFTUtils "../utils";
import Types "../types";
import FeeAccount "./fee_account";
import Verify "./verify_reciept";

module {
  let debug_channel = {
    withdraw_escrow = true;
    withdraw_sale = true;
    withdraw_reject = true;
    withdraw_deposit = true;
    withdraw_fee_deposit = true;
  };

  type StateAccess = Types.State;

  let account_handler = MigrationTypes.Current.account_handler;
  let token_handler = MigrationTypes.Current.token_handler;
  let Map = MigrationTypes.Current.Map;

  /**
    * Withdraw or deposit funds to a specified account using the specified details.
    * @param {StateAccess} state - The state of the canister.
    * @param {Types.DepositWithdrawDescription} details - The details of the withdrawal or deposit.
    * @param {Principal} caller - The caller of the function.
    * @returns {async* Result.Result<Types.ManageSaleResponse,Types.OrigynError>} - The result of the operation which may contain an error.
    */
  public func _withdraw_deposit<system>(state : StateAccess, withdraw : Types.WithdrawRequest, details : Types.DepositWithdrawDescription, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {
    debug if (debug_channel.withdraw_deposit) D.print("in deposit withdraw");
    debug if (debug_channel.withdraw_deposit) D.print("an deposit withdraw");
    debug if (debug_channel.withdraw_deposit) D.print(debug_show (withdraw));
    if (caller != state.canister() and caller != details.buyer.owner) {
      //cant withdraw for someone else
      return #err(#trappable(Types.errors(#unauthorized_access, "withdraw_nft_origyn - deposit - buyer and caller do not match", ?caller)));
    };

    debug if (debug_channel.withdraw_deposit) D.print("about to verify");

    let deposit_account = NFTUtils.get_deposit_info(details.buyer, state.canister());

    //NFT-112
    let fee = switch (details.token) {
      case (#ic(token)) {
        let token_fee = Option.get(token.fee, 0);
        if (details.amount <= token_fee) return #err(#trappable(Types.errors(#withdraw_too_large, "withdraw_nft_origyn - deposit - withdraw fee is larger than amount", ?caller)));
        token_fee;
      };
      case (_) return #err(#trappable(Types.errors(#nyi, "withdraw_nft_origyn - deposit - extensible token nyi - " # debug_show (details), ?caller)));
    };

    //attempt to send payment
    debug if (debug_channel.withdraw_deposit) D.print("sending payment" # debug_show ((details.withdraw_to, details.amount, caller)));
    var transaction_id : ?{ trx_id : Types.TransactionID; fee : Nat } = null;

    transaction_id := switch (details.token) {
      case (#ic(token)) {
        switch (token.standard) {
          case (#Ledger or #ICRC1) {
            //D.print("found ledger");
            let checker = Ledger_Interface.Ledger_Interface();

            debug if (debug_channel.withdraw_deposit) D.print("returning amount " # debug_show (details.amount, token.fee));

            try {
              switch (await* checker.send_payment_minus_fee(details.withdraw_to, token, details.amount, deposit_account.subaccount, caller)) {
                case (#ok(val)) ?val;
                case (#err(err)) return #err(#awaited(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - deposit - ledger payment failed err branch " # err.flag_point # " " # debug_show ((details.withdraw_to, token, details.amount, ?deposit_account.subaccount, caller)), ?caller)));

              };
            } catch (e) {
              return #err(#awaited(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - deposit - ledger payment failed catch branch " # Error.message(e), ?caller)));
            };
          };
          case (_) return #err(#awaited(Types.errors(#nyi, "withdraw_nft_origyn - deposit - - ledger type nyi - " # debug_show (details), ?caller)));
        };
      };
      case (#extensible(val)) return #err(#trappable(Types.errors(#nyi, "withdraw_nft_origyn - deposit - -  token standard nyi - " # debug_show (details), ?caller)));
    };

    debug if (debug_channel.withdraw_deposit) D.print("succesful transaction :" # debug_show (transaction_id) # debug_show (details));

    switch (transaction_id) {
      case (null) return #err(#awaited(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow -  payment failed txid null", ?caller)));
      case (?transaction_id) {
        switch (
          Metadata.add_transaction_record<system>(
            state,
            {
              token_id = "";
              index = 0;
              txn_type = #deposit_withdraw({
                details with
                amount = Nat.sub(details.amount, transaction_id.fee);
                fee = transaction_id.fee;
                trx_id = transaction_id.trx_id;
                extensible = #Option(null);
              });
              timestamp = state.get_time();
            },
            caller,
          )
        ) {
          case (#ok(val)) return #awaited(#withdraw(val));
          case (#err(err)) return #err(#awaited(Types.errors(err.error, "withdraw_nft_origyn - escrow - ledger not updated" # debug_show (transaction_id), ?caller)));
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
  public func _withdraw_fee_deposit(state : StateAccess, withdraw : Types.WithdrawRequest, details : Types.FeeDepositWithdrawDescription, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {
    debug if (debug_channel.withdraw_fee_deposit) D.print("in deposit withdraw");
    debug if (debug_channel.withdraw_fee_deposit) D.print("an deposit withdraw");
    debug if (debug_channel.withdraw_fee_deposit) D.print(debug_show (withdraw));
    if (caller != state.canister() and caller != details.account.owner) {
      //cant withdraw for someone else
      debug if (debug_channel.withdraw_fee_deposit) D.print("withdraw - buyer and caller do not match");
      return #err(#trappable(Types.errors(#unauthorized_access, "_withdraw_fee_deposit - withdraw - buyer and caller do not match", ?caller)));
    };

    debug if (debug_channel.withdraw_fee_deposit) D.print("about to verify");

    let fee_deposit_account = NFTUtils.get_fee_deposit_account_info(details.account, state.canister());

    //NFT-112
    let fee = switch (details.token) {
      case (#ic(token)) {
        let token_fee = Option.get(token.fee, 0);
        if (details.amount <= token_fee) return #err(#trappable(Types.errors(#withdraw_too_large, "_withdraw_fee_deposit - withdraw - withdraw fee is larger than amount", ?caller)));
        token_fee;
      };
      case (_) return #err(#trappable(Types.errors(#nyi, "_withdraw_fee_deposit - withdraw - extensible token nyi - " # debug_show (details), ?caller)));
    };

    switch (details.status) {
      case (#locked(val)) {};
      case (#unlocked) {
        switch (FeeAccount.free_token_fee_balance(state, { account = details.account; token = details.token })) {
          case (#ok(free_token)) {
            if (free_token < details.amount) {
              return #err(#trappable(Types.errors(#nyi, "_withdraw_fee_deposit - withdraw - free token : " # debug_show (free_token) # " try to withdraw : " # debug_show (details.amount), ?caller)));
            };
          };
          case (#err(e)) {
            return #err(#trappable(Types.errors(#nyi, "_withdraw_fee_deposit - withdraw - err getting free token balance - " # debug_show (e), ?caller)));
          };
        };
      };
    };

    //attempt to send payment
    debug if (debug_channel.withdraw_fee_deposit) D.print("sending payment" # debug_show ((details.withdraw_to, details.amount, caller)));
    var transaction_id : ?{ trx_id : Types.TransactionID; fee : Nat } = null;

    transaction_id := switch (details.token) {
      case (#ic(token)) {
        switch (token.standard) {
          case (#Ledger or #ICRC1) {
            //D.print("found ledger");
            let checker = Ledger_Interface.Ledger_Interface();

            debug if (debug_channel.withdraw_fee_deposit) D.print("returning amount " # debug_show (details.amount, token.fee));

            try {
              switch (await* checker.send_payment_minus_fee(details.withdraw_to, token, details.amount, fee_deposit_account.subaccount, caller)) {
                case (#ok(val)) ?val;
                case (#err(err)) {
                  debug if (debug_channel.withdraw_fee_deposit) D.print("withdraw_fee_deposit : deposit - ledger payment failed err branch " # err.flag_point # " " # debug_show ((details.withdraw_to, token, details.amount, ?fee_deposit_account.subaccount, caller)));
                  return #err(#awaited(Types.errors(#escrow_withdraw_payment_failed, "withdraw_fee_deposit - deposit - ledger payment failed err branch " # err.flag_point # " " # debug_show ((details.withdraw_to, token, details.amount, ?fee_deposit_account.subaccount, caller)), ?caller)));
                };
              };
            } catch (e) {
              return #err(#awaited(Types.errors(#escrow_withdraw_payment_failed, "withdraw_fee_deposit - deposit - ledger payment failed catch branch " # Error.message(e), ?caller)));
            };
          };
          case (_) return #err(#awaited(Types.errors(#nyi, "withdraw_fee_deposit - deposit - - ledger type nyi - " # debug_show (details), ?caller)));
        };
      };
      case (#extensible(val)) return #err(#trappable(Types.errors(#nyi, "withdraw_fee_deposit - deposit - -  token standard nyi - " # debug_show (details), ?caller)));
    };

    debug if (debug_channel.withdraw_fee_deposit) D.print("withdraw_fee_deposit : succesful transaction :" # debug_show (transaction_id) # debug_show (details));

    switch (details.status) {
      case (#locked(val)) {
        switch (
          FeeAccount.unlock_token_fee_balance(
            state,
            {
              account = details.account;
              token = details.token;
              sale_id = val.sale_id;
              update_balance = true;
            },
          )
        ) {
          case (#ok(val)) {
            debug if (debug_channel.withdraw_fee_deposit) D.print("withdraw_fee_deposit : succesful unlock token :" # debug_show (val));
          };
          case (#err(err)) {
            debug if (debug_channel.withdraw_fee_deposit) D.print("withdraw_fee_deposit : failed to unlock token " # debug_show (err));
            return #err(#trappable(Types.errors(#nyi, "_withdraw_fee_deposit - failed to unlock token " # debug_show (err), ?caller)));
          };
        };
      };
      case (#unlocked) {};
    };

    switch (transaction_id) {
      case (null) return #err(#awaited(Types.errors(#escrow_withdraw_payment_failed, "withdraw_fee_deposit - escrow -  payment failed txid null", ?caller)));
      case (?transaction_id) {
        let token_id = switch (details.status) {
          case (#locked(val)) { val.token_id };
          case (#unlocked) { "" };
        };

        switch (
          Metadata.add_transaction_record<system>(
            state,
            {
              token_id = token_id;
              index = 0;
              txn_type = #fee_deposit_withdraw({
                details with
                amount = Nat.sub(details.amount, transaction_id.fee);
                fee = transaction_id.fee;
                trx_id = transaction_id.trx_id;
                extensible = #Option(null);
              });
              timestamp = state.get_time();
            },
            caller,
          )
        ) {
          case (#ok(val)) return #awaited(#withdraw(val));
          case (#err(err)) return #err(#awaited(Types.errors(err.error, "withdraw_fee_deposit - escrow - ledger not updated" # debug_show (transaction_id), ?caller)));
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
  public func _withdraw_escrow(state : StateAccess, withdraw : Types.WithdrawRequest, details : Types.WithdrawDescription, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {

    debug if (debug_channel.withdraw_escrow) D.print("an escrow withdraw");
    debug if (debug_channel.withdraw_escrow) D.print(debug_show (withdraw));
    if (caller != state.canister() and caller != details.buyer.owner) return #err(#trappable(Types.errors(#unauthorized_access, "withdraw_nft_origyn - escrow - buyer and caller do not match", ?caller)));

    debug if (debug_channel.withdraw_escrow) D.print("about to verify");

    let verified = switch (Verify.verify_escrow_receipt(state, details, null, null)) {
      case (#err(err)) {
        debug if (debug_channel.withdraw_escrow) D.print("an error");
        debug if (debug_channel.withdraw_escrow) D.print(debug_show (err));
        return #err(#trappable(Types.errors(err.error, "withdraw_nft_origyn - escrow - - cannot verify escrow - " # debug_show (details), ?caller)));
      };
      case (#ok(verified)) verified;
    };

    let account_info = NFTUtils.get_escrow_account_info(verified.found_asset.escrow, state.canister());
    if (verified.found_asset.escrow.amount < details.amount) {
      debug if (debug_channel.withdraw_escrow) D.print("in check amount " # debug_show (verified.found_asset.escrow.amount) # " " # debug_show (details.amount));
      return #err(#trappable(Types.errors(#withdraw_too_large, "withdraw_nft_origyn - escrow - withdraw too large", ?caller)));
    };

    let a_ledger = verified.found_asset.escrow;

    switch (a_ledger.lock_to_date) {
      case (?val) {
        debug if (debug_channel.withdraw_escrow) D.print("found a lock date " # debug_show ((val, state.get_time())));
        if (state.get_time() < val) return #err(#trappable(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - escrow - this escrow is locked until " # debug_show (val), ?caller)));
      };
      case (null) {
        debug if (debug_channel.withdraw_escrow) D.print("no lock date " # debug_show ((state.get_time())));
      };
    };

    //NFT-112
    let fee = switch (details.token) {
      case (#ic(token)) {
        let token_fee = Option.get(token.fee, 0);
        if (a_ledger.amount <= token_fee) return #err(#trappable(Types.errors(#withdraw_too_large, "withdraw_nft_origyn - escrow - withdraw fee is larger than amount", ?caller)));
        token_fee;
      };
      case (_) return #err(#trappable(Types.errors(#nyi, "withdraw_nft_origyn - escrow - extensible token nyi - " # debug_show (details), ?caller)));
    };

    //D.print("got to sale id");

    switch (a_ledger.sale_id) {
      case (?sale_id) {
        //check that the owner isn't still the bidder in the sale
        let sale = switch (Map.get(state.state.nft_sales, Map.thash, sale_id)) {
          case (null) return #err(#trappable(Types.errors(#sale_not_found, "withdraw_nft_origyn - escrow - can't find sale top" # debug_show (a_ledger) # " " # debug_show (withdraw), ?caller)));
          case (?sale) sale;
        };

        debug if (debug_channel.withdraw_escrow) D.print("testing current state");

        let current_sale_state = switch (NFTUtils.get_auction_state_from_status(sale)) {
          case (#ok(val)) val;
          case (#err(err)) return #err(#trappable(Types.errors(err.error, "withdraw_nft_origyn - escrow - find state " # err.flag_point, ?caller)));
        };

        switch (current_sale_state.status) {
          case (#open) {

            debug if (debug_channel.withdraw_escrow) D.print(debug_show (current_sale_state));
            debug if (debug_channel.withdraw_escrow) D.print(debug_show (caller));

            //NFT-110
            switch (current_sale_state.winner) {
              case (?val) {
                debug if (debug_channel.withdraw_escrow) D.print("found a winner");
                if (Types.account_eq(val, details.buyer)) {
                  debug if (debug_channel.withdraw_escrow) D.print("should be throwing an error");
                  return #err(#trappable(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - escrow - you are the winner", ?caller)));
                };
              };
              case (null) {
                debug if (debug_channel.withdraw_escrow) D.print("not a winner");
              };
            };

            //NFT-76
            switch (current_sale_state.current_escrow) {
              case (?val) {
                debug if (debug_channel.withdraw_escrow) D.print("testing current escorw");
                debug if (debug_channel.withdraw_escrow) D.print(debug_show (val.buyer));
                if (Types.account_eq(val.buyer, details.buyer)) {
                  debug if (debug_channel.withdraw_escrow) D.print("passed");
                  return #err(#trappable(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - escrow - you are the current bid", ?caller)));
                };
              };
              case (null) {
                debug if (debug_channel.withdraw_escrow) D.print("not a current escrow");
              };
            };
          };
          case (_) {
            //it isn't open so we don't need to check
          };
        };
      };
      case (null) {};
    };

    debug if (debug_channel.withdraw_escrow) D.print("finding target escrow");
    debug if (debug_channel.withdraw_escrow) D.print(debug_show (a_ledger.amount));
    debug if (debug_channel.withdraw_escrow) D.print(debug_show (details.amount));
    //ok...so we should be good to withdraw
    //first update the escrow
    if (verified.found_asset.escrow.amount < details.amount) return #err(#trappable(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - escrow - amount too large ", ?caller)));

    let target_escrow = {
      details with
      account_hash = verified.found_asset.escrow.account_hash;
      balances = null;
      amount = Nat.sub(verified.found_asset.escrow.amount, details.amount);
      sale_id = a_ledger.sale_id;
      lock_to_date = a_ledger.lock_to_date;
    };

    if (target_escrow.amount > 0) {
      Map.set<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>(verified.found_asset_list, token_handler, details.token, target_escrow);
    } else {
      Map.delete<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>(verified.found_asset_list, token_handler, details.token);
    };

    //send payment
    //reentrancy risk so we remove the escrow value above before calling
    debug if (debug_channel.withdraw_escrow) D.print("sending payment" # debug_show ((details.withdraw_to, details.amount, caller)));
    var transaction_id : ?{ trx_id : Types.TransactionID; fee : Nat } = null;

    transaction_id := switch (details.token) {
      case (#ic(token)) {
        switch (token.standard) {
          case (#Ledger or #ICRC1) {
            //D.print("found ledger");
            let checker = Ledger_Interface.Ledger_Interface();

            debug if (debug_channel.withdraw_escrow) D.print("returning amount " # debug_show (details.amount, token.fee));

            try {
              switch (await* checker.send_payment_minus_fee(details.withdraw_to, token, details.amount, account_info.subaccount, caller)) {
                case (#ok(val)) ?val;
                case (#err(err)) {
                  Verify.handle_escrow_update_error(state, a_ledger, null, verified.found_asset, verified.found_asset_list);
                  return #err(#awaited(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow - ledger payment failed err branch " # err.flag_point, ?caller)));
                };
              };
            } catch (e) {
              //put the escrow back because something went wrong
              Verify.handle_escrow_update_error(state, a_ledger, null, verified.found_asset, verified.found_asset_list);
              return #err(#awaited(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow - ledger payment failed catch branch " # Error.message(e), ?caller)));
            };

          };
          case (_) return #err(#trappable(Types.errors(#nyi, "withdraw_nft_origyn - escrow - - ledger type nyi - " # debug_show (details), ?caller)));
        };
      };
      case (#extensible(val)) return #err(#trappable(Types.errors(#nyi, "withdraw_nft_origyn - escrow - -  token standard nyi - " # debug_show (details), ?caller)));
    };

    debug if (debug_channel.withdraw_escrow) D.print("succesful transaction :" # debug_show (transaction_id) # debug_show (details));

    switch (transaction_id) {
      case (null) return #err(#awaited(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - escrow -  payment failed txid null", ?caller)));
      case (?transaction_id) {
        switch (
          Metadata.add_transaction_record<system>(
            state,
            {
              token_id = details.token_id;
              index = 0;
              txn_type = #escrow_withdraw({
                details with
                amount = Nat.sub(details.amount, transaction_id.fee);
                fee = transaction_id.fee;
                trx_id = transaction_id.trx_id;
                extensible = #Option(null);
              });
              timestamp = state.get_time();
            },
            caller,
          )
        ) {
          case (#ok(val)) return #awaited(#withdraw(val));
          case (#err(err)) return #err(#awaited(Types.errors(err.error, "withdraw_nft_origyn - escrow - ledger not updated" # debug_show (transaction_id), ?caller)));
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
  public func _withdraw_sale(state : StateAccess, withdraw : Types.WithdrawRequest, details : Types.WithdrawDescription, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {
    debug if (debug_channel.withdraw_sale) D.print("withdrawing a sale");
    debug if (debug_channel.withdraw_sale) D.print(debug_show (details));
    debug if (debug_channel.withdraw_sale) D.print(debug_show (caller));
    if (caller != state.canister() and caller != details.seller.owner) return #err(#trappable(Types.errors(#unauthorized_access, "withdraw_nft_origyn - sales- buyer and caller do not match" # debug_show ((#principal(caller), details.seller)), ?caller)));

    let verified = switch (Verify.verify_sales_reciept(state, details)) {
      case (#ok(verified)) verified;
      case (#err(err)) {
        debug if (debug_channel.withdraw_sale) D.print("an error");
        debug if (debug_channel.withdraw_sale) D.print(debug_show (err));
        return #err(#trappable(Types.errors(err.error, "withdraw_nft_origyn - sale - - cannot verify escrow - " # debug_show (details), ?caller)));
      };
    };

    debug if (debug_channel.withdraw_sale) D.print("have verified");

    if (verified.found_asset.escrow.amount < details.amount) return #err(#trappable(Types.errors(#withdraw_too_large, "withdraw_nft_origyn - sales - withdraw too large", ?caller)));

    let a_ledger = verified.found_asset.escrow;

    debug if (debug_channel.withdraw_sale) D.print("a_ledger" # debug_show (a_ledger));

    let a_token_id = verified.found_asset_list;

    //NFT-112
    switch (details.token) {
      case (#ic(token)) {
        let token_fee = Option.get(token.fee, 0);
        if (a_ledger.amount <= token_fee) {
          debug if (debug_channel.withdraw_sale) D.print("withdraw fee is larger than amount");
          return #err(#trappable(Types.errors(#withdraw_too_large, "withdraw_nft_origyn - sales - withdraw fee is larger than amount", ?caller)));
        };
      };
      case (_) {
        debug if (debug_channel.withdraw_sale) D.print("nyi err");
        return #err(#trappable(Types.errors(#nyi, "withdraw_nft_origyn - sales - extensible token nyi - " # debug_show (details), ?caller)));
      };
    };

    debug if (debug_channel.withdraw_sale) D.print("finding target escrow");
    debug if (debug_channel.withdraw_sale) D.print(debug_show (a_ledger.amount));
    debug if (debug_channel.withdraw_sale) D.print(debug_show (details.amount));
    //ok...so we should be good to withdraw
    //first update the escrow
    if (verified.found_asset.escrow.amount < details.amount) return #err(#trappable(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - sale - amount too large ", ?caller)));

    let target_escrow = {
      a_ledger with
      amount = Nat.sub(a_ledger.amount, details.amount);
    };

    if (target_escrow.amount > 0) {
      Map.set<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>(a_token_id, token_handler, details.token, target_escrow);
    } else {
      Map.delete<Types.TokenSpec, MigrationTypes.Current.EscrowRecord>(a_token_id, token_handler, details.token);
    };

    //send payment
    debug if (debug_channel.withdraw_sale) D.print("sending payment");
    var transaction_id : ?{ trx_id : Types.TransactionID; fee : Nat } = null;

    transaction_id := switch (details.token) {
      case (#ic(token)) {
        switch (token.standard) {
          case (#Ledger or #ICRC1) {
            debug if (debug_channel.withdraw_sale) D.print("found ledger sale withdraw");
            let checker = Ledger_Interface.Ledger_Interface();

            debug if (debug_channel.withdraw_sale) D.print("returning amount " # debug_show (details.amount, token.fee));

            //if this fails we need to put the escrow back
            try {
              switch (await* checker.send_payment_minus_fee(details.withdraw_to, token, details.amount, a_ledger.account_hash, caller)) {
                case (#ok(val)) ?val;
                case (#err(err)) {
                  //put the escrow back
                  debug if (debug_channel.withdraw_sale) D.print("failed, putting back ledger " # debug_show (err));

                  Verify.handle_sale_update_error(state, details, null, verified.found_asset, verified.found_asset_list);
                  return #err(#awaited(Types.errors(#sales_withdraw_payment_failed, "withdraw_nft_origyn - sales ledger payment failed err branch" # err.flag_point, ?caller)));
                };
              };
            } catch (e) {
              debug if (debug_channel.withdraw_sale) D.print("withdraw_nft_origyn - sales ledger payment failed catch branch " # Error.message(e));
              //put the escrow back
              Verify.handle_sale_update_error(state, details, null, verified.found_asset, verified.found_asset_list);
              return #err(#awaited(Types.errors(#sales_withdraw_payment_failed, "withdraw_nft_origyn - sales ledger payment failed catch branch" # Error.message(e), ?caller)));
            };
          };
          case (_) {
            debug if (debug_channel.withdraw_sale) D.print("withdraw_nft_origyn - sales - ledger type nyi ");
            return #err(#trappable(Types.errors(#nyi, "withdraw_nft_origyn - sales - ledger type nyi - " # debug_show (details), ?caller)));
          };
        };
      };
      case (#extensible(val)) return #err(#trappable(Types.errors(#nyi, "withdraw_nft_origyn - sales - extensible token nyi - " # debug_show (details), ?caller)));
    };

    debug if (debug_channel.withdraw_sale) D.print("have a transactionid and will crate a transaction " # debug_show (transaction_id));
    switch (transaction_id) {
      case (null) return #err(#awaited(Types.errors(#sales_withdraw_payment_failed, "withdraw_nft_origyn - sales  payment failed txid null", ?caller)));
      case (?transaction_id) {
        switch (
          Metadata.add_transaction_record<system>(
            state,
            {
              token_id = details.token_id;
              index = 0;
              txn_type = #sale_withdraw({
                details with
                amount = Nat.sub(details.amount, transaction_id.fee);
                fee = transaction_id.fee;
                trx_id = transaction_id.trx_id;
                extensible = #Option(null);
              });
              timestamp = state.get_time();
            },
            caller,
          )
        ) {
          case (#ok(val)) return #awaited(#withdraw(val));
          case (#err(err)) return #err(#awaited(Types.errors(err.error, "withdraw_nft_origyn - sales ledger not updated" # debug_show (transaction_id), ?caller)));
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
  public func _reject_offer<system>(state : StateAccess, withdraw : Types.WithdrawRequest, details : Types.RejectDescription, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {
    // rejects and offer and sends the tokens back to the source
    debug if (debug_channel.withdraw_reject) D.print("an escrow reject");
    if (caller != state.canister() and caller != details.seller.owner and ?caller != state.state.collection_data.network) {
      //cant withdraw for someone else
      debug if (debug_channel.withdraw_reject) D.print(debug_show ((caller, state.canister(), details.seller, state.state.collection_data.network)));
      return #err(#trappable(Types.errors(#unauthorized_access, "withdraw_nft_origyn - reject - unauthorized", ?caller)));
    };

    debug if (debug_channel.withdraw_reject) D.print("about to verify");

    let verified = switch (
      Verify.verify_escrow_receipt(
        state,
        {
          amount = 0;
          buyer = details.buyer;
          seller = details.seller;
          token = details.token;
          token_id = details.token_id;
        },
        null,
        null,
      )
    ) {
      case (#ok(verified)) verified;
      case (#err(err)) {
        debug if (debug_channel.withdraw_reject) D.print("an error");
        debug if (debug_channel.withdraw_reject) D.print(debug_show (err));
        return #err(#trappable(Types.errors(err.error, "withdraw_nft_origyn - escrow - - cannot verify escrow - " # debug_show (details), ?caller)));
      };
    };

    let account_info = NFTUtils.get_escrow_account_info(verified.found_asset.escrow, state.canister());

    let a_ledger = verified.found_asset.escrow;

    // reject ignores locked assets
    //NFT-112
    let fee = switch (details.token) {
      case (#ic(token)) {
        let token_fee = Option.get(token.fee, 0);
        if (a_ledger.amount <= token_fee) return #err(#trappable(Types.errors(#withdraw_too_large, "withdraw_nft_origyn - reject - withdraw fee is larger than amount", ?caller)));
        token_fee;
      };
      case (_) return #err(#trappable(Types.errors(#nyi, "withdraw_nft_origyn - reject - extensible token nyi - " # debug_show (details), ?caller)));
    };

    debug if (debug_channel.withdraw_reject) D.print("got to sale id");

    switch (a_ledger.sale_id) {
      case (?sale_id) {
        //check that the owner isn't still the bidder in the sale
        switch (Map.get(state.state.nft_sales, Map.thash, sale_id)) {
          case (null) return #err(#trappable(Types.errors(#sale_not_found, "withdraw_nft_origyn - reject - can't find sale top" # debug_show (a_ledger) # " " # debug_show (withdraw), ?caller)));
          case (?val) {

            debug if (debug_channel.withdraw_reject) D.print("testing current state");

            let current_sale_state = switch (NFTUtils.get_auction_state_from_status(val)) {
              case (#ok(val)) { val };
              case (#err(err)) {
                return #err(#trappable(Types.errors(err.error, "withdraw_nft_origyn - reject - find state " # err.flag_point, ?caller)));
              };
            };

            switch (current_sale_state.status) {
              case (#open) {

                debug if (debug_channel.withdraw_reject) D.print(debug_show (current_sale_state));
                debug if (debug_channel.withdraw_reject) D.print(debug_show (caller));

                //NFT-110
                switch (current_sale_state.winner) {
                  case (?val) {
                    debug if (debug_channel.withdraw_reject) D.print("found a winner");
                    if (Types.account_eq(val, details.buyer)) {
                      debug if (debug_channel.withdraw_reject) D.print("should be throwing an error");
                      return #err(#trappable(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - reject - you are the winner", ?caller)));
                    };
                  };
                  case (null) {
                    debug if (debug_channel.withdraw_reject) D.print("not a winner");
                  };
                };

                //NFT-76
                switch (current_sale_state.current_escrow) {
                  case (?val) {
                    debug if (debug_channel.withdraw_reject) D.print("testing current escorw");
                    debug if (debug_channel.withdraw_reject) D.print(debug_show (val.buyer));
                    if (Types.account_eq(val.buyer, details.buyer)) {
                      debug if (debug_channel.withdraw_reject) D.print("passed");
                      return #err(#trappable(Types.errors(#escrow_cannot_be_removed, "withdraw_nft_origyn - reject - you are the current bid", ?caller)));
                    };
                  };
                  case (null) {
                    debug if (debug_channel.withdraw_reject) D.print("not a current escrow");
                  };
                };
              };
              case (_) {
                //it isn't open so we don't need to check
              };
            };
          };
        };
      };
      case (null) {

      };
    };

    debug if (debug_channel.withdraw_reject) D.print("finding target escrow");
    debug if (debug_channel.withdraw_reject) D.print(debug_show (a_ledger.amount));

    //ok...so we should be good to withdraw
    //first update the escrow

    //deleteing the asset
    Map.delete(verified.found_asset_list, token_handler, details.token);

    //send payment

    var transaction_id : ?{ trx_id : Types.TransactionID; fee : Nat } = null;
    try {
      transaction_id := switch (details.token) {
        case (#ic(token)) {
          switch (token.standard) {
            case (#Ledger or #ICRC1) {
              //D.print("found ledger");
              let checker = Ledger_Interface.Ledger_Interface();

              debug if (debug_channel.withdraw_reject) D.print("returning amount " # debug_show (verified.found_asset.escrow.amount, token.fee));

              switch (await* checker.send_payment_minus_fee(details.buyer, token, verified.found_asset.escrow.amount, account_info.subaccount, caller)) {
                case (#ok(val)) ?val;
                case (#err(err)) {
                  //put the escrow back
                  //make sure things havent changed in the mean time
                  //D.print("failed, putting back ledger");
                  Verify.handle_escrow_update_error(state, a_ledger, null, verified.found_asset, verified.found_asset_list);
                  return #err(#awaited(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - reject - ledger payment failed" # err.flag_point, ?caller)));
                };
              };

            };
            case (_) {
              return #err(#trappable(Types.errors(#nyi, "withdraw_nft_origyn - reject - - ledger type nyi - " # debug_show (details), ?caller)));
            };
          };
        };
        case (#extensible(val)) {
          return #err(#trappable(Types.errors(#nyi, "withdraw_nft_origyn - reject - -  token standard nyi - " # debug_show (details), ?caller)));
        };
      };
    } catch (e) {
      //something failed, put the escrow back
      //make sure it hasn't changed in the mean time
      //D.print("failed, putting back throw");
      Verify.handle_escrow_update_error(state, a_ledger, null, verified.found_asset, verified.found_asset_list);

      return #err(#awaited(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - reject -  payment failed" # Error.message(e), ?caller)));
    };

    debug if (debug_channel.withdraw_reject) D.print("succesful transaction :" # debug_show (transaction_id) # debug_show (details));

    switch (transaction_id) {
      case (null) {
        //really should have failed already
        return #err(#awaited(Types.errors(#escrow_withdraw_payment_failed, "withdraw_nft_origyn - transaction -  payment failed txid null", ?caller)));
      };
      case (?transaction_id) {
        switch (
          Metadata.add_transaction_record<system>(
            state,
            {
              token_id = details.token_id;
              index = 0;
              txn_type = #escrow_withdraw({
                details with
                amount = Nat.sub(verified.found_asset.escrow.amount, transaction_id.fee);
                fee = transaction_id.fee;
                trx_id = transaction_id.trx_id;
                extensible = #Option(null);
              });
              timestamp = state.get_time();
            },
            caller,
          )
        ) {
          case (#ok(val)) {
            return #awaited(#withdraw(val));
          };
          case (#err(err)) {
            return #err(#awaited(Types.errors(err.error, "withdraw_nft_origyn - transaction - ledger not updated" # debug_show (transaction_id), ?caller)));
          };
        };
      };
    };
  };
};
