use lazy_static::lazy_static;
use std::fs::File;
use std::io::Read;
use std::path::PathBuf;
use types::CanisterWasm;

lazy_static! {
  // external canisters
  pub static ref ORIGYN_NFT: CanisterWasm = get_external_canister_wasm("origyn_nft_reference");
  pub static ref OGY_LEDGER: CanisterWasm = get_external_canister_wasm("icrc_ledger");
  pub static ref LDG_LEDGER: CanisterWasm = get_external_canister_wasm("icrc_ledger");
  pub static ref NOTIFY_WASM: CanisterWasm = get_external_canister_wasm("test_notify");

  // wasms in wasms folder
  pub static ref BUYBACK_BURN_NO_ARGS: CanisterWasm = get_canister_wasm("buyback_burn_no_args");
  pub static ref BIG_WASM: CanisterWasm = get_canister_wasm("sns_neuron_controller");
  pub static ref CYCLES_BURNER: CanisterWasm = get_canister_wasm("cycles_burner");
}

fn get_internal_canister_wasm(canister: &str) -> Vec<u8> {
    read_file_from_relative_bin(&format!(
        "../../.dfx/local/canisters/{canister}/{canister}.wasm.gz"
    ))
    .unwrap()
}

fn get_external_canister_wasm(canister: &str) -> Vec<u8> {
    read_file_from_relative_bin(&format!(
        "../external_canisters/{canister}/wasm/{canister}_canister.wasm.gz"
    ))
    .unwrap()
}

fn read_file_from_relative_bin(file_path: &str) -> Result<Vec<u8>, std::io::Error> {
    // Open the wasm file
    let mut file = File::open(file_path)?;

    // Read the contents of the file into a vector
    let mut buffer = Vec::new();
    file.read_to_end(&mut buffer)?;

    Ok(buffer)
}

fn get_canister_wasm(canister_name: &str) -> CanisterWasm {
    let extensions = ["wasm", "wasm.gz"];
    find_and_read_file(&wasms_bin(), canister_name, &extensions)
}

fn find_and_read_file(
    base_path: &PathBuf,
    canister_name: &str,
    extensions: &[&str],
) -> CanisterWasm {
    for ext in extensions {
        let file_path = base_path.join(format!("{canister_name}_canister.{ext}"));
        if file_path.exists() {
            return read_file(&file_path);
        }
    }
    panic!(
        "Could not find a valid wasm file for {canister_name} with extensions: {:?}",
        extensions
    );
}

pub fn wasms_bin() -> PathBuf {
    let mut file_path = PathBuf::from(
        std::env::var("CARGO_MANIFEST_DIR")
            .expect("Failed to read CARGO_MANIFEST_DIR env variable"),
    );
    file_path.pop(); // Move up one directory to `integration_testing`
    file_path.push("wasms"); // Navigate to `wasms` folder
    file_path
}

fn read_file(file_path: &PathBuf) -> Vec<u8> {
    let mut file = File::open(file_path)
        .unwrap_or_else(|_| panic!("Failed to open file: {}", file_path.to_string_lossy()));
    let mut bytes = Vec::new();
    file.read_to_end(&mut bytes).expect("Failed to read file");
    bytes
}
