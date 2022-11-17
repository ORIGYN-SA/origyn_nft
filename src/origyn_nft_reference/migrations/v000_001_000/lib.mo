import D "mo:base/Debug";

import CandyTypes_lib "mo:candy_0_1_10/types"; 
import Map_lib "mo:map_6_0_0/Map"; 
import SB_lib "mo:stablebuffer_0_2_0/StableBuffer"; 

import MigrationTypes "../types";
import v0_0_0 "../v000_000_000/types";
import v0_1_0 "types";

module {
  public func upgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {

    
    
    
    D.print("in upgrade");
    return #v0_1_0(#data({
        //holds info about the collection

            var collection_data : v0_1_0.CollectionData = {
                    var logo = null;
                    var name = null;
                    var symbol = null;
                    var owner = args.owner;
                    var managers = [];  //managers have some special access to a collection. used for 3rd party managment dapps
                    var network = null; //networks have ultimate control over a collection
                    var metadata = null; //information about the collection
                    var active_bucket = null; //tracks the current bucket that storage is being assigned to
                    var allocated_storage = args.storage_space; //total allocated storage for this collection
                    var available_space = args.storage_space; //space remaning in the collection
                };

            //tracks storage buckets where library files can be stored
            var buckets : Map_lib.Map<Principal, v0_1_0.BucketData> = Map_lib.new<Principal, v0_1_0.BucketData>();
            
            //tracks token-id, library-id allocations and information about where the asset resides
            var allocations : Map_lib.Map<(Text, Text), v0_1_0.AllocationRecord> = Map_lib.new<(Text, Text), v0_1_0.AllocationRecord>();
            
            //tracks space on the gateway canister
            var canister_availible_space = args.storage_space;
            var canister_allocated_storage = args.storage_space;

            //basic logging functionality for the NFT
            var log = SB_lib.initPresized<v0_1_0.LogEntry>(1000);
            var log_history = SB_lib.initPresized<[v0_1_0.LogEntry]>(1); //holds log history
            var log_harvester: Principal = args.owner;  //can pull and delete logs

            //tracks metadata for a token-id
            var nft_metadata = Map_lib.new<Text,CandyTypes_lib.CandyValue>();

            //tracks escrows for sales
            var escrow_balances : v0_1_0.EscrowBuyerTrie = Map_lib.new<v0_1_0.Account, 
                                        Map_lib.Map<v0_1_0.Account,
                                            Map_lib.Map<Text,
                                                Map_lib.Map<v0_1_0.TokenSpec,v0_1_0.EscrowRecord>>>>();

            //tracks sales revenue for sales
            var sales_balances : v0_1_0.SalesSellerTrie = Map_lib.new<v0_1_0.Account, 
                                        Map_lib.Map<v0_1_0.Account,
                                            Map_lib.Map<Text,
                                                Map_lib.Map<v0_1_0.TokenSpec,v0_1_0.EscrowRecord>>>>();
            

            //tracks offers made from one user to another
            var offers : Map_lib.Map<v0_1_0.Account, Map_lib.Map<v0_1_0.Account, Int>> = Map_lib.new<v0_1_0.Account, Map_lib.Map<v0_1_0.Account, Int>>();

            //tracks the history of each token-id and the collection at token-id ""
            var nft_ledgers : Map_lib.Map<Text,SB_lib.StableBuffer<v0_1_0.TransactionRecord>> = Map_lib.new<Text,SB_lib.StableBuffer<v0_1_0.TransactionRecord>>();
            
            //tracks the active sales in the canister
            //nyi: currently only store the latest sale so other data is destoyed, probably need to store somewhere, basic data is available in the ledger
            var nft_sales : Map_lib.Map<Text, v0_1_0.SaleStatus> = Map_lib.new<Text, v0_1_0.SaleStatus>();
      }));
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public func downgrade(migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    return #v0_0_0(#data);
  };
};