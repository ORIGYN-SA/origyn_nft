module {

  //this file contains types needed to interact with an ICP/OGY style ledger
  
  public type AccountBalanceArgs = { account : AccountIdentifier };
  public type AccountBalanceArgsDFX = { account : AccountIdentifierDFX };
  public type AccountIdentifier = Blob;
  public type AccountIdentifierDFX = Text;
  public type Archive = { canister_id : Principal };
  public type ArchiveOptions = {
    num_blocks_to_archive : Nat64;
    trigger_threshold : Nat64;
    max_message_size_bytes : ?Nat64;
    cycles_for_archive_creation : ?Nat64;
    node_max_memory_size_bytes : ?Nat64;
    controller_id : Principal;
  };
  public type Archives = { archives : [Archive] };
  public type Block = {
    transaction : Transaction;
    timestamp : TimeStamp;
    parent_hash : ?Blob;
  };
  public type BlockArg = BlockHeight;
  public type BlockDFX = {
    transaction : TransactionDFX;
    timestamp : TimeStamp;
    parent_hash : ?[Nat8];
  };
  public type BlockHeight = Nat64;
  public type BlockIndex = Nat64;
  public type BlockRange = { blocks : [Block] };
  public type BlockRes = ?{
    #Ok : ?{ #Ok : Block; #Err : CanisterId };
    #Err : Text;
  };
  public type CanisterId = Principal;
  public type Duration = { secs : Nat64; nanos : Nat32 };
  public type GetBlocksArgs = { start : BlockIndex; length : Nat64 };
  public type Hash = ?{ inner : [Nat8] };
  public type HeaderField = (Text, Text);
  public type HttpRequest = {
    url : Text;
    method : Text;
    body : [Nat8];
    headers : [HeaderField];
  };
  public type HttpResponse = {
    body : [Nat8];
    headers : [HeaderField];
    status_code : Nat16;
  };
  public type LedgerCanisterInitPayload = {
    send_whitelist : [Principal];
    admin : Principal;
    token_symbol : ?Text;
    transfer_fee : ?Tokens;
    minting_account : AccountIdentifierDFX;
    transaction_window : ?Duration;
    max_message_size_bytes : ?Nat64;
    archive_options : ?ArchiveOptions;
    standard_whitelist : [Principal];
    initial_values : [(AccountIdentifierDFX, Tokens)];
    token_name : ?Text;
  };
  public type Memo = Nat64;
  public type NotifyCanisterArgs = {
    to_subaccount : ?SubAccount;
    from_subaccount : ?SubAccount;
    to_canister : Principal;
    max_fee : Tokens;
    block_height : BlockHeight;
  };
  public type Operation = {
    #Burn : { from : AccountIdentifier; amount : Tokens };
    #Mint : { to : AccountIdentifier; amount : Tokens };
    #Transfer : {
      to : AccountIdentifier;
      fee : Tokens;
      from : AccountIdentifier;
      amount : Tokens;
    };
  };
  public type OperationDFX = {
    #Burn : { from : AccountIdentifierDFX; amount : Tokens };
    #Mint : { to : AccountIdentifierDFX; amount : Tokens };
    #Send : {
      to : AccountIdentifierDFX;
      from : AccountIdentifierDFX;
      amount : Tokens;
    };
  };
  public type QueryArchiveError = {
    #BadFirstBlockIndex : {
      requested_index : BlockIndex;
      first_valid_index : BlockIndex;
    };
    #Other : { error_message : Text; error_code : Nat64 };
  };
  public type QueryArchiveFn = shared query GetBlocksArgs -> async QueryArchiveResult;
  public type QueryArchiveResult = {
    #Ok : BlockRange;
    #Err : QueryArchiveError;
  };
  public type QueryBlocksResponse = {
    certificate : ?[Nat8];
    blocks : [Block];
    chain_length : Nat64;
    first_block_index : BlockIndex;
    archived_blocks : [
      { callback : QueryArchiveFn; start : BlockIndex; length : Nat64 }
    ];
  };
  public type SendArgs = {
    to : AccountIdentifierDFX;
    fee : Tokens;
    memo : Memo;
    from_subaccount : ?SubAccount;
    created_at_time : ?TimeStamp;
    amount : Tokens;
  };
  public type SubAccount = [Nat8];
  public type TimeStamp = { timestamp_nanos : Nat64 };
  public type TipOfChainRes = {
    certification : ?[Nat8];
    tip_index : BlockHeight;
  };
  public type Tokens = { e8s : Nat64 };
  public type Transaction = {
    memo : Memo;
    operation : ?Operation;
    created_at_time : TimeStamp;
  };
  public type TransactionDFX = {
    memo : Memo;
    operation : ?OperationDFX;
    created_at_time : TimeStamp;
  };
  public type TransferArgs = {
    to : AccountIdentifier;
    fee : Tokens;
    memo : Memo;
    from_subaccount : ?SubAccount;
    created_at_time : ?TimeStamp;
    amount : Tokens;
  };
  public type TransferError = {
    #TxTooOld : { allowed_window_nanos : Nat64 };
    #BadFee : { expected_fee : Tokens };
    #TxDuplicate : { duplicate_of : BlockIndex };
    #TxCreatedInFuture;
    #InsufficientFunds : { balance : Tokens };
  };
  public type TransferFee = { transfer_fee : Tokens };
  public type TransferFeeArg = {};
  public type TransferResult = { #Ok : BlockIndex; #Err : TransferError };
  public type TransferStandardArgs = {
    to : AccountIdentifier;
    fee : Tokens;
    memo : Memo;
    from_subaccount : ?SubAccount;
    from_principal : Principal;
    created_at_time : ?TimeStamp;
    amount : Tokens;
  };
  public type Service = actor {
    account_balance : shared query AccountBalanceArgs -> async Tokens;
    account_balance_dfx : shared query AccountBalanceArgsDFX -> async Tokens;
    archives : shared query () -> async Archives;
    block_dfx : shared query BlockArg -> async BlockRes;
    decimals : shared query () -> async { decimals : Nat32 };
    get_admin : shared query {} -> async Principal;
    get_minting_account_id_dfx : shared query {} -> async ?AccountIdentifier;
    get_nodes : shared query () -> async [CanisterId];
    get_send_whitelist_dfx : shared query {} -> async [Principal];
    http_request : shared query HttpRequest -> async HttpResponse;
    name : shared query () -> async { name : Text };
    notify_dfx : shared NotifyCanisterArgs -> async ();
    query_blocks : shared query GetBlocksArgs -> async QueryBlocksResponse;
    send_dfx : shared SendArgs -> async BlockHeight;
    set_admin : shared Principal -> async ();
    set_minting_account_id_dfx : shared AccountIdentifier -> async ();
    set_send_whitelist_dfx : shared [Principal] -> async ();
    set_standard_whitelist_dfx : shared [Principal] -> async ();
    symbol : shared query () -> async { symbol : Text };
    tip_of_chain_dfx : shared query {} -> async TipOfChainRes;
    total_supply_dfx : shared query {} -> async Tokens;
    transfer : shared TransferArgs -> async TransferResult;
    transfer_fee : shared query TransferFeeArg -> async TransferFee;
    transfer_standard_stdldg : shared TransferStandardArgs -> async TransferResult;
  };

  type GetBlocksResult =  {
      #Ok : BlockRange;
      #Err : GetBlocksError;
  };

  public type GetBlocksError = {

      /// The [GetBlocksArgs.start] is below the first block that
      /// archive node stores.
      #BadFirstBlockIndex :  {
          requested_index : BlockIndex;
          first_valid_index : BlockIndex;
      };

      /// Reserved for future use.
      #Other :  {
          error_code : Nat64;
          error_message : Text;
      };
  };

  public type ArchiveService = actor {
    get_blocks : shared query(GetBlocksArgs) -> async (GetBlocksResult);
  }
}