/// Diadic intervals
///
/// From:https://github.com/nomeata/motoko-merkle-tree
///
/// This module is mostly internal to `MerkleTree`. It is extraced to expose
/// its code for the test suite without polluting the `MerkleTree` interface.

import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";

module {

  let byteLength = 32;

  public type Prefix = [Nat8];
  public type IntervalLength = Nat;

  /// A diadic interval, identified by a common prefix and its length
  public type Interval = { prefix : Prefix; len : IntervalLength };

  public func singleton(p : Prefix) : Interval {
    assert (p.size() == byteLength);
    return { prefix = p; len = byteLength * 8};
  };

  public type FindResult =
    { #before : IntervalLength;
      #equal;
      #in_left_half;
      #in_right_half;
      #after : IntervalLength;
    };
  public func find(needle: Prefix, i : Interval) : FindResult {
    assert (needle.size() == byteLength);
    assert (i.prefix.size() == byteLength);

    var bi = 0;
    while (bi < byteLength * 8) {
      let b1 = needle[bi / 8];
      let b2 = i.prefix[bi / 8];

      let mask : Nat8 =
        if (bi == i.len) { 0x00 }
        else { 0xff << Nat8.fromNat(8 - Nat.min(i.len - bi, 8)) };
      let mb1 = b1 & mask;
      let mb2 = b2 & mask;

      if (mb1 == mb2) {
        // good so far
        if (bi + 8 <= i.len) {
          // more bytes to compare, so continue
          bi += 8
        } else {
          if (Nat8.bittest(b1, 7 - (i.len - bi))) {
            return #in_right_half
          } else {
            return #in_left_half
          }
        }
      } else {
        // needle is not in the interval
        if (mb1 < mb2) {
          // needle is before the interval
          return #before (bi + Nat8.toNat(Nat8.bitcountLeadingZero(mb1 ^ mb2)));
        } else {
          // needle is after the interval
          return #after (bi + Nat8.toNat(Nat8.bitcountLeadingZero(mb1 ^ mb2)));
        }
      }
    };
    return #equal;
  };

}
