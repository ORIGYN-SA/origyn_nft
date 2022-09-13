import fs from 'fs';
import minimist from 'minimist';
import fetch from 'node-fetch';
import hdkey from 'hdkey';
import bip39 from 'bip39';
import ICAgent from '@dfinity/agent';
import { Principal } from '@dfinity/principal';
import { Crypto } from '@peculiar/webcrypto';
import { Secp256k1KeyIdentity } from '@dfinity/identity';
import { idlFactory } from '../.dfx/local/canisters/origyn_nft_reference/origyn_nft_reference.did.js';

(async () => {
    var argv = minimist(process.argv.slice(2));
    var seedfile = 'seed.txt';
    console.log('testing seed:', argv.seed);
    if (argv.seed && argv.seed.length > 0) {
        console.log('setting to alt seed');
        seedfile = argv.seed;
    }

    const phrase = fs.readFileSync(seedfile).toString().trim();

    console.log('the phrase', phrase);

    let identityFromSeed = async (phrase) => {
        const seed = await bip39.mnemonicToSeed(phrase);
        const root = hdkey.fromMasterSeed(seed);
        const addrnode = root.derive("m/44'/223'/0'/0/0");

        return Secp256k1KeyIdentity.fromSecretKey(addrnode.privateKey);
    };

    let identity = await identityFromSeed(phrase);

    console.dir(argv);
    const NFT_ID = argv.nft_canister;

    console.log('NFTID', NFT_ID);

    global.crypto = new Crypto();

    function getAgent() {
        return new ICAgent.HttpAgent({
            fetch: fetch,
            host: ICP_ENDPOINT,
            identity: identity, //await window.plug.getIdentity()
        });
    }

    //console.log("Anonymous Identity ", anonIdentity.getPrincipal().toText());

    var ICP_ENDPOINT = 'http://localhost:8000';
    console.log('arge is ', argv.prod);
    if (argv.prod == 'true') {
        console.log('in prod');
        ICP_ENDPOINT = 'https://boundary.ic0.app';
    }

    const agent = getAgent();

    if (argv.prod != 'true') {
        agent.fetchRootKey();
    }

    console.log(agent);
    //const actorClass = ICAgent.Actor.createActorClass(did);

    console.log('canister id', Principal.fromText(NFT_ID));
    console.log('factory', idlFactory);
    const actor = ICAgent.Actor.createActor(idlFactory, {
        agent: agent,
        canisterId: Principal.fromText(NFT_ID),
    });

    console.log('the actor', actor);
    console.log(actor.stage_nft_origyn);

    // console.log(chunks);

    const thejson = fs.readFileSync(argv.meta);
    console.log('logging json');
    console.log(thejson);
    const data = JSON.parse(thejson);
    console.log('thejson', data);

    const iterateObj = (dupeObj) => {
        var retObj = new Object();
        if (typeof dupeObj == 'object') {
            if (typeof dupeObj.length == 'number') var retObj = new Array();

            for (var objInd in dupeObj) {
                if (dupeObj[objInd] == null) dupeObj[objInd] = 'Empty';
                if (typeof dupeObj[objInd] == 'object') {
                    retObj[objInd] = iterateObj(dupeObj[objInd]);
                } else if (typeof dupeObj[objInd] == 'string') {
                    if (objInd == 'Principal') {
                        retObj[objInd] = Principal.fromText(dupeObj[objInd]);
                    } else if (objInd == 'Nat') {
                        retObj[objInd] = BigInt(dupeObj[objInd]);
                    } else {
                        retObj[objInd] = dupeObj[objInd];
                    }
                } else if (typeof dupeObj[objInd] == 'number') {
                    retObj[objInd] = dupeObj[objInd];
                } else if (typeof dupeObj[objInd] == 'boolean') {
                    dupeObj[objInd] == true
                        ? (retObj[objInd] = true)
                        : (retObj[objInd] = false);
                }
            }
        }
        return retObj;
    };

    const data2 = iterateObj(data);

    let nft = null;

    const stageNft = async (data2) => {
        try {
            nft = await actor.stage_nft_origyn(data2.meta);
            return nft;
        } catch (e) {
            console.log(`There was an error while staging the nft:`);
            console.log(e);
            await new Promise((resolve) => setTimeout(resolve, 3000));
            return await stageNft(data2);
        }
    };
    nft = await stageNft(data2);

    console.log('the result of stage', nft);

    console.log('thelibrary', data.library);

    for (const this_item of data.library) {
        let library_id = this_item.library_id;
        const imageSource = this_item.library_file;
        //console.log(this_item);
        //if(imageSource.indexOf("social")>-1){
        const filedata = fs.readFileSync(imageSource);

        const SIZE_CHUNK = 2048000; // two megabytes
        //const SIZE_CHUNK = 128; // two megabytes

        const chunks = [];

        for (var i = 0; i < filedata.byteLength / SIZE_CHUNK; i++) {
            const startIndex = i * SIZE_CHUNK;
            chunks.push(filedata.slice(startIndex, startIndex + SIZE_CHUNK));
        }
        let results = [];

        const stageLibraryNft = async (content, token_id, i, library_id) => {
            try {
                const res = await actor.stage_library_nft_origyn({
                    content: content,
                    token_id: token_id,
                    chunk: i,
                    filedata: { Empty: null },
                    library_id: library_id,
                });
                return res;
            } catch (e) {
                console.log(
                    `There was an error while staging the nft library:`
                );
                console.log(e);
                await new Promise((resolve) => setTimeout(resolve, 3000));
                return await stageLibraryNft(content, token_id, i, library_id);
            }
        };
        for (let i = 0; i < chunks.length; i++) {
            const chnk = chunks[i];
            console.log('appending item ', i);
            const result = await stageLibraryNft(
                Array.from(chnk),
                argv.token_id.toString(),
                i,
                library_id
            );
            console.log(result);
        }
        //}
    }

    //Promise.allSettled(results).then( (resultList) =>{

    const mintNft = async (token_id, mint_target) => {
        try {
            const res = await actor.mint_nft_origyn(token_id, {
                principal: Principal.fromText(mint_target),
            });
            return res;
        } catch (e) {
            console.log(`There was an error while miting the nft:`);
            console.log(e);
            await new Promise((resolve) => setTimeout(resolve, 3000));
            return await mintNft(token_id, mint_target);
        }
    };
    if (argv.mint == 'true') {
        console.log('minting');
        let result = await mintNft(argv.token_id.toString(), argv.mint_target);
        console.log(result);
    }

    console.log('installed done.');
    process.exit(0);
    //});
})();
