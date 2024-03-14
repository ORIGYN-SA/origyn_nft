/*


import Iter "mo:base/Iter";
import Option "mo:base/Option";

import Text "mo:base/Text";
import Properties "mo:candy/properties";
import Workspace "mo:candy/workspace";
import TrieMap "mo:base/TrieMap";

import Buffer "mo:base/Buffer";
import Time "mo:base/Time";
 */

import NFTCanisterDef "../origyn_nft_reference/main";
import D "mo:base/Debug";
import Result "mo:base/Result";
import Types "../origyn_nft_reference/types";
import Principal "mo:base/Principal";
import MigrationTypes "../origyn_nft_reference/migrations/types";

module {

  let CandyTypes = MigrationTypes.Current.CandyTypes;
  let Conversion = MigrationTypes.Current.Conversions;
  let Properties = MigrationTypes.Current.Properties;
  let Workspace = MigrationTypes.Current.Workspace;

  public func buildStandardNFT(token_id : Text, canister : Types.Service, app : Principal, file_size : Nat, is_soulbound : Bool, nft_originator : Principal) : async (

    Result.Result<Text, Types.OrigynError>,
    Result.Result<Principal, Types.OrigynError>,
    Result.Result<Principal, Types.OrigynError>,
    Result.Result<Principal, Types.OrigynError>,
  ) {
    //D.print("calling stage in build standard");

    let stage = await canister.stage_nft_origyn(standardNFT(token_id, Principal.fromActor(canister), app, file_size, is_soulbound, nft_originator));

    //D.print(debug_show(stage));
    //D.print("finished stage in build standard");

    let fileStage = await canister.stage_library_nft_origyn(standardFileChunk(token_id, "page", "hello world", #Option(null)));
    //D.print("finished filestage1 in build standard");
    //D.print(debug_show(fileStage));
    let previewStage = await canister.stage_library_nft_origyn(standardFileChunk(token_id, "preview", "preview hello world", #Option(null)));
    //D.print("finished filestage2 in build standard");
    //D.print(debug_show(previewStage));
    let hiddenStage = await canister.stage_library_nft_origyn(standardFileChunk(token_id, "hidden", "hidden hello world", #Option(null)));
    //D.print("finished filestage3 in build standard");
    //D.print(debug_show(hiddenStage));

    let immutableStage = await canister.stage_library_nft_origyn(standardFileChunk(token_id, "immutable_item", "immutable", #Option(null)));

    //let directoryStage = await canister.stage_library_nft_origyn(standardFileChunk(token_id,"test/atest/something.txt","a directory item", #Option(null));

    return (stage, switch (fileStage) { case (#ok(val)) { #ok(val.canister) }; case (#err(err)) { #err(err) } }, switch (previewStage) { case (#ok(val)) { #ok(val.canister) }; case (#err(err)) { #err(err) } }, switch (hiddenStage) { case (#ok(val)) { #ok(val.canister) }; case (#err(err)) { #err(err) } });
  };

  public let memo_one : ?[Nat8] = ?[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1];

  public func buildCollection(canister : Types.Service, app : Principal, node : Principal, originator : Principal, file_size : Nat, broker_override : Bool, ledger : MigrationTypes.Current.ICTokenSpec) : async (
    Result.Result<Text, Types.OrigynError>,
    Result.Result<Principal, Types.OrigynError>,
  ) {
    //D.print("calling stage in build standard");

    let aCollection : { metadata : CandyTypes.CandyShared } = standardCollection(Principal.fromActor(canister), app, node, originator, file_size, broker_override, ledger);

    D.print("Building test standard collection " # debug_show (broker_override, aCollection));

    let stage = await canister.stage_nft_origyn(aCollection);
    D.print(debug_show (stage));
    D.print("finished stage in build standard");

    let fileStage = await canister.stage_library_nft_origyn(standardFileChunk("", "collection_banner", "collection banner", #Option(null)));
    //let fileStage2 = await canister.stage_library_nft_origyn(standardFileChunk("","item/test/collection.csv","collection csv", #Option(null));

    return (stage, switch (fileStage) { case (#ok(val)) { #ok(val.canister) }; case (#err(err)) { #err(err) } });
  };

  public func standardNFT(
    token_id : Text,
    canister : Principal,
    app : Principal,
    file_size : Nat,
    is_soulbound : Bool,
    originator : Principal,
  ) : { metadata : CandyTypes.CandyShared } {
    {
      metadata = #Class([
        { name = "id"; value = #Text(token_id); immutable = true },
        { name = "primary_asset"; value = #Text("page"); immutable = false },
        { name = "preview"; value = #Text("page"); immutable = true },
        { name = "experience"; value = #Text("page"); immutable = true },
        {
          name = "library";
          value = #Array([
            #Class([
              { name = "library_id"; value = #Text("page"); immutable = true },
              { name = "title"; value = #Text("page"); immutable = true },
              {
                name = "location_type";
                value = #Text("canister");
                immutable = true;
              }, // ipfs, arweave, portal
              {
                name = "location";
                value = #Text("http://localhost:8000/-/1/-/page?canisterId=" # Principal.toText(canister));
                immutable = true;
              },
              {
                name = "content_type";
                value = #Text("text/html; charset=UTF-8");
                immutable = true;
              },
              {
                name = "content_hash";
                value = #Bytes([0, 0, 0, 0]);
                immutable = true;
              },
              { name = "size"; value = #Nat(file_size); immutable = true },
              { name = "sort"; value = #Nat(0); immutable = true },
              { name = "read"; value = #Text("public"); immutable = false },
            ]),
            #Class([
              {
                name = "library_id";
                value = #Text("preview");
                immutable = true;
              },
              { name = "title"; value = #Text("preview"); immutable = true },
              {
                name = "location_type";
                value = #Text("canister");
                immutable = true;
              },
              {
                name = "location";
                value = #Text("http://localhost:8000/-/1/-/preview?canisterId=" # Principal.toText(canister));
                immutable = true;
              },
              {
                name = "content_type";
                value = #Text("text/html; charset=UTF-8");
                immutable = true;
              },
              {
                name = "content_hash";
                value = #Bytes([0, 0, 0, 0]);
                immutable = true;
              },
              { name = "size"; value = #Nat(file_size); immutable = true },
              { name = "sort"; value = #Nat(0); immutable = true },
              { name = "read"; value = #Text("public"); immutable = false },
            ]),
            #Class([
              { name = "library_id"; value = #Text("hidden"); immutable = true },
              { name = "title"; value = #Text("hidden"); immutable = true },
              {
                name = "location_type";
                value = #Text("canister");
                immutable = true;
              },
              {
                name = "location";
                value = #Text("http://localhost:8000/-/1/-/hidden?canisterId=" # Principal.toText(canister));
                immutable = true;
              },
              {
                name = "content_type";
                value = #Text("text/html; charset=UTF-8");
                immutable = true;
              },
              {
                name = "content_hash";
                value = #Bytes([0, 0, 0, 0]);
                immutable = true;
              },
              { name = "size"; value = #Nat(file_size); immutable = true },
              { name = "sort"; value = #Nat(0); immutable = true },
              { name = "read"; value = #Text("public"); immutable = false },
            ]),
            #Class([
              {
                name = "library_id";
                value = #Text("collection_banner");
                immutable = true;
              },
              {
                name = "title";
                value = #Text("collection_banner");
                immutable = true;
              },
              {
                name = "location_type";
                value = #Text("collection");
                immutable = true;
              },
              {
                name = "location";
                value = #Text("http://localhost:8000/-/1/-/collection_banner?canisterId=" # Principal.toText(canister));
                immutable = true;
              },
              {
                name = "content_type";
                value = #Text("text/html; charset=UTF-8");
                immutable = true;
              },
              {
                name = "content_hash";
                value = #Bytes([0, 0, 0, 0]);
                immutable = true;
              },
              { name = "size"; value = #Nat(file_size); immutable = true },
              { name = "sort"; value = #Nat(0); immutable = true },
              { name = "read"; value = #Text("public"); immutable = false },
            ]),
            #Class([
              {
                name = "library_id";
                value = #Text("immutable_item");
                immutable = true;
              },
              { name = "title"; value = #Text("immutable"); immutable = true },
              {
                name = "location_type";
                value = #Text("canister");
                immutable = true;
              },
              {
                name = "location";
                value = #Text("http://localhost:8000/-/1/-/immutable_item?canisterId=" # Principal.toText(canister));
                immutable = true;
              },
              {
                name = "content_type";
                value = #Text("text/html; charset=UTF-8");
                immutable = true;
              },
              {
                name = "content_hash";
                value = #Bytes([0, 0, 0, 0]);
                immutable = true;
              },
              { name = "size"; value = #Nat(file_size); immutable = true },
              { name = "sort"; value = #Nat(0); immutable = true },
              { name = "read"; value = #Text("public"); immutable = false },
              {
                name = "com.origyn.immutable_library";
                value = #Bool(true);
                immutable = false;
              },
            ]),
          ]);
          immutable = false;
        },
        {
          name = "__apps";
          value = #Array([
            #Class([
              {
                name = Types.metadata.__apps_app_id;
                value = #Text("com.test.__public");
                immutable = true;
              },
              {
                name = "read";
                value = #Text("public");
                immutable = false;
              },
              {
                name = "write";
                value = #Class([
                  { name = "type"; value = #Text("allow"); immutable = false },
                  {
                    name = "list";
                    value = #Array([#Principal(app)]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
              {
                name = "permissions";
                value = #Class([
                  { name = "type"; value = #Text("allow"); immutable = false },
                  {
                    name = "list";
                    value = #Array([#Principal(app)]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
              {
                name = "data";
                value = #Class([
                  { name = "val1"; value = #Text("val1"); immutable = false },
                  { name = "val2"; value = #Text("val2"); immutable = false },
                  {
                    name = "val3";
                    value = #Class([
                      {
                        name = "data";
                        value = #Text("val3");
                        immutable = false;
                      },
                      {
                        name = "read";
                        value = #Text("public");
                        immutable = false;
                      },
                      {
                        name = "write";
                        value = #Class([
                          {
                            name = "type";
                            value = #Text("allow");
                            immutable = false;
                          },
                          {
                            name = "list";
                            value = #Array([#Principal(app)]);
                            immutable = false;
                          },
                        ]);
                        immutable = false;
                      },
                    ]);
                    immutable = false;
                  },
                  {
                    name = "val4";
                    value = #Class([
                      {
                        name = "data";
                        value = #Text("val4");
                        immutable = false;
                      },
                      {
                        name = "read";
                        value = #Class([
                          {
                            name = "type";
                            value = #Text("allow");
                            immutable = false;
                          },
                          {
                            name = "list";
                            value = #Array([#Principal(app)]);
                            immutable = false;
                          },
                        ]);
                        immutable = false;
                      },
                      {
                        name = "write";
                        value = #Class([
                          {
                            name = "type";
                            value = #Text("allow");
                            immutable = false;
                          },
                          {
                            name = "list";
                            value = #Array([#Principal(app)]);
                            immutable = false;
                          },
                        ]);
                        immutable = false;
                      },
                    ]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
            ]),
            #Class([
              {
                name = Types.metadata.__apps_app_id;
                value = #Text("com.test.__private");
                immutable = true;
              },
              {
                name = "read";
                value = #Class([
                  { name = "type"; value = #Text("allow"); immutable = false },
                  {
                    name = "list";
                    value = #Array([#Principal(app)]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
              {
                name = "write";
                value = #Class([
                  { name = "type"; value = #Text("allow"); immutable = false },
                  {
                    name = "list";
                    value = #Array([#Principal(app)]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
              {
                name = "permissions";
                value = #Class([
                  { name = "type"; value = #Text("allow"); immutable = false },
                  {
                    name = "list";
                    value = #Array([#Principal(app)]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
              {
                name = "data";
                value = #Class([
                  { name = "val1"; value = #Text("val1"); immutable = false },
                  { name = "val2"; value = #Text("val2"); immutable = false },
                  {
                    name = "val3";
                    value = #Class([
                      {
                        name = "data";
                        value = #Text("val3");
                        immutable = false;
                      },
                      {
                        name = "read";
                        value = #Text("public");
                        immutable = false;
                      },
                      {
                        name = "write";
                        value = #Class([
                          {
                            name = "type";
                            value = #Text("allow");
                            immutable = false;
                          },
                          {
                            name = "list";
                            value = #Array([#Principal(app)]);
                            immutable = false;
                          },
                        ]);
                        immutable = false;
                      },
                    ]);
                    immutable = false;
                  },
                  {
                    name = "val4";
                    value = #Class([
                      {
                        name = "data";
                        value = #Text("val4");
                        immutable = false;
                      },
                      {
                        name = "read";
                        value = #Class([
                          {
                            name = "type";
                            value = #Text("allow");
                            immutable = false;
                          },
                          {
                            name = "list";
                            value = #Array([#Principal(app)]);
                            immutable = false;
                          },
                        ]);
                        immutable = false;
                      },
                      {
                        name = "write";
                        value = #Class([
                          {
                            name = "type";
                            value = #Text("allow");
                            immutable = false;
                          },
                          {
                            name = "list";
                            value = #Array([#Principal(app)]);
                            immutable = false;
                          },
                        ]);
                        immutable = false;
                      },
                    ]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
            ]),
          ]);
          immutable = false;
        },
        { name = "primary_host"; value = #Text("localhost"); immutable = false },
        { name = "primary_port"; value = #Text("8000"); immutable = false },
        { name = "primary_protocol"; value = #Text("http"); immutable = false },

        { name = "owner"; value = #Principal(canister); immutable = false },
        {
          name = "com.origyn.originator.override";
          value = #Principal(originator);
          immutable = true;
        },
        {
          name = "is_soulbound";
          value = #Bool(is_soulbound);
          immutable = is_soulbound;
        },
      ]);
    };
  };

  public func standardCollection(
    canister : Principal,
    app : Principal,
    node : Principal,
    originator : Principal,
    file_size : Nat,
    broker_override : Bool,
    ledgerToken : MigrationTypes.Current.ICTokenSpec,
  ) : { metadata : CandyTypes.CandyShared } {
    {
      metadata = #Class([
        { name = "id"; value = #Text(""); immutable = true },
        {
          name = "primary_asset";
          value = #Text("collection_banner");
          immutable = true;
        },
        {
          name = "preview";
          value = #Text("collection_banner");
          immutable = true;
        },
        {
          name = "experience";
          value = #Text("collection_banner");
          immutable = true;
        },
        { name = "com.origyn.node"; value = #Principal(node); immutable = true },
        {
          name = "com.origyn.originator";
          value = #Principal(node);
          immutable = true;
        },
        {
          name = "com.origyn.royalties.primary.default";
          value = #Array([
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.broker");
                immutable = true;
              },
              { name = "rate"; value = #Float(0.06); immutable = true },
            ]),
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.node");
                immutable = true;
              },
              { name = "rate"; value = #Float(0.07777); immutable = true },
            ]),
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.network");
                immutable = true;
              },
              { name = "rate"; value = #Float(0.005); immutable = true },
            ]),

          ]);
          immutable = false;
        },
        {
          name = "com.origyn.royalties.secondary.default";
          value = #Array([
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.broker");
                immutable = true;
              },
              { name = "rate"; value = #Float(0.01); immutable = true },
            ]),
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.node");
                immutable = true;
              },
              { name = "rate"; value = #Float(0.02); immutable = true },
            ]),
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.originator");
                immutable = true;
              },
              { name = "rate"; value = #Float(0.03333333333); immutable = true },
            ]),
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.custom");
                immutable = true;
              },
              { name = "rate"; value = #Float(0.04); immutable = true },
              {
                name = "account";
                value = #Principal(originator);
                immutable = true;
              },
            ]),

            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.network");
                immutable = true;
              },
              { name = "rate"; value = #Float(0.005); immutable = true },
            ]),
          ]);
          immutable = false;
        },
        {
          name = "com.origyn.royalties.primary.default";
          value = #Array([
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.broker");
                immutable = true;
              },
              { name = "rate"; value = #Float(0.06); immutable = true },
            ]),
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.node");
                immutable = true;
              },
              { name = "rate"; value = #Float(0.07777); immutable = true },
            ]),
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.network");
                immutable = true;
              },
              { name = "rate"; value = #Float(0.005); immutable = true },
            ]),

          ]);
          immutable = false;
        },
        {
          name = "com.origyn.royalties.fixed.default";
          value = #Array([
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.broker");
                immutable = true;
              },
              { name = "fixedXDR"; value = #Float(1000000); immutable = true },
              {
                name = "tokenCanister";
                value = #Principal(ledgerToken.canister);
                immutable = true;
              },
              {
                name = "tokenSymbol";
                value = #Text(ledgerToken.symbol);
                immutable = true;
              },
              {
                name = "tokenDecimals";
                value = #Nat(ledgerToken.decimals);
                immutable = true;
              },
              {
                name = "tokenFee";
                value = switch (ledgerToken.fee) {
                  case (?val) { #Nat(val) };
                  case (null) { #Option(null) };
                };
                immutable = true;
              },
            ]),
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.node");
                immutable = true;
              },
              { name = "fixedXDR"; value = #Float(1000000); immutable = true },
              {
                name = "tokenCanister";
                value = #Principal(ledgerToken.canister);
                immutable = true;
              },
              {
                name = "tokenSymbol";
                value = #Text(ledgerToken.symbol);
                immutable = true;
              },
              {
                name = "tokenDecimals";
                value = #Nat(ledgerToken.decimals);
                immutable = true;
              },
              {
                name = "tokenFee";
                value = switch (ledgerToken.fee) {
                  case (?val) { #Nat(val) };
                  case (null) { #Option(null) };
                };
                immutable = true;
              },
            ]),
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.originator");
                immutable = true;
              },
              { name = "fixedXDR"; value = #Float(1000000); immutable = true },
              {
                name = "tokenCanister";
                value = #Principal(ledgerToken.canister);
                immutable = true;
              },
              {
                name = "tokenSymbol";
                value = #Text(ledgerToken.symbol);
                immutable = true;
              },
              {
                name = "tokenDecimals";
                value = #Nat(ledgerToken.decimals);
                immutable = true;
              },
              {
                name = "tokenFee";
                value = switch (ledgerToken.fee) {
                  case (?val) { #Nat(val) };
                  case (null) { #Option(null) };
                };
                immutable = true;
              },
            ]),
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.custom");
                immutable = true;
              },
              { name = "fixedXDR"; value = #Float(1000000); immutable = true },
              {
                name = "tokenCanister";
                value = #Principal(ledgerToken.canister);
                immutable = true;
              },
              {
                name = "tokenSymbol";
                value = #Text(ledgerToken.symbol);
                immutable = true;
              },
              {
                name = "tokenDecimals";
                value = #Nat(ledgerToken.decimals);
                immutable = true;
              },
              {
                name = "tokenFee";
                value = switch (ledgerToken.fee) {
                  case (?val) { #Nat(val) };
                  case (null) { #Option(null) };
                };
                immutable = true;
              },
              {
                name = "account";
                value = #Principal(originator);
                immutable = true;
              },
            ]),
            #Class([
              {
                name = "tag";
                value = #Text("com.origyn.royalty.network");
                immutable = true;
              },
              { name = "fixedXDR"; value = #Float(1000000); immutable = true },
              {
                name = "tokenCanister";
                value = #Principal(ledgerToken.canister);
                immutable = true;
              },
              {
                name = "tokenSymbol";
                value = #Text(ledgerToken.symbol);
                immutable = true;
              },
              {
                name = "tokenDecimals";
                value = #Nat(ledgerToken.decimals);
                immutable = true;
              },
              {
                name = "tokenFee";
                value = switch (ledgerToken.fee) {
                  case (?val) { #Nat(val) };
                  case (null) { #Option(null) };
                };
                immutable = true;
              },
            ]),
          ]);
          immutable = false;
        },
        {
          name = "library";
          value = #Array([
            #Class([
              {
                name = "library_id";
                value = #Text("collection_banner");
                immutable = true;
              },
              {
                name = "title";
                value = #Text("collection_banner");
                immutable = true;
              },
              {
                name = "location_type";
                value = #Text("canister");
                immutable = true;
              }, // ipfs, arweave, portal
              {
                name = "location";
                value = #Text("https://" # Principal.toText(canister) # ".raw.icp0.io/collection/-/collection_banner");
                immutable = true;
              },
              {
                name = "content_type";
                value = #Text("text/html; charset=UTF-8");
                immutable = true;
              },
              {
                name = "content_hash";
                value = #Bytes([0, 0, 0, 0]);
                immutable = true;
              },
              { name = "size"; value = #Nat(file_size); immutable = true },
              { name = "sort"; value = #Nat(0); immutable = true },
              { name = "read"; value = #Text("public"); immutable = false },
            ])
          ]);
          immutable = false;
        },
        {
          name = "__apps";
          value = #Array([
            #Class([
              {
                name = Types.metadata.__apps_app_id;
                value = #Text("com.test.__public");
                immutable = true;
              },
              {
                name = "read";
                value = #Text("public");
                immutable = false;
              },
              {
                name = "write";
                value = #Class([
                  { name = "type"; value = #Text("allow"); immutable = false },
                  {
                    name = "list";
                    value = #Array([#Principal(app)]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
              {
                name = "permissions";
                value = #Class([
                  { name = "type"; value = #Text("allow"); immutable = false },
                  {
                    name = "list";
                    value = #Array([#Principal(app)]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
              {
                name = "data";
                value = #Class([
                  { name = "val1"; value = #Text("val1"); immutable = false },
                  { name = "val2"; value = #Text("val2"); immutable = false },
                  {
                    name = "val3";
                    value = #Class([
                      {
                        name = "data";
                        value = #Text("val3");
                        immutable = false;
                      },
                      {
                        name = "read";
                        value = #Text("public");
                        immutable = false;
                      },
                      {
                        name = "write";
                        value = #Class([
                          {
                            name = "type";
                            value = #Text("allow");
                            immutable = false;
                          },
                          {
                            name = "list";
                            value = #Array([#Principal(app)]);
                            immutable = false;
                          },
                        ]);
                        immutable = false;
                      },
                    ]);
                    immutable = false;
                  },
                  {
                    name = "val4";
                    value = #Class([
                      {
                        name = "data";
                        value = #Text("val4");
                        immutable = false;
                      },
                      {
                        name = "read";
                        value = #Class([
                          {
                            name = "type";
                            value = #Text("allow");
                            immutable = false;
                          },
                          {
                            name = "list";
                            value = #Array([#Principal(app)]);
                            immutable = false;
                          },
                        ]);
                        immutable = false;
                      },
                      {
                        name = "write";
                        value = #Class([
                          {
                            name = "type";
                            value = #Text("allow");
                            immutable = false;
                          },
                          {
                            name = "list";
                            value = #Array([#Principal(app)]);
                            immutable = false;
                          },
                        ]);
                        immutable = false;
                      },
                    ]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
            ]),
            #Class([
              {
                name = Types.metadata.__apps_app_id;
                value = #Text("com.test.__private");
                immutable = true;
              },
              {
                name = "read";
                value = #Class([
                  { name = "type"; value = #Text("allow"); immutable = false },
                  {
                    name = "list";
                    value = #Array([#Principal(app)]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
              {
                name = "write";
                value = #Class([
                  { name = "type"; value = #Text("allow"); immutable = false },
                  {
                    name = "list";
                    value = #Array([#Principal(app)]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
              {
                name = "permissions";
                value = #Class([
                  { name = "type"; value = #Text("allow"); immutable = false },
                  {
                    name = "list";
                    value = #Array([#Principal(app)]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
              {
                name = "data";
                value = #Class([
                  { name = "val1"; value = #Text("val1"); immutable = false },
                  { name = "val2"; value = #Text("val2"); immutable = false },
                  {
                    name = "val3";
                    value = #Class([
                      {
                        name = "data";
                        value = #Text("val3");
                        immutable = false;
                      },
                      {
                        name = "read";
                        value = #Text("public");
                        immutable = false;
                      },
                      {
                        name = "write";
                        value = #Class([
                          {
                            name = "type";
                            value = #Text("allow");
                            immutable = false;
                          },
                          {
                            name = "list";
                            value = #Array([#Principal(app)]);
                            immutable = false;
                          },
                        ]);
                        immutable = false;
                      },
                    ]);
                    immutable = false;
                  },
                  {
                    name = "val4";
                    value = #Class([
                      {
                        name = "data";
                        value = #Text("val4");
                        immutable = false;
                      },
                      {
                        name = "read";
                        value = #Class([
                          {
                            name = "type";
                            value = #Text("allow");
                            immutable = false;
                          },
                          {
                            name = "list";
                            value = #Array([#Principal(app)]);
                            immutable = false;
                          },
                        ]);
                        immutable = false;
                      },
                      {
                        name = "write";
                        value = #Class([
                          {
                            name = "type";
                            value = #Text("allow");
                            immutable = false;
                          },
                          {
                            name = "list";
                            value = #Array([#Principal(app)]);
                            immutable = false;
                          },
                        ]);
                        immutable = false;
                      },
                    ]);
                    immutable = false;
                  },
                ]);
                immutable = false;
              },
            ]),
          ]);
          immutable = false;
        },
        { name = "owner"; value = #Principal(canister); immutable = false },
        { name = "is_soulbound"; value = #Bool(false); immutable = false },
        { name = "primary_host"; value = #Text("localhost"); immutable = false },
        { name = "primary_port"; value = #Text("8000"); immutable = false },
        { name = "primary_protocol"; value = #Text("http"); immutable = false },
        {
          name = "com.origyn.royalties.broker_dev_fund_override";
          value = if (broker_override) {
            #Bool(true);
          } else {
            #Bool(false);
          };
          immutable = false;
        },
      ]);
    };
  };

  public func standardFileChunk(token_id : Text, library_id : Text, text : Text, fileData : CandyTypes.CandyShared) : Types.StageChunkArg {
    {
      token_id = token_id : Text;
      library_id = library_id : Text;
      filedata = fileData;
      chunk = 0;
      content = Conversion.candySharedToBlob(#Text(text)); // content = #Bytes(nat8array);
    };
  };

};
