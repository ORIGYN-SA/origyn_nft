use crate::{
    generate_query_call, generate_query_call_encoded_args, generate_update_call,
    generate_update_call_encoded_args,
};
use origyn_nft_reference::origyn_nft_reference_canister::{
    Account, Account3, ApprovalArgs, ApprovalResult, CollectionMetadata, CollectionResult,
    HistoryResult, ManageCollectionCommand, ManageSaleRequest, ManageSaleResult,
    ManageStorageRequest, ManageStorageResult, MarketTransferRequest, MarketTransferResult,
    NftCanisterStageNftOrigynArg, NftInfoResult, NftUpdateAppResult, NftUpdateMetadataNode,
    OrigynBoolResult, OrigynTextResult, SaleInfoRequest, SaleInfoResult, StageChunkArg,
    StageLibraryResult, SupportedStandard, TransferArgs, TransferResult, Value,
};

// FIXME: delete this one after testing
generate_update_call!(test_canister_creation);

generate_update_call!(stage_nft_origyn);
generate_update_call!(stage_library_nft_origyn);
generate_update_call!(manage_storage_nft_origyn);
generate_update_call!(collection_update_nft_origyn);
generate_update_call_encoded_args!(mint_nft_origyn);
generate_update_call!(icrc7_approve);
generate_query_call!(icrc7_atomic_batch_transfers);
generate_query_call!(icrc7_balance_of);
generate_query_call!(icrc7_collection_metadata);
generate_query_call!(icrc7_default_take_value);
generate_query_call!(icrc7_description);
generate_query_call!(icrc7_logo);
generate_query_call!(icrc7_max_approvals_per_token_or_collection);
generate_query_call!(icrc7_max_memo_size);
generate_query_call!(icrc7_max_query_batch_size);
generate_query_call!(icrc7_max_revoke_approvals);
generate_query_call!(icrc7_max_take_value);
generate_query_call!(icrc7_max_update_batch_size);
generate_query_call!(icrc7_name);
generate_query_call!(icrc7_owner_of);
generate_query_call!(icrc7_permitted_drift);
generate_query_call!(icrc7_supply_cap);
generate_query_call!(icrc7_supported_standards);
generate_query_call!(icrc7_symbol);
generate_query_call!(icrc7_token_metadata);
generate_query_call!(icrc7_tokens);
generate_query_call!(icrc7_tokens_of);
generate_query_call!(icrc7_total_supply);
generate_update_call!(icrc7_transfer);
generate_query_call!(icrc7_transfer_fee);
generate_query_call!(icrc7_tx_window);
generate_query_call!(get_token_id_as_nat);
generate_query_call!(collection_nft_origyn);
generate_update_call!(market_transfer_nft_origyn_batch);
generate_update_call!(market_transfer_nft_origyn);
generate_query_call!(get_nat_as_token_id_origyn);
generate_query_call!(nft_origyn);
generate_query_call!(sale_info_nft_origyn);
generate_update_call!(update_metadata_node);
generate_query_call_encoded_args!(history_nft_origyn);
generate_update_call!(sale_nft_origyn);

pub mod test_canister_creation {
    use super::*;

    pub type Args = ();
    pub type Response = CanisterManagementResponse;

    use candid::CandidType;
    use candid::Nat;
    use candid::Principal;
    use serde::Deserialize;
    // Result.Result<Principal, CanisterManagementTypes.Error>
    #[derive(CandidType, Deserialize, Debug)]
    pub enum CanisterManagementResponse {
        #[serde(rename = "ok")]
        Ok(Principal),
        #[serde(rename = "err")]
        Err(CanisterManagementError),
    }

    #[derive(CandidType, Deserialize, Debug)]
    pub enum CanisterManagementError {
        Invalid_Caller,
        Nonexistent_Caller,
        Invalid_CanisterId,
        No_Wasm,
        No_Record,
        Insufficient_Cycles,
        Ledger_Transfer_Failed(Nat),
        Create_Canister_Failed(Nat),
        Delete_Hub_Failed,
    }
}

pub mod stage_nft_origyn {
    use super::*;

    pub type Args = NftCanisterStageNftOrigynArg;
    pub type Response = OrigynTextResult;
}

pub mod stage_library_nft_origyn {
    use super::*;

    pub type Args = StageChunkArg;
    pub type Response = StageLibraryResult;
}

pub mod manage_storage_nft_origyn {
    use super::*;

    pub type Args = ManageStorageRequest;
    pub type Response = ManageStorageResult;
}

pub mod collection_update_nft_origyn {
    use super::*;

    pub type Args = ManageCollectionCommand;
    pub type Response = OrigynBoolResult;
}

pub mod mint_nft_origyn {
    use super::*;

    pub type Args = (String, Account);
    pub type Response = OrigynTextResult;
}

pub mod icrc7_approve {
    use super::*;

    pub type Args = ApprovalArgs;
    pub type Response = ApprovalResult;
}

pub mod icrc7_atomic_batch_transfers {
    pub type Args = ();
    pub type Response = Option<bool>;
}

pub mod icrc7_balance_of {
    use super::*;

    pub type Args = Vec<Account3>;
    pub type Response = Vec<candid::Nat>;
}

pub mod icrc7_collection_metadata {
    use super::*;

    pub type Args = ();
    pub type Response = CollectionMetadata;
}

pub mod icrc7_default_take_value {
    pub type Args = ();
    pub type Response = Option<candid::Nat>;
}

pub mod icrc7_description {
    pub type Args = ();
    pub type Response = Option<String>;
}

pub mod icrc7_logo {
    pub type Args = ();
    pub type Response = Option<String>;
}

pub mod icrc7_max_approvals_per_token_or_collection {
    pub type Args = ();
    pub type Response = Option<candid::Nat>;
}

pub mod icrc7_max_memo_size {
    pub type Args = ();
    pub type Response = Option<candid::Nat>;
}

pub mod icrc7_max_query_batch_size {
    pub type Args = ();
    pub type Response = Option<candid::Nat>;
}

pub mod icrc7_max_revoke_approvals {
    pub type Args = ();
    pub type Response = Option<candid::Nat>;
}

pub mod icrc7_max_take_value {
    pub type Args = ();
    pub type Response = Option<candid::Nat>;
}

pub mod icrc7_max_update_batch_size {
    pub type Args = ();
    pub type Response = Option<candid::Nat>;
}

pub mod icrc7_name {
    pub type Args = ();
    pub type Response = String;
}

pub mod icrc7_owner_of {
    use super::*;

    pub type Args = Vec<candid::Nat>;
    pub type Response = Vec<Option<Account3>>;
}

pub mod icrc7_permitted_drift {
    pub type Args = ();
    pub type Response = Option<candid::Nat>;
}

pub mod icrc7_supply_cap {
    pub type Args = ();
    pub type Response = Option<candid::Nat>;
}

pub mod icrc7_supported_standards {
    use super::*;

    pub type Args = ();
    pub type Response = Vec<SupportedStandard>;
}

pub mod icrc7_symbol {
    pub type Args = ();
    pub type Response = String;
}

pub mod icrc7_token_metadata {
    use super::*;

    pub type Args = Vec<candid::Nat>;
    pub type Response = Vec<Option<Vec<(String, Value)>>>;
}

pub mod icrc7_tokens {
    pub type Args = (Option<candid::Nat>, Option<u32>);
    pub type Response = Vec<candid::Nat>;
}

pub mod icrc7_tokens_of {
    use super::*;

    pub type Args = (Account3, Option<candid::Nat>, Option<u32>);
    pub type Response = Vec<candid::Nat>;
}

pub mod icrc7_total_supply {
    pub type Args = ();
    pub type Response = candid::Nat;
}

pub mod icrc7_transfer {
    use super::*;

    pub type Args = Vec<TransferArgs>;
    pub type Response = TransferResult;
}

pub mod icrc7_transfer_fee {
    pub type Args = candid::Nat;
    pub type Response = Option<candid::Nat>;
}

pub mod icrc7_tx_window {
    pub type Args = ();
    pub type Response = Option<candid::Nat>;
}

pub mod get_token_id_as_nat {
    pub type Args = String;
    pub type Response = candid::Nat;
}

pub mod collection_nft_origyn {
    use super::*;

    pub type Args = Option<Vec<(String, Option<candid::Nat>, Option<candid::Nat>)>>;
    pub type Response = CollectionResult;
}

pub mod market_transfer_nft_origyn_batch {
    use super::*;

    pub type Args = Vec<MarketTransferRequest>;
    pub type Response = Vec<MarketTransferResult>;
}

pub mod market_transfer_nft_origyn {
    use super::*;

    pub type Args = MarketTransferRequest;
    pub type Response = MarketTransferResult;
}

pub mod get_nat_as_token_id_origyn {
    use super::*;

    pub type Args = candid::Nat;
    pub type Response = String;
}

pub mod nft_origyn {
    use super::*;

    pub type Args = String;
    pub type Response = NftInfoResult;
}

pub mod sale_info_nft_origyn {
    use super::*;

    pub type Args = SaleInfoRequest;
    pub type Response = SaleInfoResult;
}

pub mod update_metadata_node {
    use super::*;

    pub type Args = NftUpdateMetadataNode;
    pub type Response = NftUpdateAppResult;
}

pub mod history_nft_origyn {
    use super::*;

    pub type Args = (String, Option<candid::Nat>, Option<candid::Nat>);
    pub type Response = HistoryResult;
}

pub mod sale_nft_origyn {
    use super::*;

    pub type Args = ManageSaleRequest;
    pub type Response = ManageSaleResult;
}

pub mod client {
    use super::*;
    use candid::Principal;
    use icrc_ledger_types::icrc;
    use pocket_ic::PocketIc;
    use types::CanisterId;

    // FIXME: clean up after testing
    pub fn test_canister_creation(
        pic: &mut PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: test_canister_creation::Args,
    ) -> test_canister_creation::Response {
        crate::client::origyn_nft_reference::test_canister_creation(pic, sender, canister_id, &args)
    }

    pub fn stage_nft_origyn(
        pic: &mut PocketIc,
        canister_id: CanisterId,
        sender: Option<Principal>,
        args: stage_nft_origyn::Args,
    ) -> stage_nft_origyn::Response {
        match sender {
            Some(sender) => crate::client::origyn_nft_reference::stage_nft_origyn(
                pic,
                sender,
                canister_id,
                &args,
            ),
            None => crate::client::origyn_nft_reference::stage_nft_origyn(
                pic,
                Principal::anonymous(),
                canister_id,
                &args,
            ),
        }
    }

    pub fn stage_library_nft_origyn(
        pic: &mut PocketIc,
        canister_id: CanisterId,
        sender: Option<Principal>,
        args: stage_library_nft_origyn::Args,
    ) -> stage_library_nft_origyn::Response {
        match sender {
            Some(sender) => crate::client::origyn_nft_reference::stage_library_nft_origyn(
                pic,
                sender,
                canister_id,
                &args,
            ),
            None => crate::client::origyn_nft_reference::stage_library_nft_origyn(
                pic,
                Principal::anonymous(),
                canister_id,
                &args,
            ),
        }
    }

    pub fn manage_storage_nft_origyn(
        pic: &mut PocketIc,
        canister_id: CanisterId,
        sender: Option<Principal>,
        args: manage_storage_nft_origyn::Args,
    ) -> manage_storage_nft_origyn::Response {
        match sender {
            Some(sender) => crate::client::origyn_nft_reference::manage_storage_nft_origyn(
                pic,
                sender,
                canister_id,
                &args,
            ),
            None => crate::client::origyn_nft_reference::manage_storage_nft_origyn(
                pic,
                Principal::anonymous(),
                canister_id,
                &args,
            ),
        }
    }

    pub fn collection_update_nft_origyn(
        pic: &mut PocketIc,
        canister_id: CanisterId,
        sender: Option<Principal>,
        args: collection_update_nft_origyn::Args,
    ) -> collection_update_nft_origyn::Response {
        match sender {
            Some(sender) => crate::client::origyn_nft_reference::collection_update_nft_origyn(
                pic,
                sender,
                canister_id,
                &args,
            ),
            None => crate::client::origyn_nft_reference::collection_update_nft_origyn(
                pic,
                Principal::anonymous(),
                canister_id,
                &args,
            ),
        }
    }

    pub fn mint_nft_origyn(
        pic: &mut PocketIc,
        canister_id: CanisterId,
        sender: Option<Principal>,
        args: mint_nft_origyn::Args,
    ) -> mint_nft_origyn::Response {
        match sender {
            Some(sender) => crate::client::origyn_nft_reference::mint_nft_origyn(
                pic,
                sender,
                canister_id,
                candid::encode_args(args).unwrap(),
            ),
            None => crate::client::origyn_nft_reference::mint_nft_origyn(
                pic,
                Principal::anonymous(),
                canister_id,
                candid::encode_args(args).unwrap(),
            ),
        }
    }

    pub fn icrc7_approve(
        pic: &mut PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: icrc7_approve::Args,
    ) -> icrc7_approve::Response {
        crate::client::origyn_nft_reference::icrc7_approve(pic, sender, canister_id, &args)
    }

    pub fn icrc7_atomic_batch_transfers(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_atomic_batch_transfers::Response {
        crate::client::origyn_nft_reference::icrc7_atomic_batch_transfers(
            pic,
            sender,
            canister_id,
            &(),
        )
    }

    pub fn icrc7_balance_of(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: icrc7_balance_of::Args,
    ) -> icrc7_balance_of::Response {
        crate::client::origyn_nft_reference::icrc7_balance_of(pic, sender, canister_id, &args)
    }

    pub fn icrc7_collection_metadata(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_collection_metadata::Response {
        crate::client::origyn_nft_reference::icrc7_collection_metadata(
            pic,
            sender,
            canister_id,
            &(),
        )
    }

    pub fn icrc7_default_take_value(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_default_take_value::Response {
        crate::client::origyn_nft_reference::icrc7_default_take_value(pic, sender, canister_id, &())
    }

    pub fn icrc7_description(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_description::Response {
        crate::client::origyn_nft_reference::icrc7_description(pic, sender, canister_id, &())
    }

    pub fn icrc7_logo(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_logo::Response {
        crate::client::origyn_nft_reference::icrc7_logo(pic, sender, canister_id, &())
    }

    pub fn icrc7_max_approvals_per_token_or_collection(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_max_approvals_per_token_or_collection::Response {
        crate::client::origyn_nft_reference::icrc7_max_approvals_per_token_or_collection(
            pic,
            sender,
            canister_id,
            &(),
        )
    }

    pub fn icrc7_max_memo_size(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_max_memo_size::Response {
        crate::client::origyn_nft_reference::icrc7_max_memo_size(pic, sender, canister_id, &())
    }

    pub fn icrc7_max_query_batch_size(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_max_query_batch_size::Response {
        crate::client::origyn_nft_reference::icrc7_max_query_batch_size(
            pic,
            sender,
            canister_id,
            &(),
        )
    }

    pub fn icrc7_max_revoke_approvals(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_max_revoke_approvals::Response {
        crate::client::origyn_nft_reference::icrc7_max_revoke_approvals(
            pic,
            sender,
            canister_id,
            &(),
        )
    }

    pub fn icrc7_max_take_value(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_max_take_value::Response {
        crate::client::origyn_nft_reference::icrc7_max_take_value(pic, sender, canister_id, &())
    }

    pub fn icrc7_max_update_batch_size(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_max_update_batch_size::Response {
        crate::client::origyn_nft_reference::icrc7_max_update_batch_size(
            pic,
            sender,
            canister_id,
            &(),
        )
    }

    pub fn icrc7_name(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_name::Response {
        crate::client::origyn_nft_reference::icrc7_name(pic, sender, canister_id, &())
    }

    pub fn icrc7_owner_of(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: icrc7_owner_of::Args,
    ) -> icrc7_owner_of::Response {
        crate::client::origyn_nft_reference::icrc7_owner_of(pic, sender, canister_id, &args)
    }

    pub fn icrc7_permitted_drift(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_permitted_drift::Response {
        crate::client::origyn_nft_reference::icrc7_permitted_drift(pic, sender, canister_id, &())
    }

    pub fn icrc7_supply_cap(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_supply_cap::Response {
        crate::client::origyn_nft_reference::icrc7_supply_cap(pic, sender, canister_id, &())
    }

    pub fn icrc7_supported_standards(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_supported_standards::Response {
        crate::client::origyn_nft_reference::icrc7_supported_standards(
            pic,
            sender,
            canister_id,
            &(),
        )
    }

    pub fn icrc7_symbol(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_symbol::Response {
        crate::client::origyn_nft_reference::icrc7_symbol(pic, sender, canister_id, &())
    }

    pub fn icrc7_token_metadata(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: icrc7_token_metadata::Args,
    ) -> icrc7_token_metadata::Response {
        crate::client::origyn_nft_reference::icrc7_token_metadata(pic, sender, canister_id, &args)
    }

    pub fn icrc7_tokens(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: icrc7_tokens::Args,
    ) -> icrc7_tokens::Response {
        crate::client::origyn_nft_reference::icrc7_tokens(pic, sender, canister_id, &args)
    }

    pub fn icrc7_tokens_of(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: icrc7_tokens_of::Args,
    ) -> icrc7_tokens_of::Response {
        crate::client::origyn_nft_reference::icrc7_tokens_of(pic, sender, canister_id, &args)
    }

    pub fn icrc7_total_supply(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_total_supply::Response {
        crate::client::origyn_nft_reference::icrc7_total_supply(pic, sender, canister_id, &())
    }

    pub fn icrc7_transfer(
        pic: &mut PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: icrc7_transfer::Args,
    ) -> icrc7_transfer::Response {
        crate::client::origyn_nft_reference::icrc7_transfer(pic, sender, canister_id, &args)
    }

    pub fn icrc7_transfer_fee(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: icrc7_transfer_fee::Args,
    ) -> icrc7_transfer_fee::Response {
        crate::client::origyn_nft_reference::icrc7_transfer_fee(pic, sender, canister_id, &args)
    }

    pub fn icrc7_tx_window(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
    ) -> icrc7_tx_window::Response {
        crate::client::origyn_nft_reference::icrc7_tx_window(pic, sender, canister_id, &())
    }

    pub fn get_token_id_as_nat(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: get_token_id_as_nat::Args,
    ) -> get_token_id_as_nat::Response {
        crate::client::origyn_nft_reference::get_token_id_as_nat(pic, sender, canister_id, &args)
    }

    pub fn collection_nft_origyn(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: collection_nft_origyn::Args,
    ) -> collection_nft_origyn::Response {
        crate::client::origyn_nft_reference::collection_nft_origyn(pic, sender, canister_id, &args)
    }

    pub fn market_transfer_nft_origyn_batch(
        pic: &mut PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: market_transfer_nft_origyn_batch::Args,
    ) -> market_transfer_nft_origyn_batch::Response {
        crate::client::origyn_nft_reference::market_transfer_nft_origyn_batch(
            pic,
            sender,
            canister_id,
            &args,
        )
    }

    pub fn market_transfer_nft_origyn(
        pic: &mut PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: market_transfer_nft_origyn::Args,
    ) -> market_transfer_nft_origyn::Response {
        crate::client::origyn_nft_reference::market_transfer_nft_origyn(
            pic,
            sender,
            canister_id,
            &args,
        )
    }

    pub fn get_nat_as_token_id_origyn(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: get_nat_as_token_id_origyn::Args,
    ) -> get_nat_as_token_id_origyn::Response {
        crate::client::origyn_nft_reference::get_nat_as_token_id_origyn(
            pic,
            sender,
            canister_id,
            &args,
        )
    }

    pub fn nft_origyn(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: nft_origyn::Args,
    ) -> nft_origyn::Response {
        crate::client::origyn_nft_reference::nft_origyn(pic, sender, canister_id, &args)
    }

    pub fn sale_info_nft_origyn(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: sale_info_nft_origyn::Args,
    ) -> sale_info_nft_origyn::Response {
        crate::client::origyn_nft_reference::sale_info_nft_origyn(pic, sender, canister_id, &args)
    }

    pub fn update_metadata_node(
        pic: &mut PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: update_metadata_node::Args,
    ) -> update_metadata_node::Response {
        crate::client::origyn_nft_reference::update_metadata_node(pic, sender, canister_id, &args)
    }

    pub fn history_nft_origyn(
        pic: &PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: history_nft_origyn::Args,
    ) -> history_nft_origyn::Response {
        crate::client::origyn_nft_reference::history_nft_origyn(
            pic,
            sender,
            canister_id,
            candid::encode_args(args).unwrap(),
        )
    }

    pub fn sale_nft_origyn(
        pic: &mut PocketIc,
        canister_id: CanisterId,
        sender: Principal,
        args: sale_nft_origyn::Args,
    ) -> sale_nft_origyn::Response {
        crate::client::origyn_nft_reference::sale_nft_origyn(pic, sender, canister_id, &args)
    }
}
