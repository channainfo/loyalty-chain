module loyaltychain::memberable {
  use sui::tx_context::{Self, TxContext};
  use sui::transfer::{Self};
  use sui::object::{Self, UID, ID };
  use sui::dynamic_object_field;
  use sui::event;
  use sui::coin::{Self, Coin};

  use std::string::{String};
  use loyaltychain::util::{Self};
  use loyaltychain::nft::{NFTCard};

  const NFT_CARD_KEY: vector<u8> = b"nft_cards";

  struct MemberBoard has key, store {
    id: UID,
    members_count: u128,
  }

  struct Member has key, store {
    id: UID,
    nick_name: String,
    code: vector<u8>,
    owner: address,
  }

  struct MemberNFTCard has key, store {
    id: UID
  }

  struct MemberReceivedCoinEvent has copy, drop {
    metadata_id: ID,
    member_id: ID,
    amount: u64,
    from_amount: u64,
    to_amount: u64,
    received_at: u64
  }

  struct MemberSentCoinEvent has copy, drop {
    metadata_id: ID,
    sender_id: ID,
    receiver_address: address,
    amount: u64,
    sent_at: u64
  }

  struct MemberCreatedEvent has drop, copy {
    member_id: ID,
    code: vector<u8>,
    nick_name: String,
    owner: address,
    created_at: u64
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

  public fun init_create_member_board(ctx: &mut TxContext) {
    let board = MemberBoard {
      id: object::new(ctx),
      members_count: 0u128
    };

    transfer::public_share_object(board);
  }

  // make sure metadata_id: ID is the id of the CoinMetadata from the client
  // eq: metadata: &CoinMatadata and metadata_id: object::id(metadata)
  // It is easy to mock ID than constructing a real CoinMetadata object
  // coin is the coin from your own address
  public fun receive_coin<T>(member: &mut Member, coin: Coin<T>, metadata_id: ID, ctx: &TxContext){
    let member_id = object::id(member);
    let amount = coin::value(&coin);
    let received_at = tx_context::epoch(ctx);

    let from_amount = if(dynamic_object_field::exists_<ID>(&member.id, metadata_id)) {
      let existing_coin = dynamic_object_field::borrow_mut<ID, Coin<T>>(&mut member.id, metadata_id);
      coin::join(existing_coin, coin);
      coin::value(existing_coin)
    }else {
      dynamic_object_field::add<ID, Coin<T>>(&mut member.id, metadata_id, coin);
      0u64
    };

    let to_amount = from_amount + amount;
    let received_coin_event = MemberReceivedCoinEvent {
      metadata_id,
      member_id,
      amount,
      from_amount,
      to_amount,
      received_at
    };

    event::emit(received_coin_event);
  }

  public fun split_coin<T>(value: u64, member: &mut Member, metadata_id: ID, ctx: &mut TxContext): Coin<T>{
    assert!(member.owner == tx_context::sender(ctx), 0);

    let coin_exist = dynamic_object_field::exists_<ID>(&member.id, metadata_id);
    assert!(coin_exist, 0);

    let whole_coin = dynamic_object_field::borrow_mut(&mut member.id, metadata_id);
    let split_coin = coin::split<T>(whole_coin, value, ctx);

    split_coin
  }

  // transfer to an address and then allow member to claim
  public fun split_and_transfer_coin<T>(value: u64, sender: &mut Member, receiver_address: address, metadata_id: ID, ctx: &mut TxContext) {
    let split_coin = split_coin<T>(value, sender, metadata_id, ctx);

    let sender_id = object::id(sender);
    let sent_at = tx_context::epoch(ctx);
    transfer::public_transfer(split_coin, receiver_address);

    let sent_event = MemberSentCoinEvent {
      metadata_id,
      sender_id,
      receiver_address,
      amount: value,
      sent_at
    };

    event::emit(sent_event);
  }

  public fun receive_nft_card(member: &mut Member, nft_card: NFTCard, ctx: &mut TxContext){
    if(!dynamic_object_field::exists_<vector<u8>>(&member.id, NFT_CARD_KEY)){

      let member_nft_card = MemberNFTCard {
        id: object::new(ctx)
      };

      let received_event = MemberReceivedNFTCardEvent {
        member_id: object::id(member),
        nft_card_id: object::id(&nft_card),
        created_at: tx_context::epoch(ctx)
      };

      dynamic_object_field::add<vector<u8>, MemberNFTCard>(&mut member.id, NFT_CARD_KEY, member_nft_card);
      event::emit(received_event);
    };

    let member_nft_card = dynamic_object_field::borrow_mut<vector<u8>, MemberNFTCard>(&mut member.id, NFT_CARD_KEY);
    let nft_card_id = object::id(&nft_card);
    dynamic_object_field::add<ID, NFTCard>(&mut member_nft_card.id, nft_card_id, nft_card)
  }

  public fun take_nft_card(member: &mut Member, nft_card_id: ID): NFTCard {

    let member_nft_card = dynamic_object_field::borrow_mut<vector<u8>, MemberNFTCard>(&mut member.id, NFT_CARD_KEY);
    let nft_card = dynamic_object_field::remove<ID, NFTCard>(&mut member_nft_card.id, nft_card_id);
    nft_card
  }

  public fun take_and_transfer_nft_card(member: &mut Member, nft_card_id: ID, receiver_address: address, ctx: &mut TxContext){

    let sender_address = tx_context::sender(ctx);
    assert!(member.owner == sender_address, 0);

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

  public fun register_member(nick_name: String, email: String, board: &mut MemberBoard, ctx: &mut TxContext): bool {
    let code: vector<u8> = util::hash_string(&email);
    let created_at = tx_context::epoch(ctx);
    let owner = tx_context::sender(ctx);

    if(dynamic_object_field::exists_<vector<u8>>(&board.id, code)) {
      return false
    };

    let member = Member {
      id: object::new(ctx),
      nick_name,
      code,
      owner
    };

    let member_id = object::id(&member);
    dynamic_object_field::add<vector<u8>, Member>(&mut board.id, code, member);

    board.members_count = board.members_count + 1 ;

    let member_created_event = MemberCreatedEvent{
      member_id,
      nick_name,
      code,
      owner,
      created_at,
    };

    event::emit(member_created_event);
    true
  }

  // helper method
  public fun members_count(board: &MemberBoard): u128 {
    board.members_count
  }

  public fun member_code(member: &Member): vector<u8> {
    member.code
  }

  public fun member_owner(member: &Member): address {
    member.owner
  }

  public fun member_nick_name(member: &Member): String {
    member.nick_name
  }

  public fun borrow_member_by_email(board: &MemberBoard, email: &String): &Member {
    let code = util::hash_string(email);

    dynamic_object_field::borrow<vector<u8>, Member>(&board.id, code)
  }

  public fun borrow_mut_member_by_email(board: &mut MemberBoard, email: &String): &mut Member {
    let code = util::hash_string(email);

    dynamic_object_field::borrow_mut<vector<u8>, Member>(&mut board.id, code)
  }

  public fun borrow_coin_by_metadata_id<T>(member: &Member, metadata_id: ID): &Coin<T> {
    let existing_coin = dynamic_object_field::borrow<ID, Coin<T>>(& member.id, metadata_id);
    existing_coin
  }

  public fun borrow_mut_coin_by_metadata_id<T>(member: &mut Member, metadata_id: ID): &mut Coin<T> {
    let existing_coin = dynamic_object_field::borrow_mut<ID, Coin<T>>(&mut member.id, metadata_id);
    existing_coin
  }

  public fun borrow_nft_card_by_id(member: &Member, nft_card_id: ID): &NFTCard {
    let member_nft_card = dynamic_object_field::borrow<vector<u8>, MemberNFTCard>(&member.id, NFT_CARD_KEY);
    dynamic_object_field::borrow<ID, NFTCard>(&member_nft_card.id, nft_card_id)
  }
}