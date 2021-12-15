# Bitcoin Trading Game (TradeML)

## Overview

TradeML is a full-stack web app with a full-fledged Rescript React frontend and Dream backend. With the latest historical data of Bitcoin prices and related financial signals (e.g. volumn), we built a time series forecasting model for Bitcoin price using stacked stateless Long-Short Term Memory (LSTM)[1]. On top of this, we created a simulation game where the user gets to hypothetically trade Bitcoin from a wallet, using the predicted near-future price to facilitite the decision and trade with real-time price).

[1] - The choice of this architecture is based our literature review
of the following paper: https://arxiv.org/abs/2004.10240

Repo: https://github.com/robertzhidealx/btc-game-monorepo

Production Build: https://trade-ml.vercel.app. (See the [App](#app) section for details.)

Team members and responsibilities:

- Jiaxuan Zhang (jzhan239): data retrieval and shaping functions, database module (DB module), game module (Game module), the backend server (`app.ml` - Dream server and related functions), and the frontend web app (React, written in **Rescript**)
- Chuheng Hu (chu29): forecasting model (`./server/forecasting/model` files (data processing & training), Forecast module (loading & inference)), and the backend Visualization module and related Dream server function

## Structure

This monorepo contains the code for both the frontend and backend of our game. `./app` contains code pertaining to the Rescript frontend, and `./server` contains code pertaining to the OCaml backend.

```
.
├── app
│   ├── public
│   │   └── img
│   └── src
│       ├── components
│       ├── img
│       └── utils
└── server
    ├── _coverage
    │   └── src
    ├── forecasting
    │   ├── data
    │   └── model
    ├── src
    └── test
```

## Run

Build the entire project at the root by running `dune clean` and `dune build`. Run all tests at the root by running `dune test`. After running tests, run `bisect-ppx-report html` to generate the coverage html and open it by running `open ./_coverage/index.html`. For details setting up `server` and `app`, refer to the following documentation.

## Server

First, run a dune build under the `server` directory. Install any missing libraries by following their docs listed below to install using `opam install x`.

> Note that for the `ocaml-cohttp` library specifically, please make sure `tls` is locally installed via `opam install tls`. This is not well-documented by the offical docs.

> Install PostgreSQL-OCaml via `opam install postgresql`

> Caution: The ocaml-torch library is NOT compatible with Apple M1 machines, leading to errors on `dune build`. In this case, comment out `module Forecast ...` in both `lib.ml` and `lib.mli`, and comment out calls to `module Forecast` functions in `app.ml` to build other parts of the project.

Listed below are the official docs of the libraries used.

### OCaml

- [ocaml-cohttp](https://github.com/mirage/ocaml-cohttp#installation)
- [Ocaml CSV](https://github.com/Chris00/ocaml-csv)
- [ocaml-torch](https://github.com/LaurentMazare/ocaml-torch)
- [PostgreSQL-OCaml](https://github.com/mmottl/postgresql-ocaml)
- [Dream](https://github.com/aantron/dream)

### Python

- [Pandas](https://pandas.pydata.org/docs/getting_started/install.html)
- [Numpy](https://numpy.org/install/)
- [Matplotlib](https://matplotlib.org/stable/#installation)
- [PyTorch](https://pytorch.org/get-started/locally/)
- [Jupyter](https://jupyter.org/install)
- [Notebook](https://jupyter.org/install)

You can install them using pip/pip3.

### Run

First run a fresh `dune clean` and `dune build` in the `server` directory. Then configure the database as follows.

Install Postgresql on your machine via `brew install postgresql` (MacOS).

> Prereq: Make sure there is a Superuser named `postgres` in your local Postgresql server. A guaranteed solution is to `createdb db` -> `psql db` -> `CREATE USER postgres SUPERUSER;` -> exit `psql` -> `dropdb db` and proceed with the following steps. (See [this post](https://stackoverflow.com/questions/15301826/psql-fatal-role-postgres-does-not-exist) for reference.)

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

### Structure

`server/src` contains the code for our app.

`server/forecasting/data` contains the data set we use for training our time series forecasting model and backtesting.

`server/forecasting/model` contains the code for training the model which is implemented in python.

## App

Cd into the `app` directory. Make sure you have [Node.js](https://nodejs.org/en/download/package-manager/) and [NPM](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) installed locally. The frontend app is written in [Rescript](https://rescript-lang.org/) and uses [rescript-react](https://rescript-lang.org/docs/react/latest/introduction). I recommend installing the rescript-vscode VSCode extension for syntax highlighting and intellisense.

Make sure that the [Server](#server) code is running via the aforementioned steps.

First run `npm install` to set up the dependencies. Then run `npm run start` to start the Rescript compiler in watch mode and run `npm run server` to start the local development server. This is all it takes to start the web app.

I had Vercel wired up such that we would always have the latest production build deployed at https://trade-ml.vercel.app/, so feel free to try our app out there.

Currently, the frontend web app (WIP) is looking like this:

![App](/assets/app.png)
