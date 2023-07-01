module loyaltychain::loy {
  use sui::tx_context::{Self, TxContext};
  use sui::coin::{Self,};
  use sui::transfer;
  use sui::url::{Url};

  use std::option::{Self, Option};

  struct LOY has drop {}

  // Trigger when package is published
  fun init(withness: LOY, ctx: &mut TxContext) {
    create_coin(withness, ctx);
  }

  // icon can be updated later with update_icon_url
  public fun create_coin(withness: LOY, ctx: &mut TxContext){
    let decimal = 9;
    let symbol = b"LOY";
    let name = b"LOY";
    let description = b"";
    let icon_url: Option<Url> = option::none();
    let (treasury_cap, metadata) = coin::create_currency<LOY>(withness, decimal, symbol, name, description, icon_url, ctx);

    transfer::public_freeze_object(metadata);
    transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
  }

  #[test]
  public fun test_init(){
    use sui::test_scenario;
    use sui::coin::{Self, TreasuryCap, Coin};

    use loyaltychain::loy::{LOY};
    use loyaltychain::token_managable;

    let owner = @0x0001;
    let owner_amount_minted = 5_000u64;

    let receiver = @0x0002;
    let receiver_amount_mited = 15_000u64;

    let amount_burned = 3_500u64;

    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      init(LOY{}, ctx);
    };

    // coin minted
    test_scenario::next_tx(&mut scenario, owner);
    {
      let address = test_scenario::sender(&scenario);
      let treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(& scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      // mint amount: owner_amount_minted 2 times and transfer to owner
      token_managable::mint_and_transfer(&mut treasury_cap, owner_amount_minted, address, ctx);
      token_managable::mint_and_transfer(&mut treasury_cap, owner_amount_minted, address, ctx);

      // mint amount: receiver_amount_mited and transfer to receiver
      token_managable::mint_and_transfer(&mut treasury_cap, receiver_amount_mited, receiver, ctx);

      test_scenario::return_to_sender(&scenario, treasury_cap);
    };

    // test amount minted
    test_scenario::next_tx(&mut scenario, owner);
    {
      let owner_coin1 = test_scenario::take_from_address<Coin<LOY>>(&mut scenario, owner);
      let owner_coin2 = test_scenario::take_from_address<Coin<LOY>>(&mut scenario, owner);
      let recipient_coin = test_scenario::take_from_address<Coin<LOY>>(&mut scenario, receiver);

      // owner has 2 coins objects of value owner_amount_minted each
      assert!(coin::value(&owner_coin1) == owner_amount_minted, 0);
      assert!(coin::value(&owner_coin2) == owner_amount_minted, 0);

      // receiver has 1 coin object of value receiver_amount_mited
      assert!(coin::value(&recipient_coin) == receiver_amount_mited, 0);

      test_scenario::return_to_address<Coin<LOY>>(owner, owner_coin1);
      test_scenario::return_to_address<Coin<LOY>>(owner, owner_coin2);
      test_scenario::return_to_address<Coin<LOY>>(receiver, recipient_coin);
    };

    // burn coin
    test_scenario::next_tx(&mut scenario, owner);
    {
      let treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&scenario);
      let owner_coin = test_scenario::take_from_sender<Coin<LOY>>(& scenario);
      let owner_balance = coin::balance_mut<LOY>(&mut owner_coin);

      let ctx = test_scenario::ctx(&mut scenario);
      let portion = coin::take<LOY>(owner_balance, amount_burned, ctx);

      loyaltychain::token_managable::burn(&mut treasury_cap, portion);

      test_scenario::return_to_sender<Coin<LOY>>(&scenario, owner_coin);
      test_scenario::return_to_sender<TreasuryCap<LOY>>(&scenario, treasury_cap);
    };

    // test amount burn
    test_scenario::next_tx(&mut scenario, owner);
    {
      let owner_coin1 = test_scenario::take_from_sender<Coin<LOY>>(&scenario);
      let owner_coin2 = test_scenario::take_from_sender<Coin<LOY>>(&scenario);

      assert!(coin::value(&owner_coin1) == (owner_amount_minted - amount_burned), 0);
      assert!(coin::value(&owner_coin2) == (owner_amount_minted), 0);

      test_scenario::return_to_sender<Coin<LOY>>(&scenario, owner_coin1);
      test_scenario::return_to_sender<Coin<LOY>>(&scenario, owner_coin2);
    };

    // test join coin for owner_coin
    test_scenario::next_tx(&mut scenario, owner);
    {
      let owner_coin1 = test_scenario::take_from_sender<Coin<LOY>>(&scenario);
      let owner_coin2 = test_scenario::take_from_sender<Coin<LOY>>(&scenario);

      coin::join(&mut owner_coin1, owner_coin2);

      let total_coin = owner_amount_minted + (owner_amount_minted - amount_burned) ;
      assert!(coin::value(&owner_coin1) == total_coin, 0);
      test_scenario::return_to_sender<Coin<LOY>>(&scenario, owner_coin1);
    };

    // test mint_and_merge coin for owner_coin
    test_scenario::next_tx(&mut scenario, owner);
    {
      let owner_coin = test_scenario::take_from_sender<Coin<LOY>>(&scenario);
      let treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&scenario);

      let ctx = test_scenario::ctx(&mut scenario);
      token_managable::mint_and_merge(&mut treasury_cap, owner_amount_minted, &mut owner_coin, ctx);

      let total_coin = owner_amount_minted + owner_amount_minted + (owner_amount_minted - amount_burned) ;
      assert!(coin::value(&owner_coin) == total_coin, 0);
      test_scenario::return_to_sender<Coin<LOY>>(&scenario, owner_coin);
      test_scenario::return_to_sender<TreasuryCap<LOY>>(&scenario, treasury_cap);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_complete_order(){

    use sui::test_scenario;
    use sui::object::{Self};
    use sui::coin::{Self, Coin, TreasuryCap};
    use loyaltychain::orderable;
    use loyaltychain::partnerable::{Self, PartnerBoard, Partner,};
    use loyaltychain::memberable::{Self, MemberBoard};
    use loyaltychain::member_nft;
    use loyaltychain::member_token;
    use loyaltychain::partner_treasury;
    use loyaltychain::partner_nft;
    use loyaltychain::nft::{Self, NFTCard};
    use loyaltychain::loy::{LOY};
    use loyaltychain::util;
    use std::string::{Self, String};
    use std::option::{Self, Option};

    let admin_address = @0x0001;

    // setup LOY coin
    let scenario = test_scenario::begin(admin_address);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      init(LOY{}, ctx);
    };

    // setup partner
    let name = string::utf8(b"CM Market");
    let code = string::utf8(b"CMM");
    let excerpt = string::utf8(b"CM Market: Multi market place");
    let content = string::utf8(b"Provide wide range of services and ecoms");
    let logo_url = string::utf8(b"https://cm-market.io/cmm.png");
    let is_public = false;
    let token_name = string::utf8(b"LOY");
    let allow_nft_card = false;
    let partner_address = @0x0002;

    {
      let ctx = test_scenario::ctx(&mut scenario);
      partnerable::init_create_boards(ctx);
    };

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partnerable::register_partner(
        name, code, excerpt, content, logo_url,is_public, token_name, partner_address, allow_nft_card, &mut partner_board, ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // setup member
    let member_email: String = string::utf8(b"admin@loyaltychain.org");
    let member_nick_name: String = string::utf8(b"Scoth");
    let member_address = @0x0003;
    {
      let ctx = test_scenario::ctx(&mut scenario);
      memberable::init_create_member_board(ctx);
    };

    test_scenario::next_tx(&mut scenario, member_address);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = memberable::register_member(member_nick_name, member_email, member_address, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Setup nftcard for the member
    // Register a Card tier
    let tier_name = string::utf8(b"Bronz123");
    let tier_description = string::utf8(b"Bronze Benefit123");
    let tier_image_url = string::utf8(b"https://loyaltychain.sui/nft/bronze");
    let tier_benefit = 10;
    let tier_level = 0u8;
    let tier_required_value = 0u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);

      let ctx = test_scenario::ctx(&mut scenario);

      let result = nft::register_card_tier(
        tier_name,
        tier_description,
        tier_image_url,
        tier_benefit,
        tier_level,
        tier_required_value,
        partner_address,
        partner,
        ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Register Card type
    let type_name = string::utf8(b"Membership123");
    let type_image_url = string::utf8(b"https://loyaltychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = nft::register_card_type(
        type_name,
        tier_name,
        type_image_url,
        max_supply,
        partner_address,
        partner,
        ctx);
      assert!(result == true, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Mint nft card and transfer to receiver
    let receiver = member_address;
    test_scenario::next_tx(&mut scenario, partner_address);
    let nft_card_id = {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let nft_cardable: Option<NFTCard> = partner_nft::mint_card(tier_name, type_name, partner_address, partner, ctx);

      assert!(option::is_some<NFTCard>(&nft_cardable) == true, 0);

      let nft_card = option::destroy_some<NFTCard>(nft_cardable);
      let nft_card_id = object::id(&nft_card);
      partner_nft::transfer_card(nft_card, receiver);

      test_scenario::return_shared<PartnerBoard>(partner_board);
      nft_card_id
    };

    // Member receive NFT
    test_scenario::next_tx(&mut scenario, member_address);
    {
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut member_board, &member_email);
      let nft_card = test_scenario::take_from_address<NFTCard>(&mut scenario, member_address);
      let ctx = test_scenario::ctx(&mut scenario);

      member_nft::receive_nft_card(member, nft_card, ctx);

      test_scenario::return_shared(member_board);
    };

    // Transfer treasury to the partner
    test_scenario::next_tx(&mut scenario, admin_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&mut scenario);

      partner_treasury::receive_treasury_cap<LOY>(treasury_cap, code, &mut partner_board);
      test_scenario::return_shared(partner_board);
    };

    // Verify partner received TreasuryCap
    test_scenario::next_tx(&mut scenario, admin_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);

      let exists = partner_treasury::treasury_cap_exists<LOY>(partner);
      assert!(exists == true, 0);
      test_scenario::return_shared(partner_board);
    };

    let order_id = string::utf8(b"ORD-182839450388");
    test_scenario::next_tx(&mut scenario, admin_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      orderable::complete_order<LOY>(
        order_id,
        nft_card_id,
        member_email,
        &mut member_board,
        code,
        &mut partner_board,
        ctx
      );

      test_scenario::return_shared<PartnerBoard>(partner_board);
      test_scenario::return_shared<MemberBoard>(member_board);
    };

    // expect member receive coin
    test_scenario::next_tx(&mut scenario, member_address);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &member_email);
      let metadata_loy = util::get_name_as_bytes<LOY>();

      let coin_loy: &Coin<LOY> = member_token::borrow_coin_by_coin_type<LOY>(member, metadata_loy);

      assert!(coin::value(coin_loy) == tier_benefit, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    // expect nft_card modified
    test_scenario::next_tx(&mut scenario, member_address);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &member_email);
      let nft_card = member_nft::borrow_mut_nft_card_by_id(member, nft_card_id);

      let accumulated_value = nft::card_accumulated_value(nft_card);
      assert!(accumulated_value == tier_benefit, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);
  }
}
