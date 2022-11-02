# ORIGYN NFT Marketplace Integration

## Summary

The ORIGYN NFT comes with a marketplace built in.  Because the ORIGYN NFT is a sovereign digital object, only the NFT can transfer itself from one address to another.  This is done via the internal marketplace.  This protects creators from marketplaces that would not honor the royalty schedule that the intellectual property was released under.

The intent is not to bypass marketplaces as we feel that marketplaces provide a valuable service to creators as aggregators and curators. We want to reward the work and value created by those marketplaces.  The ORIGYN NFT allows creators to set a 'broker fee' for their collections. Marketplaces that provide listing or fulfillment services can obtain this fee for providing their services.  While some creators may set this broker fee very low, we expect that the desire to be listed on as many marketplaces as possible will instead create a market value for these services where marketplaces are being compensated for the value provided and creators are paying a fair amount for the exposure.

The opportunity for marketplaces is further enhanced by the fact that, because of the blockchain tech in the NFT, the NFT can be listed on all marketplaces simultaneously, drastically increasing the available inventory for the best and most value providing marketplaces.

This document will describe how a marketplace can integrate with the ORIGYN NFT to provide creators with listing services and market making.

## Broker Fees.

Creators of ORIGYN NFTs set a broker for their collection.  When their NFT is minted, this fee is written into the system storage of the NFT and cannot be changed by the creator without a network governance proposal.  The broker fee is just one of many royalties that an NFT owner can set.

Broker Fees have two behaviors based on if the sale is a Primary or Secondary Sale.

Primary Sales are the sale of an unminted NFT to a buyer upon which the NFT is minted.  This form of sale supports providing a broker id at the point of accepting the escrow. Therefore a marketplace running a primary sale for a creator will need to be a manager on the collection and execute the sale while providing the broker id.  If no broker id is provided, the broker fee for primary sale goes to the development fund.

Upon the secondary sale of an NFT, ie after minting, the broker fee is split between the listing agent and the selling agent.  If the same broker is indicated as both, they get the whole fee.  If one or the other is left blank then the whole fee goes to the one that is present. If neither is present the broker fee goes to the ORIGYN development fund.

As an example, say the broker fee was 3% on a 100 ICP transaction.  The following table describes how the fee would be broken up

|             | Listing Present      | Listing Absent |
| ----------- | ----------- | ----------- |
| **Selling Present** | 15 ICP to Selling Broker; 15 ICP to Listing Broker | 30 ICP to Selling Broker |
| **Selling Absent**   | 30 ICP to Listing Broker        | 30 ICP to Dev Fund |

Broker ids are just the principal under which one wold like their fees stored until retrieval.

Not Yet Implemented: In the future we may automate the distribution of these fees to the default account of the principal provided.

## Primary Sales

Primary sales sell an unminted NFT to an purchaser.  The general workflow for a primary sale is as follows:

High level:

1. Get Invoice
2. Send Escrow Payment
3. Claim Escrow
4. Execute the sale

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
        account_id_text: Text; //text version of th accoutn id
        account: {
            principal: Principal; //principal of the canister
            sub_account: Blob;  //sub account seed used
        };
    };


```

2. Send Payment Escrow - the user will need to send the desired amount of token to the indicated address