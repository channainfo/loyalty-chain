module loychain::loy {
  use sui::tx_context::{TxContext};
  use loychain::token_managable;

  struct LOY has drop {}

  // Trigger when package is published
  fun init(withness: LOY, ctx: &mut TxContext) {
    token_managable::create_coin<LOY>(withness, ctx);
  }
}
