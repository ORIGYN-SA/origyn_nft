module {

  //this file contains types needed to provide responses to DIP721 style NFT commands
  public type Subaccount = Blob;
  public type Account = {
    owner : Principal; 
    subaccount : ?Subaccount; 
  };

  public type Metadata = {
     #Nat : Nat; 
     #Int : Int; 
     #Text : Text; 
     #Blob : Blob;
  };

  public type TransferArgs = {
    from : ?Account;     /* if supplied and is not caller then is permit transfer, if not supplied defaults to subaccount 0 of the caller principal */
    to : Account;
    token_ids : [Nat];
    memo : ?Blob;
    created_at_time : ?Nat64;
    is_atomic : ?Bool;
  };

  public type TransferError = {
    #Unauthorized: { token_ids : [Nat]; };
    #TooOld;
    #CreatedInFuture : { ledger_time: Nat64 };
    #Duplicate : { duplicate_of : Nat };
    #TemporarilyUnavailable;
    #GenericError : { error_code : Nat; message : Text };
  };

  public type TransferResult = {#Ok: Nat; #Err: TransferError};
  public type ApprovalResult = {#Ok: Nat; #Err: ApprovalError};

  public type ApprovalArgs = {
    from_subaccount : Blob;
    to : Account;
    tokenIds : ?[Nat];
    expires_at : ?Nat64;
    memo :?Blob;
    created_at : ?Nat64; 
  };

  public type ApprovalError = {
    #Unauthorized : [Nat];
    #TooOld;
    #TemporarilyUnavailable;
    #GenericError : { error_code : Nat; message : Text};
  };  
  
  public type CollectionMetadata = {
   icrc7_name : Text;
   icrc7_symbol : Text;
   icrc7_royalties: ?Nat16;
   icrc7_royalty_recipient : ?Account;
   icrc7_description : ?Text;
   icrc7_image : ?Text;
   icrc7_total_supply : Nat;
   icrc7_supply_cap : ?Nat;
  };

  public type SupportedStandard = {name: Text; url: Text};

  public type Service = actor {
    icrc7_collection_metadata: shared query ()-> async CollectionMetadata;
    icrc7_name: shared query ()-> async Text;
    icrc7_symbol: shared query ()-> async Text;
    icrc7_royalties: shared query ()-> async ?Nat16;
    icrc7_royalty_recipient: shared query ()-> async ?Account;
    icrc7_description: shared query ()-> async ?Text;
    icrc7_image: shared query ()-> async ?Text;
    icrc7_total_supply: shared query ()-> async Nat;
    icrc7_supply_cap: shared query ()-> async ?Nat;
    icrc7_metadata: shared query (Nat)-> async [(Text,Metadata)];
    icrc7_owner_of: shared query (Nat)-> async Account;
    icrc7_balance_of: shared query (Nat)-> async Nat;
    icrc7_tokens_of: shared query (Account)-> async [Nat];
    icrc7_transfer: shared (TransferArgs)-> async TransferResult;
    icrc7_approve: shared (ApprovalArgs)-> async ApprovalResult;
    icrc7_supported_standards: shared query ()-> async [SupportedStandard];
  };
}