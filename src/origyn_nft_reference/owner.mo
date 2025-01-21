import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Blob "mo:base/Blob";

import EXT "mo:ext/Core";
import Star "mo:star/star";

import ICRC7 "ICRC7";
import Market "market";
import Metadata "metadata";
import MigrationTypes "./migrations/types";
import ICRC2 "../external_canisters/ICRC2";
import Royalties "market/royalties";
import NFTUtils "utils";
import Types "types";

module {

  type StateAccess = Types.State;
  let Map = MigrationTypes.Current.Map;

  let debug_channel = {
    owner = false;
    icrc7 = true;
  };

  let CandyTypes = MigrationTypes.Current.CandyTypes;
  let Conversions = MigrationTypes.Current.Conversions;
  let Properties = MigrationTypes.Current.Properties;
  let Workspace = MigrationTypes.Current.Workspace;

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
  public func share_wallet_nft_origyn<system>(state : StateAccess, request : Types.ShareWalletRequest, caller : Principal) : Result.Result<Types.OwnerTransferResponse, Types.OrigynError> {
    //this should only be used by an owner to transfer between wallets that they own. to protect this, any assets in the canister associated with the account/principal
    //should be moved along with the the token

    //nyi: transfers from one accountid to another must be from the same principal.Array
    //to transfer from accountId they must be in the null subaccount

    var metadata = switch (Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) {
        return #err(Types.errors(#token_not_found, "share_nft_origyn token not found" # err.flag_point, ?caller));
      };
      case (#ok(val)) {
        val;
      };
    };

    //can't owner transfer if token is soulbound
    if (Metadata.is_soulbound(metadata)) {
      return #err(Types.errors(#token_non_transferable, "share_nft_origyn ", ?caller));
    };

    let owner = switch (Metadata.get_nft_owner(metadata)) {
      case (#err(err)) {
        return #err(Types.errors(err.error, "share_nft_origyn " # err.flag_point, ?caller));
      };
      case (#ok(val)) {
        val;
      };
    };

    if (Types.account_eq(owner, { owner = caller; subaccount = null }) == false) {
      //cant transfer something you dont own;
      debug if (debug_channel.owner) D.print("should be returning item not owned");
      return #err(Types.errors(#item_not_owned, "share_nft_origyn cannot transfer item from does not own", ?caller));
    };

    //look for an existing sale
    switch (Market.is_token_on_sale(state, metadata, caller)) {
      case (#err(err)) {
        return #err(Types.errors(err.error, "share_nft_origyn ensure_no_sale " # err.flag_point, ?caller));
      };
      case (#ok(val)) {
        if (val == true) {
          return #err(Types.errors(#existing_sale_found, "share_nft_origyn - sale exists " # request.token_id, ?caller));
        };
      };
    };

    debug if (debug_channel.owner) D.print(debug_show (owner));
    debug if (debug_channel.owner) D.print(debug_show (request.from));
    if (Types.account_eq(owner, request.from) == false) {
      //cant transfer something you dont own;
      debug if (debug_channel.owner) D.print("should be returning item not owned");
      return #err(Types.errors(#item_not_owned, "share_nft_origyn cannot transfer item from does not own", ?caller));
    };

    //set new owner
    //D.print("Setting new Owner");
    metadata := switch (Properties.updatePropertiesShared(Conversions.candySharedToProperties(metadata), [{ name = Types.metadata.owner; mode = #Set(Metadata.account_to_candy(request.to)) }])) {
      case (#ok(props)) {
        #Class(props);
      };
      case (#err(err)) {
        //maybe the owner is immutable
        return #err(Types.errors(#update_class_error, "share_nft_origyn - error setting owner " # request.token_id, ?caller));
      };
    };

    let wallets = Buffer.Buffer<CandyTypes.CandyShared>(1);
    //add the wallet share
    switch (Metadata.get_system_var(metadata, Types.metadata.__system_wallet_shares)) {
      case (#Option(null)) {};
      case (#Array(val)) {
        let result = Map.new<Types.Account, Bool>();
        for (thisItem in val.vals()) {
          wallets.add(thisItem);
        };
      };
      case (_) {
        return #err(Types.errors(#improper_interface, "share_nft_origyn - wallet_share not an array", null));
      };
    };

    wallets.add(Metadata.account_to_candy(owner));

    metadata := Metadata.set_system_var(metadata, Types.metadata.__system_wallet_shares, #Array(Buffer.toArray(wallets)));

    debug if (debug_channel.owner) D.print("updating metadata");
    Map.set(state.state.nft_metadata, Map.thash, request.token_id, metadata);

    //D.print("Adding transaction");
    let txn_record = switch (
      Metadata.add_transaction_record(
        state,
        {
          token_id = request.token_id;
          index = 0; //mint should always be 0
          txn_type = #owner_transfer({
            from = request.from;
            to = request.to;
            extensible = #Option(null);
          });
          timestamp = Time.now();
          chain_hash = [];
        },
        caller,
      )
    ) {
      case (#err(err)) {
        //potentially big error once certified data is in place...may need to throw
        return #err(Types.errors(err.error, "share_nft_origyn add_transaction_record" # err.flag_point, ?caller));
      };
      case (#ok(val)) { val };
    };

    //D.print("returning transaction");
    #ok({
      transaction = txn_record;
      assets = [];
    });
  };

  /**
    * Prepare ransfer a ICRC7 token from one account to another by finding the appropriate escrow record and using it for the transfer.
    * If the escrow does not exist, the function fails.
    *
    * @param {StateAccess} state - StateAccess to the canister's state
    * @param {Account} from - The account that currently owns the token
    * @param {Account} to - The account that will own the token after the transfer
    * @param {Nat} tokenAsNat - The token ID encoded as a Nat value
    * @param {Principal} caller - The principal that called the function
    *
    * @returns {ICRC7.TransferResult} - A ICRC7 result object indicating the success or failure of the transfer operation.
    */
  public func _prepare_transferICRC7(state : StateAccess, from : ICRC7.Account, to : ICRC7.Account, tokenAsNat : Nat, caller : Principal) : async* ICRC7.TransferResultItem {
    let token_id = switch (NFTUtils.get_nat_as_token_id(tokenAsNat)) {
      case (#ok(val)) { val };
      case (#err(err)) {
        return {
          token_id = 0;
          transfer_result = #Err(
            #GenericError({
              message = "get nat as token id failed";
              error_code = 1;
            })
          );
        };
      };
    };

    debug if (debug_channel.icrc7) D.print("transferICRC7 : token_id " # debug_show (token_id));

    let metadata = switch (Metadata.get_metadata_for_token(state, token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
      case (#err(err)) {
        return {
          token_id = tokenAsNat;
          transfer_result = #Err(
            #GenericError({
              message = "fail to get origyn internal metadata ";
              error_code = 2;
            })
          );
        };
      };
      case (#ok(val)) { val };
    };

    debug if (debug_channel.icrc7) D.print("transferICRC7 : metadata " # debug_show (metadata));

    let ?collection = Map.get(state.state.nft_metadata, Map.thash, "") else {
      // NFTUtils.logDirectly("transferICRC7 cannot find collection metatdata. this should not happene" # debug_show (tokenAsNat), #Bool(false), null);
      D.trap("transferICRC7 cannot find collection metatdata. this should not happen");
    };

    let override = switch (Metadata.get_nft_bool_property(collection, Types.metadata.broker_royalty_dev_fund_override)) {
      case (#ok(val)) val;
      case (_) {
        // NFTUtils.logDirectly("_build_royalties_broker_account overriding error candy type" # debug_show (collection) # debug_show (tokenAsNat), #Bool(false), null);
        false;
      };
    };

    let _royalties_names = Array.filter<Text>(Royalties.royalties_names, func x = x != "com.origyn.royalty.broker");
    let fee_deposit_amount : Nat = Royalties.get_total_amount_fixed_royalties(_royalties_names, metadata);

    let ogy_ledger : ICRC2.Self = actor (MigrationTypes.Current.OGY_LEDGER_CANISTER_ID);

    debug if (debug_channel.icrc7) D.print("transferICRC7 : fee_deposit_amount " # debug_show (fee_deposit_amount));

    let fee_deposit_request : Types.FeeDepositRequest = {
      account = { owner = from.owner; subaccount = from.subaccount };
      token = MigrationTypes.Current.OGY();
      amount = fee_deposit_amount;
    };

    let fee_deposit_ret = Star.toResult<Types.ManageSaleResponse, Types.OrigynError>(await* Market.deposit_fee_nft_origyn(state, fee_deposit_request, caller));
    debug if (debug_channel.icrc7) D.print("fee_deposit_ret = " # debug_show (fee_deposit_ret));
    switch (fee_deposit_ret) {
      case (#ok(val)) {
        switch (val) {
          case (#fee_deposit(info)) {
            debug if (debug_channel.icrc7) D.print("transferICRC7 : fee_deposit(info) " # debug_show (info));
          };
          case (_) {
            debug if (debug_channel.icrc7) D.print("transferICRC7 : fee_deposit request failed : Should have returned a #fee_deposit");
            return {
              token_id = tokenAsNat;
              transfer_result = #Err(
                #GenericError({
                  message = "transferICRC7 : fee_deposit request failed : Should have returned a #fee_deposit ";
                  error_code = 3;
                })
              );
            };

          };
        };
      };
      case (_) {
        debug if (debug_channel.icrc7) D.print("transferICRC7 : fee_deposit request failed : Should have returned a #fee_deposit");
        return {
          token_id = tokenAsNat;
          transfer_result = #Err(
            #GenericError({
              message = "transferICRC7 : fee_deposit request failed : Should have returned a #fee_deposit ";
              error_code = 3;
            })
          );
        };

      };
    };
    return { token_id = tokenAsNat; transfer_result = #Ok(0) };
  };

  /**
    * Transfer a ICRC7 token from one account to another by finding the appropriate escrow record and using it for the transfer.
    * If the escrow does not exist, the function fails.
    *
    * @param {StateAccess} state - StateAccess to the canister's state
    * @param {Account} from - The account that currently owns the token
    * @param {Account} to - The account that will own the token after the transfer
    * @param {Nat} tokenAsNat - The token ID encoded as a Nat value
    * @param {Principal} caller - The principal that called the function
    *
    * @returns {ICRC7.TransferResult} - A ICRC7 result object indicating the success or failure of the transfer operation.
    */

  public func transferICRC7(state : StateAccess, from : ICRC7.Account, to : ICRC7.Account, tokenAsNat : Nat, caller : Principal) : async* ICRC7.TransferResultItem {
    let token_id = switch (NFTUtils.get_nat_as_token_id(tokenAsNat)) {
      case (#ok(val)) { val };
      case (#err(err)) {
        return {
          token_id = 0;
          transfer_result = #Err(#GenericError({ message = "get nat as token id failed"; error_code = 1 }));
        };
      };
    };

    debug if (debug_channel.icrc7) D.print("transferICRC7 : market_transfer_nft_origyn_async query " # debug_show ({ token_id = token_id; sales_config = { escrow_receipt = ?{ seller = #account({ owner = from.owner; sub_account = from.subaccount }); buyer = #account({ owner = to.owner; sub_account = to.subaccount }); token_id = token_id; token = #ic({ canister = Principal.fromText(MigrationTypes.Current.OGY_LEDGER_CANISTER_ID); standard = #Ledger; decimals = 8; symbol = "OGY "; fee = ?200_000; id = null }); amount = 0 }; pricing = #instant(?[#fee_accounts(Royalties.royalties_names), #fee_schema(Types.metadata.__system_fixed_royalty)]); broker_id = null } }));

    let result = await* Market.market_transfer_nft_origyn_async(
      state,
      {
        token_id = token_id;
        sales_config = {
          escrow_receipt = ?{
            seller = {
              owner = from.owner;
              subaccount = from.subaccount;
            };
            buyer = {
              owner = to.owner;
              subaccount = to.subaccount;
            };
            token_id = token_id;
            token = #ic({
              canister = Principal.fromText(MigrationTypes.Current.OGY_LEDGER_CANISTER_ID);
              standard = #Ledger;
              decimals = 8;
              symbol = "OGY ";
              fee = ?200_000;
              id = null;
            });
            amount = 0;
          };
          pricing = #instant(
            ?[
              #fee_accounts(Royalties.royalties_names),
              #fee_schema(Types.metadata.__system_fixed_royalty),
              #transfer,
            ]
          );
          broker_id = null;
        };
      },
      caller,
      false,
    );

    debug if (debug_channel.icrc7) D.print("transferICRC7 : result " # debug_show (result));

    switch (result) {
      case (#ok(data)) {
        return { token_id = tokenAsNat; transfer_result = #Ok(data.index) };
      };
      case (#err(err)) {

        return {
          token_id = tokenAsNat;
          transfer_result = #Err(#GenericError({ message = "failure of ICRC7 transferFrom " # err.flag_point; error_code = 4 }));
        };

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
  public func getNFTForTokenIdentifier(state : StateAccess, token : EXT.TokenIdentifier) : Result.Result<Text, Types.OrigynError> {

    for (this_nft in Map.entries(state.state.nft_metadata)) {
      switch (Metadata.get_nft_id(this_nft.1)) {
        case (#ok(data)) {

          if (Text.hash(data) == EXT.TokenIdentifier.getIndex(token)) {
            return #ok(data);
          };
        };
        case (_) {};
      };

    };
    return #err(Types.errors(#token_not_found, "getNFTForTokenIdentifier", null));
  };

};
