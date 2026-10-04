///|
/// Encodes well-formed Unicode text as UTF-8, then as padded RFC 4648 Base64.
pub fn base64_encode(input : String) -> String {
  base64_encode_bytes(@utf8.encode(input))
}

///|
/// Encodes arbitrary bytes using the standard Base64 alphabet and `=` padding.
pub fn base64_encode_bytes(input : BytesView) -> String {
  let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  let output = StringBuilder()
  let length = input.length()
  let remainder = length % 3
  let full_length = length - remainder
  let mut index = 0
  while index < full_length {
    let first = input[index].to_int()
    let second = input[index + 1].to_int()
    let third = input[index + 2].to_int()
    output.write_substring(alphabet, first >> 2, 1)
    output.write_substring(alphabet, ((first & 3) << 4) | (second >> 4), 1)
    output.write_substring(alphabet, ((second & 15) << 2) | (third >> 6), 1)
    output.write_substring(alphabet, third & 63, 1)
    index += 3
  }
  match remainder {
    1 => {
      let first = input[index].to_int()
      output.write_substring(alphabet, first >> 2, 1)
      output.write_substring(alphabet, (first & 3) << 4, 1)
      output.write_string("==")
    }
    2 => {
      let first = input[index].to_int()
      let second = input[index + 1].to_int()
      output.write_substring(alphabet, first >> 2, 1)
      output.write_substring(alphabet, ((first & 3) << 4) | (second >> 4), 1)
      output.write_substring(alphabet, (second & 15) << 2, 1)
      output.write_char('=')
    }
    _ => ()
  }
  output.to_string()
}
