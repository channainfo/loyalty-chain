#[test_only]
module loychain::nft_test {

  #[test]
  public fun test_register_card_tier(){
    use sui::test_scenario;
    use sui::url::{Url};

    use std::string::{Self};
    use std::option::{Self};
    use loychain::partner::{Self, PartnerBoard, Partner};
    use loychain::nft::{Self};

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
    let visibility = 1;
    let token_name = string::utf8(b"CMM");
    let allow_nft_card = 1;
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_partner(
        name, code, excerpt, content, logo_url,visibility, token_name, owner, allow_nft_card, &mut partner_board, ctx
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

    // Expect failure if not owner of the parnter
    let stranger = @0x0002;
    test_scenario::next_tx(&mut scenario, stranger);
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
        stranger,
        partner,
        ctx
      );
      assert!(result == false, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect to be successfully created
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

    // Expect the created card tier with correct fields
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

      let card_tier = nft::borrow_mut_card_tier_by_name(tier_name, partner);

      assert!(nft::card_tier_name(card_tier) == tier_name, 0);
      assert!(nft::card_tier_description(card_tier) == tier_description, 0);
      assert!(option::is_some<Url>(nft::card_tier_image_url(card_tier)) == true, 0);
      assert!(nft::card_tier_benefit(card_tier) == tier_benefit, 0);
      assert!(nft::card_tier_required_value(card_tier) == tier_required_value, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect failure if try to create the same card tier
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
      assert!(result == false, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_register_card_type(){
    use sui::test_scenario;
    use sui::url::{Url};

    use std::string::{Self};
    use std::option::{Self};
    use loychain::partner::{Self, PartnerBoard, Partner};
    use loychain::nft::{Self};

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
    let visibility = 1;
    let token_name = string::utf8(b"CMM");
    let allow_nft_card = 1;
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_partner(
        name, code, excerpt, content, logo_url,visibility, token_name, owner, allow_nft_card, &mut partner_board, ctx
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
    let type_name = string::utf8(b"Membership");
    let type_image_url = string::utf8(b"https://loychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;

    // Expect failure if not owner of the partner
    let stranger = @0x0002;
    test_scenario::next_tx(&mut scenario, stranger);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = nft::register_card_type(
        type_name,
        tier_name,
        type_image_url,
        max_supply,
        stranger,
        partner,
        ctx);
      assert!(result == false, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect to be successully created if owner of the partner
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
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

    // Expect created with correct fields
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let card_tier = nft::borrow_mut_card_tier_by_name(tier_name, partner);
      let card_type = nft::borrow_mut_card_type_by_name(type_name, card_tier);

      assert!( nft::card_type_name(card_type) == type_name, 0 );
      assert!( option::is_some<Url>(nft::card_type_image_url(card_type)) == true, 0 );
      assert!( nft::card_type_max_supply(card_type) == max_supply, 0 );
      assert!( nft::card_type_current_supply(card_type) == 0u64, 0 );
      assert!( nft::card_type_current_issued_number(card_type) == 0u64, 0 );

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect failure if try to creat the same card type
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = nft::register_card_type(
        type_name,
        tier_name,
        type_image_url,
        max_supply,
        owner,
        partner,
        ctx);
      assert!(result == false, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_complete_order() {
    use sui::test_scenario;

    use std::string::{Self};
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
    let visibility = 1;
    let token_name = string::utf8(b"CMM");
    let allow_nft_card = 1;
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_partner(
        name, code, excerpt, content, logo_url,visibility, token_name, owner, allow_nft_card, &mut partner_board, ctx
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
    let type_name = string::utf8(b"Membership");
    let type_image_url = string::utf8(b"https://loychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
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

    // Mint nft card and transfer to receiver
    let receiver = @0x0003;
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let nft_card = partner_nft::mint_card(tier_name, type_name, owner, partner, ctx);
      let card_benefit = nft::complete_order(&mut nft_card);

      assert!(card_benefit == tier_benefit, 0);

      partner_nft::transfer_card(nft_card, receiver);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect receiver has a nft card with correct issue number
    test_scenario::next_tx(&mut scenario, receiver);
    {
      let nft_card = test_scenario::take_from_address<NFTCard>(&scenario,receiver);
      assert!(nft::card_issued_number(&nft_card) == 1, 0);
      assert!(nft::card_accumulated_value(&nft_card) == 10, 0);
      assert!(nft::card_benefit(&nft_card) == tier_benefit, 0);
      assert!(nft::card_used_count(&nft_card) == 1, 0);

      test_scenario::return_to_address<NFTCard>(receiver, nft_card);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_cancel_order() {
    use sui::test_scenario;

    use std::string::{Self};
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
    let visibility = 1;
    let token_name = string::utf8(b"CMM");
    let allow_nft_card = 1;
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_partner(
        name, code, excerpt, content, logo_url,visibility, token_name, owner, allow_nft_card, &mut partner_board, ctx
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
    let type_name = string::utf8(b"Membership");
    let type_image_url = string::utf8(b"https://loychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;

    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
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

    // Mint nft card and transfer to receiver
    let receiver = @0x0003;
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let nft_card = partner_nft::mint_card(tier_name, type_name, owner, partner, ctx);

      nft::complete_order(&mut nft_card);
      nft::complete_order(&mut nft_card);
      nft::complete_order(&mut nft_card);

      partner_nft::transfer_card(nft_card, receiver);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    test_scenario::next_tx(&mut scenario, owner);
    {
      let nft_card = test_scenario::take_from_address<NFTCard>(&scenario,receiver);
      nft::cancel_order(&mut nft_card);
      test_scenario::return_to_address<NFTCard>(receiver, nft_card);
    };

    // Expect receiver has a nft card with correct card_accumulated_value
    test_scenario::next_tx(&mut scenario, receiver);
    {
      let nft_card = test_scenario::take_from_address<NFTCard>(&scenario,receiver);

      // 3 times of +10 and 1 time of -10
      assert!(nft::card_accumulated_value(&nft_card) == 20, 0);

      // 4 times, 3 times to complete the order and 1 time to cancel the order.
      assert!(nft::card_used_count(&nft_card) == 3 + 1, 0);
      test_scenario::return_to_address<NFTCard>(receiver, nft_card);
    };

    test_scenario::end(scenario);
  }

}