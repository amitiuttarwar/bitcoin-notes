# Init Params

## Connecting to Peers
`-dnsseed`: Used primarily to determine whether to initiate
  `ThreadDNSAddressSeed` which potentially queries the DNS seeds for addr
  records.
  * Defaults to `true` in bitcoind, `false` in functional tests
  * `ThreadOpenConnections` uses this value to decide whether to add fixed seeds.
  * If true, `CConnman::Start` initiates `ThreadDNSAddressSeed`.
  * Parameter interaction: when `-connect` set, `-dnsseed` defaults to false.

`-forcednsseed`:
  * Defaults to `false` in bitcoind.
  * When true, `ThreadDNSAddressSeed` will query DNS seeds even if we have
    a populated addrman || have succesfully connected to 2 or more peers.

`-connect`:
(thanks to @mzumsande for helping me understand)
takeaways:
  * `-connect=xxx` says "connect only to the specified node". it disables
    automatic connections, dns seeding, and sets `-listen` to false.
  * `-noconnect` and `-connect=0` both disable automatic connections entirely,
    also disabling dns seeding and setting `-listen` to false.
  * `-connect` & `-noconnect=0` behave unexpectedly

explanations:
  * `-connect=xxx` is used to pass in addresses to connect to. addresses passed
    in are forwarded to `ThreadOpenConnections`, and the node does not make
    connections using the addrman
  * param interactions: disables `-listen` and `-dnsseed`
  * `-connect=0` is (special
    cased)[https://github.com/bitcoin/bitcoin/blob/a8c8dbc98fa9acd653f6eff5d82c41c384dd2864/src/init.cpp#L1751]
    to disable `ThreadOpenConnections`. still upholds the parameter
    interactions
  * `-noconnect` sets `-connect=false`, disabling automatic connections. has
    the same parameter interactions and disables `-listen` & `-dnsseed`

unexpected behaviors:
  * `-connect` without an argument will try to connect to an empty string
  * passing `-noconnect=0` gives a warning about the double negative, but
    doesn't prevent the node from starting up. this gets turned  into
    `-connect=1` and the node tries to connect to a peer with the ip `1`.
