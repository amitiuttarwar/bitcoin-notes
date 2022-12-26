## on master

### relevant classes & variables
`net.h`:
```
using mapMsgTypeSize = std::map</* message type */ std::string, /* total bytes */ uint64_t>;

class CNodeStats
{
    uint64_t nSendBytes;
    mapMsgTypeSize mapSendBytesPerMsgType;
    uint64_t nRecvBytes;
    mapMsgTypeSize mapRecvBytesPerMsgType;
};

class CNode
{
public:
    uint64_t nSendBytes GUARDED_BY(cs_vSend){0};
    uint64_t nRecvBytes GUARDED_BY(cs_vRecv){0};

private:
    mapMsgTypeSize mapSendBytesPerMsgType GUARDED_BY(cs_vSend);
    mapMsgTypeSize mapRecvBytesPerMsgType GUARDED_BY(cs_vRecv);
};

class CConnman
{
public:
    uint64_t GetTotalBytesRecv() const;
    uint64_t GetTotalBytesSent() const EXCLUSIVE_LOCKS_REQUIRED(!m_total_bytes_sent_mutex);

private:
    // Network stats
    void RecordBytesRecv(uint64_t bytes);
    void RecordBytesSent(uint64_t bytes) EXCLUSIVE_LOCKS_REQUIRED(!m_total_bytes_sent_mutex);

    // Network usage totals
    mutable Mutex m_total_bytes_sent_mutex;
    std::atomic<uint64_t> nTotalBytesRecv{0};
    uint64_t nTotalBytesSent GUARDED_BY(m_total_bytes_sent_mutex) {0};
};
```

### lifecycles
`CNode.nSendBytes` & `CNode.nRecvBytes`:
- initialized to 0 & guarded by the `cs_vSend` & `cs_vRecv` locks respectively
- `CConnman::SocketSendData` increments `nSendBytes`. the whole function
  requires the `cs_vSend` lock
- `CConnman::ReceiveMsgBytes` increments `nRecvBytes`. the function
  first acquires the `cs_vRecv` lock
- `CNode::CopyStats` acquires each lock & copies the relevant fields to `CNodeStats`
- displayed via node stats in qt & `getpeerinfo.bytessent` &
  `getpeerinfo.bytesrecv`

`CNode.mapSendBytesPerMsgType` & `CNode.mapRecvBytesPerMsgType`:
- types are `mapMsgTypeSize` which is a map of {message type -> bytes}
- guarded by the `cs_vSend` & `cs_vRecv` locks respectively
- send map is implicitly initialized, and then written to with whatever
  messages are passed through to `CConnman::PushMessage`, send lock acquired
  within the function
- receive map is explicitly initialized in the `CNode` constructor, by zero
  initializing each string returned by `getAllNetMessageTypes`. an additional
  entry is added for the key `NET_MESSAGE_TYPE_OTHER`
- receive map is written to in `CNode::ReceiveMsgBytes`, if the message is
  rejected or key not found, info is stored in the `NET_MESSAGE_TYPE_OTHER`.
  recv lock acquired within the function
- `CNode::CopyStats` acquires each lock & copies the relevant fields to
  `CNodeStats`
- displayed via node stats in `getpeerinfo.bytessent_per_msg` &
  `getpeerinfo.bytesrecv_per_msg`, filtered by presence

`CConnman.nTotalBytesRecv`
- private member of type `std::atomic<uint64_t>`, initialized to 0
- incremented via connman's `threadSocketHandler` -> `SocketHandlerConnected`
  ->`RecordBytesRecv()`. no locks required since atomic.
- `CNode::ReceiveMsgBytes()` is the function that reads the bytes from the
  wire, and only called from `SocketHandlerConnected`
- returned in `GetTotalBytesRecv()`. again, no lock required. returned in
  `getnettotals.totalbytesrecv` & to QT via `NodeImpl` interface

`CConnman.nTotalBytesSent`
- private member of type `uint64_t`, initialized to 0
- guarded by `m_total_bytes_sent_mutex` (this also guards a couple other
  fields - `nMaxOutboundTotalBytesSentInCycle`, `nMaxOutboundCycleStartTime` &
  `nMaxOutboundLimit`)
- incremented in `CConnman::RecordBytesSent()`, which is called from
  `SocketHandlerConnection` and `PushMessage`.
- `CConnman::SocketSendData` is the underlying function that sends messages
  over the wire, but callers are required to acquire the lock before calling
  it. So `RecordBytesSent` must be invoked around the `SocketSendData` call.
- returned in `GetTotalBytesSent()`, which acquires the
  `m_total_bytes_sent_mutex` lock. returned in `getnettotals.totalbytessent` &
  to QT via `NodeImpl` interface

### tangential learnings
- we already have per-peer totals returned in `getpeerinfo`, we now want to add
  across-peer totals
- for `std::map`, difference between `.at()` and `.find()`
-> `at` throws an exception if element doesn't exist, returns reference
otherwise.
-> `find` returns an iterator either to the element, or to `map::end()`


### open questions
- what are `nSentSize` and `nSendOffset`?
- why can `nTotalBytesRecv` be atomic, but `nTotalBytesSent` needs to be under
  the `m_total_bytes_sent_mutex` lock?
- `SocketSendData` has the `EXCLUSIVE_LOCKS_REQUIRED` annoation, but usually
  that gets paired with the `AssertLockHeld`. Should that be added?

## considering..
- locking: should the new receive stats reuse the `cs_vRecv` lock, or steer clear?
also impacts logic in `CNode::ReceiveMsgBytes`
- `CNode::ReceiveMsgBytes` changes - combine with updating `CNode` receive
  stats
- I think `m_msgtype_bytes_recv` & `m_msgtype_bytes_sent` are unnecessary &
  just leftover from the previous version (updating `getnettotals`). This info
  should now be covered in `m_netmsg_stats_recv` & `m_netmsg_stats_sent`