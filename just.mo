// NOTE: Transfers the OGY tokens using icrc2_transfer_from method
/**
  * deposit_fee_nft_origyn
  * @param {StateAccess} state - StateAccess object for accessing the canister's state.
  * @param {Types.FeeDepositRequest} request - FeeDepositRequest object containing the details of the fee deposit.
  * @param {Principal} caller - Principal object representing the caller.
  * @returns {Star.Star<Types.ManageSaleResponse, Types.OrigynError>} - A result indicating whether the fee deposit was created.
  */
// token_id : Text,
public func deposit_fee_nft_origyn(state : StateAccess, request : Types.FeeDepositRequest, caller : Principal) : async* Star.Star<Types.ManageSaleResponse, Types.OrigynError> {
  // Ensure the caller is authorized (account owner, canister, manager, collection owner)
  if (
    Types.account_eq(#principal(caller), request.account) == false and
    Types.account_eq(#principal(caller), #principal(state.canister())) == false and
    Types.account_eq(#principal(caller), #principal(state.state.collection_data.owner)) == false and
    Array.filter<Principal>(state.state.collection_data.managers, func(item : Principal) { item == caller }).size() == 0
  ) {
    return #err(#trappable(Types.errors(?state.canistergeekLogger, #unauthorized_access, "deposit_fee_nft_origyn - escrow - account and caller do not match", ?caller)));
  };

  debug if (debug_channel.escrow) D.print("in deposit_fee");

  debug if (debug_channel.escrow) D.print(debug_show (request));

  debug if (debug_channel.escrow) D.print(debug_show (state.canister()));

  debug if (debug_channel.escrow) D.print("verifying the deposit");

  // Get the fee deposit account
  let feeDepositAccount = switch (request.token) {
    case (#ic(token)) {
      switch (token.standard) {
        case (#Ledger or #ICRC1) {
          debug if (debug_channel.escrow) D.print("found ledger");
          NFTUtils.get_fee_deposit_account_info(request.account, state.canister());
        };
        case (_) return #err(#awaited(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - ic type nyi - " # debug_show (request), ?caller)));
      };
    };
    case (#extensible(val)) return #err(#trappable(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - extensible token nyi - " # debug_show (request), ?caller)));
  };

  // // Retrieve metadata
  // let metadata = switch (Metadata.get_metadata_for_token(state, request.token_id, caller, ?state.canister(), state.state.collection_data.owner)) {
  //   case (#ok(val)) val;
  //   case (#err(err)) D.trap("Cannot find metadata for collection " # debug_show (err));
  // };

  // Retrieve metadata only if token_id is provided
  switch (request.token_id) {
    case (?id) {
      switch (Metadata.get_metadata_for_token(state, id, caller, ?state.canister(), state.state.collection_data.owner)) {
        case (#ok(metadata)) {
          // Check current balance
          let balance : Nat = switch (request.token) {
            case (#ic(token)) {
              switch (token.standard) {
                case (#Ledger or #ICRC1) {
                  debug if (debug_channel.escrow) D.print("found ledger");
                  let checker = Ledger_Interface.Ledger_Interface();
                  switch (await* checker.fee_deposit_balance(state.canister(), request, caller)) {
                    case (#trappable(val)) (val.balance);
                    case (#awaited(val)) (val.balance);
                    case (#err(#awaited(err))) return #err(#awaited(Types.errors(?state.canistergeekLogger, err.error, "deposit_fee_nft_origyn " # err.flag_point, ?caller)));
                    case (#err(#trappable(err))) return #err(#awaited(Types.errors(?state.canistergeekLogger, err.error, "deposit_fee_nft_origyn " # err.flag_point, ?caller)));
                  };
                };
                case (_) return #err(#awaited(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - ic type nyi - " # debug_show (request), ?caller)));
              };
            };
            case (#extensible(val)) return #err(#trappable(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - extensible token nyi - " # debug_show (request), ?caller)));
          };

          // Calculate the required fee deposit amount
          let _royalties_names : [Text] = Royalties.royalties_names;
          let fee_deposit_amount : Nat = Royalties.get_total_amount_fixed_royalties(_royalties_names, metadata);

          debug if (debug_channel.escrow) D.print("deposit_fee_nft_origyn : feeDepositAccount " # debug_show (feeDepositAccount));

          debug if (debug_channel.escrow) D.print("Balance is insufficient, performing transfer to top-up fee deposit account.");
          let ogy_ledger : ICRC2.Self = actor (MigrationTypes.Current.OGY_LEDGER_CANISTER_ID);
          let add_fund_to_fees_wallet = await ogy_ledger.icrc2_transfer_from({
            to = {
              owner = feeDepositAccount.account.principal;
              subaccount = ?feeDepositAccount.account.sub_account;
            };
            fee = ?200_000;
            spender_subaccount = null;
            from = {
              owner = caller;
              subaccount = null;
            };
            memo = null;
            created_at_time = null;
            amount = fee_deposit_amount;
          });
        };
        case (#err(err)) D.trap("Cannot find metadata for collection " # debug_show (err));
      };
    };
    case null {
      // Token ID is not provided, skip metadata retrieval
      debug if (debug_channel.escrow) D.print("Token ID is null, skipping metadata retrieval.");

      let balance_doublecheck = switch (request.token) {
        case (#ic(token)) {
          switch (token.standard) {
            case (#Ledger or #ICRC1) {
              debug if (debug_channel.escrow) D.print("found ledger");
              let checker = Ledger_Interface.Ledger_Interface();
              switch (await* checker.fee_deposit_balance(state.canister(), request, caller)) {
                case (#trappable(val)) (val.balance);
                case (#awaited(val)) (val.balance);
                case (#err(#awaited(err))) return #err(#awaited(Types.errors(?state.canistergeekLogger, err.error, "deposit_fee_nft_origyn " # err.flag_point, ?caller)));
                case (#err(#trappable(err))) return #err(#awaited(Types.errors(?state.canistergeekLogger, err.error, "deposit_fee_nft_origyn " # err.flag_point, ?caller)));
              };
            };
            case (_) return #err(#awaited(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - ic type nyi - " # debug_show (request), ?caller)));
          };
        };
        case (#extensible(val)) return #err(#trappable(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - extensible token nyi - " # debug_show (request), ?caller)));
      };

      // put the fee into the state (there is a map here in which all such things are stored)
      debug if (debug_channel.escrow) D.print("putting the escrow");

      // Save in the state
      let deposit_result = PutBalance.put_fee_deposit_balance(state, request, balance_doublecheck);

      debug if (debug_channel.escrow) D.print(debug_show (deposit_result));

      // add fee deposit transaction
      let new_trx = switch (
        Metadata.add_transaction_record<system>(
          state,
          {
            token_id = "";
            index = 0;
            txn_type = #fee_deposit {
              request with
              amount = balance_doublecheck;
              extensible = #Option(null);
            };
            timestamp = state.get_time();
          },
          caller,
        )
      ) {
        case (#err(err)) {
          debug if (debug_channel.escrow) D.print("in a bad error");
          debug if (debug_channel.escrow) D.print(debug_show (err));
          //nyi: this is really bad and will mess up certificatioin later so we should really throw
          return #err(#awaited(Types.errors(?state.canistergeekLogger, #nyi, "deposit_fee_nft_origyn - extensible token nyi - " # debug_show (request), ?caller)));
        };
        case (#ok(new_trx)) new_trx;
      };

      return #awaited(#fee_deposit({ balance = balance_doublecheck; transaction = ?new_trx }));
    };
  };

  // // If balance is sufficient, skip the transfer
  // if (balance >= fee_deposit_amount) {
  //   debug if (debug_channel.escrow) D.print("Balance is sufficient, no transfer needed.");
  //   return #awaited(#fee_deposit({ balance = balance; transaction = null }));
  // };

};
