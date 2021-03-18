### resources:
- Tutorial to learn fuzzing in isolation:
  https://github.com/google/fuzzing/blob/master/tutorial/libFuzzerTutorial.md
- Setting up fuzzing in bitcoin:
  https://github.com/bitcoin/bitcoin/blob/master/doc/fuzzing.md
- Works better on linux, so for mac users, using docker is recommended (but
  keep in mind, docker only uses 1 core, so the compiling step takes much
  longer)

### installing bitcoin fuzzer
```
apt update
apt install -y git
apt install -y sudo
git clone https://github.com/bitcoin/bitcoin
cd bitcoin
./autogen.sh
CC=clang CXX=clang++ ./configure --enable-fuzz --with-sanitizers=address,fuzzer,undefined
sudo apt-get install build-essential libtool autotools-dev automake pkg-config bsdmainutils python3
sudo apt-get install libevent-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev libboost-thread-dev
sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools
CC=clang CXX=clang++ ./configure --enable-fuzz --with-sanitizers=address,fuzzer,undefined
make -j7
git clone git@github.com:bitcoin-core/qa-assets.git
FUZZ=process_message src/test/fuzz/fuzz qa-assets/fuzz_seed_corpus/process_message
```

- the seed enables deterministic reproducability of the fuzz tests, maintains
  the starting seed and then the mutated seed
- the corpus is the set of seeds

### a visual metaphor:
- code has lots of branches, the fuzz tests programmatically define the
  possibility space
- each seed is a specific pathway that takes you to a particular leaf node
- once you run the fuzzers and find a new seed, you've found a path to a new
  leaf node
- corpus is the set of all found seeds. after running the existing seeds,
  mutate from there to discover new ones

### interpreting results:
- when there is `NEW` or `NEW_FUNC`, you've found new seeds!
- can make a PR to `https://github.com/bitcoin-core/qa-assets` to commit the
  new seeds to the corpus

- status messages are documented here: https://llvm.org/docs/LibFuzzer.html#output
- `pulse` is a  heartbeat when running through the corpus seeds
- `INITED` means fuzzer has run through all corpus seeds and will start
  mutating afterwards

### coverage reports
- how to generate the colored html output: [link](https://github.com/MarcoFalke/btc_cov/blob/cd1b2a714aa99be3a9fd2bc68a2308c49f36fd76/.cirrus.yml#L65)
- Marco's coverage report: [link](https://marcofalke.github.io/btc_cov/fuzz.coverage/index.html)
- aj mentioned: `make fuzz.coverage/.dirstamp` or `make cov` more generally