### CAddrInfo
- remove `nRefCount`
- new fields `m_bucket` & `m_bucket_pos`
- new function `Rebucket`, sets `m_bucket` and `m_bucket_pos` based on key &
  asmap passed in + fInTried member bool.
- `nRandomPos` is set to -1 for aliases


### CAddrMan
- adds AddrManIndex as a boost multi-index which stores `CAddrInfo` records &
  has two `ordered_non_unique` indices on `ByAddressExtractor` and
  `ByBucketExtractor`.
- simplifies the serialization & deserialization code & increments the lowest
  compatible format version.
- simplifies the `Clear()` function.
- introduces `AddrManIndex m_index`, which is the actual addrman table
- `vRandom` changes from `std::vector<int>` to
  `std::vector<AddrmanIndex::index<ByAddress>::type::iterator>` to be a
  randomly ordered vector of (non-alias) entries.
- `vvNew` and `vvTried` are removed, but `nNew` and `nTried` remain.
- `m_tried_collisions` shifts from being a set of ints to being a set of `const
  CAddrInfo*`


### Open Questions
- `ADDRMAN_NEW_BUCKETS_PER_ADDRESS = 8` -> max size of source vector would be 8
  right? is there a way to give this as a compiler clue to minimize
  allocations?


### `m_index` Access Points
- Private to `CAddrMan`
  - `Erase`
  - `Modify`
  - `Insert`
  - `Serialize` / `Unserialize`
  - `Clear`
  - `MakeTried`
  - `Good_`
  - `Add_`
  - `Attempt_`
  - `Select_`
  - `Check_`
  - `Connected_`
  - `SetServices_`
  - `ResolveCollisions_`
  - `SelectTriedCollision_`
  - `EraseInner`
  - `CountAddr`