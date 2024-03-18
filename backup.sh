PAGES=35

for (( i=0; i<=$PAGES; i++ ))
do
    dfx canister --network ic call origyn_nft_reference back_up "($i)" >> backup.suzanne.dao.$i.did
    echo "done with page $i"
done
