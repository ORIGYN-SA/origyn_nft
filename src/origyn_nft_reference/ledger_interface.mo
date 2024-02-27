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
    deposit = false;
    sale = false;
    transfer = false;
  };

  let Conversion = MigrationTypes.Current.Conversions;

   /*  
   
   validate deposit was used before we implemented sub accounts. We are leaving it here as it is 
   an example of how one could implement this using dip20 without implementing transferFrom

   public func validateDeposit(host: Principal, deposit : Types.DepositDetail, caller: Principal) : async Types.OrigynBoolResult {
     //D.print("in validate ledger deposit");
     //D.print(Principal.toText(host));
     //D.print(debug_show(deposit));
    let ledger = switch(deposit.token){
        case(#ic(detail)){
            detail;
        };
        case(_){
            return #err(Types.errors(?state.canistergeekLogger,  #improper_interface, "ledger_interface - validate deposit - not ic" # debug_show(deposit), ?caller));
        }
    };
     //D.print(debug_show(canister));
     //D.print(debug_show(block));
    let ledger_actor : DFXTypes.Service = actor(Principal.toText(ledger.canister));

    try{
       
       
        
        
       //D.print("comparing hosts");
        //D.print(debug_show(Blob.fromArray(transfer.to)));
        //D.print(debug_show(Blob.fromArray(AccountIdentifier.fromPrincipal(host, null))));

        if( transfer.to != Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(host, null)))){
           //D.print("Host didnt match");
            return #err(Types.errors(?state.canistergeekLogger,  #validate_trx_wrong_host, "ledger_interface - validate deposit - bad host" # debug_show(deposit) # " should be " # Principal.toText(host), ?caller));
        };

       //D.print("comparing buyer");
       //D.print(debug_show(transfer.from));
        //D.print(debug_show(Blob.fromArray(transfer.from)));
        //D.print(debug_show(AccountIdentifier.toText(transfer.from)));
        
        //D.print(debug_show(Text.decodeUtf8(Blob.fromArray(transfer.from))));
        //D.print(debug_show(#account_id(Opt.get(Text.decodeUtf8(Blob.fromArray(transfer.from)),""))));
       //D.print(debug_show(deposit.buyer));
        if(Types.account_eq(#account_id(Hex.encode(Blob.toArray(transfer.from))), deposit.buyer) == false){
           //D.print("from and buyer didnt match " # debug_show(transfer.from) # " " # debug_show(deposit.buyer));
            return #err(Types.errors(?state.canistergeekLogger,  #validate_deposit_wrong_buyer, "ledger_interface - validate deposit - bad buyer" # debug_show(deposit), ?caller));
        };

        if(Nat64.toNat(transfer.amount.e8s) != deposit.amount){
           //D.print("amount didnt match");
            return #err(Types.errors(?state.canistergeekLogger,  #validate_deposit_wrong_amount, "ledger_interface - validate deposit - bad amount" # debug_show(deposit), ?caller));
        };
    } catch (e){
        return #err(Types.errors(?state.canistergeekLogger,  #validate_deposit_failed, "ledger_interface - validate deposit - ledger throw " # Error.message(e) # debug_show(deposit), ?caller));
    };
     //D.print("returning true");
    return #ok(true);
  }; */

  //moves a deposit from a deposit subaccount to an escrow subaccount
  /**
  * Moves a deposit from a deposit subaccount to an escrow subaccount
  * @param {Principal} host - The canister ID of the ledger that manages the deposit
  * @param {Types.EscrowRequest} escrow - The deposit request to be transferred to an escrow account
  * @param {Principal} caller - The principal that initiated the transfer deposit request
  * @returns {async* Result.Result<{transaction_id: Types.TransactionID; subaccount_info: Types.SubAccountInfo}, Types.OrigynError>} The result of the transfer deposit operation containing the transaction ID and subaccount information if successful, or an error if unsuccessful.
  */
  public func transfer_deposit(host: Principal, escrow : Types.EscrowRequest, caller: Principal) : async* Result.Result<{transaction_id: Types.TransactionID; subaccount_info: Types.SubAccountInfo}, Types.OrigynError> {
    debug if(debug_channel.deposit) D.print("in transfer_deposit ledger deposit");
    debug if(debug_channel.deposit) D.print(Principal.toText(host));
    debug if(debug_channel.deposit) D.print(debug_show(escrow));

     //nyi: extra safety make sure the caller is the buyer(or the network?)
    let escrow_account_info : Types.SubAccountInfo = NFTUtils.get_escrow_account_info({
      amount = escrow.deposit.amount;
      buyer = escrow.deposit.buyer;
      seller = escrow.deposit.seller;
      token = escrow.deposit.token;
      token_id = escrow.token_id;
    }, host);

    let deposit_account = NFTUtils.get_deposit_info(escrow.deposit.buyer, host);

    let #ic(ledger) = escrow.deposit.token else return #err(Types.errors(null,  #improper_interface, "ledger_interface - validate deposit - not ic" # debug_show(escrow), ?caller));

    try {
       //D.print("sending transfer blocks # " # debug_show(escrow.deposit.amount - ledger.fee));

      let result = await* transfer({
          ledger = ledger.canister;
          to = host;
          //do not subract the fee...you need the full amount in the account. User needs to send in the fee as extra.
          //in the future we may want to actualluy add the fee if the buyer is going to pay all fees.
          amount = escrow.deposit.amount;
          fee = Option.get(ledger.fee, 0);
          memo = ?Conversion.candySharedToBytes(#Nat32(Text.hash("com.origyn.nft.escrow_from_deposit" # debug_show(escrow))));
          caller = caller;
          to_subaccount = ?Blob.toArray(escrow_account_info.account.sub_account);
          from_subaccount = ?Blob.toArray(deposit_account.account.sub_account);
      });

      let result_block = switch(result){
        case(#ok(val))val;
        case(#err(err)) return #err(Types.errors(null,  #validate_deposit_failed, "ledger_interface - transfer deposit failed " # debug_show(escrow.deposit) # " " # debug_show(err), ?caller));
      };

      return #ok({transaction_id= result_block; subaccount_info = escrow_account_info});

    } catch (e) return #err(Types.errors(null,  #validate_deposit_failed, "ledger_interface - validate deposit - ledger throw " # Error.message(e) # debug_show(escrow.deposit), ?caller));
  };


  //gets a balance for an escrow account
  /**
  * Gets the balance in an escrow subaccount
  * @param {Principal} host - The canister ID of the ledger that manages the deposit
  * @param {Types.EscrowRequest} escrow - The deposit request to be transferred to an escrow account
  * @param {Principal} caller - The principal that initiated the transfer deposit request
  * @returns {async* Result.Result<{balance: Nat; subaccount_info: Types.SubAccountInfo}, Types.OrigynError>} The balance if succesful.
  */
  public func escrow_balance(host: Principal, escrow : Types.EscrowRequest, caller: Principal) : async* Star.Star<{balance: Nat; subaccount_info: Types.SubAccountInfo}, Types.OrigynError> {
    debug if(debug_channel.deposit) D.print("in escrow_balance ledger deposit");
    debug if(debug_channel.deposit) D.print(Principal.toText(host));
    debug if(debug_channel.deposit) D.print(debug_show(escrow));

     //nyi: extra safety make sure the caller is the buyer(or the network?)
    let escrow_account_info : Types.SubAccountInfo = NFTUtils.get_escrow_account_info({
      amount = escrow.deposit.amount;
      buyer = escrow.deposit.buyer;
      seller = escrow.deposit.seller;
      token = escrow.deposit.token;
      token_id = escrow.token_id;
    }, host);


    let #ic(ledger) = escrow.deposit.token else return #err(#trappable(Types.errors(null,  #improper_interface, "ledger_interface - validate deposit - not ic" # debug_show(escrow), ?caller)));

    try {
       //D.print("sending transfer blocks # " # debug_show(escrow.deposit.amount - ledger.fee));

      debug if(debug_channel.deposit) D.print("getting balance " # debug_show(escrow_account_info));

      let result = await* balance(
        {
          ledger = ledger.canister;
          account = {
            owner = escrow_account_info.account.principal;
            subaccount = ?Blob.toArray(escrow_account_info.account.sub_account);
          };
          caller = caller;
        }
      );

      debug if(debug_channel.deposit) D.print("found balance " # debug_show(result));


      switch(result){
        case(#awaited(val)){return #awaited({balance = val; subaccount_info = escrow_account_info})};
        case(#trappable(val)){return #awaited({balance = val; subaccount_info = escrow_account_info})};
        case(#err(val)) return #err(val);
      };
    } catch (e) return #err(#awaited(Types.errors(null,  #validate_deposit_failed, "ledger_interface - validate deposit - ledger throw " # Error.message(e) # debug_show(escrow.deposit), ?caller)));
  };

  //gets a balance for an fee deposit account
  /**
  * Gets the balance in an fee deposit subaccount
  * @param {Principal} host - The canister ID of the ledger that manages the deposit
  * @param {Types.FeeDepositRequest} escrow - The deposit request to be checked
  * @param {Principal} caller - The principal that initiated the transfer deposit request
  * @returns {async* Star.Star<{balance: Nat; subaccount_info: Types.SubAccountInfo}, Types.OrigynError>} The balance if succesful, or an error if unsuccessful.
  */
  public func fee_deposit_balance(host: Principal, request : Types.FeeDepositRequest, caller: Principal) : async* Star.Star<{balance: Nat; subaccount_info: Types.SubAccountInfo}, Types.OrigynError> {
    debug if(debug_channel.deposit) D.print("in fee_deposit_balance");
    debug if(debug_channel.deposit) D.print(Principal.toText(host));
    debug if(debug_channel.deposit) D.print(debug_show(request));

     //nyi: extra safety make sure the caller is the buyer(or the network?)
    let fee_deposit_account_info : Types.SubAccountInfo = NFTUtils.get_fee_deposit_account_info(
      request.account
    , host);


    let #ic(ledger) = request.token else return #err(#trappable(Types.errors(null,  #improper_interface, "ledger_interface - validate deposit - not ic" # debug_show(request), ?caller)));

    try {
       
      debug if(debug_channel.deposit) D.print("getting balance " # debug_show(fee_deposit_account_info));

      let result = await* balance(
        {
          ledger = ledger.canister;
          account = {
            owner = fee_deposit_account_info.account.principal;
            subaccount = ?Blob.toArray(fee_deposit_account_info.account.sub_account);
          };
          caller = caller;
        }
      );

      debug if(debug_channel.deposit) D.print("found balance " # debug_show(result));


      switch(result){
        case(#awaited(val)){return #awaited({balance = val; subaccount_info = fee_deposit_account_info})};
        case(#trappable(val)){return #awaited({balance = val; subaccount_info = fee_deposit_account_info})};
        case(#err(val)) return #err(val);
      };
    } catch (e) return #err(#awaited(Types.errors(null,  #validate_deposit_failed, "ledger_interface - validate deposit - ledger throw " # Error.message(e) # debug_show(request), ?caller)));
  };

  private func _transfer( host: Principal, escrow : Types.EscrowReceipt, token_id : Text, caller: Principal, from_account_info : Types.SubAccountInfo, to_account_info : Types.SubAccountInfo) : async* Star.Star<(Types.TransactionID, Types.SubAccountInfo, Nat), Types.OrigynError> {
    debug if(debug_channel.sale) D.print("sale info used " # debug_show(to_account_info));

    let ledger = switch(escrow.token){
        case(#ic(detail)){
            detail;
        };
        case(_){
            return #err(#trappable(Types.errors(null,  #improper_interface, "ledger_interface - validate deposit - not ic" # debug_show(escrow), ?caller)));
        }
    };

    let ledger_fee = Option.get(ledger.fee, 0);

    if(escrow.amount <= ledger_fee){
        return #err(#trappable(Types.errors(null,  #improper_interface, "ledger_interface - amount is equal or less than fee - not ic" # debug_show(escrow), ?caller)));
     
    };

    try{
        debug if(debug_channel.sale) D.print("sending transfer blocks # " # debug_show((Nat.sub(escrow.amount, ledger_fee), to_account_info.account.sub_account) ));
        
        let result = await* transfer({
            ledger = ledger.canister;
            to = host;
            amount = escrow.amount - ledger_fee;
            fee = ledger_fee;
            memo = ?Conversion.candySharedToBytes(#Nat32(Text.hash("com.origyn.nft.sale_from_escrow" # debug_show(escrow) # token_id))); // TODO AUSTIN check with austin here, what to do
            caller = caller;
            to_subaccount = ?Blob.toArray(from_account_info.account.sub_account);
            from_subaccount = ?Blob.toArray(to_account_info.account.sub_account);
            //created_at_time = ?{timestamp_nanos = Nat64.fromNat(Int.abs(Time.now()))}
        });

        let result_block = switch(result){
            case(#ok(val)){
                debug if(debug_channel.sale) D.print("sending to sale account was succesful" # debug_show(val));
                val;
            };
            case(#err(err)){
                return #err(#awaited(Types.errors(null,  #validate_deposit_failed, "ledger_interface - transfer deposit failed " # debug_show(escrow) # " " # debug_show(err), ?caller)));
            };
        };

        return #awaited(result_block, to_account_info, Option.get(ledger.fee,0));

    } catch (e){
        return #err(#awaited(Types.errors(null,  #validate_deposit_failed, "ledger_interface - validate deposit - ledger throw " # Error.message(e) # debug_show(escrow), ?caller)));
    };
  };

  /**
  * @param {Principal} host - the principal hosting the ledger
  * @param {Types.EscrowReceipt} escrow - the escrow receipt object
  * @param {Text} token_id - the id of the token
  * @param {Principal} caller - the principal making the call
  * @returns {async* Result.Result<(Types.TransactionID, Types.SubAccountInfo, Nat), Types.OrigynError>} a result object containing the transaction ID, subaccount info, and fee or an error object
  */
  public func transfer_fees( host: Principal, escrow : Types.EscrowReceipt,  token_id : Text, caller: Principal) : async* Star.Star<(Types.TransactionID, Types.SubAccountInfo, Nat), Types.OrigynError> {
    debug if(debug_channel.sale) D.print("in transfer_sale ledger fees");
    debug if(debug_channel.sale) D.print(Principal.toText(host));
    debug if(debug_channel.sale) D.print(debug_show(escrow));

    //nyi: an extra layer of security?

    debug if(debug_channel.sale) D.print("in transfer fees" # token_id # debug_show(Time.now()));

    let basic_info = {
          amount = escrow.amount;
          buyer = escrow.buyer;
          seller = escrow.seller;
          token = escrow.token;
          token_id = escrow.token_id;
      };

    let fees_account_info : Types.SubAccountInfo = NFTUtils.get_fee_deposit_account_info(basic_info.seller, host);
    let sale_account_info = NFTUtils.get_sale_account_info(basic_info, host);

    return await* _transfer(host, escrow, token_id, caller, fees_account_info, sale_account_info);
  };

  //allows a user to withdraw money from a sale
  /**
  * allows a user to withdraw money from a sale
  * @param {Principal} host - the principal hosting the ledger
  * @param {Types.EscrowReceipt} escrow - the escrow receipt object
  * @param {Text} token_id - the id of the token
  * @param {Principal} caller - the principal making the call
  * @returns {async* Result.Result<(Types.TransactionID, Types.SubAccountInfo, Nat), Types.OrigynError>} a result object containing the transaction ID, subaccount info, and fee or an error object
  */
  public func transfer_sale( host: Principal, escrow : Types.EscrowReceipt,  token_id : Text, caller: Principal) : async* Star.Star<(Types.TransactionID, Types.SubAccountInfo, Nat), Types.OrigynError> {
    debug if(debug_channel.sale) D.print("in transfer_sale ledger sale");
    debug if(debug_channel.sale) D.print(Principal.toText(host));
    debug if(debug_channel.sale) D.print(debug_show(escrow));

    debug if(debug_channel.sale) D.print("in transfer sale" # token_id # debug_show(Time.now()));

    let basic_info = {
          amount = escrow.amount;
          buyer = escrow.buyer;
          seller = escrow.seller;
          token = escrow.token;
          token_id = escrow.token_id;
      };

    let escrow_account_info : Types.SubAccountInfo = NFTUtils.get_escrow_account_info(basic_info, host);
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
  private func transfer(request : {
    ledger: Principal;
    to: Principal;
    to_subaccount: ?[Nat8];
    from_subaccount: ?[Nat8];
    amount: Nat;
    fee: Nat;
    memo: ?[Nat8];
    caller: Principal
    }) : async* Result.Result<Types.TransactionID, Types.OrigynError> {
     debug if(debug_channel.transfer) D.print("in transfeledger");
     debug if(debug_channel.transfer) D.print(Principal.toText(request.ledger));

     
    let ledger_actor : DFXTypes.Service = actor(Principal.toText(request.ledger));

    
    let to_account = {owner = request.to; subaccount = request.to_subaccount};
    

                        debug if(debug_channel.transfer) D.print("transfering");
                        debug if(debug_channel.transfer) D.print("from account" # debug_show(request.from_subaccount));
                        debug if(debug_channel.transfer) D.print("to account" # debug_show((to_account)));
    try{
                        debug if(debug_channel.transfer) D.print("sending transfer blocks # " # debug_show(request));
        let result = await ledger_actor.icrc1_transfer({
            to = to_account;
            fee = ?request.fee;
            memo = request.memo; 
            from_subaccount = request.from_subaccount;
            created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
            amount = request.amount});

                            debug if(debug_channel.transfer) D.print("result is " # debug_show(result));
        let result_block = switch(result){
            case(#Ok(val)){
                val;
            };
            case(#Err(err)){
                return #err(Types.errors(null,  #improper_interface, "ledger_interface - transfer failed " # debug_show(request) # " " # debug_show(err), ?request.caller));
            };
        };

        return #ok(#nat(result_block));

    } catch (e){
        return #err(Types.errors(null,  #improper_interface, "ledger_interface - ledger throw " # Error.message(e) # debug_show(request), ?request.caller));
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
  private func balance(request : {
    ledger: Principal;
    account: DFXTypes.Account;
    caller: Principal
    }) : async* Star.Star<Nat, Types.OrigynError> {
     debug if(debug_channel.transfer) D.print("in balance ledger");
     debug if(debug_channel.transfer) D.print(Principal.toText(request.ledger));

     
    let ledger_actor : DFXTypes.Service = actor(Principal.toText(request.ledger));

    
    let from_account = {owner = request.account.owner; subaccount = request.account.subaccount};
    

                        debug if(debug_channel.transfer) D.print("getting balance");
                        debug if(debug_channel.transfer) D.print("from account" # debug_show(request.account));
    try{
                        debug if(debug_channel.transfer) D.print("sending balacne blocks # " # debug_show(request));
        let result = await ledger_actor.icrc1_balance_of(from_account);

                            debug if(debug_channel.transfer) D.print("result is " # debug_show(result));
        

        return #awaited(result);

    } catch (e){
        return #err(#awaited(Types.errors(null,  #improper_interface, "ledger_interface - ledger throw " # Error.message(e) # debug_show(request), ?request.caller)));
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
  public func send_payment_minus_fee(account: Types.Account, token: Types.ICTokenSpec, amount : Nat, sub_account: ?Blob, caller: Principal) : async* Result.Result<{trx_id: Types.TransactionID; fee: Nat}, Types.OrigynError> {
    debug if(debug_channel.transfer) D.print("in send payment deposit");
     
    let ledger : DFXTypes.Service = actor(Principal.toText(token.canister));
    try{
      debug if(debug_channel.transfer) D.print("sending payment" # debug_show((account, sub_account)));

      let account_id = switch(account){
        case(#account_id(val)){
          return #err(Types.errors(null,  #nyi, "ledger_interface - send payment - bad account - Account ID no longer supported. use ICRC1 Account" # debug_show(account), ?caller))
        };
        case(#principal(val)){{
          owner = val;
          subaccount = null;
        }};
        case(#account(val))
        {
          {
            owner = val.owner;
            subaccount = switch(val.sub_account){
              case(null) null;
              case(?val) ?Blob.toArray(val);
            };
          };
        };
        case(_){return #err(Types.errors(null,  #nyi, "ledger_interface - send payment - bad account" # debug_show(account), ?caller));}
      };

      debug if(debug_channel.transfer) D.print("account_id" # debug_show( account_id));

      let token_fee = Option.get(token.fee, 0);

      let result = await ledger.icrc1_transfer({
        to = account_id;
        from_subaccount = switch(sub_account){
          case(null) null;
          case(?val) ?Blob.toArray(val)
        };
        fee = token.fee;
        memo = ?Conversion.candySharedToBytes(#Nat32(Text.hash("com.origyn.nft.out_going_payment"))); 
        created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        amount = amount - token_fee; //many other places assume the token fee is removed here so don't change this
      });

      debug if(debug_channel.transfer) D.print(debug_show(result));

      switch(result){
          case(#Ok(val)) #ok({trx_id = #nat(val); fee = token_fee});
          case(#Err(err)) #err(Types.errors(null,  #nyi, "ledger_interface - send payment - payment failed " # debug_show(err), ?caller));
      };
    } catch (e) return #err(Types.errors(null,  #nyi, "ledger_interface - send payment - payment failed " # Error.message(e), ?caller));}

};
