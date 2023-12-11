## General
- The test framework adds several startup option to `bitcoin.conf`, as well as
  passes through cli options. When an individual test sets `self.extra_args`,
  they get passed in as cli options (and will overwrite the `.conf` options if
  conflict).
- When restarting a node, the `extra_args` parameters carry over, but any
  specific params in a previous restart do not.

## IP addresses
- `192.0.0.8` is good to use in the tests because they are IPv4 dummy addresses
  per RFC7600.
- It's recommended to use addresses in the block `192.0.2.0/24` for testing
  purposes (RFC 5735). -> so between `192.0.2.0` and `192.0.2.255`. Because 24
  bits are allocated for the network prefix, leaving 8 bits for the host
  addressing.
- However, `CNetAddr::IsValid()` specifically filters this IP range. So tests
  need different ip addresses to make it into the addrman.

- IANA IPv4 Special-Purpose Address Registry: [link](https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml)
- More conversation: [link](https://github.com/bitcoin/bitcoin/pull/22098#discussion_r680236317)

## Debugging tools
- run the test with `--nocleanup` flag and then
  `test/functional/combine_logs.py -c` to see the logs from the latest run


## Mine a block
```
  blockhash = self.nodes[2].generate(1)[0]
  block_hex = self.nodes[2].getblock(blockhash=blockhash, verbosity=0)
  block = from_hex(CBlock(), block_hex)
  block.rehash()
```
