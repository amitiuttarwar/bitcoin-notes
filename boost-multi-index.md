## Resources
`https://www.boost.org/doc/libs/1_75_0/libs/multi_index/doc/tutorial/basics.html`

## Examples
- use case: multiple sorts on a single set, according to different keys
- for this, we use ordered indices
- in isolation, each index behaves similar to a `std::set`

- use case: bidirectional list with fast lookup
- a `std::list` is usually a doubly-linked list, so supports constant time
  insertion & removal of elements from anywhere in the container, if you pass
  in the iterator to the element. for an example where you'd parse text into
  words, you'd have to traverse the whole list (eg. using `std::count`) to
  compare strings, so linear time complexity.
- for improved performance, we can use a combination of sequenced and ordered
  indices to index the elements
- `sequenced` provides a "list-like index" -> aka an intrinsic order. used in
  bitcoin core for `DisconnectedBlockTransactions` to sort the blocks in the
  order they appeared in the blockchain.

### Defining the index
```
typedef multi_index_container <
  CLASS_NAME,
  indexed_by<
    INDEX_TYPE<INFO<VAR(S)>>,
    INDEX_TYPE<INFO<VAR(S)>>
  >
> CONTAINER_NAME;
```

- each argument to `indexed_by` is called an `index specifier`

`INDEX_TYPES:`
- `ordered_unique`
- `ordered_non_unique`
- `hashed_unique`
- `sequenced`

`INFO`:
- depending on the index type specified, the specifier might need additional
  information, or have optional fields
- `tag`
- `identity`
- `member`

---

- `indexed_by` defines a list of index specifications. each one can be called a
  "comparison predicate"


### Accessing the index
- indices can be accessed via `get<NUM>`
- if a `tag` is specified, its an easier way to retreive an index, instead of
  specifying the index by order number `get<NAME>`. must be a c++ type

`const CONTAINER_NAME::nth_index<NUM>::type& VAR_NAME = CONTAINER_NAME.get<NUM>();`
- `CONTAINER_NAME` is the name of the `boost::multi_index_container`
- `NUM` matches up with the comparison predicate
- `type` keyword indicates its the type of the index

- then can use `VAR_NAME` as a normal `std::set`
- `get` returns a *reference* to the index, not an index object

- the functionality of index #0 can be accessed directly from the
  `multi_index_container` object without using `get<0>()`
eg. `CONTAINER_NAME.get<0>`

-
