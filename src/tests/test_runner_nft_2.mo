import AccountIdentifier "mo:principalmo/AccountIdentifier";
import C "mo:matchers/Canister";
import Conversion "mo:candy/conversion";
import DFXTypes "../origyn_nft_reference/dfxtypes";
import D "mo:base/Debug";
import Blob "mo:base/Blob";
import M "mo:matchers/Matchers";
import NFTUtils "../origyn_nft_reference/utils";
import Metadata "../origyn_nft_reference/metadata";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Properties "mo:candy/properties";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";
import TestWalletDef "test_wallet";
import Time "mo:base/Time";
import Types "../origyn_nft_reference/types";
import utils "test_utils";
import KYCService "../../.vessel/icrc17_kyc/master/test/service_example";


shared (deployer) actor class test_runner(dfx_ledger: Principal, dfx_ledger2: Principal) = this {
    let it = C.Tester({ batchSize = 8 });

    
    private var DAY_LENGTH = 60 * 60 * 24 * 10 ** 9;
    private var ledger_fee = ?200_000;

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
           S.test("testKYC", switch(await testKYC()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
           /*  S.test("testMint", switch(await testMint()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testStage", switch(await testStage()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testOwnerAndManager", switch(await testOwnerAndManager()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testBuyItNow", switch(await testBuyItNow()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),       */   
            ]);
        S.run(suite);

        return #success;
    };

    // MINT0002
    // MINT0003
    public shared func testOwnerAndManager() : async {#success; #fail : Text} {
        D.print("running testOwner");

        let owner = Principal.toText(Principal.fromActor(this));

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        let suite = S.suite("test owner and manager", [

            S.test("owner is found", (
                switch(await canister.collection_nft_origyn(null)){
                    case(#err(err)){
                        "unexpected error" # debug_show(err);
                    };
                    case(#ok(res)){
                        switch(res.owner){
                            case(null){"no owner"};
                            case(?val){Principal.toText(val);};
                        };
                        
                    };
                } ), M.equals<Text>(T.text(owner))),
            S.test("manager is found", switch(await canister.collection_nft_origyn(null)){
                    case(#err(err)){
                        99999;
                    };
                    case(#ok(res)){
                        switch(res.managers){
                            case(null){88888};
                            case(?val){val.size()};
                        };
                        
                    };
                } , M.equals<Nat>(T.nat(0))),
        ]);

        S.run(suite);

        return #success;
    };
    
    //MINT0004, MINT0005, MINT0006, MINT0007, MINT0008, MINT0009, MINT0010, MINT0011, MINT0013, MINT0014, MINT0016, MINT0017, MINT0018
    public shared func testStage() : async {#success; #fail : Text} {
        D.print("running teststage");

        let a_wallet = await TestWalletDef.test_wallet();

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        //MINT0014
        let a_wallet_try_publish = await a_wallet.try_publish_meta(Principal.fromActor(canister));

        D.print("calling stage");

        //MINT0007, MINT0008
        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this));
        D.print("finished stage");
        D.print(debug_show(standardStage.0));

        let test_metadata = await canister.nft_origyn("1");


        


        //MINT0016
        let a_wallet_try_file_publish = await a_wallet.try_publish_chunk(Principal.fromActor(canister));

        //MINT0018
        let a_wallet_try_get_nft = await a_wallet.try_get_nft(Principal.fromActor(canister), "1");

        //MINT0025
        let a_wallet_try_get_bearer = await a_wallet.try_get_bearer(Principal.fromActor(canister));


        //MINT0009
        D.print("this one should have content");
        D.print(debug_show(Principal.fromActor(canister)));
        let fileStage2 = await canister.stage_library_nft_origyn({
            token_id = "1" : Text;
            library_id = "page" : Text;
            filedata  = #Empty;
            chunk = 1;
            content = Conversion.valueToBlob(#Text("nice to meet you"));
        });

        //MINT0019 - you can now upload here but must provide proper metadata and have storagebthis will fail with id not found
        let fileStage3 = await canister.stage_library_nft_origyn({
            token_id = "1" : Text;
            library_id = "1" : Text;
            filedata  = #Empty;
            chunk = 1;
            content = Conversion.valueToBlob(#Text("nice to meet you"));
        });

        D.print("trying to upload before meta" # debug_show(fileStage3));
        //MINT0010
        let fileStageResult = await canister.chunk_nft_origyn({token_id = "1"; library_id = "page"; chunk = ?0;});
        D.print(debug_show(fileStageResult));
        
        let fileStageResult2 = await canister.chunk_nft_origyn({token_id = "1"; library_id = "page"; chunk = ?1;});
        D.print(debug_show(fileStageResult2));

        

        let fileStageResultDenied = switch(await a_wallet.try_get_chunk(Principal.fromActor(canister),"1","page",0)){
            case(#ok(data)){
                "Should not have returned data";
            };
            case(#err(data)){
                "Proper Error occured";
            };
        };

        D.print("filestage result finished");
        //MINT0004
        let fail_stage_because_id = await canister.stage_nft_origyn({metadata = #Class([
            
            {name = "primary_asset"; value=#Text("page"); immutable= true},
            {name = "preview"; value=#Text("page"); immutable= true},
            {name = "experience"; value=#Text("page"); immutable= true},
            {name = "hidden"; value=#Text("page"); immutable= true},
            {name = "library"; value=#Array(#thawed([
                #Class([
                    {name = "library_id"; value=#Text("page"); immutable= true},
                    {name = "title"; value=#Text("page"); immutable= true},
                    {name = "location_type"; value=#Text("canister"); immutable= true},
                    {name = "location"; value=#Text("https://" # Principal.toText(Principal.fromActor(canister)) # ".raw.ic0.app/_/1/_/page"); immutable= true},
                    {name = "content_type"; value=#Text("text/html; charset=UTF-8"); immutable= true},
                    {name = "content_hash"; value=#Bytes(#frozen([0,0,0,0])); immutable= true},
                    {name = "size"; value=#Nat(4); immutable= true},
                    {name = "sort"; value=#Nat(0); immutable= true},
                ])
            ])); immutable= true},
            {name = "owner"; value=#Principal(Principal.fromActor(canister)); immutable= false}
        ])});

        D.print("fail_stage_because_id result finished");

        //MINT0006
        let fail_stage_because_system = await canister.stage_nft_origyn({metadata = #Class([
            {name = "id"; value=#Text("2"); immutable= true},
            {name = "primary_asset"; value=#Text("page"); immutable= true},
            {name = "preview"; value=#Text("page"); immutable= true},
            {name = "experience"; value=#Text("page"); immutable= true},
            {name = "library"; value=#Array(#thawed([
                #Class([
                    {name = "library_id"; value=#Text("page"); immutable= true},
                    {name = "title"; value=#Text("page"); immutable= true},
                    {name = "location_type"; value=#Text("canister"); immutable= true},
                    {name = "location"; value=#Text("https://" # Principal.toText(Principal.fromActor(canister)) # ".raw.ic0.app/_/1/_/page"); immutable= true},
                    {name = "content_type"; value=#Text("text/html; charset=UTF-8"); immutable= true},
                    {name = "content_hash"; value=#Bytes(#frozen([0,0,0,0])); immutable= true},
                    {name = "size"; value=#Nat(4); immutable= true},
                    {name = "sort"; value=#Nat(0); immutable= true},
                ])
            ])); immutable= true},
            {name = "owner"; value=#Principal(Principal.fromActor(canister)); immutable= false},
            //below is what we are testing
            {name = "__system"; value=#Class([
                {name = "status"; value=#Text("minted"); immutable=false;}
            ]); immutable = false}
        ])});

        D.print("fail_stage_because_system result finished");

        let test_metadata_replace_command = await canister.stage_nft_origyn({metadata = #Class([
            {name = "id"; value=#Text("1"); immutable= true},
            {name = "primary_asset"; value=#Text("page2"); immutable= true},
            {name = "preview"; value=#Text("page"); immutable= true},
            {name = "experience"; value=#Text("page"); immutable= true},
            {name = "library"; value=#Array(#thawed([
                #Class([
                    {name = "library_id"; value=#Text("page2"); immutable= true},
                    {name = "title"; value=#Text("page"); immutable= true},
                    {name = "location_type"; value=#Text("canister"); immutable= true},
                    {name = "location"; value=#Text("https://" # Principal.toText(Principal.fromActor(canister)) # ".raw.ic0.app/_/1/_/page"); immutable= true},
                    {name = "content_type"; value=#Text("text/html; charset=UTF-8"); immutable= true},
                    {name = "content_hash"; value=#Bytes(#frozen([0,0,0,0])); immutable= true},
                    {name = "size"; value=#Nat(4); immutable= true},
                    {name = "sort"; value=#Nat(0); immutable= true},
                    {name = "read"; value=#Text("public"); immutable= false},

                ])
            ])); immutable= true},
            {name = "owner"; value=#Principal(Principal.fromActor(canister)); immutable= false}
        ])});
        
       D.print("result from trying to replace the nft was");
       D.print(debug_show(test_metadata_replace_command));

        let test_metadata_replace = await canister.nft_origyn("1");

        let suite = S.suite("test staged Nft", [

            S.test("retult is id", switch(standardStage.0){case(#ok(res)){res};case(#err(err)){"error"};}, M.equals<Text>(T.text("1"))), //MINT0007
            S.test("fail if no id", switch(fail_stage_because_id){case(#ok(res)){res};case(#err(err)){"fail_expected"};}, M.equals<Text>(T.text("fail_expected"))), //MINT0004
            S.test("fail if __system", switch(fail_stage_because_system){case(#ok(res)){res};case(#err(err)){"fail_expected"};}, M.equals<Text>(T.text("fail_expected"))), //MINT0006
            S.test("file stage succeded", switch(standardStage.1){case(#ok(res)){Principal.toText(res)};case(#err(err)){"aaaaa-aa"}}, M.equals<Text>(T.text(Principal.toText(Principal.fromActor(canister))))), //MINT0008
            S.test("file stage query works", switch(fileStageResult){
                case(#ok(res)){
                    switch(res){
                        case(#remote(redirect)){"unexpected redirect"};
                        case(#chunk(res)){
                    
                            if((switch(res.current_chunk){case(?val){val};case(null){9999999}}) + 1 == res.total_chunks){
                                "unexpectd eof chunks";
                            } else {
                                Conversion.bytesToText(Blob.toArray(res.content));
                            }
                        };
                    };
                    
                };
                case(#err(err)){err.flag_point};
                }, M.equals<Text>(T.text("hello world"))), //MINT0006
            S.test("file stage query works", switch(fileStageResult2){
                case(#ok(res)){
                    switch(res){
                        case(#remote(redirect)){"unexpected redirect"};
                        case(#chunk(res)){
                            if((switch(res.current_chunk){case(?val){val};case(null){9999999}}) + 1 == res.total_chunks){
                            Conversion.bytesToText(Blob.toArray(res.content));
                            } else {
                                "unexpecte not eof";
                            }
                        };
                    };
                   
                };
                case(#err(err)){err.flag_point};
                }, M.equals<Text>(T.text("nice to meet you"))), //MINT0009
            S.test("file stage cannot be viewed by non owner", fileStageResultDenied, M.equals<Text>(T.text("Proper Error occured"))), //MINT0011
            S.test("file stage reports chunks", switch(fileStageResult2){
                case(#ok(res)){
                    switch(res){
                        case(#remote(redirect)){999999};
                        case(#chunk(res)){
                            res.total_chunks;
                        };
                    };
                };
                case(#err(err)){999};
                }, M.equals<Nat>(T.nat(2))), //MINT0013
            S.test("cant publish metadata for someone else", switch(a_wallet_try_publish){
                case(#ok(res)){
                    "shoundnt be able to publish"
                };
                case(#err(err)){
                    D.print(debug_show(err));
                    err.text;
                };
                }, M.equals<Text>(T.text("unauthorized access"))), //MINT0014
            S.test("cant publish file for someone else", switch(a_wallet_try_file_publish){
                case(#ok(res)){
                    "shoundnt be able to publish"
                };
                case(#err(err)){
                    D.print(debug_show(err));
                    err.text;
                };
                }, M.equals<Text>(T.text("unauthorized access"))), //MINT0016
            S.test("can see metadata after I stage", switch(test_metadata){
                case(#ok(res)){
                    switch(res.metadata){
                        case(#Class(data)){
                            if(data.size() ==13){ //check if a top level element was added to the structure

                                "Ok";
                            } else {
                                D.print("testing size");
                                D.print(debug_show(test_metadata));
                                D.print(debug_show(data));
                                D.print(debug_show(data.size()));
                                "data elements don't match wanted 13 found " # debug_show(data.size());

                            }
                        };
                        case (_){
                            "should have returned a class";
                        };
                    };
                };
                case(#err(err)){
                   D.print("error stage");
                   D.print(debug_show(err));
                    "shoundnt have an error";
                };
                }, M.equals<Text>(T.text("Ok"))), //MINT0017
            S.test("can't see metadata after stage from wallet", switch(a_wallet_try_get_nft){
                case(#ok(res)){
                    "shoundnt be able to get"
                };
                case(#err(err)){
                    D.print(debug_show(err));
                    err.text;
                };
                }, M.equals<Text>(T.text("Cannot find token."))), //MINT0018
            S.test("can't see bearer after stage from wallet", switch(a_wallet_try_get_bearer){
                case(#ok(res)){
                    "shoundnt be able to get"
                };
                case(#err(err)){
                    D.print(debug_show(err));
                    err.text;
                };
                }, M.equals<Text>(T.text("Cannot find token."))), //MINT0025
            S.test("can update metadata", switch(test_metadata_replace){
                case(#ok(res)){
                    switch(Properties.getClassProperty(res.metadata,"primary_asset")){
                        case(null){
                            "should have this property";
                        };
                        case(?val){
                            Conversion.valueToText(val.value);
                        }
                    }
                };
                case(#err(err)){
                   D.print("err for test metadata");
                   D.print(debug_show(err));
                    "shoundnt error"
                };
                }, M.equals<Text>(T.text("page2"))), //MINT0005
            S.test("cant upload library_id that doesnt exist metadata", switch(fileStage3){
                case(#ok(res)){
                    "that should not have worked because the library id wasnt planed and doesnt have storage"
                };
                case(#err(err)){
                    if(err.number == 1001){
                        "correct number"
                    } else{
                        "wrong error" # debug_show(err.number);
                    }
                };
                }, M.equals<Text>(T.text("correct number"))), //MINT0019
        ]);

        S.run(suite);

        return #success;
        
          

    };
    
    

    //MINT0021, MINT0001, MINT0024, MINT0022
    public shared func testMint() : async {#success; #fail : Text} {
        D.print("running testmint");

        debug{ D.print(debug_show(Principal.fromActor(this)))};

        let a_wallet = await TestWalletDef.test_wallet();

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        D.print("a mint canister");
        D.print(debug_show(Principal.fromActor(canister)));

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this));

        let fileStage2 = await canister.stage_library_nft_origyn({
            token_id = "1" : Text;
            library_id = "page" : Text;
            filedata  = #Empty;
            chunk = 1;
            content = Conversion.valueToBlob(#Text("nice to meet you"));
        });

        D.print("after file stage");
        
        //MINT0021
        let a_wallet_try_mint = await a_wallet.try_mint(Principal.fromActor(canister));
        D.print("a wallet try mint");

        //Mint0001
        let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(a_wallet)));

        D.print("mint attempt");

        //MINT0024
        let bearer_attempt = await canister.bearer_nft_origyn("1");

        D.print("berer attempt");

        //MINT0022
        let view_after_mint_attempt = await canister.nft_origyn("1");

        D.print("view after mint");

        //try to have awallet stage a post mint change

        let a_wallet_try_publish_change = await a_wallet.try_publish_change(Principal.fromActor(canister));

        //try to have canister change the primary asset...should work

        let test_metadata_replace_command = await canister.stage_nft_origyn({metadata = #Class([
            {name = "id"; value=#Text("1"); immutable= true},
            {name = "primary_asset"; value=#Text("page2"); immutable= true}
        ])});

        let test_metadata_replace_command_with_system = await canister.stage_nft_origyn({metadata = #Class([
            {name = "id"; value=#Text("1"); immutable= true},
            {name = "primary_asset"; value=#Text("page6"); immutable= true},
            
            {name = "__system"; value=#Array(#thawed([
                #Class([
                    {name = "library_id"; value=#Text("page2"); immutable= true},
                    {name = "title"; value=#Text("page"); immutable= true},
                    {name = "location_type"; value=#Text("canister"); immutable= true},
                    {name = "location"; value=#Text("https://" # Principal.toText(Principal.fromActor(canister)) # ".raw.ic0.app/_/1/_/page"); immutable= true},
                    {name = "content_type"; value=#Text("text/html; charset=UTF-8"); immutable= true},
                    {name = "content_hash"; value=#Bytes(#frozen([0,0,0,0])); immutable= true},
                    {name = "size"; value=#Nat(4); immutable= true},
                    {name = "sort"; value=#Nat(0); immutable= true},
                    {name = "read"; value=#Text("public"); immutable= false},

                ])
            ])); immutable= true},
            {name = "owner"; value=#Principal(Principal.fromActor(canister)); immutable= false}
        ])});

        let test_metadata_replace_command_with_library = await canister.stage_nft_origyn({metadata = #Class([
            {name = "id"; value=#Text("1"); immutable= true},
            {name = "primary_asset"; value=#Text("page3"); immutable= true},
            
            {name = "library"; value=#Array(#thawed([
                #Class([
                    {name = "library_id"; value=#Text("page2"); immutable= true},
                    {name = "title"; value=#Text("page"); immutable= true},
                    {name = "location_type"; value=#Text("canister"); immutable= true},
                    {name = "location"; value=#Text("https://" # Principal.toText(Principal.fromActor(canister)) # ".raw.ic0.app/_/1/_/page"); immutable= true},
                    {name = "content_type"; value=#Text("text/html; charset=UTF-8"); immutable= true},
                    {name = "content_hash"; value=#Bytes(#frozen([0,0,0,0])); immutable= true},
                    {name = "size"; value=#Nat(4); immutable= true},
                    {name = "sort"; value=#Nat(0); immutable= true},
                    {name = "read"; value=#Text("public"); immutable= false},

                ])
            ])); immutable= true},
            {name = "owner"; value=#Principal(Principal.fromActor(canister)); immutable= false}
        ])});

         let test_metadata_replace_command_with_owner = await canister.stage_nft_origyn({metadata = #Class([
            {name = "id"; value=#Text("1"); immutable= true},
            {name = "primary_asset"; value=#Text("page4"); immutable= true},
            {name = "owner"; value=#Principal(Principal.fromActor(canister)); immutable= false}
        ])});

         let test_metadata_replace_command_with_apps = await canister.stage_nft_origyn({metadata = #Class([
            {name = "id"; value=#Text("1"); immutable= true},
            {name = "primary_asset"; value=#Text("page5"); immutable= true},
            {name = "__apps"; value=#Array(#thawed([
                #Class([
                    {name = "app_id"; value=#Text("page2"); immutable= true},
                    {name = "title"; value=#Text("page"); immutable= true},
                    {name = "location_type"; value=#Text("canister"); immutable= true},
                    {name = "location"; value=#Text("https://" # Principal.toText(Principal.fromActor(canister)) # ".raw.ic0.app/_/1/_/page"); immutable= true},
                    {name = "content_type"; value=#Text("text/html; charset=UTF-8"); immutable= true},
                    {name = "content_hash"; value=#Bytes(#frozen([0,0,0,0])); immutable= true},
                    {name = "size"; value=#Nat(4); immutable= true},
                    {name = "sort"; value=#Nat(0); immutable= true},
                    {name = "read"; value=#Text("public"); immutable= false},

                ])
            ])); immutable= true},
            
        ])});

        let test_metadata_replace_command_with_immutable = await canister.stage_nft_origyn({metadata = #Class([
            {name = "id"; value=#Text("1"); immutable= true},
            {name = "preview"; value=#Text("page2"); immutable= true},
        ])});

        
        let view_after_update_attempt = await canister.nft_origyn("1");


        let suite = S.suite("test staged Nft", [

            S.test("fail if non owner mints", switch(a_wallet_try_mint){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 2000){
                    "correct number"
                } else{
                    "wrong error";
                }};}, M.equals<Text>(T.text("correct number"))), //MINT0021
            S.test("owner can mint", switch(mint_attempt){case(#ok(res)){res};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("1"))), //MINT0001
            S.test("user can see nft after mint", switch(view_after_mint_attempt){case(#ok(res)){"worked"};case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("worked"))), //MINT0022
            S.test("creator can assign owner on mint", switch(bearer_attempt){case(#ok(res)){
                switch(res){
                    case(#principal(res)){Principal.toText(res)};
                    case(_){"unexpected account type" # debug_show(res)};
                };}
                    ;case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text(Principal.toText(Principal.fromActor(a_wallet))))), //MINT0024
            S.test("fail if a_wallet_try_publish_change", switch(a_wallet_try_publish_change){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 2000){
                    "correct number"
                } else{
                    "wrong error";
                }};}, M.equals<Text>(T.text("correct number"))),


            S.test("owner can update", switch(test_metadata_replace_command){case(#ok(res)){res};case(#err(err)){"unexpected error: " # debug_show(err)};}, M.equals<Text>(T.text("1"))), //MINT0001
            
            S.test("user can see nft after update", switch(view_after_update_attempt){case(#ok(res)){
              
              

              switch(Properties.getClassProperty(res.metadata, "primary_asset")){
                case(null){"cant find primary"};
                case(?val){Conversion.valueToText(val.value)};
              };
              
              };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("page2"))), 
            

             S.test("fail if test_metadata_replace_command_with_system", switch(test_metadata_replace_command_with_system){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 2){
                    "correct number"
                } else{
                    "wrong error" # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),


             S.test("fail if test_metadata_replace_command_with_library", switch(test_metadata_replace_command_with_library){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 1002){
                    "correct number"
                } else{
                    "wrong error" # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            
            S.test("fail if test_metadata_replace_command_with_owner", switch(test_metadata_replace_command_with_owner){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 1002){
                    "correct number"
                } else{
                    "wrong error" # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),

            S.test("fail if test_metadata_replace_command_with_apps", switch(test_metadata_replace_command_with_apps){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 1002){
                    "correct number"
                } else{
                    "wrong error" # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),

            S.test("fail if test_metadata_replace_command_with_immutable", switch(test_metadata_replace_command_with_immutable){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 1000){
                    "correct number"
                } else{
                    "wrong error" # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            
        ]);

        S.run(suite);

        return #success;
        
          

    };

     public shared func testBuyItNow() : async {#success; #fail : Text} {
        D.print("running testBuyItNow");

        let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
        
        let dfx2 : DFXTypes.Service = actor(Principal.toText(dfx_ledger2));
        

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        let c_wallet = await TestWalletDef.test_wallet();
        
        let funding_result_a = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(a_wallet); subaccount= null};
            fee = ?200_000;
            memo = utils.memo_one;
            from_subaccount = null;
            created_at_time = null;
            amount =  1000 * 10 ** 8;});

        let funding_result_b = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(b_wallet); subaccount= null};
            fee = ?200_000;
            memo = utils.memo_one;
            from_subaccount = null;
            created_at_time = null;
            amount =  1000 * 10 ** 8;});
        let funding_result_b2 = await dfx2.icrc1_transfer({
            to =  {owner = Principal.fromActor(b_wallet); subaccount= null};
            fee = ?200_000;
            memo = utils.memo_one;
            from_subaccount = null;
            created_at_time = null;
            amount =  1000 * 10 ** 8;});
        let funding_result_c = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(c_wallet); subaccount= null};
            fee = ?200_000;
            memo = utils.memo_one;
            from_subaccount = null;
            created_at_time = null;
            amount =  1000 * 10 ** 8;});

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        let mode = canister.__set_time_mode(#test);
        let atime = canister.__advance_time(Time.now());

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning a minted item
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning an unminted item

        D.print("Minting");
        let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(this))); //mint to the test account
        let mint_attempt2 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this))); //mint to the test account

        
        D.print("start auction owner");
        //start an auction by owner
        let start_auction_attempt_owner = await canister.market_transfer_nft_origyn({token_id = "1";
            sales_config = {
                escrow_receipt = null;
                broker_id = null;
                pricing = #auction{
                    reserve = ?(10 * 10 ** 8);
                    token = #ic({
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    buy_now = ?(10 * 10 ** 8);
                    start_price = (10 * 10 ** 8);
                    start_date = 0;
                    ending = #date(get_time() + DAY_LENGTH);
                    min_increase = #amount(10*10**8);
                    allow_list = ?[Principal.fromActor(a_wallet), Principal.fromActor(b_wallet)];
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


        //fund c to send an invalid bid
        let c_wallet_send_tokens_to_canister = await c_wallet.send_ledger_payment(Principal.fromActor(dfx), (10 * 10 ** 8 ) + 200000, Principal.fromActor(canister));

        let block_c = switch(c_wallet_send_tokens_to_canister){
            case(#ok(ablock)){
                ablock;
            };
            case(#err(other)){
                D.print("ledger didnt work");
                return #fail("ledger didnt work");
            };
        };

        D.print("Sending real escrow now");
        let c_wallet_try_escrow_general_staged = await c_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 10 * 10 ** 8, "1", ?current_sales_id, null, null);

        //place a  bid by an invalid user 
        let c_wallet_try_bid_valid = await c_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 10*10**8, "1", current_sales_id, null);


        let c_balance_after_bad_bid = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(c_wallet)));
      

        
        //place escrow
        D.print("sending tokens to canisters");
        let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_payment(Principal.fromActor(dfx), (10 * 10 ** 8) + 200000, Principal.fromActor(canister));

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
        let a_wallet_try_escrow_general_staged = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 10 * 10 ** 8, "1", ?current_sales_id, null, null);

        D.print("should be done now");
        let a_balance_before_first = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        
        D.print("the balance before first is");
        D.print(debug_show(a_balance_before_first));

        //place a bid below start price

        let a_wallet_try_bid_below_start = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), 1*10**7, "1", current_sales_id, null);

        //todo: bid should be refunded

        let a_balance_after_bad_bid = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        D.print("a balance " # debug_show(a_balance_after_bad_bid));

        //restake after refund
        D.print("sending tokens to canisters 3");
        let a_wallet_send_tokens_to_canister2b = await a_wallet.send_ledger_payment(Principal.fromActor(dfx), ((10 * 10 ** 8) + 1) + 200000, Principal.fromActor(canister));

        D.print("sending tokens after refund" # debug_show(a_wallet_send_tokens_to_canister2b));
        let block2 = switch(a_wallet_send_tokens_to_canister2b){
            case(#ok(ablock)){
                ablock;
            };
            case(#err(other)){
                D.print("ledger didnt work");
                return #fail("ledger didnt work");
            };
        };

        D.print("Sending real escrow now 2");
        let a_wallet_try_escrow_general_staged2b = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, (10 * 10 ** 8) + 1, "1", ?current_sales_id, null, null);

        
        let a_balance_after_bad_bid2 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        D.print("a balance 2 " # debug_show(a_balance_after_bad_bid2));

        //try a bid in th wrong currency
        //place escrow
        D.print("sending tokens to canisters");
        let b_wallet_send_tokens_to_canister = await b_wallet.send_ledger_payment(Principal.fromActor(dfx2), (10 * 10 ** 8) + 200000, Principal.fromActor(canister));

        let block2b = switch(b_wallet_send_tokens_to_canister){
            case(#ok(ablock)){
                ablock;
            };
            case(#err(other)){
                D.print("ledger didnt work");
                return #fail("ledger didnt work");
            };
        };

        D.print("Sending escrow for wrong currency escrow now");
        let b_wallet_try_escrow_wrong_currency = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx2), null, 10 * 10 ** 8, "1", ?current_sales_id, null, null);

        
        //place a bid wiht wrong asset MKT0023
        let b_wallet_try_bid_wrong_asset = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx2), 10*10**8, "1", current_sales_id, null);

        //try starting again//should fail MKT0018
        let end_date = get_time() + DAY_LENGTH;
        D.print("end date is ");
        D.print(debug_show(end_date));
        //todo: write test
        

        //place a valid bid MKT0027
        let a_wallet_try_bid_valid = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), (10*10**8) + 1, "1", current_sales_id, null);


        let a_balance_after_bad_bid4 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        D.print("a balance 4 " # debug_show(a_balance_after_bad_bid2));

        //check transaction log for bid MKT0033, TRX0005
        let a_history_1 = await canister.history_nft_origyn("1", null, null); //gets all history

         //check transaction log for bid MKT0033, TRX0005
        let a_balance = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet))); //gets all history

        D.print("withdraw during bid");
        //todo: attempt to withdraw escrow but it should be gone
        let a_withdraw_during_bid = await a_wallet.try_escrow_withdraw(Principal.fromActor(canister), Principal.fromActor(a_wallet), Principal.fromActor(dfx), Principal.fromActor(this), "1", 1 * 10 ** 8, null);

        D.print("passed this");
        //place escrow b
        let new_bid_val = 12*10**8;

        //try a bid in th wrong currency
        //place escrow
        D.print("sending tokens to canisters");
        let b_wallet_send_tokens_to_canister_correct_ledger = await b_wallet.send_ledger_payment(Principal.fromActor(dfx), new_bid_val + 200000, Principal.fromActor(canister));

        D.print("did the payment? ");
        D.print(debug_show(b_wallet_send_tokens_to_canister_correct_ledger));

        let block2_b = switch(b_wallet_send_tokens_to_canister_correct_ledger){
            case(#ok(ablock)){
                ablock;
            };
            case(#err(other)){
                D.print("ledger didnt work");
                return #fail("ledger didnt work");
            };
        };

        D.print("Sending escrow for correct currency escrow now");
        let b_wallet_try_escrow_correct_currency = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, new_bid_val, "1", ?current_sales_id, null, null);

        D.print("did the deposit work? ");
        D.print(debug_show(b_wallet_try_escrow_correct_currency));


        let b_balance_after_deposit = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet))); //gets all history

       

        //place a second bid - should fail since closed
        let b_wallet_try_bid_valid = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), new_bid_val, "1", current_sales_id, null);


        //advance time
        let time_result = await canister.__advance_time(end_date + 1);
        D.print("new time");
        D.print(debug_show(time_result));


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

        //check transaction log for sale
        let a_history_3 = await canister.history_nft_origyn("1", null, null); //gets all history

         let suite = S.suite("test staged Nft", [

             S.test("test mint attempt", switch(mint_attempt){case(#ok(res)){
                
                "correct response";
                
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), 
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
            S.test("fail if bid not on allow list", switch(c_wallet_try_bid_valid){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 2000){ 
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),

            S.test("nft balance after sale to bad user is 0", switch(c_balance_after_bad_bid){case(#ok(res)){
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
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("found empty record"))), //todo: NFT-94
           
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
              S.test("bid is succesful", switch(a_wallet_try_bid_valid){case(#ok(res)){
                 D.print("as bid");
                 D.print(debug_show(a_wallet_try_bid_valid));
               switch(res.txn_type){
                   case(#sale_ended(details)){
                       if(Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and
                            details.amount == ((10*10**8) + 1) and
                            (switch(details.sale_id){case(null){"x"};case(?val){val}}) == current_sales_id and
                            Types.account_eq(details.seller, #principal(Principal.fromActor(this))) and
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
                       D.print("bad transaction bid " # debug_show(res));
                       "bad transaction bid";
                   };
               }; 
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //MKT0027
            S.test("transaction history has the bid", switch(a_history_1){case(#ok(res)){
               
               D.print("where ismy history");
               D.print(debug_show(a_history_1));
               switch(res[res.size()-1].txn_type){ 
                   case(#sale_ended(details)){
                       if(Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and
                            details.amount == ((10*10**8) + 1) and
                            details.sale_id == ?current_sales_id and
                            Types.token_eq(details.token, #ic({
                                canister = (Principal.fromActor(dfx)); 
                                standard = #Ledger;
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
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //TRX0005, MKT0033
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
           
           
            
             S.test("transaction history have the transfer", 
                switch(a_history_3){
                    case(#ok(res)){
                
                
                        switch(res[res.size()-1].txn_type){
                            case(#sale_ended(details)){
                                if(Types.account_eq(details.buyer, #principal(Principal.fromActor(a_wallet))) and
                                        details.amount == ((10*10**8) + 1) and
                                        details.sale_id == ?current_sales_id and
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
                        };
                    
                    };
                    case(#err(err)){"unexpected error: " # err.flag_point};
                }, M.equals<Text>(T.text("correct response"))), //todo: make a user story for adding a #sale_ended to the end of transaction log
            S.test("fail if auction already over ", switch(end_again){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 2000){ //new owner so unauthorized
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), //todo: create user story for sale over
            S.test("fail if escrow is for the current winning bid", switch(a_withdraw_during_bid){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000){ //no escrow found
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-76

            S.test("fail if escrow is for the winning bid a withdraw", switch(a_withdraw_during_win){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 3000){ //wont be able to find it because it has been zeroed out.
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
            }};}, M.equals<Text>(T.text("correct number"))), // NFT-110
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
           
            
            
                
         ]);

         S.run(suite);

        return #success;
        
          

    };

    public shared func testKYC() : async {#success; #fail : Text} {
        D.print("running KYC");

        let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
        
        let dfx2 : DFXTypes.Service = actor(Principal.toText(dfx_ledger2));
        

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        let c_wallet = await TestWalletDef.test_wallet();
        
        let funding_result_a = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(a_wallet); subaccount= null};
            fee = ?200_000;
            memo = utils.memo_one;
            from_subaccount = null;
            created_at_time = null;
            amount =  1000 * 10 ** 8;});

        let funding_result_b = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(b_wallet); subaccount= null};
            fee = ?200_000;
            memo = utils.memo_one;
            from_subaccount = null;
            created_at_time = null;
            amount =  1000 * 10 ** 8;});
        let funding_result_b2 = await dfx2.icrc1_transfer({
            to =  {owner = Principal.fromActor(b_wallet); subaccount= null};
            fee = ?200_000;
            memo = utils.memo_one;
            from_subaccount = null;
            created_at_time = null;
            amount =  1000 * 10 ** 8;});
        let funding_result_c = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(c_wallet); subaccount= null};
            fee = ?200_000;
            memo = utils.memo_one;
            from_subaccount = null;
            created_at_time = null;
            amount =  1000 * 10 ** 8;});

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        let kyc_service = await KYCService.kyc_service(?3);

        let mode = canister.__set_time_mode(#test);
        let atime = canister.__advance_time(Time.now());

        let standardStage_collection = await utils.buildCollection( 
            canister, 
            Principal.fromActor(canister), 
            Principal.fromActor(canister),
            Principal.fromActor(this),
            2048000);

        let add_kyc = await canister.collection_update_nft_origyn(#UpdateMetadata("com.origyn.kyc_canister", ?#Principal(Principal.fromActor(kyc_service)), false));

        D.print("able to add kyc  " # debug_show(add_kyc));

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning a minted item
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this)); //for auctioning an unminted item

        D.print("Minting");
        let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(this))); //mint to the test account
        let mint_attempt2 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this))); //mint to the test account

        
        D.print("start auction owner");
        //start an auction by owner
        let start_auction_attempt_owner = await canister.market_transfer_nft_origyn({token_id = "1";
            sales_config = {
                escrow_receipt = null;
                broker_id = null;
                pricing = #auction{
                    reserve = ?(10 * 10 ** 8);
                    token = #ic({
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    buy_now = ?(10 * 10 ** 8);
                    start_price = (10 * 10 ** 8);
                    start_date = 0;
                    ending = #date(get_time() + DAY_LENGTH);
                    min_increase = #amount(10*10**8);
                    allow_list = ?[Principal.fromActor(a_wallet), Principal.fromActor(b_wallet)];
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
        D.print("sending tokens to canisters");

        let a_wallet_send_tokens_to_canister = await a_wallet.send_ledger_payment(Principal.fromActor(dfx), (20 * 10 ** 8) + 200000, Principal.fromActor(canister));

        D.print("does a have tokens" # debug_show(a_wallet_send_tokens_to_canister));

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
        let a_wallet_try_escrow_general_staged = await a_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, 10 * 10 ** 8, "1", ?current_sales_id, null, null);

        D.print("sending real escrow" # debug_show(a_wallet_try_escrow_general_staged));

        let block2 = switch(a_wallet_send_tokens_to_canister){
            case(#ok(ablock)){
                ablock;
            };
            case(#err(other)){
                D.print("ledger didnt work");
                return #fail("ledger didnt work");
            };
        };

        //place a bid to fail kyc
        let a_wallet_try_bid_valid = await a_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), (10*10**8), "1", current_sales_id, null);


        D.print("a try bid " # debug_show(a_wallet_try_bid_valid));


        let a_balance_after_bad_bid4 = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));


        let dfx_a_balance_after_bad_bid = await dfx.icrc1_balance_of({owner = Principal.fromActor(a_wallet); subaccount= null});

        D.print("a balance 4 " # debug_show(dfx_a_balance_after_bad_bid));

        //check transaction log for returned escrow
        let a_history_1 = await canister.history_nft_origyn("1", null, null); //gets all history

       
        D.print("passed this");
        //place escrow b
        let new_bid_val = 12*10**8;

        //try a bid in th wrong currency
        //place escrow
        D.print("sending tokens to canisters");
        let b_wallet_send_tokens_to_canister_correct_ledger = await b_wallet.send_ledger_payment(Principal.fromActor(dfx), new_bid_val + 200000, Principal.fromActor(canister));

        D.print("did the payment? ");
        D.print(debug_show(b_wallet_send_tokens_to_canister_correct_ledger));

        let block2_b = switch(b_wallet_send_tokens_to_canister_correct_ledger){
            case(#ok(ablock)){
                ablock;
            };
            case(#err(other)){
                D.print("ledger didnt work");
                return #fail("ledger didnt work");
            };
        };

        D.print("Sending escrow for correct currency escrow now");
        let b_wallet_try_escrow_correct_currency = await b_wallet.try_escrow_specific_staged(Principal.fromActor(this), Principal.fromActor(canister), Principal.fromActor(dfx), null, new_bid_val, "1", ?current_sales_id, null, null);

        D.print("did the deposit work? ");
        D.print(debug_show(b_wallet_try_escrow_correct_currency));

        //b should bit and should pass kyc
        let b_wallet_try_bid_valid = await b_wallet.try_bid(Principal.fromActor(canister), Principal.fromActor(this), Principal.fromActor(dfx), (10*10**8) + 1, "1", current_sales_id, null);

       
        //NFT-94 check ownership
        //check balance and make sure we see the nft
        let a_balance_after_close = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

         //NFT-94 check ownership
        //check balance and make sure we see the nft
        let b_balance_after_close = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet)));
        
        // //MKT0029, MKT0036
        let a_sale_status_over_new_owner = await canister.nft_origyn("1");

        //check transaction log for sale
        let a_history_3 = await canister.history_nft_origyn("1", null, null); //gets all history

         let suite = S.suite("test staged Nft", [

             
            S.test("fail if kyc asset", switch(a_wallet_try_bid_valid){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 4011){ //wrong asset
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //MKT0024
              S.test("b kyc succesful", switch(b_wallet_try_bid_valid){case(#ok(res)){
                 D.print("as bid");
                 D.print(debug_show(b_wallet_try_bid_valid));
               switch(res.txn_type){
                   case(#sale_ended(details)){
                       if(Types.account_eq(details.buyer, #principal(Principal.fromActor(b_wallet))) and
                            details.amount == ((10*10**8) + 1) and
                            (switch(details.sale_id){case(null){"x"};case(?val){val}}) == current_sales_id and
                            Types.account_eq(details.seller, #principal(Principal.fromActor(this))) and
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
                       D.print("bad transaction bid " # debug_show(res));
                       "bad transaction bid";
                   };
               }; 
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //MKT0027
            S.test("transaction history has the bid", switch(a_history_3){case(#ok(res)){
               
               D.print("where ismy history");
               D.print(debug_show(a_history_1));
               switch(res[res.size()-1].txn_type){ 
                   case(#sale_ended(details)){
                       if(Types.account_eq(details.buyer, #principal(Principal.fromActor(b_wallet))) and
                            details.amount == ((10*10**8) + 1) and
                            details.sale_id == ?current_sales_id and
                            Types.token_eq(details.token, #ic({
                                canister = (Principal.fromActor(dfx)); 
                                standard = #Ledger;
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
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //TRX0005, MKT0033
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
                if(Types.account_eq(new_owner, #principal(Principal.fromActor(b_wallet)))){
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
            
            
                
         ]);

         S.run(suite);

        return #success;
        
          

    };

    

}