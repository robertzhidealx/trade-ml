open Torch

let () =
  let tensor = Tensor.randn [ 4; 2 ] in
  Tensor.print tensor