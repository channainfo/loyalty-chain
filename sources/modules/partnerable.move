module loyaltychain::partnerable {

  use sui::object::{Self, UID, ID};
  use sui::tx_context::{Self, TxContext};
  use sui::transfer;
  use sui::dynamic_object_field;
  use sui::event;

  use std::string::{ String};

  struct PartnerBoard has key, store {
    id: UID,
    partners_count: u64,
    public_partners_count: u64,
    companies_count: u64,
    public_companies_count: u64
  }

  struct Partner has key, store {
    id: UID,
    name: String,
    code: String,
    excerpt: String,
    content: String,
    logo_url: String,
    is_public: bool,
    token_name: String,
    owner_address: address,
    companies_count: u64,
    created_at: u64,
    // token: Option<PartnerTOken>
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
    excerpt: String,
    content: String,
    logo_url: String,
    is_public: bool,
    members_count: u128,
    partner_id: ID,
    created_at: u64
  }

  struct CompanyCreatedEvent has copy, drop {
    company_id: ID,
    partner_id: ID,
    name: String,
    excerpt: String,
    content: String,
    logo_url: String,
    is_public: bool,
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
    is_public: bool,
    token_name: String,
    owner_address: address,
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
      is_public,
      token_name,
      owner_address,
      companies_count: 0u64,
      created_at
    };

    let partner_id = object::id(&partner);
    dynamic_object_field::add<String, Partner>(&mut partner_board.id, code, partner);

    let partner_cap = PartnerCap {
      id: object::new(ctx),
      partner_id
    };

    transfer::public_transfer(partner_cap, owner_address);

    partner_board.partners_count = partner_board.partners_count + 1;
    if(is_public) {
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
    partner: &mut Partner,
    company_board: &mut CompanyBoard,
    partner_board: &mut PartnerBoard,
    ctx: &mut TxContext ): bool {

    let created_at = tx_context::epoch(ctx);
    let partner_id = object::id(partner);
    let is_public = partner.is_public;

    if(dynamic_object_field::exists_<String>(&company_board.id, code)){
      return false
    };

    let company = Company {
      id: object::new(ctx),
      name,
      excerpt,
      content,
      logo_url,
      is_public: is_public,
      members_count: 064,
      created_at,
      partner_id
    };

    company_board.companies_count = company_board.companies_count + 1;
    if(is_public){
      company_board.public_companies_count = company_board.public_companies_count + 1;
    };

    partner_board.companies_count = partner_board.companies_count + 1;
    if(partner.is_public){
      partner_board.public_companies_count = partner_board.public_companies_count + 1;
    };

    partner.companies_count = partner.companies_count + 1;

    let company_id = object::id(&company);
    dynamic_object_field::add<String, Company>(&mut company_board.id, code, company);

    let company_created_event = CompanyCreatedEvent {
      company_id,
      partner_id,
      name,
      excerpt,
      content,
      logo_url,
      is_public: partner.is_public,
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

  public fun companies_count(partner_board: &PartnerBoard): u64 {
    partner_board.companies_count
  }

  public fun public_companies_count(partner_board: &PartnerBoard): u64 {
    partner_board.companies_count
  }


  public fun total_companies_count(company_board: &CompanyBoard): u64 {
    company_board.companies_count
  }

  public fun total_public_companies_count(company_board: &CompanyBoard): u64 {
    company_board.public_companies_count
  }

  // Helper partner
  public fun borrow_partner_by_code(code: String, partner_board: &PartnerBoard): &Partner {
    dynamic_object_field::borrow<String, Partner>(&partner_board.id, code)
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

  public fun partner_is_public(partner: &Partner): bool {
    partner.is_public
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

  // PartnerCap Helper
  public fun partner_cap_partner_id(partner_cap: &PartnerCap): ID {
    partner_cap.partner_id
  }

}