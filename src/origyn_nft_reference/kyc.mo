import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
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
import Metadata "Metadata";
import MigrationTypes "./migrations/types";
import NFTUtils "utils";
import Types "types";


module {

    type StateAccess = Types.State;
    let Map = MigrationTypes.Current.Map;

    let debug_channel = {
        owner = false;
    };

    private func get_collection_kyc_canister() : ?Principal {
      let ?metadata = Metadata.get_metadata_for_token("") else return null;
      let ?value = Metadata.get_nft_principal_property(Types.collection_kyc_canister, metadata) else return null;
      return value;
    };

    private func get_sale_kyc_canister(sale_id: Text) : ?Principal {

    };

    private func get_elected_kyc_canister(principal: Principal) : async* ?Principal {

    };



    public func pass_kyc(state: StateAccess, escrow : MigrationTypes.Current.EscrowReceipt, caller : Principal) :  Result.Result<MigrationTypes.Current.KYCResult, Types.OrigynError> {

        let kycTokenSpec = switch(escrow.token){
          case(#ic(token)){
            #IC(token);
           };
          case(_){
            return #err(Types.errors(#nyi, "pass_kyc - unsupported spec " # debug_show(escrow.token), ?caller));
          };
        };

        let kycBuyer = switch(escrow.buyer){
          case(#principal(account)){
            #principal(account);
          };
          case(#account(account)){
            #account({
              owner = account.owner;
              subaccount = account.subaccount;
            });
          };
          case(_){
            return #err(Types.errors(#nyi, "pass_kyc - unsupported buyer " # debug_show(escrow.token), ?caller));
          };
        };

        let sale_kyc = get_sale_kyc_canister(escrow.sale_id);

        let sale_result = 
          //currently nyi
          {
            kyc = #na;
            aml = #na;
            token = ?token;
            amount = null
          };
       

        let collection_kyc = get_collection_kyc_canister();

        let collection_result : ?KYCTypes.KYCResult = switch(collection_kyc){
          case(null){null};
          case(?val){
            switch(state.kyc_client.run_kyc({
              canister = collection_kyc;
              counterparty = kycBuyer;
              token = ?kycTokenSpec;
              amount = ?escrow.amount;

            }, null)){
              case(#ok(val)){
                val;
              };
              case(#err(err)){
                {
                  kyc = #fail;
                  aml = #fail;
                  token = ?token;
                  amount = null;
                  message = ?Error.message;
                };
              };
              
            };
          };
        };

        let elective_kyc = get_elective_kyc_canister(caller);

        let elective_result = 
          //currently nyi
          {
          kyc = #na;
          aml = #na;
          token = ?token;
          amount = null;
          };

        let result = {
          kyc = 
        }
       

        //D.print("returning transaction");
        #ok({
            transaction =txn_record;
            assets= []});
    };


}