# DNS seeds

## Init params
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
  * `-connect=xxx` is used to pass in addresses to connect to
  * addresses passed in are forwarded to `ThreadOpenConnections`, and the node
    does not make connections using the addrman
  * param interactions: disables `-listen` and `-dnsseed`
  * `-connect=0` is [special
    cased](https://github.com/bitcoin/bitcoin/blob/master/src/init.cpp#L1755)
    to not disable `ThreadOpenConnections`. still upholds the parameter
    interactions
  * `-connect` without an argument will try to connect to an empty string
  * `-noconnect` sets `-connect=false`

  Q: does this have any parameter interaction with `-dnsseed`?
  * passing `-noconnect=0` gives a warning about the double negative, but
    doesn't prevent the node from starting up. the parameter parsing turns this
    into `-connect=1` and the node tries to connect to a peer with the ip `1`.
