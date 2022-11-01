/// **A merkle tree**
///
/// Same as https://github.com/nomeata/motoko-merkle-tree but with reconstruct added
/////////////////////
/// If you benefit from this added function, please consider donating to help me continue building cool stuff
/// All procededs will be locked in 8 year ICP Neurons
/// ICP: 8521de510a846b6b20b2d4795630a29f4f937f0dd09b3bd802f3319d6b1aef45
/// ETH: 0xeF5f8a19300f85Fe0806cA4816FcB10bDd24b313
/// BTC: 3QLgWdjbF1K5j12T2sHqZtzHHLphyZVA8z
/////////////////////
///
/// This library provides a simple merkle tree data structure for Motoko.
/// It provides a key-value store, where both keys and values are of type Blob.
///
/// ```motoko
/// var t = MerkleTree.empty();
/// t := MerkleTree.put(t, "Alice", "\00\01");
/// t := MerkleTree.put(t, "Bob", "\00\02");
///
/// let w = MerkleTree.reveals(t, ["Alice" : Blob, "Malfoy": Blob].vals());
/// ```
/// will produce
/// ```
/// #fork (#labeled ("\3B…\43", #leaf("\00\01")), #pruned ("\EB…\87"))
/// ```
///
/// The witness format is compatible with
/// the [HashTree] used by the Internet Computer,
/// so client-side, the same logic can be used, but note
///
///  * the trees produces here are flat; no nested subtrees
//     (but see `witnessUnderLabel` to place the whole tree under a label).
///  * keys need to be SHA256-hashed before they are looked up in the witness
///  * no CBOR encoding is provided here. The assumption is that the witnesses are transferred
///    via Candid, and decoded to a data type understood by the client-side library.
///
/// Revealing multiple keys at once is supported, and so is proving absence of a key.
///
/// By ordering the entries by the _hash_ of the key, and branching the tree
/// based on the bits of that hash (i.e. a patricia trie), the merkle tree and thus the root
/// hash is unique for a given tree. This in particular means that insertions are efficient,
/// and that the tree can be reconstructed from the data, independently of the insertion order.
///
/// A functional API is provided (instead of an object-oriented one), so that
/// the actual tree can easily be stored in stable memory.
///
/// The tree-related functions are still limited, only insertion so far, no
/// lookup, deletion, modification, or more fancy operations. These can be added
/// when needed.
///
/// [HashTree]: <https://sdk.dfinity.org/docs/interface-spec/index.html#_certificate>

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import SHA "../sha";
import Dyadic "dyadic";

module {

  public type Key = Blob;
  public type Value = Blob;

  /// This is the main type of this module: a possibly empty tree that maps
  /// `Key`s to `Value`s.
  public type Tree = InternalT;

  type InternalT = ?T;

  type T = {
    // All values in this fork are contained in the `interval`.
    // Moreover, the `left` subtree is contained in the left half of the interval
    // And the `right` subtree is contained in the right half of the interval
    #fork : {
      interval : Dyadic.Interval;
      hash : Hash; // simple memoization of the HashTree hash
      left : T;
      right : T;
    };
    #leaf : {
      key : Key;
      keyHash : Hash;
      prefix : [Nat8];
      hash : Hash; // simple memoization of the HashTree hash
      value : Value;
    };
  };

  /// The type of witnesses. This correponds to the `HashTree` in the Interface
  /// Specification of the Internet Computer
  public type Witness = {
    #empty;
    #pruned : Hash;
    #fork : (Witness, Witness);
    #labeled : (Key, Witness);
    #leaf : Value;
  };

  public type Hash = Blob;

  /// Nat8 is easier to work with so far
  type Prefix = [Nat8];

  // Hash-related functions
  func hp(b : Blob) : [Nat8] {
    Blob.toArray(SHA.fromBlob(#sha256, b))
  };

  let prefixToHash : [Nat8] -> Blob = Blob.fromArray;

  func h(b : Blob) : Hash {
    SHA.fromBlob(#sha256, b)
  };
  func h2(b1 : Blob, b2 : Blob) : Hash {
    let d = SHA.Digest(#sha256);
    ignore d.write(Blob.toArray(b1).vals());
    ignore d.write(Blob.toArray(b2).vals());
    return d.sum();
  };
  func h3(b1 : Blob, b2 : Blob, b3 : Blob) : Hash {
    let d = SHA.Digest(#sha256);
    ignore d.write(Blob.toArray(b1).vals());
    ignore d.write(Blob.toArray(b2).vals());
    ignore d.write(Blob.toArray(b3).vals());
    return d.sum();
  };

  // Functions on Tree (the possibly empty tree)

  /// The root hash of the merkle tree. This is the value that you would sign
  /// or pass to `CertifiedData.set`
  public func treeHash(t : Tree) : Hash {
    switch t {
      case null h("\11ic-hashtree-empty");
      case (?t) hashT(t);
    }
  };


    /*
The root hash of a HashTree. This is the algorithm `reconstruct` described in
https://sdk.dfinity.org/docs/interface-spec/index.html#_certificate
*/

  public func withessHash(t : Witness) : Hash {
    switch (t) {
      case (#empty) {
        h("\11ic-hashtree-empty");
      };
      case (#fork(t1,t2)) {
        h3("\10ic-hashtree-fork", withessHash(t1), withessHash(t2));
      };
      case (#labeled(l,t)) {
        h3("\13ic-hashtree-labeled", l, withessHash(t));
      };
      case (#leaf(v)) {
        h2("\10ic-hashtree-leaf", v)
      };
      case (#pruned(h)) {
        h
      }
    }
  };

  /*
The CBOR encoding of a HashTree, according to
https://sdk.dfinity.org/docs/interface-spec/index.html#certification-encoding
This data structure needs only very few features of CBOR, so instead of writing
a full-fledged CBOR encoding library, I just directly write out the bytes for the
few construct we need here.
*/

  public func treeCBOR(tree : Witness) : Hash {
    let buf = Buffer.Buffer<Nat8>(100);

    // CBOR self-describing tag
    buf.add(0xD9);
    buf.add(0xD9);
    buf.add(0xF7);

    func add_blob(b: Blob) {
      // Only works for blobs with less than 256 bytes
      buf.add(0x58);
      buf.add(Nat8.fromNat(b.size()));
      for (c in Blob.toArray(b).vals()) {
        buf.add(c);
      };
    };

    func go(t : Witness) {
      switch (t) {
        case (#empty)        { buf.add(0x81); buf.add(0x00); };
        case (#fork(t1,t2))  { buf.add(0x83); buf.add(0x01); go(t1); go (t2); };
        case (#labeled(l,t)) { buf.add(0x83); buf.add(0x02); add_blob(l); go (t); };
        case (#leaf(v))      { buf.add(0x82); buf.add(0x03); add_blob(v); };
        case (#pruned(h))    { buf.add(0x82); buf.add(0x04); add_blob(h); }
      }
    };

    go(tree);

    return Blob.fromArray(buf.toArray());
  };


/*
Base64 encoding.
*/
  public func base64(b : Hash) : Text {
    let base64_chars : [Text] = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","+","/"];
    let bytes = Blob.toArray(b);
    let pad_len = if (bytes.size() % 3 == 0) { 0 } else {3 - bytes.size() % 3 : Nat};
    let padded_bytes = Array.append(bytes, Array.tabulate<Nat8>(pad_len, func(_) { 0 }));
    var out = "";
    for (j in Iter.range(1,padded_bytes.size() / 3)) {
      let i = j - 1 : Nat; // annoying inclusive upper bound in Iter.range
      let b1 = padded_bytes[3*i];
      let b2 = padded_bytes[3*i+1];
      let b3 = padded_bytes[3*i+2];
      let c1 = (b1 >> 2          ) & 63;
      let c2 = (b1 << 4 | b2 >> 4) & 63;
      let c3 = (b2 << 2 | b3 >> 6) & 63;
      let c4 = (b3               ) & 63;
      out #= base64_chars[Nat8.toNat(c1)]
          # base64_chars[Nat8.toNat(c2)]
          # (if (3*i+1 >= bytes.size()) { "=" } else { base64_chars[Nat8.toNat(c3)] })
          # (if (3*i+2 >= bytes.size()) { "=" } else { base64_chars[Nat8.toNat(c4)] });
    };
    return out
  };

  /// Tree construction: The empty tree
  public func empty() : Tree {
    return null
  };

  /// Tree construction: Inserting a key into the tree. An existing value under that key is overridden.
  public func put(t : Tree, k : Key, v : Value) : Tree {
    switch t {
      case null {? (mkLeaf(k,v))};
      case (?t) {? (putT(t, hp(k), k, v))};
    }
  };

  


  // Now on the real T (the non-empty tree)

  func hashT(t : T) : Hash {
    switch t {
      case (#fork(f)) f.hash;
      case (#leaf(l)) l.hash;
    }
  };

  func intervalT(t : T) : Dyadic.Interval {
    switch t {
      case (#fork(f)) { f.interval };
      case (#leaf(l)) { Dyadic.singleton(l.prefix) };
    }
  };

  // Smart contructors (memoize the hashes and other data)

  func hashValNode(v : Value) : Hash {
    h2("\10ic-hashtree-leaf", v)
  };

  func mkLeaf(k : Key, v : Value) : T {
    let keyPrefix = hp(k);
    let keyHash = prefixToHash(keyPrefix);
    let valueHash = h(v);

    #leaf {
      key = k;
      keyHash = keyHash;
      prefix = keyPrefix;
      hash = h3("\13ic-hashtree-labeled", k, hashValNode(valueHash));
      value = valueHash;
    }
  };

  func mkFork(i : Dyadic.Interval, t1 : T, t2 : T) : T {
    #fork {
      interval = i;
      hash = h3("\10ic-hashtree-fork", hashT(t1), hashT(t2));
      left = t1;
      right = t2;
    }
  };

  // Insertion

  func putT(t : T, p : Prefix, k : Key, v : Value) : T {
    switch (Dyadic.find(p, intervalT(t))) {
      case (#before(i)) {
        mkFork({ prefix = p; len = i }, mkLeaf(k, v), t)
      };
      case (#after(i)) {
        mkFork({ prefix = p; len = i }, t, mkLeaf(k, v))
      };
      case (#equal) {
	// This overrides the existing value
        mkLeaf(k,v)
      };
      case (#in_left_half) {
        putLeft(t, p, k, v);
      };
      case (#in_right_half) {
        putRight(t, p, k, v);
      };
    }
  };

  func putLeft(t : T, p : Prefix, k : Key, v : Value) : T {
    switch (t) {
      case (#fork(f)) {
        mkFork(f.interval, putT(f.left,p,k,v), f.right)
      };
      case _ {
        Debug.print("putLeft: Not a fork");
        t
      }
    }
  };

  func putRight(t : T, p : Prefix, k : Key, v : Value) : T {
    switch (t) {
      case (#fork(f)) {
        mkFork(f.interval, f.left, putT(f.right,p,k,v))
      };
      case _ {
        Debug.print("putRight: Not a fork");
        t
      }
    }
  };

  // Witness construction

  /// Create a witness that reveals the value of the key `k` in the tree `tree`.
  ///
  /// If `k` is not in the tree, the witness will prove that fact.
  public func reveal(tree : Tree, k : Key) : Witness {
    switch tree {
      case null {#empty};
      case (?t) {
        let (_, w, _) = revealT(t, hp(k));
        w
      };
    }
  };

  // Returned bools indicate whether to also reveal left or right neighbor
  func revealT(t : T, p : Prefix) : (Bool, Witness, Bool) {
    switch (Dyadic.find(p, intervalT(t))) {
      case (#before(i)) {
        (true, revealMinKey(t), false);
      };
      case (#after(i)) {
        (false, revealMaxKey(t), true);
      };
      case (#equal(i)) {
        (false, revealLeaf(t), false);
      };
      case (#in_left_half) {
        revealLeft(t, p);
      };
      case (#in_right_half) {
        revealRight(t, p);
      };
    }
  };

  func revealMinKey(t : T) : Witness {
    switch (t) {
      case (#fork(f)) {
        #fork(revealMinKey(f.left), #pruned(hashT(f.right)))
      };
      case (#leaf(l)) {
        #labeled(l.key, #pruned(hashValNode(l.value)));
      }
    }
  };

  func revealMaxKey(t : T) : Witness {
    switch (t) {
      case (#fork(f)) {
        #fork(#pruned(hashT(f.left)), revealMaxKey(f.right))
      };
      case (#leaf(l)) {
        #labeled(l.key, #pruned(hashValNode(l.value)));
      }
    }
  };

  func revealLeaf(t : T) : Witness {
    switch (t) {
      case (#fork(f)) {
        Debug.print("revealLeaf: Not a leaf");
        #empty
      };
      case (#leaf(l)) {
        #labeled(l.key, #leaf(l.value));
      }
    }
  };

  func revealLeft(t : T, p : Prefix) : (Bool, Witness, Bool) {
    switch (t) {
      case (#fork(f)) {
        let (b1,w1,b2) = revealT(f.left, p);
        let w2 = if b2 { revealMinKey(f.right) } else { #pruned(hashT(f.right)) };
        (b1, #fork(w1, w2), false);
      };
      case (#leaf(l)) {
        Debug.print("revealLeft: Not a fork");
        (false, #empty, false)
      }
    }
  };

  func revealRight(t : T, p : Prefix) : (Bool, Witness, Bool) {
    switch (t) {
      case (#fork(f)) {
        let (b1,w2,b2) = revealT(f.right, p);
        let w1 = if b1 { revealMaxKey(f.left) } else { #pruned(hashT(f.left)) };
        (false, #fork(w1, w2), b2);
      };
      case (#leaf(l)) {
        Debug.print("revealRight: Not a fork");
        (false, #empty, false)
      }
    }
  };

  /// Merges two witnesses, to reveal multiple values.
  ///
  /// The two witnesses must come from the same tree, else this function is
  /// undefined (and may trap).
  public func merge(w1 : Witness, w2 : Witness) : Witness {
    switch (w1, w2) {
      case (#pruned(h1), #pruned(h2)) {
        if (h1 != h2) Debug.print("MerkleTree.merge: pruned hashes differ");
        #pruned(h1)
      };
      case (#pruned _, w2) w2;
      case (w1, #pruned _) w1;
      // If both witnesses are not pruned, they must be headed by the same
      // constructor:
      case (#empty, #empty) #empty;
      case (#labeled(l1, w1), #labeled(l2, w2)) {
        if (l1 != l2) Debug.print("MerkleTree.merge: labels differ");
        #labeled(l1, merge(w1, w2));
      };
      case (#fork(w11, w12), #fork(w21, w22)) {
        #fork(merge(w11, w21), merge(w12, w22))
      };
      case (#leaf(v1), #leaf(v2)) {
        if (v1 != v2) Debug.print("MerkleTree.merge: values differ");
        #leaf(v2)
      };
      case (_,_) {
        Debug.print("MerkleTree.merge: shapes differ");
        #empty;
      }
    }
  };

  /// Reveal nothing from the tree. Mostly useful as a netural element to `merge`.
  public func revealNothing(tree : Tree) : Witness {
    #pruned(treeHash(tree))
  };

  /// Reveals multiple keys
  public func reveals(tree : Tree, ks : Iter.Iter<Key>) : Witness {
    // Odd, no Iter.fold? Then let’s do a mutable loop
    var w = revealNothing(tree);
    for (k in ks) { w := merge(w, reveal(tree, k)); };
    return w;
  };

  public func reconstruct(w: Witness) : Blob {
      switch(w){
          case(#empty){
              h("\11ic-hashtree-empty")
          };
          case(#pruned(prunedHash)){
              prunedHash
          };
          case(#leaf(value)){
              h2("\10ic-hashtree-leaf",value)
          };
          case(#labeled(labeled)){
              h3("\13ic-hashtree-labeled", labeled.0, reconstruct(labeled.1))
          };
          case(#fork(fork)){
              h3("\10ic-hashtree-fork", reconstruct(fork.0), reconstruct(fork.1))
          };
      };
  };


  /// Nests a witness under a label. This can be used when you want to use this
  /// library (which only produces flat labeled tree), but want to be forward
  /// compatible to a world where you actually produce nested labeled trees, or
  /// to be compatibe with an external specification that requires you to put
  /// this hash-of-blob-labeled tree in a subtree.
  ///
  /// To not pass the result of this function to `merge`! of this ru
  public func witnessUnderLabel(l : Blob, w : Witness) : Witness {
    #labeled(l, w)
  };

  public func treeUnderLabel(l : Blob, t : Tree) : Witness {
    #labeled(l, #pruned(treeHash(t)))
  };

  /// This goes along `witnessUnderLabel`, and transforms the hash
  /// that is calculated by `treeHash` accordingly.
  ///
  /// If you wrap your witnesses using `witnessUnderLabel` before
  /// sending them out, make sure to wrap your tree hash with `hashUnderLabel`
  /// before passing them to `CertifiedData.set`.
  public func hashUnderLabel(l : Blob, h : Hash) : Hash {
    h3("\13ic-hashtree-labeled", prefixToHash(hp(l)), h);
  };
}