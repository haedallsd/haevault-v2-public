#[allow(unused_variable, unused_type_parameter)]
module volatile_vault_v2::market_dlmm;

use cetusdlmm::bin::BinGroupRef;
use cetusdlmm::config::GlobalConfig as DLMMGlobalConfig;
use cetusdlmm::pool::{Pool, AddLiquidityCert};
use cetusdlmm::position::{Position, ClosePositionCert};
use cetusdlmm::versioned::Versioned as DLMMVersioned;
use std::type_name::TypeName;
use sui::balance::Balance;
use sui::clock::Clock;
use sui::coin::Coin;
use sui::object_bag::ObjectBag;
use sui::vec_map::VecMap;
use sui::vec_set::VecSet;
use volatile_vault_v2::pyth_oracle::PythOracle;

public struct DLMMMarket has key, store {
    id: UID,
    vault_id: ID,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    certified_pools: VecMap<ID, u64>,
    position_keys: VecSet<ID>,
    positions: ObjectBag,
}

public struct DLMMPosition has key, store {
    id: UID,
    position: Position,
    amounts: VecMap<TypeName, u64>,
    last_txs: VecMap<u8, vector<u8>>,
}

public struct DLMMPositionCloseCert {
    position_id: ID,
    cert: ClosePositionCert,
}

public struct DLMMPositionCloseCertV2 {
    market_id: ID,
    position_id: ID,
    cert: ClosePositionCert,
}

public(package) fun new_dlmm_market(
    vault_id: &mut UID,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    ctx: &mut TxContext,
): DLMMMarket {
    abort 0
}

public(package) fun add_certified_pool<CoinTypeA, CoinTypeB>(
    market: &mut DLMMMarket,
    pool: &Pool<CoinTypeA, CoinTypeB>,
    allow_bin_deviation: u64,
) {
    abort 0
}

public(package) fun remove_certified_pool<CoinTypeA, CoinTypeB>(
    market: &mut DLMMMarket,
    pool: &Pool<CoinTypeA, CoinTypeB>,
) {
    abort 0
}

public(package) fun update_certified_pool(
    market: &mut DLMMMarket,
    pool_id: ID,
    allow_bin_deviation: u64,
) {
    abort 0
}

public(package) fun new_position(market: &mut DLMMMarket, position: Position, ctx: &mut TxContext) {
    abort 0
}

public(package) fun open_position_spot<CoinTypeA, CoinTypeB>(
    market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    coin_a: &mut Coin<CoinTypeA>,
    coin_b: &mut Coin<CoinTypeB>,
    total_amount_a: u64,
    total_amount_b: u64,
    lower_bin_id: u32,
    width: u16,
    expected_active_id: u32,
    max_bin_slippage: u32,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    clk: &Clock,
    ctx: &mut TxContext,
): ID {
    abort 0
}

public(package) fun open_position_bid_ask<CoinTypeA, CoinTypeB>(
    market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    coin_a: &mut Coin<CoinTypeA>,
    coin_b: &mut Coin<CoinTypeB>,
    total_amount_a: u64,
    total_amount_b: u64,
    lower_bin_id: u32,
    width: u16,
    expected_active_id: u32,
    max_bin_slippage: u32,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    clk: &Clock,
    ctx: &mut TxContext,
): ID {
    abort 0
}

public(package) fun open_position_curve<CoinTypeA, CoinTypeB>(
    market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    coin_a: &mut Coin<CoinTypeA>,
    coin_b: &mut Coin<CoinTypeB>,
    total_amount_a: u64,
    total_amount_b: u64,
    lower_bin_id: u32,
    width: u16,
    expected_active_id: u32,
    max_bin_slippage: u32,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    clk: &Clock,
    ctx: &mut TxContext,
): ID {
    abort 0
}

public(package) fun new_add_liquidity_cert<CoinTypeA, CoinTypeB>(
    dlmm_market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    active_id_included: bool,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    clk: &Clock,
    ctx: &TxContext,
): AddLiquidityCert<CoinTypeA, CoinTypeB> {
    abort 0
}

public(package) fun add_liquidity_on_bin<CoinTypeA, CoinTypeB>(
    dlmm_market: &mut DLMMMarket,
    position_id: ID,
    cert: &mut AddLiquidityCert<CoinTypeA, CoinTypeB>,
    bin_group_ref: &mut BinGroupRef,
    offset_in_group: u8,
    amount_a: u64,
    amount_b: u64,
    versioned: &DLMMVersioned,
) {
    abort 0
}

public(package) fun repay_add_liquidity<CoinTypeA, CoinTypeB>(
    dlmm_market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    cert: AddLiquidityCert<CoinTypeA, CoinTypeB>,
    balance_a: Balance<CoinTypeA>,
    balance_b: Balance<CoinTypeB>,
    versioned: &DLMMVersioned,
) {
    abort 0
}

public(package) fun add_liquidity<CoinTypeA, CoinTypeB>(
    dlmm_market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    coin_a: &mut Coin<CoinTypeA>,
    coin_b: &mut Coin<CoinTypeB>,
    bins: vector<u32>,
    amounts_a: vector<u64>,
    amounts_b: vector<u64>,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public(package) fun collect_position_reward<CoinTypeA, CoinTypeB, RewardType>(
    dlmm_market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    ctx: &TxContext,
): Balance<RewardType> {
    abort 0
}

public(package) fun collect_position_fee<CoinTypeA, CoinTypeB>(
    dlmm_market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    ctx: &TxContext,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
    abort 0
}

public(package) fun remove_full_range_liquidity_by_percent<CoinTypeA, CoinTypeB>(
    dlmm_market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    lp_amount: u128,
    total_lp_amount: u128,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    clk: &Clock,
    ctx: &TxContext,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
    abort 0
}

public(package) fun remove_liquidity_by_percent<CoinTypeA, CoinTypeB>(
    dlmm_market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    min_bin_id: u32,
    max_bin_id: u32,
    percent: u16,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    clk: &Clock,
    ctx: &TxContext,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
    abort 0
}

public(package) fun remove_liquidity<CoinTypeA, CoinTypeB>(
    dlmm_market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    bins: vector<u32>,
    liquidity_shares: vector<u128>,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    clk: &Clock,
    ctx: &TxContext,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
    abort 0
}

public(package) fun add_liquidity_spot<CoinTypeA, CoinTypeB>(
    dlmm_market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    coin_a: &mut Coin<CoinTypeA>,
    coin_b: &mut Coin<CoinTypeB>,
    total_amount_a: u64,
    total_amount_b: u64,
    min_bin_id: u32,
    max_bin_id: u32,
    expected_active_id: u32,
    max_bin_slippage: u32,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public(package) fun add_liquidity_curve<CoinTypeA, CoinTypeB>(
    dlmm_market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    coin_a: &mut Coin<CoinTypeA>,
    coin_b: &mut Coin<CoinTypeB>,
    total_amount_a: u64,
    total_amount_b: u64,
    min_bin_id: u32,
    max_bin_id: u32,
    expected_active_id: u32,
    max_bin_slippage: u32,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public(package) fun add_liquidity_bid_ask<CoinTypeA, CoinTypeB>(
    dlmm_market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    coin_a: &mut Coin<CoinTypeA>,
    coin_b: &mut Coin<CoinTypeB>,
    total_amount_a: u64,
    total_amount_b: u64,
    min_bin_id: u32,
    max_bin_id: u32,
    expected_active_id: u32,
    max_bin_slippage: u32,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public(package) fun close_position_v2<CoinTypeA, CoinTypeB>(
    market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    config: &DLMMGlobalConfig,
    versioned: &DLMMVersioned,
    clk: &Clock,
    ctx: &TxContext,
): (
    DLMMPositionCloseCertV2,
    Balance<CoinTypeA>,
    Balance<CoinTypeB>,
    Balance<CoinTypeA>,
    Balance<CoinTypeB>,
) {
    abort 0
}

public(package) fun close_position<CoinTypeA, CoinTypeB>(
    _market: &mut DLMMMarket,
    _pool: &mut Pool<CoinTypeA, CoinTypeB>,
    _position_id: ID,
    _config: &DLMMGlobalConfig,
    _versioned: &DLMMVersioned,
    _clk: &Clock,
    _ctx: &TxContext,
): (DLMMPositionCloseCert, Balance<CoinTypeA>, Balance<CoinTypeB>) {
    abort 0
}

public(package) fun collect_reward_from_close_cert_v2<CoinTypeA, CoinTypeB, T>(
    market: &DLMMMarket,
    cert: &mut DLMMPositionCloseCertV2,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    versioned: &DLMMVersioned,
): Balance<T> {
    abort 0
}

public(package) fun destroy_close_cert_v2(
    market: &DLMMMarket,
    cert: DLMMPositionCloseCertV2,
    versioned: &DLMMVersioned,
) {
    abort 0
}

public(package) fun collect_reward_from_close_cert<CoinTypeA, CoinTypeB, T>(
    _cert: &mut DLMMPositionCloseCert,
    _pool: &mut Pool<CoinTypeA, CoinTypeB>,
    _versioned: &DLMMVersioned,
): Balance<T> {
    abort 0
}

public(package) fun destroy_close_cert(_cert: DLMMPositionCloseCert, _versioned: &DLMMVersioned) {
    abort 0
}

public(package) fun last_amounts(market: &DLMMMarket, ctx: &TxContext): VecMap<TypeName, u64> {
    abort 0
}

public fun assert_dlmm_position_not_withdraw(
    market: &DLMMMarket,
    position_id: ID,
    ctx: &TxContext,
) {
    abort 0
}

public(package) fun calcualate_position_amounts<CoinTypeA, CoinTypeB>(
    market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    versioned: &cetusdlmm::versioned::Versioned,
    clk: &Clock,
    ctx: &TxContext,
) {
    abort 0
}

public(package) fun calculate_position_amounts_v2<CoinTypeA, CoinTypeB>(
    market: &mut DLMMMarket,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    versioned: &cetusdlmm::versioned::Versioned,
    protocol_fee_rate: u64,
    pool_oracle_price: u128,
    clk: &Clock,
    ctx: &TxContext,
) {
    abort 0
}

public fun check_pool_price_deviation<CoinTypeA, CoinTypeB>(
    market: &DLMMMarket,
    pool: &Pool<CoinTypeA, CoinTypeB>,
    pyth_oracle: &PythOracle,
    clk: &Clock,
) {
    abort 0
}

public fun check_pool_price_deviation_v2<CoinTypeA, CoinTypeB>(
    market: &DLMMMarket,
    pool: &Pool<CoinTypeA, CoinTypeB>,
    pyth_oracle: &PythOracle,
    clk: &Clock,
): u128 {
    abort 0
}

public fun get_bin_price_from_oracle<Base, Quote>(pyth_oracle: &PythOracle, clk: &Clock): u128 {
    abort 0
}

public fun get_current_pool_price_v2<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
): u128 {
    abort 0
}

public fun price_to_q64_price(price: u128): u128 {
    abort 0
}

public fun get_current_pool_price<CoinTypeA, CoinTypeB>(_pool: &Pool<CoinTypeA, CoinTypeB>): u64 {
    abort 0
}

public fun coin_types(market: &DLMMMarket): (TypeName, TypeName) {
    abort 0
}

public fun position_keys(market: &DLMMMarket): VecSet<ID> {
    abort 0
}

public fun positions(market: &DLMMMarket): &ObjectBag {
    abort 0
}

public fun certified_pools(market: &DLMMMarket): VecMap<ID, u64> {
    abort 0
}

public fun contain_position(market: &DLMMMarket, position_id: ID): bool {
    abort 0
}

public fun borrow_position(market: &DLMMMarket, position_id: ID): &DLMMPosition {
    abort 0
}

public fun close_cert_position_id(cert: &DLMMPositionCloseCert): ID {
    abort 0
}

public fun close_cert_position_id_v2(cert: &DLMMPositionCloseCertV2): ID {
    abort 0
}

public fun pool_id(position: &DLMMPosition): ID {
    abort 0
}

public fun position_id(position: &DLMMPosition): ID {
    abort 0
}

public fun last_tx(position: &DLMMPosition, action: u8): vector<u8> {
    abort 0
}

