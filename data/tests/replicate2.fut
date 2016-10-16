-- Replicate with an unsigned type where zero-extension is important.
--
-- ==
-- input { 128u8 }
-- output { [42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32,
--           42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32, 42i32] }


fun main(n: u8): []int =
  replicate n 42