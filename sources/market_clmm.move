#[allow(unused_variable, unused_type_parameter)]
module volatile_vault_v2::market_clmm;

use cetus_clmm::config::GlobalConfig as ClmmConfig;
use cetus_clmm::pool::Pool as ClmmPool;
use cetus_clmm::position::Position;
use cetus_clmm::rewarder::RewarderGlobalVault;
use std::type_name::TypeName;
use sui::balance::Balance;
use sui::clock::Clock;
use sui::object_bag::ObjectBag;
use sui::vec_map::VecMap;
use sui::vec_set::VecSet;
use volatile_vault_v2::pyth_oracle::PythOracle;

public struct CLMMMarket has key, store {
    id: UID,
    vault_id: ID,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    certified_pools: VecMap<ID, u64>,
    position_keys: VecSet<ID>,
    positions: ObjectBag,
}

public struct CLMMPosition has key, store {
    id: UID,
    position: Position,
    amounts: VecMap<TypeName, u64>,
    last_txs: VecMap<u8, vector<u8>>,
}

public(package) fun new_clmm_market(
    vault_id: &mut UID,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    ctx: &mut TxContext,
): CLMMMarket {
    abort 0
}

public(package) fun add_certified_pool<CoinTypeA, CoinTypeB>(
    market: &mut CLMMMarket,
    pool: &ClmmPool<CoinTypeA, CoinTypeB>,
    allow_price_deviation: u64,
) {
    abort 0
}

public(package) fun remove_certified_pool<CoinTypeA, CoinTypeB>(
    market: &mut CLMMMarket,
    pool: &ClmmPool<CoinTypeA, CoinTypeB>,
) {
    abort 0
}

public(package) fun update_certified_pool(
    market: &mut CLMMMarket,
    pool_id: ID,
    allow_price_deviation: u64,
) {
    abort 0
}

public(package) fun open_position<CoinTypeA, CoinTypeB>(
    market: &mut CLMMMarket,
    pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    tick_lower: u32,
    tick_upper: u32,
    config: &ClmmConfig,
    ctx: &mut TxContext,
): ID {
    abort 0
}

public(package) fun increase_liquidity<CoinA, CoinB>(
    clmm_market: &mut CLMMMarket,
    clmm_pool: &mut ClmmPool<CoinA, CoinB>,
    position_id: ID,
    balance_a: &mut Balance<CoinA>,
    balance_b: &mut Balance<CoinB>,
    config: &ClmmConfig,
    clock: &Clock,
): (u64, u64, u128) {
    abort 0
}

public(package) fun collect_position_reward<CoinTypeA, CoinTypeB, RewardType>(
    market: &mut CLMMMarket,
    pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    reward_vault: &mut RewarderGlobalVault,
    config: &ClmmConfig,
    clk: &Clock,
    ctx: &TxContext,
): Balance<RewardType> {
    abort 0
}

public(package) fun collect_position_fee<CoinTypeA, CoinTypeB>(
    market: &mut CLMMMarket,
    pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    config: &ClmmConfig,
    ctx: &TxContext,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
    abort 0
}

public(package) fun remove_liquidity<CoinTypeA, CoinTypeB>(
    market: &mut CLMMMarket,
    pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    liquidity_delta: u128,
    config: &ClmmConfig,
    clk: &Clock,
    ctx: &TxContext,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
    abort 0
}

public(package) fun close_position<CoinTypeA, CoinTypeB>(
    market: &mut CLMMMarket,
    pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    config: &ClmmConfig,
) {
    abort 0
}

public(package) fun last_amounts(market: &CLMMMarket, ctx: &TxContext): VecMap<TypeName, u64> {
    abort 0
}

public fun assert_clmm_position_not_withdraw(
    market: &CLMMMarket,
    position_id: ID,
    ctx: &TxContext,
) {
    abort 0
}

public(package) fun calculate_position_amounts<CoinTypeA, CoinTypeB>(
    market: &mut CLMMMarket,
    pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    config: &ClmmConfig,
    protocol_fee_rate: u64,
    pool_oracle_price: u128,
    clk: &Clock,
    ctx: &TxContext,
) {
    abort 0
}

public fun check_pool_price_deviation<CoinTypeA, CoinTypeB>(
    market: &CLMMMarket,
    pool: &ClmmPool<CoinTypeA, CoinTypeB>,
    pyth_oracle: &PythOracle,
    clk: &Clock,
): u128 {
    abort 0
}

public fun get_current_pool_price<CoinTypeA, CoinTypeB>(
    pool: &ClmmPool<CoinTypeA, CoinTypeB>,
): u128 {
    abort 0
}

public fun price_to_sqrt_price(price: u128): u128 {
    abort 0
}

public fun coin_types(market: &CLMMMarket): (TypeName, TypeName) {
    abort 0
}

public fun position_keys(market: &CLMMMarket): VecSet<ID> {
    abort 0
}

public fun positions(market: &CLMMMarket): &ObjectBag {
    abort 0
}

public fun certified_pools(market: &CLMMMarket): VecMap<ID, u64> {
    abort 0
}

public fun contain_position(market: &CLMMMarket, position_id: ID): bool {
    abort 0
}

public fun borrow_position(market: &CLMMMarket, position_id: ID): &CLMMPosition {
    abort 0
}

public fun pool_id(position: &CLMMPosition): ID {
    abort 0
}

public fun position_id(position: &CLMMPosition): ID {
    abort 0
}

public fun last_tx(position: &CLMMPosition, action: u8): vector<u8> {
    abort 0
}
