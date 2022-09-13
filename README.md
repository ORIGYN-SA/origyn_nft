# origyn_nft_reference

## Getting up and running

### Testing

You will need the proper version of yes for your OS. (npm install -g yes)

yes yes | ./runners/test_runner.sh

### Produce an idetity for deploying locally

1. You need to have an identity.pem and a seed.txt in your root directory. You can follow the instructions at https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/50 to produce these file. You should add these files to your git.ignore.

Navigate to my .dfx identities → ~/.config/.dfx/identity

Create a new identity → mkdir local-testing; cd local-testing

Download quill https://github.com/dfinity/quill

Test that quill is installed correctly → quill

Look up how to generate a key → quill generate --help

Generate a key and seed file → quill generate --pem-file identity.pem --seed-file seed.txt

Copy these files to your root directory and add to git.ignore.

To run deployment scripts you will also need to produce seed.prod.txt and identity.prod.pem for a deploying identity.

### You may need a git rest key

https://docs.github.com/rest

You can put this key in gittoken.key

It may be necessary to download the default dapps

## NFT Canister

[Overview](./docs/nft.md)

[NFT Canister API](./docs/nft-current-api.md)

[NFT Canister Sample Calls](./docs/sample_calls.md)

[Bad Response Examples](./docs/badresponse.md)

[Auction Sample Calls and Results](./docs/auction-results.md)

## Sales Canister

[Overview](./docs/nft_sale.md)

## Project Management

[User Stories](./docs/PM.md)

## NFT Projects

The ./projects folder contains NFT project folders which contain NFT assets for minting along with their custom deploy scripts. All deploy scripts should be invoked from the root of the project. For example:

```bash
yes yes | bash ./projects/bayc/deploy.sh
```

Reusable scripts are placed at the root of the ./projects folder.

## Git Large File Storage

This project contains video files that are stored in Git LFS. They are now downloaded when you clone the repo.
To download the videos, run the following:

```
git lfs install
git lfs fetch
git lfs checkout
```

Reference: https://git-lfs.github.com/

### deploy.js

Location: _./projects/deploy.js_.

Node script that stages and mints NFTs with the input of a JSON metadata file. This script is called by the deployment scripts of some projects under the ./projects folder.

### csm.js

Location: _./projects/csm.js_.

Node script providing the subcommands: _config_, _stage_ and _mint_. This script is called by bash scripts in the _kobe_ and _bayc_ projects and should be called by all new NFT projects.

The _csm_ script includes the staging and minting logic from _./projects/deploy.js_ organized into subcommands, as well as a subcommand to generate the JSON metadata file. New projects should use this script. Refer to _./projects/kobe/deploy.sh_ and the documentation at the top of _./projects/csm.js_ for usage.

Currently _csm_ adds all files in the target project folder to a single asset collection. It was created with the idea that it will evolve with additonal functionality. For example, new arguments have been added for minting only a range of NFTs, minting in batches, and combining external CSS/JS references into single HTML files.

The _config_ subcommand copies all assets from the target folder (-f arg) into a new sibling folder named _\_\_staged_. Any HTML assets are modified to pull in all external CSS or JavaScript references and replace links with exOS urls. A new metadata file named _full_def.json_ is then generated in the _\_\_staged_ folder. This file will be referenced by the _stage_ and _mint_ subcommands.

Each NFT project has unique requirements and may need custom predeploy and postdeploy scripts. A predeploy script may create HTML files from templates (see _./projects/bayc/predeploy.js_) and a postdeploy script may open the metadata file (_full_def.json_) created by the _config_ subcommand.

## Testing

```bash
yes yes | bash ./runners/test_runner.sh
```
