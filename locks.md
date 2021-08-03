## Thread Safety Annotations
These are compile time checks that use clang to prevent race conditions and deadlocks.
- Macro defined in `threadsafety.h`
- Only runs when compiled with the clang static analysis tool,
  `-Wthread-safety` option (or other `-Wthread...` options)
- To run in bitcoin core, `./configure --with-sanitizers=thread`
- One of its shortcomings is that it does not check constructors.
- Clang [documentation](https://clang.llvm.org/docs/ThreadSafetyAnalysis.html) about thread safety analysis

### Uses
- `GUARDED_BY` & `EXCLUSIVE_LOCKS_REQUIRED` declares the caller _must_ hold the
given capabilities.
- `LOCKS_EXCLUDED` declares the caller _must not_ hold the given capabilities.
However, it is an optional attribute, so can lead to some false negatives.
Example:
```
class Foo {
  Mutex mu;

  void foo() {
    mu.Lock();
    b();          // No warning
    mu.Unlock();
  }

  void b() {
    a()
  }

  void a() EXCLUDES(mu);
}
```

- `REQUIRES(!mu)` is a [negative
  capability](https://clang.llvm.org/docs/ThreadSafetyAnalysis.html#negative),
  which is an alternative that provides stronger safety guarantees than the
  `EXCLUDES`. It is off by default & enabled by passing
  `-Wthread-safety-negative`. The goal of negative capabilities is to prevent
  double locking.
- Negative lock annotations only make sense for mutexes that are private
  members.
- Relevant conversations:
  [1](https://github.com/bitcoin/bitcoin/pull/20272#issuecomment-720755781),
  [2](https://github.com/bitcoin/bitcoin/pull/21598)

### Quirk of Thread Safety Annotations
- Unexpected behavior with redundant annotations in the following ordering:
```
1. function declaration annotates `EXCLUSIVE_LOCKS_REQUIRED(lock1)`
2. caller invokes function
3. function definition annotates `EXCLUSIVE_LOCKS_REQUIRED(lock1, lock2)`
```
- The compiler will not warn about `lock2`.
- The same issue can occur if the annotations are on the definition & the caller
is earlier in the file.
- The solution is to only annotate the function declaration.
- Relevant PRs: [#21188](https://github.com/bitcoin/bitcoin/pull/21188) &
[#21202](https://github.com/bitcoin/bitcoin/pull/21202)

## Runtime lock assertions
`AssertLockHeld` is a runtime check that will crash the program if the
assertion fails. It's an internal implementation defined in `sync.h`, and
relies on a debug flag to enable `DEBUG_LOCKORDER`.

## Comparisons
From [sipa's comment](https://github.com/bitcoin/bitcoin/pull/18861#discussion_r425439519):

Annotations:
- [+] Compile-time check, guarantee absence of issues in every possible code path
- [-] Only works in clang
- [-] Can't be used in some more advanced locking scenarios

Assertions:
- [+] Works in GCC and Clang
- [+] Isn't restricted to analyzable cases
- [-] Is only a runtime check; it needs test cases that actually exercise the bug
- [-] Needs building with `-DDEBUG_LOCKORDER`
