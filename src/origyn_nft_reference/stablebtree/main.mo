import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Text "mo:base/Text";

import BytesConverter "./bytesConverter";
import Conversion "./conversion";
import Memory "./memory";
import MemoryManager "memoryManager";
import StableBTree "./btreemap";
import StableBTreeTypes "./types";
import StableMemory "./memory";

actor {

    public type Stable_Memory = {
        _1 : StableBTreeTypes.IBTreeMap<Nat32, Blob>;
        _4 : StableBTreeTypes.IBTreeMap<Nat32, Blob>;
        _16 : StableBTreeTypes.IBTreeMap<Nat32, Blob>;
        _64 : StableBTreeTypes.IBTreeMap<Nat32, Blob>;
        _256 : StableBTreeTypes.IBTreeMap<Nat32, Blob>;
        _1024 : StableBTreeTypes.IBTreeMap<Nat32, Blob>;
        _2048 : StableBTreeTypes.IBTreeMap<Nat32, Blob>;
    };

    let memory_manager = MemoryManager.init(Memory.STABLE_MEMORY);

    var btreemap_multi = {
        _1 = StableBTree.init<Nat32, Blob>(memory_manager.get(0), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(1000));
        _4 = StableBTree.init<Nat32, Blob>(memory_manager.get(1), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(4000));
        _16 = StableBTree.init<Nat32, Blob>(memory_manager.get(2), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(16000));
        _64 = StableBTree.init<Nat32, Blob>(memory_manager.get(3), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(64000));
        _256 = StableBTree.init<Nat32, Blob>(memory_manager.get(4), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(256000));
        _1024 = StableBTree.init<Nat32, Blob>(memory_manager.get(5), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(1024000));
        _2048 = StableBTree.init<Nat32, Blob>(memory_manager.get(6), BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(2048000));
    };

    let bArr_1 = Array.init<Nat8>(999, 0);
    let bArr1 = Array.freeze<Nat8>(bArr_1);
    let blobSample1 : Blob = Blob.fromArray(bArr1);
    let bArr_4 = Array.init<Nat8>(3500, 0);
    let bArr4 = Array.freeze<Nat8>(bArr_4);
    let blobSample4 : Blob = Blob.fromArray(bArr4);
    let bArr_16 = Array.init<Nat8>(15500, 0);
    let bArr16 = Array.freeze<Nat8>(bArr_16);
    let blobSample16 : Blob = Blob.fromArray(bArr16);
    let bArr_64 = Array.init<Nat8>(63500, 0);
    let bArr64 = Array.freeze<Nat8>(bArr_64);
    let blobSample64 : Blob = Blob.fromArray(bArr64);
    let bArr_256 = Array.init<Nat8>(255000, 0);
    let bArr256 = Array.freeze<Nat8>(bArr_256);
    let blobSample256 : Blob = Blob.fromArray(bArr256);
    let bArr_1024 = Array.init<Nat8>(1000000, 0);
    let bArr1024 = Array.freeze<Nat8>(bArr_1024);
    let blobSample1024 : Blob = Blob.fromArray(bArr1024);
    let bArr_2048 = Array.init<Nat8>(2000000, 0);
    let bArr2048 = Array.freeze<Nat8>(bArr_2048);
    let blobSample2048 : Blob = Blob.fromArray(bArr2048);

    // For convenience: from StableBTree types
    type InsertError = StableBTreeTypes.InsertError;
    // For convenience: from base module
    type Result<Ok, Err> = Result.Result<Ok, Err>;
    // Arbitrary use of (Nat32, Text) for (key, value) types
    type K = Nat32;
    type V = Blob;

    let MAX_VALUE_SIZE : Nat32 = 1000;

    let btreemap_ = StableBTree.init<K, Blob>(Memory.STABLE_MEMORY, BytesConverter.NAT32_CONVERTER, BytesConverter.bytesPassthrough(MAX_VALUE_SIZE));

    public func get_length() : async Nat64 {
        btreemap_.getLength();
    };

    // public func insert(key: Nat32) :async Result<?Blob, InsertError>  {
    //     btreemap_.insert(key,blobSample);
    // };

    public func getTree(k : Nat32) : async ?Blob {
        btreemap_.get(k);
    };

    public query func show_entries() : async [(Nat32, Blob)] {

        let vals = btreemap_.iter();
        let localBuf = Buffer.Buffer<(Nat32, Blob)>(0);

        for (i in vals) {
            // Debug.print(debug_show(i));
            localBuf.add((i.0, i.1));
        };

        Buffer.toArray(localBuf);
    };

    public func insert_multi(n : Nat32, id : Text) : async Result<?Blob, InsertError> {

        switch (id) {
            case "1" btreemap_multi._1.insert(n, blobSample1);
            case "4" btreemap_multi._4.insert(n, blobSample4);
            case "16" btreemap_multi._16.insert(n, blobSample16);
            case "64" btreemap_multi._64.insert(n, blobSample64);
            case "256" btreemap_multi._256.insert(n, blobSample256);
            case "1024" btreemap_multi._1024.insert(n, blobSample1024);
            case "2048" btreemap_multi._2048.insert(n, blobSample2048);
            case (_) #ok(?"\00\01");
        };

    };

    public query func show_btree_multi_entries(i : Text) : async [(Nat32, Blob)] {

        let localBuf = Buffer.Buffer<(Nat32, Blob)>(0);
        switch (i) {
            case "1" {
                for (i in btreemap_multi._1.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };
            };
            case "4" {
                for (i in btreemap_multi._4.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };
            };
            case "16" {
                for (i in btreemap_multi._16.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };
            };
            case "62" {
                for (i in btreemap_multi._64.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };
            };
            case "256" {
                for (i in btreemap_multi._256.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };
            };
            case "1024" {
                for (i in btreemap_multi._1024.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };
            };
            case "2048" {
                for (i in btreemap_multi._2048.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };
            };
            // This will show all
            case (_) {
                for (i in btreemap_multi._1.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };
                for (i in btreemap_multi._4.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };
                for (i in btreemap_multi._16.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };
                for (i in btreemap_multi._64.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };
                for (i in btreemap_multi._256.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };
                for (i in btreemap_multi._1024.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };
                for (i in btreemap_multi._2048.iter()) {
                    // D.print(debug_show (i.0));
                    localBuf.add((i.0, i.1));
                };

            };
        };

        Buffer.toArray(localBuf);
    };

    //  public func getMemoryBySize (size : Nat) :  StableBTreeTypes.IBTreeMap<Nat32, Blob>{

    //         if(size <= 1000){
    //             return StableMemory._1;
    //         } else if(size <= 4000){
    //             return StableMemory._4;
    //         } else if(size <= 16000){
    //             return StableMemory._16;
    //         } else if(size <= 64000){
    //             return StableMemory._64;
    //         } else if(size <= 256000){
    //             return StableMemory._256;
    //         } else if(size <= 1024000){
    //             return StableMemory._1024;
    //         } else {
    //             return StableMemory._2048;
    //         };
    // };

};
