use crate::client::icrc1_icrc2_token;
use crate::client::origyn_nft_reference::client::{test_canister_creation, test_canister_top_up};
use crate::origyn_nft_suite::{init::init, CanisterIds, PrincipalIds, TestEnv};
use crate::utils::tick_n_blocks;
use crate::wasms;
use candid::{Encode, Nat};
use icrc_ledger_types::icrc1::account::Account;
use origyn_nft_reference::canister_manager::{CanisterManagementResult, DeployArgs};
use utils::consts::E8S_FEE_OGY;

#[test]
fn test_canister_deployment_no_wasm() {
    let mut env = init();
    let TestEnv {
        ref mut pic,
        canister_ids: CanisterIds { origyn_nft, .. },
        principal_ids: PrincipalIds { controller, .. },
    } = env;

    let deploy_args = DeployArgs {
        name: "Test Canister".to_string(),
        description: "A canister created for testing purposes.".to_string(),
        settings: None, // install, reinstall, which freezing threshold
        deploy_arguments: None,
        wasm: None,
        cycle_amount: Nat::from(1_000_000_000_000_u64),
        preserve_wasm: false,
    };

    // Add cycles in order to be able to create a canister manager with higher deploy parameters
    pic.add_cycles(origyn_nft, 1_000_000_000_000_000);
    pic.advance_time(std::time::Duration::from_secs(120));
    tick_n_blocks(pic, 100);

    let response = test_canister_top_up(pic, origyn_nft.clone(), controller.clone(), deploy_args);
    println!("response: {:?}", response);

    pic.advance_time(std::time::Duration::from_secs(120));
    tick_n_blocks(pic, 100);
    match response {
        CanisterManagementResult::Ok(ogy_ledger) => {
            println!("Successfully retrieved principal: {:?}", ogy_ledger);
            pic.add_cycles(ogy_ledger, 1_000_000_000_000_000);
        }
        CanisterManagementResult::Err(error) => {
            panic!("Error: {:?}", error)
        }
    }

    match response {
        crate::client::origyn_nft_reference::test_canister_creation::CanisterManagementResponse::Ok(ok) => {
            // 1999992924286171
            println!("Result: {:?}", pic.cycle_balance(ok));
        }
        crate::client::origyn_nft_reference::test_canister_creation::CanisterManagementResponse::Err(err) => (),
    }
}

#[test]
fn test_canister_deployment_without_deployment_args() {
    let mut env = init();
    let TestEnv {
        ref mut pic,
        canister_ids: CanisterIds { origyn_nft, .. },
        principal_ids: PrincipalIds { controller, .. },
    } = env;

    let wasm_module: Vec<u8> = wasms::BUYBACK_BURN_NO_ARGS.clone();

    let deploy_args = DeployArgs {
        name: "Test Canister".to_string(),
        description: "A canister created for testing purposes.".to_string(),
        settings: None, // install, reinstall, which freezing threshold
        deploy_arguments: None,
        wasm: Some(wasm_module),
        cycle_amount: Nat::from(1_000_000_000_000_u64),
        preserve_wasm: false,
    };
    pic.add_cycles(origyn_nft, 1_000_000_000_000_000);
    pic.advance_time(std::time::Duration::from_secs(120));
    tick_n_blocks(pic, 100);

    let response = test_canister_top_up(pic, origyn_nft.clone(), controller.clone(), deploy_args);
    println!("response: {:?}", response);

    pic.advance_time(std::time::Duration::from_secs(120));
    tick_n_blocks(pic, 100);
    match response {
        CanisterManagementResult::Ok(ogy_ledger) => {
            println!("Successfully retrieved principal: {:?}", ogy_ledger);
            pic.add_cycles(ogy_ledger, 1_000_000_000_000_000);
        }
        CanisterManagementResult::Err(error) => {
            panic!("Error: {:?}", error)
        }
    }

    match response {
        crate::client::origyn_nft_reference::test_canister_top_up::CanisterManagementResponse::Ok(ok) => {
            // 1999992924286171
            println!("Result: {:?}", pic.cycle_balance(ok));
        }
        crate::client::origyn_nft_reference::test_canister_top_up::CanisterManagementResponse::Err(err) => (),
    }
}

#[test]
fn test_canister_deployment_with_deployment_args() {
    let mut env = init();
    let TestEnv {
        ref mut pic,
        canister_ids: CanisterIds { origyn_nft, .. },
        principal_ids: PrincipalIds { controller, .. },
    } = env;

    let wasm_module: Vec<u8> = wasms::OGY_LEDGER.clone();

    let init_args: icrc_ledger_canister::init::LedgerArgument =
        icrc_ledger_canister::init::LedgerArgument::Init(icrc_ledger_canister::init::InitArgs {
            minting_account: Account::from(controller),
            initial_balances: vec![(
                Account::from(controller),
                Nat::from(18_446_744_073_709 as u64),
            )],
            archive_options: icrc_ledger_canister::init::ArchiveOptions {
                trigger_threshold: 2000,
                num_blocks_to_archive: 1000,
                controller_id: controller,
            },
            metadata: vec![],
            transfer_fee: Nat::from(E8S_FEE_OGY),
            token_symbol: "OGY".into(),
            token_name: "Origyn".into(),
        });

    let deploy_args = DeployArgs {
        name: "Test Canister".to_string(),
        description: "A canister created for testing purposes.".to_string(),
        settings: None, // install, reinstall, which freezing threshold
        deploy_arguments: Some(Encode!(&init_args).unwrap()),
        wasm: Some(wasm_module),
        cycle_amount: Nat::from(1_000_000_000_000_u64),
        preserve_wasm: false,
    };
    pic.add_cycles(origyn_nft, 1_000_000_000_000_000);
    pic.advance_time(std::time::Duration::from_secs(120));
    tick_n_blocks(pic, 100);

    let response = test_canister_top_up(pic, origyn_nft.clone(), controller.clone(), deploy_args);
    println!("response: {:?}", response);

    pic.advance_time(std::time::Duration::from_secs(120));
    tick_n_blocks(pic, 100);
    match response {
        CanisterManagementResult::Ok(ogy_ledger) => {
            println!("Successfully retrieved principal: {:?}", ogy_ledger);
            pic.add_cycles(ogy_ledger, 1_000_000_000_000_000);
            let balance =
                icrc1_icrc2_token::client::balance_of(pic, ogy_ledger.clone(), controller.clone());
            println!("Initial balance: {:?}", balance)
        }
        CanisterManagementResult::Err(error) => {
            panic!("Error: {:?}", error)
        }
    }

    println!("Result: {:?}", response);
}

// NOTE: we expect panic, because the size of wasm is more the 2MiB
#[test]
#[should_panic(expected = "BadIngressMessage(\"Request")]
fn test_canister_deployment_big_payload() {
    let mut env = init();
    let TestEnv {
        ref mut pic,
        canister_ids: CanisterIds { origyn_nft, .. },
        principal_ids: PrincipalIds { controller, .. },
    } = env;

    let wasm_module: Vec<u8> = wasms::BIG_WASM.clone();

    let deploy_args = DeployArgs {
        name: "Test Canister".to_string(),
        description: "A canister created for testing purposes.".to_string(),
        settings: None,
        deploy_arguments: None,
        wasm: Some(wasm_module),
        cycle_amount: Nat::from(1_000_000_000_000_u64),
        preserve_wasm: false,
    };

    let _response = test_canister_top_up(pic, origyn_nft.clone(), controller.clone(), deploy_args);
}

#[test]
fn test_canister_deployment_and_delete() {
    let mut env = init();
    let TestEnv {
        ref mut pic,
        canister_ids: CanisterIds { origyn_nft, .. },
        principal_ids: PrincipalIds { controller, .. },
    } = env;

    let wasm_module: Vec<u8> = wasms::BIG_WASM.clone();

    let deploy_args = DeployArgs {
        name: "Test Canister".to_string(),
        description: "A canister created for testing purposes.".to_string(),
        settings: None,
        deploy_arguments: None,
        wasm: Some(wasm_module),
        cycle_amount: Nat::from(1_000_000_000_000_u64),
        preserve_wasm: false,
    };

    // let _response =
    // test_canister_deploy_and_delete(pic, origyn_nft.clone(), controller.clone(), deploy_args);
}

#[test]
fn test_canister_deployment_and_cycles_management() {
    let mut env = init();
    let TestEnv {
        ref mut pic,
        canister_ids: CanisterIds { origyn_nft, .. },
        principal_ids: PrincipalIds { controller, .. },
    } = env;

    let wasm_module: Vec<u8> = wasms::CYCLES_BURNER.clone();

    let deploy_args = DeployArgs {
        name: "Test Canister".to_string(),
        description: "A canister created for testing purposes.".to_string(),
        settings: None,
        deploy_arguments: None,
        wasm: Some(wasm_module),
        cycle_amount: Nat::from(1_000_000_000_000_u64),
        preserve_wasm: false,
    };

    let _response = test_canister_top_up(pic, origyn_nft.clone(), controller.clone(), deploy_args);
}

// use candid::{encode_one, Principal};
// use icrc_ledger_canister::init::{ArchiveOptions as ArchiveOptionsIcrc, InitArgs, LedgerArgument};
// use icrc_ledger_types::icrc1::account::Account;

// pub fn generate_ledger_canister_init_args(
//     token: &str,
//     controller: Principal,
//     initial_ledger_accounts: Vec<(Account, Nat)>,
//     fee: &Nat,
// ) -> LedgerArgument {
//     let initial_ledger_accounts = initial_ledger_accounts
//         .iter()
//         .cloned()
//         .chain(
//             vec![(
//                 Account::from(controller),
//                 Nat::from(1_000_000_000_000_000u64),
//             )]
//             .iter()
//             .cloned(),
//         )
//         .collect();
//     LedgerArgument::Init(InitArgs {
//         minting_account: Account::from(controller),
//         initial_balances: initial_ledger_accounts,
//         transfer_fee: fee.clone(),
//         token_name: token.into(),
//         token_symbol: token.into(),
//         // fee_collector_account: None,
//         metadata: Vec::new(),
//         archive_options: ArchiveOptionsIcrc {
//             trigger_threshold: 1000,
//             num_blocks_to_archive: 1000,
//             controller_id: controller,
//         },
//     })
// }
