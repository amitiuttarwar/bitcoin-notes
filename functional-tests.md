## General
- The test framework adds several startup option to `bitcoin.conf`, as well as
  passes through cli options. When an individual test sets `self.extra_args`,
  they get passed in as cli options (and will overwrite the `.conf` options if
  conflict).
- When restarting a node, the `extra_args` parameters carry over, but any
  specific params in a previous restart do not.

## IP addresses
- It's recommended to use addresses in the block `192.0.2.0/24` for testing
  purposes (RFC 5735). -> so between `192.0.2.0` and `192.0.2.255`. Because 24
  bits are allocated for the network prefix, leaving 8 bits for the host
  addressing.
- However, the addrman code identifies these as invalid, so we're unable to use
  them in our tests.
