# Review Club on Bech32m

2. *Can you describe the length extension mutation issue found in Bech32? Does it affect Bitcoin addresses? Why or why not?*
* if the address ends with a “p”, you can insert or delete “q” characters right before won’t invalidate the checksum.

* doesn’t really matter for bitcoin because our addresses are fixed length (20 or 32?)

3. *How does Bech32m solve this length extension mutation issue?*

* bech32m replaces the constant 1 thats xored into the checksum at the end with `0x2bc830a3`

4. *Which addresses will be encoded using Bech32, and which ones with Bech32m? How does this effect the compatibility of existing software clients?*

* segwit outputs with witness version 0 will continue to use bech32, but witness version 1 or higher will use bech32m

5. *What are the three components of a Bech32m address encoding?*

[bips/bip-0173.mediawiki at master · bitcoin/bips · GitHub](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki)
* human-readable part
* separator: `1`
* data part: at least 6 chars long, only consists of alphanumeric characters and excludes some characters
	* checksum  is last 6 characters of data part

6. *How does  Decode() check whether an address is encoded as Bech32 or Bech32m? Can a string be valid in both formats?*

* a string cannot be valid in both formats
* side note: surprised this is a manual for loop, rather than a range based for loop?

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

*Learnings*
* `char` is 1 byte, which is 8 bits, which has 256 options, half of which is 128


7. The space in  [this test string](https://github.com/bitcoin/bitcoin/blob/835ff6b8568291870652ca0d33d934039e7b84a8/src/test/bech32_tests.cpp#L80)  is not an accident. What does it test?

8. For fun: Is Bech32 case-sensitive? (Hint: Why is  [“A12UEL5L”](https://github.com/bitcoin/bitcoin/blob/835ff6b8568291870652ca0d33d934039e7b84a8/src/test/bech32_tests.cpp#L16)  valid but  [“A12uEL5L”](https://github.com/bitcoin/bitcoin/blob/835ff6b8568291870652ca0d33d934039e7b84a8/src/test/bech32_tests.cpp#L69)  not?)
