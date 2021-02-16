## Thread Safety Annotation
`EXCLUSIVE_LOCKS_REQUIRED` is a compile time check that uses clang. One of its
shortcomings is that it does not check constructors.

Clang documentation about thread safety analysis:
https://clang.llvm.org/docs/ThreadSafetyAnalysis.html

In [#21188](https://github.com/bitcoin/bitcoin/pull/21188), Marco says we
should avoid adding the lock annotation in the function definition, because if
declaration annotates locks(A,B) and definition annotates (A), we won't get a
compile error even if somebody uses without taking B. I was unable to
reproduce, waiting to hear back.

## Runtime lock assertions
`AssertLockHeld` is a runtime check that will crash the program if the
assertion fails. It's defined in `sync.h`, and relies on a debug flag to enable
`DEBUG_LOCKORDER`.
