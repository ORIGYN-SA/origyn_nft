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
import Ledger_Interface "../ledger_interface";
import Metadata "../metadata";
import MigrationTypes "../migrations/types";
import NFTUtils "../utils";
import Types "../types";

module {
  let debug_channel = {
    market = false;
  };

  type StateAccess = Types.State;
  let account_handler = MigrationTypes.Current.account_handler;
  let token_handler = MigrationTypes.Current.token_handler;
  let Map = MigrationTypes.Current.Map;

  private func _access_fee_balance<T>(
    state : StateAccess,
    default_request : {
      account : Types.Account;
      token : Types.TokenSpec;
    },
    request : T,
    f : (T, MigrationTypes.Current.FeeDepositDetail) -> Result.Result<Nat, Types.OrigynError>,
  ) : Result.Result<Nat, Types.OrigynError> {
    debug if (debug_channel.market) D.print("_access_fee_balance: state.state.fee_deposit_balances  " # debug_show (state.state.fee_deposit_balances));

    return switch (Map.get<Types.Account, Map.Map<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>>(state.state.fee_deposit_balances, account_handler, default_request.account)) {
      case (null) {
        debug if (debug_channel.market) D.print("_access_fee_balance: _access_fee_balance - account not found  " # debug_show (default_request.account));
        return #err(Types.errors(#content_not_found, "_access_fee_balance - account not found  " # debug_show (default_request.account), null));
      };
      case (?val) {
        switch (Map.get<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>(val, token_handler, default_request.token)) {
          case (null) {
            debug if (debug_channel.market) D.print("_access_fee_balance: _access_fee_balance - token not found  " # debug_show (default_request.token));
            return #err(Types.errors(#content_not_found, "_access_fee_balance - token not found  " # debug_show (default_request.token), null));
          };
          case (?token) {
            return f(request, token);
          };
        };
      };
    };

  };

  /**
    * @param {StateAccess} state - The state access object.
    * @param {Types.FeeDepositRequest} FeeDepositRequest - The request record to be processed.
    * @returns {Nat} - The amount of free tokens available for fees. Returns 0 if the calculated free amount is negative or if no balance is found.
    */
  public func lock_token_fee_balance(
    state : StateAccess,
    request : {
      account : Types.Account;
      token : Types.TokenSpec;
      token_to_lock : Nat;
      sale_id : Text;
    },
  ) : Result.Result<Nat, Types.OrigynError> {
    return _access_fee_balance<{ token_to_lock : Nat; sale_id : Text }>(
      state,
      {
        account = request.account;
        token = request.token;
      },
      {
        token_to_lock = request.token_to_lock;
        sale_id = request.sale_id;
      },
      func((request, token)) {
        var all_locked_value : Nat = 0;
        for (lock_value in Map.vals(token.locks)) {
          all_locked_value += lock_value;
        };

        debug if (debug_channel.market) D.print("lock_token_fee_balance: total_balance = " # debug_show (token.total_balance) # " all_locked_value = " # debug_show (all_locked_value) # " token_to_lock " # debug_show (request.token_to_lock));

        if (token.total_balance - all_locked_value : Nat >= request.token_to_lock) {
          var previous_locked_value : Nat = Option.get<Nat>(Map.get<Text, Nat>(token.locks, Map.thash, request.sale_id), 0);
          let new_token_lock_value = previous_locked_value + request.token_to_lock;

          let _ = Map.put<Text, Nat>(token.locks, Map.thash, request.sale_id, new_token_lock_value);

          return #ok(new_token_lock_value);
        } else {
          return #err(Types.errors(#low_fee_balance, "lock_token_fee_balance - low_fee_balance  ", null));
        };
      },
    );
  };

  /**
    * @param {StateAccess} state - The state access object.
    * @param {Types.FeeDepositRequest} FeeDepositRequest - The request record to be processed.
    * @returns {Nat} - The amount of free tokens available for fees. Returns 0 if the calculated free amount is negative or if no balance is found.
    */
  public func free_token_fee_balance(
    state : StateAccess,
    request : {
      account : Types.Account;
      token : Types.TokenSpec;
    },
  ) : Result.Result<Nat, Types.OrigynError> {
    return _access_fee_balance<{}>(
      state,
      {
        account = request.account;
        token = request.token;
      },
      {},
      func((request, token)) {
        var all_locked_value : Nat = 0;
        for (lock_value in Map.vals(token.locks)) {
          all_locked_value += lock_value;
        };

        debug if (debug_channel.market) D.print("free_token_fee_balance: total_balance = " # debug_show (token.total_balance) # " all_locked_value = " # debug_show (all_locked_value));
        return #ok(token.total_balance - all_locked_value);
      },
    );
  };

  /**
    * @param {StateAccess} state - The state access object.
    * @param {Types.FeeDepositRequest} FeeDepositRequest - The request record to be processed.
    * @returns {Nat} - The amount of free tokens available for fees. Returns 0 if the calculated free amount is negative or if no balance is found.
    */
  public func unlock_token_fee_balance(
    state : StateAccess,
    request : {
      account : Types.Account;
      token : Types.TokenSpec;
      sale_id : Text;
      update_balance : Bool;
    },
  ) : Result.Result<Nat, Types.OrigynError> {
    return switch (Map.get<Types.Account, Map.Map<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>>(state.state.fee_deposit_balances, account_handler, request.account)) {
      case (null) {
        debug if (debug_channel.market) D.print("_access_fee_balance: _access_fee_balance - account not found  " # debug_show (request.account));
        return #err(Types.errors(#content_not_found, "_access_fee_balance - account not found  " # debug_show (request.account), null));
      };
      case (?val) {
        switch (Map.get<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>(val, token_handler, request.token)) {
          case (null) {
            debug if (debug_channel.market) D.print("_access_fee_balance: _access_fee_balance - token not found  " # debug_show (request.token));
            return #err(Types.errors(#content_not_found, "_access_fee_balance - token not found  " # debug_show (request.token), null));
          };
          case (?token) {
            let removed : Nat = Option.get<Nat>(Map.remove<Text, Nat>(token.locks, Map.thash, request.sale_id), 0);

            if (token.total_balance < removed) {
              return #err(Types.errors(#content_not_found, "_access_fee_balance - token.total_balance < removed  " # debug_show (request.token), null));
            };

            if (request.update_balance == true) {
              let new_token = {
                total_balance = token.total_balance - removed : Nat;
                locks = token.locks;
              };

              // update new total balance
              Map.set<Types.TokenSpec, MigrationTypes.Current.FeeDepositDetail>(val, token_handler, request.token, new_token);
            };

            return #ok(token.total_balance);
          };
        };
      };
    };
  };
};
