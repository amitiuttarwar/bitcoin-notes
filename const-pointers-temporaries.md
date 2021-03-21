# Temporaries & Pointers
A fun C++ puzzle from jnewbery


#### Which of the following compile & are safe?

```
#include <iostream>

int one() {
    return 1;
}

int main()
{
    int& ref = one();
    std::cout << ref << std::endl;
    return 0;
}
```
<details><summary> Snippet 1 Analysis </summary>

- Doesn't compile: `error: non-const lvalue reference to type 'int' cannot bind
  to a temporary of type 'int'`.
- `ref` is a non-const lvalue reference to type 'int', `one()` returns a
  temporary of type 'int'.
- The temporary only exists until it falls out of scope, so would be
  problematic if `ref` were to try to access it beyond the stack lifetime of
  the temporary created by the `one()` return value. The compiler detects the
  possiblity of a dangling reference and returns an error.

</details>



```
#include <iostream>

int one() {
    return 1;
}

int main()
{
    const int& ref = one();
    std::cout << ref << std::endl;
    return 0;
}
```
<details><summary> Snippet 2 Analysis </summary>

- Compiles and is safe.
- Even though this code creates a reference to a temporary object, the C++
  language specifies an exception: `The lifetime of a temporary object may be
  extended by binding to a const lvalue reference or to an rvalue reference`
  [link](https://en.cppreference.com/w/cpp/language/lifetime#Temporary_object_lifetime).
- Since `ref` is a `const lvalue reference`, the compiler is able to extend the
  lifetime of the temporary returned by `one()` and bind it to the lifetime of
  `ref`.

</details>

```
#include <iostream>

const int& one() {
    return 1;
}

int main()
{
    const int& ref = one();
    std::cout << ref << std::endl;
    return 0;
}
```
<details><summary> Snippet 3 Analysis </summary>

- Compiles but is unsafe, throws `warning: returning reference to local
  temporary object`.
- `one()` is returning a reference to a local variable, so `ref` would be a
  dangling reference.
- Question: why does this warn instead of error?

</details>

```
#include <iostream>

int& one() {
    return 1;
}

int main()
{
    const int& ref = one();
    std::cout << ref << std::endl;
    return 0;
}
```
<details><summary> Snippet 4 Analysis </summary>

- Doesn't compile: `error: non-const lvalue reference to type 'int' cannot bind
  to a temporary of type 'int'`
- The mismatch of type occurs at the `return 1` statement, `1` is a temporary
  and the function `one()` tried to return `int&`, which is a non-const lvalue
  reference.

</details>

```
#include <iostream>

const char* one() {
    return "one";
}

int main()
{
    const auto& ref = one();
    std::cout << ref << std::endl;
    return 0;
}
```
<details><summary> Snippet 5 Analysis </summary>

- Compiles and is safe.
- String literals have static storage duration, so the string "one" will exist
  for the duration of the program. Thus `ref` can safely refer to this part of
  memory.
- Side note: it will be stored in the DATA segment of memory, which is separate
  from the heap or the stack. ([stack overflow
  explanation](https://stackoverflow.com/questions/93039/where-are-static-variables-stored-in-c-and-c))

</details>

```
#include <iostream>

const int& one() {
    static const int i = 1;
    return i;
}

int main()
{
    const int& ref = one();
    std::cout << ref << std::endl;
    return 0;
}
```

<details><summary> Snippet 6 Analysis </summary>

- Compiles and is safe.
- Same as above, but instead of using the string literal with a default static
  storage duration, explicitly specify the int declaration as such.
- Side note: will also be stored in the DATA segment of memory

</details>
