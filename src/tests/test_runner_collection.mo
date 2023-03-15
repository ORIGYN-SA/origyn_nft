
import AccountIdentifier "mo:principalmo/AccountIdentifier";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import C "mo:matchers/Canister";
import CandyTypes "mo:candy/types";
import Conversion "mo:candy/conversion";
import D "mo:base/Debug";
import Error "mo:base/Error";
import Iter "mo:base/Iter";
import M "mo:matchers/Matchers";
import Nat "mo:base/Nat";
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
//import Instant "test_runner_instant_transfer";


shared (deployer) actor class test_runner_collection(dfx_ledger: Principal, dfx_ledger2: Principal) = this {
    let it = C.Tester({ batchSize = 8 });

    
    private var DAY_LENGTH = 60 * 60 * 24 * 10 ** 9;
    private var dip20_fee = ?200_000;

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
        //let Instant_Test = await Instant.test_runner_instant_transfer();

        let suite = S.suite("test nft", [
            S.test("testCollectionData", switch(await testCollectionData()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            //S.test("testCollectionMetadata", switch(await testCollectionMetadata()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            //S.test("testCollectionNFTList", switch(await testCollectionNFTList()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            //S.test("testCollectionOwner", switch(await testCollectionOWner()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            //S.test("testCollectionManager", switch(await testCollectionManager()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            
            //S.test("testInstantTransfer", switch(await Instant_Test.testInstantTransfer()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
        ]);
        S.run(suite);

        return #success;
    };

    // MINT0002
    // MINT0003
    public shared func testCollectionData() : async {#success; #fail : Text} {
        //D.print("running testCollectionData");

        let owner = Principal.toText(Principal.fromActor(this));

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        let collection_info_original = switch(await canister.collection_nft_origyn(null)){
            case(#err(err)){
                //throw an error
                //D.print(debug_show(err));
                throw(Error.reject("couldn't get canister info before set "));
            };
            case(#ok(val)){val};
        };

        //set collection info
        //D.print("set collection info");
        let collection_update_response = await canister.collection_update_batch_nft_origyn([
            #UpdateLogo(?"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"),
            #UpdateName(?"Test Token"),
            #UpdateSymbol(?"TST"),
            #UpdateMetadata("collection_id", ?#Text("collection_id"), true)
        ]);
        
         //D.print(debug_show(collection_update_response));


        let collection_info_after_set = switch(await canister.collection_nft_origyn(null)){
            case(#err(err)){
                //throw an error
                //D.print(debug_show(err));
                throw(Error.reject("couldn't get canister info after set "));
            };
            case(#ok(val)){val};
        };

        //test collection info

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));

        //mint 2
        let mint_attempt = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(canister)));
        let mint_attempt2 = await canister.mint_nft_origyn("3", #principal(Principal.fromActor(canister)));


         let collection_info_after_mint = switch(await canister.collection_nft_origyn(null)){
            case(#err(err)){
                //throw an error
                //D.print(debug_show(err));
                throw(Error.reject("couldn't get canister info after mint "));
            };
            case(#ok(val)){val};
        };

        let suite = S.suite("test owner and manager", [

            S.test("owner is set on default", 
                switch(collection_info_original.owner){case(?val){Principal.toText(val);};case(null){"ownerfield null"}}, M.equals<Text>(T.text(owner))),
            S.test("manager is null",  
                if((switch(collection_info_original.managers){case(null){0};case(?val){val.size()}}) == 0){
                    "properly empty"
                } else {"improprly found " # debug_show(collection_info_original.managers)}
            , M.equals<Text>(T.text("properly empty"))),
            S.test("logo is null",  switch(collection_info_original.logo){
                    case(null){"properly null"};
                    case(?val){"improprly found " # val};
            }, M.equals<Text>(T.text("properly null"))),
            S.test("name is null",  switch(collection_info_original.name){
                    case(null){"properly null"};
                    case(?val){"improprly found " # val};
            }, M.equals<Text>(T.text("properly null"))),
            S.test("symbol is null",  switch(collection_info_original.symbol){
                    case(null){"properly null"};
                    case(?val){"improprly found " # val};
            }, M.equals<Text>(T.text("properly null"))),
            S.test("totalSupply is 0",  
                if((switch(collection_info_original.total_supply){case(null){0};case(?val){val;}}) == 0){
                    "properly empty"
                } else {"improprly found " # debug_show(collection_info_original.total_supply)}
            , M.equals<Text>(T.text("properly empty"))),
            S.test("token_ids is null",  if((switch(collection_info_original.token_ids){case(null){0};case(?val){val.size()}}) == 0){
                    "properly empty"} else {"improprly found " # debug_show(collection_info_original.token_ids)}
            , M.equals<Text>(T.text("properly empty"))),
            S.test("multi_canister is null",  if((switch(collection_info_original.multi_canister){case(null){0};case(?val){val.size()}}) == 0){
                    "properly empty"} else {"improprly found " # debug_show(collection_info_original.multi_canister)}
            , M.equals<Text>(T.text("properly empty"))),
            S.test("metadata is null",  switch(collection_info_original.metadata){
                    case(null){"properly null"};
                    case(?val){"improprly found " # debug_show(val)};
            }, M.equals<Text>(T.text("properly null"))),


            S.test("logo is not null after update",  switch(collection_info_after_set.logo){
                    case(null){"didn't find data"};
                    case(?val){"found data"};
            }, M.equals<Text>(T.text("found data"))),
            S.test("name is not nullafter update",  switch(collection_info_after_set.name){
                     case(null){"didn't find data"};
                    case(?val){val};
            }, M.equals<Text>(T.text("Test Token"))),
            S.test("symbol is not null after update",  switch(collection_info_after_set.symbol){
                    case(null){"didn't find data"};
                    case(?val){val};
            }, M.equals<Text>(T.text("TST"))),
             S.test("metadata is not null after update",  switch(collection_info_after_set.metadata){
                    case(null){"didn't find data"};
                    case(?val){"found data"};
            }, M.equals<Text>(T.text("found data"))),
            S.test("unique holders is set",  switch(collection_info_after_mint.unique_holders){
                    case(null){0};
                    case(?val){val};
            }, M.equals<Nat>(T.nat(1))),
            
            S.test("transaction count is correct",  switch(collection_info_after_mint.transaction_count){
                    case(null){0};
                    case(?val){val};
            }, M.equals<Nat>(T.nat(2))),
            S.test("tokenid count is correct",  switch(collection_info_after_mint.token_ids){
                    case(null){0};
                    case(?val){val.size()};
            }, M.equals<Nat>(T.nat(3))),
        ]);

        S.run(suite);

        return #success;
    };
    


}