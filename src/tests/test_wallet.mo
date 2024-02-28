import AccountIdentifier "mo:principalmo/AccountIdentifier";

import D "mo:base/Debug";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";
import Nat32 "mo:base/Nat32";
import Buffer "mo:base/Buffer";
import Types "../origyn_nft_reference/types";
import SaleTypes "../origyn_sale_reference/types";
import DFXTypes "../origyn_nft_reference/dfxtypes";

import MigrationTypes "../origyn_nft_reference/migrations/types";
import MigrationsStorage "../origyn_nft_reference/migrations_storage";

shared (deployer) actor class test_wallet() = this {

  let CandyTypes = MigrationTypes.Current.CandyTypes;
  let Conversions = MigrationTypes.Current.Conversions;
  let Properties = MigrationTypes.Current.Properties;
  let Workspace = MigrationTypes.Current.Workspace;

  private var DAY_LENGTH = 60 * 60 * 24 * 10 ** 9;

  let debug_channel = {
    throws = false;
    deposit_info = true;
  };

  public type Operation = {
    #mint;
    #burn;
    #transfer;
    #transferFrom;
    #approve;
  };
  public type TransactionStatus = {
    #succeeded;
    #inprogress;
    #failed;
  };

  public type TxReceipt = {
    #Ok : Nat;
    #Err : {
      #InsufficientAllowance;
      #InsufficientBalance;
      #ErrorOperationStyle;
      #Unauthorized;
      #LedgerTrap;
      #ErrorTo;
      #Other : Text;
      #BlockUsed;
      #AmountTooSmall;
    };
  };

  public type TxRecord = {
    caller : ?Principal;
    op : Operation;
    index : Nat;
    from : Principal;
    to : Principal;
    amount : Nat;
    fee : Nat;
    timestamp : Time.Time;
    status : TransactionStatus;
  };

  public type AccountBalanceArgs = {
    account : Blob;
  };

  public type Tokens = {
    e8s : Nat64;
  };

  public type ledgerService = actor {
    account_balance : query (AccountBalanceArgs) -> async Tokens;
    transfer : (to : Principal, value : Nat) -> async TxReceipt;
    getTransaction : (id : Nat) -> async TxRecord;
    approve : (spender : Principal, value : Nat) -> async TxReceipt;
    transferFrom : (from : Principal, to : Principal, value : Nat) -> async TxReceipt;
  };

  public shared func try_get_chunk(canister : Principal, token_id : Text, library_id : Text, chunk : Nat) : async Result.Result<Blob, Text> {

    let acanister : Types.Service = actor (Principal.toText(canister));
    switch (await acanister.chunk_nft_origyn({ token_id = token_id; library_id = library_id; chunk = ?chunk })) {
      case (#ok(result)) {
        switch (result) {
          case (#remote(redirect)) { return #err("found remote item") };
          case (#chunk(result)) return #ok(result.content);
        };

      };
      case (#err(theerror)) {
        return #err("An error occured: " # debug_show (theerror));
      };
    };

  };

  public shared func try_get_nft(canister : Principal, token_id : Text) : async Types.NFTInfoResult {

    let acanister : Types.Service = actor (Principal.toText(canister));
    switch (await acanister.nft_origyn(token_id)) {
      case (#ok(result)) {
        //D.print("Retrieved an nft from a wallet");
        //D.print(debug_show(result));
        return #ok(result);

      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared func try_publish_meta(canister : Principal) : async Types.OrigynTextResult {

    let acanister : Types.Service = actor (Principal.toText(canister));
    let stage = await acanister.stage_nft_origyn({
      metadata = #Class([
        { name = "id"; value = #Text("1"); immutable = true },
        { name = "primary_asset"; value = #Text("page"); immutable = false },
        { name = "preview"; value = #Text("page"); immutable = true },
        { name = "experience"; value = #Text("page"); immutable = true },
        {
          name = "library";
          value = #Array([
            #Class([
              { name = "id"; value = #Text("page"); immutable = true },
              { name = "title"; value = #Text("page"); immutable = true },
              {
                name = "location_type";
                value = #Text("canister");
                immutable = true;
              },
              {
                name = "location";
                value = #Text("https://" # Principal.toText(Principal.fromActor(acanister)) # ".raw.icp0.io/_/1/_/page");
                immutable = true;
              },
              {
                name = "content_type";
                value = #Text("text/html; charset=UTF-8");
                immutable = true;
              },
              {
                name = "content_hash";
                value = #Bytes([0, 0, 0, 0]);
                immutable = true;
              },
              { name = "size"; value = #Nat(4); immutable = true },
              { name = "sort"; value = #Nat(0); immutable = true },
            ])
          ]);
          immutable = true;
        },
        {
          name = "owner";
          value = #Principal(Principal.fromActor(acanister));
          immutable = false;
        },
      ]);
    });

    switch (stage) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared func try_publish_change(canister : Principal) : async Types.OrigynTextResult {

    let acanister : Types.Service = actor (Principal.toText(canister));
    let stage = await acanister.stage_nft_origyn({
      metadata = #Class([
        { name = "id"; value = #Text("1"); immutable = true },
        { name = "primary_asset"; value = #Text("page2"); immutable = false },
      ]);
    });

    switch (stage) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared func try_publish_chunk(canister : Principal) : async Result.Result<Types.StageLibraryResponse, Types.OrigynError> {

    let acanister : Types.Service = actor (Principal.toText(canister));
    let fileStage = await acanister.stage_library_nft_origyn({
      token_id = "1" : Text;
      library_id = "page" : Text;
      filedata = #Option(null);
      chunk = 0;
      content = Blob.fromArray([104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100]);
    });

    switch (fileStage) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared func try_get_bearer(canister : Principal) : async Types.BearerResult {

    let acanister : Types.Service = actor (Principal.toText(canister));
    let fileStage = await acanister.bearer_nft_origyn("1");

    switch (fileStage) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared func try_mint(canister : Principal) : async Types.OrigynTextResult {

    let acanister : Types.Service = actor (Principal.toText(canister));
    let mint = await acanister.mint_nft_origyn("1", #principal(Principal.fromActor(this)));

    switch (mint) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared func try_sale_staged(current_owner : Principal, canister : Principal, ledger : Principal) : async Types.MarketTransferResult {

    let acanister : Types.Service = actor (Principal.toText(canister));
    //D.print("caling market transfer  origyn");
    let trysale = await acanister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(current_owner);
          buyer = #principal(Principal.fromActor(this));
          token_id = "1";

          token = #ic({
            canister = ledger;
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant;
        broker_id = null;
      };

    });

    //D.print(debug_show(trysale));

    switch (trysale) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared func try_escrow_withdraw(
    canister : Principal,
    buyer : Principal,
    ledger : Principal,
    seller : Principal,
    token_id : Text,
    amount : Nat,
    token : ?Types.TokenSpec,
  ) : async Types.MarketTransferResult {

    let acanister : Types.Service = actor (Principal.toText(canister));
    //D.print("escrow withdraw");
    let result = await acanister.sale_nft_origyn(
      #withdraw(#escrow({ withdraw_to = #principal(Principal.fromActor(this)); token_id = token_id; token = switch (token) { case (null) { #ic({ canister = ledger; standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }) }; case (?val) { val } }; seller = #principal(seller); buyer = #principal(buyer); amount = amount }))
    );
    switch (result) {
      case (#ok(result)) {
        switch (result) {
          case (#withdraw(result)) {
            return #ok(result);
          };
          case (_) {
            D.print("this should not have happened");

            return #err(Types.errors(null, #nyi, "this should not have happened", null));
          };
        };
      };
      case (#err(err)) {
        return #err(err);
      };
    };

  };

  public shared func try_escrow_reject(
    canister : Principal,
    buyer : Principal,
    ledger : Principal,
    seller : Principal,
    token_id : Text,
    token : ?Types.TokenSpec,
  ) : async Types.MarketTransferResult {

    let acanister : Types.Service = actor (Principal.toText(canister));
    //D.print("escrow withdraw");
    let result = await acanister.sale_nft_origyn(
      #withdraw(#reject({ token_id = token_id; token = switch (token) { case (null) { #ic({ canister = ledger; standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }) }; case (?val) { val } }; seller = #principal(seller); buyer = #principal(buyer) }))
    );
    switch (result) {
      case (#ok(result)) {
        switch (result) {
          case (#withdraw(result)) {
            return #ok(result);
          };
          case (_) {
            D.print("this should not have happened");

            return #err(Types.errors(null, #nyi, "this should not have happened", null));
          };
        };
      };
      case (#err(err)) {
        return #err(err);
      };
    };

  };

  public shared func try_sale_withdraw(canister : Principal, buyer : Principal, ledger : Principal, seller : Principal, token_id : Text, amount : Nat, token : ?Types.TokenSpec) : async Types.MarketTransferResult {

    let acanister : Types.Service = actor (Principal.toText(canister));
    D.print("sale withdraw");
    let tryescrow = await acanister.sale_nft_origyn(
      #withdraw(
        #sale({
          withdraw_to = #principal(Principal.fromActor(this));
          token_id = token_id;
          token = switch (token) {
            case (null) {
              #ic({
                canister = ledger;
                standard = #Ledger;
                decimals = 8;
                symbol = "LDG";
                fee = ?200000;
                id = null;
              });
            };
            case (?val) { val };
          };
          seller = #principal(seller);
          buyer = #principal(buyer);
          amount = amount;
        })
      )
    );

    switch (tryescrow) {
      case (#ok(result)) {
        switch (result) {
          case (#withdraw(result)) {
            return #ok(result);
          };
          case (_) {
            return #err(Types.errors(null, #nyi, "test", null));
          };

        };
      };
      case (#err(theerror)) {
        return #err(theerror);
      };

    };

  };

  public shared func try_deposit_refund(
    canister : Principal,
    ledger : Principal,
    amount : Nat,
    token : ?Types.TokenSpec,
  ) : async Result.Result<MigrationTypes.Current.TransactionRecord, Types.OrigynError> {

    let acanister : Types.Service = actor (Principal.toText(canister));
    D.print("deposit refund origyn");
    let trywithdraw = await acanister.sale_nft_origyn(#withdraw(#deposit({ token = switch (token) { case (null) { #ic({ canister = ledger; standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }) }; case (?val) { val } };

    buyer = #principal(Principal.fromActor(this)); amount = amount; withdraw_to = #principal(Principal.fromActor(this)) })));

    D.print("trywithdraw" # debug_show (trywithdraw));

    switch (trywithdraw) {
      case (#ok(#withdraw(result))) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
      case (_) {
        return #err(Types.errors(null, #improper_interface, "should not be here", null));
      };
    };

  };

  public shared func try_escrow_specific_staged(
    current_owner : Principal,
    canister : Principal,
    ledger : Principal,
    block : ?Nat,
    amount : Nat,
    token_id : Text,
    sale_id : ?Text,
    token : ?Types.TokenSpec,
    lock : ?Int,
  ) : async Result.Result<Types.EscrowResponse, Types.OrigynError> {

    let acanister : Types.Service = actor (Principal.toText(canister));
    //D.print("escrow origyn");
    let tryescrow = await acanister.sale_nft_origyn(#escrow_deposit({ token_id = token_id; deposit = { token = switch (token) { case (null) { #ic({ canister = ledger; standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }) }; case (?val) { val } }; seller = #principal(current_owner); buyer = #principal(Principal.fromActor(this)); amount = amount; sale_id = sale_id; trx_id = switch (block) { case (null) { null }; case (?block) { ? #nat(block) } } }; lock_to_date = lock }));

    switch (tryescrow) {
      case (#ok(#escrow_deposit((result)))) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
      case (_) {
        return #err(Types.errors(null, #improper_interface, "should not be here", null));
      };
    };

  };

  public shared func try_recognize_escrow_specific_staged(
    current_owner : Principal,
    canister : Principal,
    ledger : Principal,
    block : ?Nat,
    amount : Nat,
    token_id : Text,
    sale_id : ?Text,
    token : ?Types.TokenSpec,
    lock : ?Int,
  ) : async Result.Result<Types.RecognizeEscrowResponse, Types.OrigynError> {

    let acanister : Types.Service = actor (Principal.toText(canister));
    //D.print("escrow origyn");
    let tryescrow = await acanister.sale_nft_origyn(#recognize_escrow({ token_id = token_id; deposit = { token = switch (token) { case (null) { #ic({ canister = ledger; standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }) }; case (?val) { val } }; seller = #principal(current_owner); buyer = #principal(Principal.fromActor(this)); amount = amount; sale_id = sale_id; trx_id = switch (block) { case (null) { null }; case (?block) { ? #nat(block) } } }; lock_to_date = lock }));

    switch (tryescrow) {
      case (#ok(#recognize_escrow((result)))) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
      case (_) {
        return #err(Types.errors(null, #improper_interface, "should not be here", null));
      };
    };

  };

  public shared func try_escrow_general_staged(
    current_owner : Principal,
    canister : Principal,
    ledger : Principal,
    block : ?Nat,
    amount : Nat,
    token : ?Types.TokenSpec,
    lock : ?Int,
  ) : async Result.Result<Types.EscrowResponse, Types.OrigynError> {

    let acanister : Types.Service = actor (Principal.toText(canister));
    D.print("trying escrow" # debug_show (#escrow_deposit({ token_id = ""; deposit = { token = switch (token) { case (null) { #ic({ canister = ledger; standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }) }; case (?val) { val } }; seller = #principal(current_owner); buyer = #principal(Principal.fromActor(this)); amount = amount; sale_id = null; trx_id = switch (block) { case (null) { null }; case (?val) { ? #nat(val) } } }; lock_to_date = lock })));

    let tryescrow = await acanister.sale_nft_origyn(#escrow_deposit({ token_id = ""; deposit = { token = switch (token) { case (null) { #ic({ canister = ledger; standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }) }; case (?val) { val } }; seller = #principal(current_owner); buyer = #principal(Principal.fromActor(this)); amount = amount; sale_id = null; trx_id = switch (block) { case (null) { null }; case (?val) { ? #nat(val) } } }; lock_to_date = lock }));
    //D.print("result for escrow was");
    //D.print(debug_show(tryescrow));

    switch (tryescrow) {
      case (#ok(result)) {
        D.print("have result" # debug_show (result));
        let #escrow_deposit(aResult) = result;
        return #ok(aResult);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared func try_recognize_general_staged(
    current_owner : Principal,
    canister : Principal,
    ledger : Principal,
    block : ?Nat,
    amount : Nat,
    token : ?Types.TokenSpec,
    lock : ?Int,
  ) : async Result.Result<Types.RecognizeEscrowResponse, Types.OrigynError> {

    let acanister : Types.Service = actor (Principal.toText(canister));
    D.print("trying recognize" # debug_show (#recognize_escrow({ token_id = ""; deposit = { token = switch (token) { case (null) { #ic({ canister = ledger; standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }) }; case (?val) { val } }; seller = #principal(current_owner); buyer = #principal(Principal.fromActor(this)); amount = amount; sale_id = null; trx_id = switch (block) { case (null) { null }; case (?val) { ? #nat(val) } } }; lock_to_date = lock })));

    let tryescrow = await acanister.sale_nft_origyn(#recognize_escrow({ token_id = ""; deposit = { token = switch (token) { case (null) { #ic({ canister = ledger; standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }) }; case (?val) { val } }; seller = #principal(current_owner); buyer = #principal(Principal.fromActor(this)); amount = amount; sale_id = null; trx_id = switch (block) { case (null) { null }; case (?val) { ? #nat(val) } } }; lock_to_date = lock }));
    //D.print("result for escrow was");
    //D.print(debug_show(tryescrow));

    switch (tryescrow) {
      case (#ok(result)) {
        D.print("have result" # debug_show (result));
        let #recognize_escrow(aResult) = result;
        return #ok(aResult);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared (msg) func send_ledger_deposit(ledger : Principal, amount : Nat, to : Principal) : async Result.Result<Nat, DFXTypes.ICRC1TransferError> {

    let dfx : DFXTypes.Service = actor (Principal.toText(ledger));

    let canister : Types.Service = actor (Principal.toText(to));

    debug {
      if (debug_channel.throws == true) {
        D.print("checking deposit info in send_ledger_deposit for " # debug_show (Principal.fromActor(this)));
      };
    };

    let #ok(#deposit_info(deposit_info)) = await canister.sale_info_nft_origyn(#deposit_info(? #principal(Principal.fromActor(this))));

    debug {
      if (debug_channel.deposit_info == true) {
        D.print("Have deposit info: " # debug_show (deposit_info));
      };
    };

    let funding_result = await dfx.icrc1_transfer({
      to = {
        owner = deposit_info.account.principal;
        subaccount = ?Blob.toArray(deposit_info.account.sub_account);
      };
      fee = ?200_000;
      memo = ?Conversions.candySharedToBytes(#Nat32(Text.hash(Principal.toText(to) # Principal.toText(msg.caller))));
      from_subaccount = null;
      created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
      amount = amount;
    });

    debug {
      if (debug_channel.deposit_info == true) {
        D.print("Have funding result: " # debug_show (funding_result));
      };
    };

    switch (funding_result) {
      case (#Ok(result)) {
        D.print("an ok result" # debug_show (result));
        return #ok(result);
      };
      case (#Err(theerror)) {
        D.print("an error" # debug_show (theerror));
        return #err(theerror);
      };
    };
  };

  public shared (msg) func send_ledger_escrow(ledger : Principal, escrow : Types.EscrowReceipt, to : Principal) : async Result.Result<Nat, DFXTypes.ICRC1TransferError> {

    let dfx : DFXTypes.Service = actor (Principal.toText(ledger));

    let canister : Types.Service = actor (Principal.toText(to));

    debug {
      if (debug_channel.deposit_info == true) {
        D.print("checking deposit info in send_ledger_deposit for " # debug_show (Principal.fromActor(this)));
      };
    };

    let #ok(#escrow_info(deposit_info)) = await canister.sale_info_nft_origyn(#escrow_info(escrow));

    debug {
      if (debug_channel.deposit_info == true) {
        D.print("Have deposit info: " # debug_show (deposit_info));
      };
    };

    let funding_result = await dfx.icrc1_transfer({
      to = {
        owner = deposit_info.account.principal;
        subaccount = ?Blob.toArray(deposit_info.account.sub_account);
      };
      fee = ?200_000;
      memo = ?Conversions.candySharedToBytes(#Nat32(Text.hash(Principal.toText(to) # Principal.toText(msg.caller))));
      from_subaccount = null;
      created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
      amount = escrow.amount;
    });

    debug {
      if (debug_channel.deposit_info == true) {
        D.print("Have funding result: " # debug_show (funding_result));
      };
    };

    switch (funding_result) {
      case (#Ok(result)) {
        D.print("an ok result" # debug_show (result));
        return #ok(result);
      };
      case (#Err(theerror)) {
        D.print("an error" # debug_show (theerror));
        return #err(theerror);
      };
    };
  };

  public shared (msg) func send_payment(ledger : Principal, amount : Nat, to : Principal) : async Result.Result<Nat, Types.OrigynError> {

    let aledger : ledgerService = actor (Principal.toText(ledger));

    //D.print("calling transfer");
    let trypayment = await aledger.transfer(to, amount);

    switch (trypayment) {
      case (#Ok(result)) {
        return #ok(result);
      };
      case (#Err(theerror)) {
        return #err(Types.errors(null, #nyi, debug_show (theerror), ?msg.caller));
      };
    };
  };

  public shared (msg) func ledger_balance(ledger : Principal, wallet : Principal) : async Tokens {

    let aledger : ledgerService = actor (Principal.toText(ledger));

    //D.print("calling transfer");
    let trybalance = await aledger.account_balance({
      account = Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(wallet, null)));
    });

    return trybalance;
  };

  public shared (msg) func approve_payment(ledger : Principal, amount : Nat, to : Principal) : async Result.Result<Nat, Types.OrigynError> {

    let aledger : ledgerService = actor (Principal.toText(ledger));

    //D.print("calling transfer");
    let trypayment = await aledger.approve(to, amount);

    switch (trypayment) {
      case (#Ok(result)) {
        return #ok(result);
      };
      case (#Err(theerror)) {
        return #err(Types.errors(null, #nyi, debug_show (theerror), ?msg.caller));
      };
    };
  };

  public shared (msg) func try_owner_transfer(canister : Principal, token_id : Text, to : Types.Account) : async Types.OwnerUpdateResult {

    let acanister : Types.Service = actor (Principal.toText(canister));

    //D.print("calling transfer");
    let try_transfer = await acanister.share_wallet_nft_origyn({
      from = #principal(Principal.fromActor(this));
      to = to;
      token_id = token_id;
    });

    switch (try_transfer) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared (msg) func try_offer_refresh(canister : Principal) : async Types.ManageSaleResult {

    let acanister : Types.Service = actor (Principal.toText(canister));

    //D.print("calling transfer");
    let try_refresh = await acanister.sale_nft_origyn(#refresh_offers(null));

    switch (try_refresh) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared (msg) func try_set_nft(canister : Principal, token_id : Text, data : CandyTypes.CandyShared) : async Types.NFTUpdateResult {

    let acanister : Types.Service = actor (Principal.toText(canister));

    //D.print("calling set data");
    let try_transfer = await acanister.update_app_nft_origyn(#replace { token_id = token_id; data = data });

    switch (try_transfer) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared (msg) func try_start_auction(canister : Principal, ledger : Principal, token_id : Text, allow_list : ?[Principal]) : async Types.MarketTransferResult {

    let acanister : Types.Service = actor (Principal.toText(canister));

    //D.print("calling set data");
    let trystart = await acanister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #auction {
          reserve = ?(100 * 10 ** 8);
          token = #ic({
            canister = ledger;
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          buy_now = ?(500 * 10 ** 8);
          start_price = (1 * 10 ** 8);
          start_date = 0;
          ending = #date(1);
          min_increase = #amount(10 * 10 ** 8);
          allow_list = allow_list;
        };
      };
    });

    switch (trystart) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared (msg) func try_start_ask(canister : Principal, ledger : Principal, token_id : Text, allow_list : ?[Principal]) : async Types.MarketTransferResult {

    let acanister : Types.Service = actor (Principal.toText(canister));

    let option_buffer = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(100 * 10 ** 8),
      #token(#ic({ canister = ledger; standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),
      #buy_now(500 * 10 ** 8),
      #start_price(1 * 10 ** 8),
      #ending(#timeout(DAY_LENGTH * 5)),
      #min_increase(#amount(10 * 10 ** 8)),
    ]);
    switch (allow_list) {
      case (null) {};
      case (?allow_list) {
        option_buffer.add(#allow_list(allow_list));
      };
    };

    //D.print("calling set data");
    let trystart = await acanister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer));
      };
    });

    switch (trystart) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared (msg) func try_start_dutch(canister : Principal, ledger : Principal, token_id : Text, allow_list : ?[Principal], dutch_params : ?Types.DutchParams) : async Types.MarketTransferResult {

    let acanister : Types.Service = actor (Principal.toText(canister));

    let option_buffer = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(1 * 10 ** 8),
      #token(#ic({ canister = ledger; standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),

      #start_price(100 * 10 ** 8),
      #ending(#timeout(DAY_LENGTH * 5)),
      #dutch(
        switch (dutch_params) {
          case (null) {
            {
              time_unit = #minute(1);
              decay_type = #flat(100000000);
            };
          };
          case (?val) val;
        }
      ),
    ]);
    switch (allow_list) {
      case (null) {};
      case (?allow_list) {
        option_buffer.add(#allow_list(allow_list));
      };
    };

    //D.print("calling set data");
    let trystart = await acanister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer));
      };
    });

    switch (trystart) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared (msg) func try_bid(canister : Principal, owner : Principal, ledger : Principal, amount : Nat, token_id : Text, sale_id : Text, broker : ?Principal) : async Result.Result<Types.BidResponse, Types.OrigynError> {

    let acanister : Types.Service = actor (Principal.toText(canister));

    D.print("in try bid" # debug_show ((canister, owner, ledger, amount, token_id, sale_id, broker)));

    D.print("calling sale");
    let trystart = try {
      await acanister.sale_nft_origyn(
        #bid({
          broker_id = broker;
          sale_id = sale_id;
          escrow_receipt = {
            seller = #principal(owner);
            buyer = #principal(Principal.fromActor(this));
            token_id = token_id;
            token = #ic({
              canister = ledger;
              standard = #Ledger;
              decimals = 8;
              id = null;
              symbol = "LDG";
              fee = ?200000;
            });
            amount = amount;
          };
        })
      );
    } catch (e) {
      D.print("an error");
      D.print(Error.message(e));
      D.trap(Error.message(e));
    };

    switch (trystart) {
      case (#ok(result)) {
        switch (result) {
          case (#bid(result)) {
            #ok(result);
          };
          case (_) {
            return #err(Types.errors(null, #unreachable, "shouldnt be here", ?msg.caller));
          };
        };

      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };

  };

  public shared (msg) func try_sale_manage_nft(canister : Principal, items : [SaleTypes.ManageNFTRequest]) : async Result.Result<SaleTypes.ManageNFTResponse, SaleTypes.OrigynError> {
    let asale : SaleTypes.Service = actor (Principal.toText(canister));

    //D.print("calling set data");
    let trymanage = await asale.manage_nfts_sale_nft_origyn(items);

    switch (trymanage) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };
  };

  public shared (msg) func try_sale_nft_allocation(canister : Principal, item : SaleTypes.AllocationRequest) : async Result.Result<SaleTypes.AllocationResponse, SaleTypes.OrigynError> {
    let asale : SaleTypes.Service = actor (Principal.toText(canister));

    //D.print("calling allocate data");
    let trymanage = await asale.allocate_sale_nft_origyn(item);

    switch (trymanage) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };
  };

  public shared (msg) func try_sale_nft_redeem(canister : Principal, item : SaleTypes.RedeemAllocationRequest) : async Result.Result<SaleTypes.RedeemAllocationResponse, SaleTypes.OrigynError> {
    let asale : SaleTypes.Service = actor (Principal.toText(canister));

    //D.print("calling set try_sale_nft_redeem");
    let trymanage = await asale.redeem_allocation_sale_nft_origyn(item);

    switch (trymanage) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };
  };

  public shared (msg) func try_sale_registration(canister : Principal, item : SaleTypes.RegisterEscrowRequest) : async Result.Result<SaleTypes.RegisterEscrowResponse, SaleTypes.OrigynError> {
    let asale : SaleTypes.Service = actor (Principal.toText(canister));

    D.print("calling set data");
    let trymanage = await asale.register_escrow_sale_nft_origyn(item);

    D.print("done set data" # debug_show (trymanage));

    switch (trymanage) {
      case (#ok(result)) {
        return #ok(result);
      };
      case (#err(theerror)) {
        return #err(theerror);
      };
    };
  };

  let notification_buffer = Buffer.Buffer<Types.SubscriberNotification>(1);

  public shared (msg) func notify_sale_nft_origyn(request : Types.SubscriberNotification) : () {
    D.print("was notified!" # debug_show (request));
    notification_buffer.add(request);
  };

  public shared (msg) func get_notifications() : async [Types.SubscriberNotification] {
    Buffer.toArray<Types.SubscriberNotification>(notification_buffer);
  };
};
