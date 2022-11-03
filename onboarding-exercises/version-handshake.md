## Version Handshake

Conceptual:
- What does the "version handshake" refer to? What is it's significance?
- What other P2P messages are potentially sent during the handshake?

Bitcoin Core:
- Where does a node send the `version` and `verack` messages?  What logical
  conditions need to be met to trigger sending each message?
- Where does a node recieve the `version` and `verack` messages? What does it
  do with this information?
- In the test framework function `add_p2p_connection`, what is the point of the
  `wait_for_verack` param?
- Write a test where a node adds a `P2PConnection`. What are different ways you
  can observe the messages sent by both the node & p2p connection to complete
  the version handshake?
