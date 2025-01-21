use origyn_nft_reference::origyn_nft_reference_canister::{ Account };
use candid::{ Nat, Principal };
use pocket_ic::PocketIc;

pub fn init_nft_with_premint_nft(
  pic: &mut PocketIc,
  origyn_nft: Principal,
  originator: Principal,
  net_principal: Principal,
  nft_owner: Principal,
  nft_name: String
) -> bool {
  let _standard_nft_return: crate::origyn_nft_suite::nft_utils::BuildStandardNftReturns = crate::origyn_nft_suite::nft_utils::build_standard_nft(
    pic,
    nft_name.clone(),
    origyn_nft.clone(),
    origyn_nft.clone(),
    originator.clone(),
    Nat::from(1024 as u32),
    false,
    net_principal.clone()
  );

  let mint_return: origyn_nft_reference::origyn_nft_reference_canister::OrigynTextResult = crate::client::origyn_nft_reference::client::mint_nft_origyn(
    pic,
    origyn_nft.clone(),
    Some(net_principal.clone()),
    (nft_name.clone(), Account { owner: nft_owner.clone(), subaccount: None })
  );

  println!("mint_return: {:?}", mint_return);

  match mint_return {
    origyn_nft_reference::origyn_nft_reference_canister::OrigynTextResult::Ok(_) => true,
    _ => false,
  }
}
