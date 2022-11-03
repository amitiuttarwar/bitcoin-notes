### Thread Sanitizer

[developer notes](https://github.com/bitcoin/bitcoin/blob/master/doc/developer-notes.md#sanitizers)
- `./configure --with-sanitizers=thread`
- to identify if `make` is using clang or g++, look at `CC=` in `config.log`
- need to compile using clang: HOW?

- trying to get an example tsan failure
  - code in `tsan.cpp`
  - `clang tsan.cpp -o tsan -pthread -fsanitize=thread -g`
  - `TSAN_OPTIONS=second_deadlock_stack=1 ./tsan`

  - I'm unable to compile a "hello world" program with clang
