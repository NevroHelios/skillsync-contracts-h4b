#[starknet::contract]
mod JobPostNFT {
    // Library imports - minimal imports to reduce contract size
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;

    // Constants
    const NAME: felt252 = 'Job Postings';
    const SYMBOL: felt252 = 'JOBNFT';

    // Job Posting struct - using u64 instead of u256 for gas efficiency
    #[derive(Drop, Serde, starknet::Store)]
    struct JobPosting {
        // HR who created the job
        hr: ContractAddress,
        // Job details - immutable once created
        job_id: felt252,
        job_title: felt252,
        company_name: felt252,
        requirements: felt252,
        // Creation timestamp
        timestamp: u64,
    }

    // Storage - minimized for gas efficiency
    #[storage]
    struct Storage {
        // Token ID counter - using u64 instead of u256
        next_token_id: u64,
        // Mapping from token ID to job posting
        job_postings: LegacyMap::<u64, JobPosting>,
        // Mapping from token ID to owner
        owners: LegacyMap::<u64, ContractAddress>,
        // Mapping from owner to token count
        balances: LegacyMap::<ContractAddress, u64>,
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        JobCreated: JobCreated,
        Transfer: Transfer,
    }

    // JobCreated event - emitted when a new job posting is created
    #[derive(Drop, starknet::Event)]
    struct JobCreated {
        token_id: u64,
        hr: ContractAddress,
        job_id: felt252,
        job_title: felt252,
        company_name: felt252,
        requirements: felt252,
    }

    // Transfer event - emitted when a token is transferred
    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u64,
    }

    // Constructor - initialized on deployment
    #[constructor]
    fn constructor(ref self: ContractState) {
        // Initialize next_token_id to 1
        self.next_token_id.write(1);
    }

    // External functions
    #[external(v0)]
    #[generate_trait]
    impl JobPostNFTImpl of JobPostNFTTrait {
        // Create a new job posting
        fn create_job(
            ref self: ContractState,
            job_id: felt252,
            job_title: felt252,
            company_name: felt252,
            requirements: felt252,
        ) -> u64 {
            // Get caller address (HR)
            let hr = get_caller_address();
            
            // Get current token ID
            let token_id = self.next_token_id.read();
            
            // Create job posting
            let job_posting = JobPosting {
                hr,
                job_id,
                job_title,
                company_name,
                requirements,
                timestamp: starknet::get_block_timestamp(),
            };
            
            // Store job posting
            self.job_postings.write(token_id, job_posting);
            
            // Mint token to HR
            self._mint(hr, token_id);
            
            // Emit JobCreated event
            self.emit(Event::JobCreated(
                JobCreated {
                    token_id,
                    hr,
                    job_id,
                    job_title,
                    company_name,
                    requirements,
                }
            ));
            
            // Increment token ID counter
            self.next_token_id.write(token_id + 1);
            
            // Return token ID
            token_id
        }

        // Get job posting details
        fn get_job(self: @ContractState, token_id: u64) -> JobPosting {
            // Check if token exists
            assert(self._exists(token_id), 'Token does not exist');
            
            // Return job posting
            self.job_postings.read(token_id)
        }

        // Get token owner
        fn owner_of(self: @ContractState, token_id: u64) -> ContractAddress {
            // Check if token exists
            assert(self._exists(token_id), 'Token does not exist');
            
            // Return owner
            self.owners.read(token_id)
        }

        // Get balance of owner
        fn balance_of(self: @ContractState, owner: ContractAddress) -> u64 {
            // Check if owner is valid
            assert(!owner.is_zero(), 'Zero address');
            
            // Return balance
            self.balances.read(owner)
        }

        // Transfer token
        fn transfer(ref self: ContractState, to: ContractAddress, token_id: u64) {
            // Check if token exists
            assert(self._exists(token_id), 'Token does not exist');
            
            // Get caller address
            let from = get_caller_address();
            
            // Check if caller is owner
            assert(from == self.owners.read(token_id), 'Not owner');
            
            // Check if recipient is valid
            assert(!to.is_zero(), 'Zero address recipient');
            
            // Transfer token
            self._transfer(from, to, token_id);
        }

        // Get contract name
        fn name(self: @ContractState) -> felt252 {
            NAME
        }

        // Get contract symbol
        fn symbol(self: @ContractState) -> felt252 {
            SYMBOL
        }

        // Get next token ID
        fn get_next_token_id(self: @ContractState) -> u64 {
            self.next_token_id.read()
        }
    }

    // Internal functions
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        // Check if token exists
        fn _exists(self: @ContractState, token_id: u64) -> bool {
            !self.owners.read(token_id).is_zero()
        }

        // Mint token
        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u64) {
            // Check if recipient is valid
            assert(!to.is_zero(), 'Zero address recipient');
            
            // Check if token already exists
            assert(!self._exists(token_id), 'Token already exists');
            
            // Update balances
            self.balances.write(to, self.balances.read(to) + 1);
            
            // Set token owner
            self.owners.write(token_id, to);
            
            // Emit Transfer event
            self.emit(Event::Transfer(
                Transfer {
                    from: Zeroable::zero(),
                    to,
                    token_id,
                }
            ));
        }

        // Transfer token
        fn _transfer(ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u64) {
            // Update balances
            self.balances.write(from, self.balances.read(from) - 1);
            self.balances.write(to, self.balances.read(to) + 1);
            
            // Update token owner
            self.owners.write(token_id, to);
            
            // Emit Transfer event
            self.emit(Event::Transfer(
                Transfer {
                    from,
                    to,
                    token_id,
                }
            ));
        }
    }
}
