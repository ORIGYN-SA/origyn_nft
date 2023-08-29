# Certified Assets

The Origyn NFT Reference now has the ability to certify assets.

### How to test

Follow these instructions to test your certified assets.

- Deploy the local BM project
- Navigate to the first BM experience page. For example `http://bkyz2-fmaaa-aaaaa-qaaaq-cai.localhost:4943/-/bm-0/ex`
- Open the Network console tab and make sure the `All` button is selected
- Refresh the page
- Click the `ex` file under the `Name` in the table shown
- Under the Response Headers you should see something like this:
```
Content-Length:
9555
Content-Type:
text/html
Date:
Tue, 29 Aug 2023 19:00:19 GMT
Ic-Certificate:
certificate=:2dn3omR0cmVlgwGDAYMBgwJIY2FuaXN0ZXKDAYIEWCB9s+9TOfMYZHmyrz7ms/AsBZSCQG0b+Eub12YCXGz59oMCSoAAAAAAEAABAQGDAYMBgwGDAk5jZXJ0aWZpZWRfZGF0YYIDWCDAmdr4extnAP7WAfNfXpJyS0KvA9LFBJqt/7TJNpnYk4IEWCCDxWvxTd49KN5mxpK1/J2X6d2YW2rXKw/m+E6KjfPcsoIEWCBpOUvnRK5BX/iYwbXMKc2D9jKQuPnuotkaMW2JqLY+JYIEWCB22l1gjHk0pGSig5qwHknmd7f18+M47bgycQP2TS+ceoIEWCARkVFz51RAZusosFQ9dCC2yan1g67hjJGGEK22GXJTv4IEWCBtPCRuEhlKa40ohBGI61NjnX9b5y2AMCL+JrfZ5c1PY4MBggRYIJSw9Qoz5ZxZNONfdlTJXcANEp1LNi8tmfDPz4lV0oHSgwJEdGltZYIDSbDYy5Df+Pu/F2lzaWduYXR1cmVYMKB0YfkqgedyNVYAYQbWpl07svGXDkDYpPTHWjpLrhl4Lg6CIAjRaKD7pYYWDdPWFg==:, tree=:2dn3gwJLaHR0cF9hc3NldHODAYMBgwGDAkovLS9ibS0wL2V4ggNYIDF+2qgymI81Vjvq5Pvk6dgA8GQHWNAwUAZwIXMzr7iYggRYIBBZ/ha/gkFAljf9b2uDq14hXyUdSWuGUSF3umxfP1T7ggRYILou9yYyiHAyx3BoA7xztuCXysHjWHmO5gWRqVWoTEpfggRYIDGuylcgATiYK1mFuij0t8yuLqjldohxHS8UKxUqCuZT:
```
- The Ic-Certificate means that the current page or asset has been certified by the IC.
- If you **right-click** the top image in the page and select **open in a new window** you can follow the same instructions above to see the certificate for that image. Note that instead of `ex` the asset should be `preview`
- You can do the same with the **hidden asset**. Here is the url for example : `http://bkyz2-fmaaa-aaaaa-qaaaq-cai.localhost:4943/-/bm-0/hidden`
- Here is a list of the dapps(assets) that also certified, follow the instructions above to see the certificate:
  - `/collection/-/ledger`
  - `/collection/-/vault`
  - `/collection/-/marketplace`
  - `/collection/-/data`
  - `/collection/-/dapp_library`