import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Error "mo:base/Error";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";

import CandyTypes "mo:candy/types";
import Conversions "mo:candy/conversion";
import EXT "mo:ext/Core";
import Properties "mo:candy/properties";
import Workspace "mo:candy/workspace";


import DIP721 "DIP721";
import Metadata "./metadata";
import MigrationTypes "./migrations/types";
import NFTUtils "utils";
import Types "types";


module {

    type StateAccess = Types.State;
    let Map = MigrationTypes.Current.Map;

    let debug_channel = {
        owner = false;
    };

    private func get_collection_kyc_canister(state : Types.State) : ?Principal {
      let #ok(metadata) = Metadata.get_metadata_for_token(state, "", state.canister(), ?state.canister(),  state.state.collection_data.owner) else return null;
      let #ok(value) = Metadata.get_nft_principal_property(metadata, Types.metadata.collection_kyc_canister) else return null;

      return ?value;
    };

    private func get_sale_kyc_canister(state : Types.State, sale_id: ?Text) : ?Principal {
      //nyi
      null;
    };

    private func get_elective_kyc_canister(state : Types.State, principal: Principal) : async* ?Principal {
      //nyi
      null;
    };

    public func pass_kyc(state: StateAccess, escrow : MigrationTypes.Current.EscrowRecord, caller : Principal) : async* Result.Result<MigrationTypes.Current.KYCResult, Types.OrigynError> {

        var message : Text = "";

        let kycTokenSpec : MigrationTypes.Current.KYCTokenSpec = switch(escrow.token){
          case(#ic(token)){
            #IC({token with id = null; fee = ?token.fee});
           };
          case(_){
            return #err(Types.errors(#nyi, "pass_kyc - unsupported spec " # debug_show(escrow.token), ?caller));
          };
        };

        let kycBuyer = switch(escrow.buyer){
          case(#principal(account)){
            #ICRC1({
              owner = account;
              subaccount = null;
            });
          };
          case(#account(account)){
            #ICRC1({
              owner = account.owner;
              subaccount = switch(account.sub_account){
                case(null) null;
                case(?val) ?Blob.toArray(val);
              };
            });
          };
          case(_){
            return #err(Types.errors(#nyi, "pass_kyc - unsupported buyer " # debug_show(escrow.token), ?caller));
          };
        };

        let sale_kyc =get_sale_kyc_canister(state, escrow.sale_id);

        let sale_result : MigrationTypes.Current.KYCResult = 
          //currently nyi
          {
            kyc = #NA;
            aml = #NA;
            token = ?kycTokenSpec;
            amount = null;
            message = null;
          };
       

        let collection_kyc = get_collection_kyc_canister(state, );

        let collection_result : MigrationTypes.Current.KYCResult = switch(collection_kyc){
          case(null){
             {
              kyc = #NA;
              aml = #NA;
              token = ?kycTokenSpec;
              amount = null;
              message = null;
            };
          };
          case(?val){
            let result = try{
              await* state.kyc_client.run_kyc({
                canister = val;
                counterparty = kycBuyer;
                token = ?kycTokenSpec;
                amount = ?escrow.amount;

              }, null)
            } catch(err){
              #err(Error.message(err));
            };

            switch(result){
              case(#ok(val)){
                val;
              };
              case(#err(err)){
                {
                  kyc = #Fail;
                  aml = #Fail;
                  token = ?kycTokenSpec;
                  amount = null;
                  message = ?err;
                };
              };
              
            };
          };
        };

        let elective_kyc = get_elective_kyc_canister(state, caller);

        let elective_result : MigrationTypes.Current.KYCResult = 
          //currently nyi
          {
            kyc = #NA;
            aml = #NA;
            token = ?kycTokenSpec;
            amount = null;
            message = null;
          };

        
        let kyc_result = if(elective_result.kyc == #Fail or collection_result.kyc == #Fail or sale_result.kyc == #Fail){
            #Fail;
          } else if(elective_result.kyc == #NA or collection_result.kyc == #NA or sale_result.kyc == #NA){
            #NA;
          } else {
            #Pass;
          };

        let aml_result = if(elective_result.aml == #Fail or collection_result.aml == #Fail or sale_result.aml == #Fail){
            #Fail;
          } else if(elective_result.aml == #NA or collection_result.aml == #NA or sale_result.aml == #NA){
            #NA;
          } else {
            #Pass;
          };

        var amount : ?Nat = null;

        switch(collection_result.amount){
          case(null){};
          case(?val){amount := ?val};
        };

        switch(sale_result.amount){
          case(null){};
          case(?val){
            if(val < Option.get(amount,0)){amount := ?val}
          };
        };

        switch(elective_result.amount){
          case(null){};
          case(?val){
            if(val < Option.get(amount,0)){amount := ?val}
          };
        };

        switch(collection_result.message){
          case(null){};
          case(?val){message := message # "[" # val # "]";};
        };

    
        switch(sale_result.message){
          case(null){};
          case(?val){
            message := message # "[" # val # "]";
          };
        };

        switch(elective_result.message){
          case(null){};
          case(?val){
            message := message # "[" # val # "]";
          };
        };

        

        let result : MigrationTypes.Current.KYCResult = {
          kyc = kyc_result;
          aml = aml_result;
          token = ?kycTokenSpec;
          amount = amount;
          message = if(message.size() > 0){
            ?message;
          } else {
            null;
          };
        };
       

        //D.print("returning transaction");
        #ok(result);
    };


}