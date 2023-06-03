module loyaltychain::lyt {
  use sui::tx_context::{Self, TxContext};
  use sui::coin::{Self, Coin, TreasuryCap};
  use sui::transfer;

  use std::option::{Self, Option};
  use sui::url::{Url};

  struct LYT has drop {}

  fun init(withness: LYT, ctx: &mut TxContext) {
    create_coin(withness, ctx);
  }

  // icon can be updated later with update_icon_url
  public fun create_coin(withness: LYT, ctx: &mut TxContext){
    let decimal = 9;
    let symbol = b"LYT";
    let name = b"LYT";
    let description = b"";
    let icon_url: Option<Url> = option::none();
    let (treasury_cap, meta_data) = coin::create_currency<LYT>(withness, decimal, symbol, name, description, icon_url, ctx);

    transfer::public_freeze_object(meta_data);
    transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
  }

  public fun mint(treasury_cap: &mut TreasuryCap<LYT>, amount: u64, recipient: address, ctx: &mut TxContext) {
    coin::mint_and_transfer(treasury_cap, amount, recipient, ctx);
  }

  public fun mint_and_merge(treasury_cap: &mut TreasuryCap<LYT>, amount: u64, coin: &mut Coin<LYT>, ctx: &mut TxContext){
    let minted_coin: Coin<LYT> = coin::mint<LYT>(treasury_cap, amount, ctx);
    coin::join<LYT>(coin, minted_coin);
  }

  public fun mint_and_join(treasury_cap: &mut TreasuryCap<LYT>, amount: u64, coin: &mut Coin<LYT>, ctx: &mut TxContext){
    mint_and_merge(treasury_cap, amount, coin, ctx);
  }

  public fun burn(treasury_cap: &mut TreasuryCap<LYT>, coin: Coin<LYT>){
    coin::burn(treasury_cap, coin);
  }

  #[test]
  public fun test_init(){
    use sui::test_scenario;
    use loyaltychain::lyt::{Self, LYT};
    use sui::coin::{Self, TreasuryCap, Coin};

    let owner = @0x0001;
    let owner_amount_minted = 5_000u64;

    let receiver = @0x0002;
    let receiver_amount_mited = 15_000u64;

    let amount_burned = 3_500u64;

    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      init(LYT{}, ctx);
    };

    // coin minted
    test_scenario::next_tx(&mut scenario, owner);
    {
      let address = test_scenario::sender(&scenario);
      let treasury_cap = test_scenario::take_from_sender<TreasuryCap<LYT>>(& scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      // mint amount: owner_amount_minted 2 times and transfer to owner
      lyt::mint(&mut treasury_cap, owner_amount_minted, address, ctx);
      lyt::mint(&mut treasury_cap, owner_amount_minted, address, ctx);

      // mint amount: receiver_amount_mited and transfer to receiver
      lyt::mint(&mut treasury_cap, receiver_amount_mited, receiver, ctx);

      test_scenario::return_to_sender(&scenario, treasury_cap);
    };

    // test amount minted
    test_scenario::next_tx(&mut scenario, owner);
    {
      let owner_coin1 = test_scenario::take_from_address<Coin<LYT>>(&mut scenario, owner);
      let owner_coin2 = test_scenario::take_from_address<Coin<LYT>>(&mut scenario, owner);
      let recipient_coin = test_scenario::take_from_address<Coin<LYT>>(&mut scenario, receiver);

      // owner has 2 coins objects of value owner_amount_minted each
      assert!(coin::value(&owner_coin1) == owner_amount_minted, 0);
      assert!(coin::value(&owner_coin2) == owner_amount_minted, 0);

      // receiver has 1 coin object of value receiver_amount_mited
      assert!(coin::value(&recipient_coin) == receiver_amount_mited, 0);

      test_scenario::return_to_address<Coin<LYT>>(owner, owner_coin1);
      test_scenario::return_to_address<Coin<LYT>>(owner, owner_coin2);
      test_scenario::return_to_address<Coin<LYT>>(receiver, recipient_coin);
    };

    // burn coin
    test_scenario::next_tx(&mut scenario, owner);
    {
      let treasury_cap = test_scenario::take_from_sender<TreasuryCap<LYT>>(&scenario);
      let owner_coin = test_scenario::take_from_sender<Coin<LYT>>(& scenario);
      let owner_balance = coin::balance_mut<LYT>(&mut owner_coin);

      let ctx = test_scenario::ctx(&mut scenario);
      let portion = coin::take<LYT>(owner_balance, amount_burned, ctx);

      loyaltychain::lyt::burn(&mut treasury_cap, portion);

      test_scenario::return_to_sender<Coin<LYT>>(&scenario, owner_coin);
      test_scenario::return_to_sender<TreasuryCap<LYT>>(&scenario, treasury_cap);
    };

    // test amount burn
    test_scenario::next_tx(&mut scenario, owner);
    {
      let owner_coin1 = test_scenario::take_from_sender<Coin<LYT>>(&scenario);
      let owner_coin2 = test_scenario::take_from_sender<Coin<LYT>>(&scenario);

      assert!(coin::value(&owner_coin1) == (owner_amount_minted - amount_burned), 0);
      assert!(coin::value(&owner_coin2) == (owner_amount_minted), 0);

      test_scenario::return_to_sender<Coin<LYT>>(&scenario, owner_coin1);
      test_scenario::return_to_sender<Coin<LYT>>(&scenario, owner_coin2);
    };

    // test join coin for owner_coin
    test_scenario::next_tx(&mut scenario, owner);
    {
      let owner_coin1 = test_scenario::take_from_sender<Coin<LYT>>(&scenario);
      let owner_coin2 = test_scenario::take_from_sender<Coin<LYT>>(&scenario);

      coin::join(&mut owner_coin1, owner_coin2);

      let total_coin = owner_amount_minted + (owner_amount_minted - amount_burned) ;
      assert!(coin::value(&owner_coin1) == total_coin, 0);
      test_scenario::return_to_sender<Coin<LYT>>(&scenario, owner_coin1);
    };

    // test mint_and_merge coin for owner_coin
    test_scenario::next_tx(&mut scenario, owner);
    {
      let owner_coin = test_scenario::take_from_sender<Coin<LYT>>(&scenario);
      let treasury_cap = test_scenario::take_from_sender<TreasuryCap<LYT>>(&scenario);

      let ctx = test_scenario::ctx(&mut scenario);
      lyt::mint_and_merge(&mut treasury_cap, owner_amount_minted, &mut owner_coin, ctx);

      let total_coin = owner_amount_minted + owner_amount_minted + (owner_amount_minted - amount_burned) ;
      assert!(coin::value(&owner_coin) == total_coin, 0);
      test_scenario::return_to_sender<Coin<LYT>>(&scenario, owner_coin);
      test_scenario::return_to_sender<TreasuryCap<LYT>>(&scenario, treasury_cap);
    };

    test_scenario::end(scenario);
  }
}