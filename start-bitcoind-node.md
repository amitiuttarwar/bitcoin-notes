### steps to start a bitcoin node from scratch on a unix machine

1. Generate a new SSH key and add to ssh-agent [docs](https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
```bash
ssh-keygen -t ed25519 -C "amiti@uttarwar.org" // generate a key to
~/.ssh/id_ed25519{.pub}
eval "$(ssh-agent -s)" // start ssh agent
ssh-add ~/.ssh/id_ed25519 // add private key to ssh agent
```

2. Add SSH key to Github account [docs](https://docs.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account)
- copy contents of `~/.ssh/id_ed25519.pub`
- github > settings > SSH and GPG keys > New SSH key

3. Get bitcoin core
`git clone git@github.com:bitcoin/bitcoin.git`

4. Build bitcoin [docs](https://github.com/bitcoin/bitcoin/blob/master/doc/build-unix.md)
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

6. Monitor bitcoind
- watch logs: `tail -f stdout.log`
- default data dir: `~/.bitcoin/`

### TODOS:
- install ccache
- update to use bitcoind daemon command
- install berkeleydb to compile with wallet
