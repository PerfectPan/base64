///|
/// Encodes well-formed Unicode text as UTF-8, then as padded RFC 4648 Base64.
pub fn base64_encode(input : String) -> String {
  base64_encode_bytes(@utf8.encode(input))
}

///|
/// Encodes arbitrary bytes using the standard Base64 alphabet and `=` padding.
pub fn base64_encode_bytes(input : BytesView) -> String {
  @base64_core.encode(input)
}
