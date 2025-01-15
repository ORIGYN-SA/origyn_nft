use std::str::FromStr;

use crate::client::icrc1_icrc2_token;
use crate::client::origyn_nft_reference::client::{
  get_nat_as_token_id_origyn,
  market_transfer_nft_origyn as market_transfer_nft_origyn_client,
  nft_origyn,
  sale_info_nft_origyn,
  sale_nft_origyn,
  update_metadata_node,
};
use crate::client::origyn_nft_reference::market_transfer_nft_origyn;
use crate::client::origyn_nft_reference::market_transfer_nft_origyn::Args as market_transfer_nft_origynArgs;
use crate::origyn_nft_suite::tests::utils::init_nft_with_premint_nft;
use crate::origyn_nft_suite::{ init::init, TestEnv };
use crate::origyn_nft_suite::{ CanisterIds, PrincipalIds };
use canister_time::{ MINUTE_IN_MS, NANOS_PER_MILLISECOND };
use num_bigint::BigUint;
use origyn_nft_reference::origyn_nft_reference_canister::{
  Account3,
  Account,
  AskFeature,
  CandyShared,
  EndingType,
  ManageSaleRequest,
  ManageSaleResult,
  PricingConfigShared,
  SaleInfoRequest,
  SalesConfig,
  IcTokenSpecStandard,
  TokenSpec,
  IcTokenSpec,
  EscrowRecord,
  BidRequest,
  EscrowReceipt,
  SaleInfoResult,
  SaleInfoResponse,
  FeeDepositRequest,
};
use std::time::SystemTime;
use utils::consts::E8S_FEE_OGY;
use candid::{ Nat, Principal };
use icrc_ledger_types::icrc1::account::Account as Icrc1Account;

#[test]
fn test_get_nat_as_token_id_origyn() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner, nft_buyer },
  } = env;

  let MAX_NFTS = 10;
  let mut name_as_nat_array: Vec<Nat> = Vec::new();
  // loop to create multiple nft
  for i in 0..MAX_NFTS {
    init_nft_with_premint_nft(
      pic,
      origyn_nft.clone(),
      originator.clone(),
      net_principal.clone(),
      nft_owner.clone(),
      i.to_string()
    );

    name_as_nat_array.push(
      crate::client::origyn_nft_reference::client::get_token_id_as_nat(
        pic,
        origyn_nft.clone(),
        net_principal.clone(),
        i.to_string()
      )
    );
  }

  for i in 0..MAX_NFTS {
    let token_id = get_nat_as_token_id_origyn(
      pic,
      origyn_nft.clone(),
      net_principal.clone(),
      name_as_nat_array[i].clone()
    );

    assert_eq!(token_id, i.to_string());
  }
}

#[test]
fn test_big_get_nat_as_token_id_origyn() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner, nft_buyer },
  } = env;

  let nat_parameter = Nat::from(
    BigUint::from_str(
      "123_347_871_499_138_686_881_016_865_267_295_129_288_626_024_588_281_677_846_900_188_455_186_348_550_615_242_248_356_314_349_971_083_712_408_653_985_837_307_580_396_392_350_832_812_622_768_000_317_462_944_092_094_458_992_375_874_361_796_731_317_071_328_751_035_729_572_728_875_613_770_675_780_451_719_821_124_865_307_307_765_880_633_200_231_256_407_468_242_506_927_051_729_669_030_840_169_492_736_287_328_107_085_711_221_315_476_769_677_548_793_880_060_605_475_118_706_099_330_660_125_166_173_513_974_498_904_321_520_247_337_021_982_913_851_871_037_537_464_143_246_157_821_864_455_709_477_669_367_833_424_255_559_935_407_270_016_931_226_070_074_849_447_113_300_214_953_946_024_902_238_122_990_760_859_161_606_816_181_777_626_357_468_807_631_822_217_399_068_672_149_152_752_906_683_921_229_948_769_004_769_126_446_710_388_658_427_772_764_202_548_140_648_919_324_892_699_744_081_128_739_550_845_960_692_371_666_620_546_691_535_295_464_471_082_362_746_377_280_020_582_658_732_114_531_276_220_382_289_235_097_184_296_425_951_181_356_020_566_032_051_235_317_753_061_231_688_525_583_236_219_064_685_341_902_311_106_650_828_572_820_427_760_375_599_905_084_544_875_726_629_175_865_466_176_593_978_846_576_821_163_599_431_747_108_430_396_834_074_480_758_208_203_520_061_358_760_246_502_125_791_577_588_958_618_033_887_411_549_607_749_009_425_033_595_458_708_945_842_909_672_739_165_541_665_761_807_137_454_339_023_919_715_741_273_841_227_663_356_825_314_829_365_431_446_495_598_228_971_909_372_889_099_449_966_418_420_367_182_226_561_644_360_577_638_517_123_531_313_378_320_514_311_005_194_688_686_583_212_635_777_738_315_618_304_802_042_118_306_073_732_484_692_818_164_772_970_335_398_717_686_955_544_017_183_573_962_981_043_573_302_948_227_472_979_381_517_392_340_287_150_689_018_275_464_001_050_810_024_972_422_811_522_759_394_063_243_789_273_888_102_105_848_650_469_842_002_937_808_769_825_796_395_095_552_101_296_284_867_127_966_781_008_684_079_803_814_085_822_423_096_126_873_390_379_190_864_563_046_013_600_100_313_944_979_079_293_762_486_456_727_720_193_522_056_397_599_767_658_881_636_639_751_867_011_580_592_431_825_361_503_228_580_875_426_754_552_582_968_886_555_467_212_170_901_118_330_190_719_970_397_350_914_771_604_983_785_533_345_068_928_109_890_349_563_952_123_347_871_499_138_686_881_016_865_267_295_129_288_626_024_588_281_677_846_900_188_455_186_348_550_615_242_248_356_314_349_971_083_712_408_653_985_837_307_580_396_392_350_832_812_622_768_000_317_462_944_092_094_458_992_375_874_361_796_731_317_071_328_751_035_729_572_728_875_613_770_675_780_451_719_821_124_865_307_307_765_880_633_200_231_256_407_468_242_506_927_051_729_669_030_840_169_492_736_287_328_107_085_711_221_315_476_769_677_548_793_880_060_605_475_118_706_099_330_660_125_166_173_513_974_498_904_321_520_247_337_021_982_913_851_871_037_537_464_143_246_157_821_864_455_709_477_669_367_833_424_255_559_935_407_270_016_931_226_070_074_849_447_113_300_214_953_946_024_902_238_122_990_760_859_161_606_816_181_777_626_357_468_807_631_822_217_399_068_672_149_152_752_906_683_921_229_948_769_004_769_126_446_710_388_658_427_772_764_202_548_140_648_919_324_892_699_744_081_128_739_550_845_960_692_371_666_620_546_691_535_295_464_471_082_362_746_377_280_020_582_658_732_114_531_276_220_382_289_235_097_184_296_425_951_181_356_020_566_032_051_235_317_753_061_231_688_525_583_236_219_064_685_341_902_311_106_650_828_572_820_427_760_375_599_905_084_544_875_726_629_175_865_466_176_593_978_846_576_821_163_599_431_747_108_430_396_834_074_480_758_208_203_520_061_358_760_246_502_125_791_577_588_958_618_033_887_411_549_607_749_009_425_033_595_458_708_945_842_909_672_739_165_541_665_761_807_137_454_339_023_919_715_741_273_841_227_663_356_825_314_829_365_431_446_495_598_228_971_909_372_889_099_449_966_418_420_367_182_226_561_644_360_577_638_517_123_531_313_378_320_514_311_005_194_688_686_583_212_635_777_738_315_618_304_802_042_118_306_073_732_484_692_818_164_772_970_335_398_717_686_955_544_017_183_573_962_981_043_573_302_948_227_472_979_381_517_392_340_287_150_689_018_275_464_001_050_810_024_972_422_811_522_759_394_063_243_789_273_888_102_105_848_650_469_842_002_937_808_769_825_796_395_095_552_101_296_284_867_127_966_781_008_684_079_803_814_085_822_423_096_126_873_390_379_190_864_563_046_013_600_100_313_944_979_079_293_762_486_456_727_720_193_522_056_397_599_767_658_881_636_639_751_867_011_580_592_431_825_361_503_228_580_875_426_754_552_582_968_886_555_467_212_170_901_118_330_190_719_970_397_350_914_771_604_983_785_533_345_068_928_109_890_349_563_952_123_347_871_499_138_686_881_016_865_267_295_129_288_626_024_588_281_677_846_900_188_455_186_348_550_615_242_248_356_314_349_971_083_712_408_653_985_837_307_580_396_392_350_832_812_622_768_000_317_462_944_092_094_458_992_375_874_361_796_731_317_071_328_751_035_729_572_728_875_613_770_675_780_451_719_821_124_865_307_307_765_880_633_200_231_256_407_468_242_506_927_051_729_669_030_840_169_492_736_287_328_107_085_711_221_315_476_769_677_548_793_880_060_605_475_118_706_099_330_660_125_166_173_513_974_498_904_321_520_247_337_021_982_913_851_871_037_537_464_143_246_157_821_864_455_709_477_669_367_833_424_255_559_935_407_270_016_931_226_070_074_849_447_113_300_214_953_946_024_902_238_122_990_760_859_161_606_816_181_777_626_357_468_807_631_822_217_399_068_672_149_152_752_906_683_921_229_948_769_004_769_126_446_710_388_658_427_772_764_202_548_140_648_919_324_892_699_744_081_128_739_550_845_960_692_371_666_620_546_691_535_295_464_471_082_362_746_377_280_020_582_658_732_114_531_276_220_382_289_235_097_184_296_425_951_181_356_020_566_032_051_235_317_753_061_231_688_525_583_236_219_064_685_341_902_311_106_650_828_572_820_427_760_375_599_905_084_544_875_726_629_175_865_466_176_593_978_846_576_821_163_599_431_747_108_430_396_834_074_480_758_208_203_520_061_358_760_246_502_125_791_577_588_958_618_033_887_411_549_607_749_009_425_033_595_458_708_945_842_909_672_739_165_541_665_761_807_137_454_339_023_919_715_741_273_841_227_663_356_825_314_829_365_431_446_495_598_228_971_909_372_889_099_449_966_418_420_367_182_226_561_644_360_577_638_517_123_531_313_378_320_514_311_005_194_688_686_583_212_635_777_738_315_618_304_802_042_118_306_073_732_484_692_818_164_772_970_335_398_717_686_955_544_017_183_573_962_981_043_573_302_948_227_472_979_381_517_392_340_287_150_689_018_275_464_001_050_810_024_972_422_811_522_759_394_063_243_789_273_888_102_105_848_650_469_842_002_937_808_769_825_796_395_095_552_101_296_284_867_127_966_781_008_684_079_803_814_085_822_423_096_126_873_390_379_190_864_563_046_013_600_100_313_944_979_079_293_762_486_456_727_720_193_522_056_397_599_767_658_881_636_639_751_867_011_580_592_431_825_361_503_228_580_875_426_754_552_582_968_886_555_467_212_170_901_118_330_190_719_970_397_350_914_771_604_983_785_533_345_068_928_109_890_349_563_952"
    ).unwrap()
  );

  println!("nat_parameter: {:?}", nat_parameter);

  let token_id = get_nat_as_token_id_origyn(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    nat_parameter
  );
  assert_eq!(token_id, "not found");
}

#[test]
fn test_market_transfer_nft_origyn_timeout() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner, nft_buyer },
  } = env;

  let MAX_NFTS = 1;
  // loop to create multiple nft
  for i in 0..MAX_NFTS {
    init_nft_with_premint_nft(
      pic,
      origyn_nft.clone(),
      originator.clone(),
      net_principal.clone(),
      nft_owner.clone(),
      i.to_string()
    );
  }

  pic.set_time(SystemTime::now());

  let ret: origyn_nft_reference::origyn_nft_reference_canister::MarketTransferResult = market_transfer_nft_origyn_client(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    market_transfer_nft_origynArgs {
      token_id: '0'.to_string(),
      sales_config: SalesConfig {
        broker_id: None,
        pricing: PricingConfigShared::Ask(
          Some(
            vec![
              AskFeature::StartPrice(Nat::from(100 as u32)) // AskFeature::Ending(EndingType::Timeout(Nat::from(1000 as u64)))
            ]
          )
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

  println!("sale_id: {:?}", sale_id);
  println!("get_time: {:?}", pic.get_time());

  let sale_info_status = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::Status(sale_id.clone())
  );
  println!("sale_info_status: {:?}", sale_info_status);

  pic.advance_time(std::time::Duration::from_secs(120));
  pic.tick();
  pic.advance_time(std::time::Duration::from_secs(120));
  pic.tick();
  pic.advance_time(std::time::Duration::from_secs(120));
  pic.tick();

  crate::utils::tick_n_blocks(pic, 100);

  println!("get_time: {:?}", pic.get_time());

  let sale_info_status_2 = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::Status(sale_id.clone())
  );
  println!("sale_info_status_2: {:?}", sale_info_status_2);

  let sale_info_status_3 = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::Status(sale_id.clone())
  );
  println!("sale_info_status_3: {:?}", sale_info_status_3);
}

#[test]
fn test_market_transfer_nft_origyn_timeout_precise() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner, nft_buyer },
  } = env;

  let MAX_NFTS = 1;
  // loop to create multiple nft
  for i in 0..MAX_NFTS {
    init_nft_with_premint_nft(
      pic,
      origyn_nft.clone(),
      originator.clone(),
      net_principal.clone(),
      nft_owner.clone(),
      i.to_string()
    );
  }

  pic.set_time(SystemTime::now());

  let ret: origyn_nft_reference::origyn_nft_reference_canister::MarketTransferResult = market_transfer_nft_origyn_client(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    market_transfer_nft_origynArgs {
      token_id: '0'.to_string(),
      sales_config: SalesConfig {
        broker_id: None,
        pricing: PricingConfigShared::Ask(
          Some(
            vec![
              AskFeature::StartPrice(Nat::from(100 as u32)),
              AskFeature::Ending(
                EndingType::Timeout(
                  Nat::from(NANOS_PER_MILLISECOND * ((MINUTE_IN_MS * 100) as u64))
                )
              )
            ]
          )
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

  println!("sale_id: {:?}", sale_id);
  println!("get_time: {:?}", pic.get_time());

  let sale_info_status = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::Status(sale_id.clone())
  );
  println!("sale_info_status: {:?}", sale_info_status);

  pic.advance_time(std::time::Duration::from_secs(60 * 99));
  pic.tick();

  crate::utils::tick_n_blocks(pic, 100);

  println!("get_time: {:?}", pic.get_time());

  let sale_info_status_2 = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::Status(sale_id.clone())
  );
  println!("sale_info_status_2: {:?}", sale_info_status_2);

  pic.advance_time(std::time::Duration::from_secs(57));
  pic.tick();

  let sale_info_status_3 = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::Status(sale_id.clone())
  );
  println!("sale_info_status_3: {:?}", sale_info_status_3);
}

#[test]
fn test_market_transfer_nft_origyn_timeout_fundback() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner, nft_buyer },
  } = env;

  let MAX_NFTS = 1;
  // loop to create multiple nft
  for i in 0..MAX_NFTS {
    init_nft_with_premint_nft(
      pic,
      origyn_nft.clone(),
      originator.clone(),
      net_principal.clone(),
      nft_owner.clone(),
      i.to_string()
    );
  }

  pic.set_time(SystemTime::now());

  let ret: origyn_nft_reference::origyn_nft_reference_canister::MarketTransferResult = market_transfer_nft_origyn_client(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    market_transfer_nft_origynArgs {
      token_id: '0'.to_string(),
      sales_config: SalesConfig {
        broker_id: None,
        pricing: PricingConfigShared::Ask(
          Some(
            vec![
              AskFeature::StartPrice(Nat::from(100 as u32)),
              AskFeature::Ending(
                EndingType::Timeout(
                  Nat::from(NANOS_PER_MILLISECOND * ((MINUTE_IN_MS * 100) as u64))
                )
              )
            ]
          )
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

  println!("sale_id: {:?}", sale_id);
  println!("get_time: {:?}", pic.get_time());

  let sale_info_status = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::Status(sale_id.clone())
  );
  println!("sale_info_status: {:?}", sale_info_status);

  pic.advance_time(std::time::Duration::from_secs(60 * 99));
  pic.tick();

  crate::utils::tick_n_blocks(pic, 100);

  println!("get_time: {:?}", pic.get_time());

  let sale_info_status_2 = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::Status(sale_id.clone())
  );
  println!("sale_info_status_2: {:?}", sale_info_status_2);

  pic.advance_time(std::time::Duration::from_secs(57));
  pic.tick();

  let sale_info_status_3 = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::Status(sale_id.clone())
  );
  println!("sale_info_status_3: {:?}", sale_info_status_3);
}

#[test]
fn test_update_metadata_node() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner, nft_buyer },
  } = env;

  let MAX_NFTS = 1;
  // loop to create multiple nft
  for i in 0..MAX_NFTS {
    init_nft_with_premint_nft(
      pic,
      origyn_nft.clone(),
      originator.clone(),
      net_principal.clone(),
      nft_owner.clone(),
      i.to_string()
    );
  }

  pic.set_time(SystemTime::now());

  let node_principal = net_principal.clone();

  let nft_metadata = nft_origyn(pic, origyn_nft.clone(), node_principal.clone(), '0'.to_string());
  // println!("nft_metadata: {:?}", nft_metadata);

  let ret: crate::client::origyn_nft_reference::update_metadata_node::Response = update_metadata_node(
    pic,
    origyn_nft.clone(),
    node_principal.clone(),
    crate::client::origyn_nft_reference::update_metadata_node::Args {
      token_id: '0'.to_string(),
      value: Box::new(CandyShared::Text('0'.to_string())),
      field_id: '0'.to_string(),
      _system: true,
    }
  );
  println!("ret: {:?}", ret);

  match ret {
    crate::client::origyn_nft_reference::update_metadata_node::Response::Ok(val) => {
      panic!("Expected update_metadata_node to return error, but it didn't");
    }
    crate::client::origyn_nft_reference::update_metadata_node::Response::Err(err) => {
      if err.number != 6 {
        panic!("Expected update_metadata_node to return error, but it didn't");
      }
    }
  }

  let ret2: crate::client::origyn_nft_reference::update_metadata_node::Response = update_metadata_node(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    crate::client::origyn_nft_reference::update_metadata_node::Args {
      token_id: '0'.to_string(),
      value: Box::new(CandyShared::Text('0'.to_string())),
      field_id: '0'.to_string(),
      _system: true,
    }
  );
  println!("ret2 should return error: {:?}", ret2);

  match ret2 {
    crate::client::origyn_nft_reference::update_metadata_node::Response::Ok(val) => {
      panic!("Expected update_metadata_node to return error, but it didn't");
    }
    crate::client::origyn_nft_reference::update_metadata_node::Response::Err(err) => {
      if err.number != 6 {
        panic!("Expected update_metadata_node to return error, but it didn't");
      }
    }
  }

  let nft_metadata_2 = nft_origyn(pic, origyn_nft.clone(), node_principal.clone(), '0'.to_string());
  // println!("nft_metadata_2: {:?}", nft_metadata_2);

  let ret2: crate::client::origyn_nft_reference::update_metadata_node::Response = update_metadata_node(
    pic,
    origyn_nft.clone(),
    node_principal.clone(),
    crate::client::origyn_nft_reference::update_metadata_node::Args {
      token_id: '0'.to_string(),
      value: Box::new(CandyShared::Bool(false)),
      field_id: "com.origyn.escrow_node".to_string(),
      _system: true,
    }
  );
  println!("ret2: {:?}", ret2);

  let nft_metadata_3 = nft_origyn(pic, origyn_nft.clone(), node_principal.clone(), '0'.to_string());
  println!("nft_metadata_3: {:?}", nft_metadata_3);
}

#[test]
fn test_market_transfer_nft_origyn_fee_account_bid_full_fee_account_fixed() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner, nft_buyer },
  } = env;

  let MAX_NFTS = 1;

  let fee_account = net_principal.clone();
  let ogy_token_spec = TokenSpec::Ic(IcTokenSpec {
    id: None,
    fee: Some(Nat::from(200_000 as u32)),
    decimals: Nat::from(8 as u32),
    canister: ogy_ledger,
    standard: IcTokenSpecStandard::Ledger,
    symbol: "OGY".to_string(),
  });

  // loop to create multiple nft
  for i in 0..MAX_NFTS {
    init_nft_with_premint_nft(
      pic,
      origyn_nft.clone(),
      originator.clone(),
      net_principal.clone(),
      nft_owner.clone(),
      i.to_string()
    );
  }

  pic.set_time(SystemTime::now());

  let res_fee_info = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::FeeDepositInfo(
      Some(Account::Account {
        owner: nft_owner.clone(),
        sub_account: None,
      })
    )
  );

  let fee_info = match res_fee_info {
    SaleInfoResult::Ok(sale_return) => {
      match sale_return {
        SaleInfoResponse::FeeDepositInfo(fee_deposit_info) => {
          println!("fee_deposit_info {:?}", fee_deposit_info);
          Icrc1Account {
            owner: fee_deposit_info.account.principal,
            subaccount: Some(
              fee_deposit_info.account.sub_account
                .into_vec()
                .try_into()
                .expect("slice with incorrect length")
            ),
          }
        }
        _ => {
          panic!("fee_info failed: {:?}", sale_return);
        }
      }
    }
    SaleInfoResult::Err(err) => {
      panic!("fee_info failed: {:?}", err);
    }
  };

  let fee_balance_initial = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    fee_info
  );

  let approve_res: icrc1_icrc2_token::icrc2_approve::Response = icrc1_icrc2_token::client::approve(
    pic,
    nft_owner.clone(),
    ogy_ledger.clone(),
    origyn_nft.clone(),
    None,
    Nat::from(100_000_000_000 as u64) + Nat::from(200_000 as u32)
  );

  match approve_res {
    icrc1_icrc2_token::icrc2_approve::Response::Ok(_) => (),
    icrc1_icrc2_token::icrc2_approve::Response::Err(err) => {
      panic!("approve failed: {:?}", err);
    }
  }

  let deposit_res = sale_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    ManageSaleRequest::FeeDeposit(FeeDepositRequest {
      token: ogy_token_spec.clone(),
      account: Account::Account {
        owner: nft_owner.clone(),
        sub_account: None,
      },
      amount: Nat::from(100_000_000_000 as u64),
    })
  );

  let owner_ogy_balance_initial = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    Icrc1Account {
      owner: nft_owner,
      subaccount: None,
    }
  );

  let buyer_ogy_balance_initial = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    Icrc1Account {
      owner: nft_buyer,
      subaccount: None,
    }
  );

  let ret: origyn_nft_reference::origyn_nft_reference_canister::MarketTransferResult = market_transfer_nft_origyn_client(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    market_transfer_nft_origynArgs {
      token_id: '0'.to_string(),
      sales_config: SalesConfig {
        broker_id: None,
        pricing: PricingConfigShared::Ask(
          Some(
            vec![
              AskFeature::StartPrice(Nat::from(100_000_000_000 as u64)),
              AskFeature::BuyNow(Nat::from(100_000_000_000 as u64)),
              AskFeature::FeeSchema("com.origyn.royalties.fixed".to_string()),
              AskFeature::FeeAccounts(
                vec![
                  "com.origyn.royalty.network".to_string(),
                  "com.origyn.royalty.node".to_string(),
                  "com.origyn.royalty.broker".to_string(),
                  "com.origyn.royalty.originator".to_string(),
                  "com.origyn.royalty.custom".to_string()
                ]
              )
            ]
          )
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

  let fee_balance_before = icrc1_icrc2_token::client::balance_of(pic, ogy_ledger.clone(), fee_info);

  let deposit_info = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::EscrowInfo(EscrowReceipt {
      token: ogy_token_spec.clone(),
      token_id: "0".to_string(),
      seller: Account::Account {
        owner: nft_owner.clone(),
        sub_account: None,
      },
      buyer: Account::Account {
        owner: nft_buyer.clone(),
        sub_account: None,
      },
      amount: Nat::from(100_000_000_000 as u64),
    })
  );

  let deposit_account_info = match deposit_info {
    SaleInfoResult::Ok(sale_return) =>
      match sale_return {
        SaleInfoResponse::EscrowInfo(escrow_info) => {
          println!("escrow_info {:?}", escrow_info);
          escrow_info
        }
        _ => {
          panic!("deposit_info failed: {:?}", sale_return);
        }
      }
    SaleInfoResult::Err(err) => {
      panic!("deposit_info failed: {:?}", err);
    }
  };

  let transfer_ret = icrc1_icrc2_token::client::transfer(
    pic,
    nft_buyer.clone(),
    ogy_ledger.clone(),
    None,
    icrc_ledger_types::icrc1::account::Account {
      owner: deposit_account_info.account.principal.clone(),
      subaccount: Some(
        deposit_account_info.account.sub_account
          .into_vec()
          .try_into()
          .expect("slice with incorrect length")
      ),
    },
    Nat::from(100_000_000_000 as u64)
  );

  let bid_ret = sale_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_buyer.clone(),
    ManageSaleRequest::Bid(BidRequest {
      config: None,
      escrow_record: EscrowRecord {
        token: ogy_token_spec.clone(),
        token_id: "0".to_string(),
        seller: Account::Account {
          owner: nft_owner.clone(),
          sub_account: None,
        },
        lock_to_date: None,
        buyer: Account::Account {
          owner: nft_buyer.clone(),
          sub_account: None,
        },
        amount: Nat::from(100_000_000_000 as u64),
        sale_id: Some(sale_id.clone()),
        account_hash: None,
      },
    })
  );

  let token_id_as_nat = crate::client::origyn_nft_reference::client::get_token_id_as_nat(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    "0".to_string()
  );

  let owner_of = crate::client::origyn_nft_reference::client::icrc7_owner_of(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    vec![token_id_as_nat.clone()]
  );

  pic.tick();
  pic.tick();
  pic.tick();
  pic.tick();
  pic.tick();

  let fee_balance_after = icrc1_icrc2_token::client::balance_of(pic, ogy_ledger.clone(), fee_info);

  let buyer_ogy_balance_after = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    Icrc1Account {
      owner: nft_buyer,
      subaccount: None,
    }
  );

  let owner_ogy_balance_after = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    Icrc1Account {
      owner: nft_owner,
      subaccount: None,
    }
  );

  // paying for, with each at 1_000_000
  // "com.origyn.royalty.network".to_string(),
  // "com.origyn.royalty.node".to_string(),
  // "com.origyn.royalty.broker".to_string(),
  // "com.origyn.royalty.originator".to_string(),
  // "com.origyn.royalty.custom".to_string()
  // but no broker set, so broker fee is 0 and not paid
  // so 4_000_000 should be paid
  assert_eq!(
    fee_balance_after,
    fee_balance_before - Nat::from(4 as u32) * Nat::from(1_000_000 as u32)
  );

  assert_eq!(
    buyer_ogy_balance_after,
    buyer_ogy_balance_initial - Nat::from(100_000_000_000 as u64) - Nat::from(200_000 as u64)
  );

  assert_eq!(
    owner_ogy_balance_after,
    owner_ogy_balance_initial +
      Nat::from(100_000_000_000 as u64) -
      Nat::from(2 as u32) * Nat::from(200_000 as u32)
  );

  assert_eq!(
    owner_of,
    vec![
      Some(Account3 {
        owner: nft_buyer.clone(),
        subaccount: None,
      })
    ]
  );
}

#[test]
fn test_market_transfer_nft_origyn_fee_account_bid_partial_fee_account_fixed() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner, nft_buyer },
  } = env;

  let MAX_NFTS = 1;

  let fee_account = net_principal.clone();
  let ogy_token_spec = TokenSpec::Ic(IcTokenSpec {
    id: None,
    fee: Some(Nat::from(200_000 as u32)),
    decimals: Nat::from(8 as u32),
    canister: ogy_ledger,
    standard: IcTokenSpecStandard::Ledger,
    symbol: "OGY".to_string(),
  });

  // loop to create multiple nft
  for i in 0..MAX_NFTS {
    init_nft_with_premint_nft(
      pic,
      origyn_nft.clone(),
      originator.clone(),
      net_principal.clone(),
      nft_owner.clone(),
      i.to_string()
    );
  }

  pic.set_time(SystemTime::now());

  let res_fee_info = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::FeeDepositInfo(
      Some(Account::Account {
        owner: nft_owner.clone(),
        sub_account: None,
      })
    )
  );

  let fee_info = match res_fee_info {
    SaleInfoResult::Ok(sale_return) => {
      match sale_return {
        SaleInfoResponse::FeeDepositInfo(fee_deposit_info) => {
          println!("fee_deposit_info {:?}", fee_deposit_info);
          Icrc1Account {
            owner: fee_deposit_info.account.principal,
            subaccount: Some(
              fee_deposit_info.account.sub_account
                .into_vec()
                .try_into()
                .expect("slice with incorrect length")
            ),
          }
        }
        _ => {
          panic!("fee_info failed: {:?}", sale_return);
        }
      }
    }
    SaleInfoResult::Err(err) => {
      panic!("fee_info failed: {:?}", err);
    }
  };

  let fee_balance_initial = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    fee_info
  );

  let approve_res: icrc1_icrc2_token::icrc2_approve::Response = icrc1_icrc2_token::client::approve(
    pic,
    nft_owner.clone(),
    ogy_ledger.clone(),
    origyn_nft.clone(),
    None,
    Nat::from(100_000_000_000 as u64) + Nat::from(200_000 as u32)
  );

  match approve_res {
    icrc1_icrc2_token::icrc2_approve::Response::Ok(_) => (),
    icrc1_icrc2_token::icrc2_approve::Response::Err(err) => {
      panic!("approve failed: {:?}", err);
    }
  }

  let deposit_res = sale_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    ManageSaleRequest::FeeDeposit(FeeDepositRequest {
      token: ogy_token_spec.clone(),
      account: Account::Account {
        owner: nft_owner.clone(),
        sub_account: None,
      },
      amount: Nat::from(100_000_000_000 as u64),
    })
  );

  let owner_ogy_balance_initial = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    Icrc1Account {
      owner: nft_owner,
      subaccount: None,
    }
  );

  let buyer_ogy_balance_initial = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    Icrc1Account {
      owner: nft_buyer,
      subaccount: None,
    }
  );

  let ret: origyn_nft_reference::origyn_nft_reference_canister::MarketTransferResult = market_transfer_nft_origyn_client(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    market_transfer_nft_origynArgs {
      token_id: '0'.to_string(),
      sales_config: SalesConfig {
        broker_id: None,
        pricing: PricingConfigShared::Ask(
          Some(
            vec![
              AskFeature::StartPrice(Nat::from(100_000_000_000 as u64)),
              AskFeature::BuyNow(Nat::from(100_000_000_000 as u64)),
              AskFeature::FeeSchema("com.origyn.royalties.fixed".to_string()),
              AskFeature::FeeAccounts(
                vec![
                  "com.origyn.royalty.network".to_string(),
                  "com.origyn.royalty.node".to_string()
                ]
              )
            ]
          )
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

  let fee_balance_before = icrc1_icrc2_token::client::balance_of(pic, ogy_ledger.clone(), fee_info);

  let deposit_info = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::EscrowInfo(EscrowReceipt {
      token: ogy_token_spec.clone(),
      token_id: "0".to_string(),
      seller: Account::Account {
        owner: nft_owner.clone(),
        sub_account: None,
      },
      buyer: Account::Account {
        owner: nft_buyer.clone(),
        sub_account: None,
      },
      amount: Nat::from(100_000_000_000 as u64),
    })
  );

  let deposit_account_info = match deposit_info {
    SaleInfoResult::Ok(sale_return) =>
      match sale_return {
        SaleInfoResponse::EscrowInfo(escrow_info) => {
          println!("escrow_info {:?}", escrow_info);
          escrow_info
        }
        _ => {
          panic!("deposit_info failed: {:?}", sale_return);
        }
      }
    SaleInfoResult::Err(err) => {
      panic!("deposit_info failed: {:?}", err);
    }
  };

  let transfer_ret = icrc1_icrc2_token::client::transfer(
    pic,
    nft_buyer.clone(),
    ogy_ledger.clone(),
    None,
    icrc_ledger_types::icrc1::account::Account {
      owner: deposit_account_info.account.principal.clone(),
      subaccount: Some(
        deposit_account_info.account.sub_account
          .into_vec()
          .try_into()
          .expect("slice with incorrect length")
      ),
    },
    Nat::from(100_000_000_000 as u64)
  );

  let bid_ret = sale_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_buyer.clone(),
    ManageSaleRequest::Bid(BidRequest {
      config: None,
      escrow_record: EscrowRecord {
        token: ogy_token_spec.clone(),
        token_id: "0".to_string(),
        seller: Account::Account {
          owner: nft_owner.clone(),
          sub_account: None,
        },
        lock_to_date: None,
        buyer: Account::Account {
          owner: nft_buyer.clone(),
          sub_account: None,
        },
        amount: Nat::from(100_000_000_000 as u64),
        sale_id: Some(sale_id.clone()),
        account_hash: None,
      },
    })
  );

  let token_id_as_nat = crate::client::origyn_nft_reference::client::get_token_id_as_nat(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    "0".to_string()
  );

  let owner_of = crate::client::origyn_nft_reference::client::icrc7_owner_of(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    vec![token_id_as_nat.clone()]
  );

  pic.tick();
  pic.tick();
  pic.tick();
  pic.tick();
  pic.tick();

  let fee_balance_after = icrc1_icrc2_token::client::balance_of(pic, ogy_ledger.clone(), fee_info);

  let buyer_ogy_balance_after = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    Icrc1Account {
      owner: nft_buyer,
      subaccount: None,
    }
  );

  let owner_ogy_balance_after = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    Icrc1Account {
      owner: nft_owner,
      subaccount: None,
    }
  );

  // paying for, with each at 1_000_000
  // "com.origyn.royalty.network".to_string(),
  // "com.origyn.royalty.node".to_string(),
  // "com.origyn.royalty.broker".to_string(),
  // "com.origyn.royalty.originator".to_string(),
  // "com.origyn.royalty.custom".to_string()
  // but no broker set, so broker fee is 0 and not paid
  // so 4_000_000 should be paid
  assert_eq!(
    fee_balance_after,
    fee_balance_before - Nat::from(2 as u32) * Nat::from(1_000_000 as u32)
  );

  assert_eq!(
    buyer_ogy_balance_after,
    buyer_ogy_balance_initial - Nat::from(100_000_000_000 as u64) - Nat::from(200_000 as u64)
  );

  assert_eq!(
    owner_ogy_balance_after,
    owner_ogy_balance_initial +
      Nat::from(100_000_000_000 as u64) -
      Nat::from(2 as u32) * Nat::from(200_000 as u32) -
      Nat::from(2 as u32) * Nat::from(1_000_000 as u32)
  );

  assert_eq!(
    owner_of,
    vec![
      Some(Account3 {
        owner: nft_buyer.clone(),
        subaccount: None,
      })
    ]
  );
}

#[test]
fn test_market_transfer_nft_origyn_fee_account_bid_full_fee_account_pourcentage() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner, nft_buyer },
  } = env;

  let MAX_NFTS = 1;

  let fee_account = net_principal.clone();
  let ogy_token_spec = TokenSpec::Ic(IcTokenSpec {
    id: None,
    fee: Some(Nat::from(200_000 as u32)),
    decimals: Nat::from(8 as u32),
    canister: ogy_ledger,
    standard: IcTokenSpecStandard::Ledger,
    symbol: "OGY".to_string(),
  });

  // loop to create multiple nft
  for i in 0..MAX_NFTS {
    init_nft_with_premint_nft(
      pic,
      origyn_nft.clone(),
      originator.clone(),
      net_principal.clone(),
      nft_owner.clone(),
      i.to_string()
    );
  }

  pic.set_time(SystemTime::now());

  let res_fee_info = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::FeeDepositInfo(
      Some(Account::Account {
        owner: nft_owner.clone(),
        sub_account: None,
      })
    )
  );

  let fee_info = match res_fee_info {
    SaleInfoResult::Ok(sale_return) => {
      match sale_return {
        SaleInfoResponse::FeeDepositInfo(fee_deposit_info) => {
          println!("fee_deposit_info {:?}", fee_deposit_info);
          Icrc1Account {
            owner: fee_deposit_info.account.principal,
            subaccount: Some(
              fee_deposit_info.account.sub_account
                .into_vec()
                .try_into()
                .expect("slice with incorrect length")
            ),
          }
        }
        _ => {
          panic!("fee_info failed: {:?}", sale_return);
        }
      }
    }
    SaleInfoResult::Err(err) => {
      panic!("fee_info failed: {:?}", err);
    }
  };

  let fee_balance_initial = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    fee_info
  );

  let approve_res: icrc1_icrc2_token::icrc2_approve::Response = icrc1_icrc2_token::client::approve(
    pic,
    nft_owner.clone(),
    ogy_ledger.clone(),
    origyn_nft.clone(),
    None,
    Nat::from(100_000_000_000 as u64) + Nat::from(200_000 as u32)
  );

  match approve_res {
    icrc1_icrc2_token::icrc2_approve::Response::Ok(_) => (),
    icrc1_icrc2_token::icrc2_approve::Response::Err(err) => {
      panic!("approve failed: {:?}", err);
    }
  }

  let deposit_res = sale_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    ManageSaleRequest::FeeDeposit(FeeDepositRequest {
      token: ogy_token_spec.clone(),
      account: Account::Account {
        owner: nft_owner.clone(),
        sub_account: None,
      },
      amount: Nat::from(100_000_000_000 as u64),
    })
  );

  let owner_ogy_balance_initial = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    Icrc1Account {
      owner: nft_owner,
      subaccount: None,
    }
  );

  let buyer_ogy_balance_initial = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    Icrc1Account {
      owner: nft_buyer,
      subaccount: None,
    }
  );

  let ret: origyn_nft_reference::origyn_nft_reference_canister::MarketTransferResult = market_transfer_nft_origyn_client(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    market_transfer_nft_origynArgs {
      token_id: '0'.to_string(),
      sales_config: SalesConfig {
        broker_id: None,
        pricing: PricingConfigShared::Ask(
          Some(
            vec![
              AskFeature::StartPrice(Nat::from(100_000_000_000 as u64)),
              AskFeature::BuyNow(Nat::from(100_000_000_000 as u64))
            ]
          )
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

  let fee_balance_before = icrc1_icrc2_token::client::balance_of(pic, ogy_ledger.clone(), fee_info);

  let deposit_info = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::EscrowInfo(EscrowReceipt {
      token: ogy_token_spec.clone(),
      token_id: "0".to_string(),
      seller: Account::Account {
        owner: nft_owner.clone(),
        sub_account: None,
      },
      buyer: Account::Account {
        owner: nft_buyer.clone(),
        sub_account: None,
      },
      amount: Nat::from(100_000_000_000 as u64),
    })
  );

  let deposit_account_info = match deposit_info {
    SaleInfoResult::Ok(sale_return) =>
      match sale_return {
        SaleInfoResponse::EscrowInfo(escrow_info) => {
          println!("escrow_info {:?}", escrow_info);
          escrow_info
        }
        _ => {
          panic!("deposit_info failed: {:?}", sale_return);
        }
      }
    SaleInfoResult::Err(err) => {
      panic!("deposit_info failed: {:?}", err);
    }
  };

  let transfer_ret = icrc1_icrc2_token::client::transfer(
    pic,
    nft_buyer.clone(),
    ogy_ledger.clone(),
    None,
    icrc_ledger_types::icrc1::account::Account {
      owner: deposit_account_info.account.principal.clone(),
      subaccount: Some(
        deposit_account_info.account.sub_account
          .into_vec()
          .try_into()
          .expect("slice with incorrect length")
      ),
    },
    Nat::from(100_000_000_000 as u64)
  );

  let bid_ret = sale_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_buyer.clone(),
    ManageSaleRequest::Bid(BidRequest {
      config: None,
      escrow_record: EscrowRecord {
        token: ogy_token_spec.clone(),
        token_id: "0".to_string(),
        seller: Account::Account {
          owner: nft_owner.clone(),
          sub_account: None,
        },
        lock_to_date: None,
        buyer: Account::Account {
          owner: nft_buyer.clone(),
          sub_account: None,
        },
        amount: Nat::from(100_000_000_000 as u64),
        sale_id: Some(sale_id.clone()),
        account_hash: None,
      },
    })
  );

  let token_id_as_nat = crate::client::origyn_nft_reference::client::get_token_id_as_nat(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    "0".to_string()
  );

  let owner_of = crate::client::origyn_nft_reference::client::icrc7_owner_of(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    vec![token_id_as_nat.clone()]
  );

  pic.tick();
  pic.tick();
  pic.tick();
  pic.tick();
  pic.tick();

  let fee_balance_after = icrc1_icrc2_token::client::balance_of(pic, ogy_ledger.clone(), fee_info);

  let buyer_ogy_balance_after = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    Icrc1Account {
      owner: nft_buyer,
      subaccount: None,
    }
  );

  let owner_ogy_balance_after = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    Icrc1Account {
      owner: nft_owner,
      subaccount: None,
    }
  );

  // paying for, with each at 1_000_000
  // "com.origyn.royalty.network".to_string(),
  // "com.origyn.royalty.node".to_string(),
  // "com.origyn.royalty.broker".to_string(),
  // "com.origyn.royalty.originator".to_string(),
  // "com.origyn.royalty.custom".to_string()
  // but no broker set, so broker fee is 0 and not paid
  // so 4_000_000 should be paid
  assert_eq!(fee_balance_after, fee_balance_before);

  assert_eq!(
    buyer_ogy_balance_after,
    buyer_ogy_balance_initial - Nat::from(100_000_000_000 as u64) - Nat::from(200_000 as u64)
  );

  assert_eq!(
    owner_ogy_balance_after,
    owner_ogy_balance_initial +
      Nat::from(100_000_000_000 as u64) -
      Nat::from(499_999_000 as u64) - // 0.5% of 100_000_000_000 -> network fee
      // Nat::from(999_998_000 as u32) - // no broker fee
      Nat::from(1_999_996_000 as u32) - // 2% of 100_000_000_000 -> node fee
      Nat::from(2_999_994_000 as u32) - // 3% of 100_000_000_000 -> originator fee
      Nat::from(3_999_992_000 as u32) - // 4% of 100_000_000_000 -> custom fee
      Nat::from(2 as u32) * Nat::from(200_000 as u32) // 200_000 -> fixed fee
  );

  assert_eq!(
    owner_of,
    vec![
      Some(Account3 {
        owner: nft_buyer.clone(),
        subaccount: None,
      })
    ]
  );
}

#[test]
fn test_market_transfer_nft_origyn_fee_account_bid_different_token_full_fee_account_fixed() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner, nft_buyer },
  } = env;

  let MAX_NFTS = 1;

  let fee_account = net_principal.clone();
  let ogy_token_spec = TokenSpec::Ic(IcTokenSpec {
    id: None,
    fee: Some(Nat::from(200_000 as u32)),
    decimals: Nat::from(8 as u32),
    canister: ogy_ledger,
    standard: IcTokenSpecStandard::Ledger,
    symbol: "OGY".to_string(),
  });

  let ldg_token_spec = TokenSpec::Ic(IcTokenSpec {
    id: None,
    fee: Some(Nat::from(200_000 as u32)),
    decimals: Nat::from(8 as u32),
    canister: ldg_ledger,
    standard: IcTokenSpecStandard::Ledger,
    symbol: "LDG".to_string(),
  });

  // loop to create multiple nft
  for i in 0..MAX_NFTS {
    init_nft_with_premint_nft(
      pic,
      origyn_nft.clone(),
      originator.clone(),
      net_principal.clone(),
      nft_owner.clone(),
      i.to_string()
    );
  }

  pic.set_time(SystemTime::now());

  let res_fee_info = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::FeeDepositInfo(
      Some(Account::Account {
        owner: nft_owner.clone(),
        sub_account: None,
      })
    )
  );

  let fee_info = match res_fee_info {
    SaleInfoResult::Ok(sale_return) => {
      match sale_return {
        SaleInfoResponse::FeeDepositInfo(fee_deposit_info) => {
          println!("fee_deposit_info {:?}", fee_deposit_info);
          Icrc1Account {
            owner: fee_deposit_info.account.principal,
            subaccount: Some(
              fee_deposit_info.account.sub_account
                .into_vec()
                .try_into()
                .expect("slice with incorrect length")
            ),
          }
        }
        _ => {
          panic!("fee_info failed: {:?}", sale_return);
        }
      }
    }
    SaleInfoResult::Err(err) => {
      panic!("fee_info failed: {:?}", err);
    }
  };

  let fee_balance_initial = icrc1_icrc2_token::client::balance_of(
    pic,
    ogy_ledger.clone(),
    fee_info
  );

  let approve_res: icrc1_icrc2_token::icrc2_approve::Response = icrc1_icrc2_token::client::approve(
    pic,
    nft_owner.clone(),
    ogy_ledger.clone(),
    origyn_nft.clone(),
    None,
    Nat::from(100_000_000_000 as u64) + Nat::from(200_000 as u32)
  );

  match approve_res {
    icrc1_icrc2_token::icrc2_approve::Response::Ok(_) => (),
    icrc1_icrc2_token::icrc2_approve::Response::Err(err) => {
      panic!("approve failed: {:?}", err);
    }
  }

  let deposit_res = sale_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    ManageSaleRequest::FeeDeposit(FeeDepositRequest {
      token: ogy_token_spec.clone(),
      account: Account::Account {
        owner: nft_owner.clone(),
        sub_account: None,
      },
      amount: Nat::from(100_000_000_000 as u64),
    })
  );

  pic.tick();

  let owner_ldg_balance_initial = icrc1_icrc2_token::client::balance_of(
    pic,
    ldg_ledger.clone(),
    Icrc1Account {
      owner: nft_owner,
      subaccount: None,
    }
  );

  let buyer_ldg_balance_initial = icrc1_icrc2_token::client::balance_of(
    pic,
    ldg_ledger.clone(),
    Icrc1Account {
      owner: nft_buyer,
      subaccount: None,
    }
  );

  let ret: origyn_nft_reference::origyn_nft_reference_canister::MarketTransferResult = market_transfer_nft_origyn_client(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    market_transfer_nft_origynArgs {
      token_id: '0'.to_string(),
      sales_config: SalesConfig {
        broker_id: None,
        pricing: PricingConfigShared::Ask(
          Some(
            vec![
              AskFeature::StartPrice(Nat::from(100_000_000_000 as u64)),
              AskFeature::BuyNow(Nat::from(100_000_000_000 as u64)),
              AskFeature::FeeSchema("com.origyn.royalties.fixed".to_string()),
              AskFeature::Token(ldg_token_spec.clone()),
              AskFeature::FeeAccounts(
                vec![
                  "com.origyn.royalty.network".to_string(),
                  "com.origyn.royalty.node".to_string(),
                  "com.origyn.royalty.broker".to_string(),
                  "com.origyn.royalty.originator".to_string(),
                  "com.origyn.royalty.custom".to_string()
                ]
              )
            ]
          )
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

  let fee_balance_before = icrc1_icrc2_token::client::balance_of(pic, ogy_ledger.clone(), fee_info);

  let deposit_info = sale_info_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_owner.clone(),
    SaleInfoRequest::EscrowInfo(EscrowReceipt {
      token: ldg_token_spec.clone(),
      token_id: "0".to_string(),
      seller: Account::Account {
        owner: nft_owner.clone(),
        sub_account: None,
      },
      buyer: Account::Account {
        owner: nft_buyer.clone(),
        sub_account: None,
      },
      amount: Nat::from(100_000_000_000 as u64),
    })
  );

  let deposit_account_info = match deposit_info {
    SaleInfoResult::Ok(sale_return) =>
      match sale_return {
        SaleInfoResponse::EscrowInfo(escrow_info) => {
          println!("escrow_info {:?}", escrow_info);
          escrow_info
        }
        _ => {
          panic!("deposit_info failed: {:?}", sale_return);
        }
      }
    SaleInfoResult::Err(err) => {
      panic!("deposit_info failed: {:?}", err);
    }
  };

  let transfer_ret = icrc1_icrc2_token::client::transfer(
    pic,
    nft_buyer.clone(),
    ldg_ledger.clone(),
    None,
    icrc_ledger_types::icrc1::account::Account {
      owner: deposit_account_info.account.principal.clone(),
      subaccount: Some(
        deposit_account_info.account.sub_account
          .into_vec()
          .try_into()
          .expect("slice with incorrect length")
      ),
    },
    Nat::from(100_000_000_000 as u64)
  );

  let bid_ret = sale_nft_origyn(
    pic,
    origyn_nft.clone(),
    nft_buyer.clone(),
    ManageSaleRequest::Bid(BidRequest {
      config: None,
      escrow_record: EscrowRecord {
        token: ldg_token_spec.clone(),
        token_id: "0".to_string(),
        seller: Account::Account {
          owner: nft_owner.clone(),
          sub_account: None,
        },
        lock_to_date: None,
        buyer: Account::Account {
          owner: nft_buyer.clone(),
          sub_account: None,
        },
        amount: Nat::from(100_000_000_000 as u64),
        sale_id: Some(sale_id.clone()),
        account_hash: None,
      },
    })
  );

  let token_id_as_nat = crate::client::origyn_nft_reference::client::get_token_id_as_nat(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    "0".to_string()
  );

  let owner_of = crate::client::origyn_nft_reference::client::icrc7_owner_of(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    vec![token_id_as_nat.clone()]
  );

  pic.tick();
  pic.tick();
  pic.tick();
  pic.tick();
  pic.tick();

  let fee_balance_after = icrc1_icrc2_token::client::balance_of(pic, ogy_ledger.clone(), fee_info);

  let buyer_ldg_balance_after = icrc1_icrc2_token::client::balance_of(
    pic,
    ldg_ledger.clone(),
    Icrc1Account {
      owner: nft_buyer,
      subaccount: None,
    }
  );

  let owner_ldg_balance_after = icrc1_icrc2_token::client::balance_of(
    pic,
    ldg_ledger.clone(),
    Icrc1Account {
      owner: nft_owner,
      subaccount: None,
    }
  );

  // paying for, with each at 1_000_000
  // "com.origyn.royalty.network".to_string(),
  // "com.origyn.royalty.node".to_string(),
  // "com.origyn.royalty.broker".to_string(),
  // "com.origyn.royalty.originator".to_string(),
  // "com.origyn.royalty.custom".to_string()
  // but no broker set, so broker fee is 0 and not paid
  // so 4_000_000 should be paid
  assert_eq!(
    fee_balance_after,
    fee_balance_before - Nat::from(4 as u32) * Nat::from(1_000_000 as u32)
  );

  assert_eq!(
    buyer_ldg_balance_after,
    buyer_ldg_balance_initial - Nat::from(100_000_000_000 as u64) - Nat::from(200_000 as u64)
  );

  assert_eq!(
    owner_ldg_balance_after,
    owner_ldg_balance_initial +
      Nat::from(100_000_000_000 as u64) -
      Nat::from(2 as u32) * Nat::from(200_000 as u32)
  );

  assert_eq!(
    owner_of,
    vec![
      Some(Account3 {
        owner: nft_buyer.clone(),
        subaccount: None,
      })
    ]
  );
}

#[test]
fn test_burned_tokens_list() {
  let mut env = init();
  let TestEnv {
    ref mut pic,
    canister_ids: CanisterIds { origyn_nft, ogy_ledger, ldg_ledger, notify },
    principal_ids: PrincipalIds { net_principal, controller, originator, nft_owner, nft_buyer },
  } = env;

  let MAX_NFTS = 5;
  // loop to create multiple nft
  for i in 0..MAX_NFTS {
    init_nft_with_premint_nft(
      pic,
      origyn_nft.clone(),
      originator.clone(),
      net_principal.clone(),
      nft_owner.clone(),
      i.to_string()
    );
  }

  pic.set_time(SystemTime::now());

  let total_supply = crate::client::origyn_nft_reference::client::icrc7_total_supply(
    pic,
    origyn_nft.clone(),
    net_principal.clone()
  );

  println!("total_supply: {:?}", total_supply);

  let token_id_as_nat = crate::client::origyn_nft_reference::client::get_token_id_as_nat(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    "1".to_string()
  );

  let transfer_fee: Option<Nat> = crate::client::origyn_nft_reference::client::icrc7_transfer_fee(
    pic,
    origyn_nft.clone(),
    net_principal.clone(),
    token_id_as_nat.clone()
  );

  println!("transfer_fee: {:?}", transfer_fee);

  match transfer_fee {
    Some(fee) => {
      let balance = icrc1_icrc2_token::client::balance_of(
        pic,
        ogy_ledger.clone(),
        nft_owner.clone()
      );

      let approve_res: icrc1_icrc2_token::icrc2_approve::Response = icrc1_icrc2_token::client::approve(
        pic,
        nft_owner.clone(),
        ogy_ledger.clone(),
        origyn_nft.clone(),
        None,
        fee.clone() + Nat::from(E8S_FEE_OGY)
      );

      match approve_res {
        icrc1_icrc2_token::icrc2_approve::Response::Ok(_) => (),
        icrc1_icrc2_token::icrc2_approve::Response::Err(err) => {
          panic!("approve failed: {:?}", err);
        }
      }

      let args: origyn_nft_reference::origyn_nft_reference_canister::TransferArgs = origyn_nft_reference::origyn_nft_reference_canister::TransferArgs {
        memo: None,
        from_subaccount: None,
        created_at_time: None,
        to: Account3 {
          owner: origyn_nft.clone(),
          subaccount: None,
        },
        token_id: token_id_as_nat.clone(),
      };

      let response: origyn_nft_reference::origyn_nft_reference_canister::TransferResult = crate::client::origyn_nft_reference::client::icrc7_transfer(
        pic,
        origyn_nft.clone(),
        nft_owner.clone(),
        vec![args]
      );

      for item in response {
        println!("item: {:?}", item);
      }
    }
    None => panic!("transfer fee not found"),
  }

  let total_supply_2 = crate::client::origyn_nft_reference::client::icrc7_total_supply(
    pic,
    origyn_nft.clone(),
    net_principal.clone()
  );

  println!("total_supply_2: {:?}", total_supply_2);
}
