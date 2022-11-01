import Array "mo:base/Array";
import Blob "mo:base/Blob";
import C "mo:matchers/Canister";
import D "mo:base/Debug";
import Iter "mo:base/Iter";
import M "mo:matchers/Matchers";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";
import Text "mo:base/Text";
import Char "mo:base/Char";
import Types "../origyn_nft_reference/types";
import utils "test_utils";

shared (deployer) actor class test_runner_http(dfx_ledger: Principal, event_system_canister: Principal) = this {
    let it = C.Tester({ batchSize = 8 });

    private type canister_factory_actor = actor {
        create : ({owner: Principal; storage_space: ?Nat; event_system_canister: Principal}) -> async Principal;
    };

    private var g_canister_factory : canister_factory_actor = actor(Principal.toText(Principal.fromBlob("\04")));

    public shared func test(canister_factory : Principal, storage_factory: Principal) : async {#success; #fail : Text} {

        g_canister_factory := actor(Principal.toText(canister_factory));

        let token_id = "1";
        let non_existent_token = "2";

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
            event_system_canister=event_system_canister;
        });

        let canister : Types.Service = actor(Principal.toText(newPrincipal));
        let standardStage = await utils.buildStandardNFT(token_id, canister, Principal.fromActor(this), 1024, false);

        let suite = S.suite("test nft", [
            S.test("token not found", switch(await testRequestStatus("/-/"# non_existent_token # "/info", newPrincipal)){case(#fail(_)){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("token info", switch(await testRequestStatus("/-/"# token_id # "/info", newPrincipal)){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("page info", switch(await testRequestStatus("/-/"# token_id # "/-/" # "page" # "/info", newPrincipal)){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("certificate page", switch(await testCertification(token_id, "page", newPrincipal)){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
        ]);
        S.run(suite);

        return #success;
    };


    public shared func testRequestStatus(url: Text, canister_principal: Principal) : async {#success; #fail : Text} {
        let canister : Types.Service = actor(Principal.toText(canister_principal));

        let status_code = switch(await canister.http_request({
            body = Blob.fromArray([]);
            headers = [
                ("host", Principal.toText(canister_principal) # ".icp"),
            ];
            method = "GET";
            url = url;
        })){
            case(response) {
                response.status_code;
            };
        };

        if(status_code != 200) {
            return #fail(debug_show("URL: ", url, "-- did not pass the test --", status_code));
        };

        #success;
    };

    private func base64ToASCII(b : Text): Text {
        var decoded: [Char] = [];
        let encoded = Iter.toArray(Text.toIter(b));

        var i: Nat = 0;
        var num: Nat32 = 0;
        var count_bits: Nat32 = 0;

        for (next in Iter.range(0, (encoded.size() / 4) - 1)) {
            i := next * 4;
            num := 0; count_bits := 0;
            for (j in Iter.range(0, 4 - 1)) {
                if (Char.notEqual(encoded[i + j], '='))
                {
                    num := (num << 6);
                    count_bits := count_bits + 6;
                };

                if (Char.toNat32(encoded[i + j]) >= Char.toNat32('A') and Char.toNat32(encoded[i + j]) <= Char.toNat32('Z')) {
                    num := num | (Char.toNat32(encoded[i + j]) - Char.toNat32('A'));
                }
                else if (Char.toNat32(encoded[i + j]) >= Char.toNat32('a') and Char.toNat32(encoded[i + j]) <= Char.toNat32('z')) {
                    num := num | (Char.toNat32(encoded[i + j]) - Char.toNat32('a') + 26);
                }
                else if (Char.toNat32(encoded[i + j]) >= Char.toNat32('0') and Char.toNat32(encoded[i + j]) <= Char.toNat32('9')) {
                    num := num | (Char.toNat32(encoded[i + j]) - Char.toNat32('0') + 52);
                }
                else if (Char.toNat32(encoded[i + j]) == Char.toNat32('+')) {
                    num := num | 62;
                }
                else if (Char.toNat32(encoded[i + j]) == Char.toNat32('/')) {
                    num := num | 63;
                }
                else {
                    num := num >> 2;
                    count_bits := count_bits - 2;
                };
            };

            while (count_bits != 0) {
                count_bits := count_bits - 8;
                let new: Char = Char.fromNat32((num >> count_bits) & 255);
                decoded := Array.append<Char>(decoded, [new]);
            };
        };

        return Text.fromIter(Iter.fromArray(decoded));
    };

    public shared func testCertification(token_id: Text, library_id: Text, canister_principal: Principal) : async {#success; #fail : Text} {
        let canister : Types.Service = actor(Principal.toText(canister_principal));
        await canister.subscribe(Types.handle_events.http_access_key, []);
        let access_key = switch(await canister.http_access_key()){
            case(#ok(key)) {key};
            case(_) {""};
        };

        let url = "/-/" # token_id # "/-/" # library_id # "?access=" # access_key;

        D.print(debug_show(url, "url"));

        switch(await canister.http_request({
            body = Blob.fromArray([]);
            headers = [
                ("host", Principal.toText(canister_principal) # ".icp"),
            ];
            method = "GET";
            url = url;
        })){
            case(response) {
                var is_cert = false;
                for ((key, value) in response.headers.vals()) {
                    if(key == "ic-certificate") {
                        is_cert := true;
                        let split = Iter.toArray(Text.split(value, #text("tree=")));
                        let tree = Text.replace(split[split.size() - 1], #char(':'), "");

                        let treeASCII = base64ToASCII(tree);
                        let is_http_assets = Text.contains(treeASCII, #text("http_assets"));
                        let is_key = Text.contains(treeASCII, #text("/-/1/-/page"));

                        if(is_http_assets == false or is_key == false) {
                            return #fail(debug_show("URL: ", url, "-- invalid certificate --", response.status_code));
                        }
                    };
                };

                if(is_cert == false) {
                    return #fail(debug_show("URL: ", url, "-- certificate not found --", response.status_code));
                };

                if(response.status_code != 200) {
                    return #fail(debug_show("URL: ", url, "-- did not pass the test --", response.status_code));
                };
            };
        };


        #success;
    };
}