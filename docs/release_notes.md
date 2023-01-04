
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

v0.1.3

* Upgrade - Upgrading to Map v7.0.0
* dfx - upgrade to dfx 0.12.1
* Refactor - Data API cleaned up and de-nested
* Refactor - Market - standardized code for handling ledger errors
* Refactor - Moved access_tokens into migration state
* Refactor - Moved Candy to Json to Candy Library

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


