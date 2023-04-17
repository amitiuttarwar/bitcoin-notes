## Eviction logic

`ThreadSocketHandler` accepts new connections, sends & receives data from
sockets & services nodes marked for disconnection.

- functions: `DisconnectNodes`, `SocketHandler`, `DeleteNode`,
  `AcceptConnection`, `CreateNodeFromAcceptedSocket`, `InitializeNode`
- keywords: eviction, disconnect, `fDisconnect`

<img src="/images/thread-socket-handler.jpg" align="middle"></img>

The next diagram is an overview of eviction logic in bitcoin core. There are
many places where peers are marked for disconnect that are not captured in this
diagram, such as when outbound peers are not providing us up to date chain
information. Instead of disconnecting based on the specific actions of the
peers, eviction refers to the logic that may disconnect based on the attributes
of the full set of peers we are connected to.

The eviction of inbound vs outbound peers are considered completely separately,
and weigh attributes differently. Outbound peers are highly valued for timely
block announcements. Inbound peers are weighed for diversity, trying to prevent
an attacker from trivially overtaking all the available slots. Inbound
diversity looks at net groups, ping time, relaying novel mempool transactions,
relaying novel blocks, and duration of connection.

- functions: `CheckForStaleTipAndEvictPeers`, `EvictExtraOutboundPeers`,
  `AcceptConnection`, `AttemptToEvictConnection`, `SelectNodeToEvict`,

<img src="/images/eviction-overview.jpg" align="middle"></img>

Color scheme:
<img src="/images/eviction-color-key.jpg" align="middle"></img>
