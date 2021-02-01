## What is this?
This is an attempt to consolidate previous conversations on the topic of
transaction rebroadcast to make it easier for reviewers to understand the
context.

I've tried my best to accurately capture feedback and concerns, but please let
me know if anything feels misrepresented and I will update (or feel free to
propose a PR).

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

## bitcoin-core-dev IRC meeting on transaction rebroadcasting
On 07/25/2019, we discussed transaction rebroadcast as a [meeting
topic](http://www.erisian.com.au/bitcoin-core-dev/log-2019-07-25.html#l-389),
focused on an approach for moving the rebroadcast logic from the wallet to
the node. Here I will capture some of the highlights from that discussion.

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
  because wallet rebrodacast is still enabled by default, but is a big step
  towards being able to remove this.

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
  This lead to the ideation of a "ever broadcast" flag.

  This was implemented as the "unbroadcast" set in [PR #18038](https://github.com/bitcoin/bitcoin/pull/18038).
  Transactions submitted to the node via the wallet, gui or RPC are added to
  the unbroadcast set, then periodically announced to peers until a `GETDATA`
  is received.


## Conversation from #16698

## Other resources

but I don't recommend

via a write up in a
[gist](https://gist.github.com/amitiuttarwar/b592ee410e1f02ac0d44fcbed4621dba).
Please note that the gist is out-of-date, but some of the concepts are still
applicable.

pr review club

kanzure rebroadcast transcript