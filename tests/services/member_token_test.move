#[test_only]
module loychain::member_token_test {
  use loychain::member_token;

  #[test]
  public fun test_receive_coin(){
    use sui::test_scenario;
    use sui::coin::{Self, Coin};
    use sui::sui::{SUI};

    use loychain::loy::{LOY};
    use loychain::member::{Self, MemberBoard};
    use loychain::member_token;
    use loychain::util;
    use std::string::{Self, String};

    let owner = @0001;
    let email: String = string::utf8(b"admin@loychain.org");
    let nick_name: String = string::utf8(b"Scoth");

    let scenario = test_scenario::begin(owner);

    // setup member_board
    {
      let ctx = test_scenario::ctx(&mut scenario);
      member::init_create_member_board(ctx);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = member::register_member(nick_name, email, owner, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Execute the call
    test_scenario::next_tx(&mut scenario, owner);
    let (metadata_loy, metadata_sui) = {

      let board = test_scenario::take_shared(&scenario);
      let member = member::borrow_mut_member_by_email(&mut board, &email);

      let ctx = test_scenario::ctx(&mut scenario);
      let amount_coin1 = coin::mint_for_testing<LOY>(1000u64, ctx);
      let amount_coin2 = coin::mint_for_testing<LOY>(2000u64, ctx);

      let amount_coin3 = coin::mint_for_testing<SUI>(500u64, ctx);

      // CoinMetadata#id
      // let metadata_loy = object::id(&amount_coin1);
      // let metadata_sui = object::id(&amount_coin3);
      let metadata_loy = util::get_name_as_bytes<LOY>();
      let metadata_sui = util::get_name_as_bytes<SUI>();

      member_token::receive_coin<LOY>(member, amount_coin1, ctx);
      member_token::receive_coin<LOY>(member, amount_coin2, ctx);
      member_token::receive_coin<SUI>(member, amount_coin3, ctx);

      test_scenario::return_shared<MemberBoard>(board);
      (metadata_loy, metadata_sui)
    };

    // Expect the output
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = member::borrow_mut_member_by_email(&mut board, &email);

      let coin_loy: &Coin<LOY> = member_token::borrow_coin_by_coin_type<LOY>(member, metadata_loy);
      let coin_sui: &Coin<SUI> = member_token::borrow_coin_by_coin_type<SUI>(member, metadata_sui);

      assert!(coin::value(coin_loy) == 3000, 0);
      assert!(coin::value(coin_sui) == 500, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };
    test_scenario::end(scenario);
  }

  #[test]
  public fun test_split_coin_success(){
    use sui::test_scenario;
    use sui::coin::{Self, Coin};
    use sui::sui::{SUI};

    use loychain::loy::{LOY};
    use loychain::util;
    use loychain::member::{Self, MemberBoard};
    use loychain::member_token;

    use std::string::{Self, String};

    let owner = @0001;
    let email: String = string::utf8(b"admin@loychain.org");
    let nick_name: String = string::utf8(b"Scoth");

    let scenario = test_scenario::begin(owner);

    // setup member_board
    {
      let ctx = test_scenario::ctx(&mut scenario);
      member::init_create_member_board(ctx);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = member::register_member(nick_name, email, owner, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Execution call
    test_scenario::next_tx(&mut scenario, owner);
    let (metadata_loy, metadata_sui) = {

      let board = test_scenario::take_shared(&scenario);
      let member = member::borrow_mut_member_by_email(&mut board, &email);

      let ctx = test_scenario::ctx(&mut scenario);
      let amount_coin1 = coin::mint_for_testing<LOY>(1000u64, ctx);
      let amount_coin2 = coin::mint_for_testing<LOY>(2000u64, ctx);

      let amount_coin3 = coin::mint_for_testing<SUI>(500u64, ctx);

      // CoinMetadata#id
      // let metadata_loy = object::id(&amount_coin1);
      // let metadata_sui = object::id(&amount_coin3);
      let metadata_loy = util::get_name_as_bytes<LOY>();
      let metadata_sui = util::get_name_as_bytes<SUI>();

      member_token::receive_coin<LOY>(member, amount_coin1, ctx);
      member_token::receive_coin<LOY>(member, amount_coin2, ctx);
      member_token::receive_coin<SUI>(member, amount_coin3, ctx);

      test_scenario::return_shared<MemberBoard>(board);
      (metadata_loy, metadata_sui)
    };

    // Expect output for the return coin object
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = member::borrow_mut_member_by_email(&mut board, &email);
      let ctx = test_scenario::ctx(&mut scenario);

      let coin_loy: Coin<LOY> = member_token::split_coin<LOY>(1500, member, ctx);
      let coin_sui: Coin<SUI> = member_token::split_coin<SUI>(300, member, ctx);

      assert!(coin::value(&coin_loy) == 1500, 0);
      assert!(coin::value(&coin_sui) == 300, 0);

      assert!(coin::burn_for_testing<LOY>(coin_loy) == 1500, 0 );
      assert!(coin::burn_for_testing<SUI>(coin_sui) == 300, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    // Expect output for owner remaining coin
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = member::borrow_mut_member_by_email(&mut board, &email);

      let coin_loy: &Coin<LOY> = member_token::borrow_coin_by_coin_type<LOY>(member, metadata_loy);
      let coin_sui: &Coin<SUI> = member_token::borrow_coin_by_coin_type<SUI>(member, metadata_sui);

      assert!(coin::value(coin_loy) == 1500, 0);
      assert!(coin::value(coin_sui) == 200, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=member_token::ERROR_NOT_OWNER)]
  public fun test_split_coin_not_owner(){
    use sui::test_scenario;

    use loychain::loy::{LOY};
    use loychain::member::{Self, MemberBoard};
    use loychain::member_token;

    use std::string::{Self, String};

    let owner = @0001;
    let email: String = string::utf8(b"admin@loychain.org");
    let nick_name: String = string::utf8(b"Scoth");

    let scenario = test_scenario::begin(owner);

    // setup member_board
    {
      let ctx = test_scenario::ctx(&mut scenario);
      member::init_create_member_board(ctx);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = member::register_member(nick_name, email, owner, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Execution call
    let ousider = @0x0004;
    test_scenario::next_tx(&mut scenario, ousider);

    test_scenario::next_tx(&mut scenario, ousider);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = member::borrow_mut_member_by_email(&mut board, &email);
      let ctx = test_scenario::ctx(&mut scenario);

      // this would fail eventually ERROR_NOT_OWNER
      let coin = member_token::split_coin<LOY>(1500, member, ctx);
      member_token::receive_coin<LOY>(member, coin, ctx);
      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=member_token::ERROR_COIN_NOT_EXIST)]
  public fun test_split_coin_no_coin(){
    use sui::test_scenario;

    use loychain::loy::{LOY};
    use loychain::member::{Self, MemberBoard};
    use loychain::member_token;

    use std::string::{Self, String};

    let owner = @0001;
    let email: String = string::utf8(b"admin@loychain.org");
    let nick_name: String = string::utf8(b"Scoth");

    let scenario = test_scenario::begin(owner);

    // setup member_board
    {
      let ctx = test_scenario::ctx(&mut scenario);
      member::init_create_member_board(ctx);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = member::register_member(nick_name, email, owner, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Execution call
    test_scenario::next_tx(&mut scenario, owner);

    // Expect to crash
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = member::borrow_mut_member_by_email(&mut board, &email);
      let ctx = test_scenario::ctx(&mut scenario);

      // this would fail eventually EERROR_COIN_NOT_EXIST
      let coin = member_token::split_coin<LOY>(1500, member, ctx);
      member_token::receive_coin<LOY>(member, coin, ctx);
      test_scenario::return_shared<MemberBoard>(board);
    };
  
    test_scenario::end(scenario);
  }

  #[test]
  public fun test_split_and_transfer_coin(){
    use sui::test_scenario;
    use sui::coin::{Self, Coin};
    use sui::sui::{SUI};

    use loychain::loy::{LOY};
    use loychain::util;
    use loychain::member::{Self, MemberBoard};
    use loychain::member_token;

    use std::string::{Self, String};

    let member_address1 = @0001;
    let member_email1: String = string::utf8(b"admin1@loychain.org");
    let member_nick_name1: String = string::utf8(b"Scoth2");

    let member_address2 = @0002;
    let member_email2: String = string::utf8(b"admin2@loychain.org");
    let member_nick_name2: String = string::utf8(b"Scoth2");

    let scenario = test_scenario::begin(member_address1);

    // setup member_board
    {
      let ctx = test_scenario::ctx(&mut scenario);
      member::init_create_member_board(ctx);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, member_address1);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result1 = member::register_member(member_nick_name1, member_email1, member_address1, &mut board, ctx);

      // expect registration to be successful
      assert!(result1 == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, member_address2);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result2 = member::register_member(member_nick_name2, member_email2, member_address2, &mut board, ctx);

      // expect registration to be successful
      assert!(result2 == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Execution call
    test_scenario::next_tx(&mut scenario, member_address1);
    let (metadata_loy, metadata_sui) = {

      let board = test_scenario::take_shared(&scenario);
      let member1 = member::borrow_mut_member_by_email(&mut board, &member_email1);

      let ctx = test_scenario::ctx(&mut scenario);
      let amount_coin1 = coin::mint_for_testing<LOY>(1000u64, ctx);
      let amount_coin2 = coin::mint_for_testing<LOY>(2000u64, ctx);

      let amount_coin3 = coin::mint_for_testing<SUI>(500u64, ctx);

      // CoinMetadata#id
      // let metadata_loy = object::id(&amount_coin1);
      // let metadata_sui = object::id(&amount_coin3);
      let metadata_loy = util::get_name_as_bytes<LOY>();
      let metadata_sui = util::get_name_as_bytes<SUI>();

      member_token::receive_coin<LOY>(member1, amount_coin1, ctx);
      member_token::receive_coin<LOY>(member1, amount_coin2, ctx);
      member_token::receive_coin<SUI>(member1, amount_coin3, ctx);

      test_scenario::return_shared<MemberBoard>(board);
      (metadata_loy, metadata_sui)
    };

    // Expect output for the return coin object
    test_scenario::next_tx(&mut scenario, member_address1);
    {
      let board = test_scenario::take_shared(&scenario);
      let member1 = member::borrow_mut_member_by_email(&mut board, &member_email1);
      let ctx = test_scenario::ctx(&mut scenario);

      member_token::split_and_transfer_coin<LOY>(1700, member1, member_address2, ctx);
      member_token::split_and_transfer_coin<SUI>(100, member1, member_address2, ctx);

      test_scenario::return_shared<MemberBoard>(board);
    };

    // Expect output for owner remaining coin
    test_scenario::next_tx(&mut scenario, member_address1);
    {
      let board = test_scenario::take_shared(&scenario);
      let member1 = member::borrow_mut_member_by_email(&mut board, &member_email1);

      let coin_loy: &Coin<LOY> = member_token::borrow_coin_by_coin_type<LOY>(member1, metadata_loy);
      let coin_sui: &Coin<SUI> = member_token::borrow_coin_by_coin_type<SUI>(member1, metadata_sui);

      assert!(coin::value(coin_loy) == 1300, 0);
      assert!(coin::value(coin_sui) == 400, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    // Expect member_address2 receive coin correctly
    test_scenario::next_tx(&mut scenario, member_address2);
    {
      let board = test_scenario::take_shared(&scenario);
      let member2 = member::borrow_mut_member_by_email(&mut board, &member_email2);


      let coin_loy = test_scenario::take_from_address<Coin<LOY>>(&scenario, member_address2);
      let coin_sui = test_scenario::take_from_address<Coin<SUI>>(&scenario, member_address2);

      assert!(coin::value(&coin_loy) == 1700, 0);
      assert!(coin::value(&coin_sui) == 100, 0);

      let ctx = test_scenario::ctx(&mut scenario);
      member_token::receive_coin<LOY>(member2, coin_loy, ctx);
      member_token::receive_coin<SUI>(member2, coin_sui, ctx);
      test_scenario::return_shared<MemberBoard>(board);
    };

     // Expect coin in the member account
    test_scenario::next_tx(&mut scenario, member_address2);
    {
      let board = test_scenario::take_shared(&scenario);
      let member2 = member::borrow_mut_member_by_email(&mut board, &member_email2);

      let coin_loy: &Coin<LOY> = member_token::borrow_coin_by_coin_type<LOY>(member2, metadata_loy);
      let coin_sui: &Coin<SUI> = member_token::borrow_coin_by_coin_type<SUI>(member2, metadata_sui);

      assert!(coin::value(coin_loy) == 1700, 0);
      assert!(coin::value(coin_sui) == 100, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);
  }
}