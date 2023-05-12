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

If the following items are on the collection, they will be copied into the __system node of an NFT when it is minted:


{name = "com.origyn.evm.network_id"; value=#Nat({network id}); immutable= true},
{name = "com.origyn.evm.chain_id"; value=#Nat({network id}); immutable= true},
{name = "com.origyn.evm.contract_address"; value=#Text({hex of address}); immutable= true},
{name = "com.origyn.evm.standard"; value=#Text("erc721"); immutable= true},

If com.origyn.evm.contract_address is present for a collection, then com.origyn.evm.chain_native should be set on the NFT in the __System node.  This will keep the nft from trading on the native Origyn marketplace.

{name = "com.origyn.evm.chain_native"; value=#Bool(true); immutable=false},

A burn block value keeps track of what block has been proven through(no-rewind) so that transactions can't be replayed.
{name = "com.origyn.evm.block_burn"; value=#Nat(0); immutable=false},

A nonce must be kept so that if the canister needs to write future transactions to EVM that the nonce is manged
{name = "com.origyn.evm.trx_nonce"; value=#Nat(0); immutable=false},

_system.evm_chain_native can be set to true to indicate that a collection/NFT are off chain. For NFTs this flag will only be changed via the evm_upgrade_origyn endpoint.

ERC721 Specifics:

For now we will only support erc721 tokens.

Each NFT should have an immutable entry for ERC721 token
{name = "com.origyn.evm.token_id"; value=#Nat({evm_token_id}); immutable=true},

The evm token ID for erc 721 is a Nat.  The token can have text id elsewhere.


### Function Spec

```
  actor {
    upgrade_nft_origyn : (
      #request_upgrade_evm_address : {
        token_id : Text;
        account : Account;
      };
      #upgrade: {
        #evm_erc721 {
          witness: Blob;
          block: Nat;
          token_id;
          account : Account;
        };
      };
      #request_registered_root: {
        #evm_erc721;
      }
    ) -> async ({ 
      #request_upgrade_evm_address : Text;
      #upgrade: TransactionRecord; //see nft we will need to add a new transaction type
      #request_registered_root : Nat;
     });
    upgrade_info_nft_origyn : (
      #request_upgrade_evm_address : async {
        token_id : Text;
        account : Account;
      };
      #check_registered_block(block: Nat) : async Bool;
    ) -> async {
      #request_upgrade_evm_address : ?Text;
      #get_last_registered_block : Bool;
    };
  };
```


Querying nft_origyn will return the evm information if the item is evm native. This info makes up the evm address associated with the NFT using the seed H(account_hash).  This is the address that will need to own an NFT for it to be upgraded

upgrade_nft_origyn(#request_upgrade_evm_address())

1. check a cache to see if a value already exists.
2. If not, calculate the derivation for the H(account_hash)
3. call ecdsa_public_key of the tECDSA canister to get the proper target address
4. Return the address

upgrade_nft_origyn(#upgrade())

1. Checks to make sure there is an available root for the requested block height.
2. Confirm the witness calculates to the root and confirms the calling owing account is the same as the evm account associated with the requested account H(account_hash).
2. Changes the _system.evm_native flag to false. Now the account owns this and can sell on the origyn marketplace.

upgrade_nft_origyn(#request_registered_root())

1. Use native evm_functionality to query a root at a particular block and put it in the cache for the NFT.

upgrade_info_nft_origyn(#request_upgrade_evm_address);

1. Return the evm address for the account if it is in the cache.

upgrade_info_nft_origyn(#get_last_registered_block());

1. Checks if the requested block has a registered root.

evm_network_id, evm_chain_id, evm_contract_address, and evm_standard will need to be defined in the collection metadata. Initially only support erc721

## Definitions

EVM - An Ethereum based virtual machine that can be interacted with via ecdsa signed transactions.

Network ID - Each evm chain has an associated network ID that must be used in the signature.


## FAQ:

Q. Why not have the canister go get the witness?  Why is the user passing it in?
A. We think that having the canister will be expensive. It will be cheaper for the user to get this from Infura or some other service. Since it is cryptographically secure it should be ok to have the user pass it in.

