#[test_only]
module loyaltychain::memberable_test {

  #[test]
  public fun test_init_create_member_board(){
    use loyaltychain::memberable::{Self, MemberBoard};
    use sui::test_scenario;

    let owner = @0001;
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      memberable::init_create_member_board(ctx);
    };

    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);

      assert!(memberable::members_count(&board) == 0, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_register_member(){
    use sui::test_scenario;
    use sui::address;

    use loyaltychain::memberable::{Self, MemberBoard};

    use std::string::{Self, String};

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
      let result = memberable::register_member(nick_name, email, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Expected output
    let effects = test_scenario::next_tx(&mut scenario, owner);
    {
      // let ctx = test_scenario::ctx(&mut scenario);

      let board = test_scenario::take_shared(&scenario);

      assert!(memberable::members_count(&board) == 1, 0);

      let member = memberable::borrow_member_by_email(&board, &email);

      let expected_code = address::to_bytes(@0xe5a73b66c2a07822c54b4b46241e07c04a7b7926029ae14ab93a915f4b38a087);
      assert!(memberable::member_nick_name(member) == nick_name, 0);
      assert!(memberable::member_code(member) == expected_code, 0);
      assert!(memberable::member_owner(member)== owner, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    assert!(test_scenario::num_user_events(&effects) == 1, 0);

    // Try to register the same member
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      // it should failed
      let result = memberable::register_member(nick_name, email, &mut board, ctx);
      assert!(result == false, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);

  }

  #[test]
  public fun test_receive_coin(){
    use sui::test_scenario;
    use sui::coin::{Self, Coin};
    use sui::sui::{SUI};
    use sui::object;
    use loyaltychain::loy::{LOY};
    use loyaltychain::memberable::{Self, MemberBoard};
    use std::string::{Self, String};

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
      let result = memberable::register_member(nick_name, email, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Execute the call
    test_scenario::next_tx(&mut scenario, owner);
    let (metadata_loy, metadata_sui) = {

      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let ctx = test_scenario::ctx(&mut scenario);
      let amount_coin1 = coin::mint_for_testing<LOY>(1000u64, ctx);
      let amount_coin2 = coin::mint_for_testing<LOY>(2000u64, ctx);

      let amount_coin3 = coin::mint_for_testing<SUI>(500u64, ctx);

      // CoinMetadata#id
      let metadata_loy = object::id(&amount_coin1);
      let metadata_sui = object::id(&amount_coin3);

      memberable::receive_coin<LOY>(member, amount_coin1, metadata_loy, ctx);
      memberable::receive_coin<LOY>(member, amount_coin2, metadata_loy, ctx);
      memberable::receive_coin<SUI>(member, amount_coin3, metadata_sui, ctx);

      test_scenario::return_shared<MemberBoard>(board);
      (metadata_loy, metadata_sui)
    };

    // Expect the output
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let coin_loy: &Coin<LOY> = memberable::borrow_coin_by_metadata_id<LOY>(member, metadata_loy);
      let coin_sui: &Coin<SUI> = memberable::borrow_coin_by_metadata_id<SUI>(member, metadata_sui);

      assert!(coin::value(coin_loy) == 3000, 0);
      assert!(coin::value(coin_sui) == 500, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };
    test_scenario::end(scenario);
  }

  #[test]
  public fun test_split_coin(){
    use sui::test_scenario;
    use sui::coin::{Self, Coin};
    use sui::sui::{SUI};
    use sui::object;
    use loyaltychain::loy::{LOY};
    use loyaltychain::memberable::{Self, MemberBoard};
    use std::string::{Self, String};

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
      let result = memberable::register_member(nick_name, email, &mut board, ctx);

      // expect registration to be successful
      assert!(result == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Execution call
    test_scenario::next_tx(&mut scenario, owner);
    let (metadata_loy, metadata_sui) = {

      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let ctx = test_scenario::ctx(&mut scenario);
      let amount_coin1 = coin::mint_for_testing<LOY>(1000u64, ctx);
      let amount_coin2 = coin::mint_for_testing<LOY>(2000u64, ctx);

      let amount_coin3 = coin::mint_for_testing<SUI>(500u64, ctx);

      // CoinMetadata#id
      let metadata_loy = object::id(&amount_coin1);
      let metadata_sui = object::id(&amount_coin3);

      memberable::receive_coin<LOY>(member, amount_coin1, metadata_loy, ctx);
      memberable::receive_coin<LOY>(member, amount_coin2, metadata_loy, ctx);
      memberable::receive_coin<SUI>(member, amount_coin3, metadata_sui, ctx);

      test_scenario::return_shared<MemberBoard>(board);
      (metadata_loy, metadata_sui)
    };

    // Expect output for the return coin object
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);
      let ctx = test_scenario::ctx(&mut scenario);

      let coin_loy: Coin<LOY> = memberable::split_coin<LOY>(1500, member, metadata_loy, ctx);
      let coin_sui: Coin<SUI> = memberable::split_coin<SUI>(300, member, metadata_sui, ctx);

      assert!(coin::value(&coin_loy) == 1500, 0);
      assert!(coin::value(&coin_sui) == 300, 0);

      assert!(coin::burn_for_testing<LOY>(coin_loy) == 1500, 0 );
      assert!(coin::burn_for_testing<SUI>(coin_sui) == 300, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    // Expect output for owner remaining coin
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let coin_loy: &Coin<LOY> = memberable::borrow_coin_by_metadata_id<LOY>(member, metadata_loy);
      let coin_sui: &Coin<SUI> = memberable::borrow_coin_by_metadata_id<SUI>(member, metadata_sui);

      assert!(coin::value(coin_loy) == 1500, 0);
      assert!(coin::value(coin_sui) == 200, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_split_and_transfer_coin(){
    use sui::test_scenario;
    use sui::coin::{Self, Coin};

    use sui::sui::{SUI};
    use sui::object;
    use loyaltychain::loy::{LOY};
    use loyaltychain::memberable::{Self, MemberBoard};
    use std::string::{Self, String};

    let member_address1 = @0001;
    let member_email1: String = string::utf8(b"admin1@loyaltychain.org");
    let member_nick_name1: String = string::utf8(b"Scoth2");

    let member_address2 = @0002;
    let member_email2: String = string::utf8(b"admin2@loyaltychain.org");
    let member_nick_name2: String = string::utf8(b"Scoth2");

    let scenario = test_scenario::begin(member_address1);

    // setup member_board
    {
      let ctx = test_scenario::ctx(&mut scenario);
      memberable::init_create_member_board(ctx);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, member_address1);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result1 = memberable::register_member(member_nick_name1, member_email1, &mut board, ctx);

      // expect registration to be successful
      assert!(result1 == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Start creating membership
    test_scenario::next_tx(&mut scenario, member_address2);
    {
      let board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let result2 = memberable::register_member(member_nick_name2, member_email2, &mut board, ctx);

      // expect registration to be successful
      assert!(result2 == true, 0);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Execution call
    test_scenario::next_tx(&mut scenario, member_address1);
    let (metadata_loy, metadata_sui) = {

      let board = test_scenario::take_shared(&scenario);
      let member1 = memberable::borrow_mut_member_by_email(&mut board, &member_email1);

      let ctx = test_scenario::ctx(&mut scenario);
      let amount_coin1 = coin::mint_for_testing<LOY>(1000u64, ctx);
      let amount_coin2 = coin::mint_for_testing<LOY>(2000u64, ctx);

      let amount_coin3 = coin::mint_for_testing<SUI>(500u64, ctx);

      // CoinMetadata#id
      let metadata_loy = object::id(&amount_coin1);
      let metadata_sui = object::id(&amount_coin3);

      memberable::receive_coin<LOY>(member1, amount_coin1, metadata_loy, ctx);
      memberable::receive_coin<LOY>(member1, amount_coin2, metadata_loy, ctx);
      memberable::receive_coin<SUI>(member1, amount_coin3, metadata_sui, ctx);

      test_scenario::return_shared<MemberBoard>(board);
      (metadata_loy, metadata_sui)
    };

    // Expect output for the return coin object
    test_scenario::next_tx(&mut scenario, member_address1);
    {
      let board = test_scenario::take_shared(&scenario);
      let member1 = memberable::borrow_mut_member_by_email(&mut board, &member_email1);
      let ctx = test_scenario::ctx(&mut scenario);

      memberable::split_and_transfer_coin<LOY>(1700, member1, member_address2, metadata_loy, ctx);
      memberable::split_and_transfer_coin<SUI>(100, member1, member_address2, metadata_sui, ctx);

      test_scenario::return_shared<MemberBoard>(board);
    };

    // Expect output for owner remaining coin
    test_scenario::next_tx(&mut scenario, member_address1);
    {
      let board = test_scenario::take_shared(&scenario);
      let member1 = memberable::borrow_mut_member_by_email(&mut board, &member_email1);

      let coin_loy: &Coin<LOY> = memberable::borrow_coin_by_metadata_id<LOY>(member1, metadata_loy);
      let coin_sui: &Coin<SUI> = memberable::borrow_coin_by_metadata_id<SUI>(member1, metadata_sui);

      assert!(coin::value(coin_loy) == 1300, 0);
      assert!(coin::value(coin_sui) == 400, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    // Expect member_address2 receive coin correctly
    test_scenario::next_tx(&mut scenario, member_address2);
    {
      let board = test_scenario::take_shared(&scenario);
      let member2 = memberable::borrow_mut_member_by_email(&mut board, &member_email2);


      let coin_loy = test_scenario::take_from_address<Coin<LOY>>(&scenario, member_address2);
      let coin_sui = test_scenario::take_from_address<Coin<SUI>>(&scenario, member_address2);

      assert!(coin::value(&coin_loy) == 1700, 0);
      assert!(coin::value(&coin_sui) == 100, 0);

      let ctx = test_scenario::ctx(&mut scenario);
      memberable::receive_coin<LOY>(member2, coin_loy, metadata_loy, ctx);
      memberable::receive_coin<SUI>(member2, coin_sui, metadata_sui, ctx);
      test_scenario::return_shared<MemberBoard>(board);
    };

     // Expect coin in the member account
    test_scenario::next_tx(&mut scenario, member_address2);
    {
      let board = test_scenario::take_shared(&scenario);
      let member2 = memberable::borrow_mut_member_by_email(&mut board, &member_email2);

      let coin_loy: &Coin<LOY> = memberable::borrow_coin_by_metadata_id<LOY>(member2, metadata_loy);
      let coin_sui: &Coin<SUI> = memberable::borrow_coin_by_metadata_id<SUI>(member2, metadata_sui);

      assert!(coin::value(coin_loy) == 1700, 0);
      assert!(coin::value(coin_sui) == 100, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_receive_nft_card(){
    use sui::test_scenario;
    use sui::object;
    use loyaltychain::nft::{Self, NFTCard};
    use loyaltychain::memberable::{Self, MemberBoard};
    use loyaltychain::partnerable::{Self, PartnerBoard, Partner};
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
      let result = memberable::register_member(nick_name, email, &mut board, ctx);

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
    let type_image_url = string::utf8(b"https://loyaltychain.sui/nft/bronze/membership");
    let max_supply = 1_000_000u64;
    let capped_amount = 10u64;

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

    // Execute the call
    test_scenario::next_tx(&mut scenario, owner);
    let nft_card_id = {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let partner :&mut Partner = partnerable::borrow_mut_parter_by_code(code, &mut partner_board);
      let ctx = test_scenario::ctx(&mut scenario);

      let nft_cardable: Option<NFTCard> = nft::mint_card(tier_name, type_name, partner, ctx);
      let nft_card = option::destroy_some<NFTCard>(nft_cardable);
      let nft_card_id = object::id(&nft_card);

      memberable::receive_nft_card(member, nft_card, ctx);

      test_scenario::return_shared<MemberBoard>(board);
      test_scenario::return_shared<PartnerBoard>(partner_board);

      nft_card_id
    };

    // Expect value
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);

      let nft_card = memberable::borrow_nft_card_by_id(member, nft_card_id);
      assert!(nft::card_issued_number(nft_card) == 1, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    // Test take_nft_card
    test_scenario::next_tx(&mut scenario, owner);
    {
      let board = test_scenario::take_shared(&scenario);
      let member = memberable::borrow_mut_member_by_email(&mut board, &email);
      let nft_card = memberable::take_nft_card(member, nft_card_id);
      assert!(nft::card_issued_number(&nft_card) == 1, 0);
      nft::transfer_card(nft_card, @0x0003);
      test_scenario::return_shared<MemberBoard>(board);
    };

    // Expect the output
    test_scenario::end(scenario);
  }
}