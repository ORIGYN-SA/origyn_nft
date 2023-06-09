# ORIGYN NFT Sale Notifications v0.1

Note: For full details of any of the apis in this document, please see [nft-current-api.md](nft-current-api.md).

## Summary

The ORIGYN NFT has a market based notification system. Those interested in receiving notifications of new sales can stake OGY tokens to receive priority positions in line for the notifications.

## Explicit Notifications

A user listing an NFT for sale can specify a list of canisters to notify of their new sale.  This is done using the #notify variant in an ask request. An example request is below:

```
market_transfer_nft_origyn(
  #ask({
    token_id = "1" : text;
    sales_config = {
        escrow_receipt = null;
        broker_id = null; //can be an opt Principal
        pricing = #ask (opt vec {
          #reserve(100 * 10 ** 8), //reserve price below you do not want to sell
          #token(#ic({
            canister = Principal.fromActor(dfx); //the principal from the ledger you want to transact in
            standard =  #Ledger;
            decimals = 8;
            symbol = "GLDT";
            fee = ?10000;
            id = null; //null unless you are on a multi-token ledger
          })),
          #buy_now(500 * 10 ** 8),  //the sale price for listings -- remove for an auctions style sale
          #start_price(1 * 10 ** 8), //set this equal to the buy now price if doing a classic listing
          #ending(#date(get_time() + DAY_LENGTH)), //if you omit this the sale will last 1 minute and the token will be locked
          #min_increase(#amount(10*10**8)), //not necessary for buy it now
          #notify([Principal.fromActor(a_wallet),
          Principal.fromActor(b_wallet)]) //list of principals to notify - max 5;
          });
    };
  }));
```

There may be other features like #dutch that you can add to an ask.

Once this ask is submitted and processed, the canister will begin notifying elected principals after any subscriptions have been served.

## Listening for Notifications

To receive notifications, you must implement a one-shot endpoint that adhears to the following types:

```
public type Subscriber = actor {
  notify_sale_nft_origyn : shared (SubscriberNotification) -> ();
};

public type SubscriberNotification = {
  escrow_info : SubAccountInfo;
  sale : SaleStatusShared;
  seller : Account;
  collection: Principal;
};

public type SubAccountInfo = {
  principal : Principal;
  account_id : Blob;
  account_id_text : Text;
  account : {
    principal : Principal;
    sub_account : Blob;
  };
};

public type SaleStatusShared = {
  sale_id : Text; //sha256?;
  original_broker_id : ?Principal;
  broker_id : ?Principal;
  token_id : Text;
  sale_type : {
    #auction : AuctionStateShared;
  };
};

public type Account = {
  #principal : Principal;
  #account : {owner: Principal; sub_account: ?Blob};
  #account_id : Text;
  #extensible : CandyTypes.CandyShared;
};

public type AuctionStateShared = {
  config : PricingConfigShared;
  current_bid_amount : Nat;
  current_broker_id : ?Principal;
  end_date : Int;
  start_date : Int;
  min_next_bid : Nat;
  token : TokenSpec;
  current_escrow : ?EscrowReceipt;
  wait_for_quiet_count : ?Nat;
  allow_list : ?[(Principal, Bool)]; // user, tree
  participants : [(Principal, Int)]; //user, timestamp of last access
  status : {
      #open;
      #closed;
      #not_started;
  };
  winner : ?Account;
};

public type PricingConfigShared = {
  #instant; //executes an escrow receipt transfer -only available for non-marketable NFTs
  #auction: AuctionConfig; //deprecated - use ask
  #ask: AskConfigShared;
  #extensible: CandyTypes.CandyShared;
};

public type EscrowReceipt = {
  amount: Nat; //Nat to support cycles
  seller: Account;
  buyer: Account;
  token_id: Text;
  token: TokenSpec;
};

public type AskConfigShared = ?[AskFeature];

public type AskFeature = {
  #atomic; // not implemented
  #buy_now: Nat; //set a price at which anything greater or equal will sell
  #wait_for_quiet: {
      extension: Nat64;
      fade: Float;
      max: Nat
  }; //not implemented
  #allow_list : [Principal]; //only for non-marketable nfts
  #notify: [Principal]; //notify canisters of the sale
  #reserve: Nat; //a price below which the sale will be invalid
  #start_date: Int; //Timestamp
  #start_price: Nat; //price to start at
  #min_increase: {
    #percentage: Float;
    #amount: Nat;
  }; //min increase for each next bid
  #ending: {
    #date: Int;
    #timeout: Nat;
  }; //exact date or extension from now.
  #token: TokenSpec; //specification for the token
  #dutch: {
    time_unit: {
      #hour : Nat;
      #minute : Nat;
      #day : Nat;
    };
    decay_type:{
      #flat: Nat;
      #percent: Float;
    };
  }; //not implemented
  #kyc: Principal; //specify a KYC provider that any counterparty must pass. Not implemented
  #nifty_settlement: {
    duration: ?Int;
    expiration: ?Int;
    fixed: Bool;
    lenderOffer: Bool;
    interestRatePerSecond: Float;
  }; //not implemented
};

public type ICTokenSpec = {
      canister: Principal;
      fee: ?Nat;
      symbol: Text;
      decimals: Nat;
      id: ?Nat;
      standard: {
          #DIP20;
          #Ledger;
          #EXTFungible;
          #ICRC1; //use #Ledger instead
          #Other : CandyTypes.CandyShared;
      };
  };

  public type TokenSpec = {
    #ic: ICTokenSpec;
    #extensible : CandyTypes.CandyShared; //#Class
  };

  public type CandyShared = {
    #Int : Int;
    #Int8: Int8;
    #Int16: Int16;
    #Int32: Int32;
    #Int64: Int64;
    #Ints: [Int];
    #Nat : Nat;
    #Nat8 : Nat8;
    #Nat16 : Nat16;
    #Nat32 : Nat32;
    #Nat64 : Nat64;
    #Float : Float;
    #Text : Text;
    #Bool : Bool;
    #Blob : Blob;
    #Class : [PropertyShared];
    #Principal : Principal;
    #Option : ?CandyShared;
    #Array :  [CandyShared];
    #Nats: [Nat];
    #Floats: [Float]; 
    #Bytes : [Nat8];
    #Map : [(CandyShared, CandyShared)];
    #Set : [CandyShared];
  };

  public type PropertyShared = {name : Text; value : CandyShared; immutable : Bool};

```

A sample notification is below:

```
{
  collection = zkqhl-aeaaa-aaaaa-qac3a-cai; 
  escrow_info = {
    account = {
      principal = zkqhl-aeaaa-aaaaa-qac3a-cai; 
      sub_account = "\56\B1\83\2A\89\32\4F\34\A1\62\F0\3E\77\09\95\8D\71\20\C5\08\9A\33\E3\20\9F\1E\14\3E\BD\81\C5\6C"
    }; 
    account_id = "\A4\43\3A\95\32\6C\99\0F\04\E0\0F\E1\CB\6B\87\D2\F5\24\40\C3\FC\31\B0\A4\E8\7E\91\B2\B2\B8\8B\AC"; 
    account_id_text = "a4433a95326c990f04e00fe1cb6b87d2f52440c3fc31b0a4e87e91b2b2b88bac"; principal = zkqhl-aeaaa-aaaaa-qac3a-cai
  }; 
  sale = {
    broker_id = null; 
    original_broker_id = null; 
    sale_id = "5567f63d619efd0b5c0a2ec63d143f845101d218f36f7bd8b759e2fb2b1799d1"; sale_type = #auction(
      {
        allow_list = null; 
        config = #ask(
          ?[
            #reserve(10_000_000_000), 
            #token(#ic(
              {
                canister = bd3sg-teaaa-aaaaa-qaaba-cai; 
                decimals = 8; 
                fee = ?200_000; 
                id = null; 
                standard = #Ledger; 
                symbol = "LDG"
              })), 
            #buy_now(50_000_000_000), 
            #start_price(50_000_000_000),
            #ending(#date(+1_686_422_635_859_481_000)), 
            #min_increase(#amount(1_000_000_000)), 
            #notify([
              zeskd-3uaaa-aaaaa-qac2a-cai, 
              zdtmx-wmaaa-aaaaa-qac2q-cai])
            ]); 
        current_bid_amount = 0; 
        current_broker_id = null; 
        current_escrow = null; 
        end_date = +1_686_339_835_859_481_000; 
        min_next_bid = 100_000_000; 
        participants = [
          (bkyz2-fmaaa-aaaaa-qaaaq-cai, +1_686_336_235_859_481_000)
        ]; 
        start_date = +1_686_336_235_859_481_000; 
        status = #open; 
        token = #ic({
          canister = bd3sg-teaaa-aaaaa-qaaba-cai; 
          decimals = 8; 
          fee = ?200_000; 
          id = null; 
          standard = #Ledger; 
          symbol = "LDG"
        }); 
        wait_for_quiet_count = ?0; 
        winner = null
      }); 
    }; 
  seller = #principal(bkyz2-fmaaa-aaaaa-qaaaq-cai); 
  token_id = "1"
}
```

## Buying upon notification

If you would like to buy the NFT upon notification, you will want to follow a two step process:

1. Fund the Escrow
2. Make a bid

Assuming that the canister being notified is the buyer, the account needed to escrow funds is included in the notification.

**Warning**: Only the notified canister will have the ability to claim and withdraw these funds. Do not pass this onto your users.  If you would like to buy for a different principal than was notified you will need to procure the proper escrow information by querying:

```
 await service.sale_info_nft_origyn(#escrow_info({
  amount = 0; //Can be set ot 0
  seller = notification.seller;
  buyer = #principal(IntendedPrincipal);
  token_id: notification.sale.token_id;
  token: notification.sale.token;
 }));
```

Tokens should be sent to the ledger account indicated in notification.escrow_info.account(note the slight variation in terms):

```
   {
    owner = notification.escrow_info.acccount.principal;
    subaccount = ?notification.escrow_info.acccount.sub_account;
   }
```

Once the tokens have settled you may call a bid

```
  let bid = await service.sale_nft_origyn(#bid({
    broker_id = ?broker; //include your broker_id to get a share of the royalty payments
    sale_id = notification.sale.sale_id; //sale_id you are bidding on
    escrow_receipt = { //escrow detail, can be pulled from a users balance_of_nft_origyn
      seller= #principal(notification.seller);
      buyer= #principal(Principal.fromActor(this));
      token_id = notification.sale.token_id;
      token = notification.sale.token;
      amount = notification.sale.min_next_bid}})); //amount of the bid
```

This will return an ManageSaleResponse of type ManageSaleResult:

```
public type ManageSaleResult = Result.Result<ManageSaleResponse, OrigynError>;

public type ManageSaleResponse = {
        #end_sale : EndSaleResponse; //trx record if succesful
        #open_sale : Bool; //true if opened, false if not;
        #escrow_deposit : EscrowResponse;
        #recognize_escrow : RecognizeEscrowResponse;
        #refresh_offers : [EscrowRecord];
        #bid : BidResponse;
        #withdraw : WithdrawResponse;
        #distribute_sale : DistributeSaleResponse;
        #ask_subscribe : AskSubscribeResponse;
    };

public type BidResponse = TransactionRecord;

public type TransactionRecord = {
        token_id: Text;
        index: Nat;
        txn_type: {
            #auction_bid : {
                buyer: Account;
                amount: Nat;
                token: TokenSpec;
                sale_id: Text;
                extensible: CandyTypes.CandyShared;
            };
            #mint : {
                from: Account;
                to: Account;
                //nyi: metadata hash
                sale: ?{token: TokenSpec;
                    amount: Nat; //Nat to support cycles
                    };
                extensible: CandyTypes.CandyShared;
            };
            #sale_ended : {
                seller: Account;
                buyer: Account;
               
                token: TokenSpec;
                sale_id: ?Text;
                amount: Nat;//Nat to support cycles
                extensible: CandyTypes.CandyShared;
            };
            #royalty_paid : {
                seller: Account;
                buyer: Account;
                receiver: Account;
                tag: Text;
                token: TokenSpec;
                sale_id: ?Text;
                amount: Nat;//Nat to support cycles
                extensible: CandyTypes.CandyShared;
            };
            #sale_opened : {
                pricing: PricingConfigShared;
                sale_id: Text;
                extensible: CandyTypes.CandyShared;
            };
            #owner_transfer : {
                from: Account;
                to: Account;
                extensible: CandyTypes.CandyShared;
            }; 
            #escrow_deposit : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat;//Nat to support cycles
                trx_id: TransactionID;
                extensible: CandyTypes.CandyShared;
            };
            #escrow_withdraw : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat;//Nat to support cycles
                fee: Nat;
                trx_id: TransactionID;
                extensible: CandyTypes.CandyShared;
            };
            #deposit_withdraw : {
                buyer: Account;
                token: TokenSpec;
                amount: Nat;//Nat to support cycles
                fee: Nat;
                trx_id: TransactionID;
                extensible: CandyTypes.CandyShared;
            };
            #sale_withdraw : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat; //Nat to support cycles
                fee: Nat;
                trx_id: TransactionID;
                extensible: CandyTypes.CandyShared;
            };
            #canister_owner_updated : {
                owner: Principal;
                extensible: CandyTypes.CandyShared;
            };
            #canister_managers_updated : {
                managers: [Principal];
                extensible: CandyTypes.CandyShared;
            };
            #canister_network_updated : {
                network: Principal;
                extensible: CandyTypes.CandyShared;
            };
            #data : {
              data_dapp: ?Text;
              data_path: ?Text;
              hash: ?[Nat8];
              extensible: CandyTypes.CandyShared;
            }; //nyi
            #burn: {
              from: ?Account;
              extensible: CandyTypes.CandyShared;
            };
            #extensible : CandyTypes.CandyShared;

        };
        timestamp: Int;
    };

    public type OrigynError = {
        number : Nat32;
        text : Text;
        error : Errors;
        flag_point : Text;
    };

    public type Errors = {
        #app_id_not_found;
        #asset_mismatch;
        #attempt_to_stage_system_data;
        #auction_ended;
        #auction_not_started;
        #bid_too_low;
        #cannot_find_status_in_metadata;
        #cannot_restage_minted_token;
        #content_not_deserializable;
        #content_not_found;
        #deposit_burned;
        #escrow_cannot_be_removed;
        #escrow_owner_not_the_owner;
        #escrow_withdraw_payment_failed;
        #escrow_not_large_enough;
        #existing_sale_found;
        #id_not_found_in_metadata;
        #improper_interface;
        #item_already_minted;
        #item_not_owned;
        #library_not_found;
        #malformed_metadata;
        #no_escrow_found;
        #not_enough_storage;
        #out_of_range;
        #owner_not_found;
        #property_not_found;
        #receipt_data_mismatch;
        #sale_not_found;
        #sale_not_over;
        #sale_id_does_not_match;
        #sales_withdraw_payment_failed;
        #storage_configuration_error;
        #token_not_found;
        #token_id_mismatch;
        #token_non_transferable;
        #unauthorized_access;
        #unreachable;
        #update_class_error;
        #validate_deposit_failed;
        #validate_deposit_wrong_amount;
        #validate_deposit_wrong_buyer;
        #validate_trx_wrong_host;
        #withdraw_too_large;
        #nyi;
        #noop;
        #kyc_error;
        #kyc_fail;
    };

```