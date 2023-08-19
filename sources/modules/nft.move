module loychain::nft {

  use sui::object::{Self, UID, ID};
  use sui::tx_context::{Self, TxContext};
  use sui::url::{ Url};
  use sui::dynamic_object_field;
  use sui::transfer;
  use sui::event;

  use std::string::{String};
  use std::option::{Option};
  use loychain::partner::{Self, Partner};
  use loychain::util;

  const ERROR_NOT_OWNER: u8 = 0;

  // const LOGIC_TYPE: u8 = 1;

  // Define NFTCardTier benefit and level, required
  struct NFTCardTier has key, store {
    id: UID,
    name: String,
    description: String,
    image_url: Option<Url>,
    benefit: u64,
    required_value: u64,
    level: u8,
    partner_id: ID,
    published_at: u64
  }

  // CardType based on a CardTier with issued amount
  struct NFTCardType has key, store {
    id: UID,
    partner_id: ID,
    card_tier_id: ID,
    name: String,
    image_url: Option<Url>,
    max_supply: u64,
    current_supply: u64,
    current_issued_number: u64,
    published_at: u64,
  }

  struct NFTCard has key, store {
    id: UID,
    partner_id: ID,
    card_tier_id: ID,
    card_type_id: ID,
    issued_number: u64,
    issued_at: u64,
    used_count: u64,
    accumulated_value: u64,
    benefit: u64
  }

  struct NFTCardTierCreatedEvent has copy, drop {
    card_tier_id: ID,
    name: String,
    description: String,
    image_url: Option<Url>,
    benefit: u64,
    required_value: u64,
    partner_id: ID,
    published_at: u64
  }

  struct NFTCardTypeCreatedEvent has drop, copy {
    card_type_id: ID,
    partner_id: ID,
    card_tier_id: ID,
    name: String,
    image_url: Option<Url>,
    max_supply: u64,
    current_supply: u64,
    published_at: u64,
  }

  public fun register_card_tier(
    name: String,
    description: String,
    image_url: String,
    benefit: u64,
    level: u8,
    required_value: u64,
    owner_address: address,
    partner: &mut Partner,
    ctx: &mut TxContext): bool{

    if(partner::partner_owner_address(partner) != owner_address){
      return false
    };

    let partner_id = object::id(partner);
    let mut_parnter_id = partner::borrow_mut_partner_id(partner);

    if(dynamic_object_field::exists_<String>(mut_parnter_id, name)){
      return false
    };

    let published_at = tx_context::epoch(ctx);
    let image = util::try_url_from_string(&image_url);

    let card_tier = NFTCardTier {
      id: object::new(ctx),
      name,
      description,
      level,
      image_url: image,
      required_value,
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
      required_value,
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
    owner_address: address,
    partner: &mut Partner,
    ctx: &mut TxContext
    ): bool{

    if(partner::partner_owner_address(partner) != owner_address){
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
      current_issued_number: 0u64,
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
      published_at
    };

    event::emit(card_type_evnt);
    true
  }

  public fun new_nft_card(
    partner_id: ID,
    card_tier_id: ID,
    card_type_id: ID,
    issued_number: u64,
    issued_at: u64,
    benefit: u64,
    ctx: &mut TxContext): NFTCard {
    NFTCard {
      id: object::new(ctx),
      partner_id,
      card_tier_id,
      card_type_id,
      issued_number,
      used_count: 0u64,
      accumulated_value: 0u64,
      issued_at,
      benefit
    }
  }

  public fun burn_nft_card(nft_card: NFTCard, card_type: &mut NFTCardType): (ID, ID, ID, u64, u64, u64, u64, u64){
    if(card_type_current_supply(card_type) > 0){
      card_type.current_supply = card_type.current_supply - 1;
    };

    let NFTCard { id, partner_id, card_tier_id, card_type_id, issued_number, issued_at, used_count,  accumulated_value, benefit } = nft_card;
    object::delete(id);
    (partner_id, card_tier_id, card_type_id, issued_number, issued_at, used_count, accumulated_value, benefit)
  }

  public fun transfer_card(nft_card: NFTCard, receiver: address) {
    transfer::transfer(nft_card, receiver);
  }

  // CardTier Helper
  public fun borrow_mut_card_tier_by_name(card_tier_name: String, partner: &mut Partner,): &mut NFTCardTier {
    let mut_partner_id = partner::borrow_mut_partner_id(partner);
    dynamic_object_field::borrow_mut<String, NFTCardTier>(mut_partner_id, card_tier_name)
  }

  public fun complete_order(nft_card: &mut NFTCard): u64 {
    nft_card.accumulated_value = nft_card.accumulated_value + nft_card.benefit;
    nft_card.used_count = nft_card.used_count + 1;
    nft_card.benefit
  }

  public fun cancel_order(nft_card: &mut NFTCard): u64 {
    nft_card.accumulated_value = nft_card.accumulated_value - nft_card.benefit;
    nft_card.used_count = nft_card.used_count + 1;
    nft_card.benefit
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

  public fun card_tier_benefit(card_tier: &NFTCardTier): u64 {
    card_tier.benefit
  }

  public fun card_tier_required_value(card_tier: &NFTCardTier): u64 {
    card_tier.required_value
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

  public fun card_type_current_supply(card_type: &NFTCardType): u64 {
    card_type.current_supply
  }

  public fun card_type_current_issued_number(card_type: &NFTCardType): u64 {
    card_type.current_issued_number
  }

  public fun increase_current_issued_number(card_type: &mut NFTCardType): u64{
    card_type.current_supply = card_type.current_supply + 1;
    card_type.current_issued_number = card_type.current_issued_number + 1;
    card_type.current_issued_number
  }

  // NFTCard Helper
  public fun card_issued_number(card: &NFTCard): u64 {
    card.issued_number
  }

  public fun card_used_count(card: &NFTCard): u64 {
    card.used_count
  }

  public fun card_issued_at(card: &NFTCard): u64 {
    card.issued_at
  }

  public fun card_accumulated_value(card: &NFTCard): u64 {
    card.accumulated_value
  }

  public fun card_benefit(card: &NFTCard): u64 {
    card.benefit
  }

  public fun card_partner_id(card: &NFTCard): ID {
    card.partner_id
  }

  public fun card_card_type_id(card: &NFTCard): ID {
    card.card_type_id
  }

  public fun card_card_tier_id(card: &NFTCard): ID {
    card.card_tier_id
  }
}
