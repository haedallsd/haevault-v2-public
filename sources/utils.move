// Copyright (c) Haedal Technology Limited

#[allow(unused_variable, unused_type_parameter)]
module volatile_vault_v2::utils;

use integer_mate::i32::I32;
use sui::bag::Bag;
use sui::balance::Balance;
use sui::coin::Coin;

public fun add_balance_to_bag<T>(balances: &mut Bag, balance: Balance<T>): u64 {
    abort 0
}

public fun remove_balance_from_bag<T>(
    balance_bag: &mut Bag,
    amount: u64,
    is_all: bool,
): (Balance<T>, u64) {
    abort 0
}

public fun send_coin<CoinType>(coin: Coin<CoinType>, receipt: address) {
    abort 0
}

public fun get_id_from_price(price: u128, bin_step: u16): I32 {
    abort 0
}

