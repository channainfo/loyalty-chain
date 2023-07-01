#[test_only]
module loyaltychain::member_test {

  #[test]
  public fun test_init_create_member_board(){
    use loyaltychain::member::{Self, MemberBoard};
    use sui::test_scenario;

    let owner = @0001;
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      member::init_create_member_board(ctx);
    };

    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);

      assert!(member::members_count(&board) == 0, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_register_member(){
    use sui::test_scenario;
    use sui::address;

    use loyaltychain::member::{Self, MemberBoard};

    use std::string::{Self, String};

    let owner = @0001;
    let email: String = string::utf8(b"admin@loyaltychain.org");
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

    // Expected output
    let effects = test_scenario::next_tx(&mut scenario, owner);
    {
      // let ctx = test_scenario::ctx(&mut scenario);

      let board = test_scenario::take_shared(&scenario);

      assert!(member::members_count(&board) == 1, 0);

      let member = member::borrow_member_by_email(&board, &email);

      let expected_code = address::to_bytes(@0xe5a73b66c2a07822c54b4b46241e07c04a7b7926029ae14ab93a915f4b38a087);
      assert!(member::member_nick_name(member) == nick_name, 0);
      assert!(member::member_code(member) == expected_code, 0);
      assert!(member::member_owner(member)== owner, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    assert!(test_scenario::num_user_events(&effects) == 1, 0);

    // Try to register the same member
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      // it should failed
      let result = member::register_member(nick_name, email, owner, &mut board, ctx);
      assert!(result == false, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);

  }
}