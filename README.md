# Bitcoin Trading Game (TradeML)

## Overview

TradeML is a full-stack web app with a full-fledged Rescript React frontend and OCaml Dream backend. With the latest historical data of Bitcoin prices and related financial signals (e.g. volumn), we built a deep neural time series forecasting model for Bitcoin price using stacked stateless Long-Short Term Memory (LSTM)[1]. On top of this, we created a simulation game where the user gets to hypothetically trade Bitcoin from a wallet, using the predicted near-future price to facilitite the decision and trade with real-time price. It also comes with a linechart visualization of recent transactions, e.g., changes in total assets and Bitcoin prices.

[1] - The choice of this architecture is based our literature review
of the following paper: https://arxiv.org/abs/2004.10240

Repo: https://github.com/robertzhidealx/btc-game-monorepo

<!-- Production Build: https://trade-ml.vercel.app. (See the [App](#app) section for details.) -->

Team members and responsibilities:

- Jiaxuan Zhang (jzhan239): data retrieval and shaping functions, database module (DB module), game module (Game module), the backend server (`app.ml` - Dream server and related functions), and the frontend web app (React, written in **Rescript**)
- Chuheng Hu (chu29): forecasting model (`./server/forecasting/model` files (data processing & training), Forecast module (loading & inference)), and the backend Visualization module and related Dream server function

## Structure

This monorepo contains the code for both the frontend and backend of our game. `./app` contains code pertaining to the Rescript frontend, and `./server` contains code pertaining to the OCaml backend.

```
.
├── app
│   ├── public
│   │   └── svg
│   └── src
│       ├── components
│       ├── pages
│       └── utils
├── assets
└── server
    ├── _coverage
    │   └── src
    ├── forecasting
    │   ├── data
    │   └── model
    ├── src
    └── test
```

`app` contains the code for our app's frontend.

`server` contains the code for our app's backend.

`server/src` contains business functions and the Dream server

`server/forecasting/data` contains the data set we use for training our time series forecasting model and backtesting.

`server/forecasting/model` contains the code for training the model which is implemented in python.

## Stats

### Coverage

The code coverage for the backend is at 100% (for testable code). For instructions on running code coverage, please refer to the [Run](#run) section.

### Lines of Code

Frontend:

.res files - 1252 lines

Backend:

.ml files - 839 lines

.mli files - 179 lines

Total - 2270 lines

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

### Python3

- [Pandas](https://pandas.pydata.org/docs/getting_started/install.html)
- [Numpy](https://numpy.org/install/)
- [Matplotlib](https://matplotlib.org/stable/#installation)
- [PyTorch](https://pytorch.org/get-started/locally/)
- [Jupyter Notebook](https://jupyter.org/install)

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

> Please note that you may have to connect to a personal hotspot or a VPN (and especially not the `hopkins` network) for the GET request to Binance endpoints to go through, and ultimately for the server to work correctly. As crypto adoption progresses, the [regulatory actions of the crypto industry and exchanges are making progress in the U.S recently](https://www.forbes.com/sites/haileylennon/2021/12/09/capitol-hill-warms-up-to-crypto/?sh=3876df23790c).

To run tests and coverage, cd into `./server` and run `dune test`. After this, run `bisect-ppx-report html` and then `open ./_coverage/index.html` to see results. The coverage is now at 100%.

## App

Cd into the `app` directory. Make sure you have [Node.js](https://nodejs.org/en/download/package-manager/) and [NPM](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) installed locally. The frontend app is written in [Rescript](https://rescript-lang.org/) and uses [rescript-react](https://rescript-lang.org/docs/react/latest/introduction). I recommend installing the rescript-vscode VSCode extension for syntax highlighting and intellisense.

Make sure that the [Server](#server) code is running via the aforementioned steps.

First run `npm install` to set up the dependencies. Then run `npm run start` to start the Rescript compiler in watch mode and run `npm run server` to start the local development server. This is all it takes to start the web app.

I had Vercel wired up such that we would always have the latest production build deployed at https://trade-ml.vercel.app/, so feel free to try our app out there. Please note that the visualization (analytics) part was broken in production due to the underlying library not compiling correctly, but it works fine locally.

Currently, the frontend web app is looking like this:

The main landing dashboard page:
![Dashboard](/assets/dashboard.png)

The analytics (visualization) page
![Analytics](/assets/analytics.png)
