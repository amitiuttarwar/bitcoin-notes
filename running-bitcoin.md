## Monitor & Interact with a running bitcoin node
- watch logs: `tail -f stdout.log`

- [bitcoin/files.md](https://github.com/bitcoin/bitcoin/blob/master/doc/files.md) great docs of all the explanations
  - default data dir for linux: `~/.bitcoin/`

## `bitcoind` Startup options
To view the options: `bitcoind -help` & `bitcoind -help-debug`

You can implicitly negate arguments using `-no[arg]`. In the code, this is done by [AppInitMain](https://github.com/bitcoin/bitcoin/blob/ea5a50f92a6ff81b1d2dd67cdc3663e0e66733ac/src/bitcoind.cpp#L43),
which invokes
[ParseParameters](https://github.com/bitcoin/bitcoin/blob/ea5a50f92a6ff81b1d2dd67cdc3663e0e66733ac/src/util/system.cpp#L338)
which calls through to
[InterpretOption](https://github.com/bitcoin/bitcoin/blob/ea5a50f92a6ff81b1d2dd67cdc3663e0e66733ac/src/util/system.cpp#L209)
to handle the negation.

These are the set of options available to set in the `bitcoin.conf` file.

If a value is set in `bitcoin.conf` & you also pass it in through cli, the cli
one will overwrite the `.conf` param.

## `bitcoin-cli`
The main invocation is: `src/bitcoin-cli [RPC COMMAND]`

docs:
- `src/bitcoin-cli -help` to see command-line options
- `src/bitcoin-cli help` to see list of RPC commands
- `src/bitcoin-cli help [RPC]` to see help man for RPC command

logging:
- `logging` to see what categories are enabled
- `src/bitcoin-cli -rpcuser=user -rpcpassword=password logging "[\"net\",
    \"mempool\"]"` to enable net & mempool log categories

useful tricks:
- number of connections by type: `src/bitcoin-cli getpeerinfo | grep connection.type | sort | uniq -c`

## Start a Bitcoin node from scratch on Unix machine
1. Generate a new SSH key and add to ssh-agent ([docs](https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent))
```bash
ssh-keygen -t ed25519 -C "amiti@uttarwar.org" // generate a key to ~/.ssh/id_ed25519{.pub}
eval "$(ssh-agent -s)" // start ssh agent
ssh-add ~/.ssh/id_ed25519 // add private key to ssh agent
```

2. Add SSH key to Github account ([docs](https://docs.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account))
- copy contents of `~/.ssh/id_ed25519.pub`
- github > settings > SSH and GPG keys > New SSH key

3. Get bitcoin core
`git clone git@github.com:bitcoin/bitcoin.git`

4. Build bitcoin ([docs](https://github.com/bitcoin/bitcoin/blob/master/doc/build-unix.md))
```bash
cd bitcoin

// install dependencies:
sudo apt-get install build-essential libtool autotools-dev automake pkg-config bsdmainutils python3
sudo apt-get install libevent-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev
sudo apt install libsqlite3-dev
sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools

// build:
./autogen.sh
./configure --disable-wallet
nproc // to see how many cores we have
make -j5
```

5. Run bitcoind
```bash
sudo apt install daemonize
daemonize -c $HOME -e stderr.log -o stdout.log $HOME/bitcoin/src/bitcoind -txindex -debug=mempool,net,bench
```

## Setting up a server
- add ssh key: `echo “[SSH KEY]” >> ~/.ssh/authorized_keys`
- ssh forwarding
- become root: `sudo su -`
- add sudo permissions to my user `usermod -a -G sudo [USERNAME]`

## Debug Logging
Different ways to enable log categories for debugging

1. Arg when starting up bitcoind
  * `debug` & `debugexclude` commands
  * can be used to specify multiple categories

Usage
  * `bitcoind -debug` -> enable all categories
  * `bitcoind -debug=mempool` -> only enable mempool
  * `bitcoind -debug -debugexclude=mempool` -> enable all but mempool
  * `bitcoind -debug=mempool -debug=net` -> enable mempool & net

2. RPC command via bitcoin-cli
  * result shows which log levels are enabled

Usage
  * `bitcoin-cli logging "[\"net\", \"mempool\"]"` -> enable net & mempool

3. In bitcoin.conf file
  * `debug=mempool`, separate lines for each log category


## .dat Files
https://github.com/bitcoin/bitcoin/blob/master/doc/files.md

#### undo files (rev)
from [PR review club](https://bitcoincore.reviews/17994):
- The UTXO set maintains spendable outputs. Once a block is connected, the
  spent UTXOs are gone from the current set.
- The undo data keeps around this set of coins spent by a block, so we can
  un-spend them if the block gets disconnected.
- The undo data is useless without the corresponding block data since it
  doesn't contain txids.
- If a node is pruning with depth D & D+1 gets disconnected, it cannot reorg
  and would need to redownload the entire chain. This is why we keep a minimum
  of 288 blocks: [link](https://github.com/bitcoin/bitcoin/blob/5dcb0615898216c503e965a01d855a5999a586b5/src/validation.cpp#L3951)
- The undo data is written in `ConnectBlock`, which we only call for the
  chaintip, so we need to have processed all theh blocks up to that point. This
  is because you need *all* UTXOs spent by a block, which might include UTXOs
  created in the block before. Once a block is activated, the UTXOs are gone.
  So the undo data must be created for block B in the time between block B-1 &
  B+1.
- `blk*.dat` & `rev*.dat` files are append only. We will only ever delete them
  if we are pruning, in which case they are delted as a whole.
- We dump blocks in `blk*.dat` as they come in from the network (often out of
  order). We can't do the same with undo because they can only be generated
  once all previous blocks have been activated.
- `rev*` is partially ordered: a block's parent will always come before the
  child. However, in case of multiple branches, its possible that parent &
  child blocks are not adjacent.
- `blk*` files are explicitly size limited, but `rev*` are only implicitly
  limited because of the block files. Theoretically could have a rev file upto
  250MB (if it spent 25000 outputs all with 10000 byte scriptPubKeys)
- `rev*` files contain the undo data for theh corresponding blocks in the same
  numbered `blk*` file.
- When new data is appended, space is allocated in chunks (1 MB for undo, 16 MB
  for block) to reduce filesystem fragmentation & ensure we don't get a "disk
  full" error when writing the data later (although that means you'd get the
  error during allocation)
- To "finalize" a file means truncate unused space that was preallocated &
  flush the stream to the filesystem (fsync when flushing) `Flush()` method
  does `fflush()` & `fsync()`.

Theoretically: what would happen if you deleted all blk*/rev* files from a
(stopped) node & replaced them with a copy from another node?
-> issues because leveldb blocks db stores where the files in the blocks are
-> `-reindex` would probably help, but unsure.
-> "to be sure, I would `rm -fr blocks/index/` so at least if it bricks it
bricks with some "file not found" error instead of some obscure trying to
lookup a block in position X at file Y and finding something else there"
