# EVM "mint now, upgrade later"

The EVM "mint now, upgrade later" functionality allows evm based NFTs to use an underlying Origyn NFTs as the data object holds the NFT Data and Media while providing significantly upgraded functionality like self-hosted dapps(wallet, marketplace, social channels) and a third party development platform for expandability.

## Justification

EVM based NFTs typically use a hodgepodge of different technologies to attempt to deliver advanced and scalable NFT functionality. Immutability is provided by the base chain, media is brittlely hosted on different distributed networks, and apps are hosted on traditional web 2 infrastructure like aws.

ORIGYN's "mint now, upgrade later" functionality lets NFT developers that still want to use evm based chains for the established audience, eschew other technologies and focus on one scalable platform - the Internet Computer.  This platform provides hosted media at a remarkably low price, app hosting, and many other features not provided by single use platforms.

The "mint now, upgrade later" functionality provides two phases of NFT development for an NFT developer.

Mint Now - Developers mint their NFTs on their EVM chain of choice and set the metadata URL of the nft to a perpetualOS URL of the form https://prptl.io/-/collection_code/-/token_id/info.  This URL serves up the metadata for the NFT that points to other media also hosted on the perpetual OS inside of the NFT structure.  Using this metadata/media combination the NFT can relate its contents to 3rd party apps.  During the 'mint now' phase the ORIGYN NFT serves a decentralized file store.

Upgrade Later -  If a user decides to "upgrade" their NFT to a full featured ORIGYN NFT later, all they have to do is send it to a provided EVM address and ask the NFT to upgrade itself. Once this is done the ORIGYN NFT Canister will now hold the NFT in the name of the user and begin to provide core origyn_nft features like a native marketplace, built in wallet, integrated social channels, etc.  NFTs can return to their EVM chains to participate in approved marketplaces using our EVM broadcast technology.

The "mint now, upgrade later" functionality gives NFT devs the assurances of today's best practices while giving them the opportunity to take their NFT to next level of scalability and interactivity in the future.

## Tech Enablement

This feature is enabled by DFINITY's T-ecdsa functionality that allows a canister smart contract to ask a subnet to sign a payload with an ecdsa signature using an ethereal key that only exists via the threshold signature scheme.

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

## EVM "mint now, upgrade later" Spec

The canister collection should have a number of attributes that are set so that the collection canister and the NFTs know that they are off-chain native.

Once the NFT has been upgraded, these flags will be reset(at the NFT Level) once the canister confirms the ownership of the asset by the canister/principal derived evm address.

Once an NFT has been upgraded it can only return back to an EVM chain via the broadcast functionality.

### Data Spec

evm_network_id, evm_chain_id, evm_contract_address, evm_standard will need to be defined in the collection metadata and will be used to validate the item is owned by a contract on an evm chain.

_system.evm_chain_native can be set to true to indicate that a collection/NFT are off chain. For NFTs this flag will only be changed via the evm_upgrade_origyn endpoint.

### Function Spec

```
  public type NFTInfoStable = {
        current_sale : ?SaleStatusStable;
        metadata : CandyTypes.CandyShared;
        evm: { //add this element to NFTInfo and NFTInfoStable
          address: [Nat8];
          address_text: Text;
        }
    };
```

Querying nft_origyn will return the evm information that makes up the evm address associated with the NFT using the seed H(gateway_canister  + token_id).  This is the address that will need to own an NFT for it to be upgraded

```
public shared(msg) evm_upgrade_nft_origyn(#broadcast(
  {
    token_id: Text;
  } : async bool))
```

1. Checks the ownership of an NFT on a remote chain and makes sure it matches the H(gateway_canister  + token_id).
2. Changes the _system.evm_native flag.

evm_network_id, evm_chain_id, evm_contract_address, and evm_standard will need to be defined in the collection metadata. Initially only support erc721

## Definitions

EVM - An Ethereum based virtual machine that can be interacted with via ecdsa signed transactions.

Network ID - Each evm chain has an associated network ID that must be used in the signature.


## FAQ:

