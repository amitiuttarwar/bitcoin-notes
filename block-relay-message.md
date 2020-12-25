links:
[bip](https://github.com/sdaftuar/bips/blob/2020-09-negotiate-block-relay/bip-block-relay.mediawiki),
[pr](https://github.com/bitcoin/bitcoin/pull/20726)

# bip
### motivation:
- block-relay-only connections were introduced in #15759, they set transaction
  relay field to false to disable transaction relay & ignore addr messages
  received from the peer

- purpose of these connections is to strengthen against partition attacks.
  (1) additional low bandwidth connections to propagate blocks
  (2) obfuscating network topology

- the transaction relay field is not a permanent setting for the lifetime of
  the connection, so only the peer who initiates the connection knows that this
  connection will always require less resources.

- also, the peer receiving the connection does not know that the incoming
  connection will ignore relayed addresses

### specification:
- new `blockrelay` message is an empty message where `pchCommand == "blockrelay"`
- protocol version of nodes implementing this BIP must be 70018 or higher
- if a node sets the transaction relay field to false (in the version message),
  the `blockrelay` message MAY also be sent in response to a version message
- the `blockrelay` message MUST be sent before verack
- after a node has received a `blockrelay` message, it MUST NOT announce
  transactions to the peer (via INV or TX messages), or request transactions
  from the peer
- after a node has received a `blockrelay` message, it SHOULD NOT announce
  addresses to the peer
- after a node sends a `blockrelay` message to a peer, the node MUST NOT
  announce or request transactions from the peer.
- after a node sends a `blockrelay` message to a peer, the node SHOULD NOT
  request addresses from the peer

### questions
- if a node is sending a `blockrelay` message, does it have to set the
  transaction relay field (in the version message) to false? -> yes
- can a node send `blockrelay` message before version?
- could two nodes send each other `blockrelay` messages? would anything change?
- what about other cases where addr relay isn't desired? such as `-connect`

# pr 20726
**PR description:**
- adds new P2P message `BLOCKRELAY` to be sent between `VERSION` and `VERACK`
- use receipt of `BLOCKRELAY` message to stop relaying `ADDR` messages to
  inbound block-relay-only peers.

- future changes: save memory by not allocating peer data structures for
  transaction & address relay (`m_tx_relay` and `m_addr_known`)

### implementation
**commit 1:** Add `blockrelay` feature negotiation message support
- send the `blockrelay` message to outbound block-relay-only peers
- bumps the `PROTOCOL_VERSION` to `70018`
- adds the new protocol message to `protocol.{h, cpp}`
- in `ProcessMessage::VERSION`, if min version met & peer is an outbound
  block-relay-only peer, send the `BLOCKRELAY` message.
- in `ProcessMessage::BLOCKRELAY`, if we receive the message and
  `fSuccessfullyConnected` is already set (aka `VERACK` has been received),
  then disconnect the peer. otherwise, ignore.

**commit 2:** Add `inbound-block-relay` connection type
- adds new `ConnectionType::INBOUND_BLOCK_RELAY`
- `m_conn_type` is changed from a `const` to a `std::atomic`
- new function `CNode::UpdateConnectionType`, which is only enabled for
  converting `INBOUND` into `INBOUND_BLOCK_RELAY`

**commit 3:** Update connection type of peer after `blockrelay` message
- in `ProcessMessage::BLOCKRELAY`, add some checks & logic:
  - if node is an `OUTBOUND_FULL_RELAY` or `ADDR_FETCH`, and they send you a
    `BLOCKRELAY` message, then disconnect and find another peer
  - if node hasn't set `fRelayTxes` to false and sends you a `BLOCKRELAY`
    message, disconnect them
  - if it `IsInboundConn`, call `UpdateConnectionType` to update to
    `INBOUND_BLOCK_RELAY`. In the future -> this function will deallocate the
    tx relay and addr relay data structures.
  - review comment: suhas will improve the code to ensure we don't advertise
    addresses to {which?} peers, and ensure `BLOCKRELAY` peer doesn't send us
    other disallowed messages (mempool, filterload/add/clear, etc.)

**commit 4:** Test that inbound-block-relay peers don't get addrs

**todo:**
- double check send/process messages for different transaction & address
  relaying mechanisms
- think through testing

### questions
- why does the protocol version get bumped by 2? (70016 -> 70018)
- why is connection type now a `uint32_t`?

### feedback
- `INBOUND_BLOCK_RELAY` can be indicated as a subset of `INBOUND`
- `IsBlockOnlyConn` should either be updated to return both types, or the name
  changed.
- If we keep `INBOUND_BLOCK_RELAY` as a separate connection type, might be
  worth adding to the first assertion in `CConnman::OpenNetworkConnection`
- https://github.com/bitcoin/bitcoin/pull/20726#pullrequestreview-558732015


**commit 1 nits**
- `version.h#BLOCK_RELAY_VERSION` can be a `constexpr` instead of a `const`, as
  well as `protocol.h#BLOCKRELAY`
- `net_processing` checks `nVersion`, but the other similar checks look at
  `greatest_common_version`
- commit message: we ignore the blockrelay command unless its received after
  `VERACK`, then we disconnect
