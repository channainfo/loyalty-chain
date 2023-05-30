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

      lyt::mint(&mut treasury_cap, owner_amount_minted, address, ctx);
      lyt::mint(&mut treasury_cap, receiver_amount_mited, receiver, ctx);

      test_scenario::return_to_sender(&scenario, treasury_cap);
    };

    // test amount minted
    test_scenario::next_tx(&mut scenario, owner);
    {
      let owner_coin = test_scenario::take_from_address<Coin<LYT>>(&mut scenario, owner);
      let recipient_coin = test_scenario::take_from_address<Coin<LYT>>(&mut scenario, receiver);

      assert!(coin::value(&owner_coin) == owner_amount_minted, 0);
      assert!(coin::value(&recipient_coin) == receiver_amount_mited, 0);

      test_scenario::return_to_address<Coin<LYT>>(owner, owner_coin);
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
      let owner_coin = test_scenario::take_from_sender<Coin<LYT>>(&scenario);

      assert!(coin::value(&owner_coin) == (owner_amount_minted - amount_burned), 0);
      test_scenario::return_to_sender<Coin<LYT>>(&scenario, owner_coin);
    };

    test_scenario::end(scenario);
  }
}