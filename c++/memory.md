## prompt: understanding granular memory usage

### `sizeof` function
* returns the number of bytes allocated for an object
* it's a compile time function, so doesn't handle any dynamically allocated
  memory
* pointer interaction: `sizeof(ptr<thing>)` will just return the size of a
  pointer, completely independently of what it is pointing to
* an int takes 4 bytes on my macbook, which is common
* a pointer takes 8 bytes on my macbook, which is common for 64-bit systems
* for exercise: look at [cpplay sizeof exercise](https://github.com/amitiuttarwar/cpplay/blob/master/sizeof.cpp)

### `memusage.h` header in bitcoin core
* `DynamicUsage(v)` returns information about dynamically allocated objects.
  For pointer types, takes the `sizeof` of the managed object. For list types,
  multiplies the `sizeof` value by the number of objects on the list.