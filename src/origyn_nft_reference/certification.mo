import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Text "mo:base/Text";

import CandyTypes "mo:candy/types";
import CandyJson "mo:candy/json";
import Conversion "mo:candy/conversion";
import Properties "mo:candy/properties";
import CertifiedData "mo:base/CertifiedData";
import MerkleTree "mo:merkle_tree";
import SHA "mo:crypto/SHA/SHA256";

import Types "types";
import Metadata "metadata";

module {

  public func update_certified_assets_tree_branch(state : Types.State, urls: [([Text], MerkleTree.Value)]): Result.Result<MerkleTree.Tree, Types.OrigynError>{
    var tree = MerkleTree.empty();
    
    for(url in urls.vals()){
      let MerkleKeyInfo = "/" # Text.join("/", url.0.vals());
      tree := MerkleTree.put(state.state.certified_assets, Text.encodeUtf8(MerkleKeyInfo), url.1);
    };

    CertifiedData.set(
            MerkleTree.witnessHash(
                MerkleTree.treeUnderLabel(
                    Text.encodeUtf8("http_assets"),
                    tree
                )
            )
        );

    state.state.certified_assets := tree;
    
    return #ok(state.state.certified_assets);
  };

  //Note: Certifying metadata with private data inside will not work. Each individual data point needs to be certified and the witnesses need to be combinted and returned at the data level.
  /* public func certify_token_metadata(state : Types.State, token_id: Text, metadata: CandyTypes.CandyValue, caller: Principal): Result.Result<MerkleTree.Tree, Types.OrigynError> {
      var tree = MerkleTree.empty();
      //--------------------------------- token /info

      let new_keys = Buffer.Buffer<([Text], Blob)>(1);
      let MerkleKeyInfo = ["-",token_id,"info"];
      let cleanMetadata = Metadata.get_clean_metadata(metadata, caller);

      new_keys.add((MerkleKeyInfo), Text.encodeUtf8(CandyJson.value_to_json(cleanMetadata)));

      //--------------------------------- /library
      let MerkleKeyLib = ["-",token_id,"library"];
      let lib = switch(Metadata.get_nft_library(cleanMetadata, ?caller)) {
          case(#ok(val)){ val };
          case(#err(err)) {return #err(err)};
      };

      new_keys.add((MerkleKeyLib), Text.encodeUtf8(CandyJson.value_to_json(cleanMetadata)));

      //--------------------------------- lib /info
      for(thisItem in Conversion.valueToValueArray(lib).vals()){
        switch(Properties.getClassProperty(thisItem, Types.metadata.library_id)){
            case(?id){
                let library_id = Conversion.valueToText(id.value);
                switch(Metadata.get_library_meta(cleanMetadata, library_id)){
                    case(#ok(library_meta)){
                        let MerkleKeyMeta = ["-", token_id, "-", library_id, "info"];
                        new_keys.add((MerkleKeyMeta), Text.encodeUtf8(CandyJson.value_to_json(library_meta)));
                    };
                    case(_){};
                };
            };
            case(_){};
        };
      };

      //------------------------------------ save cert

      update_certified_assets_tree_branch(state, new_keys.toArray());
  }; */

  public func certify_library_chunk(state : Types.State, chunk: Types.StageChunkArg, this_hash: [Nat8]): Result.Result<MerkleTree.Tree, Types.OrigynError> {
      var tree = MerkleTree.empty();
      //--------------------------------- token /info

      let new_keys = Buffer.Buffer<([Text], MerkleTree.Value)>(1);

      let MerkleKeyInfo = if(chunk.token_id == ""){
        ["collection", "-", chunk.library_id # "--" # Nat.toText(chunk.chunk)];
      } else {
        ["-",chunk.token_id, "-", chunk.library_id # "--" # Nat.toText(chunk.chunk)];
      };

      new_keys.add((MerkleKeyInfo), #pre_hashed(Blob.fromArray(this_hash)));
      //------------------------------------ save cert

      return update_certified_assets_tree_branch(state, new_keys.toArray());
  };

  public func certify_library(state: Types.State, requests : [(Text, Text, [Nat8])]): Result.Result<MerkleTree.Tree, Types.OrigynError> {
      var tree = MerkleTree.empty();
      //--------------------------------- token /info

      let new_keys = Buffer.Buffer<([Text], MerkleTree.Value)>(1);

      for(thisItem in requests.vals()){

        let MerkleKeyInfo = if(thisItem.0 == ""){
          ["collection", "-", thisItem.1];
        } else {
          ["-",thisItem.0, "-", thisItem.1];
        };

        new_keys.add((MerkleKeyInfo), #pre_hashed(Blob.fromArray(thisItem.2)));
      };
      //------------------------------------ save cert

      return update_certified_assets_tree_branch(state, new_keys.toArray());
  };

}