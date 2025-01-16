use candid::types::value::IDLValue;
use candid::{ Nat, Principal };
use origyn_nft_reference::origyn_nft_reference_canister::{
  CandyShared,
  NftCanisterStageNftOrigynArg,
  OrigynError,
  OrigynTextResult,
  PropertyShared,
  StageChunkArg,
  StageLibraryResult,
};
use pocket_ic::PocketIc;
use serde_bytes::ByteBuf;
use types::CanisterId;

pub enum TokenStandard {
  DIP20,
  Ledger,
  EXTFungible,
  ICRC1,
  Other(CandyShared),
}
pub struct ICTokenSpec {
  pub canister: Principal,
  pub fee: Option<Nat>,
  pub symbol: String,
  pub decimals: Nat,
  pub id: Option<Nat>,
  pub standard: TokenStandard,
}
struct TokenSpec {
  ic: ICTokenSpec,
  extensible: CandyShared,
}

struct StandardNftReturn {
  metadata: CandyShared,
}

pub struct MetadataStruct {
  __system: &'static str,
  __system_status: &'static str,
  __system_secondary_royalty: &'static str,
  __system_primary_royalty: &'static str,
  __system_fixed_royalty: &'static str,
  __system_node: &'static str,
  __system_originator: &'static str,
  __system_wallet_shares: &'static str,
  __system_physical: &'static str,
  __system_escrowed: &'static str,
  __apps: &'static str,
  broker_royalty_dev_fund_override: &'static str,
  library: &'static str,
  library_id: &'static str,
  library_size: &'static str,
  library_location_type: &'static str,
  owner: &'static str,
  id: &'static str,
  primary_asset: &'static str,
  preview_asset: &'static str,
  experience_asset: &'static str,
  hidden_asset: &'static str,
  is_soulbound: &'static str,
  immutable_library: &'static str,
  physical: &'static str,
  primary_host: &'static str,
  primary_port: &'static str,
  primary_protocol: &'static str,
  primary_royalties_default: &'static str,
  fixed_royalties_default: &'static str,
  originator_override: &'static str,
  royalty_broker: &'static str,
  royalty_node: &'static str,
  royalty_originator: &'static str,
  royalty_network: &'static str,
  royalty_custom: &'static str,
  secondary_royalties_default: &'static str,
  icrc7_description: &'static str,
  __apps_app_id: &'static str,
  __system_current_sale_id: &'static str,
}

const metadata: MetadataStruct = MetadataStruct {
  __system: "__system",
  __system_status: "status",
  __system_secondary_royalty: "com.origyn.royalties.secondary",
  __system_primary_royalty: "com.origyn.royalties.primary",
  __system_fixed_royalty: "com.origyn.royalties.fixed",
  __system_node: "com.origyn.node",
  __system_originator: "com.origyn.originator",
  __system_wallet_shares: "com.origyn.wallet_shares",
  __system_physical: "com.origyn.physical",
  __system_escrowed: "com.origyn.escrow_node",
  __apps: "__apps",
  broker_royalty_dev_fund_override: "com.origyn.royalties.broker_dev_fund_override",
  library: "library",
  library_id: "library_id",
  library_size: "size",
  library_location_type: "location_type",
  owner: "owner",
  id: "id",
  immutable_library: "com.origyn.immutable_library",
  physical: "com.origyn.physical",
  primary_asset: "primary_asset",
  preview_asset: "preview_asset",
  primary_royalties_default: "com.origyn.royalties.primary.default",
  secondary_royalties_default: "com.origyn.royalties.secondary.default",
  fixed_royalties_default: "com.origyn.royalties.fixed.default",
  hidden_asset: "hidden_asset",
  is_soulbound: "is_soulbound",
  primary_host: "primary_host",
  primary_port: "primary_port",
  primary_protocol: "primary_protocol",
  originator_override: "com.origyn.originator.override",
  royalty_broker: "com.origyn.royalty.broker",
  royalty_node: "com.origyn.royalty.node",
  royalty_originator: "com.origyn.royalty.originator",
  royalty_network: "com.origyn.royalty.network",
  royalty_custom: "com.origyn.royalty.custom",
  experience_asset: "experience_asset",
  icrc7_description: "com.origyn.icrc7.description",
  __apps_app_id: "app_id",
  __system_current_sale_id: "current_sale_id",
};

#[derive(Debug)]
pub struct BuildStandardNftReturns {
  stage: Result<String, OrigynError>,
  filestage: Result<Principal, OrigynError>,
  previewstage: Result<Principal, OrigynError>,
  hiddenstage: Result<Principal, OrigynError>,
}

pub fn build_standard_nft(
  pic: &mut PocketIc,
  token_id: String,
  canister_id: CanisterId,
  app: Principal,
  originator: Principal,
  file_size: Nat,
  is_soulbound: bool,
  net_principal: Principal
) -> BuildStandardNftReturns {
  let stage = crate::client::origyn_nft_reference::client::stage_nft_origyn(
    pic,
    canister_id,
    Some(net_principal),
    standard_nft(token_id.clone(), canister_id, app, file_size, is_soulbound, originator)
  );
  println!("stage: {:?}", stage);

  let filestage: StageLibraryResult =
    crate::client::origyn_nft_reference::client::stage_library_nft_origyn(
      pic,
      canister_id,
      Some(net_principal),
      standardFileChunk(
        token_id.clone(),
        "page".to_string(),
        "hello world".to_string(),
        CandyShared::Option(None)
      )
    );

  println!("filestage: {:?}", filestage);

  let previewstage: StageLibraryResult =
    crate::client::origyn_nft_reference::client::stage_library_nft_origyn(
      pic,
      canister_id,
      Some(net_principal),
      standardFileChunk(
        token_id.clone(),
        "preview".to_string(),
        "preview hello world".to_string(),
        CandyShared::Option(None)
      )
    );

  println!("previewstage: {:?}", previewstage);

  let hiddenstage: StageLibraryResult =
    crate::client::origyn_nft_reference::client::stage_library_nft_origyn(
      pic,
      canister_id,
      Some(net_principal),
      standardFileChunk(
        token_id.clone(),
        "hidden".to_string(),
        "hidden hello world".to_string(),
        CandyShared::Option(None)
      )
    );

  println!("hiddenstage: {:?}", hiddenstage);

  let immutablestage: StageLibraryResult =
    crate::client::origyn_nft_reference::client::stage_library_nft_origyn(
      pic,
      canister_id,
      Some(net_principal),
      standardFileChunk(
        token_id.clone(),
        "immutable_item".to_string(),
        "immutable".to_string(),
        CandyShared::Option(None)
      )
    );

  println!("immutablestage: {:?}", immutablestage);

  let ret_stage = {
    match stage {
      OrigynTextResult::Ok(response) => Ok(response),
      OrigynTextResult::Err(error) => Err(error),
    }
  };

  let ret_filestage: Result<Principal, OrigynError> = match filestage {
    StageLibraryResult::Ok(response) => Ok(response.canister),
    StageLibraryResult::Err(error) => Err(error),
  };

  let ret_previewstage = match previewstage {
    StageLibraryResult::Ok(response) => Ok(response.canister),
    StageLibraryResult::Err(error) => Err(error),
  };

  let ret_hiddenstage = match hiddenstage {
    StageLibraryResult::Ok(response) => Ok(response.canister),
    StageLibraryResult::Err(error) => Err(error),
  };

  return BuildStandardNftReturns {
    stage: ret_stage,
    filestage: ret_filestage,
    previewstage: ret_previewstage,
    hiddenstage: ret_hiddenstage,
  };
}

#[derive(Debug)]
pub struct BuildStandardCollectionReturns {
  stage: Result<String, OrigynError>,
  filestage: Result<Principal, OrigynError>,
}

pub fn build_standard_collection(
  pic: &mut PocketIc,
  canister_id: CanisterId,
  app: Principal,
  originator: Principal,
  file_size: Nat,
  net_principal: Principal,
  ledger_token: ICTokenSpec
) -> BuildStandardCollectionReturns {
  let aCollection: NftCanisterStageNftOrigynArg = standard_collection(
    canister_id,
    app,
    net_principal,
    originator,
    file_size,
    true,
    ledger_token
  );

  // println!("acollection {:?}", aCollection);
  // println!("acollection IDLValue {:?}", IDLValue::try_from_candid_type(&&aCollection).unwrap());
  let stage: OrigynTextResult = crate::client::origyn_nft_reference::client::stage_nft_origyn(
    pic,
    canister_id,
    Some(net_principal),
    aCollection
  );

  let file_stage: StageLibraryResult =
    crate::client::origyn_nft_reference::client::stage_library_nft_origyn(
      pic,
      canister_id,
      Some(net_principal),
      standardFileChunk(
        "".to_string(),
        "collection_banner".to_string(),
        "collection_banner".to_string(),
        CandyShared::Option(None)
      )
    );

  let ret_stage = {
    match stage {
      OrigynTextResult::Ok(response) => Ok(response),
      OrigynTextResult::Err(error) => Err(error),
    }
  };

  let ret_filestage: Result<Principal, OrigynError> = match file_stage {
    StageLibraryResult::Ok(response) => Ok(response.canister),
    StageLibraryResult::Err(error) => Err(error),
  };

  return BuildStandardCollectionReturns {
    stage: ret_stage,
    filestage: ret_filestage,
  };
}

fn standard_nft(
  token_id: String,
  canister: Principal,
  app: Principal,
  file_size: Nat,
  is_soulbound: bool,
  originator: Principal
) -> NftCanisterStageNftOrigynArg {
  NftCanisterStageNftOrigynArg {
    metadata: Box::new(
      CandyShared::Class(
        vec![
          PropertyShared {
            name: "id".to_string(),
            value: Box::new(CandyShared::Text(token_id)),
            immutable: true,
          },
          PropertyShared {
            name: "primary_asset".to_string(),
            value: Box::new(CandyShared::Text("page".to_string())),
            immutable: false,
          },
          PropertyShared {
            name: "preview".to_string(),
            value: Box::new(CandyShared::Text("page".to_string())),
            immutable: true,
          },
          PropertyShared {
            name: "experience".to_string(),
            value: Box::new(CandyShared::Text("page".to_string())),
            immutable: true,
          },
          PropertyShared {
            name: "library".to_string(),
            value: Box::new(
              CandyShared::Array(
                vec![
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "library_id".to_string(),
                          value: Box::new(CandyShared::Text("page".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "title".to_string(),
                          value: Box::new(CandyShared::Text("page".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "location_type".to_string(),
                          value: Box::new(CandyShared::Text("canister".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "location".to_string(),
                          value: Box::new(
                            CandyShared::Text(
                              format!("http://localhost:8000/-/1/-/page?canisterId={}", canister)
                            )
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "content_type".to_string(),
                          value: Box::new(
                            CandyShared::Text("text/html; charset=UTF-8".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "content_hash".to_string(),
                          value: Box::new(CandyShared::Bytes(ByteBuf::from(vec![0, 0, 0, 0]))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "size".to_string(),
                          value: Box::new(CandyShared::Nat(Nat::from(file_size.clone()))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "sort".to_string(),
                          value: Box::new(CandyShared::Nat(Nat::from(0 as u32))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "read".to_string(),
                          value: Box::new(CandyShared::Text("public".to_string())),
                          immutable: false,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "library_id".to_string(),
                          value: Box::new(CandyShared::Text("preview".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "title".to_string(),
                          value: Box::new(CandyShared::Text("preview".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "location_type".to_string(),
                          value: Box::new(CandyShared::Text("canister".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "location".to_string(),
                          value: Box::new(
                            CandyShared::Text(
                              format!("http://localhost:8000/-/1/-/preview?canisterId={}", canister)
                            )
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "content_type".to_string(),
                          value: Box::new(
                            CandyShared::Text("text/html; charset=UTF-8".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "content_hash".to_string(),
                          value: Box::new(CandyShared::Bytes(ByteBuf::from(vec![0, 0, 0, 0]))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "size".to_string(),
                          value: Box::new(CandyShared::Nat(Nat::from(file_size.clone()))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "sort".to_string(),
                          value: Box::new(CandyShared::Nat(Nat::from(0 as u32))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "read".to_string(),
                          value: Box::new(CandyShared::Text("public".to_string())),
                          immutable: false,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "library_id".to_string(),
                          value: Box::new(CandyShared::Text("hidden".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "title".to_string(),
                          value: Box::new(CandyShared::Text("hidden".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "location_type".to_string(),
                          value: Box::new(CandyShared::Text("canister".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "location".to_string(),
                          value: Box::new(
                            CandyShared::Text(
                              format!("http://localhost:8000/-/1/-/hidden?canisterId={}", canister)
                            )
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "content_type".to_string(),
                          value: Box::new(
                            CandyShared::Text("text/html; charset=UTF-8".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "content_hash".to_string(),
                          value: Box::new(CandyShared::Bytes(ByteBuf::from(vec![0, 0, 0, 0]))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "size".to_string(),
                          value: Box::new(CandyShared::Nat(Nat::from(file_size.clone()))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "sort".to_string(),
                          value: Box::new(CandyShared::Nat(Nat::from(0 as u32))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "read".to_string(),
                          value: Box::new(CandyShared::Text("public".to_string())),
                          immutable: false,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "library_id".to_string(),
                          value: Box::new(CandyShared::Text("collection_banner".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "title".to_string(),
                          value: Box::new(CandyShared::Text("collection_banner".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "location_type".to_string(),
                          value: Box::new(CandyShared::Text("collection".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "location".to_string(),
                          value: Box::new(
                            CandyShared::Text(
                              format!("http://localhost:8000/-/1/-/collection_banner?canisterId={}", canister)
                            )
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "content_type".to_string(),
                          value: Box::new(
                            CandyShared::Text("text/html; charset=UTF-8".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "content_hash".to_string(),
                          value: Box::new(CandyShared::Bytes(ByteBuf::from(vec![0, 0, 0, 0]))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "size".to_string(),
                          value: Box::new(CandyShared::Nat(Nat::from(file_size.clone()))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "sort".to_string(),
                          value: Box::new(CandyShared::Nat(Nat::from(0 as u32))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "read".to_string(),
                          value: Box::new(CandyShared::Text("public".to_string())),
                          immutable: false,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "library_id".to_string(),
                          value: Box::new(CandyShared::Text("immutable_item".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "title".to_string(),
                          value: Box::new(CandyShared::Text("immutable".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "location_type".to_string(),
                          value: Box::new(CandyShared::Text("canister".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "location".to_string(),
                          value: Box::new(
                            CandyShared::Text(
                              format!("http://localhost:8000/-/1/-/immutable_item?canisterId={}", canister)
                            )
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "content_type".to_string(),
                          value: Box::new(
                            CandyShared::Text("text/html; charset=UTF-8".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "content_hash".to_string(),
                          value: Box::new(CandyShared::Bytes(ByteBuf::from(vec![0, 0, 0, 0]))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "size".to_string(),
                          value: Box::new(CandyShared::Nat(Nat::from(file_size.clone()))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "sort".to_string(),
                          value: Box::new(CandyShared::Nat(Nat::from(0 as u32))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "read".to_string(),
                          value: Box::new(CandyShared::Text("public".to_string())),
                          immutable: false,
                        },
                        PropertyShared {
                          name: "com.origyn.immutable_library".to_string(),
                          value: Box::new(CandyShared::Bool(true)),
                          immutable: false,
                        }
                      ]
                    )
                  )
                ]
              )
            ),
            immutable: false,
          },
          PropertyShared {
            name: "__apps".to_string(),
            value: Box::new(
              CandyShared::Array(
                vec![
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "com.test.__public".to_string(),
                          value: Box::new(CandyShared::Text("com.test.__public".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "read".to_string(),
                          value: Box::new(CandyShared::Text("public".to_string())),
                          immutable: false,
                        },
                        PropertyShared {
                          name: "write".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "type".to_string(),
                                  value: Box::new(CandyShared::Text("allow".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "list".to_string(),
                                  value: Box::new(
                                    CandyShared::Array(
                                      vec![Box::new(CandyShared::Principal_(app.clone()))]
                                    )
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        },
                        PropertyShared {
                          name: "permissions".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "type".to_string(),
                                  value: Box::new(CandyShared::Text("allow".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "list".to_string(),
                                  value: Box::new(
                                    CandyShared::Array(
                                      vec![Box::new(CandyShared::Principal_(app.clone()))]
                                    )
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        },
                        PropertyShared {
                          name: "data".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "val1".to_string(),
                                  value: Box::new(CandyShared::Text("val1".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "val2".to_string(),
                                  value: Box::new(CandyShared::Text("val2".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "val3".to_string(),
                                  value: Box::new(
                                    CandyShared::Class(
                                      vec![
                                        PropertyShared {
                                          name: "data".to_string(),
                                          value: Box::new(CandyShared::Text("val3".to_string())),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "read".to_string(),
                                          value: Box::new(CandyShared::Text("public".to_string())),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "write".to_string(),
                                          value: Box::new(
                                            CandyShared::Class(
                                              vec![
                                                PropertyShared {
                                                  name: "type".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Text("allow".to_string())
                                                  ),
                                                  immutable: false,
                                                },
                                                PropertyShared {
                                                  name: "list".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Array(
                                                      vec![
                                                        Box::new(
                                                          CandyShared::Principal_(app.clone())
                                                        )
                                                      ]
                                                    )
                                                  ),
                                                  immutable: false,
                                                }
                                              ]
                                            )
                                          ),
                                          immutable: false,
                                        }
                                      ]
                                    )
                                  ),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "val4".to_string(),
                                  value: Box::new(
                                    CandyShared::Class(
                                      vec![
                                        PropertyShared {
                                          name: "data".to_string(),
                                          value: Box::new(CandyShared::Text("val4".to_string())),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "read".to_string(),
                                          value: Box::new(
                                            CandyShared::Class(
                                              vec![
                                                PropertyShared {
                                                  name: "type".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Text("allow".to_string())
                                                  ),
                                                  immutable: false,
                                                },
                                                PropertyShared {
                                                  name: "list".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Array(
                                                      vec![
                                                        Box::new(
                                                          CandyShared::Principal_(app.clone())
                                                        )
                                                      ]
                                                    )
                                                  ),
                                                  immutable: false,
                                                }
                                              ]
                                            )
                                          ),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "write".to_string(),
                                          value: Box::new(
                                            CandyShared::Class(
                                              vec![
                                                PropertyShared {
                                                  name: "type".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Text("allow".to_string())
                                                  ),
                                                  immutable: false,
                                                },
                                                PropertyShared {
                                                  name: "list".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Array(
                                                      vec![
                                                        Box::new(
                                                          CandyShared::Principal_(app.clone())
                                                        )
                                                      ]
                                                    )
                                                  ),
                                                  immutable: false,
                                                }
                                              ]
                                            )
                                          ),
                                          immutable: false,
                                        }
                                      ]
                                    )
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "com.test.__private".to_string(),
                          value: Box::new(CandyShared::Text("com.test.__private".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "read".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "type".to_string(),
                                  value: Box::new(CandyShared::Text("allow".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "list".to_string(),
                                  value: Box::new(
                                    CandyShared::Array(
                                      vec![Box::new(CandyShared::Principal_(app.clone()))]
                                    )
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        },
                        PropertyShared {
                          name: "write".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "type".to_string(),
                                  value: Box::new(CandyShared::Text("allow".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "list".to_string(),
                                  value: Box::new(
                                    CandyShared::Array(
                                      vec![Box::new(CandyShared::Principal_(app.clone()))]
                                    )
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        },
                        PropertyShared {
                          name: "permissions".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "type".to_string(),
                                  value: Box::new(CandyShared::Text("allow".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "list".to_string(),
                                  value: Box::new(
                                    CandyShared::Array(
                                      vec![Box::new(CandyShared::Principal_(app.clone()))]
                                    )
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        },
                        PropertyShared {
                          name: "data".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "val1".to_string(),
                                  value: Box::new(CandyShared::Text("val1".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "val2".to_string(),
                                  value: Box::new(CandyShared::Text("val2".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "val3".to_string(),
                                  value: Box::new(
                                    CandyShared::Class(
                                      vec![
                                        PropertyShared {
                                          name: "data".to_string(),
                                          value: Box::new(CandyShared::Text("val3".to_string())),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "read".to_string(),
                                          value: Box::new(CandyShared::Text("public".to_string())),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "write".to_string(),
                                          value: Box::new(
                                            CandyShared::Class(
                                              vec![
                                                PropertyShared {
                                                  name: "type".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Text("allow".to_string())
                                                  ),
                                                  immutable: false,
                                                },
                                                PropertyShared {
                                                  name: "list".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Array(
                                                      vec![
                                                        Box::new(
                                                          CandyShared::Principal_(app.clone())
                                                        )
                                                      ]
                                                    )
                                                  ),
                                                  immutable: false,
                                                }
                                              ]
                                            )
                                          ),
                                          immutable: false,
                                        }
                                      ]
                                    )
                                  ),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "val4".to_string(),
                                  value: Box::new(
                                    CandyShared::Class(
                                      vec![
                                        PropertyShared {
                                          name: "data".to_string(),
                                          value: Box::new(CandyShared::Text("val4".to_string())),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "read".to_string(),
                                          value: Box::new(
                                            CandyShared::Class(
                                              vec![
                                                PropertyShared {
                                                  name: "type".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Text("allow".to_string())
                                                  ),
                                                  immutable: false,
                                                },
                                                PropertyShared {
                                                  name: "list".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Array(
                                                      vec![
                                                        Box::new(
                                                          CandyShared::Principal_(app.clone())
                                                        )
                                                      ]
                                                    )
                                                  ),
                                                  immutable: false,
                                                }
                                              ]
                                            )
                                          ),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "write".to_string(),
                                          value: Box::new(
                                            CandyShared::Class(
                                              vec![
                                                PropertyShared {
                                                  name: "type".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Text("allow".to_string())
                                                  ),
                                                  immutable: false,
                                                },
                                                PropertyShared {
                                                  name: "list".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Array(
                                                      vec![
                                                        Box::new(
                                                          CandyShared::Principal_(app.clone())
                                                        )
                                                      ]
                                                    )
                                                  ),
                                                  immutable: false,
                                                }
                                              ]
                                            )
                                          ),
                                          immutable: false,
                                        }
                                      ]
                                    )
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        }
                      ]
                    )
                  )
                ]
              )
            ),
            immutable: false,
          },
          PropertyShared {
            name: "primary_host".to_string(),
            value: Box::new(CandyShared::Text("localhost".to_string())),
            immutable: false,
          },
          PropertyShared {
            name: "primary_port".to_string(),
            value: Box::new(CandyShared::Text("8000".to_string())),
            immutable: false,
          },
          PropertyShared {
            name: "primary_protocol".to_string(),
            value: Box::new(CandyShared::Text("http".to_string())),
            immutable: false,
          },
          PropertyShared {
            name: "owner".to_string(),
            value: Box::new(CandyShared::Principal_(canister)),
            immutable: false,
          },
          PropertyShared {
            name: "com.origyn.originator.override".to_string(),
            value: Box::new(CandyShared::Principal_(originator)),
            immutable: true,
          },
          PropertyShared {
            name: "is_soulbound".to_string(),
            value: Box::new(CandyShared::Bool(is_soulbound)),
            immutable: is_soulbound,
          }
        ]
      )
    ),
  }
}

fn standard_collection(
  canister: Principal,
  app: Principal,
  node: Principal,
  originator: Principal,
  file_size: Nat,
  broker_override: bool,
  ledger_token: ICTokenSpec
) -> NftCanisterStageNftOrigynArg {
  NftCanisterStageNftOrigynArg {
    metadata: Box::new(
      CandyShared::Class(
        vec![
          PropertyShared {
            name: "id".to_string(),
            value: Box::new(CandyShared::Text("".to_string())),
            immutable: true,
          },
          PropertyShared {
            name: "primary_asset".to_string(),
            value: Box::new(CandyShared::Text("collection_banner".to_string())),
            immutable: true,
          },
          PropertyShared {
            name: "preview".to_string(),
            value: Box::new(CandyShared::Text("collection_banner".to_string())),
            immutable: true,
          },
          PropertyShared {
            name: "experience".to_string(),
            value: Box::new(CandyShared::Text("collection_banner".to_string())),
            immutable: true,
          },
          PropertyShared {
            name: "com.origyn.node".to_string(),
            value: Box::new(CandyShared::Principal_(node)),
            immutable: true,
          },
          PropertyShared {
            name: "com.origyn.originator".to_string(),
            value: Box::new(CandyShared::Principal_(node)),
            immutable: true,
          },
          PropertyShared {
            name: "com.origyn.royalties.primary.default".to_string(),
            value: Box::new(
              CandyShared::Array(
                vec![
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(
                            CandyShared::Text("com.origyn.royalty.broker".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "rate".to_string(),
                          value: Box::new(CandyShared::Float(0.06)),
                          immutable: true,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(CandyShared::Text("com.origyn.royalty.node".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "rate".to_string(),
                          value: Box::new(CandyShared::Float(0.07777)),
                          immutable: true,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(
                            CandyShared::Text("com.origyn.royalty.network".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "rate".to_string(),
                          value: Box::new(CandyShared::Float(0.005)),
                          immutable: true,
                        }
                      ]
                    )
                  )
                ]
              )
            ),
            immutable: false,
          },
          PropertyShared {
            name: "com.origyn.royalties.secondary.default".to_string(),
            value: Box::new(
              CandyShared::Array(
                vec![
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(
                            CandyShared::Text("com.origyn.royalty.broker".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "rate".to_string(),
                          value: Box::new(CandyShared::Float(0.01)),
                          immutable: true,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(CandyShared::Text("com.origyn.royalty.node".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "rate".to_string(),
                          value: Box::new(CandyShared::Float(0.02)),
                          immutable: true,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(
                            CandyShared::Text("com.origyn.royalty.originator".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "rate".to_string(),
                          value: Box::new(CandyShared::Float(0.03)),
                          immutable: true,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(
                            CandyShared::Text("com.origyn.royalty.custom".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "rate".to_string(),
                          value: Box::new(CandyShared::Float(0.04)),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "account".to_string(),
                          value: Box::new(CandyShared::Principal_(originator)),
                          immutable: true,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(
                            CandyShared::Text("com.origyn.royalty.network".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "rate".to_string(),
                          value: Box::new(CandyShared::Float(0.005)),
                          immutable: true,
                        }
                      ]
                    )
                  )
                ]
              )
            ),
            immutable: false,
          },
          PropertyShared {
            name: "com.origyn.royalties.primary.default".to_string(),
            value: Box::new(
              CandyShared::Array(
                vec![
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(
                            CandyShared::Text("com.origyn.royalty.broker".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "rate".to_string(),
                          value: Box::new(CandyShared::Float(0.06)),
                          immutable: true,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(CandyShared::Text("com.origyn.royalty.node".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "rate".to_string(),
                          value: Box::new(CandyShared::Float(0.07777)),
                          immutable: true,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(
                            CandyShared::Text("com.origyn.royalty.network".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "rate".to_string(),
                          value: Box::new(CandyShared::Float(0.005)),
                          immutable: true,
                        }
                      ]
                    )
                  )
                ]
              )
            ),
            immutable: false,
          },
          PropertyShared {
            name: "com.origyn.royalties.fixed.default".to_string(),
            value: Box::new(
              CandyShared::Array(
                vec![
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(
                            CandyShared::Text("com.origyn.royalty.broker".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "fixedXDR".to_string(),
                          value: Box::new(CandyShared::Float(1000000.0)),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenCanister".to_string(),
                          value: Box::new(CandyShared::Principal_(ledger_token.canister.clone())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenSymbol".to_string(),
                          value: Box::new(CandyShared::Text(ledger_token.symbol.clone())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenDecimals".to_string(),
                          value: Box::new(
                            CandyShared::Nat(Nat::from(ledger_token.decimals.clone()))
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenFee".to_string(),
                          value: Box::new(match ledger_token.fee.clone() {
                            None => CandyShared::Option(None),
                            Some(val) => CandyShared::Nat(val),
                          }),
                          immutable: true,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(CandyShared::Text("com.origyn.royalty.node".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "fixedXDR".to_string(),
                          value: Box::new(CandyShared::Float(1000000.0)),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenCanister".to_string(),
                          value: Box::new(CandyShared::Principal_(ledger_token.canister.clone())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenSymbol".to_string(),
                          value: Box::new(CandyShared::Text(ledger_token.symbol.clone())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenDecimals".to_string(),
                          value: Box::new(
                            CandyShared::Nat(Nat::from(ledger_token.decimals.clone()))
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenFee".to_string(),
                          value: Box::new(match ledger_token.fee.clone() {
                            None => CandyShared::Option(None),
                            Some(val) => CandyShared::Nat(val),
                          }),
                          immutable: true,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(
                            CandyShared::Text("com.origyn.royalty.originator".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "fixedXDR".to_string(),
                          value: Box::new(CandyShared::Float(1000000.0)),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenCanister".to_string(),
                          value: Box::new(CandyShared::Principal_(ledger_token.canister.clone())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenSymbol".to_string(),
                          value: Box::new(CandyShared::Text(ledger_token.symbol.clone())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenDecimals".to_string(),
                          value: Box::new(
                            CandyShared::Nat(Nat::from(ledger_token.decimals.clone()))
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenFee".to_string(),
                          value: Box::new(match ledger_token.fee.clone() {
                            None => CandyShared::Option(None),
                            Some(val) => CandyShared::Nat(val),
                          }),
                          immutable: true,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(
                            CandyShared::Text("com.origyn.royalty.custom".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "fixedXDR".to_string(),
                          value: Box::new(CandyShared::Float(1000000.0)),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenCanister".to_string(),
                          value: Box::new(CandyShared::Principal_(ledger_token.canister.clone())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenSymbol".to_string(),
                          value: Box::new(CandyShared::Text(ledger_token.symbol.clone())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenDecimals".to_string(),
                          value: Box::new(
                            CandyShared::Nat(Nat::from(ledger_token.decimals.clone()))
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenFee".to_string(),
                          value: Box::new(match ledger_token.fee.clone() {
                            None => CandyShared::Option(None),
                            Some(val) => CandyShared::Nat(val),
                          }),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "account".to_string(),
                          value: Box::new(CandyShared::Principal_(originator)),
                          immutable: true,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "tag".to_string(),
                          value: Box::new(
                            CandyShared::Text("com.origyn.royalty.network".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "fixedXDR".to_string(),
                          value: Box::new(CandyShared::Float(1000000.0)),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenCanister".to_string(),
                          value: Box::new(CandyShared::Principal_(ledger_token.canister.clone())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenSymbol".to_string(),
                          value: Box::new(CandyShared::Text(ledger_token.symbol.clone())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenDecimals".to_string(),
                          value: Box::new(
                            CandyShared::Nat(Nat::from(ledger_token.decimals.clone()))
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "tokenFee".to_string(),
                          value: Box::new(match ledger_token.fee.clone() {
                            None => CandyShared::Option(None),
                            Some(val) => CandyShared::Nat(val),
                          }),
                          immutable: true,
                        }
                      ]
                    )
                  )
                ]
              )
            ),
            immutable: false,
          },
          PropertyShared {
            name: "library".to_string(),
            value: Box::new(
              CandyShared::Array(
                vec![
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: "library_id".to_string(),
                          value: Box::new(CandyShared::Text("collection_banner".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "title".to_string(),
                          value: Box::new(CandyShared::Text("collection_banner".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "location_type".to_string(),
                          value: Box::new(CandyShared::Text("canister".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "location".to_string(),
                          value: Box::new(
                            CandyShared::Text(
                              format!("https://{}.raw.icp0.io/collection/-/collection_banner", canister)
                            )
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "content_type".to_string(),
                          value: Box::new(
                            CandyShared::Text("text/html; charset=UTF-8".to_string())
                          ),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "content_hash".to_string(),
                          value: Box::new(CandyShared::Bytes(ByteBuf::from(vec![0, 0, 0, 0]))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "size".to_string(),
                          value: Box::new(CandyShared::Nat(Nat::from(file_size.clone()))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "sort".to_string(),
                          value: Box::new(CandyShared::Nat(Nat::from(0 as u32))),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "read".to_string(),
                          value: Box::new(CandyShared::Text("public".to_string())),
                          immutable: false,
                        }
                      ]
                    )
                  )
                ]
              )
            ),
            immutable: false,
          },
          PropertyShared {
            name: "__apps".to_string(),
            value: Box::new(
              CandyShared::Array(
                vec![
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: metadata.__apps_app_id.to_string(),
                          value: Box::new(CandyShared::Text("com.test.__public".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "read".to_string(),
                          value: Box::new(CandyShared::Text("public".to_string())),
                          immutable: false,
                        },
                        PropertyShared {
                          name: "write".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "type".to_string(),
                                  value: Box::new(CandyShared::Text("allow".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "list".to_string(),
                                  value: Box::new(
                                    CandyShared::Array(vec![Box::new(CandyShared::Principal_(app))])
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        },
                        PropertyShared {
                          name: "permissions".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "type".to_string(),
                                  value: Box::new(CandyShared::Text("allow".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "list".to_string(),
                                  value: Box::new(
                                    CandyShared::Array(vec![Box::new(CandyShared::Principal_(app))])
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        },
                        PropertyShared {
                          name: "data".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "val1".to_string(),
                                  value: Box::new(CandyShared::Text("val1".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "val2".to_string(),
                                  value: Box::new(CandyShared::Text("val2".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "val3".to_string(),
                                  value: Box::new(
                                    CandyShared::Class(
                                      vec![
                                        PropertyShared {
                                          name: "data".to_string(),
                                          value: Box::new(CandyShared::Text("val3".to_string())),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "read".to_string(),
                                          value: Box::new(CandyShared::Text("public".to_string())),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "write".to_string(),
                                          value: Box::new(
                                            CandyShared::Class(
                                              vec![
                                                PropertyShared {
                                                  name: "type".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Text("allow".to_string())
                                                  ),
                                                  immutable: false,
                                                },
                                                PropertyShared {
                                                  name: "list".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Array(
                                                      vec![Box::new(CandyShared::Principal_(app))]
                                                    )
                                                  ),
                                                  immutable: false,
                                                }
                                              ]
                                            )
                                          ),
                                          immutable: false,
                                        }
                                      ]
                                    )
                                  ),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "val4".to_string(),
                                  value: Box::new(
                                    CandyShared::Class(
                                      vec![
                                        PropertyShared {
                                          name: "data".to_string(),
                                          value: Box::new(CandyShared::Text("val4".to_string())),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "read".to_string(),
                                          value: Box::new(
                                            CandyShared::Class(
                                              vec![
                                                PropertyShared {
                                                  name: "type".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Text("allow".to_string())
                                                  ),
                                                  immutable: false,
                                                },
                                                PropertyShared {
                                                  name: "list".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Array(
                                                      vec![Box::new(CandyShared::Principal_(app))]
                                                    )
                                                  ),
                                                  immutable: false,
                                                }
                                              ]
                                            )
                                          ),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "write".to_string(),
                                          value: Box::new(
                                            CandyShared::Class(
                                              vec![
                                                PropertyShared {
                                                  name: "type".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Text("allow".to_string())
                                                  ),
                                                  immutable: false,
                                                },
                                                PropertyShared {
                                                  name: "list".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Array(
                                                      vec![Box::new(CandyShared::Principal_(app))]
                                                    )
                                                  ),
                                                  immutable: false,
                                                }
                                              ]
                                            )
                                          ),
                                          immutable: false,
                                        }
                                      ]
                                    )
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        }
                      ]
                    )
                  ),
                  Box::new(
                    CandyShared::Class(
                      vec![
                        PropertyShared {
                          name: metadata.__apps_app_id.to_string(),
                          value: Box::new(CandyShared::Text("com.test.__private".to_string())),
                          immutable: true,
                        },
                        PropertyShared {
                          name: "read".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "type".to_string(),
                                  value: Box::new(CandyShared::Text("allow".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "list".to_string(),
                                  value: Box::new(
                                    CandyShared::Array(vec![Box::new(CandyShared::Principal_(app))])
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        },
                        PropertyShared {
                          name: "write".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "type".to_string(),
                                  value: Box::new(CandyShared::Text("allow".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "list".to_string(),
                                  value: Box::new(
                                    CandyShared::Array(vec![Box::new(CandyShared::Principal_(app))])
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        },
                        PropertyShared {
                          name: "permissions".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "type".to_string(),
                                  value: Box::new(CandyShared::Text("allow".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "list".to_string(),
                                  value: Box::new(
                                    CandyShared::Array(vec![Box::new(CandyShared::Principal_(app))])
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        },
                        PropertyShared {
                          name: "data".to_string(),
                          value: Box::new(
                            CandyShared::Class(
                              vec![
                                PropertyShared {
                                  name: "val1".to_string(),
                                  value: Box::new(CandyShared::Text("val1".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "val2".to_string(),
                                  value: Box::new(CandyShared::Text("val2".to_string())),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "val3".to_string(),
                                  value: Box::new(
                                    CandyShared::Class(
                                      vec![
                                        PropertyShared {
                                          name: "data".to_string(),
                                          value: Box::new(CandyShared::Text("val3".to_string())),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "read".to_string(),
                                          value: Box::new(CandyShared::Text("public".to_string())),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "write".to_string(),
                                          value: Box::new(
                                            CandyShared::Class(
                                              vec![
                                                PropertyShared {
                                                  name: "type".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Text("allow".to_string())
                                                  ),
                                                  immutable: false,
                                                },
                                                PropertyShared {
                                                  name: "list".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Array(
                                                      vec![Box::new(CandyShared::Principal_(app))]
                                                    )
                                                  ),
                                                  immutable: false,
                                                }
                                              ]
                                            )
                                          ),
                                          immutable: false,
                                        }
                                      ]
                                    )
                                  ),
                                  immutable: false,
                                },
                                PropertyShared {
                                  name: "val4".to_string(),
                                  value: Box::new(
                                    CandyShared::Class(
                                      vec![
                                        PropertyShared {
                                          name: "data".to_string(),
                                          value: Box::new(CandyShared::Text("val4".to_string())),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "read".to_string(),
                                          value: Box::new(
                                            CandyShared::Class(
                                              vec![
                                                PropertyShared {
                                                  name: "type".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Text("allow".to_string())
                                                  ),
                                                  immutable: false,
                                                },
                                                PropertyShared {
                                                  name: "list".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Array(
                                                      vec![Box::new(CandyShared::Principal_(app))]
                                                    )
                                                  ),
                                                  immutable: false,
                                                }
                                              ]
                                            )
                                          ),
                                          immutable: false,
                                        },
                                        PropertyShared {
                                          name: "write".to_string(),
                                          value: Box::new(
                                            CandyShared::Class(
                                              vec![
                                                PropertyShared {
                                                  name: "type".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Text("allow".to_string())
                                                  ),
                                                  immutable: false,
                                                },
                                                PropertyShared {
                                                  name: "list".to_string(),
                                                  value: Box::new(
                                                    CandyShared::Array(
                                                      vec![Box::new(CandyShared::Principal_(app))]
                                                    )
                                                  ),
                                                  immutable: false,
                                                }
                                              ]
                                            )
                                          ),
                                          immutable: false,
                                        }
                                      ]
                                    )
                                  ),
                                  immutable: false,
                                }
                              ]
                            )
                          ),
                          immutable: false,
                        }
                      ]
                    )
                  )
                ]
              )
            ),
            immutable: false,
          },
          PropertyShared {
            name: "owner".to_string(),
            value: Box::new(CandyShared::Principal_(canister)),
            immutable: false,
          },
          PropertyShared {
            name: "is_soulbound".to_string(),
            value: Box::new(CandyShared::Bool(false)),
            immutable: false,
          },
          PropertyShared {
            name: "primary_host".to_string(),
            value: Box::new(CandyShared::Text("localhost".to_string())),
            immutable: false,
          },
          PropertyShared {
            name: "primary_port".to_string(),
            value: Box::new(CandyShared::Text("8000".to_string())),
            immutable: false,
          },
          PropertyShared {
            name: "primary_protocol".to_string(),
            value: Box::new(CandyShared::Text("http".to_string())),
            immutable: false,
          },
          PropertyShared {
            name: "com.origyn.royalties.broker_dev_fund_override".to_string(),
            value: Box::new(
              if broker_override {
                CandyShared::Bool(true)
              } else {
                CandyShared::Bool(false)
              }
            ),
            immutable: false,
          }
        ]
      )
    ),
  }
}

fn standardFileChunk(
  token_id: String,
  library_id: String,
  text: String,
  filedata: CandyShared
) -> StageChunkArg {
  StageChunkArg {
    token_id: token_id,
    library_id: library_id,
    filedata: Box::new(filedata),
    chunk: Nat::from(0 as u32),
    content: ByteBuf::from(text.as_bytes()),
  }
}
