## High Level
* point of template is to accept type as parameter
* function templates: a declaration that can generate declarations for other functions
* class templates: generalization of object type

### Syntax
function template generic example:
```
template <typename T>
T max(T a, T b)
{
  return b < a ? a : b;
}
```

class template generic example:
```
template <typename T>
class Foo {
  std::vector<T> elements;
}
```

* `template <class T>` & `template <typename T>` -> same thing. here, class and typename are interchangeable.
* `template <typename T>` -> template parameter list
* `void swap (T &a, T &b)` -> function parameter list

### Terminology
* template instantiation - process of generating function definition from a template
* instatiation - refers to generated class or function definition (also, instantiated function / class)
* template-id - name of the instantiated template. eg. `swap<int>`
* specialization - template paired with specific type arguments
eg. `swap<T>` is generalization, `swap<int>` is specialization for integers.
* template argument deduction - eg. `template void swap<T>(T &a, T&b)` -> can invoke with `template void swap(int &a, int &b)` & compiler will deduce `swap<int>`

### How its interpreted
* Template instantiation is part of the translation process.
* Argument substitution (replacing type parameter T with type argument) happens at compile time.
* Compiler instantiates a function for each type passed to the template. The symbol name has the type in it. Each function will only be instantiated once. Previous instantiations will be used if its called twice for the same type.
* Function parameters are placeholders for argument expressions. If `constexpr` or `consteval`, the arguments are passed through at compile time. But usually happens at runtime.

Two-phase translation:
* compiler encounters template definition. cannot generate code for instantitation yet (doesn't know what typename it will be invoked with). stores it on the symbol table.
* 1st phase: parses the template declaration (just once for each template)
* 2nd phase: instantiates the template for a particular combination of template arguments (at each instantiation)


### Using templates
Code management:
* typically place all template declarations (including definitions) in headers
-> if symbol is defined in multiple places, linker manages & keeps one copy

Container Class Templates:
* standard c++ library provides various container class templates `list <T>` (doubly linked list) & `vector <T>` (variable length array) & `set <T>` (ordered set).

### Going deeper
Typename keyword:
* Using `typename` keyword in this specific way indicates promise to compiler that its a template, allowing for errors to be thrown earlier
```
 template <typename T>
 typename T::size_type munge(T const &a){
   typename T::size_type * i (T::npos);
 }
```

Specialization vs instantiation:
* not every specialization leads to an instantiation. but every instantiation arises from a specialization.
* normal way is implicit instantiation: compiler automatically generates code.
* explicit instantiation: specify where the compiler should instantiate a particular template specialization - `template <>`
* program must contain exactly one definition for every template instantiatied in program. If you explicitly instnatiate a template in one translation unit, you must ensure that specialization isn't instantiated elsewhere. have to manually turn it off. `extern template void swap<string>(string &a, string &b);` allows translation unit to use specialization without instantiating it.

### Resources
* [CppCon 2019: Dan Saks “Back to Basics: Function and Class Templates” - YouTube](https://www.youtube.com/watch?v=LMP_sxOaz6g)n