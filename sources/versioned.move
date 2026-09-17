// Copyright (c) Haedal Technology Limited

#[allow(unused_variable, unused_type_parameter)]
module volatile_vault_v2::versioned;

use cetusdlmm::admin_cap::AdminCap as DLMMAdminCap;
use volatile_vault_v2::admin_cap::AdminCap;

/// Main version tracking object.
///
/// This struct tracks the version of a component in the DLMM protocol.
/// It provides version checking and upgrade capabilities.
///
/// ## Fields
/// - `id`: Unique identifier for the versioned object
/// - `version`: Current version of the object
public struct Versioned has key, store {
    id: UID,
    version: u64,
}

/// Event emitted when a versioned object is initialized.
///
/// ## Fields
/// - `versioned`: ID of the initialized versioned object
public struct InitEvent has copy, drop {
    versioned: ID,
}

fun init(ctx: &mut TxContext) {
    abort 0
}

public fun check_version(versioned: &Versioned) {
    abort 0
}

public fun upgrade(_versioned: &mut Versioned, _: &DLMMAdminCap) {
    abort 0
}

public fun upgrade_v2(versioned: &mut Versioned, _: &AdminCap) {
    abort 0
}

public fun version(versioned: &Versioned): u64 {
    abort 0
}

public fun current_version(): u64 {
    abort 0
}

public(package) fun set_version(versioned: &mut Versioned, version: u64) {
    abort 0
}

