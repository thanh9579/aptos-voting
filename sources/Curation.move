module my_addrx::Curation { 

    use 0x1::signer;
    use std::vector;
    use std::account;
    use std::simple_map::{Self,SimpleMap};
    /// Error codes

    struct Poll has store,key,drop,copy{
        viewPoint: vector<u8>,
        votedAddresses: vector<address>,
        options_vote: SimpleMap<vector<u8>, u64>,
        options_list: vector<vector<u8>>
    }

    struct Polls has store,key,copy,drop{
        //poll_count : SimpleMap<u64,Poll>,
        list_of_polls : vector<Poll>
    }

    public fun assert_is_owner(addr: address) {
        assert!(addr == @my_addrx, 0);
    }

    public fun assert_is_initialized(addr: address) {
        assert!(exists<Polls>(addr), 1);
    }

    public fun assert_uninitialized(addr: address) {
        assert!(!exists<Polls>(addr), 3);
    }  

    public fun assert_contains_option(map: &SimpleMap<vector<u8>, u64>, option: &vector<u8>) {
    assert!(simple_map::contains_key(map, option), 2);  
    }

    public fun assert_not_contains_option(map: &SimpleMap<vector<u8>, u64>, option: &vector<u8>) {
    assert!(!simple_map::contains_key(map, option), 4);
    }

    public entry fun initialize(acc: &signer, msg: vector<u8>,option1:vector<u8>,option2:vector<u8>)acquires Polls{
        let addr = signer::address_of(acc);

        assert_is_owner(addr);
        

        let b_store = Poll{
            viewPoint : msg,
            votedAddresses: vector<address>[],
            options_vote: simple_map::create(),
            options_list: vector<vector<u8>>[option1,option2]
            };
         simple_map::add(&mut b_store.options_vote, option1, 0);
         simple_map::add(&mut b_store.options_vote, option2, 0);



        if(!exists<Polls>(addr))
            move_to(acc,Polls{list_of_polls : (vector[b_store])})
        else if(exists<Polls>(addr))
            vector::push_back(&mut borrow_global_mut<Polls>(addr).list_of_polls,b_store)
    }

    public entry fun add_option(acc: &signer, option: vector<u8>,i :u64) acquires Polls {
    let addr = signer::address_of(acc);
    assert_is_owner(addr);
    assert_is_initialized(addr);//it doesn't check for the specific poll

    let c_store = borrow_global_mut<Polls>(addr);
    let required_poll = vector::borrow_mut<Poll>(&mut c_store.list_of_polls,i);

    simple_map::add(&mut required_poll.options_vote, option, 0);
    vector::push_back(&mut required_poll.options_list, option);
    }



    public fun vote(acc_own: &signer, store_addr: address,_vote:bool,i:u64, option : vector<u8> )acquires Polls{
        let addr = signer::address_of(acc_own);
        
        assert_uninitialized(addr);//useless to be removed 

        let op_store = borrow_global_mut<Polls>(store_addr);

        // Check if the voter has already voted
        let required_poll = vector::borrow_mut<Poll>(&mut op_store.list_of_polls,i);
        assert!(!vector::contains(&required_poll.votedAddresses, &addr), 4);

        //increment the vote count by one
        assert_contains_option(&required_poll.options_vote, &option);  
        let votes = simple_map::borrow_mut(&mut required_poll.options_vote, &option);
        *votes = *votes + 1;
        
        // Add the voter's address to the set of voted addresses
        vector::push_back(&mut required_poll.votedAddresses, addr);
    }

    // public fun currentStandings(store_addr: address):u64 acquires Poll{
    //     let op_store = borrow_global_mut<Poll>(store_addr);
    //     return (op_store.trueVotes*100/op_store.totalVotes*100)/100
    // }


    public fun voteCount(store_addr: address,i:u64,option : vector<u8>):u64 acquires Polls{
        let op_store = borrow_global_mut<Polls>(store_addr);
        let required_poll = vector::borrow_mut<Poll>(&mut op_store.list_of_polls,i);
        let votes = simple_map::borrow(&mut required_poll.options_vote, &option);
        return *votes
    }

    #[test(admin = @my_addrx)]
    fun test_flow(admin: signer)acquires Polls {
        let owner = signer::address_of(&admin);
        let voter = account::create_account_for_test(@0x3);
        let voter2 = account::create_account_for_test(@0x4);
        let voter3 = account::create_account_for_test(@0x5);
        let voter4 = account::create_account_for_test(@0x6);
        let voter5 = account::create_account_for_test(@0x7);
        let greet:vector<u8> = b"Welcome to Aptos move by examples"; 
        //let newgreet:vector<u8> = b"Welcome to Aptos move by examples again";
        let option1:vector<u8> = b"Ariana"; 
        let option2:vector<u8> = b"Selena"; 
        let option3:vector<u8> = b"Camillo"; 
        initialize(&admin, greet,option1,option2);
        add_option(&admin, option3,0);
        vote(&voter,owner, true,0,option1);
        vote(&voter2,owner, true,0,option1);
        vote(&voter3,owner, true,0,option1);
        vote(&voter4,owner, true,0,option3);
        vote(&voter5,owner, true,0,option2);
        //vote(&voter5,owner, true,0); //THROW ERROR BECAUSE WE TRYING TO ADD OUR VOTE SECOND TIME
        //let value = currentStandings(owner); //its giving wrong value
        let totolvotes1 = voteCount(owner,0,option1);
        let totolvotes2 = voteCount(owner,0,option2);
        let totolvotes3 = voteCount(owner,0,option3);
        //std::debug::print(&value);
        //assert!(value == 100,0);
        assert!(totolvotes1 == 3,0);
        assert!(totolvotes2 == 1,0);
        assert!(totolvotes3 == 1,0);


    }
}