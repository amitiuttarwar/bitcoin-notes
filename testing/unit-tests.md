### Unit Test Basics
- When adding a new unit test, add to list in `src/Makefile.test.include`
- Recompile the unit tests: `make check`
- Recompile just the test directory: `make -j7 -C src/test`
- Run a single test: `src/test/test_bitcoin --run_test=TEST-SUITE-NAME/TEST-CASE-NAME`
- Example: `make -j7 src/bitcoind && make -j7 -C src/test && src/test/test_bitcoin --run_test=txrebroadcast_tests/recency`

### Unit Test Available Helpers
- `setup_common.{h, cpp}` defines `BasicTestingSetup`, `TestingSetup`,
  `RegTestingSetup` and `TestChain100Setup`. These fixtures enable starting a
  test in a reasonable state.
- `BasicTestingSetup` defines a `NodeContext m_node`, which provides the
  mempool, peerman, connman, etc.
- `TestMemPoolEntryHelper` can be used to create a `CTxMemPoolEntry` from a
  `CTransaction` / `CTransactionRef` and set fee / time / height / etc along
  the way. This can be used with `mempool.addUnchecked` to submit a transaction
  into the mempool, bypassing policy checks.

### Logging Basics
- `fprintf` prints to wherever you tell it, and gives lots of warnings about
  types being specified very precisely.
  eg: `fprintf(stderr, "txhsh: %s, wtxhsh: %s\n", tx_parent.GetHash(), tx_parent.GetWitnessHash())`
- `logprintf` is much better. It also saves to debug log.
  eg: `LogPrintf("txhsh: %s, wtxhsh: %s\n", tx_parent.GetHash(), tx_parent.GetWitnessHash())`

### Logging Miscellaneous Useful Info
- To monitor logs from unit tests, update the `arguments` in the
  `BasicTestingSetup` constructor -> update `-printtoconsole=1`, and add any
  relevant categories to debug, eg. `-debug=net`.
- `FormatScript` for printing out a `CScript` object.

### Useful Learnings (from attempts to form a transaction)
- `CMutableTransaction` is used when populating the fields, then finalized into
  `CTransaction`, which can also be accessed through a `CTransactionRef`
  object.
- `CTxMemPoolEntry` has a `CTransactionRef`, as well as additional ancestor /
  descendant information used for mempool calculations.
- `DecodeDestination` turns a string into a `CTxDestination` object.