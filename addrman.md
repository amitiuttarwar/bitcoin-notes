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
  - `nTime` - used in `IsTerrible` decisions & serialized into addr messages
    - updated in `CAddrMan::Connected` when we disconnect or stop the nodes
    - updated in `net.cpp#convertSeed6` for seed nodes to a random time between
      1-2 weeks ago
    - updated in `net.cpp#GetLocalAddress` to be the time called
    - read in `ConnectNode` for debug printing
    - NOT read in `CConnman::InactivityCheck`
    - NOT updated in `CAddrMan::Good`
    - updated in `ThreadDNSAddressSeed` when loading DNS seed addresses
    - when processing an `ADDR` message, if the `nTime` is < 100000000, or more
      than 10 mins in the future, we reset it to be 5 days ago.
    - when processing an `ADDR` message, we then use `nTime` being less than 10
      mins ago to decide whether we relay this address to other nodes
    - we return it in the RPC `getnodeaddresses.time`
    - in the RPC `addpeeraddress`, we set `nTime` to be now
    - use it to decide if an address `IsTerrible` if its more than 10 min in
      the future, or if its more than 30 days old
    - periodically updated in `CAddrMan::Add_`
    - updated in `Connected_`

  - serialization of a `CAddress` in regards to `nTime`
    - according to comments in `CAddress` serialization, only time we serialize a
      `CAddress` object without `nTime` is in the initial `VERSION` messages (2
      `CAddress` records: from and to.)
    - we look at the `nVersion` (serialization version) to decide whether or not
      we serialize with `nTime`. This is set when processing the `VERSION`
      message from the peer.

  Q: so, we populate `nTime` when we self-advertise? with what?
  -> oh, maybe we don't use this serialization method when self-advertising

- `CAddrInfo` - inherits from `CAddress` with extra application level info
  about this address as a (potential) peer.
    - `nLastTry`
      - updated in `Good_` and `Attempt_`
      - read from in `ThreadOpenConnections` to not try recently tried nodes until
        we have at least 30 failed attempts
      - read from in `IsTerrible`
      - read from in `GetChance` to deprioritize recent attempts
    - `nLastCountAttempt`
    - `source` - what `CNetAddr` told us about this address?
    - `nLastSuccess` - last successful connection by us
      - updated in `Good_`
      - serialized into `peers.dat`
      - read from in `IsTerrible`
      - read from in `ResolveCollisions_`
    - `nAttempts` - # of attempts since last successful
      - serialized into `peers.dat`
      - read from in `IsTerrible`
      - read from in `GetChance` to deprioritize based on failed attempts
      - zeroed out in `Good_`
      - incremented in `Attempt_`
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
  `CAddrInfo` and update the `ntime`
  - call graph: `Connected` <- `FinalizeNode` <- `DeleteNode` <-
    `DisconnectNodes` and `StopNodes`
  - the header comment is misleading, says "Mark an entry as currently-connected-to."
    but really we only call on disconnecting.

- `CAddrMan::Find` - looks up the `CNetAddr` in `mapAddr` to get the node id,
  then looks it up in `mapInfo` to return the `CAddrInfo`.

- `CAddrMan::Good_`
  - gets the `CAddrInfo` of the `CService` object
	- updates `nLastSuccess`, `nLastTry`, `nAttempts`
	- does NOT update `ntime`
	- moves address from new to tried table
	- check & store any tried table collisions

  - call graph: when processing the `VERSION` message,
    `PeerManager::ProcessMessage` will invoke `CConnman::MarkAddressGood` for
    any outbound address. the `CConnman` function simply forwards the call
    along to `CAddrMan::Good`


- `CAddrman::Attempt_`
  - takes in a `CService` object, looks up the associated `CAddrInfo` object.
    If found, updates `nLastTry`.
  - If the info's `nLastCountAttempt` was before the last time `Good` was
    called (stored on `CAddrMan.nLastGood`), update the `nLastCountAttempt`
    to now, and increment the `nAttempts` counter.

- `CAddrman::IsTerrible`: returns a bool based on usefulness of address
  - if address was tried in in the last minute (`nLastTry`), return false
  - if the `nTime` is more than 10 mins in the future, return true
  - if the `nTime` has been set, but is more than 30 days old, return true
  - if we've tried >3 times (`nAttempts`), but never had a success
    (`nLastSuccess` is still 0), return true
  - if we haven't had a success in 1 week & have attempted more than 10 times,
    return true
  - if none of these conditions match, return false

- `CAddrMan::Select`
  - takes in a boolean that defaults to false called `newOnly`
  - chooses an address to connect to
  - if `newOnly` is true, it chooses a node from the new table
  - otherwise, it has a 50% chance for choosing between new and tried table


### Serialization
- `CAddrInfo` uses the #define `SERIALIZE_METHODS`, and is serialized into
  `peers.dat`. The definition says first (un)serialize the `CAddress` part of
  the object, then (un)serialize the additional fields (`source`,
  `nLastSuccess`, `nAttempts`).
- `CAddrMan` doesn't used `SERIALIZE_METHODS`, but rather defines its own
  serialization & deserialization functions.
