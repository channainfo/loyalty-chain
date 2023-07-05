module loychain::member_nft {
  use sui::tx_context::{Self, TxContext};
  use sui::transfer::{Self};
  use sui::object::{Self, UID, ID };
  use sui::dynamic_object_field;
  use sui::event;

  use loychain::member::{Self, Member};
  use loychain::nft::{ NFTCard};

  const NFT_CARD_KEY: vector<u8> = b"nft_cards";
  const ERROR_NOT_OWNER: u64 = 0;

  struct MemberNFTCard has key, store {
    id: UID
  }

  struct MemberReceivedNFTCardEvent has drop, copy {
    member_id: ID,
    nft_card_id: ID,
    created_at: u64
  }

  struct MemberTranferedNFTCardEvent has drop, copy {
    sender_id: ID,
    receiver_address: address,
    nft_card_id: ID,
    created_at: u64
  }

  public fun claim_nft_card(member: &mut Member, nft_card: NFTCard, ctx: &mut TxContext){
    let sender_address = tx_context::sender(ctx);
    assert!(member::member_owner(member) == sender_address, ERROR_NOT_OWNER);

    receive_nft_card(member, nft_card, ctx);
  }

  public fun receive_nft_card(member: &mut Member, nft_card: NFTCard, ctx: &mut TxContext){
    let member_id = object::id(member);
    let member_uid = member::borrow_mut_id(member);

    if(!dynamic_object_field::exists_<vector<u8>>(member_uid, NFT_CARD_KEY)){

      let member_nft_card = MemberNFTCard {
        id: object::new(ctx)
      };

      let received_event = MemberReceivedNFTCardEvent {
        member_id: member_id,
        nft_card_id: object::id(&nft_card),
        created_at: tx_context::epoch(ctx)
      };

      dynamic_object_field::add<vector<u8>, MemberNFTCard>(member_uid, NFT_CARD_KEY, member_nft_card);
      event::emit(received_event);
    };

    let member_nft_card = dynamic_object_field::borrow_mut<vector<u8>, MemberNFTCard>(member_uid, NFT_CARD_KEY);
    let nft_card_id = object::id(&nft_card);
    dynamic_object_field::add<ID, NFTCard>(&mut member_nft_card.id, nft_card_id, nft_card)
  }

  public fun take_nft_card(member: &mut Member, nft_card_id: ID): NFTCard {
    let member_uid = member::borrow_mut_id(member);

    let member_nft_card = dynamic_object_field::borrow_mut<vector<u8>, MemberNFTCard>(member_uid, NFT_CARD_KEY);
    let nft_card = dynamic_object_field::remove<ID, NFTCard>(&mut member_nft_card.id, nft_card_id);
    nft_card
  }

  public fun take_and_transfer_nft_card(
    member: &mut Member,
    nft_card_id: ID,
    receiver_address: address,
    ctx: &mut TxContext){

    let sender_address = tx_context::sender(ctx);
    assert!(member::member_owner(member) == sender_address, ERROR_NOT_OWNER);

    let nft_card = take_nft_card(member, nft_card_id);
    transfer::public_transfer(nft_card, receiver_address);

    let created_at = tx_context::epoch(ctx);

    let transfer_event = MemberTranferedNFTCardEvent {
      sender_id: object::id(member),
      receiver_address,
      nft_card_id,
      created_at
    };

    event::emit(transfer_event);
  }

  public fun borrow_mut_nft_card_by_id(member: &mut Member, nft_card_id: ID): &mut NFTCard {
    let member_uid = member::borrow_mut_id(member);

    let member_nft_card = dynamic_object_field::borrow_mut<vector<u8>, MemberNFTCard>(member_uid, NFT_CARD_KEY);
    dynamic_object_field::borrow_mut<ID, NFTCard>(&mut member_nft_card.id, nft_card_id)
  }

  public fun borrow_nft_card_by_id(member: &Member, nft_card_id: ID): &NFTCard {
    let member_uid = member::borrow_id(member);

    let member_nft_card = dynamic_object_field::borrow<vector<u8>, MemberNFTCard>(member_uid, NFT_CARD_KEY);
    dynamic_object_field::borrow<ID, NFTCard>(&member_nft_card.id, nft_card_id)
  }
}