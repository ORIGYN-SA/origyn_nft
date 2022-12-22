import AccountIdentifier "mo:principalmo/AccountIdentifier";
import C "mo:matchers/Canister";
import Conversion "mo:candy_0_1_10/conversion";
import DFXTypes "../origyn_nft_reference/dfxtypes";
import D "mo:base/Debug";
import Blob "mo:base/Blob";
import Int "mo:base/Int";
import M "mo:matchers/Matchers";
import NFTUtils "../origyn_nft_reference/utils";
import Metadata "../origyn_nft_reference/metadata";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Properties "mo:candy_0_1_10/properties";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";
import TestWalletDef "test_wallet";
import Time "mo:base/Time";
import Types "../origyn_nft_reference/types";
import utils "test_utils";
//import Instant "test_runner_instant_transfer";

// ttps://m7sm4-2iaaa-aaaab-qabra-cai.raw.ic0.app/?tag=1526457217 will provide a facility to convert 
// a account hash to an account id
// ie dfx canister --network ic call mexqz-aqaaa-aaaab-qabtq-cai say '(principal "r7inp-6aaaa-aaaaa-aaabq-cai", blob "20\8F\6F\7F\9B\0D\B3\29\36\AA\8B\F4\78\38\E8\B8\15\37\30\F7\3D\03\99\EA\BB\68\98\11\08\64\90\61")'


shared (deployer) actor class test_runner(dfx_ledger: Principal, dfx_ledger2: Principal) = this {

    let debug_channel = {
        throws = true;
        withdraw_detail = true;
    };

    D.print("have ledger values are " # debug_show(dfx_ledger,dfx_ledger2));

    let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
    
    let dfx2 : DFXTypes.Service = actor(Principal.toText(dfx_ledger2));
            

    private type canister_factory = actor {
        create : (Principal) -> async Principal;
    };

    let it = C.Tester({ batchSize = 8 });

    
    private var DAY_LENGTH = 60 * 60 * 24 * 10 ** 9;
    private var dip20_fee = 200_000;

    private func get_time() : Int{
        return Time.now();
    };

        private type canister_factory_actor = actor {
        create : ({owner: Principal; storage_space: ?Nat}) -> async Principal;
    };
    private type storage_factory_actor = actor {
        create : ({owner: Principal; storage_space: ?Nat}) -> async Principal;
    };

    private var g_canister_factory : canister_factory_actor = actor(Principal.toText(Principal.fromBlob("\04")));
    private var g_storage_factory: storage_factory_actor = actor(Principal.toText(Principal.fromBlob("\04")));

    

    public shared func test(canister_factory : Principal, storage_factory: Principal) : async {#success; #fail : Text} {
        
        //let Instant_Test = await Instant.test_runner_instant_transfer();

        g_canister_factory := actor(Principal.toText(canister_factory));
        g_storage_factory := actor(Principal.toText(storage_factory));

        let suite = S.suite("test nft", [
            
            S.test("testAuction", switch(await testAuction()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testDeposits", switch(await testDeposit()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testStandardLedger", switch(await testStandardLedger()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testMarketTransfer", switch(await testMarketTransfer()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testOwnerTransfer", switch(await testOwnerTransfer()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testOffer", switch(await testOffers()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testRoyalties", switch(await testRoyalties()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
                      
            ]);
        S.run(suite);

        return #success;
    };

    public shared func testDeposit() : async {#success; #fail : Text} {
        D.print("running testDeposit");


        D.print("making wallets");

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        let timeset = await canister.__set_time_mode(#test);
        let startTime = Time.now();
        let atime = await canister.__advance_time(startTime);

        D.print("calling stage");

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false);
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false);
        let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false);
        
        //mint 2
        let mint_attempt = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this)));
        let mint_attempt2 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));
        
        D.print("starting sale");
        let sale_start = await canister.market_transfer_nft_origyn({token_id = "2";
            sales_config = {
                escrow_receipt = null;
                broker_id = null;
                pricing = #auction{
                    reserve = null;
                    token = #ic({
                      canister = dfx_ledger;
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "OGY";
                      fee = 200000;
                    });
                    buy_now = ?(500 * 10 ** 8);//nyi
                    start_price = (100 * 10 ** 8);
                    start_date = 0;
                    ending = #date(startTime + DAY_LENGTH);
                    min_increase = #amount(10*10**8);
                    allow_list = null;
                };
            }; } );


        
        
       
        D.print("funding");
        //funding
        D.print("funding");
        //funding
        let funding_result = await dfx.transfer({
            to =  Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null)));
            fee = {e8s = 200_000};
            memo = 1;
            from_subaccount = null;
            created_at_time = ?{timestamp_nanos = Nat64.fromNat(Int.abs(Time.now()))};
            amount = {e8s = 100 * 10 ** 8};});

        D.print("funding result " # debug_show(funding_result));
        let funding_result2 = await dfx.transfer({
            to =  Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(b_wallet), null)));
            fee = {e8s = 200_000};
            memo = 1;
            from_subaccount = null;
            created_at_time = ?{timestamp_nanos = Nat64.fromNat(Int.abs(Time.now()))};
            amount = {e8s = 100 * 10 ** 8};});


        D.print("funding result 2 " # debug_show(funding_result2));

        let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_payment(Principal.fromActor(dfx), (4 * 10 ** 8) + 800000, Principal.fromActor(canister));
        //let a_wallet_send_tokens_to_b = await a_wallet.send_ledger_payment(Principal.fromActor(dfx), 1 * 10 ** 8, Principal.fromActor(canister));
        
        let b_wallet_send_tokens_to_canister = await b_wallet.send_ledger_payment(Principal.fromActor(dfx), (2 * 10 ** 8) + 400000, Principal.fromActor(canister));
        //let b_wallet_send_tokens_to_canister2 = await a_wallet.send_ledger_payment(Principal.fromActor(dfx), 1 * 10 ** 8, Principal.fromActor(canister));
        
        D.print("Done funding");
        //send an escrow locked until a certain lock time

        //escrow for a general nft with to owner of nft
        let lockedEscrow_specific_no_sale = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, null, ?(startTime + DAY_LENGTH));
        debug{ if(debug_channel.withdraw_detail){D.print("lockedEscrow_specific_no_sale"  # debug_show(lockedEscrow_specific_no_sale))}};


        //escrow for a general nft with no nfts
        let lockedEscrow_specific_sale = await a_wallet.try_escrow_general_staged(Principal.fromActor(b_wallet), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, null, ?(startTime + DAY_LENGTH));
        debug{ if(debug_channel.withdraw_detail){D.print("lockedEscrow_specific_sale"  # debug_show(lockedEscrow_specific_sale))}};


        //escrow for a specific nft with no sale running
        let lockedEscrow_general_no_sale = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx),null ,  1 * 10 ** 8, "3", null, null, ?(startTime + DAY_LENGTH));
         debug{ if(debug_channel.withdraw_detail){D.print("lockedEscrow_general_no_sale"  # debug_show(lockedEscrow_general_no_sale))}};


        //escrow for a specific nft with sale running
        let lockedEscrow_general_sale = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx),null,  1 * 10 ** 8, "2", null, null, ?(startTime + DAY_LENGTH));
        debug{ if(debug_channel.withdraw_detail){D.print("lockedEscrow_general_sale"  # debug_show(lockedEscrow_general_sale))}};


        let balances = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

         D.print("did escrows work" # debug_show(
            lockedEscrow_specific_no_sale,
        lockedEscrow_specific_sale,
        lockedEscrow_general_no_sale,
        lockedEscrow_general_sale,
        balances)); 

        //try to withdraw

        D.print("trying withdrawls");

        let withdraw_before_lock_1 = await a_wallet.try_escrow_withdraw(
            Principal.fromActor(canister), 
            Principal.fromActor(a_wallet),
            Principal.fromActor(dfx),
            Principal.fromActor(canister),
            "",
            (1 * 10 ** 8) ,
            null
            );

        debug{ if(debug_channel.withdraw_detail){D.print("withdraw_before_lock_1"  # debug_show(withdraw_before_lock_1))}};

        let withdraw_before_lock_2 = await a_wallet.try_escrow_withdraw(
            Principal.fromActor(canister), 
            Principal.fromActor(a_wallet),
            Principal.fromActor(dfx),
            Principal.fromActor(b_wallet),
            "",
            (1 * 10 ** 8) ,
            null
            );

        debug{ if(debug_channel.withdraw_detail){D.print("withdraw_before_lock_2"  # debug_show(withdraw_before_lock_2))}};


        let withdraw_before_lock_3 = await a_wallet.try_escrow_withdraw(
            Principal.fromActor(canister), 
            Principal.fromActor(a_wallet),
            Principal.fromActor(dfx),
            Principal.fromActor(this),
            "2",
            (1 * 10 ** 8) ,
            null
            );

        debug{ if(debug_channel.withdraw_detail){D.print("withdraw_before_lock_3"  # debug_show(withdraw_before_lock_3))}};


        let withdraw_before_lock_4 = await a_wallet.try_escrow_withdraw(
            Principal.fromActor(canister), 
            Principal.fromActor(a_wallet),
            Principal.fromActor(dfx),
            Principal.fromActor(this),
            "3",
            (1 * 10 ** 8) ,
            null
        );

        debug{ if(debug_channel.withdraw_detail){D.print("withdraw_before_lock_4"  # debug_show(withdraw_before_lock_4))}};


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
            (1 * 10 ** 8) ,
            null
            );
        debug{ if(debug_channel.withdraw_detail){D.print("withdraw_after_lock_1"  # debug_show(withdraw_after_lock_1))}};


        let withdraw_after_lock_2 = await a_wallet.try_escrow_withdraw(
            Principal.fromActor(canister), 
            Principal.fromActor(a_wallet),
            Principal.fromActor(dfx),
            Principal.fromActor(b_wallet),
            "",
            (1 * 10 ** 8) ,
            null
            );

            debug{ if(debug_channel.withdraw_detail){D.print("withdraw_after_lock_2"  # debug_show(withdraw_after_lock_2))}};


        let withdraw_after_lock_3 = await a_wallet.try_escrow_withdraw(
            Principal.fromActor(canister), 
            Principal.fromActor(a_wallet),
            Principal.fromActor(dfx),
            Principal.fromActor(this),
            "2",
            (1 * 10 ** 8) ,
            null
            );

        debug{ if(debug_channel.withdraw_detail){D.print("withdraw_after_lock_3"  # debug_show(withdraw_after_lock_3))}};


        let withdraw_after_lock_4 = await a_wallet.try_escrow_withdraw(
            Principal.fromActor(canister), 
            Principal.fromActor(a_wallet),
            Principal.fromActor(dfx),
            Principal.fromActor(this),
            "3",
            (1 * 10 ** 8) ,
            null
        );

        debug{ if(debug_channel.withdraw_detail){D.print("withdraw_after_lock_4"  # debug_show(withdraw_after_lock_4))}};


         /* D.print("second withdraw results" # debug_show(
            withdraw_after_lock_1,
        withdraw_after_lock_2,
        withdraw_after_lock_3,
        withdraw_after_lock_4)); */

        //test balances

        let to = AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null));
         
        let a_wallet_balance = await dfx.account_balance({account= Blob.fromArray(to)});

        let suite = S.suite("test locked deposit", [

            S.test("fail if witdraw locked for general owner", switch(withdraw_before_lock_1){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 3008){ //since the requestor isnt the owner and this isnt minted we wont reveal it is a real token
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //NFT-228
            S.test("fail if witdraw locked for non owner", switch(withdraw_before_lock_2){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 3008){ //since the requestor isnt the owner and this isnt minted we wont reveal it is a real token
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //NFT-228
             S.test("fail if witdraw locked for specific with sale", switch(withdraw_before_lock_3){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 3008){ 
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //NFT-228
             S.test("fail if witdraw locked for specific with no sale", switch(withdraw_before_lock_4){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 3008){ //since the requestor isnt the owner and this isnt minted we wont reveal it is a real token
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //NFT-228
            S.test("pass withdraw for general owner if past date", switch(withdraw_after_lock_1){case(#ok(res)){"expected success"};case(#err(err)){
                
                    "wrong error " # debug_show(err);
                };}, M.equals<Text>(T.text("expected success"))), //NFT-228
            S.test("pass withdraw for general non-owner if past date", switch(withdraw_after_lock_2){case(#ok(res)){"expected success"};case(#err(err)){
                
                    "wrong error " # debug_show(err);
                };}, M.equals<Text>(T.text("expected success"))), //NFT-228
            S.test("pass withdraw for specific if sale over", switch(withdraw_after_lock_3){case(#ok(res)){"expected success"};case(#err(err)){
                
                    "wrong error " # debug_show(err);
                };}, M.equals<Text>(T.text("expected success"))), //NFT-228
            S.test("pass withdraw for specific if no sale", switch(withdraw_after_lock_4){case(#ok(res)){"expected success"};case(#err(err)){
                
                    "wrong error " # debug_show(err);
                };}, M.equals<Text>(T.text("expected success"))), //NFT-228
            
            
        ]);

        S.run(suite);

        return #success;
    };
    
    
    public shared func testMarketTransfer() : async {#success; #fail : Text} {
        D.print("running testMarketTransfer");
        
        

        D.print("making wallets");

        let a_wallet = await TestWalletDef.test_wallet();

        D.print("making factory");

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        D.print("have canister");

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        D.print("calling stage");

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false);
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false);
        let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false);

        D.print("finished stage");
        D.print(debug_show(standardStage.0));

        //MKT0015 try the sale before there is an escrow
        let blind_market_fail = await canister.market_transfer_nft_origyn({
            token_id = "1";
            sales_config = 
              {
                  escrow_receipt = ?{
                    seller = #principal(Principal.fromActor(canister));
                    buyer = #principal(Principal.fromActor(a_wallet));
                    token_id = "1";
                    token = #ic({
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    amount = 100_000_000;
                  };
                  pricing = #instant;
                  broker_id = null;
              };
            
        });

        D.print("blind market fail");
        D.print(debug_show(blind_market_fail));
        

        //MKT0008 Should fail
        D.print("calling try_sale_staged");
        let a_wallet_try_staged_market = await a_wallet.try_sale_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx));

        D.print(debug_show(a_wallet_try_staged_market));


        D.print("calling try_escrow_specific_staged");
        //ESC0003. try to escrow for the specific item; should fail
        let a_wallet_try_escrow_specific_staged = await a_wallet.try_escrow_specific_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), ?1,  1 * 10 ** 8, "1", null, null, null);

        D.print(debug_show(a_wallet_try_escrow_specific_staged));

        //ESC0002. try to escrow for the canister; should succeed
        //fund a_wallet
        let funding_result = await dfx.transfer({
            to =  Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null)));
            fee = {e8s = 200_000};
            memo = 1;
            from_subaccount = null;
            created_at_time = null;
            amount = {e8s = 1000 * 10 ** 8};});
        D.print("funding result");
        D.print(debug_show(funding_result));

        //sent an escrow for a dip20 deposit that doesn't exist
        D.print("sending an escrow with no deposit");
        let a_wallet_try_escrow_general_fake = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), ?34, 1 * 10 ** 8, null, null);


        //send a payment to the ledger
        D.print("sending tokens to canisters");
        let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_payment(Principal.fromActor(dfx), (1 * 10 ** 8) + 200000, Principal.fromActor(canister));
        
        D.print("send to canister");
        D.print(debug_show(a_wallet_send_tokens_to_canister));

        let block = switch(a_wallet_send_tokens_to_canister){
            case(#ok(ablock)){
                ablock;
            };
            case(#err(other)){
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
        D.print(debug_show(a_wallet_try_escrow_general_staged));

        //ESC0005 should fail if you try to calim a deposit a second time
        let a_wallet_try_escrow_general_staged_retry = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, null, null);

        //check balance and make sure we see the escrow BAL0002
        let a_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

        D.print("thebalance");
        D.print(debug_show(a_balance));

        //MKT0007, MKT0014
       D.print("blind market");
        let blind_market = await canister.market_transfer_nft_origyn({
            token_id = "1";
            sales_config = 
              {
                  escrow_receipt = ?{
                    seller = #principal(Principal.fromActor(canister));
                    buyer = #principal(Principal.fromActor(a_wallet));
                    token_id = "";
                    token = #ic({
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    amount = 100_000_000;
                  };
                  pricing = #instant;
                  broker_id = null;
              };
            
        });

       D.print(debug_show(blind_market));

        //MKT0014 todo: check the transaction record and confirm the gensis reocrd

        //BAL0005
        let a_balance2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

        //BAL0003
        let canister_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(canister)));

        //MKT0013, MKT0011 this item should be minted now
        let test_metadata = await canister.nft_origyn("1");
        D.print("This thing should have been minted");
        D.print(debug_show(test_metadata));
        switch(test_metadata){
            case(#ok(val)){
                D.print(debug_show(Metadata.is_minted(val.metadata)));
            };
            case(_){};
        };

        //MINT0026 shold fail because the purchase of a staged item should mint it
        let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(a_wallet)));
        D.print("This thing should have not been minted");
        D.print(debug_show(mint_attempt));

        //ESC0009
        let blind_market2 = await canister.market_transfer_nft_origyn({
            token_id = "2";
            sales_config = 
              {
                  escrow_receipt = ?{
                    seller = #principal(Principal.fromActor(canister));
                    buyer = #principal(Principal.fromActor(a_wallet));
                    token_id = "";
                    token = #ic({
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    amount = 100_000_000;
                  };
                  pricing = #instant;
                  broker_id = null;
              };
            
        });

        D.print("This thing should have not been minted either");
        D.print(debug_show(blind_market2));

        //mint the third item to test a specific sale
        let mint_attempt3 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));

        D.print("mint attempt 3");
        D.print(debug_show(mint_attempt3));

        //creae an new wallet for testing
        let b_wallet = await TestWalletDef.test_wallet();

        //give b_wallet some tokens
        let b_funding_result =await dfx.transfer({
            to =  Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(b_wallet), null)));
            fee = {e8s = 200_000};
            memo = 1;
            from_subaccount = null;
            created_at_time = null;
            amount = {e8s = 1000 * 10 ** 8};});
        D.print("funding result");
        D.print(debug_show(funding_result));

        //send a payment to the the new owner(this actor- after mint)
        D.print("sending tokens to canisters");
    
        let b_wallet_send_tokens_to_canister = await b_wallet.send_ledger_payment(Principal.fromActor(dfx), (1 * 10 ** 8) + 200000, Principal.fromActor(canister));
        
        D.print("send to canister");
        D.print(debug_show(b_wallet_send_tokens_to_canister));

        let b_block = switch(b_wallet_send_tokens_to_canister){
            case(#ok(ablock)){
                ablock;
            };
            case(#err(other)){
                D.print("ledger didnt work");
                return #fail("ledger didnt work");
            };
        };
        
        //make sure a user can't escrow for an owner that doesn't own NFT
        let b_wallet_try_escrow_wrong_owner = await b_wallet.try_escrow_specific_staged(Principal.fromActor(a_wallet), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "3", null, null, null);
        D.print("b_wallet_try_escrow_wrong_owner: " # debug_show(b_wallet_try_escrow_wrong_owner));

        //ESC0002
        D.print("Sending real escrow now");
        let b_wallet_try_escrow_specific_staged = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "3", null, null, null);

        //
        D.print("try escrow specific stage");
        D.print(debug_show(b_wallet_try_escrow_specific_staged));


        //MKT0010
        D.print("apecific market");
        let specific_market = await canister.market_transfer_nft_origyn({
            token_id = "3";
            sales_config = 
              {
                  escrow_receipt = ?{
                    seller = #principal(Principal.fromActor(this));
                    buyer = #principal(Principal.fromActor(b_wallet));
                    token_id = "3";
                    token = #ic({
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    amount = 100_000_000;
                  };
                  pricing = #instant;
                  broker_id = null;
              };
            
        });

        D.print(debug_show(specific_market));

        //test balances

        let suite = S.suite("test market Nft", [

            S.test("fail if no escrow exists for general staged sale", switch(blind_market_fail){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000){ //since the requestor isnt the owner and this isnt minted we wont reveal it is a real token
                    "correct number"
                } else{
                    "wrong error " # debug_show(err.number);
                }};}, M.equals<Text>(T.text("correct number"))), //MKT0015
            S.test("fail if non owner trys to sell", switch(a_wallet_try_staged_market){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 2000){ //since the requestor isnt the owner and this isnt minted we wont reveal it is a real token
                    "correct number"
                } else{
                    "wrong error " # debug_show(err.number);
                }};}, M.equals<Text>(T.text("correct number"))), //MKT0008
            S.test("owner can sell staged NFT - produces sale_id", switch(blind_market){case(#ok(res)){
               D.print("found blind market response");
               D.print(debug_show(res));
                if(res.index == 0){
                    "found genesis record id"
                } else {
                    "no sales id "
                }};case(#err(err)){"unexpected error: " # err.flag_point # debug_show(err)};}, M.equals<Text>(T.text("found genesis record id"))), //MKT0007, MKT0014
             S.test("fail if escrow is double processed", switch(a_wallet_try_escrow_general_staged_retry){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number ==3003){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err.number);
                }};}, M.equals<Text>(T.text("correct number"))), //ESC0005
            S.test("fail if mint is called on a minted item", switch(mint_attempt){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 10){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //MINT0026

            S.test("item is minted now", switch(test_metadata){case(#ok(res)){
                if(Metadata.is_minted(res.metadata) == true){
                    "was minted"
                } else {
                    "was not minted"
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("was minted"))), //MKT0013
            S.test("item is owned by correct owner after minting", switch(test_metadata){case(#ok(res)){
                if(Types.account_eq(switch(Metadata.get_nft_owner(res.metadata)){
                    case(#err(err)){#account_id("invalid")};
                    case(#ok(val)){D.print(debug_show(val));val};
                }, #principal(Principal.fromActor(a_wallet)) ) == true){
                    "was transfered"
                } else {
                    D.print("awallet");
                    D.print(debug_show(Principal.fromActor(a_wallet)));
                    "was not transfered"
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("was transfered"))), //MKT0011

            S.test("fail if escrow already spent", switch(blind_market2){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number ==3000){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err.number);
                }};}, M.equals<Text>(T.text("correct number"))), //ESC0009
            S.test("fail if escrowing for a specific item and it is only staged", switch(a_wallet_try_escrow_specific_staged){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number ==4){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err.number);
                }};}, M.equals<Text>(T.text("correct number"))), //ESC0003
            S.test("fail if escrowing for a non existant deposit", switch(a_wallet_try_escrow_general_fake){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3003){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err.number);
                }};}, M.equals<Text>(T.text("correct number"))), //ESC0006
            S.test("fail if escrowing for an existing deposit but fake amount", switch(a_wallet_try_escrow_general_fake_amount){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3003){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err.number);
                }};}, M.equals<Text>(T.text("correct number"))), //ESC0011
            S.test("can escrow for general unminted item", switch(a_wallet_try_escrow_general_staged){case(#ok(res)){
                D.print("an amount for escrow");
                D.print(debug_show(res.receipt));
                if(res.receipt.amount == 1*10**8){
                    "was escrowed"
                } else {
                    "was not escrowed"
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("was escrowed"))), //ESC0002

                
            S.test("escrow deposit transaction", switch(a_wallet_try_escrow_general_staged){case(#ok(res)){
                
                switch(res.transaction.txn_type){
                    case(#escrow_deposit(details)){
                        if(Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and
                                Types.account_eq(details.seller, #principal(Principal.fromActor(canister))) and
                                details.amount == ((1*10**8)) and
                                details.token_id == "" and
                                Types.token_eq(details.token, #ic({
                                    canister = (Principal.fromActor(dfx));
                                    standard = #Ledger;
                                    decimals = 8;
                                    symbol = "LDG";
                                    fee = 200000;}))){
                                    "correct response";
                            } else {
                                "details didnt match" # debug_show(details);
                            };
                    };
                    case(_){
                        "bad history sale";
                    };
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //NFT-72
            S.test("can't escrow for wrong NFT owner", switch(b_wallet_try_escrow_wrong_owner){case(#err(err)){
                if(err.number == 3002){
                    "correct number"
                } else {
                    "wrong error " # debug_show(err.number);
                }};case(#ok(res)){"unexpected success: " # debug_show(res)};},
                M.equals<Text>(T.text("correct number"))),
             S.test("can escrow for specific item", switch(b_wallet_try_escrow_specific_staged){case(#ok(res)){
                if(res.receipt.amount == 1*10**8){
                    "was escrowed"
                } else {
                    "was not escrowed"
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("was escrowed"))), //ESC0001
            S.test("owner can sell specific NFT - produces sale_id", switch(specific_market){case(#ok(res)){
                if(res.token_id == "3"){
                    "found tx record"
                } else {
                    D.print(debug_show(res));
                    "no sales id "
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found tx record"))), //MKT0010
            S.test("escrow balance is shown", switch(a_balance){case(#ok(res)){
                D.print(debug_show(res));
                D.print(debug_show(#principal(Principal.fromActor(canister))));
                D.print(debug_show(#principal(Principal.fromActor(a_wallet))));
                D.print(debug_show(Principal.fromActor(dfx)));
                if(Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(canister))) and
                    Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet))) and
                    res.escrow[0].token_id == "" and
                    Types.token_eq(res.escrow[0].token, #ic({
                        canister = Principal.fromActor(dfx);
                        standard =  #Ledger;
                        decimals = 8;
                        symbol = "LDG";
                        fee = 200000;
                        }))
                ){
                    "found escrow record"
                } else {
                    D.print(debug_show(res));
                    "didnt find record "
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found escrow record"))), //BAL0001
            S.test("escrow balance is removed", switch(a_balance2){case(#ok(res)){
                 D.print(debug_show(res));
                if(res.escrow.size() == 0 ){
                    "no escrow record"
                } else {
                    D.print(debug_show(res));
                    "found record  "
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("no escrow record"))), //BAL0005
            S.test("sale balance is shown", switch(a_balance){case(#ok(res)){
                D.print(debug_show(res));
                D.print(debug_show(#principal(Principal.fromActor(canister))));
                D.print(debug_show(#principal(Principal.fromActor(a_wallet))));
                D.print(debug_show(Principal.fromActor(dfx)));
                if(Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet))) and
                    Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(canister))) and
                    res.escrow[0].token_id == "" and
                    Types.token_eq(res.escrow[0].token, #ic({
                        canister = Principal.fromActor(dfx);
                        standard =  #Ledger;
                        decimals = 8;
                        symbol = "LDG";
                        fee = 200000;
                        })) and
                    res.escrow[0].amount == 1*10**8
                ){
                    "found sale record"
                } else {
                    D.print(debug_show(res));
                    "didnt find record "
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found sale record"))), //BAL0003
            
        ]);

        S.run(suite);

        return #success;
    };


    public shared func testRoyalties() : async {#success; #fail : Text} {
        D.print("running testRoyalties");
        D.print("making wallets");

        let a_wallet = await TestWalletDef.test_wallet(); //purchaser
        let b_wallet = await TestWalletDef.test_wallet(); //broker
        let n_wallet = await TestWalletDef.test_wallet(); //node
        let o_wallet = await TestWalletDef.test_wallet(); //originator
        let net_wallet = await TestWalletDef.test_wallet(); //net

        D.print("making factory");

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        D.print("have canister");

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));
        let standardStage_collection = await utils.buildCollection( 
            canister, 
            Principal.fromActor(canister), 
            Principal.fromActor(n_wallet),
            Principal.fromActor(o_wallet),
            2048000);

        let updateNetwork = canister.collection_update_nft_origyn(#UpdateNetwork(?Principal.fromActor(net_wallet)));
        

        D.print("calling stage");

    
        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false);
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false);
        let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false);

        let mint_attempt3 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this)));
        let mint_attempt4 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));

        D.print("finished stage");
        D.print(debug_show(standardStage.0));

        //fund a_wallet
        let funding_result = await dfx.transfer({
            to =  Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null)));
            fee = {e8s = 200_000};
            memo = 1;
            from_subaccount = null;
            created_at_time = null;
            amount = {e8s = 1000 * 10 ** 8};});

        let funding_result2 = await dfx.transfer({
            to =  Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(b_wallet), null)));
            fee = {e8s = 200_000};
            memo = 1;
            from_subaccount = null;
            created_at_time = null;
            amount = {e8s = 1000 * 10 ** 8};});

        //send a payment to the ledger
        D.print("sending tokens to canisters");
        let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_payment(Principal.fromActor(dfx), (5 * 10 ** 8) + 400000, Principal.fromActor(canister));
        
        D.print("send to canister");
        D.print(debug_show(a_wallet_send_tokens_to_canister));

        let block = switch(a_wallet_send_tokens_to_canister){
            case(#ok(ablock)){
                ablock;
            };
            case(#err(other)){
                D.print("ledger didnt work");
                return #fail("ledger didnt work");
            };
        };
        
        D.print("Sending real escrow now");
        let a_wallet_try_escrow_general_staged = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, null, null);

        D.print("try escrow genreal stage");
        D.print(debug_show(a_wallet_try_escrow_general_staged));

        let a_balance = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null))});
        let b_balance = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(b_wallet), null))});
        let n_balance = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(n_wallet), null))});
        let o_balance = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(o_wallet), null))});
        let canister_balance = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(canister), null))});
        let net_balance = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(net_wallet), null))});


        D.print("primary sale");
        let primary_sale = await canister.market_transfer_nft_origyn({
            token_id = "1";
            sales_config = 
              {
                  escrow_receipt = ?{
                    seller = #principal(Principal.fromActor(canister));
                    buyer = #principal(Principal.fromActor(a_wallet));
                    token_id = "";
                    token = #ic({
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    amount = 100_000_000;
                  };
                  pricing = #instant;
                  broker_id = ?Principal.fromActor(b_wallet);
              };
            
        });

       D.print(debug_show(primary_sale));

        //MKT0014 todo: check the transaction record and confirm the gensis reocrd

        //BAL0005
        let a_balance2 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null))});
        let b_balance2 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(b_wallet), null))});
        let n_balance2 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(n_wallet), null))});
        let o_balance2 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(o_wallet), null))});
        let canister_balance2 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(canister), null))});
        let net_balance2 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(net_wallet), null))});

        D.print("a wallet " # debug_show((a_balance, a_balance2)));
        D.print("b wallet " # debug_show((b_balance, b_balance2)));
        D.print("n wallet " # debug_show((n_balance, n_balance2)));
        D.print("o wallet " # debug_show((o_balance, o_balance2)));
        D.print("canister wallet " # debug_show((canister_balance, canister_balance2)));
        D.print("net wallet " # debug_show((net_balance, net_balance2)));

        let test_metadata = await canister.nft_origyn("1");

        D.print("Sending real escrow now");
        let a_wallet_try_escrow_specific_staged = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "2", null, null, null);


       
        //MKT0010
        D.print("secondary sale");
        let specific_market = await canister.market_transfer_nft_origyn({
            token_id = "2";
            sales_config = 
              {
                  escrow_receipt = ?{
                    seller = #principal(Principal.fromActor(this));
                    buyer = #principal(Principal.fromActor(a_wallet));
                    token_id = "2";
                    token = #ic({
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    amount = 100_000_000;
                  };
                  pricing = #instant;
                  broker_id = ?Principal.fromActor(b_wallet);
              };
            
        });

        D.print("secondary result" # debug_show(specific_market));

        
        let a_balance3 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null))});
        let b_balance3 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(b_wallet), null))});
        let n_balance3 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(n_wallet), null))});
        let o_balance3 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(o_wallet), null))});
        let canister_balance3 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(canister), null))});
        let net_balance3 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(net_wallet), null))});


        //withdraw sale
        //let #ok(b_withdraw) = b_balance2;
        //D.print(debug_show(b_withdraw));
        //let #principal(b_buyer) = b_withdraw.sales[0].buyer;

        D.print(debug_show(Principal.fromActor(b_wallet)));
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
        let start_auction_attempt_owner = await canister.market_transfer_nft_origyn({token_id = "3";
            sales_config = {
                escrow_receipt = null;
                broker_id = null;
                pricing = #auction{
                    reserve = ?(1 * 10 ** 8);
                    token = #ic({
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    buy_now = ?(500 * 10 ** 8);
                    start_price = (1 * 10 ** 8);
                    start_date = 0;
                    ending = #date(get_time() + DAY_LENGTH);
                    min_increase = #amount(10*10**8);
                    allow_list = null;
                };
            }; } );

            D.print("get sale id");
            let current_sales_id = switch(start_auction_attempt_owner){
                case(#ok(val)){
                    switch(val.txn_type){
                        case(#sale_opened(sale_data)){
                            sale_data.sale_id;
                        };
                        case(_){
                            D.print("Didn't find expected sale_opened");
                            return #fail("Didn't find expected sale_opened");
                        }
                    };
                
                };
                case(#err(item)){
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
            let a_wallet_try_bid_valid = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1*10**8, "3", current_sales_id, ?Principal.fromActor(b_wallet));
            D.print("a_wallet_try_bid_valid " # debug_show(a_wallet_try_bid_valid));

                //advance time
            let mode = canister.__set_time_mode(#test);
            let time_result = await canister.__advance_time(end_date + 1);
            D.print("new time");
            D.print(debug_show(time_result));

            //end auction
            let end_proper = await canister.sale_nft_origyn(#end_sale("3"));
            D.print("end proper");
            D.print(debug_show(end_proper));

            let a_balance5 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null))});
            let b_balance5 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(b_wallet), null))});
            let n_balance5 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(n_wallet), null))});
            let o_balance5 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(o_wallet), null))});
            let canister_balance5 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(canister), null))});
            let net_balance5 = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(net_wallet), null))});

        //test balances

        let suite = S.suite("test royalties", [

        
            S.test("fail if node does not get royalty", n_balance2.e8s, M.equals<Nat64>(T.nat64(7561446))), 
            S.test("fail if broker does not get royalty", b_balance2.e8s, M.equals<Nat64>(T.nat64(100005788000))), 
            S.test("fail if network does not get royalty", net_balance2.e8s, M.equals<Nat64>(T.nat64(299000))), 
            S.test("fail if node does not get second royalty", n_balance3.e8s, M.equals<Nat64>(T.nat64(9357446))), 
            S.test("fail if broker does not get second royalty", b_balance3.e8s, M.equals<Nat64>(T.nat64(100006586000))), 
            S.test("fail if network does not get second royalty", net_balance3.e8s, M.equals<Nat64>(T.nat64(598000))), 
            S.test("fail if originator does not get first royalty", o_balance3.e8s, M.equals<Nat64>(T.nat64(3126633))), 
            //S.test("fail if broker still has balance after withdraw", b_balance4.e8s, M.equals<Nat64>(T.nat64(6))), 
            S.test("fail if node does not get third royalty", n_balance5.e8s, M.equals<Nat64>(T.nat64(11153446))), 
            S.test("fail if broker does not get new royalty", b_balance5.e8s, M.equals<Nat64>(T.nat64(100007384000))), 
            S.test("fail if network does not get third royalty", net_balance5.e8s,  M.equals<Nat64>(T.nat64(897000))), 
            S.test("fail if originator does not get second royalty", o_balance5.e8s,  M.equals<Nat64>(T.nat64(6253266))), 
            

        ]);

        S.run(suite);

        return #success;
    };

    public shared func testOwnerTransfer() : async {#success; #fail : Text} {
        D.print("running testOwnerTransfer");

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        let c_wallet = await TestWalletDef.test_wallet();

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false);

        
        let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(a_wallet)));

        //TRX0004
        let trxattempt_fail = await c_wallet.try_owner_transfer(Principal.fromActor(canister), "1", #principal(Principal.fromActor(b_wallet)));

        //TRX0002
        let trxattempt = await a_wallet.try_owner_transfer(Principal.fromActor(canister), "1", #principal(Principal.fromActor(b_wallet)));

        let suite = S.suite("test staged Nft", [

            S.test("owner can transfer", switch(trxattempt){case(#ok(res)){
                switch(res.transaction.txn_type){
                    case(#owner_transfer(details)){
                        if(Types.account_eq(details.from, #principal(Principal.fromActor(a_wallet))) == false){
                            "from didnt match";
                        } else if(Types.account_eq(details.to, #principal(Principal.fromActor(b_wallet))) == false){
                            "to didnt match";
                        } else {
                            "correct response";
                        };
                    };
                    case(_){
                        "wrong tx type";
                    }
                };
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //TRX0002
            S.test("fail if transfering for an item you don't own", switch(trxattempt_fail){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 11){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //ESC0011
            
        ]);

        S.run(suite);

        return #success;
        
          

    };
    
    public shared func testAuction() : async {#success; #fail : Text} {
        D.print("running Auction");

        let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
        
        let dfx2 : DFXTypes.Service = actor(Principal.toText(dfx_ledger2));
        

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        
        let funding_result_a = await dfx.transfer({
            to =  Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null)));
            fee = {e8s = 200_000};
            memo = 1;
            from_subaccount = null;
            created_at_time = null;
            amount = {e8s = 1000 * 10 ** 8};});
            
            
        let funding_result_b =  await dfx.transfer({
            to =  Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(b_wallet), null)));
            fee = {e8s = 200_000};
            memo = 1;
            from_subaccount = null;
            created_at_time = null;
            amount = {e8s = 1000 * 10 ** 8};});

        let funding_result_b2 = await dfx2.transfer({
            to =  Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(b_wallet), null)));
            fee = {e8s = 200_000};
            memo = 1;
            from_subaccount = null;
            created_at_time = null;
            amount = {e8s = 1000 * 10 ** 8};});

        D.print("funding result b2 " # debug_show(funding_result_b2));

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        let mode = canister.__set_time_mode(#test);
        let atime = canister.__advance_time(Time.now());

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(this), 1024, false); //for auctioning a minted item
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(this), 1024, false); //for auctioning an unminted item

        D.print("Minting");
        let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(this))); //mint to the test account
        let mint_attempt2 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this))); //mint to the test account

        D.print("start auction fail");
        //non owner start auction should fail MKT0019
        let start_auction_attempt_fail = await a_wallet.try_start_auction(Principal.fromActor(canister), Principal.fromActor(dfx), "1", null);

        D.print("start auction owner");
        //start an auction by owner
        let start_auction_attempt_owner = await canister.market_transfer_nft_origyn({token_id = "1";
            sales_config = {
                escrow_receipt = null;
                broker_id = null;
                pricing = #auction{
                    reserve = ?(100 * 10 ** 8);
                    token = #ic({
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    buy_now = ?(500 * 10 ** 8);//nyi
                    start_price = (1 * 10 ** 8);
                    start_date = 0;
                    ending = #date(get_time() + DAY_LENGTH);
                    min_increase = #amount(10*10**8);
                    allow_list = null;
                };
            }; } );

        D.print("get sale id");
        let current_sales_id = switch(start_auction_attempt_owner){
            case(#ok(val)){
                switch(val.txn_type){
                    case(#sale_opened(sale_data)){
                        sale_data.sale_id;
                    };
                    case(_){
                        D.print("Didn't find expected sale_opened");
                        return #fail("Didn't find expected sale_opened");
                    }
                };
               
            };
            case(#err(item)){
                D.print("error with auction start");
                return #fail("error with auction start");
            };
        };

        let active_sale_info_1 = await canister.sale_info_nft_origyn(#active(null));

        D.print("starting again");
        //try starting again//should fail MKT0018
        let start_auction_attempt_owner_already_started = await canister.market_transfer_nft_origyn({token_id = "1";
            sales_config = {
                escrow_receipt = null;
                broker_id = null;
                pricing = #auction{
                    reserve = ?(100 * 10 ** 8);
                    token = #ic({
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    buy_now = ?(500 * 10 ** 8);
                    start_price = (1 * 10 ** 8);
                    start_date = 0;
                    ending = #date(get_time() + DAY_LENGTH);
                    min_increase = #amount(10*10**8);
                    allow_list = null;
                };
            }; } );

        //MKT0020 - try to transfer with an open auction
        let transfer_owner_after_auction = await canister.share_wallet_nft_origyn({token_id = "1"; from = #principal(Principal.fromActor(this)); to = #principal(Principal.fromActor(b_wallet))});

        //place escrow
        D.print("sending tokens to canisters");
        let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_payment(Principal.fromActor(dfx), (4 * 10 ** 8) + 800000, Principal.fromActor(canister));

        //balance should be 4 ICP + 800000

        let block = switch(a_wallet_send_tokens_to_canister){
            case(#ok(ablock)){
                ablock;
            };
            case(#err(other)){
                D.print("ledger didnt work" # debug_show(other));
                return #fail("ledger didnt work");
            };
        };

         D.print("trying deposit");
        //try to witdraw back 1 icp from deposit
        let a_wallet_try_deposit_refund = await a_wallet.try_deposit_refund(Principal.fromActor(canister),  Principal.fromActor(dfx), 1 * 10 ** 8, null);

        D.print("a_wallet_try_deposit_refund" # debug_show(a_wallet_try_deposit_refund));
        D.print("Sending real escrow now a wallet trye scrow");

        //claiming first escrow
        let a_wallet_try_escrow_general_staged = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "1", ?current_sales_id, null, null);

        D.print("should be done now");
        let a_balance_before_first = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        
        D.print("the balance before first is");
        D.print(debug_show(a_balance_before_first));

        //place a bid below start price

        let a_wallet_try_bid_below_start = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1*10**7 + 200000, "1", current_sales_id, null);
        //aboves should refund the bid
        //todo: bid should be refunded

        let a_balance_after_bad_bid = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        D.print("a balance " # debug_show(a_balance_after_bad_bid));


        D.print("Sending real escrow now 2");
        let a_wallet_try_escrow_general_staged2b = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 2 * 10 ** 8, "1", ?current_sales_id, null, null);
        //this should clear out the deposit account

        D.print("Sending real escrow now result 2" # debug_show(a_wallet_try_escrow_general_staged2b));

        let a_balance_after_bad_bid2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        D.print("a balance 2 " # debug_show(a_balance_after_bad_bid2));

        //try a bid in th wrong currency
        //place escrow
        D.print("sending tokens to canisters b");
        let b_wallet_send_tokens_to_canister = await b_wallet.send_ledger_payment(Principal.fromActor(dfx2), (200 * 10 ** 8) + 200000, Principal.fromActor(canister));

        let block2b = switch(b_wallet_send_tokens_to_canister){
            case(#ok(ablock)){
                ablock;
            };
            case(#err(other)){
                D.print("ledger didnt work");
                return #fail("ledger didnt work");
            };
        };

        D.print("Sending escrow for wrong currency escrow now b");
        let b_wallet_try_escrow_wrong_currency = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx2), null, 1 * 10 ** 8, "1", ?current_sales_id, null, null);

        
        //place a bid wiht wrong asset MKT0023
        let b_wallet_try_bid_wrong_asset = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx2), 1*10**8, "1", current_sales_id, null);

        //place a bid on token that isn't for sale MKT0024
        let a_wallet_try_bid_wrong_token_id_not_exist = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1*10**8, "2", current_sales_id, null);

        //try starting again//should fail MKT0018
        let end_date = get_time() + DAY_LENGTH;
        D.print("end date is ");
        D.print(debug_show(end_date));

        //todo: write test
        let start_auction_attempt_owner_already_started_b = await canister.market_transfer_nft_origyn({token_id = "2";
            sales_config = {
                escrow_receipt = null;
                broker_id = null;
                pricing = #auction{
                    reserve = ?(100 * 10 ** 8);
                    token = #ic({
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    buy_now = ?(500 * 10 ** 8);
                    start_price = (1 * 10 ** 8);
                    start_date = 0;
                    ending = #date(end_date);
                    min_increase = #amount(10*10**8);
                    allow_list = null;
                };
            }; } );

        //place a bid on token that isn't for sale MKT0024
        let a_wallet_try_bid_wrong_token_id_exists = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1*10**8, "2", current_sales_id, null);

        //place a bid with bad owner data MKT0025
        let a_wallet_try_bid_wrong_owner = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), 1*10**8, "1", current_sales_id, null);

        //place a bid with bad sales id MKT0026
        let a_wallet_try_bid_wrong_sales_id = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1*10**8, "1", "test", null);

        let a_balance_after_bad_bid3 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        D.print("a balance 3 " # debug_show(a_balance_after_bad_bid2));


        //place a valid bid MKT0027
        let a_wallet_try_bid_valid = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1*10**8, "1", current_sales_id, null);
         D.print("a_wallet_try_bid_valid " # debug_show(a_wallet_try_bid_valid));

        let a_balance_after_bad_bid4 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        D.print("a balance 4 " # debug_show(a_balance_after_bad_bid4));

        //check transaction log for bid MKT0033, TRX0005
        let a_history_1 = await canister.history_nft_origyn("1", null, null); //gets all history

        D.print("history1" # debug_show(a_history_1));

        //make sure next min bid is bid + minimum increase MKT0032
        let a_sale_status_min_bid_increase = await canister.nft_origyn("1");

        D.print("withdraw during bid");
        //todo: attempt to withdraw escrow for active bid should fail ESC0016 NFT-76
        let a_withdraw_during_bid = await a_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", 1 * 10 ** 8, null);

        D.print("passed this");
        //place escrow b
        let new_bid_val = switch (a_sale_status_min_bid_increase){
            case(#ok(res)){
        
                switch(res.current_sale){
                   case(?current_sale){
                       switch(NFTUtils.get_auction_state_from_statusStable(current_sale)){
                           case(#err(err)){return #fail("cannot get min bid to make second bid");};
                           case(#ok(res)){
                               res.min_next_bid;
                           };
                       };
                   };
                   case(null){
                       return #fail("no sale found for finding min bid for second bid");
                   };
                };
            };
            case(#err(err)){
                return #fail("cannot get min bid to make second bid");
            };
        };

        
        //deposit escrow for two upcoming bids 
        D.print("sending tokens to canisters");
        let b_wallet_send_tokens_to_canister_correct_ledger = await b_wallet.send_ledger_payment(Principal.fromActor(dfx), (new_bid_val * 2 ) + 400000, Principal.fromActor(canister));

        
        D.print("Sending escrow for correct currency escrow now");
        let b_wallet_try_escrow_too_low = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, new_bid_val - 10, "1", ?current_sales_id, null, null);

        

         //place a low bid bid
        let b_wallet_try_bid_to_low = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), new_bid_val - 10, "1", current_sales_id, null);

        
        //try this bid without submitting escrow first...bid should try to load escrow
        //D.print("Sending escrow for correct currency escrow now");
        //let b_wallet_try_escrow_correct_currency2 = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, new_bid_val, "1", ?current_sales_id, null, null);


        //place a second bid
        let b_wallet_try_bid_valid = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), new_bid_val, "1", current_sales_id, null);

        D.print("did b bid work? ");
        D.print(debug_show(b_wallet_try_bid_valid));

        let b_balance_after_bid = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet))); //gets all history

        D.print("found balance after bid ");
        D.print(debug_show(b_balance_after_bid));

        //check transaction log for bid MKT0033, TRX0005
        let b_history_1 = await canister.history_nft_origyn("1", null, null); //gets all history

        D.print("found balance after bid ");
        D.print(debug_show(b_history_1));

        //place more escrow a
        //make sure next min bid is bid + minimum increase MKT0032
        let b_sale_status_min_bid_increase = await canister.nft_origyn("1");

        let new_bid_val_b = switch (b_sale_status_min_bid_increase){
            case(#ok(res)){
        
                 switch(res.current_sale){
                    case(?current_sale){
                        switch(NFTUtils.get_auction_state_from_statusStable(current_sale)){
                            case(#err(err)){return #fail("cannot get min bid to make third bid");};
                            case(#ok(res)){
                                res.min_next_bid;
                            };
                        };
                    };
                    case(null){
                        return #fail("no sale found for finding min bid for third bid");
                };
                 };
             };
             case(#err(err)){
                 return #fail("cannot get min bid to make third bid");
             };
         };

         let a_balance_before_third_escrow = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
       
        D.print("the balance before third escrow is");
        D.print(debug_show(a_balance_before_third_escrow));

        let a_wallet_send_tokens_to_canister2 = await a_wallet.send_ledger_payment(Principal.fromActor(dfx), (101 * 10 ** 8 ) + 200000, Principal.fromActor(canister));

        let block3 = switch(a_wallet_send_tokens_to_canister2){
            case(#ok(ablock)){
                ablock;
            };
            case(#err(other)){
                D.print("ledger didnt work");
                return #fail("ledger didnt work");
            };
        };

        D.print("Sending real escrow now 3"); //escrow is for 100. There should already be 1 in the escrow account. we are going to bid 101 above reserve
        let a_wallet_try_escrow_specific_3 = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 101 * 10 ** 8, "1", ?current_sales_id, null, null);

        D.print("specific result is");
        D.print(debug_show(a_wallet_try_escrow_specific_3));
        //todo check escrow balance
        //check balance and make sure we see the escrow BAL0002
        let a_balance_before_third = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        
        D.print("the balance before third is");
        D.print(debug_show(a_balance_before_third));

        //place a third bid
        let a_wallet_try_bid_valid_3 = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 101 * 10 ** 8, "1", current_sales_id, null);
        D.print("valid 3");
        D.print(debug_show(a_wallet_try_bid_valid_3));

        //try to end auction before it is time should fail
        let end_before = await canister.sale_nft_origyn(#end_sale("1"));
        D.print("end before");
        D.print(debug_show(end_before));
        D.print("end before");

        //advance time
        let time_result = await canister.__advance_time(end_date + 1);
        D.print("new time");
        D.print(debug_show(time_result));

        //end auction
        let end_proper = await canister.sale_nft_origyn(#end_sale("1"));
        D.print("end proper");
        D.print(debug_show(end_proper));

        //end again, should fail
        let end_again = await canister.sale_nft_origyn(#end_sale("1"));
        D.print("end again");
        D.print(debug_show(end_again));

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
        D.print(debug_show(b_balance_before_withdraw));
        //b tries to withdraw more than in account NFT-99

         let b_withdraw_over = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", 101 * 10 ** 8, null);
        
        // //b tries to withdraw for other buyer NFT-102

         let b_withdraw_bad_buyer = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);
        
        // //b tries to withdraw for other seller NFT-104

         let b_withdraw_bad_seller = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(a_wallet), "1", new_bid_val, null);
   
        // //b tries to withdraw for other tokenid NFT-105

         let b_withdraw_bad_token_id = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(a_wallet), "32", new_bid_val, null);
   
        // //b tries to withdraw for other token NFT-103

         let b_withdraw_bad_token = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(a_wallet), "1", new_bid_val, ?#ic{
             canister=Principal.fromActor(dfx2); 
             standard= #Ledger;
             decimals = 8;
             symbol = "LGY";
             fee = 200000;});
   
        // //b escrow should be auto refunded - need to test

         let b_withdraw = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);
        
        D.print("this withdraw should not work");
        D.print(debug_show(b_withdraw));
        //b withdraws escrow again NFT-106

        let b_withdraw_again = await b_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(b_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);
        D.print("this withdraw should not work again");
        D.print(debug_show(b_withdraw_again));

        //check transaction log for sale
        let b_history_withdraw = await canister.history_nft_origyn("1", null, null); //gets all history



        //attempt to withdraw the sale revenue for the seller(this canister)

        //NFT-113
        //get balanance and make sure the sale is in the balance
        let owner_balance_after_sale = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(this)));
        D.print("owner_balance_after_sale" # debug_show(owner_balance_after_sale));


        D.print("withdraw over for owner");
        //NFT-114
        //try to withdraw too much
        let owner_withdraw_over = await canister.sale_nft_origyn(#withdraw(#sale({
            withdraw_to = #principal(Principal.fromActor(this));
            token_id= "1";
            token = 
                #ic({
                  canister = Principal.fromActor(dfx);
                  standard =  #Ledger;
                  decimals = 8;
                  symbol = "LDG";
                  fee = 200000;
                });
            
             seller = #principal(Principal.fromActor(this));
             buyer = #principal(Principal.fromActor(a_wallet));
             amount = (101*10**8) + 15;})));
        


        // //NFT-115
        // //have a_wallet try to withdraw the sale
         let a_withdraw_attempt_sale = await a_wallet.try_sale_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", new_bid_val, null);
        

        //NFT-116
        //try to withdare the wrong asset
        D.print("owner_withdraw_wrong_asset");
        let owner_withdraw_wrong_asset = await canister.sale_nft_origyn(#withdraw(#sale({
            withdraw_to = #principal(Principal.fromActor(this));
            token_id= "1";
            token = 
                #ic({
                  canister = Principal.fromActor(dfx2);
                  standard = #Ledger;
                  decimals = 8;
                  symbol = "LGY";
                  fee = 200000;
                });
            
            seller = #principal(Principal.fromActor(this));
            buyer = #principal(Principal.fromActor(a_wallet));
            amount = 101*10**8;})));

        //NFT-117
        //todo: try to withdraw the wrong token_id
        D.print("owner_withdraw_wrong_token_id");
        let owner_withdraw_wrong_token_id = await canister.sale_nft_origyn(#withdraw(#sale({
            withdraw_to = #principal(Principal.fromActor(this));
            token_id= "2";
            token = 
                #ic({
                  canister = Principal.fromActor(dfx);
                  standard =  #Ledger;
                  decimals = 8;
                  symbol = "LDG";
                  fee = 200000;
                });
            
            seller = #principal(Principal.fromActor(this));
            buyer = #principal(Principal.fromActor(a_wallet));
            amount = 101*10**8;})));

        //NFT-19
        //todo: withdraw the proper amount
        D.print("withdrawing proper amount from sale");
        let owner_withdraw_proper_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(this)));
           

        D.print("Proper amount result balance");
        D.print(debug_show(owner_withdraw_proper_balance));

        let owner_withdraw_proper = await dfx.account_balance_dfx({account = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(this), null))});

        D.print("Proper amount result");
        D.print(debug_show(owner_withdraw_proper));

        //NFT-118
        //todo: try to withdraw again
        D.print("trying to withdraw sale again");
         let owner_withdraw_again = await canister.sale_nft_origyn(#withdraw(#sale({
            withdraw_to = #principal(Principal.fromActor(this));
            token_id= "1";
            token = 
                #ic({
                  canister = Principal.fromActor(dfx);
                  standard =  #Ledger;
                  decimals = 8;
                  symbol = "LDG";
                  fee = 200000;
                });
            
             seller = #principal(Principal.fromActor(this));
             buyer = #principal(Principal.fromActor(a_wallet));
             amount = 101*10**8;})));

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
        


         let suite = S.suite("test staged Nft", [

             S.test("test mint attempt", switch(mint_attempt){case(#ok(res)){
                
                "correct response";
                
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), 
            S.test("fail if non owner tries to start auction", switch(start_auction_attempt_fail){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 2000){ //unauthorized
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //MKT0019
            S.test("fail if auction already running", switch(start_auction_attempt_owner_already_started){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 13){ //existing sale
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //MKT0018
            S.test("auction is started", switch(start_auction_attempt_owner){case(#ok(res)){
               switch(res.txn_type){
                   case(#sale_opened(details)){
                       "correct response";
                   };
                   case(_){
                       "bad transaction type";
                   };
               }; 
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //MKT0021
            
            S.test("fail if refund isn't succesful", switch(a_wallet_try_deposit_refund){case(#ok(res)){
              "expected success"
              };
              case(#err(err)){
                
                    "wrong error " # debug_show(err);
                };}, M.equals<Text>(T.text("expected success"))), 
            S.test("transfer ownerfail if auction already running", switch(transfer_owner_after_auction){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 13){ //existing sale
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //MKT0022
            S.test("fail if bid too low", switch(a_wallet_try_bid_below_start){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 4004){ //below bid price
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //MKT0023
            S.test("fail if wrong asset", switch(b_wallet_try_bid_wrong_asset){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 4002){ //wrong asset
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //MKT0024
            S.test("fail if cant find sale id ", switch(a_wallet_try_bid_wrong_token_id_not_exist){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 4003){ //MKT0024
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //MKT0023
             S.test("fail if bid on wrong token ", switch(a_wallet_try_bid_wrong_token_id_exists){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 4003){ //wrong token 
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //MKT0026

            S.test("fail if bid on wrong owner ", switch(a_wallet_try_bid_wrong_owner){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 4001){ //wrong token 
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //MKT0025
             S.test("bid is succesful", switch(a_wallet_try_bid_valid){case(#ok(res)){
                 D.print("as bid");
                 D.print(debug_show(a_wallet_try_bid_valid));
               switch(res.txn_type){
                   case(#auction_bid(details)){
                       if(Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and
                            details.amount == 1*10**8 and
                            details.sale_id == current_sales_id and
                            Types.token_eq(details.token, #ic({
                                canister = (Principal.fromActor(dfx)); 
                                standard = #Ledger;
                                decimals = 8;
                                symbol = "LDG";
                                fee = 200000;}))){
                                "correct response";
                        } else {
                            "details didnt match" # debug_show(details);
                        };
                   };
                   case(_){
                       "bad transaction bid";
                   };
               }; 
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //MKT0027
            S.test("transaction history has the bid", switch(a_history_1){case(#ok(res)){
               
               D.print("where ismy history");
               D.print(debug_show(a_history_1));
               if(res.size() > 0){
                switch(res[res.size()-1].txn_type){ 
                    case(#auction_bid(details)){
                        if(Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and
                                details.amount == 1*10**8 and
                                details.sale_id == current_sales_id and
                                Types.token_eq(details.token, #ic({
                                    canister = (Principal.fromActor(dfx)); 
                                    standard =  #Ledger;
                                    decimals = 8;
                                    symbol = "LDG";
                                    fee = 200000;
                                    }))){
                                    "correct response";
                            } else {
                                "details didnt match" # debug_show(details);
                            };
                    };
                    case(_){
                        "bad history bid";
                    };
                }
               } else {
                   "size was 0";
               }
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //TRX0005, MKT0033
            S.test("min bid increased", switch(a_sale_status_min_bid_increase){case(#ok(res)){
               
                switch(res.current_sale){
                    case(?current_sale){
                        switch(NFTUtils.get_auction_state_from_statusStable(current_sale)){
                            case(#err(err)){"unexpected error: " # err.flag_point};
                            case(#ok(res)){
                                //let min_bid_increase = 
                                if(res.min_next_bid == (1*10**8) + 10*10**8 ){
                                    "correct response"
                                } else {
                                    "wrong bid " # debug_show(res.min_next_bid);
                                }
                            };
                        };
                    
                    };
                    case(_){
                        "bad info min bid";
                    };
                }
             };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //MKT0032
             S.test("fail if bid is too low ", switch(b_wallet_try_bid_to_low){case(#ok(res)){"unexpected success"};case(#err(err)){
                 if(err.number == 4004){ //too low
                     "correct number"
                 } else{
                     "wrong error " # debug_show(err);
             }};}, M.equals<Text>(T.text("correct number"))), //todo: create user story for bid too low
             S.test("transaction history has the new bid", switch(b_history_1){case(#ok(res)){
               
               D.print("new bid history");
               D.print(debug_show(b_history_1));
               if(res.size() > 0){
                switch(res[res.size()-1].txn_type){
                    case(#auction_bid(details)){
                        if(Types.account_eq(details.buyer, #principal(Principal.fromActor(b_wallet))) and
                                details.amount == new_bid_val and
                                details.sale_id == current_sales_id and
                                Types.token_eq(details.token, #ic({
                                    canister = (Principal.fromActor(dfx)); 
                                    standard = #Ledger;
                                    decimals = 8;
                                    symbol = "LDG";
                                    fee = 200000;}))){
                                    "correct response";
                            } else {
                                "details didnt match for second bid " # debug_show(details);
                            };
                    };
                    case(_){
                        "bad history bid for b " # debug_show(res);
                    };
                }
               } else {
                   "size was zero for new bid";
               }
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //TRX0005, MKT0033
            S.test("escrow balance is right amount for a before thrid bid", switch(a_balance_before_third){case(#ok(res)){
                D.print("testing third bid");
                D.print(debug_show(res));
                D.print(debug_show(#principal(Principal.fromActor(canister))));
                D.print(debug_show(#principal(Principal.fromActor(a_wallet))));
                D.print(debug_show(Principal.fromActor(dfx)));
                D.print(debug_show(Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(canister)))));
                D.print(debug_show(Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet)))));
                D.print(debug_show(res.escrow[0].token_id == "1"));
                D.print(debug_show(Types.token_eq(res.escrow[0].token, #ic({canister = Principal.fromActor(dfx);standard =  #Ledger; decimals = 8;symbol = "LDG";fee = 200000;}))));
                D.print(debug_show(res.escrow[0].amount == 104 * 10 **8, res.escrow[0].amount , 104 * 10 **8,));
                if(Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(this))) and
                    Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet))) and
                    res.escrow[0].token_id == "1" and
                    Types.token_eq(res.escrow[0].token, #ic({
                        canister = Principal.fromActor(dfx);
                        standard =  #Ledger;
                        decimals = 8;
                        symbol = "LDG";
                        fee = 200000;
                        })) and
                    res.escrow[0].amount == 103 * 10 **8 
                ){
                    "found escrow record"
                } else {
                    D.print(debug_show(res));
                    "didnt find record "
            }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found escrow record"))), //todo: MKT0037
           S.test("auction winner is the new owner", switch(a_sale_status_over_new_owner){case(#ok(res)){

                let new_owner = switch(Metadata.get_nft_owner(
                    switch (a_sale_status_over_new_owner){
                        case(#ok(item)){
                            item.metadata;
                        };
                        case(#err(err)){
                           #Empty;
                        };
                    })){
                        case(#err(err)){
                            #account_id("wrong");
                        };
                        case(#ok(val)){
                            val;
                        };
                    };
                D.print("new owner");
                D.print(debug_show(new_owner));
                D.print(debug_show(Principal.fromActor(a_wallet)));
                if(Types.account_eq(new_owner, #principal(Principal.fromActor(a_wallet)))){
                    "found correct owner"
                } else {
                    D.print(debug_show(res));
                    "didnt find record "
            }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found correct owner"))), //MKT0029
            S.test("current sale status is ended", switch(a_sale_status_over_new_owner){case(#ok(res)){
                D.print("a_sale_status_over_new_owner");
                D.print(debug_show(a_sale_status_over_new_owner));
                //MKT0036 sale should be over and there should be a record with status #ended
                    switch (a_sale_status_over_new_owner){
                        case(#ok(res)){
                           
                            switch(res.current_sale){
                                case(null){
                                    "current sale improperly removed"
                                };
                                case(?val){
                                    switch(val.sale_type){
                                        case(#auction(state)){
                                            D.print("state");
                                            D.print(debug_show(state));
                                            let current_status = switch(state.status){case(#closed){true;};case(_){false}};
                                            if(current_status == true and
                                                val.sale_id == current_sales_id){
                                                    "found closed sale";
                                            } else {
                                                "didnt find closed sale";
                                            };
                                            
                                        };
                                        
                                    };
                                };
                            };
                                    
                         };
                         case(#err(err)){
                            "error getting";
                         };
                     };
                 };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found closed sale"))), // MKT0036
           
           
            
             S.test("transaction history have the transfer - auction", 
                switch(a_history_3){
                    case(#ok(res)){
                
                        if(res.size() > 1){
                        switch(res[res.size()-1].txn_type){
                            case(#sale_ended(details)){
                                if(Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and
                                        details.amount == 101*10**8 and
                                        details.sale_id == ?current_sales_id and
                                        Types.token_eq(details.token, #ic({
                                            canister = (Principal.fromActor(dfx)); 
                                            standard =  #Ledger;
                                            decimals = 8;
                                            symbol = "LDG";
                                            fee = 200000;}))){
                                            "correct response";
                                    } else {
                                        "details didnt match" # debug_show(details);
                                    };
                            };
                            case(_){
                                "bad history sale " # debug_show(a_history_3);
                            };
                        };
                        } else {
                            "size was les than one"
                        };
                    
                    };
                    case(#err(err)){"unexpected error: " # err.flag_point};
                }, M.equals<Text>(T.text("correct response"))), //todo: make a user story for adding a #sale_ended to the end of transaction log
            S.test("fail if ended before corect date ", switch(end_before){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 4007){ //sale not over
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), //todo: create user story for sale not over
            S.test("transaction history have the transfer - auction 2", switch(end_proper){case(#ok(#end_sale(res))){
                D.print("transaction history have the transfer 2");
                D.print(debug_show(res));
                switch(res.txn_type){
                    case(#sale_ended(details)){
                        if(Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and
                                details.amount == 101*10**8 and
                                Option.get(details.sale_id, "") == current_sales_id and
                                Types.token_eq(details.token, #ic({
                                    canister = (Principal.fromActor(dfx)); 
                                    standard =  #Ledger;
                                    decimals = 8;
                                    symbol = "LDG";
                                    fee = 200000;}))){
                                    "correct response";
                            } else {
                                "details didnt match" # debug_show(details);
                            };
                    };
                    case(_){
                        "bad history sale";
                    };
                }
            };case(#err(err)){"unexpected error: " # err.flag_point};
            case(_){"unexpected error: " };}, M.equals<Text>(T.text("correct response"))), //todo: make a user story for adding a #sale_ended to the end of transaction log
            S.test("fail if auction already over ", switch(end_again){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 2000){ //new owner so unauthorized
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), //todo: create user story for sale over
            S.test("fail if escrow amount over deposited amount", switch(b_withdraw_over){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000){ //escrow no longer found since it was refunded
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-101
            S.test("fail if escrow amount is the wrong token", switch(b_withdraw_bad_token){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000){ //shouldn't be able to find escrow
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), //t NFT-103
            S.test("fail if escrow amount is the wrong seller", switch(b_withdraw_bad_seller){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000){ //shouldn't be able to find escrow
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), //t NFT-104
            S.test("fail if escrow amount is the wrong buyer", switch(b_withdraw_bad_buyer){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 2000){ //unauthorized
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-102
            S.test("fail if escrow amount is the wrong token_id", switch(b_withdraw_bad_token_id){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000){ //token id not found
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-105
            S.test("fail if escrow removed twice", switch(b_withdraw_bad_token_id){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000){ //withdraw too large because 0 and not found
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-106
            S.test("fail if escrow is for the current winning bid", switch(a_withdraw_during_bid){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3008){ //cannot be removed
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-76

            S.test("fail if escrow is for the winning bid a withdraw", switch(a_withdraw_during_win){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000 or err.number == 3007){ //wont be able to find it because it has been zeroed out.
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-110
            S.test("fail if escrow is for the winning bid b withdraw", switch(b_withdraw){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000){ //wont be able to find it because it has been zeroed out.
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-18, NFT-101 - These were negated by NFT-120
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
                                    fee = 200000;}))){
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
                }
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //NFT-107
            */
            S.test("sales balance after sale has balance in it", switch(owner_balance_after_sale){case(#ok(res)){
                D.print("testing sale balance 1");
                D.print(debug_show(res));
                
                
                if(res.sales.size() ==0){
                  
                    "found no sales record"
                } else {
                    
                    D.print(debug_show(res));
                    "found record "
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found no sales record"))), //todo: NFT-113
            S.test("fail if withdraw over sale amount", switch(owner_withdraw_over){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000){ //can't find it
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-114
            S.test("fail if withdraw from wrong account", switch(a_withdraw_attempt_sale){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 2000){ //unauthorized access
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-115
            S.test("fail if withdraw from wrong asset", switch(owner_withdraw_wrong_asset){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000){ //cant find sale
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-116
            S.test("fail if withdraw from wrong token id", switch(owner_withdraw_wrong_token_id){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000){ //cant find sale
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-117
            S.test("fail if withdraw a second time", switch(owner_withdraw_again){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000){ //cant find sale
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-117
            S.test("sale withdraw works", owner_withdraw_proper.e8s, M.equals<Nat64>(T.nat64(199810099200000))), //NFT-18, NFT-101
            S.test("sales balance after withdraw has no balance in it", switch(owner_balance_after_withdraw){case(#ok(res)){
                D.print("testing sale balance 2");
                D.print(debug_show(res));
                
                
                if(res.sales.size() == 0){
                    "found empty record"
                } else {
                    D.print(debug_show(res));
                    "found a record "
            }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found empty record"))), //todo: NFT-118
           S.test("sale withdraw in history", switch(owner_history_withdraw){case(#ok(res)){
               D.print("sales withdraw history");
               D.print(debug_show(res));
                switch(res[res.size()-2].txn_type){
                    case(#sale_withdraw(details)){
                        D.print(debug_show(details));
                        if(Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and
                                Types.account_eq(details.seller, #principal(Principal.fromActor(this))) and
                                details.amount == (Nat.sub(((101*10**8)-200000),dip20_fee)) and
                                details.token_id == "1" and
                                Types.token_eq(details.token, #ic({
                                    canister = (Principal.fromActor(dfx));
                                    standard =  #Ledger;
                                    decimals = 8;
                                    symbol = "LDG";
                                    fee = 200000;}))){
                                    "correct response";
                            } else {
                                "details didnt match" # debug_show(details);
                            };
                    };
                    case(_){
                        D.print(debug_show(res[res.size()-1]));
                        "bad history withdraw";
                    };
                }
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //NFT-19
            S.test("nft balance after sale", switch(a_balance_after_close){case(#ok(res)){
                D.print("testing nft balance");
                D.print(debug_show(res));
                
                
                if(res.nfts.size() == 0){
                    "found empty record"
                } else {
                    D.print(debug_show(res));
                    if(res.nfts[res.nfts.size()-1] == "1"){
                        "found a record"
                    }else {
                        "didnt find record"
                    };

                };
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found a record"))), //todo: NFT-94
           
            S.test("sale info has active and only active sale in it", switch(active_sale_info_1){
              case(#ok(#active(val))){
                if(val.records.size() == 1 and val.records[0].0 == "1"){
                  "correct response";
                }else {
                  "bad response" # debug_show(active_sale_info_1)
                };
              };
              case(#err(err)){
                "bad error in sale info " # debug_show(err);
              };
              case(_){
                "some odd error in sale info" # debug_show(active_sale_info_1);
              }
            }, M.equals<Text>(T.text("correct response"))),

            S.test("sale info has one active sale after close of first", switch(active_sale_info_2){
              case(#ok(#active(val))){
                if(val.records.size() == 1 and val.records[0].0 == "2"){
                  "correct response";
                } else {
                  "bad response" # debug_show(active_sale_info_2)
                };
              };
              case(#err(err)){
                "bad error in sale info " # debug_show(err);
              };
              case(_){
                "some odd error in sale info" # debug_show(active_sale_info_2);
              }
            }, M.equals<Text>(T.text("correct response"))),

            S.test("sale is included in history", switch(history_sale_info_2){
              case(#ok(#history(val))){
                if(val.records.size() == 2){
                  switch(val.records[0]){
                    case(null){"shouldnt be null"};
                    case(?val){
                      if(val.sale_id == current_sales_id){
                        "correct response";
                      } else{
                        "wrong sale id "# debug_show(val);
                      };
                    };
                  };
                }else {
                  "bad response" # debug_show(history_sale_info_2)
                };
              };
              case(#err(err)){
                "bad error in sale info " # debug_show(err);
              };
              case(_){
                "some odd error in sale info" # debug_show(history_sale_info_2);
              }
            }, M.equals<Text>(T.text("correct response"))),
            
            S.test("sale info has no active sale after cancel", switch(active_sale_info_3){
              case(#ok(#active(val))){
                if(val.records.size() == 0){
                  "correct response";
                } else {
                  "bad response" # debug_show(active_sale_info_3)
                };
              };
              case(#err(err)){
                "bad error in sale info " # debug_show(err);
              };
              case(_){
                "some odd error in sale info" # debug_show(active_sale_info_3);
              }
            }, M.equals<Text>(T.text("correct response"))),
         ]);

         D.print("suite running");

         S.run(suite);

          D.print("suite over");

        return #success;
        
          

    };
    
    public shared func testStandardLedger() : async {#success; #fail : Text} {
        D.print("running testStandardLedger");

        let a_wallet = await TestWalletDef.test_wallet();

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        D.print("calling stage");

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false);
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false);
        let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false);

        D.print("finished stage");
        D.print(debug_show(standardStage.0));

        //ESC0002. try to escrow for the canister; should succeed
        //fund a_wallet
        D.print("funding result start a_wallet");
        D.print(AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null)));
        D.print(AccountIdentifier.toText(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null)));
        D.print(debug_show(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null))));
        let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
        
        let funding_result = await dfx.transfer({
            to =  Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null)));
            fee = {e8s = 200_000};
            memo = 1;
            from_subaccount = null;
            created_at_time = null;
            amount = {e8s = 100 * 10 ** 8};});
        D.print("funding result end");
        D.print(debug_show(funding_result));

        //sent an escrow for a stdledger deposit that doesn't exist
        D.print("sending an escrow with no deposit");
        let a_wallet_try_escrow_general_fake = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), ?34, 1 * 10 ** 8, ?#ic({
            canister= Principal.fromActor(dfx); 
            standard=#Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = 200000;}),  null);


        //send a payment to the ledger
        D.print("sending tokens to canisters");
        let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_payment(Principal.fromActor(dfx), (1 * 10 ** 8) + 200000, Principal.fromActor(canister));
        
        D.print("send to canister a");
        D.print(debug_show(a_wallet_send_tokens_to_canister));

        debug{ if(debug_channel.throws) D.print("checking block_result")};
        let #ok(block_result) = a_wallet_send_tokens_to_canister;
        let block = Nat64.toNat(block_result);//block is no longer relevant for ledgers

        //sent an escrow for a ledger deposit that doesn't exist
        let a_wallet_try_escrow_general_fake_amount = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), null, 2 * 10 ** 8, ?#ic({
            canister= Principal.fromActor(dfx); 
            standard=#Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = 200000;}), null);

        D.print("a_wallet_try_escrow_general_fake_amount" # debug_show(a_wallet_try_escrow_general_fake_amount));

        ////ESC0001

        D.print("Sending real escrow now");
        let a_wallet_try_escrow_general_staged = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), ?block, 1 * 10 ** 8, ?#ic({
            canister= Principal.fromActor(dfx); 
            standard=#Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = 200000;}), null);

        D.print("try escrow genreal stage");
        D.print(debug_show(a_wallet_try_escrow_general_staged));

        //ESC0005 should fail if you try to calim a deposit a second time
        let a_wallet_try_escrow_general_staged_retry = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), Principal.fromActor(dfx), ?block, 1 * 10 ** 8, ?#ic({
            canister= Principal.fromActor(dfx); 
            standard=#Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = 200000;}), null);

        //check balance and make sure we see the escrow BAL0002
        let a_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

        D.print("thebalance");
        D.print(debug_show(a_balance));

        //MKT0007, MKT0014
        D.print("blind market");
        let blind_market = await canister.market_transfer_nft_origyn({
            token_id = "1";
            sales_config = 
              {
                  escrow_receipt = ?{
                    seller = #principal(Principal.fromActor(canister));
                    buyer = #principal(Principal.fromActor(a_wallet));
                    token_id = "";
                    token = #ic({
                        canister= Principal.fromActor(dfx); 
                        standard=#Ledger;
                        decimals = 8;
                        symbol = "LDG";
                        fee = 200000;});
                    amount = 100_000_000;
                  };
                  pricing = #instant;
                  broker_id = null;
              };
            
        });

        D.print(debug_show(blind_market));

        //MKT0014 todo: check the transaction record and confirm the gensis reocrd

        //BAL0005
        let a_balance2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

        //BAL0003
        let canister_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(canister)));

        //MKT0013, MKT0011 this item should be minted now
        let test_metadata = await canister.nft_origyn("1");
        D.print("This thing should have been minted");
        D.print(debug_show(test_metadata));
        switch(test_metadata){
            case(#ok(val)){
                D.print(debug_show(Metadata.is_minted(val.metadata)));
            };
            case(_){};
        };

        //MINT0026 shold fail because the purchase of a staged item should mint it
        let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(a_wallet)));
        D.print("This thing should have not been minted");
        D.print(debug_show(mint_attempt));

        //ESC0009
        let blind_market2 = await canister.market_transfer_nft_origyn({
            token_id = "2";
            sales_config = 
              {
                  escrow_receipt = ?{
                    seller = #principal(Principal.fromActor(canister));
                    buyer = #principal(Principal.fromActor(a_wallet));
                    token_id = "";
                    token = #ic({
                        canister= Principal.fromActor(dfx); 
                        standard=#Ledger;
                        decimals = 8;
                        symbol = "LDG";
                        fee = 200000;});
                    amount = 100_000_000;
                  };
                  pricing = #instant;
                  broker_id = null;
              };
            
        });

        D.print("This thing should have not been minted either");
        D.print(debug_show(blind_market2));

        //mint the third item to test a specific sale
        let mint_attempt3 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(this)));

        D.print("mint attempt 3");
        D.print(debug_show(mint_attempt3));

        //creae an new wallet for testing
        let b_wallet = await TestWalletDef.test_wallet();

        //give b_wallet some tokens
        D.print("funding result start b_wallet");
        let b_funding_result = await dfx.transfer({
            to =  Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(b_wallet), null)));
            fee = {e8s = 200_000};
            memo = 1;
            from_subaccount = null;
            created_at_time = null;
            amount = {e8s = 100 * 10 ** 8};});
        D.print("funding result");
        D.print(debug_show(funding_result));

        //send a payment to the the new owner(this actor- after mint)
        D.print("sending tokens to canisters");
    
        let b_wallet_send_tokens_to_canister = await b_wallet.send_ledger_payment(Principal.fromActor(dfx), (1 * 10 ** 8) + 200000, Principal.fromActor(canister));
        
        D.print("send to canister b");
        D.print(debug_show(b_wallet_send_tokens_to_canister));

        let b_block = switch(b_wallet_send_tokens_to_canister){
            case(#ok(ablock)){
                Nat64.toNat(ablock);
            };
            case(#err(other)){
                D.print("ledger didnt work");
                return #fail("ledger didnt work");
            };
        };
        
        //ESC0002
        D.print("Sending real escrow now");
        let b_wallet_try_escrow_specific_staged = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), ?b_block, 1 * 10 ** 8, "3", null, ?#ic({
            canister= Principal.fromActor(dfx); 
            standard=#Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = 200000;}), null);

        //
        D.print("try escrow specific stage");
        D.print(debug_show(b_wallet_try_escrow_specific_staged));


        //MKT0010
        D.print("apecific market");
        let specific_market = await canister.market_transfer_nft_origyn({
            token_id = "3";
            sales_config = 
              {
                  escrow_receipt = ?{
                    seller = #principal(Principal.fromActor(this));
                    buyer = #principal(Principal.fromActor(b_wallet));
                    token_id = "3";
                    token = #ic({
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                        symbol = "LDG";
                        fee = 200000;
                    });
                    amount = 100_000_000;
                  };
                  pricing = #instant;
                  broker_id = null;
              };
            
        });

        D.print(debug_show(specific_market));

        //test balances

        let suite = S.suite("test market Nft", [
            S.test("fail if escrow is double processed", switch(a_wallet_try_escrow_general_staged_retry){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number ==3003){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err.number);
                }};}, M.equals<Text>(T.text("correct number"))), //ESC0005
            S.test("fail if mint is called on a minted item", switch(mint_attempt){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 10){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //MINT0026

            S.test("item is minted now", switch(test_metadata){case(#ok(res)){
                if(Metadata.is_minted(res.metadata) == true){
                    "was minted"
                } else {
                    "was not minted"
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("was minted"))), //MKT0013
            S.test("item is owned by correct owner after minting", switch(test_metadata){case(#ok(res)){
                if(Types.account_eq(switch(Metadata.get_nft_owner(res.metadata)){
                    case(#err(err)){#account_id("invalid")};
                    case(#ok(val)){D.print(debug_show(val));val};
                }, #principal(Principal.fromActor(a_wallet)) ) == true){
                    "was transfered"
                } else {
                    D.print("awallet");
                    D.print(debug_show(Principal.fromActor(a_wallet)));
                    "was not transfered"
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("was transfered"))), //MKT0011

            S.test("fail if escrow already spent", switch(blind_market2){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number ==3000){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err.number);
                }};}, M.equals<Text>(T.text("correct number"))), //ESC0009
            
            S.test("fail if escrowing for a non existant deposit", switch(a_wallet_try_escrow_general_fake){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3003){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err.number);
                }};}, M.equals<Text>(T.text("correct number"))), //ESC0006
            S.test("fail if escrowing for an existing deposit but fake amount", switch(a_wallet_try_escrow_general_fake_amount){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3003){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err.number);
                }};}, M.equals<Text>(T.text("correct number"))), //ESC0011
            S.test("can escrow for general unminted item", switch(a_wallet_try_escrow_general_staged){case(#ok(res)){
                D.print("an amount for escrow");
                D.print(debug_show(res.receipt));
                if(res.receipt.amount == 1*10**8){
                    "was escrowed"
                } else {
                    "was not escrowed"
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("was escrowed"))), //ESC0002
             S.test("can escrow for specific item", switch(b_wallet_try_escrow_specific_staged){case(#ok(res)){
                if(res.receipt.amount == 1*10**8){
                    "was escrowed"
                } else {
                    "was not escrowed"
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("was escrowed"))), //ESC0001
            S.test("owner can sell specific NFT - produces sale_id", switch(specific_market){case(#ok(res)){
                if(res.token_id == "3"){
                    "found tx record"
                } else {
                    D.print(debug_show(res));
                    "no sales id "
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found tx record"))), //MKT0010
            S.test("escrow balance is shown", switch(a_balance){case(#ok(res)){
                D.print("this should be failing for now because it cmpares dip20 but we did ledger");
                D.print(debug_show(res));
                D.print(debug_show(#principal(Principal.fromActor(canister))));
                D.print(debug_show(#principal(Principal.fromActor(a_wallet))));
                D.print(debug_show(Principal.fromActor(dfx)));
                if(Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(canister))) and
                    Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet))) and
                    res.escrow[0].token_id == "" and
                    Types.token_eq(res.escrow[0].token, #ic({
                        canister = Principal.fromActor(dfx);
                        standard =  #Ledger;
                        decimals = 8;
                        symbol = "LDG";
                        fee = 200000;
                        }))
                ){
                    "found escrow record"
                } else {
                    D.print(debug_show(res));
                    "didnt find record "
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found escrow record"))), //BAL0001
            S.test("escrow balance is removed", switch(a_balance2){case(#ok(res)){
                 D.print(debug_show(res));
                if(res.escrow.size() == 0 ){
                    "no escrow record"
                } else {
                    D.print(debug_show(res));
                    "found record  "
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("no escrow record"))), //BAL0005
            S.test("sale balance is shown", switch(a_balance){case(#ok(res)){
                D.print(debug_show(res));
                D.print(debug_show(#principal(Principal.fromActor(canister))));
                D.print(debug_show(#principal(Principal.fromActor(a_wallet))));
                D.print(debug_show(Principal.fromActor(dfx)));
                if(Types.account_eq(res.escrow[0].buyer, #principal(Principal.fromActor(a_wallet))) and
                    Types.account_eq(res.escrow[0].seller, #principal(Principal.fromActor(canister))) and
                    res.escrow[0].token_id == "" and
                    Types.token_eq(res.escrow[0].token, #ic({
                        canister = Principal.fromActor(dfx);
                        standard =  #Ledger;
                        decimals = 8;
                        symbol = "LDG";
                        fee = 200000;
                        })) and
                    res.escrow[0].amount == 1*10**8 
                ){
                    "found sale record"
                } else {
                    D.print(debug_show(res));
                    "didnt find record "
                }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found sale record"))), //BAL0003
            
        ]);

        S.run(suite);

        return #success;
    };


    public shared func testOffers() : async {#success; #fail : Text} {
        D.print("running testOffers");

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        let c_wallet = await TestWalletDef.test_wallet();

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        D.print("calling stage");

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false);
        let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(c_wallet))); //mint to c_wallet
        
        D.print("finished stage");
        D.print(debug_show(standardStage.0));
        D.print(debug_show(mint_attempt));

        //ESC0002. try to escrow for the canister; should succeed
        //fund a_wallet
        D.print("funding result start a_wallet");
        let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
        
        let funding_result = await dfx.transfer({
            to =  Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(a_wallet), null)));
            fee = {e8s = 200_000};
            memo = 1;
            from_subaccount = null;
            created_at_time = null;
            amount = {e8s = 100 * 10 ** 8};});
        D.print("funding result end");
        D.print(debug_show(funding_result));

        

        //send a payment to the ledger
        D.print("sending tokens to canisters");
        let a_ledger_balance_before_escrow = await a_wallet.ledger_balance(Principal.fromActor(dfx), Principal.fromActor(a_wallet));
        D.print("the a ledger balance" # debug_show(a_ledger_balance_before_escrow));

        let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_payment(Principal.fromActor(dfx), (1 * 10 ** 8) + 200000, Principal.fromActor(canister));
        
        D.print("send to canister a");
        D.print(debug_show(a_wallet_send_tokens_to_canister));

        
        ////ESC0001

        D.print("Sending real escrow now");

        D.print("Sending real escrow now");
       let a_wallet_try_escrow_specific_staged = await a_wallet.try_escrow_specific_staged(Principal.fromActor(c_wallet), Principal.fromActor(canister), Principal.fromActor(dfx), null, 1 * 10 ** 8, "1", null, ?#ic({
            canister= Principal.fromActor(dfx); 
            standard=#Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = 200000;}), null);

        D.print("try escrow genreal stage");
        D.print(debug_show(a_wallet_try_escrow_specific_staged));

       

        //check balance and make sure we see the escrow BAL0002
        let a_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        let a_ledger_balance_after_escrow = await a_wallet.ledger_balance(Principal.fromActor(dfx), Principal.fromActor(a_wallet));
        let c_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(c_wallet)));
        
        D.print("the a balance" # debug_show(a_balance));
        D.print("the a ledger balance" # debug_show(a_ledger_balance_after_escrow));
        D.print("the c balance" # debug_show(c_balance));

        //have b try to reject the escrow ....should fail
        
        //canister should have an offer
        let c_wallet_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(c_wallet)));

        let reject_wrong_seller = await b_wallet.try_escrow_reject(
            Principal.fromActor(canister), 
            Principal.fromActor(a_wallet),
            Principal.fromActor(dfx),
            Principal.fromActor(c_wallet),
            "1",
            null
            );


             D.print("reject_wrong_seller" # debug_show(reject_wrong_seller));

        //MKT0014 todo: check the transaction record and confirm the gensis reocrd

        //BAL0005
        let a_balance2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        let a_ledger_balance2 = await a_wallet.ledger_balance(Principal.fromActor(dfx), Principal.fromActor(a_wallet));
        
        D.print("the a balance 2 " # debug_show(a_balance2));
        D.print("the a ledger balance 2" # debug_show(a_ledger_balance2));
        D.print("c_balance" # debug_show(c_balance));

        //BAL0003
        let c_wallet_balance_2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(c_wallet)));

        //have the owner reject the offer

        let reject_right_seller = await c_wallet.try_escrow_reject(
            Principal.fromActor(canister), 
            Principal.fromActor(a_wallet),
            Principal.fromActor(dfx),
            Principal.fromActor(c_wallet),
            "1",
            null
        );

          D.print("reject_right_seller" # debug_show(reject_right_seller));


         let a_balance3 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
       

        let a_ledger_balance3 = await a_wallet.ledger_balance(Principal.fromActor(dfx), Principal.fromActor(a_wallet));
        let c_balance2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(c_wallet)));
        
        D.print("the a balance 3 " # debug_show(a_balance3));
         D.print("the a balance 2 " # debug_show(c_balance2));
        D.print("the a ledger balance 3 " # debug_show(a_ledger_balance3));

        //refresh removes the offer
        let c_refresh = await c_wallet.try_offer_refresh(Principal.fromActor(canister));
        
        D.print("c_refresh3 " # debug_show(c_refresh));
        
         let c_balance3 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(c_wallet)));
       
       D.print("c_balance3 " # debug_show(c_balance3));
        //test balances

        let suite = S.suite("test market Nft", [
            S.test("fail if b can reject", switch(reject_wrong_seller){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 2000){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //MINT0026
            
            S.test("c has offer", switch(c_balance){case(#ok(res)){
                D.print("testing sale balance 2");
                D.print(debug_show(res));
                
                
                if(res.offers.size() == 0){
                    "found empty record"
                } else {
                    D.print(debug_show(res));
                    "found a record"
            }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found a record"))), //todo: NFT-118
           
            S.test("does not  gets money back after wrong reject", if(a_ledger_balance_after_escrow.e8s == a_ledger_balance2.e8s){
                    "correct amount";
                } else {
                    "wrong amount " # Nat.toText(Nat64.toNat(a_ledger_balance_before_escrow.e8s)) # " " #  Nat.toText(Nat64.toNat(a_ledger_balance3.e8s));
                }
                    , M.equals<Text>(T.text("correct amount"))), 
            S.test("a gets money back after reject", if(a_ledger_balance_before_escrow.e8s - 200000 - 200000 - 200000  == a_ledger_balance3.e8s){ //original balance = should equal the refund + fee for depoist + fee for claim + fee to send back
                    "correct amount";
                } else {
                    "wrong amount " # Nat.toText(Nat64.toNat(a_ledger_balance_before_escrow.e8s)) # " " #  Nat.toText(Nat64.toNat(a_ledger_balance3.e8s));
                }
                    , M.equals<Text>(T.text("correct amount"))), 
            
            S.test("c has no offer", switch(c_balance3){case(#ok(res)){
                D.print("testing offer balance 3");
                D.print(debug_show(res));
                
                
                if(res.offers.size() == 0){
                    "found empty record"
                } else {
                    D.print(debug_show(res));
                    "found a record "
            }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found empty record"))), 
            S.test("a has no escrow after", switch(a_balance3){case(#ok(res)){
                D.print("testing sale balance 2");
                D.print(debug_show(res));
                
                
                if(res.offers.size() == 0){
                    "found empty record"
                } else {
                    D.print(debug_show(res));
                    "found a record "
            }};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found empty record"))), 
                

           
        ]);

        S.run(suite);

        return #success;
    };

}