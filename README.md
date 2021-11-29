# Bitcoin Trading Game

## Project Setup

First, check the `src/dune` for any libraries not yet locally installed. Then follow their docs listed below to install using `opam install x`.

> Note that for the `ocaml-cohttp` library specifically, please make sure `tls` is locally installed via `opam install tls`. This is not well-documented by the offical docs.

> Install PostgreSQL-OCaml via `opam install postgresql`

Listed below are the official docs of some of the libraries used.

- [ocaml-cohttp](https://github.com/mirage/ocaml-cohttp#installation)
- [Ocaml CSV](https://github.com/Chris00/ocaml-csv)
- [ocaml-torch](https://github.com/LaurentMazare/ocaml-torch)
- [PostgreSQL-OCaml](https://github.com/mmottl/postgresql-ocaml)

## Running the Project

First run a fresh `dune clean` and `dune build`. Then configure the database as follows.

> Prereq: Make sure there is a Superuser named `postgres` in your Postgresql system. See [this](https://stackoverflow.com/questions/15301826/psql-fatal-role-postgres-does-not-exist) Stackoverflow post for instructions.

Start the local database server (MacOS) by running

```
brew services start postgresql
```

and create a database named `testdb` by running

```
createdb -h localhost -p 5432 -U postgres -O postgres testdb
```

to start the local postgresql database server, and then run

```ocaml
dune exec ./src/app.exe
```

to execute the app compiled from app.ml. Supporting functions are in `lib.ml` as specified by `lib.mli`.

## Structure

`forecasting/data` contains the data set we use for training our time series forecasting model and backtesting.

`forecasting/model` contains the code for training the model.

`src` contains the code for our app.
