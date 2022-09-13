# NFT Sale Canister

🚀 Feature-rich NFT sales canister that empowers NFT creators and consumers. This particular smart contract enables NFT authors to take control and manage its digital assets in a very innovative way.

#### Creator features :

- Sell NFTs for different amounts and to different sets of people

- Create different groups and collections

- Allow free mint for certain groups

- Create a team group

- Auto mint

- Raffle NFTs

- Ranking groups

#### User features :

- Claim NFT with membership rights

- Use Plug id to reserve number of items in a collection

- Submit ICP to get whitelisted and be reimbursed if I don’t get an allocation

- Register and review my escrow

- See the groups I’m registered for the drop

---

#### Data workflow

- Manage NFTs - calls ==> Add Inventory Item ( Adds NFTs to inventory )
- Manage groups ( Allows the creator to create and manage groups. These groups can be allocated a certain number of NFTs )
- Manage Reservation ( Allows a creator to associate a set of nfts with a particular group or address )
- Get Groups ( Retrieves a list of groups for a particular user or address )

**To deploy ONLY the origyn_sale_reference run the following from the root directory :**

```
 yes yes | bash nft_sales_runner.sh
```

**Candid Interface (make sure you change the ids respectively)**

```
http://localhost:8000/?canisterId=ryjl3-tyaaa-aaaaa-aaaba-cai&id=rrkah-fqaaa-aaaaa-aaaaq-cai
```

**Canister init arguments**

```
public type InitArgs = {
        owner: Principal;                    //owner of the canister
        allocation_expiration: Int;          //amount of time to keep an allocation for 900000000000 = 15 minutes
        nft_gateway: ?Principal;             //the nft gateway canister this sales canister will sell NFTs for
        sale_open_date : ?Int;              //date that the NFTs in the registration shold be minted/allocated
        registration_date: ?Int;              //date that registations open up
        end_date: ?Int;                      //date that the canister closes its sale
        required_lock_date: ?Int             //date that users must lock their tokens until to qualify for reservations
};

```

**Call get_groups**

```
 dfx canister call origyn_sale_reference get_groups
```

**Call redeem_allocation**

```
 dfx canister call origyn_sale_reference redeem_allocation '(record {escrow_receipt=record {token=variant {ic=record {fee=200000; decimals=8; canister=principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; standard=variant {DIP20}; symbol="DIP20"}}; token_id="OG1"; seller=variant {"principal" = principal "u74sm-wx4yh-capur-xnz4w-orbcn-l3jlc-m65rb-ue5ah-mqyvz-fmvvc-tae"}; buyer=variant {"principal" = principal "3j2qa-oveg3-2agc5-735se-zsxjj-4n65k-qmnse-byzkf-4xhw5-mzjxe-pae"}; amount=100000000}})'
```

**Call register_escrow**

```
 dfx canister call origyn_sale_reference redeem_allocation '(record {escrow_receipt=record {token=variant {ic=record {fee=200000; decimals=8; canister=principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; standard=variant {DIP20}; symbol="DIP20"}}; token_id="OG1"; seller=variant {"principal" = principal "u74sm-wx4yh-capur-xnz4w-orbcn-l3jlc-m65rb-ue5ah-mqyvz-fmvvc-tae"}; buyer=variant {"principal" = principal "3j2qa-oveg3-2agc5-735se-zsxjj-4n65k-qmnse-byzkf-4xhw5-mzjxe-pae"}; amount=100000000}})'
```

**Call add_inventory_item**

```
dfx canister call origyn_sale_reference add_inventory_item '(record { key = "first"; item = record { canister = principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; token_id = "1"; available = true; sale = opt 100; } })'
```

**Call manage_nfts (add)**

```

 dfx canister call origyn_sale_reference manage_nfts '( vec { variant { add = record { canister = principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; token_id = "1"; available = true; sale_block = opt 100; } } ; variant { add = record { canister = principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; token_id = "2"; available = true; sale_block = opt 100; } } ; variant { add = record { canister = principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; token_id = "3"; available = true; sale_block = opt 100; } } ; variant { add = record { canister = principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; token_id = "4"; available = true; sale_block = opt 100; } } ; variant { add = record { canister = principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; token_id = "5"; available = true; sale_block = opt 100; } } ; variant { add = record { canister = principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; token_id = "6"; available = true; sale_block = opt 100; } } ; variant { add = record { canister = principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; token_id = "7"; available = true; sale_block = opt 100; } } ; } )'

 dfx canister call origyn_sale_reference manage_nfts '( variant { add = record {key = "second"; item = record { canister = principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; token_id = "2"; available = true; sale = opt 100; } ;}  })'

 dfx canister call origyn_sale_reference manage_nfts '( variant { add = record {key = "third"; item = record { canister = principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; token_id = "3"; available = true; sale = opt 100; } ;}  })'

 dfx canister call origyn_sale_reference manage_nfts '( variant { add = record {key = "fourth"; item = record { canister = principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; token_id = "4"; available = true; sale = opt 100; } ;}  })'

 #remove
 dfx canister call origyn_sale_reference manage_nfts '( vec { variant { remove = "1"}; variant {remove = "2" }; variant { remove = "3"}; variant { remove = "4"}; variant { remove = "5"}; } )'
```

**Call manage_nfts (remove)**

```
 dfx canister call origyn_sale_reference manage_nfts '(variant { remove = record { key = "first" ;} })'
```

**Call manage_group**

```
#add
 dfx canister call origyn_sale_reference manage_group '(variant { add = record { allowed_amount = opt 10; members = vec {principal "xr75m-zryhp-v2f4r-kzhsj-62bf2-azbg7-fwrt6-zcdgv-zabu3-qylvn-5qe"}; namespace = "alpha"; pricing=opt vec {record {cost_per=record {token=variant {ic=record {fee=100000; decimals=8; canister=principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; standard=variant {DIP20}; symbol="DIP20"}}; amount=1000000}}};} })'


#remove
 dfx canister call origyn_sale_reference manage_group '(variant { remove = record { namespace = "alpha"; } })'
 dfx canister call origyn_sale_reference manage_group '(variant { remove = record { namespace = "beta"; } })'

 #addMembers
 dfx canister call origyn_sale_reference manage_group '(variant { addMembers = record { namespace = "alpha"; members = vec {principal "xr75m-zryhp-v2f4r-kzhsj-62bf2-azbg7-fwrt6-zcdgv-zabu3-qylvn-5qe" ; principal "u74sm-wx4yh-capur-xnz4w-orbcn-l3jlc-m65rb-ue5ah-mqyvz-fmvvc-tae"};  } })'

 dfx canister call origyn_sale_reference manage_group '(variant { addMembers = record { namespace = "alpha"; members = vec {principal "xr75m-zryhp-v2f4r-kzhsj-62bf2-azbg7-fwrt6-zcdgv-zabu3-qylvn-5qe" ; principal "u74sm-wx4yh-capur-xnz4w-orbcn-l3jlc-m65rb-ue5ah-mqyvz-fmvvc-tae" ; principal "3j2qa-oveg3-2agc5-735se-zsxjj-4n65k-qmnse-byzkf-4xhw5-mzjxe-pae"};  } })'

dfx canister call origyn_sale_reference manage_group '(variant { addMembers = record { namespace = "alpha"; members = vec {principal "xr75m-zryhp-v2f4r-kzhsj-62bf2-azbg7-fwrt6-zcdgv-zabu3-qylvn-5qe" ; principal "u74sm-wx4yh-capur-xnz4w-orbcn-l3jlc-m65rb-ue5ah-mqyvz-fmvvc-tae" ; principal "3j2qa-oveg3-2agc5-735se-zsxjj-4n65k-qmnse-byzkf-4xhw5-mzjxe-pae"; principal "g26iu-e3i6k-ysc3e-6rdwn-lztzb-3uazv-ui6os-o7eqz-touw2-42tsd-lae"};  } })'


 dfx canister call origyn_sale_reference manage_group '(variant { addMembers = record { namespace = "beta"; members = vec {principal "xr75m-zryhp-v2f4r-kzhsj-62bf2-azbg7-fwrt6-zcdgv-zabu3-qylvn-5qe" ; principal "u74sm-wx4yh-capur-xnz4w-orbcn-l3jlc-m65rb-ue5ah-mqyvz-fmvvc-tae"};  } })'

 #removeMembers
 dfx canister call origyn_sale_reference manage_group '(variant { removeMembers = record { namespace = "alpha"; members = vec {principal "xr75m-zryhp-v2f4r-kzhsj-62bf2-azbg7-fwrt6-zcdgv-zabu3-qylvn-5qe" ; principal "u74sm-wx4yh-capur-xnz4w-orbcn-l3jlc-m65rb-ue5ah-mqyvz-fmvvc-tae"};  } })'

 #updatePricing
dfx canister call origyn_sale_reference manage_group '(variant { updatePricing = record { namespace = "alpha"; pricing=opt vec {record {cost_per=record {token=variant {ic=record {fee=100000; decimals=8; canister=principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; standard=variant {DIP20}; symbol="DIP20"}};} })'

dfx canister call origyn_sale_reference manage_group '(variant {updatePricing=record {pricing=opt vec {record {cost_per=record {token=variant {ic=record {fee=200000; decimals=8; canister=principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; standard=variant {DIP20}; symbol="DIP20"}}; amount=1000000}}}; namespace="alpha"}})'

dfx canister call origyn_sale_reference manage_group '(variant {updatePricing=record {pricing=opt vec {record {cost_per=record {token=variant {ic=record {fee=200000; decimals=8; canister=principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; standard=variant {DIP20}; symbol="DIP20"}}; amount=100000}}}; namespace="beta"}})'


#updateAllowedAmount
dfx canister call origyn_sale_reference manage_group '(variant { updateAllowedAmount = record { namespace = "alpha"; allowed_amount = opt 15; } })'
```

**Call manage_reservation - reservation_type => groups**

```
#add
 dfx canister call origyn_sale_reference manage_reservation '(variant {add=record {reservation_type=variant {Groups=vec {"uno"; "dos";}}; nfts=vec {"a"; "b"}; namespace="beta"; exclusive=true}})'

 #remove
 dfx canister call origyn_sale_reference manage_reservation '(variant {remove=record { namespace="beta"; }})'

 #addNFTs

 // Add duplicates
 dfx canister call origyn_sale_reference manage_reservation '(variant {addNFTs = record { nfts=vec {"a"; "a"; "a";}; namespace="beta"; }})'

 // Add different nfts - they may be duplicated but the system will handle it
 dfx canister call origyn_sale_reference manage_reservation '(variant {addNFTs = record { nfts=vec {"a"; "b"; "c";}; namespace="beta"; }})'

 #removeNFTs
 dfx canister call origyn_sale_reference manage_reservation '(variant {removeNFTs = record { nfts=vec {"a"; "a"; "a";}; namespace="beta"; }})'

 dfx canister call origyn_sale_reference manage_reservation '(variant {removeNFTs = record { nfts=vec {"a"; "b"; "c";}; namespace="beta"; }})'
```

**Call manage_reservation - reservation_type => principal**

```
#add
 dfx canister call origyn_sale_reference manage_reservation '(variant {add=record {reservation_type=variant {Principal=principal "xr75m-zryhp-v2f4r-kzhsj-62bf2-azbg7-fwrt6-zcdgv-zabu3-qylvn-5qe"}; nfts=vec {"1"}; namespace="alpha"; exclusive=true}})'

 #remove
 dfx canister call origyn_sale_reference manage_reservation '(variant {remove=record { namespace="alpha"; }})'

 #addNFTs

 // Add duplicates
 dfx canister call origyn_sale_reference manage_reservation '(variant {addNFTs = record { nfts=vec {"1"; "1"; "1";}; namespace="alpha"; }})'

 // Add different nfts - they may be duplicated but the system will handle it
 dfx canister call origyn_sale_reference manage_reservation '(variant {addNFTs = record { nfts=vec {"1"; "2"; "3";}; namespace="alpha"; }})'


#removeNFTs

 // Remove duplicates
 dfx canister call origyn_sale_reference manage_reservation '(variant {removeNFTs = record { nfts=vec {"1"; "1"; "1";}; namespace="alpha"; }})'

 // Remove different nfts - they may be duplicated but the system will handle it
 dfx canister call origyn_sale_reference manage_reservation '(variant {removeNFTs = record { nfts=vec {"1"; "2"; "3";}; namespace="alpha"; }})'

 #update_type

 // Change to principal type
 dfx canister call origyn_sale_reference manage_reservation '(variant {update_type = record { reservation_type=variant {Groups=vec {"uno"; "dos";}}; namespace="alpha"; }})'

 // Change to principal type
 dfx canister call origyn_sale_reference manage_reservation '(variant {update_type = record { reservation_type=variant {Principal=principal "xr75m-zryhp-v2f4r-kzhsj-62bf2-azbg7-fwrt6-zcdgv-zabu3-qylvn-5qe"}; namespace="alpha"; }})'


```

**Call get_total_reservations_tree**

```
 dfx canister call origyn_sale_reference get_total_reservations_tree
```

**Call allocate_nfts**

```
 dfx canister call origyn_sale_reference manage_reservation '(variant {add=record {reservation_type=variant {Principal=principal "xr75m-zryhp-v2f4r-kzhsj-62bf2-azbg7-fwrt6-zcdgv-zabu3-qylvn-5qe"}; nfts=vec {"gamma"}; namespace="alpha"; exclusive=true}})'
```

---

- [ ] **NFT-172. AA NFT Creator IWT sell my NFTs for a different amount and to different sets of people.**

- [ ] **NFT-173. AA user IWT claim by an NFT with my membership rights that are granted by holding another NFT(ie mintpass).**

- [ ] **NFT-174. AA NFT Creator IWT be able to have different groups of allow lists.**

- [ ] **NFT-177. AAA Buyer IWT use a plug ID to reserve a number of items in a collection STI can have time to pay for them.**

- [ ] **NFT-178. AA Creator IWT allow a free mint for a tier.**

- [ ] **NFT-179. AA Creator IWT create a team group so that I can allocate some NFTs to my team.**

- [ ] **NFT-180. AA Creator IWT supply a list of user principals for a range of my nfts STI can have them auto minted to a team/tier/etc.**

- [ ] **NFT-181. AA Creator IWT be able to raffle a set of NFTs to a set of users.**

- [ ] **NFT-182. AA user IWT submit my ICP to get on the list and then get it back if I don't get an allocation.**

- [ ] **NFT-184. AA creator IWT create a ranking of groups so that they get allocated in order.**

- [ ] **NFT-185. AA creator IWT indicate a fall through mechanism STI can either have a group completely filled or only allocate n number before falling through to the next tier.**

- [ ] **NFT-186. AA user IWT to be able to review my escrow registration STI know I am in line for an allocation.**

- [ ] **NFT-187. AA user IWT be able to see what groups I'm in STI know I'm registered for the drop.**

- [ ] **NFT-189. AA user IWT register my escrow with a sale STI get an allocation on the drop date.**

test_runner_sale

testLoadNFTs

- Create wallet a & wallet b
- Create newPrincipal from canister factory send owner() and storage(null)
- Create canister from Service (origyn_nft_reference)
- Stage nfts from utils.buildStandardNFT
- Add NFTs sale_canister.manage_nfts_sale_nft_origyn
- See final total inventory or individual

Questions:

- You can add minted or unminted NFTs to inventory. Is this correct?

testManagement

- Create SaleCanister instance
- UpdateNFTGateway
- UpdateAllocationExpiration
- UpdateSaleOpenDate
- UpdateRegistrationDate
- UpdateEndDate
- get_metrics_sale_nft_origyn

Questions:

- You can set_canister_sale_open_date_low for a past date like yesterday. Is this correct?
- You can set_canister_registration_date_low for a past date like yesterday + 200 nanos. Is this correct?
- You can set_canister_end_date_low for a past date like yesterday + 300 nanos. Is this correct?

testAllocation

add_unminted_1
defaultGroup
bGroup
cGroup
allocate_0
allocate_1
allocate_2
allocate_3
allocate_4
allocate_5
balance_check_1
balance_check_2
balance_check_3
expiration
expired_check_1
expired_check_2
expired_check_3
allocate\_\_retry_1

```
D.print("testAllocation : " # "\n\n" #
"add_unminted_1 : " # debug_show(add_unminted_1) # "\n\n" #
"defaultGroup : " # debug_show(defaultGroup) # "\n\n" #
"bGroup : " # debug_show(bGroup) # "\n\n" #
"cGroup : " # debug_show(cGroup) # "\n\n" #
"allocate_0 : " # debug_show(allocate_0) # "\n\n" #
"allocate_1 : " # debug_show(allocate_1) # "\n\n" #
"allocate_2 : " # debug_show(allocate_2) # "\n\n" #
"allocate_3 : " # debug_show(allocate_3) # "\n\n" #
"allocate_4 : " # debug_show(allocate_4) # "\n\n" #
"allocate_5 : " # debug_show(allocate_5) # "\n\n" #
"balance_check_1 : " # debug_show(balance_check_1) # "\n\n" #
"balance_check_2 : " # debug_show(balance_check_2) # "\n\n" #
"balance_check_3 : " # debug_show(balance_check_3) # "\n\n" #
"expiration : " # debug_show(expiration) # "\n\n" #
"expired_check_1 : " # debug_show(expired_check_1) # "\n\n" #
"expired_check_2 : " # debug_show(expired_check_2) # "\n\n" #
"expired_check_3 : " # debug_show(expired_check_3) # "\n\n" #
"allocate__retry_1 : " # debug_show(allocate__retry_1) # "\n\n"
);
```

testReservation

```
D.print("Test reservation sale : " # "\n\n" #
"add_unminted_1 : " # debug_show(add_unminted_1) # "\n\n" #
"defaultGroup : " # debug_show(defaultGroup) # "\n\n" #
"aGroup : " # debug_show(aGroup) # "\n\n" #
"bGroup : " # debug_show(bGroup) # "\n\n" #
"a_principal_request : " # debug_show(a_principal_request) # "\n\n" #
"a_group_request : " # debug_show(a_group_request) # "\n\n" #
"b_group_request : " # debug_show(b_group_request) # "\n\n" #
"aRedeem_payment_2 : " # debug_show(aRedeem_payment_2) # "\n\n" #
"a_wallet_try_escrow_general_valid : " # debug_show(a_wallet_try_escrow_general_valid) # "\n\n" #
"a_wallet_try_register_for_one : " # debug_show(a_wallet_try_register_for_one) # "\n\n" #
"a_wallet_registration_after_one : " # debug_show(a_wallet_registration_after_one) # "\n\n" #
"bRedeem_payment_2 : " # debug_show(bRedeem_payment_2) # "\n\n" #
"b_wallet_try_escrow_general_valid : " # debug_show(b_wallet_try_escrow_general_valid) # "\n\n" #
"b_wallet_try_register_for_four : " # debug_show(b_wallet_try_register_for_four) # "\n\n" #
"b_wallet_registration_after_four : " # debug_show(b_wallet_registration_after_four) # "\n\n" #
"dRedeem_payment_2 : " # debug_show(dRedeem_payment_2) # "\n\n" #
"d_wallet_try_escrow_general_valid : " # debug_show(d_wallet_try_escrow_general_valid) # "\n\n" #
"d_wallet_try_register_for_two : " # debug_show(d_wallet_try_register_for_two) # "\n\n" #
"d_wallet_registration_after_two : " # debug_show(d_wallet_registration_after_two) # "\n\n" #
"d_balance_before_allocation : " # debug_show(d_balance_before_allocation) # "\n\n" #
"d_allocate_empty : " # debug_show(d_allocate_empty) # "\n\n" #
"a_allocate_empty : " # debug_show(a_allocate_empty) # "\n\n" #
"a_wallet_try_redeem_for_one : " # debug_show(a_wallet_try_redeem_for_one) # "\n\n" #
"b_allocate_empty : " # debug_show(b_allocate_empty) # "\n\n" #
"b_wallet_try_redeem_for_one : " # debug_show(b_wallet_try_redeem_for_one) # "\n\n" #
"a_allocate_empty_after_two : " # debug_show(a_allocate_empty_after_two) # "\n\n" #
"a_wallet_try_redeem_for_third : " # debug_show(a_wallet_try_redeem_for_third) # "\n\n" #
"c_allocate_empty_after_two : " # debug_show(c_allocate_empty_after_two) # "\n\n" #
"c_wallet_try_redeem_for_one : " # debug_show(c_wallet_try_redeem_for_one) # "\n\n" #
"a_wallet_registration_after_allocation : " # debug_show(a_wallet_registration_after_allocation) # "\n\n" #
"b_wallet_registration_after_allocation : " # debug_show(b_wallet_registration_after_allocation) # "\n\n" #
"c_wallet_registration_after_allocation : " # debug_show(c_wallet_registration_after_allocation) # "\n\n" #
"d_wallet_registration_after_allocation : " # debug_show(d_wallet_registration_after_allocation) # "\n\n" #
"a_wallet_balance_after_three : " # debug_show(a_wallet_balance_after_three) # "\n\n" #
"b_wallet_balance_after_three : " # debug_show(b_wallet_balance_after_three) # "\n\n" #
"c_wallet_balance_after_three : " # debug_show(c_wallet_balance_after_three) # "\n\n" #
"c_allocate_empty_2_end : " # debug_show(c_allocate_empty_2_end) # "\n\n" #
"a_allocate_empty_3_end : " # debug_show(a_allocate_empty_3_end) # "\n\n" #
"d_allocate_empty_3_end : " # debug_show(d_allocate_empty_3_end) # "\n\n"
);
```

```
# METRICS
# Get metrics -sale canister - manage_sale_nft_origyn
dfx canister call origyn_sale_reference get_metrics_sale_nft_origyn

# UpdateNFTGateway
dfx canister call origyn_sale_reference manage_sale_nft_origyn '( variant {UpdateNFTGateway = opt principal "xr75m-zryhp-v2f4r-kzhsj-62bf2-azbg7-fwrt6-zcdgv-zabu3-qylvn-5qe" })'

# UpdateAllocationExpiration
dfx canister call origyn_sale_reference manage_sale_nft_origyn '( variant {UpdateAllocationExpiration = 555 })'

# UpdateSaleOpenDate
dfx canister call origyn_sale_reference manage_sale_nft_origyn '( variant {UpdateSaleOpenDate = opt 1654015582666898000 })'

# UpdateRegistrationDate
dfx canister call origyn_sale_reference manage_sale_nft_origyn '( variant {UpdateRegistrationDate = opt 1654021827313225000 })'

# UpdateEndDate
dfx canister call origyn_sale_reference manage_sale_nft_origyn '( variant {UpdateEndDate = opt 1654031827313226000 })'

```

```
# Manage NFTS - manage_nfts_sale_nft_origyn
#toke_id = "1"
dfx canister call origyn_sale_reference manage_nfts_sale_nft_origyn '( vec { variant { add = record { canister = principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; token_id = "1"; available = true; sale_block = opt null; }  }})'

#toke_id = "2"
dfx canister call origyn_sale_reference manage_nfts_sale_nft_origyn '( vec { variant { add = record { canister = principal "dw5hj-fcc4h-22h5p-zdkx2-3byeo-f2vf3-jv5sa-gckmc-mtnss-zojch-oqe"; token_id = "2"; available = true; sale_block = opt null; }  }})'

#token_id = "3", "4", "5"
dfx canister call origyn_sale_reference manage_nfts_sale_nft_origyn '( vec { variant { add = record { canister = principal "xr75m-zryhp-v2f4r-kzhsj-62bf2-azbg7-fwrt6-zcdgv-zabu3-qylvn-5qe"; token_id = "3"; available = true; sale_block = opt null; }}; variant { add = record { canister = principal "xr75m-zryhp-v2f4r-kzhsj-62bf2-azbg7-fwrt6-zcdgv-zabu3-qylvn-5qe"; token_id = "4"; available = true; sale_block = opt null; }  }; variant { add = record { canister = principal "xr75m-zryhp-v2f4r-kzhsj-62bf2-azbg7-fwrt6-zcdgv-zabu3-qylvn-5qe"; token_id = "5"; available = true; sale_block = opt null; }  }})'


```

```
# Get full inventory
dfx canister call origyn_sale_reference get_inventory_sale_nft_origyn

# get inventory item
dfx canister call origyn_sale_reference get_inventory_item_sale_nft_origyn '("1")'
```
