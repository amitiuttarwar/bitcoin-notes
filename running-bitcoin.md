## Startup options
To view the options: `bitcoind -help` & `bitcoind -help-debug`

You can implicitly negate arguments using `-no[arg]`. In the code, this is done by [AppInitMain](https://github.com/bitcoin/bitcoin/blob/ea5a50f92a6ff81b1d2dd67cdc3663e0e66733ac/src/bitcoind.cpp#L43),
which invokes
[ParseParameters](https://github.com/bitcoin/bitcoin/blob/ea5a50f92a6ff81b1d2dd67cdc3663e0e66733ac/src/util/system.cpp#L338)
which calls through to
[InterpretOption](https://github.com/bitcoin/bitcoin/blob/ea5a50f92a6ff81b1d2dd67cdc3663e0e66733ac/src/util/system.cpp#L209)
to handle the negation.
