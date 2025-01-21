import Blob "mo:base/Blob";
import D "mo:base/Debug";
import Error "mo:base/Error";
import Int "mo:base/Int";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Star "mo:star/star";

import AccountIdentifier "mo:principalmo/AccountIdentifier";
import Hex "mo:encoding/Hex";

import DFXTypes "dfxtypes";
import NFTUtils "utils";
import Types "types";
import MigrationTypes "./migrations/types";

class Ledger_Interface() {

  //this file provides services around moving tokens around a standard ledger(ICP/OGY)

  let debug_channel = {
    deposit = true;
    sale = true;
    transfer = true;
  };

  let Conversion = MigrationTypes.Current.Conversions;

  //moves a deposit from a deposit subaccount to an escrow subaccount
  /**
  * Moves a deposit from a deposit subaccount to an escrow subaccount
  * @param {Principal} host - The canister ID of the ledger that manages the deposit
  * @param {Types.EscrowRequest} escrow - The deposit request to be transferred to an escrow account
  * @param {Principal} caller - The principal that initiated the transfer deposit request
  * @returns {async* Result.Result<{transaction_id: Types.TransactionID; subaccount_info: Types.Account}, Types.OrigynError>} The result of the transfer deposit operation containing the transaction ID and subaccount information if successful, or an error if unsuccessful.
  */
  public func transfer_deposit(host : Principal, escrow : Types.EscrowRequest, caller : Principal) : async* Result.Result<{ transaction_id : Types.TransactionID; subaccount_info : Types.Account }, Types.OrigynError> {
    debug if (debug_channel.deposit) D.print("in transfer_deposit ledger deposit");
    debug if (debug_channel.deposit) D.print(Principal.toText(host));
    debug if (debug_channel.deposit) D.print(debug_show (escrow));

    //nyi: extra safety make sure the caller is the buyer(or the network?)
    let escrow_account_info : Types.Account = NFTUtils.get_escrow_account_info(
      {
        amount = escrow.deposit.amount;
        buyer = escrow.deposit.buyer;
        seller = escrow.deposit.seller;
        token = escrow.deposit.token;
        token_id = escrow.token_id;
      },
      host,
    );

    let deposit_account = NFTUtils.get_deposit_info(escrow.deposit.buyer, host);

    let #ic(ledger) = escrow.deposit.token else return #err(Types.errors(#improper_interface, "ledger_interface - validate deposit - not ic" # debug_show (escrow), ?caller));

    try {
      //D.print("sending transfer blocks # " # debug_show(escrow.deposit.amount - ledger.fee));

      let result = await* transfer({
        ledger = ledger.canister;
        to = host;
        //do not subract the fee...you need the full amount in the account. User needs to send in the fee as extra.
        //in the future we may want to actualluy add the fee if the buyer is going to pay all fees.
        amount = escrow.deposit.amount;
        fee = Option.get(ledger.fee, 0);
        memo = ?Conversion.candySharedToBytes(#Nat32(Text.hash("com.origyn.nft.escrow_from_deposit" # debug_show (escrow))));
        caller = caller;
        to_subaccount = switch (escrow_account_info.subaccount) {
          case (null) { null };
          case (?val) { ?Blob.toArray(val) };
        };
        from_subaccount = switch (deposit_account.subaccount) {
          case (null) { null };
          case (?val) { ?Blob.toArray(val) };
        };
      });

      let result_block = switch (result) {
        case (#ok(val)) val;
        case (#err(err)) return #err(Types.errors(#validate_deposit_failed, "ledger_interface - transfer deposit failed " # debug_show (escrow.deposit) # " " # debug_show (err), ?caller));
      };

      return #ok({
        transaction_id = result_block;
        subaccount_info = escrow_account_info;
      });

    } catch (e) return #err(Types.errors(#validate_deposit_failed, "ledger_interface - validate deposit - ledger throw " # Error.message(e) # debug_show (escrow.deposit), ?caller));
  };

  //gets a balance for an escrow account
  /**
  * Gets the balance in an escrow subaccount
  * @param {Principal} host - The canister ID of the ledger that manages the deposit
  * @param {Types.EscrowRequest} escrow - The deposit request to be transferred to an escrow account
  * @param {Principal} caller - The principal that initiated the transfer deposit request
  * @returns {async* Result.Result<{balance: Nat; subaccount_info: Types.Account}, Types.OrigynError>} The balance if succesful.
  */
  public func escrow_balance(host : Principal, escrow : Types.EscrowRequest, caller : Principal) : async* Star.Star<{ balance : Nat; subaccount_info : Types.Account }, Types.OrigynError> {
    debug if (debug_channel.deposit) D.print("in escrow_balance ledger deposit");
    debug if (debug_channel.deposit) D.print(Principal.toText(host));
    debug if (debug_channel.deposit) D.print(debug_show (escrow));

    //nyi: extra safety make sure the caller is the buyer(or the network?)
    let escrow_account_info : Types.Account = NFTUtils.get_escrow_account_info(
      {
        amount = escrow.deposit.amount;
        buyer = escrow.deposit.buyer;
        seller = escrow.deposit.seller;
        token = escrow.deposit.token;
        token_id = escrow.token_id;
      },
      host,
    );

    let #ic(ledger) = escrow.deposit.token else return #err(#trappable(Types.errors(#improper_interface, "ledger_interface - validate deposit - not ic" # debug_show (escrow), ?caller)));

    try {
      //D.print("sending transfer blocks # " # debug_show(escrow.deposit.amount - ledger.fee));

      debug if (debug_channel.deposit) D.print("getting balance " # debug_show (escrow_account_info));

      let result = await* balance({
        ledger = ledger.canister;
        account = {
          owner = escrow_account_info.owner;
          subaccount = switch (escrow_account_info.subaccount) {
            case (null) { null };
            case (?val) { ?Blob.toArray(val) };
          };
        };
        caller = caller;
      });

      debug if (debug_channel.deposit) D.print("found balance " # debug_show (result));

      switch (result) {
        case (#awaited(val)) {
          return #awaited({
            balance = val;
            subaccount_info = escrow_account_info;
          });
        };
        case (#trappable(val)) {
          return #awaited({
            balance = val;
            subaccount_info = escrow_account_info;
          });
        };
        case (#err(val)) return #err(val);
      };
    } catch (e) return #err(#awaited(Types.errors(#validate_deposit_failed, "ledger_interface - validate deposit - ledger throw " # Error.message(e) # debug_show (escrow.deposit), ?caller)));
  };

  //gets a balance for an fee deposit account
  /**
  * Gets the balance in an fee deposit subaccount
  * @param {Principal} host - The canister ID of the ledger that manages the deposit
  * @param {Types.FeeDepositRequest} escrow - The deposit request to be checked
  * @param {Principal} caller - The principal that initiated the transfer deposit request
  * @returns {async* Star.Star<{balance: Nat; subaccount_info: Types.Account}, Types.OrigynError>} The balance if succesful, or an error if unsuccessful.
  */
  public func fee_deposit_balance(host : Principal, request : Types.FeeDepositRequest, caller : Principal) : async* Star.Star<{ balance : Nat; subaccount_info : Types.Account }, Types.OrigynError> {
    debug if (debug_channel.deposit) D.print("in fee_deposit_balance");
    debug if (debug_channel.deposit) D.print(Principal.toText(host));
    debug if (debug_channel.deposit) D.print(debug_show (request));

    //nyi: extra safety make sure the caller is the buyer(or the network?)
    let fee_deposit_account_info : Types.Account = NFTUtils.get_fee_deposit_account_info(
      request.account,
      host,
    );

    let #ic(ledger) = request.token else return #err(#trappable(Types.errors(#improper_interface, "ledger_interface - validate deposit - not ic" # debug_show (request), ?caller)));

    try {

      debug if (debug_channel.deposit) D.print("getting balance " # debug_show (fee_deposit_account_info));

      let result = await* balance({
        ledger = ledger.canister;
        account = {
          owner = fee_deposit_account_info.owner;
          subaccount = switch (fee_deposit_account_info.subaccount) {
            case (null) { null };
            case (?val) { ?Blob.toArray(val) };
          };
        };
        caller = caller;
      });

      debug if (debug_channel.deposit) D.print("found balance " # debug_show (result));

      switch (result) {
        case (#awaited(val)) {
          return #awaited({
            balance = val;
            subaccount_info = fee_deposit_account_info;
          });
        };
        case (#trappable(val)) {
          return #awaited({
            balance = val;
            subaccount_info = fee_deposit_account_info;
          });
        };
        case (#err(val)) return #err(val);
      };
    } catch (e) return #err(#awaited(Types.errors(#validate_deposit_failed, "ledger_interface - validate deposit - ledger throw " # Error.message(e) # debug_show (request), ?caller)));
  };

  private func _transfer(host : Principal, escrow : Types.EscrowReceipt, token_id : Text, caller : Principal, from_account_info : Types.Account, to_account_info : Types.Account) : async* Star.Star<(Types.TransactionID, Types.Account, Nat), Types.OrigynError> {
    debug if (debug_channel.sale) D.print("sale info used " # debug_show (to_account_info));

    let ledger = switch (escrow.token) {
      case (#ic(detail)) {
        detail;
      };
      case (_) {
        return #err(#trappable(Types.errors(#improper_interface, "ledger_interface - validate deposit - not ic" # debug_show (escrow), ?caller)));
      };
    };

    let ledger_fee = Option.get(ledger.fee, 0);

    if (escrow.amount <= ledger_fee) {
      return #err(#trappable(Types.errors(#improper_interface, "ledger_interface - amount is equal or less than fee - not ic" # debug_show (escrow), ?caller)));

    };

    try {
      debug if (debug_channel.sale) D.print("sending transfer blocks # " # debug_show ((Nat.sub(escrow.amount, ledger_fee), to_account_info.subaccount)));

      let result = await* transfer({
        ledger = ledger.canister;
        to = host;
        amount = escrow.amount - ledger_fee;
        fee = ledger_fee;
        memo = ?Conversion.candySharedToBytes(#Nat32(Text.hash("com.origyn.nft.sale_from_escrow" # debug_show (escrow) # token_id))); // TODO AUSTIN check with austin here, what to do
        caller = caller;
        to_subaccount = switch (to_account_info.subaccount) {
          case (null) { null };
          case (?val) { ?Blob.toArray(val) };
        };
        from_subaccount = switch (from_account_info.subaccount) {
          case (null) { null };
          case (?val) { ?Blob.toArray(val) };
        };
        //created_at_time = ?{timestamp_nanos = Nat64.fromNat(Int.abs(Time.now()))}
      });

      let result_block = switch (result) {
        case (#ok(val)) {
          debug if (debug_channel.sale) D.print("sending to sale account was succesful" # debug_show (val));
          val;
        };
        case (#err(err)) {
          debug if (debug_channel.sale) D.print("ERROR : transfer deposit failed" # debug_show (escrow) # " " # debug_show (err));
          return #err(#awaited(Types.errors(#validate_deposit_failed, "ledger_interface - transfer deposit failed " # debug_show (escrow) # " " # debug_show (err), ?caller)));
        };
      };

      return #awaited(result_block, to_account_info, Option.get(ledger.fee, 0));

    } catch (e) {
      debug if (debug_channel.sale) D.print("ERROR : transfer deposit ledger throw" # Error.message(e) # debug_show (escrow));
      return #err(#awaited(Types.errors(#validate_deposit_failed, "ledger_interface - validate deposit - ledger throw " # Error.message(e) # debug_show (escrow), ?caller)));
    };
  };

  //allows a user to withdraw money from a sale
  /**
  * allows a user to withdraw money from a sale
  * @param {Principal} host - the principal hosting the ledger
  * @param {Types.EscrowReceipt} escrow - the escrow receipt object
  * @param {Text} token_id - the id of the token
  * @param {Principal} caller - the principal making the call
  * @returns {async* Result.Result<(Types.TransactionID, Types.Account, Nat), Types.OrigynError>} a result object containing the transaction ID, subaccount info, and fee or an error object
  */
  public func transfer_sale(host : Principal, escrow : Types.EscrowReceipt, token_id : Text, caller : Principal) : async* Star.Star<(Types.TransactionID, Types.Account, Nat), Types.OrigynError> {
    debug if (debug_channel.sale) D.print("in transfer_sale ledger sale");
    debug if (debug_channel.sale) D.print(Principal.toText(host));
    debug if (debug_channel.sale) D.print(debug_show (escrow));

    debug if (debug_channel.sale) D.print("in transfer sale" # token_id # debug_show (Time.now()));

    let basic_info = {
      amount = escrow.amount;
      buyer = escrow.buyer;
      seller = escrow.seller;
      token = escrow.token;
      token_id = escrow.token_id;
    };

    let escrow_account_info : Types.Account = NFTUtils.get_escrow_account_info(basic_info, host);
    let sale_account_info = NFTUtils.get_sale_account_info(basic_info, host);

    return await* _transfer(host, escrow, token_id, caller, escrow_account_info, sale_account_info);
  };

  //a raw transfer
  /**
  * Transfers an amount of a specified token from a specified `from_subaccount` to a specified `to_subaccount` on a specified ledger.
  *
  * @param {object} request - An object containing details about the transfer.
  * @param {Principal} request.ledger - The ledger to which the transfer is to be made.
  * @param {Principal} request.to - The principal of the account to which the transfer is to be made.
  * @param {Array.<number>} [request.to_subaccount=null] - The subaccount of the account to which the transfer is to be made.
  * @param {Array.<number>} [request.from_subaccount=null] - The subaccount of the account from which the transfer is to be made.
  * @param {number} request.amount - The amount of the token to be transferred.
  * @param {number} request.fee - The fee associated with the token to be transferred.
  * @param {Array.<number>} [request.memo=null] - The memo associated with the transfer.
  * @param {Principal} request.caller - The principal of the caller.
  * @returns {Promise.<Result.Result>} A promise that returns either an ok result containing the transaction ID of the transfer or an error containing information about the failed transfer.
  */
  private func transfer(
    request : {
      ledger : Principal;
      to : Principal;
      to_subaccount : ?[Nat8];
      from_subaccount : ?[Nat8];
      amount : Nat;
      fee : Nat;
      memo : ?[Nat8];
      caller : Principal;
    }
  ) : async* Result.Result<Types.TransactionID, Types.OrigynError> {
    debug if (debug_channel.transfer) D.print("in transfeledger");
    debug if (debug_channel.transfer) D.print(Principal.toText(request.ledger));

    let ledger_actor : DFXTypes.Service = actor (Principal.toText(request.ledger));

    let to_account = { owner = request.to; subaccount = request.to_subaccount };

    debug if (debug_channel.transfer) D.print("transfering");
    debug if (debug_channel.transfer) D.print("from account" # debug_show (request.from_subaccount));
    debug if (debug_channel.transfer) D.print("to account" # debug_show ((to_account)));
    try {
      debug if (debug_channel.transfer) D.print("sending transfer blocks # " # debug_show (request));
      let result = await ledger_actor.icrc1_transfer({
        to = to_account;
        fee = ?request.fee;
        memo = request.memo;
        from_subaccount = request.from_subaccount;
        created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        amount = request.amount;
      });

      debug if (debug_channel.transfer) D.print("result is " # debug_show (result));
      let result_block = switch (result) {
        case (#Ok(val)) {
          val;
        };
        case (#Err(err)) {
          return #err(Types.errors(#improper_interface, "ledger_interface - transfer failed " # debug_show (request) # " " # debug_show (err), ?request.caller));
        };
      };

      return #ok(#nat(result_block));

    } catch (e) {
      return #err(Types.errors(#improper_interface, "ledger_interface - ledger throw " # Error.message(e) # debug_show (request), ?request.caller));
    };

  };

  //a raw balance check
  /**
  * Get the balance of a subaccount
  *
  * @param {object} request - An object containing details about the transfer.
  * @param {Principal} request.ledger - The ledger to which the transfer is to be made.
  * @param {Principal} request.from - The principal of the account to which the balance is to be queried.
  * @param {Array.<number>} [request.from_subaccount=null] - The subaccount of the account from which the balance is to be queried.
  * @returns {Promise.<Result.Result>} A promise that returns either an ok result containing the transaction ID of the transfer or an error containing information about the failed transfer.
  */
  private func balance(
    request : {
      ledger : Principal;
      account : DFXTypes.Account;
      caller : Principal;
    }
  ) : async* Star.Star<Nat, Types.OrigynError> {
    debug if (debug_channel.transfer) D.print("in balance ledger");
    debug if (debug_channel.transfer) D.print(Principal.toText(request.ledger));

    let ledger_actor : DFXTypes.Service = actor (Principal.toText(request.ledger));

    let from_account = {
      owner = request.account.owner;
      subaccount = request.account.subaccount;
    };

    debug if (debug_channel.transfer) D.print("getting balance");
    debug if (debug_channel.transfer) D.print("from account" # debug_show (request.account));
    try {
      debug if (debug_channel.transfer) D.print("sending balacne blocks # " # debug_show (request));
      let result = await ledger_actor.icrc1_balance_of(from_account);

      debug if (debug_channel.transfer) D.print("result is " # debug_show (result));

      return #awaited(result);

    } catch (e) {
      return #err(#awaited(Types.errors(#improper_interface, "ledger_interface - ledger throw " # Error.message(e) # debug_show (request), ?request.caller)));
    };

  };

  //sends a payment and withdraws a fee
  /**
  * Sends a payment and withdraws a fee from an account.
  *
  * @param {object} account - An object containing information about the account.
  * @param {Types.ICTokenSpec} token - The token to be transferred.
  * @param {number} amount - The amount of the token to be transferred.
  * @param {Array.<number>} [sub_account=null] - The subaccount associated with the account.
  * @param {Principal} caller - The principal of the caller.
  * @returns {Promise.<Result.Result>} A promise that returns either an ok result containing the transaction ID and the fee of the transfer or an error containing information about the failed transfer.
  */
  public func send_payment_minus_fee(account : Types.Account, token : Types.ICTokenSpec, amount : Nat, sub_account : ?Blob, caller : Principal) : async* Result.Result<{ trx_id : Types.TransactionID; fee : Nat }, Types.OrigynError> {
    debug if (debug_channel.transfer) D.print("in send payment deposit");

    let ledger : DFXTypes.Service = actor (Principal.toText(token.canister));
    try {
      debug if (debug_channel.transfer) D.print("sending payment" # debug_show ((account, sub_account)));

      let account_id = {
        owner = account.owner;
        subaccount = switch (account.subaccount) {
          case (null) null;
          case (?val) ?Blob.toArray(val);
        };
      };

      debug if (debug_channel.transfer) D.print("account_id" # debug_show (account_id));

      let token_fee = Option.get(token.fee, 0);

      let result = await ledger.icrc1_transfer({
        to = account_id;
        from_subaccount = switch (sub_account) {
          case (null) null;
          case (?val) ?Blob.toArray(val);
        };
        fee = token.fee;
        memo = ?Conversion.candySharedToBytes(#Nat32(Text.hash("com.origyn.nft.out_going_payment")));
        created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        amount = amount - token_fee; //many other places assume the token fee is removed here so don't change this
      });

      debug if (debug_channel.transfer) D.print(debug_show (result));

      switch (result) {
        case (#Ok(val)) #ok({ trx_id = #nat(val); fee = token_fee });
        case (#Err(err)) #err(Types.errors(#nyi, "ledger_interface - send payment - payment failed " # debug_show (err), ?caller));
      };
    } catch (e) return #err(Types.errors(#nyi, "ledger_interface - send payment - payment failed " # Error.message(e), ?caller));
  };

};
