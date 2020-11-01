# Addrman learnings

### classes & their member vars
- `CNetAddr` - raw info of a network address
  - `m_addr` - raw representation (network byte order) of the network address
  - `m_net` - enum value of which network

- `CService` - inherits from `CNetAddr` (network address) and supplements with
  TCP port (member var `port`)
  - why is it a separate class from `CNetAddr`?
    - we ban addresses based on IP, ignoring the specific port, so if you want
      to ban you don't want to have a dummy port.
    - having different types allows for more compiler enforcement (eg. if you
      required a port for a particular function, you'd want to check that it
      was provided and not some random default value)
    - regtest runs multiple bitcoind nodes on the same server, with different
      ports
  - why is it called `CService`?
    - networking convention: [SRV record](https://en.wikipedia.org/wiki/SRV_record).
    A Service record (SRV record) is how DNS keeps record of the location
    (hostname and port number)

- `CAddress` - represents the addr message, which is why its in `protocol.h`.
  inherits from `CService` and adds `nServices` and `nTime`.

- `CAddrInfo` - inherits from `CAddress` with extra application level info
  about this address as a (potential) peer.
    - `nLastTry`
    - `nLastCountAttempt`
    - `source` - what `CNetAddr` told us about this address?
    - `nLastSuccess` - last successful connection by us
    - `nAttempts` - # of attempts since last successful
    - `nRefCount`
    - `fInTried` - in tried set?
    - `nRandomPos` - position in `vRandom`

- `CAddrMan`
  - `nIdCount` - last used node id: keeps track to assign new ids
  - `mapAddr` is a map from `CNetAddr` -> node id
  - `mapInfo` is a map from node id -> `CAddrInfo`
  - `vRandom` - randomly ordered vector of all node ids
  - `nTried` - number of tried entries
  - `vvTried` - tried buckets, 2D array based on bucket count & bucket size
  - `nNew` - number of new entries
  - `vvNew` - new buckets, 2D array based on bucket count & bucket size
  - `nLastGood` - last time Good was called, used to compare to the last
    `nLastCountAttempt` on the `CService`
  - `m_tried_collisions` - holds the address collisions from tried table so
    test-before-evict can resolve

### useful functions
- `PeerManager::FinalizeNode`

- `CAddrMan::Connected` - looks up the `CService` object to retrieve
  `CAddrInfo` and update the `ntime``
  - call graph: `Connected` <- `FinalizeNode` <- `DeleteNode` <-
    `DisconnectNodes` and `StopNodes`

- `CAddrMan::Find` - looks up the `CNetAddr` in `mapAddr` to get the node id,
  then looks it up in `mapInfo` to return the `CAddrInfo`.

- `CAddrMan::Good_`
  - gets the `CAddrInfo` of the `CService` object
	- updates `nLastSuccess`, `nLastTry`, `nAttempts`
	- does NOT update `ntime`
