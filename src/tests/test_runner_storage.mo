import Blob "mo:base/Blob";
import D "mo:base/Debug";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import C "mo:matchers/Canister";
import Conversion "mo:candy/conversion";
import M "mo:matchers/Matchers";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";

import StorageCanisterDef "../origyn_storage_reference/storage_canister";
import Types "../origyn_nft_reference/types";
import utils "test_utils";


shared (deployer) actor class test_runner(dfx_ledger: Principal, dfx_ledger2: Principal) = this {
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
        
        // let Instant_Test = await Instant.testInstantTransfer();
        //D.print("in storage tezt" # debug_show(canister_factory));
        g_canister_factory := actor(Principal.toText(canister_factory));
        g_storage_factory := actor(Principal.toText(storage_factory));

        let suite = S.suite("test nft", [
            S.test("testAllocation", switch(await testAllocation()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testCollectionLibrary", switch(await testCollectionLibrary()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testLibraryPostMint", switch(await testLibraryPostMint()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            //S.test("testMarketTransfer", switch(await testMarketTransfer()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            //S.test("testOwnerTransfer", switch(await testOwnerTransfer()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
                      
            ]);
        S.run(suite);

        return #success;
    };

    public shared func testLibraryPostMint() : async {#success; #fail : Text} {
        //D.print("running testAllocation");

        
         //D.print("have new principal " # debug_show(newPrincipal));

        let newPrincipal_b = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = ?4096000;
        });

       
         //D.print("have new principal " # debug_show(newPrincipal_b));

        let canister_b : Types.Service =  actor(Principal.toText(newPrincipal_b));
       
        D.print("making a storage container");
        let storage_b = await StorageCanisterDef.Storage_Canister({
            gateway_canister = Principal.fromActor(canister_b);
            network = null;
            storage_space = ?4096000;
        });

        let storage_c = await StorageCanisterDef.Storage_Canister({
            gateway_canister = Principal.fromActor(canister_b);
            network = null;
            storage_space = ?4096000;
        });

             //D.print("have new storage " # debug_show(newPrincipal));

        let new_storage_request = await canister_b.manage_storage_nft_origyn(#add_storage_canisters([
            (Principal.fromActor(storage_b), 4096000, (0,0,1))
        ]));

        let new_storage_request2 = await canister_b.manage_storage_nft_origyn(#add_storage_canisters([
            (Principal.fromActor(storage_c), 4096000, (0,0,1))
        ]));

        D.print("calling storage stuff");

       
        let standardStage = await utils.buildStandardNFT("1", canister_b, Principal.fromActor(canister_b), 2048000, false);
        //let standardStage2 = await utils.buildStandardNFT("2", canister_b, Principal.fromActor(canister_b), 2048000, false);
        //let standardStage3 = await utils.buildStandardNFT("3", canister_b, Principal.fromActor(canister_b), 2048000, false);
        //let standardStage4 = await utils.buildStandardNFT("4", canister_b, Principal.fromActor(canister_b), 2048000, false);

        //mint 2
        let mint_attempt1 = await canister_b.mint_nft_origyn("1", #principal(Principal.fromActor(this)));
        D.print("mint attempt result " # debug_show(mint_attempt1));
        ///let mint_attempt2 = await canister_b.mint_nft_origyn("2", #principal(Principal.fromActor(this)));
        //mint 2
        //let mint_attempt3 = await canister_b.mint_nft_origyn("3", #principal(Principal.fromActor(this)));
        //let mint_attempt4 = await canister_b.mint_nft_origyn("4", #principal(Principal.fromActor(this)));
        

        //try to add a library

        let library_add = await canister_b.stage_library_nft_origyn({
            token_id = "1" : Text;
            library_id = "aftermint" : Text;
            filedata  = #Class([
                    {name = "library_id"; value=#Text("aftermint"); immutable= true},
                    {name = "title"; value=#Text("page"); immutable= true},
                    {name = "location_type"; value=#Text("canister"); immutable= true},
                    {name = "location"; value=#Text("https://" # Principal.toText(Principal.fromActor(canister_b)) # ".raw.ic0.app/_/1/_/page"); immutable= true},
                    {name = "content_type"; value=#Text("text/html; charset=UTF-8"); immutable= true},
                    {name = "content_hash"; value=#Bytes(#frozen([0,0,0,0])); immutable= true},
                    {name = "size"; value=#Nat(2048000); immutable= true},
                    {name = "sort"; value=#Nat(0); immutable= true},
                    {name ="read";value = #Text("public"); immutable = false}
                ]);
            chunk = 0;
            content = Conversion.valueToBlob(#Text("after mint"));
        });


        
        let get_gatway_chunks = await canister_b.chunk_nft_origyn({
            token_id = "1";
            library_id = "aftermint";
            chunk = ?0;
        });

        let storage_metrics_canister  = await canister_b.storage_info_nft_origyn();
        let storage_metrics_storageb  = await storage_b.storage_info_nft_origyn();
        let storage_metrics_storagec  = await storage_c.storage_info_nft_origyn();



       

        let suite = S.suite("test library post mint for NFT", [

             S.test("can stage library after mint", 
                
                switch(library_add){
                    case(#ok(res)){
                        
                        
                        "expected success";
                       
                   
                    };
                    case(#err(err)){
                            "wrong error " # debug_show(err);
                    };

                }, M.equals<Text>(T.text("expected success"))),
            S.test("can get loaded aset", 
                
                switch(get_gatway_chunks){
                    case(#ok(res)){
                        
                        D.print("gateway chunk" # debug_show(res));
                        "expected success";
                       
                   
                    };
                    case(#err(err)){
                            "wrong error " # debug_show(err);
                    };

                }, M.equals<Text>(T.text("expected success"))),
          
           /*  S.test("staging with non enough space should fail", 
                
                switch(standardStage.0){
                    case(#ok(res)){
                        "unexpected success";
                    };
                    case(#err(err)){
                        if(err.number == 1001){
                            "expected error";
                        } else {
                            "wrong error " # debug_show(standardStage);
                        };
                    };

                }, M.equals<Text>(T.text("expected error"))),
            S.test("can provide more storage to canister", switch(new_storage_request){
                case(#ok(res)){
                //D.print("found blind market response");
                //D.print(debug_show(res));
                    switch(res){
                        case(#add_storage_canisters(val)){
                            if(val.0 == 8192000 and val.1 == 8192000){
                                "space matches"
                            } else {
                                "bad size " # debug_show(new_storage_request);
                            };
                        };
                        case(_){
                            "bad response " # debug_show(new_storage_request);
                        }
                    };
                    
                };
                case(#err(err)){"unexpected error: " # err.flag_point # debug_show(err)};}
                , M.equals<Text>(T.text("space matches"))), //MKT0007, MKT0014
             
            S.test("allocated space should be 8192000", switch(currentStateCanister_b){case(
                #ok(res)){
                    Nat.toText(switch(res.allocated_storage){case(null){0};case(?val){val}})};
                case(#err(err)){
                    "error " # debug_show(err);
                }}, M.equals<Text>(T.text("8192000"))), //NFT-225
            S.test("staging with  enough space should pass", 
                
                switch(standardStage_b.0){
                    case(#ok(res)){
                        "expected success";
                    };
                    case(#err(err)){
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),
            S.test("staging library should put first two on gateway", 
                
                switch(standardStage_b.1, standardStage_b.2){
                    case(#ok(res), #ok(res2)){
                        if((res == Principal.fromActor(canister_b)) and (res2 == Principal.fromActor(canister_b))){
                            "expected success";
                        } else {
                            "wrong principals " # debug_show(standardStage_b);
                        };
                    };
                    case(_,_){
                            "wrong error " # debug_show(standardStage);
                    };

                }, M.equals<Text>(T.text("expected success"))),
            S.test("staging library should put third on storage", 
                
                
                switch(standardStage_b.3){
                    case(#ok(res)){
                        //D.print("testing what should have worked " # debug_show(standardStage_b));
                        if(res == Principal.fromActor(storage_b)){
                            "expected success";
                        } else {
                            "wrong pricnipal";
                        };
                    };
                    case(#err(err)){
                         //D.print("testing what should have worked " # debug_show(standardStage_b));
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),
                
            S.test("available space on sorage should be 2048000", 
                
                switch(storage_metrics_canister_b_after_stage){
                    case(#ok(res)){
                        if(res.allocated_storage == 4096000 and
                            res.available_space == 2048000){
                            "expected success";
                        }else {
                            "wrong space " # debug_show(res);
                        };
                        
                    };
                    case(#err(err)){
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),
             S.test("available space on gateway should be 0", 
                
                switch(gateway_metrics_canister_b_after_stage){
                    case(#ok(res)){
                        if(res.allocated_storage == 4096000 and
                            res.available_space == 0){
                            "expected success";
                        } else {
                            "wrong space " # debug_show(res);
                        };
                    };
                    case(#err(err)){
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),
            S.test("collection info should have correct info", 
                
                switch(currentStateCanister_b){
                    case(#ok(res)){
                        switch(res.allocated_storage, res.available_space){
                            case(?res1, ?res2){
                                if(res1 == 8192000 and
                                    res2 == 2048000){
                                    "expected success";
                                } else {
                                    "nope "
                                };
                            };
                            case(_,_){
                                "strange null";
                            };
                        };
                    };
                    case(#err(err)){
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),

            S.test("can get chunks from gateway", 
                
                switch(get_gatway_chunks){
                    case(#ok(res)){
                        switch(res){
                            case(#remote(redirect)){"unexpected remote"};
                            case(#chunk(res)){
                                if(Blob.equal(res.content, Blob.fromArray(Conversion.valueToBytes(#Text("hello world"))))){
                                    "hello world";
                                } else {
                                    "wrong content";
                                };
                            };
                        };
                    };
                    case(#err(err)){
                       
                            "wrong content " # debug_show(get_gatway_chunks);

                    };

                }, M.equals<Text>(T.text("hello world"))),
            S.test("do get pointer for storage", 
                
                switch(get_hidden_chunks){
                    case(#ok(res)){
                        switch(res){
                            case(#remote(remote_data)){
                                if(remote_data.canister == Principal.fromActor(storage_b) and
                                    remote_data.args.library_id == "hidden" and
                                    remote_data.args.token_id == "1" and
                                    (switch(remote_data.args.chunk){case(?val){val};case(null){9999}}) == 0){
                                        "correct redirect";
                                    } else {
                                        "bad redirect " # debug_show(remote_data);
                                    }

                            };
                            case(_){
                                "wrong result"
                            }
                        }
                    };
                    case(#err(err)){
                       
                            "wrong content " # debug_show(get_hidden_chunks);

                    };

                }, M.equals<Text>(T.text("correct redirect"))),
            S.test("can get chunks from storage", 
                
                switch(get_storage_chunks){
                    case(#ok(res)){
                        switch(res){
                            case(#remote(remote_data)){ "unexpected remote"};
                            case(#chunk(res)){
                                if(Blob.equal(res.content, Blob.fromArray(Conversion.valueToBytes(#Text("hidden hello world"))))){
                                    "hidden hello world";
                                }else {
                                    "somthing unexpected"
                                };
                            };
                        };
                    };
                    case(#err(err)){
                       
                            "wrong content " # debug_show(get_gatway_chunks);

                    };

                }, M.equals<Text>(T.text("hidden hello world"))) */
          
        ]);

        S.run(suite);

        return #success;
    };
    
    
    public shared func testAllocation() : async {#success; #fail : Text} {
        D.print("running testAllocation");


        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = ?4096000;
        });
        //D.print("have new principal " # debug_show(newPrincipal));

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

         //D.print("have new principal " # debug_show(newPrincipal));

        let newPrincipal_b = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = ?4096000;
        });
         D.print("have new principal " # debug_show(newPrincipal_b));

        let canister_b : Types.Service =  actor(Principal.toText(newPrincipal_b));

        let storage_b = await StorageCanisterDef.Storage_Canister({
            gateway_canister = Principal.fromActor(canister_b);
            network = null;
            storage_space = ?4096000;
        });

             D.print("have new storage " # debug_show(newPrincipal));


        D.print("calling storage stuff allocations");

        let initialCanisterSpace = await canister.storage_info_nft_origyn(); 

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 2048000, false);

        D.print("standardStage" # debug_show(standardStage));


        
        let new_storage_request = await canister_b.manage_storage_nft_origyn(#add_storage_canisters([
            (Principal.fromActor(storage_b), 4096000, (0,0,1))
        ]));

        D.print("new_storage_request" # debug_show(new_storage_request));

        D.print("staging b");
        let standardStage_b = await utils.buildStandardNFT("1", canister_b, Principal.fromActor(canister_b), 2048000, false);
        D.print("DONE staging b " # debug_show(standardStage_b));
        let currentStateToken = await canister.nft_origyn("1");

        let currentStateCanister = await canister.collection_nft_origyn(null);

        let currentStateCanister_b = await canister_b.collection_nft_origyn(null);

        let storage_metrics_canister_b_after_stage = await storage_b.storage_info_nft_origyn();

        let gateway_metrics_canister_b_after_stage = await canister_b.storage_info_nft_origyn();

        let get_gatway_chunks = await canister_b.chunk_nft_origyn({
            token_id = "1";
            library_id = "page";
            chunk = ?0;
        });


        let get_hidden_chunks = await canister_b.chunk_nft_origyn({
            token_id = "1";
            library_id = "hidden";
            chunk = ?0;
        });

        let storage_actor : Types.StorageService = actor(Principal.toText(Principal.fromActor(storage_b)));
        let get_storage_chunks = await storage_actor.chunk_nft_origyn({
            token_id = "1";
            library_id = "hidden";
            chunk = ?0;
        });

        let suite = S.suite("test allocation for NFT", [

            S.test("available space on canister should be", switch(initialCanisterSpace){case(
                #ok(res)){
                    Nat.toText(res.available_space)};
                case(#err(err)){
                    "error " # debug_show(err);
                }}, M.equals<Text>(T.text("4096000"))),
            S.test("staging with non enough space should fail", 
                
                switch(standardStage.0){
                    case(#ok(res)){
                        "unexpected success";
                    };
                    case(#err(err)){
                        if(err.number == 1001){
                            "expected error";
                        } else {
                            "wrong error " # debug_show(standardStage);
                        };
                    };

                }, M.equals<Text>(T.text("expected error"))),
            S.test("can provide more storage to canister", switch(new_storage_request){
                case(#ok(res)){
                //D.print("found blind market response");
                //D.print(debug_show(res));
                    switch(res){
                        case(#add_storage_canisters(val)){
                            if(val.0 == 8192000 and val.1 == 8192000){
                                "space matches"
                            } else {
                                "bad size " # debug_show(new_storage_request);
                            };
                        };
                        /* case(_){
                            "bad response " # debug_show(new_storage_request);
                        } */
                    };
                    
                };
                case(#err(err)){"unexpected error: " # err.flag_point # debug_show(err)};}
                , M.equals<Text>(T.text("space matches"))), //MKT0007, MKT0014
             
            S.test("allocated space should be 8192000", switch(currentStateCanister_b){case(
                #ok(res)){
                    Nat.toText(switch(res.allocated_storage){case(null){0};case(?val){val}})};
                case(#err(err)){
                    "error " # debug_show(err);
                }}, M.equals<Text>(T.text("8192000"))), //NFT-225
            S.test("staging with  enough space should pass", 
                
                switch(standardStage_b.0){
                    case(#ok(res)){
                        "expected success";
                    };
                    case(#err(err)){
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),
            S.test("staging library should put first two on gateway", 
                
                switch(standardStage_b.1, standardStage_b.2){
                    case(#ok(res), #ok(res2)){
                        if((res == Principal.fromActor(canister_b)) and (res2 == Principal.fromActor(canister_b))){
                            "expected success";
                        } else {
                            "wrong principals " # debug_show(standardStage_b);
                        };
                    };
                    case(_,_){
                            "wrong error " # debug_show(standardStage);
                    };

                }, M.equals<Text>(T.text("expected success"))),
            S.test("staging library should put third on storage", 
                
                
                switch(standardStage_b.3){
                    case(#ok(res)){
                        //D.print("testing what should have worked " # debug_show(standardStage_b));
                        if(res == Principal.fromActor(storage_b)){
                            "expected success";
                        } else {
                            "wrong pricnipal";
                        };
                    };
                    case(#err(err)){
                         //D.print("testing what should have worked " # debug_show(standardStage_b));
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),
                
            S.test("available space on storage should be 0", 
                
                switch(storage_metrics_canister_b_after_stage){
                    case(#ok(res)){
                        if(res.allocated_storage == 4096000 and
                            res.available_space == 0){
                            "expected success";
                        }else {
                            "wrong space " # debug_show(res);
                        };
                        
                    };
                    case(#err(err)){
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),
             S.test("available space on gateway should be 0", 
                
                switch(gateway_metrics_canister_b_after_stage){
                    case(#ok(res)){
                        if(res.allocated_storage == 4096000 and
                            res.available_space == 0){
                            "expected success";
                        } else {
                            "wrong space " # debug_show(res);
                        };
                    };
                    case(#err(err)){
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),
            S.test("collection info should have correct info", 
                
                switch(currentStateCanister_b){
                    case(#ok(res)){
                        switch(res.allocated_storage, res.available_space){
                            case(?res1, ?res2){
                                if(res1 == 8192000 and
                                    res2 == 0){
                                    "expected success";
                                } else {
                                    "nope " # debug_show((res1, res2));
                                };
                            };
                            case(_,_){
                                "strange null";
                            };
                        };
                    };
                    case(#err(err)){
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),

            S.test("can get chunks from gateway", 
                
                switch(get_gatway_chunks){
                    case(#ok(res)){
                        switch(res){
                            case(#remote(redirect)){"unexpected remote"};
                            case(#chunk(res)){
                                if(Blob.equal(res.content, Blob.fromArray(Conversion.valueToBytes(#Text("hello world"))))){
                                    "hello world";
                                } else {
                                    "wrong content";
                                };
                            };
                        };
                    };
                    case(#err(err)){
                       
                            "wrong content " # debug_show(get_gatway_chunks);

                    };

                }, M.equals<Text>(T.text("hello world"))),
            S.test("do get pointer for storage", 
                
                switch(get_hidden_chunks){
                    case(#ok(res)){
                        switch(res){
                            case(#remote(remote_data)){
                                if(remote_data.canister == Principal.fromActor(storage_b) and
                                    remote_data.args.library_id == "hidden" and
                                    remote_data.args.token_id == "1" and
                                    (switch(remote_data.args.chunk){case(?val){val};case(null){9999}}) == 0){
                                        "correct redirect";
                                    } else {
                                        "bad redirect " # debug_show(remote_data);
                                    }

                            };
                            case(_){
                                "wrong result"
                            }
                        }
                    };
                    case(#err(err)){
                       
                            "wrong content " # debug_show(get_hidden_chunks);

                    };

                }, M.equals<Text>(T.text("correct redirect"))),
            S.test("can get chunks from storage", 
                
                switch(get_storage_chunks){
                    case(#ok(res)){
                        switch(res){
                            case(#remote(remote_data)){ "unexpected remote"};
                            case(#chunk(res)){
                                if(Blob.equal(res.content, Blob.fromArray(Conversion.valueToBytes(#Text("hidden hello world"))))){
                                    "hidden hello world";
                                }else {
                                    "somthing unexpected"
                                };
                            };
                        };
                    };
                    case(#err(err)){
                       
                            "wrong content " # debug_show(get_gatway_chunks);

                    };

                }, M.equals<Text>(T.text("hidden hello world")))
          
        ]);

        S.run(suite);

        return #success;
    };


    public shared func testCollectionLibrary() : async {#success; #fail : Text} {
        //D.print("running testMarketTransfer");

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = ?4096000;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));



        let newPrincipal_b = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = ?4096000;
        });

        let canister_b : Types.Service =  actor(Principal.toText(newPrincipal_b));

        let storage_b = await StorageCanisterDef.Storage_Canister({
            gateway_canister = Principal.fromActor(canister_b);
            network = null;
            storage_space = ?8192000;
        });



        //D.print("calling stage");

        let initialCanisterSpace = await canister.storage_info_nft_origyn(); 

        let standardStage = await utils.buildStandardNFT("", canister, Principal.fromActor(canister), 2048000, false);


        
        let new_storage_request = await canister_b.manage_storage_nft_origyn(#add_storage_canisters([
            (Principal.fromActor(storage_b), 8192000, (0,0,1))
        ]));

        //D.print("staging b");
        let standardStage_b = await utils.buildStandardNFT("1", canister_b, Principal.fromActor(canister_b), 2048000, false);
        //D.print("DONE staging b " # debug_show(standardStage_b));

        let standardStage_b_collection = await utils.buildCollection( canister_b, Principal.fromActor(canister_b), Principal.fromActor(canister_b), Principal.fromActor(canister_b), 2048000);
        //D.print("DONE staging b " # debug_show(standardStage_b));

        let mint_attempt = await canister_b.mint_nft_origyn("1", #principal(Principal.fromActor(this)));

        let currentStateToken = await canister.nft_origyn("");

        let currentStateCanister = await canister.collection_nft_origyn(null);

        let currentStateCanister_b = await canister_b.collection_nft_origyn(null);

        let storage_metrics_canister_b_after_stage = await storage_b.storage_info_nft_origyn();

        let gateway_metrics_canister_b_after_stage = await canister_b.storage_info_nft_origyn();

        let get_gatway_chunks = await canister_b.chunk_nft_origyn({
            token_id = "1";
            library_id = "page";
            chunk = ?0;
        });


        let get_hidden_chunks = await canister_b.chunk_nft_origyn({
            token_id = "1";
            library_id = "hidden";
            chunk = ?0;
        });

        let get_gatway_chunks_collection = await canister_b.chunk_nft_origyn({
            token_id = "1";
            library_id = "collection_banner";
            chunk = ?0;
        });

        let storage_actor : Types.StorageService = actor(Principal.toText(Principal.fromActor(storage_b)));
        let get_storage_chunks = await storage_actor.chunk_nft_origyn({
            token_id = "1";
            library_id = "hidden";
            chunk = ?0;
        });


        let get_storage_chunks_banner = await storage_actor.chunk_nft_origyn({
            token_id = "";
            library_id = "collection_banner";
            chunk = ?0;
        });

        let suite = S.suite("test collection allocation", [

            S.test("available space on canister should be collection", switch(initialCanisterSpace){case(
                #ok(res)){
                    Nat.toText(res.available_space)};
                case(#err(err)){
                    "error " # debug_show(err);
                }}, M.equals<Text>(T.text("4096000"))),
            S.test("staging with non enough space should fail collection", 
                
                switch(standardStage.0){
                    case(#ok(res)){
                        "unexpected success";
                    };
                    case(#err(err)){
                        if(err.number == 1001){
                            "expected error";
                        } else {
                            "wrong error " # debug_show(standardStage);
                        };
                    };

                }, M.equals<Text>(T.text("expected error"))),
            S.test("can provide more storage to canister collection", switch(new_storage_request){
                case(#ok(res)){
                //D.print("found blind market response");
                //D.print(debug_show(res));
                    switch(res){
                        case(#add_storage_canisters(val)){
                            if(val.0 == 12_288_000 and val.1 == 12_288_000){
                                "space matches"
                            } else {
                                "bad size " # debug_show(new_storage_request);
                            };
                        };
                        /* case(_){
                            "bad response " # debug_show(new_storage_request);
                        } */
                    };
                    
                };
                case(#err(err)){"unexpected error: " # err.flag_point # debug_show(err)};}
                , M.equals<Text>(T.text("space matches"))), //MKT0007, MKT0014
             
            S.test("allocated space should be 12_288_000 collection", switch(currentStateCanister_b){case(
                #ok(res)){
                    Nat.toText(switch(res.allocated_storage){case(null){0};case(?val){val}})};
                case(#err(err)){
                    "error " # debug_show(err);
                }}, M.equals<Text>(T.text("12288000"))), //NFT-225
            S.test("staging with  enough space should pass collection", 
                
                switch(standardStage_b.0){
                    case(#ok(res)){
                        "expected success";
                    };
                    case(#err(err)){
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),
            S.test("staging library should put first two on gateway collection ", 
                
                switch(standardStage_b.1, standardStage_b.2){
                    case(#ok(res), #ok(res2)){
                        if((res == Principal.fromActor(canister_b)) and (res2 == Principal.fromActor(canister_b))){
                            "expected success";
                        } else {
                            "wrong principals " # debug_show(standardStage_b);
                        };
                    };
                    case(_,_){
                            "wrong error " # debug_show(standardStage);
                    };

                }, M.equals<Text>(T.text("expected success"))),
            S.test("staging library should put third on storage collection", 
                
                
                switch(standardStage_b.3){
                    case(#ok(res)){
                        //D.print("testing what should have worked " # debug_show(standardStage_b));
                        if(res == Principal.fromActor(storage_b)){
                            "expected success";
                        } else {
                            "wrong pricnipal";
                        };
                    };
                    case(#err(err)){
                         //D.print("testing what should have worked " # debug_show(standardStage_b));
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),
                
            S.test("available space on sorage should be 2048000 collection", 
                
                switch(storage_metrics_canister_b_after_stage){
                    case(#ok(res)){
                        if(res.allocated_storage == 8_192_000 and
                            res.available_space == 2_048_000){
                            "expected success";
                        }else {
                            "wrong space " # debug_show(res);
                        };
                        
                    };
                    case(#err(err)){
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),
             S.test("available space on gateway should be 0 collection", 
                
                switch(gateway_metrics_canister_b_after_stage){
                    case(#ok(res)){
                        if(res.allocated_storage == 4096000 and
                            res.available_space == 0){
                            "expected success";
                        } else {
                            "wrong space " # debug_show(res);
                        };
                    };
                    case(#err(err)){
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),
            S.test("collection info should have correct info collection", 
                
                switch(currentStateCanister_b){
                    case(#ok(res)){
                        switch(res.allocated_storage, res.available_space){
                            case(?res1, ?res2){
                                if(res1 == 12_288_000 and
                                    res2 == 2_048_000){
                                    "expected success";
                                } else {
                                    "nope " # debug_show((res1, res2))
                                };
                            };
                            case(_,_){
                                "strange null";
                            };
                        };
                    };
                    case(#err(err)){
                       
                            "wrong error " # debug_show(standardStage);

                    };

                }, M.equals<Text>(T.text("expected success"))),

            S.test("can get chunks from gateway collection", 
                
                switch(get_gatway_chunks){
                    case(#ok(res)){
                        switch(res){
                            case(#remote(redirect)){"unexpected remote"};
                            case(#chunk(res)){
                                if(Blob.equal(res.content, Blob.fromArray(Conversion.valueToBytes(#Text("hello world"))))){
                                    "hello world";
                                } else {
                                    "wrong content";
                                };
                            };
                        };
                    };
                    case(#err(err)){
                       
                            "wrong content " # debug_show(get_gatway_chunks);

                    };

                }, M.equals<Text>(T.text("hello world"))),
            S.test("can get chunks from gateway for collection collection", 
            

                switch(get_gatway_chunks_collection){
                    case(#ok(res)){
                        switch(res){
                            case(#remote(remote_data)){
                                if(remote_data.canister == Principal.fromActor(storage_b) and
                                    remote_data.args.library_id == "collection_banner" and
                                    remote_data.args.token_id == "" and
                                    (switch(remote_data.args.chunk){case(?val){val};case(null){9999}}) == 0){
                                        "correct redirect";
                                    } else {
                                        "bad redirect " # debug_show(remote_data);
                                    }

                            };
                            case(_){
                                "wrong result"
                            }
                        }
                    };
                    case(#err(err)){
                       
                            "wrong content " # debug_show(get_hidden_chunks);

                    };

                }, M.equals<Text>(T.text("correct redirect"))),


                
            S.test("do get pointer for storage collection", 
                
                switch(get_hidden_chunks){
                    case(#ok(res)){
                        switch(res){
                            case(#remote(remote_data)){
                                if(remote_data.canister == Principal.fromActor(storage_b) and
                                    remote_data.args.library_id == "hidden" and
                                    remote_data.args.token_id == "1" and
                                    (switch(remote_data.args.chunk){case(?val){val};case(null){9999}}) == 0){
                                        "correct redirect";
                                    } else {
                                        "bad redirect " # debug_show(remote_data);
                                    }

                            };
                            case(_){
                                "wrong result"
                            }
                        }
                    };
                    case(#err(err)){
                       
                            "wrong content " # debug_show(get_hidden_chunks);

                    };

                }, M.equals<Text>(T.text("correct redirect"))),
            S.test("can get chunks from storage collection", 
                
                switch(get_storage_chunks){
                    case(#ok(res)){
                        switch(res){
                            case(#remote(remote_data)){ "unexpected remote"};
                            case(#chunk(res)){
                                if(Blob.equal(res.content, Blob.fromArray(Conversion.valueToBytes(#Text("hidden hello world"))))){
                                    "hidden hello world";
                                }else {
                                    "somthing unexpected"
                                };
                            };
                        };
                    };
                    case(#err(err)){
                       
                            "wrong content " # debug_show(get_gatway_chunks);

                    };

                }, M.equals<Text>(T.text("hidden hello world"))),
            S.test("can get chunks from collection collection", 
                
                switch(get_storage_chunks_banner){
                    case(#ok(res)){
                        //D.print("the res from storage canister " #debug_show(res));
                        switch(res){
                            case(#remote(remote_data)){ "unexpected remote"};
                            case(#chunk(res)){
                                Conversion.bytesToText(Blob.toArray(res.content));
                            };
                        };
                    };
                    case(#err(err)){
                       
                            "wrong content " # debug_show(get_storage_chunks_banner);

                    };

                }, M.equals<Text>(T.text("collection banner"))),
            
     
        ]);


        S.run(suite);

        return #success;
    };

    

}