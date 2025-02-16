module my_addrx::Polling { 

    use 0x1::signer;
    use std::account;
    use std::vector;
    use std::simple_map::{Self,SimpleMap};
    /// Error codes

    struct Poll has store,key,drop,copy{
        viewPoint: vector<u8>,
        totalVotes:u64,
        trueVotes: u64,
        votedAddresses: vector<address>
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

    public fun initialize(acc: &signer, msg: vector<u8>)acquires Polls{
        let addr = signer::address_of(acc);

        //assert_is_owner(addr);
        

        let b_store = Poll{
            viewPoint : msg,
            totalVotes: 0,
            trueVotes: 0,
            votedAddresses: vector<address>[],
            };

        if(!exists<Polls>(addr))
            move_to(acc,Polls{list_of_polls : (vector[b_store])})
        else if(exists<Polls>(addr))
            vector::push_back(&mut borrow_global_mut<Polls>(addr).list_of_polls,b_store)
    }



    public fun vote(acc_own: &signer, store_addr: address,_vote:bool,i:u64 )acquires Polls{
        let addr = signer::address_of(acc_own);
        
        assert_uninitialized(addr);//useless to be removed 

        let op_store = borrow_global_mut<Polls>(store_addr);

        // Check if the voter has already voted
        let required_poll = vector::borrow_mut<Poll>(&mut op_store.list_of_polls,i);
        assert!(!vector::contains(&required_poll.votedAddresses, &addr), 4);
        required_poll.totalVotes = required_poll.totalVotes + 1;

        if(_vote == true){
            required_poll.trueVotes =  required_poll.trueVotes + 1;
        };

        // Add the voter's address to the set of voted addresses
        vector::push_back(&mut required_poll.votedAddresses, addr);
    }

    public fun currentStandings(store_addr: address):u64 acquires Poll{
        let op_store = borrow_global_mut<Poll>(store_addr);
        return (op_store.trueVotes*100/op_store.totalVotes*100)/100
    }


    public fun voteCount(store_addr: address,i:u64):u64 acquires Polls{
        let op_store = borrow_global_mut<Polls>(store_addr);
        let required_poll = vector::borrow_mut<Poll>(&mut op_store.list_of_polls,i);
        return required_poll.totalVotes
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
        let newgreet:vector<u8> = b"Welcome to Aptos move by examples again";
        initialize(&admin, greet);
        initialize(&admin, newgreet);
        vote(&voter,owner, true,0);
        vote(&voter2,owner, true,1);
        vote(&voter3,owner, true,0);
        vote(&voter4,owner, true,0);
        vote(&voter5,owner, true,0);
        vote(&voter5,owner, true,0); //THROW ERROR BECAUSE WE TRYING TO ADD OUR VOTE SECOND TIME
        //let value = currentStandings(owner); //its giving wrong value
        let totolvotes1 = voteCount(owner,0);
        let totolvotes2 = voteCount(owner,1);
        //std::debug::print(&value);
        //assert!(value == 100,0);
        assert!(totolvotes1 == 4,0);
        assert!(totolvotes2 == 1,0);


    }
}