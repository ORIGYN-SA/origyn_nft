# origyn_nft_reference/ledger_interface

## Class `Ledger_Interface`

``` motoko no-repl
class Ledger_Interface()
```


### Function `transfer_deposit`
``` motoko no-repl
func transfer_deposit(host : Principal, escrow : Types.EscrowRequest, caller : Principal) : async* Result.Result<{ transaction_id : Types.TransactionID; subaccount_info : Types.SubAccountInfo }, Types.OrigynError>
```

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
            return #err(Types.errors(  #improper_interface, "ledger_interface - validate deposit - not ic" # debug_show(deposit), ?caller));
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
            return #err(Types.errors(  #validate_trx_wrong_host, "ledger_interface - validate deposit - bad host" # debug_show(deposit) # " should be " # Principal.toText(host), ?caller));
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
            return #err(Types.errors(  #validate_deposit_wrong_buyer, "ledger_interface - validate deposit - bad buyer" # debug_show(deposit), ?caller));
        };

        if(Nat64.toNat(transfer.amount.e8s) != deposit.amount){
           //D.print("amount didnt match");
            return #err(Types.errors(  #validate_deposit_wrong_amount, "ledger_interface - validate deposit - bad amount" # debug_show(deposit), ?caller));
        };
    } catch (e){
        return #err(Types.errors(  #validate_deposit_failed, "ledger_interface - validate deposit - ledger throw " # Error.message(e) # debug_show(deposit), ?caller));
    };
     //D.print("returning true");
    return #ok(true);
  };
* Moves a deposit from a deposit subaccount to an escrow subaccount
  * @param {Principal} host - The canister ID of the ledger that manages the deposit
  * @param {Types.EscrowRequest} escrow - The deposit request to be transferred to an escrow account
  * @param {Principal} caller - The principal that initiated the transfer deposit request
  * @returns {async* Result.Result<{transaction_id: Types.TransactionID; subaccount_info: Types.SubAccountInfo}, Types.OrigynError>} The result of the transfer deposit operation containing the transaction ID and subaccount information if successful, or an error if unsuccessful.


### Function `escrow_balance`
``` motoko no-repl
func escrow_balance(host : Principal, escrow : Types.EscrowRequest, caller : Principal) : async* Star.Star<{ balance : Nat; subaccount_info : Types.SubAccountInfo }, Types.OrigynError>
```

* Gets the balance in an escrow subaccount
  * @param {Principal} host - The canister ID of the ledger that manages the deposit
  * @param {Types.EscrowRequest} escrow - The deposit request to be transferred to an escrow account
  * @param {Principal} caller - The principal that initiated the transfer deposit request
  * @returns {async* Result.Result<{balance: Nat; subaccount_info: Types.SubAccountInfo}, Types.OrigynError>} The balance if succesful.


### Function `fee_deposit_balance`
``` motoko no-repl
func fee_deposit_balance(host : Principal, request : Types.FeeDepositRequest, caller : Principal) : async* Star.Star<{ balance : Nat; subaccount_info : Types.SubAccountInfo }, Types.OrigynError>
```

* Gets the balance in an fee deposit subaccount
  * @param {Principal} host - The canister ID of the ledger that manages the deposit
  * @param {Types.FeeDepositRequest} escrow - The deposit request to be checked
  * @param {Principal} caller - The principal that initiated the transfer deposit request
  * @returns {async* Star.Star<{balance: Nat; subaccount_info: Types.SubAccountInfo}, Types.OrigynError>} The balance if succesful, or an error if unsuccessful.


### Function `transfer_sale`
``` motoko no-repl
func transfer_sale(host : Principal, escrow : Types.EscrowReceipt, token_id : Text, caller : Principal) : async* Star.Star<(Types.TransactionID, Types.SubAccountInfo, Nat), Types.OrigynError>
```

* allows a user to withdraw money from a sale
  * @param {Principal} host - the principal hosting the ledger
  * @param {Types.EscrowReceipt} escrow - the escrow receipt object
  * @param {Text} token_id - the id of the token
  * @param {Principal} caller - the principal making the call
  * @returns {async* Result.Result<(Types.TransactionID, Types.SubAccountInfo, Nat), Types.OrigynError>} a result object containing the transaction ID, subaccount info, and fee or an error object


### Function `send_payment_minus_fee`
``` motoko no-repl
func send_payment_minus_fee(account : Types.Account, token : Types.ICTokenSpec, amount : Nat, sub_account : ?Blob, caller : Principal) : async* Result.Result<{ trx_id : Types.TransactionID; fee : Nat }, Types.OrigynError>
```

* Sends a payment and withdraws a fee from an account.
  *
  * @param {object} account - An object containing information about the account.
  * @param {Types.ICTokenSpec} token - The token to be transferred.
  * @param {number} amount - The amount of the token to be transferred.
  * @param {Array.<number>} [sub_account=null] - The subaccount associated with the account.
  * @param {Principal} caller - The principal of the caller.
  * @returns {Promise.<Result.Result>} A promise that returns either an ok result containing the transaction ID and the fee of the transfer or an error containing information about the failed transfer.
