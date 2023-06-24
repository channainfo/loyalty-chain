#[test_only]
module loyaltychain::market_place_test {

  #[test]
  public fun test_init_create_market_place_board(){
    use sui::test_scenario;

    use loyaltychain::market_place::{Self, MarketPlaceBoard};

    let owner = @0x0001;

    // invoke contract
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      market_place::init_create_market_place_board(ctx);
    };

    // verify output
    test_scenario::next_tx(&mut scenario, owner);
    {
      let exist = test_scenario::has_most_recent_shared<MarketPlaceBoard>();
      assert!(exist == true, 0)
    };

    test_scenario::end(scenario);

  }

  #[test]
  public fun test_create_market_place() {

    use sui::test_scenario;

    use loyaltychain::market_place::{Self, MarketPlaceBoard};
    use loyaltychain::loy::{LOY};

    let owner = @0x0001;

    // init board
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      market_place::init_create_market_place_board(ctx);
    };

    // create market place with a token should be sucessful
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = market_place::create_market_place<LOY>(&mut board, ctx);
      assert!(result == true, 0);
      test_scenario::return_shared(board);
    };

    // verify output
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let market = market_place::borrow_mut_market_place_t_token<LOY>(&mut board);
      assert!(market_place::market_place_items_count<LOY>(market) == 0, 0);

      test_scenario::return_shared(board);
    };

    // try to create the same market place token will failed
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = market_place::create_market_place<LOY>(&mut board, ctx);
      assert!(result == false, 0);
      test_scenario::return_shared(board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_create_listing() {

    use sui::test_scenario;
    use sui::object;

    use loyaltychain::market_place::{Self, MarketPlaceBoard, ItemForTest};
    use loyaltychain::loy::{LOY};

    let owner = @0x0001;

    // init board
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      market_place::init_create_market_place_board(ctx);
    };

    // create market place with a token should be sucessful
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = market_place::create_market_place<LOY>(&mut board, ctx);
      assert!(result == true, 0);
      test_scenario::return_shared(board);
    };

    // mock an item for item_owner for the next transaction
    let item_owner = @0x0002;
    test_scenario::next_tx(&mut scenario, item_owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      market_place::create_and_transfer_item_for_test(ctx);
    };

    // create listing from the item above
    test_scenario::next_tx(&mut scenario, item_owner);
    let item_id = {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let market = market_place::borrow_mut_market_place_t_token<LOY>(&mut board);
      let item = test_scenario::take_from_sender<ItemForTest>(&scenario);
      let item_id = object::id(&item);
      let ctx = test_scenario::ctx(&mut scenario);

      market_place::create_listing(item, 5000, market, ctx);
      test_scenario::return_shared(board);
      item_id
    };

    // expect market place to be changed by 1 item
    test_scenario::next_tx(&mut scenario, item_owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let market = market_place::borrow_mut_market_place_t_token<LOY>(&mut board);

      assert!(market_place::market_place_items_count(market) == 1, 0);
      test_scenario::return_shared(board);
    };

    // expect item to be store correctly
    test_scenario::next_tx(&mut scenario, item_owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let market = market_place::borrow_mut_market_place_t_token<LOY>(&mut board);
      let ctx = test_scenario::ctx(&mut scenario);

      let item = market_place::take_listing<ItemForTest, LOY>(item_id, market, ctx);

      assert!(market_place::item_value_for_test(&item) == 3000, 0);
      market_place::create_listing(item, 5000, market, ctx);
      test_scenario::return_shared(board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_take_listing() {

    use sui::test_scenario;
    use sui::object;

    use loyaltychain::market_place::{Self, MarketPlaceBoard, ItemForTest};
    use loyaltychain::loy::{LOY};

    let owner = @0x0001;

    // init board
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      market_place::init_create_market_place_board(ctx);
    };

    // create market place with a token should be sucessful
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = market_place::create_market_place<LOY>(&mut board, ctx);
      assert!(result == true, 0);
      test_scenario::return_shared(board);
    };

    // mock an item for item_owner for the next transaction
    let item_owner = @0x0002;
    test_scenario::next_tx(&mut scenario, item_owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      market_place::create_and_transfer_item_for_test(ctx);
    };

    // create listing from the item above
    test_scenario::next_tx(&mut scenario, item_owner);
    let item_id = {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let market = market_place::borrow_mut_market_place_t_token<LOY>(&mut board);
      let item = test_scenario::take_from_sender<ItemForTest>(&scenario);
      let item_id = object::id(&item);
      let ctx = test_scenario::ctx(&mut scenario);

      market_place::create_listing(item, 5000, market, ctx);
      test_scenario::return_shared(board);
      item_id
    };

    // expect market place to be changed by 1 item
    test_scenario::next_tx(&mut scenario, item_owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let market = market_place::borrow_mut_market_place_t_token<LOY>(&mut board);

      assert!(market_place::market_place_items_count(market) == 1, 0);
      test_scenario::return_shared(board);
    };

    // expect item to be store correctly
    test_scenario::next_tx(&mut scenario, item_owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let market = market_place::borrow_mut_market_place_t_token<LOY>(&mut board);
      let ctx = test_scenario::ctx(&mut scenario);

      let item = market_place::take_listing<ItemForTest, LOY>(item_id, market, ctx);

      assert!(market_place::item_value_for_test(&item) == 3000, 0);
      market_place::create_listing(item, 5000, market, ctx);
      test_scenario::return_shared(board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_withdraw_listing() {

    use sui::test_scenario;
    use sui::object;

    use loyaltychain::market_place::{Self, MarketPlaceBoard, ItemForTest};
    use loyaltychain::loy::{LOY};

    let owner = @0x0001;

    // init board
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      market_place::init_create_market_place_board(ctx);
    };

    // create market place with a token should be sucessful
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = market_place::create_market_place<LOY>(&mut board, ctx);
      assert!(result == true, 0);
      test_scenario::return_shared(board);
    };

    // mock an item for item_owner for the next transaction
    let item_owner = @0x0002;
    test_scenario::next_tx(&mut scenario, item_owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      market_place::create_and_transfer_item_for_test(ctx);
    };

    // create listing from the item above
    test_scenario::next_tx(&mut scenario, item_owner);
    let item_id = {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let market = market_place::borrow_mut_market_place_t_token<LOY>(&mut board);
      let item = test_scenario::take_from_sender<ItemForTest>(&scenario);
      let item_id = object::id(&item);
      let ctx = test_scenario::ctx(&mut scenario);

      market_place::create_listing(item, 5000, market, ctx);
      test_scenario::return_shared(board);
      item_id
    };

    // expect market place to be changed by 1 item
    test_scenario::next_tx(&mut scenario, item_owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let market = market_place::borrow_mut_market_place_t_token<LOY>(&mut board);
      let items_count = market_place::market_place_items_count(market);

      assert!( items_count == 1, 0);
      test_scenario::return_shared(board);
    };

    // expect item to be store correctly
    test_scenario::next_tx(&mut scenario, item_owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let market = market_place::borrow_mut_market_place_t_token<LOY>(&mut board);
      let ctx = test_scenario::ctx(&mut scenario);

      let item = market_place::take_listing<ItemForTest, LOY>(item_id, market, ctx);

      assert!(market_place::item_value_for_test(&item) == 3000, 0);
      market_place::create_listing(item, 5000, market, ctx);
      test_scenario::return_shared(board);
    };
    test_scenario::end(scenario);
  }

  #[test]
  public fun test_buy_item(){
    use sui::test_scenario;
    use sui::object;
    use sui::coin::{Self, Coin};

    use loyaltychain::market_place::{Self, MarketPlaceBoard, ItemForTest};
    use loyaltychain::loy::{LOY};

    let owner = @0x0001;

    // init board
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      market_place::init_create_market_place_board(ctx);
    };

    // create market place with a token should be sucessful
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = market_place::create_market_place<LOY>(&mut board, ctx);
      assert!(result == true, 0);
      test_scenario::return_shared(board);
    };

    // mock an item for item_owner for the next transaction
    let item_owner = @0x0002;
    test_scenario::next_tx(&mut scenario, item_owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      market_place::create_and_transfer_item_for_test(ctx);
    };

    // create listing from the item above
    test_scenario::next_tx(&mut scenario, item_owner);
    let item_price = 5000;
    let item_id = {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let market = market_place::borrow_mut_market_place_t_token<LOY>(&mut board);
      let item = test_scenario::take_from_sender<ItemForTest>(&scenario);
      let item_id = object::id(&item);
      let ctx = test_scenario::ctx(&mut scenario);

      market_place::create_listing(item, item_price, market, ctx);
      test_scenario::return_shared(board);
      item_id
    };

    let buyer = @0x0003;
    test_scenario::next_tx(&mut scenario, buyer);
    let items_count = {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let market = market_place::borrow_mut_market_place_t_token<LOY>(&mut board);
      let items_count = market_place::market_place_items_count(market);
      let ctx = test_scenario::ctx(&mut scenario);
      let loy_coin = coin::mint_for_testing<LOY>(item_price, ctx);

      market_place::buy_item<ItemForTest, LOY>(loy_coin, item_id, market, ctx);
      test_scenario::return_shared(board);
      items_count
    };

    // expect the buyer to receive the item
    test_scenario::next_tx(&mut scenario, buyer);
    {
      let item = test_scenario::take_from_sender<ItemForTest>(&scenario);
      assert!(market_place::item_value_for_test(&item) == 3000, 0);
      test_scenario::return_to_sender(&scenario, item);
    };

    // expect the item_owner receive the coin
    test_scenario::next_tx(&mut scenario, item_owner);
    {
      let loy_coin = test_scenario::take_from_sender<Coin<LOY>>(&scenario);
      assert!(coin::value(&loy_coin) == item_price, 0);
      test_scenario::return_to_sender(&scenario, loy_coin);
    };

    // expect market place item changed by -1
    test_scenario::next_tx(&mut scenario, item_owner);
    {
      let board = test_scenario::take_shared<MarketPlaceBoard>(&scenario);
      let market = market_place::borrow_mut_market_place_t_token<LOY>(&mut board);
      assert!(market_place::market_place_items_count(market) == items_count - 1, 0);
      test_scenario::return_shared(board);
    };

    test_scenario::end(scenario);
  }
}