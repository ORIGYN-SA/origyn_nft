import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Deque "mo:base/Deque";
import Error "mo:base/Error";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";

import AccountIdentifier "mo:principalmo/AccountIdentifier";

import Star "mo:star/star";
import SHA256 "mo:crypto/SHA/SHA256";
import Parser "mo:parser-combinators/Parser";

import PutBalance "./put_balance";
import Ledger_Interface "../ledger_interface";
import Metadata "../metadata";
import MigrationTypes "../migrations/types";
import Migrations "../migrations/types";
import NFTUtils "../utils";
import Types "../types";
import FeeAccount "./fee_account";
import Verify "./verify_reciept";

module {
  let debug_channel = {
    royalties = true;
  };

  type StateAccess = Types.State;

  let CandyTypes = MigrationTypes.Current.CandyTypes;
  let Conversions = MigrationTypes.Current.Conversions;
  let Properties = MigrationTypes.Current.Properties;
  let Map = MigrationTypes.Current.Map;

  type ProcessRoyaltiesRequest = {
    var remaining : Nat;
    total : Nat;
    fee : Nat;
    account_hash : ?Blob;
    royalty : [CandyTypes.CandyShared];
    escrow : Types.EscrowReceipt;
    broker_id : ?MigrationTypes.Current.Account;
    original_broker_id : ?Principal;
    sale_id : ?Text;
    metadata : CandyTypes.CandyShared;
    token_id : ?Text;
    token : Types.TokenSpec;
    fee_schema : Text;
    fee_accounts_with_owner : [(MigrationTypes.Current.FeeName, MigrationTypes.Current.Account)];
  };

  public let royalties_names : [MigrationTypes.Current.FeeName] = [
    "com.origyn.royalty.broker",
    "com.origyn.royalty.node",
    "com.origyn.royalty.originator",
    "com.origyn.royalty.network",
    "com.origyn.royalty.custom",
  ];

  public func get_total_amount_fixed_royalties(fee_accounts : [MigrationTypes.Current.FeeName], metadata : CandyTypes.CandyShared) : Nat {
    var total = 0;
    debug if (debug_channel.royalties) D.print("get_total_amount_fixed_royalties");

    let royalty = switch (Properties.getClassPropertyShared(metadata, Types.metadata.__system)) {
      case (null) { [] };
      case (?val) {
        royalty_to_array(val.value, Types.metadata.__system_fixed_royalty);
      };
    };

    debug if (debug_channel.royalties) D.print("royalty " # debug_show (royalty));

    label royaltyLoop for (this_item in royalty.vals()) {
      let loaded_royalty = switch (_load_royalty(Types.metadata.__system_fixed_royalty, this_item)) {
        case (#ok(val)) { val };
        case (#err(_)) {
          debug if (debug_channel.royalties) D.print("err");
          return 0;
        };
      };

      let tag = switch (loaded_royalty) {
        case (#fixed(val)) { val.tag };
        case (#dynamic(val)) { val.tag };
      };

      switch (Array.find<MigrationTypes.Current.FeeName>(fee_accounts, func(fee_name) { return fee_name == tag })) {
        case (null) {
          continue royaltyLoop;
        };
        case (_) {};
      };

      switch (loaded_royalty) {
        case (#fixed(val)) {
          debug if (debug_channel.royalties) D.print("load fixed royalty " # debug_show (val));
          total := total + Int.abs(Float.toInt(Float.ceil(val.fixedXDR)));
        };
        case (_) {};
      };
    };

    debug if (debug_channel.royalties) D.print("total " # debug_show (total));
    return total;
  };

  private func dev_fund() : { owner : Principal; sub_account : ?Blob } {
    {
      owner = Principal.fromText("cjrh3-ivpiy-uhwu3-fenuc-23mkg-vez2x-5dqbl-obt3c-2onzn-alaib-kae");
      sub_account = null;
    };
  };

  /**
    * Converts the properties and collection of a Candy NFT to an array.
    *
    * @param {CandyTypes.CandyShared} properties - The properties of the Candy NFT.
    * @param {Text} collection - The collection of the Candy NFT.
    *
    * @returns {Array} - An array of Candy NFT properties.
    */
  public func royalty_to_array(properties : CandyTypes.CandyShared, collection : Text) : [CandyTypes.CandyShared] {
    debug if (debug_channel.royalties) D.print("In royalty to array" # debug_show ((properties, collection)));
    switch (Properties.getClassPropertyShared(properties, collection)) {
      case (null) {};
      case (?list) {
        debug if (debug_channel.royalties) D.print("found list" # debug_show (list));
        switch (list.value) {
          case (#Array(the_array)) {
            debug if (debug_channel.royalties) D.print("found array");
            return the_array;
          };
          case (_) {};
        };
      };
    };

    // by default, load com.origyn.royalties.primary
    debug if (debug_channel.royalties) D.print("Load the default royalties primary value");
    switch (Properties.getClassPropertyShared(properties, "com.origyn.royalties.primary")) {
      case (null) { [] }; // should never happen
      case (?list) {
        debug if (debug_channel.royalties) D.print("found list" # debug_show (list));
        switch (list.value) {
          case (#Array(the_array)) {
            debug if (debug_channel.royalties) D.print("found array");
            return the_array;
          };
          case (_) { [] }; // should never happen
        };
      };
    };

  };

  /**
    * Calculates the network royalty account for a given principal.
    *
    * @param {Principal} principal - The principal for which to calculate the network royalty account.
    *
    * @returns {Array<Nat8>} An array of 8-bit natural numbers representing the calculated network royalty account.
    */
  public func get_network_royalty_account(principal : Principal, ledger_token_id : ?Nat) : [Nat8] {
    let h = SHA256.New();
    h.write(Conversions.candySharedToBytes(#Text("com.origyn.network_royalty")));
    h.write(Conversions.candySharedToBytes(#Text("canister-id")));
    h.write(Conversions.candySharedToBytes(#Text(Principal.toText(principal))));
    switch (ledger_token_id) {
      case (?val) {
        h.write(Conversions.candySharedToBytes(#Text("token-id")));
        h.write(Conversions.candySharedToBytes(#Nat(val)));
      };
      case (null) {};
    };
    h.sum([]);
  };

  public func _load_royalty(fee_schema : Text, royalty : CandyTypes.CandyShared) : Result.Result<MigrationTypes.Current.Royalty, Types.OrigynError> {
    debug if (debug_channel.royalties) D.print("_load_royalty" # debug_show (royalty));

    let ?properties : ?CandyTypes.PropertyShared = Properties.getClassPropertyShared(royalty, "tag") else return #err(Types.errors(#malformed_metadata, "_load_royalty - missing tag in royalty  ", null));
    let #Text(tag) = properties.value else return #err(Types.errors(#malformed_metadata, "_load_royalty - missing tag in royalty  ", null));

    if (fee_schema == Types.metadata.__system_fixed_royalty) {
      let ?properties_2 : ?CandyTypes.PropertyShared = Properties.getClassPropertyShared(royalty, "fixedXDR") else return #err(Types.errors(#malformed_metadata, "_load_royalty - missing fixedXDR in fixed royalty  ", null));
      let #Float(fixedXDR) = properties_2.value else return #err(Types.errors(#malformed_metadata, "_load_royalty - missing fixedXDR in fixed royalty  ", null));

      let tokenCanister : ?Principal = switch (Properties.getClassPropertyShared(royalty, "tokenCanister")) {
        case (null) { null };
        case (?val) {
          switch (val.value) {
            case (#Principal(val)) { ?val };
            case (_) null;
          };
        };
      };

      let tokenSymbol : ?Text = switch (Properties.getClassPropertyShared(royalty, "tokenSymbol")) {
        case (null) { null };
        case (?val) {
          switch (val.value) {
            case (#Text(val)) { ?val };
            case (_) null;
          };
        };
      };

      let tokenDecimals : ?Nat = switch (Properties.getClassPropertyShared(royalty, "tokenDecimals")) {
        case (null) { null };
        case (?val) {
          switch (val.value) {
            case (#Nat(val)) { ?val };
            case (_) null;
          };
        };
      };

      let tokenFee : ?Nat = switch (Properties.getClassPropertyShared(royalty, "tokenFee")) {
        case (null) { null };
        case (?val) {
          switch (val.value) {
            case (#Nat(val)) { ?val };
            case (_) null;
          };
        };
      };

      let token : ?Types.TokenSpec = if (tokenCanister != null and tokenSymbol != null and tokenDecimals != null and tokenFee != null) {
        switch (tokenCanister) {
          case (?canisterId) {
            ?#ic({
              canister = canisterId;
              decimals = Option.get<Nat>(tokenDecimals, 0);
              fee = tokenFee;
              id = null;
              standard = #Ledger;
              symbol = Option.get<Text>(tokenSymbol, "");
            });
          };
          case (null) { null };
        };
      } else {
        null;
      };

      return #ok(#fixed({ tag = tag; fixedXDR = fixedXDR; token = token }));
    } else {
      let ?properties_2 : ?CandyTypes.PropertyShared = Properties.getClassPropertyShared(royalty, "rate") else return #err(Types.errors(#malformed_metadata, "_load_royalty - missing rate in dynamic royalty  ", null));
      let #Float(rate) = properties_2.value else return #err(Types.errors(#malformed_metadata, "_load_royalty - missing rate in dynamic royalty  ", null));

      return #ok(#dynamic({ tag = tag; rate = rate }));
    };
  };

  //handles royalty distribution
  public func _process_royalties<system>(
    state : StateAccess,
    request : ProcessRoyaltiesRequest,
    caller : Principal,
  ) : (Nat, [(Types.EscrowRecord, Bool)]) {
    debug if (debug_channel.royalties) D.print("in process royalty" # debug_show (request));

    let results = Buffer.Buffer<(Types.EscrowRecord, Bool)>(1);

    label royaltyLoop for (this_item in request.royalty.vals()) {
      debug if (debug_channel.royalties) D.print("getting items from class " # debug_show (this_item));

      let loaded_royalty = switch (_load_royalty(request.fee_schema, this_item)) {
        case (#ok(val)) { val };
        case (#err(err)) {
          // should never happen and been check before processing royalties.
          debug if (debug_channel.royalties) D.print("_process_royalties - error _load_royalty - this path should never happened.");
          return (request.remaining, []);
          // return #err(Types.errors( #malformed_metadata, "_process_royalties - error _load_royalty ", ?caller));
        };
      };

      let tag = switch (loaded_royalty) {
        case (#fixed(val)) { val.tag };
        case (#dynamic(val)) { val.tag };
      };

      let total_royalty = switch (loaded_royalty) {
        case (#fixed(val)) {
          Int.abs(Float.toInt(Float.ceil(val.fixedXDR)));
        };
        case (#dynamic(val)) {
          (request.total * Int.abs(Float.toInt(val.rate * 1_000_000))) / 1_000_000;
        };
      };

      debug if (debug_channel.royalties) D.print("total_royalty =  " # debug_show (total_royalty));

      let principal : [{ owner : Principal; sub_account : ?Blob }] = switch (Properties.getClassPropertyShared(this_item, "account")) {
        case (null) {
          let #ic(tokenSpec) = request.token else {
            debug if (debug_channel.royalties) D.print("not an IC token spec so continuing " # debug_show (request.token));
            continue royaltyLoop;
          }; //we only support ic token specs for royalties

          let _association_table : [(Text, f : (state : StateAccess, request : ProcessRoyaltiesRequest, tokenSpec : Types.ICTokenSpec) -> [{ owner : Principal; sub_account : ?Blob }])] = [
            (Types.metadata.royalty_network, _build_network_account),
            (Types.metadata.royalty_node, _build_royalties_node_account),
            (Types.metadata.royalty_originator, _build_royalties_originator_account),
            (Types.metadata.royalty_broker, _build_royalties_broker_account),
          ];

          let _current_royalty = Array.find<(Text, f : (state : StateAccess, request : ProcessRoyaltiesRequest, tokenSpec : Types.ICTokenSpec) -> [{ owner : Principal; sub_account : ?Blob }])>(_association_table, func x = tag == x.0);
          switch (_current_royalty) {
            case (?val) { val.1 (state, request, tokenSpec) };
            case (null) { [dev_fund()] }; //dev fund
          };

        };
        case (?val) {
          switch (val.value) {
            case (#Principal(val)) [NFTUtils.create_principal_with_no_subaccount(val)];
            case (_) [dev_fund()]; //dev fund
          };
        };
      };

      debug if (debug_channel.royalties) D.print("fee_accounts_with_owner =  " # debug_show (request.fee_accounts_with_owner));
      switch (Array.find<(MigrationTypes.Current.FeeName, MigrationTypes.Current.Account)>(request.fee_accounts_with_owner, func((fee_name, acc)) { return fee_name == tag })) {
        case (?(fee_name, fee_accounts_owner)) {
          let fee_accounts_set : { owner : Principal; sub_account : ?Blob } = switch (fee_accounts_owner) {
            case (#account(fee_accounts_set)) {
              fee_accounts_set;
            };
            case (#principal(p_account)) {
              { owner = p_account; sub_account = null };
            };
            case (_) {
              debug if (debug_channel.royalties) D.print("Process royalties - shouldnt go there : " # debug_show (fee_accounts_owner));
              continue royaltyLoop;
            };
          };

          for (this_principal in principal.vals()) {
            let this_royalty = (total_royalty / principal.size());
            debug if (debug_channel.royalties) D.print("this_royalty =  " # debug_show (this_royalty));

            let _fee = switch (loaded_royalty) {
              case (#fixed(val)) {
                switch (val.token) {
                  case (?_token) {
                    switch (_token) {
                      case (#ic(token)) { Option.get<Nat>(token.fee, 0) };
                      case (_) { request.fee };
                    };
                  };
                  case (_) { request.fee };
                };
              };
              case (#dynamic(_)) { request.fee };
            };

            if (this_royalty > _fee) {
              let send_account : { owner : Principal; sub_account : ?Blob } = this_principal;

              let receiver_account = #account({
                owner = send_account.owner;
                sub_account = switch (send_account.sub_account) {
                  case (null) null;
                  case (?val) ?val;
                };
              });

              var _escrow : Types.EscrowReceipt = {
                request.escrow with
                buyer = #account(fee_accounts_set);
                seller = #account(send_account);
                amount = this_royalty;
                token_id = Option.get(request.token_id, "");
                token = switch (loaded_royalty) {
                  case (#fixed(val)) {
                    switch (val.token) {
                      case (?_token) {
                        _token;
                      };
                      case (_) {
                        request.escrow.token;
                      };
                    };
                  };
                  case (#dynamic(_)) {
                    request.escrow.token;
                  };
                };
              };

              let fees_account_info : Types.SubAccountInfo = NFTUtils.get_fee_deposit_account_info(_escrow.buyer, state.canister());

              let id = Metadata.add_transaction_record<system>(
                state,
                {
                  token_id = request.escrow.token_id;
                  index = 0;
                  txn_type = #royalty_paid {
                    _escrow with
                    tag = tag;
                    receiver = receiver_account;
                    sale_id = request.sale_id;
                    extensible = switch (request.token_id) {
                      case (null) #Option(null) : CandyTypes.CandyShared;
                      case (?token_id) #Text(token_id) : CandyTypes.CandyShared;
                    };
                  };
                  timestamp = state.get_time();
                },
                caller,
              );

              debug if (debug_channel.royalties) D.print("added trx" # debug_show (id));

              let newReciept = {
                _escrow with
                seller = receiver_account;
                sale_id = request.sale_id;
                lock_to_date = null;
                account_hash = ?fees_account_info.account.sub_account;
              };

              results.add((newReciept, true));
            } else {
              //can't pay out if less than fee
            };
          };
        };
        case (null) {
          debug if (debug_channel.royalties) D.print("test royalty" # debug_show ((total_royalty, principal)));
          for (this_principal in principal.vals()) {
            let this_royalty = (total_royalty / principal.size());

            if (this_royalty > request.fee) {
              request.remaining -= this_royalty;

              let send_account : { owner : Principal; sub_account : ?Blob } = this_principal;

              let receiver_account = #account({
                owner = send_account.owner;
                sub_account = switch (send_account.sub_account) {
                  case (null) null;
                  case (?val) ?val;
                };
              });

              let id = Metadata.add_transaction_record<system>(
                state,
                {
                  token_id = request.escrow.token_id;
                  index = 0;
                  txn_type = #royalty_paid {
                    request.escrow with
                    amount = this_royalty;
                    tag = tag;
                    receiver = receiver_account;
                    sale_id = request.sale_id;
                    extensible = switch (request.token_id) {
                      case (null) #Option(null) : CandyTypes.CandyShared;
                      case (?token_id) #Text(token_id) : CandyTypes.CandyShared;
                    };
                  };
                  timestamp = state.get_time();
                },
                caller,
              );

              debug if (debug_channel.royalties) D.print("added trx" # debug_show (id));

              let newReciept = {
                request.escrow with
                amount = this_royalty;
                seller = receiver_account;
                sale_id = request.sale_id;
                lock_to_date = null;
                account_hash = request.account_hash;
              };

              //note, if a sale ledger already exists this will add the value, but we need to keep the original amount so we don't double request the same amount.
              let new_sale_balance = PutBalance.put_sales_balance(state, newReciept, true);

              results.add((newReciept, false));
              debug if (debug_channel.royalties) D.print("new_sale_balance" # debug_show (newReciept));
            } else {
              //can't pay out if less than fee
            };
          };
        };
      };
    };

    return (request.remaining, Buffer.toArray(results));
  };

  private func _build_network_account(state : StateAccess, request : ProcessRoyaltiesRequest, tokenSpec : Types.ICTokenSpec) : [{
    owner : Principal;
    sub_account : ?Blob;
  }] {
    debug if (debug_channel.royalties) D.print("found the network" # debug_show (get_network_royalty_account(tokenSpec.canister, tokenSpec.id)));
    switch (state.state.collection_data.network) {
      case (null) [dev_fund()]; //dev fund
      case (?val) [{
        owner = val;
        sub_account = ?Blob.fromArray(get_network_royalty_account(tokenSpec.canister, tokenSpec.id));
      }];
    };
  };

  private func _build_royalties_node_account(state : StateAccess, request : ProcessRoyaltiesRequest, tokenSpec : Types.ICTokenSpec) : [{
    owner : Principal;
    sub_account : ?Blob;
  }] {
    let val = Metadata.get_system_var(request.metadata, Types.metadata.__system_node);

    switch (val) {
      case (#Option(null)) [dev_fund()]; //dev fund
      case (#Principal(val)) [NFTUtils.create_principal_with_no_subaccount(val)];
      case (_) [dev_fund()];
    };
  };

  private func _build_royalties_originator_account(state : StateAccess, request : ProcessRoyaltiesRequest, tokenSpec : Types.ICTokenSpec) : [{
    owner : Principal;
    sub_account : ?Blob;
  }] {
    let val = Metadata.get_system_var(request.metadata, Types.metadata.__system_originator);

    switch (val) {
      case (#Option(null)) [dev_fund()]; //dev fund
      case (#Principal(val)) [NFTUtils.create_principal_with_no_subaccount(val)];
      case (_) [dev_fund()];
    };
  };

  private func _build_royalties_broker_account(state : StateAccess, request : ProcessRoyaltiesRequest, tokenSpec : Types.ICTokenSpec) : [{
    owner : Principal;
    sub_account : ?Blob;
  }] {
    debug if (debug_channel.royalties) D.print("_build_royalties_broker_account : request.broker_id " # debug_show (request.broker_id) # " request.original_broker_id " # debug_show (request.original_broker_id));

    switch (request.broker_id, request.original_broker_id) {
      case (null, null) {
        let ?collection = Map.get(state.state.nft_metadata, Map.thash, "") else {
          // NFTUtils.logDirectly("_build_royalties_broker_account cannot find collection metatdata. this should not happene" # debug_show (request.token_id), #Bool(false), null);
          D.trap("_build_royalties_broker_account cannot find collection metatdata. this should not happen");
        };

        let override = switch (Metadata.get_nft_bool_property(collection, Types.metadata.broker_royalty_dev_fund_override)) {
          case (#ok(val)) val;
          case (_) {
            // NFTUtils.logDirectly("_build_royalties_broker_account overriding error candy type" # debug_show (collection) # debug_show (request.token_id), #Bool(false), null);
            false;
          };
        };

        if (override) {
          // NFTUtils.logDirectly("_build_royalties_broker_account overriding " # debug_show (request.token_id), #Bool(override), null);
          return [];
        } else {
          // NFTUtils.logDirectly("_build_royalties_broker_account override result using dev fund" # debug_show (request.token_id), #Bool(override), null);
          [dev_fund()];
        };
      }; //dev fund
      case (?val, null) {
        [MigrationTypes.Current.account_to_owner_subaccount(val)];
      };
      case (null, ?val2) [NFTUtils.create_principal_with_no_subaccount(val2)];
      case (?val, ?val2) {
        if (MigrationTypes.Current.account_to_principal(val) == val2) {
          [MigrationTypes.Current.account_to_owner_subaccount(val)];
        } else [MigrationTypes.Current.account_to_owner_subaccount(val), NFTUtils.create_principal_with_no_subaccount(val2)];
      };
    };

  };
};
