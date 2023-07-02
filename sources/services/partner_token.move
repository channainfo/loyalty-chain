#[test_only]
module loychain::partner_token {
  use sui::tx_context::{Self, TxContext};
  use sui::coin::{Self,};
  use sui::transfer;
  use sui::url::{Url};

  use std::option::{Self, Option};

  struct PARTNER_TOKEN has drop{}

  fun init(withness: PARTNER_TOKEN, ctx: &mut TxContext) {
    create_coin(withness, ctx);
  }

  // icon can be updated later with update_icon_url
  public fun create_coin(withness: PARTNER_TOKEN, ctx: &mut TxContext){
    let decimal = 9;
    let symbol = b"PARTNER_TOKEN";
    let name = b"PARTNER_TOKEN";

    let description = b"";
    let icon_url: Option<Url> = option::none();
    let (treasury_cap, metadata) = coin::create_currency<PARTNER_TOKEN>(withness, decimal, symbol, name, description, icon_url, ctx);

    transfer::public_freeze_object(metadata);
    transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
  }
}