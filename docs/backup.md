# Origyn NFT Backup

These instructions are for an `emergency only` backup.
For the moment there's no rehydration function written yet but we are working to improve the backup experience.

- To see state balances of different data structures that make up the Origyn NFT, we first call the function `state_size`. See below candid example and output.
```
dfx canister --network ic call s5eo5-gqaaa-aaaag-qa3za-cai state_size

(
  record {
    sales_balances = 3 : nat;
    offers = 2 : nat;
    nft_ledgers = 1_000 : nat;
    allocations = 2_006 : nat;
    nft_sales = 9 : nat;
    buckets = 1 : nat;
    escrow_balances = 3 : nat;
  },
)

```
The previous data gives an overview of the stored data in a canister. For example, we have 3 sales, 2 offers, 1000 nft_ledgers, 2006 allocations, etc.

- The `back_up` function in the Origyn NFT canister can backup all the data shown above, however, we might need to separate the data in several chunks as we have restrictions on how much data can be returned on one call. See below a simple call.
```
dfx canister --network ic call s5eo5-gqaaa-aaaag-qa3za-cai back_up '(0)'
```
- To be able to backup all the data without the need of manually call the backup function `x` amount of times we can create a bash script that does this in a loop.
  - First you need to find out the amount of pages we have. To do that we can simply come up the number by adding all the numbers from the result of the function `state_size`. From our example above we have the following:
  
    | Data structure | Number of pages |
    | --- | ----------- |
    | sales_balance | 3 |
    | offers | 2 |
    | nft_ledgers | 1000 |
    | allocations | 2006 |
    | nft_sales | 9 |
    | buckets | 1 |
    | escrow_balances | 3 |
    | Total | 3024 |
  - To know the number of loops that we need for our script that will help us automate the process just divide the total of pages, which is 3024 by 100 => 30.25. Make sure to round it. In our case is 31.
  - In the root of the project where you deployed Origyn NFT create a bash script called backup.sh with the following content:

```bash
#!/bin/bash


PAGES=31

for (( i=1; i<=$PAGES; i++ ))
do
    dfx canister --network ic call rrkah-fqaaa-aaaaa-aaaaq-cai back_up "($i)" >> backup_result
    echo "done with page $i"
done
```

- Here are the instructions of what to change and how to run the script:
  - Make sure you change the `PAGES` number to reflect the total number of data pages you script need to collect.
  - Change the canister id that starts with `3e73x...` with your canister id.
  - Make sure the script has execute permissions `sudo chmod +x back_up.sh`
  - Run the script from the root directory of your project `./backup.sh` or `bash backup.sh`

Note: All your data should be in a file called back_result in the root of project.
 