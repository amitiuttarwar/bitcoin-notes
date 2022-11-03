### extern
- Generally indicates to the compiler "this is a declaration only", so the
  compiler will not implicitly initialize the variable (and then error with
  duplicate symbols during the linker phase).
- It can also be used to make a definition externally available when another
  keyword has implicitly defined internal linkage (eg. `const`, `constexpr` &
  `inline`)
- If an extern variable is initialized, the extern keyword is ignored because a
  declaration with an initializer is a definition.