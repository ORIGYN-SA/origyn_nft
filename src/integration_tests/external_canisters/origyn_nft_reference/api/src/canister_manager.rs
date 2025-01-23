use candid::{CandidType, Nat, Principal};
use serde::Deserialize;

// Time alias
pub type Time = u64; // Replace with the appropriate Time representation if different

pub type CanisterId = Principal;
pub type WasmModule = Vec<u8>;

#[derive(CandidType, Deserialize, Debug)]
pub enum CanisterManagementResult<T> {
    #[serde(rename = "ok")]
    Ok(T),
    #[serde(rename = "err")]
    Err(CanisterManagementError),
}

#[derive(CandidType, Deserialize, Debug)]
pub struct Canister {
    pub name: String,
    pub description: String,
    pub canister_id: Principal,
    pub wasm: Option<Vec<u8>>,
}

#[derive(CandidType, Deserialize, Debug)]
pub struct CanisterSettings {
    pub freezing_threshold: Option<Nat>,
    pub controllers: Option<Vec<Principal>>,
    pub memory_allocation: Option<Nat>,
    pub compute_allocation: Option<Nat>,
}

#[derive(CandidType, Deserialize, Debug)]
pub struct DefiniteCanisterSettings {
    pub controllers: Vec<Principal>,
    pub compute_allocation: Nat,
    pub memory_allocation: Nat,
    pub freezing_threshold: Nat,
}

#[derive(CandidType, Deserialize, Debug)]
pub enum CanisterState {
    #[serde(rename = "running")]
    Running,
    #[serde(rename = "stopping")]
    Stopping,
    #[serde(rename = "stopped")]
    Stopped,
}

#[derive(CandidType, Deserialize, Debug)]
pub struct CanisterStatus {
    pub status: CanisterState,
    pub settings: DefiniteCanisterSettings,
    pub module_hash: Option<Vec<u8>>,
    pub memory_size: Nat,
    pub cycles: Nat,
}

#[derive(CandidType, Deserialize, Debug)]
pub enum CanisterManagementError {
    #[serde(rename = "Invalid_Caller")]
    InvalidCaller,
    #[serde(rename = "Nonexistent_Caller")]
    NonexistentCaller,
    #[serde(rename = "Invalid_CanisterId")]
    InvalidCanisterId,
    #[serde(rename = "No_Wasm")]
    NoWasm,
    #[serde(rename = "No_Record")]
    NoRecord,
    #[serde(rename = "Insufficient_Cycles")]
    InsufficientCycles,
    #[serde(rename = "Ledger_Transfer_Failed")]
    LedgerTransferFailed(Nat),
    #[serde(rename = "Create_Canister_Failed")]
    CreateCanisterFailed(Nat),
    #[serde(rename = "Delete_Hub_Failed")]
    DeleteHubFailed,
}

#[derive(CandidType, Deserialize, Debug)]
pub struct Record {
    pub caller: Principal,
    pub canister_id: Principal,
    pub method: Method,
    pub amount: Nat,
    pub times: u64, // Assuming Time is represented as u64
}

#[derive(CandidType, Deserialize, Debug)]
pub enum Method {
    #[serde(rename = "deploy")]
    Deploy,
    #[serde(rename = "deposit")]
    Deposit,
    #[serde(rename = "start")]
    Start,
    #[serde(rename = "stop")]
    Stop,
    #[serde(rename = "delete")]
    Delete,
    #[serde(rename = "install")]
    Install,
    #[serde(rename = "reinstall")]
    Reinstall,
    #[serde(rename = "upgrade")]
    Upgrade,
    #[serde(rename = "updateSettings")]
    UpdateSettings,
    #[serde(rename = "changeOwner")]
    ChangeOwner,
    #[serde(rename = "addOwner")]
    AddOwner,
    #[serde(rename = "deleteOwner")]
    DeleteOwner,
}

#[derive(CandidType, Deserialize, Debug)]
pub struct UpdateSettingsArgs {
    pub canister_id: Principal,
    pub settings: CanisterSettings,
}

#[derive(CandidType, Deserialize, Debug)]
pub struct DeployArgs {
    pub name: String,
    pub description: String,
    pub settings: Option<CanisterSettings>,
    pub deploy_arguments: Option<Vec<u8>>,
    pub wasm: Option<Vec<u8>>,
    pub cycle_amount: Nat,
    pub preserve_wasm: bool,
}

#[derive(CandidType, Deserialize, Debug)]
pub struct InstallArgs {
    pub canister_id: Principal,
    pub mode: InstallMode,
    pub wasm_module: Vec<u8>,
    pub arg: Vec<u8>,
}

#[derive(CandidType, Deserialize, Debug)]
pub enum InstallMode {
    #[serde(rename = "install")]
    Install,
    #[serde(rename = "reinstall")]
    Reinstall,
    #[serde(rename = "upgrade")]
    Upgrade,
}
