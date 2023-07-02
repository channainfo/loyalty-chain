module loychain::order {
  use sui::tx_context::{Self, TxContext};
  use sui::object::{ID};
  use sui::event;

  use loychain::member::{Self, MemberBoard, Member};
  use loychain::partner::{Self,PartnerBoard, Partner};
  use loychain::partner_treasury;
  use loychain::member_nft;
  use loychain::member_token;
  use loychain::token_managable;
  use loychain::nft;
  use loychain::util;

  use std::string::{String};

  struct CompletedOrderEvent has copy, drop {
    order_id: String,
    token_earn: u64,
    owner: address,
    created_at: u64
  }

  public fun complete_order<Token>(
    order_id: String,
    nft_card_id: ID,
    member_email: String,
    member_board: &mut MemberBoard,
    partner_code: String,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext){

    let partner: &mut Partner = partner::borrow_mut_parter_by_code(partner_code, partner_board );
    assert!(partner_treasury::treasury_cap_exists<Token>(partner) == true, 0);

    let token_name = partner::partner_token_name(partner);
    let token_sym = util::get_name_as_string<Token>();

    let treasury_cap = partner_treasury::borrow_mut_treasury_cap<Token>(partner);
    assert!(token_name == token_sym, 0);

    let member: &mut Member = member::borrow_mut_member_by_email(member_board, &member_email);
    let nft_card = member_nft::borrow_mut_nft_card_by_id(member, nft_card_id);
    let value = nft::use_card(nft_card);
    let coin = token_managable::mint<Token>(treasury_cap, value, ctx);

    member_token::receive_coin(member, coin, ctx);

    let created_at = tx_context::epoch(ctx);
    let completed_order_event = CompletedOrderEvent {
      order_id,
      token_earn: value,
      owner: member::member_owner(member),
      created_at
    };

    event::emit(completed_order_event);
  }
}