import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";

import CandyTypes "mo:candy_0_1_10/types";
import Conversions "mo:candy_0_1_10/conversion";
import Map "mo:map_6_0_0/Map";
import Properties "mo:candy_0_1_10/properties";
import SB "mo:stablebuffer_0_2_0/StableBuffer";
import Workspace "mo:candy_0_1_10/workspace";

import Metadata "metadata";
import MigrationTypes "./migrations/types";
import NFTUtils "utils";
import Types "types";

module {

    let debug_channel = {
        stage = false;
    };


    public func stage_library_nft_origyn(
        state : Types.StorageState,
        chunk : Types.StageChunkArg,
        source_allocation : Types.AllocationRecordStable,
        metadata: CandyTypes.CandyValue, //do we need metadata here? probably for http request...surely for file data
        caller : Principal) : async Result.Result<Types.StageLibraryResponse, Types.OrigynError> {

        if(state.state.collection_data.owner != caller){return #err(Types.errors(#unauthorized_access, "stage_library_nft_origyn - storage - not the gateway", ?caller))};


                        debug if(debug_channel.stage) D.print("in the remote canister");

        let bDelete : Bool = switch(chunk.filedata){
            case(#Bool(val)){
              if(val == false){
                true
              } else {
                false;
              }
            };
            case(_){
              false;
            };
        };

        //make sure we have an allocation for space for this chunk
        let allocation = switch(Map.get<(Text, Text), Types.AllocationRecord>(state.state.allocations,( NFTUtils.library_hash,  NFTUtils.library_equal), (chunk.token_id, chunk.library_id))){
            case(null){

                    if(bDelete){
                      //was never allocated
                      return #ok({canister = state.canister()});
                    };
                                        debug if(debug_channel.stage) D.print("no allocation yet, so lets add it");
                
                    
                    let allocation = {
                        canister = source_allocation.canister;
                        allocated_space = source_allocation.allocated_space;
                        var available_space = source_allocation.available_space;
                        var chunks = SB.fromArray<Nat>(source_allocation.chunks);
                        token_id = source_allocation.token_id;
                        library_id = source_allocation.library_id;
                    };
                                        debug if(debug_channel.stage) D.print("this is the allocation to be added " # debug_show(allocation));
                    Map.set<(Text,Text),Types.AllocationRecord>(state.state.allocations,( NFTUtils.library_hash,  NFTUtils.library_equal), (chunk.token_id, chunk.library_id), 
                        allocation
                    );
                    //this is where we remove the space for the whole allocation
                    state.state.canister_availible_space -= source_allocation.allocated_space;
                    allocation;
                 
                };
            case(?val)(val);
        };

        if(chunk.chunk == 0 and bDelete == false){
            //the first chunk comes with the metadata
            Map.set<Text, CandyTypes.CandyValue>(state.state.nft_metadata, Map.thash, chunk.token_id, metadata);
        };

                            debug if(debug_channel.stage) D.print("looking for workspace");
        var found_workspace : CandyTypes.Workspace =
            switch(state.nft_library.get(chunk.token_id)){
                case(null){
                    if(bDelete){
                      //was never allocated
                      return #ok({canister = state.canister()});
                    };
                    //chunk doesn't exist;
                                    debug if(debug_channel.stage) D.print("does not exist");
                    let new_workspace = Workspace.initWorkspace(2);
                                    debug if(debug_channel.stage) D.print("puting Zone");
                                    debug if(debug_channel.stage) D.print(debug_show(chunk.filedata));
                    
                    
                    
                    new_workspace.add(Workspace.initDataZone(CandyTypes.destabalizeValue(chunk.filedata)));

                                    debug if(debug_channel.stage) D.print("put the zone");
                    var new_library = TrieMap.TrieMap<Text, CandyTypes.Workspace>(Text.equal, Text.hash);
                                    debug if(debug_channel.stage) D.print("putting workspace");
                    new_library.put(chunk.library_id, new_workspace);
                                    debug if(debug_channel.stage) D.print("putting library");
                    state.nft_library.put(chunk.token_id, new_library);
                    new_workspace;
                };
                case(?library){
                    switch(library.get(chunk.library_id)){
                        case(null){
                                            debug if(debug_channel.stage) D.print("nft exists but not file");
                            //nft exists but this file librry entry doesnt exist
                            //nftdoesn't exist;
                            let new_workspace = Workspace.initWorkspace(2);

                            new_workspace.add(Workspace.initDataZone(CandyTypes.destabalizeValue(chunk.filedata)));


                            library.put(chunk.library_id, new_workspace);
                            
                    
                            new_workspace;
                        };
                        case(?workspace){
                            //D.print("found workspace");
                            if(bDelete == true){
                                  library.delete(chunk.library_id);
                                };
                            workspace;
                        };
                    };

                };
            };

        
        if(bDelete == true){
          state.state.canister_availible_space += allocation.allocated_space;
          //
        } else {
          //file the chunk
          //D.print("filing the chunk");
          let file_chunks = switch(found_workspace.getOpt(1)){
              case(null){
                  if(found_workspace.size()==0){
                      //todo: should be an error because no filedata
                      found_workspace.add(Workspace.initDataZone(#Empty));
                  };
                  if(found_workspace.size()==1){
                      found_workspace.add(Buffer.Buffer<CandyTypes.DataChunk>(0));
                  };
                  found_workspace.get(1);
              };
              case(?dz){
                  dz;
              };
          };


          if(chunk.chunk + 1 <= SB.size<Nat>(allocation.chunks)){
              //this chunk already exists in the allocatioin
              //see what size it is
              let current_size = SB.get<Nat>(allocation.chunks,chunk.chunk);
              if(chunk.content.size() > current_size){
                  //allocate more space
                  SB.put<Nat>(allocation.chunks, chunk.chunk, chunk.content.size());
                  if(allocation.available_space >= (chunk.content.size() - current_size)){
                    allocation.available_space -= (chunk.content.size() - current_size);
                  } else {
                    return #err(Types.errors(#storage_configuration_error, "stage_library_nft_origyn - storage - allocation.available_space >= (chunk.content.size() - current_size)" # debug_show((allocation.available_space,chunk.content.size(), current_size)), ?caller));
                  };
                  
              } else if (chunk.content.size() != current_size){
                  //give space back
                  SB.put<Nat>(allocation.chunks, chunk.chunk, chunk.content.size());
                  allocation.available_space += (current_size - chunk.content.size());
              } else {};
          } else {
              for(this_index in Iter.range(SB.size<Nat>(allocation.chunks), chunk.chunk)){
                  if(this_index == chunk.chunk){
                      SB.add<Nat>(allocation.chunks, chunk.content.size());

                      if(allocation.available_space >= chunk.content.size()){
                        allocation.available_space -= chunk.content.size();
                      } else {
                        return #err(Types.errors(#storage_configuration_error, "stage_library_nft_origyn - storage - allocation.available_space -= chunk.content.size()" # debug_show((allocation.available_space,chunk.content.size())), ?caller));
                      };
                      
                      
                  } else {
                      SB.add<Nat>(allocation.chunks, 0);
                  }
              };
          };

          //D.print("putting the chunk");
          if(chunk.chunk + 1 <= file_chunks.size()){
              file_chunks.put(chunk.chunk, #Blob(chunk.content));
          } else {
                                  debug if(debug_channel.stage) D.print("in putting the chunk iter");
                                  debug if(debug_channel.stage) D.print(debug_show(chunk.chunk));
                                  debug if(debug_channel.stage) D.print(debug_show(file_chunks.size()));

              for(this_index in Iter.range(file_chunks.size(),chunk.chunk)){
                  if(this_index == chunk.chunk){
                      file_chunks.add(#Blob(chunk.content));
                  } else {
                      file_chunks.add(#Blob(Blob.fromArray([])));
                  }
              };

          };
        };

        //D.print("returning");
        return #ok({canister = state.canister()});
    };


}