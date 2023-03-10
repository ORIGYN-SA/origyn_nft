import json
import hashlib
import os

dapps_folder="./dapps-latest-build/dist/"
dapps = [
    {
        "file_name": "vault.html",
        "key_size": "dapp_wallet_size",
        "key_hash": "dapp_wallet_hash",
    },
    {
        "file_name": "marketplace.html",
        "key_size": "dapp_marketplace_size",
        "key_hash": "dapp_marketplace_hash",
    },
    {
        "file_name": "ledger.html",
        "key_size": "dapp_ledger_size",
        "key_hash": "dapp_ledger_hash",
    },
    {
        "file_name": "library.html",
        "key_size": "dapp_library_size",
        "key_hash": "dapp_library_hash",
    },
    {
        "file_name": "data.html",
        "key_size": "dapp_nftdata_size",
        "key_hash": "dapp_nftdata_hash",
    },
]
def sha256(fname):
    sha256_hash = hashlib.sha256()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha256_hash.update(chunk)
    return sha256_hash.hexdigest()

file = open("./projects/bm/def_collection.json")
def_collection = file.read()
file.seek(0)

json_dump = json.dumps(def_collection)
for dapp in dapps:
    file_size = os.stat(dapps_folder + dapp["file_name"]).st_size
    file_hash = sha256(dapps_folder + dapp["file_name"])
    json_dump = json_dump.replace(dapp["key_size"], str(file_size))
    json_dump = json_dump.replace(dapp["key_hash"], file_hash)

new_file = open("./projects/bm/def_collection_build.json", "w+")
new_file.write(json.loads(json_dump))