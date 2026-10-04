///|
test "RFC 4648 encoding and padded or unpadded decoding" {
  let cases : Array[(String, Bytes, String)] = [
    ("", b"", ""),
    ("f", b"f", "Zg=="),
    ("fo", b"fo", "Zm8="),
    ("foo", b"foo", "Zm9v"),
    ("foob", b"foob", "Zm9vYg=="),
    ("fooba", b"fooba", "Zm9vYmE="),
    ("foobar", b"foobar", "Zm9vYmFy"),
  ]
  for (plain, bytes, encoded) in cases {
    assert_eq(@base64.base64_encode(plain), encoded)
    assert_eq(@base64.base64_encode_bytes(bytes[:]), encoded)
    assert_eq(@base64.base64_decode(encoded), Ok(plain))
    assert_eq(@base64.base64_decode_bytes(encoded), Ok(bytes))
    let unpadded = encoded.trim_end(chars="=").to_owned()
    assert_eq(@base64.base64_decode(unpadded), Ok(plain))
    assert_eq(@base64.base64_decode_bytes(unpadded), Ok(bytes))
  }
}

///|
test "existing ASCII decode fixtures" {
  let cases = [
    ("123", "MTIz"),
    ("Hello World!", "SGVsbG8gV29ybGQh"),
    ("1234567890987654321{}/[;',.", "MTIzNDU2Nzg5MDk4NzY1NDMyMXt9L1s7Jywu"),
  ]
  for (plain, encoded) in cases {
    assert_eq(@base64.base64_encode(plain), encoded)
    assert_eq(@base64.base64_decode(encoded), Ok(plain))
  }
}

///|
test "Unicode uses UTF-8 and preserves control characters and BOM" {
  // Expected bytes and Base64 strings were generated independently with Python.
  let cases : Array[(String, Bytes, String)] = [
    ("你好", b"\xe4\xbd\xa0\xe5\xa5\xbd", "5L2g5aW9"),
    (
      "中文测试", b"\xe4\xb8\xad\xe6\x96\x87\xe6\xb5\x8b\xe8\xaf\x95", "5Lit5paH5rWL6K+V",
    ),
    ("😀", b"\xf0\x9f\x98\x80", "8J+YgA=="),
    ("A😀B", b"\x41\xf0\x9f\x98\x80\x42", "QfCfmIBC"),
    (
      "😀😃😄", b"\xf0\x9f\x98\x80\xf0\x9f\x98\x83\xf0\x9f\x98\x84", "8J+YgPCfmIPwn5iE",
    ),
    ("e\u{0301}", b"\x65\xcc\x81", "ZcyB"),
    ("\u{0000}", b"\x00", "AA=="),
    ("\u{0000}A\u{0000}B\u{0000}", b"\x00\x41\x00\x42\x00", "AEEAQgA="),
    ("\t\n\r\u{001f}\u{007f}", b"\x09\x0a\x0d\x1f\x7f", "CQoNH38="),
    ("\u{FEFF}", b"\xef\xbb\xbf", "77u/"),
    (
      "\u{FEFF}你好😀", b"\xef\xbb\xbf\xe4\xbd\xa0\xe5\xa5\xbd\xf0\x9f\x98\x80",
      "77u/5L2g5aW98J+YgA==",
    ),
    ("é", b"\xc3\xa9", "w6k="),
    ("aé", b"\x61\xc3\xa9", "YcOp"),
    ("éa", b"\xc3\xa9\x61", "w6lh"),
    ("aéb", b"\x61\xc3\xa9\x62", "YcOpYg=="),
    ("€", b"\xe2\x82\xac", "4oKs"),
    ("a€", b"\x61\xe2\x82\xac", "YeKCrA=="),
    ("€a", b"\xe2\x82\xac\x61", "4oKsYQ=="),
    ("a€b", b"\x61\xe2\x82\xac\x62", "YeKCrGI="),
    ("a😀", b"\x61\xf0\x9f\x98\x80", "YfCfmIA="),
    ("😀a", b"\xf0\x9f\x98\x80\x61", "8J+YgGE="),
    ("ab😀c", b"\x61\x62\xf0\x9f\x98\x80\x63", "YWLwn5iAYw=="),
    (
      "\u{007f}\u{0080}\u{07ff}\u{0800}\u{ffff}\u{10000}\u{10ffff}", b"\x7f\xc2\x80\xdf\xbf\xe0\xa0\x80\xef\xbf\xbf\xf0\x90\x80\x80\xf4\x8f\xbf\xbf",
      "f8KA37/goIDvv7/wkICA9I+/vw==",
    ),
  ]
  for (plain, bytes, encoded) in cases {
    assert_eq(@base64.base64_encode(plain), encoded)
    assert_eq(@base64.base64_decode(encoded), Ok(plain))
    assert_eq(@base64.base64_encode_bytes(bytes[:]), encoded)
    assert_eq(@base64.base64_decode_bytes(encoded), Ok(bytes))
    let unpadded = encoded.trim_end(chars="=").to_owned()
    assert_eq(@base64.base64_decode(unpadded), Ok(plain))
    assert_eq(@base64.base64_decode_bytes(unpadded), Ok(bytes))
  }
}

///|
test "binary byte values and standard Base64 alphabet" {
  let cases : Array[(Bytes, String)] = [
    (b"\x00\x7f\x80\xff", "AH+A/w=="),
    (b"\xff", "/w=="),
    (b"\xff\xff", "//8="),
    (b"\xff\xff\xff", "////"),
    (b"\xfb\xef\xff", "++//"),
  ]
  for (bytes, encoded) in cases {
    assert_eq(@base64.base64_encode_bytes(bytes[:]), encoded)
    assert_eq(@base64.base64_decode_bytes(encoded), Ok(bytes))
    let unpadded = encoded.trim_end(chars="=").to_owned()
    assert_eq(@base64.base64_decode_bytes(unpadded), Ok(bytes))
  }
}

///|
test "all 256 byte values across multiple blocks and sliced BytesView" {
  let bytes = Bytes::makei(256, i => i.to_byte())
  let encoded = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGFiY2RlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn+AgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6ChoqOkpaanqKmqq6ytrq+wsbKztLW2t7i5uru8vb6/wMHCw8TFxsfIycrLzM3Oz9DR0tPU1dbX2Nna29zd3t/g4eLj5OXm5+jp6uvs7e7v8PHy8/T19vf4+fr7/P3+/w=="
  assert_eq(@base64.base64_encode_bytes(bytes[:]), encoded)
  assert_eq(@base64.base64_decode_bytes(encoded), Ok(bytes))
  assert_eq(
    @base64.base64_decode_bytes(encoded.trim_end(chars="=").to_owned()),
    Ok(bytes),
  )
  assert_eq(@base64.base64_encode_bytes(bytes[1:4]), "AQID")
  assert_eq(@base64.base64_encode_bytes(bytes[252:256]), "/P3+/w==")
  assert_eq(@base64.base64_encode_bytes(bytes[5:5]), "")
}

///|
test "independent binary vectors at block and BytesView boundaries" {
  // Oracle: Python base64.b64encode(bytes((i * 73 + 19) % 256 for i in range(40))[start:start + length]).
  let bytes = Bytes::makei(40, i => ((i * 73 + 19) % 256).to_byte())
  let cases : Array[(Int, Int, String)] = [
    (0, 0, ""),
    (0, 1, "Ew=="),
    (0, 2, "E1w="),
    (0, 3, "E1yl"),
    (0, 4, "E1yl7g=="),
    (0, 5, "E1yl7jc="),
    (0, 6, "E1yl7jeA"),
    (0, 7, "E1yl7jeAyQ=="),
    (0, 8, "E1yl7jeAyRI="),
    (1, 31, "XKXuN4DJEluk7TZ/yBFao+w1fscQWaLrNH3GD1ih6g=="),
    (2, 32, "pe43gMkSW6TtNn/IEVqj7DV+xxBZous0fcYPWKHqM3w="),
    (3, 33, "7jeAyRJbpO02f8gRWqPsNX7HEFmi6zR9xg9YoeozfMUO"),
  ]
  for (start, length, encoded) in cases {
    let view = bytes[start:start + length]
    assert_eq(@base64.base64_encode_bytes(view), encoded)
    assert_eq(@base64.base64_decode_bytes(encoded), Ok(view.to_owned()))
    assert_eq(
      @base64.base64_decode_bytes(encoded.trim_end(chars="=").to_owned()),
      Ok(view.to_owned()),
    )
  }
}

///|
test "large binary slices with zero one and two byte tails" {
  // Python base64.b64encode((b"\x00\xff\x80" * 342)[:length]) verified these compressed fixtures.
  let pattern = b"\x00\xff\x80"
  let bytes = Bytes::makei(1030, i => pattern[i % 3])
  let full_blocks = "AP+A".repeat(341)
  let cases = [
    (1024, full_blocks + "AA=="),
    (1025, full_blocks + "AP8="),
    (1026, full_blocks + "AP+A"),
  ]
  for (length, encoded) in cases {
    let view = bytes[3:3 + length]
    assert_eq(@base64.base64_encode_bytes(view), encoded)
    assert_eq(@base64.base64_decode_bytes(encoded), Ok(view.to_owned()))
    assert_eq(
      @base64.base64_decode_bytes(encoded.trim_end(chars="=").to_owned()),
      Ok(view.to_owned()),
    )
  }
}

///|
test "invalid Base64 is rejected consistently by text and bytes APIs" {
  let inputs = [
    "Z", "AAAAA", "Zg=", "Zg===", "=", "==", "===", "====", "Zm8==", "Zm9v=", "Zm9v==",
    "=Zg=", "Z=g=", "Zg=A", "AA=A", "A===", "Zg==AA==", "Zg==Zm9v", "AA==AAAA", "AAAA=AAA",
    "AAAAAA=A", "AAAA====", "AAAAZg==A", "Zg$=", "Zg-=", "Zg_=", "$$$$", "!AAA",
    "A!AA", "AA!A", "AAA!", " Zg==", "Zg== ", "Z g==", "Zg\t==", "Zg\n==", "Zg\r==",
    "Zg\r\n==", "Zg==\u{00a0}", "你好", "éAAA", "AAA😀", "AAA\u{0100}", "Zh",
    "Zh==", "Zm9", "Zm9=", "AB", "AB==", "AAB", "AAB=", "/x==", "//9=", "Zm9vZh==",
    "Zm9vZh", "Zm9vZm9=", "Zm9vZm9", "Zm9v$g==", "Zm9vZ$==", "Zm9vZg$=", "Zm9vZg=$",
    "Zm9vZm$=", "Zm9vZm8$", "Zm9v$$$$", "Zm9vAA=A", "Zm9vA===",
  ]
  for input in inputs {
    assert_eq(@base64.base64_decode(input), Err("invalid base64 input"))
    assert_eq(@base64.base64_decode_bytes(input), Err("invalid base64 input"))
  }
}

///|
test "every nonzero unused pad bit is rejected" {
  let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  for index = 0; index < 64; index = index + 1 {
    let last = alphabet[index:index + 1].to_owned()
    for prefix in ["", "Zm9v"] {
      if index % 16 != 0 {
        let tail = prefix + "A" + last
        for input in [tail, tail + "=="] {
          assert_eq(
            @base64.base64_decode_bytes(input),
            Err("invalid base64 input"),
          )
          assert_eq(@base64.base64_decode(input), Err("invalid base64 input"))
        }
      }
      if index % 4 != 0 {
        let tail = prefix + "AA" + last
        for input in [tail, tail + "="] {
          assert_eq(
            @base64.base64_decode_bytes(input),
            Err("invalid base64 input"),
          )
          assert_eq(@base64.base64_decode(input), Err("invalid base64 input"))
        }
      }
    }
  }
}

///|
test "valid Base64 with invalid UTF-8 remains available as bytes" {
  let cases : Array[(Bytes, String)] = [
    (b"\x80", "gA=="),
    (b"\xff", "/w=="),
    (b"\xc0\xaf", "wK8="),
    (b"\xe0\x80\xaf", "4ICv"),
    (b"\xed\xa0\x80", "7aCA"),
    (b"\xf4\x90\x80\x80", "9JCAgA=="),
    (b"\xc2", "wg=="),
    (b"\xe2\x82", "4oI="),
    (b"\xf0\x9f\x98", "8J+Y"),
    (b"\x41\x80\x42", "QYBC"),
    (b"\xc2\x41", "wkE="),
    (b"\xe2\x28\xa1", "4iih"),
    (b"\xf0\x28\x8c\xbc", "8CiMvA=="),
  ]
  for (bytes, encoded) in cases {
    assert_eq(@base64.base64_encode_bytes(bytes[:]), encoded)
    assert_eq(@base64.base64_decode_bytes(encoded), Ok(bytes))
    assert_eq(@base64.base64_decode(encoded), Err("invalid UTF-8 input"))
    let unpadded = encoded.trim_end(chars="=").to_owned()
    assert_eq(@base64.base64_decode_bytes(unpadded), Ok(bytes))
    assert_eq(@base64.base64_decode(unpadded), Err("invalid UTF-8 input"))
  }
}
