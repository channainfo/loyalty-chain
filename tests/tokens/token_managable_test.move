#[test_only]
module loychain::token_managable_test {

  #[test]
  public fun test_create_coin(){
    use sui::test_scenario;
    use sui::test_utils;
    use sui::coin::{TreasuryCap};

    use loychain::loy::{LOY};
    use loychain::token_managable;

    let owner = @0x0001;

    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      let withness = test_utils::create_one_time_witness<LOY>();
      token_managable::create_coin(withness, ctx);
    };
    // Expect owner to receive the treasury_cap
    test_scenario::next_tx(&mut scenario, owner);
    {
      let has_treasury = test_scenario::has_most_recent_for_address<TreasuryCap<LOY>>(owner);
      assert!(has_treasury == true, 0);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_mint(){
    use sui::test_scenario;
    use sui::test_utils;
    use sui::coin::{Self, TreasuryCap};

    use loychain::loy::{LOY};
    use loychain::token_managable;

    let owner = @0x0001;
    let owner_amount_minted = 5_000u64;

    // Setup the witness
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      let withness = test_utils::create_one_time_witness<LOY>();
      token_managable::create_coin(withness, ctx);
    };

    // Exec mint coin
    test_scenario::next_tx(&mut scenario, owner);
    {
      let treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(& scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      // mint amount: owner_amount_minted 2 times and transfer to owner
      let minted_coin = token_managable::mint(&mut treasury_cap, owner_amount_minted, ctx);
      assert!(coin::value(&minted_coin) == owner_amount_minted, 0);
      test_utils::destroy(minted_coin);
      test_scenario::return_to_sender(&scenario, treasury_cap);
    };
    test_scenario::end(scenario);
  }

  #[test]
  public fun test_mint_and_transfer(){
    use sui::test_scenario;
    use sui::test_utils;
    use sui::coin::{Self, TreasuryCap, Coin};

    use loychain::loy::{LOY};
    use loychain::token_managable;

    let owner = @0x0001;
    let owner_amount_minted = 5_000u64;

    let receiver = @0x0002;
    let receiver_amount_mited = 15_000u64;

    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      let withness = test_utils::create_one_time_witness<LOY>();
      token_managable::create_coin(withness, ctx);
    };

    // Exec mint_and_transfer
    test_scenario::next_tx(&mut scenario, owner);
    {
      let address = test_scenario::sender(&scenario);
      let treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(& scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      // mint amount: owner_amount_minted 2 times and transfer to owner
      token_managable::mint_and_transfer(&mut treasury_cap, owner_amount_minted, address, ctx);
      token_managable::mint_and_transfer(&mut treasury_cap, owner_amount_minted, address, ctx);

      // mint amount: receiver_amount_mited and transfer to receiver
      token_managable::mint_and_transfer(&mut treasury_cap, receiver_amount_mited, receiver, ctx);

      test_scenario::return_to_sender(&scenario, treasury_cap);
    };

    // test amount minted
    test_scenario::next_tx(&mut scenario, owner);
    {
      let owner_coin1 = test_scenario::take_from_address<Coin<LOY>>(&mut scenario, owner);
      let owner_coin2 = test_scenario::take_from_address<Coin<LOY>>(&mut scenario, owner);
      let recipient_coin = test_scenario::take_from_address<Coin<LOY>>(&mut scenario, receiver);

      // owner has 2 coins objects of value owner_amount_minted each
      assert!(coin::value(&owner_coin1) == owner_amount_minted, 0);
      assert!(coin::value(&owner_coin2) == owner_amount_minted, 0);

      // receiver has 1 coin object of value receiver_amount_mited
      assert!(coin::value(&recipient_coin) == receiver_amount_mited, 0);

      test_scenario::return_to_address<Coin<LOY>>(owner, owner_coin1);
      test_scenario::return_to_address<Coin<LOY>>(owner, owner_coin2);
      test_scenario::return_to_address<Coin<LOY>>(receiver, recipient_coin);
    };
    test_scenario::end(scenario);
  }

  #[test]
  public fun test_mint_and_merge(){
    use sui::test_scenario;
    use sui::test_utils;
    use sui::coin::{Self, TreasuryCap, Coin};

    use loychain::loy::{LOY};
    use loychain::token_managable;

    let owner = @0x0001;
    let owner_amount_minted = 5_000u64;

    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      let withness = test_utils::create_one_time_witness<LOY>();
      token_managable::create_coin(withness, ctx);
    };

    // Mint
    test_scenario::next_tx(&mut scenario, owner);
    {
      let address = test_scenario::sender(&scenario);
      let treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(& scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      // mint amount: owner_amount_minted 2 times and transfer to owner
      token_managable::mint_and_transfer(&mut treasury_cap, owner_amount_minted, address, ctx);
      test_scenario::return_to_sender(&scenario, treasury_cap);
    };


    // test mint_and_merge coin for owner_coin
    test_scenario::next_tx(&mut scenario, owner);
    {
      let owner_coin = test_scenario::take_from_sender<Coin<LOY>>(&scenario);
      let treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&scenario);

      let ctx = test_scenario::ctx(&mut scenario);
      token_managable::mint_and_merge(&mut treasury_cap, owner_amount_minted, &mut owner_coin, ctx);

      let total_coin = owner_amount_minted + owner_amount_minted;
      assert!(coin::value(&owner_coin) == total_coin, 0);
  
      test_scenario::return_to_sender<Coin<LOY>>(&scenario, owner_coin);
      test_scenario::return_to_sender<TreasuryCap<LOY>>(&scenario, treasury_cap);
    };

    // Expect coin to have correct amount
    test_scenario::next_tx(&mut scenario, owner);
    {
      let owner_coin = test_scenario::take_from_sender<Coin<LOY>>(&scenario);
      let total_coin = owner_amount_minted + owner_amount_minted;
      assert!(coin::value(&owner_coin) == total_coin, 0);
      test_scenario::return_to_sender<Coin<LOY>>(&scenario, owner_coin);
    };

    test_scenario::end(scenario);
  }

}