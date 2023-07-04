module loychain::main{
  use sui::tx_context::{Self, TxContext};
  use sui::coin::{Coin, TreasuryCap};
  use sui::object::{ID};

  use loychain::cap::{Self, AdminCap};
  use loychain::partner::{Self, PartnerBoard, CompanyBoard, Partner};
  use loychain::partner_treasury;
  use loychain::partner_nft;
  use loychain::partner_order;
  use loychain::member::{Self, MemberBoard, Member};
  use loychain::member_nft;
  use loychain::member_token;
  use loychain::nft::{Self, NFTCard};

  use std::string::{String};

  // Trigger when package is published
  fun init(ctx: &mut TxContext){
    cap::init_create_admin_cap(ctx);
    partner::init_create_boards(ctx);
    member::init_create_member_board(ctx);
  }

  // custody
  public entry fun admin_register_partner(
    _admin_cap: &AdminCap,
    name: String,
    code: String,
    excerpt: String,
    content: String,
    logo_url: String,
    is_public: bool,
    token_name: String,
    owner_address: address,
    allow_nft_card: bool,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext){

    partner::register_partner(
      name,
      code,
      excerpt,
      content,
      logo_url,
      is_public,
      token_name,
      owner_address,
      allow_nft_card,
      partner_board,
      ctx
    );
  }

  // custody
  public entry fun admin_register_company(
    _admin_cap: &AdminCap,
    name: String,
    code: String,
    excerpt: String,
    content: String,
    logo_url: String,
    partner_code: String,
    partner_address: address,
    company_board: &mut CompanyBoard,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext){

    partner::register_company(
      name,
      code,
      excerpt,
      content,
      logo_url,
      partner_code,
      partner_address,
      company_board,
      partner_board,
      ctx
    );
  }

  // self-custody
  public entry fun partner_register_company(
    name: String,
    code: String,
    excerpt: String,
    content: String,
    logo_url: String,
    partner_code: String,
    company_board: &mut CompanyBoard,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext){

    let partner_address = tx_context::sender(ctx);

    partner::register_company(
      name,
      code,
      excerpt,
      content,
      logo_url,
      partner_code,
      partner_address,
      company_board,
      partner_board,
      ctx
    );
  }

  // custody
  public entry fun admin_register_member(
    _admin_cap: &AdminCap,
    nick_name: String,
    email: String,
    owner: address,
    board: &mut MemberBoard,
    ctx: &mut TxContext){

    member::register_member(
      nick_name,
      email,
      owner,
      board,
      ctx
    );
  }

  // self-custody
  public entry fun member_register_member(
    nick_name: String,
    email: String,
    board: &mut MemberBoard,
    ctx: &mut TxContext){

    let owner = tx_context::sender(ctx);
    member::register_member(
      nick_name,
      email,
      owner,
      board,
      ctx
    );
  }

  // custody
  public entry fun admin_register_card_tier(
    _admin_cap: &AdminCap,
    name: String,
    description: String,
    image_url: String,
    benefit: u64,
    level: u8,
    required_value: u64,
    partner_address: address,
    partner: &mut Partner,
    ctx: &mut TxContext){

    nft::register_card_tier(
      name,
      description,
      image_url,
      benefit,
      level,
      required_value,
      partner_address,
      partner,
      ctx
    );
  }

  // self-custody
  public entry fun partner_register_card_tier(
    name: String,
    description: String,
    image_url: String,
    benefit: u64,
    level: u8,
    required_value: u64,
    partner: &mut Partner,
    ctx: &mut TxContext){

    let partner_address = tx_context::sender(ctx);
    nft::register_card_tier(
      name,
      description,
      image_url,
      benefit,
      level,
      required_value,
      partner_address,
      partner,
      ctx
    );
  }

  // custody
  public entry fun admin_register_card_type(
    _admin_cap: &AdminCap,
    name: String,
    card_tier_name: String,
    image_url: String,
    max_supply: u64,
    owner_address: address,
    partner: &mut Partner,
    ctx: &mut TxContext){

    nft::register_card_type(
      name,
      card_tier_name,
      image_url,
      max_supply,
      owner_address,
      partner,
      ctx
    );
  }

  // non-custody
  public entry fun partner_register_card_type(
    name: String,
    card_tier_name: String,
    image_url: String,
    max_supply: u64,
    partner: &mut Partner,
    ctx: &mut TxContext){

    let owner_address = tx_context::sender(ctx);
    nft::register_card_type(
      name,
      card_tier_name,
      image_url,
      max_supply,
      owner_address,
      partner,
      ctx
    );
  }

  // custody
  public entry fun admin_mint_and_transfer_card(
    _admin_cap: &AdminCap,
    card_tier_name: String,
    card_type_name: String,
    receiver: address,
    partner_address: address,
    partner: &mut Partner,
    ctx: &mut TxContext) {

    partner_nft::mint_and_transfer_card(
      card_tier_name,
      card_type_name,
      receiver,
      partner_address,
      partner,
      ctx
    );
  }

  // non-custody
  public entry fun partner_mint_and_transfer_card(
    card_tier_name: String,
    card_type_name: String,
    receiver: address,
    partner: &mut Partner,
    ctx: &mut TxContext) {

    let partner_address = tx_context::sender(ctx);
    partner_nft::mint_and_transfer_card(
      card_tier_name,
      card_type_name,
      receiver,
      partner_address,
      partner,
      ctx
    );
  }

  // self custody member
  public entry fun member_claim_coin<T>(
    member: &mut Member,
    coin: Coin<T>,
    ctx: &TxContext){

    member_token::receive_coin<T>(member, coin, ctx);
  }

  // self custody member
  public entry fun member_transfer_coin<T>(
    value: u64,
    member: &mut Member,
    receiver_address: address,
    ctx: &mut TxContext){

    member_token::split_and_transfer_coin<T>(
      value,
      member,
      receiver_address,
      ctx
    );
  }

  // self costody member
  public entry fun member_claim_nft_card(member: &mut Member, nft_card: NFTCard, ctx: &mut TxContext){
    member_nft::claim_nft_card(member, nft_card, ctx);
  }

  public entry fun member_transfer_nft_card(
    member: &mut Member,
    nft_card_id: ID,
    receiver_address: address,
    ctx: &mut TxContext){

    member_nft::take_and_transfer_nft_card(member, nft_card_id, receiver_address, ctx);
  }

  public entry fun transfer_treasury_cap<Token>(
    _admin_cap: &AdminCap,
    treasury_cap: TreasuryCap<Token>,
    partner_code: String,
    partner_board: &mut PartnerBoard){
    partner_treasury::receive_treasury_cap<Token>(treasury_cap, partner_code, partner_board);
  }

  // customdy
  public fun admin_complete_order<Token>(
    _admin_cap: &AdminCap,
    order_id: String,
    nft_card_id: ID,
    member_email: String,
    member_board: &mut MemberBoard,
    partner_address: address,
    partner_code: String,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext){
    partner_order::complete_order<Token>(order_id, nft_card_id, member_email, member_board, partner_address, partner_code, partner_board, ctx);
  }

  // non-customdy
  public fun partner_complete_order<Token>(
    order_id: String,
    nft_card_id: ID,
    member_email: String,
    member_board: &mut MemberBoard,
    partner_code: String,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext){
    let partner_address = tx_context::sender(ctx);
    partner_order::complete_order<Token>(order_id, nft_card_id, member_email, member_board, partner_address, partner_code, partner_board, ctx);
  }

  // custody
  public fun admin_mint_and_tranfer_to_member(
    _admin_cap: &AdminCap,
    card_tier_name: String,
    card_type_name: String,
    member_email: String,
    member_board: &mut MemberBoard,
    partner_address: address,
    partner_code: String,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext
  ){
    partner_nft::mint_and_tranfer_to_member(
      card_tier_name,
      card_type_name,
      member_email,
      member_board,
      partner_address,
      partner_code,
      partner_board,
      ctx
    );
  }

  // non-custody
  public fun partner_mint_and_tranfer_to_member(
    card_tier_name: String,
    card_type_name: String,
    member_email: String,
    member_board: &mut MemberBoard,
    partner_code: String,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext
  ){
    let partner_address = tx_context::sender(ctx);
    partner_nft::mint_and_tranfer_to_member(
      card_tier_name,
      card_type_name,
      member_email,
      member_board,
      partner_address,
      partner_code,
      partner_board,
      ctx
    );
  }

}