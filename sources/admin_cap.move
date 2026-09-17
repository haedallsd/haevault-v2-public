#[allow(unused_variable, unused_type_parameter)]
module volatile_vault_v2::admin_cap;

/// Administrative capability that grants privileges to perform administrative operations
/// within the DLMM Vault protocol.
public struct AdminCap has key, store {
    id: object::UID,
}

/// Event emitted when the admin capability is initialized.
public struct InitEvent has copy, drop {
    admin_cap_id: ID,
}

fun init(ctx: &mut TxContext) {
    abort 0
}

