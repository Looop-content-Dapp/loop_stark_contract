#[starknet::interface]
pub trait IAccounts<TContractState> {
    fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;
}
