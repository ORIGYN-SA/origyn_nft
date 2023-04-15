
import AccountIdentifier "mo:principalmo/AccountIdentifier";
import Array "mo:base/Array";
import C "mo:matchers/Canister";
//import CandyType "mo:candy/types";
import CandyTypes "mo:candy/types";
import D "mo:base/Debug";
import Iter "mo:base/Iter";
import M "mo:matchers/Matchers";
import NFTUtils "../origyn_nft_reference/utils";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";
import Time "mo:base/Time";
import Types "../origyn_nft_reference/types";

import MigrationTypes "../origyn_nft_reference/migrations/types";



shared (deployer) actor class test_runner(dfx_ledger: Principal, dfx_ledger2: Principal) = this {

    let CandyTypes = MigrationTypes.Current.CandyTypes;
    let Conversions = MigrationTypes.Current.Conversions;
    let Properties = MigrationTypes.Current.Properties;
    let Workspace = MigrationTypes.Current.Workspace;

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
        
        let suite = S.suite("test nft", [
            S.test("testNFTUtils", switch(await testNFTUtils()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            ]);
        S.run(suite);

        return #success;
    };


    public shared func testNFTUtils() : async {#success; #fail : Text} {
        //D.print("running testNFTUtils");

        let theNat = NFTUtils.get_token_id_as_nat("1");
        //D.print(debug_show(theNat));
        let theText = NFTUtils.get_nat_as_token_id(theNat);
        //D.print("the text should be back");
        //D.print(theText);


        let theNat2 = NFTUtils.get_token_id_as_nat("com.origyn.nft.SomethingFunky");
        D.print(debug_show(theNat2));
        let theText2 = NFTUtils.get_nat_as_token_id(theNat2);
        D.print("the text should be back");
        D.print(theText2);

        

        //test balances
        //D.print("made it here");
        let suite = S.suite("test market Nft", [
            S.test("id is converted", theText, M.equals<Text>(T.text("1"))), 
            S.test("id is converted 2", theText2, M.equals<Text>(T.text("com.origyn.nft.SomethingFunky"))), 
        ]);
        //D.print("about to run");
        S.run(suite);
        //D.print("returning");
        return #success;
    };


}