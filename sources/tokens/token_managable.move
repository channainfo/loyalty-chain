module loychain::token_managable {
  use sui::tx_context::{Self, TxContext};
  use std::option::{Self, Option};
  use sui::coin::{Self, TreasuryCap, Coin};
  use sui::url::{Url};
  use sui::transfer;
  use loychain::util;

  // icon can be updated later with update_icon_url
  public fun create_coin<Token: drop>(withness: Token, ctx: &mut TxContext){

    let decimal = 9;
    let symbol = util::get_name_as_bytes<Token>();
    let name = util::get_name_as_bytes<Token>();
    let description = b"";
    let icon_url: Option<Url> = option::none();
    let (treasury_cap, metadata) = coin::create_currency<Token>(withness, decimal, symbol, name, description, icon_url, ctx);

    transfer::public_freeze_object(metadata);
    transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
  }

  public fun mint<Token>(treasury_cap: &mut TreasuryCap<Token>, amount: u64, ctx: &mut TxContext): Coin<Token>{
    let minted_coin: Coin<Token> = coin::mint<Token>(treasury_cap, amount, ctx);
    minted_coin
  }

  public fun mint_and_transfer<Token>(treasury_cap: &mut TreasuryCap<Token>, amount: u64, recipient: address, ctx: &mut TxContext) {
    coin::mint_and_transfer(treasury_cap, amount, recipient, ctx);
  }

  public fun mint_and_merge<Token>(treasury_cap: &mut TreasuryCap<Token>, amount: u64, coin: &mut Coin<Token>, ctx: &mut TxContext){
    let minted_coin: Coin<Token> = coin::mint<Token>(treasury_cap, amount, ctx);
    coin::join<Token>(coin, minted_coin);
  }

  public fun mint_and_join<Token>(treasury_cap: &mut TreasuryCap<Token>, amount: u64, coin: &mut Coin<Token>, ctx: &mut TxContext){
    mint_and_merge(treasury_cap, amount, coin, ctx);
  }

  public fun burn<Token>(treasury_cap: &mut TreasuryCap<Token>, coin: Coin<Token>){
    coin::burn(treasury_cap, coin);
  }
}
