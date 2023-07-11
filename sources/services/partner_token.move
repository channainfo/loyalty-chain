module loychain::partner_token {
  use sui::tx_context::{Self, TxContext};
  use sui::object::{Self, ID};
  use sui::event;
  use sui::coin::{Coin, TreasuryCap};
  use std::string::String;

  use loychain::member::{Self, Member, MemberBoard};
  use loychain::member_token;
  use loychain::partner::{Self, Partner, PartnerBoard};
  use loychain::partner_treasury;
  use loychain::token_managable;
  use loychain::util;

  const ERROR_NOT_PARTNER_ADDRESS: u64 = 0;
  const ERROR_NO_TREASURY_CAP: u64 = 1;
  const ERROR_INCORRECT_TOKEN_NAME: u64 = 2;

  struct PartnerTokenMinted has copy, drop{
    amount: u64,
    description: String,
    member_id: ID,
    partner_id: ID,
    created_at: u64,
  }

  public fun burn<Token>(
    treasury: &mut TreasuryCap<Token>,
    coin: Coin<Token>,
    _ctx: &mut TxContext) {

    token_managable::burn<Token>(treasury, coin);
  }

  public fun mint_and_transfer_to_member<Token>(
    amount: u64,
    description: String,
    member_email: String,
    member_board: &mut MemberBoard,
    partner_address: address,
    partner_code: String,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext
  ) {

    let partner: &mut Partner = partner::borrow_mut_parter_by_code(partner_code, partner_board );

    assert!(partner::partner_owner_address(partner) == partner_address, ERROR_NOT_PARTNER_ADDRESS);
    assert!(partner_treasury::treasury_cap_exists<Token>(partner) == true, ERROR_NO_TREASURY_CAP);

    let token_name = partner::partner_token_name(partner);
    let token_sym = util::get_name_as_string<Token>();

    let treasury_cap = partner_treasury::borrow_mut_treasury_cap<Token>(partner);
    assert!(token_name == token_sym, ERROR_INCORRECT_TOKEN_NAME);

    let minted_coin = token_managable::mint<Token>(treasury_cap, amount, ctx);
    let member: &mut Member = member::borrow_mut_member_by_email(member_board, &member_email);
    member_token::receive_coin<Token>(member, minted_coin, ctx);

    let created_at = tx_context::epoch(ctx);
    let partner_token_minted = PartnerTokenMinted {
      amount,
      description,
      member_id: object::id(member),
      partner_id: object::id(partner),
      created_at
    };

    event::emit(partner_token_minted);
  }
}