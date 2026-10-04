# Base64 for MoonBit

**Discontinued — 0.3.0 is the final release.** MoonBit's official standard library
now provides [Base64 encoding and decoding](https://github.com/moonbitlang/core/tree/main/encoding/base64).
Use the official package for new code. This repository is retained as a public
archive; no further features, fixes, or releases are planned.

UTF-8 text and binary Base64 encoding with the standard
[RFC 4648](https://www.rfc-editor.org/rfc/rfc4648.html) alphabet. Version 0.3.0
updates the original 0.1.0 Base64 implementation and preserves the existing API.
Text conversion uses MoonBit's standard UTF-8 module; there are no third-party
dependencies.

Requires MoonBit **v0.10.14 or later**. The module uses the current `moon.mod`
and `moon.pkg` formats. Supported backends: Wasm, Wasm GC, JavaScript, and native.

## Use the official package

Import the standard library directly; no `moon add` is needed:

```moonbit
import {
  "moonbitlang/core/encoding/base64",
  "moonbitlang/core/encoding/utf8",
} for "test"
```

Put this example in a `*_test.mbt` file:

```moonbit
test "official Base64 with Unicode" {
  let text = "你好🌙"
  let encoded = @base64.encode(@utf8.encode(text))
  assert_eq(encoded, "5L2g5aW98J+MmQ==")
  assert_eq(@utf8.decode(@base64.decode(encoded)), text)
}
```

Omit `for "test"` for application or library imports. The official Base64 API
encodes bytes and decodes to bytes; use the UTF-8 module for text. Its strict
decoder raises `Malformed` on invalid input, whereas this package's decode
functions return `Result`.

## Archived package usage

Add the published module:

```sh
moon add PerfectPan/base64
```

For the black-box test example below, import the package in your `moon.pkg`:

```moonbit
import {
  "PerfectPan/base64",
} for "test"
```

Omit `for "test"` when importing it for application or library source code.
Put the example in a `*_test.mbt` file. Encode Unicode text through UTF-8, or use
the byte API for binary data:

```moonbit
test "text and bytes" {
  assert_eq(@base64.base64_encode("你好🌙"), "5L2g5aW98J+MmQ==")
  assert_eq(@base64.base64_decode("5L2g5aW98J+MmQ=="), Ok("你好🌙"))
  assert_eq(@base64.base64_decode("Zg"), Ok("f"))

  assert_eq(@base64.base64_encode_bytes(b"\x00\xFF\x80"), "AP+A")
  assert_eq(@base64.base64_decode_bytes("AP+A"), Ok(b"\x00\xFF\x80"))
  assert_eq(@base64.base64_decode("AP+A"), Err("invalid UTF-8 input"))
}
```

## API

| Function | Input | Output |
| --- | --- | --- |
| `base64_encode` | `String` | `String` |
| `base64_decode` | `String` | `Result[String, String]` |
| `base64_encode_bytes` | `BytesView` | `String` |
| `base64_decode_bytes` | `String` | `Result[Bytes, String]` |

- Encoding uses `A–Z`, `a–z`, `0–9`, `+`, `/` and includes `=` padding when needed.
- Decoding accepts both padded and unpadded input, including the empty string.
- Whitespace, URL-safe `-`/`_`, non-ASCII characters, invalid lengths, misplaced
  padding, and nonzero unused pad bits return `Err("invalid base64 input")`.
- Text decoding requires valid UTF-8 and preserves a leading BOM and NUL
  characters. Invalid UTF-8 returns `Err("invalid UTF-8 input")`; the byte API
  accepts arbitrary decoded bytes.
- Text encoding expects well-formed Unicode. For raw bytes or strings containing
  isolated UTF-16 surrogates, use the byte API with an explicit byte encoding.
  Unicode normalization is not performed.

The existing string function signatures are preserved. Since 0.2.0, non-ASCII
text is encoded as UTF-8; malformed input that older versions accepted or crashed
on now returns an error. Use the byte API when the decoded data is not text.

## Development

These commands are retained for validating the final source and working on forks.

Install or update the [stable MoonBit toolchain](https://www.moonbitlang.com/download/),
then run:

```sh
moon version --all
moon fmt
moon check --deny-warn --target wasm,wasm-gc,js,native
moon test --deny-warn --target wasm,wasm-gc,js,native
moon info --target wasm,wasm-gc,js,native
moon fmt --check
python3 -m unittest discover -s scripts -p 'test_*.py'
```

Commit `pkg.generated.mbti` when the public API changes. JavaScript tests require
Node.js; native tests require a C compiler. The publish preflight and its tests
use Python 3's standard library. Work is committed and pushed directly to `main`
after verification. CI runs checks on pushes and pull requests.

## Release procedure

The procedure below is retained as a maintainer reference. Version 0.3.0 is the
final planned release. Publishing is a local operation; CI does not upload
releases.

1. Update `version` in `moon.mod` to an unused semantic version. Check published
   versions with `moon view PerfectPan/base64 --versions`.
2. Run the development checks above, review the diff, and commit and push `main`.
3. Inspect the exact package contents and rehearse publishing:

   ```sh
   moon package --list
   moon package
   python3 scripts/check_publish.py
   ```

   The preflight runs `moon publish --dry-run`. With `moon 0.1.20260920` and
   `mooncake-bin 0.1.20260911`, the publisher treats the registry's successful
   `202 Accepted` dry-run response as a failure and exits 255. The preflight
   accepts this specific response only when it confirms that no changes were
   made and names the current module and version. Other errors remain failures;
   a native successful exit is passed through. This is a local compatibility
   fix and does not change the installed toolchain or publish a version.

4. Confirm `moon whoami` identifies the module owner (`PerfectPan`). Use
   `moon login` if needed, then publish:

   ```sh
   moon publish
   moon view PerfectPan/base64 --versions
   ```

`.moonignore` defines the release contents. Build outputs, credentials, logs,
and development-only files stay out of the archive. Keep authentication in the
toolchain's local credential store.

## License

[MIT](LICENSE).
