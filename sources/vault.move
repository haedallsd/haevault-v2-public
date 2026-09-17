// Copyright (c) Haedal Technology Limited

#[allow(unused_variable, unused_type_parameter)]
module volatile_vault_v2::vault;

use cetus_clmm::config::GlobalConfig as ClmmGlobalConfig;
use cetus_clmm::pool::Pool as ClmmPool;
use cetus_clmm::rewarder::RewarderGlobalVault;
use cetusdlmm::bin::BinGroupRef;
use cetusdlmm::config::GlobalConfig as DLMMGlobalConfig;
use cetusdlmm::pool::{Pool as DlmmPool, AddLiquidityCert, OpenPositionCert};
use cetusdlmm::position::Position;
use cetusdlmm::versioned::Versioned as DLMMVersioned;
use std::type_name::TypeName;
use sui::bag::Bag;
use sui::balance::Balance;
use sui::clock::Clock;
use sui::coin::{Coin, TreasuryCap};
use sui::object_bag::ObjectBag;
use sui::table::Table;
use sui::vec_map::VecMap;
use sui::vec_set::VecSet;
use volatile_vault_v2::balance_bag::BalanceBag;
use volatile_vault_v2::config::GlobalConfig;
use volatile_vault_v2::market_clmm::CLMMMarket;
use volatile_vault_v2::market_dlmm::DLMMMarket;
use volatile_vault_v2::pyth_oracle::PythOracle;
use volatile_vault_v2::versioned::Versioned;

public struct VaultRegistry has key, store {
    id: UID,
    index: u64,
    vaults: Table<ID, TypeName>,
}


public struct Vault<phantom T> has key, store {
    id: UID,
    lp_token_treasury: TreasuryCap<T>,
    quote_type: QuoteTypeEnum,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    buffer_assets: BalanceBag,
    protocol_fees: Bag,
    hard_cap: u128,
    markets: ObjectBag,
    action_status: u16,
    last_aum: u128,
    last_txs: VecMap<u8, vector<u8>>,
    protocol_fee_rate: u64,
}


/// QuoteTypeEnum indicating the quote type for vault AUM (Assets Under Management) calculations.
/// - Base: Quote AUM in terms of the base token (token A)
/// - Quote: Quote AUM in terms of the quote token (token B)
/// - Usd: Quote AUM in terms of USD value
public enum QuoteTypeEnum has copy, drop, store {
    Base(TypeName),
    Quote(TypeName),
    Usd,
}


public struct FlashLoanCert {
    vault_id: ID,
    repay_type: TypeName,
    repay_amount: u64,
}


public struct FlashLoanEpochBudgetState has store {
    epoch: u64,
    cum_value: u128,
}


public struct WithdrawCert {
    vault_id: ID,
    user_lp_amount: u64,
    total_lp_amount: u64,
    positions: VecSet<ID>,
    fees: VecSet<ID>,
    rewards: VecMap<ID, VecSet<TypeName>>,
    buffer_amounts: VecMap<TypeName, u64>,
    assets: BalanceBag,
    state: WithdrawStateEnum,
}


public enum WithdrawStateEnum has copy, drop, store {
    Pending,
    FinishInitedBufferAssets,
    Completed,
}


#[allow(unused_field)]
public struct FlashLoanEvent has copy, drop {
    vault_id: ID,
    loan_type: TypeName,
    repay_type: TypeName,
    loan_amount: u64,
    repay_amount: u64,
    base_to_quote_price: u64,
    base_price: u64,
    quote_price: u64,
}


public struct FlashLoanV2Event has copy, drop {
    vault_id: ID,
    loan_type: TypeName,
    repay_type: TypeName,
    loan_amount: u64,
    repay_amount: u64,
    base_to_quote_price: u128,
    base_price: u64,
    quote_price: u64,
}


public struct FlashLoanEpochBudgetEvent has copy, drop {
    vault_id: ID,
    loan_type: TypeName,
    repay_type: TypeName,
    loan_amount: u64,
    loan_value: u128,
    epoch: u64,
    epoch_cum_value: u128,
    epoch_budget: u128,
}


/// Event emitted when a flash loan is repaid.
///
/// # Fields
/// * `vault_id` - The unique identifier of the vault
/// * `repay_type` - Type of token repaid
/// * `repay_amount` - Amount repaid
public struct RepayFlashLoanEvent has copy, drop {
    vault_id: ID,
    repay_type: TypeName,
    repay_amount: u64,
}


/// Event emitted when the pool registry is initialized.
/// Contains the ID of the registry.
///
/// # Fields
/// * `registry_id` - The unique identifier of the vault registry
public struct InitEvent has copy, drop {
    registry_id: ID,
}


public struct CreateVaultEvent has copy, drop {
    id: ID,
    lp_token_treasury_id: ID,
    quote_type: QuoteTypeEnum,
    hard_cap: u128,
}


public struct AddDlmmMarketEvent has copy, drop {
    vault_id: ID,
    dlmm_market_id: ID,
}


public struct AddClmmMarketEvent has copy, drop {
    vault_id: ID,
    clmm_market_id: ID,
}


public struct DepositEvent has copy, drop {
    vault_id: ID,
    before_aum: u128,
    user_tvl: u128,
    before_supply: u64,
    lp_amount: u64,
    amount_a: u64,
    amount_b: u64,
}


public struct UpdateProtocolFeeEvent has copy, drop {
    vault_id: ID,
    old_protocol_fee_rate: u64,
    new_protocol_fee_rate: u64,
}


public struct UpdateHardCapEvent has copy, drop {
    vault_id: ID,
    old_hard_cap: u128,
    new_hard_cap: u128,
}


public struct UpdateActiveStatusEvent has copy, drop {
    vault_id: ID,
    old_action_status: u16,
    new_action_status: u16,
}


public struct CollectDlmmFeeEvent has copy, drop {
    vault_id: ID,
    position_id: ID,
    amount_a: u64,
    amount_b: u64,
    protocol_fee_a: u64,
    protocol_fee_b: u64,
}


public struct CollectClmmFeeEvent has copy, drop {
    vault_id: ID,
    pool_id: ID,
    position_id: ID,
    amount_a: u64,
    amount_b: u64,
    protocol_fee_a: u64,
    protocol_fee_b: u64,
}


public struct CollectDlmmRewardEvent has copy, drop {
    vault_id: ID,
    position_id: ID,
    reward_type: TypeName,
    amount: u64,
    protocol_fee: u64,
}


public struct CollectClmmRewardEvent has copy, drop {
    vault_id: ID,
    pool_id: ID,
    position_id: ID,
    reward_type: TypeName,
    amount: u64,
    protocol_fee: u64,
}


public struct OpenDlmmPositionEvent has copy, drop {
    vault_id: ID,
    position_id: ID,
    active_id: I32,
    total_amount_a: u64,
    total_amount_b: u64,
}


public struct OpenClmmPositionEvent has copy, drop {
    vault_id: ID,
    position_id: ID,
    pool_id: ID,
    tick_lower: u32,
    tick_upper: u32,
    amount_a: u64,
    amount_b: u64,
}


public struct ClmmAddLiquidityEvent has copy, drop {
    vault_id: ID,
    position_id: ID,
    pool_id: ID,
    current_sqrt_price: u128,
    total_amount_a: u64,
    total_amount_b: u64,
}


public struct DlmmAddLiquidityEvent has copy, drop {
    vault_id: ID,
    position_id: ID,
    active_id: I32,
    total_amount_a: u64,
    total_amount_b: u64,
}


public struct ClmmRemoveLiquidityEvent has copy, drop {
    vault_id: ID,
    position_id: ID,
    pool_id: ID,
    current_sqrt_price: u128,
    amount_a: u64,
    amount_b: u64,
}


public struct ClmmClosePositionEvent has copy, drop {
    vault_id: ID,
    position_id: ID,
    pool_id: ID,
    current_sqrt_price: u128,
    amount_a: u64,
    amount_b: u64,
}


public struct DlmmRemoveLiquidityEvent has copy, drop {
    vault_id: ID,
    position_id: ID,
    active_id: I32,
    total_amount_a: u64,
    total_amount_b: u64,
}


public struct DlmmClosePositionEvent has copy, drop {
    vault_id: ID,
    position_id: ID,
    active_id: I32,
    total_amount_a: u64,
    total_amount_b: u64,
}


#[allow(unused_field)]
public struct DlmmClosePositionRewardEvent has copy, drop {
    vault_id: ID,
    position_id: ID,
    reward_type: TypeName,
    amount: u64,
}


public struct ClaimProtocolFeeEvent has copy, drop {
    vault_id: ID,
    amount: u64,
    type_name: TypeName,
}


public struct WithdrawDlmmEvent has copy, drop {
    vault_id: ID,
    position_id: ID,
    pool: ID,
    amount_a: u64,
    amount_b: u64,
}


public struct WithdrawClmmEvent has copy, drop {
    vault_id: ID,
    position_id: ID,
    pool: ID,
    amount_a: u64,
    amount_b: u64,
}


public struct NewWithdrawCertEvent has copy, drop {
    vault_id: ID,
    user_lp_amount: u64,
    total_lp_amount: u64,
}


public struct WithdrawBufferAssetEvent has copy, drop {
    vault_id: ID,
    asset_type: TypeName,
    amount: u64,
}


public struct RecoverDeprecatedVaultBufferAssetEvent has copy, drop {
    vault_id: ID,
    asset_type: TypeName,
    amount: u64,
    recipient: address,
}


public struct AddCertifiedPoolEvent has copy, drop {
    vault_id: ID,
    pool_id: ID,
    market: String,
}


public struct RemoveCertifiedPoolEvent has copy, drop {
    vault_id: ID,
    pool_id: ID,
    market: String,
}


public struct UpdateDlmmCertifiedPoolEvent has copy, drop {
    vault_id: ID,
    pool_id: ID,
    old_allow_bin_deviation: u64,
    new_allow_bin_deviation: u64,
}


public struct UpdateClmmCertifiedPoolEvent has copy, drop {
    vault_id: ID,
    pool_id: ID,
    old_allow_price_deviation: u64,
    new_allow_price_deviation: u64,
}


public struct ProtocolFeeEvent has copy, drop {
    vault_id: ID,
    amount: u64,
    type_name: TypeName,
}


fun init(ctx: &mut TxContext) {
    abort 0
}

public fun quote_type_from_int<CoinTypeA, CoinTypeB>(quote_type: u8): QuoteTypeEnum {
    abort 0
}

public fun create_vault<CoinTypeA, CoinTypeB, LPCoin>(
    registry: &mut VaultRegistry,
    lp_token_treasury: TreasuryCap<LPCoin>,
    pyth_oracle: &PythOracle,
    quote_type: u8,
    hard_cap: u128,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun update_active_status<LPCoin>(
    vault: &mut Vault<LPCoin>,
    action_status: u16,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun update_hard_cap<LPCoin>(
    vault: &mut Vault<LPCoin>,
    new_hard_cap: u128,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun claim_protocol_fee<LPCoin, CoinType>(
    vault: &mut Vault<LPCoin>,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
): Coin<CoinType> {
    abort 0
}

public fun recover_deprecated_vault_buffer_asset<LPCoin, CoinType>(
    vault: &mut Vault<LPCoin>,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun update_protocol_fee_rate<LPCoin>(
    vault: &mut Vault<LPCoin>,
    new_protocol_fee_rate: u64,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun add_dlmm_market<LPCoin>(
    vault: &mut Vault<LPCoin>,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun add_clmm_market<LPCoin>(
    vault: &mut Vault<LPCoin>,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun add_clmm_certified_pool<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &ClmmPool<CoinTypeA, CoinTypeB>,
    allow_price_deviation: u64,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &TxContext,
) {
    abort 0
}

public fun add_dlmm_certified_pool<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &DlmmPool<CoinTypeA, CoinTypeB>,
    allow_bin_deviation: u64,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &TxContext,
) {
    abort 0
}

public fun remove_clmm_certified_pool<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &ClmmPool<CoinTypeA, CoinTypeB>,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun remove_dlmm_certified_pool<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &DlmmPool<CoinTypeA, CoinTypeB>,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun update_clmm_certified_pool<LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool_id: ID,
    allow_price_deviation: u64,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun update_dlmm_certified_pool<LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool_id: ID,
    allow_bin_deviation: u64,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun deposit<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    config: &GlobalConfig,
    pyth_oracle: &PythOracle,
    coin_a: Coin<CoinTypeA>,
    coin_b: Coin<CoinTypeB>,
    clk: &Clock,
    versioned: &Versioned,
    ctx: &mut TxContext,
): Coin<LPCoin> {
    abort 0
}

public fun calculate_aum<T>(
    vault: &mut Vault<T>,
    pyth_oracle: &PythOracle,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &TxContext,
) {
    abort 0
}

public fun calculate_clmm_position_amounts<CoinTypeA, CoinTypeB, T>(
    vault: &mut Vault<T>,
    pyth_oracle: &PythOracle,
    clmm_pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    config: &ClmmGlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &TxContext,
) {
    abort 0
}

public fun calculate_dlmm_position_amounts<CoinTypeA, CoinTypeB, T>(
    vault: &mut Vault<T>,
    pyth_oracle: &PythOracle,
    dlmm_pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    dlmm_versioned: &DLMMVersioned,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &TxContext,
) {
    abort 0
}

public fun new_withdraw_cert<LPCoin>(
    vault: &mut Vault<LPCoin>,
    lp_coin: Coin<LPCoin>,
    versioned: &Versioned,
    ctx: &mut TxContext,
): WithdrawCert {
    abort 0
}

public fun withdraw_asset<LPCoin, CoinTypeC>(
    vault: &mut Vault<LPCoin>,
    withdraw_cert: &mut WithdrawCert,
    versioned: &Versioned,
    ctx: &mut TxContext,
): Coin<CoinTypeC> {
    abort 0
}

public fun destroy_withdraw_cert<LPCoin>(
    vault: &mut Vault<LPCoin>,
    withdraw_cert: WithdrawCert,
    versioned: &Versioned,
) {
    abort 0
}

public fun finalize_buffer_assets<LPCoin>(
    vault: &mut Vault<LPCoin>,
    withdraw_cert: &mut WithdrawCert,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun withdraw_clmm<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    withdraw_cert: &mut WithdrawCert,
    pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    clmm_config: &ClmmGlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun withdraw_dlmm<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    withdraw_cert: &mut WithdrawCert,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun collect_clmm_fee_on_withdraw<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    withdraw_cert: &mut WithdrawCert,
    pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    clmm_config: &ClmmGlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun collect_dlmm_fee_on_withdraw<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    withdraw_cert: &mut WithdrawCert,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun collect_clmm_fee<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    clmm_config: &ClmmGlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun collect_dlmm_fee<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun collect_clmm_reward_on_withdraw<CoinTypeA, CoinTypeB, LPCoin, Reward>(
    vault: &mut Vault<LPCoin>,
    withdraw_cert: &mut WithdrawCert,
    pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    clmm_config: &ClmmGlobalConfig,
    reward_vault: &mut RewarderGlobalVault,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun collect_dlmm_reward_on_withdraw<CoinTypeA, CoinTypeB, LPCoin, Reward>(
    vault: &mut Vault<LPCoin>,
    withdraw_cert: &mut WithdrawCert,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun collect_clmm_reward<CoinTypeA, CoinTypeB, LPCoin, Reward>(
    vault: &mut Vault<LPCoin>,
    pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    reward_vault: &mut RewarderGlobalVault,
    clmm_config: &ClmmGlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun collect_dlmm_reward<CoinTypeA, CoinTypeB, LPCoin, Reward>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun open_clmm_position<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pyth_oracle: &PythOracle,
    clmm_pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    clmm_config: &ClmmGlobalConfig,
    tick_lower: u32,
    tick_upper: u32,
    amount_a: u64,
    amount_b: u64,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun increase_clmm_liquidity<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pyth_oracle: &PythOracle,
    clmm_pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    clmm_config: &ClmmGlobalConfig,
    position_id: ID,
    amount_a: u64,
    amount_b: u64,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun decrease_clmm_liquidity<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pyth_oracle: &PythOracle,
    clmm_pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    clmm_config: &ClmmGlobalConfig,
    position_id: ID,
    liquidity_delta: u128,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun close_clmm_position<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    clmm_pool: &mut ClmmPool<CoinTypeA, CoinTypeB>,
    clmm_config: &ClmmGlobalConfig,
    position_id: ID,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun open_dlmm_position<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pyth_oracle: &PythOracle,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position: Position,
    cert: OpenPositionCert<CoinTypeA, CoinTypeB>,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

#[allow(unused_variable)]
public fun new_dlmm_add_liquidity_cert<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    active_id_included: bool,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &TxContext,
): AddLiquidityCert<CoinTypeA, CoinTypeB> {
    abort 0
}

public fun new_dlmm_add_liquidity_cert_v2<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pyth_oracle: &PythOracle,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    active_id_included: bool,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &TxContext,
): AddLiquidityCert<CoinTypeA, CoinTypeB> {
    abort 0
}

public fun add_dlmm_liquidity_on_bin<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    position_id: ID,
    cert: &mut AddLiquidityCert<CoinTypeA, CoinTypeB>,
    bin_group_ref: &mut BinGroupRef,
    offset_in_group: u8,
    amount_a: u64,
    amount_b: u64,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &TxContext,
) {
    abort 0
}

public fun repay_dlmm_add_liquidity<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    cert: AddLiquidityCert<CoinTypeA, CoinTypeB>,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &TxContext,
) {
    abort 0
}

#[allow(unused_variable)]
public fun open_position_bid_ask<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    total_amount_a: u64,
    total_amount_b: u64,
    lower_bin_id: u32,
    width: u16,
    expected_active_id: u32,
    max_bin_slippage: u32,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun open_position_bid_ask_v2<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pyth_oracle: &PythOracle,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    total_amount_a: u64,
    total_amount_b: u64,
    lower_bin_id: u32,
    width: u16,
    expected_active_id: u32,
    max_bin_slippage: u32,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

#[allow(unused_variable)]
public fun open_position_spot<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    total_amount_a: u64,
    total_amount_b: u64,
    lower_bin_id: u32,
    width: u16,
    expected_active_id: u32,
    max_bin_slippage: u32,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun open_position_spot_v2<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pyth_oracle: &PythOracle,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    total_amount_a: u64,
    total_amount_b: u64,
    lower_bin_id: u32,
    width: u16,
    expected_active_id: u32,
    max_bin_slippage: u32,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

#[allow(unused_variable)]
public fun open_position_curve<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    total_amount_a: u64,
    total_amount_b: u64,
    lower_bin_id: u32,
    width: u16,
    expected_active_id: u32,
    max_bin_slippage: u32,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun open_position_curve_v2<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pyth_oracle: &PythOracle,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    total_amount_a: u64,
    total_amount_b: u64,
    lower_bin_id: u32,
    width: u16,
    expected_active_id: u32,
    max_bin_slippage: u32,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

#[allow(unused_variable)]
public fun add_dlmm_liquidity<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    allow_amount_a: u64,
    allow_amount_b: u64,
    bins: vector<u32>,
    amounts_a: vector<u64>,
    amounts_b: vector<u64>,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun add_dlmm_liquidity_v2<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pyth_oracle: &PythOracle,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    allow_amount_a: u64,
    allow_amount_b: u64,
    bins: vector<u32>,
    amounts_a: vector<u64>,
    amounts_b: vector<u64>,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

#[allow(unused_variable)]
public fun add_dlmm_liquidity_spot<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    allow_amount_a: u64,
    allow_amount_b: u64,
    total_amount_a: u64,
    total_amount_b: u64,
    min_bin_id: u32,
    max_bin_id: u32,
    expected_active_id: u32,
    max_bin_slippage: u32,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun add_dlmm_liquidity_spot_v2<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pyth_oracle: &PythOracle,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    allow_amount_a: u64,
    allow_amount_b: u64,
    total_amount_a: u64,
    total_amount_b: u64,
    min_bin_id: u32,
    max_bin_id: u32,
    expected_active_id: u32,
    max_bin_slippage: u32,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

#[allow(unused_variable)]
public fun add_dlmm_liquidity_curve<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    total_amount_a: u64,
    total_amount_b: u64,
    min_bin_id: u32,
    max_bin_id: u32,
    expected_active_id: u32,
    max_bin_slippage: u32,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun add_dlmm_liquidity_curve_v2<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pyth_oracle: &PythOracle,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    total_amount_a: u64,
    total_amount_b: u64,
    min_bin_id: u32,
    max_bin_id: u32,
    expected_active_id: u32,
    max_bin_slippage: u32,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

#[allow(unused_variable)]
public fun add_liquidity_bid_ask<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    total_amount_a: u64,
    total_amount_b: u64,
    min_bin_id: u32,
    max_bin_id: u32,
    expected_active_id: u32,
    max_bin_slippage: u32,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun add_dlmm_liquidity_bid_ask_v2<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pyth_oracle: &PythOracle,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    total_amount_a: u64,
    total_amount_b: u64,
    min_bin_id: u32,
    max_bin_id: u32,
    expected_active_id: u32,
    max_bin_slippage: u32,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun remove_dlmm_liquidity_by_percent<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    min_bin_id: u32,
    max_bin_id: u32,
    percent: u16,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun close_dlmm_position_v2<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    dlmm_config: &DLMMGlobalConfig,
    dlmm_versioned: &DLMMVersioned,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
): market_dlmm::DLMMPositionCloseCertV2 {
    abort 0
}

public fun collect_dlmm_reward_from_close_cert_v2<CoinTypeA, CoinTypeB, LPCoin, Reward>(
    vault: &mut Vault<LPCoin>,
    pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    cert: &mut market_dlmm::DLMMPositionCloseCertV2,
    dlmm_versioned: &DLMMVersioned,
    versioned: &Versioned,
) {
    abort 0
}

public fun destroy_close_cert_v2<LPCoin>(
    vault: &Vault<LPCoin>,
    cert: market_dlmm::DLMMPositionCloseCertV2,
    dlmm_versioned: &DLMMVersioned,
    versioned: &Versioned,
) {
    abort 0
}

public fun close_dlmm_position<CoinTypeA, CoinTypeB, LPCoin>(
    _vault: &mut Vault<LPCoin>,
    _pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    _position_id: ID,
    _dlmm_config: &DLMMGlobalConfig,
    _dlmm_versioned: &DLMMVersioned,
    _config: &GlobalConfig,
    _versioned: &Versioned,
    _clk: &Clock,
    _ctx: &mut TxContext,
): market_dlmm::DLMMPositionCloseCert {
    abort 0
}

#[allow(unused_type_parameter)]
public fun collect_dlmm_reward_from_close_cert<CoinTypeA, CoinTypeB, LPCoin, Reward>(
    _vault: &mut Vault<LPCoin>,
    _pool: &mut DlmmPool<CoinTypeA, CoinTypeB>,
    _cert: &mut market_dlmm::DLMMPositionCloseCert,
    _dlmm_versioned: &DLMMVersioned,
    _versioned: &Versioned,
) {
    abort 0
}

public fun destroy_close_cert(
    _cert: market_dlmm::DLMMPositionCloseCert,
    _dlmm_versioned: &DLMMVersioned,
    _versioned: &Versioned,
) {
    abort 0
}

public fun flash_loan<CoinTypeA, CoinTypeB, LPCoin>(
    vault: &mut Vault<LPCoin>,
    pyth_oracle: &PythOracle,
    loan_amount: u64,
    config: &GlobalConfig,
    versioned: &Versioned,
    clk: &Clock,
    ctx: &mut TxContext,
): (Coin<CoinTypeA>, FlashLoanCert) {
    abort 0
}

public fun repay_flash_loan<LPCoin, CoinType>(
    vault: &mut Vault<LPCoin>,
    flash_loan_cert: FlashLoanCert,
    repay_coin: Coin<CoinType>,
    config: &GlobalConfig,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun get_vault_assets<LPCoin>(
    vault: &mut Vault<LPCoin>,
    ctx: &TxContext,
): VecMap<TypeName, u64> {
    abort 0
}

public fun is_allow_deposit<LPCoin>(vault: &Vault<LPCoin>): bool {
    abort 0
}

public fun is_allow_withdraw<LPCoin>(vault: &Vault<LPCoin>): bool {
    abort 0
}

public fun is_allow_calculate_aum<LPCoin>(vault: &Vault<LPCoin>): bool {
    abort 0
}

public fun last_tx<LPCoin>(vault: &Vault<LPCoin>, action: u8): vector<u8> {
    abort 0
}

public fun total_lp_token_amount<LPCoin>(vault: &Vault<LPCoin>): u64 {
    abort 0
}

public fun hard_cap<LPCoin>(vault: &Vault<LPCoin>): u128 {
    abort 0
}

public fun quote_type<LPCoin>(vault: &Vault<LPCoin>): QuoteTypeEnum {
    abort 0
}

public fun coin_types<LPCoin>(vault: &Vault<LPCoin>): (TypeName, TypeName) {
    abort 0
}

public fun dlmm_market<LPCoin>(vault: &Vault<LPCoin>): &DLMMMarket {
    abort 0
}

public fun clmm_market<LPCoin>(vault: &Vault<LPCoin>): &CLMMMarket {
    abort 0
}

public fun has_clmm_market<LPCoin>(vault: &Vault<LPCoin>): bool {
    abort 0
}

public fun has_dlmm_market<LPCoin>(vault: &Vault<LPCoin>): bool {
    abort 0
}

public fun is_pending(state: &WithdrawStateEnum): bool {
    abort 0
}

public fun is_finish_inited_buffer_assets(state: &WithdrawStateEnum): bool {
    abort 0
}

public fun is_completed(state: &WithdrawStateEnum): bool {
    abort 0
}

public fun index(registry: &VaultRegistry): u64 {
    abort 0
}

public fun vaults(registry: &VaultRegistry): &Table<ID, TypeName> {
    abort 0
}

public fun vault_id(cert: &WithdrawCert): ID {
    abort 0
}

public fun positions(cert: &WithdrawCert): VecSet<ID> {
    abort 0
}

public fun buffer_amounts(cert: &WithdrawCert): VecMap<TypeName, u64> {
    abort 0
}

public fun assets(cert: &WithdrawCert): &BalanceBag {
    abort 0
}

public fun state(cert: &WithdrawCert): WithdrawStateEnum {
    abort 0
}

public fun quote_type_is_usd(quote_type: QuoteTypeEnum): bool {
    abort 0
}

public fun quote_type_name(quote_type: QuoteTypeEnum): Option<TypeName> {
    abort 0
}

public fun last_aum<LPCoin>(vault: &Vault<LPCoin>): u128 {
    abort 0
}
