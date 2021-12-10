type response<'data> = {
  data: 'data,
  code: int,
}

type transaction = {
  id: int,
  usd_bal: float,
  btc_bal: float,
  usd_amount: float,
  btc_amount: float,
  transaction_type: string,
}

type wallet = {
  usd_bal: float,
  btc_bal: float,
  msg: string,
}
