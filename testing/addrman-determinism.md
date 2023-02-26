# addrman determinism

* `Addrman` constructor takes in a `bool` called
`deterministic`. `AddrManImpl` uses this value to initialize `insecure_rand`
and `nKey`.

* `nKey` -> if deterministic, set `nKey` to be `1`, otherwise select it randomly.

* `insecure_rand` -> forward the `deterministic` bool to `insecure_rand` which is
a `FastRandomContext`. This invokes the constructor that returns early if the
bool is `false`. If the bool is `true`, it initializes `FastRandomContext.rng`
which is a `ChaCha20`.  ``` uint256 seed; rng.SetKey(seed.begin(), 32); ```

It seems like the `SetKey` function takes the key (first param) passed in and
uses it to set the values of the private member `input`. I think `uint256` gets
initialized to 0, so this case sets the key tobe predictable by setting it to
the values of 0.

**Question:** In the case where the `FastRandomContext::FastRandomContext(bool
fDeterministic)` constructor is used with the bool as false, what does `rng`
aka the `ChaCha20` get initialized to? -> `requires_seed` gets set for
`fDeterministic`, so that will make sure the seed gets set before it does stuff
in `randbytes`

There is a `FastRandomContext` constructor where you can initialize with an
explicit seed, only meant for testing. That simply invokes
`rng.SetKey(seed.begin(), 32);`

The places in the code initializing a `FastRandomContext` don’t pass any params
into the constructor, which will invoke the `bool` constructor setting
`fDeterministic` to `false`.

`SeedInsecureRand` -> controlled randomization

An init param removing randomness would be risky to expose because if anyone
actually used it in production, it would be a security leak.

To have addrman determinism from the functional tests, we could initialize an
addrman with a `peers.dat` with 0 addresses because the `nKey` would get
deserialized.

Another strategy for functional tests is, eg. instead of having 2 addresses in
addrman, add 10 then check that the results are >5 or such.
