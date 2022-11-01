/**
 * Module      : sha2.mo
 * Description : Cryptographic hash function.
 * Copyright   : 2020 DFINITY Stiftung
 * License     : Apache 2.0 with LLVM Exception
 * Maintainer  : Timo Hanke <timo@dfinity.org>
 * Stability   : Stable
 */

import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import IterExt "mo:iterext";
import Engine32 "./engine32";
import Engine64 "./engine64";
import BigEndian "./bigendian";

module {
    public type Algorithm = { #sha224; #sha256; #sha384; #sha512; #sha512_224; #sha512_256 };

    // Calculate SHA2 hash digest from Iter.
    public func fromIter(algo : Algorithm, iter : Iter.Iter<Nat8>) : Blob {
        let digest = switch (algo) {
            case (#sha256) { Digest(#sha256) };
            case (#sha224) { Digest(#sha224) };
            case (#sha512) { Digest(#sha512) };
            case (#sha512_224) { Digest(#sha512_224) };
            case (#sha512_256) { Digest(#sha512_256) };
            case (#sha384) { Digest(#sha384) };
            };
        ignore digest.write(iter);
        return digest.sum();
    };

    // Calculate SHA2 hash digest from Blob.
    public func fromBlob(algo : Algorithm, b : Blob) : Blob {
        fromIter(algo, b.vals());
    };

    public class Digest(algo: Algorithm) {
        let (engine, block_size, len_size) = switch (algo) {
                case (#sha224 or #sha256) (Engine32.Engine(), Engine32.block_size, 8); 
                case _ (Engine64.Engine(), Engine64.block_size, 16); 
            };
        let (sum_bytes, iv) = switch (algo) {
                case (#sha224) { (28, 0); };
                case (#sha256) { (32, 1); };
                case (#sha512_224) { (28, 0); };
                case (#sha512_256) { (32, 1); };
                case (#sha384) { (48, 2); };
                case (#sha512) { (64, 3); };
            };
        let buf = IterExt.BlockBuffer<Nat8>(block_size);
        var len : Nat = 0;

        public func reset() {
            len := 0;
            buf.reset();
            engine.init(iv);
        };

        reset();

        public func write(iter : Iter.Iter<Nat8>) : Nat {
            // will return the number of bytes read from iter
            var bytes_read : Nat = 0;
            label reading loop {
                // fill the buffer
                bytes_read += buf.fill(iter);
                if (buf.isFull()) {
                    // buffer is full, going to hash one block and try again
                    engine.process_block(buf.toArray(#fwd));
                    buf.reset();
                    continue reading
               } else {
                    // iter is exhausted
                    break reading
                }
            };
            len += bytes_read;
            bytes_read
        };

        public func write_blob(b : Blob) : Nat {
            write(b.vals());
        };

        public func sum() : Blob {
            // save the length before writing more bytes
            let n = len;

            // write padding
            let t = len % block_size;
            let m : Nat = block_size - len_size; 
            let p : Nat = if (m > t) (m - t) else (block_size + m - t);
            let padding = Array.tabulate<Nat8>(p, func(i) { if (i==0) 0x80 else 0 });
            ignore write(padding.vals());

            // write length
            ignore write(BigEndian.fromNat(len_size,n*8).vals());

            // retrieve sum
            let state = engine.state();
            let digest = Array.tabulate<Nat8>(sum_bytes, func (i) { state[i] });
            return Blob.fromArray(digest);
        };
    }; // class Digest
};