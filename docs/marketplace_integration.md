# ORIGYN NFT Marketplace Integration

Note: For full details of any of the apis in this document, please see [nft-current-api.md](nft-current-api.md).

## Summary

The ORIGYN NFT comes with a marketplace built in.  Because the ORIGYN NFT is a sovereign digital object, only the NFT can transfer itself from one address to another.  This is done via the internal marketplace.  This protects creators from marketplaces that would not honor the royalty schedule that the intellectual property was released under.

The intent is not to bypass marketplaces as we feel that marketplaces provide a valuable service to creators as aggregators and curators. We want to reward the work and value created by those marketplaces.  The ORIGYN NFT allows creators to set a 'broker fee' for their collections. Marketplaces that provide listing or fulfillment services can obtain this fee for providing their services.  While some creators may set this broker fee very low, we expect that the desire to be listed on as many marketplaces as possible will instead create a market value for these services where marketplaces are being compensated for the value provided and creators are paying a fair amount for the exposure.

The opportunity for marketplaces is further enhanced by the fact that, because of the blockchain tech in the NFT, the NFT can be listed on all marketplaces simultaneously, drastically increasing the available inventory for the best and most value providing marketplaces.

This document will describe how a marketplace can integrate with the ORIGYN NFT to provide creators with listing services and market making.

## Broker Fees

Creators of ORIGYN NFTs set a broker for their collection.  When their NFT is minted, this fee is written into the system storage of the NFT and cannot be changed by the creator without a network governance proposal.  The broker fee is just one of many royalties that an NFT owner can set.

Broker Fees have two behaviors based on if the sale is a Primary or Secondary Sale.

Primary Sales are the sale of an unminted NFT to a buyer upon which the NFT is minted.  This form of sale supports providing a broker id at the point of accepting the escrow. Therefore a marketplace running a primary sale for a creator will need to be a manager on the collection and execute the sale while providing the broker id.  If no broker id is provided, the broker fee for primary sale goes to the development fund.

Creators can add your marketplace as a manager by calling the collection_update_nft_origyn function:

```
let manager_add = await canister.collection_update_nft_origyn(#UpdateManagers([Principal.fromActor(sale_canister)]));
```

Upon the secondary sale of an NFT, ie after minting, the broker fee is split between the listing agent and the selling agent.  If the same broker is indicated as both, they get the whole fee.  If one or the other is left blank then the whole fee goes to the one that is present. If neither is present the broker fee goes to the ORIGYN development fund.

As an example, say the broker fee was 3% on a 100 ICP transaction.  The following table describes how the fee would be broken up

|             | Listing Present      | Listing Absent |
| ----------- | ----------- | ----------- |
| **Selling Present** | 15 ICP to Selling Broker; 15 ICP to Listing Broker | 30 ICP to Selling Broker |
| **Selling Absent**   | 30 ICP to Listing Broker        | 30 ICP to Dev Fund |

Broker ids are just the principal under which one wold like their fees stored until retrieval.

Not Yet Implemented: In the future we may automate the distribution of these fees to the default account of the principal provided.

Broker fees can be determined by looking in the __system.[com.origyn.royalties.primary].[com.origyn.royalty.broker] node of any origyn_nft.  If this does not exist then the NFT does not pay royalties to brokers.

## Primary Sales

Primary sales sell an unminted NFT to an purchaser.  The general workflow for a primary sale is as follows:

High level:

1. Get Invoice (User UI)
2. Send Escrow Payment (User UI)
3. Claim Escrow (User UI)
4. Execute the sale (Management Canister)

Detail:

1. Get Invoice - During this step you must determine the address that user will send their escrow deposit to.

A purchaser will query sale_info_nft_origyn to receive a deposit address.

```
//if called by the purchase with a connected wallet the parameter can be null
canister.sale_info_nft_origyn(#deposit_info(null))

//if calling for a know principal to predict their deposit address
canister.sale_info_nft_origyn(#deposit_info(?#principal(principal)))

//returns

    #deposit_info: {
        principal : Principal; //principal of the canister
        account_id : Blob; //blob of the account_id
        account_id_text: Text; //text version of th account id
        account: {
            principal: Principal; //principal of the canister
            sub_account: Blob;  //sub account seed used
        };
    };
```

2. Send Payment Escrow - the user will need to send the desired amount of token plus one fee to the indicated address. This fee covers the movement from the deposit address to the escrow address.  You can use the transfer function of your token ledger to send this fee.  Once the transaction is confirmed you must claim the escrow.

```
let funding_result = await dfx.transfer({
            to =  deposit_info.account_id;
            fee = {e8s = 200_000 : Nat64};
            memo = Nat64.fromNat(Nat32.toNat(Text.hash(Principal.toText(to) # Principal.toText(msg.caller)))); //not required
            from_subaccount = null;
            created_at_time = ?{timestamp_nanos = Nat64.fromNat(Int.abs(Time.now()))};
            amount = {e8s = Nat64.fromNat(amount)};});
```

3. Claim Escrow - The user will call the escrow_deposit function to claim the escrow. This call contains various details about the conditions under which the escrow can be used and/or returned.

```
        acanister.sale_nft_origyn(#escrow_deposit({
            token_id = token_id;  //the token id you want the escrow to be restricted to. use "" for any nft
            deposit = {
              token = 
                  #ic({
                    canister = ledger; //your ledger canister
                    standard = #Ledger; //the standard; currently only ICP style ledgers are supported
                    decimals = 8; //number of decimals
                    symbol = "LDG";//symbol
                    fee = 200000; //fee for the ledger
                  });
              };
              seller = #principal(current_owner); //the current owner of the NFT. If unminted then this would likely be the token canister
              buyer = #principal(Principal.fromActor(this)); //the buyer account
              amount = amount; //amount of the escrow...must be one fee less than in the deposit account
              sale_id = sale_id; //restrict to a sale id; null if a primary sale
              trx_id = null; //reserved for future integration with non-subaccount ledgers
            };
            lock_to_date = lock; //this will lock the escrow past a certain date. used with the sales canister to ensure deposits are not removed before a drop date
       }));

```

4. Execute the sale - Once the deposit has been confirmed, you may proceeded with executing the primary sale.  This is done with the market_transfer_origyn function using the #instant variant.  This must be called by an owner of the collection or a manager of the NFT. This function will mint the NFT and assign it to the purchaser.

Your canister can find the escrows by calling the balance_nft_origyn function for the principal of the owner of your NFTs.  You can pull this info for the target purchaser out of this so that you do not have to reassemble it manually.

```

        let transfer = await canister.market_transfer_nft_origyn({
            token_id = "xxxx"; //the id of the token you are selling
            sales_config = 
              {
                  escrow_receipt = ?{ //escrow info must match the escrow submitted
                    seller = #principal(canister_principal); //canister still owns xxxx
                    buyer = #principal(a_principal);
                    token_id = "second";
                    token = #ic({
                      canister = ledger_principal;
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    amount = 100_000_000;
                  };
                  broker_id = null; //put your principal here to claim the broker royalty
                  pricing = #instant;
              };            
        });

```

After this function the purchaser will be the new owner of the NFT and your share of the royalties will be distributed to a sales bucket on the canister.  You can see the sales you have assigned to you by calling balance_nft_origyn.

## Secondary Sales

Currently the only secondary sales methods that are supported are direct sale and auction.

### Direct Sales

Direct sales are peer to peer.  The process for creating a direct secondary sale is exactly the same as the primary sale except that a token_id must be provided in the escrow for the specific token being transacted.

You can show a user their "offers" by inspecting what offers they have in their name on a particular server. 

As offers are rejected/accepted you may need to refresh the offer collection.  You can do this by calling sale_nft_origy with he #refresh_offers variant

```
  acanister.sale_nft_origyn(#refresh_offers(null));

  //returns a list of the escrows that were offered to them:
  #refresh_offers: [EscrowRecord];

```

This list stays fairly fresh and you may be able to just query balance_nft_origyn and inspect the offers collection;

Once you have an escrow that your user wants to accept you can call with the same format as a primary sale. Please remember to provide your broker_id principal to get the reward.

Offers can also be rejected by using the #withdraw(#reject) variant of sale_nft_origyn:

```


    let result = await acanister.sale_nft_origyn(
      #withdraw(#reject({
        token_id= token_id;
        token = switch(token){
          case(null){
            #ic({
              canister = ledger;
              standard = #Ledger;
              decimals = 8;
              symbol = "LDG";
              fee = 200000;
            });
          };
          case(?val){val};
        };
        seller = #principal(seller);
        buyer = #principal(buyer);
      })));

```

### Auctions

Auctions are started by an NFT owner. Your site can offer an experience to create auctions by helping your user call the market_transfer_origyn variant and providing your broker_id. This gives the rights to at least half of the broker royalty if a sale is completed.

Generally when a user is out bid on an auction, their tokens are sent back to them automatically. If this fails for any reason they will need to withdraw the escrow from the NFT canister using the #withdraw: WithdrawRequest option for the sale_nft_origyn management function.  You cannot withdraw an active bid.

High Level:

1. Start an auction(User UI)
2. Get a auction information (User UI or Management Canister)
3. Get Invoice information (User UI)
4. Send the Escrow Payment (User UI)
5. Users escrows tokens for a bid (User UI)
6. User makes a bid (User UI)
7. An auction is ended (User UI or Management Canister)
8. Claim Royalties (Management Canister)

Details:

1. Start an auction - auctions currently support a minimum step, a buy it now price, and a reserve price.  You can start an auction calling the market_transfer_nft_origyn function as shown below:

```
          let start_auction_attempt_owner = await canister.market_transfer_nft_origyn({token_id = "1";
            sales_config = {
                escrow_receipt = null; //not needed
                broker_id = null; // put your broker principal here
                pricing = #auction{
                    reserve = ?(10 * 10 ** 8); //if the reserve is not met, ownership does not change
                    token = #ic({  // you must pick one token type per auction
                      canister = Principal.fromActor(dfx);
                      standard =  #Ledger;
                      decimals = 8;
                      symbol = "LDG";
                      fee = 200000;
                    });
                    buy_now = ?(10 * 10 ** 8); //a buy it now price. a bid at or above this amount will end the auction
                    start_price = (10 * 10 ** 8); // start price
                    start_date = 0; //set to 0 to start instantly, otherwise this is an int of nanoseconds utc
                    ending = #date(get_time() + DAY_LENGTH); //int nanoseconds utc when you want the auction to end
                    min_increase = #amount(10*10**8); //minimum increase. Only amount is supported at the moment
                    allow_list = ?[Principal.fromActor(a_wallet), Principal.fromActor(b_wallet)]; // a white list for auction participants if you would like to limit who can bid.
                };
            }; } );

          //the return will be a TransactionRecord of type 

          #sale_opened : {
                pricing: PricingConfig;
                sale_id: Text;
                extensible: CandyTypes.CandyValue;
            };

```

2. Get auction information -You will need the sale_id to get details for the sale using sale_info_nft_origyn(#status(sale_id)) to get info for the specific auction.

To get a list of all running auctions on the canister you can call sale_info_nft_origyn(#status(null,null)).

You can choose how to show this data to your user.

3. Get invoice info - this is the same process as described in the Principal Sale section. This gives you the address you must send tokens to make a bid.  Include one fee with the total that a user wants to bid.

4. Send the escrow payment - same as described in Principal payment.

5. User escrows tokens for bid - This process is the same as for primary sales except that you must provide a sale_id to restrict the escrow to a specific sale and a token_id to restrict the escrow to a specific token_id.

6. Make the bid - The user will need to call sale_nft_origyn with the bid info to officially register the bid.  The bid is not made until after this function is called.  This is where you will need to include your broker_id to get the selling broker share of the broker royalty.

```
          let bid = await acanister.sale_nft_origyn(#bid({
            broker_id =  broker; //include your broker_id to get a share of the royalty payments
            sale_id = sale_id; //sale_id you are bidding on
            escrow_receipt = { //escrow detail, can be pulled from a users balance_of_nft_origyn
              seller= #principal(owner);
              buyer= #principal(Principal.fromActor(this));
              token_id = token_id;
              token = #ic({
                        canister = ledger;
                        standard =  #Ledger;
                        decimals = 8;
                        symbol = "LDG";
                        fee = 200000;
                      });
              amount = amount}})); //amount of the bid
```

If the bid is over the buy it now price the auction will end and the user will get the NFT transferred to them.

7. End the auction - Once the auction end date has passed, any user may call the end sale function.  This will end the auction and award the NFT to the winner.  If the reserve has not been met, or there are no bids, the original owner will maintain ownership of the item.  All royalties will be paid if a sale is made.

```

let end_sale = await canister.sale_nft_origyn(#end_sale("2"));

```

8. Claim Royalties - Currently royalties are not paid out automatically.  To see if you have any royalties to recover you can call balance_nft_origyn and inspect the sales collection. If any sales exist, you can collect the sales by calling the below function:

```

      let owner_withdraw_over = await canister.sale_nft_origyn(#withdraw(#sale({
        withdraw_to = #principal(Principal.fromActor(broker_principal)); //account to withdraw to. if principal is used, then default sub account
        token_id= "1"; //token that was sold
        token = //description of the token used for the sale
            #ic({
              canister = Principal.fromActor(dfx);
              standard =  #Ledger;
              decimals = 8;
              symbol = "LDG";
              fee = 200000;
            });
        seller = #principal(Principal.fromActor(this)); //seller
        buyer = #principal(Principal.fromActor(a_wallet)); //buyer
        amount = (101*10**8) + 15;}))); //amount to withdraw

```

## Lost Deposits

Sometimes a call to sale_nft_origyn(#escrow_deposit) will fail for an unexpected reason. Perhaps the canister went down after the payment was successful, or perhaps your code did not add a transfer fee.

User can always withdraw from their deposit account if something goes wrong.  You can check for an available balance at their invoice address, and if there is a balance, offer for them to recover it.  Recover these payments by calling the below function:

```

    let trywithdraw = await acanister.sale_nft_origyn(#withdraw(#deposit({
          token = switch(token){ // details of the ledger that the payment was sent to.
            case(null){
              #ic({
                canister = ledger;
                standard = #Ledger;
                decimals = 8;
                symbol = "LDG";
                fee = 200000;
              });
            };
            case(?val){val};
          };
          
          buyer = #principal(Principal.fromActor(this)); //buyer 
          amount = amount; //amount to refund
          withdraw_to = #principal(Principal.fromActor(this)); //destination of the payment. If principal then then default account
      })));
```

## Active Historical Sale Info

## sale_info_nft_origyn

The sale info query is the best way to find out current info about sales going on in a collection.

```
sale_info_nft_origyn : shared SaleInfoRequest -> async Result.Result<SaleInfoResponse,OrigynError>;

public type SaleInfoRequest = {
        #active : ?(Nat, Nat); //get al list of active sales
        #history : ?(Nat, Nat); //skip, take
        #status : Text; //saleID
        #deposit_info : ?Account;
    };
```

"#active" will return a list of active sales.

"#history" will return a list of the status of all previous sales.

"#status" will get you the status of a particular sale id.

"#deposit_info" is used for creating escrows.

You can find historical information about sales for an NFT by calling history_nft_origyn(token_id, null, null) and inspecting the ledger for bids, escrows, and sales.

To discover the list of NFTs on a canister you can use collection_nft_origyn query inspect the token_ids field.

All queries have batch functions that can be used to get data for multiple tokens or sales at one time.

## Where are the Origyn NFT canisters

NYI: Currently we do not have a master list. We are working on an implementation to notify your canister when a new sale/mint is available.