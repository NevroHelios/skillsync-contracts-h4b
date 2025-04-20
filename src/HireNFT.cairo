#[starknet::contract]
mod HireNFT {
    // Library imports - minimal imports to reduce contract size
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;
    
    // Storage - using u64 instead of u256 for gas efficiency
    #[storage]
    struct Storage {
        token_owner: LegacyMap::<u64, ContractAddress>,
        token_uri: LegacyMap::<u64, felt252>,
        total_supply: u64,
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        HireNFTMinted: HireNFTMinted,
    }

    // HireNFTMinted event - emitted when a new hire NFT is minted
    #[derive(Drop, starknet::Event)]
    struct HireNFTMinted {
        hr: ContractAddress,
        developer: ContractAddress,
        token_id: u64,
        job_id: felt252,
        company_name: felt252,
        job_title: felt252,
    }

    // Constructor - initialized on deployment
    #[constructor]
    fn constructor(ref self: ContractState) {
        // Initialize total_supply to 0
        self.total_supply.write(0);
    }

    // External functions
    #[external(v0)]
    #[generate_trait]
    impl HireNFTImpl of HireNFTTrait {
        // Mint a new hire NFT
        fn mint_hire_nft(
            ref self: ContractState,
            developer: ContractAddress,
            job_id: felt252,
            company_name: felt252,
            job_title: felt252,
            uri: felt252,
        ) {
            // Get caller address (HR)
            let caller = get_caller_address();
            
            // Get current token ID
            let token_id = self.total_supply.read();
            
            // Store token owner
            self.token_owner.write(token_id, developer);
            
            // Store token URI
            self.token_uri.write(token_id, uri);
            
            // Emit HireNFTMinted event
            self.emit(Event::HireNFTMinted(
                HireNFTMinted {
                    hr: caller,
                    developer,
                    token_id,
                    job_id,
                    company_name,
                    job_title,
                }
            ));
            
            // Increment total supply
            self.total_supply.write(token_id + 1);
        }

        // Get token URI - removed #[view] attribute
        fn get_token_uri(self: @ContractState, token_id: u64) -> felt252 {
            self.token_uri.read(token_id)
        }

        // Get token owner - removed #[view] attribute
        fn get_token_owner(self: @ContractState, token_id: u64) -> ContractAddress {
            self.token_owner.read(token_id)
        }
        
        // Get total supply - removed #[view] attribute
        fn get_total_supply(self: @ContractState) -> u64 {
            self.total_supply.read()
        }
    }
}
