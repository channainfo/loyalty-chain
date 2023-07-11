#[test_only]
module loychain::partner_token_test {
  #[test]
  public fun test_mint_and_transfer_to_member(){
    use sui::test_scenario;
    use sui::test_utils;
    use sui::coin::{Self, Coin, TreasuryCap};
    use loychain::partner::{Self, PartnerBoard};
    use loychain::member::{Self, MemberBoard};
    use loychain::member_token;
    use loychain::partner_treasury;
    use loychain::partner_token;
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

    // Transfer treasury to the partner
    test_scenario::next_tx(&mut scenario, admin_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&mut scenario);

      partner_treasury::receive_treasury_cap<LOY>(treasury_cap, code, &mut partner_board);
      test_scenario::return_shared(partner_board);
    };
    let minted_amount = 1000u64;
    let description = string::utf8(b"topup");

    test_scenario::next_tx(&mut scenario, admin_address);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let member_board = test_scenario::take_shared<MemberBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      partner_token::mint_and_transfer_to_member<LOY>(
        minted_amount,
        description,
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

      assert!(coin::value(coin_loy) == minted_amount, 0);

      test_scenario::return_shared<MemberBoard>(board);
    };

    test_scenario::end(scenario);
  }
}