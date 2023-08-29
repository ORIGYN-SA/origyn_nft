# origyn_nft_reference - v0.1.4

<img src="https://gitlab.origyn.ch/origyn/engineering/opensource/origyn_nft/-/blob/develop/origyn_nft_pic.jpeg" />

### Purpose

This repo contains the refrernce implementation of the ORIGYN NFT in motoko, the sales canister reference implementation, and the storage canister implementation that allows unlimited storage for NFT canisters.

### Usage

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


### Motoko base

It is important to note that every now and then there are new items in the motoko base library. One example of this is Timer. If you are using an older vesion of the motoko base library in vessel you will have an error complaining about a non existent Timer. In this repo we try to keep libs up-to-date, however, just be aware that from time to time you might need to change the upstream varible in the package-set.dhall to reflect the lastest motoko library.

[Audit document](./docs/audit.md)

### How to update Motoko Compiler

Origyn NFT version 0.1.4 needs Motoko Compiler version >= 0.8.5. This is included in DFX 0.14.0.  If you have 0.13.x, see below:

Here are the instructions about how to do it:

- [Download MOC zip file for your Operating System](https://github.com/dfinity/motoko/releases/tag/0.8.5)
- Run the following command `dfx cache show` to get Motoko version directory installation
- Unzip file and copy `mo-ide, mo-doc, moc` files to the directory mentioned in step 2
- Make sure you give the right persmissions to those files
- Run `$(dfx cache show)/moc --version` to verify you have the downloaded version

### Example URLs

Combine a `canister URL` and a `canister-relative URL` to get a full example of an absolute URL.

**Canister URLs**

-   Canister ID

    -   Localhost
        -   http://rrkah-fqaaa-aaaaa-aaaaq-cai.localhost:8080
    -   Mainnet
        -   https://ap5ok-kqaaa-aaaak-acvha-cai.raw.icp0.io

-   Proxy

    -   Localhost (must have the proxy running locally first)
        -   http://localhost:3000/-/rrkah-fqaaa-aaaaa-aaaaq-cai
    -   Mainnet
        -   https://prptl.io/-/ap5ok-kqaaa-aaaak-acvha-cai

-   Proxy + Phonebook
    -   Localhost (must have the proxy running locally first)
        -   http://localhost:3000/-/bm
    -   Mainnet
        -   https://prptl.io/-/bm

**Canister-Relative URLs**

-   Collection Level

    -   Standard Info URLs

        -   /collection/info
        -   /collection/ledger_info
        -   /collection/library

    -   Origyn DApp URLs
        -   /collection/-/vault
        -   /collection/-/marketplace
        -   /collection/-/library
        -   /collection/-/ledger
        -   /collection/-/data

-   NFT Level

    -   Standard Info URL

        -   /-/token-id/info
        -   /-/token-id/ledger_info
        -   /-/token-id/library

    -   Standard Asset Type URLs ("token-id" is the token ID of an NFT)

        -   /-/token-id/primary
        -   /-/token-id/preview
        -   /-/token-id/hidden
        -   /-/token-id/ex

    -   Direct Asset URLs ("token-id" is the token ID of an NFT)
        -   /-/token-id/-/primary1.png
        -   /-/token-id/-/preview1.png
        -   /-/token-id/-/mystery-bm.gif
        -   /-/token-id/-/experience1.html
