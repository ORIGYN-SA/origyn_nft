

Issue 1. Query methods are uncertified

We have added certified queries for all core protocol queries.  We did not add certified queries for DIP721 or EXT endpoints as there are better methods to get that data in the core protocol.

2. Internal magic string causes externally-visible behavior

We have removed the magic string and replaced it with an optional return that must be handled by the code.

3. Vulnerable node.js dependencies

We have added npm audit into our pipeline and code cannot be merged unless the vulnerabilities have been fixed.


4. Code duplication in shell scripts

We are moving toward better scripts and node.js based testing.  The projects are being restructured so that these project specific runners are not part of the final repo.

5. Motoko code uses unsafe and deprecated constructs

todo: deepproperties

We have eliminated all the warnings and references to Array where possible.  Some libraries are under third party control and we are working with them to remove these references.


6. The README doesn’t instruct how to build or develop the project

We have added build instructions to the readme.md


7. Using 32-bit integers to track escrows allows malicious users to steal funds

We have adapted the maps to use the actual objects instead of 32 bit hashes for the keys.  The 32 bit hashes are still used for the hashing function that the map uses for efficiency, but the equivalence function will assure that only the proper principal or token can be used.


8. Entropy is lost when the sale ID is computed

We've updated some hashing to keep as much entropy in as possible.  We use a sha256 now which should provide adequate entropy.

9. Inconsistent error reporting in ensure_no_existing_sale

Replaced with is_token_on_sale and inverted case handling.

10. Use of hardcoded timestamp in escrow_nft_origyn

Added code to trap if the data is off by an extra digit.  This enables locking for up to 470 or so years.

11. clearAccessKeysExpired clears random access keys

Changed collection to access_tokens and updated code to use expiration for clearing out old items.  Also updated the expiration to 6 minutes and created a named constant.

12. The function http_access_key fails if the caller is not the collection owner

We have changed the application to allow for access keys for any non-anon principal.  Future iterations will use inspect_message for spam prevention. We also added access to NFT owners for "owner" data nodes and "collection_owner" data nodes.

13. The function manage_reservation_sale_nft_origyn always returns an empty result

Added a result builder to make sure the results has data in it.

14. Insufficient access controls on the method add_inventory_item

Added access control and removed the size tracker. Using Map.size instead.

15.  Access keys are stored in canister state

This is a known limitation of the IC. We've added language to the documentation and code base alerting users to the limitations of the current system.

16. The owner_transfer_nft_origyn API can be used to circumvent market fees

We have removed owner_transfer_nft_origyn and replaced it with share_wallet_nft_origyn which creates a shared wallet scenario where a user can share their NFT with another wallet, but the original wallet maintains ownership.  This collection of shared wallets can only be cleared by the network via governance.

Code quality Improvements:  

1. The Motoko style guide recommends using camel case names for all objects and functions. Currently, the code base mixes camel case and snake case names.

We have chosen to use snake case for function names, variables, and objects.  We have reviewed and refactored the code to us it in most places.

2. Comments regarding migration in src/origyn_nft_reference/main.mo refer to #state002 whereas the code calls the current state #v0_1_0.

Comments have been updated

3. Missing "not" in error message in src/origyn_nft_reference/metadata.mo.

Fixed Comment.

4. Switch case never reached in src/origyn_nft_reference/metadata.mo.

Branch eliminated

5. Using the CandyTypes.CandyValue type (which can represent multiple different types) weakens the security guarantees provided by the Motoko type system. It also makes the code harder to read and maintain.

CandyLibrary was selected due to its ability to provide recursive, user defined, data structures. It would be impossible for the library to know all possible data structures a user might want to use. Specifically, CandyLibrary is useful for JSON like data that is extensible and editable at runtime.

6. The DIP-721 type Metadata (defined in src/origyn_nft_reference/DIP721.mo) should be named Metadata.

Corrected

7. The implementation of DIP-721 (in src/origyn_nft_reference/DIP721.mo) uses very generic type names for various result types specified by the DIP. This makes the code less readable and should be fixed.

This code was taken from the reference implementation. We will update it with the latest version.

8. The function stage_nft_origyn (in src/origyn_nft_reference/main.mo) prints a debug message claiming it is "in update". (This seems to be copied over from update_app_nft_origyn.)

Comment removed.

9. Types.nft_status_minted and Types.nft_status_stageddefinedin src/origyn_nft_reference/types.mo should be a variant type.

The items are text because variants do not translate well to CandyLibrary.  Motoko currently lacks reflection.  Being able to reflect on variants would be very helpful and has been discussed with the motoko team.

10. Typos in function names - buildLibray should be buildLibrary and bulildNftLedgerStable should be buildNftLedgerStable in src/origyn_nft_reference/src/utils.mo

Corrected.  see build_library.

11. The function library_equal is almost identical to compare_library in src/origyn_nft_reference/src/utils.mo. Consider extracting the common logic.

Updated functions.

12. This conditional should be simplified, since the else-branch is unreachable.

Corrected.

13. The functions is_owner_manager_network and is_owner_network in src/origyn_nft_reference/utils.mo return true by default. If the authorization requirements evolve and a developer forgets to alter the condition, the function will return true by default, authorizing the wrong entities. Consider changing the functions to return false by default.

Functions Updated


14. The purchases argument is not used in calc_user_purchase_graph (in src/origyn_sale_reference/main.mo) and the purchases field in the return value is set to the empty array.

Added the data to the return.

15. Avoid using tuples as return values since this tends to make the code less readable when the tuple is unpacked at the call site.

We have removed tuples as return types for items that we have control over.

16. A number of APIs (for example owner_transfer_nft_origyn) take a request containing from and to fields as an argument. Both the msg.caller and the request.from field are then checked against the registered owner of the token. This means that msg.caller and request.from play the same role. This introduces a latent risk of forgetting to check one against the token owner, which could introduce a vulnerability into the code base.

Since request to from can be an Account type(ie. not just a principal) we have to have the user specify it in the call.  If the owner were an account with a sub account we'd have no way to specify it if we didn't use request.from

17. The condition escrow.amount > fee in market_transfer_nft_origyn_async (in src/origyn_nft_reference/market.mo) is enforced by the previous call to checker.transferSale. This should be either rewritten or documented more clearly to indicate that the code path is always taken. The same is true for the condition winningEscrow.amount > fee in end_sale_nft_origyn.

We have noted the reason for including the comparison(use of Nat.sub).

18. The function market_transfer_nft_origyn (in src/origyn_nft_reference/market.mo) does not check that auction_details.ending represents an end date which is after auction_details.start_date.

We have added the check so we don't end up with odd auctions

19. Empty if-statement body in redeem_allocation_sale_nft_origyn (in src/origyn_sale_reference/main.mo).

We have inverted the comparisons and changed it to an or statement

20. The functions compare_library, bulildNftLedgerStable, buildNftLedger, nat32Identity from src/origyn_nft_reference/utils.mo and genAccessKey from src/origyn_nft_reference/storage_http.mo are unused.

These functions have been removed.

21. The calls to NFTUtils.addLog are repeated throughout src/origyn_nft_reference/main.mo with the same arguments besides event. Consider extracting this call to a separate function with common arguments pre-filled.

We will be expanding logging and refactoring in the next version of the reference implementation.

22. The two functions handle_library and mint_nft_origyn (in src/origyn_nft_reference/mint.mo) swallow errors from Metadata.getNFTLibrary.

This is intended functionality as we only want to handle the return from these items if the values are returned without error.
