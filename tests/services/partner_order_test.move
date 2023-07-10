#[test_only]
module loychain::partner_order_test {

  #[test]
  #[expected_failure(abort_code=loychain::partner_order::ERROR_NOT_PARTNER_ADDRESS)]
  public fun test_complete_order_not_partner_address(){

    use sui::test_scenario;
    use sui::test_utils;
    use sui::object::{Self};
    use loychain::partner_order;
    use loychain::partner::{Self, PartnerBoard, Partner,};
    use loychain::member::{Self, MemberBoard};
    use loychain::partner_nft;
    use loychain::nft::{Self};
    use loychain::loy::{LOY};
    use loychain::token_managable;
    use std::string::{Self, String};

    let admin_address = @0x0001;

    // setup LOY coin
    let scenario = test_scenario::begin(admin_address);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      let withness = test_utils::create_one_time_witness<LOY>();
      token_managable::create_coin(withness, ctx);
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
      partner::init_create_boards(ctx);
    };

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_partner(
        name, code, excerpt, content, logo_url,is_public, token_name, partner_address, allow_nft_card, &mut partner_board, ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // setup member
    let member_email: String = string::utf8(b"admin@loychain.org");
    let member_nick_name: String = string::utf8(b"Scoth");
    let member_address = @0x0003;
    {
      let ctx = test_scenario::ctx(&mut scenario);
      member::init_create_member_board(ctx);
    };

    test_scenario::next_tx(&mut scenario, member_address);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = member::register_member(member_nick_name, member_email, member_address, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Setup nftcard for the member
    // Register a Card tier
    let tier_name = string::utf8(b"Bronz123");
    let tier_description = string::utf8(b"Bronze Benefit123");
    let tier_image_url = string::utf8(b"https://loychain.sui/nft/bronze");
    let tier_benefit = 10;
    let tier_level = 0u8;
    let tier_required_value = 0u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

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
    let type_image_url = string::utf8(b"https://loychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
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
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      // let nft_cardable: Option<NFTCard> = partner_nft::mint_card(tier_name, type_name, partner_address, partner, ctx);
      // assert!(option::is_some<NFTCard>(&nft_cardable) == true, 0);
      // let nft_card = option::destroy_some<NFTCard>(nft_cardable);
      let nft_card = partner_nft::mint_card(tier_name, type_name, partner_address, partner, ctx);
      let nft_card_id = object::id(&nft_card);
      partner_nft::transfer_card(nft_card, receiver);

      test_scenario::return_shared<PartnerBoard>(partner_board);
      nft_card_id
    };

    let stranger = @0x00020;
    let order_id = string::utf8(b"ORD-182839450388");
    test_scenario::next_tx(&mut scenario, admin_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      partner_order::complete_order<LOY>(
        order_id,
        nft_card_id,
        member_email,
        &mut member_board,
        stranger,
        code,
        &mut partner_board,
        ctx
      );

      test_scenario::return_shared<PartnerBoard>(partner_board);
      test_scenario::return_shared<MemberBoard>(member_board);
    };
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=loychain::partner_order::ERROR_NO_TREASURY_CAP)]
  public fun test_complete_order_no_treasury(){

    use sui::test_scenario;
    use sui::test_utils;
    use sui::object::{Self};
    use loychain::partner_order;
    use loychain::partner::{Self, PartnerBoard, Partner,};
    use loychain::member::{Self, MemberBoard};
    use loychain::member_nft;
    use loychain::partner_nft;
    use loychain::nft::{Self, NFTCard};
    use loychain::loy::{LOY};
    use loychain::token_managable;
    use std::string::{Self, String};

    let admin_address = @0x0001;

    // setup LOY coin
    let scenario = test_scenario::begin(admin_address);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      let withness = test_utils::create_one_time_witness<LOY>();
      token_managable::create_coin(withness, ctx);
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
      partner::init_create_boards(ctx);
    };

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_partner(
        name, code, excerpt, content, logo_url,is_public, token_name, partner_address, allow_nft_card, &mut partner_board, ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // setup member
    let member_email: String = string::utf8(b"admin@loychain.org");
    let member_nick_name: String = string::utf8(b"Scoth");
    let member_address = @0x0003;
    {
      let ctx = test_scenario::ctx(&mut scenario);
      member::init_create_member_board(ctx);
    };

    test_scenario::next_tx(&mut scenario, member_address);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = member::register_member(member_nick_name, member_email, member_address, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Setup nftcard for the member
    // Register a Card tier
    let tier_name = string::utf8(b"Bronz123");
    let tier_description = string::utf8(b"Bronze Benefit123");
    let tier_image_url = string::utf8(b"https://loychain.sui/nft/bronze");
    let tier_benefit = 10;
    let tier_level = 0u8;
    let tier_required_value = 0u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

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
    let type_image_url = string::utf8(b"https://loychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
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
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      // let nft_cardable: Option<NFTCard> = partner_nft::mint_card(tier_name, type_name, partner_address, partner, ctx);
      // assert!(option::is_some<NFTCard>(&nft_cardable) == true, 0);
      // let nft_card = option::destroy_some<NFTCard>(nft_cardable);
      let nft_card = partner_nft::mint_card(tier_name, type_name, partner_address, partner, ctx);
      let nft_card_id = object::id(&nft_card);
      partner_nft::transfer_card(nft_card, receiver);

      test_scenario::return_shared<PartnerBoard>(partner_board);
      nft_card_id
    };

    // Member receive NFT
    test_scenario::next_tx(&mut scenario, member_address);
    {
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let member = member::borrow_mut_member_by_email(&mut member_board, &member_email);
      let nft_card = test_scenario::take_from_address<NFTCard>(&mut scenario, member_address);
      let ctx = test_scenario::ctx(&mut scenario);

      member_nft::claim_nft_card(member, nft_card, ctx);

      test_scenario::return_shared(member_board);
    };

    let order_id = string::utf8(b"ORD-182839450388");
    test_scenario::next_tx(&mut scenario, admin_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      partner_order::complete_order<LOY>(
        order_id,
        nft_card_id,
        member_email,
        &mut member_board,
        partner_address,
        code,
        &mut partner_board,
        ctx
      );

      test_scenario::return_shared<PartnerBoard>(partner_board);
      test_scenario::return_shared<MemberBoard>(member_board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_complete_order_ok(){

    use sui::test_scenario;
    use sui::test_utils;
    use sui::object::{Self};
    use sui::coin::{Self, Coin, TreasuryCap};
    use loychain::partner_order;
    use loychain::partner::{Self, PartnerBoard, Partner,};
    use loychain::member::{Self, MemberBoard};
    use loychain::member_nft;
    use loychain::member_token;
    use loychain::partner_treasury;
    use loychain::partner_nft;
    use loychain::nft::{Self, NFTCard};
    use loychain::loy::{LOY};
    use loychain::token_managable;
    use loychain::util;
    use std::string::{Self, String};

    let admin_address = @0x0001;

    // setup LOY coin
    let scenario = test_scenario::begin(admin_address);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      let withness = test_utils::create_one_time_witness<LOY>();
      token_managable::create_coin(withness, ctx);
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
      partner::init_create_boards(ctx);
    };

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_partner(
        name, code, excerpt, content, logo_url,is_public, token_name, partner_address, allow_nft_card, &mut partner_board, ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // setup member
    let member_email: String = string::utf8(b"admin@loychain.org");
    let member_nick_name: String = string::utf8(b"Scoth");
    let member_address = @0x0003;
    {
      let ctx = test_scenario::ctx(&mut scenario);
      member::init_create_member_board(ctx);
    };

    test_scenario::next_tx(&mut scenario, member_address);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = member::register_member(member_nick_name, member_email, member_address, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Setup nftcard for the member
    // Register a Card tier
    let tier_name = string::utf8(b"Bronz123");
    let tier_description = string::utf8(b"Bronze Benefit123");
    let tier_image_url = string::utf8(b"https://loychain.sui/nft/bronze");
    let tier_benefit = 10;
    let tier_level = 0u8;
    let tier_required_value = 0u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

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
    let type_image_url = string::utf8(b"https://loychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
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
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      // let nft_cardable: Option<NFTCard> = partner_nft::mint_card(tier_name, type_name, partner_address, partner, ctx);
      // assert!(option::is_some<NFTCard>(&nft_cardable) == true, 0);
      // let nft_card = option::destroy_some<NFTCard>(nft_cardable);
      let nft_card = partner_nft::mint_card(tier_name, type_name, partner_address, partner, ctx);
      let nft_card_id = object::id(&nft_card);
      partner_nft::transfer_card(nft_card, receiver);

      test_scenario::return_shared<PartnerBoard>(partner_board);
      nft_card_id
    };

    // Member receive NFT
    test_scenario::next_tx(&mut scenario, member_address);
    {
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let member = member::borrow_mut_member_by_email(&mut member_board, &member_email);
      let nft_card = test_scenario::take_from_address<NFTCard>(&mut scenario, member_address);
      let ctx = test_scenario::ctx(&mut scenario);

      member_nft::claim_nft_card(member, nft_card, ctx);

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

    let order_id = string::utf8(b"ORD-182839450388");
    test_scenario::next_tx(&mut scenario, admin_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      partner_order::complete_order<LOY>(
        order_id,
        nft_card_id,
        member_email,
        &mut member_board,
        partner_address,
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
      let member = member::borrow_mut_member_by_email(&mut board, &member_email);
      let metadata_loy = util::get_name_as_bytes<LOY>();

      let coin_loy: &Coin<LOY> = member_token::borrow_coin_by_coin_type<LOY>(member, metadata_loy);

      assert!(coin::value(coin_loy) == tier_benefit, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    // expect nft_card modified
    test_scenario::next_tx(&mut scenario, member_address);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = member::borrow_mut_member_by_email(&mut board, &member_email);
      let nft_card = member_nft::borrow_mut_nft_card_by_id(member, nft_card_id);

      let accumulated_value = nft::card_accumulated_value(nft_card);
      assert!(accumulated_value == tier_benefit, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=loychain::partner_order::ERROR_NOT_PARTNER_ADDRESS)]
  public fun test_cancel_order_not_partner_address(){

    use sui::test_scenario;
    use sui::test_utils;
    use sui::object::{Self};
    use loychain::partner_order;
    use loychain::partner::{Self, PartnerBoard, Partner,};
    use loychain::member::{Self, MemberBoard};
    use loychain::partner_nft;
    use loychain::nft::{Self};
    use loychain::loy::{LOY};
    use loychain::token_managable;
    use std::string::{Self, String};

    let admin_address = @0x0001;

    // setup LOY coin
    let scenario = test_scenario::begin(admin_address);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      let withness = test_utils::create_one_time_witness<LOY>();
      token_managable::create_coin(withness, ctx);
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
      partner::init_create_boards(ctx);
    };

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_partner(
        name, code, excerpt, content, logo_url,is_public, token_name, partner_address, allow_nft_card, &mut partner_board, ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // setup member
    let member_email: String = string::utf8(b"admin@loychain.org");
    let member_nick_name: String = string::utf8(b"Scoth");
    let member_address = @0x0003;
    {
      let ctx = test_scenario::ctx(&mut scenario);
      member::init_create_member_board(ctx);
    };

    test_scenario::next_tx(&mut scenario, member_address);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = member::register_member(member_nick_name, member_email, member_address, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Setup nftcard for the member
    // Register a Card tier
    let tier_name = string::utf8(b"Bronz123");
    let tier_description = string::utf8(b"Bronze Benefit123");
    let tier_image_url = string::utf8(b"https://loychain.sui/nft/bronze");
    let tier_benefit = 10;
    let tier_level = 0u8;
    let tier_required_value = 0u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

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
    let type_image_url = string::utf8(b"https://loychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
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
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      // let nft_cardable: Option<NFTCard> = partner_nft::mint_card(tier_name, type_name, partner_address, partner, ctx);
      // assert!(option::is_some<NFTCard>(&nft_cardable) == true, 0);
      // let nft_card = option::destroy_some<NFTCard>(nft_cardable);
      let nft_card = partner_nft::mint_card(tier_name, type_name, partner_address, partner, ctx);
      let nft_card_id = object::id(&nft_card);
      partner_nft::transfer_card(nft_card, receiver);

      test_scenario::return_shared<PartnerBoard>(partner_board);
      nft_card_id
    };

    let stranger = @0x00020;
    let order_id = string::utf8(b"ORD-182839450388");
    test_scenario::next_tx(&mut scenario, admin_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      partner_order::cancel_order<LOY>(
        order_id,
        nft_card_id,
        member_email,
        &mut member_board,
        stranger,
        code,
        &mut partner_board,
        ctx
      );

      test_scenario::return_shared<PartnerBoard>(partner_board);
      test_scenario::return_shared<MemberBoard>(member_board);
    };
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=loychain::partner_order::ERROR_NO_TREASURY_CAP)]
  public fun test_cancel_order_no_treasury(){

    use sui::test_scenario;
    use sui::test_utils;
    use sui::object::{Self};
    use loychain::partner_order;
    use loychain::partner::{Self, PartnerBoard, Partner,};
    use loychain::member::{Self, MemberBoard};
    use loychain::member_nft;
    use loychain::partner_nft;
    use loychain::nft::{Self, NFTCard};
    use loychain::loy::{LOY};
    use loychain::token_managable;
    use std::string::{Self, String};

    let admin_address = @0x0001;

    // setup LOY coin
    let scenario = test_scenario::begin(admin_address);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      let withness = test_utils::create_one_time_witness<LOY>();
      token_managable::create_coin(withness, ctx);
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
      partner::init_create_boards(ctx);
    };

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_partner(
        name, code, excerpt, content, logo_url,is_public, token_name, partner_address, allow_nft_card, &mut partner_board, ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // setup member
    let member_email: String = string::utf8(b"admin@loychain.org");
    let member_nick_name: String = string::utf8(b"Scoth");
    let member_address = @0x0003;
    {
      let ctx = test_scenario::ctx(&mut scenario);
      member::init_create_member_board(ctx);
    };

    test_scenario::next_tx(&mut scenario, member_address);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = member::register_member(member_nick_name, member_email, member_address, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Setup nftcard for the member
    // Register a Card tier
    let tier_name = string::utf8(b"Bronz123");
    let tier_description = string::utf8(b"Bronze Benefit123");
    let tier_image_url = string::utf8(b"https://loychain.sui/nft/bronze");
    let tier_benefit = 10;
    let tier_level = 0u8;
    let tier_required_value = 0u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

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
    let type_image_url = string::utf8(b"https://loychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
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
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      // let nft_cardable: Option<NFTCard> = partner_nft::mint_card(tier_name, type_name, partner_address, partner, ctx);
      // assert!(option::is_some<NFTCard>(&nft_cardable) == true, 0);
      // let nft_card = option::destroy_some<NFTCard>(nft_cardable);
      let nft_card = partner_nft::mint_card(tier_name, type_name, partner_address, partner, ctx);
      let nft_card_id = object::id(&nft_card);
      partner_nft::transfer_card(nft_card, receiver);

      test_scenario::return_shared<PartnerBoard>(partner_board);
      nft_card_id
    };

    // Member receive NFT
    test_scenario::next_tx(&mut scenario, member_address);
    {
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let member = member::borrow_mut_member_by_email(&mut member_board, &member_email);
      let nft_card = test_scenario::take_from_address<NFTCard>(&mut scenario, member_address);
      let ctx = test_scenario::ctx(&mut scenario);

      member_nft::claim_nft_card(member, nft_card, ctx);

      test_scenario::return_shared(member_board);
    };

    let order_id = string::utf8(b"ORD-182839450388");
    test_scenario::next_tx(&mut scenario, admin_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      partner_order::cancel_order<LOY>(
        order_id,
        nft_card_id,
        member_email,
        &mut member_board,
        partner_address,
        code,
        &mut partner_board,
        ctx
      );

      test_scenario::return_shared<PartnerBoard>(partner_board);
      test_scenario::return_shared<MemberBoard>(member_board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_cancel_order_ok(){

    use sui::test_scenario;
    use sui::test_utils;
    use sui::object::{Self};
    use sui::coin::{Self, Coin, TreasuryCap};
    use loychain::partner_order;
    use loychain::partner::{Self, PartnerBoard, Partner,};
    use loychain::member::{Self, MemberBoard};
    use loychain::member_nft;
    use loychain::member_token;
    use loychain::partner_treasury;
    use loychain::partner_nft;
    use loychain::nft::{Self, NFTCard};
    use loychain::loy::{LOY};
    use loychain::token_managable;
    use loychain::util;
    use std::string::{Self, String};

    let admin_address = @0x0001;

    // setup LOY coin
    let scenario = test_scenario::begin(admin_address);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      let withness = test_utils::create_one_time_witness<LOY>();
      token_managable::create_coin(withness, ctx);
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
      partner::init_create_boards(ctx);
    };

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_partner(
        name, code, excerpt, content, logo_url,is_public, token_name, partner_address, allow_nft_card, &mut partner_board, ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // setup member
    let member_email: String = string::utf8(b"admin@loychain.org");
    let member_nick_name: String = string::utf8(b"Scoth");
    let member_address = @0x0003;
    {
      let ctx = test_scenario::ctx(&mut scenario);
      member::init_create_member_board(ctx);
    };

    test_scenario::next_tx(&mut scenario, member_address);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = member::register_member(member_nick_name, member_email, member_address, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Setup nftcard for the member
    // Register a Card tier
    let tier_name = string::utf8(b"Bronz123");
    let tier_description = string::utf8(b"Bronze Benefit123");
    let tier_image_url = string::utf8(b"https://loychain.sui/nft/bronze");
    let tier_benefit = 10;
    let tier_level = 0u8;
    let tier_required_value = 0u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

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
    let type_image_url = string::utf8(b"https://loychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
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
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      // let nft_cardable: Option<NFTCard> = partner_nft::mint_card(tier_name, type_name, partner_address, partner, ctx);
      // assert!(option::is_some<NFTCard>(&nft_cardable) == true, 0);
      // let nft_card = option::destroy_some<NFTCard>(nft_cardable);
      let nft_card = partner_nft::mint_card(tier_name, type_name, partner_address, partner, ctx);
      let nft_card_id = object::id(&nft_card);
      partner_nft::transfer_card(nft_card, receiver);

      test_scenario::return_shared<PartnerBoard>(partner_board);
      nft_card_id
    };

    // Member receive NFT
    test_scenario::next_tx(&mut scenario, member_address);
    {
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let member = member::borrow_mut_member_by_email(&mut member_board, &member_email);
      let nft_card = test_scenario::take_from_address<NFTCard>(&mut scenario, member_address);
      let ctx = test_scenario::ctx(&mut scenario);

      member_nft::claim_nft_card(member, nft_card, ctx);

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

    let order_id = string::utf8(b"ORD-182839450388");
    test_scenario::next_tx(&mut scenario, admin_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      partner_order::complete_order<LOY>(
        order_id,
        nft_card_id,
        member_email,
        &mut member_board,
        partner_address,
        code,
        &mut partner_board,
        ctx
      );

      test_scenario::return_shared<PartnerBoard>(partner_board);
      test_scenario::return_shared<MemberBoard>(member_board);
    };

    test_scenario::next_tx(&mut scenario, admin_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      partner_order::cancel_order<LOY>(
        order_id,
        nft_card_id,
        member_email,
        &mut member_board,
        partner_address,
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
      let member = member::borrow_mut_member_by_email(&mut board, &member_email);
      let metadata_loy = util::get_name_as_bytes<LOY>();

      let coin_loy: &Coin<LOY> = member_token::borrow_coin_by_coin_type<LOY>(member, metadata_loy);

      assert!(coin::value(coin_loy) == 0, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    // expect nft_card modified
    test_scenario::next_tx(&mut scenario, member_address);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = member::borrow_mut_member_by_email(&mut board, &member_email);
      let nft_card = member_nft::borrow_mut_nft_card_by_id(member, nft_card_id);

      assert!(nft::card_accumulated_value(nft_card) == 0, 0);
      assert!(nft::card_used_count(nft_card) == 2, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);
  }
}