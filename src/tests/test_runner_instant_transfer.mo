import S "mo:matchers/Suite";
import T "mo:matchers/Testable";
import M "mo:matchers/Matchers";

import Conversion "mo:candy/conversion";
import CandyTypes "mo:candy/types";
import Option "mo:base/Option";

import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
import D "mo:base/Debug";
import DFXTypes "../origyn_nft_reference/dfxtypes";
import AccountIdentifier "mo:principalmo/AccountIdentifier";
import TestWalletDef "test_wallet";
import Types "../origyn_nft_reference/types";
import Metadata "../origyn_nft_reference/metadata";
import utils "test_utils";
import MigrationTypes "../origyn_nft_reference/migrations/types";
import ICRC7Types "../origyn_nft_reference/ICRC7";
import ICRC2Types "../external_canisters/ICRC2";
import Royalties "../origyn_nft_reference/market/royalties";

shared (deployer) actor class test_runner_instant_transfer(dfx_ledger : Principal, dfx_ledger2 : Principal) = this {

  let CandyTypes = MigrationTypes.Current.CandyTypes;
  let Conversions = MigrationTypes.Current.Conversions;
  let Properties = MigrationTypes.Current.Properties;
  let Workspace = MigrationTypes.Current.Workspace;

  private func get_time() : Int {
    return Time.now();
  };

  private var DAY_LENGTH = 60 * 60 * 24 * 10 ** 9;

  let dfx : ICRC2Types.Self = actor (Principal.toText(dfx_ledger));

  let dfxspec = {
    canister = Principal.fromActor(dfx);
    standard = #Ledger;
    decimals = 8;
    symbol = "OGY";
    fee = ?200000;
    id = null;
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
        // S.test("testInstantTransfer", switch (await testInstantTransfer()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        // S.test("testSoulbound", switch (await testSoulbound()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
        S.test("testIcrc7Transfer", switch (await testIcrc7Transfer()) { case (#success) { true }; case (_) { false } }, M.equals<Bool>(T.bool(true))),
      ],
    );
    S.run(suite);

    return #success;
  };

  public shared func testInstantTransfer() : async { #success; #fail : Text } {

    let this_principal = Principal.fromActor(this);

    let dfx : DFXTypes.Service = actor (Principal.toText(dfx_ledger));
    let ledger_principal = dfx_ledger;

    //create and fund wallet
    let a_wallet = await TestWalletDef.test_wallet();
    let a_principal = Principal.fromActor(a_wallet);
    let fund_a_wallet = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 100 * 10 ** 8;
    });
    D.print("funding result end");
    D.print(debug_show (fund_a_wallet));

    //create canister
    let newPrincipal = await g_canister_factory.create({
      owner = Principal.fromActor(this);
      storage_space = null;
    });

    let canister : Types.Service = actor (Principal.toText(newPrincipal));
    let canister_principal = Principal.fromActor(canister);

    //stage unminted and minted NFTs
    let stage_minted_nft = await utils.buildStandardNFT("first", canister, this_principal, 1024, false, Principal.fromActor(this)); //this sets the owner of the nft to the canister change later on mint
    let stage_unminted_nft = await utils.buildStandardNFT("second", canister, this_principal, 1024, false, Principal.fromActor(this)); //this sets the owner of th nft to the canister

    //mint first staged NFT
    let mint_nft = await canister.mint_nft_origyn("first", #principal(this_principal)); //changing owner of first to this

    D.print("sending funds");
    //create an escrow by sending tokens to the ledger
    let send_tokens_to_canister = await a_wallet.send_ledger_deposit(ledger_principal, (1 * 10 ** 8) + 200000, canister_principal);

    D.print("funds sent " # debug_show (send_tokens_to_canister));
    //retreive block information
    let block = switch (send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    //reset time to time now
    let set_time_mode = await canister.__set_time_mode(#test);

    let set_time = await canister.__advance_time(get_time());

    D.print("time set");

    //Attempt to start the auction for minted NFT
    let start_auction_minted = await canister.market_transfer_nft_origyn({
      token_id = "first";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #auction {
          reserve = ?(1 * 10 ** 8);
          token = #ic({
            canister = ledger_principal;
            standard = #Ledger;
            decimals = 8;
            symbol = "OGY";
            fee = ?200000;
            id = null;
          });
          buy_now = ?(500 * 10 ** 8);
          start_price = (1 * 10 ** 8);
          start_date = 0;
          ending = #date(get_time() + 518400000000000);
          min_increase = #amount(10 * 10 ** 8);
          allow_list = null;
        };
      };
    });
    //Get the sales id for the minted NFT
    let sales_id_minted = switch (start_auction_minted) {
      case (#ok(val)) {
        switch (val.txn_type) {
          case (#sale_opened(sale_data)) {
            sale_data.sale_id;
          };
          case (_) {
            //D.print("Didn't find expected sale_opened");
            return #fail("Didn't find expected sale_opened");
          };
        };
      };
      case (#err(item)) {
        //D.print("error with auction start");
        return #fail("error with auction start");
      };
    };

    //Attempt to start the auction for the unminted NFT
    let start_auction_unminted = await canister.market_transfer_nft_origyn({
      token_id = "second";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #auction {
          reserve = null;
          token = #ic({
            canister = ledger_principal;
            standard = #Ledger;
            decimals = 8;
            symbol = "OGY";
            fee = ?200000;
            id = null;
          });
          buy_now = ?(500 * 10 ** 8);
          start_price = (1 * 10 ** 8);
          start_date = 0;
          ending = #date(get_time() + 518400000000000);
          min_increase = #amount(10 * 10 ** 8);
          allow_list = null;
        };
      };
    });
    //Get the sales id for the unminted NFT //shouldnt get a sale id
    /* let sales_id_unminted = switch(start_auction_unminted){
            case(#ok(val)){
                switch(val.txn_type){
                    case(#sale_opened(sale_data)){
                        sale_data.sale_id;
                    };
                    case(_){
                        //D.print("Didn't find expected sale_opened");
                        return #fail("Didn't find expected sale_opened");
                    }
                };
            };
            case(#err(item)){
                //D.print("error with auction start");
                return #fail("error with auction start");
            };
        }; */

    D.print("auction started for second " # debug_show (start_auction_unminted));

    D.print("all started");

    //Sending a valid escrow for minted item
    let escrow_minted = await a_wallet.try_escrow_specific_staged(this_principal, canister_principal, ledger_principal, null, 1 * 10 ** 8, "first", ?sales_id_minted, null, null);

    //send general escrow for unminted nft with the same block
    //should fail because deposit is burned
    let escrow_unminted_same_block = await a_wallet.try_escrow_general_staged(canister_principal, canister_principal, ledger_principal, null, 1 * 10 ** 8, null, null);

    //create another escrow
    let send_tokens_to_canister_again = await a_wallet.send_ledger_deposit(ledger_principal, (1 * 10 ** 8) + 200000 + 1, canister_principal);

    //get block information
    //      ¿Can you use the same block twice? - seems not
    let block2 = switch (send_tokens_to_canister_again) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    //Should fail - Can't escrow_specific for unminted item
    //let escrow_specific_unminted = await a_wallet.try_escrow_specific_staged(this_principal, canister_principal, ledger_principal, block, 1 * 10 ** 8, "second", ?sales_id_unminted, null);

    //send general escrow for unminted nft with new block
    let escrow_new_block = await a_wallet.try_escrow_general_staged(canister_principal, canister_principal, ledger_principal, null, 1 * 10 ** 8, null, null);

    //make sure an owner can't instant transfer with my escrow when I'm intending to bid on an auction
    D.print("Trying to transfer while auction open");
    let instant_transfer_no_bid_minted = await canister.market_transfer_nft_origyn({
      token_id = "first";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(this_principal);
          buyer = #principal(a_principal);
          token_id = "first";
          token = #ic({
            canister = ledger_principal;
            standard = #Ledger;
            decimals = 8;
            symbol = "OGY";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };
    });
    D.print(debug_show (instant_transfer_no_bid_minted));
    //note: you can't bid on an unminted NFT yet, but this should still fail as #existing_sale_found because auction has been started
    let instant_transfer_no_bid_unminted = await canister.market_transfer_nft_origyn({
      token_id = "second";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(canister_principal); //canister still owns second
          buyer = #principal(a_principal);
          token_id = "second";
          token = #ic({
            canister = ledger_principal;
            standard = #Ledger;
            decimals = 8;
            symbol = "OGY";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        broker_id = null;
        pricing = #instant(null);
      };
    });

    //Placing valid bid
    let valid_bid_minted = await a_wallet.try_bid(canister_principal, this_principal, ledger_principal, 1 * 10 ** 8, "first", sales_id_minted, null, null);

    //Placing bid for unminted item - should fail as of now
    //D.print("doing valid bid unminted");
    //let valid_bid_unminted = await a_wallet.try_bid(canister_principal, canister_principal, ledger_principal, 1*10**8, "second", sales_id_unminted);

    //D.print(debug_show(valid_bid_unminted));
    //can't do an owner transfer during an auction
    let transfer_while_auction_minted = await canister.market_transfer_nft_origyn({
      token_id = "first";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(this_principal);
          buyer = #principal(a_principal);
          token_id = "first";
          token = #ic({
            canister = ledger_principal;
            standard = #Ledger;
            decimals = 8;
            symbol = "OGY";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };
    });

    let transfer_while_auction_unminted = await canister.market_transfer_nft_origyn({
      token_id = "second";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(this_principal);
          buyer = #principal(a_principal);
          token_id = "second";
          token = #ic({
            canister = ledger_principal;
            standard = #Ledger;
            decimals = 8;
            symbol = "OGY";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };
    });

    D.print("transfer_while_auction_unminted" # debug_show (transfer_while_auction_unminted));

    let set_time2 = await canister.__advance_time(get_time() + 518400000000000 + 518400000000000);

    //end auctions - should transfer minted NFT to a wallet
    let end_auction_minted = await canister.sale_nft_origyn(#end_sale("first"));
    //let end_auction_unminted = await canister.end_sale_nft_origyn("second");

    //try transferring wrong nft with escrow on deposit (make sure user doesn't get something they don't want)
    let transfer_wrong_nft = await canister.market_transfer_nft_origyn({
      token_id = "first";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(this_principal);
          buyer = #principal(a_principal);
          token_id = "second";
          token = #ic({
            canister = ledger_principal;
            standard = #Ledger;
            decimals = 8;
            symbol = "OGY";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };
    });

    //Attempt to transfer unminted NFT after auction
    let unminted_instant_transfer = await canister.market_transfer_nft_origyn({
      token_id = "second";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(canister_principal);
          buyer = #principal(a_principal);
          token_id = "";
          token = #ic({
            canister = ledger_principal;
            standard = #Ledger;
            decimals = 8;
            symbol = "OGY";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };
    });

    //get nft metadata info to check owner for tests
    let first_nft_metadata = await a_wallet.try_get_nft(canister_principal, "first");
    let second_nft_metadata = await a_wallet.try_get_nft(canister_principal, "second");

    /* //Helpful Debug Output
        //D.print( "\n" #
            "fund_a_wallet: " # debug_show(fund_a_wallet) # "\n\n" #
            "stage_minted_nft: " # debug_show(stage_minted_nft) # "\n\n" #
            "stage_unminted_nft: " # debug_show(stage_unminted_nft) # "\n\n" #
            "mint_nft: " # debug_show(mint_nft) # "\n\n" #
            "send_tokens_to_canister: " # debug_show(send_tokens_to_canister) # "\n\n" #
            "block: " # debug_show(block) # "\n\n" #
            "set_time: " # debug_show(set_time) # "\n\n" #
            "start_auction_minted: " # debug_show(start_auction_minted) # "\n\n" #
            "sales_id_minted: " # debug_show(sales_id_minted) # "\n\n" #
            "start_auction_unminted: " # debug_show(start_auction_unminted) # "\n\n" #
            "sales_id_unminted: " # debug_show(sales_id_unminted) # "\n\n" #
            "escrow_minted: " # debug_show(escrow_minted) # "\n\n" #
            "escrow_unminted_same_block: " # debug_show(escrow_unminted_same_block) # "\n\n" #
            "send_tokens_to_canister_again: " # debug_show(send_tokens_to_canister_again) # "\n\n" #
            "block2: " # debug_show(block2) # "\n\n" #
            "escrow_specific_unminted: " # debug_show(escrow_specific_unminted) # "\n\n" #
            "escrow_new_block: " # debug_show(escrow_new_block) # "\n\n" #
            "instant_transfer_no_bid_minted: " # debug_show(instant_transfer_no_bid_minted) # "\n\n" #
            "instant_transfer_no_bid_unminted: " # debug_show(instant_transfer_no_bid_unminted) # "\n\n" #
            "valid_bid_minted: " # debug_show(valid_bid_minted) # "\n\n" #
            "valid_bid_unminted: " # debug_show(valid_bid_unminted) # "\n\n" #
            "transfer_while_auction_minted: " # debug_show(transfer_while_auction_minted) # "\n\n" #
            "transfer_while_auction_unminted: " # debug_show(transfer_while_auction_unminted) # "\n\n" #
            "end_auction_minted: " # debug_show(end_auction_minted) # "\n\n" #
            "end_auction_unminted: " # debug_show(end_auction_unminted) # "\n\n" #
            "transfer_wrong_nft: " # debug_show(transfer_wrong_nft) # "\n\n" #
            "unminted_instant_transfer: " # debug_show(unminted_instant_transfer) # "\n\n"
        ); */

    let suite = S.suite(
      "test NFT instant transfer",
      [
        S.test(
          "NFTs staged succesfully",
          switch (stage_minted_nft, stage_unminted_nft) {
            case (
              (#ok("first"), #ok(val), #ok(val2), #ok(val3)),
              (#ok("second"), #ok(val4), #ok(val5), #ok(val6)),
            ) { "staging succesful" };
            case (_, _) {
              "wrong action --\nfirst: " # debug_show (stage_minted_nft) # "\nsecond: " # debug_show (stage_unminted_nft);
            };
          },
          M.equals<Text>(T.text("staging succesful")),
        ),
        S.test(
          "NFT minted succesfully",
          switch (mint_nft) {
            case (#ok("first")) { "mint succesful" };
            case (_) { "wrong action: " # debug_show (mint_nft) };
          },
          M.equals<Text>(T.text("mint succesful")),
        ),
        S.test(
          "Tokens sent to canister",
          switch (send_tokens_to_canister) {
            case (#ok(_)) { "transfer succesful" };
            case (_) { "wrong action: " # debug_show (send_tokens_to_canister) };
          },
          M.equals<Text>(T.text("transfer succesful")),
        ),
        S.test(
          "Minted auction started correctly",
          switch (start_auction_minted) {
            case (#ok(_)) { "auction start succesful" };
            case (_) { "wrong action: " # debug_show (start_auction_minted) };
          },
          M.equals<Text>(T.text("auction start succesful")),
        ),
        S.test(
          "Unminted auction started correctly",
          switch (start_auction_unminted) {
            case (#err(err)) {
              if (err.error == #nyi) { "correct error" } else {
                "wrong error: " # debug_show (err.error);
              };
            };
            case (_) { "wrong action: " # debug_show (start_auction_unminted) };
          },
          M.equals<Text>(T.text("correct error")),
        ),
        S.test(
          "Escrow created succesfully (minted NFT)",
          switch (escrow_minted) {
            case (#ok(info)) {
              if (info.balance == 100_000_000 and info.receipt.buyer == #principal(a_principal) and info.receipt.seller == #principal(this_principal)) {
                "correct escrow data";
              } else { "wrong escrow data: " # debug_show (escrow_minted) };
            };
            case (_) {
              "escrow should have passed: " # debug_show (escrow_minted);
            };
          },
          M.equals<Text>(T.text("correct escrow data")),
        ),
        S.test(
          "Escrow with burned deposit (same block twice)",
          switch (escrow_unminted_same_block) {
            case (#err(err)) {
              if (err.number == 3003) { "correct error" } else {
                "wrong error: " # debug_show (err);
              };
            };
            case (_) {
              "escrow should not have passed: " # debug_show (escrow_unminted_same_block);
            };
          },
          M.equals<Text>(T.text("correct error")),
        ),
        S.test(
          "Tokens sent to canister again",
          switch (send_tokens_to_canister_again) {
            case (#ok(_)) { "transfer succesful" };
            case (_) {
              "wrong action: " # debug_show (send_tokens_to_canister_again);
            };
          },
          M.equals<Text>(T.text("transfer succesful")),
        ),
        /* S.test("Escrow_specific for an unminted NFT",
                switch(escrow_specific_unminted) {
                  case(#err(err)) {
                      if (err.error == #token_not_found) { "correct error" }
                      else { "wrong error: " # debug_show(err.error)}; };
                  case(_) { "escrow should not have passed: " # debug_show(escrow_specific_unminted) };},
                M.equals<Text>(T.text("correct error"))), */
        S.test(
          "Escrow created succesfully (unminted NFT)",
          switch (escrow_new_block) {
            case (#ok(info)) {
              if (info.balance == 100_000_000 and info.receipt.buyer == #principal(a_principal)) {
                "correct escrow data";
              } else { "wrong escrow data: " # debug_show (escrow_new_block) };
            };
            case (_) {
              "escrow should have passed: " # debug_show (escrow_new_block);
            };
          },
          M.equals<Text>(T.text("correct escrow data")),
        ),
        S.test(
          "Instant transfer with no bid",
          switch (instant_transfer_no_bid_minted) {
            case (#err(err)) {
              if (err.error == #existing_sale_found) { "correct error" } else {
                "wrong error: " # debug_show (err.error);
              };
            };
            case (_) {
              "nft should not have been transferred: " # debug_show (instant_transfer_no_bid_minted);
            };
          },
          M.equals<Text>(T.text("correct error")),
        ),
        S.test(
          "Instant transfer with no bid on unminted item",
          switch (instant_transfer_no_bid_unminted) {
            case (#err(err)) {
              if (err.error == #token_not_found) { "correct error" } else {
                "wrong error: " # debug_show (err.error);
              };
            };
            case (_) {
              "nft should not have been transferred: " # debug_show (instant_transfer_no_bid_unminted);
            };
          },
          M.equals<Text>(T.text("correct error")),
        ),
        S.test(
          "Able to place a valid bid for minted NFT",
          switch (valid_bid_minted) {
            case (#ok(info)) {
              if (
                info.token_id == "first" and
                (
                  switch (info.txn_type) {
                    case (#auction_bid(content)) {
                      if (content.amount == 100_000_000 and content.buyer == #principal(a_principal) and content.sale_id == sales_id_minted) {
                        true;
                      } else { false };
                    };
                    case (_) { false };
                  }
                )
              ) { "correct bid data" } else {
                "wrong bid data: " # debug_show (valid_bid_minted);
              };
            };
            case (_) {
              "bid should have been placed: " # debug_show (valid_bid_minted);
            };
          },
          M.equals<Text>(T.text("correct bid data")),
        ),
        /* S.test("Placing a bid for unminted item should fail",
                switch(valid_bid_unminted) {
                  case(#err(err)) {
                      if (err.error == #no_escrow_found) { "correct error" } //shoulnt be able to find the escrow because ids wont match
                      else {
                          //D.print(debug_show(err));
                          "wrong error: " # debug_show(err.error)}; };
                  case(_) { "escrow should not have passed: " # debug_show(valid_bid_unminted) };},
                M.equals<Text>(T.text("correct error"))), */
        S.test(
          "Instant transfer while auction is still open (minted NFT)",
          switch (transfer_while_auction_minted) {
            case (#err(err)) {
              if (err.error == #existing_sale_found) { "correct error" } else {
                "wrong error: " # debug_show (err);
              };
            };
            case (_) {
              "nft should not have been transferred: " # debug_show (transfer_while_auction_minted);
            };
          },
          M.equals<Text>(T.text("correct error")),
        ),
        S.test(
          "Instant transfer while auction is still open (unminted NFT)",
          switch (transfer_while_auction_unminted) {
            case (#err(err)) {
              if (err.error == #token_not_found) { "correct error" } else {
                "wrong error: " # debug_show (err.error);
              };
            };
            case (_) {
              "nft should not have been transferred: " # debug_show (transfer_while_auction_unminted);
            };
          },
          M.equals<Text>(T.text("correct error")),
        ),
        S.test(
          "Auction for first item ended succesfully",
          switch (end_auction_minted) {
            case (#ok(info)) {
              switch (info) {
                case (#end_sale(info)) {
                  if (
                    info.token_id == "first" and
                    (
                      switch (info.txn_type) {
                        case (#sale_ended(content)) {
                          if (content.amount == 100_000_000 and content.buyer == #principal(a_principal) and content.sale_id == ?sales_id_minted) {
                            true;
                          } else { false };
                        };
                        case (_) { false };
                      }
                    )
                  ) { "auction ended correctly" } else {
                    "wrong auction data: " # debug_show (end_auction_minted);
                  };
                };
                case (_) {
                  "auction should have closed: " # debug_show (end_auction_minted);
                };
              };
            };
            case (#err(err)) {
              "auction should have closed: " # debug_show (err);
            };
          },
          M.equals<Text>(T.text("auction ended correctly")),
        ),
        /* S.test("Auction for second item ended succesfully",
                switch(end_auction_unminted) {
                  case(#ok(info)) {
                      if ( info.token_id == "second" and
                      (switch (info.txn_type) {
                          case(#sale_ended(content)) {
                              if (content.amount == 0 and content.extensible == #Text("no bids")) {true}
                                else {false}; };
                          case(_) {false};
                      })) { "auction ended correctly" }
                      else { "wrong auction data: " # debug_show(end_auction_unminted) }; };
                  case(_) { "auction should have closed: " # debug_show(end_auction_unminted) };},
                M.equals<Text>(T.text("auction ended correctly"))),*/
        S.test(
          "Instant transfer with the wrong escrow on deposit",
          switch (transfer_wrong_nft) {
            case (#err(err)) {
              if (err.error == #unauthorized_access) { "correct error" } else {
                "wrong error: " # debug_show (err.error);
              };
            };
            case (_) {
              "nft should not have been transferred: " # debug_show (transfer_wrong_nft);
            };
          },
          M.equals<Text>(T.text("correct error")),
        ),
        S.test(
          "Instant transfer with the wrong escrow on deposit",
          switch (unminted_instant_transfer) {
            case (#ok(info)) {
              if (info.token_id == "second") { "transfer succesful" } else {
                "wrong metadata: " # debug_show (info);
              };
            };
            case (_) {
              "nft should have been transferred: " # debug_show (unminted_instant_transfer);
            };
          },
          M.equals<Text>(T.text("transfer succesful")),
        ),
        S.test(
          "minted NFT should be owned by a_wallet",
          switch (first_nft_metadata) {
            case (#ok(res)) {
              if (
                Types.account_eq(
                  switch (Metadata.get_nft_owner(res.metadata)) {
                    case (#err(err)) { #account_id("invalid") };
                    case (#ok(val)) { val };
                  },
                  #principal(a_principal),
                ) == true
              ) {
                "was transfered";
              } else {
                D.print("awallet wrong transfer");
                D.print(debug_show ((a_principal, first_nft_metadata)));
                "was not transfered";
              };
            };
            case (#err(err)) { "unexpected error: " # err.flag_point };
          },
          M.equals<Text>(T.text("was transfered")),
        ),
        /* S.test("unminted NFT should be owned by a_wallet",
                switch(second_nft_metadata)
                    {case(#ok(res)){
                        if(Types.account_eq(switch(Metadata.get_nft_owner(res.metadata)){
                            case(#err(err)){#account_id("invalid")};
                            case(#ok(val)){val};
                        }, #principal(a_principal) ) == true){
                            "was transfered"
                        } else {
                            //D.print("awallet");
                            //D.print(debug_show(a_principal));
                            "was not transfered"}};
                    case(#err(err)) {"unexpected error: " # err.flag_point};},
                M.equals<Text>(T.text("was transfered"))),           */
      ],
    );

    S.run(suite);

    return #success;
  };

  public shared func testSoulbound() : async { #success; #fail : Text } {

    let this_principal = Principal.fromActor(this);

    let dfx : DFXTypes.Service = actor (Principal.toText(dfx_ledger));
    let ledger_principal = dfx_ledger;

    //create and fund wallet
    let a_wallet = await TestWalletDef.test_wallet();
    let a_principal = Principal.fromActor(a_wallet);

    let fund_a_wallet = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = utils.memo_one;
      from_subaccount = null;
      created_at_time = null;
      amount = 100 * 10 ** 8;
    });
    D.print("funding result end");
    D.print(debug_show (fund_a_wallet));

    //create canister
    let newPrincipal = await g_canister_factory.create({
      owner = Principal.fromActor(this);
      storage_space = null;
    });
    let canister : Types.Service = actor (Principal.toText(newPrincipal));
    let canister_principal = Principal.fromActor(canister);

    //stage unminted and minted NFTs
    let stage_soulbound_nft = await utils.buildStandardNFT("soulbound", canister, this_principal, 1024, true, Principal.fromActor(this));
    let mint_nft = await canister.mint_nft_origyn("soulbound", #principal(this_principal));

    //create an escrow by sending tokens to the ledger
    let send_tokens_to_canister = await a_wallet.send_ledger_deposit(ledger_principal, (1 * 10 ** 8) + 200000, canister_principal);

    //retreive block information
    let block = switch (send_tokens_to_canister) {
      case (#ok(ablock)) {
        ablock;
      };
      case (#err(other)) {
        D.print("ledger didnt work");
        return #fail("ledger didnt work");
      };
    };

    //reset time to time now
    let set_time = await canister.__advance_time(get_time());

    //Attempt to start the auction for soubound NFT
    let start_auction_soulbound = await canister.market_transfer_nft_origyn({
      token_id = "soulbound";
      sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #auction {
          reserve = ?(1 * 10 ** 8);
          token = #ic({
            canister = ledger_principal;
            standard = #Ledger;
            decimals = 8;
            symbol = "OGY";
            fee = ?200000;
            id = null;
          });
          buy_now = ?(500 * 10 ** 8); //nyi
          start_price = (1 * 10 ** 8);
          start_date = 0;
          ending = #date(get_time());
          min_increase = #amount(10 * 10 ** 8);
          allow_list = null;
        };
      };
    });

    //Attempt to transfer unminted NFT after auction
    let soulbound_instant_transfer = await canister.market_transfer_nft_origyn({
      token_id = "soulbound";
      sales_config = {
        escrow_receipt = ?{
          seller = #principal(canister_principal);
          buyer = #principal(a_principal);
          token_id = "";
          token = #ic({
            canister = ledger_principal;
            standard = #Ledger;
            decimals = 8;
            symbol = "OGY";
            fee = ?200000;
            id = null;
          });
          amount = 100_000_000;
        };
        pricing = #instant(null);
        broker_id = null;
      };
    });

    //Attempt to do an owner transfer
    let soulbound_owner_transfer = await a_wallet.try_owner_transfer(canister_principal, "soulbound", #principal(canister_principal));

    //Helpful Debug Output
    /* D.print( "\n" #
            "fund_a_wallet: " # debug_show(fund_a_wallet) # "\n\n" #
            "stage_soulbound_nft: " # debug_show(stage_soulbound_nft) # "\n\n" #
            "mint_nft: " # debug_show(mint_nft) # "\n\n" #
            "send_tokens_to_canister: " # debug_show(send_tokens_to_canister) # "\n\n" #
            "block: " # debug_show(block) # "\n\n" #
            "set_time: " # debug_show(set_time) # "\n\n" #
            "start_auction_soulbound: " # debug_show(start_auction_soulbound) # "\n\n" #
            "soulbound_instant_transfer: " # debug_show(soulbound_instant_transfer) # "\n\n" #
            "soulbound_owner_transfer: " # debug_show(soulbound_owner_transfer) # "\n\n"
        );  */

    let suite = S.suite(
      "test soulbound NFT",
      [
        S.test(
          "NFT staged succesfully",
          switch (stage_soulbound_nft) {
            case ((#ok("soulbound"), #ok(_), #ok(_), #ok(_))) {
              "staging succesful";
            };
            case (_) { "wrong action: " # debug_show (stage_soulbound_nft) };
          },
          M.equals<Text>(T.text("staging succesful")),
        ),
        S.test(
          "NFT minted succesfully",
          switch (mint_nft) {
            case (#ok("soulbound")) { "mint succesful" };
            case (_) { "wrong action: " # debug_show (mint_nft) };
          },
          M.equals<Text>(T.text("mint succesful")),
        ),
        S.test(
          "Tokens sent to canister",
          switch (send_tokens_to_canister) {
            case (#ok(_)) { "transfer succesful" };
            case (_) { "wrong action: " # debug_show (send_tokens_to_canister) };
          },
          M.equals<Text>(T.text("transfer succesful")),
        ),
        S.test(
          "Should fail to start auction on soulbound token",
          switch (start_auction_soulbound) {
            case (#err(err)) {
              if (err.error == #token_non_transferable) { "correct error" } else {
                "wrong error: " # debug_show (err.error);
              };
            };
            case (_) {
              "escrow should not have passed: " # debug_show (start_auction_soulbound);
            };
          },
          M.equals<Text>(T.text("correct error")),
        ),
        S.test(
          "Instant transfer should fail for soulbound token",
          switch (soulbound_instant_transfer) {
            case (#err(err)) {
              if (err.error == #token_non_transferable) { "correct error" } else {
                "wrong error: " # debug_show (err.error);
              };
            };
            case (_) {
              "escrow should not have passed: " # debug_show (soulbound_instant_transfer);
            };
          },
          M.equals<Text>(T.text("correct error")),
        ),
        S.test(
          "Owner transfer should fail for soulbound token",
          switch (soulbound_owner_transfer) {
            case (#err(err)) {
              if (err.error == #token_non_transferable) { "correct error" } else {
                "wrong error: " # debug_show (err.error);
              };
            };
            case (_) {
              "escrow should not have passed: " # debug_show (soulbound_owner_transfer);
            };
          },
          M.equals<Text>(T.text("correct error")),
        ),
      ],
    );

    S.run(suite);

    return #success;
  };

  public shared func testIcrc7Transfer() : async { #success; #fail : Text } {
    let this_principal = Principal.fromActor(this);

    let ledger_principal = dfx_ledger;

    //create and fund wallet
    let a_wallet = await TestWalletDef.test_wallet();
    let a_principal = Principal.fromActor(a_wallet);
    let b_wallet = await TestWalletDef.test_wallet();
    let b_principal = Principal.fromActor(b_wallet);
    let b_account = {
      owner = b_principal;
      subaccount = null;
    };

    let n_wallet = await TestWalletDef.test_wallet(); //node
    let n_principal = Principal.fromActor(n_wallet);
    let o_wallet = await TestWalletDef.test_wallet(); //originator
    let o_principal = Principal.fromActor(o_wallet);
    let net_wallet = await TestWalletDef.test_wallet(); //net

    let net_account = {
      owner = Principal.fromActor(net_wallet);
      subaccount = ?Blob.fromArray(Royalties.get_network_royalty_account(Principal.fromActor(dfx), null));
    };

    let fund_a_wallet = await dfx.icrc1_transfer({
      to = { owner = Principal.fromActor(a_wallet); subaccount = null };
      fee = ?200_000;
      memo = null;
      from_subaccount = null;
      created_at_time = null;
      amount = 100 * 10 ** 8;
    });
    D.print("funding result end");
    D.print(debug_show (fund_a_wallet));

    //create canister
    let newPrincipal = await g_canister_factory.create({
      owner = Principal.fromActor(this);
      storage_space = null;
    });
    let icrc7_canister : ICRC7Types.Service = actor (Principal.toText(newPrincipal));
    let canister : Types.Service = actor (Principal.toText(newPrincipal));
    let canister_principal = Principal.fromActor(canister);
    D.print("Here 1");

    let standardStage_collection = await utils.buildCollection(
      canister,
      Principal.fromActor(canister),
      Principal.fromActor(n_wallet),
      Principal.fromActor(this),
      2048000,
      true,
      dfxspec,
    );
    let updateNetwork = canister.collection_update_nft_origyn(#UpdateNetwork(?Principal.fromActor(net_wallet)));
    let timeset = await canister.__set_time_mode(#test);
    let startTime = Time.now();
    let atime = await canister.__advance_time(startTime);

    //stage unminted and minted NFTs
    let stage_1_nft = await utils.buildStandardNFT("1", canister, this_principal, 1024, false, Principal.fromActor(this));
    let mint_nft = await canister.mint_nft_origyn("1", #principal(this_principal));
    D.print("Here 2");

    //reset time to time now
    let set_time = await canister.__advance_time(get_time());

    D.print("Here 3");
    let token_id = await canister.get_token_id_as_nat("1");

    D.print("Here 4");
    let fee_to_pay : ?Nat = await icrc7_canister.icrc7_transfer_fee(token_id);

    D.print("token id = " # debug_show (token_id) # "fee_to_pay = " # debug_show (fee_to_pay));

    let #ok(#fee_deposit_info(sellerFeeDepositAccount)) = await canister.sale_info_nft_origyn(#fee_deposit_info(? #account { owner = Principal.fromActor(this); sub_account = null })) else {
      D.print("failed to get sellerFeeDepositAccount");
      return #fail("failed to get sellerFeeDepositAccount");
    };
    D.print("icrc2_approve_request = " # debug_show ({ fee = ?200_000; memo = null; from_subaccount = null; created_at_time = null; amount = 2 * Option.get(fee_to_pay, 0) + 200_000; expected_allowance = null; expires_at = null; spender = { owner = Principal.fromActor(icrc7_canister); subaccount = null } }));

    let icrc2_approve_response = await dfx.icrc2_approve({
      fee = ?200_000;
      memo = null;
      from_subaccount = null;
      created_at_time = null;
      amount = Option.get(fee_to_pay, 0) + 200_000;
      expected_allowance = null;
      expires_at = null;
      spender = {
        owner = Principal.fromActor(icrc7_canister);
        subaccount = null;
      };
    });

    D.print("icrc2_approve_response = " # debug_show (icrc2_approve_response));

    D.print("icrc2_allowance_query = " # debug_show ({ account = { owner = this_principal; subaccount = null }; spender = { owner = Principal.fromActor(icrc7_canister); subaccount = null } }));
    let icrc2_allowance_response = await dfx.icrc2_allowance({
      account = {
        owner = this_principal;
        subaccount = null;
      };
      spender = {
        owner = Principal.fromActor(icrc7_canister);
        subaccount = null;
      };
    });
    D.print("icrc2_allowance_response = " # debug_show (icrc2_allowance_response));

    let owner_of = await icrc7_canister.icrc7_owner_of([token_id]);
    D.print("owner_of = " # debug_show (owner_of));

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
    let this_balance = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(this);
      subaccount = null;
    });
    let net_balance = await dfx.icrc1_balance_of(net_account);

    let fee_wallet_balance = await dfx.icrc1_balance_of({
      owner = sellerFeeDepositAccount.account.principal;
      subaccount = ?sellerFeeDepositAccount.account.sub_account;
    });

    let transfer_ret : ICRC7Types.TransferResult = await icrc7_canister.icrc7_transfer([{
      from_subaccount = null;
      to = b_account;
      token_id = token_id;
      memo = null;
      created_at_time = null;
    }]);
    D.print("transfer_ret = " # debug_show (transfer_ret));

    let owner_of2 = await icrc7_canister.icrc7_owner_of([token_id]);
    D.print("owner_of2 = " # debug_show (owner_of2));

    let fake_wallet66 = await TestWalletDef.test_wallet();
    let fake_wallet67 = await TestWalletDef.test_wallet();
    let fake_wallet78 = await TestWalletDef.test_wallet();
    let fake_wallet69 = await TestWalletDef.test_wallet();
    let fake_wallet79 = await TestWalletDef.test_wallet();
    let fake_wallet697 = await TestWalletDef.test_wallet();
    let fake_wallet797 = await TestWalletDef.test_wallet();

    let a_balance_after = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(a_wallet);
      subaccount = null;
    });
    let b_balance_after = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(b_wallet);
      subaccount = null;
    });
    let n_balance_after = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(n_wallet);
      subaccount = null;
    });
    let o_balance_after = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(o_wallet);
      subaccount = null;
    });
    let canister_balance_after = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(canister);
      subaccount = null;
    });
    let this_balance_after = await dfx.icrc1_balance_of({
      owner = Principal.fromActor(this);
      subaccount = null;
    });

    let net_balance_after = await dfx.icrc1_balance_of(net_account);

    let fee_wallet_balance_after = await dfx.icrc1_balance_of({
      owner = sellerFeeDepositAccount.account.principal;
      subaccount = ?sellerFeeDepositAccount.account.sub_account;
    });

    D.print("fee_wallet_balance5 = " # debug_show ((sellerFeeDepositAccount.account, fee_wallet_balance, fee_wallet_balance_after)));
    D.print("a wallet " # debug_show ((Principal.fromActor(a_wallet), a_balance, a_balance_after)));
    D.print("b wallet " # debug_show ((Principal.fromActor(b_wallet), b_balance, b_balance_after)));
    D.print("n wallet " # debug_show ((Principal.fromActor(n_wallet), n_balance, n_balance_after)));
    D.print("o wallet " # debug_show ((Principal.fromActor(o_wallet), o_balance, o_balance_after)));
    D.print("net wallet " # debug_show ((Principal.fromActor(net_wallet), net_balance, net_balance_after)));
    D.print("canister wallet " # debug_show ((Principal.fromActor(canister), canister_balance, canister_balance_after)));
    D.print("this wallet " # debug_show ((Principal.fromActor(this), this_balance, this_balance_after)));

    return #success;
  };

};
