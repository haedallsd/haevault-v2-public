// Copyright (c) Haedal Technology Limited

#[allow(unused_variable, unused_type_parameter)]
module volatile_vault_v2::config;

use std::type_name::TypeName;
use sui::vec_map::VecMap;
use volatile_vault_v2::acl;
use volatile_vault_v2::admin_cap::AdminCap;
use volatile_vault_v2::versioned::Versioned;

public struct GlobalConfig has key {
    id: UID,
    swap_slippages: VecMap<TypeName, u64>,
    protocol_fee_rate: u64,
    last_version: u64,
    acl: acl::ACL,
}

public struct InitConfigEvent has copy, drop {
    global_config: ID,
}

public struct SetRolesEvent has copy, drop {
    member: address,
    roles: u128,
}

public struct RemoveMemberEvent has copy, drop {
    member: address,
}

public struct UpdateFeeRateEvent has copy, drop {
    old_fee_rate: u64,
    new_fee_rate: u64,
}

public struct SetSwapSlippageEvent has copy, drop {
    type_name: TypeName,
    old_slippage: u64,
    new_slippage: u64,
}

public struct EmergencyPauseEvent has copy, drop {
    version: u64,
}

public struct EmergencyUnpauseEvent has copy, drop {
    version: u64,
}

public struct SetAumSafetyMarginBpsEvent has copy, drop {
    old: u64,
    new: u64,
}

fun init(ctx: &mut TxContext) {
    abort 0
}

public fun set_aum_safety_margin_bps(
    config: &mut GlobalConfig,
    aum_safety_margin_bps: u64,
    versioned: &Versioned,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun set_roles(
    config: &mut GlobalConfig,
    _: &AdminCap,
    versioned: &Versioned,
    member: address,
    roles: u128,
) {
    abort 0
}

public fun remove_member(
    config: &mut GlobalConfig,
    _: &AdminCap,
    versioned: &Versioned,
    member: address,
) {
    abort 0
}

public fun emergency_pause(config: &mut GlobalConfig, versioned: &mut Versioned, ctx: &TxContext) {
    abort 0
}

public fun emergency_unpause(
    config: &mut GlobalConfig,
    versioned: &mut Versioned,
    _: &AdminCap,
    version: u64,
) {
    abort 0
}

public fun update_protocol_fee_rate(
    config: &mut GlobalConfig,
    versioned: &Versioned,
    new_fee_rate: u64,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun set_swap_slippage<CoinType>(
    config: &mut GlobalConfig,
    versioned: &Versioned,
    new_slippage: u64,
    ctx: &mut TxContext,
) {
    abort 0
}

public fun check_keeper_manager_role(config: &GlobalConfig, member: address) {
    abort 0
}

public fun has_keeper_manager_role(config: &GlobalConfig, member: address): bool {
    abort 0
}

public fun check_protocol_fee_claim_role(config: &GlobalConfig, member: address) {
    abort 0
}

public fun check_vault_manager_role(config: &GlobalConfig, member: address) {
    abort 0
}

public fun check_oracle_manager_role(config: &GlobalConfig, member: address) {
    abort 0
}

public fun check_emergency_pause_role(config: &GlobalConfig, member: address) {
    abort 0
}

public fun check_config_manager_role(config: &GlobalConfig, member: address) {
    abort 0
}

public fun get_swap_slippage<CoinType>(config: &GlobalConfig): u64 {
    abort 0
}

public fun get_protocol_fee_rate(config: &GlobalConfig): u64 {
    abort 0
}

public macro fun emergency_pause_version(): u64 {
    abort 0
}

public macro fun protocol_fee_denominator(): u64 {
    abort 0
}

public macro fun max_protocol_fee_rate(): u64 {
    abort 0
}

public macro fun slippage_denominator(): u64 {
    abort 0
}

public fun get_aum_safety_margin_bps(config: &GlobalConfig): u64 {
    abort 0
}

public fun aum_safety_margin_denominator(): u64 {
    abort 0
}

