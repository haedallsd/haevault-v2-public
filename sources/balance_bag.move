// Copyright (c) Haedal Technology Limited

#[allow(unused_variable, unused_type_parameter)]
module volatile_vault_v2::balance_bag;

use std::type_name::TypeName;
use sui::bag::Bag;
use sui::balance::Balance;
use sui::vec_map::VecMap;

/// A container for managing multiple Balance objects of different coin types.
/// Combines a VecMap for tracking amounts with a Bag for storing the actual Balance objects.
public struct BalanceBag has store {
    balances: VecMap<TypeName, u64>,
    bag: Bag,
}

/// Creates a new empty BalanceBag.
public(package) fun new_balance_bag(ctx: &mut TxContext): BalanceBag {
    abort 0
}

/// Joins Balance into a BalanceBag, adding it to the existing balance if present.
public(package) fun join<CoinType>(bag: &mut BalanceBag, balances: Balance<CoinType>) {
    abort 0
}

/// Withdraws all balance of a specific coin type from the BalanceBag.
public(package) fun withdraw_all<CoinType>(bag: &mut BalanceBag): Balance<CoinType> {
    abort 0
}

/// Splits a specific amount from a balance in the BalanceBag.
public(package) fun split<CoinType>(bag: &mut BalanceBag, amount: u64): Balance<CoinType> {
    abort 0
}

public(package) fun destroy_empty(balance_bag: BalanceBag) {
    abort 0
}

/// Returns the amount of a specific coin type stored in the BalanceBag.
public fun value<CoinType>(bag: &BalanceBag): u64 {
    abort 0
}

/// Returns a reference to the balances VecMap in the BalanceBag.
public fun balances(bag: &BalanceBag): &VecMap<TypeName, u64> {
    abort 0
}

public fun is_empty(bag: &BalanceBag): bool {
    abort 0
}

