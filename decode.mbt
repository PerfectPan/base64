///|
/// Decodes padded or unpadded Base64 as strict UTF-8, preserving a leading BOM.
/// Returns `Err("invalid base64 input")` for malformed Base64 or
/// `Err("invalid UTF-8 input")` when the decoded bytes are not valid UTF-8.
pub fn base64_decode(input : String) -> Result[String, String] {
  match base64_decode_bytes(input) {
    Err(error) => Err(error)
    Ok(bytes) =>
      try @utf8.decode(bytes) catch {
        _ => Err("invalid UTF-8 input")
      } noraise {
        text => Ok(text)
      }
  }
}

///|
/// Decodes standard Base64 to arbitrary bytes, accepting padded or unpadded input.
/// Rejects whitespace, invalid characters, misplaced padding, and nonzero pad
/// bits with `Err("invalid base64 input")`.
pub fn base64_decode_bytes(input : String) -> Result[Bytes, String] {
  try @base64_core.decode(input) catch {
    _ => Err("invalid base64 input")
  } noraise {
    bytes => Ok(bytes)
  }
}
