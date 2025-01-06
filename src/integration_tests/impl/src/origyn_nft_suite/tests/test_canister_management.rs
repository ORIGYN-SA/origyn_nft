use crate::client::origyn_nft_reference::client::test_canister_creation;
use crate::origyn_nft_suite::{init::init, TestEnv};
use crate::origyn_nft_suite::{CanisterIds, PrincipalIds};

#[test]
fn test_canister_deployment() {
    let mut env = init();
    let TestEnv {
        ref mut pic,
        canister_ids:
            CanisterIds {
                origyn_nft,
                ogy_ledger,
                ldg_ledger,
                notify,
            },
        principal_ids:
            PrincipalIds {
                net_principal,
                controller,
                originator,
                nft_owner,
            },
    } = env;

    pic.add_cycles(origyn_nft, 1_000_000_000_000_000);
    println!("Balance: {:?}", pic.cycle_balance(origyn_nft));

    let response = test_canister_creation(pic, origyn_nft.clone(), controller.clone(), ());

    println!("Result: {:?}", response);
}
