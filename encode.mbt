let charMap = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "/"];

/// creates a base64-encoded ASCII string from a binary string
pub fn base64_encode(input: String) -> String {
  let length = input.length();
  let remainder = length % 3;

  let mut output = "";
  let mut i = 0;

  while i + remainder < length {
    let y0 = input[i].to_int();
    let y1 = input[i + 1].to_int();
    let y2 = input[i + 2].to_int();

    // (y0 >> 2) & 0b00111111
    output += charMap[y0.lsr(2).land(0b00111111)];
    // ((y0 << 4) & 0b00110000) | ((y1 >> 4) & 0b00001111)
    output += charMap[y0.lsl(4).land(0b00110000).lor(y1.lsr(4).land(0b00001111))];
    // ((y1 << 2) & 0b00111100) | ((y2 >> 6) & 0b00000011)
    output += charMap[y1.lsl(2).land(0b00111100).lor(y2.lsr(6).land(0b00000011))];
    // y2 & 0b00111111
    output += charMap[y2.land(0b00111111)];

    i += 3;
  }

  match remainder {
    1 => {
      let y0 = input[i].to_int();

      // (y0 >> 2) & 0b00111111
      output += charMap[y0.lsr(2).land(0b00111111)];
      // (y0 << 4) & 0b00110000
      output += charMap[y0.lsl(4).land(0b00110000)];

      output + "=="
    }
    2 => {
      let y0 = input[i].to_int();
      let y1 = input[i + 1].to_int();

      // (y0 >> 2) & 0b00111111
      output += charMap[y0.lsr(2).land(0b00111111)];
      // ((y0 << 4) & 0b00110000) | ((y1 >> 4) & 0b00001111)
      output += charMap[y0.lsl(4).land(0b00110000).lor(y1.lsr(4).land(0b00001111))];
      // (y1 << 2) & 0b00111100
      output += charMap[y1.lsl(2).land(0b00111100)];

      output + "="
    }
    _ => output
  }
}


test {
  if base64_encode("") != "" {
    return Err("base64_encode(\"\") != \"\"")
  }

  if base64_encode("f") != "Zg==" {
    return Err("base64_encode(\"f\") != \"Zg==\"")
  }

  if base64_encode("fo") != "Zm8=" {
    return Err("base64_encode(\"fo\") != \"Zm8=\"")
  }

  if base64_encode("foo") != "Zm9v" {
    return Err("base64_encode(\"foo\") != \"Zm9v\"")
  }

  if base64_encode("foob") != "Zm9vYg==" {
    return Err("base64_encode(\"foob\") != \"Zm9vYg==\"")
  }

  if base64_encode("fooba") != "Zm9vYmE=" {
    return Err("base64_encode(\"fooba\") != \"Zm9vYmE=\"")
  }

  if base64_encode("foobar") != "Zm9vYmFy" {
    return Err("base64_encode(\"foobar\") != \"Zm9vYmFy\"")
  }
}