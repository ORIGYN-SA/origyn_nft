


## Balance

```
query balance_of_nft_origyn(account: Account) -> Result<BalanceResponse, OrigynError> 

    public type Account = {
        #principal : Principal; //just a principal and default to null subaccount
        #account : {owner: Principal; sub_account: ?Blob}; //for future icrc-1
        #account_id : Text; //raw account id for compatability...some features not available
        #extensible : CandyTypes.CandyValue; //for future extensibility
    };

returns:

type BalanceResult = {
        multiCanister: ?[Principal];  // will hold other canisters that are part of the collection - not yet implemented
        nfts: [Text]; //nft ids owned by the user
        escrow: [EscrowRecord]; // escrow records that the user has on file
        sales: [EscrowRecord]; // sale records that the user has on file
        offers: [EscrowRecord]; // offers that have been made
        stake: [StakeRecord]; // nyi
    };

```


* alternative mappings
    * query balanceOfDip721(user: principal) -> Nat64; - only supports principals
    * query balanceEXT(request: EXTBalanceRequest) -> EXTBalanceResponse; Token Identifier is a text from Principal of [10, 116, 105, 100] + CanisterID as [Nat8] + Nat32 as bytes of Text.hash of token_id as each canister has only one token identifier

## Owner

```
    query bearer_nft_origyn(token_id: Text) -> Result<Account, OrigynError>
    query bearer_batch_nft_origyn(token_id: [Text]) -> [Result<Account, OrigynError>]
    bearer_secure_nft_origyn(token_id: Text) -> Result<Account, OrigynError>
    bearer_batch_secure_nft_origyn(token_id: Text) -> Result<Account, OrigynError> 
```
returns the owner of the NFT indicated by token_id

* alternative mappings
    * query ownerOfDip721(token_id: Nat) -> DIP721OwnerResult; - will compare Nat64 hash of text token IDs to the token_id
    * query ownerOf(token_id: Nat) -> DIP721OwnerResult; - will compare Nat64 hash of text token IDs to the token_id //for questinable "v2" upgrade where the standard is now compatable with fewer web 3 tools
    * query bearerEXT(token: TokenIdentifier) -> Result<EXTAccountIdentifier, EXTCommonError>; bearer() also exists for legacy native ext support
    * query bearer(token: TokenIdentifier) -> Result<EXTAccountIdentifier, EXTCommonError>; bearer() also exists for legacy native ext support //for legacy support
    

## Transfers

The origyn NFT supports two types of transfers. Owner Transfers and Market Transfers.  

Owner transfers are meant as a management function for the owners of NFT who needs to move their NFT from one wallet to another.  The NFT enforces this policy by transferring not only the NFT, but other Origyn based assets associated with NFT to the new address. Both addresses maintain rights over the nft for a configured time. You should not use this unless you are transfering to a wallet that you own and do not share with anyone.

Market transfers are the standard way to transact with Origyn NFTs. To help establish true market prices and to protect human ingenuity, reward value creators/originators all transfers of marketable NFTs must go through a public market cycle that ensures that true value is being paid for the asset. As the value flows through the NFT, the NFT implements the revenue sharing built into the NFT.

### Owner Transfers

```

    public type ShareWalletRequest = {
        token_id: Text;
        from: Account;
        to: Account;
    };

    public type OwnerTransferResponse = {
        transaction: TransactionRecord;
        assets: [CandyTypes.CandyValue];  //assets included in the transfer
    };

    share_wallet_nft_origyn(ShareWalletRequest) -> Result<OwnerTransferResponse, OrigynError>

```

Owner Tranfers moves an NFT from one wallet of an owner to another owner of a wallet. All associated assets should move with the NFT such that an owner would never use this function to transfer an NFT to another user.

### Market Transfers

```
    public type MarketTransferRequest = {
        token_id: Text;
        sales_config: SalesConfig;
    };

    public type SalesConfig = {
        escrow_receipt : ?EscrowReceipt;
        broker_id : ?Principal;
        pricing: PricingConfig;
    };

    public type PricingConfig = {
        #instant; //executes an escrow recipt transfer - only available for non-marketable NFTs
        #auction: AuctionConfig;
        //below have not been signficantly designed or vetted
        #flat: { //nyi
            token: TokenSpec;
            amount: Nat; //Nat to support cycles
        };
        #dutch: {
            start_price: Nat;
            decay_per_hour: Float;
            reserve: ?Nat;
        };
        #extensible:{
            #candyClass
        }
    };

    public type TokenSpec = {
        #ic: ICTokenSpec;
        #extensible : CandyTypes.CandyValue; //#Class
    };

    public type ICTokenSpec = {
        canister: Principal;
        fee: Nat;
        symbol: Text;
        decimals: Nat;
        standard: {
            #DIP20; //NYI
            #Ledger; //OGY and ICP
            #EXTFungible; //NYI
            #ICRC1; //NYI
        };
    };

    public type AuctionConfig = {
        reserve: ?Nat;
        token: TokenSpec;
        buy_now: ?Nat;
        start_price: Nat;
        start_date: Int;
        ending: {
            #date: Int;
            #waitForQuiet: { //nyi
                date: Int;
                extention: Nat64;
                fade: Float;
                max: Nat
            };
        };
        min_increase: {
            #percentage: Float; //nyi
            #amount: Nat;
        };
        allow_list : ?[Principal]; //Result must pass waivers
    };

    market_transfer_nft_origyn(MarketTransferRequest) -> Result<MarketTransferRequestResponse, OrigynError>
    market_transfer_batch_nft_origyn([MarketTransferRequest]) -> [Result<MarketTransferRequestResponse, OrigynError>]

```

Initiates the market-based transfer of the NFT.

Currently implemented pricing configs are:

```
#instant
```

Instant transfers are used to sell an unminted NFT or a direct sale of a minted NFT. They require an escrow to be on file with the canister.  The owner of an NFT must be given the escrow receipt and must submit the receipt with the transfer request.

```
#auction
```

An auction allows users to bid on an NFT until it closes. The winner can then claim the NFT. Bidders must post an escrow for their bids.

Note: For alternative mappings the existance of an escrow is the approval for the transfer.  They use the #instant transfer method under the hood and look up an existing escrow. They use the first escrow they find that matches the to, from, token_id pair.

* alternative mappings
    * transferFromDip721(from: principal, to: principal, tokenAsNat: nat) -> Result; - token_id will be converted from the Nat representation.  
    * transferFrom(from: principal, to: principal, tokenAsNat: nat) -> Result; - token_id will be converted from the Nat representation.  //v2
    * transferDip721(to: principal, tokenAsNat: nat) -> Result; - token_id will be converted from the Nat representation.
    * transferEXT(request : EXTTransferRequest) -> EXTTransferResponse; transfer() also exists for legacy native ext support
    * transfer(request : EXTTransferRequest) -> EXTTransferResponse; transfer() also exists for legacy native ext support


## Minting


Stages meta data for an NFT

```
stage_nft_origyn({metadata: CandyValue #Class}); - Stages the metadata
```

Stages Chunks of Data

```
stage_library_nft_origyn(StageChunkArg = {
    token_id: Text;
    library_id: Text;
    filedata: CandyTypes.CandyValue;
    chunk: Nat;
    content: Bool; //up to 2MB
}) : Result<#ok(bool),#err(OrigynError)>; - Stages the content
```

Mints an NFT

Mints a staged NFT and assigns it to the owner. This a "free" transfer.  In the future this may involve a network fee based on the node provider that is minting the item.

```
mint_nft_origyn(text:token_id, owner: Account); 

```

### NFT Information

```
query nft_origyn(id: Text) query -> NFTInfo
nft_secure origyn(id: Text) query -> NFTInfo
query nft_batch_origyn(id: [Text]) -> [NFTInfo]
query nft_batch_secure_origyn(id: [Text]) query -> [NFTInfo]

```

returns data about the nft.  

metatdata - nfts are a class of CandyValues(see below section)
currentSale - if the NFT is for sale it will returne info about the current sale

```
    {
        id: #Text
        primary_asset: #Text //id in library
        preview: #Text //id in library
        experience: #Text// asset to use for the experience of the NFT(typically html)
        hidden: #Text //asset to use for the hidden asset before it is minted
        library: #Array(#Class({
            library_id: #text //must be unique
            title: #text;
            location_type; #Text  //inCansiter, IPFS, URL, 
            location; #Text; //http addressable 
            content_type: #Text; 
            contentHash: #Bytes
            size: #Nat; 
            sort: #Nat}));
        __system: //cannot specify system vars on stage
            status: #Text //minted, staged
            current_sale_id: #Text //currently running or last run sale for the NFT
        __app:
            read: #Class{
                {{type: public;} 
                {type: roles; roles: #Array[#Text]} //nyi
                {type: block; roles: #Array[#Principal]} //nyi
                {type: allow; roles: #Array[#Principal]}
            }
            write: #Class{
                {{type: public;} 
                {type: roles; roles: #Array[#Text]} //nyi
                {type: block; roles: #Array[#Principal]} //nyi
                {type: allow; roles: #Array[#Principal]}
            }
            permissions: #Class{
                {type: roles; roles: #Array[#Text]} //nyi
                {type: block; roles: #Array[#Principal]} //nyi
                {type: allow; roles: #Array[#Principal]}
            }
            com.app*.data_item: #Class{
                read: #Class{
                    {{type: public;} 
                    {type: roles; roles: #Array[#Text]}
                    {type: block; roles: #Array[#Principal]}
                    {type: allow; roles: #Array[#Principal]}
                }
                write: #Class{
                    {{type: public;} 
                    {type: roles; roles: #Array[#Text]}
                    {type: block; roles: #Array[#Principal]}
                    {type: allow; roles: #Array[#Principal]}
                }
            }
        compute_context: #Class //nyi
            context_server: #Principal //nyi
            context_menu: [#Class] //nyi
        //content for html
        owner: #Principal
        { "name": "is_soulbound", "value": { "Bool": false },"immutable": false}
        {"name":"default_royalty_primary", "value":{"Array":{ //royalties are assigned at the colletion level and then copied to each nft in the system vars. they become immutable except for the network
            "thawed": [
                {"Class":[
                    {"name":"tag", "value":{"Text":"com.origyn.royalty.broker"}, "immutable":true},
                    {"name":"rate", "value":{"Float":0.05}, "immutable":true},
                    {"name":"account", "value":{"Principal":"rrkah-fqaaa-aaaaa-aaaaq-cai"}, "immutable":false}
                ]},
                {"Class":[
                    {"name":"tag", "value":{"Text":"com.origyn.royalty.node"}, "immutable":true},
                    {"name":"rate", "value":{"Float":0.005}, "immutable":true},
                    {"name":"account", "value":{"Principal":"rrkah-fqaaa-aaaaa-aaaaq-cai"}, "immutable":false}
                ]}
            ]
        }}, "immutable":false},
        {"name":"default_royalty_secondary", "value":{"Array":{
            "thawed": [
                {"Class":[
                    {"name":"tag", "value":{"Text":"com.origyn.royalty.broker"}, "immutable":true},
                    {"name":"rate", "value":{"Float":0.05}, "immutable":true},
                    {"name":"account", "value":{"Principal":"rrkah-fqaaa-aaaaa-aaaaq-cai"}, "immutable":false}
                ]},
                {"Class":[
                    {"name":"tag", "value":{"Text":"com.origyn.royalty.node"}, "immutable":true},
                    {"name":"rate", "value":{"Float":0.005}, "immutable":true},
                    {"name":"account", "value":{"Principal":"rrkah-fqaaa-aaaaa-aaaaq-cai"}, "immutable":false}
                ]},
                {"Class":[
                    {"name":"tag", "value":{"Text":"com.origyn.royalty.originator"}, "immutable":true},
                    {"name":"rate", "value":{"Float":0.05}, "immutable":true},
                    {"name":"account", "value":{"Principal":"rrkah-fqaaa-aaaaa-aaaaq-cai"}, "immutable":false}
                ]},
                {"Class":[
                    {"name":"tag", "value":{"Text":"com.origyn.royalty.custom"}, "immutable":true},
                    {"name":"rate", "value":{"Float":0.05}, "immutable":true},
                    {"name":"account", "value":{"Principal":"rrkah-fqaaa-aaaaa-aaaaq-cai"}, "immutable":false}
                ]}
            ]
        }}, "immutable":false},

    }
```

* alternative mappings
    * getMetaDataDip721() -> DIP721MetadataResult query //nyi
    * metadataEXT(Text) -> ?Blob - supports metadata() for legacy support. - the collection properties should be converted to a blob standard that a client can decipher(cbor?/protobuf?); //will have to manage multi chunks //nyi


### Large NFT Assets

```
query chunk_nft_origyn(ChunkRequest = {
        token_id: Text;
        library_id: Text;
        chunk: Nat;
    }) query -> Result<ChunkContent = {
            content: [Nat8]; 
            total_chunks: Nat; 
            current_chunk: Nat
    }, OrigynError>
```

returns chunk of bytes for a resource. #eof will be returned for the last chunk

* alternative mappings
    * DIP721 doesn't seem to currently support pulling chunks
    * EXT doesn't seem to support retrieving more than the first chunk.


### Data API

NFTs hold data inside of them on a per app basis.  Data can be updated by those apps using the following function. Currently only replace actions are supported:

```

    public type NFTUpdateRequest ={
        #replace:{
            token_id: Text;
            data: CandyTypes.CandyValue;
        };
        #update:{// NYI
            token_id: Text;
            app_id: Text;
            update: CandyTypes.UpdateRequest;
        }
    };

update_app_nft_origyn : shared NFTUpdateRequest -> async Result.Result<NFTUpdateResponse, OrigynError>;


read: public/allow/block/roles
write: public/allow/block/roles
permissions: allow/roles -> //perhaps permission changes should be subject to governance?



```

We also provide http_request access to this data via the /info endpoint.  To access restricted data the user must submit an access token in the query string.

To get an access token the user can call the following funciton:

```

http_access_key -> Result.Result<Text, Types.OrigynError>

```

The returned token can be appened to a url request with the ?access=TOKEN format to see restricted information

**NOTE:  Data stored on the IC should not be considered secure. It is possible(though not probable) that node operators could look at the data at rest and see access tokens. The only current method for hiding data from node providers is to encrypt the data before putting it into a canister. It is highly recommended that any personally identifiable information is encrypted before being stored on a canister with a separate and secure decryption system in place.**


    

## Ledger

Transactions for each NFT are held in an NFT history ledger. The collection ledger is held at the token_id ""(empty string).

```

public type TransactionRecord = {
        token_id: Text;
        index: Nat;
        txn_type: {
            #auction_bid : {
                buyer: Account;
                amount: Nat;
                token: TokenSpec;
                sale_id: Text;
                extensible: CandyTypes.CandyValue;
            };
            #mint : {
                from: Account;
                to: Account;
                //nyi: metadata hash
                sale: ?{token: TokenSpec;
                    amount: Nat; //Nat to support cycles
                    };
                extensible: CandyTypes.CandyValue;
            };
            #sale_ended : {
                seller: Account;
                buyer: Account;
               
                token: TokenSpec;
                sale_id: ?Text;
                amount: Nat;//Nat to support cycles
                extensible: CandyTypes.CandyValue;
            };
            #royalty_paid : {
                seller: Account;
                buyer: Account;
                 reciever: Account;
                tag: Text;
                token: TokenSpec;
                sale_id: ?Text;
                amount: Nat;//Nat to support cycles
                extensible: CandyTypes.CandyValue;
            };
            #sale_opened : {
                pricing: PricingConfig;
                sale_id: Text;
                extensible: CandyTypes.CandyValue;
            };
            #owner_transfer : {
                from: Account;
                to: Account;
                extensible: CandyTypes.CandyValue;
            }; 
            #escrow_deposit : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat;//Nat to support cycles
                trx_id: TransactionID;
                extensible: CandyTypes.CandyValue;
            };
            #escrow_withdraw : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat;//Nat to support cycles
                fee: Nat;
                trx_id: TransactionID;
                extensible: CandyTypes.CandyValue;
            };
            #sale_withdraw : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat; //Nat to support cycles
                fee: Nat;
                trx_id: TransactionID;
                extensible: CandyTypes.CandyValue;
            };
            #canister_owner_updated : {
                owner: Principal;
                extensible: CandyTypes.CandyValue;
            };
            #canister_managers_updated : {
                managers: [Principal];
                extensible: CandyTypes.CandyValue;
            };
            #canister_network_updated : {
                network: Principal;
                extensible: CandyTypes.CandyValue;
            };
            #data; //nyi
            #burn;
            #extensible : CandyTypes.CandyValue;

        };
        timestamp: Int;
    };


    history_nft_origyn : shared query (Text, ?Nat, ?Nat) -> async Result.Result<[TransactionRecord],OrigynError>;


```

## Sales

Sales are created using the market_transfer_nft_origyn function.

Sales are managed through the sale_nft_origyn function and information can be retrieved via query using the  sale_info_nft_origyn function.  Both methods have a _batch method for multiple requests and the sale_info query has a secure endpoint as well.


```
    public type ManageSaleRequest = {
        #end_sale : Text; //token_id
        #open_sale: Text; //token_id;
        #escrow_deposit: EscrowRequest;
        #refresh_offers: ?Account;
        #bid: BidRequest;
        #withdraw: WithdrawRequest;
    };

    public type ManageSaleResponse = {
        #end_sale : EndSaleResponse; //trx record if succesful
        #open_sale: Bool; //true if opened, false if not;
        #escrow_deposit: EscrowResponse;
        #refresh_offers: [EscrowRecord];
        #bid: BidResponse;
        #withdraw: WithdrawResponse;
    };

    sale_nft_origyn : shared ManageSaleRequest -> async Result.Result<ManageSaleResponse,OrigynError>;

    public type SaleInfoRequest = {
        #active : ?(Nat, Nat); //get al list of active sales
        #history : ?(Nat, Nat); //skip, take
        #status : Text; //saleID
        #deposit_info : ?Account;
    };

    public type SaleInfoResponse = {
       #active: {
            records: [(Text, ?SaleStatusStable)];
            eof: Bool;
            count: Nat};
        #history : {
            records: [?SaleStatusStable];
            eof: Bool;
            count : Nat};
        #status: ?SaleStatusStable;
        #deposit_info: SubAccountInfo; 
    };

    sale_info_nft_origyn : shared SaleInfoRequest -> async Result.Result<SaleInfoResponse,OrigynError>;

```

### Escrow

All transactions currently require an escrow from the recieving party.  Appraised transfers will be supported in the future where node providers can pay the royalties and collect the out of band.

```

To make a deposit the user must ask for the depoisit info first(like an invoice).  If the Account is null then the info is returned for the caller.  Enough tokens must be sent to cover the deposit + 1 transaction fee;

    public type SubAccountInfo = {
        principal : Principal;
        account_id : Blob;
        account_id_text: Text;
        account: {
            principal: Principal;
            sub_account: Blob;
        };
    };

sale_info_nft_origyn(#deposit_info(?Account)) -> sync Result.Result<SaleInfoResponse,OrigynError>;

Once the tokens are sent to the subaccount on the NFT canister the following is called to claim the deposit:

    public type EscrowRequest = {
        token_id : Text; //empty string for general escrow
        deposit : DepositDetail;
        lock_to_date: ?Int; //timestamp to lock escrow until.
    };

    public type DepositDetail = {
        token : TokenSpec;
        seller: Account;
        buyer : Account;
        amount: Nat; //Nat to support cycles; 
        sale_id: ?Text;
        lock_to_date: ?Int
        trx_id : ?TransactionID; //null for account based ledgers
    };

    public type EscrowReceipt = {
        amount: Nat; //Nat to support cycles
        seller: Account;
        buyer: Account;
        token_id: Text;
        token: TokenSpec;
        
    };

    public type EscrowResponse = {
        receipt: EscrowReceipt;
        balance: Nat; //total balance if an existing escrow was added to
        transaction: TransactionRecord;
    };

    sale_nft_origyn(#escrow_deposit(EscrowRequest)) -> Result.Result<ManageSaleReqsonse(#escrow_deposit: EscrowResponse),OrigynError>
```

### Bids

During auctions, a user can bid on the NFT using the #bid command.

```
    public type BidRequest = {
        escrow_receipt: EscrowReceipt;//should be returned by the escrow_deposit
        sale_id: Text;
        broker_id: ?Principal;
    };

    public type BidResponse = TransactionRecord;


    sale_nft_origyn(ManageSaleRequest(#bid(BidRequest))) -> Result<ManageSaleResponse(#bid(BidResponse)), OrigynError> - places a bid on an nft if the escrow receipt is valid. 

    
```

### Withdrawls

Allows a user to withdraw their escrowed funds from either an Escrow account or a Sales Receipt, or reject an offer and withdraw the funds back to an offerer.

```
    public type WithdrawRequest = { 
        #escrow: WithdrawDescription;
        #sale: WithdrawDescription;
        #reject: RejectDescription;
    };

    public type WithdrawDescription = {
        buyer: Account;
        seller: Account;
        token_id: Text;
        token: TokenSpec;
        amount: Nat;
        withdraw_to : Account;
    };

     public type RejectDescription = {
        buyer: Account;
        seller: Account;
        token_id: Text;
        token: TokenSpec;
    };

    sale_nft_origyn(#withdraw(WithdrawRequest)) -> Result.Result<ManageSaleResponse(#withdraw(Types.WithdrawResponse,Types.OrigynError)> - request a refund of a deposit if possible

```

### Auction Management

Ends an auction and awards the NFT to the winner and the sales price to the seller.

```

    sale_nft_origyn(#open_sale(token_id)) -> async book - open a sale if possible, happens automatically upon bid if made after the sale_date.

    sale_nft_origyn(#end_sale(token_id)) -> ManageSaleResponse(#end_sale : TransactionRecord) - ends a sale if possible, transfers token if possible
```

Refreshing Offers - the offers collection can become stale. The following function can be used to refresh the offers collection and make sure that the offers returned by balance_of_nft_origyn are fresh and still active:


```

    sale_nft_origyn(#refresh_offers: ?Account;)) -> #refresh_offers: [EscrowRecord] - refresh the orders and return the list

```



## Collection Info

Passing null to the following function will get you the current in formation about the collection.  Individual Field requets and pagination will be added in a futur Release

```
    collection_nft_origyn : (fields : ?[(Text, ?Nat, ?Nat)]) -> async Result.Result<CollectionInfo, OrigynError>

    public type CollectionInfo = {
        fields: ?[(Text, ?Nat, ?Nat)];
        logo: ?Text;
        name: ?Text;
        symbol: ?Text;
        total_supply: ?Nat;
        owner: ?Principal;
        managers: ?[Principal];
        network: ?Principal;
        token_ids: ?[Text];
        token_ids_count: ?Nat;
        multi_canister: ?[Principal];
        multi_canister_count: ?Nat;
        metadata: ?CandyTypes.CandyValue;
        allocated_storage : ?Nat;
        available_space : ?Nat;
    };

```

Collection updates are handled witht collection_update_nft_origyn


```
    public type ManageCollectionCommand = {
        #UpdateManagers : [Principal];
        #UpdateOwner : Principal;
        #UpdateNetwork : ?Principal;
        #UpdateLogo : ?Text;
        #UpdateName : ?Text;
        #UpdateSymbol : ?Text;
        #UpdateMetadata: (Text, ?CandyTypes.CandyValue, Bool);
    };


    collection_update_nft_origyn : (ManageCollectionCommand) -> async Result.Result<Bool, OrigynError>;
        collection_update_batch_nft_origyn : ([ManageCollectionCommand]) -> async [Result.Result<Bool, OrigynError>];

```

Collections can have their storage increased by manually adding storage canisters to the storage array:

```

public type ManageStorageRequest = {
        #add_storage_canisters : [(Principal, Nat, (Nat, Nat, Nat))];  [(Principal of item, Space, version of canister)] 
    };

manage_storage_nft_origyn : shared ManageStorageRequest -> async Result.Result<ManageStorageResponse, OrigynError>;


```

Storage info can be pulled with the below

```

    public type StorageMetrics = {
        allocated_storage: Nat;
        available_space: Nat;
        allocations: [AllocationRecordStable];
    };

    public type AllocationRecordStable = {
        canister : Principal;
        allocated_space: Nat;
        available_space: Nat;
        chunks: [Nat];
        token_id: Text;
        library_id: Text;
    };

    query storage_info_nft_origyn() : async Result.Result<Types.StorageMetrics, Types.OrigynError>
    storage_info_secure_nft_origyn() : async Result.Result<Types.StorageMetrics, Types.OrigynError>

```


## Extensibility

Returns the supported interfaces for the NFT canister

```
__supports() query -> [Text]
    [
    ("nft_origyn","v0.1.0"),
    ("data_nft_origyn","v0.1.0"),
    ("collection_nft_origyn","v0.1.0"),
    ("mint_nft_origyn","v0.1.0"),
    ("owner_nft_origyn","v0.1.0"),
    ("market_nft_origyn","v0.1.0")]

```

 

```
Features:
    nft_origyn
    history_nft_origyn
    mint_nft_origyn
    burn_nft_origyn
    notify_nft_origyn
```

### nft_origyn
    nft_origyn(Text) query -> async Result.Result<Types.NFTInfoStable, Types.OrigynError>
    nft_secure_origyn(token_id : Text) : async Result.Result<Types.NFTInfoStable, Types.OrigynError>
    nft_batch_origyn(Text) query -> async [Result.Result<Types.NFTInfoStable, Types.OrigynError>]
    nft_batch_secure_origyn(token_ids : [Text]) : async [Result.Result<Types.NFTInfoStable, Types.OrigynError>]
    chunk_nft_origyn(request : Types.ChunkRequest) query -> async Result.Result<Types.ChunkContent, Types.OrigynError>
    balance_of_nft_origyn(account: Types.Account) query -> async Result.Result<Types.BalanceResponse, Types.OrigynError>
    balance_of_secure_nft_origyn(account: Types.Account) : async Result.Result<Types.BalanceResponse, Types.OrigynError>
    bearer_nft_origyn(Text) query -> async Result.Result<Types.Account, Types.OrigynError>
    bearer_secure_nft_origyn(token_id : Text) : async Result.Result<Types.Account, Types.OrigynError>
    bearer_batch_nft_origyn([Text]) query -> async [Result.Result<Types.Account, Types.OrigynError>]
    bearer_batch_secure_nft_origyn([Text]) query -> async [Result.Result<Types.Account, Types.OrigynError>]
    get_token_id_as_nat_origyn(Text) query -> async Nat
    get_nat_as_token_id_origyn(Nat) query -> async Text
    
    //standard support
    balanceOfDip721(user: Principal) query ->  async Nat
    balance(request: EXT.BalanceRequest) query -> async EXT.BalanceResponse
    balanceEXT(request: EXT.BalanceRequest) query -> async EXT.BalanceResponse
    getEXTTokenIdentifier query -> async Text
    ownerOfDIP721(tokenAsNat: Nat) query -> async DIP721.OwnerOfResponse
    ownerOf(tokenAsNat: Nat) query -> async DIP721.OwnerOfResponse
    bearerEXT(tokenIdentifier: EXT.TokenIdentifier) query-> async Result.Result<EXT.AccountIdentifier, EXT.CommonError>
    bearer(tokenIdentifier: EXT.TokenIdentifier) query -> async Result.Result<EXT.AccountIdentifier, EXT.CommonError>
    metadata(token : EXT.TokenIdentifier) query :  async Result.Result<EXTCommon.Metadata,EXT.CommonError>

### history_nft_origyn
    history_nft_origyn (token_id : Text, start: ?Nat, end: ?Nat) query -> async Result.Result<[Types.TransactionRecord],Types.OrigynError>

### data_nft_origyn
    update_app_nft_origyn : (Types.NFTUpdateRequest) -> async Result.Result<Types.NFTUpdateResponse, Types.OrigynError>

### collection_nft_origyn
    collection_update_origyn(Types.CollectionUpdateRequest) -> async Result.Result<Bool, Types.OrigynError>
    manage_storage_nft_origyn(Types.ManageStorageRequest)->async Result.Result<Types.ManageStorageResponse, Types.OrigynError>
    collection_nft_origyn(fields : ?[(Text,?Nat, ?Nat)]) query -> async Result.Result<Types.CollectionInfo, Types.OrigynError>
    storage_info_nft_origyn : shared query () -> async Result.Result<StorageMetrics, OrigynError>
    storage_info_secure_nft_origyn() : async Result.Result<Types.StorageMetrics, Types.OrigynError>

### mint_nft_origyn
    stage_nft_origyn({metadata: CandyTypes.CandyValue}) -> async Result.Result<Text, Types.OrigynError>
    stage_batch_nft_origyn([{metadata: CandyTypes.CandyValue}]) -> async [Result.Result<Text, Types.OrigynError>]
    stage_library_nft_origyn(Types.StageChunkArg)-> async Result.Result<Types.StageLibraryResponse,Types.OrigynError>
    mint_nft_origyn(token_id: Text, new_owner : Types.Account) -> async Result.Result<Text,Types.OrigynError>
    mint_batch_nft_origyn([(Text, Types.Account)]) -> async [Result.Result<Text,Types.OrigynError>]

### owner_nft_origyn
    share_wallet_nft_origyn(Types.ShareWalletRequest) -> async Result.Result<Types.OwnerTransferResponse,Types.OrigynError>

### market_nft_origyn
    sale_nft_origyn : shared ManageSaleRequest -> async Result.Result<ManageSaleResponse,OrigynError>;
        sale_info_nft_origyn : shared SaleInfoRequest -> async Result.Result<SaleInfoResponse,OrigynError>;
    market_transfer_nft_origyn ( Types.MarketTransferRequest) -> async Result.Result<Types.MarketTransferRequestReponse,Types.OrigynError>
    market_transfer_batch_nft_origyn ( [Types.MarketTransferRequest]) -> async [Result.Result<Types.MarketTransferRequestReponse,Types.OrigynError>]
    transferDip721(from: Principal, to: Principal, tokenAsNat: Nat) -> async DIP721.Result
    transferFromDip721(from: Principal, to: Principal, tokenAsNat: Nat) -> async DIP721.Result
    transferFrom(from: Principal, to: Principal, tokenAsNat: Nat) -> async DIP721.Result
    transferEXT(request: EXT.TransferRequest) -> async EXT.TransferResponse
    transfer(request: EXT.TransferRequest) -> async EXT.TransferResponse
    

## Types

```

    // migration state

    public type CollectionData = {
        var logo: ?Text;
        var name: ?Text;
        var symbol: ?Text;
        var metadata: ?CandyTypes.CandyValue;
        var owner : Principal;
        var managers: [Principal];
        var network: ?Principal;
        var allocated_storage: Nat;
        var available_space : Nat;
        var active_bucket: ?Principal;
    };

    public type BucketData = {  
        principal : Principal;
        var allocated_space: Nat;
        var available_space: Nat;
        date_added: Int;
        b_gateway: Bool;
        var version: (Nat, Nat, Nat);
        var allocations: Map.Map<(Text,Text), Int>; // (token_id, library_id), Timestamp
    };

    public type AllocationRecord = {
        canister : Principal;
        allocated_space: Nat;
        var available_space: Nat;
        var chunks: SB.StableBuffer<Nat>;
        token_id: Text;
        library_id: Text;
    };

    public type LogEntry = {
        event : Text;
        timestamp: Int;
        data: CandyTypes.CandyValue;
        caller: ?Principal;
    };

    public type SalesSellerTrie = Map.Map<Nat32, 
                                    Map.Map<Nat32,
                                        Map.Map<Text,
                                            Map.Map<Nat32,EscrowRecord>>>>;
                                        

    public type SalesBuyerTrie = Map.Map<Nat32,
                                Map.Map<Text,
                                    Map.Map<Nat32,EscrowRecord>>>;

    public type EscrowBuyerTrie = Map.Map<Nat32, 
                                    Map.Map<Nat32,
                                        Map.Map<Text,
                                            Map.Map<Nat32,EscrowRecord>>>>;

    public type EscrowSellerTrie = Map.Map<Nat32,
                                Map.Map<Text,
                                    Map.Map<Nat32,EscrowRecord>>>;
    
    public type EscrowTokenIDTrie = Map.Map<Text,
                                        Map.Map<Nat32,EscrowRecord>>;

    public type EscrowLedgerTrie = Map.Map<Nat32,EscrowRecord>;

    public type Account = {
        #principal : Principal;
        #account : {owner: Principal; sub_account: ?Blob};
        #account_id : Text;
        #extensible : CandyTypes.CandyValue;
    };

    public type EscrowRecord = {
        amount: Nat;
        buyer: Account; 
        seller:Account; 
        token_id: Text; 
        token: TokenSpec;
        sale_id: ?Text; //locks the escrow to a specific sale
        lock_to_date: ?Int; //locks the escrow to a timestamp
        account_hash: ?Blob; //sub account the host holds the funds in
    };

    public type TokenSpec = {
        #ic: ICTokenSpec;
        #extensible : CandyTypes.CandyValue; //#Class
    };

    public type ICTokenSpec = {
        canister: Principal;
        fee: Nat;
        symbol: Text;
        decimals: Nat;
        standard: {
            #DIP20;
            #Ledger;
            #EXTFungible;
            #ICRC1;
        };
    };

    public type PricingConfig = {
        #instant; //executes an escrow recipt transfer -only available for non-marketable NFTs
        #flat: {
            token: TokenSpec;
            amount: Nat; //Nat to support cycles
        };
        //below have not been signficantly desinged or vetted
        #dutch: {
            start_price: Nat;
            decay_per_hour: Float;
            reserve: ?Nat;
        };
        #auction: AuctionConfig;
        #extensible:{
            #candyClass
        }
    };

    public type AuctionConfig = {
            reserve: ?Nat;
            token: TokenSpec;
            buy_now: ?Nat;
            start_price: Nat;
            start_date: Int;
            ending: {
                #date: Int;
                #waitForQuiet: {
                    date: Int;
                    extention: Nat64;
                    fade: Float;
                    max: Nat
                };
            };
            min_increase: {
                #percentage: Float;
                #amount: Nat;
            };
            allow_list : ?[Principal];
        };

    public type TransactionRecord = {
        token_id: Text;
        index: Nat;
        txn_type: {
            #auction_bid : {
                buyer: Account;
                amount: Nat;
                token: TokenSpec;
                sale_id: Text;
                extensible: CandyTypes.CandyValue;
            };
            #mint : {
                from: Account;
                to: Account;
                //nyi: metadata hash
                sale: ?{token: TokenSpec;
                    amount: Nat; //Nat to support cycles
                    };
                extensible: CandyTypes.CandyValue;
            };
            #sale_ended : {
                seller: Account;
                buyer: Account;
               
                token: TokenSpec;
                sale_id: ?Text;
                amount: Nat;//Nat to support cycles
                extensible: CandyTypes.CandyValue;
            };
            #royalty_paid : {
                seller: Account;
                buyer: Account;
                 reciever: Account;
                tag: Text;
                token: TokenSpec;
                sale_id: ?Text;
                amount: Nat;//Nat to support cycles
                extensible: CandyTypes.CandyValue;
            };
            #sale_opened : {
                pricing: PricingConfig;
                sale_id: Text;
                extensible: CandyTypes.CandyValue;
            };
            #owner_transfer : {
                from: Account;
                to: Account;
                extensible: CandyTypes.CandyValue;
            }; 
            #escrow_deposit : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat;//Nat to support cycles
                trx_id: TransactionID;
                extensible: CandyTypes.CandyValue;
            };
            #escrow_withdraw : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat;//Nat to support cycles
                fee: Nat;
                trx_id: TransactionID;
                extensible: CandyTypes.CandyValue;
            };
            #sale_withdraw : {
                seller: Account;
                buyer: Account;
                token: TokenSpec;
                token_id: Text;
                amount: Nat; //Nat to support cycles
                fee: Nat;
                trx_id: TransactionID;
                extensible: CandyTypes.CandyValue;
            };
            #canister_owner_updated : {
                owner: Principal;
                extensible: CandyTypes.CandyValue;
            };
            #canister_managers_updated : {
                managers: [Principal];
                extensible: CandyTypes.CandyValue;
            };
            #canister_network_updated : {
                network: Principal;
                extensible: CandyTypes.CandyValue;
            };
            #data; //nyi
            #burn;
            #extensible : CandyTypes.CandyValue;

        };
        timestamp: Int;
    };

    //used to identify the transaction in a remote ledger; usually a nat on the IC
    public type TransactionID = {
        #nat : Nat;
        #text : Text;
        #extensible : CandyTypes.CandyValue
    };

    public type SaleStatus = {
        sale_id: Text; //sha256?;
        original_broker_id: ?Principal;
        broker_id: ?Principal;
        token_id: Text;
        sale_type: {
            #auction: AuctionState;
        };
    };

    public type EscrowReceipt = {
        amount: Nat; //Nat to support cycles
        seller: Account;
        buyer: Account;
        token_id: Text;
        token: TokenSpec;
        
    };

    public type AuctionState = {
                config: PricingConfig;
                var current_bid_amount: Nat;
                var current_broker_id: ?Principal;
                var end_date: Int;
                var min_next_bid: Nat;
                var current_escrow: ?EscrowReceipt;
                var wait_for_quiet_count: ?Nat;
                var allow_list: ?Map.Map<Principal,Bool>; //empty set means everyone
                var participants: Map.Map<Principal,Int>;
                var status: {
                    #open;
                    #closed;
                    #not_started;
                };
                var winner: ?Account;
            };


    //types

       public type InitArgs = {
        owner: Principal.Principal;
        storage_space: ?Nat;
    };

    public type StorageInitArgs = {
        gateway_canister: Principal;
        network: ?Principal;
        storage_space: ?Nat;
    };

    public type StorageMigrationArgs = {
        gateway_canister: Principal;
        network: ?Principal;
        storage_space: ?Nat;
        caller: Principal;
    };

    public type ManageCollectionCommand = {
        #UpdateManagers : [Principal];
        #UpdateOwner : Principal;
        #UpdateNetwork : ?Principal;
        #UpdateLogo : ?Text;
        #UpdateName : ?Text;
        #UpdateSymbol : ?Text;
        #UpdateMetadata: (Text, ?CandyTypes.CandyValue, Bool);
    };

    // RawData type is a tuple of Timestamp, Data, and Principal
    public type RawData = (Int, Blob, Principal);

    public type HttpRequest = {
        body: Blob;
        headers: [HeaderField];
        method: Text;
        url: Text;
    };

    public type StreamingCallbackToken =  {
        content_encoding: Text;
        index: Nat;
        key: Text;
        //sha256: ?Blob;
    };
    public type StreamingCallbackHttpResponse = {
        body: Blob;
        token: ?StreamingCallbackToken;
    };
    public type ChunkId = Nat;
    public type SetAssetContentArguments = {
        chunk_ids: [ChunkId];
        content_encoding: Text;
        key: Key;
        sha256: ?Blob;
    };
    public type Path = Text;
    public type Key = Text;

    public type HttpResponse = {
        body: Blob;
        headers: [HeaderField];
        status_code: Nat16;
        streaming_strategy: ?StreamingStrategy;
    };

    public type StreamingStrategy = {
       #Callback: {
          callback: shared () -> async ();
          token: StreamingCallbackToken;
        };
    };

    public type HeaderField = (Text, Text);

    public type canister_id = Principal;

    public type definite_canister_settings = {
        freezing_threshold : Nat;
        controllers : ?[Principal];
        memory_allocation : Nat;
        compute_allocation : Nat;
    };

    public type canister_status = {
        status : { #stopped; #stopping; #running };
        memory_size : Nat;
        cycles : Nat;
        settings : definite_canister_settings;
        module_hash : ?[Nat8];
    };

    public type IC = actor {
        canister_status : { canister_id : canister_id } -> async canister_status;
    };

    public type StageChunkArg = {
        token_id: Text;
        library_id: Text;
        filedata: CandyTypes.CandyValue;
        chunk: Nat;
        content: Blob;
    };


    public type ChunkRequest = {
        token_id: Text;
        library_id: Text;
        chunk: ?Nat;
    };

    public type ChunkContent = {
        #remote : {
            canister: Principal;
            args: ChunkRequest;
        };
        #chunk : {
            content: Blob;
            total_chunks: Nat; 
            current_chunk: ?Nat;
            storage_allocation: AllocationRecordStable;
        };
    };

    public type MarketTransferRequest = {
        token_id: Text;
        sales_config: SalesConfig;
    };

    public type OwnerTransferResponse = {
        transaction: TransactionRecord;
        assets: [CandyTypes.CandyValue];
    };

    public type ShareWalletRequest = {
        token_id: Text;
        from: Account;
        to: Account;
    };

    public type SalesConfig = {
        escrow_receipt : ?EscrowReceipt;
        broker_id : ?Principal;
        pricing: PricingConfig;
    };

    public type ICTokenSpec = MigrationTypes.Current.ICTokenSpec;

    public type TokenSpec = MigrationTypes.Current.TokenSpec;

    public let TokenSpecDefault = #extensible(#Empty);


    //nyi: anywhere a deposit address is used, check blob for size in inspect message
    public type SubAccountInfo = {
        principal : Principal;
        account_id : Blob;
        account_id_text: Text;
        account: {
            principal: Principal;
            sub_account: Blob;
        };
    };

    public type EscrowReceipt = MigrationTypes.Current.EscrowReceipt;

    public type EscrowRequest = {
        token_id : Text; //empty string for general escrow
        deposit : DepositDetail;
        lock_to_date: ?Int; //timestamp to lock escrow until.
    };

    public type DepositDetail = {
        token : TokenSpec;
        seller: Account;
        buyer : Account;
        amount: Nat; //Nat to support cycles; 
        sale_id: ?Text;
        trx_id : ?TransactionID; //null for account based ledgers
    };

    //used to identify the transaction in a remote ledger; usually a nat on the IC
    public type TransactionID = MigrationTypes.Current.TransactionID;

    public type EscrowResponse = {
        receipt: EscrowReceipt;
        balance: Nat;
        transaction: TransactionRecord;
    };

    public type BidRequest = {
        escrow_receipt: EscrowReceipt;
        sale_id: Text;
        broker_id: ?Principal;
    };

    public type BidResponse = TransactionRecord;

    public type PricingConfig = MigrationTypes.Current.PricingConfig;

    public type AuctionConfig = MigrationTypes.Current.AuctionConfig;


    public let AuctionConfigDefault = {
        reserve = null;
        token = TokenSpecDefault;
        buy_now = null;
        start_price = 0;
        start_date = 0;
        ending = #date(0);
        min_increase = #amount(0);
    };

    public type NFTInfoStable = {
        current_sale : ?SaleStatusStable;
        metadata : CandyTypes.CandyValue;
    };

    

    public type AuctionState = MigrationTypes.Current.AuctionState;


    public type SaleStatus = MigrationTypes.Current.SaleStatus;

    public type SaleStatusStable = {
        sale_id: Text; //sha256?;
        original_broker_id: ?Principal;
        broker_id: ?Principal;
        token_id: Text;
        sale_type: {
            #auction: AuctionStateStable;
        };
    };

    public type MarketTransferRequestReponse = TransactionRecord;
    
    public type Account = MigrationTypes.Current.Account;

    public type HttpAccess= {
        identity: Principal;
        expires: Time.Time;
    };

    

    public type StorageMetrics = {
        allocated_storage: Nat;
        available_space: Nat;
        allocations: [AllocationRecordStable];
    };


    public type BucketData = {
        principal : Principal;
        var allocated_space: Nat;
        var available_space: Nat;
        date_added: Int;
        b_gateway: Bool;
        var version: (Nat, Nat, Nat);
        var allocations: Map.Map<(Text,Text), Int>; // (token_id, library_id), Timestamp
    };

    public type AllocationRecord = {
        canister : Principal;
        allocated_space: Nat;
        var available_space: Nat;
        var chunks: SB.StableBuffer<Nat>;
        token_id: Text;
        library_id: Text;
    };

    public type AllocationRecordStable = {
        canister : Principal;
        allocated_space: Nat;
        available_space: Nat;
        chunks: [Nat];
        token_id: Text;
        library_id: Text;
    };

    public func allocation_record_stabalize(item:AllocationRecord) : AllocationRecordStable{
        {canister = item.canister;
        allocated_space = item.allocated_space;
        available_space = item.available_space;
        chunks = SB.toArray<Nat>(item.chunks);
        token_id = item.token_id;
        library_id = item. library_id;}
    };

    public type TransactionRecord = MigrationTypes.Current.TransactionRecord;

    public type NFTUpdateRequest ={
        #replace:{
            token_id: Text;
            data: CandyTypes.CandyValue;
        };
        #update:{
            token_id: Text;
            app_id: Text;
            update: CandyTypes.UpdateRequest;
        }
    };

    public type NFTUpdateResponse = Bool;

    public type EndSaleResponse = TransactionRecord;

    public type EscrowRecord = MigrationTypes.Current.EscrowRecord;

    public type ManageSaleRequest = {
        #end_sale : Text; //token_id
        #open_sale: Text; //token_id;
        #escrow_deposit: EscrowRequest;
        #refresh_offers: ?Account;
        #bid: BidRequest;
        #withdraw: WithdrawRequest;
    };

    public type ManageSaleResponse = {
        #end_sale : EndSaleResponse; //trx record if succesful
        #open_sale: Bool; //true if opened, false if not;
        #escrow_deposit: EscrowResponse;
        #refresh_offers: [EscrowRecord];
        #bid: BidResponse;
        #withdraw: WithdrawResponse;
    };

    public type SaleInfoRequest = {
        #active : ?(Nat, Nat); //get al list of active sales
        #history : ?(Nat, Nat); //skip, take
        #status : Text; //saleID
        #deposit_info : ?Account;
    };

    public type SaleInfoResponse = {
       #active: {
            records: [(Text, ?SaleStatusStable)];
            eof: Bool;
            count: Nat};
        #history : {
            records: [?SaleStatusStable];
            eof: Bool;
            count : Nat};
        #status: ?SaleStatusStable;
        #deposit_info: SubAccountInfo; 
    };

    

    public type StakeRecord = {amount: Nat; staker: Account; token_id: Text;};

    public type BalanceResponse = {
        multi_canister: ?[Principal];
        nfts: [Text];
        escrow: [EscrowRecord];
        sales: [EscrowRecord];
        stake: [StakeRecord];
        offers: [EscrowRecord];
    };

    public type LocalStageLibraryResponse = {
        #stage_remote : {
            allocation :AllocationRecord;
            metadata: CandyTypes.CandyValue;
        };
        #staged : Principal;
    };

    public type StageLibraryResponse = {
        canister: Principal;
    };

    public type WithdrawDescription = {
        buyer: Account;
        seller: Account;
        token_id: Text;
        token: TokenSpec;
        amount: Nat;
        withdraw_to : Account;
    };

     public type RejectDescription = {
        buyer: Account;
        seller: Account;
        token_id: Text;
        token: TokenSpec;
    };

    public type WithdrawRequest = { 
        #escrow: WithdrawDescription;
        #sale: WithdrawDescription;
        #reject:RejectDescription;
    };
    

    public type WithdrawResponse = TransactionRecord;

    public type CollectionInfo = {
        fields: ?[(Text, ?Nat, ?Nat)];
        logo: ?Text;
        name: ?Text;
        symbol: ?Text;
        total_supply: ?Nat;
        owner: ?Principal;
        managers: ?[Principal];
        network: ?Principal;
        token_ids: ?[Text];
        token_ids_count: ?Nat;
        multi_canister: ?[Principal];
        multi_canister_count: ?Nat;
        metadata: ?CandyTypes.CandyValue;
        allocated_storage : ?Nat;
        available_space : ?Nat;
    };

    public type CollectionData = {
        var logo: ?Text;
        var name: ?Text;
        var symbol: ?Text;
        var metadata: ?CandyTypes.CandyValue;
        var owner : Principal;
        var managers: [Principal];
        var network: ?Principal;
        var allocated_storage: Nat;
        var available_space : Nat;
        var active_bucket: ?Principal;
    };

    public type CollectionDataForStorage = {

        var owner : Principal;
        var managers: [Principal];
        var network: ?Principal;

    };

    public type ManageStorageRequest = {
        #add_storage_canisters : [(Principal, Nat, (Nat, Nat, Nat))];
    };

    public type ManageStorageResponse = {
        #add_storage_canisters : (Nat,Nat);//space allocated, space available
    };

    public type LogEntry = {
        event : Text;
        timestamp: Int;
        data: CandyTypes.CandyValue;
        caller: ?Principal;
    };

    public type OrigynError = {number : Nat32; text: Text; error: Errors; flag_point: Text;};

    public type Errors = {
        #app_id_not_found;
        #asset_mismatch;
        #attempt_to_stage_system_data;
        #auction_ended;
        #auction_not_started;
        #bid_too_low;
        #cannot_find_status_in_metadata;
        #cannot_restage_minted_token;
        #content_not_deserializable;
        #content_not_found;
        #deposit_burned;
        #escrow_cannot_be_removed;
        #escrow_owner_not_the_owner;
        #escrow_withdraw_payment_failed;
        #existing_sale_found;
        #id_not_found_in_metadata;
        #improper_interface;
        #item_already_minted;
        #item_not_owned;
        #library_not_found;
        #malformed_metadata;
        #no_escrow_found;
        #not_enough_storage;
        #out_of_range;
        #owner_not_found;
        #property_not_found;
        #receipt_data_mismatch;
        #sale_not_found;
        #sale_not_over;
        #sale_id_does_not_match;
        #sales_withdraw_payment_failed;
        #storage_configuration_error;
        #token_not_found;
        #token_id_mismatch;
        #token_non_transferable;
        #unauthorized_access;
        #unreachable;
        #update_class_error;
        #validate_deposit_failed;
        #validate_deposit_wrong_amount;
        #validate_deposit_wrong_buyer;
        #validate_trx_wrong_host;
        #withdraw_too_large;
        #nyi;

    };

    public type HTTPResponse = {
        body               : Blob;
        headers            : [HeaderField];
        status_code        : Nat16;
        streaming_strategy : ?StreamingStrategy;
    };

    

    public type StreamingCallback = query (StreamingCallbackToken) -> async (StreamingCallbackResponse);

    

    public type StreamingCallbackResponse = {
        body  : Blob;
        token : ?StreamingCallbackToken;
    };

    public type StorageService = actor{
        stage_library_nft_origyn : shared (StageChunkArg, AllocationRecordStable, CandyTypes.CandyValue) -> async Result.Result<StageLibraryResponse,OrigynError>;
        storage_info_nft_origyn : shared query () -> async Result.Result<StorageMetrics, OrigynError>;
        chunk_nft_origyn : shared query ChunkRequest -> async Result.Result<ChunkContent, OrigynError>;
        refresh_metadata_nft_origyn : (token_id: Text, metadata: CandyTypes.CandyValue) -> async Result.Result<Bool, OrigynError>
    };

    public type Service = actor {
        __advance_time : shared Int -> async Int;
        __set_time_mode : shared { #test; #standard } -> async Bool;
        balance : shared query EXT.BalanceRequest -> async BalanceResponse;
        balanceEXT : shared query EXT.BalanceRequest -> async BalanceResponse;
        balanceOfDip721 : shared query Principal -> async Nat;
        balance_of_nft_origyn : shared query Account -> async Result.Result<BalanceResponse, OrigynError>;
        bearer : shared query EXT.TokenIdentifier -> async Result.Result<Account, OrigynError>;
        bearerEXT : shared query EXT.TokenIdentifier -> async Result.Result<Account, OrigynError>;
        bearer_nft_origyn : shared query Text -> async Result.Result<Account, OrigynError>;
        bearer_batch_nft_origyn : shared query [Text] -> async [Result.Result<Account, OrigynError>];
        bearer_secure_nft_origyn : shared Text -> async Result.Result<Account, OrigynError>;
        bearer_batch_secure_nft_origyn : shared [Text] -> async [Result.Result<Account, OrigynError>];
        canister_status : shared {
            canister_id : canister_id;
        } -> async canister_status;
        collection_nft_origyn : (fields : ?[(Text, ?Nat, ?Nat)]) -> async Result.Result<CollectionInfo, OrigynError>;
        collection_update_nft_origyn : (ManageCollectionCommand) -> async Result.Result<Bool, OrigynError>;
        collection_update_batch_nft_origyn : ([ManageCollectionCommand]) -> async [Result.Result<Bool, OrigynError>];
        cycles : shared query () -> async Nat;
        getEXTTokenIdentifier : shared query Text -> async Text;
        get_nat_as_token_id : shared query Nat -> async Text;
        get_token_id_as_nat : shared query Text -> async Nat;
        http_request : shared query HttpRequest -> async HTTPResponse;
        http_request_streaming_callback : shared query StreamingCallbackToken -> async StreamingCallbackResponse;
        manage_storage_nft_origyn : shared ManageStorageRequest -> async Result.Result<ManageStorageResponse, OrigynError>;
        market_transfer_nft_origyn : shared MarketTransferRequest -> async Result.Result<MarketTransferRequestReponse,OrigynError>;
        market_transfer_batch_nft_origyn : shared [MarketTransferRequest] -> async [Result.Result<MarketTransferRequestReponse,OrigynError>];
        mint_nft_origyn : shared (Text, Account) -> async Result.Result<Text,OrigynError>;
        nftStreamingCallback : shared query StreamingCallbackToken -> async StreamingCallbackResponse;
        chunk_nft_origyn : shared query ChunkRequest -> async Result.Result<ChunkContent, OrigynError>;
        history_nft_origyn : shared query (Text, ?Nat, ?Nat) -> async Result.Result<[TransactionRecord],OrigynError>;
        nft_origyn : shared query Text -> async Result.Result<NFTInfoStable, OrigynError>;
        update_app_nft_origyn : shared NFTUpdateRequest -> async Result.Result<NFTUpdateResponse, OrigynError>;
        ownerOf : shared query Nat -> async DIP721.OwnerOfResponse;
        ownerOfDIP721 : shared query Nat -> async DIP721.OwnerOfResponse;
        share_wallet_nft_origyn : shared ShareWalletRequest -> async Result.Result<OwnerTransferResponse,OrigynError>;
        sale_nft_origyn : shared ManageSaleRequest -> async Result.Result<ManageSaleResponse,OrigynError>;
        sale_info_nft_origyn : shared SaleInfoRequest -> async Result.Result<SaleInfoResponse,OrigynError>;
        stage_library_nft_origyn : shared StageChunkArg -> async Result.Result<StageLibraryResponse,OrigynError>;
        stage_nft_origyn : shared { metadata : CandyTypes.CandyValue } -> async Result.Result<Text, OrigynError>;
        storage_info_nft_origyn : shared query () -> async Result.Result<StorageMetrics, OrigynError>;
        transfer : shared EXT.TransferRequest -> async EXT.TransferResponse;
        transferEXT : shared EXT.TransferRequest -> async EXT.TransferResponse;
        transferFrom : shared (Principal, Principal, Nat) -> async DIP721.Result;
        transferFromDip721 : shared (Principal, Principal, Nat) -> async DIP721.Result;
        whoami : shared query () -> async Principal;
    };


//DIP721 Types

    type DIP721OwnerResult = {
        #Err: DIP721ApiError;
        #Ok: Principal;
    };

    type DIP721APIError = {
        #Unauthorized;
        #InvalidTokenId;
        #ZeroAddress;
        #Other;
    };

    type TxReceipt ={
        #Err: DIP721APIError;
        #Ok: nat;
    };

    type DIP721InterfaceId =
        variant {
        Approval;
        TransactionHistory;
        Mint;
        Burn;
        TransferNotification;
    };

    type DIP721ExtendedMetadataResult =
    record {
        metadata_desc: DIP721MetadataDesc;
        token_id: nat64;
    };
    type DIP721MetadataResult =
    variant {
        Err: DIP721ApiError;
        Ok: DIP721MetadataDesc;
    };

    type DIP721MetadataDesc = vec DIP721MetadataPart;

    type MetadataPart =
        record {
            purpose: DIP721MetadataPurpose;
            key_val_data: vec DIP721MetadataKeyVal;
            data: blob;
    };

    type DIP721MetadataPurpose =
        variant {
            Preview; // used as a preview, can be used as preivew in a wallet
            Rendered; // used as a detailed version of the NFT
        };

    type DIP721MetadataKeyVal =
    record {
        text;
        DIP721MetadataVal;
    };

    type DIP721MetadataVal =
    variant {
        TextContent : Text;
        BlobContent : blob;
        NatContent : Nat;
        Nat8Content: Nat8;
        Nat16Content: Nat16;
        Nat32Content: Nat32;
        Nat64Content: Nat64;
    };


    // EXT Types

    type EXTBalanceRequest = { 
        user : EXTUser; 
        token: EXTTokenIdentifier;
    };

    // A user can be any principal or canister, which can hold a balance
    type EXTUser = {
        #address : EXTAccountIdentifier; //No notification
        #principal : Principal; //defaults to sub account 0
    };

    type EXTAccountIdentifier = Text;
    type SubAccount = [Nat8];

    type CommonError = {
        #InvalidToken: Text;
        #Other : Text;
    };

    type EXTTransferRequest = {
        from : EXTUser;
        to : EXTUser;
        token : Text;
        amount : Nat;
        memo : Blob;
        notify : Bool;
        subaccount : ?[Nat8];
    };
    type EXTTransferResponse = Result<Balance, {
        #Unauthorized: EXTAccountIdentifier;
        #InsufficientBalance;
        #Rejected; //Rejected by canister
        #InvalidToken: Text;
        #CannotNotify: EXTAccountIdentifier;
        #Other : Text;
    }>;

    type EXTMetadata = {
        #fungible : {
            name : Text;
            symbol : Text;
            decimals : Nat8;
            metadata : ?Blob;
        };
        #nonfungible : {
            metadata : ?Blob;
        };
    };

```


### Http NFT Information

exos.host/_/canister_id/_/token_id - Returns the primary asset

exos.host/_/canister_id/_/token_id/preview - Returns the preview asset

exos.host/_/canister_id/_/token_id/ex - Origyn NFTs are self contained internet addressable objects. All the data for rendering is contained inside the NFT(Authors can choose to host data on other platforms). Returns an HTML interface that displays the NFT according to the NFT authors specification. 

exos.host/_/canister_id/_/token_id/_/library_id - Returns the asset in the library

exos.host/_/canister_id/_/token_id/_/library_id/info - Returns a json representation of assets in the library

exos.host/_/canister_id/_/token_id/info - Returns a json representation of the metadata, including the library items

exos.host/_/canister_id/_/token_id/info?query=[Query] - Returns a json representation of the metadata passed through a query

### Collection Information

exos.host/_/canister_id/collection - Returns a json representation of collection information





