// Copyright (c) Haedal Technology Limited

#[allow(unused_variable, unused_type_parameter)]
module volatile_vault_v2::pyth_oracle;

use pyth_pro_compatible::hot_potato_vector::HotPotatoVector;
use pyth_pro_compatible::price_info::{PriceInfo, PriceInfoObject};
use pyth_pro_compatible::state::State;
use std::type_name::TypeName;
use sui::balance::Balance;
use sui::clock::Clock;
use sui::coin::{Coin, CoinMetadata};
use sui::coin_registry::Currency;
use sui::sui::SUI;
use sui::table::Table;
use volatile_vault_v2::config::GlobalConfig;
use volatile_vault_v2::versioned::Versioned;


/// Decimal places used for oracle price calculations.
/// Represents the number of decimal places to shift oracle prices by.
/// Value of 10 means prices are multiplied by 10^10.
/// Used to standardize price formats across different oracles and tokens.
///
/// # Example
/// ```
/// // Raw price: 1.23
/// // With PRICE_MULTIPER_DECIMAL = 10:
/// // Stored price = 1.23 * 10^10 = 12,300,000,000
/// ```
public macro fun price_multiplier_decimal(): u8 {
    10
}

public macro fun relative_price_multiplier_decimal(): u8 {
    18
}

/// `PythOracle` is a wrapper around Pyth oracle that stores price feed information for different coins.
/// It maintains a mapping from coin types to their oracle information including price feed IDs and price info objects.
///
/// # Fields
/// - `id`: Unique identifier
/// - `oracle_infos`: Table mapping coin types to their oracle information
/// - `update_price_fee`: Update Price fee
///
public struct PythOracle has key {
    id: UID,
    update_price_fee: Balance<SUI>,
    prices: Table<TypeName, Price>,
    oracle_infos: Table<TypeName, OracleInfo>,
}

/// `OracleInfo` stores oracle configuration information for a specific coin type.
///
/// # Fields
/// * `price_feed_id` - The Pyth price feed identifier for this coin
/// * `price_info_object_id` - ID of the PriceInfoObject that stores the latest price data
/// * `usd_price_age` - Maximum allowed age (in seconds) of the price data before it's considered stale
/// * `coin_decimals` - Number of decimals used for the Sui coin type (e.g. 9 for SUI)
public struct OracleInfo has drop, store {
    price_feed_id: vector<u8>,
    price_info_object_id: ID,
    usd_price_age: u64,
    coin_decimals: u8,
}

/// `Price` represents a price value with its associated decimal precision.
///
/// # Fields
/// * `price` - The price value as a u64 integer, multiplied by PRICE_MULTIPER_DECIMAL
/// * `coin_decimals` - Number of decimals used for the Sui coin type (e.g. 9 for SUI)
///
public struct Price has copy, drop, store {
    price: u64,
    coin_decimals: u8,
    last_update_time: u64,
}

/// Dynamic-field key for `OracleInfo` entries registered against the
/// pro-compatible Pyth deployment. Kept separate from the legacy
/// `oracle_infos` table so both registrations can coexist during the
/// migration window: the legacy package version keeps feeding prices from
/// the old entries while `_pyth2` entrypoints resolve exclusively from
/// these fields.
public struct OracleInfoPyth2Key has copy, drop, store {
    coin_type: TypeName,
}

/// Dynamic-object-field key for the global list of coin types that may be
/// deliberately excluded from AUM when they do not have oracle information.
public struct AumExcludedAssetRegistryKey has copy, drop, store {}

/// Global, explicitly managed set of coin types that may be omitted from AUM.
/// It is attached to `PythOracle` as a dynamic object field so existing
/// `PythOracle` objects do not require a layout migration and indexers can
/// discover the registry as an object.
public struct AumExcludedAssetRegistry has key, store {
    id: UID,
    assets: Table<TypeName, bool>,
}

/// `InitEvent` is emitted when the PythOracle module is initialized.
/// This event is only emitted once during module initialization.
/// It records the global PythOracle object ID for tracking purposes.
///
/// # Fields
/// * `pyth_oracle_id` - The unique identifier of the global PythOracle object
public struct InitEvent has copy, drop {
    pyth_oracle_id: ID,
}

public struct InitAumExcludedAssetRegistryEvent has copy, drop {
    registry_id: ID,
}

public struct AddAumExcludedAssetEvent has copy, drop {
    coin_type: TypeName,
}

public struct RemoveAumExcludedAssetEvent has copy, drop {
    coin_type: TypeName,
}

/// `AddOracleInfoEvent` is emitted when a new oracle information entry is added to the PythOracle.
/// This event records the details of the newly added price feed configuration for a specific coin type.
///
/// # Fields
/// * `type_name` - The type name of the coin for which oracle info is being added
/// * `price_feed_id` - The Pyth price feed identifier assigned to this coin
/// * `price_info_object_id` - ID of the PriceInfoObject that will store price data
/// * `usd_price_age` - Maximum allowed age (in seconds) for the price data
public struct AddOracleInfoEvent has copy, drop {
    type_name: TypeName,
    price_feed_id: vector<u8>,
    price_info_object_id: ID,
    usd_price_age: u64,
}

/// `RemoveOracleInfoEvent` is emitted when an oracle information entry is removed from the PythOracle.
/// This event records which coin type had its oracle configuration removed from the system.
///
/// # Fields
/// * `type_name` - The type name of the coin for which oracle info was removed
public struct RemoveOracleInfoEvent has copy, drop {
    type_name: TypeName,
}

/// `UpdateOraclePriceAgeEvent` is emitted when the maximum allowed age for price data is updated for a coin type.
/// This event records both the old and new price age values to track the change in configuration.
///
/// # Fields
/// * `type_name` - The type name of the coin for which price age was updated
/// * `old_usd_price_age` - Previous maximum allowed age (in seconds) for the price data
/// * `new_usd_price_age` - New maximum allowed age (in seconds) for the price data
public struct UpdateOraclePriceAgeEvent has copy, drop {
    type_name: TypeName,
    old_usd_price_age: u64,
    new_usd_price_age: u64,
}

/// `DepositFeeEvent` is emitted when a fee is deposited into the PythOracle.
/// This event records the amount of SUI deposited as a fee.
///
/// # Fields
/// * `amount` - The amount of SUI deposited as a fee
public struct DepositFeeEvent has copy, drop {
    amount: u64,
}

/// Event emitted when an oracle price is updated.
///
/// # Fields
/// * `coin_type` - Type name of the coin whose price was updated
/// * `price` - New price value
/// * `last_update_time` - Timestamp of the price update
public struct UpdatePriceEvent has copy, drop {
    coin_type: TypeName,
    price: u64,
    last_update_time: u64,
}

/// `init` initializes the PythOracle module by creating and sharing a new PythOracle object.
/// This function is called only once during module initialization.
///
/// # Arguments
/// * `ctx` - The transaction context used to create new objects
///
/// # Events
/// * Emits `InitEvent` with the ID of the newly created PythOracle object
///
/// # Returns
/// * Creates and shares a new PythOracle object with an empty oracle_infos table
fun init(ctx: &mut TxContext) {
    abort 0
}

public fun init_aum_excluded_asset_registry(
    pyth_oracle: &mut PythOracle,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun add_aum_excluded_asset<T>(
    pyth_oracle: &mut PythOracle,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &TxContext,
) {
    abort 0
}

public fun remove_aum_excluded_asset<T>(
    pyth_oracle: &mut PythOracle,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &TxContext,
) {
    abort 0
}

public fun is_aum_excluded_asset(pyth_oracle: &PythOracle, type_name: TypeName): bool {
    abort 0
}

public fun deposit_fee(pyth_oracle: &mut PythOracle, fee: Coin<SUI>, versioned: &Versioned) {
    abort 0
}

public(package) fun split_fee(pyth_oracle: &mut PythOracle, amount: u64): Balance<SUI> {
    abort 0
}

public fun new_price(price: u64, coin_decimals: u8): Price {
    abort 0
}

public fun add_oracle_info<T>(
    _pyth_oracle: &mut PythOracle,
    _config: &GlobalConfig,
    _pyth_state: &pyth::state::State,
    _coin_metadata: &CoinMetadata<T>,
    _price_feed_id: vector<u8>,
    _usd_price_age: u64,
    _versioned: &Versioned,
    _ctx: &TxContext,
) {
    abort 0
}

public fun add_oracle_info_pyth2<T>(
    pyth_oracle: &mut PythOracle,
    config: &GlobalConfig,
    pyth_state: &State,
    coin_metadata: &CoinMetadata<T>,
    price_feed_id: vector<u8>,
    usd_price_age: u64,
    versioned: &Versioned,
    ctx: &TxContext,
) {
    abort 0
}

public fun add_oracle_info_v2<T>(
    _pyth_oracle: &mut PythOracle,
    _config: &GlobalConfig,
    _pyth_state: &pyth::state::State,
    _currency: &Currency<T>,
    _price_feed_id: vector<u8>,
    _usd_price_age: u64,
    _versioned: &Versioned,
    _ctx: &TxContext,
) {
    abort 0
}

public fun add_oracle_info_by_currency_pyth2<T>(
    pyth_oracle: &mut PythOracle,
    config: &GlobalConfig,
    pyth_state: &State,
    currency: &Currency<T>,
    price_feed_id: vector<u8>,
    usd_price_age: u64,
    versioned: &Versioned,
    ctx: &TxContext,
) {
    abort 0
}

/// Removes oracle information for a specific coin type from the PythOracle
/// This function deregisters price feed information for a given coin
///
/// # Arguments
/// * `pyth_oracle` - The Pyth Oracle object to remove info from
/// * `config` - Global configuration for access control
/// * `ctx` - Transaction context for access control
///
/// # Aborts
/// * If caller does not have oracle manager role
/// * If oracle info does not exist for this coin type
///
/// # Events
/// * Emits `RemoveOracleInfoEvent` with the deregistered coin type
public fun remove_oracle_info<T>(
    pyth_oracle: &mut PythOracle,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &TxContext,
) {
    abort 0
}

public fun remove_oracle_info_pyth2<T>(
    pyth_oracle: &mut PythOracle,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &TxContext,
) {
    abort 0
}

public fun update_price_age<T>(
    pyth_oracle: &mut PythOracle,
    config: &GlobalConfig,
    new_usd_price_age: u64,
    versioned: &Versioned,
    ctx: &TxContext,
) {
    abort 0
}

public fun calculate_oracle_prices<CoinTypeA, CoinTypeB>(
    _pyth_oracle: &PythOracle,
    _base_price_pair_obj: &pyth::price_info::PriceInfoObject,
    _quote_price_pair_obj: &pyth::price_info::PriceInfoObject,
    _clock: &Clock,
): (u64, u64, u64, u64) {
    abort 0
}

public fun calculate_oracle_prices_pyth2<CoinTypeA, CoinTypeB>(
    pyth_oracle: &PythOracle,
    base_price_pair_obj: &PriceInfoObject,
    quote_price_pair_obj: &PriceInfoObject,
    clock: &Clock,
): (u64, u64, u64, u64) {
    abort 0
}

public fun update_price<T>(
    _pyth_oracle: &mut PythOracle,
    _pyth_state: &pyth::state::State,
    _price_updates: pyth::hot_potato_vector::HotPotatoVector<pyth::price_info::PriceInfo>,
    _price_info_obj: &mut pyth::price_info::PriceInfoObject,
    _clk: &Clock,
    _versioned: &Versioned,
    _ctx: &mut TxContext,
): pyth::hot_potato_vector::HotPotatoVector<pyth::price_info::PriceInfo> {
    abort 0
}

public fun update_price_into_pyth_oracle<T>(
    _pyth_oracle: &mut PythOracle,
    _price_info_obj: &mut pyth::price_info::PriceInfoObject,
    _clk: &Clock,
    _versioned: &Versioned,
    _ctx: &TxContext,
) {
    abort 0
}

public fun update_price_into_pyth_oracle_pyth2<T>(
    pyth_oracle: &mut PythOracle,
    price_info_obj: &mut PriceInfoObject,
    clk: &Clock,
    versioned: &Versioned,
    _ctx: &TxContext,
) {
    abort 0
}

public fun pyth_price_from_oracle_info(
    _pyth_price_pair_obj: &pyth::price_info::PriceInfoObject,
    _oracle_info: &OracleInfo,
    _clock: &Clock,
): u64 {
    abort 0
}

public fun pyth_price_from_oracle_info_pyth2(
    pyth_price_pair_obj: &PriceInfoObject,
    oracle_info: &OracleInfo,
    clock: &Clock,
): u64 {
    abort 0
}

public fun calculate_prices(base_price: &Price, quote_price: &Price): (u64, u64) {
    abort 0
}

public fun calculate_prices_v2(base_price: &Price, quote_price: &Price): (u128, u128) {
    abort 0
}

public fun get_price<T>(pyth_oracle: &PythOracle, clock: &Clock): Price {
    abort 0
}

public fun get_price_by_type(pyth_oracle: &PythOracle, type_name: TypeName, clock: &Clock): Price {
    abort 0
}

public fun oracle_info<T>(pyth_oracle: &PythOracle): &OracleInfo {
    abort 0
}

public fun contain_oracle_info(pyth_oracle: &PythOracle, type_name: TypeName): bool {
    abort 0
}

public fun contain_oracle_info_pyth2(pyth_oracle: &PythOracle, type_name: TypeName): bool {
    abort 0
}

public fun price_feed_id(oracle_info: &OracleInfo): vector<u8> {
    abort 0
}

public fun price_info_object_id(oracle_info: &OracleInfo): ID {
    abort 0
}

public fun usd_price_age(oracle_info: &OracleInfo): u64 {
    abort 0
}

public fun coin_decimals(oracle_info: &OracleInfo): u8 {
    abort 0
}

public fun price_value(p: &Price): u64 {
    abort 0
}

public fun price_coin_decimal(p: &Price): u8 {
    abort 0
}

public fun last_update_time(p: &Price): u64 {
    abort 0
}

