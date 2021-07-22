# Temporaries & Pointers

A fun C++ puzzle from jnewbery

#### Which of the following compile & are safe?

##### 1)

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
<details><summary> Analysis </summary>

- Doesn't compile: `error: non-const lvalue reference to type 'int' cannot bind
  to a temporary of type 'int'`.
- `ref` is a non-const lvalue reference to type 'int', `one()` returns a
  temporary of type 'int'.
- The temporary is destroyed as the last step of evaluating the `one()` expression , so would be
  problematic if `ref` were to try to access it beyond that lifetime. Binding the temporary to
  a non-const lvalue reference is therefore not allowed.

</details>

##### 2)

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

<details><summary> Analysis </summary>

- Compiles and is safe.
- Even though this code creates a reference to a temporary object, the C++
  language specifies an exception: `The lifetime of a temporary object may be
  extended by binding to a const lvalue reference or to an rvalue reference`
  [link](https://en.cppreference.com/w/cpp/language/lifetime#Temporary_object_lifetime).
- Since `ref` is a `const lvalue reference`, the lifetime of the temporary returned by
  `one()` is extended until `ref` is out of scope.

</details>

##### 3)

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

<details><summary> Analysis </summary>

- Compiles but is unsafe, throws `warning: returning reference to local
  temporary object`.
- `one()` is returning a reference to a local variable, so `ref` would be a
  dangling reference.
- Question: why does this warn instead of error?

</details>

##### 4)

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
<details><summary> Analysis </summary>

- Doesn't compile: `error: non-const lvalue reference to type 'int' cannot bind
  to a temporary of type 'int'`
- This is the same error as in **(1)**, but the mismatch of type occurs at the `return 1` statement.
  `1` is a temporary and the function `one()` tried to return `int&`, which is a non-const lvalue
  reference.

</details>

##### 5)

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
<details><summary> Analysis </summary>

- Compiles and is safe.
- String literals have static storage duration, so the string "one" will exist
  for the duration of the program. Thus `ref` can safely refer to this part of
  memory.
- Side note: it will be stored in the [DATA segment of memory](https://stackoverflow.com/questions/93039/where-are-static-variables-stored-in-c-and-c),
  which is separate from the heap or the stack.

</details>

##### 6)

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

<details><summary> Analysis </summary>

- Compiles and is safe.
- Same as above, but instead of using the string literal with a default static
  storage duration, explicitly specify the int declaration as such.
- Side note: will also be stored in the DATA segment of memory

</details>
