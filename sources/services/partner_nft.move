module loyaltychain::partner_nft {
  use sui::object::{Self, ID};
  use sui::tx_context::{Self, TxContext};
  use sui::event;

  use std::string::{String};
  use std::option::{Self, Option};
  use loyaltychain::partnerable::{Self, Partner};
  use loyaltychain::nft::{Self, NFTCard};

  struct PartnerNFTCardCreatedEvent has copy, drop {
    card_id: ID,
    partner_id: ID,
    card_tier_id: ID,
    card_tier_name: String,
    card_type_id: ID,
    card_type_name: String,
    issued_number: u64,
    benefit: u64,
    issued_at: u64,
  }

  struct PartnerTransferNFTCardEvent has copy, drop {
    card_id: ID,
    partner_id: ID,
    card_tier_id: ID,
    card_type_id: ID,
    issued_number: u64,
    benefit: u64,
    issued_at: u64,
    receiver: address,
  }

  struct PartnerBurnNFTCardEvent has copy, drop {
    card_id: ID,
    partner_id: ID,
    card_tier_id: ID,
    card_tier_name: String,
    card_type_id: ID,
    card_type_name: String,
    issued_number: u64,
    accumulated_value: u64,
    benefit: u64,
    issued_at: u64,
    burned_at: u64
  }


  public fun mint_card(
    card_tier_name: String,
    card_type_name: String,
    partner_address: address,
    partner: &mut Partner,
    ctx: &mut TxContext): Option<NFTCard>{

    let partner_id = object::id(partner);

    // assert!(partnerable::partner_owner_address(partner) == sender, 0);
    if(partnerable::partner_owner_address(partner) != partner_address) {
      return option::none<NFTCard>()
    };

    let mut_card_tier = nft::borrow_mut_card_tier_by_name(card_tier_name, partner);
    let card_tier_id = object::id(mut_card_tier);
    let benefit = nft::card_tier_benefit(mut_card_tier);

    let mut_card_type = nft::borrow_mut_card_type_by_name(card_type_name, mut_card_tier);
    let card_type_id = object::id(mut_card_type);

    if(nft::card_type_current_issued_number(mut_card_type) >= nft::card_type_max_supply(mut_card_type)) {
      return option::none<NFTCard>()
    };

    let issued_number = nft::card_type_current_issued_number(mut_card_type) + 1;
    let issued_at = tx_context::epoch(ctx);

    let nft_card = nft::new_nft_card(
      partner_id,
      card_tier_id,
      card_type_id,
      issued_number,
      issued_at,
      benefit,
      ctx
    );

    nft::increase_current_issued_number(mut_card_type);

    let card_id = object::id(&nft_card);
    let partner_id = object::id(partner);

    let card_created_event = PartnerNFTCardCreatedEvent {
      card_id,
      partner_id,
      card_tier_id: card_tier_id,
      card_tier_name,
      card_type_id: card_type_id,
      card_type_name,
      issued_number: issued_number,
      issued_at: issued_at,
      benefit: benefit
    };

    event::emit(card_created_event);

    option::some<NFTCard>(nft_card)
  }

  public fun mint_and_transfer_card(
    card_tier_name: String,
    card_type_name: String,
    receiver: address,
    partner_address: address,
    partner: &mut Partner,
    ctx: &mut TxContext) {

    let nft_cardable = mint_card(card_tier_name, card_type_name, partner_address, partner, ctx);
    let nft_card = option::destroy_some<NFTCard>(nft_cardable);

    let receive_event = PartnerTransferNFTCardEvent{
      card_id: object::id(&nft_card),
      partner_id: nft::card_partner_id(&nft_card),
      card_tier_id: nft::card_card_tier_id(&nft_card),
      card_type_id: nft::card_card_type_id(&nft_card),
      issued_number: nft::card_issued_number(&nft_card),
      benefit: nft::card_benefit(&nft_card),
      issued_at: nft::card_issued_at(&nft_card),
      receiver,
    };

    event::emit(receive_event);
    nft::transfer_card(nft_card, receiver);
  }

  public fun burn_card(
    card_tier_name: String,
    card_type_name: String,
    nft_card: NFTCard,
    partner: &mut Partner,
    ctx: &mut TxContext){

    let sender = tx_context::sender(ctx);
    assert!(partnerable::partner_owner_address(partner) == sender, 0);

    let mut_card_tier = nft::borrow_mut_card_tier_by_name(card_tier_name, partner);
    let mut_card_type = nft::borrow_mut_card_type_by_name(card_type_name, mut_card_tier);

    let card_id = object::id(&nft_card);
    let (partner_id, card_tier_id, card_type_id, issued_number, issued_at, accumulated_value, benefit) = nft::burn_nft_card(nft_card, mut_card_type);

    let burned_at = tx_context::epoch(ctx);
    let nft_card_burned_event = PartnerBurnNFTCardEvent {
      card_id,
      partner_id,
      card_tier_id,
      card_tier_name,
      card_type_id,
      card_type_name,
      issued_number,
      accumulated_value,
      benefit,
      issued_at,
      burned_at
    };
    event::emit(nft_card_burned_event);
  }

  public fun transfer_card(
    nft_card: NFTCard,
    receiver: address) {
    nft::transfer_card(nft_card, receiver);

  }
}