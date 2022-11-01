import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Array "mo:base/Array";

module {
    public func fromNat(len : Nat, n : Nat) : [Nat8] {
        let ith_byte = func(i : Nat) : Nat8 {
        	assert(i < len);
            let shift : Nat = 8 * (len - 1 - i);
            Nat8.fromIntWrap(n / 2**shift)
        };
        Array.tabulate<Nat8>(len, ith_byte)
    };

	public func fromNat64(n: Nat64) : [Nat8] {
    	fromNat(8, Nat64.toNat(n))
    };

    public func fromNat32(n: Nat32) : [Nat8] {
    	fromNat(4, Nat32.toNat(n))
    };

    public func fromNat16(n: Nat16) : [Nat8] {
    	fromNat(2, Nat16.toNat(n))
    };
}