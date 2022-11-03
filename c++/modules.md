## Links
- modernes cpp blog
  - [advantages of modules](https://www.modernescpp.com/index.php/cpp20-modules)
  - [simple math module](https://www.modernescpp.com/index.php/cpp20-a-first-module)
  - [interface vs implementation](https://www.modernescpp.com/index.php/c-20-module-interface-unit-and-module-implementation-unit)
  - [submodules](https://www.modernescpp.com/index.php/c-20-divide-modules)
  - [open questions](https://www.modernescpp.com/index.php/c-20-open-questions-to-modules)

## Context
- The C++ build process (preprocessing, compiling, linking) quickly
  leads to repeated substitution of headers during the first phase, since the
  preprocessor runs on each source files.
- Preprocessor macros are simple text substitutions, and prone to errors such
  as ordering dependence or clashes with other names in the apaplications.
- Header guards are needed to prevent a "redefinition of [symbol]" error that
  would otherwise occur from indirectly importing the same header file twice.

## Advantages of Modules
- Only imported once
- Not dependent on order
- Unlikely to have identical symbols
- Allow expressing logical structure, can specify names that should be exported
  or not
- Don't need to separate code into interface & implementation

## It's Module Time

Example program:
```
// math.cpp

export module math;

export int add(int a, int b) {
  return a + b;
}
```

- `export module math` is the declaration of the module
- `export` before `add` allows other classes to use the function
- a client would `import math;` to import the module. this makes the exported
  names from the module visible to the client.
-
