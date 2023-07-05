#[test_only]
module loychain::partner_nft_test {
  
  #[test]
  public fun test_minting_and_burning_nft_card() {
    use sui::test_scenario;

    use std::string::{Self};
    use std::option::{Self, Option};
    use loychain::partner::{Self, PartnerBoard, Partner};
    use loychain::partner_nft;
    use loychain::nft::{Self, NFTCard};

    let owner = @0x0001;
    // Create boards for partner list
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      partner::init_create_boards(ctx);
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

      let result = partner::register_partner(
        name, code, excerpt, content, logo_url,is_public, token_name, owner, allow_nft_card, &mut partner_board, ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Register a Card tier
    let tier_name = string::utf8(b"Bronze");
    let tier_description = string::utf8(b"Bronze Benefit");
    let tier_image_url = string::utf8(b"https://loychain.sui/nft/bronze");
    let tier_benefit = 10;
    let tier_level = 0u8;
    let tier_required_value = 0u64;

    test_scenario::next_tx(&mut scenario, owner);
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
        owner,
        partner,
        ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Register Card type
    let card_type_name = string::utf8(b"Membership");
    let card_type_image_url = string::utf8(b"https://loychain.sui/nft/bronze/membership");
    let card_max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = nft::register_card_type(
        card_type_name,
        tier_name,
        card_type_image_url,
        card_max_supply,
        owner,
        partner,
        ctx);
      assert!(result == true, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Mint nft card and transfer to receiver
    let receiver = @0x0003;
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let nft_cardable: Option<NFTCard> = partner_nft::mint_card(tier_name, card_type_name, owner, partner, ctx);

      assert!(option::is_some<NFTCard>(&nft_cardable) == true, 0);

      let nft_card = option::destroy_some<NFTCard>(nft_cardable);
      partner_nft::transfer_card(nft_card, receiver);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect receiver has a nft card with correct issue number
    test_scenario::next_tx(&mut scenario, receiver);
    {
      let nft_card = test_scenario::take_from_address<NFTCard>(&scenario,receiver);
      assert!(nft::card_issued_number(&nft_card) == 1, 0);
      test_scenario::return_to_address<NFTCard>(receiver, nft_card);
    };

    // Expect current_supply and current_issued_number to be increased to 1
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

      let card_tier = nft::borrow_mut_card_tier_by_name(tier_name, partner);
      let card_type = nft::borrow_mut_card_type_by_name(card_type_name, card_tier);

      assert!(nft::card_type_current_supply(card_type) == 1, 0);
      assert!(nft::card_type_current_issued_number(card_type) == 1, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Mint and transfer card at the same time
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      partner_nft::mint_and_transfer_card( tier_name, card_type_name, receiver, owner, partner, ctx);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect receiver address has two cards with correct data
    test_scenario::next_tx(&mut scenario, receiver);
    {
      let nft_card2 = test_scenario::take_from_address<NFTCard>(&scenario,receiver);
      let nft_card1 = test_scenario::take_from_address<NFTCard>(&scenario,receiver);

      assert!(nft::card_issued_number(&nft_card2) == 2, 0);
      assert!(nft::card_issued_number(&nft_card1) == 1, 0);

      test_scenario::return_to_address<NFTCard>(receiver, nft_card1);
      test_scenario::return_to_address<NFTCard>(receiver, nft_card2);
    };

    // Expect card type current supply and current issued number increased
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

      let card_tier = nft::borrow_mut_card_tier_by_name(tier_name, partner);
      let card_type = nft::borrow_mut_card_type_by_name(card_type_name, card_tier);

      assert!(nft::card_type_current_supply(card_type) == 2, 0);
      assert!(nft::card_type_current_issued_number(card_type) == 2, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Burn one of the card
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

      let nft_card2 = test_scenario::take_from_address<NFTCard>(&scenario,receiver);
      let nft_card1 = test_scenario::take_from_address<NFTCard>(&scenario,receiver);
      let ctx = test_scenario::ctx(&mut scenario);

      partner_nft::burn_card(tier_name, card_type_name, nft_card1, partner, ctx);

      test_scenario::return_to_address<NFTCard>(receiver, nft_card2);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect current supply goes down and current issued number unchanged
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

      let card_tier = nft::borrow_mut_card_tier_by_name(tier_name, partner);
      let card_type = nft::borrow_mut_card_type_by_name(card_type_name, card_tier);

      assert!(nft::card_type_current_supply(card_type) == 1, 0);
      assert!(nft::card_type_current_issued_number(card_type) == 2, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_mint_and_tranfer_to_member(){
    use sui::test_scenario;

    use std::string::{Self, String};
    use loychain::partner::{Self, PartnerBoard, Partner};
    use loychain::partner_nft;
    use loychain::member::{Self, MemberBoard};
    use loychain::member_nft;
    use loychain::nft::{Self, NFTCard};

    let owner = @0x0001;
    // Create boards for partner list
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      partner::init_create_boards(ctx);
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
    let partner_address = @0x0002;
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

    // Register a Card tier
    let tier_name = string::utf8(b"Bronze");
    let tier_description = string::utf8(b"Bronze Benefit");
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
    let card_type_name = string::utf8(b"Membership");
    let card_type_image_url = string::utf8(b"https://loychain.sui/nft/bronze/membership");
    let card_max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, partner_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = nft::register_card_type(
        card_type_name,
        tier_name,
        card_type_image_url,
        card_max_supply,
        partner_address,
        partner,
        ctx);
      assert!(result == true, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Setup member
    let member_email: String = string::utf8(b"admin@loychain.org");
    let member_nick_name: String = string::utf8(b"Scoth");
    let member_address = @0x0003;

    test_scenario::next_tx(&mut scenario, owner);

    // setup member_board
    {
      let ctx = test_scenario::ctx(&mut scenario);
      member::init_create_member_board(ctx);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, member_address);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result = member::register_member(member_nick_name, member_email, member_address, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Mint nft card and transfer to receiver
    test_scenario::next_tx(&mut scenario, owner);
    let nft_card_id = {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let member_board  = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let nft_card_id = partner_nft::mint_and_tranfer_to_member(
        tier_name,
        card_type_name,
        member_email,
        &mut member_board,
        partner_address,
        code,
        &mut partner_board,
        ctx
      );

      test_scenario::return_shared<MemberBoard>(member_board);
      test_scenario::return_shared<PartnerBoard>(partner_board);
      nft_card_id
    };

    // Expect receiver has a nft card with correct issue number
    test_scenario::next_tx(&mut scenario, member_address);
    {
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let member = member::borrow_member_by_email(&member_board, &member_email);
      let nft_card: &NFTCard = member_nft::borrow_nft_card_by_id(member, nft_card_id);

      std::debug::print(nft_card);
      assert!(nft::card_issued_number(nft_card) == 1, 0);
      assert!(nft::card_accumulated_value(nft_card) == 0, 0);

      test_scenario::return_shared<MemberBoard>(member_board);
    };

    // Expect current_supply and current_issued_number to be increased to 1
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

      let card_tier = nft::borrow_mut_card_tier_by_name(tier_name, partner);
      let card_type = nft::borrow_mut_card_type_by_name(card_type_name, card_tier);

      assert!(nft::card_type_current_supply(card_type) == 1, 0);
      assert!(nft::card_type_current_issued_number(card_type) == 1, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect card type current supply and current issued number increased
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

      let card_tier = nft::borrow_mut_card_tier_by_name(tier_name, partner);
      let card_type = nft::borrow_mut_card_type_by_name(card_type_name, card_tier);

      assert!(nft::card_type_current_supply(card_type) == 1, 0);
      assert!(nft::card_type_current_issued_number(card_type) == 1, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    test_scenario::end(scenario);
  }
}