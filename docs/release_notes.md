
Definitions

App Data - ORIGYN NFTs have a simple database inside of them.  Apps can store data in a reserved space that can have flexible permissions.  The apps can make it so that only they can read the data and/or only they can write the data. They can also grant write permissions to certain other principals via an allow list.  Currently, the implementation is more like a structured notepad where you have to write out the entered note each time.  Future versions will add granular access to data per app.

Collection Manager - Collection Managers are granted certain rights over a collection. This allows collection owners to grant third-party apps some rights over their collection. Owners should only grant this privilege to managers that they trust, preferably with applications that are open-sourced and audited.

  Implemented Manager Rights:

    - stage
    - mint
    - market transfers
    - manage sales


Collection Owner - A collection can have one owner. An owner has specific and broad rights over a collection except for a few instances(changing immutable data being the most prominent).

Escrow - All NFT sales require an escrow.  The tokens must be deposited in the canister and registered before a bid or peer-to-peer sale can take place.

Experience Asset - An asset that the creator of an NFT can specify as the canonical experience of an NFT, usually an HTML page.

Gateway Canister - The gateway canister is the "main" canister for your NFT collection.  All metadata resides on the gateway canister and thus you are limited to about 2GB of metadata + history at the moment.

Hidden Asset - An asset that is shown if a user tries to look at an NFT before it is minted.

Network - Each NFT Collection has a network that it pays network fees to when an NFT is transacted.  This network can also make governance changes to the NFT and can change immutable data.  Users should only set the network to decentralized DAOs such as the ORIGYN Network as the network has "god mode" over your collection.

Preview Asset - A smaller asset in the NFT that is good for showing in lists.

Primary Asset - Each NFT can assign a "primary" asset. The NFT expects this to be loaded when viewed from a list of NFTs.

Storage Canister - A storage canister holds library files.  The gateway canister is in charge of distributing those files to the swarm of storage canisters.

Token-id - Each token in your collection has a unique text-based namespace id.

Library-id - Each library item in your token's asset library has a unique text-based namespace id.

v0.1.5

* Network and collection owner can now add a data dapp to an NFT.
* Breaking Change: read permission for nft owner is now nft_owner
* Shared wallets can now read nft_owner data.
* Default minimum increase for asks set to 5%.
* Default end date for ask is one minute after start.
* Default start date for ask is the current time.
* Default token is OGY.
* Min increase by percentage activated. Default is 5%.
* Notify canisters of new sales using the notify interface.  Implement this interface in your canister and submit your principal with the sale and you will be notified of the new sale if created.

```
public type Subscriber = actor {
    notify_sale_nft_origyn : shared (SubscriberNotification) -> ();
};
```

* New #ask sale type with a simpler interface. A sale can now be started with all defaults by providing a much simpler interface:

```
let start_auction_attempt_owner = await canister.market_transfer_nft_origyn({
    token_id = "1";
    sales_config = {
        escrow_receipt = null;
        broker_id = null;
        pricing = #ask(null);
    };
});
```

* pricing annotations can be added by adding an opt vec of a combination of the following:
```
public type AskFeature = {
      #buy_now: Nat; //set a buy it now price
      #allow_list : [Principal]; //restrict access to an auction
      #notify: [Principal]; //notify canisters using the new notify interface
      #reserve: Nat; //set a reserve price
      #start_date: Int; //set a date in the future for the sale to start. Defaults to now
      #start_price: Nat; //set a start price.  Defaults to 1.
      #min_increase: {  //set a min increase.  Defaults to 5%.
        #percentage: Float;
        #amount: Nat;
      };
      #ending: { //set an end time for the sale. Defaults to 1 minute.
        #date: Int; //a specific date
        #timeout: Nat; //nanoseconds in the future
      };
      #token: TokenSpec; //the token spec for the currency to use for the Sale.  Defaults to OGY
      #dutch: {
        time_unit: { //increment period and multiple
          #hour : Nat;
          #minute : Nat;
          #day : Nat;
        };
        decay_type:{ //amount to decrease the price at each interval
          #flat: Nat;
          #percent: Float;
        };
    };  
      
};

```

* Dutch auctions are now available using the new #ask type. You can set a high price and then decay by the minute, day, hour by a flat amount or a percentage.  Reserve prices can also be provided.
* Updated ICRC7 test implementation to latest draft spec. This may change in the future.

v0.1.4

* KYC - Collection level KYC available through the top level collection attribute com.origyn.kyc_canister=#Principal(canister that implements icrc17_kyc)
* KYC - Bids and Buy Nows should auto refund failed kyc.
* Refactor - Buffer.toArrays refactored to new syntax
* ICRC1 - ICRC1 is now used internally for transfers on the #Ledger Type
* Bug Fix - mutable items would overwrite collection data when using #UpdateMetadata on collection
* Bug Fix - can no longer start a buy it now auction with a 0 minimum price.
* Logging - Errors are now reported to canister geek
* Network Royalties are now sent to network accounts on a per token basis for better tracking.
* Upgrade to CandyLibrary 0.2.0
* Upgrade to Mops Package Manager
* Added JSDoc style documentation
* Removed params for deployment to make it easier to launch a canister. Be sure to set the network, set storage, and update your owner after deployment.

```
public func get_network_royalty_account(principal : Principal) : [Nat8]{
      let h = SHA256.New();
      h.write(Conversions.valueToBytes(#Text("com.origyn.network_royalty")));
      h.write(Conversions.valueToBytes(#Text("canister-id")));
      h.write(Conversions.valueToBytes(#Text(Principal.toText(principal))));
      h.sum([]);
    };
```

"ICP" "ryjl3-tyaaa-aaaaa-aaaba-cai", {owner = a3lu7-uiaaa-aaaaj-aadnq-cai; subaccount = ?[172, 255, 169, 103, 157, 15, 63, 92, 98, 171, 192, 27, 17, 244, 117, 8, 84, 178, 124, 170, 65, 96, 138, 84, 211, 239, 22, 67, 74, 174, 213, 253]}

"OGY", "jwcfb-hyaaa-aaaaj-aac4q-cai", {owner = a3lu7-uiaaa-aaaaj-aadnq-cai; subaccount = ?[95, 115, 186, 240, 133, 110, 68, 189, 5, 208, 92, 181, 94, 57, 91, 181, 1, 222, 30, 185, 173, 66, 138, 170, 115, 168, 244, 114, 122, 206, 107, 2]}

"ckBTC", "mxzaz-hqaaa-aaaar-qaada-cai", {owner = a3lu7-uiaaa-aaaaj-aadnq-cai; subaccount = ?[229, 159, 79, 200, 161, 80, 156, 140, 12, 186, 141, 235, 113, 11, 145, 253, 126, 245, 6, 70, 38, 200, 197, 114, 106, 64, 179, 6, 254, 90, 85, 160]}

"CHAT", "2ouva-viaaa-aaaaq-aaamq-cai", {owner = a3lu7-uiaaa-aaaaj-aadnq-cai; subaccount = ?[104, 31, 193, 103, 15, 18, 188, 249, 82, 13, 53, 49, 109, 120, 212, 150, 95, 112, 40, 60, 155, 76, 171, 38, 15, 64, 183, 145, 216, 12, 130, 135]}

"SNS-1", "zfcdd-tqaaa-aaaaq-aaaga-cai", {owner = a3lu7-uiaaa-aaaaj-aadnq-cai; subaccount = ?[19, 239, 169, 124, 238, 36, 197, 24, 185, 239, 208, 48, 152, 137, 26, 237, 189, 142, 210, 165, 177, 51, 198, 107, 106, 114, 188, 195, 18, 99, 71, 177]}


v0.1.3-1

* added balance_of_batch_nft_origyn
* added balance_of_secure_batch_nft_origyn

v0.1.3

* Upgrade - Upgrading to Map v7.0.0
* dfx - upgrade to dfx 0.13.1
* Refactor - Data API cleaned up and de-nested
* Refactor - Market - standardized code for handling ledger errors
* DIP721 - Added v2 functions that seem to be supported by plug
* EXT and DIP721 - Added endpoint at /collection/translate and /-/{token_id}/translate to retrieve ext and dip721 token id mappings.
* Added unique_holders and transaction_count to collection_nft_origyn

v0.1.2-2

* Adds gateway principal to the storage_info_nft_origyn query
* EXT - Adds compatibility for stoic wallet.  query getEXTTokenIdentifier(token_id) to get the identifier necessary to add an NFT to a wallet.

v0.1.2-1

* Fixes a bug where two buyers within a few blocks(while token send in flight) could give both set of tokens to the seller. The first to be processed now locks the NFT until the transaction success or fails.
* Also adds royalty_originator_override = "com.origyn.originator.override" that allows a minter to override the collection level originator when minting an nft.


v0.1.2

* Library - make a library mutable with a node "com.origyn.immutable_library" with a value of #Bool(true). (Defaults to false if not present).
* Library - Delete a library using stage_library_nft_origyn with filedata set to #Bool(false).  This will not work for minted immutable libraries.
* Soulbound - Souldbound now only takes effect after minting for sales.
* Batch and Secure - added batch and secure methods for history.
* Services - Updated Service definition in Types.mo
* Docs - Changed api file to specification.md
* Collection - collection_nft_origyn will now return the full list of NFTs(minted or not) for collection owners, managers, and the network
* http routes - /collection now returns the ids of minted items in json
* http routes - support NatX, IntX, Blob, Floats, Bytes, Option candy types
* http routes - /ledger_info/{page}/{page_size} now returns the ledger json for the collection level
* http routes - /-/token_id/ledger_info/{page}/{page_size} now returns the ledger json for the token level
* Logging - Canister geek integration
* Debugging - Updated some debug messages to queries.
* Metadata - Non-immutable NFT level mata data can be updated with stage_nft_origyn by the manager or owner.
* Backup - Backup mechanism added
* Backup - Halt canister added.
* Auction - Auction owners can now end a sale if it has no bids. Useful for setting a long running buy it now sale. Set minimum and buy it now to the same amount.
* Auction - Proceeds and Royalties should now be distributed to the default account of the principal/owner.
* Sales - Fixed #active endpoint so that only tokens with active sales are listed.
* Batch - Async batch operations are now parallelized for faster processing. Note: Order is no longer stable for responses.
* Offers - Offers are no longer processed for the empty string collection.
* Royalties - Fixed bug that split broker fees into two payments when there was only one broker fee.
* Library - now support "/" in library ids to simulate directory structure for http access.
* Bug Fix - Minting a item that was minted after mint check now returns escrow and fails gracefully.
* Bug Fix - Fixed bug when deallocating a library and adding it back larger.
* Sale Distribution - Collection owner can now distribute sales using the #distribute_sale variant for sale_nft_origyn

v0.1.0

* Storage - Supports Manually Adding Storage Canisters to a Gateway Canister
* Storage - Gateway Canisters support up to 2GB of Storage
* Upgrades - Implemented Migration Scheme.  See https://github.com/ZhenyaUsenko/motoko-migrations
* Logging - Basic logging - Details are not saved
* Marketplace - Peer to Peer market transactions with escrow
* Marketplace - Make offers on NFTs with escrow, Owner can reject and refund
* Marketplace - Sub-account-based deposits and escrow transfer.
* Marketplace - Auctions - Buy It Now
* Marketplace - Auctions - Reserve Price
* Marketplace - Auctions - Increase Amount
* Marketplace - Supports Ledger Style Transactions (ICP, OGY)
* Marketplace - Deprecated end_sale_nft_origyn - see sale_nft_origyn
* Marketplace - Deprecated escrow_nft_origyn - see sale_nft_origyn
* Marketplace - Deprecated withdraw_nft_origyn - see sale_nft_origyn
* Marketplace - Deprecated bid_nft_origyn - see sale_nft_origyn
* Marketplace - Manual sale withdraws
* Marketplace - Auctions for Minted NFTS
* Marketplace - Royalty distribution
* Marketplace - broker code for peer-to-peer and auctions.
* Marketplace - Royalty split for auctions between the listing broker and bid broker
* Marketplace - Time-locked escrows for pre-sales
* Data - Read Type Owner lets data and libraries be restricted to NFT Owners
* Data - App node data API with allow list access
* Data - Only initial data nodes can be replaced(ie. Data nodes must be added before mint);
* Identity - Token Mechanism lets a user get an access token to validate their HTTP requests so that we can show them owner-only data(single canister only)
* Collection - Retrieve token ids
* Minting - Metadata Upload
* Minting - Multi-asset handling
* Minting - Remote Storage Integration
* Minting - Free transfer
* DIP721 - TokenIDs are reversibly converted to a large NAT for Compatability
* DIP721 - Bearer, owner, metadata functionality
* EXT - TokenIDs are converted to an ext style principal id.
* EXT - Bearer, owner, metadata functionality
* Metadata - Report balances for escrow, sales, NFTs, offers
* Security - Secure queries provided for when consensus is required for query values
* Logging - Basic logging
* Media - Streaming callback for large files
* Media - Video streaming for safari/ios via ICxProxy
* Media - Handle nft specific media
* Media - Handle collection media
* Media - Handle web-based media with a redirect
* Dapps - Wallet, Marketplace, Library Viewer, Data Viewer, Ledger Viewer





Future
* Marketplace - Archive sale data
* Marketplace - Auctions - wait for quiet.
* Marketplace - Auctions - Percentage Increase
* Marketplace - Auctions - Dutch Auction
* Marketplace - Waivers Period for marketable NFTs
* Marketplace - Supports DIP20 Style Token - Pending Sub Account Solution
* Marketplace - Supports EXT Style Tokens - Pending Sub Account Solution
* Marketplace - Supports ICRC1 Style Tokens - Pending Finalization of Standard
* Marketplace - Batch Cycle Break
* Marketplace - Implement Marketable NFTs
* Marketplace - Automated Payouts
* Marketplace - Separate Payouts per Royalty to Subaccount
* Collection - Pagination and Field Selection for collection_nft_origyn
* Data - Granular Data Updates for Apps
* Data - Add Data Dapp Nodes
* Data - Storage Economics
* Data - blocklists(maybe...Sybil may make this useless)
* Data - Role-based security(collection_owner, nft_owner,nft_of_collection_owner, former_nft_owner, former_nft_of_collection_owner)
* Storage - Automatic storage canister distribution and creation
* Storage - Erase an existing library item if mutable
* Storage - Immutable Library Items
* Storage - Collection Library Validation
* Storage - Permissioned Libraries
* Minting - Stage Batch Cycle Break
* Minting - Stage Library Batch Cycle Break
* Minting - Async workflow for notifying multiple storage canisters of metadata updates
* DIP721 - Implement Market-Based Transfer
* Marketable - Implement Marketable Rewards
* Marketable - Implement Waivers
* Marketable - Implement Required Actions
* Marketable - Auctions for Unminted NFTS
* Metadata - Report stake in an NFT
* Metadata - Hide unminted NFTs from balance calls not made by the manager/network/owner
* Metadata - Index balance functions for faster responses
* Metadata - Hide unminted items from bearer for non-manager/network/owner
* Ledger - Indexes across a canister
* Ledger - Search across the canister
* Ledger - Data Updates in Ledger
* Ledger - Archive and Query Blocks
* Logging - Canister Geek integration
* HTTP - Handling new location types
* Dapps - Default Dapp Routes
* Dapps - Playground Dapp
* Dapps - Library writer
* Dapps - Data Writer
* Backup - Gateway and Storage Canister Backup schemas
* Spam Protection - Inspect message safeguards
* Identity - Multi canister token access mechanism


