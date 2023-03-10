# Physical and Logistic Workflow

The Physcal and Logistic Workflow functionality allows Origyn NFTs to support the sale of NFTs with a physical component.

## Justification

Physical objects need to follow a different sales workflow than digital objects because they can not support atomic transactions in the same way that digital objects can.

Many ORIGYN NFTs have a physical object which they represent.  The ORIGYN Network exists to protect the authenticity of these objects and provide the trust layer to those that would participate in the marketplace.

By providing a physical sales workflow and logistics for physical item delivery, ORIGYN can become a significant player in the secondary market for a wide array of physical goods.

Customers will be able to participate in the market with a level of trust that does not exist in current marketplaces.

Node providers will be a major part of the logistics workflow. They will not only provide re-certification services which improve the digital record of each object and enhance the data quality available in the public market, but they will also be able to provide add on logistics services that can provide another profitable area of their business.

## Tech Enablement

The Physical and Logistic workflow is enabled by an interplay between the Node network of the ORIGYN network and the data api enabled in the ORIGYN NFT.

Communications of parties via a public blockchain is accomplished through standard public/private key crypto.

## Physical and Logistic Spec

### Marking an item as physical

Physical NFTs must be marked as "physical" in their metadata before they are minted or have a collection level physical marker that will be inherited from the collection metadata.

```
{name="com.origyn.physical"; value = #Bool(true); immutable=true)}
```

This will be moved into the _system store in the NFT when the item is minted.

### Marketplace updates

Physical items should not change ownership  in the same way as digital objects:

Instant - An instant transfer is not allowed for a physical object unless the item is in escrow.

Auction - For Auctions, end_sale needs to not transfer ownership. It should lock the item and initialize logistics_mode.

### Logistics Mode

An item in logistics mode can only be removed from logistics mode by a NODE.  When first created, the fulfilling_node will be #Empty until selected by a buyer.

```
  {
    name = "__system"; 
    value=#Class([
      {name = "com.origyn.logistics_mode"; value=#Class([
        {name="fulfilling_node"; value=#Principal("XXXXXXXX")};
        {name="fulfilling_key"; value=#Principal("XXXXXXXX")};
        {name="target_owner"; value=#Principal("XXXXXXXX")};
        {name="target_owner_key"; value=#Principal("XXXXXXXX")};
        {name="seller"; value=#Principal("XXXXXXXX")};
        {name="seller_key"; value=#Principal("XXXXXXXX")};
        {name="providers"; value=#Array(#frozen([
          #Principal("XXXXXXXX")};
          #Principal("XXXXXXXX")};
          #Principal("XXXXXXXX")};
          ])); immutable = false;} //Providers who can write to the fulfillment arrays
        {name="fulfillment_node"; value=#Array(#frozen([
          #Blob("0xXXXXXXXX")}; //holds a candy value to_candid for information needed to fulfill or invalidate the sale encrypted with the node's public key
          #Blob("0xXXXXXXXX")}; //holds a candy value to_candid for information needed to fulfill or invalidate the sale encrypted with the node's public key
          ])); immutable = true;}
        {name="fulfillment_buyer"; value=#Array(#frozen([
          #Blob("0xXXXXXXXX")}; //holds a candy value to_candid for information needed to fulfill or invalidate the sale encrypted with the node's public key
          #Blob("0xXXXXXXXX")}; //holds a candy value to_candid for information needed to fulfill or invalidate the sale encrypted with the buyer's public key
          ])); immutable = true;}
        {name="fulfillment_seller"; value=#Array(#frozen([
          #Blob("0xXXXXXXXX")}; //holds a candy value to_candid for information needed to fulfill or invalidate the sale encrypted with the node's public key
          #Blob("0xXXXXXXXX")}; //holds a candy value to_candid for information needed to fulfill or invalidate the sale encrypted with the sellers's public key
          ])); immutable = true;}

      ]); immutable=false;}
    ]); 
    immutable = false;
  }

```

The logistic node is created by the end of the sale of a physical item that is not in escrow.

Nodes, buyers, sellers, shippers and other logistics participants can add to the logistics document by submitting encrypted messages that will be appended to the fulfillment arrays using:

```
sale_nft_origyn(#update_logistics([({#seller;#buyer;#node;}, Blob)]));

```

This function can only be called by the node, buyer, and seller unless a provider is added(ie a shipping company).  A provider can be added with the following function.  It should record an update_logistics transaction on the ledger and record a hash of the Blob.

Only the buyer can select the node as they will be responsible for paying shipping charges.

```
sale_nft_origyn(#add_logistics_provider([({#node;#custom: Text},Principal]));
```

The above should be captured by an add_logistics_provider event on the NFT's ledger.

Once a node receives an item and re-certifies the object it can remove logistics mode by calling the following:

```
sale_nft_origyn(#finalize_logistics({transfer : Bool = true});
```

true will transfer ownership to the buyer.

false will transfer ownership back to the seller.

The above should be captured by an finalize_logistics event on the NFT's ledger.

### Escrow Mode

Only a NODE can finalize an item in escrow mode. 

```
  //called by an owner indicating that they want to escrow their object to a particular node.
  //puts the item in Logistics mode
  sale_nft_origyn(#escrow({ #initialize(
    node : Principal = "XXXXXX";
    token_id="X";)
  }))

  //results in an escrow_initialized transaction on the ledger

  //called by a node to accept that an item has arrived in escrow or that it has left escrow.
  sale_nft_origyn(#escrow({ #update(
    token_id="X";
    in_escrow=true;) //or false
  }))

  //results in an update_escrow transaction on the ledger

```

The function should verify with the governance canister that the node is a valid node.

If an item is in escrow mode it can behave like a digital NFT.  Fulfillment will be handled by the Node out side of the system.

## State

The governance canister will need to keep track of Nodes.

State is held in the NFT metadata.

## Definitions

Atomic Transaction - A transaction where the object that is being sold and the tokens being paid change ownership in one transaction.

Escrow - A physical item is in escrow when a node has possession of it. It be treated as a digital NFT when a node has possession of the item.

Logistics Mode - An NFT enters logistics mode when it is in transit from an owner to a node provider for either escrow or for re-authentication/delivery.
