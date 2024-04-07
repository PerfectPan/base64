let asciiMap = ['\x00', '\x01', '\x02', '\x03', '\x04', '\x05', '\x06', '\x07', '\x08', '\x09', '\x0A', '\x0B', '\x0C', '\x0D', '\x0E', '\x0F', '\x10', '\x11', '\x12', '\x13', '\x14', '\x15', '\x16', '\x17', '\x18', '\x19', '\x1A', '\x1B', '\x1C', '\x1D', '\x1E', '\x1F', ' ', '!', '"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',', '-', '.', '/', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ':', ';', '<', '=', '>', '?', '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '[', '\\', ']', '^', '_', '`', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '{', '|', '}', '~', '\x7F'];

let decodeMap = [64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64, 64, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64, 64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64];

fn isInvalid(ch: Char) -> Bool {
  ch.to_int() > 127 || ch == '=' || decodeMap[ch.to_int()] >= 64 
}

/// decodes a string of data which has been encoded using base64 encoding
pub fn base64_decode(input: String) -> Result[String, String] {
  let mut length = input.length();
  // pre calculate the output size
  // let mut output_size = length / 4 * 3;
  // match length % 4 {
  //   0 => {
  //     if input[length - 1] == '=' {
  //       output_size -= 1;
  //     }
  //     if input[length - 2] == '=' {
  //       output_size -= 1;
  //     }
  //   }
  //   2 => output_size += 1
  //   3 => output_size += 2
  //   // remainder 1
  //   _ => return Err("invalid base64 input")
  // }

  let remainder = length % 4;
  if remainder == 0 {
    if input[length - 1] == '=' {
      length -= 1;
    }
    if input[length - 1] == '=' {
      length -= 1;
    }
  }

  if remainder == 1 {
    return Err("invalid base64 input")
  }

  // remove padding remainder
  let remainder = length % 4;

  let chunk_size = if remainder == 0 {
    length / 4 - 1
   } else {
    length / 4
   };

  let mut output = "";

  let mut i = 0;
  let mut idx = 0;

  while i < chunk_size {
    if isInvalid(input[idx]) || isInvalid(input[idx + 1]) || isInvalid(input[idx + 2]) || isInvalid(input[idx + 3]) {
      return Err("invalid base64 input")
    }
    // 4 byte convert to 3 byte
    let y0 = decodeMap[input[idx].to_int()];
    let y1 = decodeMap[input[idx + 1].to_int()];
    let y2 = decodeMap[input[idx + 2].to_int()];
    let y3 = decodeMap[input[idx + 3].to_int()];

    // ((y0 << 2) & 0b11111111) | ((y0 >> 4) & 0b00000011)
    output += asciiMap[y0.lsl(2).land(0b11111111).lor(y1.lsr(4).land(0b00000011))].to_string();
    // ((y1 << 4) & 0b11111111) | ((y2 >> 2) & 0b00001111)
    output += asciiMap[y1.lsl(4).land(0b11111111).lor(y2.lsr(2).land(0b00001111))].to_string();
    // ((y2 << 6) & 0b11111111) | (y3 & 0b00111111)
    output += asciiMap[y2.lsl(6).land(0b11111111).lor(y3.land(0b00111111))].to_string();

    i += 1;
    idx += 4;
  }

  match remainder {
    0 => {
      // 4 byte convert to 3 byte
      let y0 = decodeMap[input[idx].to_int()];
      let y1 = decodeMap[input[idx + 1].to_int()];
      let y2 = decodeMap[input[idx + 2].to_int()];
      let y3 = decodeMap[input[idx + 3].to_int()];

      // ((y0 << 2) & 0b11111111) | ((y0 >> 4) & 0b00000011)
      output += asciiMap[y0.lsl(2).land(0b11111111).lor(y1.lsr(4).land(0b00000011))].to_string();
      // ((y1 << 4) & 0b11111111) | ((y2 >> 2) & 0b00001111)
      output += asciiMap[y1.lsl(4).land(0b11111111).lor(y2.lsr(2).land(0b00001111))].to_string();
      // ((y2 << 6) & 0b11111111) | (y3 & 0b00111111)
      output += asciiMap[y2.lsl(6).land(0b11111111).lor(y3.land(0b00111111))].to_string();
    }
    2 => {
      let y0 = decodeMap[input[idx].to_int()];
      let y1 = decodeMap[input[idx + 1].to_int()];
      // ((y0 << 2) & 0b11111111) | ((y0 >> 4) & 0b00000011)
      output += asciiMap[y0.lsl(2).land(0b11111111).lor(y1.lsr(4).land(0b00000011))].to_string();
    }
    3 => {
      let y0 = decodeMap[input[idx].to_int()];
      let y1 = decodeMap[input[idx + 1].to_int()];
      let y2 = decodeMap[input[idx + 2].to_int()];
      // ((y0 << 2) & 0b11111111) | ((y0 >> 4) & 0b00000011)
      output += asciiMap[y0.lsl(2).land(0b11111111).lor(y1.lsr(4).land(0b00000011))].to_string();
      // ((y1 << 4) & 0b11111111) | ((y2 >> 2) & 0b00001111)
      output += asciiMap[y1.lsl(4).land(0b11111111).lor(y2.lsr(2).land(0b00001111))].to_string();
    }
    _ => return Err("invalid base64 input")
  }

  Ok(output);
}


test "decode_without_padding" {
  if base64_decode("Zg") != Ok("f") {
    return Err("base64_decode(\"Zg\") != Ok(\"f\")")
  }

  if base64_decode("Zm8") != Ok("fo") {
    return Err("base64_decode(\"Zm8\") != Ok(\"fo\")")
  }

  if base64_decode("MTIz") != Ok("123") {
    return Err("base64_decode(\"MTIz\") != Ok(\"123\")")
  }

  if base64_decode("SGVsbG8gV29ybGQh") != Ok("Hello World!") {
    return Err("base64_decode(\"SGVsbG8gV29ybGQh\") != Ok(\"Hello World!\")")
  }

  if base64_decode("Zm9vYmFy") != Ok("foobar") {
    return Err("base64_decode(\"Zm9vYmFy\") != Ok(\"foobar\")")
  }

  if base64_decode("MTIzNDU2Nzg5MDk4NzY1NDMyMXt9L1s7Jywu") != Ok("1234567890987654321{}/[;\',.") {
    return Err("base64_decode(\"MTIzNDU2Nzg5MDk4NzY1NDMyMXt9L1s7Jywu\") != Ok(\"1234567890987654321{}/[;\',.\")")
  }
}

test "decode_with_padding" {
  if base64_decode("Zg==") != Ok("f") {
    return Err("base64_decode(\"Zg==\") != Ok(\"f\")")
  }

  if base64_decode("Zm8=") != Ok("fo") {
    return Err("base64_decode(\"Zm8=\") != Ok(\"fo\")")
  }

  if base64_decode("Zm9vYg==") != Ok("foob") {
    return Err("base64_decode(\"Zm9vYg==\") != Ok(\"foob\")")
  }

  if base64_decode("Zm9vYmE=") != Ok("fooba") {
    return Err("base64_decode(\"Zm9vYmE=\") != Ok(\"fooba\")")
  }
}

test "decode_failed" {
  if base64_decode("Z") != Err("invalid base64 input") {
    return Err("base64_decode(\"Z\") != Err(\"invalid base64 input\")")
  }
}
