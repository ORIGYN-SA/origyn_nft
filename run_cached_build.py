#!/usr/bin/python
'''
Pipeline:
1. Inspect dfx.json and load mapping of canisters and main files
2. for each canister, if any timestamp of used source file and its imports  > timestamp of canister wasm.gz -> rebuild canister
4. otherwise, pass and re-use
'''
import os
import subprocess
import json
import os
import datetime
import glob


ROOT_DIR = os.path.abspath(os.getcwd())


def run_cached_build():
    canister_map = json.load(open('dfx.json'))
    for name in canister_map['canisters']:
        if canister_map['canisters'][name]['type'] == 'motoko':
            print(f"canister {name}:")
            processed_files = set()

            # get canister wasm modification timestamp
            try:
                wasm_file = os.path.join(ROOT_DIR, f'.dfx/local/canisters/{name}/{name}.wasm.gz')
                m_time = os.path.getmtime(wasm_file)
                canister_md_time = datetime.datetime.fromtimestamp(m_time)
            except FileNotFoundError as e:
                print(f"Wasm was not found, trying to build..")
                subprocess.call(f"dfx canister create {name}", shell=True)
                subprocess.call(f"dfx build {name}", shell=True)
                subprocess.call(f"gzip ./.dfx/local/canisters/{name}/{name}.wasm -f", shell=True)
                continue

            
            # inspect source file imports and compare timestamps with canister wasm
            main_file = os.path.join(ROOT_DIR, canister_map['canisters'][name]['main'])
            subimports_q = [main_file]
            cached = True

            # BFS with queue
            while len(subimports_q) > 0:
                # print(f'queue: {subimports_q}')
                filename = subimports_q.pop()
                m_time = os.path.getmtime(filename)
                dt_m = datetime.datetime.fromtimestamp(m_time)
                
                if dt_m > canister_md_time:
                    print(f'source file {filename} was changed; rebuilding..')
                    subprocess.call(f"dfx build {name}", shell=True)
                    subprocess.call(f"gzip ./.dfx/local/canisters/{name}/{name}.wasm -f", shell=True)
                    cached = False
                    break

                dirname = filename.split('/')[-2]
                # load imports from file and add to dependency_tree
                with open(filename, 'r') as fin:
                    lines = fin.readlines()[:100]
                for l in lines:
                    if l.startswith('import'):
                        subimport = l.split(" ")[-1].strip("./\"\;\n")
                        subimport += ".mo"
                        importfile = glob.glob(f"**/{dirname}/{subimport}", recursive=True)
                        if len(importfile) == 0:
                            continue
                        assert len(importfile) == 1
                        importfile = importfile[0]
                        if importfile not in processed_files:
                            subimports_q.append(importfile)
                            processed_files.add(importfile)
            if cached:
                print("cached build reuse")


if __name__ == "__main__":
    run_cached_build()