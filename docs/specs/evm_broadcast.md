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


## FAQ:

I think it would be helpful to start with a high-level overview of how/when the IC will integrate with Ethereum.
What type of integration do we need? Just Ethereum addresses/signatures, or full EVM compatibility? If the latter, will this be implemented as separate subnets?

1a. T-ecdsa - I've added a tech enablement section to the design doc

Will this integration only work with Ethereum, or will it work with any EVM compatible blockchain?

1b. Any evm chain

How would we select the blockchain? Is it as simple as changing the Network ID?

1c. Part of the signature construction in etherum includes a chain ID.  It has to do with how r,s,v are calculated and included in the signature.

How far away is this integration?

1d. The beta key exists on chain already.  Production has been slotted for November.

Is the idea that a canister can have an Ethereum address (with ETH in it) and sign an Ethereum transaction to create a new smart contract?

2. Yes. Each canister can have many ETH addresses to send transactions they need an eth balance to pay gas.

When an NFT is sold on OpenSea, what will call the canister method to burn the NFT (market_transfer_nft_origyn/#chain_return)? Since Ethereum contracts can't make HTTP calls, are we depending on the exchanges to implement this especially for Origyn?

3. We will wait for the new buyer to return the NFT to the ORIGYN network by calling #chainreturn.  The custom ERC721 will restrict transfer of the NFT beyond the purchaser's address so the user will be requred to return it to the ORIGYN chain and burn the evm based NFT before they could resell it.  Maybe there is a fancier way of doing this that only requires one transaction. We'll need to design that.


If an NFT is burned on the Ethereum blockchain each time it is transferred, how does it appear in the purchaser's Ethereum wallet (OpenSea profile page)?

4. It will not appear until they transfer it to the evm chain unless Opensea implements the origyn_nft standard and lets users track their IC wallets

Is the intention to re-mint the same token id in an ERC721 contract each time it is listed? If it's "burned" by getting transferred to the burn address, doesn't the token id still exist?

5. Yes...I think I understand the question.  Each time you want to list on the EVM chain then you'll need to mint back to the evm chain.  When you return the evm based NFT is burned...the custom contract will allow the contract admin address to reconstitute an NFT if was previously burned.

What does this mean? Will there be a function named "H"?
see: H("com.origyn.canister.evm_controller");

6. Hash. sha-256 most likely

Are users required to use gas tokens, instead of just burning ETH for gas? If so, will that integrate well with Ethereum marketplaces like OpenSea?

7. The address sending the transactin will need eth in it to pay for gas(or matic or whatever the native evm token is).  Likely the transaction will need to contian a sig from the admin of the evm erc721 contract, so the origyn_nft contract will actually have to do two sigs. One to sign the authorization by the admin that can be included in the mint transactions by the submitter and the signature of the owner by the derivative key.

What are some examples of addresses that would be in the whitelist other than marketplaces and sales contracts?

8. I'm not sure I understand.  There will be a transferTo whitelist that will likely be marketplaces.  There will be transferFrom whitelist which will likely also be the marketplaces that are allowed to transfer from themselves to the winner of the sale.

I'm not sure how centralized NFT exchanges work in regard to transferring addresses. Can we depend on marketplace addresses staying the same?

9. We will likely not support centralized exchanges.

Wherever variants require a network_id parameter, do you they also need a chain_id? https://besu.hyperledger.org/en/stable/public-networks/concepts/network-and-chain-id/

10. network_id==chain_id - if that isn't the case then we'll need to handle both. I hadn't seen that setup in Avalanche...interesting.

Note that the Avalanche EVM compatible C-Chain has different network and chain ids: https://docs.avax.network/apis/avalanchego/apis/c-chain
It seems that we would need to generate metadata for the ERC721 tokenURI in the required format of target exchange and add the JSON as an asset in the NFT canister. The metadata would not support the rich features of the Origyn NFT, but the external_url could point to an experience page where users could get the full experience. Is that the idea or have I missed the bigger picture? https://docs.opensea.io/docs/metadata-standards#metadata-structure

11. We should make it very easy to create these attributes in the metatdat so that when one calls http://prptil.io/-/collection_code/-/token_id/info they show in the json that is returned.  We will use this URL for the base url for the item in the erc721 contract.  the external_url would be a likely candidate for the experience page.


What is the reason for using a single function with multiple variants, instead of creating multiple functions?

12. Just trying to keep the api slim.