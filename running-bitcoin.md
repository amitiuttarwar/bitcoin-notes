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

## `bitcoin-cli` 
The main invocation is: `src/bitcoin-cli [RPC COMMAND]`

- `logging` to see what categories are enabled
- `src/bitcoin-cli -rpcuser=user -rpcpassword=password logging "[\"net\",
    \"mempool\"]"` to enable net & mempool log categories 
- `bitcoin-cli getpeerinfo | grep connection.type | sort | uniq -c` to see number of connections by type 

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
