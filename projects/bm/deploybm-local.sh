set -ex
env_network='local'
env_prod='false'
env_name='origyn_nft_reference'
env_name_sale='origyn_sale_reference'
export env_network
export env_prod
export env_name
export env_name_sale
# bash ./projects/bm/deploybm.sh
bash ./projects/bm/deploybm-fm.sh