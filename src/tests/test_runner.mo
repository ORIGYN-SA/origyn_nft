
import C "mo:matchers/Canister";
import M "mo:matchers/Matchers";
import T "mo:matchers/Testable";
import D "mo:base/Debug";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import DFXTypes "../origyn_nft_reference/dfxtypes";
import AccountIdentifier "mo:principalmo/AccountIdentifier";
import utils "test_utils";



shared (deployer) actor class test_runner(tests : {
    canister_factory : Principal;
    storage_factory : Principal;
    dfx_ledger: ?Principal;
    dfx_ledger2: ?Principal;
    test_runner_nft: ?Principal; 
    test_runner_nft_2: ?Principal;
    test_runner_instant: ?Principal;
    test_runner_data :?Principal;
    test_runner_utils: ?Principal;
    test_runner_collection: ?Principal;
    test_runner_storage: ?Principal;
    test_runner_sale: ?Principal;
  }) = this {


    //D.print("tests are " # debug_show(tests));

    type test_runner_nft_service = actor {
        test: (Principal, Principal) -> async ({#success; #fail : Text});
    };

    let it = C.Tester({ batchSize = 8 });

    public shared func test() : async Text {

      D.print("tests are " # debug_show(tests));

      var dfx_ledger = switch(tests.dfx_ledger){
        case(null){Principal.fromText("aaaaa-aa")};
        case(?val){val};
      };

      var dfx_ledger2 = switch(tests.dfx_ledger2){
        case(null){Principal.fromText("aaaaa-aa")};
        case(?val){val};
      };


      //this is annoying, but it is gets around the "not defined bug";
      switch(tests.test_runner_sale){
        case(null){
          D.print("skipping sale tests" # debug_show(tests));
        };
        case(?test_runner_sale){
          D.print("running sale tests" # debug_show(test_runner_sale));
          let SaleTestCanister : test_runner_nft_service = actor(Principal.toText(test_runner_sale));
          
          it.should("run sale tests", func () : async C.TestResult = async {
            //send testrunnner some dfx tokens
            D.print("int the it");
            let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
            D.print("about to send to test canister" # debug_show(dfx_ledger));
            let resultdfx = await dfx.icrc1_transfer({
              to =  {owner = Principal.fromActor(SaleTestCanister); subaccount= null};
              fee = ?200_000;
              memo = utils.memo_one;
              from_subaccount = null;
              created_at_time = null;
              amount = 200_000_000_000_000;});


              let dfx2 : DFXTypes.Service = actor(Principal.toText(dfx_ledger2));
            D.print("about to send to test canister" # debug_show(dfx_ledger2));
            let resultdfx2 = await dfx2.icrc1_transfer({
              to =  {owner = Principal.fromActor(SaleTestCanister); subaccount= null};
              fee = ?200_000;
              memo = utils.memo_one;
              from_subaccount = null;
              created_at_time = null;
              amount = 200_000_000_000_000;});

            D.print(debug_show(resultdfx));

            let result = await SaleTestCanister.test(tests.canister_factory, tests.storage_factory);
            D.print("result");
            //D.print(debug_show(result));
            //M.attempt(greeting, M.equals(T.text("Hello, Christoph!")))
            return result;
          }); 
        };
      };

      //this is annoying, but it is gets around the "not defined bug";
      switch(tests.test_runner_nft){
        case(null){};
        case(?test_runner_nft){
          D.print("running nft tests");
          let NFTTestCanister : test_runner_nft_service = actor(Principal.toText(test_runner_nft));

          it.should("run nft tests", func () : async C.TestResult = async {
            //send testrunnner some dfx tokens
            let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
            D.print("about to send to test canister nft" # debug_show(dfx_ledger));
            let resultdfx = try{
              await dfx.icrc1_transfer({
              to =  {owner = Principal.fromActor(NFTTestCanister); subaccount= null};
              fee = ?200_000;
              memo = null;
              from_subaccount = null;
              created_at_time = null;
              amount = 200_000_000_000_000;});
            } catch(e){
              
              D.print(Error.message(e));
              D.trap(Error.message(e));
            };

            let dfx2 : DFXTypes.Service = actor(Principal.toText(dfx_ledger2));
            D.print("about to send to test canister nft 2 " # debug_show(dfx_ledger2));
            let resultdfx2 = await dfx2.icrc1_transfer({
               to =  {owner = Principal.fromActor(NFTTestCanister); subaccount= null};
              fee = ?200_000;
              memo = utils.memo_one;
              from_subaccount = null;
              created_at_time = null;
              amount = 200_000_000_000_000;});

            D.print(debug_show(resultdfx));

            D.print(debug_show(resultdfx2));

            let result = await NFTTestCanister.test(tests.canister_factory, tests.storage_factory);
            //D.print("result");
            //D.print(debug_show(result));
            //M.attempt(greeting, M.equals(T.text("Hello, Christoph!")))
            return result;
          }); 
        };
      };

      switch(tests.test_runner_nft_2){
        case(null){};
        case(?test_runner_nft_2){
          D.print("running nft 2 tests");
          let NFTTestCanister2 : test_runner_nft_service = actor(Principal.toText(test_runner_nft_2));
         D.print("running nft 2 tests after");
            it.should("run nft tests 2", func () : async C.TestResult = async {
              //send testrunnner some dfx tokens
              let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
              D.print("about to send to test canister" # debug_show(dfx_ledger));
              let resultdfx = await dfx.icrc1_transfer({
                to =  {owner = Principal.fromActor(NFTTestCanister2); subaccount= null};
                fee = ?200_000;
                memo = utils.memo_one;
                from_subaccount = null;
                created_at_time = null;
                amount = 200_000_000_000_000;});

                let dfx2 : DFXTypes.Service = actor(Principal.toText(dfx_ledger2));
            //D.print("about to send to test canister");
            let resultdfx2 = await dfx2.icrc1_transfer({
              to =  {owner = Principal.fromActor(NFTTestCanister2); subaccount= null};
              fee = ?200_000;
              memo = utils.memo_one;
              from_subaccount = null;
              created_at_time = null;
              amount = 200_000_000_000_000;});

              //D.print(debug_show(resultdfx));

              let result = await NFTTestCanister2.test(tests.canister_factory, tests.storage_factory);
              //D.print("result");
              //D.print(debug_show(result));
              //M.attempt(greeting, M.equals(T.text("Hello, Christoph!")))
              return result;
            }); 
        };
      };

      switch(tests.test_runner_collection){

        case(null){};
          case(?test_runner_collection){
            //D.print("running collection tests");

            let CollectionTestCanister : test_runner_nft_service = actor(Principal.toText(test_runner_collection)); 

            it.should("run collection tests", func () : async C.TestResult = async {
              //send testrunnner some dfx tokens
            

              let result = await CollectionTestCanister.test(tests.canister_factory, tests.storage_factory);
            
              return result;
            });
          };
      };

      switch(tests.test_runner_storage){

        case(null){};
          case(?test_runner_storage){
            //D.print("running storage tests");

            let StorageTestCanister : test_runner_nft_service = actor(Principal.toText(test_runner_storage)); 

            it.should("run storage tests", func () : async C.TestResult = async {
              //send testrunnner some dfx tokens
            

              let result = await StorageTestCanister.test(tests.canister_factory, tests.storage_factory);
            
              return result;
            });
          };
      };

      switch(tests.test_runner_instant){

        case(null){};
        case(?test_runner_instant){
          //D.print("running instant tests");
          let InstantTestCanister : test_runner_nft_service = actor(Principal.toText(test_runner_instant)); 

          it.should("run instant tests", func () : async C.TestResult = async {
            //send testrunnner some dfx tokens
            let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
            //D.print("about to send to test canister");
            let resultdfx = await dfx.icrc1_transfer({
               to =  {owner = Principal.fromActor(InstantTestCanister); subaccount= null};
              fee = ?200_000;
              memo = utils.memo_one;
              from_subaccount = null;
              created_at_time = null;
              amount = 200_000_000_000_000;});

              let dfx2 : DFXTypes.Service = actor(Principal.toText(dfx_ledger2));
            //D.print("about to send to test canister");
            let resultdfx2 = await dfx2.icrc1_transfer({
               to =  {owner = Principal.fromActor(InstantTestCanister); subaccount= null};
                fee = ?200_000;
                memo = utils.memo_one;
                from_subaccount = null;
                created_at_time = null;
                amount = 200_000_000_000_000;});

            //D.print(debug_show(resultdfx));

            let result = await InstantTestCanister.test(tests.canister_factory, tests.storage_factory);
            //D.print("result");
            //D.print(debug_show(result));
            //M.attempt(greeting, M.equals(T.text("Hello, Christoph!")))
            return result;
          }); 
        };
      };

      switch(tests.test_runner_data){

        case(null){};
        case(?test_runner_data){
          //D.print("running data tests");
          let DATATestCanister : test_runner_nft_service = actor(Principal.toText(test_runner_data));

          it.should("run data tests", func () : async C.TestResult = async {
        
            let result = await DATATestCanister.test(tests.canister_factory, tests.storage_factory);
            //M.attempt(greeting, M.equals(T.text("Hello, Christoph!")))
            return result;
          });
        };
      };

      switch(tests.test_runner_utils){

        case(null){};
          case(?test_runner_utils){
            //D.print("running util tests");
            let UTILSTestCanister : test_runner_nft_service = actor(Principal.toText(test_runner_utils)); 
            it.should("run util tests", func () : async C.TestResult = async {
              //send testrunnner some dfx tokens
            

              let result = await UTILSTestCanister.test(tests.canister_factory, tests.storage_factory);
            
              return result;
            });
          };
      };

      //D.print("about to run");
      await it.runAll()
      //await it.run()
    }
}