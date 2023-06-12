#[test_only]
module loyaltychain::memberable_test {

  #[test]
  public fun test_init_create_member_board(){
    use loyaltychain::memberable::{Self, MemberBoard};
    use sui::test_scenario;

    let owner = @0001;
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      memberable::init_create_member_board(ctx);
    };

    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);

      assert!(memberable::members_count(&board) == 0, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_register_member(){
    use sui::test_scenario;
    use sui::address;

    use loyaltychain::memberable::{Self, MemberBoard};

    use std::string::{Self, String};

    let owner = @0001;
    let email: String = string::utf8(b"admin@loyaltychain.org");
    let nick_name: String = string::utf8(b"Scoth");

    let scenario = test_scenario::begin(owner);

    // setup member_board
    {
      let ctx = test_scenario::ctx(&mut scenario);
      memberable::init_create_member_board(ctx);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = memberable::register_member(nick_name, email, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Expected output
    let effects = test_scenario::next_tx(&mut scenario, owner);
    {
      // let ctx = test_scenario::ctx(&mut scenario);

      let board = test_scenario::take_shared(&scenario);

      assert!(memberable::members_count(&board) == 1, 0);

      let member = memberable::borrow_member_by_email(&board, &email);

      let expected_code = address::to_bytes(@0xe5a73b66c2a07822c54b4b46241e07c04a7b7926029ae14ab93a915f4b38a087);
      assert!(memberable::member_nick_name(member) == nick_name, 0);
      assert!(memberable::member_code(member) == expected_code, 0);
      assert!(memberable::member_owner(member)== owner, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    assert!(test_scenario::num_user_events(&effects) == 1, 0);

    // Try to register the same member
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      // it should failed
      let result = memberable::register_member(nick_name, email, &mut board, ctx);
      assert!(result == false, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);

  }

  #[test]
  public fun test_receive_coin(){
    use sui::test_scenario;
    use sui::coin::{Self, Coin};
    use sui::sui::{SUI};
    use sui::object;
    use loyaltychain::loy::{LOY};
    use loyaltychain::memberable::{Self, MemberBoard};
    use std::string::{Self, String};

    let owner = @0001;
    let email: String = string::utf8(b"admin@loyaltychain.org");
    let nick_name: String = string::utf8(b"Scoth");

    let scenario = test_scenario::begin(owner);

    // setup member_board
    {
      let ctx = test_scenario::ctx(&mut scenario);
      memberable::init_create_member_board(ctx);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = memberable::register_member(nick_name, email, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Execute the call
    test_scenario::next_tx(&mut scenario, owner);
    let (metadata_loy, metadata_sui) = {

      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let ctx = test_scenario::ctx(&mut scenario);
      let amount_coin1 = coin::mint_for_testing<LOY>(1000u64, ctx);
      let amount_coin2 = coin::mint_for_testing<LOY>(2000u64, ctx);

      let amount_coin3 = coin::mint_for_testing<SUI>(500u64, ctx);

      // CoinMetadata#id
      let metadata_loy = object::id(&amount_coin1);
      let metadata_sui = object::id(&amount_coin3);

      memberable::receive_coin<LOY>(member, amount_coin1, metadata_loy, ctx);
      memberable::receive_coin<LOY>(member, amount_coin2, metadata_loy, ctx);
      memberable::receive_coin<SUI>(member, amount_coin3, metadata_sui, ctx);

      test_scenario::return_shared<MemberBoard>(board);
      (metadata_loy, metadata_sui)
    };

    // Expect the output
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let coin_loy: &Coin<LOY> = memberable::borrow_coin_by_metadata_id<LOY>(member, metadata_loy);
      let coin_sui: &Coin<SUI> = memberable::borrow_coin_by_metadata_id<SUI>(member, metadata_sui);

      assert!(coin::value(coin_loy) == 3000, 0);
      assert!(coin::value(coin_sui) == 500, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };
    test_scenario::end(scenario);
  }

  #[test]
  public fun test_split_coin(){
    use sui::test_scenario;
    use sui::coin::{Self, Coin};
    use sui::sui::{SUI};
    use sui::object;
    use loyaltychain::loy::{LOY};
    use loyaltychain::memberable::{Self, MemberBoard};
    use std::string::{Self, String};

    let owner = @0001;
    let email: String = string::utf8(b"admin@loyaltychain.org");
    let nick_name: String = string::utf8(b"Scoth");

    let scenario = test_scenario::begin(owner);

    // setup member_board
    {
      let ctx = test_scenario::ctx(&mut scenario);
      memberable::init_create_member_board(ctx);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = memberable::register_member(nick_name, email, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Execution call
    test_scenario::next_tx(&mut scenario, owner);
    let (metadata_loy, metadata_sui) = {

      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let ctx = test_scenario::ctx(&mut scenario);
      let amount_coin1 = coin::mint_for_testing<LOY>(1000u64, ctx);
      let amount_coin2 = coin::mint_for_testing<LOY>(2000u64, ctx);

      let amount_coin3 = coin::mint_for_testing<SUI>(500u64, ctx);

      // CoinMetadata#id
      let metadata_loy = object::id(&amount_coin1);
      let metadata_sui = object::id(&amount_coin3);

      memberable::receive_coin<LOY>(member, amount_coin1, metadata_loy, ctx);
      memberable::receive_coin<LOY>(member, amount_coin2, metadata_loy, ctx);
      memberable::receive_coin<SUI>(member, amount_coin3, metadata_sui, ctx);

      test_scenario::return_shared<MemberBoard>(board);
      (metadata_loy, metadata_sui)
    };

    // Expect output for the return coin object
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);
      let ctx = test_scenario::ctx(&mut scenario);

      let coin_loy: Coin<LOY> = memberable::split_coin<LOY>(1500, member, metadata_loy, ctx);
      let coin_sui: Coin<SUI> = memberable::split_coin<SUI>(300, member, metadata_sui, ctx);

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
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let coin_loy: &Coin<LOY> = memberable::borrow_coin_by_metadata_id<LOY>(member, metadata_loy);
      let coin_sui: &Coin<SUI> = memberable::borrow_coin_by_metadata_id<SUI>(member, metadata_sui);

      assert!(coin::value(coin_loy) == 1500, 0);
      assert!(coin::value(coin_sui) == 200, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);
  }
}