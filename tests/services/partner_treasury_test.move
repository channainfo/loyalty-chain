#[test_only]
module loychain::partner_treasury_test {

  #[test]
  public fun test_receive_treasury_cap(){

    use sui::test_scenario;
    use sui::test_utils;
    use sui::coin::{TreasuryCap};
    use loychain::partner::{Self, PartnerBoard, Partner,};
    use loychain::partner_treasury;
    use loychain::loy::{LOY};
    use loychain::token_managable;
    use std::string::{Self};

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
      let partner :&mut Partner = partner::borrow_mut_parter_by_code(code, &mut partner_board);

      let exists = partner_treasury::treasury_cap_exists<LOY>(partner);
      assert!(exists == true, 0);
      test_scenario::return_shared(partner_board);
    };

    test_scenario::end(scenario);
  }
}