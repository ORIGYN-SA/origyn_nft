use crate::{ generate_query_call, generate_update_call };
use candid::{ CandidType, Nat };
use icrc_ledger_canister::*;
use icrc_ledger_types::icrc2::approve::{ ApproveArgs, ApproveError };
use icrc_ledger_types::icrc2::allowance::{ Allowance, AllowanceArgs };
use icrc_ledger_types::icrc2::transfer_from::{ TransferFromArgs, TransferFromError };
use icrc_ledger_types::icrc1::account::{ Account, Subaccount };
use icrc_ledger_types::icrc1::transfer::{ TransferArg, TransferError };
use ic_ledger_types::BlockIndex;
use serde::Deserialize;

generate_query_call!(icrc1_balance_of);
generate_query_call!(icrc1_total_supply);
generate_query_call!(icrc2_allowance);
// Updates
generate_update_call!(icrc1_transfer);
generate_update_call!(icrc2_transfer_from);
generate_update_call!(icrc2_approve);

pub mod icrc1_balance_of {
  use super::*;

  pub type Args = Account;
  pub type Response = Nat;
}

pub mod icrc1_total_supply {
  use super::*;

  pub type Args = ();
  pub type Response = Nat;
}

pub mod icrc1_transfer {
  use super::*;

  pub type Args = TransferArg;
  #[derive(CandidType, Deserialize, Debug)]
  pub enum Response {
    Ok(Nat),
    Err(TransferError),
  }
}

pub mod icrc2_transfer_from {
  use super::*;
  pub type Args = TransferFromArgs;
  #[derive(CandidType, Deserialize)]
  pub enum Response {
    Ok(Nat),
    Err(TransferFromError),
  }
}

pub mod icrc2_approve {
  use super::*;

  pub type Args = ApproveArgs;
  #[derive(CandidType, Deserialize)]
  pub enum Response {
    Ok(Nat),
    Err(ApproveError),
  }
}

pub mod icrc2_allowance {
  use super::*;

  pub type Args = AllowanceArgs;
  pub type Response = Allowance;
}

pub mod client {
  use super::*;
  use candid::Principal;
  use icrc_ledger_types::icrc1::{ account::Account, account::Subaccount, transfer::NumTokens };
  use pocket_ic::PocketIc;
  use types::CanisterId;

  pub fn transfer(
    pic: &mut PocketIc,
    sender: Principal,
    ledger_canister_id: CanisterId,
    from: Option<Subaccount>,
    recipient: impl Into<Account>,
    amount: NumTokens
  ) -> icrc1_transfer::Response {
    icrc1_transfer(
      pic,
      sender,
      ledger_canister_id,
      &(icrc1_transfer::Args {
        from_subaccount: from,
        to: recipient.into(),
        fee: None,
        created_at_time: None,
        memo: None,
        amount: amount.into(),
      })
    )
  }

  pub fn balance_of(
    pic: &PocketIc,
    ledger_canister_id: CanisterId,
    account: impl Into<Account>
  ) -> icrc1_balance_of::Response {
    icrc1_balance_of(pic, Principal::anonymous(), ledger_canister_id, &account.into())
  }

  pub fn total_supply(
    pic: &PocketIc,
    ledger_canister_id: CanisterId
  ) -> icrc1_total_supply::Response {
    icrc1_total_supply(pic, Principal::anonymous(), ledger_canister_id, &())
  }

  pub fn transfer_from(
    pic: &mut PocketIc,
    sender: Principal,
    ledger_canister_id: CanisterId,
    spender: Principal,
    from: impl Into<Account>,
    recipient: impl Into<Account>,
    amount: NumTokens
  ) -> icrc2_transfer_from::Response {
    icrc2_transfer_from(
      pic,
      sender,
      ledger_canister_id,
      &(icrc2_transfer_from::Args {
        from: from.into(),
        to: recipient.into(),
        fee: None,
        created_at_time: None,
        memo: None,
        amount: amount.into(),
        spender_subaccount: None,
      })
    )
  }

  pub fn allowance(
    pic: &PocketIc,
    ledger_canister_id: CanisterId,
    owner: impl Into<Account>,
    spender: Principal
  ) -> Allowance {
    icrc2_allowance(
      pic,
      Principal::anonymous(),
      ledger_canister_id,
      &(icrc2_allowance::Args {
        account: owner.into(),
        spender: spender.into(),
      })
    )
  }

  pub fn approve(
    pic: &mut PocketIc,
    sender: Principal,
    ledger_canister_id: CanisterId,
    spender: Principal,
    from: Option<Subaccount>,
    amount: NumTokens
  ) -> icrc2_approve::Response {
    icrc2_approve(
      pic,
      sender,
      ledger_canister_id,
      &(icrc2_approve::Args {
        fee: None,
        memo: None,
        from_subaccount: from,
        created_at_time: None,
        amount: amount.into(),
        expected_allowance: None,
        expires_at: None,
        spender: spender.into(),
      })
    )
  }
}
