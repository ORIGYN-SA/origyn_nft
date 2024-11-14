use crate::origyn_nft_suite::{ CanisterIds, PrincipalIds };
use crate::origyn_nft_suite::{ init::init, TestEnv };
use candid::Nat;
use crate::origyn_nft_suite::tests::utils::init_nft_with_premint_nft;
use crate::client::origyn_nft_reference::client::{
  init_fractionalization,
  market_transfer_nft_origyn as market_transfer_nft_origyn_client,
};
use origyn_nft_reference::origyn_nft_reference_canister::{
  Errors as OrigynNftReferenceErrors,
  SalesConfig,
  PricingConfigShared,
  AskFeature,
};
use crate::client::origyn_nft_reference::market_transfer_nft_origyn::Args as market_transfer_nft_origynArgs;

#[test]
fn test_fractionalization_error() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner },
  } = env;

  // loop to create multiple nft
  init_nft_with_premint_nft(
    pic,
    origyn_nft.clone(),
    originator.clone(),
    net_principal.clone(),
    nft_owner.clone(),
    "1".to_string()
  );

  let error_1 = init_fractionalization(
    pic,
    origyn_nft.clone(),
    ogy_ledger.clone(),
    crate::client::origyn_nft_reference::init_fractionalization::Args {
      token_id: "1".to_string(),
    }
  );

  match error_1 {
    crate::client::origyn_nft_reference::init_fractionalization::Response::Ok => {
      panic!("init_fractionalization should return error if caller is not the owner");
    }
    crate::client::origyn_nft_reference::init_fractionalization::Response::Err(err) => {
      assert_eq!(err.text, "unauthorized access");
      assert_eq!(err.error, OrigynNftReferenceErrors::UnauthorizedAccess);
      assert_eq!(err.number, 2000);
      assert_eq!(err.flag_point, "init_fractionalization : Caller is not the owner of the NFT");
    }
  }
}

#[test]
fn test_fractionalization_token_not_found() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner },
  } = env;

  let error = init_fractionalization(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    crate::client::origyn_nft_reference::init_fractionalization::Args {
      token_id: "non_existent_token".to_string(),
    }
  );

  match error {
    crate::client::origyn_nft_reference::init_fractionalization::Response::Ok => {
      panic!("init_fractionalization should return error if token is not found");
    }
    crate::client::origyn_nft_reference::init_fractionalization::Response::Err(err) => {
      assert_eq!(err.text, "Cannot find token.");
      assert_eq!(err.error, OrigynNftReferenceErrors::TokenNotFound);
    }
  }
}

#[test]
fn test_fractionalization_nft_on_sale() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner },
  } = env;

  // loop to create multiple nft
  init_nft_with_premint_nft(
    pic,
    origyn_nft.clone(),
    originator.clone(),
    net_principal.clone(),
    nft_owner.clone(),
    "1".to_string()
  );

  let ret: origyn_nft_reference::origyn_nft_reference_canister::MarketTransferResult = market_transfer_nft_origyn_client(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    market_transfer_nft_origynArgs {
      token_id: '1'.to_string(),
      sales_config: SalesConfig {
        broker_id: None,
        pricing: PricingConfigShared::Ask(
          Some(vec![AskFeature::StartPrice(Nat::from(100 as u32))])
        ),
        escrow_receipt: None,
      },
    }
  );

  let sale_id: String = match ret {
    origyn_nft_reference::origyn_nft_reference_canister::MarketTransferResult::Ok(val) => {
      match val.txn_type {
        origyn_nft_reference::origyn_nft_reference_canister::MarketTransferRequestReponseTxnType::SaleOpened {
          pricing,
          extensible,
          sale_id,
        } => {
          sale_id
        }
        _ => {
          panic!("TransactionType::Sale not found");
        }
      }
    }
    origyn_nft_reference::origyn_nft_reference_canister::MarketTransferResult::Err(err) => {
      panic!("MarketTransferResult::Err: {:?}", err);
    }
  };

  let error = init_fractionalization(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    crate::client::origyn_nft_reference::init_fractionalization::Args {
      token_id: "1".to_string(),
    }
  );

  match error {
    crate::client::origyn_nft_reference::init_fractionalization::Response::Ok => {
      panic!("init_fractionalization should return error if NFT is on sale");
    }
    crate::client::origyn_nft_reference::init_fractionalization::Response::Err(err) => {
      assert_eq!(err.text, "A sale for this item is already underway.");
      assert_eq!(err.error, OrigynNftReferenceErrors::ExistingSaleFound);
    }
  }
}
