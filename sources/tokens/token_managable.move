module loyaltychain::token_managable {

  use sui::coin::{Self, TreasuryCap, Coin};
  use sui::tx_context::{TxContext};

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
