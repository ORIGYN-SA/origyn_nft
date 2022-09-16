
import C "mo:matchers/Canister";
import M "mo:matchers/Matchers";
import T "mo:matchers/Testable";
import D "mo:base/Debug";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import DFXTypes "../origyn_nft_reference/dfxtypes";
import SalesCanister "../origyn_sale_reference/main";
import TestRunner "test_runner";


import CollectionTestCanisterDef "test_runner_collection";
import DataTestCanisterDef "test_runner_data";
import InstantTest "test_runner_instant_transfer";
import NFTTestCanisterDef2 "test_runner_nft_2";
import NFTTestCanisterDef "test_runner_nft";
import SaleTestCanisterDef "test_runner_sale";
import StorageTestCanisterDef "test_runner_storage";
import UtilTestCanisterDef "test_runner_utils";

import Wallet "test_wallet";

import CanisterFactoryDef "canister_creator";
import StorageFactory "storage_creator";
import AccountIdentifier "mo:principalmo/AccountIdentifier";

import Migrations "../origyn_nft_reference/migrations";
import StorageMigrations "../origyn_nft_reference/migrations_storage";


shared (deployer) actor class test_runner(dfx_ledger: Principal,test_runner_nft: Principal) = this {


    type test_runner_nft_service = actor {
        test: () -> async ({#success; #fail : Text});
    };

    let it = C.Tester({ batchSize = 8 });

    

    public shared func test() : async Text {

      //this is annoying, but it is gets around the "not defined bug";
      let NFTTestCanister : test_runner_nft_service = actor(Principal.toText(test_runner_nft));


        it.should("run nft tests", func () : async C.TestResult = async {
          //send testrunnner some dfx tokens
          let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
          //D.print("about to send to test canister");
          let resultdfx = await dfx.transfer({
            to =  Blob.fromArray(AccountIdentifier.addHash(AccountIdentifier.fromPrincipal(Principal.fromActor(NFTTestCanister), null)));
            fee = {e8s = 200_000};
            memo = 1;
            from_subaccount = null;
            created_at_time = null;
            amount = {e8s = 200_000_000_000_000};});

          //D.print(debug_show(resultdfx));

          let result = await NFTTestCanister.test();
          //D.print("result");
          //D.print(debug_show(result));
          //M.attempt(greeting, M.equals(T.text("Hello, Christoph!")))
          return result;
        });
        await it.runAll()
        // await it.run()
    }
}