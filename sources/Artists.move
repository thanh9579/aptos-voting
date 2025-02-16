module my_addrx::Application {
	use std::vector;
    use std::debug;
    use 0x1::signer;
	use std::string::{String,utf8};

	struct Users has key,drop {
		list_of_users: vector<User>    //storing the list of the users
	}

	struct User has store,drop,copy {
		name:String,                   //information required for a typical user
		age:u8
	}

        //creating a user by adding the user to the existing list and returning the user
	public fun create_user(acc:&signer, new_name:String, new_age:u8)  :User acquires Users{
        let addr = signer::address_of(acc);

        let new_user = User{
            name : new_name,
            age : new_age
        };
        
        if(!exists<Users>(addr))
            move_to(acc, Users{list_of_users : (vector[new_user])})
        else if(exists<Users>(addr))
            vector::push_back(&mut borrow_global_mut<Users>(addr).list_of_users,new_user);

		return new_user
	}
	
	#[test(admin = @my_addrx)]
	fun test_create_friend(admin: signer)acquires Users{
        let new_name: String = utf8(b"tarun");

		let createdUser = create_user(&admin,new_name,20);
        //debug::print(&users);
        assert!(createdUser.name == utf8(b"tarun"),0);
	}
}