## What is this?
This is an attempt to consolidate previous conversations on the topic of
transaction rebroadcast to make it easier for reviewers to glean context.

I've tried my best to accurately capture feedback and concerns, but please let
me know if anything feels misrepresented and I will update (or feel free to
propose a PR). While this write up goes into significant depth, it is not
intended to be 100% comprehensive - that's what the logs are for :)

## FAQ
**Is the bandwidth increase acceptable?**

It is important to carefully evaluate bandwidth usage for these changes,
because this is where a problem could easily arise. For example, if a naive
implementation took the approach of frequently rebroadcasting every transaction
in the mempool, the increase in bandwidth usage would essentially be DDoSing
the network.

I believe the proposed changes will not have a significant impact on bandwidth.
We carefully select which transactions to rebroadcast based on several
different factors- they must be >30 minutes old, be at the top of the mempool
according to a fee-rate threshold based on dynamically calculated targets,
cannot have been already rebroadcast >6 times, cannot have been rebroadcast in
the past 4 hours. In addition to these rebroadcast specific conditions, the
selected transactions are subject to all the normal transaction relay logic-
`filterInventoryKnown` bloom filter that prevents us from relaying repeated
transactions to a peer, `INVENTORY_BROADCAST_MAX` logic that bounds how many
inv messages we send to a peer, etc.

However, we need to build confidence that the bandwidth usage is actually
acceptable, both under normal circumstances as well as in edge cases. I've
currently implemented the changes behind a config flag that defaults to off, so
we can observe the expected behavior under current network conditions. And I'm
seeking reviewer feedback to think through edge cases that could arise.

**What happens if a transaction can / will never be mined?**

There are a few circumstances where this could happen, some examples:
1. If there is a software upgrade that tightens policy, nodes with the old
   policy can see transactions that should be rebroadcast (high fee-rate &
   old), but are stuck in the mempool.

2. If an attacker targets the network by sending conflicting transactions to
   nodes that are close vs far from the miners. (example from gmaxwell
   [here](https://github.com/bitcoin/bitcoin/pull/16698#issuecomment-571399346))

3. If miners are censoring transactions - we cannot actually tell the
   difference between what would be "helpful" to rebroadcast VS what is being
   intentionally censored. In fact, empty blocks demonstrate a tiny hint of
   this behavior- there are valid transactions that a miner could confirm, but
   is choosing not to.

In these circumstances, we want to *avoid* 1. wasting lots of network bandwidth
and 2. preventing transactions from expiring from the majority of mempools on
the network. If there are transactions that will never be mined, the nodes who
would accept the transaction into their mempool could ping pong between each
other forever.

Technically, this is already possible- it only takes 1 node running custom
software to rebroadcast all transactions. However, we want to avoid having the
automatic rebroadcast behavior built into bitcoin core demonstrate these issues.

To address these cases, the current proposal has built a data structure
(`TxRebroadcastHandler.m_attempt_tracker`) that enforces a maximum number of
times a particular txid will be rebroadcast to peers. This limit will not last
forever since transaction ids do expire from the data structure, but it should
hopefully be pretty effective.

## bitcoin-core-dev IRC meeting
On 07/25/2019, we discussed transaction rebroadcast as a [meeting
topic](http://www.erisian.com.au/bitcoin-core-dev/log-2019-07-25.html#l-389),
focused on feedback around the approach to move the rebroadcast logic from the
wallet to the node. Here I will capture some of the highlights from that
discussion.

- A central design question is whether the bandwidth increase is acceptable.

  The bandwidth effect is designed to be small by constraining rebroadcast
  logic to old transactions at the top of the mempool.

- "Does this help with privacy? the first node broadcasting something will
  still be the same one"
  ([link](http://www.erisian.com.au/bitcoin-core-dev/log-2019-07-25.html#l-399)).

  These changes do not impact transaction _broadcast_- aka the first time a
  transaction gets announced to the network. However, they seek to improve the
  privacy around _rebroadcast_- aka any subsequent announcements to the
  network. The current proposal does not yet significantly improve privacy
  because wallet rebroadcast is still enabled by default, but the aim of the
  project is to eventually remove wallet rebroadcast.

- In addition to creating decoy transactions for wallet nodes to hide
  their transactions in, these changes could aid general transaction relay
  ([link](http://www.erisian.com.au/bitcoin-core-dev/log-2019-07-25.html#l-389)).

```
<wumpus> so basically all nodes would create noise for the nodes with a wallet to hide in, hmm
<sdaftuar> wumpus: i think it's more than that, it's way to ensure that things that should be mined get relayed, eg to nodes with small mempools or recently started up
<sdaftuar> sort of like a mempool-sync might do
<sipa> right, full nodes have an incentives themselves to see their mempools match what it actually mined
<sipa> even without wallets
<jnewbery_> if we consider the top of the mempool to be "transactions we expect to get mined soon" and they're not getting mined, rebroadcasting them to make sure miners are aware seems like sensible mempool logic
<jnewbery_> if not, then the mempool might as well expire them - they're doing our node no good
```

- We discussed the idea of a rebroadcast cap to ensure a node doesn't keep
  rebroadcasting the same transaction forever.

  This is implemented in the current proposal, see
  `TxRebroadcastHandler.m_attempt_tracker`.

- harding brought up a use case where users may rely on wallet rebroadcast
  logic to get a successful initial broadcast
  ([link](http://www.erisian.com.au/bitcoin-core-dev/log-2019-07-25.html#l-399)).
  This lead to the idea of a "ever broadcast" flag.

  This was implemented as the "unbroadcast" set in [PR #18038](https://github.com/bitcoin/bitcoin/pull/18038).
  Transactions submitted to the node via the wallet, gui or RPC are added to
  the unbroadcast set, then periodically announced to peers until a `GETDATA`
  is received.


## Conversation from #16698

Concept ACKs:
[jnewbery](https://github.com/bitcoin/bitcoin/pull/16698#issuecomment-524480853),
[MarcoFalke](https://github.com/bitcoin/bitcoin/pull/16698#pullrequestreview-279342223),
[laanwj](https://github.com/bitcoin/bitcoin/pull/16698#issuecomment-531756860),
[JeremyRubin](https://github.com/bitcoin/bitcoin/pull/16698#pullrequestreview-321309451),
[ariard](https://github.com/bitcoin/bitcoin/pull/16698#issuecomment-562912194),
[fjahr](https://github.com/bitcoin/bitcoin/pull/16698#issuecomment-569158954)

**mzumsande: "How can we answer the question of *what transactions should have
been mined* without looking into the contents of recent blocks?"
([link](https://github.com/bitcoin/bitcoin/pull/16698#issuecomment-525063430))**

Taken from [here](https://github.com/bitcoin/bitcoin/pull/16698#issuecomment-526321842):
We can't. And further, even if we do look at the recent blocks, we still
cannot answer exactly what "should" have been included. The two main pieces
of information we are missing are 1. what the miner's mempool looked like and
2. any weight applied through prioritisetransaction. By looking at a block,
it is difficult to extrapolate the exact minimum fee rate for transactions to
be included. So instead, the approach here is for a node to look at its local
mempool and work towards the picture of what it believes should have already
been included.

**Using the miner logic to identify rebroadcast candidates**

**JeremyRubin: "I don't quite like using the mining code as a dependency for
  figuring out what to rebroadcast"
  ([link](https://github.com/bitcoin/bitcoin/pull/16698#pullrequestreview-321309451))**

**fjahr: "I am not so happy with the changes in the miner code as they are not
  concerns of the miner."
  ([link](https://github.com/bitcoin/bitcoin/pull/16698#issuecomment-569158954))**

The current implementation still relies on the mining code to
calculate a dynamic minimum threshold fee for transactions, as well as
identifying the candidate set.

The comment from JeremyRubin is accurate that this would make it harder to
disable ancestor-scored mapTx for non-mining nodes. However, I am unaware of
work that is trying to do this, and do not understand the context that would
make this desirable. The node rebroadcast logic is currently hidden behind a
startup config flag, so if needed this could extend to disable rebroadcast for
nodes that want to remove this mapTx index. If I am mistaken in this
understanding, we should revisit this dependency.

The comment from fjahr seems to focus more on layer separation, and keeping
rebroadcast concerns separate from the mining code. The alternative approach
proposed is: "A block template would be requested from unchanged miner code and
then run through a series of filters that kick out rebroadcast candidates for
different reasons". In addition to this approach being more resource-heavy, the
issue would be managing package dependencies (eg. fee rate). Instead of
reinventing this logic, I think it makes more sense to tap into the existing
mechanisms in the miner code. More in-depth explanation in [this
comment](https://github.com/bitcoin/bitcoin/pull/16698#issuecomment-570838774).

**JeremyRubin: "Would this PR be better if we used a "thin blocks" style
relay?"
([link](https://github.com/bitcoin/bitcoin/pull/16698#pullrequestreview-321309451))**

Taken from
[here](https://github.com/bitcoin/bitcoin/pull/16698#issuecomment-570838774):
using compact-blocks relay code seems like a suggestion to address concerns
around bandwidth usage, which I believe can be addressed in simpler ways. to
use compact-blocks, we'd have to introduce a different P2P message to indicate
these are mempool transactions.

Taken from gmaxwell's response
[here](https://github.com/bitcoin/bitcoin/pull/16698#issuecomment-571399346):
Compact blocks would be entirely the wrong mechanism. The transactions are
unordered, unlike a block. And they are almost entirely known. The mechanism
you want is the erlay reconcillation mechanism because it uses bandwidth equal
to the size of the actual set difference, not the size of the mempool.

**gmaxwell on bandwidth ([link](https://github.com/bitcoin/bitcoin/pull/16698#issuecomment-571399346))**
```
[...] this change makes rebroadcasting apply to all mempool transactions. I think
that is conceptually a very good move but it has considerable implications.

Looking at your average bandwidth usage isn't enough, you have to worry about
cases like what if all nodes are running into their mempool limits under high
load-- will this change cause the network to start DOS attacking itself?

[...]

However, in practice it isn't that simple. While designing erlay we
specifically consider and discarded the approach of making it work by
synchronizing the mempools (which was how I approached the relay efficiency
problem in my original writeup). The reason for this is that difference in
mempool policy (standardness, minfees, maximum mempool sizes, ancestor depth
limits, softforks) or even just simple transaction ordering causes persistent
network-wide bandwidth leaks if you relay by syncing the mempool.

All these problems also apply here, because this is essentially a mempool
syncing proposal, but even worse because compared to the erlay reconciliation
this is an extremely inefficient way of syncing: it spends bandwidth for
transactions the peer already knows.

Consider an attacker that monitors the network and finds nodes close to miners.
Then he sends the near-miner nodes a bunch of very low feerate transactions
which won't get mined soon . He concurrently sends conflicting high feerate
transactions to every other node. The high feerate transactions don't get
mined, the other nodes have no idea why, and they bleed bandwidth continually
uselessly re-advertising transactions. (if the higher feerate txn gets mined by
accident he just tries again)

If erlay style relay is used, the bandwidth is really only wasted at the
low/high feerate boundary... but unfortunately the attacker can make that
boundary arbitrarily large (e.g. give half the nodes the low feerate txn in
additional to all the miner-proximal nodes).
```

I copy pasted the majority of this comment directly because it adeptly captures
some fundamental design questions and edge cases that should be evaluated in
regards to the current code proposal.

## Other resources

If you've managed to make it this far and you STILL want more to read, here are
some other resources for you. That said, I don't recommend reading them, you
should read the code instead :)

- [previous writeup](https://gist.github.com/amitiuttarwar/b592ee410e1f02ac0d44fcbed4621dba)
the gist is out-of-date, but some of the concepts are still applicable

- [pr review club](https://bitcoincore.reviews/16698)

- [transcript](https://diyhpl.us/wiki/transcripts/scalingbitcoin/tel-aviv-2019/edgedevplusplus/rebroadcasting/)
  of a talk I gave at dev++ in tel aviv
