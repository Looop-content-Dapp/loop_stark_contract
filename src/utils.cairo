use core::ecdsa::check_ecdsa_signature;
use core::integer::{u32_wide_mul, u8_wide_mul, BoundedInt};


use starknet::SyscallResultTrait;
use starknet::account::Call;


pub const MIN_TRANSACTION_VERSION: u256 = 1;
pub const QUERY_OFFSET: u256 = 0x100000000000000000000000000000000;
// QUERY_OFFSET + TRANSACTION_VERSION
pub const QUERY_VERSION: u256 = 0x100000000000000000000000000000001;

pub fn execute_calls(mut calls: Array<Call>) -> Array<Span<felt252>> {
    let mut res = ArrayTrait::new();
    loop {
        match calls.pop_front() {
            Option::Some(call) => {
                let _res = execute_single_call(call);
                res.append(_res);
            },
            Option::None(_) => { break (); },
        };
    };
    res
}

fn execute_single_call(call: Call) -> Span<felt252> {
    let Call { to, selector, calldata } = call;
    starknet::syscalls::call_contract_syscall(to, selector, calldata).unwrap_syscall()
}

// pub fn is_valid_stark_signature(
//     msg_hash: felt252, public_key: felt252, signature: Span<felt252>
// ) -> bool {
//     let valid_length = signature.len() == 2;

//     if valid_length {
//         check_ecdsa_signature(msg_hash, public_key, *signature.at(0_u32), *signature.at(1_u32))
//     } else {
//         false
//     }
// }

fn is_valid_stark_signature(self: @ContractState, hash: felt252, signature: Span<felt252>) -> bool {
    //let valid_length = signature.len() == 2_u32;

    //if valid_length {
    check_ecdsa_signature(hash, self.public_key.read(), *signature.at(0_u32), *signature.at(1_u32))
// } else {
//     false
// }
}
