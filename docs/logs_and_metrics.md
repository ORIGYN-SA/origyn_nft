# Logs & Metrics

🚀 Status, quality logs, cycles and memory tracking in the Origyn NFT canister that allow users to gather important information about events happening in the backend.

## User features

- Get status in realtime
- Track cycles and memory
- Get logs and filter by time or specific event
- UI dashboard

## Getting started

- Make sure you run the Brain Matter project first
```bash
yes yes | bash ./projects/bm/deploybm-local.sh
```
- Run `dfx canister id origyn_nft_reference` and copy the origyn_nft_reference canister id, keep it handy.
- Clone the following repo that contains the [Logs & Metrics Dashboard](https://github.com/ORIGYN-SA/canistergeek-ui)
- Open the Logs & Metrics dashboard project and run it
```node
# Install all dependencies
npm install
# Build
npm run build
# Start local server on port 3001
npm run start
# If you get webpack-cli error run the following then do the npm run start
npm install --save-dev webpack-cli
```
- Navigate to the settings tab
- Click the example button to copy default settings
- Under canisters replace the `canistedId` with the origyn_nft_reference id and change the name to Origyn NFT.
- Delete the second entry object that contains a blackhole reference
- Click the save button. It should take you to the metrics page
- At this you should be able to see logs & metrics for the origyn_nft_refence
- Click on the Origyn NFT subtab to see more info
- Navigate to the Logs tab
- You should see a number of logs under the Logs header
- Navigate to the Realtime tab and enter the word `stage` into the text input then click the show button ( Notice that by entering the word stage the system will filter all the latest logs that contains that word. The filter is designed to search by function name or part of it like is in the case of 'stage' )
- Click on any item and you should see more info related to that entry
- Swap to the History tab and you can filter by time and/or by function name
