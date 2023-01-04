
import AccountIdentifier "mo:principalmo/AccountIdentifier";
import Array "mo:base/Array";
import C "mo:matchers/Canister";
//import CandyType "mo:candy/types";
import CandyTypes "mo:candy/types";
import Conversion "mo:candy/conversion";
import DFXTypes "../origyn_nft_reference/dfxtypes";
import D "mo:base/Debug";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import M "mo:matchers/Matchers";
import NFTUtils "../origyn_nft_reference/utils";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Properties "mo:candy/properties";
import Result "mo:base/Result";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";
import TestWalletDef "test_wallet";
import Time "mo:base/Time";
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
        g_canister_factory := actor(Principal.toText(canister_factory));
        g_storage_factory := actor(Principal.toText(storage_factory));
        
        let suite = S.suite("test nft", [
          S.test("testRewriteLibrary", switch(await testRewriteLibrary()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            
            S.test("testDataInterface", switch(await testDataInterface()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testImmutableLibrary", switch(await testImmutableLibrary()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testDeleteLibrary", switch(await testDeleteLibrary()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            
            
            ]);
        S.run(suite);

        return #success;
    };

    public shared func testDataInterface() : async {#success; #fail : Text} {
        //D.print("running testDataInterface");

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this));

        //D.print("Minting");
        let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(a_wallet)));

        //try to get public data DATA0001
        //try to get private data DATA0002
        let getNFTAttempt = await b_wallet.try_get_nft(Principal.fromActor(canister),"1");
        let new_data = #Class([
                    {name = Types.metadata.__apps_app_id; value=#Text("com.test.__public"); immutable= true},
                    {name = "read"; value=#Text("public");
                        immutable=false;},
                    {name = "write"; value=#Class([
                        {name = "type"; value=#Text("allow"); immutable= false},
                        {name = "list"; value=#Array(#thawed([#Principal(Principal.fromActor(this))]));
                        immutable=false;}]);
                        immutable=false;},
                    {name = "permissions"; value=#Class([
                        {name = "type"; value=#Text("allow"); immutable= false},
                        {name = "list"; value=#Array(#thawed([#Principal(Principal.fromActor(this))]));
                        immutable=false;}]);
                    immutable=false;},
                    {name = "data"; value=#Class([
                        {name = "val1"; value=#Text("val1-modified"); immutable= false},
                        {name = "val2"; value=#Text("val2-modified"); immutable= false},
                        {name = "val3"; value=#Class([
                            {name = "data"; value=#Text("val3-modified"); immutable= false},
                            {name = "read"; value=#Text("public");
                            immutable=false;},
                            {name = "write"; value=#Class([
                                {name = "type"; value=#Text("allow"); immutable= false},
                                {name = "list"; value=#Array(#thawed([#Principal(Principal.fromActor(this))]));
                                immutable=false;}]);
                            immutable=false;}]);
                        immutable=false;},
                        {name = "val4"; value=#Class([
                            {name = "data"; value=#Text("val4-modified"); immutable= false},
                            {name = "read"; value=#Class([
                                {name = "type"; value=#Text("allow"); immutable= false},
                                {name = "list"; value=#Array(#thawed([#Principal(Principal.fromActor(this))]));
                                immutable=false;}]);
                            immutable=false;},
                            {name = "write"; value=#Class([
                                {name = "type"; value=#Text("allow"); immutable= false},
                                {name = "list"; value=#Array(#thawed([#Principal(Principal.fromActor(this))]));
                                immutable=false;}]);
                            immutable=false;}]);
                        immutable=false;}]);
                    immutable=false;}
                    ]);
        //DATA0010
        let setNFTAttemp_fail = await b_wallet.try_set_nft(Principal.fromActor(canister),"1", new_data);
        
        //DATA0012
        //D.print("should be sucessful");
        let setNFTAttemp = await canister.update_app_nft_origyn(#replace{token_id= "1"; data = new_data});
        //D.print(debug_show(setNFTAttemp));


        

        let getNFTAttempt2 = await b_wallet.try_get_nft(Principal.fromActor(canister),"1");
        //D.print(debug_show(getNFTAttempt2));

        //D.print("have meta");
        let suite = S.suite("test staged Nft", [

            S.test("test getNFT Attempt", switch(getNFTAttempt){case(#ok(res)){
                
                switch(Properties.getClassProperty(res.metadata, Types.metadata.__apps)){
                    case(?app){
                        //D.print("have app");
                        switch(app.value){
                            case(#Array(val)){
                                //D.print("have val");
                                switch(val){
                                    case(#thawed(classes)){
                                        var b_foundPublic = false;
                                        var b_foundPrivate = false;
                                        var b_foundVal3 = false;
                                        var b_foundVal4 = false;
                                        //D.print("have classes");
                                        for(this_item in Iter.fromArray<CandyTypes.CandyValue>(classes)){
                                            //D.print("checking");
                                            //D.print(debug_show(classes));
                                            let a_app : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(this_item,Types.metadata.__apps_app_id), {immutable = false; name="app"; value =#Text("")});
                                            //D.print("have a_app");
                                            //D.print(debug_show(a_app));
                                            //DATA0001
                                            if(Conversion.valueToText(a_app.value) == "com.test.__public"){
                                                b_foundPublic := true;
                                                //try to find val3 which should be hidden
                                                //D.print("looking for val3");
                                                let a_data : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(this_item,"data"), {immutable = false; name="data"; value =#Text("")});
                                                //D.print("have a data");
                                                //D.print(debug_show(a_data));
                                                let a_val : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(a_data.value,"val3"), {immutable = false; name="data"; value =#Text("")});
                                                let a_val2 : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(a_data.value,"val4"), {immutable = false; name="data"; value =#Text("")});
                                                //D.print("have a val");
                                                switch(a_val.value){
                                                    case(#Class(valInfo)){
                                                        let a_data_data : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(a_val.value,"data"), {immutable = false; name="data"; value =#Text("")});
                                                        //D.print("have a data data");
                                                        
                                                        if(Conversion.valueToText(a_data_data.value) == "val3"){
                                                            //D.print("found it");
                                                            b_foundVal3 := true;
                                                        } else {
                                                            //D.print("didn't find it");
                                                        }
                                                    };
                                                    case(_){

                                                    };
                                                };
                                                switch(a_val2.value){
                                                    case(#Class(valInfo)){
                                                        let a_data_data : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(a_val2.value,"data"), {immutable = false; name="data"; value =#Text("")});
                                                        //D.print("have a data data");
                                                        
                                                        if(Conversion.valueToText(a_data_data.value) == "val4"){
                                                            //D.print("found it");
                                                            b_foundVal3 := true;
                                                        } else {
                                                            //D.print("didn't find it");
                                                        }
                                                    };
                                                    case(_){

                                                    };
                                                };
                                            };
                                            //DATA0002
                                            if(Conversion.valueToText(a_app.value) == "com.test.__private"){
                                                b_foundPrivate := true;
                                            }
                                        };

                                    
                                        switch(b_foundPublic, b_foundPrivate, b_foundVal3, b_foundVal4){
                                            case(true, false, true, false){
                                                "correct response";
                                            };
                                            case(_,_,_,_){
                                                "something missing or something extra";
                                            };
                                        };

                                    };
                                    case(_){
                                        "wrong type of arrray";
                                    };
                                };
                            };
                            case(_){
                                "not an array";
                            };
                        
                        };
                    };
                    case(null){
                        "can't find app";
                    };
                };
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //DATA0001, DATA0002
            S.test("fail if non allowed calls write", switch(setNFTAttemp_fail){case(#ok(res)){"unexpected success"};case(#err(err)){
                if(err.number == 2000){ //unauthorized
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //DATA0010
            S.test("allowed user can write", switch(getNFTAttempt2){case(#ok(res)){
                
                switch(Properties.getClassProperty(res.metadata, Types.metadata.__apps)){
                    case(?app){
                        //D.print("have app");
                        switch(app.value){
                            case(#Array(val)){
                                //D.print("have val");
                                switch(val){
                                    case(#thawed(classes)){
                                        var b_foundPublic = false;
                                        var b_foundPrivate = false;
                                        var b_foundVal3 = false;
                                        var b_foundVal4 = false;
                                        //D.print("have classes");
                                        for(this_item in Iter.fromArray<CandyTypes.CandyValue>(classes)){
                                            //D.print("checking");
                                            //D.print(debug_show(classes));
                                            let a_app : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(this_item, Types.metadata.__apps_app_id), {immutable = false; name="app"; value =#Text("")});
                                            //D.print("have a_app");
                                            //D.print(debug_show(a_app));
                                            //DATA0001
                                            if(Conversion.valueToText(a_app.value) == "com.test.__public"){
                                                b_foundPublic := true;
                                                //try to find val3 which should be hidden
                                                //D.print("looking for val3");
                                                let a_data : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(this_item,"data"), {immutable = false; name="data"; value =#Text("")});
                                                //D.print("have a data");
                                                //D.print(debug_show(a_data));
                                                let a_val : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(a_data.value,"val3"), {immutable = false; name="data"; value =#Text("")});
                                                let a_val2 : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(a_data.value,"val4"), {immutable = false; name="data"; value =#Text("")});
                                                //D.print("have a val");
                                                switch(a_val.value){
                                                    case(#Class(valInfo)){
                                                        let a_data_data : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(a_val.value,"data"), {immutable = false; name="data"; value =#Text("")});
                                                        //D.print("have a data data");
                                                        
                                                        if(Conversion.valueToText(a_data_data.value) == "val3-modified"){
                                                            //D.print("found it");
                                                            b_foundVal3 := true;
                                                        } else {
                                                            //D.print("didn't find it");
                                                        }
                                                    };
                                                    case(_){

                                                    };
                                                };
                                                switch(a_val2.value){
                                                    case(#Class(valInfo)){
                                                        let a_data_data : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(a_val2.value,"data"), {immutable = false; name="data"; value =#Text("")});
                                                        //D.print("have a data data");
                                                        
                                                        if(Conversion.valueToText(a_data_data.value) == "val4-modified"){
                                                            //D.print("found it");
                                                            b_foundVal3 := true;
                                                        } else {
                                                            //D.print("didn't find it");
                                                        }
                                                    };
                                                    case(_){

                                                    };
                                                };
                                            };
                                            //DATA0002
                                            if(Conversion.valueToText(a_app.value) == "com.test.__private"){
                                                b_foundPrivate := true;
                                            }
                                        };

                                    
                                        switch(b_foundPublic, b_foundPrivate, b_foundVal3, b_foundVal4){
                                            case(true, false, true, false){
                                                "correct response";
                                            };
                                            case(_,_,_,_){
                                                "something missing or something extra";
                                            };
                                        };

                                    };
                                    case(_){
                                        "wrong type of arrray";
                                    };
                                };
                            };
                            case(_){
                                "not an array";
                            };
                        
                        };
                    };
                    case(null){
                        "can't find app";
                    };
                };
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //DATA0012
            
            
        ]);

        S.run(suite);

        return #success;
        
          

    };


    public shared func testImmutableLibrary() : async {#success; #fail : Text} {
        //D.print("running testDataInterface");

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this));

        //attempt to change the metadata of a library before mint

        let reStageLibrary = await canister.stage_library_nft_origyn(
          {
            token_id = "1";
            library_id = "immutable_item";
            filedata  = #Class([
              {name = "library_id"; value=#Text("immutable_item"); immutable= true},
              {name = "title"; value=#Text("immutable-updated"); immutable= true},
              {name = "location_type"; value=#Text("canister"); immutable= true},
              {name = "location"; value=#Text("http://localhost:8000/-/1/-/immutable_item?canisterId="); immutable= true},
              {name = "content_type"; value=#Text("text/html; charset=UTF-8"); immutable= true},
              {name = "content_hash"; value=#Bytes(#frozen([0,0,0,0])); immutable= true},
              {name = "size"; value=#Nat(40); immutable= true},
              {name = "sort"; value=#Nat(0); immutable= true},
              {name = "read"; value=#Text("public");immutable=false;},
              {name = "com.origyn.immutable_library"; value=#Bool(true);immutable=false;},
            ]);
            chunk = 0;
            content = Blob.fromArray([]);// content = #Bytes(nat8array);
          }
        );
        
        D.print("reStageLibrary:" # debug_show(reStageLibrary));
        

        //D.print("Minting");
        let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(a_wallet)));

        //attempt to change the metadata of a library before mint
        D.print("mint_attempt:" # debug_show(mint_attempt));

        let reStageLibrary_after_mint = await canister.stage_library_nft_origyn(
          {
            token_id = "1";
            library_id = "immutable_item";
            filedata  = #Class([
              {name = "library_id"; value=#Text("immutable_item"); immutable= true},
              {name = "title"; value=#Text("immutable-updated-2"); immutable= true},
              {name = "location_type"; value=#Text("canister"); immutable= true},
              {name = "location"; value=#Text("http://localhost:8000/-/1/-/immutable_item?canisterId="); immutable= true},
              {name = "content_type"; value=#Text("text/html; charset=UTF-8"); immutable= true},
              {name = "content_hash"; value=#Bytes(#frozen([0,0,0,0])); immutable= true},
              {name = "size"; value=#Nat(40); immutable= true},
              {name = "sort"; value=#Nat(0); immutable= true},
              {name = "read"; value=#Text("public");immutable=false;},
              {name = "com.origyn.immutable_library"; value=#Bool(true);immutable=false;},
            ]);
            chunk = 0;
            content = Blob.fromArray([]);// content = #Bytes(nat8array);
          }
        );

        D.print("reStageLibrary_after_mint:" # debug_show(reStageLibrary_after_mint));

        let getNFTAttempt = await b_wallet.try_get_nft(Principal.fromActor(canister),"1");
        
        D.print("getNFTAttempt:" # debug_show(getNFTAttempt));


        
        //D.print("have meta");
        let suite = S.suite("testImmutable", [

            S.test("reStageLibrary should succeed", switch(reStageLibrary){case(#ok(res)){
                
               "correct response";
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), 
            S.test("fail if already minted", switch(reStageLibrary_after_mint){case(#ok(res)){"unexpected success " # debug_show(res)};case(#err(err)){
                if(err.number == 1000){ //update class error
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //DATA0010
            S.test("Data is correct", switch(getNFTAttempt){case(#ok(res)){
                
                switch(Properties.getClassProperty(res.metadata, Types.metadata.library)){
                    case(?library){
                        //D.print("have app");
                        switch(library.value){
                            case(#Array(val)){
                                //D.print("have val");
                                switch(val){
                                    case(#thawed(classes)){
                                        var b_found_immutable : Bool = false;
                                        var b_found_updated : Bool = false;
                                        //D.print("have classes");
                                        for(this_item in Iter.fromArray<CandyTypes.CandyValue>(classes)){
                                            //D.print("checking");
                                            //D.print(debug_show(classes));
                                            let a_app : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(this_item, Types.metadata.library_id), {immutable = false; name="library_id"; value =#Text("")});
                                            //D.print("have a_app");
                                            //D.print(debug_show(a_app));
                                            //DATA0001
                                            if(Conversion.valueToText(a_app.value) == "immutable_item"){
                                                b_found_immutable := true;
                                                //try to find val3 which should be hidden
                                                //D.print("looking for val3");
                                                let title_data : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(this_item,"title"), {immutable = false; name="title"; value =#Text("")});
                                                
                                                if(Conversion.valueToText(title_data.value) == "immutable-updated"){
                                                  b_found_updated := true;
                                                };
                                                
                                            };
                                           
                                        };

                                    
                                        switch(b_found_immutable, b_found_updated){
                                            case(true, true){
                                                "correct response";
                                            };
                                            case(_,_){
                                                "something missing or something extra";
                                            };
                                        };

                                    };
                                    case(_){
                                        "wrong type of arrray";
                                    };
                                };
                            };
                            case(_){
                                "not an array";
                            };
                        
                        };
                    };
                    case(null){
                        "can't find library";
                    };
                };
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //DATA0012
            
            
        ]);

        S.run(suite);

        return #success;

    };


    public shared func testDeleteLibrary() : async {#success; #fail : Text} {
        //D.print("running testDataInterface");

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this));

        //attempt to delete page before minting

        let deletePage = await canister.stage_library_nft_origyn(
          {
            token_id = "1";
            library_id = "page";
            filedata  = #Bool(false);
            chunk = 0;
            content = Blob.fromArray([]);// content = #Bytes(nat8array);
          }
        );
        
        D.print("deletePage:" # debug_show(deletePage));
        

        //D.print("Minting");
        let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(a_wallet)));

        //attempt to delete preview after mint
        D.print("mint_attempt:" # debug_show(mint_attempt));

        let deletePreview = await canister.stage_library_nft_origyn(
          {
            token_id = "1";
            library_id = "preview";
            filedata  = #Bool(false);
            chunk = 0;
            content = Blob.fromArray([]);// content = #Bytes(nat8array);
          }
        );
        D.print("deletePreview:" # debug_show(deletePreview));


        

        let deleteImmutable = await canister.stage_library_nft_origyn(
          {
            token_id = "1";
            library_id = "immutable_item";
            filedata  = #Bool(false);
            chunk = 0;
            content = Blob.fromArray([]);// content = #Bytes(nat8array);
          }
        );

        //attempt to delete preview after mint
        D.print("deleteImmutable:" # debug_show(deleteImmutable));


        let getNFTAttempt = await b_wallet.try_get_nft(Principal.fromActor(canister),"1");
        
        D.print("getNFTAttempt:" # debug_show(getNFTAttempt));


        
        //D.print("have meta");
        let suite = S.suite("testDeleteLibrary", [

            S.test("delete page succeed", switch(deletePage){case(#ok(res)){
                
               "correct response";
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), 
            S.test("delete preview succeed", switch(deletePreview){case(#ok(res)){
                
               "correct response";
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), 
            S.test("deleteImmutable should fail", switch(deleteImmutable){case(#ok(res)){"unexpected success " # debug_show(res)};case(#err(err)){
                if(err.number == 1000){ //update class error
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //DATA0010
            S.test("Data is correct", switch(getNFTAttempt){case(#ok(res)){
                
                switch(Properties.getClassProperty(res.metadata, Types.metadata.library)){
                    case(?library){
                        //D.print("have app");
                        switch(library.value){
                            case(#Array(val)){
                                //D.print("have val");
                                switch(val){
                                    case(#thawed(classes)){
                                        var b_found_page : Bool = false;
                                        var b_found_preview : Bool = false;
                                        var b_found_immutable : Bool = false;
                                        //D.print("have classes");
                                        for(this_item in Iter.fromArray<CandyTypes.CandyValue>(classes)){
                                            
                                            let a_app : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(this_item, Types.metadata.library_id), {immutable = false; name="library_id"; value =#Text("")});

                                            if(Conversion.valueToText(a_app.value) == "immutable_item"){
                                                b_found_immutable := true;
                                            };
                                            if(Conversion.valueToText(a_app.value) == "page"){
                                                b_found_page := true;
                                            };
                                            if(Conversion.valueToText(a_app.value) == "preview"){
                                                b_found_preview := true;
                                            };
                                           
                                        };

                                    
                                        switch(b_found_immutable, b_found_page, b_found_preview){
                                            case(true, false, false){
                                                "correct response";
                                            };
                                            case(_,_,_){
                                                "something missing or something extra " # debug_show((b_found_immutable, b_found_page, b_found_preview));
                                            };
                                        };

                                    };
                                    case(_){
                                        "wrong type of arrray";
                                    };
                                };
                            };
                            case(_){
                                "not an array";
                            };
                        
                        };
                    };
                    case(null){
                        "can't find library";
                    };
                };
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //DATA0012
            
            
        ]);

        S.run(suite);

        return #success;

    };

    public shared func testRewriteLibrary() : async {#success; #fail : Text} {
        //D.print("running testDataInterface");

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(this), 1024, false, Principal.fromActor(this));

        //attempt to delete page before minting

        let deletePage = await canister.stage_library_nft_origyn(
          {
            token_id = "1";
            library_id = "page";
            filedata  = #Bool(false);
            chunk = 0;
            content = Blob.fromArray([]);// content = #Bytes(nat8array);
          }
        );
        
        D.print("deletePage:" # debug_show(deletePage));

        //let stage = await canister.stage_nft_origyn(utils.standardNFT("1", Principal.fromActor(canister), Principal.fromActor(this), 1024, false, Principal.fromActor(this)));
        
        let fileStage = await canister.stage_library_nft_origyn(utils.standardFileChunk("1","page","hello world replace larger", #Class([
                    {name = "library_id"; value=#Text("page"); immutable= true},
                    {name = "title"; value=#Text("page"); immutable= true},
                    {name = "location_type"; value=#Text("canister"); immutable= true},// ipfs, arweave, portal
                    {name = "location"; value=#Text("http://localhost:8000/-/1/-/page?canisterId=" # Principal.toText(Principal.fromActor(canister))); immutable= true},
                    {name = "content_type"; value=#Text("text/html; charset=UTF-8"); immutable= true},
                    {name = "content_hash"; value=#Bytes(#frozen([0,0,0,0])); immutable= true},
                    {name = "size"; value=#Nat(1025); immutable= true},
                    {name = "sort"; value=#Nat(0); immutable= true},
                    {name = "read"; value=#Text("public"); immutable=false;},
                ])));

        let deletePage2 = await canister.stage_library_nft_origyn(
          {
            token_id = "1";
            library_id = "page";
            filedata  = #Bool(false);
            chunk = 0;
            content = Blob.fromArray([]);// content = #Bytes(nat8array);
          }
        );


        
        D.print("deletePage2:" # debug_show(deletePage2));

        let fileStage2 = await canister.stage_library_nft_origyn(utils.standardFileChunk("1","page","hello world replace smaller", #Class([
                    {name = "library_id"; value=#Text("page"); immutable= true},
                    {name = "title"; value=#Text("page"); immutable= true},
                    {name = "location_type"; value=#Text("canister"); immutable= true},// ipfs, arweave, portal
                    {name = "location"; value=#Text("http://localhost:8000/-/1/-/page?canisterId=" # Principal.toText(Principal.fromActor(canister))); immutable= true},
                    {name = "content_type"; value=#Text("text/html; charset=UTF-8"); immutable= true},
                    {name = "content_hash"; value=#Bytes(#frozen([0,0,0,0])); immutable= true},
                    {name = "size"; value=#Nat(1023); immutable= true},
                    {name = "sort"; value=#Nat(0); immutable= true},
                    {name = "read"; value=#Text("public"); immutable=false;},
                ])));

        
        let getNFTAttempt = await canister.nft_origyn("1");
        
        D.print("getNFTAttempt:" # debug_show(getNFTAttempt));


        
        //D.print("have meta");
        let suite = S.suite("testRewriteLibrary", [

            
            S.test("delete page succeed", switch(deletePage){case(#ok(res)){
                
               "correct response";
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), 
            S.test("delete page 2 succeed", switch(deletePage2){case(#ok(res)){
                
               "correct response";
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), 
           
            S.test("Data is correct", switch(getNFTAttempt){case(#ok(res)){
                
                switch(Properties.getClassProperty(res.metadata, Types.metadata.library)){
                    case(?library){
                        //D.print("have app");
                        switch(library.value){
                            case(#Array(val)){
                                //D.print("have val");
                                switch(val){
                                    case(#thawed(classes)){
                                        var b_found_page : Bool = false;
                                        //D.print("have classes");
                                        for(this_item in Iter.fromArray<CandyTypes.CandyValue>(classes)){
                                            
                                            let a_app : CandyTypes.Property = Option.get<CandyTypes.Property>(Properties.getClassProperty(this_item, Types.metadata.library_id), {immutable = false; name="library_id"; value =#Text("")});

                                           
                                            if(Conversion.valueToText(a_app.value) == "page"){
                                                b_found_page := true;
                                            };

                                           
                                        };

                                    
                                        switch(b_found_page){
                                            case(true){
                                                "correct response";
                                            };
                                            case(_){
                                                "something missing or something extra " # debug_show((b_found_page));
                                            };
                                        };

                                    };
                                    case(_){
                                        "wrong type of arrray";
                                    };
                                };
                            };
                            case(_){
                                "not an array";
                            };
                        
                        };
                    };
                    case(null){
                        "can't find library";
                    };
                };
            };case(#err(err)){"unexpected error: " # err.flag_point};}, M.equals<Text>(T.text("correct response"))), //DATA0012
            
            
        ]);

        S.run(suite);

        return #success;

    };



}