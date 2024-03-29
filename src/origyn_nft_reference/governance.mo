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
import NFTUtils "utils";

module {

  let Map = MigrationTypes.Current.Map;
  let CandyTypes = MigrationTypes.Current.CandyTypes;

  let debug_channel = {
    function_announce = false;
    governance = false;
  };

  //allows the network to govern the NFT via decentralized concensus.
  /**
  * Executes a governance action for an NFT in the Origyn canister.
  * @param {Types.State} state - The current state of the Origyn canister.
  * @param {Types.GovernanceRequest} request - The governance request object specifying the type of action to execute.
  * @param {Principal} caller - The principal of the caller making the governance request.
  * @returns {Types.GovernanceResult} - Returns a Result object containing either a Types.GovernanceResponse object or a Types.OrigynError object if an error occurs during the governance process.
  * @throws {Types.OrigynError} Throws an OrigynError if an error occurs during the governance process.
  */
  public func governance_nft_origyn(state: Types.State, request : Types.GovernanceRequest, caller : Principal) : async* Types.GovernanceResult {

    //only the network can enact goverance
    if(NFTUtils.is_network(state, caller) == false){
      return #err(Types.errors(?state.canistergeekLogger,  #unauthorized_access, "governance_nft_origyn - unauthorized access - only network can govern", ?caller))
    };

    switch(request){
      case(#clear_shared_wallets(token_id)){
      //clears shared wallets from an NFT leaving only the last assigned owner in control of the NFT
        let ?metadata = Map.get(state.state.nft_metadata, Map.thash, token_id) else {
          return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "governance_nft_origyn - clear_shared_wallets token not found", ?caller));
        };

        let new_metadata = Metadata.set_system_var(metadata, Types.metadata.__system_wallet_shares, #Option(null));

        Map.set<Text, CandyTypes.CandyShared>(state.state.nft_metadata, Map.thash, token_id, new_metadata);

        return #ok(#clear_shared_wallets(true));

      };
      
      case(#update_system_var(request)){
      //clears shared wallets from an NFT leaving only the last assigned owner in control of the NFT
        let ?metadata = Map.get(state.state.nft_metadata, Map.thash, request.token_id) else {
          return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "governance_nft_origyn - update_system_var token not found", ?caller));
        };

        let new_metadata = Metadata.set_system_var(metadata, request.key, request.val);

        Map.set<Text, CandyTypes.CandyShared>(state.state.nft_metadata, Map.thash, request.token_id, new_metadata);

        return #ok(#update_system_var(true));

      };
      case(_) return #err(Types.errors(?state.canistergeekLogger, #nyi, "governance_nft_origyn - not yet implemented" # debug_show(request), ?caller))
    };
   };
};