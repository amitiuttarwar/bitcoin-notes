- `SERIALIZE_METHODS` is #define(d) in `serialize.h` and builds both `Serialize`
and `Unserialize` from a singular code chunk.
- gets invoked with `<<` and `>>` operators
- `CAddrMan` defines its own serialization & unserialization code to write to /
  read from `peers.dat`