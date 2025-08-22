module MyModule::PreventiveCare {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing a patient's preventive care account
    struct CareAccount has store, key {
        balance: u64,           // Available balance for care payments
        last_checkup: u64,      // Timestamp of last preventive checkup
        provider: address,      // Healthcare provider address
    }

    /// Error codes
    const E_ACCOUNT_NOT_EXISTS: u64 = 1;
    const E_INSUFFICIENT_BALANCE: u64 = 2;
    const E_UNAUTHORIZED_PROVIDER: u64 = 3;

    /// Function to setup a patient's preventive care account
    public fun setup_care_account(
        patient: &signer, 
        provider: address, 
        initial_deposit: u64
    ) {
        let account = CareAccount {
            balance: initial_deposit,
            last_checkup: 0,
            provider,
        };

        // Transfer initial deposit from patient
        if (initial_deposit > 0) {
            let deposit = coin::withdraw<AptosCoin>(patient, initial_deposit);
            coin::deposit<AptosCoin>(signer::address_of(patient), deposit);
        };

        move_to(patient, account);
    }

    /// Function for healthcare provider to process micro-payment for preventive care
    public fun process_care_payment(
        provider: &signer,
        patient_address: address,
        service_cost: u64
    ) acquires CareAccount {
        let care_account = borrow_global_mut<CareAccount>(patient_address);
        
        // Verify provider authorization
        assert!(care_account.provider == signer::address_of(provider), E_UNAUTHORIZED_PROVIDER);
        
        // Check sufficient balance
        assert!(care_account.balance >= service_cost, E_INSUFFICIENT_BALANCE);
        
        // Process payment
        care_account.balance = care_account.balance - service_cost;
        care_account.last_checkup = timestamp::now_seconds();
        
        // Transfer payment to provider
        let payment = coin::withdraw<AptosCoin>(provider, service_cost);
        coin::deposit<AptosCoin>(signer::address_of(provider), payment);
    }
}