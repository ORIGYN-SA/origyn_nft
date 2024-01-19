# Fee Options Update: Phase 1

The following spec satisfies the specified user stories:

AA Merchant IWT pay the NFT fees for my users ST(they) don't have to have to have more that the exact amount of the sale and I still get as much as possible of the transacted token.

AA Merchant IWT pay fees in a fixed amount of OGY per transaction.

AA Buyer IWT pick the fee schema that I want to pay in.

AA Creator IWT specify fees in a fixed amount of OGY STMy users can choose between types of fees.

## Updating EscrowReceipt

Update EscrowReceipt that allows an escrower to specify which fee schema they would like to use if they are charged.  Can be overriden by an ask feature of type #MerchantPaysFee:

public type EscrowReceipt = {
    amount: Nat; //Nat to support cycles
    seller: Account;
    buyer: Account;
    token_id: Text;
    token: TokenSpec;
    fee_schema: : ?Text; //lets the user select the fee structure they want to pay in conjunction with the bid request
};

## Add MerchantPaysFee variant to ask feature

Add a new Ask feature to the Ask Feature list that lets a merchant indicate that they are willing to pay the fee for the buyer out of a specified account:

#MerchantPaysFee {
  account: Account;
  fee_schema: ?Text
}

## Specify Fee Option Metadata

Configuring Alternative fees in metadata:

ogy_royalty_primary
ogy_royalty_secondary

When the user selects to pay this fee with their escrow reciept. Only fixed types will be supported in this version.(percentage and annualized percentage will require an oracle).

{"name":"ogy_royalty_primary", "value":{"Array": [
                {"Class":[
                    {"name":"tag", "value":{"Text":"com.origyn.royalty.broker"}, "immutable":true},
                    {"name":"fixed", "value":{"Nat": 100000}, "immutable":true},
                    {"name":"account", "value":{ "Map" :[["owner",{"Principal":"rrkah-fqaaa-aaaaa-aaaaq-cai"}],
                    ["subaccount", "value":{"Blob":"0x2a433334938393939493"}]]}, "immutable":true}, 
                    {"name":"token", "value":{
                    }, "immutable":true},
                ]},
                {"Class":[
                    {"name":"tag", "value":{"Text":"com.origyn.royalty.node"}, "immutable":true},
                    {"name":"fixed", "value":{"Nat": 100000}, "immutable":true},
                    {"name":"account", "value":{ "Map" :[["owner",{"Principal":"rrkah-fqaaa-aaaaa-aaaaq-cai"}],
                    ["subaccount", "value":{"Blob":"0x2a433334938393939493"}]]}, "immutable":true}, 
                    {"name":"token", "value":{
                    }, "immutable":true},
                ]},
               {"Class":[
                    {"name":"tag", "value":{"Text":"com.origyn.royalty.originator"}, "immutable":true},
                    {"name":"fixed", "value":{"Nat": 100000}, "immutable":true},
                    {"name":"account", "value":{ "Map" :[["owner",{"Principal":"rrkah-fqaaa-aaaaa-aaaaq-cai"}],
                    ["subaccount", "value":{"Blob":"0x2a433334938393939493"}]]}, "immutable":true}, 
                    {"name":"token", "value":{
                    }, "immutable":true},
                ]},
                {"Class":[
                    {"name":"tag", "value":{"Text":"com.origyn.royalty.custom"}, "immutable":true},
                    {"name":"fixed", "value":{"Nat": 100000}, "immutable":true},
                    {"name":"account", "value":{ "Map" :[["owner",{"Principal":"rrkah-fqaaa-aaaaa-aaaaq-cai"}],
                    ["subaccount", "value":{"Blob":"0x2a433334938393939493"}]]}, "immutable":true}, 
                    {"name":"token", "value":{
                    }, "immutable":true},
                ]},
            ]
}, "immutable":false},



## Work List:

1. Merchant needs to deposit fees into the canister so that we know the fees are there(Merchant fees could be put in escrows where the buyer and seller account are equal and token id is the empty string). Make sure deposit process works.
2. If a buyer wants to pay in an alternate currency, they will have to make a second deposit of that currency. (We may be able to sue the same BuyerAccount == Seller account strategy as with merchants). Make sure deposit process works.
3. Update Process Royalties to take the alternate royalty structure.
4. Update Process Royalties to know if the merchant or buyer is paying the fees.
5. Update Process Royalties to take the alternate payment and move the tokens out of escrow to the sale trie.
6. Update the selection of royalty based on the fee_schema provided.
7. Build the migration to add the fee_schema to existing escrows/sales
8. Update all tests that include the Escrow Receipt
9. Add new tests to test alternative Fee Structures
10. Add logic to select proper/default fee structure if only one is provided and/or neither ask or bid provides a fee schema.
11. Add logic to sale creation to handle the #MerchantPaysFee feature.

# Note:

There will always be two fees of GLDT because there is a fee on the transaction so the swapper will need to be ok with that having already been burned.

There are two kinds of fees:

1. ICRC1 Transaction fees - Fees. We can't do anything about these.(I don't see how we get around the swapper having to have more than 100 unless the swapper knows that two fees are required and thus sets the required amount lower).  So the swapper would have to give up the NFT for 100 - EscrowDepositTransactionFee - SaleWithdrawTransaction Fee.  It will balance but be yucky.
2. NFT Fees - we can have the merchant pay these out of a deposit account.