# Review Club on Bech32m

**Resources**
- short, mathematical explanation of length extension mutation weakness [here](https://bitcoin.stackexchange.com/questions/91602/how-does-the-bech32-length-extension-mutation-weakness-work)
- [bip 173, bech32](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki#bech32)
- [bip 350, bech32m](https://github.com/bitcoin/bips/blob/master/bip-0350.mediawiki)

**Learnings**
- bech32 is essentially the equation `code(x) mod g(x) = 1`
	- `code(x)` is the polynomial corresponding to the data (including checksum) of the bech32 string
	- `g(x) =  x^6 + 29x^5 + 22x^4 + 20x^3 + 21x^2 + 29x + 18`
	- if your string is represented as `p(x)`, you need `p(x) = f(x)*g(x) + 1` aka `p(x) mod g(x) = 1` to be true

2. **Can you describe the length extension mutation issue found in Bech32? Does it affect Bitcoin addresses? Why or why not?**
	* if the address ends with a “p”, you can insert or delete “q” characters right before won’t invalidate the checksum.
	* doesn’t really matter for bitcoin because our addresses are fixed length (20 or 32?)

3. **How does Bech32m solve this length extension mutation issue?**
	* bech32m replaces the constant 1 thats xored into the checksum at the end with `0x2bc830a3`

4. **Which addresses will be encoded using Bech32, and which ones with Bech32m? How does this effect the compatibility of existing software clients?**
	* segwit outputs with witness version 0 will continue to use bech32, but witness version 1 or higher will use bech32m

5. **What are the three components of a Bech32m address encoding?**

	* human-readable part
		* `bc` for bitcoin
		* `bcrt` for bitcoin regtest
		* `tb` for testnet bitcoin 
	* separator: `1`
	* data part: at least 6 chars long, only consists of alphanumeric characters and excludes some characters
		* witness version
		* witness program
		* checksum  is last 6 characters of data part

6. **How does  Decode() check whether an address is encoded as Bech32 or Bech32m? Can a string be valid in both formats?**
	* a string cannot be valid in both formats
	* side note: surprised this is a manual for loop, rather than a range based for loop?
	* xor to get the checksum and checks that it is 1 or the Bech32m constant  

	Decode function:
	* return empty if there are lowercase & uppercase characters
	* return empty if string is >90 characters

	* `rfind` aka search for the last instance of the character `1`
		* return empty if not found
		* return empty if found in the last 7 characters of the string

	* go through the characters of string from pos -> end
		* checks that they are defined on the `CHARSET_REV` list. If there, populate `values[index]` with corresponding `CHARSET_REV` value.

	* go through characters of string from start -> pos
		* lowercase everything, populate `hrp`
		* `VerifyChecksum(hrp, values)`
		* return `(encoding_result, hrp, pos I think?)`

	Relevant: 
	* `char` is 1 byte, which is 8 bits, which has 256 options, half of which is 128


7. **The space in  [this test string](https://github.com/bitcoin/bitcoin/blob/835ff6b8568291870652ca0d33d934039e7b84a8/src/test/bech32_tests.cpp#L80)  is not an accident. What does it test?**
	* 

8. **For fun: Is Bech32 case-sensitive? (Hint: Why is  [“A12UEL5L”](https://github.com/bitcoin/bitcoin/blob/835ff6b8568291870652ca0d33d934039e7b84a8/src/test/bech32_tests.cpp#L16)  valid but  [“A12uEL5L”](https://github.com/bitcoin/bitcoin/blob/835ff6b8568291870652ca0d33d934039e7b84a8/src/test/bech32_tests.cpp#L69)  not?)**
	* kind of, can't be mixed cases 
