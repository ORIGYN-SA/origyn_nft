if [ -f "gittoken.key" ]
then
   token=$(head -n 1 gittoken.key)
else
   echo "Enter your github personal access token (will be used to fetch relaese of dApps):"
   read token
   echo $token >> "gittoken.key"
fi

owner="ORIGYN-SA"
repo="DApps"
tag="dapps-latest-build"
name="dist.zip"
downloaded_file_name="$tag.zip"
GH_API="https://api.github.com"
GH_REPO="$GH_API/repos/$owner/$repo"
GH_TAGS="$GH_REPO/releases/tags/$tag"
AUTH="Authorization: token $token"
WGET_ARGS="--content-disposition --auth-no-challenge --no-cookie"
CURL_ARGS="-LS"

curl -o /dev/null -sH "$AUTH" $GH_REPO || { echo "Error: Invalid repo, token or network issue!";  exit 1; }

response=$(curl -sH "$AUTH" $GH_TAGS)

eval $(echo "$response" | grep -C3 "name.:.\+$name" | grep -w id | tr : = | tr -cd '[[:alnum:]]=')
[ "$id" ] || { echo "Error: Failed to get asset id, response: $response" | awk 'length($0)<100' >&2; exit 1; }
GH_ASSET="$GH_REPO/releases/assets/$id"
echo $GH_ASSET

echo "Downloading asset..." >&2
curl $CURL_ARGS -H "Authorization: token $token" -H 'Accept: application/octet-stream' "$GH_ASSET" -o "$downloaded_file_name"
echo "$0 done." >&2

rm -rf $tag
unzip "$downloaded_file_name" -d "$tag"
python3 ./projects/bm/update_dapps_in_collection.py