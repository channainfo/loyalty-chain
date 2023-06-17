module loyaltychain::main{
  use sui::tx_context::{Self, TxContext};
  use sui::coin::{Coin};
  use sui::object::{ID};

  use loyaltychain::cap::{Self, AdminCap};
  use loyaltychain::partnerable::{Self, PartnerBoard, CompanyBoard, Partner};
  use loyaltychain::memberable::{Self, MemberBoard, Member};
  use loyaltychain::nft::{Self, NFTCard};

  use std::string::{String};

  fun init(ctx: &mut TxContext){
    cap::init_create_admin_cap(ctx);
    partnerable::init_create_boards(ctx);
    memberable::init_create_member_board(ctx);
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

    partnerable::register_partner(
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

    partnerable::register_company(
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

    partnerable::register_company(
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

    memberable::register_member(
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
    memberable::register_member(
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
    benefit: u8,
    partner_address: address,
    partner: &mut Partner,
    ctx: &mut TxContext){

    nft::register_card_tier(
      name,
      description,
      image_url,
      benefit,
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
    benefit: u8,
    partner: &mut Partner,
    ctx: &mut TxContext){

    let partner_address = tx_context::sender(ctx);
    nft::register_card_tier(
      name,
      description,
      image_url,
      benefit,
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
    capped_amount: u64,
    owner_address: address,
    partner: &mut Partner,
    ctx: &mut TxContext){

    nft::register_card_type(
      name,
      card_tier_name,
      image_url,
      max_supply,
      capped_amount,
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
    capped_amount: u64,
    partner: &mut Partner,
    ctx: &mut TxContext){

    let owner_address = tx_context::sender(ctx);
    nft::register_card_type(
      name,
      card_tier_name,
      image_url,
      max_supply,
      capped_amount,
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

    nft::mint_and_transfer_card(
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
    nft::mint_and_transfer_card(
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
    metadata_id: ID,
    ctx: &TxContext){

    memberable::receive_coin<T>(member, coin, metadata_id, ctx);
  }

  // self custody member
  public entry fun member_transfer_coin<T>(
    value: u64,
    member: &mut Member,
    receiver_address: address,
    metadata_id: ID,
    ctx: &mut TxContext){

    memberable::split_and_transfer_coin<T>(
      value,
      member,
      receiver_address,
      metadata_id,
      ctx
    );
  }

  // self costody member
  public entry fun member_claim_nft_card(member: &mut Member, nft_card: NFTCard, ctx: &mut TxContext){
    memberable::receive_nft_card(member, nft_card, ctx);
  }

  public entry fun member_transfer_nft_card(
    member: &mut Member,
    nft_card_id: ID,
    receiver_address: address,
    ctx: &mut TxContext){

    memberable::take_and_transfer_nft_card(member, nft_card_id, receiver_address, ctx);
  }
}