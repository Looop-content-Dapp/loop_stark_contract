use starknet::{ContractAddress};


// #[starknet::interface]
// pub trait ISRC6<TState> {
//     fn __execute__(self: @TState, calls: Array<Call>) -> Array<Span<felt252>>;
//     fn __validate__(self: @TState, calls: Array<Call>) -> felt252;
//     fn is_valid_signature(self: @TState, hash: felt252, signature: Array<felt252>) -> felt252;
// }

#[starknet::contract]
pub mod Account {
    use core::clone::Clone;
    use core::option::OptionTrait;
    use core::num::traits::zero::Zero;
    use core::traits::{TryInto, Into};
    use core::byte_array::ByteArrayTrait;
    use starknet::{ContractAddress, get_caller_address, get_tx_info};
    use starknet::SyscallResultTrait;
    use starknet::account::Call;
    use loop_stark_contract::utils::{
        MIN_TRANSACTION_VERSION, QUERY_VERSION, QUERY_OFFSET, execute_calls,
        is_valid_stark_signature
    };


    use loop_stark_contract::base::errors::Errors::{
        ZERO_ADDRESS_CALLER, ZERO_ADDRESS_OWNER, NOT_OWNER
    };
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::account::interface::ISRC6;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[key]
        public_key: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }


    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, public_key: u256) {
        assert(!owner.is_zero(), ZERO_ADDRESS_CALLER);
        self.ownable.initializer(owner);
        self.public_key.write(public_key)
    }


    #[abi(embed_v0)]
    impl ISRC6Impl of ISRC6<ContractState> {
        fn __execute__(self: @ContractState, calls: Array<Call>) -> Array<Span<felt252>> {
            assert!(get_caller_address().is_zero(), "Invalid Address");

            //check for transaction version
            let tx_info = get_tx_info().unbox();
            let tx_version = tx_info.version.into();

            if (tx_version >= QUERY_OFFSET) {
                assert!(QUERY_OFFSET + MIN_TRANSACTION_VERSION <= tx_version, "invalid tx version")
            } else {
                assert!(MIN_TRANSACTION_VERSION <= tx_version, "invalid tx version");
            }
            execute_calls(calls)
        }

        fn __validate__(self: @ContractState, calls: Array<Call>) -> felt252 {
            let tx_info = get_tx_info().unbox();
            self._is_valid_signature(tx_info.transaction_hash, tx_info.signature)
        }

        fn is_valid_signature(
            self: @ContractState, hash: felt252, signature: Array<felt252>
        ) -> felt252 {
            self._is_valid_signature(hash, signature.span())
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _is_valid_signature(
            self: @ContractState, hash: felt252, signature: Span<felt252>
        ) -> felt252 {
            let public_key = self.public_key.read();

            let validate_signature = is_valid_stark_signature(
                hash, public_key.try_into().unwrap(), signature
            );

            if validate_signature {
                starknet::VALIDATED
            } else {
                0
            }
        }
    }
}
