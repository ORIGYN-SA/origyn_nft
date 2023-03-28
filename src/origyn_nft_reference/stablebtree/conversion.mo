import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import Utils "utils";

module {

  // Comes from Candy library conversion.mo: https://raw.githubusercontent.com/skilesare/candy_library/main/src/conversion.mo
  
  //////////////////////////////////////////////////////////////////////
  // The following functions converst standard types to Byte arrays
  // From there you can easily get to blobs if necessary with the Blob package
  //////////////////////////////////////////////////////////////////////

  public func nat64ToBytes(x : Nat64) : Blob {
    
    let array = [ Nat8.fromNat(Nat64.toNat((x >> 56) & (255))),
    Nat8.fromNat(Nat64.toNat((x >> 48) & (255))),
    Nat8.fromNat(Nat64.toNat((x >> 40) & (255))),
    Nat8.fromNat(Nat64.toNat((x >> 32) & (255))),
    Nat8.fromNat(Nat64.toNat((x >> 24) & (255))),
    Nat8.fromNat(Nat64.toNat((x >> 16) & (255))),
    Nat8.fromNat(Nat64.toNat((x >> 8) & (255))),
    Nat8.fromNat(Nat64.toNat((x & 255))) ];
    Blob.fromArray(array);
  };

  public func nat64ToByteArray(x : Nat64) : [Nat8] {
    
    let array = [ Nat8.fromNat(Nat64.toNat((x >> 56) & (255))),
    Nat8.fromNat(Nat64.toNat((x >> 48) & (255))),
    Nat8.fromNat(Nat64.toNat((x >> 40) & (255))),
    Nat8.fromNat(Nat64.toNat((x >> 32) & (255))),
    Nat8.fromNat(Nat64.toNat((x >> 24) & (255))),
    Nat8.fromNat(Nat64.toNat((x >> 16) & (255))),
    Nat8.fromNat(Nat64.toNat((x >> 8) & (255))),
    Nat8.fromNat(Nat64.toNat((x & 255))) ];
    array;
  };

  public func nat32ToByteArray(x : Nat32) : [Nat8] {
    
    [ Nat8.fromNat(Nat32.toNat((x >> 24) & (255))),
    Nat8.fromNat(Nat32.toNat((x >> 16) & (255))),
    Nat8.fromNat(Nat32.toNat((x >> 8) & (255))),
    Nat8.fromNat(Nat32.toNat((x & 255))) ];
  };

  public func nat32ToBytes(x : Nat32) : Blob {
    
    let array = [ Nat8.fromNat(Nat32.toNat((x >> 24) & (255))),
    Nat8.fromNat(Nat32.toNat((x >> 16) & (255))),
    Nat8.fromNat(Nat32.toNat((x >> 8) & (255))),
    Nat8.fromNat(Nat32.toNat((x & 255))) ];
    Blob.fromArray(array);
  };

  /// Returns Blob of size 4 of the Nat16
  public func nat16ToBytes(x : Nat16) : Blob {
    
    let array = [ Nat8.fromNat(Nat16.toNat((x >> 8) & (255))),
    Nat8.fromNat(Nat16.toNat((x & 255))) ];
    Blob.fromArray(array);
  };

  public func bytesToNat16(bytes: Blob) : Nat16{

    let array = Blob.toArray(bytes);
    (Nat16.fromNat(Nat8.toNat(array[0])) << 8) +
    (Nat16.fromNat(Nat8.toNat(array[1])));
  };

  public func byteArrayToNat32(array: [Nat8]) : Nat32{

    (Nat32.fromNat(Nat8.toNat(array[0])) << 24) +
    (Nat32.fromNat(Nat8.toNat(array[1])) << 16) +
    (Nat32.fromNat(Nat8.toNat(array[2])) << 8) +
    (Nat32.fromNat(Nat8.toNat(array[3])));
  };

  public func bytesToNat32(bytes: Blob) : Nat32{

    let array = Blob.toArray(bytes);
    (Nat32.fromNat(Nat8.toNat(array[0])) << 24) +
    (Nat32.fromNat(Nat8.toNat(array[1])) << 16) +
    (Nat32.fromNat(Nat8.toNat(array[2])) << 8) +
    (Nat32.fromNat(Nat8.toNat(array[3])));
  };

  public func bytesToNat64(bytes: Blob) : Nat64{
    
    let array = Blob.toArray(bytes);
    (Nat64.fromNat(Nat8.toNat(array[0])) << 56) +
    (Nat64.fromNat(Nat8.toNat(array[1])) << 48) +
    (Nat64.fromNat(Nat8.toNat(array[2])) << 40) +
    (Nat64.fromNat(Nat8.toNat(array[3])) << 32) +
    (Nat64.fromNat(Nat8.toNat(array[4])) << 24) +
    (Nat64.fromNat(Nat8.toNat(array[5])) << 16) +
    (Nat64.fromNat(Nat8.toNat(array[6])) << 8) +
    (Nat64.fromNat(Nat8.toNat(array[7])));
  };


  public func natToBytes(n : Nat) : Blob {
    
    var a : Nat8 = 0;
    var b : Nat = n;
    var bytes = List.nil<Nat8>();
    var test = true;
    while test {
      a := Nat8.fromNat(b % 256);
      b := b / 256;
      bytes := List.push<Nat8>(a, bytes);
      test := b > 0;
    };
    Blob.fromArray(List.toArray<Nat8>(bytes));
  };

  public func bytesToNat(bytes : Blob) : Nat {
    
    let array = Blob.toArray(bytes);
    var n : Nat = 0;
    var i = 0;
    Array.foldRight<Nat8, ()>(array, (), func (byte, _) {
      n += Nat8.toNat(byte) * 256 ** i;
      i += 1;
      return;
    });
    return n;
  };

  public func textToBytes(_text : Text) : Blob{
    
    let result : Buffer.Buffer<Nat8> = Buffer.Buffer<Nat8>((_text.size() * 4) +4);
    for(thisChar in _text.chars()){
      for(thisByte in nat32ToBytes(Char.toNat32(thisChar)).vals()){
        result.add(thisByte);
      };
    };
    return Blob.fromArray(result.toArray());
  };

  //encodes a string it to a giant int
  public func encodeTextAsNat(phrase : Text) : ?Nat {
    var theSum : Nat = 0;
    Iter.iterate(Text.toIter(phrase), func (x : Char, n : Nat){
      //todo: check for digits
      theSum := theSum + ((Nat32.toNat(Char.toNat32(x)) - 48) * 10 **  (phrase.size()-n-1));
    });
    return ?theSum;
  };

  //conversts "10" to 10
  public func textToNat( txt : Text) : ?Nat {
    if(txt.size() > 0){
      let chars = txt.chars();
      var num : Nat = 0;
      for (v in chars){
        let charToNum = Nat32.toNat(Char.toNat32(v)-48);
        if(charToNum >= 0 and charToNum <= 9){
          num := num * 10 +  charToNum; 
        } else {
          return null;
        };       
      };
      ?num;
    }else {
      return null;
    };
  };

  public func bytesToText(_bytes : Blob) : Text{
    
    let array = Blob.toArray(_bytes);
    var result : Text = "";
    var aChar : [var Nat8] = [var 0, 0, 0, 0];

    for(thisChar in Iter.range(0,_bytes.size())){
      if(thisChar > 0 and thisChar % 4 == 0){
        aChar[0] := array[thisChar-4];
        aChar[1] := array[thisChar-3];
        aChar[2] := array[thisChar-2];
        aChar[3] := array[thisChar-1];
        result := result # Char.toText(Char.fromNat32(byteArrayToNat32(Array.freeze<Nat8>(aChar))));
      };
    };
    return result;
  };

  public func principalToBytes(_principal: Principal) : Blob{
    
    return Principal.toBlob(_principal);
  };

  public func bytesToPrincipal(_bytes: Blob) : Principal{
    
    return Principal.fromBlob(_bytes);
  };

  public func boolToBytes(_bool : Bool) : Blob {
    
    if(_bool == true){
      return Blob.fromArray([1:Nat8]);
    } else {
      return Blob.fromArray([0:Nat8]);
    };
  };

  public func bytesToBool(_bytes : Blob) : Bool{
    
    let _array = Blob.toArray(_bytes);
    if(_array[0] == 0){
      return false;
    } else {
      return true;
    };
  };

  public func intToBytes(n : Int) : Blob{
    
    var a : Nat8 = 0;
    var c : Nat8 = if(n < 0){1}else{0};
    var b : Nat = Int.abs(n);
    var bytes = List.nil<Nat8>();
    var test = true;
    while test {
      a := Nat8.fromNat(b % 128);
      b := b / 128;
      bytes := List.push<Nat8>(a, bytes);
      test := b > 0;
    };
    let result = Utils.toBuffer<Nat8>([c]);
    result.append(Utils.toBuffer<Nat8>(List.toArray<Nat8>(bytes)));
    Blob.fromArray(result.toArray());
  };

  public func bytesToInt(_bytes : Blob) : Int{
    
    let _array = Blob.toArray(_bytes);
    var n : Int = 0;
    var i = 0;
    let natBytes = Array.tabulate<Nat8>(_bytes.size() - 2, func(idx){_array[idx+1]});

    Array.foldRight<Nat8, ()>(natBytes, (), func (byte, _) {
      n += Nat8.toNat(byte) * 128 ** i;
      i += 1;
      return;
    });
    if(_array[0]==1){
      n *= -1;
    };
    return n;
  };

  public func bytesToNat64Array(bytes: Blob) : [Nat64] {
    assert(bytes.size() % 8 == 0);
    let array = Blob.toArray(bytes);
    let size = array.size() / 8;
    let buffer = Buffer.Buffer<Nat64>(size);
    for (idx in Iter.range(0, size - 1)){
      buffer.add(
        (Nat64.fromNat(Nat8.toNat(array[idx])) << 56) +
        (Nat64.fromNat(Nat8.toNat(array[idx + 1])) << 48) +
        (Nat64.fromNat(Nat8.toNat(array[idx + 2])) << 40) +
        (Nat64.fromNat(Nat8.toNat(array[idx + 3])) << 32) +
        (Nat64.fromNat(Nat8.toNat(array[idx + 4])) << 24) +
        (Nat64.fromNat(Nat8.toNat(array[idx + 5])) << 16) +
        (Nat64.fromNat(Nat8.toNat(array[idx + 6])) << 8) +
        (Nat64.fromNat(Nat8.toNat(array[idx + 7]))));
    };
    buffer.toArray();
  };

  public func nat64ArrayToBytes(array: [Nat64]) : Blob {
    let buffer = Buffer.Buffer<[Nat8]>(array.size() * 8);
    for (nat64 in Array.vals(array)){
      buffer.add(nat64ToByteArray(nat64));
    };
    Blob.fromArray(Array.flatten(buffer.toArray()));
  };

};