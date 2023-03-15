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

import Conversion "mo:candy_0_1_12/conversion";

import AccountIdentifier "mo:principalmo/AccountIdentifier";
import Hex "mo:encoding/Hex";

import DFXTypes "dfxtypes";
import NFTUtils "utils";
import Types "types";

class Ledger_Interface() {

  //this file provides services around moving tokens around a standard ledger(ICP/OGY)

  let debug_channel = {
    deposit = false;
    sale = false;
    transfer = false;
  };

   /*  
   
   validate deposit was used before we implemented sub accounts. We are leaving it here as it is 
   an example of how one could implement this using dip20 without implementing transferFrom

   public func validateDeposit(host: Principal, deposit : Types.DepositDetail, caller: Principal) : async Result.Result<Bool, Types.OrigynError> {
     //D.print("in validate ledger deposit");
     //D.print(Principal.toText(host));
     //D.print(debug_show(deposit));
    let ledger = switch(deposit.token){
        case(#ic(detail)){
            detail;
        };
        case(_){
            return #err(Types.errors(#improper_interface, "ledger_interface - validate deposit - not ic" # debug_show(deposit), ?caller));
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
            return #err(Types.errors(#validate_trx_wrong_host, "ledger_interface - validate deposit - bad host" # debug_show(deposit) # " should be " # Principal.toText(host), ?caller));
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
            return #err(Types.errors(#validate_deposit_wrong_buyer, "ledger_interface - validate deposit - bad buyer" # debug_show(deposit), ?caller));
        };

        if(Nat64.toNat(transfer.amount.e8s) != deposit.amount){
           //D.print("amount didnt match");
            return #err(Types.errors(#validate_deposit_wrong_amount, "ledger_interface - validate deposit - bad amount" # debug_show(deposit), ?caller));
        };
    } catch (e){
        return #err(Types.errors(#validate_deposit_failed, "ledger_interface - validate deposit - ledger throw " # Error.message(e) # debug_show(deposit), ?caller));
    };
     //D.print("returning true");
    return #ok(true);
  }; */

  //moves a deposit from a deposit subaccount to an escrow subaccount
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

    let ledger = switch(escrow.deposit.token){
        case(#ic(detail)) detail;
        case(_) return #err(Types.errors(#improper_interface, "ledger_interface - validate deposit - not ic" # debug_show(escrow), ?caller));
    };

    try {
       //D.print("sending transfer blocks # " # debug_show(escrow.deposit.amount - ledger.fee));

      let result = await* transfer({
          ledger = ledger.canister;
          to = host;
          //do not subract the fee...you need the full amount in the account. User needs to send in the fee as extra.
          //in the future we may want to actualluy add the fee if the buyer is going to pay all fees.
          amount = escrow.deposit.amount;
          fee = ledger.fee;
          memo = ?Conversion.valueToBytes(#Nat32(Text.hash("com.origyn.nft.escrow_from_deposit" # debug_show(escrow))));
          caller = caller;
          to_subaccount = ?Blob.toArray(escrow_account_info.account.sub_account);
          from_subaccount = ?Blob.toArray(deposit_account.account.sub_account);
      });

      let result_block = switch(result){
        case(#ok(val))val;
        case(#err(err)) return #err(Types.errors(#validate_deposit_failed, "ledger_interface - transfer deposit failed " # debug_show(escrow.deposit) # " " # debug_show(err), ?caller));
      };

      return #ok({transaction_id= result_block; subaccount_info = escrow_account_info});

    } catch (e) return #err(Types.errors(#validate_deposit_failed, "ledger_interface - validate deposit - ledger throw " # Error.message(e) # debug_show(escrow.deposit), ?caller));
  };

  //allows a user to withdraw money from a sale
  public func transfer_sale(host: Principal, escrow : Types.EscrowReceipt,  token_id : Text, caller: Principal) : async* Result.Result<(Types.TransactionID, Types.SubAccountInfo, Nat), Types.OrigynError> {
                    debug if(debug_channel.sale) D.print("in transfer_sale ledger sale");
                    debug if(debug_channel.sale) D.print(Principal.toText(host));
                    debug if(debug_channel.sale) D.print(debug_show(escrow));

     //nyi: an extra layer of security?

     D.print("in transfer sale" # token_id # debug_show(Time.now()));

     let basic_info = {
            amount = escrow.amount;
            buyer = escrow.buyer;
            seller = escrow.seller;
            token = escrow.token;
            token_id = escrow.token_id;
        };

     let escrow_account_info : Types.SubAccountInfo = NFTUtils.get_escrow_account_info(basic_info, host);

    let sale_account_info = NFTUtils.get_sale_account_info(basic_info, host);

                         debug if(debug_channel.sale) D.print("sale info used " # debug_show(sale_account_info));

    let ledger = switch(escrow.token){
        case(#ic(detail)){
            detail;
        };
        case(_){
            return #err(Types.errors(#improper_interface, "ledger_interface - validate deposit - not ic" # debug_show(escrow), ?caller));
        }
    };

    if(escrow.amount <= ledger.fee){
        return #err(Types.errors(#improper_interface, "ledger_interface - amount is equal or less than fee - not ic" # debug_show(escrow), ?caller));
     
    };

    try{
                         debug if(debug_channel.sale) D.print("sending transfer blocks # " # debug_show((Nat.sub(escrow.amount,ledger.fee), sale_account_info.account.sub_account) ));

        D.print("memo will be com.origyn.nft.sale_from_escrow" # debug_show(escrow) # token_id);
        let result = await* transfer({
            ledger = ledger.canister;
            to = host;
            amount = escrow.amount - ledger.fee;
            fee = ledger.fee;
            memo = ?Conversion.valueToBytes(#Nat32(Text.hash("com.origyn.nft.sale_from_escrow" # debug_show(escrow) # token_id)));
            caller = caller;
            to_subaccount = ?Blob.toArray(sale_account_info.account.sub_account);
            from_subaccount = ?Blob.toArray(escrow_account_info.account.sub_account);
            //created_at_time = ?{timestamp_nanos = Nat64.fromNat(Int.abs(Time.now()))}
        });

        let result_block = switch(result){
            case(#ok(val)){
                                     debug if(debug_channel.sale) D.print("sending to sale account was succesful" # debug_show(val));
                val;
            };
            case(#err(err)){
                return #err(Types.errors(#validate_deposit_failed, "ledger_interface - transfer deposit failed " # debug_show(escrow) # " " # debug_show(err), ?caller));
            };
        };

        return #ok(result_block, sale_account_info, ledger.fee);

    } catch (e){
        return #err(Types.errors(#validate_deposit_failed, "ledger_interface - validate deposit - ledger throw " # Error.message(e) # debug_show(escrow), ?caller));
    };
  };


  //a raw transfer
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
     D.print("in transfeledger");
     D.print(Principal.toText(request.ledger));

     
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
                return #err(Types.errors(#improper_interface, "ledger_interface - transfer failed " # debug_show(request) # " " # debug_show(err), ?request.caller));
            };
        };

        return #ok(#nat(result_block));

    } catch (e){
        return #err(Types.errors(#improper_interface, "ledger_interface - ledger throw " # Error.message(e) # debug_show(request), ?request.caller));
    };
   
  };

  //sends a payment and withdraws a fee
  public func send_payment_minus_fee(account: Types.Account, token: Types.ICTokenSpec, amount : Nat, sub_account: ?Blob, caller: Principal) : async* Result.Result<{trx_id: Types.TransactionID; fee: Nat}, Types.OrigynError> {
    debug if(debug_channel.transfer) D.print("in send payment deposit");
     
    let ledger : DFXTypes.Service = actor(Principal.toText(token.canister));
    try{
      debug if(debug_channel.transfer) D.print("sending payment" # debug_show((account, sub_account)));

      let account_id = switch(account){
        case(#account_id(val)){
          return #err(Types.errors(#nyi, "ledger_interface - send payment - bad account - Account ID no longer supported. use ICRC1 Account" # debug_show(account), ?caller))
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
        case(_){return #err(Types.errors(#nyi, "ledger_interface - send payment - bad account" # debug_show(account), ?caller));}
      };

      debug if(debug_channel.transfer) D.print("account_id" # debug_show( account_id));

      let result = await ledger.icrc1_transfer({
        to = account_id;
        from_subaccount = switch(sub_account){
          case(null) null;
          case(?val) ?Blob.toArray(val)
        };
        fee = ?token.fee;
        memo = ?Conversion.valueToBytes(#Nat32(Text.hash("com.origyn.nft.out_going_payment"))); 
        created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        amount = amount - token.fee; //many other places assume the token fee is removed here so don't change this
      });

      debug if(debug_channel.transfer) D.print(debug_show(result));

      switch(result){
          case(#Ok(val)) #ok({trx_id = #nat(val); fee = token.fee});
          case(#Err(err)) #err(Types.errors(#nyi, "ledger_interface - send payment - payment failed " # debug_show(err), ?caller));
      };
    } catch (e) return #err(Types.errors(#nyi, "ledger_interface - send payment - payment failed " # Error.message(e), ?caller));}

};
