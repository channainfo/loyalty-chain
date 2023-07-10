module loychain::member_token {
  use sui::tx_context::{Self, TxContext};
  use sui::transfer::{Self};
  use sui::object::{Self, ID};
  use sui::dynamic_object_field;
  use sui::event;
  use sui::coin::{Self, Coin};
  use loychain::util;
  use loychain::member::{Self, Member};

  const ERROR_NOT_OWNER: u64 = 0u64;
  const ERROR_COIN_NOT_EXIST: u64 = 1u64;

  struct MemberReceivedCoinEvent has copy, drop {
    coin_type: vector<u8>,
    member_id: ID,
    amount: u64,
    from_amount: u64,
    to_amount: u64,
    received_at: u64
  }

  struct MemberSentCoinEvent has copy, drop {
    coin_type: vector<u8>,
    sender_id: ID,
    receiver_address: address,
    amount: u64,
    sent_at: u64
  }

  public fun receive_coin<T>(member: &mut Member, coin: Coin<T>, ctx: &TxContext){

    let member_id = object::id(member);
    let amount = coin::value(&coin);
    let received_at = tx_context::epoch(ctx);
    let coin_type = util::get_name_as_bytes<T>();
    let member_uid = member::borrow_mut_id(member);

    let from_amount = if(dynamic_object_field::exists_(member_uid, coin_type)) {
      let existing_coin = dynamic_object_field::borrow_mut(member_uid, coin_type);
      coin::join(existing_coin, coin);
      coin::value(existing_coin)
    }else {
      dynamic_object_field::add(member_uid, coin_type, coin);
      0u64
    };

    let to_amount = from_amount + amount;
    let received_coin_event = MemberReceivedCoinEvent {
      coin_type,
      member_id,
      amount,
      from_amount,
      to_amount,
      received_at
    };

    event::emit(received_coin_event);
  }

  public fun split_coin<T>(value: u64, member: &mut Member, sender: address, ctx: &mut TxContext): Coin<T>{
    assert!(member::member_owner(member) == sender, ERROR_NOT_OWNER);
    let member_uid = member::borrow_mut_id(member);

    let coin_type = util::get_name_as_bytes<T>();
    let coin_exist = dynamic_object_field::exists_(member_uid, coin_type);
    assert!(coin_exist, ERROR_COIN_NOT_EXIST);

    let whole_coin = dynamic_object_field::borrow_mut(member_uid, coin_type);
    let split_coin = coin::split<T>(whole_coin, value, ctx);

    split_coin
  }

  // transfer to an address and then allow member to claim
  public fun split_and_transfer_coin<T>(
    value: u64,
    member: &mut Member,
    receiver_address: address,
    ctx: &mut TxContext) {

    let sender = tx_context::sender(ctx);
    let splitted_coin = split_coin<T>(value, member, sender, ctx);

    let member_id = object::id(member);
    let sent_at = tx_context::epoch(ctx);
    transfer::public_transfer(splitted_coin, receiver_address);
    let coin_type = util::get_name_as_bytes<T>();

    let sent_event = MemberSentCoinEvent {
      coin_type,
      sender_id: member_id,
      receiver_address,
      amount: value,
      sent_at
    };

    event::emit(sent_event);
  }

  public fun borrow_coin_by_coin_type<T>(member: &Member, coin_type: vector<u8>): &Coin<T> {
    let member_uid = member::borrow_id(member);
    let existing_coin = dynamic_object_field::borrow(member_uid, coin_type);
    existing_coin
  }

  public fun borrow_mut_coin_by_coin_type<T>(member: &mut Member, coin_type: vector<u8>): &mut Coin<T> {
    let member_uid = member::borrow_mut_id(member);

    let existing_coin = dynamic_object_field::borrow_mut(member_uid, coin_type);
    existing_coin
  }
}