import Buffer "mo:base/Buffer";
import CandyTypes "mo:candy_0_1_10/types";
import Conversions "mo:candy_0_1_10/conversion";
import D "mo:base/Debug";
import Metadata "metadata";
import MigrationTypes "./migrations/types";
import Option "mo:base/Option";
import Properties "mo:candy_0_1_10/properties";
import Result "mo:base/Result";
import Types "types";

module {

    let Map = MigrationTypes.Current.Map;
    let CandyTypes = MigrationTypes.Current.CandyTypes;

    let debug_channel = {
        function_announce = false;
        governance = false;
    };

    public func governance_nft_origyn(state: Types.State, request : Types.GovernanceRequest, caller : Principal) : Result.Result<Types.GovernanceResponse, Types.OrigynError> {

      if(state.state.collection_data.network != ?caller){
        return return #err(Types.errors(#unauthorized_access, "governance_nft_origyn - unauthorized access - only network can govern", ?caller))
      };

      switch(request){
        case(#clear_shared_wallets(token_id)){
          var metadata = switch(Metadata.get_metadata_for_token(state, token_id, caller, ?state.canister(), state.state.collection_data.owner)){
              case(#err(err)){
                  return #err(Types.errors(#token_not_found, "share_nft_origyn token not found" # err.flag_point, ?caller));
              };
              case(#ok(val)){
                  val;
              };
          };

          metadata := Metadata.set_system_var(metadata, Types.metadata.__system_wallet_shares, #Empty);
          Map.set<Text, CandyTypes.CandyValue>(state.state.nft_metadata, Map.thash, token_id, metadata);
          return #ok(#clear_shared_wallets(true));

        };
        case(_){
          return #err(Types.errors(#nyi, "governance_nft_origyn - not yet implemented" # debug_show(request), ?caller))
    
        };
      };
   };

    
};