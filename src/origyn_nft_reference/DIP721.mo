module {

  //this file contains types needed to provide responses to DIP721 style NFT commands
  
  public type GenericValue = {
    #Nat64Content : Nat64;
    #Nat32Content : Nat32;
    #BoolContent : Bool;
    #Nat8Content : Nat8;
    #Int64Content : Int64;
    #IntContent : Int;
    #NatContent : Nat;
    #Nat16Content : Nat16;
    #Int32Content : Int32;
    #Int8Content : Int8;
    #FloatContent : Float;
    #Int16Content : Int16;
    #BlobContent : [Nat8];
    #NestedContent : Vec;
    #Principal : Principal;
    #TextContent : Text;
  };
  public type InitArgs = {
    logo : ?Text;
    name : ?Text;
    custodians : ?[Principal];
    symbol : ?Text;
  };
  public type DIP721Metadata = {
    logo : ?Text;
    name : ?Text;
    created_at : Nat64;
    upgraded_at : Nat64;
    custodians : [Principal];
    symbol : ?Text;
  };
  public type DIP721TokensListMetadata = { #Ok : [Nat]; #Err : NftError };
  public type DIP721TokensMetadata = { #Ok : [TokenMetadata]; #Err : NftError };
  public type DIP721TokenMetadata = { #Ok : TokenMetadata; #Err : NftError };
  public type DIP721Metadata_4 = { #Ok : TxEvent; #Err : NftError };
  public type NftError = {
    #UnauthorizedOperator;
    #SelfTransfer;
    #TokenNotFound;
    #UnauthorizedOwner;
    #TxNotFound;
    #SelfApprove;
    #OperatorNotFound;
    #ExistedNFT;
    #OwnerNotFound;
    #Other : Text;
  };
  public type DIP721NatResult = { #Ok : Nat; #Err : NftError };
  public type DIP721BoolResult = { #Ok : Bool; #Err : NftError };
  public type OwnerOfResponse = { #Ok : ?Principal; #Err : NftError };
  public type DIP721Stats = {
    cycles : Nat;
    total_transactions : Nat;
    total_unique_holders : Nat;
    total_supply : Nat;
  };
  public type DIP721SupportedInterface = {
    #Burn;
    #Mint;
    #Approval;
    #TransactionHistory;
  };
  public type TokenMetadata = {
    transferred_at : ?Nat64;
    transferred_by : ?Principal;
    owner : ?Principal;
    operator : ?Principal;
    approved_at : ?Nat64;
    approved_by : ?Principal;
    properties : [(Text, GenericValue)];
    is_burned : Bool;
    token_identifier : Nat;
    burned_at : ?Nat64;
    burned_by : ?Principal;
    minted_at : Nat64;
    minted_by : Principal;
  };
  public type TxEvent = {
    time : Nat64;
    operation : Text;
    details : [(Text, GenericValue)];
    caller : Principal;
  };
  public type Vec = [
    (
      Text,
      {
        #Nat64Content : Nat64;
        #Nat32Content : Nat32;
        #BoolContent : Bool;
        #Nat8Content : Nat8;
        #Int64Content : Int64;
        #IntContent : Int;
        #NatContent : Nat;
        #Nat16Content : Nat16;
        #Int32Content : Int32;
        #Int8Content : Int8;
        #FloatContent : Float;
        #Int16Content : Int16;
        #BlobContent : [Nat8];
        #NestedContent : Vec;
        #Principal : Principal;
        #TextContent : Text;
      },
    )
  ];
  public type Self = ?InitArgs -> async actor {
    approve : shared (Principal, Nat) -> async DIP721NatResult;
    balanceOf : shared query Principal -> async DIP721NatResult;
    burn : shared Nat -> async DIP721NatResult;
    custodians : shared query () -> async [Principal];
    cycles : shared query () -> async Nat;
    isApprovedForAll : shared query (Principal, Principal) -> async DIP721BoolResult;
    logo : shared query () -> async ?Text;
    metadata : shared query () -> async DIP721Metadata;
    mint : shared (Principal, Nat, [(Text, GenericValue)]) -> async DIP721NatResult;
    name : shared query () -> async ?Text;
    operatorOf : shared query Nat -> async OwnerOfResponse;
    operatorTokenIdentifiers : shared query Principal -> async DIP721TokensListMetadata;
    operatorTokenMetadata : shared query Principal -> async DIP721TokensMetadata;
    ownerOf : shared query Nat -> async OwnerOfResponse;
    ownerTokenIdentifiers : shared query Principal -> async DIP721TokensListMetadata;
    ownerTokenMetadata : shared query Principal -> async DIP721TokensMetadata;
    setApprovalForAll : shared (Principal, Bool) -> async DIP721NatResult;
    setCustodians : shared [Principal] -> async ();
    setLogo : shared Text -> async ();
    setName : shared Text -> async ();
    setSymbol : shared Text -> async ();
    stats : shared query () -> async DIP721Stats;
    supportedInterfaces : shared query () -> async [DIP721SupportedInterface];
    symbol : shared query () -> async ?Text;
    tokenMetadata : shared query Nat -> async DIP721TokenMetadata;
    totalSupply : shared query () -> async Nat;
    totalTransactions : shared query () -> async Nat;
    totalUniqueHolders : shared query () -> async Nat;
    transaction : shared query Nat -> async DIP721Metadata_4;
    transfer : shared (Principal, Nat) -> async DIP721NatResult;
    transferFrom : shared (Principal, Principal, Nat) -> async DIP721NatResult;
  }
}