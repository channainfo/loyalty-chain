#[test_only]
module loyaltychain::nft_test {

  #[test]
  public fun test_register_card_tier(){
    use sui::test_scenario;
    use sui::url::{Url};

    use std::string::{Self};
    use std::option::{Self};
    use loyaltychain::partnerable::{Self, PartnerBoard, Partner};
    use loyaltychain::nft::{Self};

    let owner = @0x0001;
    // Create boards for partner list
    let scenario = test_scenario::begin(owner);
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
    let tier_name = string::utf8(b"Bronse");
    let tier_description = string::utf8(b"Bronse Benefit");
    let tier_image_url = string::utf8(b"https://loyaltychain.sui/nft/bronse");
    let tier_benefit = 10;

    // Expect failure if not owner of the parnter
    let stranger = @0x0002;
    test_scenario::next_tx(&mut scenario, stranger);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);

      let ctx = test_scenario::ctx(&mut scenario);

      let result = nft::register_card_tier(
        tier_name,
        tier_description,
        tier_image_url,
        tier_benefit,
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
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);

      let ctx = test_scenario::ctx(&mut scenario);

      let result = nft::register_card_tier(
        tier_name,
        tier_description,
        tier_image_url,
        tier_benefit,
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
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);

      let card_tier = nft::borrow_mut_card_tier_by_name(tier_name, partner);

      assert!(nft::card_tier_name(card_tier) == tier_name, 0);
      assert!(nft::card_tier_description(card_tier) == tier_description, 0);
      assert!(option::is_some<Url>(nft::card_tier_image_url(card_tier)) == true, 0);
      assert!(nft::card_tier_benefit(card_tier) == tier_benefit, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect failure if try to create the same card tier
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
    use loyaltychain::partnerable::{Self, PartnerBoard, Partner};
    use loyaltychain::nft::{Self};

    let owner = @0x0001;
    // Create boards for partner list
    let scenario = test_scenario::begin(owner);
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
    let tier_name = string::utf8(b"Bronse");
    let tier_description = string::utf8(b"Bronse Benefit");
    let tier_image_url = string::utf8(b"https://loyaltychain.sui/nft/bronse");
    let tier_benefit = 10;

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
        partner,
        ctx
      );

      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Register Card type
    let type_name = string::utf8(b"Membership");
    let type_image_url = string::utf8(b"https://loyaltychain.sui/nft/bronse/membership");
    let max_supply = 1_000_000u64;
    let capped_amount = 10u64;

    // Expect failure if not owner of the partner
    let stranger = @0x0002;
    test_scenario::next_tx(&mut scenario, stranger);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = nft::register_card_type(
        type_name,
        tier_name,
        type_image_url,
        max_supply,
        capped_amount,
        partner,
        ctx);
      assert!(result == false, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect to be successully created if owner of the partner
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
        capped_amount,
        partner,
        ctx);
      assert!(result == true, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect created with correct fields
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);
      let card_tier = nft::borrow_mut_card_tier_by_name(tier_name, partner);
      let card_type = nft::borrow_mut_card_type_by_name(type_name, card_tier);

      assert!( nft::card_type_name(card_type) == type_name, 0 );
      assert!( option::is_some<Url>(nft::card_type_image_url(card_type)) == true, 0 );
      assert!( nft::card_type_max_supply(card_type) == max_supply, 0 );
      assert!( nft::card_type_current_supply(card_type) == 0u64, 0 );
      assert!( nft::card_type_current_issued_number(card_type) == 0u64, 0 );
      assert!( nft::card_type_capped_amount(card_type) == capped_amount, 0 );
      assert!( nft::card_type_benefit(card_type) == tier_benefit, 0 );

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect failure if try to creat the same card type
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
        capped_amount,
        partner,
        ctx);
      assert!(result == false, 0);

      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    test_scenario::end(scenario);
  }
}