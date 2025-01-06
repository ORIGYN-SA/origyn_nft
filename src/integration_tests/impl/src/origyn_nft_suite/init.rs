use candid::{Nat, Principal};
use icrc_ledger_types::icrc1::account::Account;
use origyn_nft_reference::origyn_nft_reference_canister::ManageStorageRequestConfigureStorage;
use pocket_ic::{PocketIc, PocketIcBuilder};
use std::{env, path::Path};
use types::CanisterId;
use utils::consts::E8S_FEE_OGY;

use crate::{
    client::pocket::{create_canister, create_canister_with_id, install_canister},
    origyn_nft_suite::nft_utils::build_standard_nft,
    utils::random_principal,
    wasms,
};

use super::{CanisterIds, PrincipalIds, TestEnv};

pub static POCKET_IC_BIN: &str = "/usr/local/bin/pocket-ic";

pub fn init() -> TestEnv {
    validate_pocketic_installation();
    println!("install validate");

    // let mut pic: PocketIc = PocketIc::new();
    let mut pic = PocketIcBuilder::new()
        .with_application_subnet()
        .with_application_subnet()
        .with_sns_subnet()
        .build();

    let get_app_subnets = pic.topology().get_app_subnets()[1];

    println!("topology {:?}", pic.topology());
    println!("get_app_subnets {:?}", get_app_subnets.to_string());
    println!("pic set");

    // let mut pic: PocketIc = PocketIc::new();
    // println!("pic set");

    let principal_ids: PrincipalIds = PrincipalIds {
        net_principal: random_principal(),
        controller: random_principal(),
        originator: random_principal(),
        nft_owner: random_principal(),
    };
    let canister_ids: CanisterIds =
        install_canisters(&mut pic, principal_ids.controller, principal_ids.nft_owner);
    println!("origyn_nft: {:?}", canister_ids.origyn_nft.to_string());
    println!("ogy_ledger: {:?}", canister_ids.ogy_ledger.to_string());
    println!("ldg_ledger: {:?}", canister_ids.ldg_ledger.to_string());

    init_origyn_nft(
        &mut pic,
        canister_ids.origyn_nft,
        principal_ids.controller,
        principal_ids.originator,
        principal_ids.net_principal,
        canister_ids.ogy_ledger,
    );
    TestEnv {
        pic: pic,
        canister_ids,
        principal_ids,
    }
}

fn init_origyn_nft(
    pic: &mut PocketIc,
    canister: CanisterId,
    controller: Principal,
    originator: Principal,
    net_principal: Principal,
    ogy_principal: Principal,
) {
    let manage_storage_return: origyn_nft_reference::origyn_nft_reference_canister::ManageStorageResult = crate::client::origyn_nft_reference::client::manage_storage_nft_origyn(
    pic,
    canister,
    Some(controller),
    crate::client::origyn_nft_reference::manage_storage_nft_origyn::Args::ConfigureStorage(
      ManageStorageRequestConfigureStorage::Heap(Some(Nat::from(500000000 as u32)))
    )
  );

    println!("manage_storage_return: {:?}", manage_storage_return);

    let collection_update_return: origyn_nft_reference::origyn_nft_reference_canister::OrigynBoolResult = crate::client::origyn_nft_reference::client::collection_update_nft_origyn(
    pic,
    canister,
    Some(controller),
    crate::client::origyn_nft_reference::collection_update_nft_origyn::Args::UpdateOwner(
      net_principal
    )
  );
    println!("collection_update_return: {:?}", collection_update_return);

    let standard_collection_return = crate::origyn_nft_suite::nft_utils::build_standard_collection(
        pic,
        canister.clone(),
        canister.clone(),
        originator.clone(),
        Nat::from(1024 as u32),
        net_principal.clone(),
        crate::origyn_nft_suite::nft_utils::ICTokenSpec {
            canister: ogy_principal,
            fee: Some(Nat::from(E8S_FEE_OGY)),
            symbol: "OGY".to_string(),
            decimals: Nat::from(8 as u32),
            standard: crate::origyn_nft_suite::nft_utils::TokenStandard::Ledger,
            id: None,
        },
    );
    println!(
        "standard_collection_return: {:?}",
        standard_collection_return
    );
}

fn install_canisters(
    pic: &mut PocketIc,
    controller: Principal,
    nft_owner: Principal,
) -> CanisterIds {
    let origyn_nft_canister_id: Principal = create_canister(pic, controller);
    let ogy_ledger_canister_id: Principal =
        create_canister_with_id(pic, controller, "j5naj-nqaaa-aaaal-ajc7q-cai");
    let ldg_ledger_canister_id: Principal = create_canister(pic, controller);
    let notify_canister_id: Principal = create_canister(pic, controller);

    let origyn_nft_canister_wasm: Vec<u8> = wasms::ORIGYN_NFT.clone();
    let ogy_ledger_canister_wasm: Vec<u8> = wasms::OGY_LEDGER.clone();
    let ldg_ledger_canister_wasm: Vec<u8> = wasms::LDG_LEDGER.clone();
    let notify_canister_wasm: Vec<u8> = wasms::NOTIFY_WASM.clone();

    install_canister(
        pic,
        controller,
        origyn_nft_canister_id,
        origyn_nft_canister_wasm,
        {},
    );

    let ogy_ledger_init_args: icrc_ledger_canister::init::LedgerArgument =
        icrc_ledger_canister::init::LedgerArgument::Init(icrc_ledger_canister::init::InitArgs {
            minting_account: Account::from(controller),
            initial_balances: vec![
                (
                    Account::from(controller),
                    Nat::from(18_446_744_073_709 as u64),
                ),
                (
                    Account::from(origyn_nft_canister_id),
                    Nat::from(18_446_744_073_709 as u64),
                ),
                (
                    Account::from(nft_owner),
                    Nat::from(18_446_744_073_709 as u64),
                ),
            ],
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

    println!("ogy_ledger_canister_id {:?}", ogy_ledger_canister_id);

    install_canister(
        pic,
        controller,
        ogy_ledger_canister_id,
        ogy_ledger_canister_wasm,
        ogy_ledger_init_args,
    );

    let ldg_ledger_init_args: icrc_ledger_canister::init::LedgerArgument =
        icrc_ledger_canister::init::LedgerArgument::Init(icrc_ledger_canister::init::InitArgs {
            minting_account: Account::from(controller),
            initial_balances: vec![
                (
                    Account::from(controller),
                    Nat::from(18_446_744_073_709 as u64),
                ),
                (
                    Account::from(origyn_nft_canister_id),
                    Nat::from(18_446_744_073_709 as u64),
                ),
            ],
            archive_options: icrc_ledger_canister::init::ArchiveOptions {
                trigger_threshold: 2000,
                num_blocks_to_archive: 1000,
                controller_id: controller,
            },
            metadata: vec![],
            transfer_fee: Nat::from(E8S_FEE_OGY),
            token_symbol: "LDG".to_string(),
            token_name: "LeDGer".to_string(),
        });

    install_canister(
        pic,
        controller,
        ldg_ledger_canister_id,
        ldg_ledger_canister_wasm,
        ldg_ledger_init_args,
    );

    install_canister(pic, controller, notify_canister_id, notify_canister_wasm, {
    });

    CanisterIds {
        origyn_nft: origyn_nft_canister_id,
        ogy_ledger: ogy_ledger_canister_id,
        ldg_ledger: ldg_ledger_canister_id,
        notify: notify_canister_id,
    }
}

pub fn validate_pocketic_installation() {
    let path = POCKET_IC_BIN;

    if !Path::new(&path).exists() {
        println!(
      "
        Could not find the PocketIC binary to run canister integration tests.

        I looked for it at {:?}. You can specify another path with the environment variable POCKET_IC_BIN (note that I run from {:?}).
        ",
      &path,
      &env
        ::current_dir()
        .map(|x| x.display().to_string())
        .unwrap_or_else(|_| "an unknown directory".to_string())
    );
    }
}
