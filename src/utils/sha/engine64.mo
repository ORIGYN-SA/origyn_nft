import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import BigEndian "./bigendian";

module {
    type Word = Nat64;
    type State = [Word];

    public let block_size = 128;
    public type Block = [Nat8]; 

    let K : [Nat64] = [
        0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc,
        0x3956c25bf348b538, 0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118,
        0xd807aa98a3030242, 0x12835b0145706fbe, 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2,
        0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235, 0xc19bf174cf692694,
        0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65,
        0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5,
        0x983e5152ee66dfab, 0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4,
        0xc6e00bf33da88fc2, 0xd5a79147930aa725, 0x06ca6351e003826f, 0x142929670a0e6e70,
        0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df,
        0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b,
        0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30,
        0xd192e819d6ef5218, 0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8,
        0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8,
        0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3,
        0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
        0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b,
        0xca273eceea26619c, 0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178,
        0x06f067aa72176fba, 0x0a637dc5a2c898a6, 0x113f9804bef90dae, 0x1b710b35131c471b,
        0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc, 0x431d67c49c100d4c,
        0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817
    ];

    let iv : [State] = [[
            // 512-224
            0x8c3d37c819544da2, 0x73e1996689dcd4d6, 0x1dfab7ae32ff9c82, 0x679dd514582f9fcf, 
            0x0f6d2b697bd44da8, 0x77e36f7304c48942, 0x3f9d85a86a1d36c8, 0x1112e6ad91d692a1, 
        ],[
            // 512-256
            0x22312194fc2bf72c, 0x9f555fa3c84c64c2, 0x2393b86b6f53b151, 0x963877195940eabd,
            0x96283ee2a88effe3, 0xbe5e1e2553863992, 0x2b0199fc2c85b8aa, 0x0eb72ddc81c52ca2,
        ],[
            // 384
            0xcbbb9d5dc1059ed8, 0x629a292a367cd507, 0x9159015a3070dd17, 0x152fecd8f70e5939,
            0x67332667ffc00b31, 0x8eb44a8768581511, 0xdb0c2e0d64f98fa7, 0x47b5481dbefa4fa4,
        ],[
            // 512
            0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
            0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179,
        ]];

    let expansion_rounds = [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79];

    let compression_rounds = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79];

    let rot = Nat64.bitrotRight;

    public class Engine() {
        // arrays for state and message schedule
        let state_ = Array.init<Word>(8, 0);
        let w = Array.init<Word>(80, 0);

        public func init(n : Nat) {
            for (i in Iter.range(0, 7)) { 
                state_[i] := iv[n][i];
            };
        };

        // hash one block
        public func process_block(data : Block) {
            assert data.size() == block_size;
            // copy block to words
            w[0] :=
                Nat64.fromIntWrap(Nat8.toNat(data[0])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[1])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[2])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[3])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[4])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[5])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[6])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[7])) << 00;
            w[1] :=
                Nat64.fromIntWrap(Nat8.toNat(data[8])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[9])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[10])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[11])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[12])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[13])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[14])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[15])) << 00;
            w[2] :=
                Nat64.fromIntWrap(Nat8.toNat(data[16])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[17])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[18])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[19])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[20])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[21])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[22])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[23])) << 00;
            w[3] :=
                Nat64.fromIntWrap(Nat8.toNat(data[24])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[25])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[26])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[27])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[28])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[29])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[30])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[31])) << 00;
            w[4] :=
                Nat64.fromIntWrap(Nat8.toNat(data[32])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[33])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[34])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[35])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[36])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[37])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[38])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[39])) << 00;
            w[5] :=
                Nat64.fromIntWrap(Nat8.toNat(data[40])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[41])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[42])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[43])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[44])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[45])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[46])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[47])) << 00;
            w[6] :=
                Nat64.fromIntWrap(Nat8.toNat(data[48])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[49])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[50])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[51])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[52])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[53])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[54])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[55])) << 00;
            w[7] :=
                Nat64.fromIntWrap(Nat8.toNat(data[56])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[57])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[58])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[59])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[60])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[61])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[62])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[63])) << 00;
            w[8] :=
                Nat64.fromIntWrap(Nat8.toNat(data[64])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[65])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[66])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[67])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[68])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[69])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[70])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[71])) << 00;
            w[9] :=
                Nat64.fromIntWrap(Nat8.toNat(data[72])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[73])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[74])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[75])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[76])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[77])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[78])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[79])) << 00;
            w[10] :=
                Nat64.fromIntWrap(Nat8.toNat(data[80])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[81])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[82])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[83])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[84])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[85])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[86])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[87])) << 00;
            w[11] :=
                Nat64.fromIntWrap(Nat8.toNat(data[88])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[89])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[90])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[91])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[92])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[93])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[94])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[95])) << 00;
            w[12] :=
                Nat64.fromIntWrap(Nat8.toNat(data[96])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[97])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[98])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[99])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[100])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[101])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[102])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[103])) << 00;
            w[13] :=
                Nat64.fromIntWrap(Nat8.toNat(data[104])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[105])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[106])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[107])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[108])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[109])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[110])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[111])) << 00;
            w[14] :=
                Nat64.fromIntWrap(Nat8.toNat(data[112])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[113])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[114])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[115])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[116])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[117])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[118])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[119])) << 00;
            w[15] :=
                Nat64.fromIntWrap(Nat8.toNat(data[120])) << 56 |
                Nat64.fromIntWrap(Nat8.toNat(data[121])) << 48 |
                Nat64.fromIntWrap(Nat8.toNat(data[122])) << 40 |
                Nat64.fromIntWrap(Nat8.toNat(data[123])) << 32 |
                Nat64.fromIntWrap(Nat8.toNat(data[124])) << 24 |
                Nat64.fromIntWrap(Nat8.toNat(data[125])) << 16 |
                Nat64.fromIntWrap(Nat8.toNat(data[126])) << 08 |
                Nat64.fromIntWrap(Nat8.toNat(data[127])) << 00;
            // expand message
            for (i in expansion_rounds.keys()) {
                let (v0, v1) = (w[i + 1], w[i + 14]);
                let s0 = rot(v0, 01) ^ rot(v0, 08) ^ (v0 >> 07);
                let s1 = rot(v1, 19) ^ rot(v1, 61) ^ (v1 >> 06);
                w[i+16] := w[i] +% s0 +% w[i + 09] +% s1;
            };
            // compress
            var a = state_[0];
            var b = state_[1];
            var c = state_[2];
            var d = state_[3];
            var e = state_[4];
            var f = state_[5];
            var g = state_[6];
            var h = state_[7];
            for (i in compression_rounds.keys()) {
                let ch = (e & f) ^ (^ e & g);
                let maj = (a & b) ^ (a & c) ^ (b & c);
                let sigma0 = rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
                let sigma1 = rot(e, 14) ^ rot(e, 18) ^ rot(e, 41);
                let t = h +% K[i] +% w[i] +% ch +% sigma1;
                h := g;
                g := f;
                f := e;
                e := d +% t;
                d := c;
                c := b;
                b := a;
                a := t +% maj +% sigma0;
            };
            // final addition
            state_[0] +%= a;
            state_[1] +%= b;
            state_[2] +%= c;
            state_[3] +%= d;
            state_[4] +%= e;
            state_[5] +%= f;
            state_[6] +%= g;
            state_[7] +%= h;
        };    

        public func state() : [Nat8] {
            let buf = Buffer.Buffer<Nat8>(64);
            for (wi in state_.vals()) {
                let w = BigEndian.fromNat64(wi);
                buf.add(w[0]);
                buf.add(w[1]);
                buf.add(w[2]);
                buf.add(w[3]);
                buf.add(w[4]);
                buf.add(w[5]);
                buf.add(w[6]);
                buf.add(w[7]);
            };
            buf.toArray()
        };

    }; // class Engine
};
