# EVM Broadcast

The EVM broadcast functionality allows Origyn NFTs to move to evm based networks in a way that preserves the integrity of the ORIGYN Network and the perpetual marketplace.

## Justification

The Ethereum landscape has recently been subject to a number of marketplace that routes around the royalties expressed by the creators.  This uncertainty causes creators to second guess publishing on the platform.

The EVM broadcast functionality keeps this from occurring by enabling the ORIGYN NFT to write a custom smart contract to a remote EVM that can 1. Only operate with compliant marketplaces and 2. Forces the NFT back to the native IC Chain after the marketplace transaction is over.

By publishing on the ORIGYN platform NFT creators will be able to take advantage of highly popular EVM based marketplaces like OpenSea without fear that their royalties will not be honored.  This will attract a broader user base that wants to engage with NFTs that can be listed on these same popular marketplaces.

## Tech Enablement

The EVM Broadcast feature is enabled by DFINITY's T-ecdsa functionality that allows a canister smart contract to ask a subnet to sign a payload with an ecdsa signature using an ethereal key that only exists via the threshold signature scheme.

Each canister can produce a subset of ethereum addresses using the system functions on the IC system canister:

```

type IC = actor {
    ecdsa_public_key : ({
      canister_id : ?Principal;
      derivation_path : [Blob];
      key_id : { curve: { #secp256k1; } ; name: Text };
    }) -> async ({ public_key : Blob; chain_code : Blob; });
    sign_with_ecdsa : ({
      message_hash : Blob;
      derivation_path : [Blob];
      key_id : { curve: { #secp256k1; } ; name: Text };
    }) -> async ({ signature : Blob });
  };

  let ic : IC = actor("aaaaa-aa");

```

The payload can be any message the user wishes to sign including btc transactions, eth payment transactions, eth smartcontract calls, eth smart contract creation transactions, or other items.

## EVM Broadcast Spec

The canister should be able to deploy an ERC721 contract to an evm network that has the following unique properties:

1. The minter/burner should be the EVM address of the canister. see: H("com.origyn.canister.evm_controller");
2. The transfer function should consult a whitelist for authorized addresses that an NFT can be transferred to.
3. (I'm guessing sales contracts will need to be whitelisted as well so you can transfer to a contract...do you need to transfer first? if so it should be a combo transfer/list function).
4. Transferring to any address other than on the white list should fail unless the transferring caller is the marketplace.  So once a marketplace transfers it to a sale winner it is stuck there.


## Spec

```
  public query (msg) func sale_info_nft_origyn(#evm_address) : {
    address: [Nat8];
    addressText: Text
  }
```

This will return the evm address that belong to the user in the context of this NFT Collection.  Users must send their gas token to this address. Gas is required to send NFTs to evm chains.  When an NFT is minted to an evm chain or returned to the ORIGYN Network it will reside at this address

```
market_transfer_nft_origyn(#broadcast(
  {
    network_id: Nat64;
    token_id: Text;
    max_gas: Nat; //please check this...there may be different ways of dealing with gas and it might need to be a variant
  } : async {
    raw:[Nat8];  //transaction that was relayed
    transaction: [Nat8]; //hash
  }))
```

1. Locks the NFT so that no other sale or transfer can occur(create a record in the sale category...the type will have to be #offchain or something).
2. Produces a transaction that can be relayed to the evm - This transaction mints the NFT in the ERC_721 owned contract
3. Relay the transaction via http_outcalls

```
market_transfer_nft_origyn(#evm_list(
  {
    network_id: Nat64;
    token_id: Text;
    listing_args: [Nat8]; //price etc will be here...market must have a single step listing function
    listing_address: [nat8]; //EVM address of the network, must be on the whitelist
    max_gas: Nat; //please check this...there may be different ways of dealing with gas and it might need to be a variant
  } : async {
    raw:[Nat8];  //transaction that was relayed
    transaction: [Nat8]; //hash
  }))
```

1. Produces a transaction that can be relayed to the evm - This transaction creates the sale on an on-chain marketplace
2. Relay the transaction via http_outcalls

```
market_transfer_nft_origyn(#prep_return(
  {
    network_id: Nat64;
    token_id: Text;
    max_gas: Nat64; ////please check this...there may be different ways of dealing with gas and it might need to be a variant
  } : async {
    raw:[Nat8];  //transaction that was relayed
    transaction: [Nat8]; //hash
  }))
```

1. Calculates the address for a user on the evm network(same as sale_info_nft_origyn(#evm_address))
2. Broadcasts a transaction whitelisting this address in the custom erc721 contract for receiving NFT transfers


```
market_transfer_nft_origyn(#chain_return(
  {
    network_id: Nat64;
    token_id: Text;
    max_gas: Nat64; ////please check this...there may be different ways of dealing with gas and it might need to be a variant
  } : async {
    SaleStable?
  }))
```

1. Checks an oracle to see that the caller's address is the owner of the NFT on the remote chain
2. Ends the sale.
3. Broadcasts a burn transaction to burn the NFT on the EVM chain.
3. Returns details about the sale?

```
market_transfer_nft_origyn(#evm_init(
  {
    network_id: Nat64;
    max_gas: Nat; //please check this...there may be different ways of dealing with gas and it might need to be a variant
  } : async {
    raw:[Nat8];  //transaction that was relayed
    transaction: [Nat8]; //hash
    contract: [Nat8];
    contractText: Text;
  }))
```

1. Preps a transaction that creates the custom ERC721 contract on the evm chain.
2. Broadcasts the transaction to the chain.
3. Records the location of the contract 
4. Checks with the governance canister for a list of whitelisted marketplace addresses


## State

public evm_nonce : Map.Map<{NetworkID, Caller}, Nat64>; //Keeps track of the nonce per caller/evm network.
public evm_contract : Map.Map<NetworkID, [Nat8]>; //Keeps track of the custom ERC721 contract on each

add varint to SaleStatus and Sale Status Stable:

#evm: EVMSaleState : {
  sale_args: [nat8]; //the args to initiate the sale
  marketplace_contract: [nat8]; //the marketplace address
  network_id: Nat64; //network the item is on
  contract: [nat8]; //erc721 contract
  seller_evm: [nat8]; //evm address for the seller
  date_opened: int/
  status: {#open;#closed;}
  winner: ?Account;
  winner_evm ?[nat8];
}

## Definitions

Compliant Marketplace - A marketplace on an EVM chain that allows for the collection of royalties in compliance with the ORGYN NFT's specifications.

EVM - An Ethereum based virtual machine that can be interacted with via ecdsa signed transactions.

Network ID - Each evm chain has an associated network ID that must be used in the signature.