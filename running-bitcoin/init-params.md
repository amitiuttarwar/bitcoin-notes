# Init Params / Startup Options

## Overview
To view the options: `bitcoind -help` & `bitcoind -help-debug`

You can implicitly negate arguments using `-no[arg]`. In the code, this is done by [AppInitMain](https://github.com/bitcoin/bitcoin/blob/ea5a50f92a6ff81b1d2dd67cdc3663e0e66733ac/src/bitcoind.cpp#L43),
which invokes
[ParseParameters](https://github.com/bitcoin/bitcoin/blob/ea5a50f92a6ff81b1d2dd67cdc3663e0e66733ac/src/util/system.cpp#L338)
which calls through to
[InterpretOption](https://github.com/bitcoin/bitcoin/blob/ea5a50f92a6ff81b1d2dd67cdc3663e0e66733ac/src/util/system.cpp#L209)
to handle the negation.

These are the set of options available to set in the `bitcoin.conf` file.

If a value is set in `bitcoin.conf` & you also pass it in through cli, the cli
one will overwrite the `.conf` param.

## Connecting to Peers
#### `-dnsseed`:
  * Used primarily to determine whether to initiate
  `ThreadDNSAddressSeed` which potentially queries the DNS seeds for addr
  records.
  * Defaults to `true` in bitcoind, `false` in functional tests
  * `ThreadOpenConnections` uses this value to decide whether to add fixed seeds.
  * If true, `CConnman::Start` initiates `ThreadDNSAddressSeed`.
  * Parameter interaction: when `-connect` set, `-dnsseed` defaults to false.

#### `-forcednsseed`:
  * Defaults to `false` in bitcoind.
  * When true, `ThreadDNSAddressSeed` will query DNS seeds even if we have
    a populated addrman || have succesfully connected to 2 or more peers.

#### `-connect`:
(props to @mzumsande)

takeaways:
  * `-connect=xxx` says "connect only to the specified node". it disables
    automatic connections, dns seeding, and sets `-listen` to false. addresses passed in are forwarded to `ThreadOpenConnections` and the node does not use addrman for additional connections.
  * `-noconnect` and `-connect=0` both disable automatic connections entirely. They also disable dns seeding and set `-listen` to false.

    -> `-connect=0` is [special
    cased](https://github.com/bitcoin/bitcoin/blob/a8c8dbc98fa9acd653f6eff5d82c41c384dd2864/src/init.cpp#L1751)
    to disable `ThreadOpenConnections`.

    -> `-noconnect` gets interpreted as `-connect=false`
  * `-connect` without a parameter & `-noconnect=0` behave unexpectedly

unexpected behaviors:
  * `-connect` without an argument will try to connect to an empty string
  * passing `-noconnect=0` gives a warning about the double negative, but
    doesn't prevent the node from starting up. this gets turned  into
    `-connect=1` and the node tries to connect to a peer with the ip `1`.

## Modes of operation
#### `-blocksonly`:
* Help docs: Whether to reject transactions from network peers. Automatic
broadcast and rebroadcast of any transactions from inbound peers is disabled,
unless the peer has the 'forcerelay' permission. RPC transactions are not
affected. Defaults off.
* Parameter interactions: `-whitelistrelay`. If `blocksonly` is enabled,
`whitelistrelay` gets disabled.
* blocksonly mode doesn't initialize `node.fee_estimator`
* blocksonly mode skips `MaybeSetPeerAsAnnouncingHeaderAndIDs` -> don't request
  high-bandwidth mode from peers. the mempool doesn't have txns to reconstruct
  compact blocks
* skip general compact block functionalities
* when processing the `VERSION` message, will not send `SENDTXRCNCL` message ->
  erlay
* will not send `FEEFILTER` message
* value can be seen on `getnetworkinfo` in the field `localrelay`
* the `VERSION` message has a `relay` bool to communicate to your peers whether
  or not to send transactions
* relay bool in `VERSION` message has interactions with `filterload` and
  `filterclear` -> BIP37
* we disconnect peers that send p2p messages: `SENDTXRCNCL`, `TX`, `INV` for a
  tx unless it has 'relay' permissions set
* interaction with relay permissions -> peers with the relay or forcerelay flag
  set can still send transactions
* you can set these permissions using `-whitelistforcerelay` and
  `-whitelistrelay` init params
* still participates in `ADDR` relay, also can send out `TX` messages. but
  that's a significant privacy leak.
* advantage is lower bandwidth usage

* Q: Is there no way to set relay/forcerelay params via RPC?
* Q: How much space does the mempool take in blocksonly mode, vs normal?
