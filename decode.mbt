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
  let length = input.length()
  let mut data_length = length
  while data_length > 0 && input[data_length - 1] == 61 {
    data_length -= 1
  }
  let padding = length - data_length
  let remainder = data_length % 4
  if remainder == 1 ||
    (
      padding > 0 &&
      (
        length % 4 != 0 ||
        padding > 2 ||
        (padding == 1 && remainder != 3) ||
        (padding == 2 && remainder != 2)
      )
    ) {
    return Err("invalid base64 input")
  }
  let tail_length = match remainder {
    2 => 1
    3 => 2
    _ => 0
  }
  let output_length = data_length / 4 * 3 + tail_length
  let output = FixedArray::make(output_length, b'\x00')
  let full_length = data_length - remainder
  let mut index = 0
  let mut output_index = 0
  while index < full_length {
    let first = decode_digit(input[index].to_int())
    let second = decode_digit(input[index + 1].to_int())
    let third = decode_digit(input[index + 2].to_int())
    let fourth = decode_digit(input[index + 3].to_int())
    if first < 0 || second < 0 || third < 0 || fourth < 0 {
      return Err("invalid base64 input")
    }
    output[output_index] = ((first << 2) | (second >> 4)).to_byte()
    output[output_index + 1] = (((second & 15) << 4) | (third >> 2)).to_byte()
    output[output_index + 2] = (((third & 3) << 6) | fourth).to_byte()
    index += 4
    output_index += 3
  }
  // Each short final group must have zero unused bits, with or without `=`.
  match remainder {
    2 => {
      let first = decode_digit(input[index].to_int())
      let second = decode_digit(input[index + 1].to_int())
      if first < 0 || second < 0 || (second & 15) != 0 {
        return Err("invalid base64 input")
      }
      output[output_index] = ((first << 2) | (second >> 4)).to_byte()
    }
    3 => {
      let first = decode_digit(input[index].to_int())
      let second = decode_digit(input[index + 1].to_int())
      let third = decode_digit(input[index + 2].to_int())
      if first < 0 || second < 0 || third < 0 || (third & 3) != 0 {
        return Err("invalid base64 input")
      }
      output[output_index] = ((first << 2) | (second >> 4)).to_byte()
      output[output_index + 1] = (((second & 15) << 4) | (third >> 2)).to_byte()
    }
    _ => ()
  }
  Ok(Bytes::from_array(output[:]))
}

///|
fn decode_digit(code_unit : Int) -> Int {
  match code_unit {
    65..=90 => code_unit - 65
    97..=122 => code_unit - 97 + 26
    48..=57 => code_unit - 48 + 52
    43 => 62
    47 => 63
    _ => -1
  }
}
