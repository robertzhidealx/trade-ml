# Bitcoin Trading Game

## Project Setup

First, check the `src/dune` for any libraries not yet locally installed. Then follow their docs listed below to install using `opam install x`.

> Note that for the `ocaml-cohttp` library specifically, please make sure `tls` is locally installed via `opam install tls`. This is not well-documented by the offical docs.

Listed below are the official docs of some of the libraries used.

- [ocaml-cohttp](https://github.com/mirage/ocaml-cohttp#installation)
- [Ocaml CSV](https://github.com/Chris00/ocaml-csv)
- [ocaml-torch](https://github.com/LaurentMazare/ocaml-torch)

## Running the Project

Run a fresh `dune clean` and `dune build`, and then run

```ocaml
dune exec ./src/app.exe
```

to execute the app compiled from app.ml. Supporting functions are in `lib.ml` as specified by `lib.mli`.

## Structure
`forecasting/data` contains the data set we use for training our time series forecasting model and backtesting.

`forecasting/model` contains the code for training the model.

`src` contains the code for our app.

