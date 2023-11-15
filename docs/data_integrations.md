# ORIGYN NFT Data Integration v0.2

Note: For full details of any of the apis in this document, please see [nft-current-api.md](nft-current-api.md).

## Summary

The ORIGYN NFT comes with a permissioned database inside it. This database is currently very simple and allows developers to write a document object model in CandyShared syntax to a particular "Data Dapp" namespace.

Each Data Dapp can have its own permission set such that other users can be sure of hte provenance of a particular data page and be assured that only certain cryptographically secure accounts can update the data.

## Data Pages

Each data page lives as a vector entry in the __apps section of an NFT's metadata.  The format of a data page takes the following format:

```
let new_data = #Class([
  {name = "app_id"; value=#Text("com.test.__public"); immutable= true},
  {name = "read"; value=#Text("public");immutable=false;},
  {name = "write"; value=#Class([
      {name = "type"; value=#Text("allow"); immutable= false},
      {name = "list"; value=#Array([#Principal("4ecnw-byqwz-dtgss-ua2mh-pfvs7-c3lct-gtf4e-hnu75-j7eek-iifqm-sqe")]);
      immutable=false;}]);
    immutable=false;},
  {name = "permissions"; value=#Class([
      {name = "type"; value=#Text("allow"); immutable= false},
      {name = "list"; value=#Array([#Principal("4ecnw-byqwz-dtgss-ua2mh-pfvs7-c3lct-gtf4e-hnu75-j7eek-iifqm-sqe")]);
    immutable=false;}]);
  immutable=false;},
  {name = "data"; value=#Class([
      {name = "val1"; value=#Text("val1-modified"); immutable= false},
      {name = "val2"; value=#Text("val2-modified"); immutable= false},
      {name = "val3"; value=#Class([
          {name = "data"; value=#Text("val3-modified"); immutable= false},
          {name = "read"; value=#Text("public");
          immutable=false;},
          {name = "write"; value=#Class([
              {name = "type"; value=#Text("allow"); immutable= false},
              {name = "list"; value=#Array([#Principal(Principal.fromActor(this))]);
              immutable=false;}]);
          immutable=false;}]);
      immutable=false;},
      {name = "val4"; value=#Class([
          {name = "data"; value=#Text("val4-modified"); immutable= false},
          {name = "read"; value=#Class([
              {name = "type"; value=#Text("allow"); immutable= false},
              {name = "list"; value=#Array([#Principal(Principal.fromActor(this))]);
              immutable=false;}]);
          immutable=false;},
          {name = "write"; value=#Class([
              {name = "type"; value=#Text("allow"); immutable= false},
              {name = "list"; value=#Array([#Principal(Principal.fromActor(this))]);
              immutable=false;}]);
          immutable=false;}]);
      immutable=false;}]);
  immutable=false;}
  ]);
```

This data page has the following components:

### App ID

```
   {name = "app_id"; value=#Text("com.test.__public"); immutable= true},
```

We encourage developers to pick a namespace that they will be able to prove they have rights to later.  This is currently not restricted, but we expect to have a registry in the future that registers namespaces to particular parties to ensure exclusive configuration, schema versions, and consistent handling.

### Read Permissions

```
{name = "read"; value=#Text("public");immutable=false;},
```
You can restrict if data shows up in public queries by using the read permissions. 

Possible values:

- #Text("public") is the default open read value.
- #Text("nft_owner") means that only the owner of the NFT can read the data.
- Class([
      {name = "type"; value=#Text("allow"); immutable= false},
      {name = "list"; value=#Array([#Principal("4ecnw-byqwz-dtgss-ua2mh-pfvs7-c3lct-gtf4e-hnu75-j7eek-iifqm-sqe")]);
    immutable=false;}]); - Limits the read permission to the principals in the list 

These permissions cascade to classes within the data object such that different nodes of the data can have different read permissions.

### Write Permissions

```
{name = "write"; value=#Class([
      {name = "type"; value=#Text("allow"); immutable= false},
      {name = "list"; value=#Array([#Principal("4ecnw-byqwz-dtgss-ua2mh-pfvs7-c3lct-gtf4e-hnu75-j7eek-iifqm-sqe")]);
      immutable=false;}]);
    immutable=false;}
```
You can restrict if data shows up in public queries by using the read permissions. 

Trap values:

- #Text("public") is not allowed because it could allow spamming of the platform.

Possible values:

- #Text("nft_owner") means that only the owner of the NFT can write to the data page.
- #Text("collection_owner") means that only the owner of the NFT collection can write to the data page.
- Class([
      {name = "type"; value=#Text("allow"); immutable= false},
      {name = "list"; value=#Array([#Principal("4ecnw-byqwz-dtgss-ua2mh-pfvs7-c3lct-gtf4e-hnu75-j7eek-iifqm-sqe")]);
    immutable=false;}]); - Limits the read permission to the principals in the list 

### Permission Permissions

```
{name = "permissions"; value=#Class([
      {name = "type"; value=#Text("allow"); immutable= false},
      {name = "list"; value=#Array([#Principal("4ecnw-byqwz-dtgss-ua2mh-pfvs7-c3lct-gtf4e-hnu75-j7eek-iifqm-sqe")]);
    immutable=false;}]);
  immutable=false;}
```

This permission will eventually be able to restrict who can update the permissions on an atomic basis. Currently this must be set, but is not yet effective.

Trap values:

- #Text("public") is not allowed because it could allow spamming of the platform.

Possible values:

- #Text("nft_owner") means that only the owner of the NFT can write to the data page.
- #Text("collection_owner") means that only the owner of the NFT collection can write to the data page.
- Class([
      {name = "type"; value=#Text("allow"); immutable= false},
      {name = "list"; value=#Array([#Principal("4ecnw-byqwz-dtgss-ua2mh-pfvs7-c3lct-gtf4e-hnu75-j7eek-iifqm-sqe")]);
    immutable=false;}]); - Limits the read permission to the principals in the list 

### Data


```
{name = "data"; value=#Class([
      {name = "val1"; value=#Text("val1-modified"); immutable= false},
      {name = "val2"; value=#Text("val2-modified"); immutable= false},
      {name = "val3"; value=#Class([
          {name = "data"; value=#Text("val3-modified"); immutable= false},
          {name = "read"; value=#Text("public");
          immutable=false;},
          {name = "write"; value=#Class([
              {name = "type"; value=#Text("allow"); immutable= false},
              {name = "list"; value=#Array([#Principal(Principal.fromActor(this))]);
              immutable=false;}]);
          immutable=false;}]);
      immutable=false;},
      {name = "val4"; value=#Class([
          {name = "data"; value=#Text("val4-modified"); immutable= false},
          {name = "read"; value=#Class([
              {name = "type"; value=#Text("allow"); immutable= false},
              {name = "list"; value=#Array([#Principal(Principal.fromActor(this))]);
              immutable=false;}]);
          immutable=false;},
          {name = "write"; value=#Class([
              {name = "type"; value=#Text("allow"); immutable= false},
              {name = "list"; value=#Array([#Principal(Principal.fromActor(this))]);
              immutable=false;}]);
          immutable=false;}]);
      immutable=false;}]);
  immutable=false;}
```

The data component is a CandyShared object.  If you set immutable = true at the top layer then the item cannot be updated even if a user has write permissions.

## Updating data dapps

Data pages are updated by calling the NFT canister's update_app_nft_origyn method that has the following signature:

```
public type NFTUpdateRequest = {
        #replace : {
            token_id : Text;
            data : CandyTypes.CandyShared;
        };
        #update : {
            token_id : Text;
            app_id : Text;
            update : CandyTypes.UpdateRequestShared;

        };
    };

public type NFTUpdateResponse = Bool;

update_app_nft_origyn : shared NFTUpdateRequest -> async NFTUpdateResult;
```

Currently only the #replace variant is supported.  If the function is succesful the entire data page is replaced with the provided data object.  This data object needs to replace all the read, write, and permission settings as well.

In the future, atomic updates will be allowed.