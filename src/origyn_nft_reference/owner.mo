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
import Market "market";
import Metadata "metadata";
import MigrationTypes "./migrations/types";
import NFTUtils "utils";
import Types "types";


module {

    type StateAccess = Types.State;
    let Map = MigrationTypes.Current.Map;

    let debug_channel = {
        owner = false;
    };

    /**
    * Share ownership of an NFT token within the same principal or account ID.
    * This should only be used by the owner to transfer between wallets they own.
    * To protect this, any assets in the canister associated with the account/principal should be moved along with the token.
    * 
    * @param {StateAccess} state - the state of the canister
    * @param {Types.ShareWalletRequest} request - the request object containing the token ID, the current owner's account, and the new owner's account
    * @param {Principal} caller - the principal of the caller
    * 
    * @returns {Types.OwnerUpdateResult} the transaction record and a list of assets associated with the token
    */
    public func share_wallet_nft_origyn(state: StateAccess, request : Types.ShareWalletRequest, caller : Principal) :  Result.Result<Types.OwnerTransferResponse,Types.OrigynError> {
      //this should only be used by an owner to transfer between wallets that they own. to protect this, any assets in the canister associated with the account/principal
      //should be moved along with the the token

      //nyi: transfers from one accountid to another must be from the same principal.Array
      //to transfer from accountId they must be in the null subaccount

      var metadata = switch(Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)){
        case(#err(err)){
          return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "share_nft_origyn token not found" # err.flag_point, ?caller));
        };
        case(#ok(val)){
          val;
        };
      };

      //can't owner transfer if token is soulbound
      if (Metadata.is_soulbound(metadata)) {
        return #err(Types.errors(?state.canistergeekLogger,  #token_non_transferable, "share_nft_origyn ", ?caller));
      };

      let owner = switch(Metadata.get_nft_owner(metadata)){
        case(#err(err)){
          return #err(Types.errors(?state.canistergeekLogger,  err.error, "share_nft_origyn " # err.flag_point, ?caller));
        };
        case(#ok(val)){
          val;
        };
      };

      if(Types.account_eq(owner, #principal(caller)) == false){
        //cant transfer something you dont own;
        debug if(debug_channel.owner) D.print("should be returning item not owned");
        return #err(Types.errors(?state.canistergeekLogger,  #item_not_owned, "share_nft_origyn cannot transfer item from does not own", ?caller));
      };


      //look for an existing sale
      switch(Market.is_token_on_sale(state, metadata, caller)){
        case(#err(err)){return #err(Types.errors(?state.canistergeekLogger,  err.error, "share_nft_origyn ensure_no_sale " # err.flag_point, ?caller))};
        case(#ok(val)){
          if(val == true){
            return #err(Types.errors(?state.canistergeekLogger,  #existing_sale_found, "share_nft_origyn - sale exists " # request.token_id , ?caller));
          };
        };
      };

      debug if(debug_channel.owner) D.print(debug_show(owner));
      debug if(debug_channel.owner) D.print(debug_show(request.from));
      if(Types.account_eq(owner, request.from) == false){
        //cant transfer something you dont own;
        debug if(debug_channel.owner) D.print("should be returning item not owned");
        return #err(Types.errors(?state.canistergeekLogger,  #item_not_owned, "share_nft_origyn cannot transfer item from does not own", ?caller));
      };

      //set new owner
      //D.print("Setting new Owner");
      metadata := switch(Properties.updateProperties(Conversions.valueToProperties(metadata), [
        {
          name = Types.metadata.owner;
          mode = #Set(Metadata.account_to_candy(request.to));
        }
      ])){
          case(#ok(props)){
              #Class(props);
          };
          case(#err(err)){
              //maybe the owner is immutable
              return #err(Types.errors(?state.canistergeekLogger,  #update_class_error, "share_nft_origyn - error setting owner " # request.token_id, ?caller));
          };
      };

      let wallets = Buffer.Buffer<CandyTypes.CandyValue>(1);
      //add the wallet share
      switch(Metadata.get_system_var(metadata, Types.metadata.__system_wallet_shares)){
        case(#Empty){};
        case(#Array(#thawed(val))){
          let result = Map.new<Types.Account, Bool>();
          for(thisItem in val.vals()){
            wallets.add(thisItem);
          };
        };
        case(#Array(#frozen(val))){
          for(thisItem in val.vals()){
            wallets.add(thisItem);
          };
        };
        case(_){
          return #err(Types.errors(?state.canistergeekLogger,  #improper_interface, "share_nft_origyn - wallet_share not an array", null));
        };
      };

      wallets.add(Metadata.account_to_candy(owner));

      metadata := Metadata.set_system_var(metadata, Types.metadata.__system_wallet_shares, #Array(#frozen(Buffer.toArray(wallets))));


      debug if(debug_channel.owner) D.print("updating metadata");
      Map.set(state.state.nft_metadata, Map.thash, request.token_id, metadata);

      //D.print("Adding transaction");
      let txn_record = switch(Metadata.add_transaction_record(state, {
            token_id = request.token_id;
            index = 0; //mint should always be 0
            txn_type = #owner_transfer({
                from = request.from;
                to = request.to;
                extensible = #Empty;
            });
            timestamp = Time.now();
            chain_hash = [];
        }, caller)){
          case(#err(err)){
              //potentially big error once certified data is in place...may need to throw
              return #err(Types.errors(?state.canistergeekLogger,  err.error, "share_nft_origyn add_transaction_record" # err.flag_point, ?caller));
          };
          case(#ok(val)){val};
      };

      //D.print("returning transaction");
      #ok({
          transaction =txn_record;
          assets= []});
    };


    /**
    * Transfer a DIP721 token from one principal to another by finding the appropriate escrow record and using it for the transfer.
    * If the escrow does not exist, the function fails.
    *
    * @param {StateAccess} state - StateAccess to the canister's state
    * @param {Principal} from - The principal that currently owns the token
    * @param {Principal} to - The principal that will own the token after the transfer
    * @param {Nat} tokenAsNat - The token ID encoded as a Nat value
    * @param {Principal} caller - The principal that called the function
    * 
    * @returns {DIP721.Result} - A DIP721 result object indicating the success or failure of the transfer operation.
    */
    public func transferDip721(state: StateAccess, from: Principal, to: Principal, tokenAsNat: Nat, caller: Principal) : async* DIP721.DIP721NatResult{
        //uses market_transfer_nft_origyn where we look for an escrow from one user to the other and use the full escrow for the transfer
        //if the escrow doesn't exist then we should fail
        //nyi: determine if this is a marketable NFT and take proper action
        //marketable NFT may not be transfered between owner wallets execpt through share_nft_origyn
        let token_id = NFTUtils.get_nat_as_token_id(tokenAsNat);
        
        let escrows = switch(Market.find_escrow_reciept(state, #principal(to), #principal(from), token_id)){
            case(#ok(val)){val};
            case(#err(err)){
                return #Err(#Other("escrow required for DIP721 transfer - failure of DIP721 transferFrom " # err.flag_point));
            };
        };

        if(Map.size(escrows) == 0 ){
            return #Err(#Other("escrow required for DIP721 transfer - failure of DIP721 transferFrom"));
        };

        //dip721 is not discerning. If it finds a first asset it will use that for the transfer
        let first_asset = Iter.toArray(Map.entries(escrows))[0];

        if(first_asset.1.sale_id != null){
            return #Err(#Other("escrow required for DIP721 transfer - failure of DIP721 transferFrom due to sale_id in escrow reciept" # debug_show(first_asset)));
        };

        let result = await* Market.market_transfer_nft_origyn_async(state, {
            token_id = token_id;
            sales_config = 
              {
                  escrow_receipt = ?first_asset.1;
                  pricing = #instant;
                  broker_id = null;
              };            
        }, from);



        switch(result){
            case(#ok(data)){
                return #Ok(data.index);
            };
            case(#err(err)){
                
                return #Err(#Other("failure of DIP721 transferFrom " # err.flag_point));
                 
            };
        };
    };

    /**
    * Transfer an EXT token from one principal to another by finding the appropriate escrow record and using it for the transfer.
    * If the escrow does not exist, the function fails.
    *
    * @param {StateAccess} state - StateAccess to the canister's state
    * @param {EXT.TransferRequest} request - The transfer request object, which includes information about the token and the principals involved in the transfer
    * @param {Principal} caller - The principal that called the function
    * 
    * @returns {EXT.TransferResponse} - A transfer response object indicating the success or failure of the transfer operation.
    */
    public func transferExt(state: StateAccess, request: EXT.TransferRequest, caller : Principal) : async* EXT.TransferResponse {
      //uses market_transfer_nft_origyn where we look for an escrow from one user to the other and use the full escrow for the transfer
      //if the escrow doesn't exist then we should fail

        if(Types.account_eq(#principal(caller), switch(request.from){
                                case(#principal(data)){
                                    #principal(data);
                                };
                                case(#address(data)){
                                    #account_id(data);
                                };}) == false ){

            return #err(#Other("unauthorized caller must be the from address" # debug_show(request)));

        };
        
        switch(getNFTForTokenIdentifier(state, request.token)){
            case(#ok(data)){

                let escrows = switch(Market.find_escrow_reciept(state, switch(request.from){
                                case(#principal(data)){
                                    #principal(data);
                                };
                                case(#address(data)){
                                    #account_id(data);
                                };
                                /* case(_){
                                    return #err(#Other("accountID extensible not implemented in EXT transfer from"));
                                }; */
                            }, switch(request.from){
                                case(#principal(data)){
                                    #principal(data);
                                };
                                case(#address(data)){
                                    #account_id(data);
                                };
                                /* case(_){
                                    return #err(#Other("accountID extensible not implemented in EXT transfer from"));
                                }; */
                            }, data)){
                    case(#ok(val)){val};
                    case(#err(err)){
                      return #err(#Other("escrow required for EXT transfer - failure of EXT tranfer - have receiver visit https://prptl.io/-/" # Principal.toText(state.canister()) # "/-/" # data # "/-/vault?make-offer=true to make an offer" # err.flag_point));
                    };
                };

                if(Map.size(escrows) == 0 ){
                    return #err(#Other("escrow required of EXT tranfer transfer - failure of EXT tranfer - have receiver visit https://prptl.io/-/" # Principal.toText(state.canister()) # "/-/" # data # "/-/vault?make-offer=true to make an offer"));
                };

                //dip721 is not discerning. If it finds a first asset it will use that for the transfer
                let first_asset = Iter.toArray(Map.entries(escrows))[0];

                if(first_asset.1.sale_id != null){
                    return #err(#Other("escrow required of EXT tranfer transfer - failure of EXT tranfer due to sale_id in escrow reciept - have receiver visit https://prptl.io/-/" # Principal.toText(state.canister()) # "/-/" # data # "/-/vault?make-offer=true to make an offer. " # debug_show(first_asset)));
                };

                let result = await* Market.market_transfer_nft_origyn_async(state, {
                    token_id = data;
                    sales_config = 
                    {
                        escrow_receipt = ?first_asset.1;
                        pricing = #instant;
                        broker_id = null;
                    };            
                }, caller);

                switch(result){
                    case(#ok(data)){
                        return #ok(data.index);
                    };
                    case(#err(err)){
                        
                        return #err(#Other("failure of EXT tranfer " # err.flag_point));
                        
                    };
                };
            };
            case(#err(err)){
                return #err(#InvalidToken(request.token));
            };
        };
    };

    /**
    * Gets the NFT with the specified token identifier.
    * 
    * @param {StateAccess} state - The state accessor.
    * @param {EXT.TokenIdentifier} token - The token identifier to search for.
    * 
    * @returns {Result.Result<Text,Types.OrigynError>} Returns a result indicating success or failure with the data or an error message.
    */
    public func getNFTForTokenIdentifier(state: StateAccess, token: EXT.TokenIdentifier) : Result.Result<Text,Types.OrigynError> {

        for(this_nft in Map.entries(state.state.nft_metadata)){
            switch(Metadata.get_nft_id(this_nft.1)){
                case(#ok(data)){

                    if(Text.hash(data) == EXT.TokenIdentifier.getIndex(token) ){
                        return #ok(data);
                    };
                };
                case(_){};
            };

        };
        return #err(Types.errors(?state.canistergeekLogger,  #token_not_found, "getNFTForTokenIdentifier", null));
    };

    /**
    * Gets the account identifier of the bearer of the NFT with the specified token identifier.
    * 
    * @param {StateAccess} state - The state accessor.
    * @param {EXT.TokenIdentifier} tokenIdentifier - The token identifier for which to get the account identifier of the bearer.
    * @param {Principal} caller - The caller principal.
    * 
    * @returns {Types.EXTBearerResult} Returns a result indicating success or failure with the data or an error message.
    */
    public func bearerEXT(state: StateAccess, tokenIdentifier: EXT.TokenIdentifier, caller :Principal) : Types.EXTBearerResult{

        switch(getNFTForTokenIdentifier(state, tokenIdentifier)){
            case(#ok(data)){
                switch(Metadata.get_nft_owner(
                    switch(Metadata.get_metadata_for_token(state,
                        data
                    , caller, null, state.state.collection_data.owner)){
                        case(#err(err)){
                            return #err(#Other("Token not found"));
                        };
                        case(#ok(val)){
                            val;
                        };
                    })){
                        case(#err(err)){
                            return #err(#Other("ownerOf " # err.flag_point));
                        };
                        case(#ok(val)){
                            switch(val){
                                case(#principal(data)){
                                    return #ok(EXT.User.toAID(#principal(data)));
                                };
                                case(#account_id(data)){
                                    return #ok(data);
                                };
                                case(_){
                                    return #err(#Other("ownerOf unsupported owner type by DIP721" # debug_show(val)));
                                };
                            };

                        };
                    };
            };
            case(#err(err)){
                return #err(#InvalidToken(tokenIdentifier));
            };
        };
    };
}