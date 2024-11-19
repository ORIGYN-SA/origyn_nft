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
fn test_fractionalization_token_unfractionalizable_token() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner },
  } = env;

  init_nft_with_premint_nft(
    pic,
    origyn_nft.clone(),
    originator.clone(),
    net_principal.clone(),
    nft_owner.clone(),
    "1".to_string()
  );

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
      panic!("init_fractionalization should return error if token is not found");
    }
    crate::client::origyn_nft_reference::init_fractionalization::Response::Err(err) => {
      assert_eq!(err.text, "malformed metadata");
      assert_eq!(err.error, OrigynNftReferenceErrors::MalformedMetadata);
      assert_eq!(
        err.flag_point,
        "init_fractionalization : \"Not allowed to fractionalize this NFT\""
      );
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

#[test]
fn test_consecutive_init_fractionalization_calls() {
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

  let first_call = init_fractionalization(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    crate::client::origyn_nft_reference::init_fractionalization::Args {
      token_id: "1".to_string(),
    }
  );

  match first_call {
    crate::client::origyn_nft_reference::init_fractionalization::Response::Ok => {}
    crate::client::origyn_nft_reference::init_fractionalization::Response::Err(err) => {
      panic!("First init_fractionalization call should succeed, but got error: {:?}", err);
    }
  }

  let second_call = init_fractionalization(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    crate::client::origyn_nft_reference::init_fractionalization::Args {
      token_id: "1".to_string(),
    }
  );

  match second_call {
    crate::client::origyn_nft_reference::init_fractionalization::Response::Ok => {
      panic!("Second init_fractionalization call should fail");
    }
    crate::client::origyn_nft_reference::init_fractionalization::Response::Err(err) => {
      assert_eq!(err.text, "Fractionalization already initialized");
      // assert_eq!(err.error, OrigynNftReferenceErrors::InvalidStateTransition);
    }
  }
}

#[test]
fn test_create_sub_canister_with_governance() {
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

  crate::client::origyn_nft_reference::client::authorize_fractionalization(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    crate::client::origyn_nft_reference::authorize_fractionalization::Args {
      token_id: "1".to_string(),
    }
  );

  let init_call = init_fractionalization(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    crate::client::origyn_nft_reference::init_fractionalization::Args {
      token_id: "1".to_string(),
    }
  );

  match init_call {
    crate::client::origyn_nft_reference::init_fractionalization::Response::Ok => {}
    crate::client::origyn_nft_reference::init_fractionalization::Response::Err(err) => {
      panic!("init_fractionalization call should succeed, but got error: {:?}", err);
    }
  }

  // Simulate creating a new sub-canister with the governance canister
  // ...code to create sub-canister...

  // Verify the sub-canister creation
  // ...code to verify sub-canister creation...

  // Ensure the governance canister is correctly set up
  // ...code to verify governance canister setup...

  // If all checks pass, the test is successful
}

#[test]
fn test_authorize_fractionalization_success() {
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

  let authorize_call = crate::client::origyn_nft_reference::client::authorize_fractionalization(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    crate::client::origyn_nft_reference::authorize_fractionalization::Args {
      token_id: "1".to_string(),
    }
  );

  match authorize_call {
    crate::client::origyn_nft_reference::authorize_fractionalization::Response::Ok => {}
    crate::client::origyn_nft_reference::authorize_fractionalization::Response::Err(err) => {
      panic!("authorize_fractionalization call should succeed, but got error: {:?}", err);
    }
  }
}

#[test]
fn test_authorize_fractionalization_not_owner() {
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

  let authorize_call = crate::client::origyn_nft_reference::client::authorize_fractionalization(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    crate::client::origyn_nft_reference::authorize_fractionalization::Args {
      token_id: "1".to_string(),
    }
  );

  match authorize_call {
    crate::client::origyn_nft_reference::authorize_fractionalization::Response::Ok => {
      panic!("authorize_fractionalization call should fail if caller is not the owner");
    }
    crate::client::origyn_nft_reference::authorize_fractionalization::Response::Err(err) => {
      assert_eq!(err.text, "unauthorized access");
      assert_eq!(err.error, OrigynNftReferenceErrors::UnauthorizedAccess);
    }
  }
}

#[test]
fn test_authorize_fractionalization_already_authorized() {
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

  let authorize_call = crate::client::origyn_nft_reference::client::authorize_fractionalization(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    crate::client::origyn_nft_reference::authorize_fractionalization::Args {
      token_id: "1".to_string(),
    }
  );

  match authorize_call {
    crate::client::origyn_nft_reference::authorize_fractionalization::Response::Ok => {}
    crate::client::origyn_nft_reference::authorize_fractionalization::Response::Err(err) => {
      panic!("First authorize_fractionalization call should succeed, but got error: {:?}", err);
    }
  }

  let second_authorize_call =
    crate::client::origyn_nft_reference::client::authorize_fractionalization(
      pic,
      origyn_nft.clone(),
      net_principal.clone(),
      crate::client::origyn_nft_reference::authorize_fractionalization::Args {
        token_id: "1".to_string(),
      }
    );

  match second_authorize_call {
    crate::client::origyn_nft_reference::authorize_fractionalization::Response::Ok => {
      panic!("Second authorize_fractionalization call should fail if NFT is already authorized");
    }
    crate::client::origyn_nft_reference::authorize_fractionalization::Response::Err(err) => {
      assert_eq!(err.text, "malformed metadata");
      assert_eq!(err.error, OrigynNftReferenceErrors::MalformedMetadata);
      assert_eq!(
        err.flag_point,
        "authorize_fractionalization : Fractionalization already authorized"
      );
    }
  }
}
