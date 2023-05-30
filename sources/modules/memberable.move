module loyaltychain::memberable {
  use sui::tx_context::{Self, TxContext};
  use sui::transfer::{Self};
  use sui::object::{Self, UID, ID };
  use sui::dynamic_object_field;
  use sui::event;

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