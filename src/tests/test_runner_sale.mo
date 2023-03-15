import AccountIdentifier "mo:principalmo/AccountIdentifier";
import Blob "mo:base/Blob";
import C "mo:matchers/Canister";
import D "mo:base/Debug";
import DFXTypes "../origyn_nft_reference/dfxtypes";
import Error "mo:base/Error";
import M "mo:matchers/Matchers";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import S "mo:matchers/Suite";
import Sales "../origyn_sale_reference/main";
import T "mo:matchers/Testable";
import TestWalletDef "test_wallet";
import Time "mo:base/Time";
import Types "../origyn_nft_reference/types";
import utils "test_utils";
//import Instant "test_runner_instant_transfer";


shared (deployer) actor class test_runner_sale(dfx_ledger: Principal, dfx_ledger2: Principal) = this {

    private type canister_factory = actor {
        create : (Principal) -> async Principal;
    };

    let it = C.Tester({ batchSize = 8 });

    
    private var DAY_LENGTH = 60 * 60 * 24 * 10 ** 9;
    private var dip20_fee = ?200_000;

    private var dfx_token_spec = #ic({
            canister= dfx_ledger; 
            standard=#Ledger;
            decimals = 8;
            symbol = "LDG";
            fee = 200000;});

    private func get_time() : Int{
        return Time.now();
    };

    private type canister_factory_actor = actor {
        create : ({owner: Principal; storage_space: ?Nat}) -> async Principal;
    };
    private type storage_factory_actor = actor {
        create : ({owner: Principal; storage_space: ?Nat}) -> async Principal;
    };

    private var g_canister_factory : canister_factory_actor = actor(Principal.toText(Principal.fromBlob("\04")));
    private var g_storage_factory: storage_factory_actor = actor(Principal.toText(Principal.fromBlob("\04")));

    

    public shared func test(canister_factory : Principal, storage_factory: Principal) : async {#success; #fail : Text} {
        
        //let Instant_Test = await Instant.test_runner_instant_transfer();

        g_canister_factory := actor(Principal.toText(canister_factory));
        g_storage_factory := actor(Principal.toText(storage_factory));
        D.print("in test");

        let suite = S.suite("test nft", [
            S.test("testLoadNFTs", switch(await testLoadNFTS()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testManagement", switch(await testManagement()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testAllocation", switch(await testAllocation()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            S.test("testRedeemAllocation", switch(await testRedeemAllocation()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            //S.test("testRegistration", switch(await testRegistration()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            //S.test("testReservation", switch(await testReservation()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            //S.test("testReservationNoReg", switch(await testReservationNoReg()){case(#success){true};case(_){false};}, M.equals<Bool>(T.bool(true))),
            ]);
        S.run(suite);

        return #success;
    };

    public shared func testReservation() : async {#success; #fail : Text} {
        D.print("running testReservation");

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        let c_wallet = await TestWalletDef.test_wallet();
        let d_wallet = await TestWalletDef.test_wallet();
        let e_wallet = await TestWalletDef.test_wallet();
        let f_wallet = await TestWalletDef.test_wallet();

        D.print("have wallets");

        //fund wallets

        let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
        let funding_result = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(a_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_2 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(b_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_5 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(c_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_3 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(d_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_4 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(e_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_6 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(f_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        D.print("have canister");

        D.print("calling stage");

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage4 = await utils.buildStandardNFT("4", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage5 = await utils.buildStandardNFT("5", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage6 = await utils.buildStandardNFT("6", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage7 = await utils.buildStandardNFT("7", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage8 = await utils.buildStandardNFT("8", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));

        let registration_date = Time.now() + 100000000000;
        let allocation_date = Time.now() + 900000000000;
        let lock_until = allocation_date + 900000000000;
        //create sales canister
        let sale_canister = await Sales.SaleCanister({
            owner = Principal.fromActor(this);
            allocation_expiration = 900000000000;
            nft_gateway = ?Principal.fromActor(canister);
            sale_open_date = ?(allocation_date);  // in 15 minutes 
            registration_date = ?registration_date;
            end_date = null;
            required_lock_date = ?(lock_until); //15 minutes past allocation date
            
        });

        let manager_add = await canister.collection_update_nft_origyn(#UpdateManagers([Principal.fromActor(sale_canister)]));
        //D.print("manager add" # debug_show(manager_add));
       

       

        D.print("adding unminted");

        let add_unminted_1 = await sale_canister.manage_nfts_sale_nft_origyn([
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "1";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "2";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "3";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "4";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "5";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "6";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "5";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "6";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "7";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "8";
                }),
            ]
        );

        //we will allocate one specific to a
        //we will allocate one group to a

        //we will have a register one and then buy one after


        //we will allocate five to group b

        //we will have b regiser for 4

        //b regiters for 2
        //b buy 2

        //have c/d try to buy

        //create a defalut group with an allocation of 2

        let defaultGroup = await sale_canister.manage_group_sale_nft_origyn([#update({
            namespace = ""; //default namespace
            members = null;
            pricing = ?[#cost_per{
                amount = 1000000000;
                token = #ic({
                    canister = dfx_ledger;
                    fee = 200000 : Nat;
                    symbol = "OGY";
                    decimals = 8 : Nat;
                    standard = #Ledger;
                });
            }];
            allowed_amount = ?2;
            tier = 0;
            additive = true;
        }
        )]);

        //create a specific group with allocation of 2 for b wallet
        let aGroup =  await sale_canister.manage_group_sale_nft_origyn([#update({
                namespace = "agroup"; //default namespace
                members = ?[Principal.fromActor(a_wallet)];
                pricing = ?[#cost_per{
                    amount = 1000000000;
                    token = #ic({
                        canister = dfx_ledger;
                        fee = 200000;
                        symbol = "OGY";
                        decimals = 8;
                        standard = #Ledger;
                    })
                }];
                allowed_amount = ?1;
                additive = true;
                tier = 1;
            }
        )]);

        //put b and c in b group

        //create a specific group with allocation of 2 for b wallet
        let bGroup =  await sale_canister.manage_group_sale_nft_origyn([#update({
                namespace = "bgroup"; //default namespace
                members = ?[Principal.fromActor(b_wallet),Principal.fromActor(c_wallet)];
                pricing = ? [#cost_per{
                    amount = 1000000000;
                    token = #ic({
                        canister = dfx_ledger;
                        fee = 200000;
                        symbol = "OGY";
                        decimals = 8;
                        standard = #Ledger;
                    })
                }];
                allowed_amount = ?2;
                additive = true;
                tier = 2
            }
        )]);

        //set up reservations:

        // allocate "1" to a_wallet
        let a_principal_request = await sale_canister.manage_reservation_sale_nft_origyn([
            #add({
                namespace = Principal.toText(Principal.fromActor(a_wallet)) # "individual";
                reservation_type = #Principal(Principal.fromActor(a_wallet));
                nfts : [Text] = ["1" : Text];
                exclusive = true;
            }
            )
        ]);

        // allocate "2","3" to a group a

        let a_group_request = await sale_canister.manage_reservation_sale_nft_origyn([
            #add({
                namespace = "agroupreservation";
                reservation_type = #Groups(["agroup"]);
                nfts : [Text] = ["2" : Text, "3"];
                exclusive = true;
            }
            )
        ]);

        // allocate "4,5,6,7,8" to  group b 

        let b_group_request = await sale_canister.manage_reservation_sale_nft_origyn([
            #add({
                namespace = "bgroupreservation";
                reservation_type = #Groups(["bgroup"]);
                nfts : [Text] = ["4", "5", "6", "7", "8"];
                exclusive = true;
            }
            )
        ]);

        D.print("finished group requets" # debug_show(b_group_request));

        

        //leave d out but try to get one anyway...should fail

        let aRedeem_payment_2 = await a_wallet.send_ledger_payment(dfx_ledger, (30 * 10 ** 8) + 600000, Principal.fromActor(canister));

        D.print("apayment"# debug_show(aRedeem_payment_2));

        let a_wallet_try_escrow_general_valid = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(aRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, 30  * 10 ** 8, ?dfx_token_spec, ?lock_until);

        D.print("about to try registration"# debug_show(a_wallet_try_escrow_general_valid));
        //register escrow for one NFT

        let a_wallet_try_register_for_one = await a_wallet.try_sale_registration(Principal.fromActor(sale_canister), { principal = Principal.fromActor(a_wallet); max_desired = 1; escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
            ?{
                
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 10 * 10 ** 8; //one icp for one

            }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});

        D.print("registered for one " # debug_show(a_wallet_try_register_for_one));
        //check that registration is updated

        let a_wallet_registration_after_one = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(a_wallet));

        //redeem escrow for the two more of the NFTs

        D.print("about to payment b");
        
        //register b for 4 with additive
        let bRedeem_payment_2 = await b_wallet.send_ledger_payment(dfx_ledger, (40 * 10 ** 8) + 800000, Principal.fromActor(canister));

        D.print("about to escrow b" # debug_show(bRedeem_payment_2));

        let b_wallet_try_escrow_general_valid = await b_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(bRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, 40  * 10 ** 8, ?dfx_token_spec, ?lock_until);

        D.print("about to register b" # debug_show(b_wallet_try_escrow_general_valid));
        let b_wallet_try_register_for_two = await b_wallet.try_sale_registration(Principal.fromActor(sale_canister), {principal = Principal.fromActor(b_wallet); max_desired = 2; escrow_receipt = switch(b_wallet_try_escrow_general_valid){case(#ok(val)){
            ?{
                
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 20 * 10 ** 8; //20 icp for two
            }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});

        D.print("registered for two " # debug_show(b_wallet_try_register_for_two));
        

        let b_wallet_registration_after_four = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(b_wallet));

        //regist d for 2 with non-additive but should get allocated none due to reservations

        let dRedeem_payment_2 = await d_wallet.send_ledger_payment(dfx_ledger, (20  * 10 ** 8) + 400000, Principal.fromActor(canister));

        let d_wallet_try_escrow_general_valid = await d_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(dRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, 20 * 10 ** 8, ?dfx_token_spec, ?lock_until);

        let d_wallet_try_register_for_two= await d_wallet.try_sale_registration(Principal.fromActor(sale_canister), {principal = Principal.fromActor(d_wallet); max_desired = 2; escrow_receipt = switch(d_wallet_try_escrow_general_valid){case(#ok(val)){
            ?{
                
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 20 * 10 ** 8; //40 icp for four but shold only get two
            }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});


        let d_wallet_registration_after_two = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(d_wallet));

        //advance time

        D.print("registered for two d " # debug_show(d_wallet_registration_after_two));
        

        let advancer = await sale_canister.__advance_time(allocation_date + 1);

        //assure allocation is made
            //ways to assure this
            //make a new registration?
            //make a new allocation?
            //reedeem an allocatoin?

       let d_balance_before_allocation = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(d_wallet)));

        //shold be empty
       let d_allocate_empty = await d_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(d_wallet);
            number_to_allocate = 1;
            token = ?dfx_token_spec;
        });

        //should be 2
        let a_allocate_empty = await a_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(a_wallet);
            number_to_allocate = 2;
            token = ?dfx_token_spec;
        });

        let a_wallet_try_redeem_for_one = await a_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
        {
            buyer = val.receipt.buyer;
            seller = val.receipt.seller;
            token = dfx_token_spec;
            token_id = "";
            amount = 10 * 10 ** 8; //one icp for one

        }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});

        D.print("reddem for one a " # debug_show(a_wallet_try_redeem_for_one));


        let b_allocate_empty = await b_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(b_wallet);
            number_to_allocate = 2;
            token = ?dfx_token_spec;
        });

        let b_wallet_try_redeem_for_one = await b_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(b_wallet_try_escrow_general_valid){case(#ok(val)){
        {
            buyer = val.receipt.buyer;
            seller = val.receipt.seller;
            token = dfx_token_spec;
            token_id = "";
            amount = 20 * 10 ** 8; //one icp for one

        }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});

        D.print("reddem for one b " # debug_show(b_wallet_try_redeem_for_one));



        //should fail event though A qualifes for 3 because it is reserved for c

        let a_allocate_empty_after_two = await a_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(a_wallet);
            number_to_allocate = 2;
            token = ?dfx_token_spec;
        });

        let a_wallet_try_redeem_for_third = await a_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
        {
            buyer = val.receipt.buyer;
            seller = val.receipt.seller;
            token = dfx_token_spec;
            token_id = "";
            amount = 10 * 10 ** 8; //one icp for one

        }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});


        D.print("reddem for third a " # debug_show(a_wallet_try_redeem_for_third));


        let cRedeem_payment_2 = await c_wallet.send_ledger_payment(dfx_ledger, (20  * 10 ** 8) + 400000, Principal.fromActor(canister));

        let c_wallet_try_escrow_general_valid = await c_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(cRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, 20 * 10 ** 8, ?dfx_token_spec, ?lock_until);



        let c_allocate_empty_after_two = await c_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(c_wallet);
            number_to_allocate = 2;
            token = ?dfx_token_spec;
        });

        let c_wallet_try_redeem_for_one = await c_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(c_wallet_try_escrow_general_valid){case(#ok(val)){
        {
            buyer = val.receipt.buyer;
            seller = val.receipt.seller;
            token = dfx_token_spec;
            token_id = "";
            amount = 20 * 10 ** 8; //one icp for one

        }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});


        D.print("redeem for two c " # debug_show(c_wallet_try_redeem_for_one));
        

    
        //check that allocation is updated

        let a_wallet_registration_after_allocation = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(a_wallet));
        let b_wallet_registration_after_allocation = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(b_wallet));
        let c_wallet_registration_after_allocation = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(c_wallet));
        let d_wallet_registration_after_allocation = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(d_wallet));


        D.print("balance after allocation " # debug_show(a_wallet_registration_after_allocation,b_wallet_registration_after_allocation,c_wallet_registration_after_allocation,d_wallet_registration_after_allocation));
        

        //claim
        switch(
            a_wallet_registration_after_allocation,
            b_wallet_registration_after_allocation,
            c_wallet_registration_after_allocation,
            d_wallet_registration_after_allocation){
                case(#ok(a),#ok(b),#ok(c),#ok(d)){
                    for(thisitem in a.allocation.vals()){
                        let claim_result = await sale_canister.execute_claim_sale_nft_origyn(thisitem.token_id);
                    };
                    for(thisitem in b.allocation.vals()){
                        let claim_result = await sale_canister.execute_claim_sale_nft_origyn(thisitem.token_id);
                    };
                    for(thisitem in c.allocation.vals()){
                        let claim_result = await sale_canister.execute_claim_sale_nft_origyn(thisitem.token_id);
                    };
                    for(thisitem in d.allocation.vals()){
                        let claim_result = await sale_canister.execute_claim_sale_nft_origyn(thisitem.token_id);
                    };
                };
                case(_,_,_,_) {
                    D.print("THROW ----------------- couldnt get the registratons after allocation" # debug_show(a_wallet_registration_after_allocation,b_wallet_registration_after_allocation,c_wallet_registration_after_allocation,d_wallet_registration_after_allocation));
                    throw(Error.reject("THROW ----------------- couldnt get the registratons after allocation"));
                };          
        };

        //check nft balance

        let a_wallet_balance_after_three = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        let b_wallet_balance_after_three = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet)));
        let c_wallet_balance_after_three = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(c_wallet)));
        let d_wallet_balance_after_three = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(d_wallet)));
    

        D.print("balance after three " # debug_show(a_wallet_balance_after_three,b_wallet_balance_after_three,c_wallet_balance_after_three,d_wallet_balance_after_three));
        

        //try to allocate nfts --- should be out of inventory

        let c_allocate_empty_2_end = await c_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(c_wallet);
            number_to_allocate = 1;
            token = ?dfx_token_spec;
        });


        let a_allocate_empty_3_end = await a_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(a_wallet);
            number_to_allocate = 1;
            token = ?dfx_token_spec;
        });

        let d_allocate_empty_3_end = await d_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(d_wallet);
            number_to_allocate = 1;
            token = ?dfx_token_spec;
        });



        //D.print("running suite test registrations");

        let suite = S.suite("test registration", [
           
           S.test("can register one item", switch(d_balance_before_allocation){case(#ok(res)){
                if(res.nfts.size() == 0){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 

            S.test("fail d is allocated inventory", switch(d_allocate_empty){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5004){ //empty inventory because all are allocated to reservations
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),

             S.test("fail if a is allocated more than 1 inventory", switch(a_allocate_empty){case(#ok(res)){
                if(res.allocation_size == 1){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
             S.test("b should be allocated two more", switch(a_allocate_empty){case(#ok(res)){
                if(res.allocation_size == 2){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
             S.test("fail d is allocated inventory", switch(a_allocate_empty_after_two){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5004){ //empty inventory because all are allocated to reservations
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
             S.test("fail a if allocating for a un allocated item", switch(a_wallet_try_redeem_for_third){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5001){ //allocation doesnt exist
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            S.test("c can register for one", switch(c_allocate_empty_after_two){case(#ok(res)){
                if(res.allocation_size == 1){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("c can register for one", switch(c_wallet_try_redeem_for_one){case(#ok(res)){
                if(res.nfts.size() == 1){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 

             S.test("only 8 items allocated in balance", switch(
                a_wallet_balance_after_three,
                b_wallet_balance_after_three,
                c_wallet_balance_after_three,
                d_wallet_balance_after_three){
                    case(#ok(a),#ok(b),#ok(c),#ok(d)){
                        if(a.nfts.size() + b.nfts.size() + c.nfts.size() + d.nfts.size() == 8){
                            "expected success"
                        } else {
                            "unexpected success" # debug_show((a,b,c,d))
                        }};
                    case(_,_,_,_) {
                        "wrong error " # debug_show((a_wallet_balance_after_three, b_wallet_balance_after_three, c_wallet_balance_after_three, d_wallet_balance_after_three));
                    };          
            }, M.equals<Text>(T.text("expected success"))), 

             S.test("fail if  is allocated inventory", switch(c_allocate_empty_2_end){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5004){ //empty inventory because all are allocated to reservations
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),

             S.test("fail if  is allocated inventory", switch(a_allocate_empty_3_end){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5004){ //empty inventory because all are allocated to reservations
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),

             S.test("fail if  is allocated inventory", switch(d_allocate_empty_3_end){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5004){ //empty inventory because all are allocated to reservations
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            
            
            
        ]);

        S.run(suite);

        return #success;
    };

    public shared func testReservationNoReg() : async {#success; #fail : Text} {
        D.print("running testRegistration");

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        let c_wallet = await TestWalletDef.test_wallet();
        let d_wallet = await TestWalletDef.test_wallet();
        let e_wallet = await TestWalletDef.test_wallet();
        let f_wallet = await TestWalletDef.test_wallet();

        D.print("have wallets");

        //fund wallets

        let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
        let funding_result = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(a_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_2 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(b_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_5 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(c_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_3 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(d_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_4 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(e_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_6 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(f_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        D.print("have canister");

        D.print("calling stage");

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage4 = await utils.buildStandardNFT("4", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage5 = await utils.buildStandardNFT("5", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage6 = await utils.buildStandardNFT("6", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage7 = await utils.buildStandardNFT("7", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage8 = await utils.buildStandardNFT("8", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));

        let registration_date = Time.now() + 100000000000;
        let allocation_date = Time.now() + 900000000000;
        let lock_until = allocation_date + 900000000000;
        //create sales canister
        let sale_canister = await Sales.SaleCanister({
            owner = Principal.fromActor(this);
            allocation_expiration = 900000000000;
            nft_gateway = ?Principal.fromActor(canister);
            sale_open_date = ?(allocation_date);  // in 15 minutes 
            registration_date = ?registration_date;
            end_date = null;
            required_lock_date = ?(lock_until); //15 minutes past allocation date
            
        });

        let manager_add = await canister.collection_update_nft_origyn(#UpdateManagers([Principal.fromActor(sale_canister)]));
        //D.print("manager add" # debug_show(manager_add));
       

       

        D.print("adding unminted");

        let add_unminted_1 = await sale_canister.manage_nfts_sale_nft_origyn([
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "1";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "2";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "3";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "4";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "5";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "6";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "5";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "6";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "7";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "8";
                }),
            ]
        );

        //we will allocate one specific to a
        //we will allocate one group to a

        //we will have a register one and then buy one after


        //we will allocate five to group b

        //we will have b regiser for 4

        //b regiters for 2
        //b buy 2

        //have c/d try to buy

        //create a defalut group with an allocation of 2

        let defaultGroup = await sale_canister.manage_group_sale_nft_origyn([#update({
            namespace = ""; //default namespace
            members = null;
            pricing = ?[#cost_per{
                amount = 1000000000;
                token = #ic({
                    canister = dfx_ledger;
                    fee = 200000 : Nat;
                    symbol = "OGY";
                    decimals = 8 : Nat;
                    standard = #Ledger;
                });
            }];
            allowed_amount = ?2;
            tier = 0;
            additive = true;
        }
        )]);

        //create a specific group with allocation of 2 for b wallet
        let aGroup =  await sale_canister.manage_group_sale_nft_origyn([#update({
                namespace = "agroup"; //default namespace
                members = ?[Principal.fromActor(a_wallet)];
                pricing = ?[#cost_per{
                    amount = 1000000000;
                    token = #ic({
                        canister = dfx_ledger;
                        fee = 200000;
                        symbol = "OGY";
                        decimals = 8;
                        standard = #Ledger;
                    })
                }];
                allowed_amount = ?1;
                additive = true;
                tier = 1;
            }
        )]);

        //put b and c in b group

        //create a specific group with allocation of 2 for b wallet
        let bGroup =  await sale_canister.manage_group_sale_nft_origyn([#update({
                namespace = "bgroup"; //default namespace
                members = ?[Principal.fromActor(b_wallet),Principal.fromActor(c_wallet)];
                pricing = ? [#cost_per{
                    amount = 1000000000;
                    token = #ic({
                        canister = dfx_ledger;
                        fee = 200000;
                        symbol = "OGY";
                        decimals = 8;
                        standard = #Ledger;
                    })
                }];
                allowed_amount = ?2;
                additive = true;
                tier = 2
            }
        )]);

        //set up reservations:

        // allocate "1" to a_wallet
        let a_principal_request = await sale_canister.manage_reservation_sale_nft_origyn([
            #add({
                namespace = Principal.toText(Principal.fromActor(a_wallet)) # "individual";
                reservation_type = #Principal(Principal.fromActor(a_wallet));
                nfts : [Text] = ["1" : Text];
                exclusive = true;
            }
            )
        ]);

        // allocate "2","3" to a group a

        let a_group_request = await sale_canister.manage_reservation_sale_nft_origyn([
            #add({
                namespace = "agroupreservation";
                reservation_type = #Groups(["agroup"]);
                nfts : [Text] = ["2" : Text, "3"];
                exclusive = true;
            }
            )
        ]);

        // allocate "4,5,6,7,8" to  group b 

        let b_group_request = await sale_canister.manage_reservation_sale_nft_origyn([
            #add({
                namespace = "bgroupreservation";
                reservation_type = #Groups(["bgroup"]);
                nfts : [Text] = ["4", "5", "6", "7", "8"];
                exclusive = true;
            }
            )
        ]);

        D.print("finished group requets" # debug_show(b_group_request));

        

        //leave d out but try to get one anyway...should fail


         let advancer = await sale_canister.__advance_time(allocation_date + 1);

        let aRedeem_payment_2 = await a_wallet.send_ledger_payment(dfx_ledger, (30 * 10 ** 8) + 600000, Principal.fromActor(canister));

        D.print("apayment"# debug_show(aRedeem_payment_2));

        let a_wallet_try_escrow_general_valid = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(aRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, 30  * 10 ** 8, ?dfx_token_spec, ?lock_until);

        D.print("about to try registration"# debug_show(a_wallet_try_escrow_general_valid));
        //register escrow for one NFT

        let a_allocate_one = await a_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(a_wallet);
            number_to_allocate = 1;
            token = ?dfx_token_spec;
        });

        let a_wallet_try_redeem_for_one = await a_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
        {
            buyer = val.receipt.buyer;
            seller = val.receipt.seller;
            token = dfx_token_spec;
            token_id = "";
            amount = 10 * 10 ** 8; //one icp for one

        }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});


        //redeem escrow for the two more of the NFTs

        D.print("about to payment b");
        
        //register b for 4 with additive
        let bRedeem_payment_2 = await b_wallet.send_ledger_payment(dfx_ledger, (40 * 10 ** 8) + 800000, Principal.fromActor(canister));

        D.print("about to escrow b" # debug_show(bRedeem_payment_2));

        let b_wallet_try_escrow_general_valid = await b_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(bRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, 40  * 10 ** 8, ?dfx_token_spec, ?lock_until);

        D.print("about to register b" # debug_show(b_wallet_try_escrow_general_valid));
        

        let b_allocate_two = await b_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(b_wallet);
            number_to_allocate = 2;
            token = ?dfx_token_spec;
        });

        let b_wallet_try_redeem_for_two = await a_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(b_wallet_try_escrow_general_valid){case(#ok(val)){
        {
            buyer = val.receipt.buyer;
            seller = val.receipt.seller;
            token = dfx_token_spec;
            token_id = "";
            amount = 20 * 10 ** 8; //one icp for one

        }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});

        

        let b_wallet_registration_after_four = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(b_wallet));

        //regist d for 2 with non-additive but should get allocated none due to reservations

        let dRedeem_payment_2 = await d_wallet.send_ledger_payment(dfx_ledger, (20  * 10 ** 8) + 400000, Principal.fromActor(canister));

        let d_wallet_try_escrow_general_valid = await d_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(dRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, 20  * 10 ** 8, ?dfx_token_spec, ?lock_until);


        let d_allocate_two = await d_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(d_wallet);
            number_to_allocate = 2;
            token = ?dfx_token_spec;
        });

        let d_wallet_try_redeem_for_two = await a_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(d_wallet_try_escrow_general_valid){case(#ok(val)){
        {
            buyer = val.receipt.buyer;
            seller = val.receipt.seller;
            token = dfx_token_spec;
            token_id = "";
            amount = 20 * 10 ** 8; //one icp for one

        }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});

        
        //advance time

        D.print("registered for two d " # debug_show(d_wallet_try_redeem_for_two));
        

       

        //assure allocation is made
            //ways to assure this
            //make a new registration?
            //make a new allocation?
            //reedeem an allocatoin?

       let d_balance_before_allocation = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(d_wallet)));

        //shold be empty
       let d_allocate_empty = await d_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(d_wallet);
            number_to_allocate = 1;
            token = ?dfx_token_spec;
        });

        //should be 2
        let a_allocate_empty = await a_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(a_wallet);
            number_to_allocate = 2;
            token = ?dfx_token_spec;
        });

        let a_wallet_try_redeem_for_one_more = await a_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
        {
            buyer = val.receipt.buyer;
            seller = val.receipt.seller;
            token = dfx_token_spec;
            token_id = "";
            amount = 10 * 10 ** 8; //one icp for one

        }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});

        D.print("reddem for one a " # debug_show(a_wallet_try_redeem_for_one_more));


        let b_allocate_empty = await b_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(b_wallet);
            number_to_allocate = 2;
            token = ?dfx_token_spec;
        });

        let b_wallet_try_redeem_for_one = await b_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(b_wallet_try_escrow_general_valid){case(#ok(val)){
        {
            buyer = val.receipt.buyer;
            seller = val.receipt.seller;
            token = dfx_token_spec;
            token_id = "";
            amount = 20 * 10 ** 8; //one icp for one

        }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});

        D.print("reddem for one b " # debug_show(b_wallet_try_redeem_for_one));



        //should fail event though A qualifes for 3 because it is reserved for c

        let a_allocate_empty_after_two = await a_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(a_wallet);
            number_to_allocate = 2;
            token = ?dfx_token_spec;
        });

        let a_wallet_try_redeem_for_third = await a_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
        {
            buyer = val.receipt.buyer;
            seller = val.receipt.seller;
            token = dfx_token_spec;
            token_id = "";
            amount = 10 * 10 ** 8; //one icp for one

        }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});


        D.print("reddem for third a " # debug_show(a_wallet_try_redeem_for_third));


        let cRedeem_payment_2 = await c_wallet.send_ledger_payment(dfx_ledger, (20  * 10 ** 8) + 400000, Principal.fromActor(canister));

        let c_wallet_try_escrow_general_valid = await c_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(cRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, 20 * 10 ** 8, ?dfx_token_spec, ?lock_until);



        let c_allocate_empty_after_two = await c_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(c_wallet);
            number_to_allocate = 2;
            token = ?dfx_token_spec;
        });

        let c_wallet_try_redeem_for_one = await c_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(c_wallet_try_escrow_general_valid){case(#ok(val)){
        {
            buyer = val.receipt.buyer;
            seller = val.receipt.seller;
            token = dfx_token_spec;
            token_id = "";
            amount = 20 * 10 ** 8; //one icp for one

        }};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});


        D.print("redeem for two c " # debug_show(c_wallet_try_redeem_for_one));
        

    
        //check that allocation is updated

        let a_wallet_registration_after_allocation = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(a_wallet));
        let b_wallet_registration_after_allocation = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(b_wallet));
        let c_wallet_registration_after_allocation = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(c_wallet));
        let d_wallet_registration_after_allocation = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(d_wallet));


        D.print("balance after allocation " # debug_show(a_wallet_registration_after_allocation,b_wallet_registration_after_allocation,c_wallet_registration_after_allocation,d_wallet_registration_after_allocation));
        

        //claim
        switch(
            a_wallet_registration_after_allocation,
            b_wallet_registration_after_allocation,
            c_wallet_registration_after_allocation,
            d_wallet_registration_after_allocation){
                case(#ok(a),#ok(b),#ok(c),#ok(d)){
                    for(thisitem in a.allocation.vals()){
                        let claim_result = await sale_canister.execute_claim_sale_nft_origyn(thisitem.token_id);
                    };
                    for(thisitem in b.allocation.vals()){
                        let claim_result = await sale_canister.execute_claim_sale_nft_origyn(thisitem.token_id);
                    };
                    for(thisitem in c.allocation.vals()){
                        let claim_result = await sale_canister.execute_claim_sale_nft_origyn(thisitem.token_id);
                    };
                    for(thisitem in d.allocation.vals()){
                        let claim_result = await sale_canister.execute_claim_sale_nft_origyn(thisitem.token_id);
                    };
                };
                case(_,_,_,_) {
                    D.print("THROW ----------------- couldnt get the registratons after allocation" # debug_show(a_wallet_registration_after_allocation,b_wallet_registration_after_allocation,c_wallet_registration_after_allocation,d_wallet_registration_after_allocation));
                    throw(Error.reject("THROW ----------------- couldnt get the registratons after allocation"));
                };          
        };

        //check nft balance

        let a_wallet_balance_after_three = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        let b_wallet_balance_after_three = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet)));
        let c_wallet_balance_after_three = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(c_wallet)));
        let d_wallet_balance_after_three = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(d_wallet)));
    

        D.print("balance after three " # debug_show(a_wallet_balance_after_three,b_wallet_balance_after_three,c_wallet_balance_after_three,d_wallet_balance_after_three));
        

        //try to allocate nfts --- should be out of inventory

        let c_allocate_empty_2_end = await c_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(c_wallet);
            number_to_allocate = 1;
            token = ?dfx_token_spec;
        });


        let a_allocate_empty_3_end = await a_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(a_wallet);
            number_to_allocate = 1;
            token = ?dfx_token_spec;
        });

        let d_allocate_empty_3_end = await d_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(d_wallet);
            number_to_allocate = 1;
            token = ?dfx_token_spec;
        });



        //D.print("running suite test registrations");

        let suite = S.suite("test registration", [
           
           S.test("can register one item", switch(d_balance_before_allocation){case(#ok(res)){
                if(res.nfts.size() == 0){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 

            S.test("fail d is allocated inventory", switch(d_allocate_empty){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5004){ //empty inventory because all are allocated to reservations
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),

             S.test("fail if a is allocated more than 1 inventory", switch(a_allocate_empty){case(#ok(res)){
                if(res.allocation_size == 1){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
             S.test("b should be allocated two more", switch(a_allocate_empty){case(#ok(res)){
                if(res.allocation_size == 2){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
             S.test("fail d is allocated inventory", switch(a_allocate_empty_after_two){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5004){ //empty inventory because all are allocated to reservations
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
             S.test("fail a if allocating for a un allocated item", switch(a_wallet_try_redeem_for_third){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5001){ //allocation doesnt exist
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            S.test("c can register for one", switch(c_allocate_empty_after_two){case(#ok(res)){
                if(res.allocation_size == 1){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("c can register for one", switch(c_wallet_try_redeem_for_one){case(#ok(res)){
                if(res.nfts.size() == 1){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 

             S.test("only 8 items allocated in balance", switch(
                a_wallet_balance_after_three,
                b_wallet_balance_after_three,
                c_wallet_balance_after_three,
                d_wallet_balance_after_three){
                    case(#ok(a),#ok(b),#ok(c),#ok(d)){
                        if(a.nfts.size() + b.nfts.size() + c.nfts.size() + d.nfts.size() == 8){
                            "expected success"
                        } else {
                            "unexpected success" # debug_show((a,b,c,d))
                        }};
                    case(_,_,_,_) {
                        "wrong error " # debug_show((a_wallet_balance_after_three, b_wallet_balance_after_three, c_wallet_balance_after_three, d_wallet_balance_after_three));
                    };          
            }, M.equals<Text>(T.text("expected success"))), 

             S.test("fail if  is allocated inventory", switch(c_allocate_empty_2_end){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5004){ //empty inventory because all are allocated to reservations
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),

             S.test("fail if  is allocated inventory", switch(a_allocate_empty_3_end){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5004){ //empty inventory because all are allocated to reservations
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),

             S.test("fail if  is allocated inventory", switch(d_allocate_empty_3_end){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5004){ //empty inventory because all are allocated to reservations
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            
            
            
        ]);

        S.run(suite);

        return #success;
    };

    public shared func testRegistration() : async {#success; #fail : Text} {
        D.print("running testRegistration");

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        let c_wallet = await TestWalletDef.test_wallet();
        let d_wallet = await TestWalletDef.test_wallet();
        let e_wallet = await TestWalletDef.test_wallet();
        let f_wallet = await TestWalletDef.test_wallet();

        //D.print("have wallets");

        //fund wallets

        let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
        let funding_result = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(a_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_2 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(b_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_5 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(c_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_3 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(d_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_4 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(e_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let funding_result_6 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(f_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  100 * 10 ** 8;});

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        

        //D.print("have canister");

        //D.print("calling stage");

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage4 = await utils.buildStandardNFT("4", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage5 = await utils.buildStandardNFT("5", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage6 = await utils.buildStandardNFT("6", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage7 = await utils.buildStandardNFT("7", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage8 = await utils.buildStandardNFT("8", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));

        let registration_date = Time.now() + 100000000000;
        let allocation_date = Time.now() + 900000000000;
        let lock_until = allocation_date + 900000000000;
        //create sales canister
        let sale_canister = await Sales.SaleCanister({
            owner = Principal.fromActor(this);
            allocation_expiration = 900000000000;
            nft_gateway = ?Principal.fromActor(canister);
            sale_open_date = ?(allocation_date);  // in 15 minutes 
            registration_date = ?registration_date;
            end_date = null;
            required_lock_date = ?(lock_until); //15 minutes past allocation date
            
        });

       let manager_add = await canister.collection_update_nft_origyn(#UpdateManagers([Principal.fromActor(sale_canister)]));
        //D.print("manager add" # debug_show(manager_add));
       

        //D.print("adding unminted");

        let add_unminted_1 = await sale_canister.manage_nfts_sale_nft_origyn([
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "1";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "2";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "3";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "4";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "5";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "6";
                }),
            ]
        );

        //create a defalut group with an allocation of 2

        let defaultGroup = await sale_canister.manage_group_sale_nft_origyn([#update({
            namespace = ""; //default namespace
            members = null;
            pricing = ?[#cost_per{
                amount = 1000000000;
                token = #ic({
                    canister = dfx_ledger;
                    fee = 200000 : Nat;
                    symbol = "OGY";
                    decimals = 8 : Nat;
                    standard = #Ledger;
                });
            }];
            allowed_amount = ?5;
            tier = 0;
            additive = true;
        }
        )]);

        //create a specific group with allocation of 2 for b wallet
        let bGroup =  await sale_canister.manage_group_sale_nft_origyn([#update({
                namespace = "bgroup"; //default namespace
                members = ?[Principal.fromActor(b_wallet)];
                pricing = ?[#cost_per{
                    amount = 1000000000;
                    token = #ic({
                        canister = dfx_ledger;
                        fee = 200000;
                        symbol = "OGY";
                        decimals = 8;
                        standard = #Ledger;
                    })
                }];
                allowed_amount = ?2;
                additive = true;
                tier = 1;
            }
        )]);

        //create a specific group with allocation of 2 for b wallet
        let dGroup =  await sale_canister.manage_group_sale_nft_origyn([#update({
                namespace = ""; //default namespace
                members = ?[Principal.fromActor(d_wallet)];
                pricing = ? [#cost_per{
                    amount = 1000000000;
                    token = #ic({
                        canister = dfx_ledger;
                        fee = 200000;
                        symbol = "OGY";
                        decimals = 8;
                        standard = #Ledger;
                    })
                }];
                allowed_amount = ?2;
                additive = false;
                tier = 2
            }
        )]);

       
        //have a redeem thier allocation

        let fRedeem_payment = await f_wallet.send_ledger_payment(dfx_ledger, (20  * 10 ** 8) + 400000, Principal.fromActor(canister));

        let f_wallet_try_escrow_general_no_lock = await f_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(fRedeem_payment){case(#ok(val)){?val};case(#err(err)){?0};}, 20  * 10 ** 8, ?dfx_token_spec, ?(lock_until - 1));


        //register before open
         let f_wallet_try_registration_before_open = await a_wallet.try_sale_registration(Principal.fromActor(sale_canister), {principal = Principal.fromActor(a_wallet); max_desired =1; escrow_receipt =  
            ?{
                buyer = #principal(Principal.fromActor(a_wallet));
                seller = #principal(Principal.fromActor(canister));
                token = dfx_token_spec;
                token_id = "";
                amount = 10 * 10 ** 8; //one icp for one token
            }});




        //register with fake escrow
         let a_wallet_try_registration_no_escrow = await a_wallet.try_sale_registration(Principal.fromActor(sale_canister), { principal = Principal.fromActor(a_wallet);max_desired =1; escrow_receipt =  
            ?{
                buyer = #principal(Principal.fromActor(a_wallet));
                seller = #principal(Principal.fromActor(canister));
                token = dfx_token_spec;
                token_id = "";
                amount = 10 * 10 ** 8; //one icp for one token
            }});

        //send payment to nft canister

        let aRedeem_payment = await a_wallet.send_ledger_payment(dfx_ledger, (20 * 10 ** 8) + 400000, Principal.fromActor(canister));

        let a_wallet_try_escrow_general_no_lock = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(aRedeem_payment){case(#ok(val)){?val};case(#err(err)){?0};}, 20 * 10 ** 8, ?dfx_token_spec, ?(lock_until - 1));

        //register escrow with no lock past mint date

        let a_wallet_try_registration_bad_lock = await a_wallet.try_sale_registration(Principal.fromActor(sale_canister), { principal = Principal.fromActor(a_wallet);max_desired = 1; escrow_receipt = switch(a_wallet_try_escrow_general_no_lock){case(#ok(val)){?val.receipt};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});

        //create a new payment with lock

        let aRedeem_payment_2 = await a_wallet.send_ledger_payment(dfx_ledger, (20 * 10 ** 8) + 400001, Principal.fromActor(canister));

        D.print("escrow general valid a" # debug_show(aRedeem_payment_2) );

        let a_wallet_try_escrow_general_valid = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(aRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, (20 * 10 ** 8) + 1, ?dfx_token_spec, ?lock_until);

        D.print("escrow general valid a" # debug_show(a_wallet_try_escrow_general_valid) );
        //register escrow with not enough payment for at least 1 NFT

        let a_wallet_try_registration_low_amount = await a_wallet.try_sale_registration(Principal.fromActor(sale_canister), {principal = Principal.fromActor(a_wallet);max_desired=1; escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
            ?{
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 9 * 10 ** 8; //one token short

            }};case(#err(err)){
                D.print("THROW ----------------- failed a register for low" # debug_show(a_wallet_try_escrow_general_valid) );
                throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});


        //register escrow for one NFT

        let a_wallet_try_redeem_for_one = await a_wallet.try_sale_registration(Principal.fromActor(sale_canister), { principal = Principal.fromActor(a_wallet);max_desired = 1; escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
           ?{
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 10 * 10 ** 8; //one icp for one

            }};case(#err(err)){
                D.print("THROW ----------------- failed a register for 1" # debug_show(a_wallet_try_escrow_general_valid) );
                throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});


        //check that registration is updated

        let a_wallet_registration_after_one = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(a_wallet));

        D.print("a_wallet_registration_after_one " # debug_show(a_wallet_registration_after_one) );

        //redeem escrow for the two more of the NFTs

        let a_wallet_try_register_for_two = await a_wallet.try_sale_registration(Principal.fromActor(sale_canister), { principal = Principal.fromActor(a_wallet);max_desired = 2; escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
            ?{
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 20 * 10 ** 8; //20 icp for two
            }};case(#err(err)){
                D.print("THROW ----------------- failed a register for 2" # debug_show(a_wallet_registration_after_one) );
                throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});

        let a_wallet_registration_after_two = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(a_wallet));

        
        //register b for 4 with additive
        let bRedeem_payment_2 = await b_wallet.send_ledger_payment(dfx_ledger, (40 * 10 ** 8) + 800000, Principal.fromActor(canister));

        let b_wallet_try_escrow_general_valid = await b_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(bRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, 40  * 10 ** 8, ?dfx_token_spec, ?lock_until);

        let b_wallet_try_register_for_four = await b_wallet.try_sale_registration(Principal.fromActor(sale_canister), { principal = Principal.fromActor(b_wallet);max_desired = 2; escrow_receipt = switch(b_wallet_try_escrow_general_valid){case(#ok(val)){
            ?{
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 40 * 10 ** 8; //20 icp for two
            }};case(#err(err)){
                D.print("THROW ----------------- failed b register for 2" # debug_show(b_wallet_try_escrow_general_valid) );
                throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});


        let b_wallet_registration_after_four = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(b_wallet));

        //regist d for 2 with non-additive

        let dRedeem_payment_2 = await d_wallet.send_ledger_payment(dfx_ledger, (40 * 10 ** 8) + 800000, Principal.fromActor(canister));

        let d_wallet_try_escrow_general_valid = await d_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(dRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, 40 * 10 ** 8, ?dfx_token_spec, ?lock_until);

        let d_wallet_try_register_for_four= await d_wallet.try_sale_registration(Principal.fromActor(sale_canister), {principal = Principal.fromActor(d_wallet); max_desired = 2; escrow_receipt = switch(d_wallet_try_escrow_general_valid){case(#ok(val)){
            ?{
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 40 * 10 ** 8; //40 icp for four but shold only get two
            }};case(#err(err)){
                D.print("THROW ----------------- failed d register for 4" # debug_show(b_wallet_try_escrow_general_valid) );
                
                throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});


        let d_wallet_registration_after_four = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(d_wallet));

        //register e for 2 with general
        let eRedeem_payment_2 = await e_wallet.send_ledger_payment(dfx_ledger, (20 * 10 ** 8) + 400000, Principal.fromActor(canister));

        let e_wallet_try_escrow_general_valid = await e_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(eRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, 20  * 10 ** 8, ?dfx_token_spec, ?lock_until);

        let e_wallet_try_register_for_two = await e_wallet.try_sale_registration(Principal.fromActor(sale_canister), { principal = Principal.fromActor(e_wallet);max_desired = 2; escrow_receipt = switch(e_wallet_try_escrow_general_valid){case(#ok(val)){
            ?{
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 20 * 10 ** 8; //40 icp for four but shold only get two
            }};case(#err(err)){
                D.print("THROW ----------------- failed e register for 2" # debug_show(e_wallet_try_escrow_general_valid) );
                throw(
                
                
                Error.reject("THROW ----------------- failed e register for 2"))}}});

        let e_wallet_registration_after_two = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(e_wallet));


        //total 10 registrations for 6 items


        //advance time

        let advancer = await sale_canister.__advance_time(allocation_date + 1);

        //assure allocation is made
            //ways to assure this
            //make a new registration?
            //make a new allocation?
            //reedeem an allocatoin?

       let c_allocate_empty = await c_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(c_wallet);
            number_to_allocate = 1;
            token = ?dfx_token_spec;
        });

        let a_wallet_registration_after_allocation = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(a_wallet));
        let b_wallet_registration_after_allocation = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(b_wallet));
        let d_wallet_registration_after_allocation = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(d_wallet));
        let e_wallet_registration_after_allocation = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(e_wallet));



        //claim
        switch(
            a_wallet_registration_after_allocation,
            b_wallet_registration_after_allocation,
            d_wallet_registration_after_allocation,
            e_wallet_registration_after_allocation){
                case(#ok(a),#ok(b),#ok(d),#ok(e)){
                    for(thisitem in a.allocation.vals()){
                        let claim_result = await sale_canister.execute_claim_sale_nft_origyn(thisitem.token_id);
                    };
                    for(thisitem in b.allocation.vals()){
                        let claim_result = await sale_canister.execute_claim_sale_nft_origyn(thisitem.token_id);
                    };
                    for(thisitem in d.allocation.vals()){
                        let claim_result = await sale_canister.execute_claim_sale_nft_origyn(thisitem.token_id);
                    };
                    for(thisitem in e.allocation.vals()){
                        let claim_result = await sale_canister.execute_claim_sale_nft_origyn(thisitem.token_id);
                    };
                };
                case(_,_,_,_) {
                    D.print("THROW ----------------- failed to get registrations" # debug_show(a_wallet_registration_after_allocation,b_wallet_registration_after_allocation,d_wallet_registration_after_allocation,e_wallet_registration_after_allocation) );
                
                    throw(Error.reject("THROW ----------------- couldnt get the registratons after allocation"));
                };          
        };

        //check nft balance

        let a_wallet_balance_after_three = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        let b_wallet_balance_after_three = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(b_wallet)));
        let d_wallet_balance_after_three = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(d_wallet)));
        let e_wallet_balance_after_three = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(e_wallet)));
    

        

        //todo: make sure we can't register after the sale_opened_date

        let cRedeem_payment_2 = await c_wallet.send_ledger_payment(dfx_ledger, (20 * 10 ** 8) + 400000, Principal.fromActor(canister));

        let c_wallet_try_escrow_general_valid = await c_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(cRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, 20 * 10 ** 8, ?dfx_token_spec, ?lock_until);






         let c_wallet_try_register_after_sale_date = await c_wallet.try_sale_registration(Principal.fromActor(sale_canister), { principal = Principal.fromActor(c_wallet);max_desired = 1; escrow_receipt = switch(c_wallet_try_escrow_general_valid){case(#ok(val)){
            ?{
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 10 * 10 ** 8; //20 icp for two
            }};case(#err(err)){
                D.print("THROW ----------------- failed sale registration c" # debug_show(c_wallet_try_escrow_general_valid) );
                throw(Error.reject("THROW ----------------- failed sale registration c"))}}});

        let c_wallet_registration_after_sale_date = await sale_canister.get_registration_sale_nft_origyn(Principal.fromActor(c_wallet));


        //try to allocate nfts --- should be out of inventory

        let c_allocate_empty_2 = await c_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(c_wallet);
            number_to_allocate = 1;
            token = ?dfx_token_spec;
        });



        //D.print("running suite test registrations");

        let suite = S.suite("test registration", [
            S.test("fail if registering before open", switch(f_wallet_try_registration_before_open){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5005){ //improper escrwo
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            S.test("fail if registering no escrow", switch(a_wallet_try_registration_no_escrow){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5003){ //improper escrwo
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            S.test("fail if no lock", switch(a_wallet_try_registration_bad_lock){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5002){ //improper escrwo
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
             S.test("fail if not enough tokens", switch(a_wallet_try_registration_low_amount){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5003){ //improper escrwo
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
           S.test("can register one item", switch(a_wallet_try_redeem_for_one){case(#ok(res)){
                if(res.max_desired == 1){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("can get reg afterone item", switch(a_wallet_registration_after_one){case(#ok(res)){
                if(res.max_desired == 1){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))),
             S.test("can register two item replace", switch(a_wallet_try_register_for_two){case(#ok(res)){
                if(res.max_desired == 2){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("can get reg after two item", switch(a_wallet_registration_after_two){case(#ok(res)){
                if(res.max_desired == 1){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("can register four item additive", switch(b_wallet_try_register_for_four){case(#ok(res)){
                if(res.max_desired == 4){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("can get reg after four item b", switch(b_wallet_registration_after_four){case(#ok(res)){
                if(res.max_desired == 4){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 

            S.test("can register d four item non additive", switch(d_wallet_try_register_for_four){case(#ok(res)){
                if(res.max_desired == 2){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("can get reg after four item d", switch(d_wallet_registration_after_four){case(#ok(res)){
                if(res.max_desired == 4){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 

            S.test("can register e two item non-additive", switch(e_wallet_try_register_for_two){case(#ok(res)){
                if(res.max_desired == 2){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("can get reg after four item e", switch(e_wallet_registration_after_two){case(#ok(res)){
                if(res.max_desired == 2){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 

            S.test("only 6 items allocated", switch(
                a_wallet_registration_after_allocation,
                b_wallet_registration_after_allocation,
                d_wallet_registration_after_allocation,
                e_wallet_registration_after_allocation){
                    case(#ok(a),#ok(b),#ok(d),#ok(e)){
                        if(a.allocation.size() + b.allocation.size() + d.allocation.size() + e.allocation.size() == 6){
                            "expected success"
                        } else {
                            "unexpected success" # debug_show((a,b,d,e))
                        }};
                    case(_,_,_,_) {
                        "wrong error " # debug_show((a_wallet_registration_after_allocation, b_wallet_registration_after_allocation, d_wallet_registration_after_allocation, e_wallet_registration_after_allocation));
                    };          
            }, M.equals<Text>(T.text("expected success"))), 

            S.test("only 6 items allocated in balance", switch(
                a_wallet_balance_after_three,
                b_wallet_balance_after_three,
                d_wallet_balance_after_three,
                e_wallet_balance_after_three){
                    case(#ok(a),#ok(b),#ok(d),#ok(e)){
                        if(a.nfts.size() + b.nfts.size() + d.nfts.size() + e.nfts.size() == 6){
                            "expected success"
                        } else {
                            "unexpected success" # debug_show((a,b,d,e))
                        }};
                    case(_,_,_,_) {
                        "wrong error " # debug_show((a_wallet_balance_after_three, b_wallet_balance_after_three, d_wallet_balance_after_three, e_wallet_balance_after_three));
                    };          
            }, M.equals<Text>(T.text("expected success"))), 
            S.test("cannot register after sale ends", switch(c_wallet_try_register_after_sale_date){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5005){ //improper escrwo
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
             S.test("allocation doesnt work inventory cleared during allocation", switch(c_allocate_empty){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5004){ //improper escrwo
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            S.test("allocation doesnt work inventory cleared during allocation", switch(c_allocate_empty_2){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5004){ //improper escrow
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            
        ]);

        S.run(suite);

        return #success;
    };

    public shared func testRedeemAllocation() : async {#success; #fail : Text} {
        D.print("running testRedeemAllocation");

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        let c_wallet = await TestWalletDef.test_wallet();

        //D.print("have wallets");

        //fund wallets

        let dfx : DFXTypes.Service = actor(Principal.toText(dfx_ledger));
        let funding_result = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(a_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  1000 * 10 ** 8;});

        //D.print("funding a" # debug_show(funding_result));

        let funding_result_2 = await dfx.icrc1_transfer({
            to =  {owner = Principal.fromActor(b_wallet); subaccount = null};
            fee = ?200_000;
            memo = ?[0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,1];
            from_subaccount = null;
            created_at_time = null;
            amount =  1000 * 10 ** 8;});

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        

        //D.print("have canister" # debug_show(Principal.fromActor(canister)));

        //D.print("calling stage");

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage4 = await utils.buildStandardNFT("4", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage5 = await utils.buildStandardNFT("5", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage6 = await utils.buildStandardNFT("6", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage7 = await utils.buildStandardNFT("7", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage8 = await utils.buildStandardNFT("8", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));


        let allocation_date = Time.now() + 900000000000;
        let lock_until = allocation_date + 900000000000;
        //create sales canister
        let sale_canister = await Sales.SaleCanister({
            owner = Principal.fromActor(this);
            allocation_expiration = 900000000000;
            nft_gateway = ?Principal.fromActor(canister);
            sale_open_date = ?(allocation_date);  // in 15 minutes 
            registration_date = null;
            end_date = null;
            required_lock_date = ?(lock_until); //15 minutes past allocation date
            
        });

        //D.print("sales canister is " # debug_show(Principal.fromActor(sale_canister), Principal.fromActor(canister)));
        let current_manager = switch(await canister.collection_nft_origyn(null)){
            case(#err(err)){[]};
            case(#ok(val)){
                switch(val.managers){
                    case(null){[]};
                    case(?val){val};
                };
            };
        };
        //D.print("current manager add" # debug_show(current_manager, Principal.fromActor(canister)));
        let manager_add = await canister.collection_update_nft_origyn(#UpdateManagers([Principal.fromActor(sale_canister)]));
        //D.print("manager add" # debug_show(manager_add));
       

        D.print("adding add_unminted_1");

        let add_unminted_1 = await sale_canister.manage_nfts_sale_nft_origyn([
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "1";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "2";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "3";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "4";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "5";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "6";
                }),
            ]
        );

        D.print(debug_show(add_unminted_1));

        //create a defalut group with an allocation of 2

        let defaultGroup = await sale_canister.manage_group_sale_nft_origyn([#update({
            namespace = ""; //default namespace
            members = null;
            pricing = ?[#cost_per{
                amount = 1000000000;
                token = #ic({
                    canister = dfx_ledger;
                    fee = 200000 : Nat;
                    symbol = "OGY";
                    decimals = 8 : Nat;
                    standard = #Ledger;
                });
            }];
            allowed_amount = ?5;
            tier = 0;
            additive = true;
        }
        )]);


        D.print("making reservation");

        //creat a default reservation
        let reserve = await sale_canister.manage_reservation_sale_nft_origyn([
            #add({
                namespace = "default";
                reservation_type = #Groups([""]);
                exclusive = false;
                nfts = ["1","2","3","4","5","6"];
            })
        ]);


        D.print("allocating 1");

        //allocate 5 nfts 
        let allocate_1 = await a_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(a_wallet);
            number_to_allocate = 5;
            token = ?dfx_token_spec;
        });

        D.print("allocating 1" # debug_show(allocate_1));

        //check allocation balances

        let balance_check_1 = await sale_canister.get_allocation_sale_nft_origyn(Principal.fromActor(a_wallet));

         D.print("balance_check_1 1" # debug_show(balance_check_1));

        //have b try to redeem the allocation should fail

        let bRedeem_payment = await b_wallet.send_ledger_payment(dfx_ledger, (10 * 10 ** 8) + 200000, Principal.fromActor(canister));

        let b_wallet_try_escrow_general = await b_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(bRedeem_payment){case(#ok(val)){?val};case(#err(err)){?0};}, 10 * 10 ** 8, ?dfx_token_spec, ?lock_until);

        let b_wallet_allocation_attempt = await b_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(b_wallet_try_escrow_general){case(#ok(val)){val.receipt};case(#err(err)){throw(Error.reject("THROW ----------------- failed to get escrow for b payment in testRedeem"))}}});

        //have a redeem thier allocation
        D.print("fake escrow");

        //redeem with fake escrow
         let a_wallet_try_redeem_no_escrow = await a_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt =  {
                buyer = #principal(Principal.fromActor(a_wallet));
                seller = #principal(Principal.fromActor(canister));
                token = dfx_token_spec;
                token_id = "";
                amount = 10 * 10 ** 8; //one icp for one token
            }});

            D.print("a_wallet_try_redeem_no_escrow 1" # debug_show(a_wallet_try_redeem_no_escrow));


        
        //create a new payment with lock

        let aRedeem_payment_2 = await a_wallet.send_ledger_payment(dfx_ledger, (30  * 10 ** 8) + 600000, Principal.fromActor(canister));

        D.print("attempted payment " # debug_show(aRedeem_payment_2));

        let a_wallet_try_escrow_general_valid = await a_wallet.try_escrow_general_staged(Principal.fromActor(canister), Principal.fromActor(canister), dfx_ledger, switch(aRedeem_payment_2){case(#ok(val)){?val};case(#err(err)){?0};}, 30 * 10 ** 8, ?dfx_token_spec, null);

        //redeem escrow with not enough payment for at least 1 NFT

        let a_wallet_try_redeem_low_amount = await a_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
            {
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 9 * 10 ** 8; //one token short

            }};case(#err(err)){
                D.print("THROW ----------------- failed to get escrow for a payment in testRedeem for a_wallet_try_redeem_low_amount" # debug_show(err));
                throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for a_wallet_try_redeem_low_amount"))}}});

         D.print("a_wallet_try_redeem_low_amount 1" # debug_show(a_wallet_try_redeem_low_amount));


        //redeem escrow for one NFT

        let a_wallet_try_redeem_for_one = await a_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
            {
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 10 * 10 ** 8; //one icp for one

            }};case(#err(err)){D.print("THROW ----------------- failed to get escrow for a payment in testRedeem for a_wallet_try_redeem_for_one");
            
            throw(
                
                Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for a_wallet_try_redeem_for_one"))}}});

        D.print("a good redeem" # debug_show(a_wallet_try_redeem_for_one));
        //check that allocation is updated

        let a_wallet_allocation_after_one = await sale_canister.get_allocation_sale_nft_origyn(Principal.fromActor(a_wallet));


        D.print("a_wallet_allocation_after_one" # debug_show(a_wallet_allocation_after_one));

        let a_wallet_balance_after_one = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

        D.print("a_wallet_balance_after_one" # debug_show(a_wallet_balance_after_one));

        //redeem escrow for the two more of the NFTs

        let a_wallet_try_redeem_for_two = await a_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
            {
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 20 * 10 ** 8; //20 icp for two

            }};case(#err(err)){
                D.print("THROW ----------------- failed to get escrow for a payment in testRedeem for a_wallet_try_redeem_for_two");
                throw(
                
                
                Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for a_wallet_try_redeem_for_two"))}}});

                D.print("a_wallet_try_redeem_for_two 1" # debug_show(a_wallet_try_redeem_for_two));

        D.print("a_wallet_try_redeem_for_two" # debug_show(a_wallet_try_redeem_for_two));

        let a_wallet_allocation_after_three = await sale_canister.get_allocation_sale_nft_origyn(Principal.fromActor(a_wallet));

        D.print("a_wallet_allocation_after_three" # debug_show(a_wallet_allocation_after_three));


        let a_wallet_balance_after_three = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));
        //redeem escrow with enough for 10 NFT...make sure only the last two ae allocated

        D.print("a_wallet_balance_after_three" # debug_show(a_wallet_balance_after_three));


         let a_wallet_try_redeem_for_ten = await a_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
            {
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 100 * 10 ** 8; //10 icp for ten

            }};case(#err(err)){
                D.print("THROW ----------------- failed to get escrow for a payment in testRedeem for a_wallet_try_redeem_for_ten");
                throw(
                
                Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for a_wallet_try_redeem_for_ten"))}}});

        //check that allocation is deleted

        D.print("a_wallet_try_redeem_for_ten" # debug_show(a_wallet_try_redeem_for_ten));


        let a_wallet_allocation_after_ten = await sale_canister.get_allocation_sale_nft_origyn(Principal.fromActor(a_wallet));


        D.print("a_wallet_allocation_after_ten" # debug_show(a_wallet_allocation_after_ten));


        let a_wallet_balance_after_ten = await canister.balance_of_nft_origyn(#principal(Principal.fromActor(a_wallet)));

        D.print("a_wallet_balance_after_ten" # debug_show(a_wallet_balance_after_ten));

        //advance time

        let advancer = await sale_canister.__advance_time(allocation_date + 1);

        //check allocation balance

        let a_wallet_allocation_after_expiration = await sale_canister.get_allocation_sale_nft_origyn(Principal.fromActor(a_wallet));

        D.print("a_wallet_allocation_after_expiration" # debug_show(a_wallet_allocation_after_expiration));


        //allocate an nft

        let allocate_2 = await a_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(a_wallet);
            number_to_allocate = 1;
            token = ?dfx_token_spec;
        });

        D.print("allocate_2" # debug_show(allocate_2));


        //advance time passed escrow

        let advancer2 = await sale_canister.__advance_time(allocation_date + 1 + 900000000000 + 1);


        //try to redeem escrow for expired allocation

        let a_wallet_try_redeem_for_expired = await a_wallet.try_sale_nft_redeem(Principal.fromActor(sale_canister), { escrow_receipt = switch(a_wallet_try_escrow_general_valid){case(#ok(val)){
            {
                buyer = val.receipt.buyer;
                seller = val.receipt.seller;
                token = dfx_token_spec;
                token_id = "";
                amount = 10 * 10 ** 8; 

            }};case(#err(err)){
                //D.print("THROW ----------------- failed to get escrow for a payment in testRedeem for a_wallet_try_redeem_for_expired");
                throw(Error.reject("THROW ----------------- failed to get escrow for a payment in testRedeem for bad lock"))}}});






        //D.print("running suite test redeem");

        D.print("a_wallet_try_redeem_for_expired" # debug_show(a_wallet_try_redeem_for_expired));



        let suite = S.suite("test allocations", [

            S.test("fail if redeeming with no allocation", switch(b_wallet_allocation_attempt){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5001){ //allocation does not exist
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            S.test("fail if redeeming with a non existant escrow", switch(a_wallet_try_redeem_no_escrow){case(#ok(res)){
                //D.print("unexpected success"# debug_show(res));
                    if(res.nfts.size() == 1){
                        switch(res.nfts[0].transaction){
                            case(#ok(trxres)){
                                "unexpected success " # debug_show(res);
                            };
                            case(#err(err)){
                                if(err.number == 64){ //bad transaction error
                                    "correct error";
                                } else {
                                    "unexpected error"  # debug_show((err, res));
                                };
                            };

                        }
                    } else {
                        "unexpected size " # debug_show(res);
                    };
                };
                
                case(#err(err)){
                //D.print("unexpected err"# debug_show(err));
                if(err.number == 5001){ //escrow does not exist
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct error"))),
            
            S.test("fail if the payment was too low", switch(a_wallet_try_redeem_low_amount){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5003){ //improper low payment
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),

           S.test("can allocate  one item", switch(a_wallet_try_redeem_for_one){case(#ok(res)){
                if(res.nfts.size() == 1){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
             S.test("can allocate one item", switch(a_wallet_balance_after_one){case(#ok(res)){
                if(res.nfts.size() == 1){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
             S.test("allocation balance after one items", switch(a_wallet_allocation_after_one){case(#ok(res)){
                if(res.allocation_size == 4){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
           
            S.test("can allocate additive two items", switch(a_wallet_allocation_after_three){case(#ok(res)){
                if(res.allocation_size == 2){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("can allocate additive two items", switch(a_wallet_try_redeem_for_two){case(#ok(res)){
                if(res.nfts.size() == 2){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("has 3", switch(a_wallet_balance_after_three){case(#ok(res)){
                if(res.nfts.size() == 3){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("cannot over allocate  ten items", switch(a_wallet_try_redeem_for_ten){case(#ok(res)){
                if(res.nfts.size() == 2){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("has 3", switch(a_wallet_balance_after_ten){case(#ok(res)){
                if(res.nfts.size() == 3){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
    
            
        ]);

        S.run(suite);

        return #success;
    };

    public shared func testAllocation() : async {#success; #fail : Text} {
        //D.print("running testMarketTransfer");

        D.print("in test allocations");

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();
        let c_wallet = await TestWalletDef.test_wallet();
        let d_wallet = await TestWalletDef.test_wallet();

        //D.print("have wallets");

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        //D.print("have canister");

        //D.print("calling stage");

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage4 = await utils.buildStandardNFT("4", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage5 = await utils.buildStandardNFT("5", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage6 = await utils.buildStandardNFT("6", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage7 = await utils.buildStandardNFT("7", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage8 = await utils.buildStandardNFT("8", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));

        //create sales canister
        let sale_canister = await Sales.SaleCanister({
            owner = Principal.fromActor(this);
            allocation_expiration = 900000000000;
            nft_gateway = ?Principal.fromActor(canister);
            sale_open_date = null;
            registration_date = null;
            end_date = null;
            required_lock_date = null;
            
        });

        let set_time = await sale_canister.__set_time_mode(#test);
        let set_time2 = await sale_canister.__advance_time(Time.now());
       

        //D.print("adding auth");

        //add items as authorized
        //NFT-229
        let add_unminted_1 = await sale_canister.manage_nfts_sale_nft_origyn([
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "1";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "2";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "3";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "4";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "5";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "6";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "7";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "8";
                }),
            ]
        );

        //create a defalut group with an allocation of 2

        let defaultGroup = await sale_canister.manage_group_sale_nft_origyn([#update({
            namespace = ""; //default namespace
            members = null;
            pricing = ?[#cost_per{
                amount = 1000000000;
                token = #ic({
                    canister = dfx_ledger;
                    fee = 200000 : Nat;
                    symbol = "OGY";
                    decimals = 8 : Nat;
                    standard = #Ledger;
                });
            }];
            allowed_amount = ?2;
            tier = 0;
            additive = true;
        }
        )]);



        //create a specific group with allocation of 2 for b wallet
        let bGroup =  await sale_canister.manage_group_sale_nft_origyn([#update({
                namespace = "bgroup"; //default namespace
                members = ?[Principal.fromActor(b_wallet)];
                pricing = ?[#cost_per{
                    amount = 1000000000;
                    token = #ic({
                        canister = dfx_ledger;
                        fee = 200000;
                        symbol = "OGY";
                        decimals = 8;
                        standard = #Ledger;
                    })
                }];
                allowed_amount = ?2;
                additive = true;
                tier = 1;
            }
        )]);

        //create a specific group with allocation of 2 for b wallet
        let cGroup =  await sale_canister.manage_group_sale_nft_origyn([#update({
                namespace = "cgroup"; //default namespace
                members = ?[Principal.fromActor(c_wallet)];
                pricing = ? [#cost_per{
                    amount = 1000000000;
                    token = #ic({
                        canister = dfx_ledger;
                        fee = 200000;
                        symbol = "OGY";
                        decimals = 8;
                        standard = #Ledger;
                    })
                }];
                allowed_amount = ?2;
                additive = false;
                tier = 2
            }
        )]);

        //creat a default reservation
        let reserve = await sale_canister.manage_reservation_sale_nft_origyn([
            #add({
                namespace = "default";
                reservation_type = #Groups([""]);
                exclusive = false;
                nfts = ["1","2","3","4","5","6","7","8"];
            })
        ]);



        //set allocation expiration to 15 minutes

        //D.print("allocating details");


        //allocate 0 nfts should fail
        let allocate_0 = await a_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(a_wallet);
            number_to_allocate = 0;
            token = ?dfx_token_spec;
        });

        //D.print(debug_show(allocate_0));

        //allocate 4 nfts should get 2
        let allocate_1 = await a_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(a_wallet);
            number_to_allocate = 4;
            token = ?dfx_token_spec;
        });

        D.print("allocate 1 " #debug_show(allocate_1));

        //try to allocate 6 nfts, should allocate 4 (defalut + special group)
        let allocate_2 = await b_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(b_wallet);
            number_to_allocate = 6;
            token = ?dfx_token_spec;
        });

        D.print("allocate 2 " #debug_show(allocate_2));

        //try to allocate 6 more, should allocate 2 since c group is not additive
        let allocate_3 = await c_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(c_wallet);
            number_to_allocate = 6;
            token = ?dfx_token_spec;
        });

        //D.print("allocate 3 " #debug_show(allocate_3));


        //try allocate 10 more, should fail
        let allocate_4 = await c_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(a_wallet);
            number_to_allocate = 10;
            token = ?dfx_token_spec;
        });

        //D.print("allocate 4 " #debug_show(allocate_4));

         //try allocate some for d but all have been allocated
        let allocate_5 = await d_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(d_wallet);
            number_to_allocate = 10;
            token = ?dfx_token_spec;
        });
        //D.print("allocate 5 " #debug_show(allocate_5));

        //check allocation balances
        //D.print("checking balances details");

        let balance_check_1 = await sale_canister.get_allocation_sale_nft_origyn(Principal.fromActor(a_wallet));
        let balance_check_2 = await sale_canister.get_allocation_sale_nft_origyn(Principal.fromActor(b_wallet));
        let balance_check_3 = await sale_canister.get_allocation_sale_nft_origyn(Principal.fromActor(c_wallet));



        //items are returned to the pool after expiration
        let expiration = switch(allocate_1){
            case(#ok(val)){
                val.expiration
            };
            case(#err(err)){
                //D.print("THROW ----------------- we cant simulate time because the allocation didnt work in test_allocation " # debug_show(err));
                throw(Error.reject("THROW ----------------- we cant simulate time because the allocation didnt work in test_allocation " # debug_show(err)));
            }
        };
        //D.print("advancing time " # debug_show(Time.now(), expiration));

        let advancer = await sale_canister.__advance_time(expiration + 1);


        let expired_check_1 = await sale_canister.get_allocation_sale_nft_origyn(Principal.fromActor(a_wallet));
        let expired_check_2 = await sale_canister.get_allocation_sale_nft_origyn(Principal.fromActor(b_wallet));
        let expired_check_3 = await sale_canister.get_allocation_sale_nft_origyn(Principal.fromActor(c_wallet));

        //can allocate again

        //allocate 4 nfts should get 2
        let allocate__retry_1 = await a_wallet.try_sale_nft_allocation(Principal.fromActor(sale_canister),{
            principal = Principal.fromActor(a_wallet);
            number_to_allocate = 1;
            token = ?dfx_token_spec;
        });

        //D.print("running suite test allocations");

        let suite = S.suite("test allocations", [

            S.test("allocate 0 items should fail", switch(allocate_0){case(#ok(res)){
                
                    "unexpected success" # debug_show(res)
                };case(#err(err)){
                    if(err.number == 5000){ //improper allocation
                        "correct error";
                    } else {
                        "wrong error " # debug_show(err);
                    }
                    
            };}, M.equals<Text>(T.text("correct error"))), //NFT-235, NFT-237
             S.test("can allocate default items", switch(allocate_1){case(#ok(res)){
                if(res.allocation_size == 2){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), //NFT-235
            S.test("can allocate additive items", switch(allocate_2){case(#ok(res)){
                if(res.allocation_size == 4){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), //NFT-235
            S.test("can allocate non additive items", switch(allocate_3){case(#ok(res)){
                if(res.allocation_size == 2){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), //NFT-236

           S.test("fail if no nfts available to allocate", switch(allocate_5){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5004){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //NFT-239

            S.test("a has 2", switch(balance_check_1){case(#ok(res)){
                if(res.allocation_size == 2){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("b has 4", switch(balance_check_2){case(#ok(res)){
                if(res.allocation_size == 4){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("c has 2", switch(balance_check_3){case(#ok(res)){
                if(res.allocation_size == 2){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), 


            S.test("a has expired", switch(expired_check_1){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5001){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), 


            S.test("b has expired", switch(expired_check_2){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5001){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), 

            S.test("c has expired", switch(expired_check_3){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 5001){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), 
           S.test("can do a new allocation after expiration", switch(allocate__retry_1){case(#ok(res)){
                if(res.allocation_size == 1){
                   
                    "expected success"
                       
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), //NFT-236
            
            
        ]);

        S.run(suite);

        return #success;
    };

    public shared func testManagement() : async {#success; #fail : Text} {
      D.print("running testManagement");



        //create sales canister
        let sale_canister = await Sales.SaleCanister({
            owner = Principal.fromActor(this);
            allocation_expiration = 900000000000;
            nft_gateway = null;
            sale_open_date = null;
            registration_date = null;
            end_date = null;
            required_lock_date = null;
        });

        //D.print("have canister");


        let set_canister_gateway = await sale_canister.manage_sale_nft_origyn(#UpdateNFTGateway(?Principal.fromActor(this)));

        D.print("have set_canister_gateway");

        let set_canister_expiration = await sale_canister.manage_sale_nft_origyn(#UpdateAllocationExpiration(555));

        //D.print("have set_canister_expiration");

        

        let a_now = Time.now();

        let set_canister_sale_open_date = await sale_canister.manage_sale_nft_origyn(#UpdateSaleOpenDate(?(a_now + 1)));
        
        //D.print("have set_canister_sale_open_date");

        let set_canister_registration_date = await sale_canister.manage_sale_nft_origyn(#UpdateRegistrationDate(?(a_now + 2)));
        
        //D.print("have set_canister_registration_date");

        let set_canister_end_date = await sale_canister.manage_sale_nft_origyn(#UpdateEndDate(?(a_now + 3)));

        //D.print("getting metrics");
        let canister_metrics = await sale_canister.get_metrics_sale_nft_origyn();

        //D.print("have metrics");
        let set_canister_sale_open_date_low = await sale_canister.manage_sale_nft_origyn(#UpdateSaleOpenDate(?(1)));
        let set_canister_registration_date_low = await sale_canister.manage_sale_nft_origyn(#UpdateRegistrationDate(?(2)));
        let set_canister_end_date_low = await sale_canister.manage_sale_nft_origyn(#UpdateEndDate(?(3)));

        let set_canister_sale_open_date_high = await sale_canister.manage_sale_nft_origyn(#UpdateSaleOpenDate(?(10000000000000000000000000000000000)));
        let set_canister_registration_date_high = await sale_canister.manage_sale_nft_origyn(#UpdateRegistrationDate(?(210000000000000000000000000000000000)));
        let set_canister_end_date_high = await sale_canister.manage_sale_nft_origyn(#UpdateEndDate(?(310000000000000000000000000000000000)));

        let set_canister_owner = await sale_canister.manage_sale_nft_origyn(#UpdateOwner(dfx_ledger));

         //D.print("getting metrics");
        let owner_change_metrics = await sale_canister.get_metrics_sale_nft_origyn();

        //D.print("have set_canister_owner");

        //D.print("running suite test management");

        let suite = S.suite("test managment", [

            S.test("can change gateway", switch(canister_metrics){case(#ok(res)){
                    if(Option.isSome(res.nft_gateway) == true){
                            "expected success";
                    } else {
                        "unexpected success" # debug_show(res)
                    }
                };case(#err(err)){
  
                        "wrong error " # debug_show(err);
            
                    
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("can change expiration", switch(canister_metrics){case(#ok(res)){
                    if(res.allocation_expiration == 555){
                            "expected success";
                    } else {
                        "unexpected success" # debug_show(res)
                    }
                };case(#err(err)){
 
                        "wrong error " # debug_show(err);
                
                    
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("can change owner",  switch(owner_change_metrics){case(#ok(res)){
                    if(res.owner == dfx_ledger){
                        "expected success"
                    } else {
                        "unexpected success" # debug_show(res)
                    }
              
                };case(#err(err)){

                        "wrong error " # debug_show(err);
               
                    
            };}, M.equals<Text>(T.text("expected success"))), 
            S.test("can change mintdate",  switch(canister_metrics){case(#ok(res)){
                    switch(res.sale_open_date){
                        case(null){"unexpected success" # debug_show(res)};
                        case(?val){
                            if(val == a_now + 1){
                                "expected success";
                            } else {
                                "unexpected success" # debug_show(res)
                            }
                        };
                    };
                
                    
                };case(#err(err)){

                        "wrong error " # debug_show(err);
                 
                    
            };}, M.equals<Text>(T.text("expected success"))),
            S.test("can change reservation date",  switch(canister_metrics){case(#ok(res)){
                    switch(res.registration_date){
                        case(null){"unexpected success" # debug_show(res)};
                        case(?val){
                            if(val == a_now + 2){
                                "expected success";
                            } else {
                                "unexpected success" # debug_show(res)
                            }
                        };
                    };
                
                    
                };case(#err(err)){

                        "wrong error " # debug_show(err);
                 
                    
            };}, M.equals<Text>(T.text("expected success"))),
            S.test("can change end date",  switch(canister_metrics){case(#ok(res)){
                    switch(res.end_date){
                        case(null){"unexpected success" # debug_show(res)};
                        case(?val){
                            if(val == a_now + 3){
                                "expected success";
                            } else {
                                "unexpected success" # debug_show(res)
                            }
                        };
                    };
                };case(#err(err)){

                        "wrong error " # debug_show(err);
                 
                    
            };}, M.equals<Text>(T.text("expected success"))),
            S.test("fail if canister date set low", switch(set_canister_sale_open_date_low){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 16){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            S.test("fail if canister registration set low", switch(set_canister_registration_date_low){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 16){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            S.test("fail if canister end date set low", switch(set_canister_end_date_low){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 16){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            S.test("fail if canister sale date set high", switch(set_canister_sale_open_date_high){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 16){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            S.test("fail if registration date set high", switch(set_canister_registration_date_high){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 16){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))),
            S.test("fail if end date set high", switch(set_canister_end_date_high){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 16){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number")))
             
            
        ]);

        S.run(suite);

        return #success;
    };
    
    public shared func testLoadNFTS() : async {#success; #fail : Text} {
        

        D.print("in test loads nft");

        let a_wallet = await TestWalletDef.test_wallet();
        let b_wallet = await TestWalletDef.test_wallet();

        //D.print("have wallets");

        let newPrincipal = await g_canister_factory.create({
            owner = Principal.fromActor(this);
            storage_space = null;
        });

        let canister : Types.Service =  actor(Principal.toText(newPrincipal));

        //D.print("have canister");

        D.print("calling stage");

        let standardStage = await utils.buildStandardNFT("1", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage2 = await utils.buildStandardNFT("2", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage3 = await utils.buildStandardNFT("3", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));
        let standardStage4 = await utils.buildStandardNFT("4", canister, Principal.fromActor(canister), 1024, false, Principal.fromActor(this));

        //mint 2
        let mint_attempt = await canister.mint_nft_origyn("1", #principal(Principal.fromActor(this)));
        let mint_attempt2 = await canister.mint_nft_origyn("2", #principal(Principal.fromActor(this)));
        

        D.print("minted");
        //create sales canister
        let sale_canister = await Sales.SaleCanister({
            owner = Principal.fromActor(this);
            allocation_expiration = 900000000000;
            nft_gateway = ?Principal.fromActor(canister);
            sale_open_date = null;
            registration_date = null;
            end_date = null;
            required_lock_date = null;

        });

        //add items as an unauthorized user NFT-231
        //D.print("attempting uauth add");

        let add_minted_unauth = await a_wallet.try_sale_manage_nft(Principal.fromActor(sale_canister),[
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "1";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "2";
                }),
            ]
        );

        D.print("adding auth");

        //add items as authorized
        //NFT-229
        let add_minted_1 = await sale_canister.manage_nfts_sale_nft_origyn([
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "1";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "2";
                }),
            ]
        );


        //NFT-230
        let add_unminted_1 = await sale_canister.manage_nfts_sale_nft_origyn([
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "3";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "4";
                }),
            ]
        );

        D.print("adding second");

        // try adding a second time
        //nft-233
        let add_unminted_1_second_time = await sale_canister.manage_nfts_sale_nft_origyn([
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "3";
                }),
                #add({
                    canister = Principal.fromActor(canister);
                    token_id = "4";
                }),
            ]
        );

        //D.print("getting details");
        
        //test inventory
        let final_inventory = await sale_canister.get_inventory_sale_nft_origyn(null,null);

        //can get specific item
        let specific_inventory = await sale_canister.get_inventory_item_sale_nft_origyn("1");

        //D.print("running suite load nfts");

        let suite = S.suite("test loading nfts", [

            S.test("fail if non owner adds nfts", switch(add_minted_unauth){case(#ok(res)){"unexpected success" # debug_show(res)};case(#err(err)){
                if(err.number == 2000){ //
                    "correct number"
                } else{
                    "wrong error " # debug_show(err);
                }};}, M.equals<Text>(T.text("correct number"))), //NFT-231
            S.test("can add minted items", switch(add_minted_1){case(#ok(res)){
                if(res.total_size == 2 and res.items.size()==2){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
                };}, M.equals<Text>(T.text("expected success"))), //NFT-229
            S.test("can add unminted items", switch(add_unminted_1){case(#ok(res)){
                if(res.total_size == 4 and res.items.size()==2){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
                };}, M.equals<Text>(T.text("expected success"))), //NFT-230
           S.test("cant readd items", switch(add_unminted_1_second_time){case(#ok(res)){
                if(res.total_size == 4 and res.items.size()==2){
                    switch(res.items[0]){
                        case(#err(err)){
                            "expected success"
                        };
                        case(_){
                            "unexpected success" # debug_show(res)
                        };
                    }
                    
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
            };}, M.equals<Text>(T.text("expected success"))), //NFT-233
            S.test("can get inventory", switch(final_inventory){case(#ok(res)){
                if(res.total_size == 4 and res.items.size()==4){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
                };}, M.equals<Text>(T.text("expected success"))), 
            S.test("can get inventory item", switch(specific_inventory){case(#ok(res)){
                if(res.token_id == "1"){
                    "expected success"
                } else {
                    "unexpected success" # debug_show(res)
                }};case(#err(err)){
                    "wrong error " # debug_show(err);
                };}, M.equals<Text>(T.text("expected success"))), 
        ]);

        S.run(suite);

        return #success;
    };

}