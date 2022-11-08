## Functional Test Exercise

Note: `test_node.py` and `util.py` are two files that might be useful for these
exercies.

1. A good entry point to bitcoin core & the functional tests is
   `test/functional/test_framework/example_test.py`. Start by reading it
   through & tinkering with it to understand what it's doing. Next, Extend the
   main chain by having node 2 create block with height 12. What are different
   ways you can test that node 1 received the block?

2. Use pdb to pry into the example test. You can read about how to use it
   [here](https://github.com/bitcoin/bitcoin/blob/master/test/README.md#attaching-a-debugger).
   Don't get bogged down trying to become a wizard, the basics can take you far
   :)

3. Create a new test file. Set it up to have 3 nodes. Add an outbound P2P
   connection to the 3rd node. Create a mempool transaction and submit it to
   node 1. How can you confirm that the P2P connection recieved the
   transaction?

