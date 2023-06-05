module loyaltychain::nft {

  use sui::object::{Self, UID, ID};
  use sui::tx_context::{Self, TxContext};
  use sui::url::{ Url};
  use sui::dynamic_object_field;
  use sui::event;
  use sui::transfer;

  use std::string::{String};
  use std::option::{Self, Option};
  use loyaltychain::partnerable::{Self, Partner};
  use loyaltychain::util;

  const ERROR_NOT_OWNER: u8 = 0;

  struct NFTCardTier has key, store {
    id: UID,
    name: String,
    description: String,
    image_url: Option<Url>,
    benefit: u8,
    partner_id: ID,
    published_at: u64
  }

  struct NFTCardTierCreatedEvent has copy, drop {
    card_tier_id: ID,
    name: String,
    description: String,
    image_url: Option<Url>,
    benefit: u8,
    partner_id: ID,
    published_at: u64
  }

  struct NFTCardType has key, store {
    id: UID,
    partner_id: ID,
    card_tier_id: ID,
    name: String,
    image_url: Option<Url>,
    max_supply: u64,
    current_supply: u64,
    current_issued_nunber: u64,
    benefit: u8,
    capped_amount: u64,
    published_at: u64,
  }

  struct NFTCardTypeCreatedEvent has drop, copy {
    card_type_id: ID,
    partner_id: ID,
    card_tier_id: ID,
    name: String,
    image_url: Option<Url>,
    max_supply: u64,
    current_supply: u64,
    benefit: u8,
    capped_amount: u64,
    published_at: u64,
  }

  struct NFTCard has key, store {
    id: UID,
    card_tier_id: ID,
    card_type_id: ID,
    issued_number: u64,
    issued_at: u64,
  }

  struct NFTCardCreatedEvent has copy, drop {
    card_id: ID,
    card_tier_id: ID,
    card_tier_name: String,
    card_type_id: ID,
    card_type_name: String,
    issued_number: u64,
    owner: address,
    issued_at: u64,
  }

  struct NFTCardBurnedEvent has copy, drop {
    card_id: ID,
    card_tier_id: ID,
    card_tier_name: String,
    card_type_id: ID,
    card_type_name: String,
    issued_number: u64,
    issued_at: u64,
    burned_at: u64
  }

  public fun mint_card(
    card_tier_name: String,
    card_type_name: String,
    partner: &mut Partner,
    ctx: &mut TxContext): Option<NFTCard>{
    let sender = tx_context::sender(ctx);

    // assert!(partnerable::partner_owner_address(partner) == sender, 0);
    if(partnerable::partner_owner_address(partner) != sender) {
      return option::none<NFTCard>()
    };

    let mut_card_tier = borrow_mut_card_tier_by_name(card_tier_name, partner);
    let card_tier_id = object::id(mut_card_tier);

    let mut_card_type = borrow_mut_card_type_by_name(card_type_name, mut_card_tier);
    let card_type_id = object::id(mut_card_type);

    if(mut_card_type.current_issued_nunber >= mut_card_type.max_supply) {
      return option::none<NFTCard>()
    };

    let issued_number = mut_card_type.current_issued_nunber + 1;
    let issued_at = tx_context::epoch(ctx);

    let nft_card = NFTCard {
      id: object::new(ctx),
      card_tier_id,
      card_type_id,
      issued_number,
      issued_at,
    };

    mut_card_type.current_supply = mut_card_type.current_supply + 1;
    mut_card_type.current_issued_nunber = issued_number;

    option::some<NFTCard>(nft_card)
  }

  public fun mint_and_transfer_card(
    card_tier_name: String,
    card_type_name: String,
    receiver: address,
    partner: &mut Partner,
    ctx: &mut TxContext) {

    let nft_cardable = mint_card(card_tier_name, card_type_name, partner, ctx);

    let nft_card = option::destroy_some<NFTCard>(nft_cardable);

    let card_id = object::id(&nft_card);
    let card_created_event = NFTCardCreatedEvent {
      card_id,
      card_tier_id: nft_card.card_tier_id,
      card_tier_name,
      card_type_id: nft_card.card_type_id,
      card_type_name,
      issued_number: nft_card.issued_number,
      issued_at: nft_card.issued_at,
      owner: receiver,
    };

    transfer::transfer(nft_card, receiver);
    event::emit(card_created_event);
  }

  public fun burn_card(card_tier_name: String, card_type_name: String, nft_card: NFTCard, partner: &mut Partner, ctx: &mut TxContext){
    let sender = tx_context::sender(ctx);
    assert!(partnerable::partner_owner_address(partner) == sender, 0);

    let mut_card_tier = borrow_mut_card_tier_by_name(card_tier_name, partner);
    let mut_card_type = borrow_mut_card_type_by_name(card_type_name, mut_card_tier);

    if(mut_card_type.current_supply > 0){
      mut_card_type.current_supply = mut_card_type.current_supply - 1;
    };

    let card_id = object::id(&nft_card);
    let NFTCard { id, card_tier_id, card_type_id, issued_number, issued_at } = nft_card;
    object::delete(id);

    let burned_at = tx_context::epoch(ctx);
    let nft_card_burned_event = NFTCardBurnedEvent {
      card_id,
      card_tier_id,
      card_tier_name,
      card_type_id,
      card_type_name,
      issued_number,
      issued_at,
      burned_at
    };
    event::emit(nft_card_burned_event);
  }

  public fun transfer_card(nft_card: NFTCard, receiver: address) {
    transfer::transfer(nft_card, receiver);
  }

  public fun register_card_tier( name: String, description: String, image_url: String, benefit: u8, partner: &mut Partner, ctx: &mut TxContext): bool{
    if(partnerable::partner_owner_address(partner) != tx_context::sender(ctx)){
      return false
    };

    let partner_id = object::id(partner);
    let mut_parnter_id = partnerable::borrow_mut_partner_id(partner);

    if(dynamic_object_field::exists_<String>(mut_parnter_id, name)){
      return false
    };

    let published_at = tx_context::epoch(ctx);
    let image = util::try_url_from_string(&image_url);

    let card_tier = NFTCardTier {
      id: object::new(ctx),
      name,
      description,
      image_url: image,
      benefit,
      partner_id,
      published_at
    };

    let card_tier_id = object::id(&card_tier);
    dynamic_object_field::add<String, NFTCardTier>(mut_parnter_id, name, card_tier);

    let card_tier_event = NFTCardTierCreatedEvent {
      card_tier_id,
      name,
      description,
      image_url: image,
      benefit,
      partner_id,
      published_at
    };

    event::emit(card_tier_event);
    true
  }

  public fun register_card_type(
    name: String,
    card_tier_name: String,
    image_url: String,
    max_supply: u64,
    capped_amount: u64,
    partner: &mut Partner,
    ctx: &mut TxContext
    ): bool{

    if(partnerable::partner_owner_address(partner) != tx_context::sender(ctx)){
      return false
    };

    let partner_id = object::id(partner);
    let mut_card_tier = borrow_mut_card_tier_by_name(card_tier_name, partner);
    let card_tier_id = object::id(mut_card_tier);

    if(dynamic_object_field::exists_<String>(&mut_card_tier.id, name)){
      return false
    };

    let published_at = tx_context::epoch(ctx);
    let image = util::try_url_from_string(&image_url);

    let card_type = NFTCardType{
      id: object::new(ctx),
      partner_id,
      card_tier_id,
      name,
      image_url: image,
      max_supply,
      current_supply: 0u64,
      current_issued_nunber: 0u64,
      benefit: mut_card_tier.benefit,
      capped_amount,
      published_at
    };

    let card_type_id = object::id(&card_type);
    dynamic_object_field::add<String, NFTCardType>(&mut mut_card_tier.id, name, card_type);

    let card_type_evnt = NFTCardTypeCreatedEvent {
      card_type_id,
      partner_id,
      card_tier_id,
      name,
      image_url: image,
      max_supply,
      current_supply: 0u64,
      benefit: mut_card_tier.benefit,
      capped_amount,
      published_at
    };

    event::emit(card_type_evnt);
    true
  }

  // CardTier Helper
  public fun borrow_mut_card_tier_by_name(card_tier_name: String, partner: &mut Partner,): &mut NFTCardTier {
    let mut_partner_id = partnerable::borrow_mut_partner_id(partner);
    dynamic_object_field::borrow_mut<String, NFTCardTier>(mut_partner_id, card_tier_name)
  }

  public fun card_tier_name(card_tier: &NFTCardTier): String {
    card_tier.name
  }

  public fun card_tier_description(card_tier: &NFTCardTier): String {
    card_tier.description
  }

  public fun card_tier_image_url(card_tier: &NFTCardTier): &Option<Url> {
    &card_tier.image_url
  }

  public fun card_tier_benefit(card_tier: &NFTCardTier): u8 {
    card_tier.benefit
  }

  // CardType Helper
  public fun borrow_mut_card_type_by_name(card_type_name: String, card_tier: &mut NFTCardTier): &mut NFTCardType {
    dynamic_object_field::borrow_mut<String, NFTCardType>(&mut card_tier.id, card_type_name)
  }

  public fun card_type_name(card_type: &NFTCardType): String {
    card_type.name
  }

  public fun card_type_image_url(card_type: &NFTCardType): &Option<Url> {
    &card_type.image_url
  }

  public fun card_type_max_supply(card_type: &NFTCardType): u64 {
    card_type.max_supply
  }

  public fun card_type_capped_amount(card_type: &NFTCardType): u64 {
    card_type.capped_amount
  }

  public fun card_type_current_supply(card_type: &NFTCardType): u64 {
    card_type.current_supply
  }

  public fun card_type_current_issued_number(card_type: &NFTCardType): u64 {
    card_type.current_issued_nunber
  }

  public fun card_type_benefit(card_type: &NFTCardType): u8 {
    card_type.benefit
  }

  // NFTCard Helper
  public fun card_issued_number(card: &NFTCard): u64 {
    card.issued_number
  }
}
