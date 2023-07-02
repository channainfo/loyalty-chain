module loychain::market_place {
  use sui::object::{Self, UID, ID};
  use sui::tx_context::{Self, TxContext};
  use sui::transfer;
  use sui::dynamic_object_field;
  use sui::coin::{Self, Coin};

  use loychain::util;

  struct MarketPlaceBoard has key, store {
    id: UID,
  }

  struct MarketPlace<phantom Token> has key, store {
    id: UID,
    items_count: u64,
  }

  struct ItemForTest has key, store {
    id: UID,
    value: u64,

  }

  struct Listing<T, phantom Token> has key, store {
    id: UID,
    value: u64,
    owner: address,
    item: T,
  }

  public fun init_create_market_place_board(ctx: &mut TxContext){
    let market_place_board = MarketPlaceBoard {
      id: object::new(ctx)
    };
    transfer::share_object(market_place_board);
  }

  public fun create_market_place<Token>(board: &mut MarketPlaceBoard, ctx: &mut TxContext): bool {
    let type = util::get_name_as_bytes<Token>();
    if(dynamic_object_field::exists_(&board.id, type)){
      return false
    };

    let market_place = MarketPlace<Token> {
      id: object::new(ctx),
      items_count: 0u64,
    };
    dynamic_object_field::add(&mut board.id, type, market_place);

    true
  }

  public fun create_listing<T: key + store, Token>(item: T, value: u64, market_place: &mut MarketPlace<Token>, ctx: &mut TxContext) {
    let item_id = object::id(&item);
    let owner = tx_context::sender(ctx);

    let listing =  Listing<T, Token>{
      id: object::new(ctx),
      value,
      owner,
      item
    };
    market_place.items_count = market_place.items_count + 1;
    dynamic_object_field::add(&mut market_place.id, item_id, listing);
  }

  public fun take_listing<T: key + store, Token>(item_id: ID, market_place: &mut MarketPlace<Token>, ctx: &mut TxContext): T{
    let listing = dynamic_object_field::borrow<ID, Listing<T, Token>>(&market_place.id, item_id);

    assert!(listing.owner == tx_context::sender(ctx), 0);

    let listing = dynamic_object_field::remove<ID, Listing<T, Token>>(&mut market_place.id, item_id);

    let Listing { id, value: _, owner: _, item } = listing;

    object::delete(id);
    market_place.items_count = market_place.items_count - 1;

    item
  }

  public fun withdraw_listing<T: key + store, Token>(item_id: ID, market_place: &mut MarketPlace<Token>, ctx: &mut TxContext){
    let item = take_listing<T, Token>(item_id, market_place, ctx);
    let owner = tx_context::sender(ctx);

    transfer::public_transfer(item, owner);
  }

  public fun buy_item<T: key+store, Token>(value: Coin<Token>, item_id: ID, market_place: &mut MarketPlace<Token>, ctx: &mut TxContext){
    let listing = dynamic_object_field::borrow<ID, Listing<T, Token>>(&market_place.id, item_id);
    let coin_value = coin::value(&value);
    let sender = tx_context::sender(ctx);

    assert!(listing.value == coin_value, 0);

    let listing = dynamic_object_field::remove<ID, Listing<T, Token>>(&mut market_place.id, item_id);
    let Listing { id, value: _, owner , item } = listing;

    object::delete(id);
    market_place.items_count = market_place.items_count - 1;

    transfer::public_transfer(item, sender);
    transfer::public_transfer(value, owner);

  }

  public fun market_place_items_count<Token>(market_place: &MarketPlace<Token>): u64 {
    market_place.items_count
  }

  public fun borrow_mut_market_place_t_token<Token>(board: &mut MarketPlaceBoard): &mut MarketPlace<Token> {
    let type = util::get_name_as_bytes<Token>();

    dynamic_object_field::borrow_mut<vector<u8>, MarketPlace<Token>>(&mut board.id, type)
  }

  #[test_only]
  public fun create_and_transfer_item_for_test(ctx: &mut TxContext) {
    let item = ItemForTest {
      id: object::new(ctx),
      value: 3000
    };

    let sender = tx_context::sender(ctx);
    transfer::public_transfer(item, sender);
  }

  #[test_only]
  public fun item_value_for_test(item: &ItemForTest): u64 {
    item.value
  }
}