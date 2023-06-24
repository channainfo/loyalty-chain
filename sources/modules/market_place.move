module loyaltychain::market_place {
  use sui::object::{Self, UID, ID};
  use sui::tx_context::{Self, TxContext};
  use sui::transfer;
  use sui::dynamic_object_field;
  use sui::coin::{Self, Coin};

  use std::type_name;

  struct MarketPlaceBoard has key, store {
    id: UID,
  }

  struct MarketPlace<phantom Token> has key, store {
    id: UID,
    items_count: u64,
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
    let type = type_name::get<Token>();
    if(dynamic_object_field::exists_(&board.id, type)){
      return false
    };

    let market_place = MarketPlace<Token> {
      id: object::new(ctx),
      items_count: 064,
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

    transfer::transfer(item, sender);
    transfer::public_transfer(value, owner);
  }

}