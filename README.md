# origyn_nft_reference

<img src="https://github.com/ORIGYN-SA/origyn_nft/blob/add-origyn-nft-pic/origyn_nft_pic.jpeg" />

## NFT Canister

[NFT Canister API](./docs/nft-current-api.md)

[NFT Canister Sample Calls](./docs/audit.md)

## Sales Canister

[Overview](./docs/nft_sale.md)

## Getting up and running

### Testing

You will need the proper version of yes for your OS. (npm install -g yes)

yes yes | ./runners/test_runner.sh

### Produce an identity for deploying locally

1. You need to have an identity.pem and a seed.txt in your root directory. You can follow the instructions at https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/50 to produce these file. You should add these files to your git.ignore.

Navigate to my .dfx identities. → ~/.config/.dfx/identity

Create a new identity. → mkdir local-testing; cd local-testing

Download quill https://github.com/dfinity/quill.

Test that quill is installed correctly. → quill

Look up how to generate a key. → quill generate --help

Generate a key and seed file. → quill generate --pem-file identity.pem --seed-file seed.txt

Copy these files to your root directory and add to git.ignore.

To run deployment scripts you will also need to produce seed.prod.txt and identity.prod.pem for a deploying identity.

__You may need a git rest key__

https://docs.github.com/rest

You can put this key in gittoken.key

It may be necessary to download the default dapps.

### NFT Projects

The ./projects folder contains a sample NFT project with NFT assets for minting along with a deploy script. The deploy script should be invoked from the root of the project. For example:

```bash
yes yes | bash ./projects/bm/deploybm-local.sh
```

Reusable scripts are placed at the root of the ./projects folder.

### Git Large File Storage

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

Node script that stages and mints NFTs with the input of a JSON metadata file.

See also: https://github.com/ORIGYN-SA/minting-starter

### Logs & Metrics

[Logs and metrics documentation](./docs/logs_and_metrics.md)

### Audit

[Audit document](./docs/audit.md)

### How to update Motoko Compiler

Origyn NFT version 0.1.4 needs Motoko Compiler version >= 0.8.5

Here are the instructions about to do it:

- [Download MOC zip file for your Operating System](https://github.com/dfinity/motoko/releases/tag/0.8.5)
- Run the following command `dfx cache show` to get Motoko version directory installation
- Unzip file and copy `mo-ide, mo-doc, moc` files to the directory mentioned in step 2
- Make sure you give the right persmissions to those files
- Run `$(dfx cache show)/moc --version` to verify you have the downloaded version

