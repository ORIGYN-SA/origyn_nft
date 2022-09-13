let aviate_labs = https://github.com/aviate-labs/package-set/releases/download/v0.1.3/package-set.dhall sha256:ca68dad1e4a68319d44c587f505176963615d533b8ac98bdb534f37d1d6a5b47

let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.21-20220215/package-set.dhall sha256:b46f30e811fe5085741be01e126629c2a55d4c3d6ebf49408fb3b4a98e37589b

let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }


let additions =
    [
   { name = "candy_0_1_10"
    , repo = "https://github.com/aramakme/candy_library.git"
    , version = "v0.1.10"
    , dependencies = ["base"]
   },
   {
       name="principalmo",
       repo = "https://github.com/aviate-labs/principal.mo.git",
       version = "v0.2.5",
       dependencies = ["base"]
   },
   { name = "crypto"
    , repo = "https://github.com/aviate-labs/crypto.mo"
    , version = "v0.2.0"
    , dependencies = [ "base", "encoding" ]
  },
   { name = "encoding"
  , repo = "https://github.com/aviate-labs/encoding.mo"
  , version = "v0.3.2"
  , dependencies = [ "array", "base" ]
  },
  { name = "array"
  , repo = "https://github.com/aviate-labs/array.mo"
  , version = "v0.2.0"
  , dependencies = [ "base" ]
  },
  { name = "hash"
  , repo = "https://github.com/aviate-labs/hash.mo"
  , version = "v0.1.0"
  , dependencies = [ "array", "base" ]
  },
  {
    name = "ext",
    repo = "https://github.com/skilesare/extendable-token",
    version = "v0.1.0",
    dependencies = ["ext"]
},
{
    name = "httpparser",     
    repo = "https://github.com/skilesare/http-parser.mo",
    version = "v0.1.0",
    dependencies = ["base"]
},
{ name = "http"
  , repo = "https://github.com/aviate-labs/http.mo"
  , version = "v0.1.0"
  , dependencies = [ "base" ]
  },
  { name = "format"
  , repo = "https://github.com/skilesare/format.mo"
  , version = "v0.1.0"
  , dependencies = [ "base" ]
  },
  { name = "json"
  , repo = "https://github.com/aviate-labs/json.mo"
  , version = "v0.1.0"
  , dependencies = [ "base", "parser-combinators" ]
  },
  { name = "stablerbtree_0_6_1"
  , repo = "https://github.com/skilesare/StableRBTree"
  , version = "v0.6.1"
  , dependencies = [ "base"]
  },
  { name = "stablebuffer_0_2_0"
  , repo = "https://github.com/skilesare/StableBuffer"
  , version = "v0.2.0"
  , dependencies = [ "base"]
  },
  { name = "stablebuffer"
  , repo = "https://github.com/skilesare/StableBuffer"
  , version = "v0.2.0"
  , dependencies = [ "base"]
  },
  { name = "map_6_0_0"
  , repo = "https://github.com/ZhenyaUsenko/motoko-hash-map"
  , version = "v6.0.0"
  , dependencies = [ "base"]
  },
  { name = "map"
  , repo = "https://github.com/ZhenyaUsenko/motoko-hash-map"
  , version = "v6.0.0"
  , dependencies = [ "base"]
  }] : List Package
let
  {- This is where you can override existing packages in the package-set

     For example, if you wanted to use version `v2.0.0` of the foo library:
     let overrides = [
         { name = "foo"
         , version = "v2.0.0"
         , repo = "https://github.com/bar/foo"
         , dependencies = [] : List Text
         }
     ]
  -}
  overrides =
    [] : List Package

in  aviate_labs # upstream # additions # overrides
