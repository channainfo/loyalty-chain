#[test_only]
module loyaltychain::member_nft_test {
  #[test]
  public fun test_receive_nft_card(){
    use sui::test_scenario;
    use sui::object;
    use loyaltychain::nft::{Self, NFTCard};
    use loyaltychain::memberable::{Self, MemberBoard};
    use loyaltychain::member_nft;
    use loyaltychain::partnerable::{Self, PartnerBoard, Partner};
    use loyaltychain::partner_nft;
    use std::string::{Self, String};
    use std::option::{Self, Option};

    let owner = @0001;
    let email: String = string::utf8(b"admin@loyaltychain.org");
    let nick_name: String = string::utf8(b"Scoth");

    let scenario = test_scenario::begin(owner);

    // setup member_board
    {
      let ctx = test_scenario::ctx(&mut scenario);
      memberable::init_create_member_board(ctx);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = memberable::register_member(nick_name, email, owner, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::next_tx(&mut scenario, owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      partnerable::init_create_boards(ctx);
    };

    // Register a partner
    let name = string::utf8(b"CM Market");
    let code = string::utf8(b"CMM");
    let excerpt = string::utf8(b"CM Market: Multi market place");
    let content = string::utf8(b"Provide wide range of services and ecoms");
    let logo_url = string::utf8(b"https://cm-market.io/cmm.png");
    let is_public = false;
    let token_name = string::utf8(b"CMM");
    let allow_nft_card = false;
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partnerable::register_partner(
        name, code, excerpt, content, logo_url,is_public, token_name, owner, allow_nft_card, &mut partner_board, ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

     // Register a Card tier
    let tier_name = string::utf8(b"Bronze");
    let tier_description = string::utf8(b"Bronze Benefit");
    let tier_image_url = string::utf8(b"https://loyaltychain.sui/nft/bronze");
    let tier_benefit = 10;
    let tier_level = 0u8;
    let tier_required_value = 0u64;

    test_scenario::next_tx(&mut scenario, owner);
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
        owner,
        partner,
        ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Register Card type
    let type_name = string::utf8(b"Membership");
    let type_image_url = string::utf8(b"https://loyaltychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = nft::register_card_type(
        type_name,
        tier_name,
        type_image_url,
        max_supply,
        owner,
        partner,
        ctx);
      assert!(result == true, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Execute the call
    test_scenario::next_tx(&mut scenario, owner);
    let nft_card_id = {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let nft_cardable: Option<NFTCard> = partner_nft::mint_card(tier_name, type_name, owner, partner, ctx);
      let nft_card = option::destroy_some<NFTCard>(nft_cardable);
      let nft_card_id = object::id(&nft_card);

      member_nft::receive_nft_card(member, nft_card, ctx);

      test_scenario::return_shared<MemberBoard>(board);
      test_scenario::return_shared<PartnerBoard>(partner_board);

      nft_card_id
    };

    // Expect value
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let nft_card = member_nft::borrow_nft_card_by_id(member, nft_card_id);
      assert!(nft::card_issued_number(nft_card) == 1, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };
    // Expect the output
    test_scenario::end(scenario);
  }

  #[test]
  public fun test_take_nft_card(){
    use sui::test_scenario;
    use sui::object;
    use loyaltychain::nft::{Self, NFTCard};
    use loyaltychain::memberable::{Self, MemberBoard};
    use loyaltychain::member_nft;
    use loyaltychain::partnerable::{Self, PartnerBoard, Partner};
    use loyaltychain::partner_nft;
    use std::string::{Self, String};
    use std::option::{Self, Option};

    let owner = @0001;
    let email: String = string::utf8(b"admin@loyaltychain.org");
    let nick_name: String = string::utf8(b"Scoth");

    let scenario = test_scenario::begin(owner);

    // setup member_board
    {
      let ctx = test_scenario::ctx(&mut scenario);
      memberable::init_create_member_board(ctx);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = memberable::register_member(nick_name, email, owner, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::next_tx(&mut scenario, owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      partnerable::init_create_boards(ctx);
    };

    // Register a partner
    let name = string::utf8(b"CM Market");
    let code = string::utf8(b"CMM");
    let excerpt = string::utf8(b"CM Market: Multi market place");
    let content = string::utf8(b"Provide wide range of services and ecoms");
    let logo_url = string::utf8(b"https://cm-market.io/cmm.png");
    let is_public = false;
    let token_name = string::utf8(b"CMM");
    let allow_nft_card = false;
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partnerable::register_partner(
        name, code, excerpt, content, logo_url,is_public, token_name, owner, allow_nft_card, &mut partner_board, ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

     // Register a Card tier
    let tier_name = string::utf8(b"Bronze");
    let tier_description = string::utf8(b"Bronze Benefit");
    let tier_image_url = string::utf8(b"https://loyaltychain.sui/nft/bronze");
    let tier_benefit = 10;
    let tier_level = 0u8;
    let tier_required_value = 0u64;

    test_scenario::next_tx(&mut scenario, owner);
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
        owner,
        partner,
        ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Register Card type
    let type_name = string::utf8(b"Membership");
    let type_image_url = string::utf8(b"https://loyaltychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = nft::register_card_type(
        type_name,
        tier_name,
        type_image_url,
        max_supply,
        owner,
        partner,
        ctx);
      assert!(result == true, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Execute the call
    test_scenario::next_tx(&mut scenario, owner);
    let nft_card_id = {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let nft_cardable: Option<NFTCard> = partner_nft::mint_card(tier_name, type_name, owner, partner, ctx);
      let nft_card = option::destroy_some<NFTCard>(nft_cardable);
      let nft_card_id = object::id(&nft_card);

      member_nft::receive_nft_card(member, nft_card, ctx);

      test_scenario::return_shared<MemberBoard>(board);
      test_scenario::return_shared<PartnerBoard>(partner_board);

      nft_card_id
    };

    // Test take_nft_card
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);
      let nft_card = member_nft::take_nft_card(member, nft_card_id);
      assert!(nft::card_issued_number(&nft_card) == 1, 0);
      partner_nft::transfer_card(nft_card, @0x0003);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Expect the output
    test_scenario::end(scenario);
  }

  #[test]
  public fun take_and_transfer_nft_card(){
    use sui::test_scenario;
    use sui::object;
    use loyaltychain::nft::{Self, NFTCard};
    use loyaltychain::memberable::{Self, MemberBoard};
    use loyaltychain::member_nft;
    use loyaltychain::partnerable::{Self, PartnerBoard, Partner};
    use loyaltychain::partner_nft;
    use std::string::{Self, String};
    use std::option::{Self, Option};

    let owner = @0001;
    let email: String = string::utf8(b"admin@loyaltychain.org");
    let nick_name: String = string::utf8(b"Scoth");

    let scenario = test_scenario::begin(owner);

    // setup member_board
    {
      let ctx = test_scenario::ctx(&mut scenario);
      memberable::init_create_member_board(ctx);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = memberable::register_member(nick_name, email, owner, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::next_tx(&mut scenario, owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      partnerable::init_create_boards(ctx);
    };

    // Register a partner
    let name = string::utf8(b"CM Market");
    let code = string::utf8(b"CMM");
    let excerpt = string::utf8(b"CM Market: Multi market place");
    let content = string::utf8(b"Provide wide range of services and ecoms");
    let logo_url = string::utf8(b"https://cm-market.io/cmm.png");
    let is_public = false;
    let token_name = string::utf8(b"CMM");
    let allow_nft_card = false;
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partnerable::register_partner(
        name, code, excerpt, content, logo_url,is_public, token_name, owner, allow_nft_card, &mut partner_board, ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

     // Register a Card tier
    let tier_name = string::utf8(b"Bronze");
    let tier_description = string::utf8(b"Bronze Benefit");
    let tier_image_url = string::utf8(b"https://loyaltychain.sui/nft/bronze");
    let tier_benefit = 10;
    let tier_level = 0u8;
    let tier_required_value = 0u64;

    test_scenario::next_tx(&mut scenario, owner);
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
        owner,
        partner,
        ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Register Card type
    let type_name = string::utf8(b"Membership");
    let type_image_url = string::utf8(b"https://loyaltychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = nft::register_card_type(
        type_name,
        tier_name,
        type_image_url,
        max_supply,
        owner,
        partner,
        ctx);
      assert!(result == true, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Set nft card to member
    test_scenario::next_tx(&mut scenario, owner);
    let nft_card_id = {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let nft_cardable: Option<NFTCard> = partner_nft::mint_card(tier_name, type_name, owner, partner, ctx);
      let nft_card = option::destroy_some<NFTCard>(nft_cardable);
      let nft_card_id = object::id(&nft_card);

      member_nft::receive_nft_card(member, nft_card, ctx);

      test_scenario::return_shared<MemberBoard>(board);
      test_scenario::return_shared<PartnerBoard>(partner_board);

      nft_card_id
    };

    let receiver_address = @0x0002;
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);
      let ctx = test_scenario::ctx(&mut scenario);

      member_nft::take_and_transfer_nft_card(member, nft_card_id, receiver_address, ctx);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Expect address to receive the card
    test_scenario::next_tx(&mut scenario, receiver_address);
    {
      let nft_card = test_scenario::take_from_address<NFTCard>(&scenario, receiver_address);
      assert!(nft::card_issued_number(&nft_card) == 1, 0);

      test_scenario::return_to_address<NFTCard>(receiver_address, nft_card);
    };

    // Expect the output
    test_scenario::end(scenario);
  }

}