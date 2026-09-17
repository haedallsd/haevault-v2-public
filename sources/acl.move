// Copyright (c) Haedal Technology Limited

#[allow(unused_variable, unused_type_parameter)]
module volatile_vault_v2::acl;

use move_stl::linked_table::LinkedTable;

/// Stores access control permissions for members using a linked table mapping addresses to permission bitmasks.
/// Each member's permissions are represented by a 128-bit integer where each bit corresponds to a role.
public struct ACL has store {
    permissions: LinkedTable<address, u128>,
}

/// Create a new empty access control list (ACL).
public fun new(ctx: &mut TxContext): ACL {
    abort 0
}

/// Check if a member has a specific role in the ACL.
public fun has_role(acl: &ACL, member: address, role: u8): bool {
    abort 0
}

/// Set all roles for a member in the ACL.
public fun set_roles(acl: &mut ACL, member: address, permissions: u128) {
    abort 0
}

/// Add a role for a member in the ACL.
public fun add_role(acl: &mut ACL, member: address, role: u8) {
    abort 0
}

/// Revoke a role for a member in the ACL.
public fun remove_role(acl: &mut ACL, member: address, role: u8) {
    abort 0
}

/// Remove all roles and permissions for a member from the ACL.
public fun remove_member(acl: &mut ACL, member: address) {
    abort 0
}

/// Get the permission of member by addresss.
/// Get the permission value for a member address in the ACL.
/// Returns 0 if the address is not a member, otherwise returns their permission bitmask.
public fun get_permission(acl: &ACL, user_addr: address): u128 {
    abort 0
}

