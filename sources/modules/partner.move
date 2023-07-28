module loychain::partner {

  use sui::object::{Self, UID, ID};
  use sui::tx_context::{Self, TxContext};
  use sui::transfer;
  use sui::dynamic_object_field;
  use sui::event;

  use std::string::{ String};

  const VISIBILITY_HIDDEN: u64 = 0;
  const VISIBILITY_VISIBLE: u64 = 1;

  struct PartnerBoard has key, store {
    id: UID,
    partners_count: u64,
    public_partners_count: u64,
    companies_count: u64,
    public_companies_count: u64
  }

  struct Partner has key, store{
    id: UID,
    name: String,
    code: String,
    excerpt: String,
    content: String,
    logo_url: String,
    visibility: u8,
    token_name: String,
    owner_address: address,
    companies_count: u64,
    created_at: u64,
    allow_nft_card: u8,
  }

  struct PartnerCap has key, store{
    id: UID,
    partner_id: ID,
  }

  struct PartnerCreateEvent has copy, drop {
    partner_id: ID,
    name: String,
    code: String,
    excerpt: String,
    content: String,
    logo_url: String,
    token_name: String,
    created_at: u64
  }

  struct CompanyBoard has key, store{
    id: UID,
    companies_count: u64,
    public_companies_count: u64,
  }

  struct Company has key, store {
    id: UID,
    name: String,
    code: String,
    excerpt: String,
    content: String,
    logo_url: String,
    visibility: u8,
    members_count: u128,
    owner_address: address,
    partner_id: ID,
    created_at: u64
  }

  struct CompanyCreatedEvent has copy, drop {
    company_id: ID,
    partner_id: ID,
    owner_address: address,
    name: String,
    excerpt: String,
    content: String,
    logo_url: String,
    visibility: u8,
    created_at: u64
  }

  public fun init_create_boards(ctx: &mut TxContext) {

    let partner_board = PartnerBoard {
      id: object::new(ctx),
      companies_count: 0u64,
      partners_count: 0u64,
      public_partners_count: 0u64,
      public_companies_count: 0u64
    };

    let company_board = CompanyBoard {
      id: object::new(ctx),
      companies_count: 0u64,
      public_companies_count: 0u64
    };

    transfer::public_share_object(partner_board);
    transfer::public_share_object(company_board);
  }

  public fun register_partner(
    name: String,
    code: String,
    excerpt: String,
    content: String,
    logo_url: String,
    visibility: u8,
    token_name: String,
    owner_address: address,
    allow_nft_card: u8,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext): bool{

    if(dynamic_object_field::exists_<String>(&partner_board.id, code)){
      return false
    };

    let _sender = tx_context::sender(ctx);
    let id = object::new(ctx);
    let created_at = tx_context::epoch(ctx);

    let partner = Partner {
      id,
      name,
      code,
      excerpt,
      content,
      logo_url,
      visibility,
      token_name,
      owner_address,
      companies_count: 0u64,
      created_at,
      allow_nft_card,
    };

    let partner_id = object::id(&partner);
    dynamic_object_field::add<String, Partner>(&mut partner_board.id, code, partner);

    let partner_cap = PartnerCap {
      id: object::new(ctx),
      partner_id
    };

    transfer::public_transfer(partner_cap, owner_address);

    partner_board.partners_count = partner_board.partners_count + 1;
    let visible = visibility == (VISIBILITY_VISIBLE as u8);
    if(visible) {
      partner_board.public_partners_count = partner_board.public_partners_count + 1;
    };

    let partner_created_event = PartnerCreateEvent{
      partner_id,
      name,
      code,
      excerpt,
      content,
      logo_url,
      token_name,
      created_at
    };

    event::emit(partner_created_event);
    return true
  }

  public fun register_company(
    name: String,
    code: String,
    excerpt: String,
    content: String,
    logo_url: String,
    partner_code: String,
    partner_address: address,
    company_board: &mut CompanyBoard,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext ): bool {

    if(dynamic_object_field::exists_<String>(&company_board.id, code)){
      return false
    };

    let (partner_id, visibility, partner_owner_address) = {
      let partner = borrow_mut_parter_by_code(partner_code, partner_board);
      partner.companies_count = partner.companies_count + 1;
      (
        object::id(partner),
        partner.visibility,
        partner.owner_address
      )
    };

    assert!(partner_owner_address == partner_address, 0);

    let created_at = tx_context::epoch(ctx);

    // we recommend to use partner_code::company_code
    let company = Company {
      id: object::new(ctx),
      code,
      name,
      excerpt,
      content,
      logo_url,
      visibility,
      owner_address: partner_address,
      members_count: 064,
      created_at,
      partner_id
    };
    let visible = visibility == (VISIBILITY_VISIBLE as u8);
    company_board.companies_count = company_board.companies_count + 1;
    if(visible){
      company_board.public_companies_count = company_board.public_companies_count + 1;
    };

    partner_board.companies_count = partner_board.companies_count + 1;
    if(visible){
      partner_board.public_companies_count = partner_board.public_companies_count + 1;
    };

    let company_id = object::id(&company);
    dynamic_object_field::add<String, Company>(&mut company_board.id, code, company);

    let company_created_event = CompanyCreatedEvent {
      company_id,
      partner_id,
      name,
      excerpt,
      content,
      logo_url,
      visibility,
      owner_address: partner_address,
      created_at,
    };
    event::emit(company_created_event);

    true
  }


  // Helper boards
  public fun partners_count(partner_board: &PartnerBoard): u64 {
    partner_board.partners_count
  }

  public fun public_partners_count(partner_board: &PartnerBoard): u64 {
    partner_board.public_partners_count
  }

  public fun partners_companies_count(partner_board: &PartnerBoard): u64 {
    partner_board.companies_count
  }

  public fun partners_public_companies_count(partner_board: &PartnerBoard): u64 {
    partner_board.companies_count
  }

  // Company board Helper
  public fun companies_count(company_board: &CompanyBoard): u64 {
    company_board.companies_count
  }

  public fun public_companies_count(company_board: &CompanyBoard): u64 {
    company_board.public_companies_count
  }

  // Helper partner
  public fun borrow_partner_by_code(code: String, partner_board: &PartnerBoard): &Partner {
    dynamic_object_field::borrow<String, Partner>(&partner_board.id, code)
  }

  public fun borrow_mut_parter_by_code(code: String, partner_board: &mut PartnerBoard): &mut Partner {
    dynamic_object_field::borrow_mut<String, Partner>(&mut partner_board.id, code)
  }

  public fun borrow_mut_partner_id(partner: &mut Partner): &mut UID {
    &mut partner.id
  }

  public fun borrow_partner_id(partner: &Partner): &UID {
    &partner.id
  }

  public fun partner_name(partner: &Partner): String {
    partner.name
  }

  public fun partner_code(partner: &Partner): String {
    partner.code
  }

  public fun partner_excerpt(partner: &Partner): String {
    partner.excerpt
  }

  public fun partner_content(partner: &Partner): String {
    partner.content
  }

  public fun partner_logo_url(partner: &Partner): String {
    partner.logo_url
  }

  public fun partner_visibility(partner: &Partner): u8 {
    partner.visibility
  }

  public fun partner_token_name(partner: &Partner): String {
    partner.token_name
  }

  public fun partner_owner_address(partner: &Partner): address {
    partner.owner_address
  }
  public fun partner_companies_count(partner: &Partner): u64 {
    partner.companies_count
  }

  public fun partner_allow_nft_card(partner: &Partner): u8 {
    partner.allow_nft_card
  }

  // PartnerCap Helper
  public fun partner_cap_partner_id(partner_cap: &PartnerCap): ID {
    partner_cap.partner_id
  }

  // Company Helper
  public fun borrow_company_by_code(code: String, company_board: &CompanyBoard): &Company {
    dynamic_object_field::borrow<String, Company>(&company_board.id, code)
  }

  public fun company_code(company: &Company): String {
    company.code
  }

  public fun company_name(company: &Company): String {
    company.name
  }

  public fun company_excerpt(company: &Company): String {
    company.excerpt
  }

  public fun company_content(company: &Company): String {
    company.content
  }

  public fun company_logo_url(company: &Company): String {
    company.logo_url
  }

  public fun company_partner_id(company: &Company): &ID {
    &company.partner_id
  }

  public fun company_owner_address(company: &Company): address {
    company.owner_address
  }

}