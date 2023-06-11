module loyaltychain::memberable {
  use sui::tx_context::{Self, TxContext};
  use sui::transfer::{Self};
  use sui::object::{Self, UID, ID };
  use sui::dynamic_object_field;
  use sui::event;
  use sui::coin::{Self, Coin, CoinMetadata};

  use std::string::{String};
  use loyaltychain::util::{Self};

  struct MemberBoard has key, store {
    id: UID,
    members_count: u128,
  }

  struct Member has key, store {
    id: UID,
    nick_name: String,
    code: vector<u8>,
    owner: address,
  }

  struct MemberReceivedCoinEvent has copy, drop {
    metadata_id: ID,
    member_id: ID,
    amount: u64,
    from_amount: u64,
    to_amount: u64,
    received_at: u64
  }

  struct MemberSentCoinEvent has copy, drop {
    metadata_id: ID,
    sender_id: ID,
    receiver_id: ID,
    amount: u64,
    sent_at: u64
  }

  struct MemberCreatedEvent has drop, copy {
    member_id: ID,
    code: vector<u8>,
    nick_name: String,
    owner: address,
    created_at: u64
  }

  public fun init_create_member_board(ctx: &mut TxContext) {
    let board = MemberBoard {
      id: object::new(ctx),
      members_count: 0u128
    };

    transfer::public_share_object(board);
  }

  public fun receive_coin<T>(member: &mut Member, coin: Coin<T>, metadata: &CoinMetadata<T>, ctx: &TxContext){

    let metadata_id = object::id(metadata);
    let member_id = object::id(member);
    let amount = coin::value(&coin);
    let received_at = tx_context::epoch(ctx);

    let from_amount = if(dynamic_object_field::exists_<ID>(&member.id, metadata_id)) {
      let existing_coin = dynamic_object_field::borrow_mut<ID, Coin<T>>(&mut member.id, metadata_id);
      coin::join(existing_coin, coin);
      coin::value(existing_coin)
    }else {
      dynamic_object_field::add<ID, Coin<T>>(&mut member.id, metadata_id, coin);
      0u64
    };

    let to_amount = from_amount + amount;
    let received_coin_event = MemberReceivedCoinEvent {
      metadata_id,
      member_id,
      amount,
      from_amount,
      to_amount,
      received_at
    };

    event::emit(received_coin_event);
  }

  public fun split_coin<T>(value: u64, member: &mut Member, metadata: &CoinMetadata<T>, ctx: &mut TxContext): Coin<T>{
    let metadata_id = object::id(metadata);
    let coin_exist = dynamic_object_field::exists_<ID>(&member.id, metadata_id);
    assert!(coin_exist, 0);

    let whole_coin = dynamic_object_field::borrow_mut(&mut member.id, metadata_id);
    let split_coin = coin::split<T>(whole_coin, value, ctx);

    split_coin
  }

  public fun split_and_transfer_coin<T>(value: u64, sender: &mut Member, receiver: &mut Member, meta_data: &CoinMetadata<T>, ctx: &mut TxContext) {

    let split_coin = split_coin<T>(value, sender, meta_data, ctx);
    receive_coin<T>(receiver, split_coin, meta_data, ctx);

    let metadata_id = object::id(meta_data);
    let sender_id = object::id(sender);
    let receiver_id = object::id(receiver);
    let sent_at = tx_context::epoch(ctx);

    let sent_event = MemberSentCoinEvent {
      metadata_id,
      sender_id,
      receiver_id,
      amount: value,
      sent_at
    };

    event::emit(sent_event);
  }

  public fun register_member(nick_name: String, email: String, board: &mut MemberBoard, ctx: &mut TxContext): bool {
    let code: vector<u8> = util::hash_string(&email);
    let created_at = tx_context::epoch(ctx);
    let owner = tx_context::sender(ctx);

    if(dynamic_object_field::exists_<vector<u8>>(&board.id, code)) {
      return false
    };

    let member = Member {
      id: object::new(ctx),
      nick_name,
      code,
      owner
    };

    let member_id = object::id(&member);
    dynamic_object_field::add<vector<u8>, Member>(&mut board.id, code, member);

    board.members_count = board.members_count + 1 ;

    let member_created_event = MemberCreatedEvent{
      member_id,
      nick_name,
      code,
      owner,
      created_at,
    };

    event::emit(member_created_event);
    true
  }

  // helper method
  public fun members_count(board: &MemberBoard): u128 {
    board.members_count
  }

  public fun member_code(member: &Member): vector<u8> {
    member.code
  }

  public fun member_owner(member: &Member): address {
    member.owner
  }

  public fun member_nick_name(member: &Member): String {
    member.nick_name
  }

  public fun borrow_member_by_email(board: &MemberBoard, email: &String): &Member {
    let code = util::hash_string(email);

    dynamic_object_field::borrow<vector<u8>, Member>(&board.id, code)
  }
}