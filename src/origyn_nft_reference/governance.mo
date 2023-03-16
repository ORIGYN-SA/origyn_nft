import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Option "mo:base/Option";
import Result "mo:base/Result";

import CandyTypes "mo:candy/types";
import Conversions "mo:candy/conversion";
import Properties "mo:candy/properties";

import Metadata "metadata";
import MigrationTypes "./migrations/types";
import Types "types";

module {

  let Map = MigrationTypes.Current.Map;
  let CandyTypes = MigrationTypes.Current.CandyTypes;

  let debug_channel = {
    function_announce = false;
    governance = false;
  };

  //allows the network to govern the NFT via decentralized concensus.
  public func governance_nft_origyn(state: Types.State, request : Types.GovernanceRequest, caller : Principal) : Result.Result<Types.GovernanceResponse, Types.OrigynError> {

    //only the network can enact goverance
    if(state.state.collection_data.network != ?caller){
      return return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "governance_nft_origyn - unauthorized access - only network can govern", ?caller))
    };

    switch(request){
      case(#clear_shared_wallets(token_id)){
      //clears shared wallets from an NFT leaving only the last assigned owner in control of the NFT
        var metadata = switch(Metadata.get_metadata_for_token(state, token_id, caller, ?state.canister(), state.state.collection_data.owner)){
          case(#err(err))return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "share_nft_origyn token not found" # err.flag_point, ?caller));
          case(#ok(val)) val;
        };

        metadata := Metadata.set_system_var(metadata, Types.metadata.__system_wallet_shares, #Empty);
        Map.set<Text, CandyTypes.CandyValue>(state.state.nft_metadata, Map.thash, token_id, metadata);
        return #ok(#clear_shared_wallets(true));

      };
      case(_) return #err(Types.errors(?state.canistergeekLogger, #nyi, "governance_nft_origyn - not yet implemented" # debug_show(request), ?caller))

    };
   };
};