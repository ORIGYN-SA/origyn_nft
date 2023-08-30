# com.origyn.nft.gateway_initialization

Emitted when a new gateway canister is spun up

Data:

#Class([
  {name="canister"; value=#Principal({principal}); immutable=true;},
])

# com.origyn.nft.storage_initialization

Emitted when a new storage canister is spun up

Data:

#Class([
  {name="canister"; value=#Principal({principal}); immutable=true;},
  {name="gateway"; value=#Principal({principal}); immutable=true;},
])

# com.origyn.nft.collection_update

Emitted when data about a collection is updated.  dapp_namespace will be null for non-dapp data.

Data:

#Class([
  {name="canister"; value=#Principal({principal}); immutable=true;},
  {name="dapp_namespace"; value=#Opt(#Text({sale_id})); immutable=true;}
  
])

# com.origyn.nft.mint

Emitted when an NFT is minted

Data:

#Class([
  {name="canister"; value=#Principal({principal}); immutable=true;},
  {name="token_id"; value=#Text({token_id}); immutable=true;}
])

# com.origyn.nft.burn

Emitted when an NFT is burned

Data:

#Class([
  {name="canister"; value=#Principal({principal}); immutable=true;},
  {name="token_id"; value=#Text({token_id}); immutable=true;}
])

# com.origyn.nft.new_sale

Emitted when an NFT is put on sale

Data:

#Class([
  {name="canister"; value=#Principal({principal}); immutable=true;},
  {name="token_id"; value=#Text({token_id}); immutable=true;}
  {name="sale_id"; value=#Text({sale_id}); immutable=true;}
])

# com.origyn.nft.end_sale

Emitted when an NFT is put on sale

Data:

#Class([
  {name="canister"; value=#Principal({principal}); immutable=true;},
  {name="token_id"; value=#Text({token_id}); immutable=true;}
  {name="sale_id"; value=#Text({sale_id}); immutable=true;}
])

# com.origyn.nft.wallet_share

Emitted when an NFT is shared with a new wallet

Data:

#Class([
  {name="canister"; value=#Principal({principal}); immutable=true;},
  {name="token_id"; value=#Text({token_id}); immutable=true;}
])

# com.origyn.nft.new_bid

Emitted when an NFT bid on

Data:

#Class([
  {name="canister"; value=#Principal({principal}); immutable=true;},
  {name="token_id"; value=#Text({token_id}); immutable=true;}
  {name="sale_id"; value=#Text({sale_id}); immutable=true;}
])

# com.origyn.nft.new_data

Emitted when an NFT has a metadata update. For NFT level data like owner the dapp_namespace will be null

Data:

#Class([
  {name="canister"; value=#Principal({principal}); immutable=true;},
  {name="token_id"; value=#Text({token_id}); immutable=true;}
  {name="dapp_namespace"; value=#Opt(#Text({sale_id})); immutable=true;}
])

# com.origyn.nft.payment

Emitted when an NFT sends out a payment or registers a deposit, escrow.

Data:

#Class([
  {name="canister"; value=#Principal({principal}); immutable=true;},
  {name="token_id"; value=#Text({token_id}); immutable=true;}
  {name="transaction_id"; value=#Nat({transaction_id}); immutable=true;}
  {name="type"; value=#Text({type}); immutable=true;}
])