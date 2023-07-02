module loychain::partner_treasury {
  use sui::dynamic_object_field;
  use sui::coin::{TreasuryCap};

  use std::string::{ String};
  use loychain::partner::{Self, Partner, PartnerBoard};
  use loychain::util;


  public fun receive_treasury_cap<Token>(treasury_cap: TreasuryCap<Token>, partner_code: String, partner_board: &mut PartnerBoard) {
    let token_name = util::get_name_as_string<Token>();
    let partner = partner::borrow_mut_parter_by_code(partner_code, partner_board);
    let partner_uid = partner::borrow_mut_partner_id(partner);
    dynamic_object_field::add<String, TreasuryCap<Token>>(partner_uid, token_name, treasury_cap);
  }

  // Treasury Helper
  public fun borrow_mut_treasury_cap<Token>(partner: &mut Partner): &mut TreasuryCap<Token> {
    let token_name = util::get_name_as_string<Token>();
    let partner_uid = partner::borrow_mut_partner_id(partner);

    dynamic_object_field::borrow_mut<String, TreasuryCap<Token>>(partner_uid, token_name)
  }

  public fun treasury_cap_exists<Token>(partner: &Partner): bool {
    let token_name = util::get_name_as_string<Token>();
    let partner_uid = partner::borrow_partner_id(partner);

    dynamic_object_field::exists_<String>(partner_uid, token_name)
  }
}