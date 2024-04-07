fn main {
  let id = match @lib.base64_decode("MTIzNDU2Nzg5MDk4NzY1NDMyMXt9L1s7Jywu") {
    Ok(str) => str
    _ => ""
  }

  println(id);

  let id = @lib.base64_encode("Hello")

  println(id);

  let id = @lib.base64_encode("你好")

  println(id);
}
