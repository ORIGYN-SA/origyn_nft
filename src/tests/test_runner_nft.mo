import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Error "mo:base/Error";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Random "mo:base/Random";
import Time "mo:base/Time";

import AccountIdentifier "mo:principalmo/AccountIdentifier";
import C "mo:matchers/Canister";
import Conversion "mo:candy/conversion";
import M "mo:matchers/Matchers";
import Properties "mo:candy/properties";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";

import DFXTypes "../origyn_nft_reference/dfxtypes";
import Instant "test_runner_instant_transfer";
import Metadata "../origyn_nft_reference/metadata";
import NFTUtils "../origyn_nft_reference/utils";
import Royalties "../origyn_nft_reference/market/royalties";
import TestWalletDef "test_wallet";
import Types "../origyn_nft_reference/types";
import ICRC7Types "../origyn_nft_reference/ICRC7";
import Market "../origyn_nft_reference/market";
import utils "test_utils";
//import Instant "test_runner_instant_transfer";
import MigrationTypes "../origyn_nft_reference/migrations/types";

// ttps://m7sm4-2iaaa-aaaab-qabra-cai.raw.icp0.io/?tag=1526457217 will provide a facility to convert
// a account hash to an account id
// ie dfx canister --network ic call mexqz-aqaaa-aaaab-qabtq-cai say '(principal "r7inp-6aaaa-aaaaa-aaabq-cai", blob "20\8F\6F\7F\9B\0D\B3\29\36\AA\8B\F4\78\38\E8\B8\15\37\30\F7\3D\03\99\EA\BB\68\98\11\08\64\90\61")'

shared (deployer) actor class test_runner(dfx_ledger : Principal, dfx_ledger2 : Principal) = this {

  let CandyTypes = MigrationTypes.Current.CandyTypes;
  let Conversions = MigrationTypes.Current.Conversions;
  let Properties = MigrationTypes.Current.Properties;
  let Workspace = MigrationTypes.Current.Workspace;

  let debug_channel = {
    throws = false;
    withdraw_detail = false;
  };

  D.print("have ledger values are " # debug_show (dfx_ledger, dfx_ledger2));

  let dfx : DFXTypes.Service = actor (Principal.toText(dfx_ledger));

  let dfxspec = {
    canister = Principal.fromActor(dfx);
    standard = #Ledger;
    decimals = 8;
    symbol = "LDG";
    fee = ?200000;
    id = null;
  };

  let dfx2 : DFXTypes.Service = actor (Principal.toText(dfx_ledger2));

  private type canister_factory = actor {
    create : (Principal) -> async Principal;
  };

  let it = C.Tester({ batchSize = 8 });

  private var DAY_LENGTH = 60 * 60 * 24 * 10 ** 9;
  private var dip20_fee = 200_000;

  private func get_time() : Int {
    return Time.now();
  };

  private type canister_factory_actor = actor {
    create : ({ owner : Principal; storage_space : ?Nat }) -> async Principal;
  };
  private type storage_factory_actor = actor {
    create : ({ owner : Principal; storage_space : ?Nat }) -> async Principal;
  };

  private var g_canister_factory : canister_factory_actor = actor (Principal.toText(Principal.fromBlob("\04")));
  private var g_storage_factory : storage_factory_actor = actor (Principal.toText(Principal.fromBlob("\04")));

  public shared func test(canister_factory : Principal, storage_factory : Principal) : async {
    #success;
    #fail : Text;
  } {

    //let Instant_Test = await Instant.test_runner_instant_transfer();

    g_canister_factory := actor (Principal.toText(canister_factory));
    g_storage_factory := actor (Principal.toText(storage_factory));

    let suite = S.suite(
      "test nft",
      [
        // S.test("testAuction_v3", switch (await testAuction_v3()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        // S.test("testDutch", switch (await testDutch()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        // S.test("testRecognizeEscrow", switch (await testRecognizeEscrow()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        // S.test("testRoyalties", switch (await testRoyalties()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        // S.test("testAuction", switch (await testAuction()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        // S.test("testAuction_v2", switch (await testAuction_v2()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        // S.test("testDeposits", switch (await testDeposit()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        // S.test("testStandardLedger", switch (await testStandardLedger()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        // S.test("testMarketTransfer", switch (await testMarketTransfer()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        // S.test("testOwnerTransfer", switch (await testOwnerTransfer()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        // S.test("testOffer", switch (await testOffers()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))) S.test("testRoyaltiesFixed", switch (await testRoyaltiesFixed()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        // S.test("testRoyaltiesFixed", switch (await testRoyaltiesFixed()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        S.test("testRoyaltiesFixedDifferentToken", switch (await testRoyaltiesFixedDifferentToken()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
      ],
    );
    S.run(suite);

    return #success;
  };

  public shared func testDeposit() : async { #success; #fail : Text } {
    D.print("running testDeposit");

    D.print("making wallets");

    let a_wallet = await TestWalletDef.test_wallet();
    let b_wallet = await TestWalletDef.test_wallet();

    let newPrincipal = await g_canister_factory.create({
      owner = Principal.fromActor(this);
      storage_space = null;
    });

    let canister : Types.Service = actor (Principal.toText(newPrincipal));

    let timeset = await canister.__set_time_mode(#test);
    let startTime = Time.now();
    let atime = await canister.__advance_time(startTime);

    D.print("calling stage");

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
    let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));

    D.print("stage result" # debug_show (standardStage2));

    //mint 2
    let mint_attempt = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this)));
    let mint_attempt2 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));

    D.print("mint result" # debug_show (mint_attempt2));

    D.print("starting sale");
    let sale_start = await canister.market_transfer_nft_origyn({
      token_id = "2";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #auction {
          reserve = null;
          token = #ic({
            canister = dfx_ledger;
            standard = #Ledger;
            decimals = 8;
            symbol = "OGY";
            fee = ?200000;
            id = null;
          });
          buy_now = ?(500 * 10 ** 8); //nyi
          start_price = (100 * 10 ** 8);
          start_date = 0;
          ending = #date(startTime + DAY_LENGTH);
          min_increase = #amount(10 * 10 ** 8);
          allow_list = null;
        };
      };
    });

    D.print("funding");
    //funding
    D.print("funding");
    //funding
    let funding_result = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
      amount = 100 * 10 ** 8;
    });

    D.print("funding result " # debug_show (funding_result));
    let funding_result2 = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
      amount = 100 * 10 ** 8;
    });

    D.print("funding result 2 " # debug_show (funding_result2));

    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (4 * 10 ** 8) + 800000, Principal.fromActor(canister));
    //let a_wallet_send_tokens_to_b = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), 1 * 10 ** 8, Principal.fromActor(canister));

    let b_wallet_send_tokens_to_canister = await b_wallet.send_ledger_deposit(Principal.fromActor(dfx), (2 * 10 ** 8) + 400000, Principal.fromActor(canister));
    //let b_wallet_send_tokens_to_canister2 = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), 1 * 10 ** 8, Principal.fromActor(canister));

    D.print("Done funding");
    //send an escrow locked until a certain lock time

    //escrow for a general nft with to owner of nft
    let lockedEscrow_specific_no_sale = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, null, ?(startTime + DAY_LENGTH));
    debug {
      if (debug_channel.withdraw_detail) {
        D.print("lockedEscrow_specific_no_sale" # debug_show (lockedEscrow_specific_no_sale));
      };
    };

    //escrow for a general nft with no nfts
    let lockedEscrow_specific_sale = await a_wallet.try_escrow_general_staged(Principal.fromActor(b_wallet), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, null, ?(startTime + DAY_LENGTH));
    debug {
      if (debug_channel.withdraw_detail) {
        D.print("lockedEscrow_specific_sale" # debug_show (lockedEscrow_specific_sale));
      };
    };

    //escrow for a specific nft with no sale running
    let lockedEscrow_general_no_sale = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "3", null, null, ?(startTime + DAY_LENGTH));
    debug {
      if (debug_channel.withdraw_detail) {
        D.print("lockedEscrow_general_no_sale" # debug_show (lockedEscrow_general_no_sale));
      };
    };

    //escrow for a specific nft with sale running
    let lockedEscrow_general_sale = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "2", null, null, ?(startTime + DAY_LENGTH));
    debug {
      if (debug_channel.withdraw_detail) {
        D.print("lockedEscrow_general_sale" # debug_show (lockedEscrow_general_sale));
      };
    };

    let balances = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    D.print(
      "did escrows work" # debug_show (
        lockedEscrow_specific_no_sale,
        lockedEscrow_specific_sale,
        lockedEscrow_general_no_sale,
        lockedEscrow_general_sale,
        balances,
      )
    );

    //try to withdraw

    D.print("trying withdrawls");

    let withdraw_before_lock_1 = await a_wallet.try_escrow_withdraw(
      Principal.fromActor(canister),
      Principal.fromActor(a_wallet),
      Principal.fromActor(dfx),
      Principal.fromActor(canister),
      "",
      (1 * 10 ** 8),
      null,
    );

    debug {
      if (debug_channel.withdraw_detail) {
        D.print("withdraw_before_lock_1" # debug_show (withdraw_before_lock_1));
      };
    };

    let withdraw_before_lock_2 = await a_wallet.try_escrow_withdraw(
      Principal.fromActor(canister),
      Principal.fromActor(a_wallet),
      Principal.fromActor(dfx),
      Principal.fromActor(b_wallet),
      "",
      (1 * 10 ** 8),
      null,
    );

    debug {
      if (debug_channel.withdraw_detail) {
        D.print("withdraw_before_lock_2" # debug_show (withdraw_before_lock_2));
      };
    };

    let withdraw_before_lock_3 = await a_wallet.try_escrow_withdraw(
      Principal.fromActor(canister),
      Principal.fromActor(a_wallet),
      Principal.fromActor(dfx),
      Principal.fromActor(this),
      "2",
      (1 * 10 ** 8),
      null,
    );

    debug {
      if (debug_channel.withdraw_detail) {
        D.print("withdraw_before_lock_3" # debug_show (withdraw_before_lock_3));
      };
    };

    let withdraw_before_lock_4 = await a_wallet.try_escrow_withdraw(
      Principal.fromActor(canister),
      Principal.fromActor(a_wallet),
      Principal.fromActor(dfx),
      Principal.fromActor(this),
      "3",
      (1 * 10 ** 8),
      null,
    );

    debug {
      if (debug_channel.withdraw_detail) {
        D.print("withdraw_before_lock_4" # debug_show (withdraw_before_lock_4));
      };
    };

    /* D.print("first withdraw results" # debug_show(
            withdraw_before_lock_1,
        withdraw_before_lock_2,
        withdraw_before_lock_3,
        withdraw_before_lock_4)); */

    let atime2 = await canister.__advance_time(startTime + DAY_LENGTH + 1);

    let end_sale = await canister.sale_nft_origyn(#end_sale("2"));

    //try withdraws again

    let withdraw_after_lock_1 = await a_wallet.try_escrow_withdraw(
      Principal.fromActor(canister),
      Principal.fromActor(a_wallet),
      Principal.fromActor(dfx),
      Principal.fromActor(canister),
      "",
      (1 * 10 ** 8),
      null,
    );
    debug {
      if (debug_channel.withdraw_detail) {
        D.print("withdraw_after_lock_1" # debug_show (withdraw_after_lock_1));
      };
    };

    let withdraw_after_lock_2 = await a_wallet.try_escrow_withdraw(
      Principal.fromActor(canister),
      Principal.fromActor(a_wallet),
      Principal.fromActor(dfx),
      Principal.fromActor(b_wallet),
      "",
      (1 * 10 ** 8),
      null,
    );

    debug {
      if (debug_channel.withdraw_detail) {
        D.print("withdraw_after_lock_2" # debug_show (withdraw_after_lock_2));
      };
    };

    let withdraw_after_lock_3 = await a_wallet.try_escrow_withdraw(
      Principal.fromActor(canister),
      Principal.fromActor(a_wallet),
      Principal.fromActor(dfx),
      Principal.fromActor(this),
      "2",
      (1 * 10 ** 8),
      null,
    );

    debug {
      if (debug_channel.withdraw_detail) {
        D.print("withdraw_after_lock_3" # debug_show (withdraw_after_lock_3));
      };
    };

    let withdraw_after_lock_4 = await a_wallet.try_escrow_withdraw(
      Principal.fromActor(canister),
      Principal.fromActor(a_wallet),
      Principal.fromActor(dfx),
      Principal.fromActor(this),
      "3",
      (1 * 10 ** 8),
      null,
    );

    debug {
      if (debug_channel.withdraw_detail) {
        D.print("withdraw_after_lock_4" # debug_show (withdraw_after_lock_4));
      };
    };

    /* D.print("second withdraw results" # debug_show(
            withdraw_after_lock_1,
        withdraw_after_lock_2,
        withdraw_after_lock_3,
        withdraw_after_lock_4)); */

    //test balances

    let to = AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null));

    let a_wallet_balance = await dfx.account_balance({
      account = Blob.fromArray(to);
    });

    let suite = S.suite(
      "test locked deposit",
      [

        S.test(
          "fail if witdraw locked for general owner",
          switch (withdraw_before_lock_1) {
            case (#ok(res)) {
              "unexpected success" # debug_show (res);
            };
            case (#err(err)) {
              if (err.number == 3008) {
                //since the requestor isnt the owner and this isnt minted we wont reveal it is a real token
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //NFT-228
        S.test(
          "fail if witdraw locked for non owner",
          switch (withdraw_before_lock_2) {
            case (#ok(res)) {
              "unexpected success" # debug_show (res);
            };
            case (#err(err)) {
              if (err.number == 3008) {
                //since the requestor isnt the owner and this isnt minted we wont reveal it is a real token
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //NFT-228
        S.test(
          "fail if witdraw locked for specific with sale",
          switch (withdraw_before_lock_3) {
            case (#ok(res)) {
              "unexpected success" # debug_show (res);
            };
            case (#err(err)) {
              if (err.number == 3008) {
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //NFT-228
        S.test(
          "fail if witdraw locked for specific with no sale",
          switch (withdraw_before_lock_4) {
            case (#ok(res)) {
              "unexpected success" # debug_show (res);
            };
            case (#err(err)) {
              if (err.number == 3008) {
                //since the requestor isnt the owner and this isnt minted we wont reveal it is a real token
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //NFT-228
        S.test(
          "pass withdraw for general owner if past date",
          switch (withdraw_after_lock_1) {
            case (#ok(res)) { "expected success" };
            case (#err(err)) {

              "wrong error " # debug_show (err);
            };
          },
          M.equals<Text>(T.text("expected success")),
        ), //NFT-228
        S.test(
          "pass withdraw for general non-owner if past date",
          switch (withdraw_after_lock_2) {
            case (#ok(res)) { "expected success" };
            case (#err(err)) {

              "wrong error " # debug_show (err);
            };
          },
          M.equals<Text>(T.text("expected success")),
        ), //NFT-228
        S.test(
          "pass withdraw for specific if sale over",
          switch (withdraw_after_lock_3) {
            case (#ok(res)) { "expected success" };
            case (#err(err)) {

              "wrong error " # debug_show (err);
            };
          },
          M.equals<Text>(T.text("expected success")),
        ), //NFT-228
        S.test(
          "pass withdraw for specific if no sale",
          switch (withdraw_after_lock_4) {
            case (#ok(res)) { "expected success" };
            case (#err(err)) {

              "wrong error " # debug_show (err);
            };
          },
          M.equals<Text>(T.text("expected success")),
        ), //NFT-228

      ],
    );

    S.run(suite);

    return #success;
  };

  public shared func testMarketTransfer() : async { #success; #fail : Text } {
    D.print("running testMarketTransfer");

    D.print("making wallets");

    let a_wallet = await TestWalletDef.test_wallet();

    D.print("making factory");

    let newPrincipal = try {
      await g_canister_factory.create({
        owner = Principal.fromActor(this);
        storage_space = null;
      });
    } catch (e) {
      D.print(Error.message(e));
      return #fail(Error.message(e));
    };

    D.print("have canister");

    let canister : Types.Service = actor (Principal.toText(newPrincipal));

    D.print("calling stage");

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
    let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));

    D.print("finished stage");
    D.print(debug_show (standardStage.0));

    //MKT0015 try the sale before there is an escrow
    let blind_market_fail = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(canister));
          buyer = #principal(Principal.fromActor(a_wallet));
          token_id = "1";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };

    });

    D.print("blind market fail");
    D.print(debug_show (blind_market_fail));

    //MKT0008 Should fail
    D.print("calling try_sale_staged");
    let a_wallet_try_staged_market = await a_wallet.try_sale_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx));

    D.print(debug_show (a_wallet_try_staged_market));

    D.print("calling try_escrow_specific_staged");
    //ESC0003. try to escrow for the specific item; should fail
    let a_wallet_try_escrow_specific_staged = await a_wallet.try_escrow_specific_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), ?1, 1 * 10 ** 8, "1", null, null, null);

    D.print(debug_show (a_wallet_try_escrow_specific_staged));

    //ESC0002. try to escrow for the canister; should succeed
    //fund a_wallet
    let funding_result = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });
    D.print("funding result");
    D.print(debug_show (funding_result));

    //sent an escrow for a dip20 deposit that doesn't exist
    D.print("sending an escrow with no deposit");
    let a_wallet_try_escrow_general_fake = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), ?34, 1 * 10 ** 8, null, null);

    //send a payment to the ledger
    D.print("sending tokens to canisters");
    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (1 * 10 ** 8) + 200000, Principal.fromActor(canister));

    D.print("send to canister");
    D.print(debug_show (a_wallet_send_tokens_to_canister));

    let block = switch (a_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    //sent an escrow for a ledger deposit that doesn't exist
    let a_wallet_try_escrow_general_fake_amount = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), null, 2 * 10 ** 8, null, null);

    ////ESC0001

    D.print("Sending real escrow now");
    let a_wallet_try_escrow_general_staged = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, null, null);

    D.print("try escrow genreal stage");
    D.print(debug_show (a_wallet_try_escrow_general_staged));

    //ESC0005 should fail if you try to calim a deposit a second time
    let a_wallet_try_escrow_general_staged_retry = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, null, null);

    //check balance and make sure we see the escrow BAL0002
    let a_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    D.print("thebalance");
    D.print(debug_show (a_balance));

    //MKT0007, MKT0014
    D.print("blind market");
    let blind_market = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(canister));
          buyer = #principal(Principal.fromActor(a_wallet));
          token_id = "";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };

    });

    D.print(debug_show (blind_market));

    //MKT0014 todo: check the transaction record and confirm the gensis reocrd

    //BAL0005
    let a_balance2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    //BAL0003
    let canister_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(canister)));

    //MKT0013, MKT0011 this item should be minted now
    let test_metadata = await canister.nft_origyn("1");
    D.print("This thing should have been minted");
    D.print(debug_show (test_metadata));
    switch (test_metadata) {
      case (#ok(val)) {
        D.print(debug_show (Metadata.is_minted(val.metadata)));
      };
      case (_) {};
    };

    //MINT0026 shold fail because the purchase of a staged item should mint it
    let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(a_wallet)));
    D.print("This thing should have not been minted");
    D.print(debug_show (mint_attempt));

    //ESC0009
    let blind_market2 = await canister.market_transfer_nft_origyn({
      token_id = "2";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(canister));
          buyer = #principal(Principal.fromActor(a_wallet));
          token_id = "";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };

    });

    D.print("This thing should have not been minted either");
    D.print(debug_show (blind_market2));

    //mint the third item to test a specific sale
    let mint_attempt3 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));

    D.print("mint attempt 3");
    D.print(debug_show (mint_attempt3));

    //creae an new wallet for testing
    let b_wallet = await TestWalletDef.test_wallet();

    //give b_wallet some tokens
    let b_funding_result = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    //send a payment to the the new owner(this actor- after mint)
    D.print("sending tokens to canisters");

    let b_wallet_send_tokens_to_canister = await b_wallet.send_ledger_deposit(Principal.fromActor(dfx), (1 * 10 ** 8) + 200000, Principal.fromActor(canister));

    D.print("send to canister market transfer b");
    D.print(debug_show (b_wallet_send_tokens_to_canister));

    let b_block = switch (b_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    //make sure a user can't escrow for an owner that doesn't own NFT
    let b_wallet_try_escrow_wrong_owner = await b_wallet.try_escrow_specific_staged(Principal.fromActor(a_wallet), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "3", null, null, null);
    D.print("b_wallet_try_escrow_wrong_owner: " # debug_show (b_wallet_try_escrow_wrong_owner));

    //ESC0002
    D.print("Sending real escrow now");
    let b_wallet_try_escrow_specific_staged = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "3", null, null, null);

    //
    D.print("try escrow specific stage");
    D.print(debug_show (b_wallet_try_escrow_specific_staged));

    //MKT0010
    D.print("apecific market");
    let specific_market = await canister.market_transfer_nft_origyn({
      token_id = "3";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(this));
          buyer = #principal(Principal.fromActor(b_wallet));
          token_id = "3";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };

    });

    D.print(debug_show (specific_market));

    //test balances

    let suite = S.suite(
      "test market Nft",
      [

        S.test(
          "fail if no escrow exists for general staged sale a",
          switch (blind_market_fail) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4) {
                //since the requestor isnt the owner and this isnt minted we wont reveal it is a real token
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0015
        S.test(
          "fail if non owner trys to sell a",
          switch (a_wallet_try_staged_market) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4) {
                //no escrow
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0008
        S.test(
          "owner can sell staged NFT - produces sale_id",
          switch (blind_market) {
            case (#ok(res)) {
              D.print("found blind market response");
              D.print(debug_show (res));
              if (res.index == 0) {
                "found genesis record id";
              } else {
                "no sales id ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point # debug_show (err);
            };
          },
          M.equals<Text>(T.text("found genesis record id")),
        ), //MKT0007, MKT0014
        S.test(
          "fail if escrow is double processed",
          switch (a_wallet_try_escrow_general_staged_retry) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3003) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0005
        S.test(
          "fail if mint is called on a minted item",
          switch (mint_attempt) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 10) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MINT0026

        S.test(
          "item is minted now",
          switch (test_metadata) {
            case (#ok(res)) {
              if (Metadata.is_minted(res.metadata) == true) {
                "was minted";
              } else {
                "was not minted";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("was minted")),
        ), //MKT0013
        S.test(
          "item is owned by correct owner after minting",
          switch (test_metadata) {
            case (#ok(res)) {
              if (
                Types.account_eq(
                  switch (Metadata.get_nft_owner(res.metadata)) {
                    case (#err(err)) {
                      #account_id("invalid");
                    };
                    case (#ok(val)) {
                      D.print(debug_show (val));
                      val;
                    };
                  },
                  #principal(Principal.fromActor(a_wallet)),
                ) == true
              ) {
                "was transfered";
              } else {
                D.print("awallet");
                D.print(debug_show (Principal.fromActor(a_wallet)));
                "was not transfered";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("was transfered")),
        ), //MKT0011

        S.test(
          "fail if escrow already spent a",
          switch (blind_market2) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0009
        S.test(
          "fail if escrowing for a specific item and it is only staged",
          switch (a_wallet_try_escrow_specific_staged) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0003
        S.test(
          "fail if escrowing for a non existant deposit a",
          switch (a_wallet_try_escrow_general_fake) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3003) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0006
        S.test(
          "fail if escrowing for an existing deposit but fake amount a",
          switch (a_wallet_try_escrow_general_fake_amount) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3003) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0011
        S.test(
          "can escrow for general unminted item",
          switch (a_wallet_try_escrow_general_staged) {
            case (#ok(res)) {
              D.print("an amount for escrow");
              D.print(debug_show (res.receipt));
              if (res.receipt.amount == 1 * 10 ** 8) {
                "was escrowed";
              } else {
                "was not escrowed";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("was escrowed")),
        ), //ESC0002

        S.test(
          "escrow deposit transaction",
          switch (a_wallet_try_escrow_general_staged) {
            case (#ok(res)) {

              switch (res.transaction.txn_type) {
                case (#escrow_deposit(details)) {
                  if (
                    Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and Types.account_eq(details.seller, #principal(Principal.fromActor(canister))) and details.amount == ((1 * 10 ** 8)) and details.token_id == "" and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                  ) {
                    "correct response";
                  } else {
                    "details didnt match" # debug_show (details);
                  };
                };
                case (_) {
                  "bad history sale";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //NFT-72
        S.test(
          "can't escrow for wrong NFT owner",
          switch (b_wallet_try_escrow_wrong_owner) {
            case (#err(err)) {
              if (err.number == 3002) {
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
            case (#ok(res)) {
              "unexpected success: " # debug_show (res);
            };
          },
          M.equals<Text>(T.text("correct number")),
        ),
        S.test(
          "can escrow for specific item",
          switch (b_wallet_try_escrow_specific_staged) {
            case (#ok(res)) {
              if (res.receipt.amount == 1 * 10 ** 8) {
                "was escrowed";
              } else {
                "was not escrowed";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("was escrowed")),
        ), //ESC0001
        S.test(
          "owner can sell specific NFT - produces sale_id",
          switch (specific_market) {
            case (#ok(res)) {
              if (res.token_id == "3") {
                "found tx record";
              } else {
                D.print(debug_show (res));
                "no sales id ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found tx record")),
        ), //MKT0010
        S.test(
          "escrow balance is shown",
          switch (a_balance) {
            case (#ok(res)) {
              D.print(debug_show (res));
              D.print(debug_show (#principal(Principal.fromActor(canister))));
              D.print(debug_show (#principal(Principal.fromActor(a_wallet))));
              D.print(debug_show (Principal.fromActor(dfx)));
              if (
                Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(canister))) and Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet))) and res.escrow[0].token_id == "" and Types.token_eq(res.escrow[0].token, #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
              ) {
                "found escrow record";
              } else {
                D.print(debug_show (res));
                "didnt find record ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found escrow record")),
        ), //BAL0001
        S.test(
          "escrow balance is removed",
          switch (a_balance2) {
            case (#ok(res)) {
              D.print(debug_show (res));
              if (res.escrow.size() == 0) {
                "no escrow record";
              } else {
                D.print(debug_show (res));
                "found record  ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("no escrow record")),
        ), //BAL0005
        S.test(
          "sale balance is shown",
          switch (a_balance) {
            case (#ok(res)) {
              D.print(debug_show (res));
              D.print(debug_show (#principal(Principal.fromActor(canister))));
              D.print(debug_show (#principal(Principal.fromActor(a_wallet))));
              D.print(debug_show (Principal.fromActor(dfx)));
              if (
                Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet))) and Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(canister))) and res.escrow[0].token_id == "" and Types.token_eq(res.escrow[0].token, #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })) and res.escrow[0].amount == 1 * 10 ** 8
              ) {
                "found sale record";
              } else {
                D.print(debug_show (res));
                "didnt find record ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found sale record")),
        ), //BAL0003

      ],
    );

    S.run(suite);

    return #success;
  };

  public shared func testRecognizeEscrow() : async { #success; #fail : Text } {
    D.print("running testMarketTransfer");

    D.print("making wallets");

    let a_wallet = await TestWalletDef.test_wallet();
    let b_wallet = await TestWalletDef.test_wallet();

    D.print("making factory");

    let newPrincipal = try {
      await g_canister_factory.create({
        owner = Principal.fromActor(this);
        storage_space = null;
      });
    } catch (e) {
      D.print(Error.message(e));
      return #fail(Error.message(e));
    };

    D.print("have canister");

    let canister : Types.Service = actor (Principal.toText(newPrincipal));

    D.print("calling stage");

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
    let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));

    D.print("finished stage");
    D.print(debug_show (standardStage.0));

    //MKT0015 try the sale before there is an escrow
    let blind_market_fail = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(canister));
          buyer = #principal(Principal.fromActor(a_wallet));
          token_id = "";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };

    });

    D.print("blind market fail");
    D.print(debug_show (blind_market_fail));

    //MKT0008 Should fail
    D.print("calling try_sale_staged");
    let a_wallet_try_staged_market = await a_wallet.try_sale_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx));

    D.print(debug_show (a_wallet_try_staged_market));

    D.print("calling try_escrow_specific_staged");
    //ESC0003. try to escrow for the specific item; should fail
    let a_wallet_try_recognize_escrow_specific_staged = await a_wallet.try_recognize_escrow_specific_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), ?1, 1 * 10 ** 8, "1", null, null, null);

    D.print(debug_show (a_wallet_try_recognize_escrow_specific_staged));

    //ESC0002. try to escrow for the canister; should succeed
    //fund a_wallet
    let funding_result = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });
    D.print("funding result");
    D.print(debug_show (funding_result));

    let funding_result2 = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });
    D.print("funding result2");
    D.print(debug_show (funding_result2));

    //sent an escrow for a dip20 deposit that doesn't exist
    D.print("sending an escrow with no deposit");
    let a_wallet_try_recognize_general_staged_fake = await a_wallet.try_recognize_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), ?34, 1 * 10 ** 8, null, null);

    //send a payment to the ledger
    D.print("sending tokens to canisters");

    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_escrow(
      Principal.fromActor(dfx),
      {
        seller = #principal(Principal.fromActor(canister));
        buyer = #principal(Principal.fromActor(a_wallet));
        token_id = "";
        token = #ic({
          canister = Principal.fromActor(dfx);
          standard = #Ledger;
          decimals = 8;
          symbol = "LDG";
          fee = ?200000;
          id = null;
        });
        amount = 100_000_001;
      },
      Principal.fromActor(canister),
    );

    D.print("send to canister a wallet");
    D.print(debug_show (a_wallet_send_tokens_to_canister));

    let block = switch (a_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    //sent an escrow for a ledger deposit that doesn't exist
    let a_wallet_try_recognize_general_staged_fake_amount = await a_wallet.try_recognize_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), null, 2 * 10 ** 8, null, null);

    ////need to resend amount because last amount was refunded

    let a_wallet_send_tokens_to_canister2 = await a_wallet.send_ledger_escrow(
      Principal.fromActor(dfx),
      {
        seller = #principal(Principal.fromActor(canister));
        buyer = #principal(Principal.fromActor(a_wallet));
        token_id = "";
        token = #ic({
          canister = Principal.fromActor(dfx);
          standard = #Ledger;
          decimals = 8;
          symbol = "LDG";
          fee = ?200000;
          id = null;
        });
        amount = 100_000_000;
      },
      Principal.fromActor(canister),
    );

    ////ESC0001

    D.print("Sending real escrow now");
    let a_wallet_try_recognize_general_staged = await a_wallet.try_recognize_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, null, null);

    D.print("try escrow genreal stage");
    D.print(debug_show (a_wallet_try_recognize_general_staged));

    //should succeed if you try to calim a recognize a second time
    let a_wallet_try_escrow_general_staged_retry = await a_wallet.try_recognize_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, null, null);

    D.print("try escrow genreal stage retry");
    D.print(debug_show (a_wallet_try_escrow_general_staged_retry));

    //check balance and make sure we see the escrow and that it is only 1 * 10 ** 8
    let a_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    D.print("thebalance");
    D.print(debug_show (a_balance));

    //MKT0007, MKT0014
    D.print("blind market");
    let blind_market = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(canister));
          buyer = #principal(Principal.fromActor(a_wallet));
          token_id = "";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };

    });

    D.print(debug_show (blind_market));

    //MKT0014 todo: check the transaction record and confirm the gensis reocrd

    //BAL0005
    let b_balance2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet)));

    //BAL0003
    let canister_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(canister)));

    //MKT0013, MKT0011 this item should be minted now
    let test_metadata = await canister.nft_origyn("1");
    D.print("This thing should have been minted");
    D.print(debug_show (test_metadata));
    switch (test_metadata) {
      case (#ok(val)) {
        D.print(debug_show (Metadata.is_minted(val.metadata)));
      };
      case (_) {};
    };

    //ESC0009
    let blind_market2 = await canister.market_transfer_nft_origyn({
      token_id = "2";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(canister));
          buyer = #principal(Principal.fromActor(a_wallet));
          token_id = "";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };

    });

    D.print("This thing should have not been minted either");
    D.print(debug_show (blind_market2));

    //mint the second item to test a specific sale
    let mint_attempt2 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this)));

    //mint the third item to test a specific sale
    let mint_attempt3 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));

    D.print("mint attempt 3");
    D.print(debug_show (mint_attempt3));

    //creae an new wallet for testing

    //send a payment to the the new owner(this actor- after mint)
    D.print("sending tokens to canisters");

    let b_wallet_send_tokens_to_canister = await b_wallet.send_ledger_escrow(
      Principal.fromActor(dfx),
      {
        seller = #principal(Principal.fromActor(this));
        buyer = #principal(Principal.fromActor(b_wallet));
        token_id = "2";
        token = #ic({
          canister = Principal.fromActor(dfx);
          standard = #Ledger;
          decimals = 8;
          symbol = "LDG";
          fee = ?200000;
          id = null;
        });
        amount = 100_000_000;
      },
      Principal.fromActor(canister),
    );

    D.print("send to canister b wallet");
    D.print(debug_show (b_wallet_send_tokens_to_canister));

    let b_block = switch (b_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    let b_wallet_send_tokens_to_canister2 = await b_wallet.send_ledger_escrow(
      Principal.fromActor(dfx),
      {
        seller = #principal(Principal.fromActor(this));
        buyer = #principal(Principal.fromActor(b_wallet));
        token_id = "3";
        token = #ic({
          canister = Principal.fromActor(dfx);
          standard = #Ledger;
          decimals = 8;
          symbol = "LDG";
          fee = ?200000;
          id = null;
        });
        amount = 100_000_000;
      },
      Principal.fromActor(canister),
    );

    D.print("send to canister b wallet 2");
    D.print(debug_show (b_wallet_send_tokens_to_canister2));

    let b_block2 = switch (b_wallet_send_tokens_to_canister2) {
      case (#ok(ablock)) {
        D.print(debug_show (ablock));
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    D.print("trying to recognize for wrong owner");
    //make sure a user can't escrow for an owner that doesn't own NFT
    let b_wallet_try_recognize_escrow_wrong_owner = await b_wallet.try_recognize_escrow_specific_staged(Principal.fromActor(a_wallet), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "3", null, null, null);
    D.print("b_wallet_try_escrow_wrong_owner: " # debug_show (b_wallet_try_recognize_escrow_wrong_owner));

    D.print(debug_show (b_wallet_try_recognize_escrow_wrong_owner));

    D.print("trying to recongize escrow for token 2");
    //make sure we can recognize an escrow for a specific item
    let b_wallet_try_recognize_escrow_specific = await b_wallet.try_recognize_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "2", null, null, null);

    D.print(debug_show (b_wallet_try_recognize_escrow_specific));

    //MKT0010
    D.print("apecific market");
    let specific_market = await canister.market_transfer_nft_origyn({
      token_id = "3";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(this));
          buyer = #principal(Principal.fromActor(b_wallet));
          token_id = "3";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };

    });

    D.print(debug_show (specific_market));

    //test balances
    D.print(debug_show ("ready to start testing"));

    let suite = S.suite(
      "test recognize escrow Nft",
      [

        S.test(
          "fail if no escrow exists for general staged sale b",
          switch (blind_market_fail) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              D.print("fail if no escrow exists for general staged sale has error");
              if (err.number == 3011) {
                //since the requestor isnt the owner and this isnt minted we wont reveal it is a real token
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0015
        S.test(
          "fail if non owner trys to sell b",
          switch (a_wallet_try_staged_market) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              D.print("fail if non owner trys to sell has error");
              if (err.number == 4) {
                //no escrow
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0008
        S.test(
          "owner can sell staged NFT - produces transaction",
          switch (blind_market) {
            case (#ok(res)) {
              D.print("found blind market response");
              D.print(debug_show (res));
              if (res.index == 0) {
                "found genesis record id";
              } else {
                "no sales id ";
              };
            };
            case (#err(err)) {
              D.print("blind market has error");
              "unexpected error: " # err.flag_point # debug_show (err);
            };
          },
          M.equals<Text>(T.text("found genesis record id")),
        ), //MKT0007, MKT0014
        S.test(
          "fail if escrow is double processed",
          switch (a_wallet_try_escrow_general_staged_retry) {
            case (#ok(res)) {
              if (res.balance == 100_000_000) {
                "correct response";
              } else {
                "wrong response" # debug_show (res);
              };
            };
            case (#err(err)) {

              "wrong error " # debug_show (err.number);

            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //ESC0005
        S.test(
          "item is minted now",
          switch (test_metadata) {
            case (#ok(res)) {
              if (Metadata.is_minted(res.metadata) == true) {
                "was minted";
              } else {
                "was not minted";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("was minted")),
        ), //MKT0013
        S.test(
          "item is owned by correct owner after minting",
          switch (test_metadata) {
            case (#ok(res)) {
              if (
                Types.account_eq(
                  switch (Metadata.get_nft_owner(res.metadata)) {
                    case (#err(err)) {
                      #account_id("invalid");
                    };
                    case (#ok(val)) {
                      D.print(debug_show (val));
                      val;
                    };
                  },
                  #principal(Principal.fromActor(a_wallet)),
                ) == true
              ) {
                "was transfered";
              } else {
                D.print("testing owner was not transfered");
                D.print("awallet");
                D.print(debug_show (Principal.fromActor(a_wallet)));
                "was not transfered";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("was transfered")),
        ), //MKT0011

        S.test(
          "fail if escrow already spent b",
          switch (blind_market2) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              D.print("blind market 2 error");
              if (err.number == 3011) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0009
        S.test(
          "fail if escrowing for a specific item and it is only staged",
          switch (a_wallet_try_recognize_escrow_specific_staged) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              D.print("a wallet escrow specific error");
              if (err.number == 4) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0003
        S.test(
          "fail if escrowing for a non existant deposit b",
          switch (a_wallet_try_recognize_general_staged_fake) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              D.print("a wallet recognize general staged fake error");
              if (err.number == 3011) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0006
        S.test(
          "fail if escrowing for an existing deposit but fake amount b",
          switch (a_wallet_try_recognize_general_staged_fake_amount) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              D.print("a wallet try recognize stage fake amount");
              if (err.number == 3011) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0011
        S.test(
          "can escrow for general unminted item",
          switch (a_wallet_try_recognize_general_staged) {
            case (#ok(res)) {
              D.print("an amount for escrow");
              D.print(debug_show (res.receipt));
              if (res.receipt.amount == 1 * 10 ** 8) {
                "was escrowed";
              } else {
                "was not escrowed";
              };
            };
            case (#err(err)) {
              D.print("a wallet try recognize general error");
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("was escrowed")),
        ), //ESC0002
        S.test(
          "escrow deposit transaction",
          switch (a_wallet_try_recognize_general_staged) {
            case (#ok(res)) {
              D.print("escrow deposit transaction ok");

              switch (res.transaction) {
                case (?val) {
                  switch (val.txn_type) {
                    case (#escrow_deposit(details)) {
                      if (
                        Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and Types.account_eq(details.seller, #principal(Principal.fromActor(canister))) and details.amount == ((1 * 10 ** 8)) and details.token_id == "" and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                      ) {
                        "correct response";
                      } else {
                        "details didnt match" # debug_show (details);
                      };
                    };
                    case (_) {
                      "bad history sale";
                    };
                  };
                };

                case (null) {
                  "bad history sale null";
                };
              };
            };
            case (#err(err)) {
              D.print("escrow deposit transaction error");
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //NFT-72
        S.test(
          "can't escrow for wrong NFT owner",
          switch (b_wallet_try_recognize_escrow_wrong_owner) {
            case (#err(err)) {
              D.print("wrong owner error");
              if (err.number == 3002) {
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
            case (#ok(res)) {
              "unexpected success: " # debug_show (res);
            };
          },
          M.equals<Text>(T.text("correct number")),
        ),
        S.test(
          "can escrow for specific item",
          switch (b_wallet_try_recognize_escrow_specific) {
            case (#ok(res)) {
              D.print("escrow sepecific ok");
              if (res.receipt.amount == 1 * 10 ** 8) {
                "was escrowed";
              } else {
                "was not escrowed";
              };
            };
            case (#err(err)) {
              D.print("escrow specific error");
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("was escrowed")),
        ), //ESC0001
        S.test(
          "owner can sell specific NFT - produces sale_id",
          switch (specific_market) {
            case (#ok(res)) {
              D.print("specific market ok");
              if (res.token_id == "3") {
                "found tx record";
              } else {
                D.print(debug_show (res));
                "no sales id ";
              };
            };
            case (#err(err)) {
              D.print("specific market error");
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found tx record")),
        ), //MKT0010
        S.test(
          "escrow balance is shown",
          switch (a_balance) {
            case (#ok(res)) {
              D.print("escrow balance ok");
              D.print(debug_show (res));
              D.print(debug_show (#principal(Principal.fromActor(canister))));
              D.print(debug_show (#principal(Principal.fromActor(a_wallet))));
              D.print(debug_show (Principal.fromActor(dfx)));
              D.print("escrow size" # debug_show (res.escrow.size()));
              if (
                Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(canister))) and Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet))) and res.escrow[0].token_id == "" and Types.token_eq(res.escrow[0].token, #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
              ) {
                "found escrow record";
              } else {
                D.print(debug_show (res));
                "didnt find record ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found escrow record")),
        ), //BAL0001

      ],
    );

    S.run(suite);

    return #success;
  };

  public shared func testRoyalties() : async { #success; #fail : Text } {
    D.print("running testRoyalties");
    D.print("making wallets");

    let a_wallet = await TestWalletDef.test_wallet(); //purchaser
    let b_wallet = await TestWalletDef.test_wallet(); //broker
    let n_wallet = await TestWalletDef.test_wallet(); //node
    let o_wallet = await TestWalletDef.test_wallet(); //originator
    let net_wallet = await TestWalletDef.test_wallet(); //net

    let net_account = {
      owner = Principal.fromActor(net_wallet);
      subaccount = ?Royalties.get_network_royalty_account(Principal.fromActor(dfx), null);
    };

    let alist = [
      ("ICP", "ryjl3-tyaaa-aaaaa-aaaba-cai"),
      ("OGY", "jwcfb-hyaaa-aaaaj-aac4q-cai"),
      ("ckBTC", "mxzaz-hqaaa-aaaar-qaada-cai"),
      ("CHAT", "2ouva-viaaa-aaaaq-aaamq-cai"),
      ("SNS-1", "zfcdd-tqaaa-aaaaq-aaaga-cai"),

    ];

    for (thisItem in alist.vals()) {
      D.print("codes for network:" # debug_show ((thisItem.0, thisItem.1, { owner = Principal.fromText("a3lu7-uiaaa-aaaaj-aadnq-cai"); subaccount = ?Royalties.get_network_royalty_account(Principal.fromText(thisItem.1), null) }, AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromText("a3lu7-uiaaa-aaaaj-aadnq-cai"), ?Royalties.get_network_royalty_account(Principal.fromText(thisItem.1), null))))));
    };

    D.print("have the net account " # debug_show (net_account));

    D.print("making factory");

    let newPrincipal = try {
      await g_canister_factory.create({
        owner = Principal.fromActor(this);
        storage_space = null;
      });
    } catch (e) {
      D.print(Error.message(e));
      return #fail(Error.message(e));
    };

    let noBrokerPrincipal = try {
      await g_canister_factory.create({
        owner = Principal.fromActor(this);
        storage_space = null;
      });
    } catch (e) {
      D.print(Error.message(e));
      return #fail(Error.message(e));
    };

    D.print("have canister");

    let canister : Types.Service = actor (Principal.toText(newPrincipal));
    let standardStage_collection = await utils.buildCollection(
      canister,
      Principal.fromActor(canister),
      Principal.fromActor(n_wallet),
      Principal.fromActor(this),
      2048000,
      false,
      dfxspec,
    );

    let updateNetwork = canister.collection_update_nft_origyn(#UpdateNetwork(?Principal.fromActor(net_wallet)));

    D.print("calling stage");

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));
    let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));

    let mint_attempt3 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this)));
    let mint_attempt4 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));

    D.print("finished stage");
    D.print(debug_show (standardStage.0));

    let noBrokerCanister : Types.Service = actor (Principal.toText(noBrokerPrincipal));

    let standardStage_collection_noBroker = await utils.buildCollection(
      noBrokerCanister,
      Principal.fromActor(noBrokerCanister),
      Principal.fromActor(n_wallet),
      Principal.fromActor(this),
      2048000,
      true,
      dfxspec,
    );

    D.print("has broker canister");
    D.print(debug_show (newPrincipal));

    D.print("no broker canister");
    D.print(debug_show (noBrokerPrincipal, standardStage_collection_noBroker));

    let standardStage_no_broker = await utils.buildStandardNFT("1", noBrokerCanister, Principal.fromActor(noBrokerCanister), 1024, false, Principal.fromActor(o_wallet));

    D.print("stage no broker");
    D.print(debug_show (standardStage_no_broker));

    let mint_attempt6 = await noBrokerCanister.mint_nft_origyn("1", #principal(Principal.fromActor(this)));

    D.print("mint no broker");
    D.print(debug_show (mint_attempt6));

    //fund a_wallet
    let funding_result = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    D.print("funding result a");
    D.print(debug_show (funding_result));

    let funding_result2 = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    //send a payment to the ledger
    D.print("sending tokens to canisters");
    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (5 * 10 ** 8) + 400000, Principal.fromActor(canister));

    D.print("send to canister a wallet royalties");
    D.print(debug_show (a_wallet_send_tokens_to_canister));

    let block = switch (a_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    D.print("Sending real escrow now");
    let a_wallet_try_escrow_general_staged = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, null, null);

    D.print("try escrow genreal stage");
    D.print(debug_show (a_wallet_try_escrow_general_staged));

    let a_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    D.print("network account is " # debug_show (net_account));
    let net_balance = await dfx.icrc1_balance_of(net_account);

    D.print("initial balances " # debug_show (a_balance, b_balance, n_balance, o_balance, canister_balance, net_balance));
    D.print("primary sale");
    let primary_sale = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(canister));
          buyer = #principal(Principal.fromActor(a_wallet));
          token_id = "";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = ? #principal(Principal.fromActor(b_wallet));
      };

    });

    D.print("primary_sale ");
    D.print(debug_show (primary_sale));

    //create fake wallet for time duration
    let fake_wallet1 = await TestWalletDef.test_wallet();
    //create fake wallet for time duration
    let fake_wallet2 = await TestWalletDef.test_wallet();
    let fake_wallet22 = await TestWalletDef.test_wallet();
    let fake_wallet23 = await TestWalletDef.test_wallet();
    let fake_wallet24 = await TestWalletDef.test_wallet();
    let fake_wallet235 = await TestWalletDef.test_wallet();
    let fake_wallet246 = await TestWalletDef.test_wallet();

    //MKT0014 todo: check the transaction record and confirm the gensis reocrd

    //BAL0005
    let a_balance2 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance2 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance2 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance2 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance2 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    let net_balance2 = await dfx.icrc1_balance_of(net_account);

    D.print("a wallet " # debug_show ((a_balance, a_balance2)));
    D.print("b wallet " # debug_show ((b_balance, b_balance2)));
    D.print("n wallet " # debug_show ((n_balance, n_balance2)));
    D.print("o wallet " # debug_show ((o_balance, o_balance2)));
    D.print("canister wallet " # debug_show ((canister_balance, canister_balance2)));
    D.print("net wallet " # debug_show ((net_balance, net_balance2)));

    let test_metadata = await canister.nft_origyn("1");

    D.print("Sending real escrow now");
    let a_wallet_try_escrow_specific_staged = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "2", null, null, null);

    //MKT0010
    D.print("secondary sale");
    let specific_market = await canister.market_transfer_nft_origyn({
      token_id = "2";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(this));
          buyer = #principal(Principal.fromActor(a_wallet));
          token_id = "2";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = ? #principal(Principal.fromActor(b_wallet));
      };

    });

    //create fake wallet for time duration
    let fake_wallet14 = await TestWalletDef.test_wallet();
    //create fake wallet for time duration
    let fake_wallet25 = await TestWalletDef.test_wallet();
    let fake_wallet2e25 = await TestWalletDef.test_wallet();
    let fake_wallet23e5 = await TestWalletDef.test_wallet();
    let fake_wallet245 = await TestWalletDef.test_wallet();
    let fake_wallet2355 = await TestWalletDef.test_wallet();
    let fake_wallet2465 = await TestWalletDef.test_wallet();

    D.print("secondary result" # debug_show (specific_market));

    let a_balance3 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance3 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance3 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance3 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance3 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    let net_balance3 = await dfx.icrc1_balance_of(net_account);

    D.print("a wallet " # debug_show ((a_balance, a_balance2, a_balance3)));
    D.print("b wallet " # debug_show ((b_balance, b_balance2, b_balance3)));
    D.print("n wallet " # debug_show ((n_balance, n_balance2, n_balance3)));
    D.print("o wallet " # debug_show ((o_balance, o_balance2, o_balance3)));
    D.print("canister wallet " # debug_show ((canister_balance, canister_balance2, canister_balance3)));
    D.print("net wallet " # debug_show ((net_balance, net_balance2, net_balance3)));

    //withdraw sale
    //let #ok(b_withdraw) = b_balance2;
    //D.print(debug_show(b_withdraw));
    //let #principal(b_buyer) = b_withdraw.sales[0].buyer;

    D.print(debug_show (Principal.fromActor(b_wallet)));
    //D.print(debug_show(b_buyer));

    //let b_withdraw_attempt_sale = await b_wallet.try_sale_withdraw(Principal.fromActor(canister), b_buyer, Principal.fromActor(dfx), Principal.fromActor(b_wallet), "", b_withdraw.sales[0].amount, null);
    //D.print("withdraw 1 for b was " # debug_show(b_withdraw_attempt_sale));
    //D.print("trying withdraw2");
    //let #ok(b_withdraw2) = b_balance3;
    //D.print("withdraw 2 " # debug_show(b_withdraw2));
    //let #principal(b_buyer2) = b_withdraw2.sales[1].buyer;
    //let b_withdraw_attempt_sale2 = await b_wallet.try_sale_withdraw(Principal.fromActor(canister), b_buyer2, Principal.fromActor(dfx), Principal.fromActor(b_wallet), "2", b_withdraw2.sales[1].amount, null);

    //let b_balance4 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet)));

    //D.print("did I get my tokens " # debug_show(b_withdraw_attempt_sale));
    //D.print("did I get my tokens2 " # debug_show(b_withdraw_attempt_sale2));

    //start an auction by owner
    let start_auction_attempt_owner = await canister.market_transfer_nft_origyn({
      token_id = "3";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #auction {
          reserve = ?(1 * 10 ** 8);
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          buy_now = ?(500 * 10 ** 8);
          start_price = (1 * 10 ** 8);
          start_date = 0;
          ending = #date(get_time() + DAY_LENGTH);
          min_increase = #amount(10 * 10 ** 8);
          allow_list = null;
        };
      };
    });

    D.print("get sale id");
    let current_sales_id = switch (start_auction_attempt_owner) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };

      };
      case (#err(item)) {
        D.print("error with auction start");
        return #fail("error with auction start");
      };
    };

    //place escrow
    let end_date = get_time() + DAY_LENGTH + DAY_LENGTH;
    D.print("sending tokens to canisters");

    //balance should be 2 ICP + 400000

    D.print("Sending real escrow now a wallet trye scrow");
    //claiming first escrow
    let a_wallet_try_escrow_general_staged2 = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "3", ?current_sales_id, null, null);

    //place a valid bid MKT0027
    let a_wallet_try_bid_valid = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 8, "3", current_sales_id, ?Principal.fromActor(b_wallet), null);
    D.print("a_wallet_try_bid_valid " # debug_show (a_wallet_try_bid_valid));

    //create fake wallet for time duration
    let fake_wallet3 = await TestWalletDef.test_wallet();
    //create fake wallet for time duration
    let fake_wallet4 = await TestWalletDef.test_wallet();
    //create fake wallet for time duration
    let fake_wallet5 = await TestWalletDef.test_wallet();
    let fake_wallet57 = await TestWalletDef.test_wallet();
    let fake_wallet58 = await TestWalletDef.test_wallet();
    let fake_wallet575 = await TestWalletDef.test_wallet();
    let fake_wallet585 = await TestWalletDef.test_wallet();

    //advance time
    let mode = canister.__set_time_mode(#test);
    let time_result = await canister.__advance_time(end_date + 1);
    D.print("new time");
    D.print(debug_show (time_result));

    //end auction
    let end_proper = await canister.sale_nft_origyn(#end_sale("3"));
    D.print("end proper");
    D.print(debug_show (end_proper));

    //create wallets to force rounds
    let fake_wallet66 = await TestWalletDef.test_wallet();
    let fake_wallet67 = await TestWalletDef.test_wallet();
    let fake_wallet78 = await TestWalletDef.test_wallet();
    let fake_wallet69 = await TestWalletDef.test_wallet();
    let fake_wallet79 = await TestWalletDef.test_wallet();
    let fake_wallet697 = await TestWalletDef.test_wallet();
    let fake_wallet797 = await TestWalletDef.test_wallet();

    let a_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    let net_balance5 = await dfx.icrc1_balance_of(net_account);

    D.print("a wallet " # debug_show ((Principal.fromActor(a_wallet), a_balance, a_balance2, a_balance3, a_balance5)));
    D.print("b wallet " # debug_show ((Principal.fromActor(b_wallet), b_balance, b_balance2, b_balance3, b_balance5)));
    D.print("n wallet " # debug_show ((Principal.fromActor(n_wallet), n_balance, n_balance2, n_balance3, n_balance5)));
    D.print("o wallet " # debug_show ((Principal.fromActor(o_wallet), o_balance, o_balance2, o_balance3, o_balance5)));
    D.print("canister wallet " # debug_show ((Principal.fromActor(canister), canister_balance, canister_balance2, canister_balance3, canister_balance5)));
    D.print("net wallet " # debug_show ((Principal.fromActor(net_wallet), net_balance, net_balance2, net_balance3, net_balance5)));
    //test balances

    D.print("sending tokens to canisters");
    let a_wallet_send_tokens_to_canister_no_broker = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (1 * 10 ** 8) + 400000, Principal.fromActor(noBrokerCanister));

    D.print("send deposit for no broker " # debug_show (a_wallet_send_tokens_to_canister_no_broker));

    D.print("Sending real escrow now for no broker");
    let a_wallet_try_escrow_specific_staged_no_broker = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(noBrokerCanister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "1", null, null, null);

    D.print("secondary sale for no broker " # debug_show (a_wallet_try_escrow_specific_staged_no_broker));

    let specific_market3 = await noBrokerCanister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(this));
          buyer = #principal(Principal.fromActor(a_wallet));
          token_id = "1";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };

    });

    D.print("secondary result no broker" # debug_show (specific_market3));

    //advance time
    let mode2 = canister.__set_time_mode(#test);
    let time_result2 = await canister.__advance_time(end_date + 4);
    D.print("new time");
    D.print(debug_show (time_result2));

    //create wallets to force rounds
    let fake_wallet8 = await TestWalletDef.test_wallet();
    let fake_wallet9 = await TestWalletDef.test_wallet();
    let fake_wallet10 = await TestWalletDef.test_wallet();
    let fake_wallet854 = await TestWalletDef.test_wallet();
    let fake_wallet956 = await TestWalletDef.test_wallet();
    let fake_wallet1076 = await TestWalletDef.test_wallet();

    let a_balance6 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance6 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance6 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance6 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance6 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    let net_balance6 = await dfx.icrc1_balance_of(net_account);

    D.print("a wallet 6 " # debug_show ((a_balance6)));
    D.print("b wallet 6 " # debug_show ((b_balance6)));
    D.print("n wallet 6 " # debug_show ((n_balance6)));
    D.print("o wallet 6 " # debug_show ((o_balance6)));
    D.print("canister wallet 6 " # debug_show ((canister_balance6)));
    D.print("net wallet 6 " # debug_show ((net_balance6)));

    let suite = S.suite(
      "test royalties",
      [

        S.test("fail if node does not get royalty", n_balance2, M.equals<Nat>(T.nat(7561446))),
        S.test("fail if broker does not get royalty", b_balance2, M.equals<Nat>(T.nat(100005788000))),
        S.test("fail if network does not get royalty", net_balance2, M.equals<Nat>(T.nat(299000))),
        S.test("fail if node does not get second royalty", n_balance3, M.equals<Nat>(T.nat(9357446))),
        S.test("fail if broker does not get second royalty", b_balance3, M.equals<Nat>(T.nat(100006586000))),
        S.test("fail if network does not get second royalty", net_balance3, M.equals<Nat>(T.nat(598000))),
        S.test("fail if originator does not get first royalty", o_balance3, M.equals<Nat>(T.nat(3126633))),
        //S.test("fail if broker still has balance after withdraw", b_balance4.e8s, M.equals<Nat>(T.nat(6))),
        S.test("fail if node does not get third royalty", n_balance5, M.equals<Nat>(T.nat(11153446))),
        S.test("fail if broker does not get new royalty", b_balance5, M.equals<Nat>(T.nat(100007384000))),
        S.test("fail if network does not get third royalty", net_balance5, M.equals<Nat>(T.nat(897000))),
        S.test("fail if originator does not get second royalty", o_balance5, M.equals<Nat>(T.nat(6253266))),

      ],
    );

    S.run(suite);

    return #success;
  };

  public shared func testRoyaltiesFixed() : async { #success; #fail : Text } {
    D.print("running testRoyaltiesFixed");
    D.print("making wallets");

    let a_wallet = await TestWalletDef.test_wallet(); //purchaser
    let b_wallet = await TestWalletDef.test_wallet(); //broker
    let n_wallet = await TestWalletDef.test_wallet(); //node
    let o_wallet = await TestWalletDef.test_wallet(); //originator
    let net_wallet = await TestWalletDef.test_wallet(); //net

    let net_account = {
      owner = Principal.fromActor(net_wallet);
      subaccount = ?Royalties.get_network_royalty_account(Principal.fromActor(dfx), null);
    };

    D.print("have the net account " # debug_show (net_account));

    D.print("making factory");

    let newPrincipal = try {
      await g_canister_factory.create({
        owner = Principal.fromActor(this);
        storage_space = null;
      });
    } catch (e) {
      D.print(Error.message(e));
      return #fail(Error.message(e));
    };

    let noBrokerPrincipal = try {
      await g_canister_factory.create({
        owner = Principal.fromActor(this);
        storage_space = null;
      });
    } catch (e) {
      D.print(Error.message(e));
      return #fail(Error.message(e));
    };

    D.print("have canister");

    let canister : Types.Service = actor (Principal.toText(newPrincipal));
    let icrc7_canister : ICRC7Types.Service = actor (Principal.toText(newPrincipal));

    let standardStage_collection = await utils.buildCollection(
      canister,
      Principal.fromActor(canister),
      Principal.fromActor(n_wallet),
      Principal.fromActor(this),
      2048000,
      false,
      dfxspec,
    );

    let updateNetwork = canister.collection_update_nft_origyn(#UpdateNetwork(?Principal.fromActor(net_wallet)));

    D.print("calling stage");

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));
    let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));

    let mint_attempt2 = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(this)));
    let mint_attempt3 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this)));
    let mint_attempt4 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));

    D.print("finished stage");
    D.print(debug_show (standardStage.0));

    //fund a_wallet
    let funding_result = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    D.print("funding result a");
    D.print(debug_show (funding_result));

    let funding_result2 = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    //send a payment to the ledger
    D.print("sending tokens to canisters");
    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (5 * 10 ** 8) + 400000, Principal.fromActor(canister));

    D.print("send to canister a wallet royalties");
    D.print(debug_show (a_wallet_send_tokens_to_canister));

    let block = switch (a_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    let a_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    D.print("network account is " # debug_show (net_account));
    let net_balance = await dfx.icrc1_balance_of(net_account);
    D.print("a_balance " # debug_show ((Principal.fromActor(a_wallet), a_balance)));
    D.print("b_balance " # debug_show ((Principal.fromActor(b_wallet), b_balance)));
    D.print("n_balance " # debug_show ((Principal.fromActor(n_wallet), n_balance)));
    D.print("o_balance " # debug_show ((Principal.fromActor(o_wallet), o_balance)));
    D.print("canister wallet " # debug_show ((Principal.fromActor(canister), canister_balance)));

    D.print(debug_show (Principal.fromActor(b_wallet)));

    let #ok(#fee_deposit_info(sellerFeeDepositAccount)) = await canister.sale_info_nft_origyn(#fee_deposit_info(? #account { owner = Principal.fromActor(this); sub_account = null })) else {
      D.print("failed to get sellerFeeDepositAccount");
      return #fail("failed to get sellerFeeDepositAccount");
    };

    let fee_deposit_request : Types.FeeDepositRequest = {
      account = #account({
        owner = Principal.fromActor(this);
        sub_account = null;
      });
      token = #ic({
        canister = Principal.fromActor(dfx);
        standard = #Ledger;
        decimals = 8;
        symbol = "LDG";
        fee = ?200000;
        id = null;
      });
    };

    let fee_deposit_ret = await canister.sale_nft_origyn(#fee_deposit(fee_deposit_request));
    D.print("fee_deposit_ret = " # debug_show (fee_deposit_ret));
    // no fund has been sent to fees wallet, balance = 0
    switch (fee_deposit_ret) {
      case (#ok(val)) {
        switch (val) {
          case (#fee_deposit(info)) {
            if (info.balance != 0) {
              return #fail("Balance should be == 0");
            };
          };
          case (_) {
            return #fail("Should have returned a #fee_deposit");
          };
        };
      };
      case (_) {
        return #fail("sale_nft_origyn #fee_deposit failed : Should have returned a #ok(#fee_deposit)");
      };
    };

    let add_fund_to_fees_wallet = await dfx.icrc1_transfer({
      to = {
        owner = sellerFeeDepositAccount.account.principal;
        subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
      };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 10 * 10 ** 8;
    });

    let fee_wallet_balance = await dfx.icrc1_balance_of({
      owner = sellerFeeDepositAccount.account.principal;
      subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
    });
    D.print("fee_wallet_balance = " # debug_show (fee_wallet_balance));

    let fee_deposit_ret2 = await canister.sale_nft_origyn(#fee_deposit(fee_deposit_request));
    D.print("fee_deposit_ret2 = " # debug_show (fee_deposit_ret2));
    // fund has been sent to fees wallet, balance > 0
    switch (fee_deposit_ret2) {
      case (#ok(val)) {
        switch (val) {
          case (#fee_deposit(info)) {
            if (info.balance == 0) {
              return #fail("Balance should be > 0");
            };
          };
          case (_) {
            return #fail("Should have returned a #fee_deposit");
          };
        };
      };
      case (_) {
        return #fail("sale_nft_origyn #fee_deposit failed : Should have returned a #ok(#fee_deposit)");
      };
    };

    let _invalid_option_buffer_array = [
      (
        Buffer.fromArray<MigrationTypes.Current.AskFeature>([#reserve(1), #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })), #buy_now(1), #start_price(1), #ending(#date(get_time() + DAY_LENGTH)), #fee_accounts(["com.origyn.royalty.node"]), #fee_schema("com.origyn.royalties.fixed")]),
        "market_transfer_nft_origyn - start price cannot be less than mininal fee",
        "auction should have fail with startprice < all fees that user has to pay",
      ),
      (
        Buffer.fromArray<MigrationTypes.Current.AskFeature>([#reserve(1 * 10 ** 8), #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })), #buy_now(1 * 10 ** 8), #start_price(1 * 10 ** 8), #ending(#date(get_time() + DAY_LENGTH)), #fee_accounts(["com.origyn.royalty.AAAAAA"]), #fee_schema("com.origyn.royalties.fixed")]),
        "market_transfer_nft_origyn bad royalty name = \"com.origyn.royalty.AAAAAA\" and should be one of [\"com.origyn.royalty.broker\", \"com.origyn.royalty.node\", \"com.origyn.royalty.originator\", \"com.origyn.royalty.custom\", \"com.origyn.royalty.network\"]",
        "auction should have fail with bad royalty name = \"com.origyn.royalty.AAAAAA\"",
      ),
      (
        Buffer.fromArray<MigrationTypes.Current.AskFeature>([#reserve(1 * 10 ** 8), #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })), #buy_now(1 * 10 ** 8), #start_price(1 * 10 ** 8), #ending(#date(get_time() + DAY_LENGTH)), #fee_accounts(["com.origyn.royalty.node"]), #fee_schema("com.origyn.royalties.fixedAAAA")]),
        "market_transfer_nft_origyn fee_accounts need fixed fee_schema. Not compatible yet others royalties schema.",
        "auction should have fail with fee_accounts need fixed fee_schema",
      ),
      (
        Buffer.fromArray<MigrationTypes.Current.AskFeature>([#reserve(1 * 10 ** 8), #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })), #buy_now(1 * 10 ** 8), #start_price(1 * 10 ** 8), #ending(#date(get_time() + DAY_LENGTH)), #fee_accounts(["com.origyn.royalty.node"])]),
        "market_transfer_nft_origyn fee_accounts need fixed fee_schema. Not compatible yet others royalties schema.",
        "auction should have fail with fee_accounts need fixed fee_schema",
      ),
    ];

    for ((_invalid_option_buffer, err_msg_return, err_msg_to_print_in_case_of_error) in _invalid_option_buffer_array.vals()) {
      D.print("sellerFeeDepositAccount = " # debug_show (sellerFeeDepositAccount));
      let start_auction_attempt_owner = await canister.market_transfer_nft_origyn({
        token_id = "3";
        sales_config = {
          escrow_receipt = null;
          broker_id = null;
          pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(_invalid_option_buffer));
        };
      });

      switch (start_auction_attempt_owner) {
        case (#ok(val)) {
          D.print(err_msg_to_print_in_case_of_error);
          return #fail("error with auction start");
        };
        case (#err(item)) {
          if (item.flag_point != err_msg_return) {
            D.print("error with auction start");
            D.print(item.flag_point);
            return #fail("error with auction start");
          };
        };
      };
    };

    // This one should not fail
    D.print("sellerFeeDepositAccount = " # debug_show (sellerFeeDepositAccount));
    let option_buffer2 = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(1 * 10 ** 8),
      #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),
      #buy_now(1 * 10 ** 8),
      #start_price(1 * 10 ** 8),
      #ending(#date(get_time() + DAY_LENGTH)),
      #fee_accounts(["com.origyn.royalty.node"]),
      #fee_schema("com.origyn.royalties.fixed"),
    ]);

    let start_auction_attempt_owner2 = await canister.market_transfer_nft_origyn({
      token_id = "3";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer2));
      };
    });

    D.print("get sale id");
    // verify that auction fail with startprice < all fees that user has to pay
    let current_sales_id = switch (start_auction_attempt_owner2) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };

      };
      case (#err(item)) {
        D.print("error with auction start");
        D.print(item.flag_point);
        return #fail("error with auction start");
      };

    };

    //claiming first escrow
    let a_wallet_try_escrow_general_staged2 = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "3", ?current_sales_id, null, null);

    //place a valid bid MKT0027
    let a_wallet_try_bid_valid = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 8, "3", current_sales_id, ?Principal.fromActor(b_wallet), null);
    D.print("a_wallet_try_bid_valid " # debug_show (a_wallet_try_bid_valid));

    //end auction
    let end_proper_2 = await canister.sale_nft_origyn(#end_sale("3"));
    D.print("end_proper_2");
    D.print(debug_show (end_proper_2));

    //place escrow
    let end_date = get_time() + DAY_LENGTH + DAY_LENGTH;
    D.print("sending tokens to canisters");

    //balance should be 2 ICP + 400000

    let try_withdraw_locked_fee_deposit = await canister.sale_nft_origyn(#withdraw(#fee_deposit({ account = #account({ owner = Principal.fromActor(this); sub_account = null }); token = #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }); amount = 10 * 10 ** 8; withdraw_to = #account({ owner = Principal.fromActor(a_wallet); sub_account = null }); status = #unlocked() })));
    D.print("try_withdraw_locked_fee_deposit " # debug_show (try_withdraw_locked_fee_deposit));

    let option_buffer3 = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(1 * 10 ** 8),
      #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),
      #buy_now(1 * 10 ** 8),
      #start_price(1 * 10 ** 8),
      #ending(#date(get_time() + DAY_LENGTH)),
      #fee_accounts([
        "com.origyn.royalty.node",
        "com.origyn.royalty.broker",
        "com.origyn.royalty.originator",
        "com.origyn.royalty.custom",
        "com.origyn.royalty.network",
      ]),
      #fee_schema("com.origyn.royalties.fixed"),
    ]);

    let start_auction_attempt_owner3 = await canister.market_transfer_nft_origyn({
      token_id = "2";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer3));
      };
    });

    let try_withdraw_locked_fee_deposit_2 = await canister.sale_nft_origyn(#withdraw(#fee_deposit({ account = #account({ owner = Principal.fromActor(this); sub_account = null }); token = #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }); amount = 10 * 10 ** 8; withdraw_to = #account({ owner = Principal.fromActor(a_wallet); sub_account = null }); status = #unlocked() })));
    D.print("try_withdraw_locked_fee_deposit_2 " # debug_show (try_withdraw_locked_fee_deposit_2));

    let end_proper = await canister.sale_nft_origyn(#end_sale("2"));
    D.print("end proper");
    D.print(debug_show (end_proper));

    let try_withdraw_locked_fee_deposit_3 = await canister.sale_nft_origyn(#withdraw(#fee_deposit({ account = #account({ owner = Principal.fromActor(this); sub_account = null }); token = #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }); amount = 10 * 10 ** 8; withdraw_to = #account({ owner = Principal.fromActor(a_wallet); sub_account = null }); status = #unlocked() })));
    D.print("try_withdraw_locked_fee_deposit_3 " # debug_show (try_withdraw_locked_fee_deposit_3));

    //create wallets to force rounds
    let fake_wallet66 = await TestWalletDef.test_wallet();
    let fake_wallet67 = await TestWalletDef.test_wallet();
    let fake_wallet78 = await TestWalletDef.test_wallet();
    let fake_wallet69 = await TestWalletDef.test_wallet();
    let fake_wallet79 = await TestWalletDef.test_wallet();
    let fake_wallet697 = await TestWalletDef.test_wallet();
    let fake_wallet797 = await TestWalletDef.test_wallet();

    let a_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    let net_balance5 = await dfx.icrc1_balance_of(net_account);

    let fee_wallet_balance5 = await dfx.icrc1_balance_of({
      owner = sellerFeeDepositAccount.account.principal;
      subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
    });

    D.print("fee_wallet_balance5 = " # debug_show (fee_wallet_balance5));
    D.print("a wallet " # debug_show ((Principal.fromActor(a_wallet), a_balance, a_balance5)));
    D.print("b wallet " # debug_show ((Principal.fromActor(b_wallet), b_balance + 800000 /* 1_000_000 - 200_000 token fees*/, b_balance5)));
    D.print("n wallet " # debug_show ((Principal.fromActor(n_wallet), n_balance + 800000 /* 1_000_000 - 200_000 token fees*/, n_balance5)));
    D.print("o wallet " # debug_show ((Principal.fromActor(o_wallet), o_balance + 800000 /* 1_000_000 - 200_000 token fees*/, o_balance5)));
    D.print("net wallet " # debug_show ((Principal.fromActor(net_wallet), net_balance + 800000 /* 1_000_000 - 200_000 token fees*/, net_balance5)));
    D.print("canister wallet " # debug_show ((Principal.fromActor(canister), canister_balance, canister_balance5)));

    let suite = S.suite(
      "test royalties fixed",
      [
        //todo: add test to make sure that the deposit has been reduced
        S.test("fail if seller doest not get his monney", a_balance5, M.equals<Nat>(T.nat(99499400000))), // 1000000000 - 5000000 = 995000000
        S.test("fail if broker does not get first royalty", b_balance5, M.equals<Nat>(T.nat(b_balance + 800000))),
        S.test("fail if node does not get first royalty", n_balance5, M.equals<Nat>(T.nat(n_balance + 800000))),
        S.test("fail if network does not get first royalty", net_balance5, M.equals<Nat>(T.nat(o_balance + 800000))),
        S.test("fail if originator does not get first royalty", o_balance5, M.equals<Nat>(T.nat(net_balance + 800000))),
        S.test("fail if fee wallet balance wallet didnt paid", fee_wallet_balance5, M.equals<Nat>(T.nat(999000000))), // 1000000000 - 5000000 = 995000000

        //todo: add test to make sure the ignore broker pathway has consistent fees totals and royalties

      ],
    );

    S.run(suite);

    return #success;
  };

  public shared func testRoyaltiesFixed_2() : async { #success; #fail : Text } {
    D.print("running testRoyaltiesFixed_2");
    D.print("making wallets");

    let a_wallet = await TestWalletDef.test_wallet(); //purchaser
    let b_wallet = await TestWalletDef.test_wallet(); //broker
    let n_wallet = await TestWalletDef.test_wallet(); //node
    let o_wallet = await TestWalletDef.test_wallet(); //originator
    let net_wallet = await TestWalletDef.test_wallet(); //net

    let net_account = {
      owner = Principal.fromActor(net_wallet);
      subaccount = ?Royalties.get_network_royalty_account(Principal.fromActor(dfx), null);
    };

    D.print("have the net account " # debug_show (net_account));

    D.print("making factory");

    let newPrincipal = try {
      await g_canister_factory.create({
        owner = Principal.fromActor(this);
        storage_space = null;
      });
    } catch (e) {
      D.print(Error.message(e));
      return #fail(Error.message(e));
    };

    let noBrokerPrincipal = try {
      await g_canister_factory.create({
        owner = Principal.fromActor(this);
        storage_space = null;
      });
    } catch (e) {
      D.print(Error.message(e));
      return #fail(Error.message(e));
    };

    D.print("have canister");

    let canister : Types.Service = actor (Principal.toText(newPrincipal));
    let icrc7_canister : ICRC7Types.Service = actor (Principal.toText(newPrincipal));

    let standardStage_collection = await utils.buildCollection(
      canister,
      Principal.fromActor(canister), //app
      Principal.fromActor(n_wallet), // node
      Principal.fromActor(this), // originator (x2)
      2048000,
      false,
      dfxspec,
    );

    let updateNetwork = canister.collection_update_nft_origyn(#UpdateNetwork(?Principal.fromActor(net_wallet)));

    D.print("calling stage");

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));
    let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));

    let mint_attempt2 = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(this)));
    let mint_attempt3 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this)));
    let mint_attempt4 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));

    D.print("finished stage");
    D.print(debug_show (standardStage.0));

    //fund a_wallet
    let funding_result = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    D.print("funding result a");
    D.print(debug_show (funding_result));

    let funding_result2 = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    //send a payment to the ledger
    D.print("sending tokens to canisters");
    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (5 * 10 ** 8) + 400000, Principal.fromActor(canister));

    D.print("send to canister a wallet royalties");
    D.print(debug_show (a_wallet_send_tokens_to_canister));

    let block = switch (a_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    let a_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    D.print("network account is " # debug_show (net_account));
    let net_balance = await dfx.icrc1_balance_of(net_account);
    D.print("a_balance " # debug_show ((Principal.fromActor(a_wallet), a_balance)));
    D.print("b_balance " # debug_show ((Principal.fromActor(b_wallet), b_balance)));
    D.print("n_balance " # debug_show ((Principal.fromActor(n_wallet), n_balance)));
    D.print("o_balance " # debug_show ((Principal.fromActor(o_wallet), o_balance)));
    D.print("canister wallet " # debug_show ((Principal.fromActor(canister), canister_balance)));

    D.print(debug_show (Principal.fromActor(b_wallet)));

    let #ok(#fee_deposit_info(sellerFeeDepositAccount)) = await canister.sale_info_nft_origyn(#fee_deposit_info(? #account { owner = Principal.fromActor(this); sub_account = null })) else {
      D.print("failed to get sellerFeeDepositAccount");
      return #fail("failed to get sellerFeeDepositAccount");
    };

    let fee_deposit_request : Types.FeeDepositRequest = {
      account = #account({
        owner = Principal.fromActor(this);
        sub_account = null;
      });
      token = #ic({
        canister = Principal.fromActor(dfx);
        standard = #Ledger;
        decimals = 8;
        symbol = "LDG";
        fee = ?200000;
        id = null;
      });
    };

    let fee_deposit_ret = await canister.sale_nft_origyn(#fee_deposit(fee_deposit_request));
    D.print("fee_deposit_ret = " # debug_show (fee_deposit_ret));
    // no fund has been sent to fees wallet, balance = 0
    switch (fee_deposit_ret) {
      case (#ok(val)) {
        switch (val) {
          case (#fee_deposit(info)) {
            if (info.balance != 0) {
              return #fail("Balance should be == 0");
            };
          };
          case (_) {
            return #fail("Should have returned a #fee_deposit");
          };
        };
      };
      case (_) {
        return #fail("sale_nft_origyn #fee_deposit failed : Should have returned a #ok(#fee_deposit)");
      };
    };

    let add_fund_to_fees_wallet = await dfx.icrc1_transfer({
      to = {
        owner = sellerFeeDepositAccount.account.principal;
        subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
      };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 10 * 10 ** 8;
    });

    let fee_wallet_balance = await dfx.icrc1_balance_of({
      owner = sellerFeeDepositAccount.account.principal;
      subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
    });
    D.print("fee_wallet_balance = " # debug_show (fee_wallet_balance));

    let fee_deposit_ret2 = await canister.sale_nft_origyn(#fee_deposit(fee_deposit_request));
    D.print("fee_deposit_ret2 = " # debug_show (fee_deposit_ret2));
    // fund has been sent to fees wallet, balance > 0
    switch (fee_deposit_ret2) {
      case (#ok(val)) {
        switch (val) {
          case (#fee_deposit(info)) {
            if (info.balance == 0) {
              return #fail("Balance should be > 0");
            };
          };
          case (_) {
            return #fail("Should have returned a #fee_deposit");
          };
        };
      };
      case (_) {
        return #fail("sale_nft_origyn #fee_deposit failed : Should have returned a #ok(#fee_deposit)");
      };
    };

    let icrc7_balance = await icrc7_canister.icrc7_balance_of([{
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    }]);
    D.print("icrc7_balance = " # debug_show (icrc7_balance));

    let option_buffer4 = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(0),
      #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),
      #buy_now(0),
      #start_price(0),
      #allow_list([Principal.fromActor(a_wallet)]),
      #ending(#date(get_time() + DAY_LENGTH)),
      #fee_accounts([
        "com.origyn.royalty.node",
        "com.origyn.royalty.broker",
        "com.origyn.royalty.originator",
        "com.origyn.royalty.custom",
        "com.origyn.royalty.network",
      ]),
      #fee_schema("com.origyn.royalties.fixed"),
    ]);

    let start_auction_attempt_owner4 = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer4));
      };
    });
    D.print("start_auction_attempt_owner4 " # debug_show (start_auction_attempt_owner4));

    // verify that auction fail with startprice < all fees that user has to pay
    let current_sales_id_2 = switch (start_auction_attempt_owner4) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };

      };
      case (#err(item)) {
        D.print("error with auction start");
        D.print(item.flag_point);
        return #fail("error with auction start");
      };
    };

    let b_wallet_try_bid_valid_2 = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 0, "1", current_sales_id_2, ?Principal.fromActor(b_wallet), null);
    D.print("b_wallet_try_bid_valid_2 " # debug_show (b_wallet_try_bid_valid_2));

    let a_wallet_try_bid_valid_2 = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 0, "1", current_sales_id_2, ?Principal.fromActor(b_wallet), null);
    D.print("a_wallet_try_bid_valid_2 " # debug_show (a_wallet_try_bid_valid_2));

    let end_proper_3 = await canister.sale_nft_origyn(#end_sale("1"));
    D.print("end proper");
    D.print(debug_show (end_proper_3));

    let icrc7_balance_1 = await icrc7_canister.icrc7_balance_of([{
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    }]);
    D.print("icrc7_balance_1 = " # debug_show (icrc7_balance_1));

    //create wallets to force rounds
    let fake_wallet66 = await TestWalletDef.test_wallet();
    let fake_wallet67 = await TestWalletDef.test_wallet();
    let fake_wallet78 = await TestWalletDef.test_wallet();
    let fake_wallet69 = await TestWalletDef.test_wallet();
    let fake_wallet79 = await TestWalletDef.test_wallet();
    let fake_wallet697 = await TestWalletDef.test_wallet();
    let fake_wallet797 = await TestWalletDef.test_wallet();

    let a_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    let net_balance5 = await dfx.icrc1_balance_of(net_account);

    let fee_wallet_balance5 = await dfx.icrc1_balance_of({
      owner = sellerFeeDepositAccount.account.principal;
      subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
    });

    D.print("fee_wallet_balance5 = " # debug_show (fee_wallet_balance5));
    D.print("a wallet " # debug_show ((Principal.fromActor(a_wallet), a_balance, a_balance5)));
    D.print("b wallet " # debug_show ((Principal.fromActor(b_wallet), b_balance + 800000 /* 1_000_000 - 200_000 token fees*/, b_balance5)));
    D.print("n wallet " # debug_show ((Principal.fromActor(n_wallet), n_balance + 800000 /* 1_000_000 - 200_000 token fees*/, n_balance5)));
    D.print("o wallet " # debug_show ((Principal.fromActor(o_wallet), o_balance + 800000 /* 1_000_000 - 200_000 token fees*/, o_balance5)));
    D.print("net wallet " # debug_show ((Principal.fromActor(net_wallet), net_balance + 800000 /* 1_000_000 - 200_000 token fees*/, net_balance5)));
    D.print("canister wallet " # debug_show ((Principal.fromActor(canister), canister_balance, canister_balance5)));

    let suite = S.suite(
      "test royalties fixed",
      [
        //todo: add test to make sure that the deposit has been reduced
        S.test("fail if seller doest not get his monney", a_balance5, M.equals<Nat>(T.nat(99_499_400_000))), // 1000000000 - 5000000 = 995000000
        S.test("fail if broker does not get first royalty", b_balance5, M.equals<Nat>(T.nat(b_balance + 800000))),
        S.test("fail if node does not get first royalty", n_balance5, M.equals<Nat>(T.nat(n_balance + 800000))),
        S.test("fail if network does not get first royalty", net_balance5, M.equals<Nat>(T.nat(o_balance + 800000))),
        S.test("fail if originator does not get first royalty", o_balance5, M.equals<Nat>(T.nat(net_balance + 800000))),
        S.test("fail if fee wallet balance wallet didnt paid", fee_wallet_balance5, M.equals<Nat>(T.nat(995000000))), // 1000000000 - 5000000 = 995000000

        //todo: add test to make sure the ignore broker pathway has consistent fees totals and royalties

      ],
    );

    S.run(suite);

    return #success;
  };

  public shared func testRoyaltiesBidFeeAccount() : async {
    #success;
    #fail : Text;
  } {
    D.print("running testRoyaltiesBidFeeAccount");
    D.print("making wallets");

    let a_wallet = await TestWalletDef.test_wallet(); //purchaser
    let b_wallet = await TestWalletDef.test_wallet(); //broker
    let n_wallet = await TestWalletDef.test_wallet(); //node
    let o_wallet = await TestWalletDef.test_wallet(); //originator
    let net_wallet = await TestWalletDef.test_wallet(); //net

    let net_account = {
      owner = Principal.fromActor(net_wallet);
      subaccount = ?Royalties.get_network_royalty_account(Principal.fromActor(dfx), null);
    };

    D.print("have the net account " # debug_show (net_account));

    D.print("making factory");

    let newPrincipal = try {
      await g_canister_factory.create({
        owner = Principal.fromActor(this);
        storage_space = null;
      });
    } catch (e) {
      D.print(Error.message(e));
      return #fail(Error.message(e));
    };

    let noBrokerPrincipal = try {
      await g_canister_factory.create({
        owner = Principal.fromActor(this);
        storage_space = null;
      });
    } catch (e) {
      D.print(Error.message(e));
      return #fail(Error.message(e));
    };

    D.print("have canister");

    let canister : Types.Service = actor (Principal.toText(newPrincipal));
    let icrc7_canister : ICRC7Types.Service = actor (Principal.toText(newPrincipal));

    let standardStage_collection = await utils.buildCollection(
      canister,
      Principal.fromActor(canister), //app
      Principal.fromActor(n_wallet), // node
      Principal.fromActor(this), // originator
      2048000,
      false,
      dfxspec,
    );

    let updateNetwork = canister.collection_update_nft_origyn(#UpdateNetwork(?Principal.fromActor(net_wallet)));

    D.print("calling stage");

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));
    let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));

    let mint_attempt2 = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(this)));
    let mint_attempt3 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this)));
    let mint_attempt4 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));

    D.print("finished stage");
    D.print(debug_show (standardStage.0));

    //fund a_wallet
    let funding_result = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    D.print("funding result a");
    D.print(debug_show (funding_result));

    let funding_result2 = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    //send a payment to the ledger
    D.print("sending tokens to canisters");
    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (5 * 10 ** 8) + 400000, Principal.fromActor(canister));

    D.print("send to canister a wallet royalties");
    D.print(debug_show (a_wallet_send_tokens_to_canister));

    let block = switch (a_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    let a_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    D.print("network account is " # debug_show (net_account));
    let net_balance = await dfx.icrc1_balance_of(net_account);
    D.print("a_balance " # debug_show ((Principal.fromActor(a_wallet), a_balance)));
    D.print("b_balance " # debug_show ((Principal.fromActor(b_wallet), b_balance)));
    D.print("n_balance " # debug_show ((Principal.fromActor(n_wallet), n_balance)));
    D.print("o_balance " # debug_show ((Principal.fromActor(o_wallet), o_balance)));
    D.print("canister wallet " # debug_show ((Principal.fromActor(canister), canister_balance)));

    D.print(debug_show (Principal.fromActor(b_wallet)));

    let #ok(#fee_deposit_info(sellerFeeDepositAccount)) = await canister.sale_info_nft_origyn(#fee_deposit_info(? #account { owner = Principal.fromActor(a_wallet); sub_account = null })) else {
      D.print("failed to get sellerFeeDepositAccount");
      return #fail("failed to get sellerFeeDepositAccount");
    };

    let fee_deposit_request : Types.FeeDepositRequest = {
      account = #account({
        owner = Principal.fromActor(a_wallet);
        sub_account = null;
      });
      token = #ic({
        canister = Principal.fromActor(dfx);
        standard = #Ledger;
        decimals = 8;
        symbol = "LDG";
        fee = ?200000;
        id = null;
      });
    };

    let fee_deposit_ret = await canister.sale_nft_origyn(#fee_deposit(fee_deposit_request));
    D.print("fee_deposit_ret = " # debug_show (fee_deposit_ret));
    // no fund has been sent to fees wallet, balance = 0
    switch (fee_deposit_ret) {
      case (#ok(val)) {
        switch (val) {
          case (#fee_deposit(info)) {
            if (info.balance != 0) {
              return #fail("Balance should be == 0");
            };
          };
          case (_) {
            return #fail("Should have returned a #fee_deposit");
          };
        };
      };
      case (_) {
        return #fail("sale_nft_origyn #fee_deposit failed : Should have returned a #ok(#fee_deposit)");
      };
    };

    let add_fund_to_fees_wallet = await dfx.icrc1_transfer({
      to = {
        owner = sellerFeeDepositAccount.account.principal;
        subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
      };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 10 * 10 ** 8;
    });

    let fee_wallet_balance = await dfx.icrc1_balance_of({
      owner = sellerFeeDepositAccount.account.principal;
      subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
    });
    D.print("fee_wallet_balance = " # debug_show (fee_wallet_balance));

    let fee_deposit_ret2 = await canister.sale_nft_origyn(#fee_deposit(fee_deposit_request));
    D.print("fee_deposit_ret2 = " # debug_show (fee_deposit_ret2));
    // fund has been sent to fees wallet, balance > 0
    switch (fee_deposit_ret2) {
      case (#ok(val)) {
        switch (val) {
          case (#fee_deposit(info)) {
            if (info.balance == 0) {
              return #fail("Balance should be > 0");
            };
          };
          case (_) {
            return #fail("Should have returned a #fee_deposit");
          };
        };
      };
      case (_) {
        return #fail("sale_nft_origyn #fee_deposit failed : Should have returned a #ok(#fee_deposit)");
      };
    };

    // This one should not fail
    D.print("sellerFeeDepositAccount = " # debug_show (sellerFeeDepositAccount));
    let option_buffer2 = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(1 * 10 ** 8),
      #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),
      #buy_now(1 * 10 ** 8),
      #start_price(1 * 10 ** 8),
      #ending(#date(get_time() + DAY_LENGTH)),
      #fee_schema("com.origyn.royalties.fixed"),
    ]);

    let start_auction_attempt_owner2 = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer2));
      };
    });
    // verify that auction fail with startprice < all fees that user has to pay
    let current_sales_id_2 = switch (start_auction_attempt_owner2) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };

      };
      case (#err(item)) {
        D.print("error with auction start");
        D.print(item.flag_point);
        return #fail("error with auction start");
      };
    };
    D.print("start_auction_attempt_owner2 " # debug_show (start_auction_attempt_owner2));

    let a_wallet_try_bid_valid_2 = await a_wallet.try_bid(
      Principal.fromActor(canister),
      Principal.fromActor(this),
      Principal.fromActor(dfx),
      1 * 10 ** 8,
      "1",
      current_sales_id_2,
      ?Principal.fromActor(b_wallet),
      ?[
        #fee_accounts([
          "com.origyn.royalty.node",
          "com.origyn.royalty.broker",
          "com.origyn.royalty.originator",
          "com.origyn.royalty.custom",
          "com.origyn.royalty.network",
        ])
      ],
    );
    D.print("a_wallet_try_bid_valid_2 " # debug_show (a_wallet_try_bid_valid_2));

    let end_proper_3 = await canister.sale_nft_origyn(#end_sale("1"));
    D.print("end proper");
    D.print(debug_show (end_proper_3));

    let icrc7_balance_1 = await icrc7_canister.icrc7_balance_of([{
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    }]);
    D.print("icrc7_balance_1 = " # debug_show (icrc7_balance_1));

    //create wallets to force rounds
    let fake_wallet66 = await TestWalletDef.test_wallet();
    let fake_wallet67 = await TestWalletDef.test_wallet();
    let fake_wallet78 = await TestWalletDef.test_wallet();
    let fake_wallet69 = await TestWalletDef.test_wallet();
    let fake_wallet79 = await TestWalletDef.test_wallet();
    let fake_wallet697 = await TestWalletDef.test_wallet();
    let fake_wallet797 = await TestWalletDef.test_wallet();

    let a_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    let net_balance5 = await dfx.icrc1_balance_of(net_account);

    let fee_wallet_balance5 = await dfx.icrc1_balance_of({
      owner = sellerFeeDepositAccount.account.principal;
      subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
    });

    D.print("fee_wallet_balance5 = " # debug_show (fee_wallet_balance5));
    D.print("a wallet " # debug_show ((Principal.fromActor(a_wallet), a_balance, a_balance5)));
    D.print("b wallet " # debug_show ((Principal.fromActor(b_wallet), b_balance + 800000 /* 1_000_000 - 200_000 token fees*/, b_balance5)));
    D.print("n wallet " # debug_show ((Principal.fromActor(n_wallet), n_balance + 800000 /* 1_000_000 - 200_000 token fees*/, n_balance5)));
    D.print("o wallet " # debug_show ((Principal.fromActor(o_wallet), o_balance + 800000 /* 1_000_000 - 200_000 token fees*/, o_balance5)));
    D.print("net wallet " # debug_show ((Principal.fromActor(net_wallet), net_balance + 800000 /* 1_000_000 - 200_000 token fees*/, net_balance5)));
    D.print("canister wallet " # debug_show ((Principal.fromActor(canister), canister_balance, canister_balance5)));

    let suite = S.suite(
      "test royalties fixed",
      [
        //todo: add test to make sure that the deposit has been reduced
        S.test("fail if seller doest not get his monney", a_balance5, M.equals<Nat>(T.nat(99_499_400_000))), // 1000000000 - 5000000 = 995000000
        S.test("fail if broker does not get first royalty", b_balance5, M.equals<Nat>(T.nat(b_balance + 800000))),
        S.test("fail if node does not get first royalty", n_balance5, M.equals<Nat>(T.nat(n_balance + 800000))),
        S.test("fail if network does not get first royalty", net_balance5, M.equals<Nat>(T.nat(o_balance + 800000))),
        S.test("fail if originator does not get first royalty", o_balance5, M.equals<Nat>(T.nat(net_balance + 800000))),
        S.test("fail if fee wallet balance wallet didnt paid", fee_wallet_balance5, M.equals<Nat>(T.nat(995000000))), // 1000000000 - 5000000 = 995000000

        //todo: add test to make sure the ignore broker pathway has consistent fees totals and royalties

      ],
    );

    S.run(suite);

    return #success;
  };

  public shared func testRoyaltiesBidAndSellerFeeAccount() : async {
    #success;
    #fail : Text;
  } {
    D.print("running testRoyaltiesBidAndSellerFeeAccount");
    D.print("making wallets");

    let a_wallet = await TestWalletDef.test_wallet(); //purchaser
    let b_wallet = await TestWalletDef.test_wallet(); //broker
    let n_wallet = await TestWalletDef.test_wallet(); //node
    let o_wallet = await TestWalletDef.test_wallet(); //originator
    let net_wallet = await TestWalletDef.test_wallet(); //net

    let net_account = {
      owner = Principal.fromActor(net_wallet);
      subaccount = ?Royalties.get_network_royalty_account(Principal.fromActor(dfx), null);
    };

    D.print("have the net account " # debug_show (net_account));

    D.print("making factory");

    let newPrincipal = try {
      await g_canister_factory.create({
        owner = Principal.fromActor(this);
        storage_space = null;
      });
    } catch (e) {
      D.print(Error.message(e));
      return #fail(Error.message(e));
    };

    let noBrokerPrincipal = try {
      await g_canister_factory.create({
        owner = Principal.fromActor(this);
        storage_space = null;
      });
    } catch (e) {
      D.print(Error.message(e));
      return #fail(Error.message(e));
    };

    D.print("have canister");

    let canister : Types.Service = actor (Principal.toText(newPrincipal));
    let icrc7_canister : ICRC7Types.Service = actor (Principal.toText(newPrincipal));

    let standardStage_collection = await utils.buildCollection(
      canister,
      Principal.fromActor(canister), //app
      Principal.fromActor(n_wallet), // node
      Principal.fromActor(this), // originator
      2048000,
      false,
      dfxspec,
    );

    let updateNetwork = canister.collection_update_nft_origyn(#UpdateNetwork(?Principal.fromActor(net_wallet)));

    D.print("calling stage");

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));
    let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));

    let mint_attempt2 = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(this)));
    let mint_attempt3 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this)));
    let mint_attempt4 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));

    D.print("finished stage");
    D.print(debug_show (standardStage.0));

    //fund a_wallet
    let funding_result = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    D.print("funding result a");
    D.print(debug_show (funding_result));

    let funding_result2 = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    //send a payment to the ledger
    D.print("sending tokens to canisters");
    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (5 * 10 ** 8) + 400000, Principal.fromActor(canister));

    D.print("send to canister a wallet royalties");
    D.print(debug_show (a_wallet_send_tokens_to_canister));

    let block = switch (a_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    let a_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    D.print("network account is " # debug_show (net_account));
    let net_balance = await dfx.icrc1_balance_of(net_account);
    D.print("a_balance " # debug_show ((Principal.fromActor(a_wallet), a_balance)));
    D.print("b_balance " # debug_show ((Principal.fromActor(b_wallet), b_balance)));
    D.print("n_balance " # debug_show ((Principal.fromActor(n_wallet), n_balance)));
    D.print("o_balance " # debug_show ((Principal.fromActor(o_wallet), o_balance)));
    D.print("canister wallet " # debug_show ((Principal.fromActor(canister), canister_balance)));

    D.print(debug_show (Principal.fromActor(b_wallet)));

    let #ok(#fee_deposit_info(sellerFeeDepositAccount)) = await canister.sale_info_nft_origyn(#fee_deposit_info(? #account { owner = Principal.fromActor(a_wallet); sub_account = null })) else {
      D.print("failed to get sellerFeeDepositAccount");
      return #fail("failed to get sellerFeeDepositAccount");
    };

    let fee_deposit_request : Types.FeeDepositRequest = {
      account = #account({
        owner = Principal.fromActor(a_wallet);
        sub_account = null;
      });
      token = #ic({
        canister = Principal.fromActor(dfx);
        standard = #Ledger;
        decimals = 8;
        symbol = "LDG";
        fee = ?200000;
        id = null;
      });
    };

    let fee_deposit_ret = await canister.sale_nft_origyn(#fee_deposit(fee_deposit_request));
    D.print("fee_deposit_ret = " # debug_show (fee_deposit_ret));
    // no fund has been sent to fees wallet, balance = 0
    switch (fee_deposit_ret) {
      case (#ok(val)) {
        switch (val) {
          case (#fee_deposit(info)) {
            if (info.balance != 0) {
              return #fail("Balance should be == 0");
            };
          };
          case (_) {
            return #fail("Should have returned a #fee_deposit");
          };
        };
      };
      case (_) {
        return #fail("sale_nft_origyn #fee_deposit failed : Should have returned a #ok(#fee_deposit)");
      };
    };

    let add_fund_to_fees_wallet = await dfx.icrc1_transfer({
      to = {
        owner = sellerFeeDepositAccount.account.principal;
        subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
      };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 10 * 10 ** 8;
    });

    let fee_wallet_balance = await dfx.icrc1_balance_of({
      owner = sellerFeeDepositAccount.account.principal;
      subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
    });
    D.print("fee_wallet_balance = " # debug_show (fee_wallet_balance));

    let fee_deposit_ret2 = await canister.sale_nft_origyn(#fee_deposit(fee_deposit_request));
    D.print("fee_deposit_ret2 = " # debug_show (fee_deposit_ret2));
    // fund has been sent to fees wallet, balance > 0
    switch (fee_deposit_ret2) {
      case (#ok(val)) {
        switch (val) {
          case (#fee_deposit(info)) {
            if (info.balance == 0) {
              return #fail("Balance should be > 0");
            };
          };
          case (_) {
            return #fail("Should have returned a #fee_deposit");
          };
        };
      };
      case (_) {
        return #fail("sale_nft_origyn #fee_deposit failed : Should have returned a #ok(#fee_deposit)");
      };
    };

    let #ok(#fee_deposit_info(sellerFeeDepositAccount_2)) = await canister.sale_info_nft_origyn(#fee_deposit_info(? #account { owner = Principal.fromActor(this); sub_account = null })) else {
      D.print("failed to get sellerFeeDepositAccount_2");
      return #fail("failed to get sellerFeeDepositAccount_2");
    };

    let fee_deposit_request_2 : Types.FeeDepositRequest = {
      account = #account({
        owner = Principal.fromActor(this);
        sub_account = null;
      });
      token = #ic({
        canister = Principal.fromActor(dfx);
        standard = #Ledger;
        decimals = 8;
        symbol = "LDG";
        fee = ?200000;
        id = null;
      });
    };

    let fee_deposit_ret_21 = await canister.sale_nft_origyn(#fee_deposit(fee_deposit_request_2));
    D.print("fee_deposit_ret_21 = " # debug_show (fee_deposit_ret_21));
    // no fund has been sent to fees wallet, balance = 0
    switch (fee_deposit_ret_21) {
      case (#ok(val)) {
        switch (val) {
          case (#fee_deposit(info)) {
            if (info.balance != 0) {
              return #fail("Balance should be == 0");
            };
          };
          case (_) {
            return #fail("Should have returned a #fee_deposit");
          };
        };
      };
      case (_) {
        return #fail("sale_nft_origyn #fee_deposit failed : Should have returned a #ok(#fee_deposit)");
      };
    };

    let add_fund_to_fees_wallet_2 = await dfx.icrc1_transfer({
      to = {
        owner = sellerFeeDepositAccount_2.account.principal;
        subaccount = ?Blob.toArray(sellerFeeDepositAccount_2.account.sub_account);
      };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 10 * 10 ** 8;
    });

    let fee_wallet_balance_2 = await dfx.icrc1_balance_of({
      owner = sellerFeeDepositAccount_2.account.principal;
      subaccount = ?Blob.toArray(sellerFeeDepositAccount_2.account.sub_account);
    });
    D.print("fee_wallet_balance_2 = " # debug_show (fee_wallet_balance_2));

    let fee_deposit_ret22 = await canister.sale_nft_origyn(#fee_deposit(fee_deposit_request_2));
    D.print("fee_deposit_ret22 = " # debug_show (fee_deposit_ret22));
    // fund has been sent to fees wallet, balance > 0
    switch (fee_deposit_ret22) {
      case (#ok(val)) {
        switch (val) {
          case (#fee_deposit(info)) {
            if (info.balance == 0) {
              return #fail("Balance should be > 0");
            };
          };
          case (_) {
            return #fail("Should have returned a #fee_deposit");
          };
        };
      };
      case (_) {
        return #fail("sale_nft_origyn #fee_deposit failed : Should have returned a #ok(#fee_deposit)");
      };
    };

    // This one should not fail
    D.print("sellerFeeDepositAccount = " # debug_show (sellerFeeDepositAccount));
    let option_buffer2 = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(1 * 10 ** 8),
      #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),
      #buy_now(1 * 10 ** 8),
      #start_price(1 * 10 ** 8),
      #ending(#date(get_time() + DAY_LENGTH)),
      #fee_accounts([
        "com.origyn.royalty.node",
        "com.origyn.royalty.broker",
        "com.origyn.royalty.network",
      ]),
      #fee_schema("com.origyn.royalties.fixed"),
    ]);

    let start_auction_attempt_owner2 = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer2));
      };
    });
    // verify that auction fail with startprice < all fees that user has to pay
    let current_sales_id_2 = switch (start_auction_attempt_owner2) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };

      };
      case (#err(item)) {
        D.print("error with auction start");
        D.print(item.flag_point);
        return #fail("error with auction start");
      };
    };
    D.print("start_auction_attempt_owner2 " # debug_show (start_auction_attempt_owner2));

    let a_wallet_try_bid_valid_2 = await a_wallet.try_bid(
      Principal.fromActor(canister),
      Principal.fromActor(this),
      Principal.fromActor(dfx),
      1 * 10 ** 8,
      "1",
      current_sales_id_2,
      ?Principal.fromActor(b_wallet),
      ?[
        #fee_accounts([
          "com.origyn.royalty.node",
          "com.origyn.royalty.broker",
          "com.origyn.royalty.originator",
          "com.origyn.royalty.custom",
          "com.origyn.royalty.network",
        ]),
      ],
    );
    D.print("a_wallet_try_bid_valid_2 " # debug_show (a_wallet_try_bid_valid_2));

    let end_proper_3 = await canister.sale_nft_origyn(#end_sale("1"));
    D.print("end proper");
    D.print(debug_show (end_proper_3));

    let icrc7_balance_1 = await icrc7_canister.icrc7_balance_of([{
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    }]);
    D.print("icrc7_balance_1 = " # debug_show (icrc7_balance_1));

    //create wallets to force rounds
    let fake_wallet66 = await TestWalletDef.test_wallet();
    let fake_wallet67 = await TestWalletDef.test_wallet();
    let fake_wallet78 = await TestWalletDef.test_wallet();
    let fake_wallet69 = await TestWalletDef.test_wallet();
    let fake_wallet79 = await TestWalletDef.test_wallet();
    let fake_wallet697 = await TestWalletDef.test_wallet();
    let fake_wallet797 = await TestWalletDef.test_wallet();

    let a_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    let net_balance5 = await dfx.icrc1_balance_of(net_account);

    let fee_wallet_balance5 = await dfx.icrc1_balance_of({
      owner = sellerFeeDepositAccount.account.principal;
      subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
    });

    let fee_wallet_balance5___2 = await dfx.icrc1_balance_of({
      owner = sellerFeeDepositAccount_2.account.principal;
      subaccount = ?Blob.toArray(sellerFeeDepositAccount_2.account.sub_account);
    });

    let try_withdraw_locked_fee_deposit = await canister.sale_nft_origyn(#withdraw(#fee_deposit({ account = #account({ owner = Principal.fromActor(this); sub_account = null }); token = #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }); amount = 10 * 10 ** 8; withdraw_to = #account({ owner = Principal.fromActor(a_wallet); sub_account = null }); status = #unlocked() })));
    D.print("try_withdraw_locked_fee_deposit " # debug_show (try_withdraw_locked_fee_deposit));

    D.print("fee_wallet_balance5 = " # debug_show (fee_wallet_balance5));
    D.print("fee_wallet_balance5___2 = " # debug_show (fee_wallet_balance5___2));
    D.print("a wallet " # debug_show ((Principal.fromActor(a_wallet), a_balance, a_balance5)));
    D.print("b wallet " # debug_show ((Principal.fromActor(b_wallet), b_balance + 800000 /* 1_000_000 - 200_000 token fees*/, b_balance5)));
    D.print("n wallet " # debug_show ((Principal.fromActor(n_wallet), n_balance + 800000 /* 1_000_000 - 200_000 token fees*/, n_balance5)));
    D.print("o wallet " # debug_show ((Principal.fromActor(o_wallet), o_balance + 800000 /* 1_000_000 - 200_000 token fees*/, o_balance5)));
    D.print("net wallet " # debug_show ((Principal.fromActor(net_wallet), net_balance + 800000 /* 1_000_000 - 200_000 token fees*/, net_balance5)));
    D.print("canister wallet " # debug_show ((Principal.fromActor(canister), canister_balance, canister_balance5)));

    let suite = S.suite(
      "test royalties fixed",
      [
        //todo: add test to make sure that the deposit has been reduced
        S.test("fail if seller doest not get his monney", a_balance5, M.equals<Nat>(T.nat(99_499_400_000))), // 1000000000 - 5000000 = 995000000
        S.test("fail if broker does not get first royalty", b_balance5, M.equals<Nat>(T.nat(b_balance + 800000))),
        S.test("fail if node does not get first royalty", n_balance5, M.equals<Nat>(T.nat(n_balance + 800000))),
        S.test("fail if network does not get first royalty", net_balance5, M.equals<Nat>(T.nat(o_balance + 800000))),
        S.test("fail if originator does not get first royalty", o_balance5, M.equals<Nat>(T.nat(net_balance + 800000))),
        S.test("fail if fee wallet balance wallet didnt paid", fee_wallet_balance5, M.equals<Nat>(T.nat(995000000))), // 1000000000 - 5000000 = 995000000

        //todo: add test to make sure the ignore broker pathway has consistent fees totals and royalties

      ],
    );

    S.run(suite);

    return #success;
  };

  public shared func testRoyaltiesFixedDifferentToken() : async {
    #success;
    #fail : Text;
  } {
    D.print("running testRoyaltiesFixedDifferentToken");
    D.print("making wallets");

    let a_wallet = await TestWalletDef.test_wallet(); //purchaser
    let b_wallet = await TestWalletDef.test_wallet(); //broker
    let n_wallet = await TestWalletDef.test_wallet(); //node
    let o_wallet = await TestWalletDef.test_wallet(); //originator
    let net_wallet = await TestWalletDef.test_wallet(); //net

    let net_account = {
      owner = Principal.fromActor(net_wallet);
      subaccount = ?Royalties.get_network_royalty_account(Principal.fromActor(dfx), null);
    };

    D.print("have the net account " # debug_show (net_account));

    D.print("making factory");

    let newPrincipal = try {
      await g_canister_factory.create({
        owner = Principal.fromActor(this);
        storage_space = null;
      });
    } catch (e) {
      D.print(Error.message(e));
      return #fail(Error.message(e));
    };

    D.print("have canister");
    let dfxspec2 = {
      canister = Principal.fromActor(dfx2);
      standard = #Ledger;
      decimals = 8;
      symbol = "LGY";
      fee = ?200000;
      id = null;
    };

    let canister : Types.Service = actor (Principal.toText(newPrincipal));
    let standardStage_collection = await utils.buildCollection(
      canister,
      Principal.fromActor(canister),
      Principal.fromActor(n_wallet),
      Principal.fromActor(this),
      2048000,
      false,
      dfxspec2,
    );

    let updateNetwork = canister.collection_update_nft_origyn(#UpdateNetwork(?Principal.fromActor(net_wallet)));

    D.print("calling stage");

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));
    let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(o_wallet));

    let mint_attempt3 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this)));
    let mint_attempt4 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));

    D.print("finished stage");
    D.print(debug_show (standardStage.0));

    //fund a_wallet
    let funding_result = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    D.print("funding result a");
    D.print(debug_show (funding_result));

    let funding_result2 = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    //send a payment to the ledger
    D.print("sending tokens to canisters");
    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (5 * 10 ** 8) + 400000, Principal.fromActor(canister));

    D.print("send to canister a wallet royalties");
    D.print(debug_show (a_wallet_send_tokens_to_canister));

    let block = switch (a_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    let a_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance = await dfx2.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance = await dfx2.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance = await dfx2.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance = await dfx2.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    D.print("network account is " # debug_show (net_account));
    let net_balance = await dfx2.icrc1_balance_of(net_account);
    D.print("a_balance " # debug_show ((Principal.fromActor(a_wallet), a_balance)));
    D.print("b_balance " # debug_show ((Principal.fromActor(b_wallet), b_balance)));
    D.print("n_balance " # debug_show ((Principal.fromActor(n_wallet), n_balance)));
    D.print("o_balance " # debug_show ((Principal.fromActor(o_wallet), o_balance)));
    D.print("canister wallet " # debug_show ((Principal.fromActor(canister), canister_balance)));

    D.print(debug_show (Principal.fromActor(b_wallet)));

    let #ok(#fee_deposit_info(sellerFeeDepositAccount)) = await canister.sale_info_nft_origyn(#fee_deposit_info(? #account { owner = Principal.fromActor(this); sub_account = null })) else {
      D.print("failed to get sellerFeeDepositAccount");
      return #fail("failed to get sellerFeeDepositAccount");
    };

    let fee_deposit_request : Types.FeeDepositRequest = {
      account = #account({
        owner = Principal.fromActor(this);
        sub_account = null;
      });
      token = #ic({
        canister = Principal.fromActor(dfx2);
        standard = #Ledger;
        decimals = 8;
        symbol = "LDY";
        fee = ?200000;
        id = null;
      });
    };

    let fee_deposit_ret = await canister.sale_nft_origyn(#fee_deposit(fee_deposit_request));
    D.print("fee_deposit_ret = " # debug_show (fee_deposit_ret));
    // no fund has been sent to fees wallet, balance = 0
    switch (fee_deposit_ret) {
      case (#ok(val)) {
        switch (val) {
          case (#fee_deposit(info)) {
            if (info.balance != 0) {
              return #fail("Balance should be == 0");
            };
          };
          case (_) {
            return #fail("Should have returned a #fee_deposit");
          };
        };
      };
      case (_) {
        return #fail("sale_nft_origyn #fee_deposit failed : Should have returned a #ok(#fee_deposit)");
      };
    };

    let add_fund_to_fees_wallet = await dfx2.icrc1_transfer({
      to = {
        owner = sellerFeeDepositAccount.account.principal;
        subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
      };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 10 * 10 ** 8;
    });

    let fee_wallet_balance = await dfx2.icrc1_balance_of({
      owner = sellerFeeDepositAccount.account.principal;
      subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
    });
    D.print("fee_wallet_balance = " # debug_show (fee_wallet_balance));

    let fee_deposit_ret2 = await canister.sale_nft_origyn(#fee_deposit(fee_deposit_request));
    D.print("fee_deposit_ret2 = " # debug_show (fee_deposit_ret2));
    // fund has been sent to fees wallet, balance > 0
    switch (fee_deposit_ret2) {
      case (#ok(val)) {
        switch (val) {
          case (#fee_deposit(info)) {
            if (info.balance == 0) {
              return #fail("Balance should be > 0");
            };
          };
          case (_) {
            return #fail("Should have returned a #fee_deposit");
          };
        };
      };
      case (_) {
        return #fail("sale_nft_origyn #fee_deposit failed : Should have returned a #ok(#fee_deposit)");
      };
    };

    D.print("sellerFeeDepositAccount = " # debug_show (sellerFeeDepositAccount));
    let option_buffer_should_fail = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(1),
      #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),
      #buy_now(1),
      #start_price(1),
      #ending(#date(get_time() + DAY_LENGTH)),
      #fee_accounts(["com.origyn.royalty.node"]),
      #fee_schema("com.origyn.royalties.fixed"),
    ]);

    let start_auction_attempt_owner_should_fail = await canister.market_transfer_nft_origyn({
      token_id = "3";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer_should_fail));
      };
    });

    D.print("get sale id");
    // verify that auction fail with startprice < all fees that user has to pay
    switch (start_auction_attempt_owner_should_fail) {
      case (#ok(val)) {
        D.print("auction should have fail with startprice < all fees that user has to pay");
        return #fail("error with auction start");
      };
      case (#err(item)) {
        if (item.flag_point != "market_transfer_nft_origyn - start price cannot be less than mininal fee") {
          D.print("error with auction start");
          D.print(item.flag_point);
          return #fail("error with auction start");
        };
      };
    };

    // This one should fail
    D.print("sellerFeeDepositAccount = " # debug_show (sellerFeeDepositAccount));
    let option_buffer_should_fail2 = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(1 * 10 ** 8),
      #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),
      #buy_now(1 * 10 ** 8),
      #start_price(1 * 10 ** 8),
      #ending(#date(get_time() + DAY_LENGTH)),
      #fee_accounts(["com.origyn.royalty.node"]),
      #fee_schema("com.origyn.royalties.fixed"),
    ]);

    let start_auction_attempt_owner_should_fail2 = await canister.market_transfer_nft_origyn({
      token_id = "3";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer_should_fail2));
      };
    });

    D.print("get sale id");
    // verify that auction fail with startprice < all fees that user has to pay
    switch (start_auction_attempt_owner_should_fail2) {
      case (#ok(val)) {
        D.print("market_transfer_nft_origyn specific token set for this royalty : \"com.origyn.royalty.originator\" but no fee_account setted to pay this royalty.");
        return #fail("error with auction start");
      };
      case (#err(item)) {
        if (item.flag_point != "market_transfer_nft_origyn specific token set for this royalty : \"com.origyn.royalty.originator\" but no fee_account setted to pay this royalty.") {
          D.print("error with auction start");
          D.print(item.flag_point);
          return #fail("error with auction start");
        };
      };
    };

    // This one should not fail
    D.print("sellerFeeDepositAccount = " # debug_show (sellerFeeDepositAccount));
    let option_buffer = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(1 * 10 ** 8),
      #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),
      #buy_now(1 * 10 ** 8),
      #start_price(1 * 10 ** 8),
      #ending(#date(get_time() + DAY_LENGTH)),
      #fee_accounts([
        "com.origyn.royalty.node",
        "com.origyn.royalty.broker",
        "com.origyn.royalty.originator",
        "com.origyn.royalty.custom",
        "com.origyn.royalty.network",
      ]),
      #fee_schema("com.origyn.royalties.fixed"),
    ]);

    let start_auction_attempt_owner = await canister.market_transfer_nft_origyn({
      token_id = "3";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer));
      };
    });

    D.print("get sale id");
    // verify that auction fail with startprice < all fees that user has to pay
    let current_sales_id = switch (start_auction_attempt_owner) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };
      };
      case (#err(item)) {
        D.print("error with auction start");
        D.print(item.flag_point);
        return #fail("error with auction start");
      };
    };

    //place escrow
    let end_date = get_time() + DAY_LENGTH + DAY_LENGTH;
    D.print("sending tokens to canisters");

    D.print("Sending real escrow now a wallet try escrow");
    //claiming first escrow
    let a_wallet_try_escrow_general_staged2 = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "3", ?current_sales_id, null, null);

    //place a valid bid MKT0027
    let a_wallet_try_bid_valid = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 8, "3", current_sales_id, ?Principal.fromActor(b_wallet), null);
    D.print("a_wallet_try_bid_valid " # debug_show (a_wallet_try_bid_valid));

    //create fake wallet for time duration
    let fake_wallet3 = await TestWalletDef.test_wallet();
    //create fake wallet for time duration
    let fake_wallet4 = await TestWalletDef.test_wallet();
    //create fake wallet for time duration
    let fake_wallet5 = await TestWalletDef.test_wallet();
    let fake_wallet57 = await TestWalletDef.test_wallet();
    let fake_wallet58 = await TestWalletDef.test_wallet();
    let fake_wallet575 = await TestWalletDef.test_wallet();
    let fake_wallet585 = await TestWalletDef.test_wallet();

    //advance time
    let mode = canister.__set_time_mode(#test);
    let time_result = await canister.__advance_time(end_date + 1);
    D.print("new time");
    D.print(debug_show (time_result));

    //end auction
    let end_proper = await canister.sale_nft_origyn(#end_sale("3"));
    D.print("end proper");
    D.print(debug_show (end_proper));

    //create wallets to force rounds
    let fake_wallet66 = await TestWalletDef.test_wallet();
    let fake_wallet67 = await TestWalletDef.test_wallet();
    let fake_wallet78 = await TestWalletDef.test_wallet();
    let fake_wallet69 = await TestWalletDef.test_wallet();
    let fake_wallet79 = await TestWalletDef.test_wallet();
    let fake_wallet697 = await TestWalletDef.test_wallet();
    let fake_wallet797 = await TestWalletDef.test_wallet();

    let a_balance5 = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance5 = await dfx2.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance5 = await dfx2.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance5 = await dfx2.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance5 = await dfx2.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    let net_balance5 = await dfx2.icrc1_balance_of(net_account);

    let fee_wallet_balance5 = await dfx2.icrc1_balance_of({
      owner = sellerFeeDepositAccount.account.principal;
      subaccount = ?Blob.toArray(sellerFeeDepositAccount.account.sub_account);
    });

    D.print("fee_wallet_balance5 = " # debug_show (fee_wallet_balance5));
    D.print("a wallet " # debug_show ((Principal.fromActor(a_wallet), a_balance, a_balance5)));
    D.print("b wallet " # debug_show ((Principal.fromActor(b_wallet), b_balance + 800000 /* 1_000_000 - 200_000 token fees*/, b_balance5)));
    D.print("n wallet " # debug_show ((Principal.fromActor(n_wallet), n_balance + 800000 /* 1_000_000 - 200_000 token fees*/, n_balance5)));
    D.print("o wallet " # debug_show ((Principal.fromActor(o_wallet), o_balance + 800000 /* 1_000_000 - 200_000 token fees*/, o_balance5)));
    D.print("net wallet token 1 " # debug_show ((Principal.fromActor(net_wallet), net_balance + 800000 /* 1_000_000 - 200_000 token fees*/, net_balance5)));
    D.print("canister wallet token 2 " # debug_show ((Principal.fromActor(canister), canister_balance, canister_balance5)));

    let suite = S.suite(
      "test royalties fixed",
      [
        //todo: add test to make sure that the deposit has been reduced
        S.test("fail if seller doest not get his monney", a_balance5, M.equals<Nat>(T.nat(99_499_400_000))), // 1000000000 - 1000000 = 999000000
        S.test("fail if broker does not get first royalty", b_balance5, M.equals<Nat>(T.nat(800000))),
        S.test("fail if node does not get first royalty", n_balance5, M.equals<Nat>(T.nat(800000))),
        S.test("fail if network does not get first royalty", net_balance5, M.equals<Nat>(T.nat(800000))),
        S.test("fail if originator does not get first royalty", o_balance5, M.equals<Nat>(T.nat(800000))),
        S.test("fail if fee wallet balance wallet didnt paid", fee_wallet_balance5, M.equals<Nat>(T.nat(995000000))), // 1000000000 - (5 * 1000000) = 995000000

        //todo: add test to make sure the ignore broker pathway has consistent fees totals and royalties

      ],
    );

    S.run(suite);

    return #success;
  };

  public shared func testOwnerTransfer() : async { #success; #fail : Text } {
    D.print("running testOwnerTransfer");

    let a_wallet = await TestWalletDef.test_wallet();
    let b_wallet = await TestWalletDef.test_wallet();
    let c_wallet = await TestWalletDef.test_wallet();

    let newPrincipal = await g_canister_factory.create({
      owner = Principal.fromActor(this);
      storage_space = null;
    });

    let canister : Types.Service = actor (Principal.toText(newPrincipal));

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));

    let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(a_wallet)));

    //TRX0004
    let trxattempt_fail = await c_wallet.try_owner_transfer(Principal.fromActor(canister), "1", #principal(Principal.fromActor(b_wallet)));

    //TRX0002
    let trxattempt = await a_wallet.try_owner_transfer(Principal.fromActor(canister), "1", #principal(Principal.fromActor(b_wallet)));

    let suite = S.suite(
      "test staged Nft",
      [

        S.test(
          "owner can transfer",
          switch (trxattempt) {
            case (#ok(res)) {
              switch (res.transaction.txn_type) {
                case (#owner_transfer(details)) {
                  if (Types.account_eq(details.from, #principal(Principal.fromActor(a_wallet))) == false) {
                    "from didnt match";
                  } else if (Types.account_eq(details.to, #principal(Principal.fromActor(b_wallet))) == false) {
                    "to didnt match";
                  } else {
                    "correct response";
                  };
                };
                case (_) {
                  "wrong tx type";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //TRX0002
        S.test(
          "fail if transfering for an item you don't own",
          switch (trxattempt_fail) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 11) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0011

      ],
    );

    S.run(suite);

    return #success;

  };

  public shared func testAuction() : async { #success; #fail : Text } {
    D.print("running Auction");

    let dfx : DFXTypes.Service = actor (Principal.toText(dfx_ledger));

    let dfx2 : DFXTypes.Service = actor (Principal.toText(dfx_ledger2));

    let a_wallet = await TestWalletDef.test_wallet();
    let b_wallet = await TestWalletDef.test_wallet();

    let funding_result_a = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    let funding_result_b = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    let funding_result_b2 = await dfx2.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    D.print("funding result b2 " # debug_show (funding_result_b2));

    let newPrincipal = await g_canister_factory.create({
      owner = Principal.fromActor(this);
      storage_space = null;
    });

    let initialOwnerBalance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(this);
      subaccount = null;
    });

    D.print("initialOwnerBalance = " # debug_show (initialOwnerBalance));

    let canister : Types.Service = actor (Principal.toText(newPrincipal));

    let mode = canister.__set_time_mode(#test);
    let atime = canister.__advance_time(Time.now());

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning a minted item
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning an unminted item

    D.print("Minting");
    let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(this))); //mint to the test account
    let mint_attempt2 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this))); //mint to the test account

    D.print("start auction fail " # debug_show ((mint_attempt, mint_attempt2)));
    //non owner start auction should fail MKT0019
    let start_auction_attempt_fail = await a_wallet.try_start_auction(Principal.fromActor(canister), Principal.fromActor(dfx), "1", null);

    D.print("start auction owner");
    //start an auction by owner
    let start_auction_attempt_owner = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #auction {
          reserve = ?(100 * 10 ** 8);
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          buy_now = ?(500 * 10 ** 8); //nyi
          start_price = (1 * 10 ** 8);
          start_date = 0;
          ending = #date(get_time() + DAY_LENGTH);
          min_increase = #amount(10 * 10 ** 8);
          allow_list = null;
        };
      };
    });

    D.print("get sale id " # debug_show (start_auction_attempt_owner));
    let current_sales_id = switch (start_auction_attempt_owner) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };

      };
      case (#err(item)) {
        D.print("error with auction start");
        return #fail("error with auction start");
      };
    };

    let active_sale_info_1 = await canister.sale_info_nft_origyn(#active(null));

    D.print("starting again");
    //try starting again//should fail MKT0018
    let start_auction_attempt_owner_already_started = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #auction {
          reserve = ?(100 * 10 ** 8);
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          buy_now = ?(500 * 10 ** 8);
          start_price = (1 * 10 ** 8);
          start_date = 0;
          ending = #date(get_time() + DAY_LENGTH);
          min_increase = #amount(10 * 10 ** 8);
          allow_list = null;
        };
      };
    });

    //MKT0020 - try to transfer with an open auction
    let transfer_owner_after_auction = await canister.share_wallet_nft_origyn({
      token_id = "1";
      from = #principal(Principal.fromActor(this));
      to = #principal(Principal.fromActor(b_wallet));
    });

    //place escrow
    D.print("sending tokens to canisters");
    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (4 * 10 ** 8) + 800000, Principal.fromActor(canister));

    //balance should be 4 ICP + 800000

    let block = switch (a_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work" # debug_show (other));
        return #fail("ledger didnt work");
      };
    };

    D.print("trying deposit");
    //try to witdraw back 1 icp from deposit
    let a_wallet_try_deposit_refund = await a_wallet.try_deposit_refund(Principal.fromActor(canister), Principal.fromActor(dfx), 1 * 10 ** 8, null);

    D.print("a_wallet_try_deposit_refund" # debug_show (a_wallet_try_deposit_refund));
    D.print("Sending real escrow now a wallet trye scrow");

    //claiming first escrow
    let a_wallet_try_escrow_general_staged = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "1", ?current_sales_id, null, null);

    D.print("should be done now");
    let a_balance_before_first = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    D.print("the balance before first is");
    D.print(debug_show (a_balance_before_first));

    //place a bid below start price

    let a_wallet_try_bid_below_start = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 7 + 200000, "1", current_sales_id, null, null);
    //aboves should refund the bid
    //todo: bid should be refunded

    let a_balance_after_bad_bid = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    D.print("a balance " # debug_show (a_balance_after_bad_bid));

    D.print("Sending real escrow now 2");
    let a_wallet_try_escrow_general_staged2b = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 2 * 10 ** 8, "1", ?current_sales_id, null, null);
    //this should clear out the deposit account

    D.print("Sending real escrow now result 2" # debug_show (a_wallet_try_escrow_general_staged2b));

    let a_balance_after_bad_bid2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    D.print("a balance 2 " # debug_show (a_balance_after_bad_bid2));

    //try a bid in th wrong currency
    //place escrow
    D.print("sending tokens to canisters b");
    let b_wallet_send_tokens_to_canister = await b_wallet.send_ledger_deposit(Principal.fromActor(dfx2), (200 * 10 ** 8) + 200000, Principal.fromActor(canister));

    let block2b = switch (b_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    D.print("Sending escrow for wrong currency escrow now b");
    let b_wallet_try_escrow_wrong_currency = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx2), null, 1 * 10 ** 8, "1", ?current_sales_id, null, null);

    //place a bid wiht wrong asset MKT0023
    let b_wallet_try_bid_wrong_asset = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx2), 1 * 10 ** 8, "1", current_sales_id, null, null);

    //place a bid on token that isn't for sale MKT0024
    let a_wallet_try_bid_wrong_token_id_not_exist = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 8, "2", current_sales_id, null, null);

    //try starting again//should fail MKT0018
    let end_date = get_time() + DAY_LENGTH;
    D.print("end date is ");
    D.print(debug_show (end_date));

    //todo: write test
    let start_auction_attempt_owner_already_started_b = await canister.market_transfer_nft_origyn({
      token_id = "2";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #auction {
          reserve = ?(100 * 10 ** 8);
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          buy_now = ?(500 * 10 ** 8);
          start_price = (1 * 10 ** 8);
          start_date = 0;
          ending = #date(end_date);
          min_increase = #amount(10 * 10 ** 8);
          allow_list = null;
        };
      };
    });

    //place a bid on token that isn't for sale MKT0024
    let a_wallet_try_bid_wrong_token_id_exists = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 8, "2", current_sales_id, null, null);

    //place a bid with bad owner data MKT0025
    let a_wallet_try_bid_wrong_owner = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), 1 * 10 ** 8, "1", current_sales_id, null, null);

    //place a bid with bad sales id MKT0026
    let a_wallet_try_bid_wrong_sales_id = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 8, "1", "test", null, null);

    let a_balance_after_bad_bid3 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    D.print("a balance 3 " # debug_show (a_balance_after_bad_bid2));

    //place a valid bid MKT0027
    let a_wallet_try_bid_valid = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 8, "1", current_sales_id, null, null);
    D.print("a_wallet_try_bid_valid " # debug_show (a_wallet_try_bid_valid));

    let a_balance_after_bad_bid4 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    D.print("a balance 4 " # debug_show (a_balance_after_bad_bid4));

    //check transaction log for bid MKT0033, TRX0005
    let a_history_1 = await canister.history_nft_origyn("1", null, null); //gets all history

    D.print("history1" # debug_show (a_history_1));

    //make sure next min bid is bid + minimum increase MKT0032
    let a_sale_status_min_bid_increase = await canister.nft_origyn("1");

    D.print("withdraw during bid");
    //todo: attempt to withdraw escrow for active bid should fail ESC0016 NFT-76
    let a_withdraw_during_bid = await a_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", 1 * 10 ** 8, null);

    D.print("passed this");
    //place escrow b
    let new_bid_val = switch (a_sale_status_min_bid_increase) {
      case (#ok(res)) {

        switch (res.current_sale) {
          case (?current_sale) {
            switch (NFTUtils.get_auction_state_from_statusStable(current_sale)) {
              case (#err(err)) {
                return #fail("cannot get min bid to make second bid");
              };
              case (#ok(res)) {
                res.min_next_bid;
              };
            };
          };
          case (null) {
            return #fail("no sale found for finding min bid for second bid");
          };
        };
      };
      case (#err(err)) {
        return #fail("cannot get min bid to make second bid");
      };
    };

    //deposit escrow for two upcoming bids
    D.print("sending tokens to canisters");
    let b_wallet_send_tokens_to_canister_correct_ledger = await b_wallet.send_ledger_deposit(Principal.fromActor(dfx), (new_bid_val * 2) + 400000, Principal.fromActor(canister));

    D.print("Sending escrow for correct currency escrow now");
    let b_wallet_try_escrow_too_low = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, new_bid_val - 10, "1", ?current_sales_id, null, null);

    //place a low bid bid
    let b_wallet_try_bid_to_low = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), new_bid_val - 10, "1", current_sales_id, null, null);

    //try this bid without submitting escrow first...bid should try to load escrow
    //D.print("Sending escrow for correct currency escrow now");
    //let b_wallet_try_escrow_correct_currency2 = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, new_bid_val, "1", ?current_sales_id, null, null);

    //place a second bid
    let b_wallet_try_bid_valid = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), new_bid_val, "1", current_sales_id, null, null);

    D.print("did b bid work? ");
    D.print(debug_show (b_wallet_try_bid_valid));

    let b_balance_after_bid = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet))); //gets all history

    D.print("found balance after bid ");
    D.print(debug_show (b_balance_after_bid));

    //check transaction log for bid MKT0033, TRX0005
    let b_history_1 = await canister.history_nft_origyn("1", null, null); //gets all history

    D.print("found balance after bid ");
    D.print(debug_show (b_history_1));

    //place more escrow a
    //make sure next min bid is bid + minimum increase MKT0032
    let b_sale_status_min_bid_increase = await canister.nft_origyn("1");

    let new_bid_val_b = switch (b_sale_status_min_bid_increase) {
      case (#ok(res)) {

        switch (res.current_sale) {
          case (?current_sale) {
            switch (NFTUtils.get_auction_state_from_statusStable(current_sale)) {
              case (#err(err)) {
                return #fail("cannot get min bid to make third bid");
              };
              case (#ok(res)) {
                res.min_next_bid;
              };
            };
          };
          case (null) {
            return #fail("no sale found for finding min bid for third bid");
          };
        };
      };
      case (#err(err)) {
        return #fail("cannot get min bid to make third bid");
      };
    };

    let a_balance_before_third_escrow = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    D.print("the balance before third escrow is");
    D.print(debug_show (a_balance_before_third_escrow));

    let a_wallet_send_tokens_to_canister2 = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (101 * 10 ** 8) + 200000, Principal.fromActor(canister));

    let block3 = switch (a_wallet_send_tokens_to_canister2) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    D.print("Sending real escrow now 3"); //escrow is for 100. There should already be 1 in the escrow account. we are going to bid 101 above reserve
    let a_wallet_try_escrow_specific_3 = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 101 * 10 ** 8, "1", ?current_sales_id, null, null);

    D.print("specific result is");
    D.print(debug_show (a_wallet_try_escrow_specific_3));
    //todo check escrow balance
    //check balance and make sure we see the escrow BAL0002
    let a_balance_before_third = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    D.print("the balance before third is");
    D.print(debug_show (a_balance_before_third));

    //place a third bid
    let a_wallet_try_bid_valid_3 = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 101 * 10 ** 8, "1", current_sales_id, null, null);
    D.print("valid 3");
    D.print(debug_show (a_wallet_try_bid_valid_3));

    //try to end auction before it is time should fail
    let end_before = await canister.sale_nft_origyn(#end_sale("1"));
    D.print("end before");
    D.print(debug_show (end_before));
    D.print("end before");

    //advance time
    let time_result = await canister.__advance_time(end_date + 1);
    D.print("new time");
    D.print(debug_show (time_result));

    //end auction
    let end_proper = await canister.sale_nft_origyn(#end_sale("1"));
    D.print("end proper");
    D.print(debug_show (end_proper));

    //end again, should fail
    let end_again = await canister.sale_nft_origyn(#end_sale("1"));
    D.print("end again");
    D.print(debug_show (end_again));

    //create fake wallet for time duration
    let fake_wallet = await TestWalletDef.test_wallet();

    //try to withdraw winning bid NFT-110
    let a_withdraw_during_win = await a_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", 101 * 10 ** 8, null);

    //NFT-94 check ownership
    //check balance and make sure we see the nft
    let a_balance_after_close = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    // //MKT0029, MKT0036
    let a_sale_status_over_new_owner = await canister.nft_origyn("1");

    // //check transaction log

    //create fake wallet for time duration

    //check transaction log for sale
    let a_history_3 = await canister.history_nft_origyn("1", null, null); //gets all history

    // //a tries to start a new sale

    // //item is replaced in the current sale
    let b_balance_before_withdraw = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet))); //gets all history

    D.print("found balance before escrow withdraw");
    D.print(debug_show (b_balance_before_withdraw));
    //b tries to withdraw more than in account NFT-99

    let b_withdraw_over = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", 101 * 10 ** 8, null);

    // //b tries to withdraw for other buyer NFT-102

    let b_withdraw_bad_buyer = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);

    // //b tries to withdraw for other seller NFT-104

    let b_withdraw_bad_seller = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(a_wallet), "1", new_bid_val, null);

    // //b tries to withdraw for other tokenid NFT-105

    let b_withdraw_bad_token_id = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(a_wallet), "32", new_bid_val, null);

    // //b tries to withdraw for other token NFT-103

    let b_withdraw_bad_token = await b_wallet.try_escrow_withdraw(
      Principal.fromActor(canister),
      Principal.fromActor(b_wallet),
      Principal.fromActor(dfx),
      Principal.fromActor(a_wallet),
      "1",
      new_bid_val,
      ? #ic {
        canister = Principal.fromActor(dfx2);
        standard = #Ledger;
        decimals = 8;
        symbol = "LGY";
        fee = ?200000;
        id = null;
      },
    );

    // //b escrow should be auto refunded - need to test

    let b_withdraw = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);

    D.print("this withdraw should not work");
    D.print(debug_show (b_withdraw));
    //b withdraws escrow again NFT-106

    let b_withdraw_again = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);
    D.print("this withdraw should not work again");
    D.print(debug_show (b_withdraw_again));

    //check transaction log for sale
    let b_history_withdraw = await canister.history_nft_origyn("1", null, null); //gets all history

    //attempt to withdraw the sale revenue for the seller(this canister)

    //NFT-113
    //get balanance and make sure the sale is in the balance
    let owner_balance_after_sale = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(this)));
    D.print("owner_balance_after_sale" # debug_show (owner_balance_after_sale));

    D.print("withdraw over for owner");
    //NFT-114
    //try to withdraw too much
    let owner_withdraw_over = await canister.sale_nft_origyn(#withdraw(#sale({ withdraw_to = #principal(Principal.fromActor(this)); token_id = "1"; token = #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }); seller = #principal(Principal.fromActor(this)); buyer = #principal(Principal.fromActor(a_wallet)); amount = (101 * 10 ** 8) + 15 })));

    // //NFT-115
    // //have a_wallet try to withdraw the sale
    let a_withdraw_attempt_sale = await a_wallet.try_sale_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);

    //NFT-116
    //try to withdare the wrong asset
    D.print("owner_withdraw_wrong_asset");
    let owner_withdraw_wrong_asset = await canister.sale_nft_origyn(#withdraw(#sale({ withdraw_to = #principal(Principal.fromActor(this)); token_id = "1"; token = #ic({ canister = Principal.fromActor(dfx2); standard = #Ledger; decimals = 8; symbol = "LGY"; fee = ?200000; id = null }); seller = #principal(Principal.fromActor(this)); buyer = #principal(Principal.fromActor(a_wallet)); amount = 101 * 10 ** 8 })));

    //NFT-117
    //todo: try to withdraw the wrong token_id
    D.print("owner_withdraw_wrong_token_id");
    let owner_withdraw_wrong_token_id = await canister.sale_nft_origyn(#withdraw(#sale({ withdraw_to = #principal(Principal.fromActor(this)); token_id = "2"; token = #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }); seller = #principal(Principal.fromActor(this)); buyer = #principal(Principal.fromActor(a_wallet)); amount = 101 * 10 ** 8 })));

    //NFT-19
    //todo: withdraw the proper amount
    D.print("withdrawing proper amount from sale");
    let owner_withdraw_proper_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(this)));

    D.print("Proper amount result balance");
    D.print(debug_show (owner_withdraw_proper_balance));

    let owner_withdraw_proper = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(this);
      subaccount = null;
    });

    D.print("Proper amount result");
    D.print(debug_show (owner_withdraw_proper));

    //NFT-118
    //todo: try to withdraw again
    D.print("trying to withdraw sale again");
    let owner_withdraw_again = await canister.sale_nft_origyn(#withdraw(#sale({ withdraw_to = #principal(Principal.fromActor(this)); token_id = "1"; token = #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }); seller = #principal(Principal.fromActor(this)); buyer = #principal(Principal.fromActor(a_wallet)); amount = 101 * 10 ** 8 })));

    // //NFT-118
    // //todo: check balance and make sure it is gone
    let owner_balance_after_withdraw = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(this)));

    //NFT-19
    //todo: check ledger and make sure transaction is there and it went to the right account
    //check transaction log for sale
    D.print("trying owner hisotry");
    let owner_history_withdraw = await canister.history_nft_origyn("1", null, null); //gets all history

    let active_sale_info_2 = await canister.sale_info_nft_origyn(#active(null));

    let history_sale_info_2 = await canister.sale_info_nft_origyn(#history(null));

    //try to cancel the sale created for 2

    let cancel_auction_with_no_bids = await canister.sale_nft_origyn(#end_sale("2"));

    let active_sale_info_3 = await canister.sale_info_nft_origyn(#active(null));

    let suite = S.suite(
      "test staged Nft",
      [

        S.test(
          "test mint attempt",
          switch (mint_attempt) {
            case (#ok(res)) {

              "correct response";

            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),
        S.test(
          "fail if non owner tries to start auction",
          switch (start_auction_attempt_fail) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 2000) {
                //unauthorized
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0019
        S.test(
          "fail if auction already running",
          switch (start_auction_attempt_owner_already_started) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 13) {
                //existing sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0018
        S.test(
          "auction is started",
          switch (start_auction_attempt_owner) {
            case (#ok(res)) {
              switch (res.txn_type) {
                case (#sale_opened(details)) {
                  "correct response";
                };
                case (_) {
                  "bad transaction type";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //MKT0021

        S.test(
          "fail if refund isn't succesful",
          switch (a_wallet_try_deposit_refund) {
            case (#ok(res)) {
              "expected success";
            };
            case (#err(err)) {

              "wrong error " # debug_show (err);
            };
          },
          M.equals<Text>(T.text("expected success")),
        ),
        S.test(
          "transfer ownerfail if auction already running",
          switch (transfer_owner_after_auction) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 13) {
                //existing sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0022
        S.test(
          "fail if bid too low",
          switch (a_wallet_try_bid_below_start) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4004) {
                //below bid price
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0023
        S.test(
          "fail if wrong asset",
          switch (b_wallet_try_bid_wrong_asset) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4002) {
                //wrong asset
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0024
        S.test(
          "fail if cant find sale id ",
          switch (a_wallet_try_bid_wrong_token_id_not_exist) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4003) {
                //MKT0024
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0023
        S.test(
          "fail if bid on wrong token ",
          switch (a_wallet_try_bid_wrong_token_id_exists) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4003) {
                //wrong token
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0026

        S.test(
          "fail if bid on wrong owner ",
          switch (a_wallet_try_bid_wrong_owner) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4001) {
                //wrong token
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0025
        S.test(
          "bid is succesful",
          switch (a_wallet_try_bid_valid) {
            case (#ok(res)) {
              D.print("as bid");
              D.print(debug_show (a_wallet_try_bid_valid));
              switch (res.txn_type) {
                case (#auction_bid(details)) {
                  if (
                    Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 1 * 10 ** 8 and details.sale_id == current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                  ) {
                    "correct response";
                  } else {
                    "details didnt match" # debug_show (details);
                  };
                };
                case (_) {
                  "bad transaction bid";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //MKT0027
        S.test(
          "transaction history has the bid",
          switch (a_history_1) {
            case (#ok(res)) {

              D.print("where ismy history");
              D.print(debug_show (a_history_1));
              if (res.size() > 0) {
                switch (res[res.size() -1].txn_type) {
                  case (#auction_bid(details)) {
                    if (
                      Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 1 * 10 ** 8 and details.sale_id == current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                    ) {
                      "correct response";
                    } else {
                      "details didnt match" # debug_show (details);
                    };
                  };
                  case (_) {
                    "bad history bid";
                  };
                };
              } else {
                "size was 0";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //TRX0005, MKT0033
        S.test(
          "min bid increased",
          switch (a_sale_status_min_bid_increase) {
            case (#ok(res)) {

              switch (res.current_sale) {
                case (?current_sale) {
                  switch (NFTUtils.get_auction_state_from_statusStable(current_sale)) {
                    case (#err(err)) {
                      "unexpected error: " # err.flag_point;
                    };
                    case (#ok(res)) {
                      //let min_bid_increase =
                      if (res.min_next_bid == (1 * 10 ** 8) + 10 * 10 ** 8) {
                        "correct response";
                      } else {
                        "wrong bid " # debug_show (res.min_next_bid);
                      };
                    };
                  };

                };
                case (_) {
                  "bad info min bid";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //MKT0032
        S.test(
          "fail if bid is too low ",
          switch (b_wallet_try_bid_to_low) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4004) {
                //too low
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //todo: create user story for bid too low
        S.test(
          "transaction history has the new bid",
          switch (b_history_1) {
            case (#ok(res)) {

              D.print("new bid history");
              D.print(debug_show (b_history_1));
              if (res.size() > 0) {
                switch (res[res.size() -1].txn_type) {
                  case (#auction_bid(details)) {
                    if (
                      Types.account_eq(details.buyer, #principal(Principal.fromActor(b_wallet))) and details.amount == new_bid_val and details.sale_id == current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                    ) {
                      "correct response";
                    } else {
                      "details didnt match for second bid " # debug_show (details);
                    };
                  };
                  case (_) {
                    "bad history bid for b " # debug_show (res);
                  };
                };
              } else {
                "size was zero for new bid";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //TRX0005, MKT0033
        S.test(
          "escrow balance is right amount for a before thrid bid",
          switch (a_balance_before_third) {
            case (#ok(res)) {
              D.print("testing third bid");
              D.print(debug_show (res));
              D.print(debug_show (#principal(Principal.fromActor(canister))));
              D.print(debug_show (#principal(Principal.fromActor(a_wallet))));
              D.print(debug_show (Principal.fromActor(dfx)));
              D.print(debug_show (Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(canister)))));
              D.print(debug_show (Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet)))));
              D.print(debug_show (res.escrow[0].token_id == "1"));
              D.print(debug_show (Types.token_eq(res.escrow[0].token, #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))));
              D.print(debug_show (res.escrow[0].amount == 104 * 10 ** 8, res.escrow[0].amount, 104 * 10 ** 8));
              if (
                Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(this))) and Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet))) and res.escrow[0].token_id == "1" and Types.token_eq(res.escrow[0].token, #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })) and res.escrow[0].amount == 103 * 10 ** 8
              ) {
                "found escrow record";
              } else {
                D.print(debug_show (res));
                "didnt find record ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found escrow record")),
        ), //todo: MKT0037
        S.test(
          "auction winner is the new owner",
          switch (a_sale_status_over_new_owner) {
            case (#ok(res)) {

              let new_owner = switch (
                Metadata.get_nft_owner(
                  switch (a_sale_status_over_new_owner) {
                    case (#ok(item)) {
                      item.metadata;
                    };
                    case (#err(err)) {
                      #Option(null);
                    };
                  }
                )
              ) {
                case (#err(err)) {
                  #account_id("wrong");
                };
                case (#ok(val)) {
                  val;
                };
              };
              D.print("new owner");
              D.print(debug_show (new_owner));
              D.print(debug_show (Principal.fromActor(a_wallet)));
              if (Types.account_eq(new_owner, #principal(Principal.fromActor(a_wallet)))) {
                "found correct owner";
              } else {
                D.print(debug_show (res));
                "didnt find record ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found correct owner")),
        ), //MKT0029
        S.test(
          "current sale status is ended",
          switch (a_sale_status_over_new_owner) {
            case (#ok(res)) {
              D.print("a_sale_status_over_new_owner");
              D.print(debug_show (a_sale_status_over_new_owner));
              //MKT0036 sale should be over and there should be a record with status #ended
              switch (a_sale_status_over_new_owner) {
                case (#ok(res)) {

                  switch (res.current_sale) {
                    case (null) {
                      "current sale improperly removed";
                    };
                    case (?val) {
                      switch (val.sale_type) {
                        case (#auction(state)) {
                          D.print("state");
                          D.print(debug_show (state));
                          let current_status = switch (state.status) {
                            case (#closed) { true };
                            case (_) { false };
                          };
                          if (
                            current_status == true and val.sale_id == current_sales_id
                          ) {
                            "found closed sale";
                          } else {
                            "didnt find closed sale";
                          };

                        };

                      };
                    };
                  };

                };
                case (#err(err)) {
                  "error getting";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found closed sale")),
        ), // MKT0036

        S.test(
          "transaction history have the transfer - auction",
          switch (a_history_3) {
            case (#ok(res)) {

              if (res.size() > 1) {
                switch (res[res.size() - 2].txn_type) {

                  case (#sale_ended(details)) {
                    D.print("sale_ended");
                    D.print(debug_show (details));
                    if (
                      Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 101 * 10 ** 8 and details.sale_id == ?current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                    ) {
                      "correct response";
                    } else {
                      "details didnt match" # debug_show (details);
                    };
                  };
                  case (_) {
                    "bad history sale " # debug_show (a_history_3);
                  };
                };
              } else {
                "size was les than one";
              };

            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //todo: make a user story for adding a #sale_ended to the end of transaction log
        S.test(
          "fail if ended before corect date ",
          switch (end_before) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4007) {
                //sale not over
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //todo: create user story for sale not over
        S.test(
          "transaction history have the transfer - auction 2",
          switch (end_proper) {
            case (#ok(#end_sale(res))) {
              D.print("transaction history have the transfer 2");
              D.print(debug_show (res));
              switch (res.txn_type) {
                case (#sale_ended(details)) {
                  if (
                    Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 101 * 10 ** 8 and Option.get(details.sale_id, "") == current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                  ) {
                    "correct response";
                  } else {
                    "details didnt match" # debug_show (details);
                  };
                };
                case (_) {
                  "bad history sale";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
            case (_) { "unexpected error: " };
          },
          M.equals<Text>(T.text("correct response")),
        ), //todo: make a user story for adding a #sale_ended to the end of transaction log
        S.test(
          "fail if auction already over ",
          switch (end_again) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4006) {
                //new owner so unauthorized
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //todo: create user story for sale over
        S.test(
          "fail if escrow amount over deposited amount",
          switch (b_withdraw_over) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //escrow no longer found since it was refunded
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-101
        S.test(
          "fail if escrow amount is the wrong token",
          switch (b_withdraw_bad_token) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //shouldn't be able to find escrow
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //t NFT-103
        S.test(
          "fail if escrow amount is the wrong seller",
          switch (b_withdraw_bad_seller) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //shouldn't be able to find escrow
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //t NFT-104
        S.test(
          "fail if escrow amount is the wrong buyer",
          switch (b_withdraw_bad_buyer) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 2000) {
                //unauthorized
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-102
        S.test(
          "fail if escrow amount is the wrong token_id",
          switch (b_withdraw_bad_token_id) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //token id not found
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-105
        S.test(
          "fail if escrow removed twice",
          switch (b_withdraw_bad_token_id) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //withdraw too large because 0 and not found
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-106
        S.test(
          "fail if escrow is for the current winning bid",
          switch (a_withdraw_during_bid) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3008) {
                //cannot be removed
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-76

        S.test(
          "fail if escrow is for the winning bid a withdraw",
          switch (a_withdraw_during_win) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000 or err.number == 3007) {
                //wont be able to find it because it has been zeroed out.
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-110
        S.test(
          "fail if escrow is for the winning bid b withdraw",
          switch (b_withdraw) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //wont be able to find it because it has been zeroed out.
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-18, NFT-101 - These were negated by NFT-120
        //todo: test needs to be re written to cycle through history and find the escrow
        /* S.test("escrow withdraw in transaction record", switch(b_history_withdraw){case(#ok(res)){
                D.print("b_history_withdraw");
                D.print(debug_show(b_history_withdraw));
                switch(res[res.size()-1].txn_type){
                    case(#escrow_withdraw(details)){
                        if(Types.account_eq(details.buyer, #principal(Principal.fromActor(b_wallet))) and
                                Types.account_eq(details.seller, #principal(Principal.fromActor(this))) and
                                details.amount == ((11*10**8) - dip20_fee) and
                                details.token_id == "1" and
                                Types.token_eq(details.token, #ic({
                                    canister = (Principal.fromActor(dfx));
                                    standard =  #Ledger;
                                    decimals = 8;
                                    symbol = "LDG";
                                    fee = ?200000;
                                    id = null;}))){
                                    "correct response";
                            } else {
                                "details didnt match" # debug_show(details);
                            };
                    };
                    case(_){
                        D.print("Bad history sale");
                        D.print(debug_show(res));
                        "bad history sale";
                    };
                };
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //NFT-107
            */
        S.test(
          "sales balance after sale has balance in it",
          switch (owner_balance_after_sale) {
            case (#ok(res)) {
              D.print("testing sale balance 1");
              D.print(debug_show (res));

              if (res.sales.size() == 0) {

                "found no sales record";
              } else {

                D.print(debug_show (res));
                "found record ";
              };
            };
            case (#err(err)) { "unexpected error: " # err.flag_point };
          },
          M.equals<Text>(T.text("found no sales record")),
        ), //todo: NFT-113
        S.test(
          "fail if withdraw over sale amount",
          switch (owner_withdraw_over) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //can't find it
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-114
        S.test(
          "fail if withdraw from wrong account",
          switch (a_withdraw_attempt_sale) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 2000) {
                //unauthorized access
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-115
        S.test(
          "fail if withdraw from wrong asset",
          switch (owner_withdraw_wrong_asset) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //cant find sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-116
        S.test(
          "fail if withdraw from wrong token id",
          switch (owner_withdraw_wrong_token_id) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //cant find sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-117
        S.test(
          "fail if withdraw a second time",
          switch (owner_withdraw_again) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //cant find sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-117
        S.test("sale withdraw works", owner_withdraw_proper, M.equals<Nat>(T.nat(initialOwnerBalance + 10099600000))), //NFT-18, NFT-101
        S.test(
          "sales balance after withdraw has no balance in it",
          switch (owner_balance_after_withdraw) {
            case (#ok(res)) {
              D.print("testing sale balance 2");
              D.print(debug_show (res));

              if (res.sales.size() == 0) {
                "found empty record";
              } else {
                D.print(debug_show (res));
                "found a record ";
              };
            };
            case (#err(err)) { "unexpected error: " # err.flag_point };
          },
          M.equals<Text>(T.text("found empty record")),
        ), //todo: NFT-118
        S.test(
          "sale withdraw in history",
          switch (owner_history_withdraw) {
            case (#ok(res)) {
              D.print("sales withdraw history");
              D.print(debug_show (res));
              switch (res[res.size() -1].txn_type) {
                case (#sale_withdraw(details)) {
                  D.print(debug_show (details));
                  if (
                    Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and
                    Types.account_eq(details.seller, #principal(Principal.fromActor(this))) and
                    details.amount == (Nat.sub(((101 * 10 ** 8) -200000), dip20_fee)) and
                    details.token_id == "1" and
                    Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                  ) {
                    "correct response";
                  } else {
                    "details didnt match" # debug_show (details);
                  };
                };
                case (_) {
                  D.print(debug_show (res[res.size() -1]));
                  "bad history withdraw";
                };
              };
            };
            case (#err(err)) { "unexpected error: " # err.flag_point };
          },
          M.equals<Text>(T.text("correct response")),
        ), //NFT-19
        S.test(
          "nft balance after sale",
          switch (a_balance_after_close) {
            case (#ok(res)) {
              D.print("testing nft balance");
              D.print(debug_show (res));

              if (res.nfts.size() == 0) {
                "found empty record";
              } else {
                D.print(debug_show (res));
                if (res.nfts[res.nfts.size() -1] == "1") {
                  "found a record";
                } else {
                  "didnt find record";
                };

              };
            };
            case (#err(err)) { "unexpected error: " # err.flag_point };
          },
          M.equals<Text>(T.text("found a record")),
        ), //todo: NFT-94

        S.test(
          "sale info has active and only active sale in it",
          switch (active_sale_info_1) {
            case (#ok(#active(val))) {
              if (val.records.size() == 1 and val.records[0].0 == "1") {
                "correct response";
              } else {
                "bad response" # debug_show (active_sale_info_1);
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_1);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "sale info has one active sale after close of first",
          switch (active_sale_info_2) {
            case (#ok(#active(val))) {
              if (val.records.size() == 1 and val.records[0].0 == "2") {
                "correct response";
              } else {
                "bad response" # debug_show (active_sale_info_2);
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_2);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "sale is included in history",
          switch (history_sale_info_2) {
            case (#ok(#history(val))) {
              if (val.records.size() == 2) {
                switch (val.records[0]) {
                  case (null) { "shouldnt be null" };
                  case (?val) {
                    if (val.sale_id == current_sales_id) {
                      "correct response";
                    } else {
                      "wrong sale id " # debug_show (val);
                    };
                  };
                };
              } else {
                "bad response" # debug_show (history_sale_info_2);
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (history_sale_info_2);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "sale info has no active sale after cancel",
          switch (active_sale_info_3) {
            case (#ok(#active(val))) {
              if (val.records.size() == 0) {
                "correct response";
              } else {
                "bad response" # debug_show (active_sale_info_3);
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_3);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),
      ],
    );

    D.print("suite running");

    S.run(suite);

    D.print("suite over");

    return #success;

  };

  public shared func testAuction_v2() : async { #success; #fail : Text } {
    D.print("running Auction");

    let dfx : DFXTypes.Service = actor (Principal.toText(dfx_ledger));

    let dfx2 : DFXTypes.Service = actor (Principal.toText(dfx_ledger2));

    let a_wallet = await TestWalletDef.test_wallet();
    let b_wallet = await TestWalletDef.test_wallet();

    let funding_result_a = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    let funding_result_b = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    let funding_result_b2 = await dfx2.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    D.print("funding result b2 " # debug_show (funding_result_b2));

    let newPrincipal = await g_canister_factory.create({
      owner = Principal.fromActor(this);
      storage_space = null;
    });

    let initialOwnerBalance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(this);
      subaccount = null;
    });

    D.print("initialOwnerBalance = " # debug_show (initialOwnerBalance));

    let canister : Types.Service = actor (Principal.toText(newPrincipal));

    let mode = canister.__set_time_mode(#test);
    let atime = canister.__advance_time(Time.now());

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning a minted item
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning an unminted item

    D.print("Minting");
    let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(this))); //mint to the test account
    let mint_attempt2 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this))); //mint to the test account

    D.print("start auction fail " # debug_show ((mint_attempt, mint_attempt2)));
    //non owner start auction should fail MKT0019
    let start_auction_attempt_fail = await a_wallet.try_start_ask(Principal.fromActor(canister), Principal.fromActor(dfx), "1", null);

    D.print("start auction owner");
    let option_buffer = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(100 * 10 ** 8),
      #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),
      #buy_now(500 * 10 ** 8),
      #start_price(1 * 10 ** 8),
      #ending(#date(get_time() + DAY_LENGTH)),
      #min_increase(#amount(10 * 10 ** 8)),
      #notify([
        Principal.fromActor(a_wallet),
        Principal.fromActor(b_wallet),
      ]),
    ]);
    //start an auction by owner
    let start_auction_attempt_owner = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer));
      };
    });

    D.print("get sale id " # debug_show (start_auction_attempt_owner));
    let current_sales_id = switch (start_auction_attempt_owner) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };

      };
      case (#err(item)) {
        D.print("error with auction start");
        return #fail("error with auction start");
      };
    };

    let active_sale_info_1 = await canister.sale_info_nft_origyn(#active(null));

    D.print("active_sale_info_1" # debug_show (active_sale_info_1));

    //force a round?

    let aRandom = await TestWalletDef.test_wallet();

    let aRandom2 = await TestWalletDef.test_wallet();
    let aRandom3 = await TestWalletDef.test_wallet();
    let aRandom4 = await TestWalletDef.test_wallet();

    //lets make sure that we were notified
    let notifications = await a_wallet.get_notifications();

    D.print("found notifications" # debug_show (notifications));

    D.print("starting again");
    //try starting again//should fail MKT0018
    let start_auction_attempt_owner_already_started = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer));
      };
    });

    D.print(" already started reslt ");
    D.print(debug_show (start_auction_attempt_owner_already_started));

    //MKT0020 - try to transfer with an open auction
    let transfer_owner_after_auction = await canister.share_wallet_nft_origyn({
      token_id = "1";
      from = #principal(Principal.fromActor(this));
      to = #principal(Principal.fromActor(b_wallet));
    });

    D.print(" transfer_owner_after_auction ");
    D.print(debug_show (start_auction_attempt_owner_already_started));

    //place escrow
    D.print("sending tokens to canisters");
    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (4 * 10 ** 8) + 800000, Principal.fromActor(canister));

    D.print(" a_wallet_send_tokens_to_canister ");
    D.print(debug_show (a_wallet_send_tokens_to_canister));

    //balance should be 4 ICP + 800000

    let block = switch (a_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work" # debug_show (other));
        return #fail("ledger didnt work");
      };
    };

    D.print(" block ");
    D.print(debug_show (block));

    D.print("trying deposit");
    //try to witdraw back 1 icp from deposit
    let a_wallet_try_deposit_refund = await a_wallet.try_deposit_refund(Principal.fromActor(canister), Principal.fromActor(dfx), 1 * 10 ** 8, null);

    D.print("a_wallet_try_deposit_refund" # debug_show (a_wallet_try_deposit_refund));
    D.print("Sending real escrow now a wallet trye scrow");

    //claiming first escrow
    let a_wallet_try_escrow_general_staged = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "1", ?current_sales_id, null, null);

    D.print("should be done now");
    let a_balance_before_first = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    D.print("the balance before first is");
    D.print(debug_show (a_balance_before_first));

    //place a bid below start price

    let a_wallet_try_bid_below_start = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 7 + 200000, "1", current_sales_id, null, null);
    //aboves should refund the bid
    //todo: bid should be refunded

    D.print("the after low bid ");
    D.print(debug_show (a_wallet_try_bid_below_start));

    let a_balance_after_bad_bid = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    D.print("a balance " # debug_show (a_balance_after_bad_bid));

    D.print("Sending real escrow now 2");
    let a_wallet_try_escrow_general_staged2b = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 2 * 10 ** 8, "1", ?current_sales_id, null, null);
    //this should clear out the deposit account

    D.print("Sending real escrow now result 2" # debug_show (a_wallet_try_escrow_general_staged2b));

    let a_balance_after_bad_bid2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    D.print("a balance 2 " # debug_show (a_balance_after_bad_bid2));

    //try a bid in th wrong currency
    //place escrow
    D.print("sending tokens to canisters b");
    let b_wallet_send_tokens_to_canister = await b_wallet.send_ledger_deposit(Principal.fromActor(dfx2), (200 * 10 ** 8) + 200000, Principal.fromActor(canister));

    let block2b = switch (b_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    D.print("Sending escrow for wrong currency escrow now b");
    let b_wallet_try_escrow_wrong_currency = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx2), null, 1 * 10 ** 8, "1", ?current_sales_id, null, null);

    //place a bid wiht wrong asset MKT0023
    let b_wallet_try_bid_wrong_asset = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx2), 1 * 10 ** 8, "1", current_sales_id, null, null);

    //place a bid on token that isn't for sale MKT0024
    let a_wallet_try_bid_wrong_token_id_not_exist = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 8, "2", current_sales_id, null, null);

    //try starting again//should fail MKT0018
    let end_date = get_time() + DAY_LENGTH;
    D.print("end date is ");
    D.print(debug_show (end_date));

    //todo: write test
    let start_auction_attempt_owner_already_started_b = await canister.market_transfer_nft_origyn({
      token_id = "2";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer));
      };
    });

    //place a bid on token that isn't for sale MKT0024
    let a_wallet_try_bid_wrong_token_id_exists = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 8, "2", current_sales_id, null, null);
    D.print("a_wallet_try_bid_wrong_token_id_exists " # debug_show (a_wallet_try_bid_wrong_token_id_exists));

    //place a bid with bad owner data MKT0025
    let a_wallet_try_bid_wrong_owner = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), 1 * 10 ** 8, "1", current_sales_id, null, null);
    D.print("a_wallet_try_bid_wrong_owner " # debug_show (a_wallet_try_bid_wrong_owner));

    //place a bid with bad sales id MKT0026
    let a_wallet_try_bid_wrong_sales_id = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 8, "1", "test", null, null);
    D.print("a_wallet_try_bid_wrong_sales_id " # debug_show (a_wallet_try_bid_wrong_sales_id));

    let a_balance_after_bad_bid3 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    D.print("a balance 3 " # debug_show (a_balance_after_bad_bid2));

    //place a valid bid MKT0027
    let a_wallet_try_bid_valid = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 8, "1", current_sales_id, null, null);
    D.print("a_wallet_try_bid_valid " # debug_show (a_wallet_try_bid_valid));

    let a_balance_after_bad_bid4 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    D.print("a balance 4 " # debug_show (a_balance_after_bad_bid4));

    //check transaction log for bid MKT0033, TRX0005
    let a_history_1 = await canister.history_nft_origyn("1", null, null); //gets all history

    D.print("history1" # debug_show (a_history_1));

    //make sure next min bid is bid + minimum increase MKT0032
    let a_sale_status_min_bid_increase = await canister.nft_origyn("1");

    D.print("withdraw during bid");
    //todo: attempt to withdraw escrow for active bid should fail ESC0016 NFT-76
    let a_withdraw_during_bid = await a_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", 1 * 10 ** 8, null);

    D.print("passed this");
    //place escrow b
    let new_bid_val = switch (a_sale_status_min_bid_increase) {
      case (#ok(res)) {

        switch (res.current_sale) {
          case (?current_sale) {
            switch (NFTUtils.get_auction_state_from_statusStable(current_sale)) {
              case (#err(err)) {
                return #fail("cannot get min bid to make second bid");
              };
              case (#ok(res)) {
                res.min_next_bid;
              };
            };
          };
          case (null) {
            return #fail("no sale found for finding min bid for second bid");
          };
        };
      };
      case (#err(err)) {
        return #fail("cannot get min bid to make second bid");
      };
    };

    //deposit escrow for two upcoming bids
    D.print("sending tokens to canisters");
    let b_wallet_send_tokens_to_canister_correct_ledger = await b_wallet.send_ledger_deposit(Principal.fromActor(dfx), (new_bid_val * 2) + 400000, Principal.fromActor(canister));

    D.print("Sending escrow for correct currency escrow now");
    let b_wallet_try_escrow_too_low = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, new_bid_val - 10, "1", ?current_sales_id, null, null);

    //place a low bid bid
    let b_wallet_try_bid_to_low = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), new_bid_val - 10, "1", current_sales_id, null, null);

    //try this bid without submitting escrow first...bid should try to load escrow
    //D.print("Sending escrow for correct currency escrow now");
    //let b_wallet_try_escrow_correct_currency2 = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, new_bid_val, "1", ?current_sales_id, null, null);

    //place a second bid
    let b_wallet_try_bid_valid = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), new_bid_val, "1", current_sales_id, null, null);

    D.print("did b bid work? ");
    D.print(debug_show (b_wallet_try_bid_valid));

    let b_balance_after_bid = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet))); //gets all history

    D.print("found balance after bid ");
    D.print(debug_show (b_balance_after_bid));

    //check transaction log for bid MKT0033, TRX0005
    let b_history_1 = await canister.history_nft_origyn("1", null, null); //gets all history

    D.print("found balance after bid ");
    D.print(debug_show (b_history_1));

    //place more escrow a
    //make sure next min bid is bid + minimum increase MKT0032
    let b_sale_status_min_bid_increase = await canister.nft_origyn("1");

    let new_bid_val_b = switch (b_sale_status_min_bid_increase) {
      case (#ok(res)) {

        switch (res.current_sale) {
          case (?current_sale) {
            switch (NFTUtils.get_auction_state_from_statusStable(current_sale)) {
              case (#err(err)) {
                return #fail("cannot get min bid to make third bid");
              };
              case (#ok(res)) {
                res.min_next_bid;
              };
            };
          };
          case (null) {
            return #fail("no sale found for finding min bid for third bid");
          };
        };
      };
      case (#err(err)) {
        return #fail("cannot get min bid to make third bid");
      };
    };

    let a_balance_before_third_escrow = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    D.print("the balance before third escrow is");
    D.print(debug_show (a_balance_before_third_escrow));

    let a_wallet_send_tokens_to_canister2 = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (101 * 10 ** 8) + 200000, Principal.fromActor(canister));

    let block3 = switch (a_wallet_send_tokens_to_canister2) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    D.print("Sending real escrow now 3"); //escrow is for 100. There should already be 1 in the escrow account. we are going to bid 101 above reserve
    let a_wallet_try_escrow_specific_3 = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 101 * 10 ** 8, "1", ?current_sales_id, null, null);

    D.print("specific result is");
    D.print(debug_show (a_wallet_try_escrow_specific_3));
    //todo check escrow balance
    //check balance and make sure we see the escrow BAL0002
    let a_balance_before_third = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    D.print("the balance before third is");
    D.print(debug_show (a_balance_before_third));

    //place a third bid
    let a_wallet_try_bid_valid_3 = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 101 * 10 ** 8, "1", current_sales_id, null, null);
    D.print("valid 3");
    D.print(debug_show (a_wallet_try_bid_valid_3));

    //force a round?

    let aRandom5 = await TestWalletDef.test_wallet();

    let aRandom6 = await TestWalletDef.test_wallet();
    let aRandom7 = await TestWalletDef.test_wallet();
    let aRandom8 = await TestWalletDef.test_wallet();

    //try to end auction before it is time should fail
    D.print("end before");

    let end_before = try {
      await canister.sale_nft_origyn(#end_sale("1"));
    } catch (e) {
      D.print(Error.message(e));
      D.trap(Error.message(e));
    };

    D.print(debug_show (end_before));
    D.print("end before");

    //advance time
    let time_result = await canister.__advance_time(end_date + 1);
    D.print("new time");
    D.print(debug_show (time_result));

    let aRandom9 = await TestWalletDef.test_wallet();

    let aRandom10 = await TestWalletDef.test_wallet();
    let aRandom11 = await TestWalletDef.test_wallet();
    let aRandom12 = await TestWalletDef.test_wallet();

    //end auction
    let end_proper = await canister.sale_nft_origyn(#end_sale("1"));
    D.print("end proper");
    D.print(debug_show (end_proper));

    //end again, should fail
    let end_again = await canister.sale_nft_origyn(#end_sale("1"));
    D.print("end again");
    D.print(debug_show (end_again));

    //try to withdraw winning bid NFT-110
    let a_withdraw_during_win = await a_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", 101 * 10 ** 8, null);

    //NFT-94 check ownership
    //check balance and make sure we see the nft
    let a_balance_after_close = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    // //MKT0029, MKT0036
    let a_sale_status_over_new_owner = await canister.nft_origyn("1");

    // //check transaction log

    //check transaction log for sale
    let a_history_3 = await canister.history_nft_origyn("1", null, null); //gets all history

    // //a tries to start a new sale

    // //item is replaced in the current sale
    let b_balance_before_withdraw = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet))); //gets all history

    D.print("found balance before escrow withdraw");
    D.print(debug_show (b_balance_before_withdraw));
    //b tries to withdraw more than in account NFT-99

    let b_withdraw_over = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", 101 * 10 ** 8, null);

    // //b tries to withdraw for other buyer NFT-102

    let b_withdraw_bad_buyer = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);

    // //b tries to withdraw for other seller NFT-104

    let b_withdraw_bad_seller = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(a_wallet), "1", new_bid_val, null);

    // //b tries to withdraw for other tokenid NFT-105

    let b_withdraw_bad_token_id = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(a_wallet), "32", new_bid_val, null);

    // //b tries to withdraw for other token NFT-103

    let b_withdraw_bad_token = await b_wallet.try_escrow_withdraw(
      Principal.fromActor(canister),
      Principal.fromActor(b_wallet),
      Principal.fromActor(dfx),
      Principal.fromActor(a_wallet),
      "1",
      new_bid_val,
      ? #ic {
        canister = Principal.fromActor(dfx2);
        standard = #Ledger;
        decimals = 8;
        symbol = "LGY";
        fee = ?200000;
        id = null;
      },
    );

    // //b escrow should be auto refunded - need to test

    let b_withdraw = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);

    D.print("this withdraw should not work");
    D.print(debug_show (b_withdraw));
    //b withdraws escrow again NFT-106

    let b_withdraw_again = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);
    D.print("this withdraw should not work again");
    D.print(debug_show (b_withdraw_again));

    //check transaction log for sale
    let b_history_withdraw = await canister.history_nft_origyn("1", null, null); //gets all history

    //attempt to withdraw the sale revenue for the seller(this canister)

    //NFT-113
    //get balanance and make sure the sale is in the balance
    let owner_balance_after_sale = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(this)));
    D.print("owner_balance_after_sale" # debug_show (owner_balance_after_sale));

    D.print("withdraw over for owner");
    //NFT-114
    //try to withdraw too much
    let owner_withdraw_over = await canister.sale_nft_origyn(#withdraw(#sale({ withdraw_to = #principal(Principal.fromActor(this)); token_id = "1"; token = #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }); seller = #principal(Principal.fromActor(this)); buyer = #principal(Principal.fromActor(a_wallet)); amount = (101 * 10 ** 8) + 15 })));

    // //NFT-115
    // //have a_wallet try to withdraw the sale
    let a_withdraw_attempt_sale = await a_wallet.try_sale_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);

    //NFT-116
    //try to withdare the wrong asset
    D.print("owner_withdraw_wrong_asset");
    let owner_withdraw_wrong_asset = await canister.sale_nft_origyn(#withdraw(#sale({ withdraw_to = #principal(Principal.fromActor(this)); token_id = "1"; token = #ic({ canister = Principal.fromActor(dfx2); standard = #Ledger; decimals = 8; symbol = "LGY"; fee = ?200000; id = null }); seller = #principal(Principal.fromActor(this)); buyer = #principal(Principal.fromActor(a_wallet)); amount = 101 * 10 ** 8 })));

    //NFT-117
    //todo: try to withdraw the wrong token_id
    D.print("owner_withdraw_wrong_token_id");
    let owner_withdraw_wrong_token_id = await canister.sale_nft_origyn(#withdraw(#sale({ withdraw_to = #principal(Principal.fromActor(this)); token_id = "2"; token = #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }); seller = #principal(Principal.fromActor(this)); buyer = #principal(Principal.fromActor(a_wallet)); amount = 101 * 10 ** 8 })));

    //NFT-19
    //todo: withdraw the proper amount
    D.print("withdrawing proper amount from sale");
    let owner_withdraw_proper_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(this)));

    D.print("Proper amount result balance");
    D.print(debug_show (owner_withdraw_proper_balance));

    let owner_withdraw_proper = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(this);
      subaccount = null;
    });

    D.print("Proper amount result");
    D.print(debug_show (owner_withdraw_proper));

    //NFT-118
    //todo: try to withdraw again
    D.print("trying to withdraw sale again");
    let owner_withdraw_again = await canister.sale_nft_origyn(#withdraw(#sale({ withdraw_to = #principal(Principal.fromActor(this)); token_id = "1"; token = #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }); seller = #principal(Principal.fromActor(this)); buyer = #principal(Principal.fromActor(a_wallet)); amount = 101 * 10 ** 8 })));

    // //NFT-118
    // //todo: check balance and make sure it is gone
    let owner_balance_after_withdraw = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(this)));

    //NFT-19
    //todo: check ledger and make sure transaction is there and it went to the right account
    //check transaction log for sale
    D.print("trying owner hisotry");
    let owner_history_withdraw = await canister.history_nft_origyn("1", null, null); //gets all history

    let active_sale_info_2 = await canister.sale_info_nft_origyn(#active(null));
    D.print("active_sale_info_2" # debug_show (active_sale_info_2));

    let history_sale_info_2 = await canister.sale_info_nft_origyn(#history(null));

    //try to cancel the sale created for 2

    let cancel_auction_with_no_bids = await canister.sale_nft_origyn(#end_sale("2"));

    let active_sale_info_3 = await canister.sale_info_nft_origyn(#active(null));

    let suite = S.suite(
      "test staged Nft ask",
      [

        S.test(
          "test mint attempt ask",
          switch (mint_attempt) {
            case (#ok(res)) {

              "correct response";

            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),
        S.test(
          "fail if non owner tries to start auction ask",
          switch (start_auction_attempt_fail) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 2000) {
                //unauthorized
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0019
        S.test(
          "fail if auction already running ask",
          switch (start_auction_attempt_owner_already_started) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 13) {
                //existing sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0018
        S.test(
          "auction is started ask ",
          switch (start_auction_attempt_owner) {
            case (#ok(res)) {
              switch (res.txn_type) {
                case (#sale_opened(details)) {
                  "correct response";
                };
                case (_) {
                  "bad transaction type";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //MKT0021

        S.test(
          "fail if refund isn't succesful ask",
          switch (a_wallet_try_deposit_refund) {
            case (#ok(res)) {
              "expected success";
            };
            case (#err(err)) {

              "wrong error " # debug_show (err);
            };
          },
          M.equals<Text>(T.text("expected success")),
        ),
        S.test(
          "transfer ownerfail if auction already running ask",
          switch (transfer_owner_after_auction) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 13) {
                //existing sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0022
        S.test(
          "fail if bid too low ask",
          switch (a_wallet_try_bid_below_start) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4004) {
                //below bid price
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0023
        S.test(
          "fail if wrong asset ask",
          switch (b_wallet_try_bid_wrong_asset) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4002) {
                //wrong asset
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0024
        S.test(
          "fail if cant find sale id ask ",
          switch (a_wallet_try_bid_wrong_token_id_not_exist) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4003) {
                //MKT0024
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0023
        S.test(
          "fail if bid on wrong token ask ",
          switch (a_wallet_try_bid_wrong_token_id_exists) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4003) {
                //wrong token
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0026

        S.test(
          "fail if bid on wrong owner ask ",
          switch (a_wallet_try_bid_wrong_owner) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4001) {
                //wrong token
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0025
        S.test(
          "bid is succesful ask ",
          switch (a_wallet_try_bid_valid) {
            case (#ok(res)) {
              D.print("as bid");
              D.print(debug_show (a_wallet_try_bid_valid));
              switch (res.txn_type) {
                case (#auction_bid(details)) {
                  if (
                    Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 1 * 10 ** 8 and details.sale_id == current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                  ) {
                    "correct response";
                  } else {
                    "details didnt match" # debug_show (details);
                  };
                };
                case (_) {
                  "bad transaction bid";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //MKT0027
        S.test(
          "transaction history has the bid ask",
          switch (a_history_1) {
            case (#ok(res)) {

              D.print("where ismy history");
              D.print(debug_show (a_history_1));
              if (res.size() > 0) {
                switch (res[res.size() -1].txn_type) {
                  case (#auction_bid(details)) {
                    if (
                      Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 1 * 10 ** 8 and details.sale_id == current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                    ) {
                      "correct response";
                    } else {
                      "details didnt match" # debug_show (details);
                    };
                  };
                  case (_) {
                    "bad history bid";
                  };
                };
              } else {
                "size was 0";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //TRX0005, MKT0033
        S.test(
          "min bid increased ask ",
          switch (a_sale_status_min_bid_increase) {
            case (#ok(res)) {

              switch (res.current_sale) {
                case (?current_sale) {
                  switch (NFTUtils.get_auction_state_from_statusStable(current_sale)) {
                    case (#err(err)) {
                      "unexpected error: " # err.flag_point;
                    };
                    case (#ok(res)) {
                      //let min_bid_increase =
                      if (res.min_next_bid == (1 * 10 ** 8) + 10 * 10 ** 8) {
                        "correct response";
                      } else {
                        "wrong bid " # debug_show (res.min_next_bid);
                      };
                    };
                  };

                };
                case (_) {
                  "bad info min bid";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //MKT0032
        S.test(
          "fail if bid is too low ask ",
          switch (b_wallet_try_bid_to_low) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4004) {
                //too low
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //todo: create user story for bid too low
        S.test(
          "transaction history has the new bid ask ",
          switch (b_history_1) {
            case (#ok(res)) {

              D.print("new bid history");
              D.print(debug_show (b_history_1));
              if (res.size() > 0) {
                switch (res[res.size() -1].txn_type) {
                  case (#auction_bid(details)) {
                    if (
                      Types.account_eq(details.buyer, #principal(Principal.fromActor(b_wallet))) and details.amount == new_bid_val and details.sale_id == current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                    ) {
                      "correct response";
                    } else {
                      "details didnt match for second bid " # debug_show (details);
                    };
                  };
                  case (_) {
                    "bad history bid for b " # debug_show (res);
                  };
                };
              } else {
                "size was zero for new bid";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //TRX0005, MKT0033
        S.test(
          "escrow balance is right amount for a before thrid bid",
          switch (a_balance_before_third) {
            case (#ok(res)) {
              D.print("testing third bid");
              D.print(debug_show (res));
              D.print(debug_show (#principal(Principal.fromActor(canister))));
              D.print(debug_show (#principal(Principal.fromActor(a_wallet))));
              D.print(debug_show (Principal.fromActor(dfx)));
              D.print(debug_show (Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(canister)))));
              D.print(debug_show (Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet)))));
              D.print(debug_show (res.escrow[0].token_id == "1"));
              D.print(debug_show (Types.token_eq(res.escrow[0].token, #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))));
              D.print(debug_show (res.escrow[0].amount == 104 * 10 ** 8, res.escrow[0].amount, 104 * 10 ** 8));
              if (
                Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(this))) and Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet))) and res.escrow[0].token_id == "1" and Types.token_eq(res.escrow[0].token, #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })) and res.escrow[0].amount == 103 * 10 ** 8
              ) {
                "found escrow record";
              } else {
                D.print(debug_show (res));
                "didnt find record ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found escrow record")),
        ), //todo: MKT0037
        S.test(
          "auction winner is the new owner",
          switch (a_sale_status_over_new_owner) {
            case (#ok(res)) {

              let new_owner = switch (
                Metadata.get_nft_owner(
                  switch (a_sale_status_over_new_owner) {
                    case (#ok(item)) {
                      item.metadata;
                    };
                    case (#err(err)) {
                      #Option(null);
                    };
                  }
                )
              ) {
                case (#err(err)) {
                  #account_id("wrong");
                };
                case (#ok(val)) {
                  val;
                };
              };
              D.print("new owner");
              D.print(debug_show (new_owner));
              D.print(debug_show (Principal.fromActor(a_wallet)));
              if (Types.account_eq(new_owner, #principal(Principal.fromActor(a_wallet)))) {
                "found correct owner";
              } else {
                D.print(debug_show (res));
                "didnt find record ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found correct owner")),
        ), //MKT0029
        S.test(
          "current sale status is ended",
          switch (a_sale_status_over_new_owner) {
            case (#ok(res)) {
              D.print("a_sale_status_over_new_owner");
              D.print(debug_show (a_sale_status_over_new_owner));
              //MKT0036 sale should be over and there should be a record with status #ended
              switch (a_sale_status_over_new_owner) {
                case (#ok(res)) {

                  switch (res.current_sale) {
                    case (null) {
                      "current sale improperly removed";
                    };
                    case (?val) {
                      switch (val.sale_type) {
                        case (#auction(state)) {
                          D.print("state");
                          D.print(debug_show (state));
                          let current_status = switch (state.status) {
                            case (#closed) { true };
                            case (_) { false };
                          };
                          if (
                            current_status == true and val.sale_id == current_sales_id
                          ) {
                            "found closed sale";
                          } else {
                            "didnt find closed sale";
                          };

                        };

                      };
                    };
                  };

                };
                case (#err(err)) {
                  "error getting";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found closed sale")),
        ), // MKT0036

        S.test(
          "transaction history have the transfer - auction 4699",
          switch (a_history_3) {
            case (#ok(res)) {

              if (res.size() > 1) {
                switch (res[res.size() - 2].txn_type) {
                  case (#sale_ended(details)) {
                    if (
                      Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 101 * 10 ** 8 and details.sale_id == ?current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                    ) {
                      "correct response";
                    } else {
                      "details didnt match" # debug_show (details);
                    };
                  };
                  case (_) {
                    "bad history sale " # debug_show (a_history_3);
                  };
                };
              } else {
                "size was les than one";
              };

            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //todo: make a user story for adding a #sale_ended to the end of transaction log
        S.test(
          "fail if ended before corect date  ask",
          switch (end_before) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4007) {
                //sale not over
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //todo: create user story for sale not over
        S.test(
          "transaction history have the transfer - ask 2",
          switch (end_proper) {
            case (#ok(#end_sale(res))) {
              D.print("transaction history have the transfer 2");
              D.print(debug_show (res));
              switch (res.txn_type) {
                case (#sale_ended(details)) {
                  if (
                    Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 101 * 10 ** 8 and Option.get(details.sale_id, "") == current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                  ) {
                    "correct response";
                  } else {
                    "details didnt match" # debug_show (details);
                  };
                };
                case (_) {
                  "bad history sale";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
            case (_) { "unexpected error: " };
          },
          M.equals<Text>(T.text("correct response")),
        ), //todo: make a user story for adding a #sale_ended to the end of transaction log
        S.test(
          "fail if auction already over ",
          switch (end_again) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4006) {
                //new owner so unauthorized
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //todo: create user story for sale over
        S.test(
          "fail if escrow amount over deposited amount",
          switch (b_withdraw_over) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //escrow no longer found since it was refunded
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-101
        S.test(
          "fail if escrow amount is the wrong token",
          switch (b_withdraw_bad_token) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //shouldn't be able to find escrow
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //t NFT-103
        S.test(
          "fail if escrow amount is the wrong seller",
          switch (b_withdraw_bad_seller) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //shouldn't be able to find escrow
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //t NFT-104
        S.test(
          "fail if escrow amount is the wrong buyer",
          switch (b_withdraw_bad_buyer) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 2000) {
                //unauthorized
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-102
        S.test(
          "fail if escrow amount is the wrong token_id",
          switch (b_withdraw_bad_token_id) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //token id not found
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-105
        S.test(
          "fail if escrow removed twice",
          switch (b_withdraw_bad_token_id) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //withdraw too large because 0 and not found
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-106
        S.test(
          "fail if escrow is for the current winning bid",
          switch (a_withdraw_during_bid) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3008) {
                //cannot be removed
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-76

        S.test(
          "fail if escrow is for the winning bid a withdraw",
          switch (a_withdraw_during_win) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000 or err.number == 3007) {
                //wont be able to find it because it has been zeroed out.
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-110
        S.test(
          "fail if escrow is for the winning bid b withdraw",
          switch (b_withdraw) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //wont be able to find it because it has been zeroed out.
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-18, NFT-101 - These were negated by NFT-120
        //todo: test needs to be re written to cycle through history and find the escrow
        /* S.test("escrow withdraw in transaction record", switch(b_history_withdraw){case(#ok(res)){
                D.print("b_history_withdraw");
                D.print(debug_show(b_history_withdraw));
                switch(res[res.size()-1].txn_type){
                    case(#escrow_withdraw(details)){
                        if(Types.account_eq(details.buyer, #principal(Principal.fromActor(b_wallet))) and
                                Types.account_eq(details.seller, #principal(Principal.fromActor(this))) and
                                details.amount == ((11*10**8) - dip20_fee) and
                                details.token_id == "1" and
                                Types.token_eq(details.token, #ic({
                                    canister = (Principal.fromActor(dfx));
                                    standard =  #Ledger;
                                    decimals = 8;
                                    symbol = "LDG";
                                    fee = ?200000;
                                    id = null;}))){
                                    "correct response";
                            } else {
                                "details didnt match" # debug_show(details);
                            };
                    };
                    case(_){
                        D.print("Bad history sale");
                        D.print(debug_show(res));
                        "bad history sale";
                    };
                };
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //NFT-107
            */
        S.test(
          "sales balance after sale has balance in it",
          switch (owner_balance_after_sale) {
            case (#ok(res)) {
              D.print("testing sale balance 1");
              D.print(debug_show (res));

              if (res.sales.size() == 0) {

                "found no sales record";
              } else {

                D.print(debug_show (res));
                "found record ";
              };
            };
            case (#err(err)) { "unexpected error: " # err.flag_point };
          },
          M.equals<Text>(T.text("found no sales record")),
        ), //todo: NFT-113
        S.test(
          "fail if withdraw over sale amount",
          switch (owner_withdraw_over) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //can't find it
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-114
        S.test(
          "fail if withdraw from wrong account",
          switch (a_withdraw_attempt_sale) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 2000) {
                //unauthorized access
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-115
        S.test(
          "fail if withdraw from wrong asset",
          switch (owner_withdraw_wrong_asset) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //cant find sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-116
        S.test(
          "fail if withdraw from wrong token id",
          switch (owner_withdraw_wrong_token_id) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //cant find sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-117
        S.test(
          "fail if withdraw a second time",
          switch (owner_withdraw_again) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //cant find sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-117
        S.test("sale withdraw works", owner_withdraw_proper, M.equals<Nat>(T.nat(initialOwnerBalance + 10099600000))), //NFT-18, NFT-101
        S.test(
          "sales balance after withdraw has no balance in it",
          switch (owner_balance_after_withdraw) {
            case (#ok(res)) {
              D.print("testing sale balance 2");
              D.print(debug_show (res));

              if (res.sales.size() == 0) {
                "found empty record";
              } else {
                D.print(debug_show (res));
                "found a record ";
              };
            };
            case (#err(err)) { "unexpected error: " # err.flag_point };
          },
          M.equals<Text>(T.text("found empty record")),
        ), //todo: NFT-118
        S.test(
          "sale withdraw in history",
          switch (owner_history_withdraw) {
            case (#ok(res)) {
              D.print("sales withdraw history");
              D.print(debug_show (res));
              switch (res[res.size() -1].txn_type) {
                case (#sale_withdraw(details)) {
                  D.print(debug_show (details));
                  if (
                    Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and
                    Types.account_eq(details.seller, #principal(Principal.fromActor(this))) and
                    details.amount == (Nat.sub(((101 * 10 ** 8) -200000), dip20_fee)) and
                    details.token_id == "1" and
                    Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                  ) {
                    "correct response";
                  } else {
                    "details didnt match" # debug_show (details);
                  };
                };
                case (_) {
                  D.print(debug_show (res[res.size() -1]));
                  "bad history withdraw";
                };
              };
            };
            case (#err(err)) { "unexpected error: " # err.flag_point };
          },
          M.equals<Text>(T.text("correct response")),
        ), //NFT-19
        S.test(
          "nft balance after sale",
          switch (a_balance_after_close) {
            case (#ok(res)) {
              D.print("testing nft balance");
              D.print(debug_show (res));

              if (res.nfts.size() == 0) {
                "found empty record";
              } else {
                D.print(debug_show (res));
                if (res.nfts[res.nfts.size() -1] == "1") {
                  "found a record";
                } else {
                  "didnt find record";
                };

              };
            };
            case (#err(err)) { "unexpected error: " # err.flag_point };
          },
          M.equals<Text>(T.text("found a record")),
        ), //todo: NFT-94

        S.test(
          "sale info has active and only active sale in it",
          switch (active_sale_info_1) {
            case (#ok(#active(val))) {
              if (val.records.size() == 1 and val.records[0].0 == "1") {
                "correct response";
              } else {
                "bad response" # debug_show (active_sale_info_1);
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_1);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "sale info has one active sale after close of first",
          switch (active_sale_info_2) {
            case (#ok(#active(val))) {
              if (val.records.size() == 1 and val.records[0].0 == "2") {
                "correct response";
              } else {
                "bad response" # debug_show (active_sale_info_2);
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_2);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "sale is included in history",
          switch (history_sale_info_2) {
            case (#ok(#history(val))) {
              if (val.records.size() == 2) {
                switch (val.records[0]) {
                  case (null) { "shouldnt be null" };
                  case (?val) {
                    if (val.sale_id == current_sales_id) {
                      "correct response";
                    } else {
                      "wrong sale id " # debug_show (val);
                    };
                  };
                };
              } else {
                "bad response" # debug_show (history_sale_info_2);
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (history_sale_info_2);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "sale info has no active sale after cancel",
          switch (active_sale_info_3) {
            case (#ok(#active(val))) {
              if (val.records.size() == 0) {
                "correct response";
              } else {
                "bad response" # debug_show (active_sale_info_3);
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_3);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test("a was notified of sale", notifications.size(), M.equals<Nat>(T.nat(1))),
      ],
    );

    D.print("suite running");

    S.run(suite);

    D.print("suite over");

    return #success;

  };

  public shared func testAuction_v3() : async { #success; #fail : Text } {
    D.print("running Auction v3");

    let dfx : DFXTypes.Service = actor (Principal.toText(dfx_ledger));

    let dfx2 : DFXTypes.Service = actor (Principal.toText(dfx_ledger2));

    let a_wallet = await TestWalletDef.test_wallet();
    let b_wallet = await TestWalletDef.test_wallet();

    let funding_result_a = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    let funding_result_b = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    let funding_result_b2 = await dfx2.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    D.print("funding result b2 " # debug_show (funding_result_b2));

    let newPrincipal = await g_canister_factory.create({
      owner = Principal.fromActor(this);
      storage_space = null;
    });

    let initialOwnerBalance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(this);
      subaccount = null;
    });

    D.print("initialOwnerBalance = " # debug_show (initialOwnerBalance));

    let canister : Types.Service = actor (Principal.toText(newPrincipal));

    let mode = canister.__set_time_mode(#test);
    let atime = canister.__advance_time(Time.now());

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning a minted item
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning an unminted item

    D.print("Minting");
    let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(this))); //mint to the test account
    let mint_attempt2 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this))); //mint to the test account

    D.print("start auction fail " # debug_show ((mint_attempt, mint_attempt2)));
    //non owner start auction should fail MKT0019
    let start_auction_attempt_fail = await a_wallet.try_start_ask(Principal.fromActor(canister), Principal.fromActor(dfx), "1", null);

    D.print("start auction owner");
    let option_buffer = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(100 * 10 ** 8),
      #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),
      #buy_now(500 * 10 ** 8),
      #start_price(1 * 10 ** 8),
      #ending(#date(get_time() + DAY_LENGTH)),
      #min_increase(#amount(10 * 10 ** 8)),
      #notify([
        Principal.fromActor(a_wallet),
        Principal.fromActor(b_wallet),
      ]),
    ]);
    //start an auction by owner
    let start_auction_attempt_owner = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer));
      };
    });

    D.print("get sale id " # debug_show (start_auction_attempt_owner));
    let current_sales_id = switch (start_auction_attempt_owner) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };

      };
      case (#err(item)) {
        D.print("error with auction start");
        return #fail("error with auction start");
      };
    };

    let active_sale_info_1 = await canister.sale_info_nft_origyn(#active(null));

    D.print("active_sale_info_1" # debug_show (active_sale_info_1));

    //force a round?

    let aRandom = await TestWalletDef.test_wallet();

    let aRandom2 = await TestWalletDef.test_wallet();
    let aRandom3 = await TestWalletDef.test_wallet();
    let aRandom4 = await TestWalletDef.test_wallet();

    //lets make sure that we were notified
    let notifications = await a_wallet.get_notifications();

    D.print("found notifications" # debug_show (notifications));

    //claiming first escrow
    let a_wallet_try_escrow_general_staged = await a_wallet.send_ledger_escrow(
      Principal.fromActor(dfx),
      {
        token = #ic({
          canister = Principal.fromActor(dfx);
          standard = #Ledger;
          decimals = 8;
          symbol = "LDG";
          fee = ?200000;
          id = null;
        });
        seller = #principal(Principal.fromActor(this));
        buyer = #principal(Principal.fromActor(a_wallet));
        token_id = "1";
        amount = 1 * 10 ** 8;
      },
      Principal.fromActor(canister),
    );

    //try starting again//should fail MKT0018
    let end_date = get_time() + DAY_LENGTH;
    D.print("end date is ");
    D.print(debug_show (end_date));

    let a_balance_before_valid_bid4 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    D.print("a_balance_before_valid_bid4 v3 " # debug_show (a_balance_before_valid_bid4));

    //place a valid bid MKT0027
    let a_wallet_try_bid_valid = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1 * 10 ** 8, "1", current_sales_id, null, null);
    D.print("a_wallet_try_bid_valid " # debug_show (a_wallet_try_bid_valid));

    let a_balance_after_bad_bid4 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    D.print("a balance 4 " # debug_show (a_balance_after_bad_bid4));

    //check transaction log for bid MKT0033, TRX0005
    let a_history_1 = await canister.history_nft_origyn("1", null, null); //gets all history

    D.print("history1" # debug_show (a_history_1));

    //make sure next min bid is bid + minimum increase MKT0032
    let a_sale_status_min_bid_increase = await canister.nft_origyn("1");

    D.print("withdraw during bid");
    //todo: attempt to withdraw escrow for active bid should fail ESC0016 NFT-76
    let a_withdraw_during_bid = await a_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", 1 * 10 ** 8, null);

    D.print("passed this");
    //place escrow b
    let new_bid_val = switch (a_sale_status_min_bid_increase) {
      case (#ok(res)) {

        switch (res.current_sale) {
          case (?current_sale) {
            switch (NFTUtils.get_auction_state_from_statusStable(current_sale)) {
              case (#err(err)) {
                return #fail("cannot get min bid to make second bid");
              };
              case (#ok(res)) {
                res.min_next_bid;
              };
            };
          };
          case (null) {
            return #fail("no sale found for finding min bid for second bid");
          };
        };
      };
      case (#err(err)) {
        return #fail("cannot get min bid to make second bid");
      };
    };

    //deposit escrow for two upcoming bids
    D.print("sending tokens to canisters for b");
    let b_wallet_send_tokens_to_canister_correct_ledger = await b_wallet.send_ledger_escrow(
      Principal.fromActor(dfx),
      {
        token = #ic({
          canister = Principal.fromActor(dfx);
          standard = #Ledger;
          decimals = 8;
          symbol = "LDG";
          fee = ?200000;
          id = null;
        });
        seller = #principal(Principal.fromActor(this));
        buyer = #principal(Principal.fromActor(b_wallet));
        token_id = "1";
        amount = (new_bid_val);
      },
      Principal.fromActor(canister),
    );

    D.print("Sending escrow for correct currency escrow now");

    //place a second bid
    let b_wallet_try_bid_valid = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), new_bid_val, "1", current_sales_id, null, null);

    D.print("did b bid work? ");
    D.print(debug_show (b_wallet_try_bid_valid));

    let b_balance_after_bid = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet))); //gets all history

    D.print("found balance after bid ");
    D.print(debug_show (b_balance_after_bid));

    //check transaction log for bid MKT0033, TRX0005
    let b_history_1 = await canister.history_nft_origyn("1", null, null); //gets all history

    D.print("found balance after bid ");
    D.print(debug_show (b_history_1));

    //place more escrow a
    //make sure next min bid is bid + minimum increase MKT0032
    let b_sale_status_min_bid_increase = await canister.nft_origyn("1");

    let new_bid_val_b = switch (b_sale_status_min_bid_increase) {
      case (#ok(res)) {

        switch (res.current_sale) {
          case (?current_sale) {
            switch (NFTUtils.get_auction_state_from_statusStable(current_sale)) {
              case (#err(err)) {
                return #fail("cannot get min bid to make third bid");
              };
              case (#ok(res)) {
                res.min_next_bid;
              };
            };
          };
          case (null) {
            return #fail("no sale found for finding min bid for third bid");
          };
        };
      };
      case (#err(err)) {
        return #fail("cannot get min bid to make third bid");
      };
    };

    let a_balance_before_third_escrow = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    D.print("the balance before third escrow is");
    D.print(debug_show (a_balance_before_third_escrow));

    let a_wallet_send_tokens_to_canister2 = await a_wallet.send_ledger_escrow(
      Principal.fromActor(dfx),
      {
        token = #ic({
          canister = Principal.fromActor(dfx);
          standard = #Ledger;
          decimals = 8;
          symbol = "LDG";
          fee = ?200000;
          id = null;
        });
        seller = #principal(Principal.fromActor(this));
        buyer = #principal(Principal.fromActor(a_wallet));
        token_id = "1";
        amount = (101 * 10 ** 8);
      },
      Principal.fromActor(canister),
    );

    let block3 = switch (a_wallet_send_tokens_to_canister2) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    D.print("Sending real escrow now 3"); //escrow is for 100. There should already be 1 in the escrow account. we are going to bid 101 above reserve

    //todo check escrow balance
    //check balance and make sure we see the escrow BAL0002
    let a_balance_before_third = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    D.print("the balance before third is");
    D.print(debug_show (a_balance_before_third));

    //place a third bid
    let a_wallet_try_bid_valid_3 = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 101 * 10 ** 8, "1", current_sales_id, null, null);
    D.print("valid 3");
    D.print(debug_show (a_wallet_try_bid_valid_3));

    //force a round?

    let aRandom5 = await TestWalletDef.test_wallet();

    let aRandom6 = await TestWalletDef.test_wallet();
    let aRandom7 = await TestWalletDef.test_wallet();
    let aRandom8 = await TestWalletDef.test_wallet();

    //try to end auction before it is time should fail
    D.print("end before");

    let end_before = try {
      await canister.sale_nft_origyn(#end_sale("1"));
    } catch (e) {
      D.print(Error.message(e));
      D.trap(Error.message(e));
    };

    D.print(debug_show (end_before));
    D.print("end before");

    //advance time
    let time_result = await canister.__advance_time(end_date + 1);
    D.print("new time");
    D.print(debug_show (time_result));

    let aRandom9 = await TestWalletDef.test_wallet();

    let aRandom10 = await TestWalletDef.test_wallet();
    let aRandom11 = await TestWalletDef.test_wallet();
    let aRandom12 = await TestWalletDef.test_wallet();

    //end auction
    let end_proper = await canister.sale_nft_origyn(#end_sale("1"));
    D.print("end proper");
    D.print(debug_show (end_proper));

    //end again, should fail
    let end_again = await canister.sale_nft_origyn(#end_sale("1"));
    D.print("end again");
    D.print(debug_show (end_again));

    //try to withdraw winning bid NFT-110
    let a_withdraw_during_win = await a_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", 101 * 10 ** 8, null);

    //NFT-94 check ownership
    //check balance and make sure we see the nft
    let a_balance_after_close = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    // //MKT0029, MKT0036
    let a_sale_status_over_new_owner = await canister.nft_origyn("1");

    // //check transaction log

    //check transaction log for sale
    let a_history_3 = await canister.history_nft_origyn("1", null, null); //gets all history

    // //a tries to start a new sale

    // //item is replaced in the current sale
    let b_balance_before_withdraw = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet))); //gets all history

    D.print("found balance before escrow withdraw");
    D.print(debug_show (b_balance_before_withdraw));
    //b tries to withdraw more than in account NFT-99

    let b_withdraw_over = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", 101 * 10 ** 8, null);

    // //b tries to withdraw for other buyer NFT-102

    let b_withdraw_bad_buyer = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);

    // //b tries to withdraw for other seller NFT-104

    let b_withdraw_bad_seller = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(a_wallet), "1", new_bid_val, null);

    // //b tries to withdraw for other tokenid NFT-105

    let b_withdraw_bad_token_id = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(a_wallet), "32", new_bid_val, null);

    // //b tries to withdraw for other token NFT-103

    let b_withdraw_bad_token = await b_wallet.try_escrow_withdraw(
      Principal.fromActor(canister),
      Principal.fromActor(b_wallet),
      Principal.fromActor(dfx),
      Principal.fromActor(a_wallet),
      "1",
      new_bid_val,
      ? #ic {
        canister = Principal.fromActor(dfx2);
        standard = #Ledger;
        decimals = 8;
        symbol = "LGY";
        fee = ?200000;
        id = null;
      },
    );

    // //b escrow should be auto refunded - need to test

    let b_withdraw = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);

    D.print("this withdraw should not work");
    D.print(debug_show (b_withdraw));
    //b withdraws escrow again NFT-106

    let b_withdraw_again = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);
    D.print("this withdraw should not work again");
    D.print(debug_show (b_withdraw_again));

    //check transaction log for sale
    let b_history_withdraw = await canister.history_nft_origyn("1", null, null); //gets all history

    //attempt to withdraw the sale revenue for the seller(this canister)

    //NFT-113
    //get balanance and make sure the sale is in the balance
    let owner_balance_after_sale = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(this)));
    D.print("owner_balance_after_sale" # debug_show (owner_balance_after_sale));

    D.print("withdraw over for owner");
    //NFT-114
    //try to withdraw too much
    let owner_withdraw_over = await canister.sale_nft_origyn(#withdraw(#sale({ withdraw_to = #principal(Principal.fromActor(this)); token_id = "1"; token = #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }); seller = #principal(Principal.fromActor(this)); buyer = #principal(Principal.fromActor(a_wallet)); amount = (101 * 10 ** 8) + 15 })));

    // //NFT-115
    // //have a_wallet try to withdraw the sale
    let a_withdraw_attempt_sale = await a_wallet.try_sale_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);

    //NFT-116
    //try to withdare the wrong asset
    D.print("owner_withdraw_wrong_asset");
    let owner_withdraw_wrong_asset = await canister.sale_nft_origyn(#withdraw(#sale({ withdraw_to = #principal(Principal.fromActor(this)); token_id = "1"; token = #ic({ canister = Principal.fromActor(dfx2); standard = #Ledger; decimals = 8; symbol = "LGY"; fee = ?200000; id = null }); seller = #principal(Principal.fromActor(this)); buyer = #principal(Principal.fromActor(a_wallet)); amount = 101 * 10 ** 8 })));

    //NFT-117
    //todo: try to withdraw the wrong token_id
    D.print("owner_withdraw_wrong_token_id");
    let owner_withdraw_wrong_token_id = await canister.sale_nft_origyn(#withdraw(#sale({ withdraw_to = #principal(Principal.fromActor(this)); token_id = "2"; token = #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }); seller = #principal(Principal.fromActor(this)); buyer = #principal(Principal.fromActor(a_wallet)); amount = 101 * 10 ** 8 })));

    //NFT-19
    //todo: withdraw the proper amount
    D.print("withdrawing proper amount from sale");
    let owner_withdraw_proper_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(this)));

    D.print("Proper amount result balance");
    D.print(debug_show (owner_withdraw_proper_balance));

    let owner_withdraw_proper = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(this);
      subaccount = null;
    });

    D.print("Proper amount result");
    D.print(debug_show (owner_withdraw_proper));

    //NFT-118
    //todo: try to withdraw again
    D.print("trying to withdraw sale again");
    let owner_withdraw_again = await canister.sale_nft_origyn(#withdraw(#sale({ withdraw_to = #principal(Principal.fromActor(this)); token_id = "1"; token = #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }); seller = #principal(Principal.fromActor(this)); buyer = #principal(Principal.fromActor(a_wallet)); amount = 101 * 10 ** 8 })));

    // //NFT-118
    // //todo: check balance and make sure it is gone
    let owner_balance_after_withdraw = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(this)));

    //NFT-19
    //todo: check ledger and make sure transaction is there and it went to the right account
    //check transaction log for sale
    D.print("trying owner hisotry");
    let owner_history_withdraw = await canister.history_nft_origyn("1", null, null); //gets all history

    let active_sale_info_2 = await canister.sale_info_nft_origyn(#active(null));
    D.print("active_sale_info_2" # debug_show (active_sale_info_2));

    let history_sale_info_2 = await canister.sale_info_nft_origyn(#history(null));

    //try to cancel the sale created for 2

    let cancel_auction_with_no_bids = await canister.sale_nft_origyn(#end_sale("2"));

    let active_sale_info_3 = await canister.sale_info_nft_origyn(#active(null));

    let suite = S.suite(
      "test staged Nft ask",
      [

        S.test(
          "test mint attempt ask",
          switch (mint_attempt) {
            case (#ok(res)) {

              "correct response";

            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),
        S.test(
          "fail if non owner tries to start auction ask",
          switch (start_auction_attempt_fail) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 2000) {
                //unauthorized
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0019

        S.test(
          "bid is succesful ask ",
          switch (a_wallet_try_bid_valid) {
            case (#ok(res)) {
              D.print("as bid");
              D.print(debug_show (a_wallet_try_bid_valid));
              switch (res.txn_type) {
                case (#auction_bid(details)) {
                  if (
                    Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 1 * 10 ** 8 and details.sale_id == current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                  ) {
                    "correct response";
                  } else {
                    "details didnt match" # debug_show (details);
                  };
                };
                case (_) {
                  "bad transaction bid";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //MKT0027
        S.test(
          "transaction history has the bid ask",
          switch (a_history_1) {
            case (#ok(res)) {

              D.print("where ismy history");
              D.print(debug_show (a_history_1));
              if (res.size() > 0) {
                switch (res[res.size() -1].txn_type) {
                  case (#auction_bid(details)) {
                    if (
                      Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 1 * 10 ** 8 and details.sale_id == current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                    ) {
                      "correct response";
                    } else {
                      "details didnt match" # debug_show (details);
                    };
                  };
                  case (_) {
                    "bad history bid";
                  };
                };
              } else {
                "size was 0";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //TRX0005, MKT0033
        S.test(
          "min bid increased ask ",
          switch (a_sale_status_min_bid_increase) {
            case (#ok(res)) {

              switch (res.current_sale) {
                case (?current_sale) {
                  switch (NFTUtils.get_auction_state_from_statusStable(current_sale)) {
                    case (#err(err)) {
                      "unexpected error: " # err.flag_point;
                    };
                    case (#ok(res)) {
                      //let min_bid_increase =
                      if (res.min_next_bid == (1 * 10 ** 8) + 10 * 10 ** 8) {
                        "correct response";
                      } else {
                        "wrong bid " # debug_show (res.min_next_bid);
                      };
                    };
                  };

                };
                case (_) {
                  "bad info min bid";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //MKT0032

        S.test(
          "transaction history has the new bid ask ",
          switch (b_history_1) {
            case (#ok(res)) {

              D.print("new bid history");
              D.print(debug_show (b_history_1));
              if (res.size() > 0) {
                switch (res[res.size() - 2].txn_type) {
                  case (#auction_bid(details)) {
                    if (
                      Types.account_eq(details.buyer, #principal(Principal.fromActor(b_wallet))) and details.amount == new_bid_val and details.sale_id == current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                    ) {
                      "correct response";
                    } else {
                      "details didnt match for second bid " # debug_show (details);
                    };
                  };
                  case (_) {
                    "bad history bid for b " # debug_show (res);
                  };
                };
              } else {
                "size was zero for new bid";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //TRX0005, MKT0033

        S.test(
          "auction winner is the new owner",
          switch (a_sale_status_over_new_owner) {
            case (#ok(res)) {

              let new_owner = switch (
                Metadata.get_nft_owner(
                  switch (a_sale_status_over_new_owner) {
                    case (#ok(item)) {
                      item.metadata;
                    };
                    case (#err(err)) {
                      #Option(null);
                    };
                  }
                )
              ) {
                case (#err(err)) {
                  #account_id("wrong");
                };
                case (#ok(val)) {
                  val;
                };
              };
              D.print("new owner");
              D.print(debug_show (new_owner));
              D.print(debug_show (Principal.fromActor(a_wallet)));
              if (Types.account_eq(new_owner, #principal(Principal.fromActor(a_wallet)))) {
                "found correct owner";
              } else {
                D.print(debug_show (res));
                "didnt find record ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found correct owner")),
        ), //MKT0029
        S.test(
          "current sale status is ended",
          switch (a_sale_status_over_new_owner) {
            case (#ok(res)) {
              D.print("a_sale_status_over_new_owner");
              D.print(debug_show (a_sale_status_over_new_owner));
              //MKT0036 sale should be over and there should be a record with status #ended
              switch (a_sale_status_over_new_owner) {
                case (#ok(res)) {

                  switch (res.current_sale) {
                    case (null) {
                      "current sale improperly removed";
                    };
                    case (?val) {
                      switch (val.sale_type) {
                        case (#auction(state)) {
                          D.print("state");
                          D.print(debug_show (state));
                          let current_status = switch (state.status) {
                            case (#closed) { true };
                            case (_) { false };
                          };
                          if (
                            current_status == true and val.sale_id == current_sales_id
                          ) {
                            "found closed sale";
                          } else {
                            "didnt find closed sale";
                          };

                        };

                      };
                    };
                  };

                };
                case (#err(err)) {
                  "error getting";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found closed sale")),
        ), // MKT0036

        S.test(
          "transaction history have the transfer - auction 4699",
          switch (a_history_3) {
            case (#ok(res)) {

              if (res.size() > 1) {
                switch (res[res.size() - 2].txn_type) {
                  case (#sale_ended(details)) {
                    if (
                      Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 101 * 10 ** 8 and details.sale_id == ?current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                    ) {
                      "correct response";
                    } else {
                      "details didnt match" # debug_show (details);
                    };
                  };
                  case (_) {
                    "bad history sale " # debug_show (a_history_3);
                  };
                };
              } else {
                "size was les than one";
              };

            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //todo: make a user story for adding a #sale_ended to the end of transaction log
        S.test(
          "fail if ended before corect date  ask",
          switch (end_before) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4007) {
                //sale not over
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //todo: create user story for sale not over
        S.test(
          "transaction history have the transfer - ask 2",
          switch (end_proper) {
            case (#ok(#end_sale(res))) {
              D.print("transaction history have the transfer 2");
              D.print(debug_show (res));
              switch (res.txn_type) {
                case (#sale_ended(details)) {
                  if (
                    Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 101 * 10 ** 8 and Option.get(details.sale_id, "") == current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                  ) {
                    "correct response";
                  } else {
                    "details didnt match" # debug_show (details);
                  };
                };
                case (_) {
                  "bad history sale";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
            case (_) { "unexpected error: " };
          },
          M.equals<Text>(T.text("correct response")),
        ), //todo: make a user story for adding a #sale_ended to the end of transaction log
        S.test(
          "fail if auction already over ",
          switch (end_again) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4006) {
                //new owner so unauthorized
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //todo: create user story for sale over
        S.test(
          "fail if escrow amount over deposited amount",
          switch (b_withdraw_over) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //escrow no longer found since it was refunded
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-101
        S.test(
          "fail if escrow amount is the wrong token",
          switch (b_withdraw_bad_token) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //shouldn't be able to find escrow
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //t NFT-103
        S.test(
          "fail if escrow amount is the wrong seller",
          switch (b_withdraw_bad_seller) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //shouldn't be able to find escrow
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //t NFT-104
        S.test(
          "fail if escrow amount is the wrong buyer",
          switch (b_withdraw_bad_buyer) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 2000) {
                //unauthorized
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-102
        S.test(
          "fail if escrow amount is the wrong token_id",
          switch (b_withdraw_bad_token_id) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //token id not found
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-105
        S.test(
          "fail if escrow removed twice",
          switch (b_withdraw_bad_token_id) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //withdraw too large because 0 and not found
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-106
        S.test(
          "fail if escrow is for the current winning bid",
          switch (a_withdraw_during_bid) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3008) {
                //cannot be removed
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-76

        S.test(
          "fail if escrow is for the winning bid a withdraw",
          switch (a_withdraw_during_win) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000 or err.number == 3007) {
                //wont be able to find it because it has been zeroed out.
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-110
        S.test(
          "fail if escrow is for the winning bid b withdraw",
          switch (b_withdraw) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //wont be able to find it because it has been zeroed out.
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-18, NFT-101 - These were negated by NFT-120
        //todo: test needs to be re written to cycle through history and find the escrow
        /* S.test("escrow withdraw in transaction record", switch(b_history_withdraw){case(#ok(res)){
                D.print("b_history_withdraw");
                D.print(debug_show(b_history_withdraw));
                switch(res[res.size()-1].txn_type){
                    case(#escrow_withdraw(details)){
                        if(Types.account_eq(details.buyer, #principal(Principal.fromActor(b_wallet))) and
                                Types.account_eq(details.seller, #principal(Principal.fromActor(this))) and
                                details.amount == ((11*10**8) - dip20_fee) and
                                details.token_id == "1" and
                                Types.token_eq(details.token, #ic({
                                    canister = (Principal.fromActor(dfx));
                                    standard =  #Ledger;
                                    decimals = 8;
                                    symbol = "LDG";
                                    fee = ?200000;
                                    id = null;}))){
                                    "correct response";
                            } else {
                                "details didnt match" # debug_show(details);
                            };
                    };
                    case(_){
                        D.print("Bad history sale");
                        D.print(debug_show(res));
                        "bad history sale";
                    };
                };
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //NFT-107
            */
        S.test(
          "sales balance after sale has balance in it",
          switch (owner_balance_after_sale) {
            case (#ok(res)) {
              D.print("testing sale balance 1");
              D.print(debug_show (res));

              if (res.sales.size() == 0) {

                "found no sales record";
              } else {

                D.print(debug_show (res));
                "found record ";
              };
            };
            case (#err(err)) { "unexpected error: " # err.flag_point };
          },
          M.equals<Text>(T.text("found no sales record")),
        ), //todo: NFT-113
        S.test(
          "fail if withdraw over sale amount",
          switch (owner_withdraw_over) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //can't find it
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-114
        S.test(
          "fail if withdraw from wrong account",
          switch (a_withdraw_attempt_sale) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 2000) {
                //unauthorized access
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-115
        S.test(
          "fail if withdraw from wrong asset",
          switch (owner_withdraw_wrong_asset) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //cant find sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-116
        S.test(
          "fail if withdraw from wrong token id",
          switch (owner_withdraw_wrong_token_id) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //cant find sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-117
        S.test(
          "fail if withdraw a second time",
          switch (owner_withdraw_again) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //cant find sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), // NFT-117
        S.test("sale withdraw works", owner_withdraw_proper, M.equals<Nat>(T.nat(initialOwnerBalance + 10099600000))), //NFT-18, NFT-101
        S.test(
          "sales balance after withdraw has no balance in it",
          switch (owner_balance_after_withdraw) {
            case (#ok(res)) {
              D.print("testing sale balance 2");
              D.print(debug_show (res));

              if (res.sales.size() == 0) {
                "found empty record";
              } else {
                D.print(debug_show (res));
                "found a record ";
              };
            };
            case (#err(err)) { "unexpected error: " # err.flag_point };
          },
          M.equals<Text>(T.text("found empty record")),
        ), //todo: NFT-118
        S.test(
          "sale withdraw in history",
          switch (owner_history_withdraw) {
            case (#ok(res)) {
              D.print("sales withdraw history");
              D.print(debug_show (res));
              switch (res[res.size() -1].txn_type) {
                case (#sale_withdraw(details)) {
                  D.print(debug_show (details));
                  if (
                    Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and
                    Types.account_eq(details.seller, #principal(Principal.fromActor(this))) and
                    details.amount == (Nat.sub(((101 * 10 ** 8) -200000), dip20_fee)) and
                    details.token_id == "1" and
                    Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                  ) {
                    "correct response";
                  } else {
                    "details didnt match" # debug_show (details);
                  };
                };
                case (_) {
                  D.print(debug_show (res[res.size() -1]));
                  "bad history withdraw";
                };
              };
            };
            case (#err(err)) { "unexpected error: " # err.flag_point };
          },
          M.equals<Text>(T.text("correct response")),
        ), //NFT-19
        S.test(
          "nft balance after sale",
          switch (a_balance_after_close) {
            case (#ok(res)) {
              D.print("testing nft balance");
              D.print(debug_show (res));

              if (res.nfts.size() == 0) {
                "found empty record";
              } else {
                D.print(debug_show (res));
                if (res.nfts[res.nfts.size() -1] == "1") {
                  "found a record";
                } else {
                  "didnt find record";
                };

              };
            };
            case (#err(err)) { "unexpected error: " # err.flag_point };
          },
          M.equals<Text>(T.text("found a record")),
        ), //todo: NFT-94

        S.test(
          "sale info has active and only active sale in it",
          switch (active_sale_info_1) {
            case (#ok(#active(val))) {
              if (val.records.size() == 1 and val.records[0].0 == "1") {
                "correct response";
              } else {
                "bad response" # debug_show (active_sale_info_1);
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_1);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "sale is included in history",
          switch (history_sale_info_2) {
            case (#ok(#history(val))) {
              D.print("the sale history");
              D.print(debug_show (val));
              if (val.records.size() == 1) {
                switch (val.records[0]) {
                  case (null) { "shouldnt be null" };
                  case (?val) {
                    if (val.sale_id == current_sales_id) {
                      "correct response";
                    } else {
                      "wrong sale id " # debug_show (val);
                    };
                  };
                };
              } else {
                "bad response" # debug_show (history_sale_info_2);
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (history_sale_info_2);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "sale info has no active sale after cancel",
          switch (active_sale_info_3) {
            case (#ok(#active(val))) {
              if (val.records.size() == 0) {
                "correct response";
              } else {
                "bad response" # debug_show (active_sale_info_3);
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_3);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test("a was notified of sale", notifications.size(), M.equals<Nat>(T.nat(1))),
      ],
    );

    D.print("suite running");

    S.run(suite);

    D.print("suite over");

    return #success;

  };

  public shared func testDutch() : async { #success; #fail : Text } {
    D.print("running Dutch");

    let dfx : DFXTypes.Service = actor (Principal.toText(dfx_ledger));

    let dfx2 : DFXTypes.Service = actor (Principal.toText(dfx_ledger2));

    let a_wallet = await TestWalletDef.test_wallet();
    D.print("A wallet canister is " # debug_show (Principal.fromActor(a_wallet)));
    let b_wallet = await TestWalletDef.test_wallet();

    let funding_result_a = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    let funding_result_b = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    let funding_result_b2 = await dfx2.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 1000 * 10 ** 8;
    });

    D.print("funding result b2 " # debug_show (funding_result_b2));

    let newPrincipal = await g_canister_factory.create({
      owner = Principal.fromActor(this);
      storage_space = null;
    });

    let initialOwnerBalance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(this);
      subaccount = null;
    });

    D.print("initialOwnerBalance = " # debug_show (initialOwnerBalance));

    let canister : Types.Service = actor (Principal.toText(newPrincipal));

    D.print("NFT Canister is " # debug_show (Principal.fromActor(canister)));

    let mode = canister.__set_time_mode(#test);
    let atime = canister.__advance_time(Time.now());
    let start_time = Time.now();

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning a minted item
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning an unminted item
    let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning an unminted item

    let standardStage4 = await utils.buildStandardNFT("4", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning an unminted item

    D.print("Minting");
    let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(this))); //mint to the test account
    let mint_attempt2 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this))); //mint to the test account
    let mint_attempt3 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this))); //mint to the test account

    let mint_attempt4 = await canister.mint_nft_origyn("4", #principal(Principal.fromActor(this))); //mint to the test account

    D.print("start auction fail " # debug_show ((mint_attempt, mint_attempt2)));
    //non owner start auction should fail MKT0019
    let start_auction_attempt_fail = await a_wallet.try_start_ask(Principal.fromActor(canister), Principal.fromActor(dfx), "1", null);

    D.print("start auction dutch");
    let option_buffer = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(20 * 10 ** 8),
      #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),
      #start_price(100 * 10 ** 8),
      #ending(#date(start_time + DAY_LENGTH)),
      #dutch({
        time_unit = #minute(1);
        decay_type = #flat(100000000);
      }),
    ]);

    let option_buffer_2 = Buffer.fromArray<MigrationTypes.Current.AskFeature>([
      #reserve(20 * 10 ** 8),
      #token(#ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })),
      #start_price(100 * 10 ** 8),
      #ending(#date(start_time + DAY_LENGTH)),
      #dutch({
        time_unit = #minute(1);
        decay_type = #percent(0.1);
      }),
    ]);

    let end_date = start_time + DAY_LENGTH;

    D.print("end_date " # debug_show (end_date));
    //start an auction by owner
    let start_auction_attempt_owner = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer));
      };
    });

    let start_auction_attempt_owner_2 = await canister.market_transfer_nft_origyn({
      token_id = "2";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer));
      };
    });

    let start_auction_attempt_owner_3 = await canister.market_transfer_nft_origyn({
      token_id = "3";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer));
      };
    });

    let start_auction_attempt_owner_4 = await canister.market_transfer_nft_origyn({
      token_id = "4";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer_2));
      };
    });

    D.print("get sale id " # debug_show (start_auction_attempt_owner));
    D.print("get sale id 2 " # debug_show (start_auction_attempt_owner_2));
    D.print("get sale id 3 " # debug_show (start_auction_attempt_owner_3));
    D.print("get sale id 4 " # debug_show (start_auction_attempt_owner_4));

    let current_sales_id = switch (start_auction_attempt_owner) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };

      };
      case (#err(item)) {
        D.print("error with auction start");
        return #fail("error with auction start");
      };
    };

    let current_sales_id_2 = switch (start_auction_attempt_owner_2) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };

      };
      case (#err(item)) {
        D.print("error with auction start");
        return #fail("error with auction start");
      };
    };

    let current_sales_id_3 = switch (start_auction_attempt_owner_3) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };

      };
      case (#err(item)) {
        D.print("error with auction start");
        return #fail("error with auction start");
      };
    };

    let current_sales_id_4 = switch (start_auction_attempt_owner_4) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };

      };
      case (#err(item)) {
        D.print("error with auction start");
        return #fail("error with auction start");
      };
    };

    let active_sale_info_1 = await canister.sale_info_nft_origyn(#active(null));

    D.print("active_sale_info_1" # debug_show (active_sale_info_1));

    let active_sale_info_by_id = await canister.sale_info_nft_origyn(#status(current_sales_id));

    D.print("starting again");
    //try starting again//should fail MKT0018
    let start_auction_attempt_owner_already_started = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(?Buffer.toArray<MigrationTypes.Current.AskFeature>(option_buffer));
      };
    });

    D.print(" already started result ");
    D.print(debug_show (start_auction_attempt_owner_already_started));

    //MKT0020 - try to transfer with an open auction
    let transfer_owner_after_auction = await canister.share_wallet_nft_origyn({
      token_id = "1";
      from = #principal(Principal.fromActor(this));
      to = #principal(Principal.fromActor(b_wallet));
    });

    D.print(" transfer_owner_after_auction ");
    D.print(debug_show (start_auction_attempt_owner_already_started));

    //place escrow
    D.print("sending tokens to canisters");
    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_escrow(
      Principal.fromActor(dfx),
      {
        token = #ic({
          canister = Principal.fromActor(dfx);
          standard = #Ledger;
          decimals = 8;
          symbol = "LDG";
          fee = ?200000;
          id = null;
        });
        seller = #principal(Principal.fromActor(this));
        buyer = #principal(Principal.fromActor(a_wallet));
        token_id = "1";
        amount = (100 * 10 ** 8);
      },
      Principal.fromActor(canister),
    );

    D.print(" a_wallet_send_tokens_to_canister ");
    D.print(debug_show (a_wallet_send_tokens_to_canister));

    let a_balance_before_bad_bid = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    D.print(" a_balance_before_bad_bid ");
    D.print(debug_show (a_balance_before_bad_bid));

    //balance should be 100 ICP + 800000

    let block = switch (a_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work" # debug_show (other));
        return #fail("ledger didnt work");
      };
    };

    D.print(" block ");
    D.print(debug_show (block));

    //place a bid below start price

    let a_wallet_try_bid_below_start = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 50 * 10 ** 7 + 200000, "1", current_sales_id, null, null);
    //aboves should refund the bid
    //todo: bid should be refunded

    D.print("the after low bid ");
    D.print(debug_show (a_wallet_try_bid_below_start));

    let a_balance_after_bad_bid = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    D.print("a balance " # debug_show (a_balance_after_bad_bid));

    D.print("Sending real escrow now 2");
    let a_wallet_try_escrow_general_staged2b = await a_wallet.send_ledger_escrow(
      Principal.fromActor(dfx),
      {
        token = #ic({
          canister = Principal.fromActor(dfx);
          standard = #Ledger;
          decimals = 8;
          symbol = "LDG";
          fee = ?200000;
          id = null;
        });
        seller = #principal(Principal.fromActor(this));
        buyer = #principal(Principal.fromActor(a_wallet));
        token_id = "1";
        amount = (101 * 10 ** 8);
      },
      Principal.fromActor(canister),
    );
    //this should clear out the deposit account

    D.print("Sending real escrow now result 2" # debug_show (a_wallet_try_escrow_general_staged2b));

    let a_balance_after_bad_bid3 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    D.print("a balance 3 " # debug_show (a_balance_after_bad_bid3));

    //place a valid bid MKT0027
    let a_wallet_try_bid_valid = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 100 * 10 ** 8, "1", current_sales_id, null, null);
    D.print("a_wallet_try_bid_valid " # debug_show (a_wallet_try_bid_valid));

    let a_balance_after_bad_bid4 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    D.print("a balance 4 " # debug_show (a_balance_after_bad_bid4));

    //check transaction log for bid MKT0033, TRX0005
    let a_history_1 = await canister.history_nft_origyn("1", null, null); //gets all history

    D.print("history1" # debug_show (a_history_1));

    let active_sale_info_2 = await canister.sale_info_nft_origyn(#active(null));

    D.print("active_sale_info_2" # debug_show (active_sale_info_2));

    //deposit escrow for two upcoming bids
    D.print("sending tokens to canisters for b");

    let b_wallet_send_tokens_to_canister = await b_wallet.send_ledger_escrow(
      Principal.fromActor(dfx),
      {
        token = #ic({
          canister = Principal.fromActor(dfx);
          standard = #Ledger;
          decimals = 8;
          symbol = "LDG";
          fee = ?200000;
          id = null;
        });
        seller = #principal(Principal.fromActor(this));
        buyer = #principal(Principal.fromActor(b_wallet));
        token_id = "2";
        amount = (90 * 10 ** 8);
      },
      Principal.fromActor(canister),
    );

    //advance the clock one minute and check the price
    let time_result = await canister.__advance_time(start_time + (60 * 10 ** 9));

    let active_sale_info_3 = await canister.sale_info_nft_origyn(#status(current_sales_id_2));
    let percent_sale_info_3 = await canister.sale_info_nft_origyn(#status(current_sales_id_4));

    D.print("active_sale_info_3 ");
    D.print(debug_show (active_sale_info_3));
    D.print(debug_show (percent_sale_info_3));

    let time_result_2_half = await canister.__advance_time(start_time + ((60 * 10 ** 9)) + (30 * 10 ** 9));

    let active_sale_info_half = await canister.sale_info_nft_origyn(#status(current_sales_id_2));
    let percent_sale_info_half = await canister.sale_info_nft_origyn(#status(current_sales_id_4));

    D.print("percent_sale_info_half ");
    D.print(debug_show (percent_sale_info_half));

    //advance the clock 9 more minutes and check the clock
    let time_result_2 = await canister.__advance_time(start_time + ((60 * 10 ** 9) * 10));

    let active_sale_info_4 = await canister.sale_info_nft_origyn(#status(current_sales_id_2));
    let percent_sale_info_4 = await canister.sale_info_nft_origyn(#status(current_sales_id_4));

    D.print("active_sale_info_4 ");
    D.print(debug_show (active_sale_info_4));
    D.print(debug_show (percent_sale_info_4));

    //place a low bid bid
    let b_wallet_try_bid_lower = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 9000000000, "2", current_sales_id_2, null, null);

    D.print("b_wallet_try_bid_lower ");
    D.print(debug_show (b_wallet_try_bid_lower));

    let b_balance_after_bid = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet))); //gets all history

    D.print("found balance after bid ");
    D.print(debug_show (b_balance_after_bid));

    //check transaction log for bid MKT0033, TRX0005
    let b_history_1 = await canister.history_nft_origyn("1", null, null); //gets all history

    D.print("found balance after bid ");
    D.print(debug_show (b_history_1));

    //advance time 90 minutes
    let time_result4 = await canister.__advance_time(start_time + ((60 * 10 ** 9) * 100));
    D.print("new time");
    D.print(debug_show (time_result4));

    //make sure only goes to reserve
    let active_sale_info_5 = await canister.sale_info_nft_origyn(#status(current_sales_id_3));
    let percent_sale_info_5 = await canister.sale_info_nft_origyn(#status(current_sales_id_4));

    D.print("active_sale_info_5 ");
    D.print(debug_show (active_sale_info_5));
    D.print(debug_show (percent_sale_info_5));

    //end auction

    let time_result5 = await canister.__advance_time(start_time + ((60 * 10 ** 9) * 300));
    D.print("new time");
    D.print(debug_show (time_result5));

    let end_proper = await canister.sale_nft_origyn(#end_sale("3"));
    D.print("end proper");
    D.print(debug_show (end_proper));

    //end again, should fail
    let end_again = await canister.sale_nft_origyn(#end_sale("3"));
    D.print("end again");
    D.print(debug_show (end_again));

    let active_sale_info_6 = await canister.sale_info_nft_origyn(#active(null));

    //NFT-94 check ownership
    //check owner of 3 is still canister
    let owner_after_close = await canister.bearer_nft_origyn("3");

    let suite = S.suite(
      "test staged Nft ask",
      [

        S.test(
          "test mint attempt ask",
          switch (mint_attempt) {
            case (#ok(res)) {

              "correct response";

            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),
        S.test(
          "fail if non owner tries to start auction ask",
          switch (start_auction_attempt_fail) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 2000) {
                //unauthorized
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0019
        S.test(
          "fail if auction already running ask",
          switch (start_auction_attempt_owner_already_started) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 13) {
                //existing sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0018
        S.test(
          "auction is started ask ",
          switch (start_auction_attempt_owner) {
            case (#ok(res)) {
              switch (res.txn_type) {
                case (#sale_opened(details)) {
                  "correct response";
                };
                case (_) {
                  "bad transaction type";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ), //MKT0021

        S.test(
          "transfer ownerfail if auction already running ask",
          switch (transfer_owner_after_auction) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 13) {
                //existing sale
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0022
        S.test(
          "fail if bid too low ask",
          switch (a_wallet_try_bid_below_start) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4004) {
                //below bid price
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MKT0023

        S.test(
          "bid is succesful ask ",
          switch (a_wallet_try_bid_valid) {
            case (#ok(res)) {
              D.print("as bid");
              D.print(debug_show (a_wallet_try_bid_valid));
              switch (res.txn_type) {
                case (#sale_ended(details)) {
                  if (
                    Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 100 * 10 ** 8 and details.sale_id == ?current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                  ) {
                    "correct response";
                  } else {
                    "details didnt match" # debug_show (details);
                  };
                };
                case (_) {
                  "bad transaction bid";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),
        S.test(
          "transaction history has the bid ask",
          switch (a_history_1) {
            case (#ok(res)) {

              D.print("where ismy history");
              D.print(debug_show (a_history_1));
              if (res.size() > 0) {
                switch (res[res.size() - 3].txn_type) {
                  case (#auction_bid(details)) {
                    if (
                      Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and details.amount == 100 * 10 ** 8 and details.sale_id == current_sales_id and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                    ) {
                      "correct response";
                    } else {
                      "details didnt match" # debug_show (details);
                    };
                  };
                  case (_) {
                    "bad history bid";
                  };
                };
              } else {
                "size was 0";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),
        S.test(
          "transaction history have the empty cancel - ask 3",
          switch (end_proper) {
            case (#ok(#end_sale(res))) {
              D.print("transaction history have the transfer 2");
              D.print(debug_show (res));
              switch (res.txn_type) {
                case (#sale_ended(details)) {
                  if (
                    Types.account_eq(details.buyer, #principal(Principal.fromActor(this))) and details.amount == 0 and Option.get(details.sale_id, "") == current_sales_id_3 and Types.token_eq(details.token, #ic({ canister = (Principal.fromActor(dfx)); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
                  ) {
                    "correct response";
                  } else {
                    "details didnt match" # debug_show (details);
                  };
                };
                case (_) {
                  "bad history sale";
                };
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
            case (_) { "unexpected error: " };
          },
          M.equals<Text>(T.text("correct response")),
        ), //todo: make a user story for adding a #sale_ended to the end of transaction log
        S.test(
          "fail if auction already over ",
          switch (end_again) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4006) {
                //already closed
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ),
        S.test(
          "flat decreases after one cycle ",
          switch (end_again) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 4006) {
                //already closed
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ),

        S.test(
          "sale info has active and only active sale in it",
          switch (active_sale_info_1) {
            case (#ok(#active(val))) {
              if (val.records.size() == 4 and val.records[0].0 == "1" and val.records[3].0 == "4") {
                "correct response";
              } else {
                "bad response" # debug_show (active_sale_info_1);
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_1);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "sale info has three active sale after close of first",
          switch (active_sale_info_2) {
            case (#ok(#active(val))) {
              if (val.records.size() == 3 and val.records[0].0 == "2") {
                "correct response";
              } else {
                "bad response" # debug_show (active_sale_info_2);
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_2);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "flat sale degrades after one minute",
          switch (active_sale_info_3) {
            case (#ok(#status(?val))) {
              switch (val.sale_type) {
                case (#auction(val)) {
                  if (val.min_next_bid == 9_900_000_000) {
                    "correct response";
                  } else {
                    "bad value" # debug_show ((val.min_next_bid, 9_900_000_000));
                  };
                };
              };

            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_3);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "percentage degrades after one minute",
          switch (percent_sale_info_3) {
            case (#ok(#status(?val))) {
              switch (val.sale_type) {
                case (#auction(val)) {
                  if (val.min_next_bid == 9_000_000_000) {
                    "correct response";
                  } else {
                    "bad value" # debug_show ((val.min_next_bid, 9_000_000_000));
                  };
                };
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (percent_sale_info_3);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "flat sale degrades after one and a half minute",
          switch (active_sale_info_half) {
            case (#ok(#status(?val))) {
              switch (val.sale_type) {
                case (#auction(val)) {
                  if (val.min_next_bid == 9_900_000_000) {
                    "correct response";
                  } else {
                    "bad value" # debug_show ((val.min_next_bid, 9_900_000_000));
                  };
                };
              };

            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_half);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "percentage degrades after one and a half minute",
          switch (percent_sale_info_half) {
            case (#ok(#status(?val))) {
              switch (val.sale_type) {
                case (#auction(val)) {
                  if (val.min_next_bid == 9_000_000_000) {
                    "correct response";
                  } else {
                    "bad value" # debug_show ((val.min_next_bid, 9_000_000_000));
                  };
                };
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (percent_sale_info_half);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "flat sale degrades after ten minutes",
          switch (active_sale_info_4) {
            case (#ok(#status(?val))) {
              switch (val.sale_type) {
                case (#auction(val)) {
                  if (val.min_next_bid == 9_000_000_000) {
                    "correct response";
                  } else {
                    "bad value" # debug_show ((val.min_next_bid, 9_000_000_000));
                  };
                };
              };

            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_4);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "percentage degrades after ten minute",
          switch (percent_sale_info_4) {
            case (#ok(#status(?val))) {
              switch (val.sale_type) {
                case (#auction(val)) {
                  if (val.min_next_bid == 3_486_784_401) {
                    "correct response";
                  } else {
                    "bad value" # debug_show ((val.min_next_bid, 3_486_784_401));
                  };
                };
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (percent_sale_info_4);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "flat sale degrades to reserve eventually",
          switch (active_sale_info_5) {
            case (#ok(#status(?val))) {
              switch (val.sale_type) {
                case (#auction(val)) {
                  if (val.min_next_bid == 2_000_000_000) {
                    "correct response";
                  } else {
                    "bad value" # debug_show ((val.min_next_bid, 2_000_000_000));
                  };
                };
              };

            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (active_sale_info_5);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

        S.test(
          "percentage degrades to reserve eventually",
          switch (percent_sale_info_5) {
            case (#ok(#status(?val))) {
              switch (val.sale_type) {
                case (#auction(val)) {
                  if (val.min_next_bid == 2_000_000_000) {
                    "correct response";
                  } else {
                    "bad value" # debug_show ((val.min_next_bid, 2_000_000_000));
                  };
                };
              };
            };
            case (#err(err)) {
              "bad error in sale info " # debug_show (err);
            };
            case (_) {
              "some odd error in sale info" # debug_show (percent_sale_info_5);
            };
          },
          M.equals<Text>(T.text("correct response")),
        ),

      ],
    );

    D.print("suite running");

    S.run(suite);

    D.print("suite over");

    return #success;

  };

  public shared func testStandardLedger() : async { #success; #fail : Text } {
    D.print("running testStandardLedger");

    let a_wallet = await TestWalletDef.test_wallet();

    let newPrincipal = await g_canister_factory.create({
      owner = Principal.fromActor(this);
      storage_space = null;
    });

    let canister : Types.Service = actor (Principal.toText(newPrincipal));

    D.print("calling stage");

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
    let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
    let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));

    D.print("finished stage");
    D.print(debug_show (standardStage.0));

    //ESC0002. try to escrow for the canister; should succeed
    //fund a_wallet
    D.print("funding result start a_wallet");
    D.print(debug_show ({ owner = Principal.fromActor(a_wallet); subaccount = null }));
    D.print(debug_show ({ owner = Principal.fromActor(a_wallet); subaccount = null }));
    D.print(debug_show (AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null))));
    let dfx : DFXTypes.Service = actor (Principal.toText(dfx_ledger));

    let funding_result = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 100 * 10 ** 8;
    });
    D.print("funding result end");
    D.print(debug_show (funding_result));

    //sent an escrow for a stdledger deposit that doesn't exist
    D.print("sending an escrow with no deposit");
    let a_wallet_try_escrow_general_fake = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), ?34, 1 * 10 ** 8, ? #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }), null);

    //send a payment to the ledger
    D.print("sending tokens to canisters");
    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (1 * 10 ** 8) + 200000, Principal.fromActor(canister));

    D.print("send to canister a");
    D.print(debug_show (a_wallet_send_tokens_to_canister));

    debug { if (debug_channel.throws) D.print("checking block_result") };
    let #ok(block_result) = a_wallet_send_tokens_to_canister;
    let block = block_result; //block is no longer relevant for ledgers

    //sent an escrow for a ledger deposit that doesn't exist
    let a_wallet_try_escrow_general_fake_amount = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), null, 2 * 10 ** 8, ? #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }), null);

    D.print("a_wallet_try_escrow_general_fake_amount" # debug_show (a_wallet_try_escrow_general_fake_amount));

    ////ESC0001

    D.print("Sending real escrow now");
    let a_wallet_try_escrow_general_staged = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), ?block, 1 * 10 ** 8, ? #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }), null);

    D.print("try escrow genreal stage");
    D.print(debug_show (a_wallet_try_escrow_general_staged));

    //ESC0005 should fail if you try to calim a deposit a second time
    let a_wallet_try_escrow_general_staged_retry = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), ?block, 1 * 10 ** 8, ? #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }), null);

    D.print("try escrow genreal stage retry");
    D.print(debug_show (a_wallet_try_escrow_general_staged_retry));

    //check balance and make sure we see the escrow BAL0002
    let a_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    D.print("thebalance");
    D.print(debug_show (a_balance));

    //MKT0007, MKT0014
    D.print("blind market");
    let blind_market = await canister.market_transfer_nft_origyn({
      token_id = "1";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(canister));
          buyer = #principal(Principal.fromActor(a_wallet));
          token_id = "";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };

    });

    D.print(debug_show (blind_market));

    //MKT0014 todo: check the transaction record and confirm the gensis reocrd

    //BAL0005
    let a_balance2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    //BAL0003
    let canister_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(canister)));

    //MKT0013, MKT0011 this item should be minted now
    let test_metadata = await canister.nft_origyn("1");
    D.print("This thing should have been minted");
    D.print(debug_show (test_metadata));
    switch (test_metadata) {
      case (#ok(val)) {
        D.print(debug_show (Metadata.is_minted(val.metadata)));
      };
      case (_) {};
    };

    //MINT0026 shold fail because the purchase of a staged item should mint it
    let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(a_wallet)));
    D.print("This thing should have not been minted");
    D.print(debug_show (mint_attempt));

    //ESC0009
    let blind_market2 = await canister.market_transfer_nft_origyn({
      token_id = "2";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(canister));
          buyer = #principal(Principal.fromActor(a_wallet));
          token_id = "";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };

    });

    D.print("This thing should have not been minted either");
    D.print(debug_show (blind_market2));

    //mint the third item to test a specific sale
    let mint_attempt3 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));

    D.print("mint attempt 3");
    D.print(debug_show (mint_attempt3));

    //creae an new wallet for testing
    let b_wallet = await TestWalletDef.test_wallet();

    //give b_wallet some tokens
    D.print("funding result start b_wallet");
    let b_funding_result = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(b_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 100 * 10 ** 8;
    });
    D.print("funding result");
    D.print(debug_show (funding_result));

    //send a payment to the the new owner(this actor- after mint)
    D.print("sending tokens to canisters");

    let b_wallet_send_tokens_to_canister = await b_wallet.send_ledger_deposit(Principal.fromActor(dfx), (1 * 10 ** 8) + 200000, Principal.fromActor(canister));

    D.print("send to canister b");
    D.print(debug_show (b_wallet_send_tokens_to_canister));

    let b_block = switch (b_wallet_send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    //ESC0002
    D.print("Sending real escrow now");
    let b_wallet_try_escrow_specific_staged = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), ?b_block, 1 * 10 ** 8, "3", null, ? #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }), null);

    //
    D.print("try escrow specific stage");
    D.print(debug_show (b_wallet_try_escrow_specific_staged));

    //MKT0010
    D.print("apecific market");
    let specific_market = await canister.market_transfer_nft_origyn({
      token_id = "3";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(Principal.fromActor(this));
          buyer = #principal(Principal.fromActor(b_wallet));
          token_id = "3";
          token = #ic({
            canister = Principal.fromActor(dfx);
            standard = #Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };

    });

    D.print(debug_show (specific_market));

    //test balances

    let suite = S.suite(
      "test market Nft",
      [
        S.test(
          "fail if escrow is double processed",
          switch (a_wallet_try_escrow_general_staged_retry) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3003) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0005
        S.test(
          "fail if mint is called on a minted item",
          switch (mint_attempt) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 10) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MINT0026

        S.test(
          "item is minted now",
          switch (test_metadata) {
            case (#ok(res)) {
              if (Metadata.is_minted(res.metadata) == true) {
                "was minted";
              } else {
                "was not minted";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("was minted")),
        ), //MKT0013
        S.test(
          "item is owned by correct owner after minting",
          switch (test_metadata) {
            case (#ok(res)) {
              if (
                Types.account_eq(
                  switch (Metadata.get_nft_owner(res.metadata)) {
                    case (#err(err)) {
                      #account_id("invalid");
                    };
                    case (#ok(val)) {
                      D.print(debug_show (val));
                      val;
                    };
                  },
                  #principal(Principal.fromActor(a_wallet)),
                ) == true
              ) {
                "was transfered";
              } else {
                D.print("awallet");
                D.print(debug_show (Principal.fromActor(a_wallet)));
                "was not transfered";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("was transfered")),
        ), //MKT0011

        S.test(
          "fail if escrow already spent c",
          switch (blind_market2) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3000) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0009

        S.test(
          "fail if escrowing for a non existant deposit c",
          switch (a_wallet_try_escrow_general_fake) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3003) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0006
        S.test(
          "fail if escrowing for an existing deposit but fake amount c",
          switch (a_wallet_try_escrow_general_fake_amount) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 3003) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err.number);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //ESC0011
        S.test(
          "can escrow for general unminted item",
          switch (a_wallet_try_escrow_general_staged) {
            case (#ok(res)) {
              D.print("an amount for escrow");
              D.print(debug_show (res.receipt));
              if (res.receipt.amount == 1 * 10 ** 8) {
                "was escrowed";
              } else {
                "was not escrowed";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("was escrowed")),
        ), //ESC0002
        S.test(
          "can escrow for specific item",
          switch (b_wallet_try_escrow_specific_staged) {
            case (#ok(res)) {
              if (res.receipt.amount == 1 * 10 ** 8) {
                "was escrowed";
              } else {
                "was not escrowed";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("was escrowed")),
        ), //ESC0001
        S.test(
          "owner can sell specific NFT - produces sale_id",
          switch (specific_market) {
            case (#ok(res)) {
              if (res.token_id == "3") {
                "found tx record";
              } else {
                D.print(debug_show (res));
                "no sales id ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found tx record")),
        ), //MKT0010
        S.test(
          "escrow balance is shown",
          switch (a_balance) {
            case (#ok(res)) {
              D.print("this should be failing for now because it cmpares dip20 but we did ledger");
              D.print(debug_show (res));
              D.print(debug_show (#principal(Principal.fromActor(canister))));
              D.print(debug_show (#principal(Principal.fromActor(a_wallet))));
              D.print(debug_show (Principal.fromActor(dfx)));
              if (
                Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(canister))) and Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet))) and res.escrow[0].token_id == "" and Types.token_eq(res.escrow[0].token, #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }))
              ) {
                "found escrow record";
              } else {
                D.print(debug_show (res));
                "didnt find record ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found escrow record")),
        ), //BAL0001
        S.test(
          "escrow balance is removed",
          switch (a_balance2) {
            case (#ok(res)) {
              D.print(debug_show (res));
              if (res.escrow.size() == 0) {
                "no escrow record";
              } else {
                D.print(debug_show (res));
                "found record  ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("no escrow record")),
        ), //BAL0005
        S.test(
          "sale balance is shown",
          switch (a_balance) {
            case (#ok(res)) {
              D.print(debug_show (res));
              D.print(debug_show (#principal(Principal.fromActor(canister))));
              D.print(debug_show (#principal(Principal.fromActor(a_wallet))));
              D.print(debug_show (Principal.fromActor(dfx)));
              if (
                Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet))) and Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(canister))) and res.escrow[0].token_id == "" and Types.token_eq(res.escrow[0].token, #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null })) and res.escrow[0].amount == 1 * 10 ** 8
              ) {
                "found sale record";
              } else {
                D.print(debug_show (res));
                "didnt find record ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found sale record")),
        ), //BAL0003

      ],
    );

    S.run(suite);

    return #success;
  };

  public shared func testOffers() : async { #success; #fail : Text } {
    D.print("running testOffers");

    let a_wallet = await TestWalletDef.test_wallet();
    let b_wallet = await TestWalletDef.test_wallet();
    let c_wallet = await TestWalletDef.test_wallet();

    let newPrincipal = await g_canister_factory.create({
      owner = Principal.fromActor(this);
      storage_space = null;
    });

    let canister : Types.Service = actor (Principal.toText(newPrincipal));

    D.print("calling stage");

    let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
    let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(c_wallet))); //mint to c_wallet

    D.print("finished stage");
    D.print(debug_show (standardStage.0));
    D.print(debug_show (mint_attempt));

    //ESC0002. try to escrow for the canister; should succeed
    //fund a_wallet
    D.print("funding result start a_wallet");
    D.print(debug_show ({ owner = Principal.fromActor(a_wallet); subaccount = null }));
    D.print(debug_show ({ owner = Principal.fromActor(a_wallet); subaccount = null }));
    D.print(debug_show (AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null))));
    let dfx : DFXTypes.Service = actor (Principal.toText(dfx_ledger));

    let funding_result = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 100 * 10 ** 8;
    });
    D.print("funding result end");
    D.print(debug_show (funding_result));

    //send a payment to the ledger
    D.print("sending tokens to canisters");
    let a_ledger_balance_before_escrow = await a_wallet.ledger_balance(Principal.fromActor(dfx), Principal.fromActor(a_wallet));
    D.print("the a ledger balance" # debug_show (a_ledger_balance_before_escrow));

    let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_deposit(Principal.fromActor(dfx), (1 * 10 ** 8) + 200000, Principal.fromActor(canister));

    D.print("send to canister a");
    D.print(debug_show (a_wallet_send_tokens_to_canister));

    ////ESC0001

    D.print("Sending real escrow now");

    D.print("Sending real escrow now");
    let a_wallet_try_escrow_specific_staged = await a_wallet.try_escrow_specific_staged(Principal.fromActor(c_wallet), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "1", null, ? #ic({ canister = Principal.fromActor(dfx); standard = #Ledger; decimals = 8; symbol = "LDG"; fee = ?200000; id = null }), null);

    D.print("try escrow genreal stage");
    D.print(debug_show (a_wallet_try_escrow_specific_staged));

    //check balance and make sure we see the escrow BAL0002
    let a_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    let a_ledger_balance_after_escrow = await a_wallet.ledger_balance(Principal.fromActor(dfx), Principal.fromActor(a_wallet));
    let c_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(c_wallet)));

    D.print("the a balance" # debug_show (a_balance));
    D.print("the a ledger balance" # debug_show (a_ledger_balance_after_escrow));
    D.print("the c balance" # debug_show (c_balance));

    //have b try to reject the escrow ....should fail

    //canister should have an offer
    let c_wallet_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(c_wallet)));

    let reject_wrong_seller = await b_wallet.try_escrow_reject(
      Principal.fromActor(canister),
      Principal.fromActor(a_wallet),
      Principal.fromActor(dfx),
      Principal.fromActor(c_wallet),
      "1",
      null,
    );

    D.print("reject_wrong_seller" # debug_show (reject_wrong_seller));

    //MKT0014 todo: check the transaction record and confirm the gensis reocrd

    //BAL0005
    let a_balance2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
    let a_ledger_balance2 = await a_wallet.ledger_balance(Principal.fromActor(dfx), Principal.fromActor(a_wallet));

    D.print("the a balance 2 " # debug_show (a_balance2));
    D.print("the a ledger balance 2" # debug_show (a_ledger_balance2));
    D.print("c_balance" # debug_show (c_balance));

    //BAL0003
    let c_wallet_balance_2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(c_wallet)));

    //have the owner reject the offer

    let reject_right_seller = await c_wallet.try_escrow_reject(
      Principal.fromActor(canister),
      Principal.fromActor(a_wallet),
      Principal.fromActor(dfx),
      Principal.fromActor(c_wallet),
      "1",
      null,
    );

    D.print("reject_right_seller" # debug_show (reject_right_seller));

    let a_balance3 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

    let a_ledger_balance3 = await a_wallet.ledger_balance(Principal.fromActor(dfx), Principal.fromActor(a_wallet));
    let c_balance2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(c_wallet)));

    D.print("the a balance 3 " # debug_show (a_balance3));
    D.print("the a balance 2 " # debug_show (c_balance2));
    D.print("the a ledger balance 3 " # debug_show (a_ledger_balance3));

    //refresh removes the offer
    let c_refresh = await c_wallet.try_offer_refresh(Principal.fromActor(canister));

    D.print("c_refresh3 " # debug_show (c_refresh));

    let c_balance3 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(c_wallet)));

    D.print("c_balance3 " # debug_show (c_balance3));
    //test balances

    let suite = S.suite(
      "test market Nft",
      [
        S.test(
          "fail if b can reject",
          switch (reject_wrong_seller) {
            case (#ok(res)) { "unexpected success" };
            case (#err(err)) {
              if (err.number == 2000) {
                //
                "correct number";
              } else {
                "wrong error " # debug_show (err);
              };
            };
          },
          M.equals<Text>(T.text("correct number")),
        ), //MINT0026

        S.test(
          "c has offer",
          switch (c_balance) {
            case (#ok(res)) {
              D.print("testing sale balance 2");
              D.print(debug_show (res));

              if (res.offers.size() == 0) {
                "found empty record";
              } else {
                D.print(debug_show (res));
                "found a record";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found a record")),
        ), //todo: NFT-118

        S.test(
          "does not  gets money back after wrong reject",
          if (a_ledger_balance_after_escrow.e8s == a_ledger_balance2.e8s) {
            "correct amount";
          } else {
            "wrong amount " # Nat.toText(Nat64.toNat(a_ledger_balance_before_escrow.e8s)) # " " # Nat.toText(Nat64.toNat(a_ledger_balance3.e8s));
          },
          M.equals<Text>(T.text("correct amount")),
        ),
        S.test(
          "a gets money back after reject",
          if (a_ledger_balance_before_escrow.e8s - 200000 - 200000 - 200000 == a_ledger_balance3.e8s) {
            //original balance = should equal the refund + fee for depoist + fee for claim + fee to send back
            "correct amount";
          } else {
            "wrong amount " # Nat.toText(Nat64.toNat(a_ledger_balance_before_escrow.e8s)) # " " # Nat.toText(Nat64.toNat(a_ledger_balance3.e8s));
          },
          M.equals<Text>(T.text("correct amount")),
        ),

        S.test(
          "c has no offer",
          switch (c_balance3) {
            case (#ok(res)) {
              D.print("testing offer balance 3");
              D.print(debug_show (res));

              if (res.offers.size() == 0) {
                "found empty record";
              } else {
                D.print(debug_show (res));
                "found a record ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found empty record")),
        ),
        S.test(
          "a has no escrow after",
          switch (a_balance3) {
            case (#ok(res)) {
              D.print("testing sale balance 2");
              D.print(debug_show (res));

              if (res.offers.size() == 0) {
                "found empty record";
              } else {
                D.print(debug_show (res));
                "found a record ";
              };
            };
            case (#err(err)) {
              "unexpected error: " # err.flag_point;
            };
          },
          M.equals<Text>(T.text("found empty record")),
        ),

      ],
    );

    S.run(suite);

    return #success;
  };

};
