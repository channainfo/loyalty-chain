module loychain::partner_order {
  use sui::tx_context::{Self, TxContext};
  use sui::object::{ID};
  use sui::event;

  use loychain::member::{Self, MemberBoard, Member};
  use loychain::partner::{Self,PartnerBoard, Partner};
  use loychain::partner_treasury;
  use loychain::partner_token;
  use loychain::member_nft;
  use loychain::member_token;
  use loychain::token_managable;
  use loychain::nft;
  use loychain::util;

  use std::string::{String};

  const ERROR_NOT_PARTNER_ADDRESS: u64 = 1;
  const ERROR_NO_TREASURY_CAP: u64 = 2;
  const ERROR_INCORRECT_TOKEN_NAME: u64 = 3;


  struct PartnerCompletedOrderEvent has copy, drop {
    order_id: String,
    token_earn: u64,
    owner: address,
    partner_address: address,
    created_at: u64
  }

  public fun complete_order<Token>(
    order_id: String,
    nft_card_id: ID,
    member_email: String,
    member_board: &mut MemberBoard,
    partner_address: address,
    partner_code: String,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext){

    let partner: &mut Partner = partner::borrow_mut_parter_by_code(partner_code, partner_board );

    assert!(partner::partner_owner_address(partner) == partner_address, ERROR_NOT_PARTNER_ADDRESS);
    assert!(partner_treasury::treasury_cap_exists<Token>(partner) == true, ERROR_NO_TREASURY_CAP);

    let token_name = partner::partner_token_name(partner);
    let token_sym = util::get_name_as_string<Token>();

    let treasury_cap = partner_treasury::borrow_mut_treasury_cap<Token>(partner);
    assert!(token_name == token_sym, ERROR_INCORRECT_TOKEN_NAME);

    let member: &mut Member = member::borrow_mut_member_by_email(member_board, &member_email);
    let nft_card = member_nft::borrow_mut_nft_card_by_id(member, nft_card_id);
    let value = nft::complete_order(nft_card);
    let coin = token_managable::mint<Token>(treasury_cap, value, ctx);

    member_token::receive_coin(member, coin, ctx);

    let created_at = tx_context::epoch(ctx);
    let completed_order_event = PartnerCompletedOrderEvent {
      order_id,
      token_earn: value,
      owner: member::member_owner(member),
      partner_address,
      created_at
    };

    event::emit(completed_order_event);
  }

  public fun cancel_order<Token>(
    order_id: String,
    nft_card_id: ID,
    member_email: String,
    member_board: &mut MemberBoard,
    partner_address: address,
    partner_code: String,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext){

    let partner: &mut Partner = partner::borrow_mut_parter_by_code(partner_code, partner_board );

    assert!(partner::partner_owner_address(partner) == partner_address, ERROR_NOT_PARTNER_ADDRESS);
    assert!(partner_treasury::treasury_cap_exists<Token>(partner) == true, ERROR_NO_TREASURY_CAP);

    let token_name = partner::partner_token_name(partner);
    let token_sym = util::get_name_as_string<Token>();

    let treasury_cap = partner_treasury::borrow_mut_treasury_cap<Token>(partner);
    assert!(token_name == token_sym, ERROR_INCORRECT_TOKEN_NAME);

    let member: &mut Member = member::borrow_mut_member_by_email(member_board, &member_email);
    let member_address = member::member_owner(member);
    let nft_card = member_nft::borrow_mut_nft_card_by_id(member, nft_card_id);
    let value = nft::cancel_order(nft_card);

    let splitted_coin = member_token::split_coin<Token>(value, member, member_address, ctx);
    partner_token::burn(treasury_cap, splitted_coin, ctx);

    let created_at = tx_context::epoch(ctx);
    let completed_order_event = PartnerCompletedOrderEvent {
      order_id,
      token_earn: value,
      owner: member_address,
      partner_address,
      created_at
    };

    event::emit(completed_order_event);
  }

}