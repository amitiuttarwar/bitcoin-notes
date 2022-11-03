## BIP 37: Connection Bloom filtering
- introduces 3 new messages: `filterload`, `filteradd` & `filterclear`
- filtered blocks can be served via the `merkeblock` message, which is
  essentially a block header + part of a merkle tree.
  - since `merkleblock` message contains only a list of tx hashes, txs that
    match the filter should be sent in separate tx messages after `merkleblock`
    is sent.
  - point of the `merkleblock` message is to allow clients to ensure the remote
    node is not feeding fake transactions.
- `version` command is extended with a new `fRelay` field. "If missing or true,
  no change in protocol behaviour occurs."
- `getdata` command is extended to allow `inv` in submessage. type field can be
  `MSG_FILTERED_BLOCK` rather than `MSG_BLOCK`. Request is ignored if a filter
  has not been set on the connection.

## BIP 111: `NODE_BLOOM` service bit
- service bit so peers can explicitly advertise that they support bloom filters
- bumps protocol version (70002 -> 70011) so peers can identify old nodes which
  allow bloom filtering connections without the new service bit
- `NODE_BLOOM = (1 << 2)` service bit. unset for those who don't support bloom
  filters.
- If a node does not support bloom filters but receives `filterload`,
  `filteradd`, or `filterclear`, it should disconnect that peer immediately.
  For backwards compatibility, nodes can choose to only disconnect nodes who
  attempt this with a new protocol version set.


## Mailing List conversation:
- (aj's comment on fRelay)[https://lists.linuxfoundation.org/pipermail/bitcoin-dev/2021-January/018347.html]
  - either set `m_tx_relay->fRelayTxes` to true via the `VERSION` message
    (either explicitly or by not setting `fRelay`), or you enable it later with
    `FILTERLOAD` or `FILTERCLEAR`, which cause disconnect if bloom filters are
    not supported.
  - Bloom filter support is (optionally?) indicated via a service bit (BIP
    111), so you can know if they are supported when you receive the `VERSION`
    message.

## Learnings
- `fRelay` is an optional part of the `VERSION` message

- nodes with protocol versions between 70000 & 70011 probably support bloom
  filtered connections without the `NODE_BLOOM` bit being set. but clients
  requiring bloom filtered connections should avoid making this assumption.
- bip 111 (bloom service bit) bumps protocol version from 70002 -> 70011
- current version 70016, bip 338 (`disabletx`) bumps to 70017

## Bitcoin Core
Do the service flags disable what is provided on the connection?

- `ServiceFlags` enum defined in `protocol.h`, defined `NODE_BLOOM` bit which
  indicates if the node supports bloom-filtered connections. According to the
  comment, Bitcoin Core does not support this by default as of 70011.

- `services` is a field on the `VERSION` message.
   - check that we currently disable the bit for bloom filters
   - what do we do if a peer sends us a `filter*` message?