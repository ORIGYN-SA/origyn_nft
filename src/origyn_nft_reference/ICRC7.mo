module {

  //this file contains types needed to provide responses to DIP721 style NFT commands
  public type Subaccount = Blob;
  public type Account = {
    owner : Principal; 
    subaccount : ?Subaccount; 
  };

  public type Value = {
     #Nat : Nat; 
     #Int : Int; 
     #Text : Text; 
     #Blob : Blob;
     #Array : [Value];
     #Map : [(Text, Value)];
  };

  public type TransferArgs = {
    spender_subaccount : ?Blob;
    from : Account;     /* if supplied and is not caller then is permit transfer, if not supplied defaults to subaccount 0 of the caller principal */
    to : Account;
    token_ids : [Nat];
    memo : ?Blob;
    created_at_time : ?Nat64;
  };

  public type TransferError = {
    #Unauthorized;
    #NonExistingTokenId;
    #TooOld;
    #CreatedInFuture : { ledger_time: Nat64 };
    #Duplicate : { duplicate_of : Nat };
    #GenericError : { error_code : Nat; message : Text };
  };

  public type TransferResultItem = {token_id: Nat; transfer_result: {#Ok: Nat; #Err: TransferError}};
  public type TransferResult = [TransferResultItem];

  public type ApprovalResult = [{token_id: Nat; approval_result : {#Ok: Nat; #Err: ApprovalError}}];
  public type ApproveCollectionResult = {#Ok: Nat; #Err: ApproveCollectionError};

  public type ApprovalArgs = {
    from_subaccount : ?Blob;
    spender : Account;
    memo : ?Blob;
    expires_at : ?Nat64;
    created_at_time : ?Nat64;
  };

  public type ApprovalError = {
    #Unauthorized;
    #TooOld;
    #NonExistingTokenId;
    #CreatexInFuture : { ledger_time : Nat64};
    #GenericError : { error_code : Nat; message : Text};
  };  

  public type ApproveCollectionError = {
    #TooOld;
    #CreatexInFuture : { ledger_time : Nat64};
    #GenericError : { error_code : Nat; message : Text};
  };  
  
  public type CollectionMetadata = [(Text, Value)];

  public type SupportedStandard = {name: Text; url: Text};

  public type Service = actor {

    icrc7_name: shared query ()-> async Text;
    icrc7_symbol: shared query ()-> async Text;
    icrc7_description: shared query ()-> async ?Text;
    icrc7_logo: shared query ()-> async ?Text;
    icrc7_total_supply: shared query ()-> async Nat;
    icrc7_supply_cap: shared query ()-> async ?Nat;
    icrc7_max_approvals_per_token_or_collection: shared query ()-> async ?Nat;
    icrc7_max_query_batch_size: shared query ()-> async ?Nat;
    icrc7_max_update_batch_size: shared query ()-> async ?Nat;
    icrc7_default_take_value: shared query ()-> async ?Nat;
    icrc7_max_take_value:  shared query ()-> async ?Nat;
    icrc7_max_revoke_approvals:  shared query ()-> async ?Nat;
    icrc7_max_memo_size:  shared query ()-> async ?Nat;

    icrc7_collection_metadata: shared query ()-> async [(Text, Value)];
    icrc7_token_metadata: shared query (Nat)-> async [(Nat, [(Text,Value)])];

    icrc7_owner_of: shared query ([Nat])-> async [{token_id: Nat; account:Account}];
    icrc7_balance_of: shared query (Account)-> async Nat;
    icrc7_tokens: shared query (prev: ?Nat, take: ?Nat32)-> async [Nat];
    icrc7_tokens_of: shared query (Account, prev : ?Nat, take: ?Nat32)-> async [Nat];
    icrc7_transfer: shared (TransferArgs)-> async TransferResult;
    icrc7_approve: shared (token_ids: [Nat], approval: ApprovalArgs)-> async ApprovalResult;
    icrc7_approve_collection: shared (approval: ApprovalArgs)-> async ApproveCollectionResult;
    icrc7_supported_standards: shared query ()-> async [SupportedStandard];
  };
}